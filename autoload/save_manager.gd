extends Node

## SaveManager - Manages multiple save slots similar to Renpy
## Handles save/load operations, slot management, and thumbnails

signal save_completed(slot_id: int)
signal load_completed(slot_id: int)
signal save_deleted(slot_id: int)

const MAX_MANUAL_SLOTS := 10  # Manual save slots (1-10)
const AUTOSAVE_SLOTS := 3      # Auto-save slots (auto-1, auto-2, auto-3)
const QUICKSAVE_SLOT := 99     # Quick save slot

# Save slot data structure
class SaveSlot:
	var slot_id: int
	var timestamp: int  # Unix timestamp
	var chapter: int
	var scene_name: String
	var player_level: int
	var total_score: int
	var screenshot_path: String
	var dialogic_slot_name: String

	func _init(id: int) -> void:
		slot_id = id
		timestamp = 0
		chapter = 1
		scene_name = ""
		player_level = 1
		total_score = 0
		screenshot_path = ""
		dialogic_slot_name = _get_dialogic_slot_name(id)

	func _get_dialogic_slot_name(id: int) -> String:
		if id == QUICKSAVE_SLOT:
			return "quicksave"
		elif id < 0:  # Auto-save slots
			return "autosave_" + str(abs(id))
		else:
			return "save_" + str(id)

	func to_dict() -> Dictionary:
		return {
			"slot_id": slot_id,
			"timestamp": timestamp,
			"chapter": chapter,
			"scene_name": scene_name,
			"player_level": player_level,
			"total_score": total_score,
			"screenshot_path": screenshot_path,
			"dialogic_slot_name": dialogic_slot_name
		}

	func from_dict(data: Dictionary) -> void:
		slot_id = data.get("slot_id", slot_id)
		timestamp = data.get("timestamp", 0)
		chapter = data.get("chapter", 1)
		scene_name = data.get("scene_name", "")
		player_level = data.get("player_level", 1)
		total_score = data.get("total_score", 0)
		screenshot_path = data.get("screenshot_path", "")
		dialogic_slot_name = data.get("dialogic_slot_name", dialogic_slot_name)

var save_slots: Dictionary = {}  # slot_id -> SaveSlot
var current_autosave_index := 0  # Rotating auto-save index (0-2)

const SAVE_METADATA_PATH := "user://save_metadata.json"

func _ready() -> void:
	load_save_metadata()

## Save game to a specific slot
func save_game(slot_id: int, take_screenshot: bool = true) -> bool:
	var slot := SaveSlot.new(slot_id)
	slot.timestamp = Time.get_unix_time_from_system()
	slot.chapter = Dialogic.VAR.current_chapter if Dialogic.VAR.has("current_chapter") else 1
	slot.player_level = PlayerStats.level
	slot.total_score = PlayerStats.score

	# Get current timeline name for scene display
	var current_timeline = Dialogic.current_timeline
	if current_timeline:
		slot.scene_name = current_timeline.resource_path.get_file().get_basename()
	else:
		slot.scene_name = "Unknown"

	# Take screenshot for save slot thumbnail
	if take_screenshot:
		slot.screenshot_path = await _take_screenshot(slot_id)

	# Save Dialogic state (only if a timeline is active)
	if Dialogic.current_timeline and is_instance_valid(Dialogic.current_timeline):
		var dialogic_saved = Dialogic.Save.save(slot.dialogic_slot_name, false, Dialogic.Save.ThumbnailMode.NONE)
		if not dialogic_saved:
			push_error("Failed to save Dialogic state for slot " + str(slot_id))
			# Don't fail the entire save just because Dialogic save failed
			# The player stats and evidence will still be saved
			print("Warning: Dialogic state not saved, but continuing with save operation")
	else:
		print("Info: No active timeline - Dialogic state not saved for slot " + str(slot_id))

	# Save PlayerStats and Evidence to slot-specific files
	_save_slot_data(slot_id)

	# Store slot metadata
	save_slots[slot_id] = slot
	save_save_metadata()

	save_completed.emit(slot_id)
	print("Game saved to slot ", slot_id, " at ", Time.get_datetime_string_from_unix_time(slot.timestamp))
	return true

