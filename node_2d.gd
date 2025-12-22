extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("DEBUG: node_2d.gd is running. Starting c1s4.")
	Dialogic.start("c1s3")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
