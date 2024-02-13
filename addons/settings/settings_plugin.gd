@tool
extends EditorPlugin

const SETTINGS_FILEPATH = "res://addons/settings/settings.tscn"
const SETTINGS_AUTLOAD_NAME = "Settings"


func _enable_plugin():
	add_autoload_singleton(SETTINGS_AUTLOAD_NAME, SETTINGS_FILEPATH)


func _disable_plugin():
	remove_autoload_singleton(SETTINGS_AUTLOAD_NAME)
