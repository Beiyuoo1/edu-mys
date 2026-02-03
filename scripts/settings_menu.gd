extends Control

# Dialogic text settings
const SETTING_LETTER_SPEED := 'dialogic/text/letter_speed'
const SETTING_AUTOADVANCE_ENABLED := 'dialogic/text/autoadvance_enabled'
const SETTING_AUTOADVANCE_FIXED_DELAY := 'dialogic/text/autoadvance_fixed_delay'

# Save path for user settings
const USER_SETTINGS_PATH := "user://settings.cfg"

# Track where settings was opened from
# Set by PauseManager before changing to this scene
static var opened_from_pause := false

# Signal emitted when back button is pressed from pause menu
signal back_pressed

@onready var text_speed_slider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/TextSpeedContainer/TextSpeedSlider
@onready var text_speed_value = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/TextSpeedContainer/TextSpeedValue
@onready var auto_advance_check = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/AutoAdvanceContainer/AutoAdvanceCheck
@onready var auto_advance_delay = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/AutoAdvanceContainer/AutoAdvanceDelay
@onready var master_volume_slider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/MasterVolumeContainer/MasterVolumeSlider
@onready var master_volume_value = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/MasterVolumeContainer/MasterVolumeValue
@onready var music_volume_slider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_value = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/MusicVolumeContainer/MusicVolumeValue
@onready var sfx_volume_slider = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/SFXVolumeContainer/SFXVolumeSlider
@onready var sfx_volume_value = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/SFXVolumeContainer/SFXVolumeValue
@onready var fullscreen_check = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SettingsContainer/FullscreenContainer/FullscreenCheck
@onready var back_button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BackButton

var config := ConfigFile.new()

func _ready() -> void:
	load_settings()

	# Connect signals
	text_speed_slider.value_changed.connect(_on_text_speed_changed)
	auto_advance_check.toggled.connect(_on_auto_advance_toggled)
	auto_advance_delay.value_changed.connect(_on_auto_advance_delay_changed)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)

func load_settings() -> void:
	# Load from config file
	var err = config.load(USER_SETTINGS_PATH)

	# Text speed (Dialogic uses 0.01 as default, lower = faster)
	# We invert it for UI: slider 1-10 where 10 is fastest
	var letter_speed = ProjectSettings.get_setting(SETTING_LETTER_SPEED, 0.01)
	var speed_ui_value = clamp(10.0 - (letter_speed * 100), 1, 10)
	text_speed_slider.value = speed_ui_value
	text_speed_value.text = str(int(speed_ui_value))

	# Auto-advance
	auto_advance_check.button_pressed = ProjectSettings.get_setting(SETTING_AUTOADVANCE_ENABLED, false)
	auto_advance_delay.value = ProjectSettings.get_setting(SETTING_AUTOADVANCE_FIXED_DELAY, 1.0)
	auto_advance_delay.editable = auto_advance_check.button_pressed

	# Audio volumes (from config file or default)
	var master_vol = config.get_value("audio", "master_volume", 100)
	var music_vol = config.get_value("audio", "music_volume", 80)
	var sfx_vol = config.get_value("audio", "sfx_volume", 80)

	master_volume_slider.value = master_vol
	master_volume_value.text = str(int(master_vol)) + "%"
	music_volume_slider.value = music_vol
	music_volume_value.text = str(int(music_vol)) + "%"
	sfx_volume_slider.value = sfx_vol
	sfx_volume_value.text = str(int(sfx_vol)) + "%"

	# Apply audio settings
	_apply_audio_volume("Master", master_vol)
	_apply_audio_volume("Music", music_vol)
	_apply_audio_volume("SFX", sfx_vol)

	# Fullscreen
	var is_fullscreen = config.get_value("display", "fullscreen", false)
	fullscreen_check.button_pressed = is_fullscreen
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func save_settings() -> void:
	# Save Dialogic settings to ProjectSettings at runtime
	# Note: These won't persist between game sessions in exported builds
	# For persistent settings, we also save to config file

	config.set_value("text", "speed_ui", text_speed_slider.value)
	config.set_value("text", "auto_advance", auto_advance_check.button_pressed)
	config.set_value("text", "auto_advance_delay", auto_advance_delay.value)
	config.set_value("audio", "master_volume", master_volume_slider.value)
	config.set_value("audio", "music_volume", music_volume_slider.value)
	config.set_value("audio", "sfx_volume", sfx_volume_slider.value)
	config.set_value("display", "fullscreen", fullscreen_check.button_pressed)

	config.save(USER_SETTINGS_PATH)

func _on_text_speed_changed(value: float) -> void:
	# Convert UI value (1-10) to letter speed (0.09-0.0)
	# Higher slider = faster text = lower letter_speed
	var letter_speed = (10.0 - value) / 100.0
	letter_speed = max(letter_speed, 0.001)  # Minimum delay

	ProjectSettings.set_setting(SETTING_LETTER_SPEED, letter_speed)
	text_speed_value.text = str(int(value))
	save_settings()

func _on_auto_advance_toggled(enabled: bool) -> void:
	ProjectSettings.set_setting(SETTING_AUTOADVANCE_ENABLED, enabled)
	auto_advance_delay.editable = enabled
	# Update Dialogic's auto-advance directly (ProjectSettings only read at init)
	if Dialogic.Inputs != null and Dialogic.Inputs.auto_advance != null:
		Dialogic.Inputs.auto_advance.enabled_forced = enabled
	save_settings()

func _on_auto_advance_delay_changed(value: float) -> void:
	ProjectSettings.set_setting(SETTING_AUTOADVANCE_FIXED_DELAY, value)
	# Update Dialogic's auto-advance directly (ProjectSettings only read at init)
	if Dialogic.Inputs != null and Dialogic.Inputs.auto_advance != null:
		Dialogic.Inputs.auto_advance.fixed_delay = value
	save_settings()

func _on_master_volume_changed(value: float) -> void:
	_apply_audio_volume("Master", value)
	master_volume_value.text = str(int(value)) + "%"
	save_settings()

func _on_music_volume_changed(value: float) -> void:
	_apply_audio_volume("Music", value)
	music_volume_value.text = str(int(value)) + "%"
	save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	_apply_audio_volume("SFX", value)
	sfx_volume_value.text = str(int(value)) + "%"
	save_settings()

func _apply_audio_volume(bus_name: String, volume_percent: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		# Convert percentage to dB (-80 to 0 range)
		if volume_percent <= 0:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			var db = linear_to_db(volume_percent / 100.0)
			AudioServer.set_bus_volume_db(bus_idx, db)

func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func _on_back_pressed() -> void:
	print("Settings back button pressed. opened_from_pause: ", opened_from_pause)
	if opened_from_pause:
		# Signal that we're going back (PauseManager will handle cleanup)
		opened_from_pause = false
		print("Emitting back_pressed signal")
		back_pressed.emit()
		print("Signal emitted")
	else:
		# Return to main menu
		print("Going back to main menu")
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
