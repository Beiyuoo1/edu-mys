extends Node

signal minigame_completed(puzzle_id: String, success: bool)

# Minigame scenes
var fillinTheblank_scene = preload("res://minigames/Drag/scenes/FillInTheBlank.tscn")
var pacman_scene = preload("res://minigames/Pacman/scenes/Main.tscn")
var runner_scene = preload("res://minigames/Runner/scenes/Main.tscn")
var platformer_scene = preload("res://minigames/Platformer/scenes/Main.tscn")
var maze_scene = preload("res://minigames/Maze/scenes/Main.tscn")
var pronunciation_scene = preload("res://minigames/Pronunciation/scenes/Main.tscn")
var math_scene = preload("res://minigames/Math/scenes/Main.tscn")
var dialogue_choice_scene = preload("res://minigames/DialogueChoice/scenes/Main.tscn")
var hear_and_fill_scene = preload("res://minigames/HearAndFill/scenes/Main.tscn")
var riddle_scene = preload("res://minigames/Riddle/scenes/Main.tscn")
var detective_analysis_scene = preload("res://minigames/DetectiveAnalysis/scenes/Main.tscn")
var logic_grid_scene = preload("res://minigames/LogicGrid/scenes/Main.tscn")
var timeline_reconstruction_scene = preload("res://minigames/TimelineReconstruction/scenes/Main.tscn")
var current_minigame = null

# Track if last minigame earned speed bonus (for ChapterStatsTracker)
var last_minigame_speed_bonus: bool = false
# Track if last minigame succeeded or failed (for ChapterStatsTracker)
var last_minigame_success: bool = true

# ============================================
# TEMPORARY: Set to true to disable Vosk and test other game features
const DISABLE_VOSK = false
# ============================================

# Preloaded Vosk recognizer for dialogue choice minigame
var shared_vosk_recognizer = null
var vosk_loading_progress: float = 0.0  # 0.0 to 1.0
var vosk_is_loaded: bool = false
var loading_screen = null
const VOSK_MODEL_PATH = "res://addons/vosk/models/vosk-model-en-us-0.22"
const VOSK_SAMPLE_RATE = 16000.0
var loading_screen_scene = preload("res://scenes/ui/vosk_loading_screen.tscn")

func _ready():
	if DISABLE_VOSK:
		print("MinigameManager: ⚠️ VOSK DISABLED - Skipping voice recognition loading")
		vosk_is_loaded = false  # Mark as not loaded
		return

	print("MinigameManager: Starting Vosk preload with loading screen...")
	_show_loading_screen_and_load()

func _show_loading_screen_and_load():
	"""Show loading screen and load Vosk model with progress tracking"""
	# Show loading screen (use call_deferred to avoid parent busy error)
	loading_screen = loading_screen_scene.instantiate()
	get_tree().root.call_deferred("add_child", loading_screen)

	# Start loading asynchronously
	_preload_vosk_async()

func _preload_vosk_async():
	"""Preload Vosk model asynchronously with simulated progress tracking"""
	# Wait one frame to let the loading screen appear
	await get_tree().process_frame

	print("MinigameManager: Initializing Vosk recognizer...")

	# Simulate progress (since GodotVoskRecognizer.initialize() doesn't report progress)
	# We'll fake the progress bar animation
	var progress_tween = create_tween()
	progress_tween.tween_property(self, "vosk_loading_progress", 0.3, 1.0)

	await get_tree().create_timer(1.0).timeout

	# Actually initialize Vosk (this is the slow part)
	shared_vosk_recognizer = GodotVoskRecognizer.new()
	var absolute_path = ProjectSettings.globalize_path(VOSK_MODEL_PATH)

	# Continue progress animation
	var progress_tween2 = create_tween()
	progress_tween2.tween_property(self, "vosk_loading_progress", 0.7, 2.0)

	# Initialize (this blocks, but progress bar keeps animating)
	var success = await _initialize_vosk_threaded(absolute_path)

	# Complete progress
	vosk_loading_progress = 1.0

	if success:
		print("MinigameManager: ✓ Vosk model loaded and ready!")
		vosk_is_loaded = true
	else:
		push_error("MinigameManager: Failed to load Vosk model at: " + absolute_path)
		shared_vosk_recognizer = null
		vosk_is_loaded = false

func _initialize_vosk_threaded(absolute_path: String) -> bool:
	"""Initialize Vosk in a way that doesn't completely freeze the UI"""
	# Break into chunks to allow UI updates
	await get_tree().process_frame
	vosk_loading_progress = 0.75

	var result = shared_vosk_recognizer.initialize(absolute_path, VOSK_SAMPLE_RATE)

	await get_tree().process_frame
	vosk_loading_progress = 0.95

	await get_tree().create_timer(0.3).timeout

	return result

# Fill-in-the-blank puzzle configs
var fillinTheblank_configs = {
	"timeline_deduction": {
		"sentence_parts": ["The scientific method starts with ", " and ends with a ", "."],
		"answers": ["observation", "conclusion"],
		"choices": ["observation", "experiment", "conclusion", "hypothesis", "question", "theory", "analysis", "research"]
	},
	"statement_analysis": {
		"sentence_parts": ["Critical thinking requires ", " evidence before forming a ", "."],
		"answers": ["evaluating", "judgment"],
		"choices": ["evaluating", "ignoring", "judgment", "question", "collecting", "opinion", "belief", "theory"]
	},
	"locker_examination": {
		"sentence_parts": ["Conrad ", " the envelope closely."],
		"answers": ["examines"],
		"choices": ["examines", "studies", "ignores", "watches", "inspects", "reads", "opens", "holds"]
	},
	# ====================
	# MATH VARIANTS - Chapter 1
	# ====================
	"locker_examination_math": {
		"sentence_parts": ["In the equation y = mx + b, m represents the ", "."],
		"answers": ["slope"],
		"choices": ["slope", "intercept", "coefficient", "constant", "variable", "exponent", "base", "power"]
	},
	"locker_examination_science": {
		"sentence_parts": ["Newton's second law states that force equals mass times ", "."],
		"answers": ["acceleration"],
		"choices": ["acceleration", "velocity", "speed", "momentum", "energy", "power", "distance", "friction"]
	},
	"budget_basics": {
		"sentence_parts": ["A budget helps track ", " and ", " to manage money wisely."],
		"answers": ["income", "expenses"],
		"choices": ["income", "expenses", "savings", "debts", "profits", "losses", "assets", "taxes"]
	},
	# Chapter 4 - Library access logic
	"library_logic": {
		"sentence_parts": ["To solve the case, Conrad must analyze ", " and identify ", " to find the truth."],
		"answers": ["patterns", "evidence"],
		"choices": ["patterns", "evidence", "suspects", "motives", "alibis", "witnesses", "clues", "facts"]
	},
	# Chapter 4 - Pedagogy methods (Archive scene)
	"pedagogy_methods": {
		"sentence_parts": ["Experimental ", " teaches through ", " rather than lectures."],
		"answers": ["pedagogy", "experience"],
		"choices": ["authority", "memorization", "pedagogy", "observation", "discipline", "experience", "control", "teaching"]
	},
	# Chapter 5 - Lesson reflection
	"lesson_reflection": {
		"sentence_parts": ["True teaching requires ", " and respects ", " while guiding growth."],
		"answers": ["wisdom", "choice"],
		"choices": ["wisdom", "choice", "control", "force", "patience", "freedom", "power", "authority"]
	},
	# ====================
	# MATH VARIANTS - Chapter 4
	# ====================
	"pedagogy_methods_math": {
		"sentence_parts": ["In trigonometry, ", " is opposite over ", "."],
		"answers": ["sine", "hypotenuse"],
		"choices": ["sine", "cosine", "tangent", "adjacent", "hypotenuse", "opposite", "secant", "angle"]
	},
	"pedagogy_methods_science": {
		"sentence_parts": ["In a series circuit, ", " adds up across resistors while ", " stays constant."],
		"answers": ["voltage", "current"],
		"choices": ["voltage", "current", "power", "resistance", "energy", "frequency", "amplitude", "wavelength"]
	},

	# ========================================
	# ENGLISH MODULE 1: Nature, Functions, and Process of Communication
	# ========================================

	# Q1: Definition of Communication
	"english_m1_communication_def": {
		"sentence_parts": ["The exchange of ", ", ideas, or feelings between people is called ", "."],
		"answers": ["information", "communication"],
		"choices": ["language", "information", "message", "interaction", "communication", "feedback", "channel", "context"]
	},
	# Q2: Sender
	"english_m1_sender": {
		"sentence_parts": ["The ", " is the person who ", " the message."],
		"answers": ["sender", "creates"],
		"choices": ["sender", "receiver", "listener", "decoder", "creates", "receives", "sends", "interprets"]
	},
	# Q3: Receiver
	"english_m1_receiver": {
		"sentence_parts": ["The ", " is the person who ", " the message."],
		"answers": ["receiver", "interprets"],
		"choices": ["sender", "receiver", "speaker", "listener", "receives", "interprets", "sends", "creates"]
	},
	# Q4: Message
	"english_m1_message": {
		"sentence_parts": ["The ", " is the ", " being communicated."],
		"answers": ["message", "information"],
		"choices": ["message", "channel", "information", "feedback", "noise", "context", "medium", "process"]
	},
	# Q5: Encoding
	"english_m1_encoding": {
		"sentence_parts": ["", " is the process of ", " ideas into words or symbols."],
		"answers": ["encoding", "converting"],
		"choices": ["encoding", "decoding", "feedback", "noise", "converting", "interpreting", "sending", "responding"]
	},
	# Q6: Decoding
	"english_m1_decoding": {
		"sentence_parts": ["", " is the process of ", " the message."],
		"answers": ["decoding", "interpreting"],
		"choices": ["encoding", "decoding", "feedback", "noise", "sending", "interpreting", "receiving", "responding"]
	},
	# Q7: Channel
	"english_m1_channel": {
		"sentence_parts": ["The ", " is the ", " used to transmit the message."],
		"answers": ["channel", "medium"],
		"choices": ["channel", "message", "feedback", "context", "medium", "noise", "sender", "receiver"]
	},
	# Q8: Feedback
	"english_m1_feedback": {
		"sentence_parts": ["", " is the ", " given by the receiver."],
		"answers": ["feedback", "response"],
		"choices": ["feedback", "message", "channel", "noise", "response", "encoding", "decoding", "context"]
	},
	# Q9: Noise
	"english_m1_noise": {
		"sentence_parts": ["", " refers to anything that ", " communication."],
		"answers": ["noise", "interferes"],
		"choices": ["noise", "feedback", "context", "channel", "interferes", "improves", "sends", "receives"]
	},
	# Q10: Verbal Communication
	"english_m1_verbal": {
		"sentence_parts": ["", " communication uses ", " or written words."],
		"answers": ["verbal", "spoken"],
		"choices": ["verbal", "nonverbal", "visual", "digital", "spoken", "gestures", "images", "signals"]
	},
	# Q11: Nonverbal Communication
	"english_m1_nonverbal": {
		"sentence_parts": ["", " communication uses ", " language and facial expressions."],
		"answers": ["nonverbal", "body"],
		"choices": ["verbal", "written", "nonverbal", "oral", "body", "spoken", "digital", "formal"]
	},
	# Q12: Nature of Communication
	"english_m1_nature": {
		"sentence_parts": ["The ", " of communication describes how it ", "."],
		"answers": ["nature", "works"],
		"choices": ["nature", "function", "process", "context", "works", "begins", "ends", "changes"]
	},
	# Q13: Process of Communication
	"english_m1_process": {
		"sentence_parts": ["The ", " is the continuous ", " between sender and receiver."],
		"answers": ["process", "exchange"],
		"choices": ["process", "channel", "message", "feedback", "exchange", "response", "medium", "context"]
	},
	# Q14: Effective Communication
	"english_m1_effective": {
		"sentence_parts": ["", " communication is ", " by the receiver."],
		"answers": ["effective", "understood"],
		"choices": ["effective", "formal", "verbal", "clear", "understood", "spoken", "written", "sent"]
	},
	# Q15: Function of Communication
	"english_m1_function": {
		"sentence_parts": ["The ", " of communication is its ", "."],
		"answers": ["function", "purpose"],
		"choices": ["function", "nature", "process", "channel", "purpose", "message", "context", "feedback"]
	},
	# Q16: Context
	"english_m1_context": {
		"sentence_parts": ["The ", " is the situation where communication ", "."],
		"answers": ["context", "occurs"],
		"choices": ["context", "channel", "message", "noise", "occurs", "ends", "begins", "stops"]
	},
	# Q17: Clarity
	"english_m1_clarity": {
		"sentence_parts": ["", " means expressing ideas ", " and understandably."],
		"answers": ["clarity", "clearly"],
		"choices": ["clarity", "courtesy", "conciseness", "correctness", "clearly", "briefly", "politely", "accurately"]
	},
	# Q18: Courtesy
	"english_m1_courtesy": {
		"sentence_parts": ["", " refers to politeness and ", " in communication."],
		"answers": ["courtesy", "respect"],
		"choices": ["courtesy", "clarity", "respect", "tone", "conciseness", "accuracy", "feedback", "context"]
	},
	# Q19: Conciseness
	"english_m1_conciseness": {
		"sentence_parts": ["", " means expressing ideas ", " and directly."],
		"answers": ["conciseness", "briefly"],
		"choices": ["conciseness", "clarity", "courtesy", "correctness", "briefly", "clearly", "politely", "accurately"]
	},
	# Q20: Communication Breakdown
	"english_m1_breakdown": {
		"sentence_parts": ["A communication ", " happens when the message is not ", "."],
		"answers": ["breakdown", "understood"],
		"choices": ["breakdown", "barrier", "noise", "error", "understood", "sent", "heard", "received"]
	},

	# ========================================
	# ENGLISH MODULE 2: Models of Communication
	# ========================================

	# Q1: Diagram Definition
	"english_m2_diagram": {
		"sentence_parts": ["A ", " is a visual ", " of how communication works."],
		"answers": ["diagram", "representation"],
		"choices": ["diagram", "speech", "model", "message", "representation", "language", "process", "interaction"]
	},
	# Q2: Linear Model
	"english_m2_linear": {
		"sentence_parts": ["The ", " model shows communication as a ", " process."],
		"answers": ["linear", "oneway"],
		"choices": ["linear", "interactive", "transactional", "circular", "oneway", "twoway", "dynamic", "simultaneous"]
	},
	# Q3: Interactive Model
	"english_m2_interactive": {
		"sentence_parts": ["The ", " model includes ", " from the receiver."],
		"answers": ["interactive", "feedback"],
		"choices": ["linear", "passive", "interactive", "static", "feedback", "noise", "message", "channel"]
	},
	# Q4: Transactional Model
	"english_m2_transactional": {
		"sentence_parts": ["The ", " model shows participants as ", " sender and receiver."],
		"answers": ["transactional", "simultaneous"],
		"choices": ["linear", "interactive", "transactional", "sequential", "simultaneous", "passive", "active", "circular"]
	},
	# Q5: Shannon-Weaver
	"english_m2_shannon_weaver": {
		"sentence_parts": ["The Shannon-Weaver model was developed by ", " ", "."],
		"answers": ["shannon", "claude"],
		"choices": ["aristotle", "berlo", "shannon", "schramm", "claude", "wilbur", "linear", "model"]
	},
	# Q6: Noise Definition
	"english_m2_noise": {
		"sentence_parts": ["", " refers to ", " in communication."],
		"answers": ["noise", "interference"],
		"choices": ["channel", "noise", "feedback", "context", "interference", "response", "process", "message"]
	},
	# Q7: Sender Role
	"english_m2_sender": {
		"sentence_parts": ["The ", " ", " the communication process."],
		"answers": ["sender", "starts"],
		"choices": ["receiver", "decoder", "sender", "listener", "starts", "ends", "interrupts", "responds"]
	},
	# Q8: Receiver Role
	"english_m2_receiver": {
		"sentence_parts": ["The ", " ", " and interprets the message."],
		"answers": ["receiver", "receives"],
		"choices": ["sender", "encoder", "receiver", "speaker", "receives", "sends", "creates", "converts"]
	},
	# Q9: Schramm Model
	"english_m2_schramm": {
		"sentence_parts": ["The ", " model emphasizes ", " experience."],
		"answers": ["schramm", "shared"],
		"choices": ["aristotle", "shannon", "schramm", "linear", "shared", "public", "individual", "passive"]
	},
	# Q10: Aristotle Model
	"english_m2_aristotle": {
		"sentence_parts": ["The ", " model focuses on ", " speaking."],
		"answers": ["aristotle", "public"],
		"choices": ["interactive", "transactional", "aristotle", "circular", "public", "group", "mass", "digital"]
	},
	# Q11: Channel Definition
	"english_m2_channel": {
		"sentence_parts": ["The ", " is the ", " used to transmit messages."],
		"answers": ["channel", "medium"],
		"choices": ["message", "channel", "feedback", "noise", "medium", "process", "context", "sender"]
	},
	# Q12: Message Content
	"english_m2_message": {
		"sentence_parts": ["The ", " refers to the ", " of communication."],
		"answers": ["message", "content"],
		"choices": ["context", "message", "noise", "feedback", "content", "situation", "medium", "process"]
	},
	# Q13: Feedback Definition
	"english_m2_feedback": {
		"sentence_parts": ["", " refers to the receiver's ", "."],
		"answers": ["feedback", "response"],
		"choices": ["channel", "noise", "feedback", "encoding", "response", "message", "medium", "process"]
	},
	# Q14: Linear Mass Communication
	"english_m2_linear_mass": {
		"sentence_parts": ["The ", " model is commonly used in ", " communication."],
		"answers": ["linear", "mass"],
		"choices": ["transactional", "interactive", "linear", "circular", "mass", "personal", "group", "digital"]
	},
	# Q15: Interactive Turn-Taking
	"english_m2_interactive_turn": {
		"sentence_parts": ["The ", " model allows ", " taking."],
		"answers": ["interactive", "turn"],
		"choices": ["linear", "interactive", "aristotle", "passive", "turn", "role", "message", "feedback"]
	},
	# Q16: Context Situation
	"english_m2_context": {
		"sentence_parts": ["The ", " refers to the ", " of communication."],
		"answers": ["context", "situation"],
		"choices": ["noise", "channel", "context", "message", "situation", "medium", "process", "feedback"]
	},
	# Q17: Transactional Dynamic
	"english_m2_transactional_dynamic": {
		"sentence_parts": ["The ", " model views communication as ", "."],
		"answers": ["transactional", "dynamic"],
		"choices": ["linear", "interactive", "transactional", "mechanical", "dynamic", "static", "passive", "fixed"]
	},
	# Q18: Encoding Definition
	"english_m2_encoding": {
		"sentence_parts": ["", " refers to ", " ideas into symbols."],
		"answers": ["encoding", "converting"],
		"choices": ["decoding", "feedback", "encoding", "noise", "converting", "interpreting", "sending", "receiving"]
	},
	# Q19: Decoding Definition
	"english_m2_decoding": {
		"sentence_parts": ["", " refers to ", " symbols."],
		"answers": ["decoding", "interpreting"],
		"choices": ["encoding", "channel", "decoding", "feedback", "interpreting", "sending", "receiving", "converting"]
	},
	# Q20: Schramm Fields
	"english_m2_schramm_fields": {
		"sentence_parts": ["The ", " model highlights ", " experience."],
		"answers": ["schramm", "fields"],
		"choices": ["aristotle", "shannon", "schramm", "linear", "fields", "shared", "public", "passive"]
	},

	# ========================================
	# SCIENCE MODULE 1: SI Units, Measurement, Scientific Notation
	# ========================================

	# SI Base Units (Q1-Q5)
	# Q1: Length Unit
	"science_m1_length_unit": {
		"sentence_parts": ["The SI unit of ", " is ", "."],
		"answers": ["length", "meter"],
		"choices": ["length", "mass", "time", "current", "meter", "gram", "second", "liter"]
	},
	# Q2: Mass Unit
	"science_m1_mass_unit": {
		"sentence_parts": ["The SI unit of ", " is ", "."],
		"answers": ["mass", "kilogram"],
		"choices": ["length", "mass", "time", "current", "kilogram", "meter", "second", "ampere"]
	},
	# Q3: Time Unit
	"science_m1_time_unit": {
		"sentence_parts": ["The SI unit of ", " is ", "."],
		"answers": ["time", "second"],
		"choices": ["time", "length", "mass", "temperature", "second", "minute", "hour", "day"]
	},
	# Q4: Electric Current Unit
	"science_m1_current_unit": {
		"sentence_parts": ["The SI unit of ", " current is ", "."],
		"answers": ["electric", "ampere"],
		"choices": ["electric", "thermal", "mechanical", "magnetic", "ampere", "volt", "watt", "ohm"]
	},
	# Q5: Derived Quantity
	"science_m1_derived": {
		"sentence_parts": ["A physical quantity formed from base units is called ", " ", "."],
		"answers": ["derived", "quantity"],
		"choices": ["base", "derived", "scalar", "vector", "quantity", "unit", "measure", "value"]
	},

	# Measurement Instruments (Q6-Q10)
	# Q6: Length Instrument
	"science_m1_length_instrument": {
		"sentence_parts": ["", " is measured using a ", "."],
		"answers": ["length", "ruler"],
		"choices": ["length", "mass", "time", "temperature", "ruler", "balance", "clock", "thermometer"]
	},
	# Q7: Mass Instrument
	"science_m1_mass_instrument": {
		"sentence_parts": ["", " is measured using a ", "."],
		"answers": ["mass", "balance"],
		"choices": ["length", "mass", "time", "temperature", "balance", "ruler", "clock", "stopwatch"]
	},
	# Q8: Time Instrument
	"science_m1_time_instrument": {
		"sentence_parts": ["", " is measured using a ", "."],
		"answers": ["time", "clock"],
		"choices": ["time", "length", "mass", "temperature", "clock", "ruler", "balance", "thermometer"]
	},
	# Q9: Temperature Instrument
	"science_m1_temp_instrument": {
		"sentence_parts": ["", " is measured using a ", "."],
		"answers": ["temperature", "thermometer"],
		"choices": ["temperature", "mass", "time", "length", "thermometer", "balance", "clock", "ruler"]
	},
	# Q10: Least Count
	"science_m1_least_count": {
		"sentence_parts": ["The ", " measurement an instrument can detect is called ", "."],
		"answers": ["smallest", "least"],
		"choices": ["smallest", "largest", "accurate", "exact", "least", "precision", "error", "limit"]
	},

	# Scientific Notation and Significant Figures (Q11-Q15)
	# Q11: Scientific Notation Example
	"science_m1_sci_notation1": {
		"sentence_parts": ["0.00052 written in ", " notation is ", "."],
		"answers": ["scientific", "5.2×10⁻⁴"],
		"choices": ["scientific", "standard", "decimal", "expanded", "5.2×10⁻⁴", "5.2×10⁴", "52×10⁻⁶", "0.52×10⁻³"]
	},
	# Q12: Significant Figures Count
	"science_m1_sig_figs": {
		"sentence_parts": ["The number of ", " figures in 0.00450 is ", "."],
		"answers": ["significant", "three"],
		"choices": ["significant", "decimal", "exact", "whole", "three", "two", "four", "five"]
	},
	# Q13: Multiplication Rule
	"science_m1_mult_rule": {
		"sentence_parts": ["In multiplication, the result follows the ", " number of ", " figures."],
		"answers": ["smallest", "significant"],
		"choices": ["largest", "smallest", "average", "mean", "significant", "decimal", "exact", "whole"]
	},
	# Q14: Scientific Notation Example 2
	"science_m1_sci_notation2": {
		"sentence_parts": ["3,900 written in ", " notation is ", "."],
		"answers": ["scientific", "3.9×10³"],
		"choices": ["scientific", "standard", "decimal", "expanded", "3.9×10³", "39×10²", "0.39×10⁴", "3.9×10²"]
	},
	# Q15: Significant Figure Definition
	"science_m1_sig_fig_def": {
		"sentence_parts": ["A digit showing measurement precision is called a ", " ", "."],
		"answers": ["significant", "figure"],
		"choices": ["significant", "decimal", "exact", "whole", "figure", "value", "count", "number"]
	},

	# Unit Conversion (Q16-Q20)
	# Q16: Meters to Centimeters
	"science_m1_m_to_cm": {
		"sentence_parts": ["2.5 meters is equal to ", " ", "."],
		"answers": ["250", "centimeters"],
		"choices": ["25", "250", "2500", "0.25", "centimeters", "meters", "millimeters", "kilometers"]
	},
	# Q17: Kilometers to Meters
	"science_m1_km_to_m": {
		"sentence_parts": ["5 kilometers is equal to ", " ", "."],
		"answers": ["5000", "meters"],
		"choices": ["50", "500", "5000", "0.005", "meters", "centimeters", "millimeters", "kilometers"]
	},
	# Q18: Centimeters to Meters
	"science_m1_cm_to_m": {
		"sentence_parts": ["120 centimeters is equal to ", " ", "."],
		"answers": ["1.20", "meters"],
		"choices": ["1.20", "12.0", "0.120", "1200", "meters", "centimeters", "kilometers", "millimeters"]
	},
	# Q19: Hours to Seconds
	"science_m1_hr_to_sec": {
		"sentence_parts": ["One hour is equal to ", " ", "."],
		"answers": ["3600", "seconds"],
		"choices": ["360", "1800", "3600", "6000", "seconds", "minutes", "hours", "days"]
	},
	# Q20: Inches to Centimeters
	"science_m1_in_to_cm": {
		"sentence_parts": ["Ten inches is equal to ", " ", "."],
		"answers": ["25.4", "centimeters"],
		"choices": ["25.4", "254", "2.54", "0.254", "centimeters", "meters", "millimeters", "kilometers"]
	}
}

