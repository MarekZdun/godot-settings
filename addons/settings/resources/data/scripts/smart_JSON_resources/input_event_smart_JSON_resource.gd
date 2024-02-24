class_name InputEventSmartJSONResource
extends InputEventResource

@export var filepath: String


func _init():
	filepath = get_script().resource_path
