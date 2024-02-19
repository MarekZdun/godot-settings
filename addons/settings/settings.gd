@tool
extends Node

enum SaveLoadType {JSON_, RESOURCE_, INI_}
enum WindowModeType {FULLSCREEN, WINDOW, BORDERLESS_WINDOW}
enum GettextFileExtensions {PO, MO}

const LANGUAGE_DEFAULT: String = "en"

@export var gettext_file_extension: GettextFileExtensions = GettextFileExtensions.PO
@export_group("Save Config")
@export var save_config_type: SaveLoadType = SaveLoadType.JSON_
@export_dir var save_config_dir_path: String = "user://save":
	set(p_save_config_dir_path):
		save_config_dir_path = p_save_config_dir_path
		_update_save_config_file_path()
@export var save_config_filename: String = "settings":
	set(p_save_config_filename):
		save_config_filename = p_save_config_filename
		_update_save_config_file_path()

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

var setting_audio: SettingAudio
var setting_controls: SettingControls
var setting_language: SettingLanguage
var setting_display: SettingDisplay

var translation_file_paths: Array[String]:
	set(p_translation_file_paths):
		translation_file_paths = p_translation_file_paths
		_update_translations()
var gettext_translation_file_paths: Array[String]:
	set(p_gettext_translation_file_paths):
		gettext_translation_file_paths = p_gettext_translation_file_paths
		_update_gettext_translations()

var _save_config_file_path: String
var _translations: Array[Translation]
var _gettext_translations: Array[Translation]


func _ready():
	if Engine.is_editor_hint():
		return
	
	_update_save_config_file_path()
	
	setting_audio = SettingAudio.new()
	setting_controls = SettingControls.new()
	setting_language = SettingLanguage.new()
	setting_display = SettingDisplay.new()
	
	setting_language.add_translations(_translations)
	setting_language.add_translations(_gettext_translations)
	
	if not load_settings():
		reset_to_default()
		
		
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
	
	
func save_settings(save_load_type: SaveLoadType = save_config_type) -> void:
	DirAccess.make_dir_recursive_absolute(save_config_dir_path)

	var settings: SettingsResource
	match save_load_type:
		SaveLoadType.JSON_:
			settings = _evaluate_settings(SettingsSmartJSONResource.new())
			save_settings_JSON(settings)
		SaveLoadType.RESOURCE_:
			settings = _evaluate_settings(SettingsResource.new())
			save_settings_resource(settings)
		SaveLoadType.INI_:
			settings = _evaluate_settings(SettingsResource.new())
			save_settings_INI(settings)
	
	
func load_settings(save_load_type: SaveLoadType = save_config_type) -> bool:
	match save_load_type:
		SaveLoadType.JSON_:
			return load_settings_JSON()
		SaveLoadType.RESOURCE_:
			return load_settings_resource()
		SaveLoadType.INI_:
			return load_settings_INI()
		_:
			return false
	
	
func save_settings_resource(settings: SettingsResource) -> void:
	FileUtil.save_data_resource(_save_config_file_path, settings)
	
	
func load_settings_resource() -> bool:
	var settings := FileUtil.load_data_resource(_save_config_file_path) as SettingsResource
	if not settings:
		print("Error loading the settings.")
		return false
	_update_settings(settings)
	return true
	
	
func save_settings_JSON(settings: SettingsSmartJSONResource) -> void:
	FileUtil.save_data_JSON(_save_config_file_path, SmartJSONParser.serialize_variant_data(settings), "\t")
	
	
func load_settings_JSON() -> bool:
	var settings: SettingsSmartJSONResource
	var data : Dictionary = FileUtil.load_data_JSON(_save_config_file_path)
	if !data.is_empty() and data.has("type") and data.has("value"):
		settings = SmartJSONParser.deserialize_variant_data(data)
	if not settings:
		print("Error loading the settings.")
		return false
	_update_settings(settings)
	return true
	
	
func save_settings_INI(settings: SettingsResource) -> void:
	var config := ConfigFile.new()
	for section in settings.get_property_list():
		if section.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
			var setting: Resource = settings[section.name]
			for prop in setting.get_property_list():
				if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
					config.set_value(section.name, prop.name, setting[prop.name])
	config.save(_save_config_file_path)
	
	
