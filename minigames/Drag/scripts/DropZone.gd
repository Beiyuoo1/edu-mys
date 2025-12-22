extends ColorRect

var expected_answer = "" 
var minigame_scene = null 
var is_filled = false
var original_color = Color(1,1,1,0) # Store the default color

func _ready():
	original_color = color

# 1. Checks if the dropped data is acceptable (required function)
func _can_drop_data(at_position, data):
	return !is_filled and typeof(data) == TYPE_STRING

# 2. Handles the drop action (required function)
func _drop_data(at_position, data):
	if data == expected_answer:
		is_filled = true
		
		var tile_to_remove = find_tile_by_word(data)
		if tile_to_remove:
			# --- START OF FIX: INSTANT FULL TRANSPARENCY ---
			# Sets the tile's color modulate to fully transparent (alpha = 0)
			tile_to_remove.modulate = Color(1, 1, 1, 0)
			
			# Disable mouse interaction on the invisible tile
			tile_to_remove.mouse_filter = MOUSE_FILTER_IGNORE
			# --- END OF FIX ---
		
		var new_label = Label.new()
		add_child(new_label)
		new_label.text = data
		new_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		new_label.align = HORIZONTAL_ALIGNMENT_CENTER
		new_label.valign = VERTICAL_ALIGNMENT_CENTER
		
		_handle_successful_drop()

	else:
		# Incorrect drop - provide visual feedback
		color = Color.RED 
		get_tree().create_timer(0.5).timeout.connect(reset_color)

func reset_color():
	if not is_filled: 
		color = original_color

func _handle_successful_drop():
	color = Color.GREEN
	get_tree().create_timer(0.5).timeout.connect(_reset_success_color)
	minigame_scene.check_win_condition(true)

func _reset_success_color():
	color = original_color

func find_tile_by_word(word):
	var grid = minigame_scene.choices_grid
	for tile in grid.get_children():
		if tile.get_script() == load("res://Tile.gd"): 
			if tile.word_data == word:
				return tile
	return null
