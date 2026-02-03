extends PanelContainer

## Save Slot Button - Displays save slot info and handles interaction

signal slot_clicked(slot_id: int, mode: int)

var slot_data: SaveManager.SaveSlot
var current_mode: int  # SaveLoadScreen.Mode enum

@onready var thumbnail: TextureRect = $MarginContainer/HBoxContainer/Thumbnail
@onready var slot_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/SlotLabel
@onready var timestamp_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/TimestampLabel
@onready var chapter_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/ChapterLabel
@onready var score_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/ScoreLabel
@onready var action_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/ButtonContainer/ActionButton
@onready var delete_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/ButtonContainer/DeleteButton

const EMPTY_SLOT_COLOR = Color(0.2, 0.2, 0.25, 0.8)
const FILLED_SLOT_COLOR = Color(0.15, 0.25, 0.35, 0.9)

func setup(slot: SaveManager.SaveSlot, mode: int, custom_label: String = "") -> void:
	slot_data = slot
	current_mode = mode

	# Set slot label
	if custom_label:
		slot_label.text = custom_label
	elif slot.slot_id == SaveManager.QUICKSAVE_SLOT:
		slot_label.text = "Quick Save"
	elif slot.slot_id < 0:
		slot_label.text = "Auto Save " + str(abs(slot.slot_id))
	else:
		slot_label.text = "Slot " + str(slot.slot_id)

	# Check if slot is empty
	var is_empty = slot.timestamp == 0

	if is_empty:
		_setup_empty_slot()
	else:
		_setup_filled_slot()

func _setup_empty_slot() -> void:
	# Update UI for empty slot
	timestamp_label.text = "Empty Slot"
	chapter_label.text = ""
	score_label.text = ""

	# Set empty thumbnail
	thumbnail.texture = null
	var style = get_theme_stylebox("panel", "PanelContainer").duplicate()
	if style is StyleBoxFlat:
		style.bg_color = EMPTY_SLOT_COLOR
	add_theme_stylebox_override("panel", style)

	# Update buttons
	if current_mode == 0:  # SAVE mode
		action_button.text = "Save Here"
		action_button.disabled = false
		delete_button.visible = false
	else:  # LOAD mode
		action_button.text = "Load"
		action_button.disabled = true
		delete_button.visible = false

func _setup_filled_slot() -> void:
	# Update UI for filled slot
	timestamp_label.text = SaveManager.format_timestamp(slot_data.timestamp)
	chapter_label.text = "Chapter " + str(slot_data.chapter) + " - " + slot_data.scene_name
	score_label.text = "Level " + str(slot_data.player_level) + " | Score: " + str(slot_data.total_score)

	# Load thumbnail
	_load_thumbnail()

	# Style for filled slot
	var style = get_theme_stylebox("panel", "PanelContainer").duplicate()
	if style is StyleBoxFlat:
		style.bg_color = FILLED_SLOT_COLOR
		style.border_color = Color(0.5, 0.7, 0.9, 1)
	add_theme_stylebox_override("panel", style)

	# Update buttons
	if current_mode == 0:  # SAVE mode
		action_button.text = "Overwrite"
		action_button.disabled = false
		delete_button.visible = true
	else:  # LOAD mode
		action_button.text = "Load"
		action_button.disabled = false
		delete_button.visible = true

func _load_thumbnail() -> void:
	if not slot_data.screenshot_path or not FileAccess.file_exists(slot_data.screenshot_path):
		# Use placeholder or game logo
		thumbnail.texture = null
		return

	var img = Image.load_from_file(slot_data.screenshot_path)
	if img:
		var texture = ImageTexture.create_from_image(img)
		thumbnail.texture = texture
	else:
		thumbnail.texture = null

func _on_action_button_pressed() -> void:
	slot_clicked.emit(slot_data.slot_id, current_mode)

func _on_delete_button_pressed() -> void:
	# Confirm deletion
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Delete this save?"
	dialog.confirmed.connect(_perform_delete)
	add_child(dialog)
	dialog.popup_centered()

func _perform_delete() -> void:
	SaveManager.delete_save(slot_data.slot_id)
	# Refresh parent screen
	var parent = get_parent().get_parent().get_parent().get_parent()
	if parent.has_method("refresh_slots"):
		parent.refresh_slots()
