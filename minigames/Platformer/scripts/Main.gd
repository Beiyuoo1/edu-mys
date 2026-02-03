extends Node2D

signal game_finished(success: bool, score: int)

# Game configuration
var questions: Array = []
var current_question_index: int = 0
var correct_answers_needed: int = 3

# Game state
var score: int = 0
var health: int = 3
var game_active: bool = false
var level_width: float = 2000.0

# Scenes
var collectible_scene = preload("res://minigames/Platformer/scenes/Collectible.tscn")
var enemy_scene = preload("res://minigames/Platformer/scenes/Enemy.tscn")
var platform_scene = preload("res://minigames/Platformer/scenes/Platform.tscn")

# Current question
var current_correct_answer: String = ""
var current_wrong_answers: Array = []

func _ready():
	# Default questions for testing
	if questions.is_empty():
		questions = [
			{
				"question": "What is 3 + 4?",
				"correct": "7",
				"wrong": ["6", "8", "5"]
			},
			{
				"question": "What color is the sky?",
				"correct": "Blue",
				"wrong": ["Red", "Green", "Yellow"]
			},
			{
				"question": "How many legs does a spider have?",
				"correct": "8",
				"wrong": ["6", "4", "10"]
			}
		]

	_start_game()

func configure_puzzle(config: Dictionary):
	if config.has("questions"):
		questions = config.questions
	if config.has("answers_needed"):
		correct_answers_needed = config.answers_needed
	if config.has("level_width"):
		level_width = config.level_width

func _start_game():
	game_active = true
	score = 0
	health = 3
	current_question_index = 0

	_load_question()  # Must be called before _generate_level to set up answers
	_generate_level()
	_update_ui()

func _load_question():
	if current_question_index >= questions.size():
		current_question_index = 0

	var q = questions[current_question_index]
	current_correct_answer = q.correct
	current_wrong_answers = q.wrong.duplicate()

	$UILayer/QuestionLabel.text = q.question

func _generate_level():
	# Clear any existing generated content
	for child in $GameLayer/Platforms.get_children():
		child.queue_free()
	for child in $GameLayer/Collectibles.get_children():
		child.queue_free()
	for child in $GameLayer/Enemies.get_children():
		child.queue_free()

	var player = $GameLayer/Player
	var ground_y = 550  # Ground level

	# Create starting platform
	var start_platform = platform_scene.instantiate()
	start_platform.position = Vector2(100, ground_y)
	$GameLayer/Platforms.add_child(start_platform)

	# Player starts on first platform
	player.position = Vector2(100, ground_y - 30)

	# Generate level as connected platforms with jumps
	var x_pos = 250.0
	var current_y = ground_y
	var platform_count = 0
	var correct_spawned = 0

	while x_pos < level_width - 200:
		# Vary height - go up or down but stay in range
		var y_change = randi_range(-80, 60)
		current_y = clamp(current_y + y_change, 300, ground_y)

		# Create platform
		var platform = platform_scene.instantiate()
		platform.position = Vector2(x_pos, current_y)
		$GameLayer/Platforms.add_child(platform)

		# Add collectible floating above platform
		if randf() < 0.6 or correct_spawned < correct_answers_needed:
			var collectible = collectible_scene.instantiate()
			collectible.position = Vector2(x_pos, current_y - 60)

			# Ensure enough correct answers spawn
			var spawn_correct = false
			if correct_spawned < correct_answers_needed and randf() < 0.5:
				spawn_correct = true
			elif correct_spawned >= correct_answers_needed:
				spawn_correct = false

			if spawn_correct:
				collectible.setup(current_correct_answer, true)
				correct_spawned += 1
			else:
				var wrong = current_wrong_answers[randi() % current_wrong_answers.size()]
				collectible.setup(wrong, false)

			collectible.collected.connect(_on_collectible_collected)
			$GameLayer/Collectibles.add_child(collectible)

		# Add enemy on some platforms (not too many)
		if randf() < 0.2 and platform_count > 2:
			var enemy = enemy_scene.instantiate()
			enemy.position = Vector2(x_pos, current_y - 25)
			enemy.hit_player.connect(_on_enemy_hit)
			$GameLayer/Enemies.add_child(enemy)

		# Space between platforms - jumpable distance
		x_pos += randi_range(120, 180)
		platform_count += 1

	# Final platform with goal
	var final_platform = platform_scene.instantiate()
	final_platform.position = Vector2(level_width - 150, ground_y)
	$GameLayer/Platforms.add_child(final_platform)

	# Goal flag on final platform
	$GameLayer/Goal.position = Vector2(level_width - 150, ground_y - 40)

func _on_collectible_collected(is_correct: bool):
	if is_correct:
		score += 100
		_flash_screen(Color(0.2, 0.8, 0.2, 0.3))

		current_question_index += 1
		_load_question()

		if score >= correct_answers_needed * 100:
			_end_game(true)
	else:
		health -= 1
		_flash_screen(Color(0.8, 0.2, 0.2, 0.4))
		_shake_screen()

		if health <= 0:
			_end_game(false)

	_update_ui()

func _on_enemy_hit():
	var player = $GameLayer/Player
	if player.is_invincible:
		return

	health -= 1
	player.take_damage()
	_flash_screen(Color(0.8, 0.2, 0.2, 0.4))
	_shake_screen()

	if health <= 0:
		_end_game(false)

	_update_ui()

func _on_goal_reached(body):
	if not body.is_in_group("player"):
		return

	if score >= correct_answers_needed * 100:
		_end_game(true)
	else:
		$UILayer/QuestionLabel.text = "Collect more correct answers! (" + str(score/100) + "/" + str(correct_answers_needed) + ")"

func _flash_screen(color: Color):
	$UILayer/FlashRect.color = color
	$UILayer/FlashRect.show()

	var tween = create_tween()
	tween.tween_property($UILayer/FlashRect, "color:a", 0.0, 0.3)
	tween.tween_callback($UILayer/FlashRect.hide)

func _shake_screen():
	# CanvasLayer uses 'offset' instead of 'position'
	var original_offset = $GameLayer.offset
	var tween = create_tween()

	for i in range(5):
		var shake_offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		tween.tween_property($GameLayer, "offset", original_offset + shake_offset, 0.04)

	tween.tween_property($GameLayer, "offset", original_offset, 0.04)

func _update_ui():
	$UILayer/ScoreLabel.text = "Score: " + str(score)
	$UILayer/HealthLabel.text = "Health: " + "❤️".repeat(health)
	$UILayer/ProgressLabel.text = str(score / 100) + "/" + str(correct_answers_needed)

func _process(_delta):
	if not game_active:
		return

	# Camera follows player (Node2D uses 'position', not 'offset')
	var player = $GameLayer/Player
	if player:
		$GameLayer.position.x = -player.position.x + 200
		$GameLayer.position.x = clamp($GameLayer.position.x, -(level_width - 600), 0)

func _end_game(success: bool):
	game_active = false

	$UILayer/ResultPanel.show()

	if success:
		$UILayer/ResultPanel/ResultLabel.text = "Level Complete!\nScore: " + str(score)
		$UILayer/ResultPanel/ResultLabel.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	else:
		$UILayer/ResultPanel/ResultLabel.text = "Game Over\nScore: " + str(score)
		$UILayer/ResultPanel/ResultLabel.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

	await get_tree().create_timer(2.5).timeout
	game_finished.emit(success, score)
	# Wait a frame to ensure signal is processed before cleanup
	await get_tree().process_frame
	queue_free()
