extends CanvasLayer

# Node references
@onready var timer_label = $Control/MainContainer/VBoxContainer/HeaderContainer/TimerLabel
@onready var choices_container = $Control/MainContainer/VBoxContainer/ChoicesContainer
@onready var microphone_panel = $Control/MainContainer/VBoxContainer/MicrophonePanel
@onready var feedback_label = $Control/MainContainer/VBoxContainer/FeedbackLabel
@onready var sentence_display = $Control/MainContainer/VBoxContainer/MicrophonePanel/MarginContainer/VBoxContainer/SentenceDisplay
@onready var status_label = $Control/MainContainer/VBoxContainer/MicrophonePanel/MarginContainer/VBoxContainer/StatusLabel
@onready var transcription_label = $Control/MainContainer/VBoxContainer/MicrophonePanel/MarginContainer/VBoxContainer/TranscriptionLabel
@onready var progress_label = $Control/MainContainer/VBoxContainer/MicrophonePanel/MarginContainer/VBoxContainer/ProgressLabel

# Choice buttons
@onready var choice_buttons = [
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Choice1,
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Choice2,
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Choice3,
	$Control/MainContainer/VBoxContainer/ChoicesContainer/Choice4
]

# Timer
var time_remaining: float = 90.0  # 1:30 in seconds
var timer_active: bool = false

# Correct answer index (configurable)
var correct_answer: int = 1  # Default to Choice 2 for janitor scenario

# Selected choice
var selected_choice_index: int = -1

# Configurable question and choices
var question_text: String = "How do you politely ask the janitor for help?"
var choice_texts: Array = []  # Will be populated by configure_puzzle()

# Voice recognition using GodotVoskRecognizer
var vosk_recognizer: GodotVoskRecognizer = null
var audio_effect_capture: AudioEffectCapture = null
var audio_bus_index: int = -1
var microphone_player: AudioStreamPlayer = null
var is_listening: bool = false
var audio_buffer: PackedByteArray = PackedByteArray()
var silence_timer: float = 0.0
var has_spoken: bool = false
const SILENCE_THRESHOLD: float = 1.0  # Stop after 1.0 second of silence (reduced for faster feedback)

# Word-by-word recognition tracking
var current_word_index: int = 0  # Which word we're currently trying to recognize
var last_partial_text: String = ""  # Track changes in partial results
var word_just_recognized: bool = false  # Prevent double-triggering

# Vosk configuration
const MODEL_PATH = "res://addons/vosk/models/vosk-model-en-us-0.22"  # Large model for better accuracy
const SAMPLE_RATE = 16000.0
const PHRASE_MATCH_THRESHOLD = 0.6  # 60% of words must match
const AUDIO_CHUNK_SIZE = 2048  # Smaller chunks = faster processing (was 4096)

# Homophone/variant groups - words that should be treated as equivalent
# To add more: "base_word": ["variant1", "variant2", "variant3"]
# Example: "im": ["im", "i'm", "i am"] means all three are treated as the same
const HOMOPHONE_GROUPS = {
	"im": ["im", "i'm", "i am"],
	"youre": ["youre", "you're", "you are"],
	"theyre": ["theyre", "they're", "they are"],
	"were": ["were", "we're", "we are"],
	"its": ["its", "it's", "it is"],
	"thats": ["thats", "that's", "that is"],
	"whats": ["whats", "what's", "what is"],
	"hes": ["hes", "he's", "he is"],
	"shes": ["shes", "she's", "she is"],
	"ive": ["ive", "i've", "i have"],
	"weve": ["weve", "we've", "we have"],
	"theyve": ["theyve", "they've", "they have"],
	"youve": ["youve", "you've", "you have"],
	"dont": ["dont", "don't", "do not"],
	"doesnt": ["doesnt", "doesn't", "does not"],
	"didnt": ["didnt", "didn't", "did not"],
	"wont": ["wont", "won't", "will not"],
	"wouldnt": ["wouldnt", "wouldn't", "would not"],
	"couldnt": ["couldnt", "couldn't", "could not"],
	"shouldnt": ["shouldnt", "shouldn't", "should not"],
	"isnt": ["isnt", "isn't", "is not"],
	"arent": ["arent", "aren't", "are not"],
	"wasnt": ["wasnt", "wasn't", "was not"],
	"werent": ["werent", "weren't", "were not"],
	"havent": ["havent", "haven't", "have not"],
	"hasnt": ["hasnt", "hasn't", "has not"],
	"hadnt": ["hadnt", "hadn't", "had not"],
	"cant": ["cant", "can't", "cannot", "can not"],

	# Common Vosk misrecognitions
	"afternoon": ["afternoon", "after noon", "after new"],
	"hoping": ["hoping", "hopping", "hope", "hoping"],
	"looking": ["looking", "lock", "look"],
	"could": ["could", "cold", "good", "called"],
	"something": ["something", "some", "somethin"],
	"unusual": ["unusual", "and usual"],
	"sweeping": ["sweeping", "sweep", "sweeping"],
	"come": ["come", "came", "calm"],
	"across": ["across", "a cross"],
	"anything": ["anything", "any"],
	"while": ["while", "well", "wall"],
}

