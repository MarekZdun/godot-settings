class_name SettingsSmartJSONResource
extends SettingsResource

@export var filepath: String


func _init():
	filepath = get_script().resource_path
