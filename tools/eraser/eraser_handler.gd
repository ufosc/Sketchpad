extends PanelContainer

@export var thick_sldr: Slider
@export var thick_label: Label
@export var hard_sldr: Slider
@export var hard_label: Label
@export var eraser_list: ItemList
@export var button_group: ButtonGroup
@export var tool_manager: ToolManager
@export var tool: Eraser
@export var default_eraser_width = 2.5
@export var default_eraser_hardness = 1.0

var erasers = [
	load("res://tools/eraser/big_circle/big_circle.tres"),
	load("res://tools/eraser/big_semi_square/big_semi_square.tres"),
	load("res://tools/eraser/big_square/big_square.tres")
]

var scale_filter = Image.INTERPOLATE_NEAREST
var editor: Editor


func _ready() -> void:
	editor = tool_manager.editor
	eraser_list.item_selected.connect(_on_eraser_selected)
	thick_sldr.value_changed.connect(_on_thickness_changed)
	hard_sldr.value_changed.connect(_on_hardness_changed)

	thick_sldr.value = default_eraser_width
	hard_sldr.value = default_eraser_hardness

	for button in button_group.get_buttons():
		button.pressed.connect(_on_filter_selected)
		if button.name == "Nearest":
			button.button_pressed = true

	eraser_list.select(0)
	_on_eraser_selected(0)


func _on_thickness_changed(value: float) -> void:
	thick_label.text = "%dpx" % value
	tool.width = value


func _on_hardness_changed(value: float) -> void:
	hard_label.text = "%d%%" % (value * 100)
	tool.hardness = value
	tool.filter = tool.generate_filter()


func _on_eraser_selected(index: int) -> void:
	erasers[index].hardness = tool.hardness
	erasers[index].width = tool.width
	tool = erasers[index]
	tool.filter = tool.generate_filter()
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
