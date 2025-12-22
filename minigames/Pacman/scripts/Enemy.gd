# Enemy.gd - Attach to Enemy scene
extends CharacterBody2D

var player_position = Vector2.ZERO

@export var chase_speed = 120.0

func _ready():
	# Add to group for collision detection
	$Area2D.add_to_group("enemy")

func _physics_process(delta):
	if player_position != Vector2.ZERO:
		# Chase the player
		var direction = (player_position - position).normalized()
		velocity = direction * chase_speed
		move_and_slide()
		
		# Keep in screen bounds
		var screen_size = get_viewport_rect().size
		position.x = clamp(position.x, 20, screen_size.x - 20)
		position.y = clamp(position.y, 20, screen_size.y - 20)