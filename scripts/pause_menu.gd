extends Control

@onready var resume_button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var save_button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SaveButton
@onready var load_button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LoadButton
@onready var settings_button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsButton
@onready var main_menu_button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MainMenuButton

signal resumed
signal settings_requested
signal main_menu_requested

const SAVE_LOAD_SCREEN = preload("res://scenes/ui/save_load_screen.tscn")

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# Focus on resume button by default
	resume_button.grab_focus()

func _on_resume_pressed() -> void:
	resumed.emit()

func _on_save_pressed() -> void:
	var save_screen = SAVE_LOAD_SCREEN.instantiate()
	save_screen.current_mode = 0  # Set mode before adding to tree

	# Add to a high-layer CanvasLayer to ensure it appears on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 101  # Higher than pause menu (100)
	canvas_layer.add_child(save_screen)
	get_tree().root.add_child(canvas_layer)

	# Connect close signal to clean up canvas layer
	save_screen.tree_exited.connect(func():
		if is_instance_valid(canvas_layer):
			canvas_layer.queue_free()
	)

	hide()

func _on_load_pressed() -> void:
	var load_screen = SAVE_LOAD_SCREEN.instantiate()
	load_screen.current_mode = 1  # Set mode before adding to tree

	# Add to a high-layer CanvasLayer to ensure it appears on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 101  # Higher than pause menu (100)
	canvas_layer.add_child(load_screen)
	get_tree().root.add_child(canvas_layer)

	# Connect close signal to clean up canvas layer
	load_screen.tree_exited.connect(func():
		if is_instance_valid(canvas_layer):
			canvas_layer.queue_free()
	)

	hide()

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()