func load_settings_INI() -> bool:
	var config := ConfigFile.new()
	var settings: SettingsResource = SettingsResource.new()
	var error := config.load(_save_config_file_path)
	if error != OK:
		print("Error loading the settings. Error code: %s" % error)
		return false
		
	for section in settings.get_property_list():
		if section.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
			if section.name == "setting_audio":
				var setting_audio_res := SettingAudioResource.new()
				for prop in setting_audio_res.get_property_list():
					if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
						setting_audio_res[prop.name] = config.get_value(section.name, prop.name)
				settings[section.name] = setting_audio_res
						
			elif section.name == "setting_controls":
				var setting_controls_res := SettingControlsResource.new()
				for prop in setting_controls_res.get_property_list():
					if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
						setting_controls_res[prop.name] = config.get_value(section.name, prop.name)
				settings[section.name] = setting_controls_res
						
			elif section.name == "setting_language":
				var setting_language_res := SettingLanguageResource.new()
				for prop in setting_language_res.get_property_list():
					if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
						setting_language_res[prop.name] = config.get_value(section.name, prop.name)
				settings[section.name] = setting_language_res
						
			elif section.name == "setting_display":
				var setting_display_res := SettingDisplayResource.new()
				for prop in setting_display_res.get_property_list():
					if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
						setting_display_res[prop.name] = config.get_value(section.name, prop.name)
				settings[section.name] = setting_display_res
					
	_update_settings(settings)
	return true
	
	
func reset_to_default() -> void:
	setting_audio.reset_to_default()
	setting_controls.reset_to_default()
	setting_language.reset_to_default()
	setting_display.reset_to_default()
	
	
func _update_save_config_file_path() -> void:
	var ext: String
	match save_config_type:
		SaveLoadType.JSON_:
			ext = ".json"
		SaveLoadType.RESOURCE_:
			ext = ".tres"
		SaveLoadType.INI_:
			ext = ".ini"
	_save_config_file_path = save_config_dir_path.path_join(save_config_filename + ext)
	
	
func _update_translations() -> void:
	_translations.clear()

	for translation_file_path in translation_file_paths:
		if translation_file_path.is_empty():
			continue
		var translation := load(translation_file_path)
		if translation is OptimizedTranslation:
			_translations.append(translation)
			
			
func _update_gettext_translations() -> void:
	_gettext_translations.clear()

	for gettext_translation_file_path in gettext_translation_file_paths:
		if gettext_translation_file_path.is_empty():
			continue
		var translation := load(gettext_translation_file_path)
		if translation is Translation:
			_gettext_translations.append(translation)
	
	
func _update_settings(p_settings: SettingsResource) -> void:
	setting_audio.set_audio_data(p_settings.setting_audio)
	setting_controls.set_controls_data(p_settings.setting_controls)
	setting_language.set_language_data(p_settings.setting_language)
	setting_display.set_display_data(p_settings.setting_display)
	
	
func _evaluate_settings(p_settings: SettingsResource) -> SettingsResource:
	if p_settings is SettingsSmartJSONResource:
		p_settings.setting_audio = setting_audio.get_smart_JSON_audio_data()
		p_settings.setting_controls = setting_controls.get_smart_JSON_controls_data()
		p_settings.setting_language = setting_language.get_smart_JSON_language_data()
		p_settings.setting_display = setting_display.get_smart_JSON_display_data()
	else :
		p_settings.setting_audio = setting_audio.get_audio_data()
		p_settings.setting_controls = setting_controls.get_controls_data()
		p_settings.setting_language = setting_language.get_language_data()
		p_settings.setting_display = setting_display.get_display_data()
	
	return p_settings

# ------------------------------------------------------------------------------	
	
