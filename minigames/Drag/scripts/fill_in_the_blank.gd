extends Control

# Signal to notify the main game when the puzzle is done
signal game_finished(success: bool, score: int)

# --- Puzzle Data (now dynamic) ---
# Default puzzle data - can be overridden via configure_puzzle()
var puzzle_data = {
	"sentence_parts": [
		"A function assigns each ", # Part 1
		" to exactly one ",          # Part 2
		"."                          # Part 3
	],
	"answers": ["input", "output"],
	"choices": [
		"input", "output", "domain", "range",
		"variable", "constant", "equation", "value"
	],
	"title": "Complete the Sentence",
	"subtitle": "Drag the correct words into the blanks",
	"context": ""
}

var is_configured = false
var is_ready = false

# --- Node Paths ---
var header_path = "CanvasLayer/TextureRect/CenterContainer/PanelContainer/"
var header_path2 = "AspectRatioContainer/MarginContainer/VBoxContainer/ColorRect/MarginContainer/VBoxContainer/"
var content_path = "CanvasLayer/TextureRect/CenterContainer/PanelContainer/"
var content_path2 = "AspectRatioContainer/MarginContainer/VBoxContainer/"

@onready var sentence_line = get_node(content_path + content_path2 + "HBoxContainer")
@onready var choices_grid = get_node(content_path + content_path2 + "GridContainer")
@onready var drop_zone_1 = get_node(content_path + content_path2 + "HBoxContainer/drop1")
@onready var texture_rect = $CanvasLayer/TextureRect

# Header labels (now configurable)
@onready var timer_label = get_node(header_path + header_path2 + "HBoxContainer/TimerLabel")
@onready var hint_button = get_node(header_path + header_path2 + "HBoxContainer/HintButton")
@onready var hint_label = get_node(header_path + header_path2 + "HBoxContainer/HintLabel")
@onready var title_label = get_node(header_path + header_path2 + "TitleLabel")
@onready var subtitle_label = get_node(header_path + header_path2 + "SubtitleLabel")
@onready var context_label = get_node(header_path + header_path2 + "ContextLabel")

# Timer
var time_remaining: float = 90.0  # 1:30 in seconds
var timer_active: bool = false

# Hint system
var hint_used: bool = false

# Time tracking for bonus hint
var start_time: float = 0.0
const TIME_BONUS_THRESHOLD: float = 60.0  # Complete within 1 minute for bonus hint

var correct_drops = 0
const TOTAL_DROPS = 1
const TILE_SCRIPT = preload("res://minigames/Drag/scripts/Tile.gd")
const DROP_SCRIPT = preload("res://minigames/Drag/scripts/DropZone.gd")

func _ready():
	is_ready = true
	# Quick fade-in for smooth transition
	texture_rect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(texture_rect, "modulate:a", 1.0, 0.15)

	# Record start time for bonus hint
	start_time = Time.get_ticks_msec() / 1000.0

	# Update hint display from PlayerStats
	_update_hint_display()

	# Connect hint button
	if hint_button:
		hint_button.pressed.connect(_on_hint_button_pressed)

	# Start timer
	timer_active = true

	# Initialize puzzle now that nodes are ready
	_initialize_puzzle()

func _process(delta):
	if timer_active:
		time_remaining -= delta
		_update_timer_display()

		if time_remaining <= 0:
			_on_time_up()

func _update_timer_display():
	if timer_label:
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		timer_label.text = "⏱️ %d:%02d" % [minutes, seconds]

		# Change color when time is running low
		if time_remaining <= 10:
			timer_label.add_theme_color_override("font_color", Color.RED)
		elif time_remaining <= 30:
			timer_label.add_theme_color_override("font_color", Color.YELLOW)

func _update_hint_display():
	if hint_label:
		hint_label.text = "Hints: %d" % PlayerStats.hints

func _on_hint_button_pressed():
	if hint_used:
		print("Hint already used for this puzzle!")
		return

	if not PlayerStats.use_hint():
		print("No hints available!")
		# Show feedback
		if hint_button:
			hint_button.text = "No hints!"
			await get_tree().create_timer(1.0).timeout
			hint_button.text = "💡 Hint"
		return

	hint_used = true
	_update_hint_display()
	_show_hint()