# Full sentence text with punctuation for display
var full_sentence_texts = [
	"Excuse me, sir sorry to interrupt, but may I quickly check under my desk for something I left",
	"Good afternoon, sir have you seen any unusual item while cleaning this room?",
	"“Hi sir, I can help move the chairs, and by the way, did you see a small item I dropped near here",
	"Sir, did anyone turn in a lost item from this classroom today"
]

# Full sentence to pronounce (no punctuation, for matching)
var target_sentence: String = ""
var target_words = []

signal minigame_completed(success: bool)

func configure_puzzle(config: Dictionary):
	"""Configure the minigame with custom question and choices"""
	if config.has("question"):
		question_text = config["question"]
	if config.has("choices"):
		choice_texts = config["choices"]
		full_sentence_texts = config["choices"].duplicate()
	if config.has("correct_index"):
		correct_answer = config["correct_index"]

	print("DEBUG: Dialogue choice configured - Question: ", question_text)
	print("DEBUG: Correct answer index: ", correct_answer)

func _ready():
	print("DEBUG: DialogueChoice minigame _ready() called")

	# Make sure the control is visible
	visible = true

	# Verify node references
	if timer_label == null:
		push_error("DialogueChoice: timer_label is null!")
	if choices_container == null:
		push_error("DialogueChoice: choices_container is null!")

	print("DEBUG: DialogueChoice minigame visible: ", visible)
	print("DEBUG: DialogueChoice layer: ", layer)

	# Set up choice buttons with configured text
	if choice_texts.size() > 0:
		for i in range(min(choice_buttons.size(), choice_texts.size())):
			if choice_buttons[i]:
				choice_buttons[i].text = choice_texts[i]
				print("DEBUG: Button ", i, " text set to: ", choice_texts[i])

	# Debug button connections
	for i in range(choice_buttons.size()):
		if choice_buttons[i]:
			print("DEBUG: Button ", i, " exists: ", choice_buttons[i].name)
			print("DEBUG: Button ", i, " disabled: ", choice_buttons[i].disabled)
			print("DEBUG: Button ", i, " visible: ", choice_buttons[i].visible)
		else:
			push_error("DialogueChoice: Button ", i, " is null!")

	# Start timer
	timer_active = true

	# Initialize Vosk
	_initialize_vosk()
	_setup_audio_capture()

func _process(delta):
	if timer_active:
		time_remaining -= delta
		if time_remaining <= 0:
			time_remaining = 0
			timer_active = false
			# Timer reached zero - nothing happens as per requirement

		_update_timer_display()

	# Process audio capture for Vosk
	if is_listening and audio_effect_capture:
		var frames_available = audio_effect_capture.get_frames_available()
		if frames_available > 0:
			var stereo_data = audio_effect_capture.get_buffer(frames_available)

			# Convert stereo float to mono PCM 16-bit
			for i in range(0, stereo_data.size(), 2):
				if i + 1 < stereo_data.size():
					# Average left and right channels
					var mono_sample = (stereo_data[i].x + stereo_data[i].y) / 2.0
					# Convert to 16-bit PCM
					var int_sample = int(clamp(mono_sample * 32767.0, -32768, 32767))
					# Append as little-endian bytes
					audio_buffer.append(int_sample & 0xFF)
					audio_buffer.append((int_sample >> 8) & 0xFF)

			# Send to Vosk with smaller chunks for faster processing
			while audio_buffer.size() >= AUDIO_CHUNK_SIZE:
				var chunk = audio_buffer.slice(0, AUDIO_CHUNK_SIZE)
				audio_buffer = audio_buffer.slice(AUDIO_CHUNK_SIZE)

				vosk_recognizer.accept_waveform(chunk)

		# Check partial result every frame for responsiveness
		if is_listening and vosk_recognizer:
			var partial_json = vosk_recognizer.get_partial_result()
			var partial = JSON.parse_string(partial_json)
			if partial and partial.has("partial") and partial["partial"] != "":
				var partial_text = partial["partial"]

				# Process word-by-word updates
				_process_partial_text(partial_text)

				has_spoken = true
				silence_timer = 0.0  # Reset silence timer when speech detected
			elif has_spoken:
				# User has spoken before, start counting silence
				silence_timer += delta
				if silence_timer >= SILENCE_THRESHOLD:
					print("Silence detected - checking if we have enough words")
					_check_if_sentence_complete()