## Load game from a specific slot
func load_game(slot_id: int) -> bool:
	if not save_slots.has(slot_id):
		push_error("Save slot " + str(slot_id) + " does not exist")
		return false

	var slot: SaveSlot = save_slots[slot_id]

	# Clean up any active minigame before loading
	if MinigameManager and MinigameManager.current_minigame:
		if is_instance_valid(MinigameManager.current_minigame):
			MinigameManager.current_minigame.queue_free()
		MinigameManager.current_minigame = null
		print("Cleaned up active minigame before loading save")

	# If there's an active timeline, end it before loading
	# This prevents issues when loading during minigames or other scenes
	if Dialogic.current_timeline:
		Dialogic.end_timeline()
		# Wait a frame to ensure cleanup is complete
		await get_tree().process_frame

	# Load Dialogic state - check if the save file exists first
	if Dialogic.Save.has_slot(slot.dialogic_slot_name):
		var dialogic_loaded = Dialogic.Save.load(slot.dialogic_slot_name)
		if not dialogic_loaded:
			push_error("Failed to load Dialogic state from slot " + str(slot_id))
			return false
	else:
		push_warning("No Dialogic save found for slot " + str(slot_id) + ", skipping Dialogic load")

	# Load PlayerStats and Evidence from slot-specific files
	_load_slot_data(slot_id)

	load_completed.emit(slot_id)
	print("Game loaded from slot ", slot_id, " (", Time.get_datetime_string_from_unix_time(slot.timestamp), ")")
	return true

## Delete a save slot
func delete_save(slot_id: int) -> void:
	if not save_slots.has(slot_id):
		return

	var slot: SaveSlot = save_slots[slot_id]

	# Delete Dialogic save
	Dialogic.Save.delete_slot(slot.dialogic_slot_name)

	# Delete screenshot
	if slot.screenshot_path and FileAccess.file_exists(slot.screenshot_path):
		DirAccess.remove_absolute(slot.screenshot_path)

	# Delete slot-specific data file
	var slot_data_path = "user://slot_" + str(slot_id) + "_data.sav"
	if FileAccess.file_exists(slot_data_path):
		DirAccess.remove_absolute(slot_data_path)

	# Remove from metadata
	save_slots.erase(slot_id)
	save_save_metadata()

	save_deleted.emit(slot_id)
	print("Save slot ", slot_id, " deleted")

## Check if a save slot exists
func has_save(slot_id: int) -> bool:
	return save_slots.has(slot_id)

## Get save slot data
func get_save_slot(slot_id: int) -> SaveSlot:
	return save_slots.get(slot_id)

## Get all save slots sorted by timestamp (newest first)
func get_all_saves() -> Array[SaveSlot]:
	var slots: Array[SaveSlot] = []
	for slot in save_slots.values():
		slots.append(slot)
	slots.sort_custom(func(a, b): return a.timestamp > b.timestamp)
	return slots

## Quick save to dedicated quick save slot
func quick_save() -> bool:
	return await save_game(QUICKSAVE_SLOT, true)

## Quick load from quick save slot
func quick_load() -> bool:
	return await load_game(QUICKSAVE_SLOT)

## Auto-save (rotating through 3 auto-save slots)
func auto_save() -> bool:
	var slot_id = -(current_autosave_index + 1)  # -1, -2, -3
	var result = await save_game(slot_id, true)
	if result:
		current_autosave_index = (current_autosave_index + 1) % AUTOSAVE_SLOTS
	return result

## Get all manual save slots (including empty ones)
func get_manual_save_slots() -> Array[SaveSlot]:
	var slots: Array[SaveSlot] = []
	for i in range(1, MAX_MANUAL_SLOTS + 1):
		if save_slots.has(i):
			slots.append(save_slots[i])
		else:
			var empty_slot = SaveSlot.new(i)
			slots.append(empty_slot)
	return slots

## Get all auto-save slots
func get_autosave_slots() -> Array[SaveSlot]:
	var slots: Array[SaveSlot] = []
	for i in range(1, AUTOSAVE_SLOTS + 1):
		var slot_id = -i
		if save_slots.has(slot_id):
			slots.append(save_slots[slot_id])
		else:
			var empty_slot = SaveSlot.new(slot_id)
			slots.append(empty_slot)
	slots.sort_custom(func(a, b): return a.timestamp > b.timestamp)
	return slots

