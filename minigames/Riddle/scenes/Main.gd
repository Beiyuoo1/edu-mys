extends CanvasLayer

# Node references
@onready var timer_label = $Control/MainContainer/HeaderContainer/TimerLabel
@onready var hint_button = $Control/MainContainer/HeaderContainer/HintButton
@onready var hint_label = $Control/MainContainer/HeaderContainer/HintLabel
@onready var title_label = $Control/MainContainer/InstructionPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var riddle_label = $Control/MainContainer/RiddlePanel/MarginContainer/RiddleLabel
@onready var answer_display = $Control/MainContainer/AnswerContainer/AnswerDisplay
@onready var letter_container = $Control/MainContainer/LetterContainer
@onready var feedback_label = $Control/MainContainer/FeedbackLabel

# Letter buttons (2 rows)
@onready var letter_buttons_row1 = [
	$Control/MainContainer/LetterContainer/Row1/Letter1,
	$Control/MainContainer/LetterContainer/Row1/Letter2,
	$Control/MainContainer/LetterContainer/Row1/Letter3,
	$Control/MainContainer/LetterContainer/Row1/Letter4,
	$Control/MainContainer/LetterContainer/Row1/Letter5,
	$Control/MainContainer/LetterContainer/Row1/Letter6,
	$Control/MainContainer/LetterContainer/Row1/Letter7,
	$Control/MainContainer/LetterContainer/Row1/Letter8
]

@onready var letter_buttons_row2 = [
	$Control/MainContainer/LetterContainer/Row2/Letter9,
	$Control/MainContainer/LetterContainer/Row2/Letter10,
	$Control/MainContainer/LetterContainer/Row2/Letter11,
	$Control/MainContainer/LetterContainer/Row2/Letter12,
	$Control/MainContainer/LetterContainer/Row2/Letter13,
	$Control/MainContainer/LetterContainer/Row2/Letter14,
	$Control/MainContainer/LetterContainer/Row2/Letter15,
	$Control/MainContainer/LetterContainer/Row2/Letter16
]

# Timer
var time_remaining: float = 90.0  # 1:30 in seconds
var timer_active: bool = false

# Puzzle configuration
var riddle_text: String = "Round I go, around your hand,\nI shine and sparkle, isn't that grand?"
var correct_answer: String = "BRACELET"
var available_letters: Array = ["A", "B", "G", "T", "M", "R", "T", "K", "E", "C", "L", "E", "O", "I", "L", "G", "U", "N"]

# Current answer
var current_answer: String = ""
var current_answer_buttons: Array = []  # Track which buttons were used in order
var letter_buttons: Array = []

# Hint system
var hint_used: bool = false

# Time tracking for bonus hint
var start_time: float = 0.0
const TIME_BONUS_THRESHOLD: float = 60.0  # Complete within 1 minute for bonus hint

signal minigame_completed(success: bool)

func _ready():
	print("DEBUG: Riddle minigame _ready() called")

	# Make sure the control is visible
	visible = true

	# Record start time for bonus hint
	start_time = Time.get_ticks_msec() / 1000.0

	# Combine letter button arrays
	letter_buttons = letter_buttons_row1 + letter_buttons_row2

	# Verify node references
	_verify_nodes()

	# Set up UI
	_setup_ui()

	# Connect button signals
	_connect_buttons()

	# Start timer
	timer_active = true

func _verify_nodes():
	"""Verify all node references exist"""
	if timer_label == null:
		push_error("Riddle: timer_label is null!")
	if hint_button == null:
		push_error("Riddle: hint_button is null!")
	if hint_label == null:
		push_error("Riddle: hint_label is null!")
	if title_label == null:
		push_error("Riddle: title_label is null!")
	if riddle_label == null:
		push_error("Riddle: riddle_label is null!")
	if answer_display == null:
		push_error("Riddle: answer_display is null!")

func _setup_ui():
	"""Initialize UI elements"""
	if title_label:
		title_label.text = "\"Riddle, What Am I.\""
	if riddle_label:
		riddle_label.text = riddle_text

	# Update hint display from PlayerStats
	_update_hint_display()

	# Scramble the letters array
	available_letters.shuffle()

	# Set letter button labels
	for i in range(letter_buttons.size()):
		if letter_buttons[i] == null:
			push_error("Riddle: letter_buttons[" + str(i) + "] is null!")
			continue
		if i < available_letters.size():
			letter_buttons[i].text = available_letters[i]
			letter_buttons[i].visible = true
		else:
			letter_buttons[i].visible = false

	# Initialize answer display with blanks
	_update_answer_display()

	if feedback_label:
		feedback_label.visible = false

func _connect_buttons():
	"""Connect all button signals"""
	# Connect letter buttons
	for i in range(letter_buttons.size()):
		if letter_buttons[i]:
			letter_buttons[i].pressed.connect(_on_letter_pressed.bind(i))

	# Connect hint button
	if hint_button:
		hint_button.pressed.connect(_on_hint_pressed)

	# Make answer display clickable to remove letters
	if answer_display:
		answer_display.gui_input.connect(_on_answer_display_clicked)

func _process(delta):
	if timer_active:
		time_remaining -= delta
		if time_remaining <= 0:
			time_remaining = 0
			timer_active = false
			_on_time_up()

		_update_timer_display()

func _update_timer_display():
	if not timer_label:
		return
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func _update_answer_display():
	"""Update the answer display with current letters"""
	var display_text = ""
	for i in range(correct_answer.length()):
		if i < current_answer.length():
			display_text += current_answer[i] + " "
		else:
			display_text += "_ "

	if answer_display:
		answer_display.text = display_text.strip_edges()

