extends Node

@export var debug: bool = true

var _last_size : Vector2i

@onready var ui_input_rebind: Control = $UiInputRebind


func _ready():
	Settings.setting_controls.keyboard_input_changed.connect(_on_keyboard_input_changed)
	Settings.setting_controls.joypad_input_changed.connect(_on_joypad_input_changed)
	
	#DisplayServer.window_set_min_size(Settings.resolution_mode_sizes[0])
	_last_size = DisplayServer.window_get_size()
	
	await get_tree().create_timer(4).timeout
	#Settings.reset_to_default()
	#ui_input_rebind.create_input_action_list()
	
	
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
	
	
func _on_keyboard_input_changed(action: String, input: InputEvent) -> void:
	print("%s - %s" % [action, input])
	
	
func _on_joypad_input_changed(action: String, input: InputEventJoypadButton) -> void:
	print("%s - %s" % [action, input])