class SettingAudio extends Object:
	
	signal volume_master_changed(volume, previous_volume)
	signal volume_music_changed(volume, previous_volume)
	signal volume_sound_changed(volume, previous_volume)
	signal volume_sound_2d_changed(volume, previous_volume)
	signal volume_sound_3d_changed(volume, previous_volume)
	
	var volume_master: float = 0.0:
		set = set_volume_master
	var volume_music: float = 0.0:
		set = set_volume_music
	var volume_sound: float = 0.0:
		set = set_volume_sound
	var volume_sound_2d: float = 0.0:
		set = set_volume_sound_2d
	var volume_sound_3d: float = 0.0:
		set = set_volume_sound_3d


	func set_volume_master(volume: float) -> void:
		var previous_volume_master := volume_master
		volume_master = volume
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume_master))
		if previous_volume_master != volume_master:
			volume_master_changed.emit(volume_master, previous_volume_master)
		
	func set_volume_music(volume: float) -> void:
		var previous_volume_music := volume_music
		volume_music = volume
		var bus_index := AudioServer.get_bus_index("Music")
		if bus_index != -1:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(volume_music))
			if previous_volume_music != volume_music:
				volume_music_changed.emit(volume_music, previous_volume_music)
		
		
	func set_volume_sound(volume: float) -> void:
		var previous_volume_sound := volume_sound
		volume_sound = volume
		var bus_index := AudioServer.get_bus_index("Sound")
		if bus_index != -1:
			AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_sound))
			if previous_volume_sound != volume_sound:
				volume_sound_changed.emit(volume_sound, previous_volume_sound)
		
		
	func set_volume_sound_2d(volume: float) -> void:
		var previous_volume_sound_2d := volume_sound_2d
		volume_sound_2d = volume
		var bus_index := AudioServer.get_bus_index("Sound2D")
		if bus_index != -1:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound2D"), linear_to_db(volume_sound_2d))
			if previous_volume_sound_2d != volume_sound_2d:
				volume_sound_2d_changed.emit(volume_sound_2d, previous_volume_sound_2d)
		
		
	func set_volume_sound_3d(volume: float) -> void:
		var previous_volume_sound_3d := volume_sound_3d
		volume_sound_3d = volume
		var bus_index := AudioServer.get_bus_index("Sound3D")
		if bus_index != -1:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound3D"), linear_to_db(volume_sound_3d))
			if previous_volume_sound_3d != volume_sound_3d:
				volume_sound_3d_changed.emit(volume_sound_3d, previous_volume_sound_3d)


	func get_audio_data() -> SettingAudioResource:
		var setting_audio_resource := SettingAudioResource.new()
		setting_audio_resource.volume_master = volume_master
		setting_audio_resource.volume_music = volume_music
		setting_audio_resource.volume_sound = volume_sound
		setting_audio_resource.volume_sound_2d = volume_sound_2d
		setting_audio_resource.volume_sound_3d = volume_sound_3d
		return setting_audio_resource
		
		
	func get_smart_JSON_audio_data() -> SettingAudioSmartJSONResource:
		var setting_audio_resource := SettingAudioSmartJSONResource.new()
		setting_audio_resource.volume_master = volume_master
		setting_audio_resource.volume_music = volume_music
		setting_audio_resource.volume_sound = volume_sound
		setting_audio_resource.volume_sound_2d = volume_sound_2d
		setting_audio_resource.volume_sound_3d = volume_sound_3d
		return setting_audio_resource
		
		
	func set_audio_data(setting_audio_resource: SettingAudioResource) -> void:
		set_volume_master(setting_audio_resource.volume_master)
		set_volume_music(setting_audio_resource.volume_music)
		set_volume_sound(setting_audio_resource.volume_sound)
		set_volume_sound_2d(setting_audio_resource.volume_sound_2d)
		set_volume_sound_3d(setting_audio_resource.volume_sound_3d)
		
		
	func reset_to_default() -> void:
		volume_master = Settings.volume_master_default
		volume_music = Settings.volume_music_default
		volume_sound = Settings.volume_sound_default
		volume_sound_2d = Settings.volume_sound_2d_default
		volume_sound_3d = Settings.volume_sound_3d_default
	
# ------------------------------------------------------------------------------

