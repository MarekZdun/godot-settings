extends Node

@export var debug: bool = true

var _last_size : Vector2i


func _ready():
	#DisplayServer.window_set_min_size(Settings.resolution_mode_sizes[0])
	_last_size = DisplayServer.window_get_size()
	
	await get_tree().create_timer(2).timeout
	
	
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
	
	print(Settings.setting_display.scale)