## Take screenshot for save thumbnail
func _take_screenshot(slot_id: int) -> String:
	await get_tree().process_frame  # Wait one frame to ensure screen is rendered

	var img = get_viewport().get_texture().get_image()
	if not img:
		push_error("Failed to capture screenshot")
		return ""

	# Resize to thumbnail size (256x144 for 16:9 aspect ratio)
	img.resize(256, 144, Image.INTERPOLATE_LANCZOS)

	var screenshot_dir = "user://screenshots/"
	if not DirAccess.dir_exists_absolute(screenshot_dir):
		DirAccess.make_dir_absolute(screenshot_dir)

	var screenshot_path = screenshot_dir + "save_" + str(slot_id) + ".png"
	var err = img.save_png(screenshot_path)

	if err != OK:
		push_error("Failed to save screenshot: " + str(err))
		return ""

	return screenshot_path

## Save metadata to JSON file
func save_save_metadata() -> void:
	var metadata = {}
	for slot_id in save_slots:
		metadata[str(slot_id)] = save_slots[slot_id].to_dict()

	metadata["current_autosave_index"] = current_autosave_index

	var file = FileAccess.open(SAVE_METADATA_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(metadata, "\t"))
		file.close()
	else:
		push_error("Failed to save metadata: " + str(FileAccess.get_open_error()))

## Load metadata from JSON file
func load_save_metadata() -> void:
	if not FileAccess.file_exists(SAVE_METADATA_PATH):
		return

	var file = FileAccess.open(SAVE_METADATA_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to load metadata: " + str(FileAccess.get_open_error()))
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse save metadata JSON")
		return

	var metadata = json.data
	if typeof(metadata) != TYPE_DICTIONARY:
		push_error("Invalid metadata format")
		return

	current_autosave_index = metadata.get("current_autosave_index", 0)

	for key in metadata:
		if key == "current_autosave_index":
			continue

		var slot_id = int(key)
		var slot_data = metadata[key]

		var slot = SaveSlot.new(slot_id)
		slot.from_dict(slot_data)
		save_slots[slot_id] = slot

## Save PlayerStats and Evidence data to slot-specific file
func _save_slot_data(slot_id: int) -> void:
	var slot_data = {
		"player_stats": {
			"level": PlayerStats.level,
			"xp": PlayerStats.xp,
			"score": PlayerStats.score,
			"hints": PlayerStats.hints
		},
		"evidence": {
			"collected": EvidenceManager.collected_evidence
		}
	}

	var slot_data_path = "user://slot_" + str(slot_id) + "_data.sav"
	var file = FileAccess.open(slot_data_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(slot_data, "\t"))
		file.close()
	else:
		push_error("Failed to save slot data: " + str(FileAccess.get_open_error()))

## Load PlayerStats and Evidence data from slot-specific file
func _load_slot_data(slot_id: int) -> void:
	var slot_data_path = "user://slot_" + str(slot_id) + "_data.sav"

	if not FileAccess.file_exists(slot_data_path):
		push_warning("No slot data found for slot " + str(slot_id) + ", using defaults")
		return

	var file = FileAccess.open(slot_data_path, FileAccess.READ)
	if not file:
		push_error("Failed to load slot data: " + str(FileAccess.get_open_error()))
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse slot data JSON")
		return

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid slot data format")
		return

	# Restore PlayerStats
	if data.has("player_stats"):
		var stats = data["player_stats"]
		PlayerStats.level = stats.get("level", 1)
		PlayerStats.xp = stats.get("xp", 0)
		PlayerStats.score = stats.get("score", 0)
		PlayerStats.hints = stats.get("hints", 3)

	# Restore Evidence
	if data.has("evidence"):
		var evidence = data["evidence"]
		EvidenceManager.collected_evidence = evidence.get("collected", [])

## Get formatted timestamp string
func format_timestamp(unix_time: int) -> String:
	if unix_time == 0:
		return "Empty Slot"

	var datetime = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d/%02d/%04d %02d:%02d" % [
		datetime.month,
		datetime.day,
		datetime.year,
		datetime.hour,
		datetime.minute
	]

## Check if any saves exist (for main menu Continue button)
func has_any_save() -> bool:
	return save_slots.size() > 0
