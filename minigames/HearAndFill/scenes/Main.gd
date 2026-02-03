extends CanvasLayer

# Node references
@onready var timer_label = $Control/MainContainer/VBoxContainer/HeaderContainer/TimerLabel
@onready var hint_button = $Control/MainContainer/VBoxContainer/HeaderContainer/HintButton
@onready var hint_label = $Control/MainContainer/VBoxContainer/HeaderContainer/HintLabel
@onready var title_label = $Control/MainContainer/VBoxContainer/InstructionPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var instruction_label = $Control/MainContainer/VBoxContainer/InstructionPanel/MarginContainer/VBoxContainer/InstructionLabel
@onready var sentence_container = $Control/MainContainer/VBoxContainer/SentenceContainer
@onready var sentence_label = $Control/MainContainer/VBoxContainer/SentenceContainer/SentenceLabel
@onready var speaker_button = $Control/MainContainer/VBoxContainer/SentenceContainer/SpeakerButton
@onready var choices_container = $Control/MainContainer/VBoxContainer/ChoicesContainer
@onready var feedback_label = $Control/MainContainer/VBoxContainer/FeedbackLabel

# Choice buttons (8 buttons in 2 rows of 4)
@onready var choice_buttons = [
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Row1/Choice1,
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Row1/Choice2,
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Row1/Choice3,
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Row1/Choice4,
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Row2/Choice5,
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Row2/Choice6,
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Row2/Choice7,
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Row2/Choice8
]

# Timer
var time_remaining: float = 90.0  # 1:30 in seconds
var timer_active: bool = false

# Puzzle configuration
var sentence_text: String = "Sir, does this room have a dedicated ____ router?"
var blank_word: String = "WiFi"
var correct_answer_index: int = 2  # "WiFi" is at index 2
var choices: Array = ["Hi-fi", "Sci-fi", "WiFi", "Bye-bye", "Fly high", "Sky high", "Pie-fry", "Why try"]

# Hint system
var hint_used: bool = false

# Time tracking for bonus hint
var start_time: float = 0.0
const TIME_BONUS_THRESHOLD: float = 60.0  # Complete within 1 minute for bonus hint

# Audio system
var tts_player: AudioStreamPlayer = null

signal minigame_completed(success: bool)

func _ready():
	print("DEBUG: HearAndFill minigame _ready() called")

	# Make sure the control is visible
	visible = true

	# Record start time for bonus hint
	start_time = Time.get_ticks_msec() / 1000.0

	# Verify node references
	_verify_nodes()

	# Set up UI
	_setup_ui()

	# Connect button signals
	_connect_buttons()

	# Start timer
	timer_active = true

	# Setup TTS
	_setup_tts()

func _verify_nodes():
	"""Verify all node references exist"""
	if timer_label == null:
		push_error("HearAndFill: timer_label is null!")
	if hint_button == null:
		push_error("HearAndFill: hint_button is null!")
	if hint_label == null:
		push_error("HearAndFill: hint_label is null!")
	if title_label == null:
		push_error("HearAndFill: title_label is null!")
	if instruction_label == null:
		push_error("HearAndFill: instruction_label is null!")
	if sentence_label == null:
		push_error("HearAndFill: sentence_label is null!")
	if speaker_button == null:
		push_error("HearAndFill: speaker_button is null!")

func _setup_ui():
	"""Initialize UI elements"""
	if title_label:
		title_label.text = "\"Hear and Fill!\""
	if instruction_label:
		instruction_label.text = "Listen to the audio clip\nChoose the correct word based on proper pronunciation."
	if sentence_label:
		sentence_label.text = sentence_text

	# Update hint display from PlayerStats
	_update_hint_display()

	# Set choice button labels
	for i in range(choice_buttons.size()):
		if choice_buttons[i] == null:
			push_error("HearAndFill: choice_buttons[" + str(i) + "] is null!")
			continue
		if i < choices.size():
			choice_buttons[i].text = choices[i]
			choice_buttons[i].visible = true
		else:
			choice_buttons[i].visible = false

	if feedback_label:
		feedback_label.visible = false

func _connect_buttons():
	"""Connect all button signals"""
	# Connect choice buttons
	for i in range(choice_buttons.size()):
		if choice_buttons[i]:
			choice_buttons[i].pressed.connect(_on_choice_selected.bind(i))

	# Connect hint button
	if hint_button:
		hint_button.pressed.connect(_on_hint_pressed)

	# Connect speaker button
	if speaker_button:
		speaker_button.pressed.connect(_on_speaker_pressed)

func _process(delta):
	if timer_active:
		time_remaining -= delta
		if time_remaining <= 0:
			time_remaining = 0
			timer_active = false
			_on_time_up()

		_update_timer_display()

func _update_timer_display():
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func _on_time_up():
	"""Called when timer reaches zero"""
	feedback_label.text = "Time's up! Try again."
	feedback_label.add_theme_color_override("font_color", Color.ORANGE)
	feedback_label.visible = true

	# Disable all buttons
	for button in choice_buttons:
		button.disabled = true

	await get_tree().create_timer(2.0).timeout
	_complete_minigame(false)

