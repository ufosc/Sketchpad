class_name LineTool
extends Tool

@export var width: float = 2.5

var _line: Line2D
var _drawing := false

func on_pointer_down(position: Vector2, canvas: Canvas) -> void:
	if not canvas._project:
		return

	_drawing = true

	_line = Line2D.new()
	_line.width = width
	_line.default_color = EditorState.color

	_line.add_point(position)
	_line.add_point(position)

	canvas.dynamic_node.add_child(_line)


func on_pointer_move(position: Vector2, _canvas: Canvas) -> void:
	if not _drawing or not _line:
		return
	
	_line.set_point_position(1, position)


func on_pointer_up(position: Vector2, canvas: Canvas) -> void:
	if not _drawing or not _line:
		return

	_line.set_point_position(1, position)
	_drawing = false

	await canvas.bake_page()
	_line = null
