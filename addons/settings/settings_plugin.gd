@tool
extends EditorPlugin

const Utils:= preload("util.gd")

func _enable_plugin() -> void:
	add_autoload_singleton("Settings", "settings.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("Settings")

func _enter_tree() -> void:
	if not Engine.is_editor_hint(): return
	
	Utils.enable()
	
	if not EditorInterface.get_resource_filesystem().is_scanning():
		EditorInterface.get_resource_filesystem().scan()
		EditorInterface.get_file_system_dock().folder_moved.connect(_on_folder_moved)

func _exit_tree() -> void:
	if not Engine.is_editor_hint(): return
	Utils.disable()
	if EditorInterface.get_file_system_dock().folder_moved.is_connected(_on_folder_moved):
		EditorInterface.get_file_system_dock().folder_moved.disconnect(_on_folder_moved)

func add_theme_variation() -> void:
	var theme: Theme = ThemeDB.get_project_theme()
	if not theme: return
	theme.set_type_variation(&"SettingsPicker", &"HBoxContainer")
	

## Automatically updates settings resource dir if moved.
func _on_folder_moved(old_folder: String, new_folder: String) -> void:
	if old_folder == Utils.get_settings_resource_dir():
		ProjectSettings.set_setting(Utils.PROJECT_SETTING_SECTION.path_join(Utils.SETTINGS_CONFIG.RESOURCE_DIR.name), new_folder)
		ProjectSettings.save()
