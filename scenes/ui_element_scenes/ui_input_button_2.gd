extends Button

@export var action_name: String:
	set = set_action_name
@export var action_name_for_display: String:
	set = set_action_name_for_display

var _is_remapping: bool = false

@onready var action_label: Label = $MarginContainer/HBoxContainer/ActionLabel
@onready var input_label: Label = $MarginContainer/HBoxContainer/InputLabel
	
	
func _ready():
	button_down.connect(_on_button_down)
	update_labels()
		
		
func _input(event):
	if _is_remapping and event.is_pressed():
		InputHelper.replace_keyboard_input_at_index(action_name, 0, event, true)
		update_labels()
		accept_event()
		_is_remapping = false
		
	
func set_action_name(p_action_name: String) -> void:
	action_name = p_action_name
	update_labels()
			
			
func set_action_name_for_display(p_action_name_for_display: String) -> void:
	action_name_for_display = p_action_name_for_display
	update_labels()
	
	
func update_labels() -> void:
	action_label.text = action_name_for_display
	var keyboard_inputs: Array = InputHelper.get_keyboard_inputs_for_action(action_name)
	if not keyboard_inputs.is_empty():
		input_label.text = InputHelper.get_label_for_input(keyboard_inputs[0])
	
	
func _on_button_down() -> void:
	if not _is_remapping:
		_is_remapping = true
		input_label.text = "... Awaiting Input ..."