class SettingControls extends Object:

	signal keyboard_input_changed(action, input)
	signal joypad_input_changed(action, input)


	func get_controls_data() -> SettingControlsResource:
		var setting_controls_resource := SettingControlsResource.new()
		var input_map: Dictionary = serialize_inputs_for_actions(Settings.input_actions)
		for action_name in input_map:
			var input_event: Dictionary = input_map[action_name]
			var input_event_resource := InputEventResource.new()
			input_event_resource.keyboard = input_event["keyboard"]
			input_event_resource.mouse = input_event["mouse"]
			input_event_resource.joypad = input_event["joypad"]
			setting_controls_resource.action_names.append(action_name)
			setting_controls_resource.action_input_events.append(input_event_resource)
		return setting_controls_resource
		
		
	func get_smart_JSON_controls_data() -> SettingControlsSmartJSONResource:
		var setting_controls_resource := SettingControlsSmartJSONResource.new()
		var input_map: Dictionary = serialize_inputs_for_actions(Settings.input_actions)
		for action_name in input_map:
			var input_event: Dictionary = input_map[action_name]
			var input_event_resource := InputEventSmartJSONResource.new()
			input_event_resource.keyboard = input_event["keyboard"]
			input_event_resource.mouse = input_event["mouse"]
			input_event_resource.joypad = input_event["joypad"]
			setting_controls_resource.action_names.append(action_name)
			setting_controls_resource.action_input_events.append(input_event_resource)
		return setting_controls_resource
		
		
	func set_controls_data(setting_controls_resource: SettingControlsResource) -> void:
		var input_map: Dictionary
		var action_names := setting_controls_resource.action_names
		var action_input_events := setting_controls_resource.action_input_events
		for i in range(action_names.size()):
			var input_event: Dictionary
			var action_name := action_names[i]
			var input_event_resource := action_input_events[i]
			input_event["keyboard"] = input_event_resource.keyboard
			input_event["mouse"] = input_event_resource.mouse
			input_event["joypad"] = input_event_resource.joypad
			input_map[action_name] = input_event
		deserialize_inputs_for_actions(input_map)
		
		
	func serialize_inputs_for_actions(actions: PackedStringArray = []) -> Dictionary:
		if actions == null or actions.is_empty():
			actions = InputMap.get_actions()

		var map: Dictionary = {}
		for action in actions:
			var inputs: Array[InputEvent] = InputMap.action_get_events(action)
			var action_map: Dictionary = {
				"keyboard": [],
				"mouse": [],
				"joypad": []
			}
			for input in inputs:
				if input is InputEventKey:
					var s: String = get_label_for_input(input)
					var modifiers: Array[String] = []
					if input.alt_pressed:
						modifiers.append("alt")
					if input.shift_pressed:
						modifiers.append("shift")
					if input.ctrl_pressed:
						modifiers.append("ctrl")
					if input.meta_pressed:
						modifiers.append("meta")
					if not modifiers.is_empty():
						s += "|" + ",".join(modifiers)
					action_map["keyboard"].append(s)
				elif input is InputEventMouseButton:
					action_map["mouse"].append(input.button_index)
				elif input is InputEventJoypadButton:
					action_map["joypad"].append(input.button_index)
				elif input is InputEventJoypadMotion:
					action_map["joypad"].append("%d|%d" % [input.axis, input.axis_value])

			map[action] = action_map

		return map
		
		
	func deserialize_inputs_for_actions(map: Dictionary) -> void:
		for action in map.keys():
			InputMap.action_erase_events(action)

			for key in map[action]["keyboard"]:
				var keyboard_input = InputEventKey.new()
				if "|" in key:
					var bits = key.split("|")
					keyboard_input.keycode = OS.find_keycode_from_string(bits[0])
					bits = bits[1].split(",")
					if bits.has("alt"):
						keyboard_input.alt_pressed = true
					if bits.has("shift"):
						keyboard_input.shift_pressed = true
					if bits.has("ctrl"):
						keyboard_input.ctrl_pressed = true
					if bits.has("meta"):
						keyboard_input.meta_pressed = true
				else:
					keyboard_input.keycode = OS.find_keycode_from_string(key)
				InputMap.action_add_event(action, keyboard_input)

			for button_index in map[action]["mouse"]:
				var mouse_input = InputEventMouseButton.new()
				mouse_input.button_index = int(button_index)
				InputMap.action_add_event(action, mouse_input)

			for button_index_or_motion in map[action]["joypad"]:
				if "|" in str(button_index_or_motion):
					var joypad_motion_input = InputEventJoypadMotion.new()
					var bits = button_index_or_motion.split("|")
					joypad_motion_input.axis = int(bits[0])
					joypad_motion_input.axis_value = float(bits[1])
					InputMap.action_add_event(action, joypad_motion_input)
				else:
					var joypad_input = InputEventJoypadButton.new()
					joypad_input.button_index = int(button_index_or_motion)
					InputMap.action_add_event(action, joypad_input)
					
			var input: InputEvent = get_joypad_input_for_action(action)
			if input != null:
				joypad_input_changed.emit(action, input)

			input = get_keyboard_input_for_action(action)
			if input != null:
				keyboard_input_changed.emit(action, input)
					
					
	func get_label_for_input(input: InputEvent) -> String:
		if input == null: return ""

		if input is InputEventKey:
			if input.physical_keycode > 0:
				var keycode := DisplayServer.keyboard_get_keycode_from_physical(input.physical_keycode)
				return OS.get_keycode_string(keycode)
			elif input.keycode > 0:
				return OS.get_keycode_string(input.keycode)
			else:
				return input.as_text()
		elif input is InputEventMouseButton:
			match input.button_index:
				MOUSE_BUTTON_LEFT:
					return "Mouse Left Button"
				MOUSE_BUTTON_MIDDLE:
					return "Mouse Middle Button"
				MOUSE_BUTTON_RIGHT:
					return "Mouse Right Button"
			return "Mouse Button %d" % input

		return input.as_text()
		
		
	func get_joypad_inputs_for_action(action: String) -> Array[InputEvent]:
		return InputMap.action_get_events(action).filter(func(event):
			return event is InputEventJoypadButton or event is InputEventJoypadMotion
		)
		
		
	func get_joypad_input_for_action(action: String) -> InputEvent:
		var buttons: Array[InputEvent] = get_joypad_inputs_for_action(action)
		return null if buttons.is_empty() else buttons[0]
		
		
	func get_keyboard_inputs_for_action(action: String) -> Array[InputEvent]:
		return InputMap.action_get_events(action).filter(func(event):
			return event is InputEventKey or event is InputEventMouseButton
		)
		
		
	func get_keyboard_input_for_action(action: String) -> InputEvent:
		var inputs: Array[InputEvent] = get_keyboard_inputs_for_action(action)
		return null if inputs.is_empty() else inputs[0]
		
		
	func reset_to_default() -> void:
		InputMap.load_from_project_settings()
		for action in Settings.input_actions:
			var input: InputEvent = get_joypad_input_for_action(action)
			if input != null:
				joypad_input_changed.emit(action, input)

			input = get_keyboard_input_for_action(action)
			if input != null:
				keyboard_input_changed.emit(action, input)

