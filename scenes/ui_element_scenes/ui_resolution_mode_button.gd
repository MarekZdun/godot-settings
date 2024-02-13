extends "res://scenes/ui_element_scenes/ui_option_display_button.gd"

@onready var option_button: OptionButton = $HBoxContainer/OptionButton


func _ready():
	option_button.item_selected.connect(on_resolution_mode_selected)
	
	
func add_resolution_mode_items(items: Array[StringName]) -> void:
	for resolution_mode_name in items:
		option_button.add_item(resolution_mode_name)
			
			
func check_resolution_mode(resolution_mode_index: int) -> void:
	if resolution_mode_index != -1:
		option_button.select(resolution_mode_index)


func on_resolution_mode_selected(index: int) -> void:
	Settings.setting_display.change_resolution_mode_to(index)
	
	
func on_fullscreen_changed(fullscreen: bool) -> void:
	if fullscreen:
		option_button.set_text("%s x %s" % [Settings.setting_display.screen_size.x, Settings.setting_display.screen_size.y])
		option_button.set_disabled(true)
	else:
		check_resolution_mode(Settings.setting_display.resolution_mode_index)
		option_button.set_text(Settings.resolution_mode_names[Settings.setting_display.resolution_mode_index])
		option_button.set_disabled(false)
		