# ========================================
# ORAL COMMUNICATION MODULE QUIZ CONFIGS
# ========================================

# Module 1: Functions, Nature, and Process of Communication
var oralcom_module1_configs = {
	"oralcom_m1_pacman": {
		"questions": [
			{"question": "What is the exchange of information, ideas, or feelings between people?", "correct": "Communication", "wrong": ["Language", "Interaction", "Conversation"]},
			{"question": "Who is the person that starts or creates the message?", "correct": "Sender", "wrong": ["Receiver", "Decoder", "Listener"]},
			{"question": "Who receives and interprets the message?", "correct": "Receiver", "wrong": ["Speaker", "Sender", "Encoder"]},
			{"question": "What is the idea or information being communicated?", "correct": "Message", "wrong": ["Feedback", "Channel", "Noise"]}
		]
	},
	"oralcom_m1_runner": {
		"questions": [
			{"question": "What is the process of converting ideas into words or symbols?", "correct": "Encoding", "wrong": ["Decoding", "Feedback", "Noise"]},
			{"question": "What is the process of interpreting the message?", "correct": "Decoding", "wrong": ["Encoding", "Sending", "Responding"]},
			{"question": "What is the medium used to transmit the message?", "correct": "Channel", "wrong": ["Context", "Message", "Noise"]},
			{"question": "What is the response given by the receiver?", "correct": "Feedback", "wrong": ["Message", "Channel", "Noise"]},
			{"question": "What refers to anything that interferes with communication?", "correct": "Noise", "wrong": ["Context", "Feedback", "Channel"]}
		],
		"answers_needed": 4
	},
	"oralcom_m1_platformer": {
		"questions": [
			{"question": "What type of communication uses spoken or written words?", "correct": "Verbal", "wrong": ["Nonverbal", "Oral", "Visual"]},
			{"question": "What type of communication uses body language and facial expressions?", "correct": "Nonverbal", "wrong": ["Oral", "Written", "Verbal"]},
			{"question": "What refers to the characteristics that describe how communication works?", "correct": "Nature", "wrong": ["Function", "Process", "Context"]},
			{"question": "What is the continuous exchange between sender and receiver?", "correct": "Process", "wrong": ["Channel", "Encoding", "Feedback"]}
		],
		"answers_needed": 3
	},
	"oralcom_m1_maze": {
		"questions": [
			{"question": "What type of communication is clear and understood by the receiver?", "correct": "Effective", "wrong": ["Verbal", "Formal", "Correct"]},
			{"question": "What refers to the purpose of communication?", "correct": "Function", "wrong": ["Channel", "Nature", "Process"]},
			{"question": "What refers to the situation or environment where communication occurs?", "correct": "Context", "wrong": ["Channel", "Noise", "Message"]},
			{"question": "What means expressing ideas clearly and understandably?", "correct": "Clarity", "wrong": ["Courtesy", "Conciseness", "Correctness"]},
			{"question": "What refers to politeness and respect in communication?", "correct": "Courtesy", "wrong": ["Clarity", "Conciseness", "Correctness"]}
		]
	}
}

# Module 2: Models of Communication
var oralcom_module2_configs = {
	"oralcom_m2_pacman": {
		"questions": [
			{"question": "What refers to a visual representation of how communication works?", "correct": "Diagram", "wrong": ["Speech", "Message", "Language"]},
			{"question": "Which model shows communication as a one-way process?", "correct": "Linear", "wrong": ["Interactive", "Transactional", "Circular"]},
			{"question": "Which model includes feedback from the receiver?", "correct": "Interactive", "wrong": ["Linear", "Passive", "Static"]},
			{"question": "Which model shows participants as simultaneous sender and receiver?", "correct": "Transactional", "wrong": ["Linear", "Interactive", "Sequential"]}
		]
	},
	"oralcom_m2_runner": {
		"questions": [
			{"question": "Who developed the Shannon-Weaver model?", "correct": "Shannon", "wrong": ["Aristotle", "Berlo", "Schramm"]},
			{"question": "What refers to interference in communication?", "correct": "Noise", "wrong": ["Channel", "Feedback", "Context"]},
			{"question": "Who starts the communication process?", "correct": "Sender", "wrong": ["Receiver", "Decoder", "Listener"]},
			{"question": "Who receives and interprets the message?", "correct": "Receiver", "wrong": ["Sender", "Encoder", "Speaker"]},
			{"question": "Which model emphasizes shared experience?", "correct": "Schramm", "wrong": ["Aristotle", "Shannon", "Linear"]}
		],
		"answers_needed": 4
	},
	"oralcom_m2_platformer": {
		"questions": [
			{"question": "Which model focuses on public speaking?", "correct": "Aristotle", "wrong": ["Interactive", "Transactional", "Circular"]},
			{"question": "What refers to the medium used to transmit messages?", "correct": "Channel", "wrong": ["Message", "Feedback", "Noise"]},
			{"question": "What refers to the content of communication?", "correct": "Message", "wrong": ["Context", "Noise", "Feedback"]},
			{"question": "What refers to the receiver's response?", "correct": "Feedback", "wrong": ["Channel", "Noise", "Encoding"]}
		],
		"answers_needed": 3
	},
	"oralcom_m2_maze": {
		"questions": [
			{"question": "Which model is commonly used in mass communication?", "correct": "Linear", "wrong": ["Transactional", "Interactive", "Circular"]},
			{"question": "Which model allows turn-taking?", "correct": "Interactive", "wrong": ["Linear", "Aristotle", "Passive"]},
			{"question": "What refers to the situation of communication?", "correct": "Context", "wrong": ["Noise", "Channel", "Message"]},
			{"question": "Which model views communication as dynamic?", "correct": "Transactional", "wrong": ["Linear", "Interactive", "Mechanical"]},
			{"question": "Which model highlights fields of experience?", "correct": "Schramm", "wrong": ["Aristotle", "Shannon", "Linear"]}
		]
	}
}

# Module 3: Strategies to Avoid Communication Breakdown
var oralcom_module3_configs = {
	"oralcom_m3_pacman": {
		"questions": [
			{"question": "What refers to the failure of communication?", "correct": "Breakdown", "wrong": ["Clarity", "Feedback", "Context"]},
			{"question": "What strategy involves paying full attention to the speaker?", "correct": "Listening", "wrong": ["Speaking", "Reading", "Writing"]},
			{"question": "What refers to asking questions to ensure understanding?", "correct": "Clarification", "wrong": ["Encoding", "Noise", "Feedback"]},
			{"question": "What helps reduce misunderstanding?", "correct": "Feedback", "wrong": ["Ambiguity", "Silence", "Noise"]}
		]
	},
	"oralcom_m3_runner": {
		"questions": [
			{"question": "What refers to expressing ideas clearly?", "correct": "Clarity", "wrong": ["Courtesy", "Context", "Conciseness"]},
			{"question": "What strategy involves showing respect to the listener?", "correct": "Courtesy", "wrong": ["Volume", "Speed", "Gesture"]},
			{"question": "What refers to shortening messages without losing meaning?", "correct": "Conciseness", "wrong": ["Clarity", "Completeness", "Correctness"]},
			{"question": "What causes misunderstanding in communication?", "correct": "Noise", "wrong": ["Feedback", "Context", "Clarity"]},
			{"question": "What refers to the situation where communication occurs?", "correct": "Context", "wrong": ["Channel", "Feedback", "Message"]}
		],
		"answers_needed": 4
	},
	"oralcom_m3_platformer": {
		"questions": [
			{"question": "What strategy involves adjusting language to the audience?", "correct": "Adaptation", "wrong": ["Encoding", "Decoding", "Noise"]},
			{"question": "What refers to responding to confirm understanding?", "correct": "Feedback", "wrong": ["Channel", "Noise", "Message"]},
			{"question": "What refers to polite language use?", "correct": "Courtesy", "wrong": ["Clarity", "Volume", "Speed"]},
			{"question": "What refers to listening with understanding?", "correct": "Listening", "wrong": ["Hearing", "Speaking", "Writing"]}
		],
		"answers_needed": 3
	},
	"oralcom_m3_maze": {
		"questions": [
			{"question": "What refers to correcting misunderstandings?", "correct": "Clarification", "wrong": ["Silence", "Noise", "Context"]},
			{"question": "What prevents confusion?", "correct": "Clarity", "wrong": ["Ambiguity", "Noise", "Speed"]},
			{"question": "What strategy avoids using unnecessary words?", "correct": "Conciseness", "wrong": ["Courtesy", "Completeness", "Adaptation"]},
			{"question": "What occurs when the message is unclear?", "correct": "Breakdown", "wrong": ["Success", "Understanding", "Adaptation"]},
			{"question": "What strategy helps confirm message accuracy?", "correct": "Feedback", "wrong": ["Noise", "Silence", "Ambiguity"]}
		]
	}
}

# Module 4: Oral Communication Activities
var oralcom_module4_configs = {
	"oralcom_m4_pacman": {
		"questions": [
			{"question": "What refers to spoken interaction between two or more people?", "correct": "Communication", "wrong": ["Writing", "Speaking", "Listening"]},
			{"question": "What oral activity involves sharing personal experiences?", "correct": "Storytelling", "wrong": ["Reporting", "Interviewing", "Debating"]},
			{"question": "What oral activity involves asking and answering questions?", "correct": "Interview", "wrong": ["Debate", "Speech", "Reporting"]},
			{"question": "What oral activity involves expressing opinions on an issue?", "correct": "Debating", "wrong": ["Reporting", "Narrating", "Listening"]}
		]
	},
	"oralcom_m4_runner": {
		"questions": [
			{"question": "What oral activity aims to inform an audience?", "correct": "Reporting", "wrong": ["Persuading", "Entertaining", "Arguing"]},
			{"question": "What oral activity involves sharing ideas to a group?", "correct": "Speaking", "wrong": ["Listening", "Writing", "Reading"]},
			{"question": "What oral activity uses voice and gestures?", "correct": "Speaking", "wrong": ["Writing", "Reading", "Typing"]},
			{"question": "What oral activity involves attentive hearing?", "correct": "Listening", "wrong": ["Speaking", "Reading", "Writing"]},
			{"question": "What oral activity focuses on audience understanding?", "correct": "Feedback", "wrong": ["Clarity", "Courtesy", "Context"]}
		],
		"answers_needed": 4
	},
	"oralcom_m4_platformer": {
		"questions": [
			{"question": "What oral activity involves sharing information formally?", "correct": "Reporting", "wrong": ["Interview", "Storytelling", "Debating"]},
			{"question": "What refers to planned oral activities?", "correct": "Controlled", "wrong": ["Random", "Casual", "Unplanned"]},
			{"question": "What refers to spontaneous oral activities?", "correct": "Uncontrolled", "wrong": ["Controlled", "Formal", "Planned"]},
			{"question": "What oral activity involves telling events in sequence?", "correct": "Storytelling", "wrong": ["Interview", "Reporting", "Debating"]}
		],
		"answers_needed": 3
	},
	"oralcom_m4_maze": {
		"questions": [
			{"question": "What oral activity involves exchanging ideas politely?", "correct": "Discussion", "wrong": ["Listening", "Writing", "Reading"]},
			{"question": "What oral activity allows sharing viewpoints?", "correct": "Discussion", "wrong": ["Silence", "Listening", "Reading"]},
			{"question": "What helps improve oral communication activities?", "correct": "Practice", "wrong": ["Noise", "Silence", "Speed"]},
			{"question": "What oral activity requires clear pronunciation?", "correct": "Speaking", "wrong": ["Writing", "Reading", "Typing"]},
			{"question": "What oral activity improves communication skills?", "correct": "Practice", "wrong": ["Avoidance", "Silence", "Noise"]}
		]
	}
}

# Module 5: Types of Speech Context
var oralcom_module5_configs = {
	"oralcom_m5_pacman": {
		"questions": [
			{"question": "Communication that happens within oneself is called?", "correct": "Intrapersonal", "wrong": ["Interpersonal", "Public", "Mass"]},
			{"question": "Communication between two or more people is called?", "correct": "Interpersonal", "wrong": ["Intrapersonal", "Public", "Mass"]},
			{"question": "Communication delivered to a large audience at once is?", "correct": "Mass", "wrong": ["Public", "Interpersonal", "Intrapersonal"]},
			{"question": "Communication addressed to a smaller audience or group is?", "correct": "Public", "wrong": ["Interpersonal", "Mass", "Intrapersonal"]}
		]
	},
	"oralcom_m5_runner": {
		"questions": [
			{"question": "What refers to the situation where communication occurs?", "correct": "Context", "wrong": ["Audience", "Feedback", "Noise"]},
			{"question": "Who receives the message in communication?", "correct": "Audience", "wrong": ["Sender", "Feedback", "Noise"]},
			{"question": "What shows if the message is understood?", "correct": "Feedback", "wrong": ["Context", "Noise", "Channel"]},
			{"question": "Communication that is organized and professional is called?", "correct": "Formal", "wrong": ["Informal", "Casual", "Personal"]},
			{"question": "Communication that is casual and relaxed is?", "correct": "Informal", "wrong": ["Formal", "Public", "Mass"]}
		],
		"answers_needed": 4
	},
	"oralcom_m5_platformer": {
		"questions": [
			{"question": "What describes communication that is clear and successful?", "correct": "Effective", "wrong": ["Noise", "Ambiguous", "Context"]},
			{"question": "Communication that happens in your mind is?", "correct": "Intrapersonal", "wrong": ["Interpersonal", "Public", "Mass"]},
			{"question": "Communication that happens between classmates is?", "correct": "Interpersonal", "wrong": ["Public", "Intrapersonal", "Mass"]},
			{"question": "Speaking in front of a classroom is what type?", "correct": "Public", "wrong": ["Mass", "Interpersonal", "Intrapersonal"]}
		],
		"answers_needed": 3
	},
	"oralcom_m5_maze": {
		"questions": [
			{"question": "Broadcasting a message to thousands is what type?", "correct": "Mass", "wrong": ["Interpersonal", "Intrapersonal", "Public"]},
			{"question": "The listeners or viewers in communication are called?", "correct": "Audience", "wrong": ["Sender", "Feedback", "Channel"]},
			{"question": "The response from the audience is called?", "correct": "Feedback", "wrong": ["Noise", "Channel", "Message"]},
			{"question": "Communication done during ceremonies or official events is?", "correct": "Formal", "wrong": ["Informal", "Mass", "Casual"]},
			{"question": "Communication that succeeds in delivering meaning is?", "correct": "Effective", "wrong": ["Noise", "Context", "Feedback"]}
		]
	}
}

