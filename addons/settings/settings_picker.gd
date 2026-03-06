@tool
class_name SettingsPicker extends HBoxContainer
## GUI for editing the value of a [SettingsProperty].

## [SettingsProperty] that picker will display and edit.
@export var settings_property: SettingsProperty: set = set_settings_property

@export_range(0.01, 3.0, 0.01, "or_greater")
var name_stretch_ratio: float = 0.3:
	set(val):
		name_stretch_ratio = val
		name_label.size_flags_stretch_ratio = name_stretch_ratio

@export var name_horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_RIGHT:
	set(val):
		name_horizontal_alignment = val
		name_label.horizontal_alignment = name_horizontal_alignment

@export var name_vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER:
	set(val):
		name_vertical_alignment = val
		name_label.vertical_alignment = name_vertical_alignment

@export var name_clip_text: bool = true:
	set(val):
		name_clip_text = val
		name_label.clip_text = name_clip_text

@export var picker_min_size: Vector2 = Vector2(24.0, 0.0):
	set(val):
		picker_min_size = val
		for child in picker_hbox.get_children():
			child.custom_minimum_size = picker_min_size

@export_group("Color Picker", "color_picker")
@export_range(0.01, 3.0, 0.01, "or_greater") 
var color_picker_popup_content_scale_factor: float = 0.5
@export var color_picker_popup_transparent: bool = true
@export var color_picker_picker_shape: ColorPicker.PickerShapeType = ColorPicker.PickerShapeType.SHAPE_HSV_WHEEL
@export var color_picker_deferred_mode: bool = false
@export var color_picker_can_add_swatches: bool = false
@export var color_picker_color_modes_visible: bool = false
@export var color_picker_hex_visible: bool = false
@export var color_picker_presets_visible: bool = false
@export var color_picker_sliders_visible: bool = false

@export_group("Line Edit", "line_edit")
@export var line_edit_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
@export var line_edit_max_length: int = 0
@export var line_edit_expand_to_text_length: bool
@export var line_edit_settings_override: Dictionary[StringName, Variant]

var name_label: Label
var picker_hbox: HBoxContainer

func _init() -> void:
	theme_type_variation = &"SettingsPicker"
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.size_flags_stretch_ratio = name_stretch_ratio
	name_label.horizontal_alignment = name_horizontal_alignment
	name_label.vertical_alignment = name_vertical_alignment
	name_label.clip_text = name_clip_text
	add_child(name_label)
	
	picker_hbox = HBoxContainer.new()
	picker_hbox.alignment = BoxContainer.ALIGNMENT_END
	picker_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(picker_hbox)

func set_settings_property(val: SettingsProperty) -> void:
	if settings_property:
		settings_property.display_mode_changed.disconnect(update_picker)
		settings_property.changed.disconnect(update_picker)
	
	settings_property = val
	
	if settings_property:
		settings_property.display_mode_changed.connect(update_picker)
		settings_property.changed.connect(update_picker)
	
	update_picker()

func get_display_mode() -> SettingsProperty.DisplayMode:
	return settings_property.get_display_mode() if settings_property else SettingsProperty.DisplayMode.HIDDEN

