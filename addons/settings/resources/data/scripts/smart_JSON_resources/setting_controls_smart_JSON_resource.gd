class_name SettingControlsSmartJSONResource
extends SettingControlsResource

@export var filepath: String


func _init():
	filepath = get_script().resource_path
