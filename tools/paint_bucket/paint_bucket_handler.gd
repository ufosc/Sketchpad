extends PanelContainer

@export var tolerance_sldr: Slider
@export var tolerance_label: Label
@export var color_picker: ColorPickerButton
@export var tool: PaintBucket

var tolerance: float

@onready var root: Node = get_tree().current_scene


func _ready() -> void:
	color_picker.color_changed.connect(_on_color_changed)
	tolerance_sldr.value_changed.connect(_on_tolerance_changed)
	EditorState.color_changed.connect(_on_editor_color_changed)

	tolerance_sldr.value = tool.tolerance
	color_picker.color = EditorState.color


func _on_tolerance_changed(value: float) -> void:
	tolerance = value
	tolerance_label.text = "%d%%" % (value * 100)
	tool.tolerance = tolerance


func _on_color_changed(color: Color) -> void:
	EditorState.color = color


func _on_editor_color_changed(value: Color) -> void:
	color_picker.color = value
