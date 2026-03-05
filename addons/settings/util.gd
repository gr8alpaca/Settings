@tool
extends Object
## Static script for settings plugin scripts to use.

const PROJECT_SETTING_SECTION: String = "settings_plugin/config/"

const SETTINGS_CONFIG: Dictionary[String, Dictionary] = {
	RESOURCE_DIR = {
		name = "resource_directory",
		value = "res://settings",
		type = TYPE_STRING,
		hint = PROPERTY_HINT_DIR,
	},
	
	FILE_PATH = {
		name = "file_name",
		value = "user://settings.cfg",
		type = TYPE_STRING,
	},
	
	LOAD_ON_READY = {
		name = "load_on_ready",
		value = true,
		type = TYPE_BOOL,
	}
}

static func enable() -> void:
	if not Engine.is_editor_hint(): return

	for dict: Dictionary in SETTINGS_CONFIG.values():
		set_project_setting(dict.name, dict.value, dict)
	
	ProjectSettings.save()
	
	if not DirAccess.dir_exists_absolute(get_settings_resource_dir()):
		DirAccess.make_dir_recursive_absolute(get_settings_resource_dir())
		print("Created Settings directory at '%s'" % get_settings_resource_dir())
	

static func disable() -> void:
	pass

static func set_project_setting(key: String, value: Variant, property_info: Dictionary = {}) -> void:
	var path: String = PROJECT_SETTING_SECTION.path_join(key)
	if not ProjectSettings.has_setting(path):
		ProjectSettings.set_setting(path, value)
	ProjectSettings.set_initial_value(path, value)
	ProjectSettings.add_property_info({
		name = path,
		type = property_info.get("type", typeof(value)),
		hint = property_info.get("hint", PROPERTY_HINT_NONE),
		hint_string = property_info.get("hint_string", ""),
	})
	ProjectSettings.save()

static func get_project_setting(key: String, default: Variant = null) -> Variant:
	return ProjectSettings.get_setting(PROJECT_SETTING_SECTION.path_join(key), default)

static func get_settings_resource_dir() -> String:
	var dir: String = get_project_setting(SETTINGS_CONFIG.RESOURCE_DIR.name, SETTINGS_CONFIG.RESOURCE_DIR.value)
	if not dir.is_absolute_path():
		push_warning("Settings resource directory path '%s' is not absolute." % dir)
		return SETTINGS_CONFIG.RESOURCE_DIR.value
	return dir

static func get_settings_file_path() -> String:
	var file_path: String = get_project_setting(SETTINGS_CONFIG.FILE_PATH.name, SETTINGS_CONFIG.FILE_PATH.value)
	if not file_path.is_absolute_path():
		push_warning("Settings file path '%s' is not absolute." % file_path)
		return SETTINGS_CONFIG.FILE_PATH.value
	return file_path

static func get_settings_load_on_ready() -> bool:
	return get_project_setting(SETTINGS_CONFIG.LOAD_ON_READY.name, SETTINGS_CONFIG.LOAD_ON_READY.value)
