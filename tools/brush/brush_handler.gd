extends PanelContainer

@export var thick_sldr: Slider
@export var thick_label: Label
@export var hard_sldr: Slider
@export var hard_label: Label
@export var color_picker: ColorPickerButton
@export var brush_list: ItemList
@export var button_group: ButtonGroup
@export var tool: Brush
@export var default_brush_width: int = 3
@export var default_brush_hardness = 1.0

var tool_manager: ToolManager

var brushes = [
	load("res://assets/brush_templates/big_circle.png"),
	load("res://assets/brush_templates/big_semi_square.png"),
	load("res://assets/brush_templates/big_square.png")
]

var scale_filter = Image.INTERPOLATE_NEAREST
var editor: Editor


func _ready() -> void:
	if brush_list:
		brush_list.item_selected.connect(_on_brush_selected)
	if thick_sldr:
		thick_sldr.value_changed.connect(_on_thickness_changed)
	if hard_sldr:
		hard_sldr.value_changed.connect(_on_hardness_changed)
	if color_picker:
		color_picker.color_changed.connect(_on_color_changed)
	EditorState.color_changed.connect(_on_editor_color_changed)

	if button_group:
		for button in button_group.get_buttons():
			button.pressed.connect(_on_filter_selected)
			if button.name == "Nearest":
				button.button_pressed = true

	if tool_manager and brush_list:
		brush_list.select(0)
		_on_brush_selected(0)
	thick_sldr.value = tool.width if tool else default_brush_width
	hard_sldr.value = tool.hardness if tool else default_brush_hardness
	color_picker.color = EditorState.color


func assign_tool(new_tool: Tool) -> void:
	if tool_manager:
		editor = tool_manager.editor
	self.tool = new_tool
	thick_sldr.value = new_tool.width
	hard_sldr.value = new_tool.hardness
	color_picker.color = EditorState.color


func _on_thickness_changed(value: float) -> void:
	var size := int(round(value))
	thick_label.text = "%dpx" % size
	tool.width = size
	tool.emit_signal("settings_changed")


func _on_hardness_changed(value: float) -> void:
	hard_label.text = "%d%%" % (value * 100)
	tool.hardness = value
	tool.stamp_tex = tool.generate_stamp()
	tool.emit_signal("settings_changed")


func _on_color_changed(color: Color) -> void:
	EditorState.color = color
	tool.emit_signal("settings_changed")


func _on_editor_color_changed(value: Color) -> void:
	color_picker.color = value


func _on_brush_selected(index: int) -> void:
	tool.original_stamp = brushes[index]
	tool.stamp_tex = tool.generate_stamp()
	tool.emit_signal("settings_changed")


func _on_tool_settings_changed() -> void:
	if hard_sldr:
		hard_sldr.value = tool.hardness
	if thick_sldr:
		thick_sldr.value = tool.width
	if color_picker:
		color_picker.color = EditorState.color


func _on_filter_selected() -> void:
	var button = button_group.get_pressed_button()

	match button.name:
		"Nearest":
			scale_filter = Image.INTERPOLATE_NEAREST
		"Bilinear":
			scale_filter = Image.INTERPOLATE_BILINEAR
		"Cubic":
			scale_filter = Image.INTERPOLATE_CUBIC
		"Trilinear":
			scale_filter = Image.INTERPOLATE_TRILINEAR

	tool.scaling_filter = scale_filter