# Pacman quiz puzzle configs
var pacman_configs = {
	"pacman_science": {
		"questions": [
			{
				"question": "What is the chemical symbol for water?",
				"correct": "H2O",
				"wrong": ["CO2", "NaCl", "O2"]
			},
			{
				"question": "Which planet is known as the Red Planet?",
				"correct": "Mars",
				"wrong": ["Venus", "Jupiter", "Saturn"]
			},
			{
				"question": "What gas do plants absorb from the atmosphere?",
				"correct": "Carbon Dioxide",
				"wrong": ["Oxygen", "Nitrogen", "Hydrogen"]
			},
			{
				"question": "What is the largest organ in the human body?",
				"correct": "Skin",
				"wrong": ["Heart", "Liver", "Brain"]
			}
		]
	},
	"pacman_history": {
		"questions": [
			{
				"question": "Who was the first President of the United States?",
				"correct": "Washington",
				"wrong": ["Lincoln", "Jefferson", "Adams"]
			},
			{
				"question": "In what year did World War II end?",
				"correct": "1945",
				"wrong": ["1944", "1946", "1943"]
			},
			{
				"question": "Which ancient civilization built the pyramids?",
				"correct": "Egyptians",
				"wrong": ["Romans", "Greeks", "Mayans"]
			},
			{
				"question": "What was the name of the ship that brought Pilgrims to America?",
				"correct": "Mayflower",
				"wrong": ["Santa Maria", "Endeavour", "Victory"]
			}
		]
	},
	"pacman_math": {
		"questions": [
			{
				"question": "What is 15 x 4?",
				"correct": "60",
				"wrong": ["45", "55", "70"]
			},
			{
				"question": "What is the square root of 144?",
				"correct": "12",
				"wrong": ["11", "13", "14"]
			},
			{
				"question": "What is 7 + 8 x 2?",
				"correct": "23",
				"wrong": ["30", "22", "16"]
			},
			{
				"question": "How many sides does a hexagon have?",
				"correct": "6",
				"wrong": ["5", "7", "8"]
			}
		]
	}
}

# Runner quiz configs
var runner_configs = {
	# Chapter 1: Investigation basics - before talking to janitor
	"investigation_basics": {
		"questions": [
			{"question": "What should a detective do first at a scene?", "correct": "Observe", "wrong": ["Accuse", "Leave", "Guess"]},
			{"question": "What makes a good question during an interview?", "correct": "Open-ended", "wrong": ["Yes/No only", "Leading", "Confusing"]},
			{"question": "What should you do with witness statements?", "correct": "Verify", "wrong": ["Ignore", "Assume true", "Dismiss"]},
			{"question": "What is the key to finding truth?", "correct": "Evidence", "wrong": ["Rumors", "Feelings", "Luck"]},
			{"question": "A good investigator remains...?", "correct": "Objective", "wrong": ["Biased", "Emotional", "Hasty"]}
		],
		"answers_needed": 4
	},
	"runner_geography": {
		"questions": [
			{
				"question": "What is the capital of Japan?",
				"correct": "Tokyo",
				"wrong": ["Osaka", "Kyoto", "Hiroshima"]
			},
			{
				"question": "Which continent is the Sahara Desert located in?",
				"correct": "Africa",
				"wrong": ["Asia", "Australia", "South America"]
			},
			{
				"question": "What is the longest river in the world?",
				"correct": "Nile",
				"wrong": ["Amazon", "Yangtze", "Mississippi"]
			},
			{
				"question": "Which country has the largest population?",
				"correct": "China",
				"wrong": ["India", "USA", "Indonesia"]
			},
			{
				"question": "What is the smallest country in the world?",
				"correct": "Vatican City",
				"wrong": ["Monaco", "San Marino", "Liechtenstein"]
			}
		],
		"answers_needed": 4
	},
	"runner_science": {
		"questions": [
			{
				"question": "What is the speed of light in km/s?",
				"correct": "300,000",
				"wrong": ["150,000", "500,000", "1,000,000"]
			},
			{
				"question": "What planet has the most moons?",
				"correct": "Saturn",
				"wrong": ["Jupiter", "Uranus", "Neptune"]
			},
			{
				"question": "What is the hardest natural substance?",
				"correct": "Diamond",
				"wrong": ["Gold", "Iron", "Titanium"]
			},
			{
				"question": "How many bones are in the adult human body?",
				"correct": "206",
				"wrong": ["186", "216", "256"]
			},
			{
				"question": "What is the chemical symbol for gold?",
				"correct": "Au",
				"wrong": ["Go", "Gd", "Ag"]
			}
		],
		"answers_needed": 4
	},
	"runner_literature": {
		"questions": [
			{
				"question": "Who wrote 'Romeo and Juliet'?",
				"correct": "Shakespeare",
				"wrong": ["Dickens", "Austen", "Twain"]
			},
			{
				"question": "What is the name of Harry Potter's owl?",
				"correct": "Hedwig",
				"wrong": ["Errol", "Pigwidgeon", "Scabbers"]
			},
			{
				"question": "In which book does the character Gandalf appear?",
				"correct": "Lord of Rings",
				"wrong": ["Narnia", "Harry Potter", "Eragon"]
			},
			{
				"question": "Who wrote 'The Great Gatsby'?",
				"correct": "Fitzgerald",
				"wrong": ["Hemingway", "Steinbeck", "Faulkner"]
			},
			{
				"question": "What is the first book of the Bible?",
				"correct": "Genesis",
				"wrong": ["Exodus", "Leviticus", "Matthew"]
			}
		],
		"answers_needed": 4
	}
}

# Platformer quiz configs
var platformer_configs = {
	"platformer_math": {
		"questions": [
			{
				"question": "What is 9 x 6?",
				"correct": "54",
				"wrong": ["45", "56", "63"]
			},
			{
				"question": "What is 144 / 12?",
				"correct": "12",
				"wrong": ["11", "13", "14"]
			},
			{
				"question": "What is 25 + 37?",
				"correct": "62",
				"wrong": ["52", "72", "63"]
			},
			{
				"question": "What is 100 - 47?",
				"correct": "53",
				"wrong": ["43", "57", "63"]
			}
		],
		"answers_needed": 3
	},
	"platformer_science": {
		"questions": [
			{
				"question": "What is the SI unit of force?",
				"correct": "Newton",
				"wrong": ["Joule", "Watt", "Pascal"]
			},
			{
				"question": "What is the speed of light approximately?",
				"correct": "3×10⁸ m/s",
				"wrong": ["3×10⁶ m/s", "3×10⁴ m/s", "300 m/s"]
			},
			{
				"question": "What does PE stand for in physics?",
				"correct": "Potential Energy",
				"wrong": ["Physical Exam", "Power Equation", "Proton Electron"]
			},
			{
				"question": "What is the acceleration due to gravity on Earth?",
				"correct": "10 m/s²",
				"wrong": ["5 m/s²", "20 m/s²", "1 m/s²"]
			}
		],
		"answers_needed": 3
	},
	"platformer_nature": {
		"questions": [
			{
				"question": "What do bees make?",
				"correct": "Honey",
				"wrong": ["Milk", "Silk", "Wax"]
			},
			{
				"question": "How many legs does an insect have?",
				"correct": "6",
				"wrong": ["4", "8", "10"]
			},
			{
				"question": "What is the largest mammal?",
				"correct": "Blue Whale",
				"wrong": ["Elephant", "Giraffe", "Hippo"]
			},
			{
				"question": "What gas do we breathe in?",
				"correct": "Oxygen",
				"wrong": ["Nitrogen", "Carbon", "Helium"]
			}
		],
		"answers_needed": 3
	},
	"platformer_history": {
		"questions": [
			{
				"question": "Who discovered America?",
				"correct": "Columbus",
				"wrong": ["Magellan", "Cook", "Drake"]
			},
			{
				"question": "What year did WW1 start?",
				"correct": "1914",
				"wrong": ["1912", "1916", "1918"]
			},
			{
				"question": "Who was the first man on the moon?",
				"correct": "Armstrong",
				"wrong": ["Aldrin", "Glenn", "Gagarin"]
			},
			{
				"question": "What empire built the Colosseum?",
				"correct": "Roman",
				"wrong": ["Greek", "Egyptian", "Persian"]
			}
		],
		"answers_needed": 3
	}
}

# Maze puzzle configs - questions shown in order, player plans route through maze
var maze_configs = {
	# Chapter 1: Evidence Analysis - when Conrad finds the bracelet
	"evidence_analysis": {
		"questions": [
			{"question": "What must evidence be to be used in an argument?", "correct": "Relevant", "wrong": ["Popular", "Emotional", "Lengthy"]},
			{"question": "What do we call information that proves something?", "correct": "Evidence", "wrong": ["Opinion", "Rumor", "Guess"]},
			{"question": "In law, the prosecution must prove guilt beyond reasonable...?", "correct": "Doubt", "wrong": ["Time", "Effort", "Distance"]},
			{"question": "What type of evidence comes from witnesses?", "correct": "Testimony", "wrong": ["Physical", "Digital", "Forensic"]},
			{"question": "What skill helps you evaluate if evidence is trustworthy?", "correct": "Critical thinking", "wrong": ["Speed reading", "Memorization", "Guessing"]}
		]
	},
	"maze_deduction": {
		"questions": [
			{"question": "What comes after 'observation' in the scientific method?", "correct": "Hypothesis", "wrong": ["Conclusion", "Experiment", "Theory"]},
			{"question": "What type of reasoning goes from general to specific?", "correct": "Deductive", "wrong": ["Inductive", "Abductive", "Circular"]},
			{"question": "What do we call a testable prediction?", "correct": "Hypothesis", "wrong": ["Fact", "Opinion", "Law"]},
			{"question": "What confirms or denies a hypothesis?", "correct": "Evidence", "wrong": ["Belief", "Assumption", "Guess"]},
			{"question": "What is the final step of the scientific method?", "correct": "Conclusion", "wrong": ["Question", "Research", "Hypothesis"]}
		]
	},
	"maze_logic": {
		"questions": [
			{"question": "If A implies B, and A is true, what is B?", "correct": "True", "wrong": ["False", "Unknown", "Neither"]},
			{"question": "What is the opposite of 'all'?", "correct": "None", "wrong": ["Some", "Most", "Few"]},
			{"question": "A AND B is true when?", "correct": "Both true", "wrong": ["One true", "Both false", "Either true"]},
			{"question": "A OR B is false when?", "correct": "Both false", "wrong": ["One false", "Both true", "One true"]},
			{"question": "What is NOT true?", "correct": "False", "wrong": ["Maybe", "True", "Unknown"]}
		]
	},
	"maze_vocabulary": {
		"questions": [
			{"question": "A word that means the same is called a?", "correct": "Synonym", "wrong": ["Antonym", "Homonym", "Acronym"]},
			{"question": "A word that means the opposite is called a?", "correct": "Antonym", "wrong": ["Synonym", "Homonym", "Acronym"]},
			{"question": "Words that sound the same are called?", "correct": "Homophones", "wrong": ["Synonyms", "Antonyms", "Metaphors"]},
			{"question": "The main character in a story is the?", "correct": "Protagonist", "wrong": ["Antagonist", "Narrator", "Author"]},
			{"question": "A comparison using 'like' or 'as' is a?", "correct": "Simile", "wrong": ["Metaphor", "Hyperbole", "Irony"]}
		]
	},
	# Chapter 3: Art vocabulary - examining Victor's art supplies
	"art_vocabulary": {
		"questions": [
			{"question": "The arrangement of elements in art is called?", "correct": "Composition", "wrong": ["Texture", "Hue", "Medium"]},
			{"question": "Light and dark contrast in art is called?", "correct": "Value", "wrong": ["Color", "Line", "Shape"]},
			{"question": "The surface quality of artwork is its?", "correct": "Texture", "wrong": ["Form", "Space", "Balance"]},
			{"question": "The material used to create art is the?", "correct": "Medium", "wrong": ["Subject", "Style", "Genre"]},
			{"question": "Visual weight distribution in art is called?", "correct": "Balance", "wrong": ["Rhythm", "Unity", "Contrast"]}
		]
	},

	# English Communication Module - 20 fill-in-the-blank questions (2 blanks each)
	"english_communication_q1": {
		"question": {
			"text": "The exchange of ________, ideas, or feelings between people is called ________.",
			"options": [
				{"letter": "A", "text": "Language", "correct": false},
				{"letter": "B", "text": "Information", "correct": true},
				{"letter": "C", "text": "Message", "correct": false},
				{"letter": "D", "text": "Interaction", "correct": false},
				{"letter": "E", "text": "Communication", "correct": true},
				{"letter": "F", "text": "Feedback", "correct": false},
				{"letter": "G", "text": "Channel", "correct": false},
				{"letter": "H", "text": "Context", "correct": false}
			]
		}
	},
	"english_communication_q2": {
		"question": {
			"text": "The ________ is the person who ________ the message.",
			"options": [
				{"letter": "A", "text": "Sender", "correct": true},
				{"letter": "B", "text": "Receiver", "correct": false},
				{"letter": "C", "text": "Listener", "correct": false},
				{"letter": "D", "text": "Decoder", "correct": false},
				{"letter": "E", "text": "Creates", "correct": true},
				{"letter": "F", "text": "Receives", "correct": false},
				{"letter": "G", "text": "Sends", "correct": false},
				{"letter": "H", "text": "Interprets", "correct": false}
			]
		}
	},
	"english_communication_q3": {
		"question": {
			"text": "The ________ is the person who ________ the message.",
			"options": [
				{"letter": "A", "text": "Sender", "correct": false},
				{"letter": "B", "text": "Receiver", "correct": true},
				{"letter": "C", "text": "Speaker", "correct": false},
				{"letter": "D", "text": "Listener", "correct": false},
				{"letter": "E", "text": "Receives", "correct": false},
				{"letter": "F", "text": "Interprets", "correct": true},
				{"letter": "G", "text": "Sends", "correct": false},
				{"letter": "H", "text": "Creates", "correct": false}
			]
		}
	},
	"english_communication_q4": {
		"question": {
			"text": "The ________ is the ________ being communicated.",
			"options": [
				{"letter": "A", "text": "Message", "correct": true},
				{"letter": "B", "text": "Channel", "correct": false},
				{"letter": "C", "text": "Information", "correct": true},
				{"letter": "D", "text": "Feedback", "correct": false},
				{"letter": "E", "text": "Noise", "correct": false},
				{"letter": "F", "text": "Context", "correct": false},
				{"letter": "G", "text": "Medium", "correct": false},
				{"letter": "H", "text": "Process", "correct": false}
			]
		}
	},
	"english_communication_q5": {
		"question": {
			"text": "________ is the process of ________ ideas into words or symbols.",
			"options": [
				{"letter": "A", "text": "Encoding", "correct": true},
				{"letter": "B", "text": "Decoding", "correct": false},
				{"letter": "C", "text": "Feedback", "correct": false},
				{"letter": "D", "text": "Noise", "correct": false},
				{"letter": "E", "text": "Converting", "correct": true},
				{"letter": "F", "text": "Interpreting", "correct": false},
				{"letter": "G", "text": "Sending", "correct": false},
				{"letter": "H", "text": "Responding", "correct": false}
			]
		}
	},
	"english_communication_q6": {
		"question": {
			"text": "________ is the process of ________ the message.",
			"options": [
				{"letter": "A", "text": "Encoding", "correct": false},
				{"letter": "B", "text": "Decoding", "correct": true},
				{"letter": "C", "text": "Feedback", "correct": false},
				{"letter": "D", "text": "Noise", "correct": false},
				{"letter": "E", "text": "Sending", "correct": false},
				{"letter": "F", "text": "Interpreting", "correct": true},
				{"letter": "G", "text": "Receiving", "correct": false},
				{"letter": "H", "text": "Responding", "correct": false}
			]
		}
	},
	"english_communication_q7": {
		"question": {
			"text": "The ________ is the ________ used to transmit the message.",
			"options": [
				{"letter": "A", "text": "Channel", "correct": true},
				{"letter": "B", "text": "Message", "correct": false},
				{"letter": "C", "text": "Feedback", "correct": false},
				{"letter": "D", "text": "Context", "correct": false},
				{"letter": "E", "text": "Medium", "correct": true},
				{"letter": "F", "text": "Noise", "correct": false},
				{"letter": "G", "text": "Sender", "correct": false},
				{"letter": "H", "text": "Receiver", "correct": false}
			]
		}
	},
	"english_communication_q8": {
		"question": {
			"text": "________ is the ________ given by the receiver.",
			"options": [
				{"letter": "A", "text": "Feedback", "correct": true},
				{"letter": "B", "text": "Message", "correct": false},
				{"letter": "C", "text": "Channel", "correct": false},
				{"letter": "D", "text": "Noise", "correct": false},
				{"letter": "E", "text": "Response", "correct": true},
				{"letter": "F", "text": "Encoding", "correct": false},
				{"letter": "G", "text": "Decoding", "correct": false},
				{"letter": "H", "text": "Context", "correct": false}
			]
		}
	},
	"english_communication_q9": {
		"question": {
			"text": "________ refers to anything that ________ communication.",
			"options": [
				{"letter": "A", "text": "Noise", "correct": true},
				{"letter": "B", "text": "Feedback", "correct": false},
				{"letter": "C", "text": "Context", "correct": false},
				{"letter": "D", "text": "Channel", "correct": false},
				{"letter": "E", "text": "Interferes", "correct": true},
				{"letter": "F", "text": "Improves", "correct": false},
				{"letter": "G", "text": "Sends", "correct": false},
				{"letter": "H", "text": "Receives", "correct": false}
			]
		}
	},
	"english_communication_q10": {
		"question": {
			"text": "________ communication uses ________ or written words.",
			"options": [
				{"letter": "A", "text": "Verbal", "correct": true},
				{"letter": "B", "text": "Nonverbal", "correct": false},
				{"letter": "C", "text": "Visual", "correct": false},
				{"letter": "D", "text": "Digital", "correct": false},
				{"letter": "E", "text": "Spoken", "correct": true},
				{"letter": "F", "text": "Gestures", "correct": false},
				{"letter": "G", "text": "Images", "correct": false},
				{"letter": "H", "text": "Signals", "correct": false}
			]
		}
	},
	"english_communication_q11": {
		"question": {
			"text": "________ communication uses ________ language and facial expressions.",
			"options": [
				{"letter": "A", "text": "Verbal", "correct": false},
				{"letter": "B", "text": "Written", "correct": false},
				{"letter": "C", "text": "Nonverbal", "correct": true},
				{"letter": "D", "text": "Oral", "correct": false},
				{"letter": "E", "text": "Body", "correct": true},
				{"letter": "F", "text": "Spoken", "correct": false},
				{"letter": "G", "text": "Digital", "correct": false},
				{"letter": "H", "text": "Formal", "correct": false}
			]
		}
	},
	"english_communication_q12": {
		"question": {
			"text": "The ________ of communication describes how it ________.",
			"options": [
				{"letter": "A", "text": "Nature", "correct": true},
				{"letter": "B", "text": "Function", "correct": false},
				{"letter": "C", "text": "Process", "correct": false},
				{"letter": "D", "text": "Context", "correct": false},
				{"letter": "E", "text": "Works", "correct": true},
				{"letter": "F", "text": "Begins", "correct": false},
				{"letter": "G", "text": "Ends", "correct": false},
				{"letter": "H", "text": "Changes", "correct": false}
			]
		}
	},
	"english_communication_q13": {
		"question": {
			"text": "The ________ is the continuous ________ between sender and receiver.",
			"options": [
				{"letter": "A", "text": "Process", "correct": true},
				{"letter": "B", "text": "Channel", "correct": false},
				{"letter": "C", "text": "Message", "correct": false},
				{"letter": "D", "text": "Feedback", "correct": false},
				{"letter": "E", "text": "Exchange", "correct": true},
				{"letter": "F", "text": "Response", "correct": false},
				{"letter": "G", "text": "Medium", "correct": false},
				{"letter": "H", "text": "Context", "correct": false}
			]
		}
	},
	"english_communication_q14": {
		"question": {
			"text": "________ communication is ________ by the receiver.",
			"options": [
				{"letter": "A", "text": "Effective", "correct": true},
				{"letter": "B", "text": "Formal", "correct": false},
				{"letter": "C", "text": "Verbal", "correct": false},
				{"letter": "D", "text": "Clear", "correct": false},
				{"letter": "E", "text": "Understood", "correct": true},
				{"letter": "F", "text": "Spoken", "correct": false},
				{"letter": "G", "text": "Written", "correct": false},
				{"letter": "H", "text": "Sent", "correct": false}
			]
		}
	},
	"english_communication_q15": {
		"question": {
			"text": "The ________ of communication is its ________.",
			"options": [
				{"letter": "A", "text": "Function", "correct": true},
				{"letter": "B", "text": "Nature", "correct": false},
				{"letter": "C", "text": "Process", "correct": false},
				{"letter": "D", "text": "Channel", "correct": false},
				{"letter": "E", "text": "Purpose", "correct": true},
				{"letter": "F", "text": "Message", "correct": false},
				{"letter": "G", "text": "Context", "correct": false},
				{"letter": "H", "text": "Feedback", "correct": false}
			]
		}
	},
	"english_communication_q16": {
		"question": {
			"text": "The ________ is the situation where communication ________.",
			"options": [
				{"letter": "A", "text": "Context", "correct": true},
				{"letter": "B", "text": "Channel", "correct": false},
				{"letter": "C", "text": "Message", "correct": false},
				{"letter": "D", "text": "Noise", "correct": false},
				{"letter": "E", "text": "Occurs", "correct": true},
				{"letter": "F", "text": "Ends", "correct": false},
				{"letter": "G", "text": "Begins", "correct": false},
				{"letter": "H", "text": "Stops", "correct": false}
			]
		}
	},
	"english_communication_q17": {
		"question": {
			"text": "________ means expressing ideas ________ and understandably.",
			"options": [
				{"letter": "A", "text": "Clarity", "correct": true},
				{"letter": "B", "text": "Courtesy", "correct": false},
				{"letter": "C", "text": "Conciseness", "correct": false},
				{"letter": "D", "text": "Correctness", "correct": false},
				{"letter": "E", "text": "Clearly", "correct": true},
				{"letter": "F", "text": "Briefly", "correct": false},
				{"letter": "G", "text": "Politely", "correct": false},
				{"letter": "H", "text": "Accurately", "correct": false}
			]
		}
	},
	"english_communication_q18": {
		"question": {
			"text": "________ refers to politeness and ________ in communication.",
			"options": [
				{"letter": "A", "text": "Courtesy", "correct": true},
				{"letter": "B", "text": "Clarity", "correct": false},
				{"letter": "C", "text": "Respect", "correct": true},
				{"letter": "D", "text": "Tone", "correct": false},
				{"letter": "E", "text": "Conciseness", "correct": false},
				{"letter": "F", "text": "Accuracy", "correct": false},
				{"letter": "G", "text": "Feedback", "correct": false},
				{"letter": "H", "text": "Context", "correct": false}
			]
		}
	},
	"english_communication_q19": {
		"question": {
			"text": "________ means expressing ideas ________ and directly.",
			"options": [
				{"letter": "A", "text": "Conciseness", "correct": true},
				{"letter": "B", "text": "Clarity", "correct": false},
				{"letter": "C", "text": "Courtesy", "correct": false},
				{"letter": "D", "text": "Correctness", "correct": false},
				{"letter": "E", "text": "Briefly", "correct": true},
				{"letter": "F", "text": "Clearly", "correct": false},
				{"letter": "G", "text": "Politely", "correct": false},
				{"letter": "H", "text": "Accurately", "correct": false}
			]
		}
	},
	"english_communication_q20": {
		"question": {
			"text": "A communication ________ happens when the message is not ________.",
			"options": [
				{"letter": "A", "text": "Breakdown", "correct": true},
				{"letter": "B", "text": "Barrier", "correct": false},
				{"letter": "C", "text": "Noise", "correct": false},
				{"letter": "D", "text": "Error", "correct": false},
				{"letter": "E", "text": "Understood", "correct": true},
				{"letter": "F", "text": "Sent", "correct": false},
				{"letter": "G", "text": "Heard", "correct": false},
				{"letter": "H", "text": "Received", "correct": false}
			]
		}
	}
}

