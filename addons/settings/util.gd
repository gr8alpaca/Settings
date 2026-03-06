@tool
extends Object
## Static script for settings plugin scripts to use.

const PROJECT_SETTING_SECTION: String = "settings_plugin/config/"

const SETTINGS_CONFIG: Dictionary[String, Dictionary] = {
	RESOURCE_DIR = {
		name = "resource_directory",
		value = "res://resources/settings",
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
	return get_project_setting(SETTINGS_CONFIG.RESOURCE_DIR.name, SETTINGS_CONFIG.RESOURCE_DIR.value)

static func get_settings_file_path() -> String:
	return get_project_setting(SETTINGS_CONFIG.FILE_PATH.name, SETTINGS_CONFIG.FILE_PATH.value)

static func get_settings_load_on_ready() -> bool:
	return get_project_setting(SETTINGS_CONFIG.LOAD_ON_READY.name, SETTINGS_CONFIG.LOAD_ON_READY.value)