func _update_timer_display():
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func _on_choice_selected(choice_index: int):
	print("DEBUG: Choice selected: ", choice_index)
	selected_choice_index = choice_index

	# Disable all choice buttons
	for button in choice_buttons:
		button.disabled = true

	if choice_index == correct_answer:
		# Correct choice - show microphone panel
		print("DEBUG: Correct choice! Showing microphone panel")
		_show_microphone_panel()
	else:
		# Wrong choice - show feedback
		print("DEBUG: Wrong choice. Showing feedback")
		_show_wrong_feedback()

func _show_microphone_panel():
	choices_container.visible = false
	microphone_panel.visible = true
	feedback_label.visible = false

	# Prepare the target sentence
	_prepare_target_sentence()

	# Display the full sentence
	sentence_display.text = full_sentence_texts[correct_answer]
	status_label.text = "Speak the sentence above"
	progress_label.text = "Ready to listen..."
	transcription_label.text = "Waiting for speech..."

	# Start voice recognition
	_start_sentence_recognition()

func _prepare_target_sentence():
	"""Prepare the target sentence for matching"""
	var full_text = full_sentence_texts[correct_answer]

	# Remove punctuation for matching
	target_sentence = full_text.replace(",", "").replace(".", "").replace("?", "").replace("!", "").replace("—", "").replace("'", "").to_lower()
	target_words = target_sentence.split(" ", false)

	print("DEBUG: Target sentence: ", target_sentence)
	print("DEBUG: Target words (", target_words.size(), "): ", target_words)

func _show_wrong_feedback():
	feedback_label.visible = true
	feedback_label.text = "This isn't the right way to say it, maybe there's something better."

	# Wait 2 seconds then re-enable buttons
	await get_tree().create_timer(2.0).timeout
	feedback_label.visible = false

	# Re-enable all buttons except the wrong one
	for i in range(choice_buttons.size()):
		if i != selected_choice_index:
			choice_buttons[i].disabled = false

func _initialize_vosk():
	"""Initialize Vosk speech recognizer (use preloaded one if available)"""
	# Try to use the preloaded Vosk from MinigameManager
	if MinigameManager.shared_vosk_recognizer != null:
		vosk_recognizer = MinigameManager.shared_vosk_recognizer
		print("Using preloaded Vosk recognizer from MinigameManager ✓")
		return

	# Fallback: Load Vosk now if not preloaded
	print("Vosk not preloaded, loading now...")
	vosk_recognizer = GodotVoskRecognizer.new()
	var absolute_path = ProjectSettings.globalize_path(MODEL_PATH)

	if not vosk_recognizer.initialize(absolute_path, SAMPLE_RATE):
		push_error("Failed to initialize Vosk recognizer")
		print("ERROR: Vosk failed to initialize at path: ", absolute_path)
		vosk_recognizer = null
		return

	print("Vosk initialized successfully")

func _setup_audio_capture():
	"""Setup audio capture for microphone input"""
	if vosk_recognizer == null:
		print("WARNING: Skipping audio capture setup - Vosk not initialized")
		return

	# Check available input devices
	var input_device_count = AudioServer.get_input_device_list().size()
	print("DEBUG: Available input devices: ", AudioServer.get_input_device_list())
	print("DEBUG: Current input device: ", AudioServer.input_device)

	if input_device_count == 0:
		push_error("No microphone input devices found!")
		return

	# Enable microphone capture
	var idx = AudioServer.get_bus_index("Record")
	if idx == -1:
		# Create Record bus if it doesn't exist
		idx = AudioServer.get_bus_count()
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Record")

	audio_bus_index = idx

	# Add capture effect to the Record bus
	audio_effect_capture = AudioEffectCapture.new()
	audio_effect_capture.buffer_length = 0.05  # 50ms buffer for faster response (was 100ms)
	AudioServer.add_bus_effect(audio_bus_index, audio_effect_capture)

	# IMPORTANT: Mute the bus so we don't hear ourselves (prevents echo)
	AudioServer.set_bus_mute(audio_bus_index, true)

	# Create an AudioStreamPlayer to start the microphone
	microphone_player = AudioStreamPlayer.new()
	microphone_player.stream = AudioStreamMicrophone.new()
	microphone_player.bus = "Record"
	add_child(microphone_player)
	microphone_player.play()

	print("Audio capture setup complete with microphone input (muted for recording only)")

