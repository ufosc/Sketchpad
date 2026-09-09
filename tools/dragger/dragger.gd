class_name Dragger
extends Tool

@export var title: String = "Dragger"

var dragging := false
var _start_mouse := Vector2.ZERO
var _drag_sprite: Sprite2D = null
var _layer_image: Image = null

func _init() -> void:
	name = "Dragger"

func on_pointer_down(_position: Vector2, _canvas: Canvas) -> void:
	if not _canvas or not _canvas._project:
		return

	var project: Project = _canvas._project
	var page: Page = project.frames[project.current_frame]
	var layer: Image = page.layers[project.current_layer]

	dragging = true
	_start_mouse = _position
	_layer_image = layer.duplicate()

	# Remove the original so the dragged copy is not duplicated.
	layer.fill(Color(0, 0, 0, 0))
	page.set_layer(project.current_layer, layer)

	if _drag_sprite:
		_drag_sprite.queue_free()

	_drag_sprite = Sprite2D.new()
	_drag_sprite.texture = ImageTexture.create_from_image(_layer_image)
	_drag_sprite.centered = false
	_drag_sprite.position = Vector2.ZERO
	_drag_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.dynamic_node.add_child(_drag_sprite)

func on_pointer_move(_position: Vector2, _canvas: Canvas) -> void:
	if not dragging or not _drag_sprite:
		return

	_drag_sprite.position = _position - _start_mouse

func on_pointer_up(position: Vector2, canvas: Canvas) -> void:
	if not dragging:
		return

	dragging = false

	if _drag_sprite:
		_drag_sprite.queue_free()
		_drag_sprite = null

	if _layer_image and canvas and canvas._project:
		var project: Project = canvas._project
		var page: Page = project.frames[project.current_frame]
		var layer = page.layers[project.current_layer]
		var offset = position - _start_mouse
		var moved = Image.create_empty(layer.get_width(), layer.get_height(), false, Image.FORMAT_RGBA8)
		moved.blend_rect(_layer_image, Rect2(Vector2.ZERO, _layer_image.get_size()), offset)
		page.set_layer(project.current_layer, moved)
		_layer_image = null
