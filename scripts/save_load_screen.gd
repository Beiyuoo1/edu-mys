extends Control

## Save/Load Screen - Renpy-style save/load interface

enum Mode { SAVE, LOAD }

var current_mode: Mode = Mode.SAVE
var current_tab: String = "manual"  # "manual" or "auto"

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/Title
@onready var close_button: Button = $MarginContainer/VBoxContainer/Header/CloseButton
@onready var manual_saves_tab: Button = $MarginContainer/VBoxContainer/TabContainer/ManualSavesTab
@onready var auto_saves_tab: Button = $MarginContainer/VBoxContainer/TabContainer/AutoSavesTab
@onready var save_slots_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/SaveSlotsContainer

var save_slot_button_scene: PackedScene

func _ready() -> void:
	# Check if SaveManager is available
	if not SaveManager:
		push_error("SaveManager not available - please reload the project!")
		queue_free()
		return

	# Load save slot button scene dynamically
	save_slot_button_scene = load("res://scenes/ui/save_slot_button.tscn")

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

	# Connect tab buttons
	if manual_saves_tab:
		manual_saves_tab.pressed.connect(_on_manual_saves_tab_pressed)
	if auto_saves_tab:
		auto_saves_tab.pressed.connect(_on_auto_saves_tab_pressed)

	update_title()
	refresh_slots()

func _input(event: InputEvent) -> void:
	# Handle ESC key to close the save/load screen
	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()

## Set the mode (Save or Load)
func set_mode(mode: Mode) -> void:
	current_mode = mode
	update_title()
	refresh_slots()

## Update title based on mode
func update_title() -> void:
	if current_mode == Mode.SAVE:
		title_label.text = "Save Game"
	else:
		title_label.text = "Load Game"

## Refresh the displayed save slots
func refresh_slots() -> void:
	# Clear existing slots
	for child in save_slots_container.get_children():
		child.queue_free()

	var slots: Array
	if current_tab == "manual":
		slots = SaveManager.get_manual_save_slots()
	else:
		slots = SaveManager.get_autosave_slots()

	# Create slot buttons
	for slot in slots:
		var slot_button = save_slot_button_scene.instantiate()
		save_slots_container.add_child(slot_button)
		slot_button.setup(slot, current_mode)
		slot_button.slot_clicked.connect(_on_slot_clicked)

	# Add quick save slot if in manual tab and load mode
	if current_tab == "manual" and current_mode == Mode.LOAD:
		if SaveManager.has_save(SaveManager.QUICKSAVE_SLOT):
			var quick_slot = SaveManager.get_save_slot(SaveManager.QUICKSAVE_SLOT)
			var slot_button = save_slot_button_scene.instantiate()
			save_slots_container.add_child(slot_button)
			slot_button.setup(quick_slot, current_mode, "Quick Save")
			slot_button.slot_clicked.connect(_on_slot_clicked)

func _on_slot_clicked(slot_id: int, mode: Mode) -> void:
	if mode == Mode.SAVE:
		# Confirm save
		var slot = SaveManager.get_save_slot(slot_id)
		if slot and slot.timestamp > 0:
			# Slot already has a save, confirm overwrite
			var confirm_text = "Overwrite save slot " + str(slot_id) + "?"
			_show_confirmation(confirm_text, func(): _perform_save(slot_id))
		else:
			# Empty slot, save directly
			_perform_save(slot_id)
	else:
		# Load game
		_perform_load(slot_id)

func _perform_save(slot_id: int) -> void:
	# Hide the save screen temporarily to capture gameplay
	hide()
	await get_tree().process_frame

	# Save with screenshot (now captures gameplay instead of save screen)
	var success = await SaveManager.save_game(slot_id, true)

	# Show the save screen again
	show()

	if success:
		_show_notification("Game Saved!")
		refresh_slots()
	else:
		_show_notification("Save Failed!")

func _perform_load(slot_id: int) -> void:
	var success = await SaveManager.load_game(slot_id)
	if success:
		_show_notification("Game Loaded!")
		await get_tree().create_timer(0.5).timeout
		queue_free()
	else:
		_show_notification("Load Failed!")

func _show_confirmation(text: String, callback: Callable) -> void:
	# Simple confirmation using AcceptDialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	dialog.confirmed.connect(callback)
	add_child(dialog)
	dialog.popup_centered()

func _show_notification(text: String) -> void:
	# Simple notification
	var label = Label.new()
	label.text = text
	label.position = Vector2(get_viewport_rect().size.x / 2 - 100, 50)
	label.modulate = Color.YELLOW
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.5).set_delay(1.0)
	tween.tween_callback(label.queue_free)

func _on_close_button_pressed() -> void:
	# Find and show the pause menu again
	var pause_menu = get_tree().root.get_node_or_null("CanvasLayer/PauseMenu")
	if pause_menu:
		pause_menu.show()
	queue_free()

func _on_manual_saves_tab_pressed() -> void:
	current_tab = "manual"
	auto_saves_tab.button_pressed = false
	manual_saves_tab.button_pressed = true
	refresh_slots()

func _on_auto_saves_tab_pressed() -> void:
	current_tab = "auto"
	manual_saves_tab.button_pressed = false
	auto_saves_tab.button_pressed = true
	refresh_slots()