# Pronunciation puzzle configs - K-12 English Oral Communications
var pronunciation_configs = {
	# Story-related pronunciation challenges
	"focus_test": {
		"sentence": "i will focus my mind and find the truth",
		"prompt": "Prove your focus: Say 'I will focus my mind and find the truth.'",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	# Basic articulation and clarity
	"oral_greeting": {
		"sentence": "good morning everyone my name is conrad",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oral_introduction": {
		"sentence": "today i will talk about an important topic",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	# Presentation skills
	"oral_transition": {
		"sentence": "now let us move on to the next point",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oral_conclusion": {
		"sentence": "in conclusion we have learned three key ideas",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	# Reading fluency
	"oral_fluency_1": {
		"sentence": "the quick brown fox jumps over the lazy dog",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oral_fluency_2": {
		"sentence": "she sells seashells by the seashore",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	# Expression and emphasis
	"oral_question": {
		"sentence": "what do you think is the best solution",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oral_persuasion": {
		"sentence": "i believe we should work together as a team",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	# Formal speaking
	"oral_formal": {
		"sentence": "thank you for giving me this opportunity to speak",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	# Storytelling
	"oral_narrative": {
		"sentence": "once upon a time there lived a brave young hero",
		"min_confidence": 0.6,
		"max_attempts": 3
	},

	# ========================================
	# ORAL COMMUNICATION MODULE SPEECH RECOGNITION
	# ========================================

	# Module 1: Subject-Verb Agreement & Grammar
	"oralcom_m1_grammar_1": {
		"sentence": "she goes to school every day",
		"prompt": "Say the sentence using the correct verb form: 'She ___ (go) to school every day.'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m1_grammar_2": {
		"sentence": "yesterday i finished my homework",
		"prompt": "Say the sentence using the correct past tense: 'Yesterday, I ___ (finish) my homework.'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m1_grammar_3": {
		"sentence": "this gift is for me",
		"prompt": "Say the sentence using the correct pronoun: 'This gift is for ___.'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m1_grammar_4": {
		"sentence": "he is always on time",
		"prompt": "Rearrange and say the sentence correctly: 'always / on time / is / he'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m1_grammar_5": {
		"sentence": "she adopted an honest dog",
		"prompt": "Say the sentence using the correct article: 'She adopted ___ honest dog.'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},

	# Module 2: Models of Communication Grammar
	"oralcom_m2_grammar_1": {
		"sentence": "the linear model shows one way communication",
		"prompt": "Say the sentence correctly: 'The linear model ___ (show) one-way communication.'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m2_grammar_2": {
		"sentence": "the interactive model includes feedback",
		"prompt": "Say the sentence using the correct article: '___ interactive model includes feedback.'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m2_grammar_3": {
		"sentence": "the transactional model includes feedback",
		"prompt": "Arrange and say correctly: 'includes / transactional / feedback / model / the'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m2_grammar_4": {
		"sentence": "communication noise interrupts understanding",
		"prompt": "Say using correct present tense: 'Communication noise ___ (interrupt) understanding.'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m2_grammar_5": {
		"sentence": "feedback is important because it shows understanding",
		"prompt": "Complete and say: 'Feedback is important because ___.'",
		"min_confidence": 0.5,
		"max_attempts": 3
	},

	# Module 3: Avoiding Communication Breakdown Grammar
	"oralcom_m3_grammar_1": {
		"sentence": "clear communication helps avoid misunderstanding",
		"prompt": "Say correctly: 'Clear communication ___ (help) avoid misunderstanding.'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m3_grammar_2": {
		"sentence": "speakers should listen carefully to their audience",
		"prompt": "Say using correct modal verb: 'Speakers ___ listen carefully to their audience.'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m3_grammar_3": {
		"sentence": "asking for clarification prevents misunderstanding",
		"prompt": "Rearrange and say: 'asking / clarification / prevents / misunderstanding'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m3_grammar_4": {
		"sentence": "miscommunication occurs when the message is unclear",
		"prompt": "Say using correct present tense: 'Miscommunication ___ (occur) when the message is unclear.'",
		"min_confidence": 0.6,
		"max_attempts": 3
	},
	"oralcom_m3_grammar_5": {
		"sentence": "communication breakdown happens when the message is not understood",
		"prompt": "Complete and say: 'Communication breakdown happens when ___.'",
		"min_confidence": 0.5,
		"max_attempts": 3
	},

	# Module 4: Oral Communication Activities - Word Usage
	"oralcom_m4_word_storytelling": {
		"sentence": "storytelling helps share personal experiences with the audience",
		"prompt": "Use the word STORYTELLING in a sentence about oral communication.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m4_word_interview": {
		"sentence": "an interview allows people to ask and answer questions",
		"prompt": "Use the word INTERVIEW in a grammatically correct sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m4_word_debating": {
		"sentence": "debating helps students express their opinions clearly",
		"prompt": "Use the word DEBATING in a sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m4_word_reporting": {
		"sentence": "reporting shares important information with the audience",
		"prompt": "Use the word REPORTING in a sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m4_word_practice": {
		"sentence": "practice helps improve your oral communication skills",
		"prompt": "Use the word PRACTICE in a sentence about improving oral communication.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},

	# Module 5: Types of Speech Context - Word Usage
	"oralcom_m5_word_intrapersonal": {
		"sentence": "intrapersonal communication happens when i reflect on my own thoughts",
		"prompt": "Use INTRAPERSONAL in a sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m5_word_interpersonal": {
		"sentence": "interpersonal communication occurs when i talk with my friend",
		"prompt": "Use INTERPERSONAL in a sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m5_word_public": {
		"sentence": "public communication happens when the teacher speaks to the class",
		"prompt": "Use PUBLIC in a sentence about communication.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m5_word_mass": {
		"sentence": "mass communication reaches many people through television or radio",
		"prompt": "Use MASS in a sentence about communication.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m5_word_context": {
		"sentence": "the context of communication affects how the message is understood",
		"prompt": "Use CONTEXT in a sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m5_word_audience": {
		"sentence": "the speaker adjusts the speech based on the audience",
		"prompt": "Use AUDIENCE in a sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m5_word_feedback": {
		"sentence": "feedback helps the speaker know if the audience understands the message",
		"prompt": "Use FEEDBACK in a sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m5_word_formal": {
		"sentence": "formal communication is used during school presentations",
		"prompt": "Use FORMAL in a sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m5_word_informal": {
		"sentence": "informal communication happens when i chat with my classmates",
		"prompt": "Use INFORMAL in a sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	},
	"oralcom_m5_word_effective": {
		"sentence": "effective communication occurs when the message is clear and understood",
		"prompt": "Use EFFECTIVE in a sentence.",
		"min_confidence": 0.5,
		"max_attempts": 3
	}
}

# ========================================
# MATH MINIGAME CONFIGS - Grade 12 General Mathematics (Philippine Curriculum)
# ========================================

var math_configs = {
	# Quarter 1: Functions
	"math_q1_functions": {
		"questions": [
			{"question": "Evaluate f(x) = 3x - 5 when x = 4", "correct": "7", "wrong": ["12", "2", "17"]},
			{"question": "If f(x) = x² + 1, what is f(3)?", "correct": "10", "wrong": ["9", "8", "6"]},
			{"question": "What is the domain of f(x) = 1/(x-2)?", "correct": "x ≠ 2", "wrong": ["x > 2", "x < 2", "All real numbers"]},
			{"question": "If f(x) = 2x and g(x) = x + 3, find (f∘g)(2)", "correct": "10", "wrong": ["7", "8", "12"]},
			{"question": "What is the inverse of f(x) = 2x + 4?", "correct": "(x-4)/2", "wrong": ["2x-4", "x/2+4", "(x+4)/2"]}
		],
		"time_per_question": 20.0
	},
	"math_q1_inverse": {
		"questions": [
			{"question": "If f(x) = 3x - 6, find f⁻¹(x)", "correct": "(x+6)/3", "wrong": ["3x+6", "(x-6)/3", "x/3-6"]},
			{"question": "Is f(x) = x² one-to-one?", "correct": "No", "wrong": ["Yes", "Only for x>0", "Only for x<0"]},
			{"question": "The inverse of an exponential function is?", "correct": "Logarithmic", "wrong": ["Polynomial", "Rational", "Linear"]},
			{"question": "If f(f⁻¹(x)) = x, then the functions are?", "correct": "Inverses", "wrong": ["Equal", "Parallel", "Perpendicular"]},
			{"question": "Find f⁻¹(x) if f(x) = (x+1)/2", "correct": "2x - 1", "wrong": ["(x-1)/2", "2x + 1", "x/2 + 1"]}
		],
		"time_per_question": 25.0
	},

	# Quarter 2: Exponential and Logarithmic Functions
	"math_q2_exponential": {
		"questions": [
			{"question": "Simplify: 2³ × 2⁴", "correct": "128", "wrong": ["64", "256", "32"]},
			{"question": "What is log₁₀(1000)?", "correct": "3", "wrong": ["2", "4", "10"]},
			{"question": "Solve: 2ˣ = 16", "correct": "4", "wrong": ["3", "5", "8"]},
			{"question": "What is ln(e)?", "correct": "1", "wrong": ["0", "e", "2.718"]},
			{"question": "Simplify: log₂(8)", "correct": "3", "wrong": ["2", "4", "8"]}
		],
		"time_per_question": 20.0
	},
	"math_q2_logarithm": {
		"questions": [
			{"question": "log(ab) equals?", "correct": "log a + log b", "wrong": ["log a × log b", "log a - log b", "(log a)(log b)"]},
			{"question": "log(a/b) equals?", "correct": "log a - log b", "wrong": ["log a + log b", "log a / log b", "log(a-b)"]},
			{"question": "What is log₃(27)?", "correct": "3", "wrong": ["9", "2", "27"]},
			{"question": "Solve: log x = 2", "correct": "100", "wrong": ["20", "10", "1000"]},
			{"question": "log(aⁿ) equals?", "correct": "n log a", "wrong": ["log(na)", "a log n", "log a + n"]}
		],
		"time_per_question": 20.0
	},

	# Quarter 3: Trigonometry
	"math_q3_trigonometry": {
		"questions": [
			{"question": "What is sin(30°)?", "correct": "1/2", "wrong": ["√3/2", "√2/2", "1"]},
			{"question": "What is cos(60°)?", "correct": "1/2", "wrong": ["√3/2", "√2/2", "0"]},
			{"question": "What is tan(45°)?", "correct": "1", "wrong": ["0", "√2", "√3"]},
			{"question": "sin²θ + cos²θ equals?", "correct": "1", "wrong": ["0", "2", "sin 2θ"]},
			{"question": "What is the period of sin(x)?", "correct": "2π", "wrong": ["π", "π/2", "4π"]}
		],
		"time_per_question": 20.0
	},
	"math_q3_identities": {
		"questions": [
			{"question": "What is 1/sin(θ)?", "correct": "csc θ", "wrong": ["sec θ", "cot θ", "cos θ"]},
			{"question": "What is 1/cos(θ)?", "correct": "sec θ", "wrong": ["csc θ", "tan θ", "sin θ"]},
			{"question": "tan θ equals?", "correct": "sin θ/cos θ", "wrong": ["cos θ/sin θ", "1/sin θ", "1/cos θ"]},
			{"question": "cos(90° - θ) equals?", "correct": "sin θ", "wrong": ["cos θ", "tan θ", "-sin θ"]},
			{"question": "What is sin(0°)?", "correct": "0", "wrong": ["1", "-1", "undefined"]}
		],
		"time_per_question": 20.0
	},

	# Quarter 4: Statistics and Probability
	"math_q4_statistics": {
		"questions": [
			{"question": "The mean of 2, 4, 6, 8 is?", "correct": "5", "wrong": ["4", "6", "20"]},
			{"question": "The median of 1, 3, 5, 7, 9 is?", "correct": "5", "wrong": ["3", "7", "25"]},
			{"question": "The mode of 2, 3, 3, 4, 5 is?", "correct": "3", "wrong": ["2", "4", "17"]},
			{"question": "Range of 5, 10, 15, 20 is?", "correct": "15", "wrong": ["5", "10", "50"]},
			{"question": "Standard deviation measures?", "correct": "Spread", "wrong": ["Center", "Mode", "Range"]}
		],
		"time_per_question": 20.0
	},
	"math_q4_probability": {
		"questions": [
			{"question": "P(A) + P(not A) equals?", "correct": "1", "wrong": ["0", "2", "P(A)²"]},
			{"question": "Probability of rolling 6 on a die?", "correct": "1/6", "wrong": ["1/2", "1/3", "6"]},
			{"question": "If P(A) = 0.3 and P(B) = 0.4 (independent), P(A and B) = ?", "correct": "0.12", "wrong": ["0.7", "0.1", "0.34"]},
			{"question": "P(A or B) for mutually exclusive events?", "correct": "P(A) + P(B)", "wrong": ["P(A) × P(B)", "P(A) - P(B)", "P(A)/P(B)"]},
			{"question": "Coin flip: P(heads) = ?", "correct": "1/2", "wrong": ["1/4", "2/3", "1"]}
		],
		"time_per_question": 20.0
	}
}

# Hear and Fill pronunciation puzzle configs
var hear_and_fill_configs = {
	"wifi_router": {
		"sentence": "Sir, does this room have a dedicated ____ router?",
		"blank_word": "WiFi",
		"correct_index": 2,
		"choices": ["Hi-fi", "Sci-fi", "WiFi", "Bye-bye", "Fly high", "Sky high", "Pie-fry", "Why try"]
	},
	"anonymous_notes": {
		"sentence": "The students are receiving ____ notes that expose their secrets.",
		"blank_word": "anonymous",
		"correct_index": 0,
		"choices": ["anonymous", "unanimous", "anomalous", "enormous", "synonymous", "autonomous", "monotonous", "ominous"]
	},
	"observation_teaching": {
		"sentence": "B.C. teaches through ____ rather than direct instruction.",
		"blank_word": "observation",
		"correct_index": 0,
		"choices": ["observation", "conservation", "reservation", "conversation", "preservation", "consideration", "declaration", "confrontation"]
	},
	# ====================
	# MATH VARIANTS - Chapter 1
	# ====================
	"wifi_router_math": {
		"sentence": "To find the slope of a line, calculate the ____ over the run.",
		"blank_word": "rise",
		"correct_index": 2,
		"choices": ["price", "wise", "rise", "flies", "size", "prize", "cries", "ties"]
	},
	# ====================
	# SCIENCE VARIANTS - Chapter 1 (Motion and Forces)
	# ====================
	"wifi_router_science": {
		"sentence": "Newton's first law is also known as the law of ____.",
		"blank_word": "inertia",
		"correct_index": 1,
		"choices": ["criteria", "inertia", "bacteria", "cafeteria", "hysteria", "Nigeria", "Algeria", "Siberia"]
	},
	# ====================
	# MATH VARIANTS - Chapter 4
	# ====================
	"anonymous_notes_math": {
		"sentence": "The angle that measures exactly 90 degrees is called a ____ angle.",
		"blank_word": "right",
		"correct_index": 3,
		"choices": ["write", "bite", "sight", "right", "flight", "bright", "tight", "night"]
	},
	# ====================
	# SCIENCE VARIANTS - Chapter 4 (Electricity and Magnetism)
	# ====================
	"anonymous_notes_science": {
		"sentence": "Ohm's law relates voltage, ____, and resistance in electrical circuits.",
		"blank_word": "current",
		"correct_index": 4,
		"choices": ["currant", "torrent", "warrant", "errant", "current", "recurrent", "concurrent", "aberrant"]
	},
	# ====================
	# MATH VARIANTS - Chapter 5
	# ====================
	"observation_teaching_math": {
		"sentence": "In statistics, the ____ is the middle value when data is arranged in order.",
		"blank_word": "median",
		"correct_index": 5,
		"choices": ["comedian", "medium", "immediate", "media", "remedial", "median", "medicinal", "medieval"]
	},
	# ====================
	# SCIENCE VARIANTS - Chapter 5 (Waves, Light, Modern Physics)
	# ====================
	"observation_teaching_science": {
		"sentence": "Light exhibits both wave and particle properties, a concept called wave-particle ____.",
		"blank_word": "duality",
		"correct_index": 3,
		"choices": ["quality", "brutality", "finality", "duality", "fatality", "morality", "reality", "vitality"]
	}
}

# Riddle puzzle configs
var riddle_configs = {
	"bracelet_riddle": {
		"riddle": "Round I go, around your hand,\nI shine and sparkle, isn't that grand?",
		"answer": "BRACELET",
		"letters": ["B", "R", "A", "C", "E", "L", "E", "T", "W", "H", "V", "M", "K", "O", "I", "G"]
	},
	"receipt_riddle": {
		"riddle": "I am the sound of paper in motion, a quick motion of the wrist and hand. As I was ____ the pages, something fell out onto the land.",
		"answer": "FLIPPING",
		"letters": ["F", "L", "I", "P", "P", "I", "N", "G", "A", "S", "T", "R", "M", "O", "B", "W"]
	},
	# ====================
	# MATH VARIANTS - Chapter 1
	# ====================
	"bracelet_riddle_math": {
		"riddle": "I have four equal sides and four right angles,\nYou'll find me in geometry from all angles.",
		"answer": "SQUARE",
		"letters": ["S", "Q", "U", "A", "R", "E", "T", "I", "C", "L", "N", "G", "H", "O", "P", "M"]
	},
	# ====================
	# MATH VARIANTS - Chapter 3
	# ====================
	"receipt_riddle_math": {
		"riddle": "I grow without bounds, my base stays the same,\nRaised to a power is my claim to fame.\nIn growth and decay, I'm the function you'll see,\nWhat mathematical term could I be?",
		"answer": "EXPONENTIAL",
		"letters": ["E", "X", "P", "O", "N", "E", "N", "T", "I", "A", "L", "R", "G", "W", "H", "M"]
	},
	# ====================
	# SCIENCE VARIANTS - Chapter 1 (Motion and Forces)
	# ====================
	"bracelet_riddle_science": {
		"riddle": "I resist change in motion, that's my game,\nThe more mass you have, the more I remain.\nNewton's first law gave me my fame,\nWhat physics concept am I by name?",
		"answer": "INERTIA",
		"letters": ["I", "N", "E", "R", "T", "I", "A", "F", "O", "C", "M", "S", "V", "L", "G", "H"]
	},
	# ====================
	# SCIENCE VARIANTS - Chapter 3 (Work, Energy, Power)
	# ====================
	"receipt_riddle_science": {
		"riddle": "I cannot be created, nor destroyed,\nOnly transformed in the cosmic void.\nFrom potential to kinetic I flow,\nWhat fundamental principle do I show?",
		"answer": "ENERGY",
		"letters": ["E", "N", "E", "R", "G", "Y", "F", "O", "W", "K", "P", "T", "M", "A", "I", "L"]
	}
}

# Detective Analysis configs (Context-integrated Math/Science minigames)
var detective_analysis_configs = {
	# ====================
	# CHAPTER 1 - MATH: Timeline Analysis
	# ====================
	# ====================
	# CHAPTER 1 - SCIENCE: Evaporation Analysis
	# ====================
	"evaporation_analysis_science": {
		"title": "Forensic Science: Evaporation Analysis",
		"context": "The janitor mopped the hallway floor at 3:00 PM. Fresh footprints lead to the faculty room. The janitor says the floor dries completely in 45 minutes in this 60% humidity. You notice the prints still have slight moisture.",
		"question": "[b]Question:[/b] If water evaporates at a rate of 0.5 mm/hour in 60% humidity, and 0.25mm of moisture remains in the footprints, approximately when were these prints made?",
		"choices": [
			"3:30 PM (30 minutes ago)",
			"3:15 PM (45 minutes ago)",
			"3:45 PM (15 minutes ago)",
			"2:45 PM (1 hour 15 minutes ago)"
		],
		"correct_index": 0,
		"explanation": "[b]Physics Solution:[/b]\n• Rate: 0.5 mm/hour\n• Moisture: 0.25 mm remaining\n• Time = 0.25 ÷ 0.5 = 0.5 hours = [b]30 minutes[/b]\n• Footprints made: 4:00 PM - 30 min = [b]3:30 PM[/b]\n\n[color=yellow]Someone entered the faculty room at 3:30 PM![/color]"
	},

	# ====================
	# CHAPTER 2 - MATH: Ratio Analysis (Fund Calculation)
	# ====================
	"fund_analysis_math": {
		"title": "Financial Analysis",
		"context": "The Student Council fund had ₱20,000. Records show that 40% was allocated for supplies, 35% for events, and the rest for emergency funds. But the lockbox is completely empty.",
		"question": "[b]Question:[/b] How much money should have been in the emergency fund portion?",
		"choices": [
			"₱5,000 (25% of ₱20,000)",
			"₱7,000 (35% of ₱20,000)",
			"₱8,000 (40% of ₱20,000)",
			"₱4,000 (20% of ₱20,000)"
		],
		"correct_index": 0,
		"explanation": "[b]Correct Answer: ₱5,000[/b]\n\n[b]Solution:[/b]\nSupplies: 40%\nEvents: 35%\nEmergency: 100% - 40% - 35% = 25%\n\nEmergency fund = 25% of ₱20,000\nEmergency fund = 0.25 × ₱20,000 = [b]₱5,000[/b]\n\n[b]Detective Conclusion:[/b] The thief took the entire ₱20,000, including the ₱5,000 emergency fund."
	},

	# ====================
	# CHAPTER 2 - SCIENCE: Fingerprint Analysis
	# ====================
	"fingerprint_analysis_science": {
		"title": "Forensic Science: Fingerprint Classification",
		"context": "You found partial fingerprints on the lockbox. Fingerprints are classified by their ridge patterns. The print shows a triangular pattern where ridges flow inward from both sides.",
		"question": "[b]Question:[/b] Based on the ridge pattern description, what type of fingerprint is this?",
		"choices": [
			"Loop pattern (ridges flow in one direction)",
			"Whorl pattern (circular ridges)",
			"Tented Arch pattern (ridges meet at center forming triangle)",
			"Plain Arch pattern (ridges flow smoothly across)"
		],
		"correct_index": 2,
		"explanation": "[b]Correct Answer: Tented Arch[/b]\n\n[b]Fingerprint Science:[/b]\n• [b]Loop:[/b] Ridges enter from one side and exit same side (60-65% of population)\n• [b]Whorl:[/b] Circular/spiral patterns (30-35% of population)\n• [b]Tented Arch:[/b] Ridges meet at center forming triangular tent (4-5% of population)\n• [b]Plain Arch:[/b] Ridges flow smoothly across without meeting (~5% of population)\n\n[b]Detective Conclusion:[/b] The triangular pattern indicates a rare Tented Arch, helping narrow down suspects."
	},

	# ====================
	# CHAPTER 3 - MATH: Area Calculation (Vandalism Scene)
	# ====================
	"paint_area_math": {
		"title": "Geometry: Area Analysis",
		"context": "The vandalized sculpture 'The Reader' has paint splattered on its base. The base is rectangular, measuring 2.5 meters by 1.8 meters. Paint covers approximately 60% of the base area.",
		"question": "[b]Question:[/b] What is the approximate area covered by paint?",
		"choices": [
			"2.7 square meters (60% of 4.5 m²)",
			"3.2 square meters (60% of 5.3 m²)",
			"4.5 square meters (100% of base)",
			"1.8 square meters (40% of 4.5 m²)"
		],
		"correct_index": 0,
		"explanation": "[b]Correct Answer: 2.7 m²[/b]\n\n[b]Solution:[/b]\nBase area = length × width\nBase area = 2.5 m × 1.8 m = 4.5 m²\n\nPaint coverage = 60% of base area\nPaint coverage = 0.60 × 4.5 m² = [b]2.7 m²[/b]\n\n[b]Detective Conclusion:[/b] The vandal used approximately 2.7 square meters worth of paint, suggesting a deliberate, extensive act of vandalism."
	},

	# ====================
	# CHAPTER 3 - SCIENCE: Energy Analysis (Falling Sculpture)
	# ====================
	"energy_analysis_science": {
		"title": "Physics: Potential Energy",
		"context": "The broken sculpture fell from a pedestal 2 meters high. The sculpture has a mass of 15 kg. You need to determine if it fell accidentally or was pushed with force.",
		"question": "[b]Question:[/b] What was the potential energy of the sculpture before it fell? (Use g = 10 m/s²)",
		"choices": [
			"300 Joules (PE = mgh = 15×10×2)",
			"150 Joules (PE = 15×10×1)",
			"200 Joules (PE = 10×10×2)",
			"450 Joules (PE = 15×15×2)"
		],
		"correct_index": 0,
		"explanation": "[b]Correct Answer: 300 Joules[/b]\n\n[b]Solution:[/b]\nPotential Energy (PE) = mass × gravity × height\nPE = m × g × h\nPE = 15 kg × 10 m/s² × 2 m\nPE = [b]300 Joules[/b]\n\n[b]Detective Conclusion:[/b] The sculpture had 300 J of potential energy. When it fell, this converted to kinetic energy, causing significant damage upon impact. The energy calculation helps determine if external force was applied."
	},

	# ====================
	# CHAPTER 4 - MATH: Probability Analysis (Anonymous Notes)
	# ====================
	"probability_analysis_math": {
		"title": "Statistics: Probability Calculation",
		"context": "Five students received anonymous notes: Ben, Sarah, Tom, Lisa, and Jake. Only 3 students have access to the school archive after hours: Alex, Ben, and Sarah. What is the probability that the sender is one of the students who received a note?",
		"question": "[b]Question:[/b] If the sender must have archive access, what is the probability they also received a note?",
		"choices": [
			"2/3 or 66.7% (Ben and Sarah are both targets and have access)",
			"3/5 or 60% (3 out of 5 received notes)",
			"1/2 or 50% (Random chance)",
			"1/3 or 33.3% (Only one person fits)"
		],
		"correct_index": 0,
		"explanation": "[b]Correct Answer: 2/3 or 66.7%[/b]\n\n[b]Solution:[/b]\nStudents with archive access: Alex, Ben, Sarah (3 total)\nStudents who received notes: Ben, Sarah, Tom, Lisa, Jake (5 total)\n\nOverlap (access AND received note): Ben, Sarah (2 people)\n\nProbability = (People with both) ÷ (People with access)\nProbability = 2 ÷ 3 = [b]2/3 ≈ 66.7%[/b]\n\n[b]Detective Conclusion:[/b] There's a 66.7% chance the sender is someone who also received a note, suggesting possible self-targeting or insider knowledge."
	},

	# ====================
	# CHAPTER 4 - SCIENCE: Electricity Analysis (Computer Lab)
	# ====================
	"electricity_analysis_science": {
		"title": "Physics: Electrical Power",
		"context": "The anonymous notes were printed in the computer lab. The printer draws 5 Amperes of current at 220 Volts. It was used for 30 minutes (0.5 hours) to print the notes.",
		"question": "[b]Question:[/b] How much electrical energy (in kilowatt-hours) did the printer consume?",
		"choices": [
			"0.55 kWh (P=VI=1100W, E=1.1kW×0.5h)",
			"1.1 kWh (P=220×5=1100W for 1 hour)",
			"0.25 kWh (P=500W for 0.5h)",
			"2.2 kWh (P=220×5×2)"
		],
		"correct_index": 0,
		"explanation": "[b]Correct Answer: 0.55 kWh[/b]\n\n[b]Solution:[/b]\nPower (P) = Voltage (V) × Current (I)\nP = 220 V × 5 A = 1100 Watts = 1.1 kW\n\nEnergy (E) = Power (P) × Time (t)\nE = 1.1 kW × 0.5 hours = [b]0.55 kWh[/b]\n\n[b]Detective Conclusion:[/b] The printer used 0.55 kilowatt-hours of energy. By checking the computer lab's power logs, we can confirm the time the printer was used."
	},

	# ====================
	# CHAPTER 4 - SCIENCE: Teaching Power Analysis (Archive)
	# ====================
	"teaching_power_analysis_science": {
		"title": "Physics: Power and Energy Transfer",
		"context": "Alex studied the 1990s teaching journal for 6 hours total, then spent 3 hours writing notes. She distributed 6 notes in 48 hours. The journal contained concentrated 'teaching energy' built up over 3 years (1992-1995).",
		"question": "[b]Question:[/b] If Alex transferred the journal's teaching methods at a rate of 2 notes per day, what was her average 'teaching power' (notes/hour)?",
		"choices": [
			"0.125 notes/hour (6 notes ÷ 48 hours)",
			"2 notes/hour (rate of writing)",
			"0.5 notes/hour (6 notes ÷ 12 hours)",
			"3 notes/hour (total time ÷ days)"
		],
		"correct_index": 0,
		"explanation": "[b]Correct Answer: 0.125 notes/hour[/b]\n\n[b]Physics Solution:[/b]\nPower (P) = Work (W) / Time (t)\n• Work done: 6 notes created and distributed\n• Time taken: 48 hours (2 days)\n• Power = 6 notes ÷ 48 hours = [b]0.125 notes/hour[/b]\n\n[b]Alternative calculation:[/b]\n• Rate per day: 2 notes/day ÷ 24 hours/day = 0.083 notes/hour average\n• But concentrated distribution: 6 notes in 48 hours = 0.125 notes/hour\n\n[b]Energy Transfer Analogy:[/b]\n• [b]Source (Journal):[/b] 3 years of teaching experience (high potential energy)\n• [b]Converter (Alex):[/b] 6 hours reading + 3 hours writing = 9 hours total work\n• [b]Output (Notes):[/b] 6 notes distributed at 0.125 notes/hour average power\n• [b]Efficiency:[/b] Low! Much energy lost in translation (misunderstood wisdom)\n\n[b]Ohm's Law Connection:[/b]\nPower = Voltage × Current (P = VI)\n• Alex's 'voltage' (motivation) was high but 'current' (understanding) was low\n• Result: Power transferred, but without wisdom = harmful output\n\n[b]Detective Conclusion:[/b] Alex had the power to teach but lacked the resistance (ethical understanding) to use it wisely. Raw power without control causes damage!"
	},

	# ====================
	# CHAPTER 5 - MATH: Pattern Recognition (B.C. Card Sequence)
	# ====================
	"pattern_recognition_math": {
		"title": "Mathematical Patterns",
		"context": "The B.C. cards appeared after solving cases. Card 1 appeared after 1 case, Card 2 after 2 cases, Card 3 after 3 cases, Card 4 after 4 cases. A 5th mystery remains unsolved.",
		"question": "[b]Question:[/b] If the pattern continues, how many total cases must be solved to receive all 5 cards?",
		"choices": [
			"15 cases (Sum of sequence 1+2+3+4+5)",
			"10 cases (2×5)",
			"25 cases (5²)",
			"5 cases (One per card)"
		],
		"correct_index": 0,
		"explanation": "[b]Correct Answer: 15 cases[/b]\n\n[b]Solution:[/b]\nPattern: Card N appears after N cases\nTotal cases = 1 + 2 + 3 + 4 + 5\n\nUsing sum formula: Sum = n(n+1)/2\nSum = 5(5+1)/2 = 5(6)/2 = [b]15 cases[/b]\n\nAlternatively: 1+2+3+4+5 = 15\n\n[b]Detective Conclusion:[/b] B.C. has been observing and teaching through 15 total cases across all chapters. This reveals a deliberate, long-term mentorship pattern."
	},

	# ====================
	# CHAPTER 5 - SCIENCE: Light and Optics (Theater Stage)
	# ====================
	"light_analysis_science": {
		"title": "Physics: Light and Optics",
		"context": "B.C. left a prism on the theater stage that splits white light into a spectrum. The prism has a refractive index of 1.5. Light enters at one angle and bends as it passes through.",
		"question": "[b]Question:[/b] What phenomenon is demonstrated when white light splits into colors through a prism?",
		"choices": [
			"Reflection (light bouncing off surfaces)",
			"Diffraction (light bending around edges)",
			"Dispersion (different wavelengths refract at different angles)",
			"Absorption (light being absorbed by materials)"
		],
		"correct_index": 2,
		"explanation": "[b]Correct Answer: Dispersion[/b]\n\n[b]Light Science:[/b]\n• [b]Dispersion:[/b] White light separates into its component colors (ROYGBIV) because each wavelength refracts at a slightly different angle\n• Red light (long wavelength) bends least\n• Violet light (short wavelength) bends most\n• Refractive index determines bending amount\n\n[b]Detective Conclusion:[/b] B.C. used this prism as a metaphor - just as white light contains many colors, truth contains many perspectives. A teacher helps students see the full spectrum."
	}
}

# Dialogue Choice (Speech-to-Text) configs
var dialogue_choice_configs = {
	"dialogue_choice_janitor": {
		"question": "How do you politely ask the janitor for help?",
		"choices": [
			"Excuse me, sir sorry to interrupt, but may I quickly check under my desk for something I left",
			"Good afternoon, sir have you seen any unusual item while cleaning this room?",
			"Hi sir, I can help move the chairs, and by the way, did you see a small item I dropped near here",
			"Sir, did anyone turn in a lost item from this classroom today"
		],
		"correct_index": 1  # Choice 2 (0-indexed)
	},
	"dialogue_choice_ria_note": {
		"question": "Why didn't Ria tell anyone about the note?",
		"choices": [
			"She feared it would make her look guilty.",
			"She fear it make her guilty.",
			"She was fear to look guilty.",
			"She fearing it made her guilty."
		],
		"correct_index": 0  # Choice 1 (A)
	},
	"dialogue_choice_cruel_note": {
		"question": "Which sentence is grammatically correct and clearly states an observation?",
		"choices": [
			"They left evidence.",
			"They leaving evidence.",
			"Evidence left they.",
			"They was left evidence."
		],
		"correct_index": 0  # Choice A
	},
	"dialogue_choice_approach_suspect": {
		"question": "How should Conrad approach Alex, who might be sending the anonymous notes?",
		"choices": [
			"We should confront her directly and ask if she's been sending the notes.",
			"We should observe her behavior carefully before making assumptions about her intentions.",
			"We should report her to the principal immediately based on the archive access log.",
			"We should ignore the evidence and look for other suspects instead."
		],
		"correct_index": 1  # Choice 2 (0-indexed) - Observe carefully before assumptions
	},
	"dialogue_choice_bc_approach": {
		"question": "How should Conrad approach B.C., the mysterious teacher who has been guiding him?",
		"choices": [
			"Enter respectfully and thank them for the lessons they have taught through the cards.",
			"Demand answers about why they manipulated events and left cryptic messages.",
			"Accuse them of watching students secretly and interfering with school affairs.",
			"Ignore their presence and examine the evidence they left on the stage first."
		],
		"correct_index": 0  # Choice 1 (A) - Respectful gratitude, understanding guidance not manipulation
	},
	# ====================
	# MATH VARIANTS - Chapter 1
	# ====================
	"dialogue_choice_janitor_math": {
		"question": "Conrad needs to calculate the average of Greg's three exam scores: 75, 82, and 88. What is the correct method?",
		"choices": [
			"Add all three scores and divide by three to get the mean",
			"Multiply the three scores and divide by three",
			"Add the highest and lowest scores only",
			"Subtract the lowest from the highest and divide by two"
		],
		"correct_index": 0  # Choice 1 - Correct averaging formula
	},
	# ====================
	# MATH VARIANTS - Chapter 2
	# ====================
	"dialogue_choice_ria_note_math": {
		"question": "The lockbox contained 20,000 pesos divided into 100, 500, and 1000 peso bills. If there are 8 bills of 1000, 12 bills of 500, and the rest are 100 peso bills, how many 100 peso bills are there?",
		"choices": [
			"Subtract (8×1000 + 12×500) from 20000, then divide by 100",
			"Add 8, 12, and 100, then multiply by 1000",
			"Multiply 8 by 1000 and divide by 100",
			"Divide 20000 by 100 and subtract 8 and 12"
		],
		"correct_index": 0  # Choice 1 - (20000 - 8000 - 6000) / 100 = 60
	},
	# ====================
	# MATH VARIANTS - Chapter 3
	# ====================
	"dialogue_choice_cruel_note_math": {
		"question": "Conrad finds paint stains on the cloth at different times. If the first stain was made 2 hours ago and each subsequent stain was made in half the time of the previous one, how long ago was the 4th stain made?",
		"choices": [
			"Divide 2 by 2 three times: 2, 1, 0.5, 0.25 hours (15 minutes ago)",
			"Multiply 2 by 0.5 four times to get 0.25 hours",
			"Subtract 0.5 from 2 four times",
			"Add 2 plus 1 plus 0.5 to get 3.5 hours"
		],
		"correct_index": 0  # Exponential decay pattern: 2 → 1 → 0.5 → 0.25
	},
	# ====================
	# MATH VARIANTS - Chapter 4
	# ====================
	"dialogue_choice_approach_suspect_math": {
		"question": "Conrad notices a pattern in when the anonymous notes were delivered. If the angle between the library and the archive on a map is 45 degrees, and Conrad walks along the hypotenuse of this right triangle, which trigonometric ratio should he use to calculate the shortest path?",
		"choices": [
			"Use sine to find the opposite side divided by the hypotenuse",
			"Use cosine to find the adjacent side divided by the hypotenuse, then apply the Pythagorean theorem",
			"Use tangent to find the ratio of opposite to adjacent sides",
			"Multiply the angle by pi and divide by 180 to convert to radians first"
		],
		"correct_index": 1  # Cosine approach for finding adjacent side in navigation
	},
	# ====================
	# MATH VARIANTS - Chapter 5
	# ====================
	"dialogue_choice_bc_approach_math": {
		"question": "Conrad collected data from all 5 B.C. cards. If the mean time between cards was 8 days with a standard deviation of 2 days, what does this tell him about the pattern?",
		"choices": [
			"The pattern is consistent with most cards appearing within 6-10 days of each other",
			"The pattern is random with no predictable timing",
			"All cards appeared exactly 8 days apart with no variation",
			"The standard deviation being 2 means the cards were 2 days late on average"
		],
		"correct_index": 0  # Understanding mean and standard deviation: most values within 1 SD of mean
	},
	# ====================
	# SCIENCE VARIANTS - Chapter 1 (Motion and Forces)
	# ====================
	"dialogue_choice_janitor_science": {
		"question": "Conrad analyzes the bracelet's motion when it fell. If it fell from rest and hit the ground after 1 second, what is the correct physics principle?",
		"choices": [
			"The bracelet accelerated at approximately 10 meters per second squared due to gravity",
			"The bracelet fell at a constant speed of 10 meters per second throughout",
			"The bracelet's mass determined how fast it fell to the ground",
			"The bracelet experienced no force during its fall"
		],
		"correct_index": 0  # Free fall acceleration = 10 m/s² (or 9.8)
	},
	# ====================
	# SCIENCE VARIANTS - Chapter 2 (Motion and Forces continued)
	# ====================
	"dialogue_choice_ria_note_science": {
		"question": "If Ria pushed the lockbox across a table with 50 Newtons of force and it accelerated at 5 m/s², what was the box's mass?",
		"choices": [
			"Use Newton's second law: divide force by acceleration to get 10 kilograms",
			"Multiply force by acceleration to get 250 kilograms",
			"Add force and acceleration to get 55 kilograms",
			"Subtract acceleration from force to get 45 kilograms"
		],
		"correct_index": 0  # F = ma, so m = F/a = 50/5 = 10 kg
	},
	# ====================
	# SCIENCE VARIANTS - Chapter 3 (Work, Energy, Power)
	# ====================
	"dialogue_choice_cruel_note_science": {
		"question": "Victor lifted his paint supplies 2 meters high. If the supplies weighed 5 kilograms and gravity is 10 m/s², how much potential energy did they gain?",
		"choices": [
			"Multiply mass, gravity, and height: 5 × 10 × 2 equals 100 Joules",
			"Add mass, gravity, and height: 5 + 10 + 2 equals 17 Joules",
			"Divide mass by gravity and multiply by height to get 1 Joule",
			"Multiply mass by height only to get 10 Joules"
		],
		"correct_index": 0  # PE = mgh = 5 × 10 × 2 = 100 J
	},
	# ====================
	# SCIENCE VARIANTS - Chapter 4 (Electricity and Magnetism)
	# ====================
	"dialogue_choice_approach_suspect_science": {
		"question": "Conrad finds that the library's computer uses 120 Watts of power and runs on 24 Volts. What current does it draw?",
		"choices": [
			"Divide power by voltage to get 5 Amperes using P equals V times I",
			"Multiply power by voltage to get 2880 Amperes",
			"Subtract voltage from power to get 96 Amperes",
			"Add power and voltage to get 144 Amperes"
		],
		"correct_index": 0  # P = VI, so I = P/V = 120/24 = 5 A
	},
	# ====================
	# SCIENCE VARIANTS - Chapter 5 (Waves, Light, Modern Physics)
	# ====================
	"dialogue_choice_bc_approach_science": {
		"question": "Conrad observes light patterns in the auditorium. If a wave has a frequency of 5 Hertz and a wavelength of 3 meters, what is its speed?",
		"choices": [
			"Multiply frequency by wavelength to get 15 meters per second using wave equation v equals f lambda",
			"Divide frequency by wavelength to get 1.67 meters per second",
			"Add frequency and wavelength to get 8 meters per second",
			"Subtract wavelength from frequency to get 2 meters per second"
		],
		"correct_index": 0  # v = fλ = 5 × 3 = 15 m/s
	}
}

# ====================
# LOGIC GRID PUZZLE CONFIGURATIONS
# ====================
var logic_grid_configs = {
	# Chapter 1 - Suspect Locations (Math focus: Set theory, logical elimination)
	"logic_grid_alibi_math": {
		"title": "Alibi Verification Grid",
		"context": "Use the clues to deduce where each suspect was during the theft.",
		"rows": ["Greg", "Ben", "Alex"],
		"cols": ["Library", "Cafeteria", "Gym"],
		"clues": [
			"Greg was NOT in the library",
			"The person in the gym arrived before 3:30 PM",
			"Ben was studying in a quiet place",
			"Alex was seen near the cafeteria at 3:15 PM"
		],
		"solution": {
			"Greg": "Gym",
			"Ben": "Library",
			"Alex": "Cafeteria"
		},
		"explanation": "[b]Logical Deduction:[/b]\n• Greg ≠ Library (Clue 1)\n• Ben = Library (Clue 3: quiet place)\n• Alex = Cafeteria (Clue 4)\n• Greg = Gym (only remaining option)\n\nThis uses set elimination, a key mathematical reasoning skill."
	},
	# Chapter 1, Scene 3 - WiFi Connection Analysis (Math focus: Set theory, time intervals)
	"logic_grid_wifi_math": {
		"title": "WiFi Connection Analysis",
		"context": "Two devices connected to Faculty WiFi yesterday evening. Use logical deduction to match devices to students.",
		"rows": ["Ben", "Greg", "Alex"],
		"cols": ["8:00 PM", "9:00 PM", "Not Connected"],
		"clues": [
			"Ben went back to retrieve his pen after the library closed (8:00 PM)",
			"A teacher let Ben in and watched him leave quickly",
			"Greg's connection time was later in the evening",
			"Alex has an alibi - she was at home with her family"
		],
		"solution": {
			"Ben": "8:00 PM",
			"Greg": "9:00 PM",
			"Alex": "Not Connected"
		},
		"explanation": "[b]Set Theory & Logic:[/b]\n• Ben ∈ {8:00 PM} (Clue 1 + 2)\n• Alex ∉ {Connected devices} (Clue 4: alibi)\n• Greg ∈ {9:00 PM} (only remaining connection time)\n\nUsing set membership and elimination systematically identifies suspects."
	},
	# Chapter 2 - Blackmail Plan Analysis (Math focus: Logical sequences, inequalities)
	"logic_grid_blackmail_math": {
		"title": "Blackmail Plan Deduction",
		"context": "Ryan planned each step carefully. Match each action to the correct time period using logical reasoning.",
		"rows": ["Write Note", "Steal Money", "Frame Ria"],
		"cols": ["Day 1", "Day 3", "Day 7"],
		"clues": [
			"The note was written before any theft occurred",
			"Framing Ria happened on the same day as the theft",
			"The theft occurred exactly 7 days after planning began",
			"Writing the note was the first step"
		],
		"solution": {
			"Write Note": "Day 1",
			"Steal Money": "Day 7",
			"Frame Ria": "Day 7"
		},
		"explanation": "[b]Sequential Logic (Math):[/b]\n• Write Note < Steal Money (Clue 1: ordering)\n• Frame Ria = Steal Money (Clue 2: equality)\n• Steal Money = Day 7 (Clue 3: specific value)\n• Write Note = Day 1 (Clue 4: first action)\n\nThis uses inequalities (>, <, =) and logical ordering to solve the sequence."
	},
	# Chapter 2, Scene 4 - Energy Transfer Analysis (Science focus: Work, Energy, Power - Q2)
	"logic_grid_blackmail_science": {
		"title": "Energy Transfer Analysis",
		"context": "Ryan's blackmail plan involved different forms of energy transfer. Match each action to the primary energy type involved.",
		"rows": ["Writing Note", "Stealing Money", "Running Away"],
		"cols": ["Chemical Energy", "Potential Energy", "Kinetic Energy"],
		"clues": [
			"Writing requires muscle energy from food (ATP breakdown)",
			"Lifting the lockbox from desk to bag involves height change",
			"Running away converts stored energy into motion",
			"Kinetic energy = ½mv² relates to velocity"
		],
		"solution": {
			"Writing Note": "Chemical Energy",
			"Stealing Money": "Potential Energy",
			"Running Away": "Kinetic Energy"
		},
		"explanation": "[b]Physics: Energy Types (Q2)[/b]\n\n• [b]Chemical Energy → Work:[/b]\n  - Muscles use ATP (adenosine triphosphate)\n  - Chemical bonds break to release energy\n  - Energy transfers to pen motion (writing)\n\n• [b]Potential Energy (PE = mgh):[/b]\n  - Lockbox lifted to bag height (Δh)\n  - Mass (m) × gravity (g) × height (h)\n  - Energy stored in elevated position\n\n• [b]Kinetic Energy (KE = ½mv²):[/b]\n  - Running increases velocity (v)\n  - Mass in motion has kinetic energy\n  - Energy proportional to velocity squared\n\n[b]Energy Conservation:[/b] Chemical → Kinetic → Potential\nAll criminal actions involve energy transformations! Understanding energy helps reconstruct the crime sequence."
	},
	# Chapter 3, Scene 1 - Evidence Pattern Analysis (Math focus: Pattern recognition, categorical logic)
	"logic_grid_evidence_math": {
		"title": "Evidence Pattern Analysis",
		"context": "Three pieces of evidence were found at the vandalism scene. Match each evidence type to its characteristic using logical deduction.",
		"rows": ["Cruel Note", "Paint Cloth", "Timing"],
		"cols": ["Emotional", "Physical", "Temporal"],
		"clues": [
			"The note contains emotional language showing jealousy",
			"Physical evidence was left behind at the scene",
			"The timing of events creates a pattern",
			"The cloth is a tangible object with paint stains"
		],
		"solution": {
			"Cruel Note": "Emotional",
			"Paint Cloth": "Physical",
			"Timing": "Temporal"
		},
		"explanation": "[b]Categorical Logic (Math):[/b]\n• Evidence ∈ {Emotional, Physical, Temporal} (three categories)\n• Cruel Note → Emotional (Clue 1: language analysis)\n• Paint Cloth → Physical (Clue 4: tangible object)\n• Timing → Temporal (Clue 3: time-based pattern)\n\nThis uses categorical classification and one-to-one mapping, where each element from one set corresponds to exactly one element in another set - a fundamental concept in functions and relations."
	},
	# Chapter 3, Scene 1 - Work and Energy Analysis (Science focus: Work, Energy, Power - Q3)
	"logic_grid_evidence_science": {
		"title": "Vandalism Energy Analysis",
		"context": "The vandalism required different forms of work and energy. Match each action to the primary physics concept involved.",
		"rows": ["Pushing Sculpture", "Spray Painting", "Running Away"],
		"cols": ["Work (W=Fd)", "Power (P=W/t)", "Kinetic Energy"],
		"clues": [
			"Pushing the heavy sculpture required force over distance",
			"Spray painting happened quickly - energy transferred per unit time",
			"Running away involved mass in motion with velocity",
			"Power measures how fast work is done (watts = joules/second)"
		],
		"solution": {
			"Pushing Sculpture": "Work (W=Fd)",
			"Spray Painting": "Power (P=W/t)",
			"Running Away": "Kinetic Energy"
		},
		"explanation": "[b]Physics: Work, Energy, Power (Q3)[/b]\n\n• [b]Work (W = F × d):[/b]\n  - Force applied to push sculpture\n  - Sculpture moved distance (d)\n  - W = Force × displacement\n  - Unit: Joules (J)\n\n• [b]Power (P = W/t):[/b]\n  - Spray painting done quickly\n  - Energy transferred per second\n  - P = Work / time\n  - Unit: Watts (W = J/s)\n\n• [b]Kinetic Energy (KE = ½mv²):[/b]\n  - Victor running has velocity (v)\n  - Mass in motion stores energy\n  - Proportional to v² (doubling speed = 4× energy)\n\n[b]Energy Conservation:[/b] Victor's chemical energy (muscles) → Work (pushing) → Kinetic energy (running)\nEvery criminal action follows physics laws!"
	},
	# Chapter 2 - Fund Allocation (Science focus: Hypothesis elimination)
	"logic_grid_funds_science": {
		"title": "Fund Allocation Analysis",
		"context": "Match each project to its allocated fund amount using scientific deduction.",
		"rows": ["Art Week", "Sports Day", "Science Fair"],
		"cols": ["5000 pesos", "8000 pesos", "12000 pesos"],
		"clues": [
			"Science Fair received more than Sports Day",
			"Art Week did NOT receive the smallest amount",
			"Sports Day received exactly 5000 pesos",
			"The largest fund went to a creative project"
		],
		"solution": {
			"Art Week": "12000 pesos",
			"Sports Day": "5000 pesos",
			"Science Fair": "8000 pesos"
		},
		"explanation": "[b]Scientific Method Applied:[/b]\n• Hypothesis 1: Sports Day = 5000 (Clue 3) ✓\n• Hypothesis 2: Science Fair > 5000 (Clue 1) ✓\n• Hypothesis 3: Art Week = 12000 (Clue 2 + 4) ✓\n• Remaining: Science Fair = 8000 ✓\n\nSystematic elimination mimics scientific reasoning."
	},
	# Chapter 4, Scene 2 - Information Circuit Analysis (Science focus: Electricity, circuits - Q4)
	"logic_grid_information_circuit_science": {
		"title": "Information Circuit Analysis",
		"context": "The note distribution system works like an electrical circuit. Match each student's role to the electrical component they represent.",
		"rows": ["Alex (Source)", "Locker System", "Students (Recipients)"],
		"cols": ["Battery/EMF", "Conductors", "Resistors"],
		"clues": [
			"Alex provides the 'energy' (information) that flows through the system",
			"The locker system allows information to travel from source to recipients",
			"Students receiving notes act like resistors - they convert and respond to the energy",
			"Ohm's Law: V = IR (Voltage = Current × Resistance)"
		],
		"solution": {
			"Alex (Source)": "Battery/EMF",
			"Locker System": "Conductors",
			"Students (Recipients)": "Resistors"
		},
		"explanation": "[b]Physics: Electrical Circuits (Q4)[/b]\n\n• [b]Battery/EMF (Alex):[/b]\n  - Source of energy (electromotive force)\n  - Creates 'voltage' (motivation to spread notes)\n  - Drives current through circuit\n  - Maintains potential difference\n\n• [b]Conductors (Locker System):[/b]\n  - Low resistance pathway\n  - Allows charge (information) to flow\n  - Connects source to load\n  - Made of conductive material (accessible lockers)\n\n• [b]Resistors (Students):[/b]\n  - Convert electrical energy to other forms\n  - Provide resistance to current flow\n  - V = IR (Ohm's Law)\n  - Power dissipated: P = I²R or P = V²/R\n\n[b]Circuit Analysis:[/b]\nWhen students reported notes (increased R), current decreased (fewer distributions). When investigation started (circuit broken), current stopped completely!\n\n[b]Ohm's Law Application:[/b] Higher resistance → Lower current → Investigation success!"
	},
	# Chapter 4, Scene 2 - Suspect Behavior Analysis (Math focus: Logic, conditional statements)
	"logic_grid_suspect_behavior_math": {
		"title": "Suspect Behavior Deduction",
		"context": "Three students are suspects. Match each student to their behavior pattern using logical reasoning.",
		"rows": ["Alex", "Ben", "Alice"],
		"cols": ["Archive Access", "Note Witness", "Uninvolved"],
		"clues": [
			"Ben witnessed someone receiving a note but didn't report it",
			"Alice was not involved in any way",
			"The person with archive access is the key to solving this case",
			"Alex is NOT uninvolved"
		],
		"solution": {
			"Alex": "Archive Access",
			"Ben": "Note Witness",
			"Alice": "Uninvolved"
		},
		"explanation": "[b]Logical Deduction (Math):[/b]\n• Ben = Note Witness (Clue 1: direct statement)\n• Alice = Uninvolved (Clue 2: direct statement)\n• Alex ≠ Uninvolved (Clue 4: negation)\n• Alex ≠ Note Witness (already assigned to Ben)\n• Therefore: Alex = Archive Access (only remaining option)\n\nThis uses conditional logic and proof by elimination - if all other options are false, the remaining must be true."
	},
	# Chapter 4, Scene 3 - Teaching Methods Analysis (Math focus: Venn diagrams, set relationships)
	"logic_grid_pedagogy_math": {
		"title": "Teaching Method Classification",
		"context": "Alex found three teaching methods in the old journal. Match each method to its category.",
		"rows": ["Socratic Question", "Moral Reflection", "Experience-Based"],
		"cols": ["Dialogue", "Ethics", "Practice"],
		"clues": [
			"Socratic methods focus on questioning and dialogue",
			"Moral reflection deals with ethical consideration",
			"Experience-based learning emphasizes practical application",
			"Each method has one primary category"
		],
		"solution": {
			"Socratic Question": "Dialogue",
			"Moral Reflection": "Ethics",
			"Experience-Based": "Practice"
		},
		"explanation": "[b]Set Classification (Math):[/b]\n• Let S = {Socratic, Moral, Experience} (teaching methods)\n• Let C = {Dialogue, Ethics, Practice} (categories)\n• Function f: S → C (one-to-one mapping)\n• f(Socratic) = Dialogue (Clue 1)\n• f(Moral) = Ethics (Clue 2)\n• f(Experience) = Practice (Clue 3)\n\nThis demonstrates function mapping where each input has exactly one output, and categories form disjoint sets."
	},
	# Chapter 5, Scene 2 - Teaching Principles Integration (Math focus: Advanced synthesis)
	"logic_grid_teaching_principles_math": {
		"title": "Teaching Principles Synthesis",
		"context": "B.C.'s teaching philosophy integrates three core mathematical principles. Match each principle to its application.",
		"rows": ["Observation", "Guidance", "Reflection"],
		"cols": ["Data Collection", "Function Mapping", "Meta-Analysis"],
		"clues": [
			"Observation involves systematically gathering information (data)",
			"Guidance creates relationships between problems and solutions (functions)",
			"Reflection examines one's own thinking process (meta-cognition)",
			"Each principle uses a different mathematical approach"
		],
		"solution": {
			"Observation": "Data Collection",
			"Guidance": "Function Mapping",
			"Reflection": "Meta-Analysis"
		},
		"explanation": "[b]Advanced Mathematical Synthesis:[/b]\n• Observation → Data Collection (gathering evidence systematically)\n• Guidance → Function Mapping (input problem → output solution)\n• Reflection → Meta-Analysis (analyzing how we think)\n\nThis demonstrates how mathematical thinking mirrors teaching philosophy: observe patterns (data), guide understanding (functions), and reflect on learning (meta-cognition). B.C. used mathematical reasoning as a teaching framework."
	},
	# Chapter 5, Scene 3 - Four Lessons Logic Grid (Math focus: Comprehensive review)
	"logic_grid_four_lessons_math": {
		"title": "The Four Lessons Integration",
		"context": "Each B.C. card taught a moral lesson through mathematical reasoning. Match each lesson to its core mathematical concept.",
		"rows": ["Truth", "Responsibility", "Creativity", "Wisdom"],
		"cols": ["Time Analysis", "Causality", "Classification", "Patterns"],
		"clues": [
			"Truth required calculating time intervals to verify alibis",
			"Responsibility involved understanding cause-and-effect sequences",
			"Creativity focused on categorizing evidence systematically",
			"Wisdom demanded recognizing patterns in behavior"
		],
		"solution": {
			"Truth": "Time Analysis",
			"Responsibility": "Causality",
			"Creativity": "Classification",
			"Wisdom": "Patterns"
		},
		"explanation": "[b]Comprehensive Integration (Math):[/b]\n• Truth = Time Analysis (Ch 1: distance-rate-time, chronology)\n• Responsibility = Causality (Ch 2: A leads to B, sequential logic)\n• Creativity = Classification (Ch 3: categorical organization, sets)\n• Wisdom = Patterns (Ch 4: frequency analysis, data trends)\n\nThis final synthesis shows how moral lessons and mathematical concepts are interconnected. Each mystery taught both ethics and reasoning - you cannot separate truth from evidence, responsibility from consequences, creativity from organization, or wisdom from pattern recognition. B.C.'s teaching integrated mathematics and morality seamlessly."
	},
	# Chapter 5, Scene 2 - Teaching Principles (Science focus: Light reflection and refraction)
	"logic_grid_teaching_principles_science": {
		"title": "Light Behavior Analysis",
		"context": "B.C.'s teaching philosophy mirrors how light behaves. Match each teaching principle to its corresponding light phenomenon.",
		"rows": ["Observation", "Guidance", "Reflection"],
		"cols": ["Absorption", "Refraction", "Reflection"],
		"clues": [
			"Observation is like absorption - taking in information from the environment",
			"Guidance bends the path like refraction - changing direction without changing nature",
			"Reflection bounces back - examining what you already know from a different angle",
			"Each principle corresponds to a different light behavior"
		],
		"solution": {
			"Observation": "Absorption",
			"Guidance": "Refraction",
			"Reflection": "Reflection"
		},
		"explanation": "[b]Physics: Light Behavior & Optics (Q4)[/b]\n\n• [b]Observation → Absorption:[/b]\n  - Light energy absorbed by material\n  - Information taken in and internalized\n  - Energy transforms (photons → knowledge)\n  - B.C. absorbed student behavior patterns\n\n• [b]Guidance → Refraction:[/b]\n  - Light bends when changing medium (air → glass)\n  - Snell's Law: n₁sinθ₁ = n₂sinθ₂\n  - Path changes but nature remains light\n  - B.C. redirected students without changing who they are\n  - Student enters at one angle, emerges at different angle (wiser)\n\n• [b]Reflection → Reflection:[/b]\n  - Light bounces off surface (angle in = angle out)\n  - Law of Reflection: θᵢ = θᵣ\n  - Students examine their own actions from new perspective\n  - Mirror shows truth you already possess\n\n[b]Teaching Philosophy as Optics:[/b]\nB.C. uses light principles for education:\n1. Observe (absorb information)\n2. Guide (refract student's path gently)\n3. Reflect (help them see themselves clearly)\n\nJust as light reveals the world, teaching reveals potential!"
	},
	# Chapter 5, Scene 3 - Four Lessons Integration (Science focus: Energy forms and transformation)
	"logic_grid_four_lessons_science": {
		"title": "Energy Transformation Analysis",
		"context": "Each B.C. lesson transformed one form of energy into another, like physics principles. Match each moral lesson to the energy transformation it represents.",
		"rows": ["Truth", "Responsibility", "Creativity", "Wisdom"],
		"cols": ["Potential→Kinetic", "Chemical→Thermal", "Electrical→Light", "Nuclear→Mass"],
		"clues": [
			"Truth revealed hidden potential and set it in motion (Chapter 1: Greg's confession)",
			"Responsibility involved burning energy through choices (Chapter 2: Ryan's actions)",
			"Creativity illuminated darkness with bright ideas (Chapter 3: Victor's art turned dark)",
			"Wisdom is the fundamental force binding everything (Chapter 4: Alex's power misused)"
		],
		"solution": {
			"Truth": "Potential→Kinetic",
			"Responsibility": "Chemical→Thermal",
			"Creativity": "Electrical→Light",
			"Wisdom": "Nuclear→Mass"
		},
		"explanation": "[b]Physics: Energy Transformation & Conservation (Q4)[/b]\n\n• [b]Truth → Potential to Kinetic:[/b]\n  - PE = mgh (stored energy of hidden truth)\n  - KE = ½mv² (active confession, motion)\n  - Greg's secret (potential) became confession (kinetic)\n  - Energy Conservation: PE converts to KE\n\n• [b]Responsibility → Chemical to Thermal:[/b]\n  - Chemical bonds store energy (choices)\n  - Combustion releases heat (consequences)\n  - Ryan's actions burned bridges (exothermic)\n  - Energy released can't be taken back\n\n• [b]Creativity → Electrical to Light:[/b]\n  - P = VI (electrical power input)\n  - Light output (photons emitted)\n  - Victor's electrical anger → destructive \"light\"\n  - True creativity should emit positive illumination\n\n• [b]Wisdom → Nuclear to Mass:[/b]\n  - E = mc² (Einstein's mass-energy equivalence)\n  - Strongest force in universe (nuclear)\n  - Alex had knowledge (mass) but not wisdom (binding energy)\n  - Wisdom holds knowledge together like strong nuclear force\n\n[b]Law of Energy Conservation:[/b]\nTotal energy remains constant - just changes form\nEach lesson transformed student potential into actual growth!\n\n[b]Four Fundamental Forces:[/b]\n1. Truth (Gravity) - pulls hidden things to light\n2. Responsibility (Electromagnetic) - actions repel/attract consequences\n3. Creativity (Weak Nuclear) - transforms one state to another\n4. Wisdom (Strong Nuclear) - binds everything together"
	},
	# Chapter 1, Scene 3 - WiFi Connection Timeline (Science focus: Signal physics and electromagnetic waves)
	"logic_grid_wifi_science": {
		"title": "WiFi Signal Analysis",
		"context": "Two devices connected to the Faculty WiFi router. Use physics principles to determine which suspect owns which device based on signal strength and location data.",
		"rows": ["Greg", "Ben", "Alex"],
		"cols": ["Galaxy_A52", "Redmi_Note_10", "No Connection"],
		"clues": [
			"Greg's device connected at 9:00 PM with -45 dBm signal strength (very strong - close range)",
			"Ben's device had -72 dBm signal strength at 8:00 PM (moderate - medium distance)",
			"Signal strength follows inverse square law: closer = stronger signal",
			"Alex was home all evening (confirmed by family) - no WiFi connection"
		],
		"solution": {
			"Greg": "Galaxy_A52",
			"Ben": "Redmi_Note_10",
			"Alex": "No Connection"
		},
		"explanation": "[b]Physics: Electromagnetic Wave Propagation[/b]\n• WiFi uses electromagnetic waves (2.4 GHz or 5 GHz)\n• Signal strength measured in dBm (decibel-milliwatts)\n• Inverse square law: Power ∝ 1/r² (closer = stronger)\n• -45 dBm = very strong (1-2 meters from router)\n• -72 dBm = moderate (10-15 meters away)\n• Greg was inside faculty room (strong signal)\n• Ben was in hallway (weaker signal)\n\nUnderstanding electromagnetic wave behavior helps solve technical mysteries!"
	},
}

# ====================
# TIMELINE RECONSTRUCTION CONFIGURATIONS
# ====================
var timeline_reconstruction_configs = {
	# Chapter 1, Scene 2 - Footprint Timeline (Math focus: Evaporation rate calculations)
	"timeline_footprints_math": {
		"title": "Footprint Timeline Analysis",
		"context": "Arrange the events in chronological order. The janitor mopped at 3:00 PM. The floor dries completely in 45 minutes. Use time calculations to determine when the footprints were made.",
		"events": [
			{"id": "event1", "text": "Janitor mops hallway floor (3:00 PM)"},
			{"id": "event2", "text": "Floor begins drying (3:00 PM - 3:45 PM)"},
			{"id": "event3", "text": "Someone enters faculty room, leaving footprints (3:30 PM)"},
			{"id": "event4", "text": "Floor completely dry (3:45 PM)"},
			{"id": "event5", "text": "Footprints discovered by Conrad/Celestine (5:30 PM)"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Mathematical Reasoning:[/b]\n• Mop time: 3:00 PM (t = 0 min)\n• Drying period: 45 minutes (t = 0 to t = 45)\n• Footprint time: 3:30 PM (t = 30 min) - still slightly wet\n• Fully dry: 3:45 PM (t = 45 min)\n• Discovery: 5:30 PM (t = 150 min)\n\nCalculating time intervals helps determine when events occurred during the theft."
	},
	# Chapter 1 - Theft Sequence (Math focus: Time intervals)
	"timeline_theft_math": {
		"title": "Theft Timeline Analysis",
		"context": "Arrange the events in chronological order based on time stamps and durations.",
		"events": [
			{"id": "event1", "text": "Janitor mops faculty room floor (3:00 PM)"},
			{"id": "event2", "text": "Air conditioner starts leaking (3:15 PM)"},
			{"id": "event3", "text": "Wet footprints appear on floor (3:30 PM)"},
			{"id": "event4", "text": "Exam papers get soaked (3:45 PM)"},
			{"id": "event5", "text": "Teacher discovers wet papers (7:30 AM next day)"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Timeline Reasoning (Math):[/b]\n• Floor mopped at 3:00 PM (t = 0)\n• AC leaks at 3:15 PM (t = +15 min)\n• Footprints at 3:30 PM (t = +30 min)\n• Papers soaked at 3:45 PM (t = +45 min)\n• Discovery at 7:30 AM (t = +16.5 hours)\n\nUnderstanding time intervals and chronological sequencing is essential for mathematical problem-solving."
	},
	# Chapter 1, Scene 5 - Greg's Alibi Timeline (Math focus: Distance, rate, time calculations)
	"timeline_analysis_greg_math": {
		"title": "Greg's Alibi Analysis",
		"context": "Calculate Greg's timeline using distance, rate, and time. School ends at 5:00 PM. His house is 2.5 km away. Walking speed is 5 km/h.",
		"events": [
			{"id": "event1", "text": "School dismissal (5:00 PM)"},
			{"id": "event2", "text": "Greg leaves school campus (5:10 PM)"},
			{"id": "event3", "text": "Greg arrives home - calculated (5:30 PM)"},
			{"id": "event4", "text": "Greg's phone connects to Faculty WiFi (9:00 PM)"},
			{"id": "event5", "text": "Confrontation with Conrad/Celestine (next day)"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Mathematical Calculation:[/b]\n• Distance = 2.5 km\n• Rate = 5 km/h\n• Time = Distance ÷ Rate = 2.5 ÷ 5 = 0.5 hours (30 minutes)\n• Departure: 5:00 PM\n• Arrival: 5:00 PM + 30 min = 5:30 PM\n• WiFi connection: 9:00 PM (3.5 hours later!)\n\nThis proves Greg returned to school after going home, contradicting his alibi."
	},
	# Chapter 2 - Threatening Note Timeline (Math focus: Chronological analysis)
	"timeline_threat_note_math": {
		"title": "Threatening Note Timeline",
		"context": "Analyze the sequence of events related to Ria's threatening note. Use chronological reasoning to determine when each event occurred.",
		"events": [
			{"id": "event1", "text": "Ryan discovers Ria's mistake with last year's funds"},
			{"id": "event2", "text": "Ryan writes the threatening note to Ria"},
			{"id": "event3", "text": "Ria finds the note in her locker (morning)"},
			{"id": "event4", "text": "Ria becomes distracted and fearful"},
			{"id": "event5", "text": "Student Council money goes missing"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Chronological Analysis (Math):[/b]\n• Discovery (t = 0): Ryan learns about the error\n• Planning (t = +1 day): Ryan writes the note\n• Delivery (t = +2 days): Note placed in locker\n• Psychological effect (t = +2 to +7 days): Ria becomes fearful\n• Crime execution (t = +7 days): Money stolen while Ria is distracted\n\nThis demonstrates how sequential events follow a logical timeline, with each step enabling the next. Understanding chronology helps detect patterns in complex situations."
	},
	# Chapter 2, Scene 3 - Threatening Note Force Analysis (Science focus: Work, Energy, Power - Q2)
	"timeline_threat_note_science": {
		"title": "Force and Work Analysis",
		"context": "Ryan applied force to write the threatening note. Arrange events in order, considering the physics of force, work, and pressure.",
		"events": [
			{"id": "event1", "text": "Ryan discovers Ria's accounting error"},
			{"id": "event2", "text": "Ryan applies force (F) with pen on paper to write threat"},
			{"id": "event3", "text": "Work done (W = F × d) creates visible ink marks on paper"},
			{"id": "event4", "text": "Note placed in Ria's locker - gravitational potential energy"},
			{"id": "event5", "text": "Ria finds note - reads message created by applied force"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Physics: Work and Force (Q2)[/b]\n• Force (F): Ryan pressed pen against paper (contact force)\n• Displacement (d): Pen moved across paper surface\n• Work (W): W = F × d × cos(θ), where θ = 0° (parallel)\n• Pressure: F/A created indentations on paper\n• Potential Energy: Note gained PE = mgh when placed in elevated locker\n\n[b]Key Physics Principle:[/b] Work = Force × Distance\nEvery written word required Ryan to apply force over a distance, transferring energy from his hand to the paper. The threatening note is physical evidence of work done!\n\n[b]Energy Transfer:[/b] Chemical energy (muscles) → Kinetic energy (hand motion) → Work (pen marking paper)"
	},
	# Chapter 3 - Vandalism Sequence (Science focus: Cause and effect)
	"timeline_vandalism_science": {
		"title": "Vandalism Event Sequence",
		"context": "Order the events based on cause-and-effect relationships.",
		"events": [
			{"id": "event1", "text": "Victor feels overshadowed by Mia's success"},
			{"id": "event2", "text": "Victor purchases paint supplies (8:47 PM)"},
			{"id": "event3", "text": "Victor returns to school after hours"},
			{"id": "event4", "text": "Sculpture is vandalized with paint"},
			{"id": "event5", "text": "Paint-stained cloth left at scene"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Causal Chain (Science):[/b]\n• Cause 1: Emotional trigger (jealousy)\n• Effect 1: Decision to act (buy supplies)\n• Cause 2: Opportunity (after hours)\n• Effect 2: Action (vandalism)\n• Effect 3: Evidence (cloth left behind)\n\nUnderstanding cause-and-effect relationships is fundamental to scientific thinking and the scientific method."
	},
	# Chapter 3, Scene 3 - Receipt Time Analysis (Math focus: Time intervals, word problems)
	"timeline_receipt_analysis_math": {
		"title": "Receipt Timeline Analysis",
		"context": "Victor claimed he was home all night. The receipt shows a purchase at 8:47 PM. The store is 1.2 km from school. Walking speed is 6 km/h.",
		"events": [
			{"id": "event1", "text": "Art Week ends, students leave (6:00 PM)"},
			{"id": "event2", "text": "Victor goes to art supply store (8:35 PM - calculated)"},
			{"id": "event3", "text": "Victor makes purchase at store (8:47 PM - receipt)"},
			{"id": "event4", "text": "Victor returns to school (9:00 PM - calculated)"},
			{"id": "event5", "text": "Sculpture vandalized (estimated 9:15 PM)"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Time Interval Calculations:[/b]\n• Store distance from school: 1.2 km\n• Walking speed: 6 km/h\n• Time to walk = Distance ÷ Speed = 1.2 ÷ 6 = 0.2 hours (12 minutes)\n\n[b]Timeline Reconstruction:[/b]\n• Purchase time: 8:47 PM (from receipt)\n• Time to return to school: 12 minutes\n• Estimated arrival: 8:47 PM + 12 min = 8:59 PM ≈ 9:00 PM\n• Vandalism window: 9:00 PM - 9:30 PM\n\nThe receipt proves Victor was near the school during the vandalism time, contradicting his alibi of being home all night."
	},
	# Chapter 3, Scene 3 - Vandalism Energy Sequence (Science focus: Work, Energy, Power - Q3)
	"timeline_receipt_analysis_science": {
		"title": "Vandalism Energy Sequence",
		"context": "Victor's vandalism involved multiple energy transformations. Arrange events in order based on work, energy, and power principles.",
		"events": [
			{"id": "event1", "text": "Victor stores chemical energy (eating dinner before leaving)"},
			{"id": "event2", "text": "Victor walks to store - chemical energy → kinetic energy (KE = ½mv²)"},
			{"id": "event3", "text": "Victor lifts paint cans - work done against gravity (W = mgh)"},
			{"id": "event4", "text": "Victor pushes sculpture - applies force over distance (W = F×d)"},
			{"id": "event5", "text": "Victor runs away - kinetic energy increases with velocity²"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Physics: Work, Energy, Power (Q3)[/b]\n\n• [b]Chemical Energy (stored):[/b]\n  - Food provides energy (ATP)\n  - Stored in molecular bonds\n  - Source for all physical activity\n\n• [b]Kinetic Energy (KE = ½mv²):[/b]\n  - Walking: velocity = 1.5 m/s\n  - Running: velocity = 5 m/s\n  - KE increases with v² (running = 11× more energy!)\n\n• [b]Work Against Gravity (W = mgh):[/b]\n  - Lifting 2kg paint can 1.5m high\n  - W = 2 × 10 × 1.5 = 30 Joules\n  - PE gained = 30 J\n\n• [b]Work (W = F × d):[/b]\n  - Pushing sculpture with 200N force\n  - Sculpture moved 0.3m\n  - W = 200 × 0.3 = 60 Joules\n\n[b]Energy Conservation:[/b] Chemical → Kinetic → Potential → Work → Kinetic\nEvery criminal action follows energy conservation laws! Victor's body converted stored chemical energy through multiple transformations."
	},
	# Chapter 4, Scene 1 - Anonymous Notes Pattern (Math focus: Frequency analysis, data patterns)
	"timeline_notes_pattern_math": {
		"title": "Anonymous Notes Timeline",
		"context": "Six students received anonymous notes over the past week. Analyze the pattern to understand when and how the notes were distributed.",
		"events": [
			{"id": "event1", "text": "Alex accesses archive, finds old teaching journal (Day 1)"},
			{"id": "event2", "text": "Alex studies the journal's methods (Day 2-3)"},
			{"id": "event3", "text": "First note appears - Ben's locker (Day 5)"},
			{"id": "event4", "text": "More notes distributed - 5 additional students (Day 6-7)"},
			{"id": "event5", "text": "Conrad/Celestine begins investigation (Day 8)"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Pattern Analysis (Math):[/b]\n• Discovery phase: Days 1-3 (Alex learns methods)\n• Implementation phase: Days 5-7 (Notes distributed)\n• Gap: 2 days between learning and first note (planning time)\n• Frequency: 1 note on Day 5, then 5 notes over Days 6-7 (increasing rate)\n• Total: 6 notes in 3 days (average 2 notes/day)\n\nThis demonstrates data pattern recognition - identifying frequency, rate of change, and time intervals in a sequence of events."
	},
	# Chapter 5, Scene 1 - Four Lessons Integration (Math focus: Synthesis, meta-cognition)
	"timeline_lessons_synthesis_math": {
		"title": "The Four Lessons Timeline",
		"context": "Reconstruct the journey of learning. Each B.C. card built upon the previous, teaching different mathematical reasoning skills.",
		"events": [
			{"id": "event1", "text": "Lesson 1: Truth - Time intervals & chronological sequencing (Chapter 1)"},
			{"id": "event2", "text": "Lesson 2: Responsibility - Sequential events & cause-effect (Chapter 2)"},
			{"id": "event3", "text": "Lesson 3: Creativity - Pattern recognition & categorical logic (Chapter 3)"},
			{"id": "event4", "text": "Lesson 4: Wisdom - Frequency analysis & conditional logic (Chapter 4)"},
			{"id": "event5", "text": "Final Understanding: All lessons converge to teach Choice"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Meta-Cognitive Synthesis (Math):[/b]\n• Chapter 1 → Basic foundations (time, sequences)\n• Chapter 2 → Causality understanding (A leads to B)\n• Chapter 3 → Classification systems (organizing knowledge)\n• Chapter 4 → Advanced analysis (patterns, logic)\n• Chapter 5 → Integration (all skills combine)\n\nThis demonstrates how mathematical thinking builds progressively - each concept depends on mastering previous ones. True understanding comes from seeing the connections between isolated skills."
	},
	# Chapter 1, Scene 5 - Alibi Verification (Science focus: Motion physics and kinematics)
	"timeline_alibi_science": {
		"title": "Alibi Motion Analysis",
		"context": "Greg claims he went straight home after school at 5:00 PM. His house is 2.5 km away. Arrange events chronologically using physics principles (distance, velocity, time).",
		"events": [
			{"id": "event1", "text": "School dismissal - Greg leaves campus (5:00 PM)"},
			{"id": "event2", "text": "Greg walks home at average velocity 5 km/h"},
			{"id": "event3", "text": "Greg arrives home - calculated time (5:30 PM)"},
			{"id": "event4", "text": "Greg's phone detected at school WiFi (9:00 PM)"},
			{"id": "event5", "text": "Confrontation: Greg must explain the gap"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Physics: Kinematics (Motion)[/b]\n• Distance (d) = 2.5 km\n• Velocity (v) = 5 km/h (average walking speed)\n• Time (t) = d/v = 2.5 km ÷ 5 km/h = 0.5 hours = 30 minutes\n• Departure: 5:00 PM (t₀)\n• Arrival home: 5:30 PM (t₁ = t₀ + 30 min)\n• WiFi detection: 9:00 PM (t₂ = t₁ + 3.5 hours)\n\n[b]Key Physics Principle:[/b] Velocity = Distance/Time (v = d/t)\nThis fundamental kinematic equation proves Greg returned to school 3.5 hours after going home - his alibi fails!\n\n[b]Newton's First Law Application:[/b] An object in motion stays in motion. Greg's motion pattern shows intentional return to school, not accidental presence."
	},
	# Chapter 4, Scene 1 - Note Distribution Timeline (Science focus: Electrical signals and circuits)
	"timeline_notes_distribution_science": {
		"title": "Electrical Signal Analysis",
		"context": "Six anonymous notes were distributed over a week. Using electrical circuit principles, analyze the pattern of information flow from source to recipients.",
		"events": [
			{"id": "event1", "text": "Day 1: Alex finds journal - closes the circuit (completes learning loop)"},
			{"id": "event2", "text": "Day 3: First note delivered - current begins flowing (I = ΔQ/Δt)"},
			{"id": "event3", "text": "Day 4-5: Rapid note distribution - high current (6 notes in 48 hours)"},
			{"id": "event4", "text": "Day 6: Students report notes - resistance builds in the circuit"},
			{"id": "event5", "text": "Day 7: Investigation starts - circuit breaks (information flow stops)"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Physics: Electricity - Current and Charge Flow[/b]\n• Electric Current (I) = Charge/Time (I = ΔQ/Δt)\n• 6 notes in 48 hours = high current flow\n• Average rate: 6 notes ÷ 2 days = 3 notes/day\n• Information flows like electrical current through a circuit\n\n[b]Circuit Analogy:[/b]\n• Source: Alex (battery/EMF)\n• Conductors: Locker system (wires)\n• Recipients: Students (resistors receiving energy)\n• Resistance: Student reports (opposing current flow)\n• Open Circuit: Investigation stops the flow\n\n[b]Ohm's Law Connection (V = IR):[/b] More resistance (R↑) = lower current (I↓). When students resisted (reported notes), the distribution stopped!"
	},
	# Chapter 5, Scene 1 - Teaching Lessons Timeline (Science focus: Wave interference and synthesis)
	"timeline_lessons_synthesis_science": {
		"title": "Wave Interference Synthesis",
		"context": "Each B.C. lesson was like a wave - individual oscillations that interfere constructively to create wisdom. Arrange the four lessons in order, understanding how they combine like waves.",
		"events": [
			{"id": "event1", "text": "Lesson 1 (Truth) - First wave λ₁: Evidence & honesty (Chapter 1)"},
			{"id": "event2", "text": "Lesson 2 (Responsibility) - Second wave λ₂: Actions & consequences (Chapter 2)"},
			{"id": "event3", "text": "Lesson 3 (Creativity) - Third wave λ₃: Expression over competition (Chapter 3)"},
			{"id": "event4", "text": "Lesson 4 (Wisdom) - Fourth wave λ₄: Knowledge + guidance (Chapter 4)"},
			{"id": "event5", "text": "Constructive Interference: All waves combine → Complete understanding"}
		],
		"correct_order": ["event1", "event2", "event3", "event4", "event5"],
		"explanation": "[b]Physics: Wave Interference & Superposition (Q4)[/b]\n\n• [b]Wave Superposition Principle:[/b]\n  - Multiple waves combine at same point\n  - Total amplitude = sum of individual waves\n  - Each lesson (wave) adds to total understanding\n\n• [b]Constructive Interference:[/b]\n  - Waves in phase reinforce each other\n  - Lessons 1-4 aligned perfectly (in phase)\n  - Result: Maximum amplitude (wisdom)\n  - Formula: A_total = A₁ + A₂ + A₃ + A₄\n\n• [b]Wave Properties:[/b]\n  - Wavelength (λ): Each lesson has unique 'frequency'\n  - Amplitude: Depth of understanding\n  - Phase: Timing of lesson delivery\n  - B.C. timed each lesson perfectly (phase alignment)\n\n• [b]Application to Learning:[/b]\n  - Truth (wave 1) establishes foundation\n  - Responsibility (wave 2) adds depth\n  - Creativity (wave 3) increases amplitude\n  - Wisdom (wave 4) completes the pattern\n  - All four waves interfere constructively → Complete knowledge\n\n[b]Wave Equation Connection:[/b] v = fλ\nEach lesson travels at the speed of understanding (v), with its own frequency (f) and wavelength (λ)!"
	}
}

func _get_subject_variant_id(base_id: String) -> String:
	"""
	Returns the subject-specific variant of a minigame ID.
	If no variant exists, returns the original ID (defaults to English).
	"""
	if not PlayerStats:
		print("DEBUG: PlayerStats not found, using base ID: ", base_id)
		return base_id

	var subject = PlayerStats.selected_subject
	print("DEBUG: PlayerStats.selected_subject = ", subject)

	# First, check if base_id already exists in any config
	# This handles subject-specific minigames that don't have variants (e.g., "timeline_footprints_math")
	if fillinTheblank_configs.has(base_id) or hear_and_fill_configs.has(base_id) or \
	   riddle_configs.has(base_id) or dialogue_choice_configs.has(base_id) or \
	   logic_grid_configs.has(base_id) or timeline_reconstruction_configs.has(base_id):
		print("DEBUG: Base ID exists in configs, using as-is: ", base_id)
		return base_id

	if subject == "english":
		print("DEBUG: Subject is English, using base ID: ", base_id)
		return base_id  # English is the base/default

	# Try to find subject-specific variant
	var variant_id = base_id + "_" + subject
	print("DEBUG: Looking for variant: ", variant_id)

	# Check if variant exists in any config
	if fillinTheblank_configs.has(variant_id):
		print("DEBUG: Found in fillinTheblank_configs!")
		return variant_id
	elif hear_and_fill_configs.has(variant_id):
		print("DEBUG: Found in hear_and_fill_configs!")
		return variant_id
	elif riddle_configs.has(variant_id):
		print("DEBUG: Found in riddle_configs!")
		return variant_id
	elif dialogue_choice_configs.has(variant_id):
		print("DEBUG: Found in dialogue_choice_configs!")
		return variant_id
	elif logic_grid_configs.has(variant_id):
		print("DEBUG: Found in logic_grid_configs!")
		return variant_id
	elif timeline_reconstruction_configs.has(variant_id):
		print("DEBUG: Found in timeline_reconstruction_configs!")
		return variant_id

	# No variant found, use base (English)
	print("DEBUG: Variant not found, falling back to base ID: ", base_id)
	return base_id

func start_minigame(puzzle_id: String) -> void:
	print("DEBUG: MinigameManager.start_minigame called with: ", puzzle_id)
	if current_minigame:
		push_warning("Minigame already active!")
		return

	# Check for curriculum-based minigames (format: "curriculum:type")
	if puzzle_id.begins_with("curriculum:"):
		var minigame_type = puzzle_id.trim_prefix("curriculum:")
		_start_curriculum_minigame(minigame_type)
		return

	# Get subject-specific variant (if exists)
	puzzle_id = _get_subject_variant_id(puzzle_id)
	print("DEBUG: Using minigame variant: ", puzzle_id)

	# Check which type of minigame this is
	if fillinTheblank_configs.has(puzzle_id):
		_start_fillinblank(puzzle_id)
	elif pacman_configs.has(puzzle_id):
		_start_pacman(puzzle_id)
	elif runner_configs.has(puzzle_id):
		_start_runner(puzzle_id)
	elif platformer_configs.has(puzzle_id):
		_start_platformer(puzzle_id)
	elif maze_configs.has(puzzle_id):
		_start_maze(puzzle_id)
	elif pronunciation_configs.has(puzzle_id):
		_start_pronunciation(puzzle_id)
	elif math_configs.has(puzzle_id):
		_start_math(puzzle_id)
	elif hear_and_fill_configs.has(puzzle_id):
		_start_hear_and_fill(puzzle_id)
	elif riddle_configs.has(puzzle_id):
		_start_riddle(puzzle_id)
	elif dialogue_choice_configs.has(puzzle_id):
		_start_dialogue_choice(puzzle_id)
	elif detective_analysis_configs.has(puzzle_id):
		_start_detective_analysis(puzzle_id)
	elif logic_grid_configs.has(puzzle_id):
		_start_logic_grid(puzzle_id)
	elif timeline_reconstruction_configs.has(puzzle_id):
		_start_timeline_reconstruction(puzzle_id)
	# Oral Communication Module configs
	elif _get_oralcom_config(puzzle_id) != null:
		_start_oralcom_minigame(puzzle_id)
	else:
		push_error("Unknown puzzle: " + puzzle_id)
		return

# Helper to find which oral communication module config contains the puzzle
func _get_oralcom_config(puzzle_id: String) -> Dictionary:
	# Check all module configs
	for module in [oralcom_module1_configs, oralcom_module2_configs, oralcom_module3_configs, oralcom_module4_configs, oralcom_module5_configs]:
		if module.has(puzzle_id):
			return module[puzzle_id]
	return {}

# Start the appropriate minigame type based on puzzle_id suffix
func _start_oralcom_minigame(puzzle_id: String) -> void:
	var config = _get_oralcom_config(puzzle_id)
	if config.is_empty():
		push_error("Could not find oral com config for: " + puzzle_id)
		return

	# Determine minigame type from puzzle_id suffix
	if puzzle_id.ends_with("_pacman"):
		print("DEBUG: Starting Oral Com Pacman minigame...")
		current_minigame = pacman_scene.instantiate()
		get_tree().root.add_child(current_minigame)
		current_minigame.configure_puzzle(config)
		current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	elif puzzle_id.ends_with("_runner"):
		print("DEBUG: Starting Oral Com Runner minigame...")
		current_minigame = runner_scene.instantiate()
		get_tree().root.add_child(current_minigame)
		current_minigame.configure_puzzle(config)
		current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	elif puzzle_id.ends_with("_platformer"):
		print("DEBUG: Starting Oral Com Platformer minigame...")
		current_minigame = platformer_scene.instantiate()
		get_tree().root.add_child(current_minigame)
		current_minigame.configure_puzzle(config)
		current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	elif puzzle_id.ends_with("_maze"):
		print("DEBUG: Starting Oral Com Maze minigame...")
		current_minigame = maze_scene.instantiate()
		get_tree().root.add_child(current_minigame)
		var game_node = current_minigame.get_node("Game")
		game_node.configure_puzzle(config)
		game_node.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	else:
		push_error("Unknown oral com minigame type for: " + puzzle_id)

func _start_fillinblank(puzzle_id: String) -> void:
	print("DEBUG: Starting fill-in-the-blank minigame...")
	print("DEBUG: Puzzle ID = ", puzzle_id)
	print("DEBUG: Puzzle config = ", fillinTheblank_configs[puzzle_id])
	current_minigame = fillinTheblank_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(fillinTheblank_configs[puzzle_id])
	current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	print("DEBUG: Fill-in-the-blank minigame should now be visible")

func _start_pacman(puzzle_id: String) -> void:
	print("DEBUG: Starting Pacman minigame...")
	current_minigame = pacman_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(pacman_configs[puzzle_id])
	current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	print("DEBUG: Pacman minigame should now be visible")

func _start_runner(puzzle_id: String) -> void:
	print("DEBUG: Starting Runner minigame...")
	current_minigame = runner_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(runner_configs[puzzle_id])
	current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	print("DEBUG: Runner minigame should now be visible")

func _start_platformer(puzzle_id: String) -> void:
	print("DEBUG: Starting Platformer minigame...")
	current_minigame = platformer_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(platformer_configs[puzzle_id])
	current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	print("DEBUG: Platformer minigame should now be visible")

func _start_maze(puzzle_id: String) -> void:
	print("DEBUG: Starting Maze minigame...")
	current_minigame = maze_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	# The maze scene has Main (CanvasLayer) > Game (Node2D with script)
	var game_node = current_minigame.get_node("Game")
	game_node.configure_puzzle(maze_configs[puzzle_id])
	game_node.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	print("DEBUG: Maze minigame should now be visible")

func _start_pronunciation(puzzle_id: String) -> void:
	print("DEBUG: Starting Pronunciation minigame...")

	# Auto-complete if Vosk is disabled
	if DISABLE_VOSK:
		print("⚠️ Vosk disabled - Auto-completing Pronunciation minigame")
		await get_tree().create_timer(0.5).timeout  # Small delay for realism
		_on_minigame_finished(true, 100, puzzle_id)  # Pass success, score, puzzle_id
		return

	current_minigame = pronunciation_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(pronunciation_configs[puzzle_id])
	current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	print("DEBUG: Pronunciation minigame should now be visible")

func _start_math(puzzle_id: String) -> void:
	print("DEBUG: Starting Math minigame...")
	current_minigame = math_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(math_configs[puzzle_id])
	current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
	print("DEBUG: Math minigame should now be visible")

func _start_curriculum_minigame(minigame_type: String) -> void:
	var config = CurriculumQuestions.get_config(minigame_type)
	if config.is_empty():
		push_error("No curriculum config for: " + minigame_type)
		return

	var puzzle_id = "curriculum_" + minigame_type
	print("DEBUG: Starting curriculum minigame: ", minigame_type)

	match minigame_type:
		"pacman":
			current_minigame = pacman_scene.instantiate()
			get_tree().root.add_child(current_minigame)
			current_minigame.configure_puzzle(config)
			current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
		"runner":
			current_minigame = runner_scene.instantiate()
			get_tree().root.add_child(current_minigame)
			current_minigame.configure_puzzle(config)
			current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
		"platformer":
			current_minigame = platformer_scene.instantiate()
			get_tree().root.add_child(current_minigame)
			current_minigame.configure_puzzle(config)
			current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
		"maze":
			current_minigame = maze_scene.instantiate()
			get_tree().root.add_child(current_minigame)
			var game_node = current_minigame.get_node("Game")
			game_node.configure_puzzle(config)
			game_node.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
		"fillinblank":
			current_minigame = fillinTheblank_scene.instantiate()
			get_tree().root.add_child(current_minigame)
			current_minigame.configure_puzzle(config)
			current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
		"math":
			current_minigame = math_scene.instantiate()
			get_tree().root.add_child(current_minigame)
			current_minigame.configure_puzzle(config)
			current_minigame.game_finished.connect(_on_minigame_finished.bind(puzzle_id))
		_:
			push_error("Unknown curriculum minigame type: " + minigame_type)
			return

	print("DEBUG: Curriculum minigame started: ", minigame_type)

func _start_dialogue_choice(puzzle_id: String) -> void:
	print("DEBUG: Starting Dialogue Choice minigame: ", puzzle_id)

	# Auto-complete if Vosk is disabled
	if DISABLE_VOSK:
		print("⚠️ Vosk disabled - Auto-completing Dialogue Choice minigame")
		await get_tree().create_timer(0.5).timeout  # Small delay for realism
		_on_dialogue_choice_finished(true, puzzle_id)
		return

	var config = dialogue_choice_configs[puzzle_id]
	print("DEBUG: Question being shown: ", config.get("question", "Unknown question"))
	current_minigame = dialogue_choice_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(config)
	current_minigame.minigame_completed.connect(_on_dialogue_choice_finished.bind(puzzle_id))
	print("DEBUG: Dialogue Choice minigame should now be visible")

func _on_dialogue_choice_finished(success: bool, puzzle_id: String) -> void:
	print("DEBUG: Dialogue Choice minigame finished. Success: ", success, ", Puzzle: ", puzzle_id)
	last_minigame_success = success
	if success:
		Dialogic.VAR.minigames_completed += 1
	minigame_completed.emit(puzzle_id, success)
	current_minigame = null

func _start_hear_and_fill(puzzle_id: String) -> void:
	print("DEBUG: Starting Hear and Fill minigame...")

	# Auto-complete if Vosk is disabled (Hear and Fill uses TTS, not Vosk, but disable for consistency)
	if DISABLE_VOSK:
		print("⚠️ Vosk disabled - Auto-completing Hear and Fill minigame")
		await get_tree().create_timer(0.5).timeout  # Small delay for realism
		_on_hear_and_fill_finished(true, puzzle_id)
		return

	var config = hear_and_fill_configs[puzzle_id]
	current_minigame = hear_and_fill_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(config)
	current_minigame.minigame_completed.connect(_on_hear_and_fill_finished.bind(puzzle_id))
	print("DEBUG: Hear and Fill minigame should now be visible")

func _on_hear_and_fill_finished(success: bool, puzzle_id: String) -> void:
	print("DEBUG: Hear and Fill minigame finished. Success: ", success, ", Puzzle: ", puzzle_id)
	last_minigame_success = success
	if success:
		Dialogic.VAR.minigames_completed += 1
	minigame_completed.emit(puzzle_id, success)
	current_minigame = null

func _start_riddle(puzzle_id: String) -> void:
	print("DEBUG: Starting Riddle minigame: ", puzzle_id)
	var config = riddle_configs[puzzle_id]
	current_minigame = riddle_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(config)
	current_minigame.minigame_completed.connect(_on_riddle_finished.bind(puzzle_id))
	print("DEBUG: Riddle minigame should now be visible")

func _on_riddle_finished(success: bool, puzzle_id: String) -> void:
	print("DEBUG: Riddle minigame finished. Success: ", success, ", Puzzle: ", puzzle_id)
	last_minigame_success = success
	if success:
		Dialogic.VAR.minigames_completed += 1
	minigame_completed.emit(puzzle_id, success)
	current_minigame = null

func _start_detective_analysis(puzzle_id: String) -> void:
	print("DEBUG: Starting Detective Analysis minigame: ", puzzle_id)
	var config = detective_analysis_configs[puzzle_id]
	current_minigame = detective_analysis_scene.instantiate()

	# Pause Dialogic while minigame is active
	Dialogic.paused = true

	# Wrap minigame in a CanvasLayer to ensure it renders on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer number to render on top
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(current_minigame)
	print("DEBUG: Detective Analysis minigame added to CanvasLayer 100")

	current_minigame.configure_puzzle(config)
	current_minigame.minigame_completed.connect(_on_detective_analysis_finished.bind(puzzle_id))
	print("DEBUG: Detective Analysis minigame should now be visible")

func _on_detective_analysis_finished(success: bool, time_taken: float, puzzle_id: String) -> void:
	print("DEBUG: Detective Analysis finished. Success: ", success, ", Time: ", time_taken, "s, Puzzle: ", puzzle_id)
	last_minigame_success = success

	# Track speed bonus (< 60 seconds = fast)
	last_minigame_speed_bonus = (time_taken < 60.0)

	if success:
		Dialogic.VAR.minigames_completed += 1

	# Resume Dialogic
	Dialogic.paused = false
	print("DEBUG: Dialogic resumed")

	minigame_completed.emit(puzzle_id, success)
	current_minigame = null

func _start_logic_grid(puzzle_id: String) -> void:
	print("DEBUG: Starting Logic Grid minigame: ", puzzle_id)
	var config = logic_grid_configs[puzzle_id]
	current_minigame = logic_grid_scene.instantiate()

	# Pause Dialogic while minigame is active
	Dialogic.paused = true

	# Wrap minigame in a CanvasLayer to ensure it renders on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer number to render on top
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(current_minigame)

	current_minigame.minigame_completed.connect(_on_logic_grid_finished.bind(puzzle_id))
	# Defer configuration until next frame (after _ready() is called)
	current_minigame.configure_puzzle.call_deferred(config)
	print("DEBUG: Logic Grid minigame should now be visible")

func _on_logic_grid_finished(success: bool, time_taken: float, puzzle_id: String) -> void:
	print("DEBUG: Logic Grid finished. Success: ", success, ", Time: ", time_taken, "s, Puzzle: ", puzzle_id)
	last_minigame_success = success
	last_minigame_speed_bonus = (time_taken < 60.0)

	if success:
		Dialogic.VAR.minigames_completed += 1

	# Resume Dialogic
	Dialogic.paused = false

	minigame_completed.emit(puzzle_id, success)
	current_minigame = null

func _start_timeline_reconstruction(puzzle_id: String) -> void:
	print("DEBUG: Starting Timeline Reconstruction minigame: ", puzzle_id)
	print("DEBUG: Config keys: ", timeline_reconstruction_configs.keys())

	if not timeline_reconstruction_configs.has(puzzle_id):
		push_error("Timeline Reconstruction config not found for: " + puzzle_id)
		return

	var config = timeline_reconstruction_configs[puzzle_id]
	print("DEBUG: Config loaded: ", config.get("title", "NO TITLE"))

	current_minigame = timeline_reconstruction_scene.instantiate()
	print("DEBUG: Minigame instantiated: ", current_minigame)
	print("DEBUG: Minigame type: ", current_minigame.get_class())

	# Pause Dialogic while minigame is active
	Dialogic.paused = true
	print("DEBUG: Dialogic paused")

	# Wrap minigame in a CanvasLayer to ensure it renders on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer number to render on top
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(current_minigame)
	print("DEBUG: Minigame added to CanvasLayer 100")

	current_minigame.minigame_completed.connect(_on_timeline_reconstruction_finished.bind(puzzle_id))
	print("DEBUG: Signal connected")

	# Defer configuration until next frame (after _ready() is called)
	current_minigame.configure_puzzle.call_deferred(config)
	print("DEBUG: Configuration deferred")
	print("DEBUG: Timeline Reconstruction minigame should now be visible")

func _on_timeline_reconstruction_finished(success: bool, time_taken: float, puzzle_id: String) -> void:
	print("DEBUG: Timeline Reconstruction finished. Success: ", success, ", Time: ", time_taken, "s, Puzzle: ", puzzle_id)
	last_minigame_success = success
	last_minigame_speed_bonus = (time_taken < 60.0)

	if success:
		Dialogic.VAR.minigames_completed += 1

	# Resume Dialogic
	Dialogic.paused = false
	print("DEBUG: Dialogic resumed")

	minigame_completed.emit(puzzle_id, success)
	current_minigame = null

func _on_minigame_finished(success: bool, score: int, puzzle_id: String) -> void:
	print("DEBUG: Minigame finished. Success: ", success, ", Score: ", score, ", Puzzle: ", puzzle_id)
	last_minigame_success = success
	if success:
		Dialogic.VAR.minigames_completed += 1
	minigame_completed.emit(puzzle_id, success)
	current_minigame = null
