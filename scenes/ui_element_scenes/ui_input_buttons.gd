extends Control

@export var action_name: String:
	set = set_action_name
@export var action_name_for_display: String:
	set = set_action_name_for_display

var changing_input_index: int = -1

@onready var action_label: Label = $InputMarginContainer/HBoxContainer/ActionLabel
@onready var input_button: Button = $InputMarginContainer/HBoxContainer/InputButton
@onready var input_button_2: Button = $InputMarginContainer/HBoxContainer/InputButton2

	
	
func _ready():
	input_button.button_down.connect(_on_input_button_down)
	input_button_2.button_down.connect(_on_input_button_2_down)
	update()
		
		
func _input(event):
	if changing_input_index == -1:
		return
		
	if changing_input_index == 0 and (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		InputHelper.replace_keyboard_input_at_index(action_name, 0, event, true)
		update()
		accept_event()
		changing_input_index = -1
		
	if changing_input_index == 1 and (event is InputEventJoypadButton and event.is_pressed()):
		InputHelper.replace_joypad_input_at_index(action_name, 0, event, true)
		update()
		accept_event()
		changing_input_index = -1
		
		
func set_action_name(p_action_name: String) -> void:
	action_name = p_action_name
	update()
	
	
func set_action_name_for_display(p_action_name_for_display: String) -> void:
	action_name_for_display = p_action_name_for_display
	update()
	
	
func update() -> void:
	action_label.text = action_name_for_display
	var keyboard_inputs: Array = InputHelper.get_keyboard_inputs_for_action(action_name)
	var joypad_inputs: Array = InputHelper.get_joypad_inputs_for_action(action_name)
	
	if not keyboard_inputs.is_empty():
		input_button.text = InputHelper.get_label_for_input(keyboard_inputs[0])
		
	if not joypad_inputs.is_empty():
		input_button_2.text = InputHelper.get_label_for_input(joypad_inputs[0])
	
	
func _on_input_button_down() -> void:
	changing_input_index = 0
	input_button.text = "... Awaiting Keyboard/Mouse Input ..."
	
	
func _on_input_button_2_down() -> void:
	changing_input_index = 1
	input_button_2.text = "... Awaiting Joypad Input ..."
