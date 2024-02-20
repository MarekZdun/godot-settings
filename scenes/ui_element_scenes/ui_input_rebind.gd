extends Control

@export_file("*.tscn") var input_button_file_path: String:
	set(value):
		input_button_file_path = value
		_update_input_button_packed_scene_from_file_path(input_button_file_path)
		
var _input_button_packed_scene: PackedScene

@onready var action_list_v_box_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ActionListVBoxContainer
@onready var reset_button: Button = $Panel/MarginContainer/VBoxContainer/ResetButton


func _ready():
	reset_button.button_down.connect(_on_reset_button_button_down)
	create_input_action_list()
	if action_list_v_box_container.get_child_count() > 0:
		var input_button_first := action_list_v_box_container.get_child(0)
		if input_button_first.focus_mode == FOCUS_NONE:
			var buttons := input_button_first.find_children("*", "Button")
			if not buttons.is_empty():
				buttons[0].grab_focus()
		else:
			input_button_first.grab_focus()


func create_input_action_list() -> void:
	if not _input_button_packed_scene:
		return
		
	for input_button in action_list_v_box_container.get_children():
		input_button.queue_free()
	
	for i in range(Settings.input_actions.size()):
		var input_button := _input_button_packed_scene.instantiate()
		action_list_v_box_container.add_child(input_button)
		input_button.set_action_name(Settings.input_actions[i])
		input_button.set_action_name_for_display(Settings.input_action_names[i])
		
		
func _update_input_button_packed_scene_from_file_path(p_input_button_file_path: String) -> void:
	if p_input_button_file_path:
		_input_button_packed_scene = load(p_input_button_file_path) as PackedScene
		
		
func _on_reset_button_button_down() -> void:
	InputHelper.reset_all_actions()
	create_input_action_list()
