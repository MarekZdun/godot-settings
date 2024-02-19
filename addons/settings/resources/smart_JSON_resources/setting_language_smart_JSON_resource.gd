class_name SettingLanguageSmartJSONResource
extends SettingLanguageResource

@export var filepath: String


func _init():
	filepath = get_script().resource_path
