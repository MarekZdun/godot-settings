extends Node

@export var debug: bool = true

var _last_size : Vector2i


func _ready():
	Settings.setting_language.retranslated.connect(_on_retranslated)
	
	#DisplayServer.window_set_min_size(Settings.resolution_mode_sizes[0])
	_last_size = DisplayServer.window_get_size()
	
	await get_tree().create_timer(4).timeout
	#Settings.reset_to_default()
	#Settings.setting_display.change_content_scale_size(Vector2i(1152 * 2, 648 * 2))
	#Settings.setting_display.change_content_scale_factor(0.5)
	
	await get_tree().create_timer(4).timeout
	#Settings.setting_display.change_content_scale_size(Vector2i(1152, 648))
	#Settings.setting_display.change_content_scale_factor(1)
	
	
func _process(delta):
	if debug:
		if _last_size != DisplayServer.window_get_size():
			_last_size = DisplayServer.window_get_size()
			_on_viewport_size_changed()
			
			
func _input(event):
	if event is InputEventKey and event.pressed and !event.is_echo():
		if event.shift_pressed and event.keycode == KEY_S:
			Settings.save_settings()


func _on_viewport_size_changed():
	Settings.setting_display.evaluate_display()
	
	
func _on_retranslated(language: String) -> void:
	print(language)
