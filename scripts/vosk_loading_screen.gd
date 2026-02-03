extends CanvasLayer

@onready var title_label = $Control/CenterContainer/VBoxContainer/TitleLabel
@onready var spinner_label = $Control/CenterContainer/VBoxContainer/SpinnerLabel
@onready var status_label = $Control/CenterContainer/VBoxContainer/StatusLabel
@onready var progress_bar = $Control/CenterContainer/VBoxContainer/ProgressContainer/ProgressBar
@onready var percent_label = $Control/CenterContainer/VBoxContainer/ProgressContainer/PercentLabel
@onready var tip_label = $Control/CenterContainer/VBoxContainer/TipLabel

# Spinner animation
var spinner_chars = ["◐", "◓", "◑", "◒"]
var spinner_index = 0
var spinner_timer = 0.0
const SPINNER_SPEED = 0.15

# Loading tips
var loading_tips = [
	"Tip: The voice recognition system helps you practice pronunciation!",
	"Tip: Speak clearly and at a moderate pace for best results.",
	"Tip: The AI will listen to how you pronounce words, not just what you say.",
	"Tip: You can retry voice challenges as many times as you need!",
	"Tip: Background noise may affect voice recognition accuracy."
]
var current_tip_index = 0

signal loading_complete

func _ready():
	visible = true
	progress_bar.value = 0
	_randomize_tip()

func _process(delta):
	# Animate spinner
	spinner_timer += delta
	if spinner_timer >= SPINNER_SPEED:
		spinner_timer = 0.0
		spinner_index = (spinner_index + 1) % spinner_chars.size()
		spinner_label.text = spinner_chars[spinner_index]

	# Update progress from MinigameManager
	if MinigameManager:
		var progress = MinigameManager.vosk_loading_progress * 100.0
		progress_bar.value = progress
		percent_label.text = str(int(progress)) + "%"

		# Update status based on progress
		if progress < 30:
			status_label.text = "Initializing Vosk speech recognition model..."
		elif progress < 70:
			status_label.text = "Loading neural network weights..."
		elif progress < 95:
			status_label.text = "Preparing voice recognition system..."
		else:
			status_label.text = "Almost ready..."

		# Check if loading is complete
		if MinigameManager.vosk_is_loaded:
			_on_loading_complete()

func _randomize_tip():
	"""Show a random loading tip"""
	current_tip_index = randi() % loading_tips.size()
	tip_label.text = loading_tips[current_tip_index]

func _on_loading_complete():
	"""Called when Vosk finishes loading"""
	progress_bar.value = 100
	percent_label.text = "100%"
	status_label.text = "Voice recognition ready!"
	spinner_label.text = "✓"

	# Emit signal and fade out
	loading_complete.emit()

	# Fade out animation
	var tween = create_tween()
	tween.tween_property($Control, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tween.tween_callback(queue_free)
