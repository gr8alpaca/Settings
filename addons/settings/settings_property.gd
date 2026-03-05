@tool
class_name SettingsProperty extends Resource

signal value_changed(new_val: Variant)
signal display_mode_changed

enum DisplayMode{
	HIDDEN,
	SPINBOX,
	SLIDER,
	CHECKBOX,
	CHECKBUTTON,
	COLORPICKER,
	LINE_EDIT,
	ENUM,
}

@export_placeholder("master_volume") 
var name: String: set = set_property_name

## Section name in Config file.
@export var section: String = ""

## The [constant Variant.Type] of [member value].
@export_enum("bool:1", "int:2", "float:3", "String:4", "Color:20") var type: int = TYPE_FLOAT: set = set_value_type

## Value of settings property.
@export var value: Variant: get = get_value, set = set_value

## How this property should be shown by [class SettingsPicker]
@export var display_mode: DisplayMode = DisplayMode.HIDDEN: set = set_display_mode, get = get_display_mode

@export_group("Property Details")

@export_storage var min_value: float = 0.0:
	set(val):
		min_value = val
		notify_property_list_changed()
@export_storage var max_value: float = 1.0:
	set(val):
		max_value = val
		notify_property_list_changed()
@export_storage var step: float = 1.0:
	set(val):
		step = val
		notify_property_list_changed()
@export_storage var rounded: bool = false:
	set(val):
		rounded = val
		notify_property_list_changed()
@export_storage var exp_edit: bool = false:
	set(val):
		exp_edit = val
		notify_property_list_changed()
@export_storage var allow_greater: bool = false:
	set(val):
		allow_greater = val
		notify_property_list_changed()
@export_storage var allow_lesser: bool = false:
	set(val):
		allow_lesser = val
		notify_property_list_changed()

@export_storage var enum_values: String

@export_storage var edit_alpha: bool = false:
	set(val):
		edit_alpha = val
		notify_property_list_changed()

#TODO String settings

## Refreshes value option button to reflect those found in [member enum_values].
@export_tool_button("Update Enum Values")
var update_enum_func: Callable = notify_property_list_changed

@export_group("Update Callables")

# ALERT This may be revised as using expressions is not as performant.
## Expression string to be executed when [member set_value] is called. 
## Use [code]value[/code] to reflect the updated value.
## [br][br][b]Note:[/b] Autoloads must be referenced using [method Engine.get_singleton].
@export_custom(PROPERTY_HINT_EXPRESSION, "")
var update_expression_text: String = "":
	set(val):
		update_expression_text = val
		if Engine.is_editor_hint(): return
		var err:= expression.parse(update_expression_text, ["Engine", "value"])
		expression_valid = err == OK
		if not expression_valid:
			push_error("Parse error for SettingsProperty '%s' => %s." % [get_display_name(), update_expression_text])
		update()

## Expression to be called by [method update]
var expression: Expression = Expression.new()

## Internally used to determine if expression is valid. 
## This allows us to only parse [member update_expression_text] once.
var expression_valid: bool = false

## Sets value and emits changed signal.
func set_value(val: Variant) -> void:
	if is_same_type(val):
		value = val
	update()
	value_changed.emit(val)

## Sets value without emitting [member value_changed] signal or updating.
func set_value_no_signal(val: Variant) -> void:
	set_block_signals(true)
	set_value(val)
	set_block_signals(false)

## Returns [member value] converted to [member type].
func get_value() -> Variant:
	return type_convert(value, type)

## Calls expression text if a valid one is defined.
func update() -> void:
	if Engine.is_editor_hint() or not expression_valid: return
	expression.execute([Engine, value], self)

## Compares [param val] with [member value] to see if the types are the same. floats/ints are considered equivalent.
func is_same_type(val: Variant) -> bool:
	var val_type: int = typeof(val)
	return (TYPE_FLOAT if type == TYPE_INT else type) == (TYPE_FLOAT if val_type == TYPE_INT else val_type)

## Reads property from [param cfg].
func read_file(cfg: ConfigFile) -> void:
	set_value(cfg.get_value(section, name, get_value()))

