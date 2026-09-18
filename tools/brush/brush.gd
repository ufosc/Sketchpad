class_name Brush
extends Tool

@export var title: String = "Brush"
@export var original_stamp: Texture2D = PlaceholderTexture2D.new()

var width: float
var hardness: float
var scaling_filter: Image.Interpolation
var stamp_tex: Texture2D
var _stroke_node: Node2D
var _last_pos: Vector2
var _has_last = false


func _init() -> void:
	cursor = load("res://tools/brush/cursor.png")


func _ready() -> void:
	stamp_tex = generate_stamp()

func on_pointer_down(_position: Vector2, _canvas: Canvas) -> void:
	_stroke_node = Node2D.new()
	_canvas.dynamic_node.add_child(_stroke_node)
	_has_last = true
	_last_pos = _position
	_place_stamp(_last_pos)


func on_pointer_move(_position: Vector2, _canvas: Canvas) -> void:
	if not _stroke_node or not _canvas._project or not _has_last:
		return

	var delta = _last_pos - _position
	var dist = delta.length()
	var dir = delta / dist

	var t = 0.0
	while t <= dist:
		if (dir * t).length() > (width / stamp_tex.get_width() * 10):
			_place_stamp(_last_pos + dir * t)
			_last_pos = _position
		t += (width / stamp_tex.get_width() * 10)


func on_pointer_up(_position: Vector2, _canvas: Canvas) -> void:
	_has_last = false
	_canvas.bake_page()


func generate_stamp() -> Texture2D:
	if original_stamp == null or original_stamp.get_image() == null:
		return

	var size_px = original_stamp.get_height() * max(width * 2, 10)
	var img = original_stamp.get_image()
	var org_img = img
	img.resize(size_px, size_px, scaling_filter)
	var center = Vector2(size_px * 0.5, size_px * 0.5)
	var radius = size_px * 0.5 * sqrt(2)
	var feather = 1.0 - hardness
	var inner = radius * (1 - feather)

	for y in size_px:
		for x in size_px:
			var distance = center.distance_to(Vector2(x + 0.5, y + 0.5))

			var transparency = 0.0
			if distance <= inner:
				transparency = 1.0
			elif distance < radius:
				transparency = pow(1.0 - (distance - inner) / (radius - inner), 3)
			else:
				transparency = 0

			img.set_pixel(
				x, y, Color(org_img.get_pixel(x, y), org_img.get_pixel(x, y).a * transparency)
			)

	img = ImageTexture.create_from_image(img)
	return img


func _place_stamp(_position: Vector2) -> void:
	var s = Sprite2D.new()
	s.texture = stamp_tex
	s.position = _position
	s.modulate = EditorState.color

	var tex_w = float(stamp_tex.get_width())
	var scale_factor = width / tex_w
	s.scale = Vector2.ONE * scale_factor

	_stroke_node.add_child(s)
