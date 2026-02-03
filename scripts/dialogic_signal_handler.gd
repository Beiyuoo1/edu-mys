extends Node

func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogic_signal(argument: String):
	print("DEBUG: Signal received: ", argument)

	# Handle level up signal
	if argument == "show_level_up":
		_handle_level_up_signal()
		return

	# Handle minigame signals: "start_minigame <puzzle_id>"
	if argument.begins_with("start_minigame "):
		var puzzle_id = argument.trim_prefix("start_minigame ").strip_edges()
		print("DEBUG: Starting minigame: ", puzzle_id)
		_handle_minigame_signal(puzzle_id)
		return

	# Handle evidence unlock: "unlock_evidence <evidence_id>"
	if argument.begins_with("unlock_evidence "):
		var evidence_id = argument.trim_prefix("unlock_evidence ").strip_edges()
		_handle_evidence_unlock(evidence_id)
		return

	# Handle evidence reset
	if argument == "reset_evidence":
		EvidenceManager.reset_evidence()
		print("Evidence reset")
		return

	# Handle level up check after all minigames complete
	if argument == "check_level_up":
		_handle_check_level_up()
		return

	# Handle textbox visibility
	if argument == "hide_textbox":
		Dialogic.Text.hide_textbox(true)
		return
	if argument == "show_textbox":
		Dialogic.Text.show_textbox(true)
		return

	# Handle title card signals: "show_title_card <chapter_number>"
	if argument.begins_with("show_title_card "):
		var chapter = argument.trim_prefix("show_title_card ").strip_edges()
		_handle_title_card_signal(chapter)
		return

func _handle_level_up_signal():
	Dialogic.paused = true
	var conrad_level = Dialogic.VAR.conrad_level
	await LevelUpManager.show_level_up(conrad_level)
	Dialogic.paused = false

func _handle_minigame_signal(puzzle_id: String):
	Dialogic.paused = true
	MinigameManager.start_minigame(puzzle_id)
	await MinigameManager.minigame_completed

	# Auto-save after completing minigame (requires SaveManager autoload)
	if SaveManager:
		await SaveManager.auto_save()

	# Safety check: ensure Dialogic is still valid before resuming
	if is_instance_valid(Dialogic) and Dialogic.current_timeline != null:
		Dialogic.paused = false
	else:
		push_warning("Dialogic timeline was cleared during minigame, skipping resume")

func _handle_check_level_up():
	if Dialogic.VAR.minigames_completed >= 3 and Dialogic.VAR.conrad_level < 2:
		Dialogic.paused = true
		Dialogic.VAR.conrad_level = 2
		await LevelUpManager.show_level_up(2)
		Dialogic.paused = false

func _handle_title_card_signal(chapter: String):
	Dialogic.paused = true
	# Update current chapter for curriculum question selection
	Dialogic.VAR.current_chapter = int(chapter)
	TitleCardManager.show_chapter_title(chapter)
	await TitleCardManager.title_card_completed

	# Auto-save at chapter transitions (requires SaveManager autoload)
	if SaveManager:
		await SaveManager.auto_save()

	if is_instance_valid(Dialogic) and Dialogic.current_timeline != null:
		Dialogic.paused = false

func _handle_evidence_unlock(evidence_id: String):
	# Pause dialogic and show evidence unlock animation
	Dialogic.paused = true
	EvidenceManager.unlock_evidence(evidence_id)

	# Show evidence unlock animation
	await _show_evidence_unlock_animation(evidence_id)

	# Resume dialogic
	if is_instance_valid(Dialogic) and Dialogic.current_timeline != null:
		Dialogic.paused = false

func _show_evidence_unlock_animation(evidence_id: String):
	"""Show an animated popup when evidence is unlocked"""
	var evidence = EvidenceManager.evidence_definitions.get(evidence_id)
	if not evidence:
		return

	# Create the evidence unlock popup scene
	var canvas_layer = _create_evidence_popup(evidence)
	get_tree().root.add_child(canvas_layer)

	# Wait for animation to complete
	await get_tree().create_timer(3.5).timeout

	# Fade out and remove
	if is_instance_valid(canvas_layer):
		var overlay = canvas_layer.get_child(0)  # Get the overlay ColorRect
		var center_container = canvas_layer.get_child(1)  # Get the center container
		if is_instance_valid(overlay) and is_instance_valid(center_container):
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(overlay, "modulate:a", 0.0, 0.5)
			tween.tween_property(center_container, "modulate:a", 0.0, 0.5)
			await tween.finished
		canvas_layer.queue_free()

func _create_evidence_popup(evidence: Dictionary) -> CanvasLayer:
	"""Create an evidence unlock popup UI"""
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100

	# Create background overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.8)
	canvas_layer.add_child(overlay)

	# Create center container
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(center_container)

	# Create content VBox
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(600, 400)
	center_container.add_child(vbox)

	# Add "Clue Found!" label
	var clue_label = Label.new()
	clue_label.text = "🔍 CLUE FOUND! 🔍"
	clue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clue_label.add_theme_font_size_override("font_size", 48)
	clue_label.add_theme_color_override("font_color", Color(1, 0.8, 0, 1))
	vbox.add_child(clue_label)

	# Add spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	# Add evidence image
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(500, 300)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture = load(evidence["image_path"])
	if texture:
		texture_rect.texture = texture
	else:
		push_error("Failed to load evidence image: " + evidence["image_path"])
	vbox.add_child(texture_rect)

	# Add spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)

	# Add evidence title
	var title_label = Label.new()
	title_label.text = evidence["title"]
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_label)

	# Add evidence description
	var desc_label = Label.new()
	desc_label.text = evidence["description"]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(500, 0)
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(desc_label)

	# Animate entrance - fade in the overlay
	overlay.modulate.a = 0.0
	vbox.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 0.8, 0.5)
	tween.tween_property(vbox, "modulate:a", 1.0, 0.5)

	# Pulse animation for clue label
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(clue_label, "scale", Vector2(1.1, 1.1), 0.5)
	pulse_tween.tween_property(clue_label, "scale", Vector2(1.0, 1.0), 0.5)

	return canvas_layer