## Writes property to [param cfg].
func write_file(cfg: ConfigFile) -> void:
	cfg.set_value(section, name, get_value())

## Rejects [param prop_name] if spaces are included.
func set_property_name(prop_name: String) -> void:
	if prop_name.contains(" "):
		push_warning("Name cannot contain spaces.")
		return
	name = prop_name
	emit_changed()

## Returns human formatted version of [member name].
func get_display_name() -> String:
	return name.capitalize()

## Returns human formatted version of [member section].
func get_display_section() -> String:
	return section.capitalize()

func set_value_type(val: int) -> void:
		type = val
		display_mode_changed.emit()
		notify_property_list_changed()

func set_display_mode(val: DisplayMode) -> void:
	display_mode = val
	display_mode_changed.emit()
	notify_property_list_changed()

func get_display_mode() -> DisplayMode:
	return display_mode if is_display_mode_valid(display_mode) else DisplayMode.HIDDEN

func is_display_mode_valid(disp_mode: DisplayMode) -> bool:
	if disp_mode == DisplayMode.HIDDEN:
		return true
	match type:
		TYPE_INT:
			return disp_mode == DisplayMode.SPINBOX or disp_mode == DisplayMode.SLIDER or disp_mode == DisplayMode.ENUM
		TYPE_FLOAT:
			return disp_mode == DisplayMode.SPINBOX or disp_mode == DisplayMode.SLIDER 
		TYPE_BOOL:
			return disp_mode == DisplayMode.CHECKBOX or disp_mode == DisplayMode.CHECKBUTTON
		TYPE_COLOR:
			return disp_mode == DisplayMode.COLORPICKER
		TYPE_STRING:
			return disp_mode == DisplayMode.LINE_EDIT
	return false

func _validate_property(property: Dictionary) -> void:
	if not Engine.is_editor_hint(): return
	
	if property.name == &"value":
		property.type = type
		
		match type:
			TYPE_INT, TYPE_FLOAT:
				if get_display_mode() == DisplayMode.ENUM:
					property.hint = PROPERTY_HINT_ENUM
					property.hint_string = enum_values
				else:
					property.hint = PROPERTY_HINT_RANGE
					property.hint_string = "%s,%s,%s,%s%s%s" % [min_value, max_value, step,
					"exp," if exp_edit else "",
					"allow_greater," if allow_greater else "",
					"allow_lesser," if allow_lesser else "",
					]
			
			TYPE_COLOR when not edit_alpha:
				property.hint = PROPERTY_HINT_COLOR_NO_ALPHA
	
	elif property.name == &"display_mode":
		property.hint_string = "Hidden:0"
		match type:
			TYPE_FLOAT:
				property.hint_string += ",Spinbox:1,Slider:2"
			TYPE_INT:
				property.hint_string += ",Spinbox:1,Slider:2,Enum:7"
			TYPE_BOOL:
				property.hint_string += ",Checkbox:3,Checkbutton:4"
			TYPE_COLOR:
				property.hint_string += ",Colorpicker:5"
			TYPE_STRING:
				property.hint_string += ",Line Edit:6"
	
	
	elif property.name == &"Property Details" and (type != TYPE_INT and type != TYPE_FLOAT):
		property.usage = PROPERTY_USAGE_NONE
	
	elif property.name == &"enum_values" and get_display_mode() == DisplayMode.ENUM:
		property.usage |= PROPERTY_USAGE_EDITOR
	
	elif property.name == &"update_enum_func" and get_display_mode() != DisplayMode.ENUM:
		property.usage = PROPERTY_USAGE_NONE
	
	elif property.name in [&"min_value", &"max_value",  &"step", &"exp_edit", &"allow_greater", &"allow_lesser", &"rounded"]:
		if (type == TYPE_INT or type == TYPE_FLOAT) and get_display_mode() != DisplayMode.ENUM:
			property.usage |= PROPERTY_USAGE_EDITOR
	
	elif property.name == &"edit_alpha" and type == TYPE_COLOR:
		property.usage |= PROPERTY_USAGE_EDITOR
