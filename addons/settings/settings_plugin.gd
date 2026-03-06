@tool
extends EditorPlugin
## Settings plugin initialization script.

const Utils:= preload("util.gd")

func _enable_plugin() -> void:
	add_autoload_singleton("Settings", "settings.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("Settings")

func _enter_tree() -> void:
	for dict: Dictionary in Utils.SETTINGS_CONFIG.values():
		Utils.set_project_setting(dict.name, dict.value, dict)
	
	EditorInterface.get_file_system_dock().folder_moved.connect(_on_folder_moved)
	
	prompt_dir_create.call_deferred(Utils.get_settings_resource_dir())

func _exit_tree() -> void:
	EditorInterface.get_file_system_dock().folder_moved.disconnect(_on_folder_moved)

## Automatically updates settings resource dir if moved.
func _on_folder_moved(old_folder: String, new_folder: String) -> void:
	if old_folder.trim_suffix("/") == Utils.get_settings_resource_dir():
		ProjectSettings.set_setting(Utils.PROJECT_SETTING_SECTION.path_join(Utils.SETTINGS_CONFIG.RESOURCE_DIR.name), new_folder)
		ProjectSettings.save()

func prompt_dir_create(dir: String) -> void:
	if not dir or DirAccess.dir_exists_absolute(dir): return
	
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Create Settings Directory"
	dialog.dialog_text = "Current setting directory '%s' does not exist. Would you like to create it?" % dir
	dialog.ok_button_text = "Yes"
	dialog.cancel_button_text = "No"
	
	dialog.confirmed.connect(create_dir.bind(dir))
	dialog.confirmed.connect(dialog.queue_free, CONNECT_DEFERRED)
	dialog.canceled.connect(dialog.queue_free, CONNECT_DEFERRED)
	
	EditorInterface.popup_dialog_centered(dialog)

func create_dir(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	
	if not EditorInterface.get_resource_filesystem().is_scanning():
		EditorInterface.get_resource_filesystem().scan()
		EditorInterface.get_file_system_dock().folder_moved.connect(_on_folder_moved)
	