func _start_sentence_recognition():
	"""Start listening for word-by-word sequential recognition"""
	if vosk_recognizer == null:
		# Fallback: Auto-complete after 3 seconds for testing
		print("WARNING: Vosk not available - auto-completing")
		await get_tree().create_timer(3.0).timeout
		_complete_minigame(true)
		return

	is_listening = true
	has_spoken = false
	silence_timer = 0.0
	audio_buffer.clear()
	vosk_recognizer.reset()
	current_word_index = 0
	last_partial_text = ""
	word_just_recognized = false

	# Show initial state
	_update_word_display()
	status_label.text = "Say the highlighted word!"
	transcription_label.text = ""
	progress_label.text = "Word 1 / " + str(target_words.size())
	print("Listening for word-by-word sequential recognition...")
	print("Waiting for word: '", target_words[current_word_index], "'")

func _process_partial_text(partial_text: String):
	"""Process partial text and check current word OR multiple words in sequence"""
	# Check if text has changed
	if partial_text == last_partial_text or partial_text.strip_edges().is_empty():
		return

	if word_just_recognized:
		return  # Waiting for user to say next word

	var spoken_words = partial_text.to_lower().split(" ", false)

	# Show what's being heard
	transcription_label.text = "Hearing: " + partial_text

	print("Expected: '", target_words[current_word_index], "' | Got: '", partial_text, "'")

	# FIRST: Try to match multiple consecutive words (sentence detection)
	# Example: If user says "good afternoon sir", match all 3 words at once
	var words_matched = _check_multiple_words_match(spoken_words)
	if words_matched > 0:
		print("✅ CORRECT! Matched ", words_matched, " words in sequence!")
		# Recognize all matched words at once
		for i in range(words_matched):
			_on_word_recognized()
		return

	# SECOND: Fall back to single word matching (check last word only)
	# This allows: "it was a" → recognizes "a"
	if spoken_words.size() > 0:
		var target_word = target_words[current_word_index]
		var last_spoken_word = spoken_words[spoken_words.size() - 1]

		if _words_match(last_spoken_word, target_word):
			print("✅ CORRECT! Single word matched!")
			_on_word_recognized()
			return
		else:
			# Debug: show why it didn't match
			var similarity = _calculate_similarity(last_spoken_word, target_word)
			if similarity < 0.5 and not _are_homophones(last_spoken_word, target_word):
				print("⚠️ Last word '", last_spoken_word, "' doesn't match '", target_word, "' (similarity: ", int(similarity * 100), "%)")

	last_partial_text = partial_text

func _check_multiple_words_match(spoken_words: Array) -> int:
	"""Check if multiple spoken words match consecutive target words starting from current index"""
	if spoken_words.size() == 0:
		return 0

	var matched_count = 0
	var remaining_target_words = target_words.size() - current_word_index

	# Try to match as many words as possible in sequence
	for i in range(min(spoken_words.size(), remaining_target_words)):
		var spoken_word = spoken_words[i]
		var target_word = target_words[current_word_index + i]

		if _words_match(spoken_word, target_word):
			matched_count += 1
		else:
			# Stop at first non-match
			break

	# Only return match if we got at least 2 words (otherwise single word matching handles it)
	return matched_count if matched_count >= 2 else 0

func _on_word_recognized():
	"""Called when current word is successfully recognized"""
	word_just_recognized = true

	# Mark word as recognized
	current_word_index += 1

	# Update display
	_update_word_display()

	# Update progress
	progress_label.text = "Word " + str(current_word_index + 1) + " / " + str(target_words.size())
	progress_label.add_theme_color_override("font_color", Color.GREEN)

	# Check if we've completed all words
	if current_word_index >= target_words.size():
		_on_all_words_complete()
	else:
		# Prepare for next word
		status_label.text = "Great! Say the next word..."
		await get_tree().create_timer(0.5).timeout  # Brief pause

		if is_listening:  # Make sure we haven't stopped
			word_just_recognized = false
			vosk_recognizer.reset()  # Clear Vosk buffer for next word
			last_partial_text = ""
			transcription_label.text = ""
			status_label.text = "Say: " + target_words[current_word_index]
			progress_label.add_theme_color_override("font_color", Color.WHITE)
			print("Waiting for next word: '", target_words[current_word_index], "'")

