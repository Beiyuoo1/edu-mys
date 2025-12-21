# AnswerObject.gd - Attach to AnswerObject scene
extends CharacterBody2D

var answer_text = ""
var is_correct = false

@export var move_speed = 80.0
var direction = Vector2.ZERO
var change_direction_timer = 0.0

func _ready():
	$Label.text = answer_text
	
	# All answers look the same - yellow/gold color
	$ColorRect.color = Color(0.9, 0.8, 0.2)
	
	# Add to group for collision detection
	$Area2D.add_to_group("answer")
	
	# Set initial random direction
	randomize_direction()

func _physics_process(delta):
	# Change direction periodically
	change_direction_timer -= delta
	if change_direction_timer <= 0:
		randomize_direction()
		change_direction_timer = randf_range(2.0, 4.0)
	
	# Move in current direction
	velocity = direction * move_speed
	move_and_slide()
	
	# Bounce off screen bounds
	var screen_size = get_viewport_rect().size
	if position.x < 40 or position.x > screen_size.x - 40:
		direction.x = -direction.x
		position.x = clamp(position.x, 40, screen_size.x - 40)
	if position.y < 40 or position.y > screen_size.y - 40:
		direction.y = -direction.y
		position.y = clamp(position.y, 40, screen_size.y - 40)

func randomize_direction():
	var angle = randf() * TAU  # Random angle in radians
	direction = Vector2(cos(angle), sin(angle)).normalized()
