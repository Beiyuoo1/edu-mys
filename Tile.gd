extends ColorRect

var word_data = "" 
var original_parent = null
var click_offset = Vector2.ZERO # Added for "jigsaw" movement

func _ready():
	original_parent = get_parent()

# Implements the drag action and sets up the visual preview
func _get_drag_data(at_position):
	# Store the offset relative to the tile's top-left corner
	click_offset = at_position
	
	# --- Create the Visual Representation (The Jigsaw Piece) ---
	var drag_preview = ColorRect.new()
	drag_preview.size = size # Corrected: use size instead of rect_size
	drag_preview.color = color * Color(1.2, 1.2, 1.2)
	
	# JIGSAW FEEL: Add a slight rotation and scale to make it feel 'lifted'
	drag_preview.scale = Vector2(1.1, 1.1) 
	drag_preview.rotation_degrees = 2 
	
	# Reparent the label and fix its layout on the preview tile
	var label_copy = get_node("Label").duplicate()
	drag_preview.add_child(label_copy)
	
	# Corrected: Renamed function in Godot 4
	label_copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) 
	
	set_drag_preview(drag_preview)
	
	# CRITICAL: Adjust the drag preview position by the offset for "jigsaw" feel
	drag_preview.position -= click_offset * drag_preview.scale
	
	# Return the word data
	return word_data
