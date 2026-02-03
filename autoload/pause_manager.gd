extends Node

# Pause Manager - Handles escape key to pause/resume game and show pause menu

const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const TEMP_SAVE_SLOT := "_pause_temp"

var pause_menu_instance: Control = null
var is_paused := false
var was_dialogic_paused := false

# Tracks whether we're in a context where pausing is allowed
var pause_enabled := false

func _ready() -> void:
	# Listen for when Dialogic starts/ends to enable/disable pausing
	if Dialogic.timeline_started.is_connected(_on_timeline_started) == false:
		Dialogic.timeline_started.connect(_on_timeline_started)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended) == false:
		Dialogic.timeline_ended.connect(_on_timeline_ended)

func _on_timeline_started() -> void:
	pause_enabled = true
	# Ensure Dialogic is not paused when timeline starts
	Dialogic.paused = false

func _on_timeline_ended() -> void:
	pause_enabled = false
	# Clean up pause menu if open when timeline ends
	if is_paused:
		_resume_game()

func _input(event: InputEvent) -> void:
	# Quick Save (F5)
	if event.is_action_pressed("quick_save") and pause_enabled and not is_paused:
		_quick_save()
		get_viewport().set_input_as_handled()
		return

	# Quick Load (F9)
	if event.is_action_pressed("quick_load") and pause_enabled and not is_paused:
		_quick_load()
		get_viewport().set_input_as_handled()
		return

	# Pause/Resume (ESC)
	if event.is_action_pressed("ui_cancel"):
		# Check if save/load screen is open - if so, don't handle ESC here
		if _is_save_load_screen_active():
			return

		if is_paused:
			_resume_game()
			get_viewport().set_input_as_handled()
		elif pause_enabled:
			_pause_game()
			get_viewport().set_input_as_handled()

## Check if a save/load screen is currently active
func _is_save_load_screen_active() -> bool:
	# Check if any save/load screen exists in the scene tree
	for node in get_tree().root.get_children():
		if node is CanvasLayer:
			for child in node.get_children():
				if child.get_script() and child.get_script().resource_path.ends_with("save_load_screen.gd"):
					return true
		elif node.get_script() and node.get_script().resource_path.ends_with("save_load_screen.gd"):
			return true
	return false

func _pause_game() -> void:
	if is_paused:
		return

	is_paused = true

	# Store Dialogic's pause state and pause it
	was_dialogic_paused = Dialogic.paused
	Dialogic.paused = true

	# Create and show pause menu
	pause_menu_instance = PAUSE_MENU_SCENE.instantiate()
	pause_menu_instance.resumed.connect(_on_resume)
	pause_menu_instance.settings_requested.connect(_on_settings)
	pause_menu_instance.main_menu_requested.connect(_on_main_menu)

	# Add to a CanvasLayer to ensure it's on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.add_child(pause_menu_instance)
	get_tree().root.add_child(canvas_layer)

func _resume_game() -> void:
	if not is_paused:
		return

	is_paused = false

	# Remove pause menu
	if pause_menu_instance and is_instance_valid(pause_menu_instance):
		var canvas_layer = pause_menu_instance.get_parent()
		pause_menu_instance.queue_free()
		if canvas_layer:
			canvas_layer.queue_free()
		pause_menu_instance = null

	# Restore Dialogic's pause state
	Dialogic.paused = was_dialogic_paused

func _on_resume() -> void:
	_resume_game()

func _on_settings() -> void:
	# Don't use Dialogic.Save - it causes freed instance errors when returning
	# Instead, just load settings scene on top of the current scene

	# Hide pause menu but keep is_paused true so game stays frozen
	if pause_menu_instance and is_instance_valid(pause_menu_instance):
		pause_menu_instance.hide()

	# Set flag so settings menu knows it was opened from pause
	var SettingsMenu = load("res://scripts/settings_menu.gd")
	SettingsMenu.opened_from_pause = true

	# Load settings scene on top (don't change scene, just instantiate)
	var settings_scene = load("res://scenes/ui/settings_menu.tscn")
	var settings_instance = settings_scene.instantiate()

	# Add to a high-layer CanvasLayer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 102  # Higher than pause menu (100)
	canvas_layer.add_child(settings_instance)
	get_tree().root.add_child(canvas_layer)

	# Connect the signal - it's available immediately after instantiation
	if settings_instance.has_signal("back_pressed"):
		settings_instance.back_pressed.connect(_on_settings_back.bind(canvas_layer))
		print("Settings back_pressed signal connected successfully")
	else:
		print("ERROR: Settings instance doesn't have back_pressed signal!")

func _on_settings_back(canvas_layer: CanvasLayer) -> void:
	# Clean up settings scene
	if is_instance_valid(canvas_layer):
		canvas_layer.queue_free()

	# Show pause menu again
	if pause_menu_instance and is_instance_valid(pause_menu_instance):
		pause_menu_instance.show()
		# Refocus on resume button
		var resume_button = pause_menu_instance.get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton")
		if resume_button:
			resume_button.grab_focus()

func _on_main_menu() -> void:
	# Save game progress before returning to main menu
	Dialogic.Save.save("continue_save", false, Dialogic.Save.ThumbnailMode.NONE)
	PlayerStats.save_stats()

	# Clean up any active minigame before going to main menu
	if MinigameManager and MinigameManager.current_minigame:
		if is_instance_valid(MinigameManager.current_minigame):
			MinigameManager.current_minigame.queue_free()
		MinigameManager.current_minigame = null
		print("Cleaned up active minigame before going to main menu")

	# End the current timeline FIRST to properly clean up Dialogic state
	Dialogic.end_timeline()

	# Wait a frame to ensure Dialogic cleanup is complete
	await get_tree().process_frame

	# Clean up pause menu
	_resume_game()

	# Now change to main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# Called by settings menu to restore game state
static func restore_from_pause() -> void:
	Dialogic.Save.load(TEMP_SAVE_SLOT)

# Quick Save functionality
func _quick_save() -> void:
	if not SaveManager:
		_show_notification("Save System Not Ready!", Color.RED)
		return

	var success = await SaveManager.quick_save()
	if success:
		_show_notification("Quick Saved!", Color.GREEN)
	else:
		_show_notification("Quick Save Failed!", Color.RED)

# Quick Load functionality
func _quick_load() -> void:
	if not SaveManager:
		_show_notification("Save System Not Ready!", Color.RED)
		return

	if not SaveManager.has_save(SaveManager.QUICKSAVE_SLOT):
		_show_notification("No Quick Save Found!", Color.ORANGE)
		return

	var success = await SaveManager.quick_load()
	if success:
		_show_notification("Quick Loaded!", Color.GREEN)
	else:
		_show_notification("Quick Load Failed!", Color.RED)

# Show a temporary notification on screen
func _show_notification(text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.modulate = color

	# Position at top center
	label.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, 50)

	get_tree().root.add_child(label)

	# Fade out and remove
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.5).set_delay(1.5)
	tween.tween_callback(label.queue_free)