func _on_choice_selected(choice_index: int):
	"""Called when player selects an answer"""
	print("DEBUG: Choice selected: ", choice_index, " (", choices[choice_index], ")")

	# Disable all buttons
	for button in choice_buttons:
		button.disabled = true

	timer_active = false

	if choice_index == correct_answer_index:
		# Correct answer
		_show_correct_feedback()
	else:
		# Wrong answer
		_show_wrong_feedback(choice_index)

func _show_correct_feedback():
	"""Show feedback for correct answer"""
	var completion_time = (Time.get_ticks_msec() / 1000.0) - start_time

	# Check if player earned a bonus hint (completed within 1 minute)
	var bonus_hint_earned = completion_time <= TIME_BONUS_THRESHOLD

	if bonus_hint_earned:
		PlayerStats.add_hints(1)
		feedback_label.text = "Correct! Well done!\n⚡ Speed Bonus: +1 Hint! ⚡"
		print("DEBUG: Bonus hint earned! Completion time: ", completion_time, "s")
	else:
		feedback_label.text = "Correct! Well done!"

	feedback_label.add_theme_color_override("font_color", Color.GREEN)
	feedback_label.visible = true

	# Highlight correct answer
	choice_buttons[correct_answer_index].add_theme_color_override("font_color", Color.GREEN)

	await get_tree().create_timer(2.5).timeout
	_complete_minigame(true)

func _show_wrong_feedback(selected_index: int):
	"""Show feedback for wrong answer"""
	feedback_label.text = "Incorrect. The correct answer is: " + blank_word
	feedback_label.add_theme_color_override("font_color", Color.RED)
	feedback_label.visible = true

	# Highlight wrong answer in red
	choice_buttons[selected_index].add_theme_color_override("font_color", Color.RED)

	# Highlight correct answer in green
	choice_buttons[correct_answer_index].add_theme_color_override("font_color", Color.GREEN)

	await get_tree().create_timer(3.0).timeout
	_complete_minigame(false)

func _update_hint_display():
	"""Update hint label from PlayerStats"""
	if hint_label and PlayerStats:
		hint_label.text = "Hints: " + str(PlayerStats.hints)

func _on_hint_pressed():
	"""Called when hint button is pressed"""
	if hint_used:
		feedback_label.text = "You already used a hint for this puzzle!"
		feedback_label.add_theme_color_override("font_color", Color.ORANGE)
		feedback_label.visible = true
		await get_tree().create_timer(2.0).timeout
		feedback_label.visible = false
		return

	# Try to use a hint from PlayerStats
	if PlayerStats.use_hint():
		hint_used = true
		_update_hint_display()
		hint_button.disabled = true

		# Highlight the correct answer box
		var correct_button = choice_buttons[correct_answer_index]

		# Create a visual highlight effect (yellow border/background)
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(correct_button, "modulate", Color.YELLOW, 0.3)
		tween.tween_property(correct_button, "modulate", Color.WHITE, 0.3)

		print("DEBUG: Hint used! Highlighting correct answer: ", blank_word)
		print("DEBUG: Hints remaining: ", PlayerStats.hints)
	else:
		# No hints available
		feedback_label.text = "No hints available! Complete minigames quickly to earn more."
		feedback_label.add_theme_color_override("font_color", Color.ORANGE)
		feedback_label.visible = true
		await get_tree().create_timer(2.0).timeout
		feedback_label.visible = false

func _setup_tts():
	"""Setup TTS audio player"""
	tts_player = AudioStreamPlayer.new()
	add_child(tts_player)
	tts_player.finished.connect(_on_tts_finished)

	# Generate TTS audio for the blank word
	_generate_tts_audio(blank_word)

func _generate_tts_audio(text: String):
	"""Generate TTS audio using DisplayServer.tts_speak"""
	# Godot 4.x TTS support
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()

	# Speak the text (voice parameter: empty string = default voice)
	DisplayServer.tts_speak(text, "")
	print("DEBUG: TTS speaking: ", text)

func _on_speaker_pressed():
	"""Called when speaker button is pressed to play TTS"""
	print("DEBUG: Speaker button pressed")
	_generate_tts_audio(blank_word)

func _on_tts_finished():
	"""Called when TTS finishes playing"""
	print("DEBUG: TTS finished")

func _complete_minigame(success: bool):
	"""Complete the minigame"""
	# Stop TTS if playing
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()

	minigame_completed.emit(success)
	_cleanup()
	queue_free()

func _cleanup():
	"""Cleanup resources"""
	if tts_player:
		tts_player.queue_free()
		tts_player = null

func _exit_tree():
	_cleanup()

# Configuration function for different puzzle variations
func configure_puzzle(config: Dictionary):
	"""Configure the puzzle with custom parameters"""
	if config.has("sentence"):
		sentence_text = config["sentence"]
	if config.has("blank_word"):
		blank_word = config["blank_word"]
	if config.has("correct_index"):
		correct_answer_index = config["correct_index"]
	if config.has("choices"):
		choices = config["choices"]

	# Re-setup UI with new configuration
	if is_node_ready():
		_setup_ui()