# ------------------------------------------------------------------------------

class SettingLanguage extends Object:
	
	signal retranslated(language)
	
	var language: String:
		set = set_language
		
		
	func set_language(p_language: String) -> void:
		var previous_language := language
		language = p_language
		TranslationServer.set_locale(language)
		if previous_language != language:
			retranslated.emit(language)
		
		
	func add_translations(p_translations: Array[Translation]) -> void:
		for translation in p_translations:
			TranslationServer.add_translation(translation)
			
			
	func get_language_data() -> SettingLanguageResource:
		var setting_language_resource := SettingLanguageResource.new()
		setting_language_resource.locale = TranslationServer.get_locale()
		return setting_language_resource
		
		
	func get_smart_JSON_language_data() -> SettingLanguageSmartJSONResource:
		var setting_language_resource := SettingLanguageSmartJSONResource.new()
		setting_language_resource.locale = TranslationServer.get_locale()
		return setting_language_resource
		
		
	func set_language_data(setting_language_resource: SettingLanguageResource) -> void:
		language = setting_language_resource.locale
		
		
	func reset_to_default() -> void:
		if OS.get_locale_language() in TranslationServer.get_loaded_locales():
			set_language(OS.get_locale_language())
		else:
			set_language(Settings.LANGUAGE_DEFAULT)