func _on_all_words_complete():
	"""Called when all words have been recognized"""
	is_listening = false
	print("SUCCESS: All words recognized!")

	# Show completion message
	status_label.text = "✓ COMPLETE!"
	status_label.add_theme_color_override("font_color", Color.GREEN)
	transcription_label.text = "Perfect! You said the entire sentence correctly!"
	transcription_label.add_theme_color_override("font_color", Color.GREEN)

	# Highlight all words green
	var all_green = ""
	for word in target_words:
		all_green += "[color=green]" + word + "[/color] "
	sentence_display.text = all_green.strip_edges()

	await get_tree().create_timer(2.0).timeout
	_complete_minigame(true)

func _update_word_display():
	"""Update the sentence display to highlight current word"""
	var highlighted_sentence = ""

	for i in range(target_words.size()):
		var word = target_words[i]

		if i < current_word_index:
			# Already recognized - show in green
			highlighted_sentence += "[color=green]" + word + "[/color] "
		elif i == current_word_index:
			# Current word - highlight in yellow/bright
			highlighted_sentence += "[color=yellow]" + word + "[/color] "
		else:
			# Not yet reached - show in gray
			highlighted_sentence += "[color=gray]" + word + "[/color] "

	sentence_display.text = highlighted_sentence.strip_edges()

func _check_if_sentence_complete():
	"""Called when silence is detected - give feedback to continue"""
	if not is_listening or word_just_recognized:
		return

	# Encourage user to speak
	if has_spoken:
		status_label.text = "Keep going! Say: " + target_words[current_word_index]

	# Reset for next attempt at current word
	silence_timer = 0.0
	has_spoken = false

# Old function - replaced by progressive word-by-word checking
# func _check_sentence_match(recognized_text: String):
# 	"""Check if recognized sentence matches target sentence"""
# 	# This function is no longer used - see _check_sentence_match_progressive() instead

func _words_match(spoken_word: String, target_word: String) -> bool:
	"""Check if two words match, considering homophones and similarity"""
	spoken_word = spoken_word.to_lower().strip_edges()
	target_word = target_word.to_lower().strip_edges()

	# Direct match
	if spoken_word == target_word:
		return true

	# Check homophone groups
	if _are_homophones(spoken_word, target_word):
		return true

	# Fallback to similarity check (lowered threshold for Vosk small model)
	var similarity = _calculate_similarity(spoken_word, target_word)
	return similarity >= 0.5  # 50% similarity (was 70%)

func _are_homophones(word1: String, word2: String) -> bool:
	"""Check if two words are in the same homophone group"""
	word1 = word1.to_lower().strip_edges()
	word2 = word2.to_lower().strip_edges()

	# Check each homophone group
	for group_key in HOMOPHONE_GROUPS:
		var variants = HOMOPHONE_GROUPS[group_key]
		var word1_in_group = word1 in variants
		var word2_in_group = word2 in variants

		if word1_in_group and word2_in_group:
			return true

	return false

func _calculate_similarity(text1: String, text2: String) -> float:
	"""Calculate Levenshtein distance-based similarity"""
	if text1 == text2:
		return 1.0

	if text1.is_empty() or text2.is_empty():
		return 0.0

	var len1 = text1.length()
	var len2 = text2.length()
	var matrix = []

	# Initialize matrix
	for i in range(len1 + 1):
		matrix.append([])
		for j in range(len2 + 1):
			matrix[i].append(0)

	# Fill first row and column
	for i in range(len1 + 1):
		matrix[i][0] = i
	for j in range(len2 + 1):
		matrix[0][j] = j

	# Calculate Levenshtein distance
	for i in range(1, len1 + 1):
		for j in range(1, len2 + 1):
			var cost = 0 if text1[i-1] == text2[j-1] else 1
			matrix[i][j] = min(
				matrix[i-1][j] + 1,      # deletion
				matrix[i][j-1] + 1,      # insertion
				matrix[i-1][j-1] + cost  # substitution
			)

	var distance = matrix[len1][len2]
	var max_len = max(len1, len2)
	return 1.0 - (float(distance) / float(max_len))

func _complete_minigame(success: bool):
	minigame_completed.emit(success)
	_cleanup()
	queue_free()

func _cleanup():
	"""Cleanup audio resources"""
	is_listening = false

	# Stop and remove microphone player
	if microphone_player:
		microphone_player.stop()
		microphone_player.queue_free()
		microphone_player = null

	# Note: Don't remove the Record bus as it might be used elsewhere
	audio_bus_index = -1

func _exit_tree():
	_cleanup()
