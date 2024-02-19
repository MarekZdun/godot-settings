class_name SettingAudioSmartJSONResource
extends SettingAudioResource

@export var filepath: String


func _init():
	filepath = get_script().resource_path
