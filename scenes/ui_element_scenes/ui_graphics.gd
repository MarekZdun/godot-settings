extends Control

@onready var ui_window_mode_button: Control = $Panel/MarginContainer/VBoxContainer/UiWindowModeButton
@onready var ui_resolution_mode_button: Control = $Panel/MarginContainer/VBoxContainer/UiResolutionModeButton


func _ready():
	Settings.setting_display.fullscreen_changed.connect(ui_resolution_mode_button.on_fullscreen_changed)

	ui_resolution_mode_button.add_resolution_mode_items(Settings.resolution_mode_names)
	ui_resolution_mode_button.check_resolution_mode(Settings.setting_display.resolution_mode_index)

	var window_mode_index := get_window_mode_index()
	ui_window_mode_button.add_window_mode_items(Settings.window_mode_names)
	ui_window_mode_button.check_window_mode(window_mode_index)
	
	if window_mode_index != -1 and window_mode_index == Settings.window_mode_types_sequence.find(Settings.WindowModeType.FULLSCREEN):
		ui_resolution_mode_button.on_fullscreen_changed(true)
	
	
func get_window_mode_index() -> int:
	var index: int
	if Settings.setting_display.fullscreen and !Settings.setting_display.borderless:
		index = Settings.window_mode_types_sequence.find(Settings.WindowModeType.FULLSCREEN)
	elif !Settings.setting_display.fullscreen and !Settings.setting_display.borderless:
		index = Settings.window_mode_types_sequence.find(Settings.WindowModeType.WINDOW)
	elif !Settings.setting_display.fullscreen and Settings.setting_display.borderless:
		index = Settings.window_mode_types_sequence.find(Settings.WindowModeType.BORDERLESS_WINDOW)
	return index