func _on_time_up():
	"""Called when timer reaches zero"""
	feedback_label.text = "Time's up! The answer was: " + correct_answer
	feedback_label.add_theme_color_override("font_color", Color.ORANGE)
	feedback_label.visible = true

	# Disable all buttons
	for button in letter_buttons:
		button.disabled = true

	await get_tree().create_timer(3.0).timeout
	_complete_minigame(false)

func _on_letter_pressed(letter_index: int):
	"""Called when player presses a letter"""
	var letter = available_letters[letter_index]
	print("DEBUG: Letter pressed: ", letter)

	# Add letter to current answer
	current_answer += letter
	current_answer_buttons.append(letter_index)

	# Disable the button so it can't be clicked again
	letter_buttons[letter_index].disabled = true

	# Update display
	_update_answer_display()

	# Check if answer is complete
	if current_answer.length() == correct_answer.length():
		_check_answer()

func _on_answer_display_clicked(event: InputEvent):
	"""Called when player clicks on the answer display to undo last letter"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_undo_last_letter()

func _undo_last_letter():
	"""Remove the last letter from the answer"""
	if current_answer.length() == 0:
		return

	# Get the last button index
	var last_button_index = current_answer_buttons[current_answer_buttons.size() - 1]

	# Remove last letter from answer
	current_answer = current_answer.substr(0, current_answer.length() - 1)
	current_answer_buttons.remove_at(current_answer_buttons.size() - 1)

	# Re-enable the button
	letter_buttons[last_button_index].disabled = false

	# Update display
	_update_answer_display()

func _check_answer():
	"""Check if the current answer is correct"""
	print("DEBUG: Checking answer: ", current_answer, " vs ", correct_answer)

	if current_answer.to_upper() == correct_answer.to_upper():
		# Correct answer - finish the minigame
		# Disable all buttons
		for button in letter_buttons:
			button.disabled = true
		timer_active = false
		_show_correct_feedback()
	else:
		# Wrong answer - allow retry
		_show_wrong_feedback_retry()

func _show_correct_feedback():
	"""Show feedback for correct answer"""
	var completion_time = (Time.get_ticks_msec() / 1000.0) - start_time

	# Check if player earned a bonus hint (completed within 1 minute)
	var bonus_hint_earned = completion_time <= TIME_BONUS_THRESHOLD

	if bonus_hint_earned:
		PlayerStats.add_hints(1)
		feedback_label.text = "Correct! The answer is " + correct_answer + "!\n⚡ Speed Bonus: +1 Hint! ⚡"
		print("DEBUG: Bonus hint earned! Completion time: ", completion_time, "s")
	else:
		feedback_label.text = "Correct! The answer is " + correct_answer + "!"

	feedback_label.add_theme_color_override("font_color", Color.GREEN)
	feedback_label.visible = true

	await get_tree().create_timer(3.0).timeout
	_complete_minigame(true)

func _show_wrong_feedback_retry():
	"""Show feedback for wrong answer and allow retry"""
	feedback_label.text = "Wrong! Try again! Click the answer to undo letters."
	feedback_label.add_theme_color_override("font_color", Color.ORANGE)
	feedback_label.visible = true

	# Briefly flash red on the answer display
	if answer_display:
		var tween = create_tween()
		tween.tween_property(answer_display, "modulate", Color.RED, 0.2)
		tween.tween_property(answer_display, "modulate", Color.WHITE, 0.2)

	# Hide feedback after a moment
	await get_tree().create_timer(2.0).timeout
	feedback_label.visible = false

func _update_hint_display():
	"""Update hint label from PlayerStats"""
	if hint_label and PlayerStats:
		hint_label.text = "Hint: " + str(PlayerStats.hints)

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

		# Reveal the first letter if not already revealed
		if current_answer.length() < correct_answer.length():
			var next_letter = correct_answer[current_answer.length()]

			# Find and auto-click the button with that letter
			for i in range(available_letters.size()):
				if available_letters[i] == next_letter and not letter_buttons[i].disabled:
					# Highlight the button
					var tween = create_tween()
					tween.set_loops(3)
					tween.tween_property(letter_buttons[i], "modulate", Color.YELLOW, 0.3)
					tween.tween_property(letter_buttons[i], "modulate", Color.WHITE, 0.3)
					await tween.finished

					# Auto-click it
					_on_letter_pressed(i)
					break

		print("DEBUG: Hint used! Revealing next letter")
		print("DEBUG: Hints remaining: ", PlayerStats.hints)
	else:
		# No hints available
		feedback_label.text = "No hints available! Complete minigames quickly to earn more."
		feedback_label.add_theme_color_override("font_color", Color.ORANGE)
		feedback_label.visible = true
		await get_tree().create_timer(2.0).timeout
		feedback_label.visible = false

func _complete_minigame(success: bool):
	"""Complete the minigame"""
	minigame_completed.emit(success)
	queue_free()

# Configuration function for different puzzle variations
func configure_puzzle(config: Dictionary):
	"""Configure the puzzle with custom parameters"""
	if config.has("riddle"):
		riddle_text = config["riddle"]
	if config.has("answer"):
		correct_answer = config["answer"].to_upper()
	if config.has("letters"):
		available_letters = config["letters"]

	# Re-setup UI with new configuration
	if is_node_ready():
		_setup_ui()