func update_picker() -> void:
	for child in picker_hbox.get_children():
		picker_hbox.remove_child(child)
		child.free()
	
	name_label.text = settings_property.get_display_name() if settings_property else ""
	
	var display_mode: SettingsProperty.DisplayMode = get_display_mode()
	
	match display_mode:
		SettingsProperty.DisplayMode.HIDDEN:
			hide()
			return
		
		SettingsProperty.DisplayMode.SLIDER, SettingsProperty.DisplayMode.SPINBOX:
			var slider: HSlider = HSlider.new()
			var spinbox: SpinBox = SpinBox.new()
			
			spinbox.share(slider)
			
			spinbox.size_flags_horizontal = Control.SIZE_SHRINK_END
			spinbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			spinbox.min_value = settings_property.min_value
			spinbox.max_value = settings_property.max_value
			spinbox.step = settings_property.step
			spinbox.rounded = settings_property.rounded
			spinbox.exp_edit = settings_property.exp_edit
			spinbox.allow_greater = settings_property.allow_greater
			spinbox.allow_lesser = settings_property.allow_lesser
			
			spinbox.value = settings_property.get_value()
			
			slider.visible = display_mode == SettingsProperty.DisplayMode.SLIDER
			
			picker_hbox.add_child(slider)
			picker_hbox.add_child(spinbox)
			
			settings_property.value_changed.connect(spinbox.set_value_no_signal)
			spinbox.value_changed.connect(update_settings_value)
		
		SettingsProperty.DisplayMode.CHECKBOX, SettingsProperty.DisplayMode.CHECKBUTTON:
			var check_button: BaseButton = CheckButton.new() \
					if display_mode == SettingsProperty.DisplayMode.CHECKBUTTON else CheckBox.new()
			check_button.size_flags_horizontal = Control.SIZE_SHRINK_END
			check_button.button_pressed = settings_property.get_value()
			check_button.toggled.connect(update_settings_value)
			settings_property.value_changed.connect(check_button.set_pressed_no_signal)
			picker_hbox.add_child(check_button)
			
		SettingsProperty.DisplayMode.COLORPICKER:
			var color_picker: ColorPickerButton = ColorPickerButton.new()
			
			color_picker.size_flags_horizontal = Control.SIZE_SHRINK_END
			color_picker.custom_minimum_size = picker_min_size
			color_picker.edit_alpha = settings_property.edit_alpha
			# NOTE - Disabling intensity for now
			color_picker.edit_intensity = false 
			color_picker.toggled.connect(_on_color_toggled.bind(color_picker))
			
			color_picker.color = settings_property.get_value()
			
			
			color_picker.color_changed.connect(update_settings_value)
			if not settings_property.value_changed.is_connected(update_color_picker):
				settings_property.value_changed.connect(update_color_picker.bind(color_picker))
			
			picker_hbox.add_child(color_picker)
		
		SettingsProperty.DisplayMode.LINE_EDIT:
			var line_edit: LineEdit = LineEdit.new()
			line_edit.size_flags_horizontal = Control.SIZE_SHRINK_END
			line_edit.ready.connect(prepare_picker_object.bind("line_edit_", line_edit), CONNECT_ONE_SHOT)
			
			line_edit.text_changed.connect(update_settings_value)
			if not settings_property.value_changed.is_connected(update_line_edit):
				settings_property.value_changed.connect(update_line_edit.bind(line_edit as LineEdit))
			
			update_line_edit(settings_property.get_value(), line_edit)
			picker_hbox.add_child(line_edit)
		
		SettingsProperty.DisplayMode.ENUM:
			var option_but: OptionButton = OptionButton.new()
			option_but.size_flags_horizontal = Control.SIZE_SHRINK_END
			var enums: PackedStringArray = settings_property.enum_values.split(",")
			for i: int in enums.size():
				var idx: int = i
				var slice_str: String = enums[i].get_slice(":", 1)
				if slice_str.is_valid_int():
					idx = slice_str.to_int()
					option_but.add_item(enums[i].get_slice(":", 0), idx)
				else:
					option_but.add_item(enums[i])
			
			option_but.selected = option_but.get_item_index(settings_property.get_value())
			option_but.item_selected.connect(_on_option_button_item_selected.bind(option_but))
			if not settings_property.value_changed.is_connected(update_option_button):
				settings_property.value_changed.connect(update_option_button.bind(option_but))
			picker_hbox.add_child(option_but)
	
	for child in picker_hbox.get_children():
		child.custom_minimum_size = picker_min_size
	
	show()

func update_settings_value(val: Variant) -> void:
	settings_property.set_value(val)

func update_color_picker(value: Variant, col_pick: ColorPickerButton) -> void:
	if col_pick.color == value: return
	col_pick.set_block_signals(true)
	col_pick.color = value
	col_pick.set_block_signals(false)

func update_line_edit(value: Variant, line_edit: LineEdit) -> void:
	if line_edit.text == value: return
	line_edit.set_block_signals(true)
	line_edit.text = value
	line_edit.set_block_signals(false)

func update_option_button(value: Variant, but: OptionButton) -> void:
	if but.selected == but.get_item_index(value): return
	but.set_block_signals(true)
	but.selected = but.get_item_index(value)
	but.set_block_signals(false)

func _on_option_button_item_selected(idx: int, but: OptionButton) -> void:
	settings_property.set_value(but.get_item_id(idx))

func _on_color_toggled(toggled_on: bool, col_pick_but: ColorPickerButton) -> void:
	if not toggled_on: return
	prepare_picker_object("color_picker_", col_pick_but.get_picker())
	prepare_picker_object("color_picker_popup_", col_pick_but.get_popup())

const HIDDEN_PROPERTIES: Dictionary[SettingsProperty.DisplayMode, String] = {
	SettingsProperty.DisplayMode.COLORPICKER: "color_picker",
	SettingsProperty.DisplayMode.LINE_EDIT: "line_edit",
}

func prepare_picker_object(prefix: String, node: Node) -> void:
	for property: Dictionary in get_property_list():
		if not prefix in property.name: continue
		node.set(property.name.trim_prefix(prefix), get(property.name))


func _validate_property(property: Dictionary) -> void:
	if not Engine.is_editor_hint(): return
	
	var disp: SettingsProperty.DisplayMode = get_display_mode()
	for key: SettingsProperty.DisplayMode in HIDDEN_PROPERTIES:
		if disp != key and HIDDEN_PROPERTIES[key] in property.name: 
			property.usage &= ~PROPERTY_USAGE_EDITOR

func _set(property: StringName, value: Variant) -> bool:
	if not Engine.is_editor_hint() or not is_node_ready():
		return false
	
	for prefix: String in HIDDEN_PROPERTIES.values():
		if prefix in property:
			update_picker()
	
	return false
