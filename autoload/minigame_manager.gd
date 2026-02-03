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
var current_minigame = null

# Preloaded Vosk recognizer for dialogue choice minigame
var shared_vosk_recognizer = null
var vosk_loading_progress: float = 0.0  # 0.0 to 1.0
var vosk_is_loaded: bool = false
var loading_screen = null
const VOSK_MODEL_PATH = "res://addons/vosk/models/vosk-model-en-us-0.22"
const VOSK_SAMPLE_RATE = 16000.0
var loading_screen_scene = preload("res://scenes/ui/vosk_loading_screen.tscn")

func _ready():
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
		"choices": ["examines", "ignores", "watches", "touches", "breaks", "opens", "closes", "avoids"]
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
	# Chapter 5 - Lesson reflection
	"lesson_reflection": {
		"sentence_parts": ["True teaching requires ", " and respects ", " while guiding growth."],
		"answers": ["wisdom", "choice"],
		"choices": ["wisdom", "choice", "control", "force", "patience", "freedom", "power", "authority"]
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
	}
}

# Riddle puzzle configs
var riddle_configs = {
	"bracelet_riddle": {
		"riddle": "Round I go, around your hand,\nI shine and sparkle, isn't that grand?",
		"answer": "BRACELET",
		"letters": ["B", "R", "A", "C", "E", "L", "E", "T", "W", "H", "V", "M", "K", "O", "I", "G"]
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
	}
}

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
		# Emit completion signal with failure to unpause Dialogic
		minigame_completed.emit("curriculum_" + minigame_type, false)
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
			# Emit completion signal with failure to unpause Dialogic
			minigame_completed.emit("curriculum_" + minigame_type, false)
			return

	print("DEBUG: Curriculum minigame started: ", minigame_type)

func _start_dialogue_choice(puzzle_id: String) -> void:
	print("DEBUG: Starting Dialogue Choice minigame: ", puzzle_id)
	var config = dialogue_choice_configs[puzzle_id]
	current_minigame = dialogue_choice_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(config)
	current_minigame.minigame_completed.connect(_on_dialogue_choice_finished.bind(puzzle_id))
	print("DEBUG: Dialogue Choice minigame should now be visible")

func _on_dialogue_choice_finished(success: bool, puzzle_id: String) -> void:
	print("DEBUG: Dialogue Choice minigame finished. Success: ", success, ", Puzzle: ", puzzle_id)
	if success:
		Dialogic.VAR.minigames_completed += 1
	minigame_completed.emit(puzzle_id, success)
	current_minigame = null

func _start_hear_and_fill(puzzle_id: String) -> void:
	print("DEBUG: Starting Hear and Fill minigame...")
	var config = hear_and_fill_configs[puzzle_id]
	current_minigame = hear_and_fill_scene.instantiate()
	get_tree().root.add_child(current_minigame)
	current_minigame.configure_puzzle(config)
	current_minigame.minigame_completed.connect(_on_hear_and_fill_finished.bind(puzzle_id))
	print("DEBUG: Hear and Fill minigame should now be visible")

func _on_hear_and_fill_finished(success: bool, puzzle_id: String) -> void:
	print("DEBUG: Hear and Fill minigame finished. Success: ", success, ", Puzzle: ", puzzle_id)
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
	if success:
		Dialogic.VAR.minigames_completed += 1
	minigame_completed.emit(puzzle_id, success)
	current_minigame = null

func _on_minigame_finished(success: bool, score: int, puzzle_id: String) -> void:
	print("DEBUG: Minigame finished. Success: ", success, ", Score: ", score, ", Puzzle: ", puzzle_id)
	if success:
		Dialogic.VAR.minigames_completed += 1
	minigame_completed.emit(puzzle_id, success)
	current_minigame = null
