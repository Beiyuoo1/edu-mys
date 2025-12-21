# Main.gd - Attach this to your main game node
extends Node2D

# Question database
var questions = [
	{
		"question": "What is the capital of France?",
		"correct": "Paris",
		"wrong": ["London", "Berlin", "Madrid"]
	},
	{
		"question": "What is 5 + 7?",
		"correct": "12",
		"wrong": ["13", "11", "14"]
	},
	{
		"question": "What color is the sky?",
		"correct": "Blue",
		"wrong": ["Red", "Green", "Yellow"]
	},
	{
		"question": "How many continents are there?",
		"correct": "7",
		"wrong": ["5", "6", "8"]
	}
]

var current_question = 0
var player = null
var answer_objects = []
var enemy_objects = []
var obstacle_objects = []
var score = 0
var game_over = false

func _ready():
	# Set fullscreen mode
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	start_game()

func start_game():
	game_over = false
	current_question = 0
	score = 0
	spawn_obstacles()
	spawn_player()
	spawn_enemies()
	load_question()

func spawn_player():
	# Remove old player if exists
	if player != null and is_instance_valid(player):
		player.queue_free()
	
	var player_scene = load("res://Player.tscn")
	player = player_scene.instantiate()
	var screen_size = get_viewport_rect().size
	player.position = screen_size / 2  # Center of screen
	add_child(player)
	player.connect("hit_answer", Callable(self, "_on_answer_hit"))
	player.connect("hit_enemy", Callable(self, "_on_enemy_hit"))

func spawn_obstacles():
	# Clear old obstacles
	for obstacle in obstacle_objects:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	obstacle_objects.clear()
	
	var screen_size = get_viewport_rect().size
	var obstacle_scene = load("res://Obstacle.tscn")
	
	# Create maze-like pattern
	var wall_configs = [
		# Horizontal walls
		{"pos": Vector2(screen_size.x * 0.25, screen_size.y * 0.25), "size": Vector2(200, 20), "rot": 0},
		{"pos": Vector2(screen_size.x * 0.75, screen_size.y * 0.25), "size": Vector2(200, 20), "rot": 0},
		{"pos": Vector2(screen_size.x * 0.25, screen_size.y * 0.75), "size": Vector2(200, 20), "rot": 0},
		{"pos": Vector2(screen_size.x * 0.75, screen_size.y * 0.75), "size": Vector2(200, 20), "rot": 0},
		{"pos": Vector2(screen_size.x * 0.5, screen_size.y * 0.4), "size": Vector2(250, 20), "rot": 0},
		{"pos": Vector2(screen_size.x * 0.5, screen_size.y * 0.6), "size": Vector2(250, 20), "rot": 0},
		# Vertical walls
		{"pos": Vector2(screen_size.x * 0.35, screen_size.y * 0.5), "size": Vector2(20, 150), "rot": 0},
		{"pos": Vector2(screen_size.x * 0.65, screen_size.y * 0.5), "size": Vector2(20, 150), "rot": 0},
		# Corner walls
		{"pos": Vector2(screen_size.x * 0.15, screen_size.y * 0.15), "size": Vector2(100, 20), "rot": 45},
		{"pos": Vector2(screen_size.x * 0.85, screen_size.y * 0.15), "size": Vector2(100, 20), "rot": -45},
		{"pos": Vector2(screen_size.x * 0.15, screen_size.y * 0.85), "size": Vector2(100, 20), "rot": -45},
		{"pos": Vector2(screen_size.x * 0.85, screen_size.y * 0.85), "size": Vector2(100, 20), "rot": 45},
	]
	
	for config in wall_configs:
		var obstacle = obstacle_scene.instantiate()
		obstacle.position = config.pos
		
		# Update collision shape and visual size
		var collision_shape = obstacle.get_node("CollisionShape2D")
		var shape = RectangleShape2D.new()
		shape.size = config.size
		collision_shape.shape = shape
		
		var color_rect = obstacle.get_node("ColorRect")
		color_rect.size = config.size
		color_rect.position = -config.size / 2
		
		obstacle.rotation_degrees = config.rot
		
		add_child(obstacle)
		obstacle_objects.append(obstacle)

func spawn_enemies():
	# Clear old enemies
	for enemy in enemy_objects:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemy_objects.clear()
	
	# Spawn 5 enemies at various positions
	var screen_size = get_viewport_rect().size
	var enemy_positions = [
		Vector2(100, 100),
		Vector2(screen_size.x - 100, 100),
		Vector2(screen_size.x / 2, screen_size.y - 100),
		Vector2(100, screen_size.y - 100),
		Vector2(screen_size.x - 100, screen_size.y - 100)
	]
	
	var enemy_scene = load("res://Enemy.tscn")
	for pos in enemy_positions:
		var enemy = enemy_scene.instantiate()
		enemy.position = pos
		add_child(enemy)
		enemy_objects.append(enemy)

func load_question():
	# Clear previous answer objects
	for obj in answer_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	answer_objects.clear()
	
	if current_question >= questions.size():
		show_victory()
		return
	
	var q = questions[current_question]
	$UI/QuestionLabel.text = q.question
	$UI/ScoreLabel.text = "Score: " + str(score)
	
	# Create list of all answers
	var all_answers = q.wrong.duplicate()
	all_answers.append(q.correct)
	all_answers.shuffle()
	
	# Spawn answer objects in different positions (avoiding center walls)
	var screen_size = get_viewport_rect().size
	var positions = [
		Vector2(screen_size.x * 0.15, screen_size.y * 0.3),
		Vector2(screen_size.x * 0.85, screen_size.y * 0.3),
		Vector2(screen_size.x * 0.15, screen_size.y * 0.7),
		Vector2(screen_size.x * 0.85, screen_size.y * 0.7)
	]
	
	var answer_scene = load("res://AnswerObject.tscn")
	for i in range(all_answers.size()):
		var answer_obj = answer_scene.instantiate()
		answer_obj.position = positions[i]
		answer_obj.answer_text = all_answers[i]
		answer_obj.is_correct = (all_answers[i] == q.correct)
		add_child(answer_obj)
		answer_objects.append(answer_obj)

func _on_answer_hit(answer_text, is_correct):
	if is_correct:
		score += 1
		current_question += 1
		await get_tree().create_timer(0.5).timeout
		load_question()

func _on_enemy_hit():
	show_game_over()

func show_game_over():
	game_over = true
	$UI/QuestionLabel.text = "Game Over! Final Score: " + str(score) + "\nPress R to restart"
	
	# Clear all objects
	for obj in answer_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	answer_objects.clear()
	
	if player != null and is_instance_valid(player):
		player.queue_free()
		player = null

func show_victory():
	game_over = true
	$UI/QuestionLabel.text = "You Win! Final Score: " + str(score) + "\nPress R to play again"

func _process(delta):
	# Restart game
	if Input.is_key_pressed(KEY_R) and game_over:
		start_game()
	
	# Update enemies with player position
	if is_instance_valid(player):
		for enemy in enemy_objects:
			if is_instance_valid(enemy):
				enemy.player_position = player.position
