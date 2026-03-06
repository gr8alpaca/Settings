@tool
extends Control

@export var bg_color_setting: SettingsProperty
@export var color_rect: ColorRect
@export var additional_settings: Array[SettingsProperty]

func _ready() -> void:
	bg_color_setting.value_changed.connect(color_rect.set_color)
	color_rect.set_color(bg_color_setting.get_value())

func _on_save_button_pressed() -> void:
	if Engine.is_editor_hint(): return
	Settings.save_settings(additional_settings)

func _on_load_button_pressed() -> void:
	if Engine.is_editor_hint(): return
	Settings.load_settings(additional_settings)
