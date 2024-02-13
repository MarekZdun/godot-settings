extends "res://scenes/ui_element_scenes/ui_option_display_button.gd"

@onready var option_button: OptionButton = $HBoxContainer/OptionButton


func _ready():
	option_button.item_selected.connect(on_window_mode_selected)
	
	
func add_window_mode_items(items: Array[StringName]) -> void:
	for window_mode_name in items:
		option_button.add_item(window_mode_name)
		
		
func check_window_mode(window_mode_index: int) -> void:
	if window_mode_index != -1:
		option_button.select(window_mode_index)


func on_window_mode_selected(index: int) -> void:
	if Settings.window_mode_types_sequence[index] == Settings.WindowModeType.FULLSCREEN:
		Settings.setting_display.change_to_fullscreen()

	elif Settings.window_mode_types_sequence[index] == Settings.WindowModeType.WINDOW:
		Settings.setting_display.change_to_window()
		
	elif Settings.window_mode_types_sequence[index] == Settings.WindowModeType.BORDERLESS_WINDOW:
		Settings.setting_display.change_to_borderless_window()
