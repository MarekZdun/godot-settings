@tool
class_name SettingsConfigurationResource
extends Resource

enum WindowModeType {FULLSCREEN, WINDOW, BORDERLESS_WINDOW}
enum GettextFileExtensions {PO, MO}

@export var gettext_file_extension: GettextFileExtensions = GettextFileExtensions.PO
@export_group("Audio Properties")
@export_range(0, 1.0) var volume_master_default: float = 1.0
@export_range(0, 1.0) var volume_music_default: float = 0.1
@export_range(0, 1.0) var volume_sound_default: float = 0.1
@export_range(0, 1.0) var volume_sound_2d_default: float = 0.1
@export_range(0, 1.0) var volume_sound_3d_default: float = 0.1

@export_group("Input Properties")
@export var input_actions: Array[StringName] = []
@export var input_action_names: Array[StringName] = []

@export_group("Display Properties")
@export var window_mode_names: Array[StringName] = []
@export var window_mode_types_sequence: Array[WindowModeType] = []
@export var resolution_mode_names: Array[StringName] = []
@export var resolution_mode_sizes: Array[Vector2i] = []
@export var catch_fullscreen_resolution: bool = true
@export var window_resizable: bool = true

var translation_file_paths: Array[String]:
	set(p_translation_file_paths):
		translation_file_paths = p_translation_file_paths
		_update_translations()
var gettext_translation_file_paths: Array[String]:
	set(p_gettext_translation_file_paths):
		gettext_translation_file_paths = p_gettext_translation_file_paths
		_update_gettext_translations()
var translations: Array[Translation]
var gettext_translations: Array[Translation]


func _get_property_list() -> Array:
	var ext: String
	if gettext_file_extension == GettextFileExtensions.PO:
		ext = "po"
	elif gettext_file_extension == GettextFileExtensions.MO:
		ext = "mo"
		
	var properties = []
	properties.append({
		"name": "Language Properties",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	})
	properties.append({
		"name": "translation_file_paths",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "%d/%d:*.translation" % [TYPE_STRING, PROPERTY_HINT_FILE]
	})
	properties.append({
		"name": "gettext_translation_file_paths",
		"type": TYPE_ARRAY,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "%d/%d:*.%s" % [TYPE_STRING, PROPERTY_HINT_FILE, ext]
	})

	return properties
	
	
func _update_translations() -> void:
	translations.clear()

	for translation_file_path in translation_file_paths:
		if translation_file_path.is_empty():
			continue
		var translation := load(translation_file_path)
		if translation is OptimizedTranslation:
			translations.append(translation)
			
			
func _update_gettext_translations() -> void:
	gettext_translations.clear()

	for gettext_translation_file_path in gettext_translation_file_paths:
		if gettext_translation_file_path.is_empty():
			continue
		var translation := load(gettext_translation_file_path)
		if translation is Translation:
			gettext_translations.append(translation)