# ------------------------------------------------------------------------------

class SettingDisplay extends Object:
	
	signal resized(current_resolution, previous_resolution)
	signal fullscreen_changed(fullscreen)
	signal content_scale_size_changed(current_scale_size, previous_scale_size)
	signal content_scale_factor_changed(current_content_scale_factor, previous_content_scale_factor)
	
	var fullscreen: bool = false
	var borderless: bool = false
	var resolution_mode_index: int
	var scale: int
	var max_scale: int
	var viewport_size: Vector2i
	var window_size: Vector2i
	var screen_size: Vector2i
	var base_size: Vector2i = Vector2(ProjectSettings["display/window/size/viewport_width"], ProjectSettings["display/window/size/viewport_height"])
	var content_scale_size: Vector2i
	var content_scale_factor: float
	
	
	func change_to_fullscreen() -> void:
		var previous_resolution := window_size
		var previous_fullscreen := fullscreen
		
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			
		evaluate_display()
		if fullscreen != previous_fullscreen:
			fullscreen_changed.emit(fullscreen)
		if window_size != previous_resolution:
			resized.emit(window_size, previous_resolution)
			
			
	func change_to_window() -> void:
		var previous_resolution := window_size
		var previous_fullscreen := fullscreen
		
		if not Settings.window_resizable:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if not Settings.resolution_mode_sizes.is_empty():
			DisplayServer.window_set_size(Settings.resolution_mode_sizes[resolution_mode_index])
		center_window()
			
		evaluate_display()
		if fullscreen != previous_fullscreen:
			fullscreen_changed.emit(fullscreen)
		if window_size != previous_resolution:
			resized.emit(window_size, previous_resolution)
			
			
	func change_to_borderless_window() -> void:
		var previous_resolution := window_size
		var previous_fullscreen := fullscreen
		
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		if not Settings.resolution_mode_sizes.is_empty():
			DisplayServer.window_set_size(Settings.resolution_mode_sizes[resolution_mode_index])
		center_window()
		
		evaluate_display()
		if fullscreen != previous_fullscreen:
			fullscreen_changed.emit(fullscreen)
		if window_size != previous_resolution:
			resized.emit(window_size, previous_resolution)
		
		
	func change_resolution_mode_to(index: int) -> void:
		var previous_resolution := window_size
		resolution_mode_index = index
		if not Settings.resolution_mode_sizes.is_empty():
			DisplayServer.window_set_size(Settings.resolution_mode_sizes[resolution_mode_index])
		center_window()

		evaluate_display()
		if window_size != previous_resolution:
			resized.emit(window_size, previous_resolution)
		
		
	func get_resolution_mode_size() -> Vector2i:
		var resolution_mode_size := Vector2i.ZERO
		if not Settings.resolution_mode_sizes.is_empty():
			resolution_mode_size = Settings.resolution_mode_sizes[resolution_mode_index]
		return resolution_mode_size
		
		
	func change_scale(p_scale: int) -> void:
		if Settings.get_window().content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED:
			return
		var previous_resolution := window_size
		var previous_fullscreen := fullscreen
		scale = clamp(p_scale, 1, max_scale)
		if scale >= max_scale:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			#DisplayServer.window_set_size(viewport_size * scale)
			DisplayServer.window_set_size(base_size * scale)
			center_window()
			
		evaluate_display()
		if fullscreen != previous_fullscreen:
			fullscreen_changed.emit(fullscreen)
		if window_size != previous_resolution:
			resized.emit(window_size, previous_resolution)
			
			
	func change_content_scale_size(p_content_scale_size: Vector2i) -> void:
		var previous_content_scale_size := content_scale_size
		Settings.get_window().content_scale_size = p_content_scale_size
		
		evaluate_display()
		if content_scale_size != previous_content_scale_size:
			content_scale_size_changed.emit(content_scale_size, previous_content_scale_size)
		
		
	func change_content_scale_factor(p_content_scale_factor: float) -> void:
		var previous_content_scale_factor := content_scale_factor
		Settings.get_window().content_scale_factor = p_content_scale_factor
		
		evaluate_display()
		if content_scale_factor != previous_content_scale_factor:
			content_scale_factor_changed.emit(content_scale_factor, previous_content_scale_factor)
			
			
	func evaluate_display() -> void:
		viewport_size = Settings.get_viewport().get_visible_rect().size
		window_size = DisplayServer.window_get_size()
		screen_size = DisplayServer.screen_get_size()
		content_scale_size = Settings.get_window().content_scale_size
		content_scale_factor = Settings.get_window().content_scale_factor
		fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		borderless = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
		resolution_mode_index = find_index_most_similar_vector2i_to_base_vector2i(window_size, Settings.resolution_mode_sizes) \
				 if (Settings.catch_fullscreen_resolution or !fullscreen) else resolution_mode_index
		#max_scale = min(ceil(float(screen_size.x) / float(viewport_size.x)), ceil(float(screen_size.y) / float(viewport_size.y)))
		max_scale = min(ceil(float(screen_size.x) / float(base_size.x)), ceil(float(screen_size.y) / float(base_size.y)))
		#scale = max_scale if fullscreen else min(float(window_size.x) / float(viewport_size.x), float(window_size.y) / float(viewport_size.y))
		scale = max_scale if fullscreen else min(float(window_size.x) / float(base_size.x), float(window_size.y) / float(base_size.y))

		
	func center_window() -> void:
		var center_screen := DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
		var window_size := Settings.get_window().get_size_with_decorations()
		Settings.get_window().set_position(center_screen - window_size / 2)
		
		
	func find_index_most_similar_vector2i_to_base_vector2i(base_vector: Vector2i, pool: Array[Vector2i]) -> int:
		var index := -1
		if pool.is_empty():
			return index
		
		var most_similar_vector := pool[0]
		index = 0
		for i in range(pool.size()):
			var part_a: bool = abs(base_vector.x - pool[i].x) < abs(base_vector.x - most_similar_vector.x)
			var part_b: bool = abs(base_vector.y - pool[i].y) < abs(base_vector.y - most_similar_vector.y)
			if part_a and part_b:
				most_similar_vector = pool[i]
				index = i
		return index
		

	func get_display_data() -> SettingDisplayResource:
		var setting_display_resource := SettingDisplayResource.new()
		setting_display_resource.fullscreen = fullscreen
		setting_display_resource.borderless = borderless
		setting_display_resource.resolution_mode_index = resolution_mode_index
		setting_display_resource.content_scale_size = content_scale_size
		setting_display_resource.content_scale_factor = content_scale_factor
		return setting_display_resource
		
		
	func get_smart_JSON_display_data() -> SettingDisplaySmartJSONResource:
		var setting_display_resource := SettingDisplaySmartJSONResource.new()
		setting_display_resource.fullscreen = fullscreen
		setting_display_resource.borderless = borderless
		setting_display_resource.resolution_mode_index = resolution_mode_index
		setting_display_resource.content_scale_size = content_scale_size
		setting_display_resource.content_scale_factor = content_scale_factor
		return setting_display_resource
		
		
	func set_display_data(setting_display_resource: SettingDisplayResource) -> void:
		change_resolution_mode_to(setting_display_resource.resolution_mode_index)
		if setting_display_resource.fullscreen:
			change_to_fullscreen()
		elif setting_display_resource.borderless:
			change_to_borderless_window()
		else :
			change_to_window()
			
		change_content_scale_size(setting_display_resource.content_scale_size)
		change_content_scale_factor(setting_display_resource.content_scale_factor)
		
		
	func reset_to_default() -> void:
		var size_mode: DisplayServer.WindowMode = ProjectSettings["display/window/size/mode"]
		var size_borderless: bool = ProjectSettings["display/window/size/borderless"]
		var stretch_scale: float = ProjectSettings["display/window/stretch/scale"]

		DisplayServer.window_set_size(base_size)
		evaluate_display()
		if size_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			change_to_fullscreen()
		elif size_borderless == true:
			change_to_borderless_window()
		elif size_mode == DisplayServer.WINDOW_MODE_WINDOWED:
			change_to_window()
		
		change_content_scale_size(base_size)
		change_content_scale_factor(stretch_scale)

# ------------------------------------------------------------------------------
