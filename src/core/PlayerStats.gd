extends Node

# Signal to notify other parts of the game that stats have changed.
signal stats_changed(stats)

# Player's current statistics
var score: int = 0
var xp: int = 0
var level: int = 1
var hints: int = 3  # Starting hints for minigames

# How much XP is needed to reach the next level.
# This could be a constant, or a value from a curve (e.g., exponential).
const XP_PER_LEVEL: int = 100

# File path for saving and loading game data.
const SAVE_PATH = "user://player_stats.sav"


func _ready():
	load_stats()


func add_score(amount: int):
	"""
	Adds a given amount to the player's score.
	"""
	score += amount
	emit_signal("stats_changed", get_stats())
	save_stats()


func add_xp(amount: int):
	"""
	Adds a given amount of experience points and handles leveling up.
	"""
	xp += amount
	while xp >= XP_PER_LEVEL:
		xp -= XP_PER_LEVEL
		level += 1
	emit_signal("stats_changed", get_stats())
	save_stats()


func add_hints(amount: int):
	"""
	Adds hints to the player's hint pool.
	"""
	hints += amount
	emit_signal("stats_changed", get_stats())
	save_stats()

func use_hint() -> bool:
	"""
	Uses one hint. Returns true if successful, false if no hints available.
	"""
	if hints > 0:
		hints -= 1
		emit_signal("stats_changed", get_stats())
		save_stats()
		return true
	return false

func get_stats() -> Dictionary:
	"""
	Returns a dictionary containing all current player stats.
	"""
	return {
		"score": score,
		"xp": xp,
		"level": level,
		"xp_needed": XP_PER_LEVEL,
		"hints": hints
	}


func save_stats():
	"""
	Saves the current player stats to a file.
	"""
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = get_stats()
		var json_string = JSON.stringify(data)
		file.store_string(json_string)


func load_stats():
	"""
	Loads player stats from a file if it exists.
	"""
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var data = JSON.parse_string(json_string)

			if data:
				score = data.get("score", 0)
				xp = data.get("xp", 0)
				level = data.get("level", 1)
				hints = data.get("hints", 10)

	emit_signal("stats_changed", get_stats())


func save_exists() -> bool:
	"""
	Returns true if a save file exists.
	"""
	return FileAccess.file_exists(SAVE_PATH)


func reset_stats():
	"""
	Resets all player stats to default values.
	"""
	score = 0
	xp = 0
	level = 1
	hints = 10
	emit_signal("stats_changed", get_stats())
	save_stats()
