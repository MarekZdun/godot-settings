extends Node

@export var debug: bool = true

var _last_size : Vector2i

@onready var h_slider: HSlider = $Control/VBoxContainer/HSlider


func _ready():
	h_slider.value_changed.connect(_on_h_slider_value_changed)
	Settings.setting_audio.volume_master_changed.connect(_on_volume_master_changed)
	_on_volume_master_changed(0, Settings.setting_audio.volume_master)
	
	#DisplayServer.window_set_min_size(Settings.resolution_mode_sizes[0])
	_last_size = DisplayServer.window_get_size()
	
	await get_tree().create_timer(4).timeout
	Settings.setting_audio.reset_to_default()
	
	
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


func _on_h_slider_value_changed(value: float) -> void:
	Settings.setting_audio.set_volume_master(value / 100)
	
	
func _on_volume_master_changed(previous_volume: float, volume: float) -> void:
	h_slider.value = volume * 100
	#print("%s - %s" % [previous_volume, volume]) 
