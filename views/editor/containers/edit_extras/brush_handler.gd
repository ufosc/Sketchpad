extends PanelContainer

@export var thick_sldr: Slider
@export var thick_label: Label
@export var hard_sldr: Slider
@export var hard_label: Label
@export var color_picker: ColorPickerButton
@export var brush_list: ItemList
@export var button_group: ButtonGroup
@export var tool_manager: ToolManager
@export var tool: Brush
@export var default_brush_width = 2.5
@export var default_brush_hardness = 1.0

var brushes = [
	load("res://tools/brush/big_circle/big_circle.tres"),
	load("res://tools/brush/big_semi_square/big_semi_square.tres"),
	load("res://tools/brush/big_square/big_square.tres")
]

var scale_filter = Image.INTERPOLATE_NEAREST
var editor: Editor


func _ready() -> void:
	editor = tool_manager.editor
	brush_list.item_selected.connect(_on_brush_selected)
	thick_sldr.value_changed.connect(_on_thickness_changed)
	hard_sldr.value_changed.connect(_on_hardness_changed)
	color_picker.color_changed.connect(_on_color_changed)
	EditorState.color_changed.connect(_on_editor_color_changed)

	for button in button_group.get_buttons():
		button.pressed.connect(_on_filter_selected)
		if button.name == "Nearest":
			button.button_pressed = true

	brush_list.select(0)
	_on_brush_selected(0)
	thick_sldr.value = default_brush_width
	hard_sldr.value = default_brush_hardness
	color_picker.color = EditorState.color


func _on_thickness_changed(value: float) -> void:
	thick_label.text = "%dpx" % value
	tool.width = value


func _on_hardness_changed(value: float) -> void:
	hard_label.text = "%d%%" % (value * 100)
	tool.hardness = value
	tool.stamp_tex = tool.generate_stamp()


func _on_color_changed(color: Color) -> void:
	EditorState.color = color


func _on_editor_color_changed(value: Color) -> void:
	color_picker.color = value


func _on_brush_selected(index: int) -> void:
	brushes[index].hardness = tool.hardness
	brushes[index].width = tool.width
	tool = brushes[index]
	tool.stamp_tex = tool.generate_stamp()
	editor.current_tool = tool


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
