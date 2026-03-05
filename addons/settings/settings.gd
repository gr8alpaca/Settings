extends Node

const Utils:= preload("util.gd")

signal loaded
signal saved

var setting_properties: Array[SettingsProperty]

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	for prop: SettingsProperty in load_resource_dir():
		add_settings_property(prop)
	
	if Utils.get_settings_load_on_ready():
		load_settings()

func add_settings_property(prop: SettingsProperty) -> void:
	if not prop in setting_properties: 
		setting_properties.push_back(prop)

func load_settings(additional_settings: Array[SettingsProperty] = []) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(Utils.get_settings_file_path())
	for prop: SettingsProperty in setting_properties + additional_settings:
		prop.read_file(cfg)
	
	loaded.emit()

func save_settings(additional_settings: Array[SettingsProperty] = []) -> void:
	var save_file_path: String = Utils.get_settings_file_path()
	if not save_file_path:
		push_error("Cannot save Settings file at path '%s'" % save_file_path)
		return
	
	var cfg: ConfigFile = ConfigFile.new()
	for prop: SettingsProperty in setting_properties + additional_settings:
		prop.write_file(cfg)
	cfg.save(save_file_path)
	saved.emit()

func load_resource_dir() -> Array[SettingsProperty]:
	var dir: String = Utils.get_settings_resource_dir()
	var props: Array[SettingsProperty]
	
	if not DirAccess.dir_exists_absolute(dir):
		return props
	
	for file: String in DirAccess.get_files_at(dir):
		var file_path: String = dir.path_join(file)
		if not FileAccess.file_exists(file_path): continue
		var res: Resource = ResourceLoader.load(file_path)
		if res is SettingsProperty:
			props.push_back(res)
	
	return props
