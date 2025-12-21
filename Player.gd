# Player.gd - Attach to Player scene
extends CharacterBody2D

signal hit_answer(answer_text, is_correct)
signal hit_enemy()

@export var speed = 300.0

func _ready():
	# Connect collision detection
	$CollisionArea.connect("area_entered", Callable(self, "_on_area_entered"))

func _physics_process(delta):
	# Get input direction
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	
	# Normalize and apply speed
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	velocity = input_dir * speed
	move_and_slide()
	
	# Keep player in screen bounds
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 20, screen_size.x - 20)
	position.y = clamp(position.y, 20, screen_size.y - 20)

func _on_area_entered(area):
	if area.is_in_group("answer"):
		var answer_obj = area.get_parent()
		emit_signal("hit_answer", answer_obj.answer_text, answer_obj.is_correct)
		if answer_obj.is_correct:
			answer_obj.queue_free()
	elif area.is_in_group("enemy"):
		emit_signal("hit_enemy")