func _show_hint():
	# Highlight the correct answers with a pulsing yellow glow
	var correct_tiles = []

	# Find tiles with correct answers
	for i in range(choices_grid.get_child_count()):
		var tile_rect = choices_grid.get_child(i)
		# Check if the tile has word_data property and if it's a correct answer
		if "word_data" in tile_rect:
			if tile_rect.word_data in puzzle_data.answers:
				correct_tiles.append(tile_rect)

	# Pulse animation for correct tiles
	for tile in correct_tiles:
		var original_modulate = tile.modulate
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(tile, "modulate", Color.YELLOW, 0.5)
		tween.tween_property(tile, "modulate", original_modulate, 0.5)

func _on_time_up():
	timer_active = false
	if timer_label:
		timer_label.text = "⏱️ 0:00"
		timer_label.add_theme_color_override("font_color", Color.RED)

	# Show failure message
	print("Time's up! Puzzle failed.")

	# Fade out and emit failure signal
	var tween = create_tween()
	tween.tween_property(texture_rect, "modulate:a", 0.0, 0.2)
	await tween.finished
	emit_signal("game_finished", false, 0)
	await get_tree().process_frame
	queue_free()

# Configure puzzle with external data from MinigameManager
func configure_puzzle(config: Dictionary) -> void:
	puzzle_data = {
		"sentence_parts": config.get("sentence_parts", []),
		"answers": config.get("answers", []),
		"choices": config.get("choices", []),
		"title": config.get("title", "Complete the Sentence"),
		"subtitle": config.get("subtitle", "Drag the correct words into the blanks"),
		"context": config.get("context", "")
	}
	is_configured = true
	# Only initialize if _ready() has already run, otherwise _ready() will handle it
	if is_ready:
		_initialize_puzzle()

func _initialize_puzzle():
	# 0. Set header labels if configured
	if puzzle_data.has("title"):
		title_label.text = puzzle_data.title
	if puzzle_data.has("subtitle"):
		subtitle_label.text = puzzle_data.subtitle
	if puzzle_data.has("context"):
		context_label.text = puzzle_data.context

	# 1. Set the sentence labels
	var labels = sentence_line.get_children().filter(func(c): return c is Label)
	if labels.size() >= 3 and puzzle_data.sentence_parts.size() >= 3:
		labels[0].text = puzzle_data.sentence_parts[0]
		labels[1].text = puzzle_data.sentence_parts[1]
		labels[2].text = puzzle_data.sentence_parts[2]

	# 2. Attach and initialize Drop Zone scripts
	drop_zone_1.set_script(DROP_SCRIPT)
	drop_zone_1.expected_answer = puzzle_data.answers[0]
	drop_zone_1.minigame_scene = self
	drop_zone_1.name = "DropZone1"


	# 3. Initialize Draggable Tiles
	var choices = puzzle_data.choices.duplicate()
	choices.shuffle()

	for i in range(choices_grid.get_child_count()):
		var tile_rect = choices_grid.get_child(i)
		if i < choices.size():
			tile_rect.set_script(TILE_SCRIPT)
			tile_rect.word_data = choices[i]
			var label = tile_rect.get_node("Label")
			label.text = choices[i]
			# Force center alignment
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		else:
			tile_rect.visible = false

func check_win_condition(correctly_dropped):
	if correctly_dropped:
		correct_drops += 1

	if correct_drops == TOTAL_DROPS:
		# Stop timer
		timer_active = false

		# Check for speed bonus (completed in under 60 seconds)
		var completion_time = (Time.get_ticks_msec() / 1000.0) - start_time
		var earned_bonus = false
		if completion_time < TIME_BONUS_THRESHOLD:
			PlayerStats.add_hints(1)
			earned_bonus = true
			print("⚡ Speed Bonus: +1 Hint! ⚡")

		# Win condition achieved!
		print("Puzzle Solved!")

		# Show bonus message if earned
		if earned_bonus and title_label:
			title_label.text = "⚡ Speed Bonus: +1 Hint! ⚡"
			title_label.add_theme_color_override("font_color", Color.YELLOW)

		# Brief delay to show bonus message
		if earned_bonus:
			await get_tree().create_timer(1.5).timeout

		# Fade out before emitting signal and closing
		var tween = create_tween()
		tween.tween_property(texture_rect, "modulate:a", 0.0, 0.2)
		await tween.finished
		# Emit signal AFTER fade completes but BEFORE queue_free
		emit_signal("game_finished", true, 100)
		# Small delay to ensure signal is processed
		await get_tree().process_frame
		queue_free()
	else:
		# Optionally handle failure/time runs out here
		pass
