class_name SettingDisplaySmartJSONResource
extends SettingDisplayResource

@export var filepath: String


func _init():
	filepath = get_script().resource_path
