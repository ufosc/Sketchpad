class_name Eraser
extends Tool

@export var title: String = "Eraser"
@export var original_stamp: Texture2D = PlaceholderTexture2D.new()
var width: float
var hardness: float
var scaling_filter: Image.Interpolation
var filter: Texture2D

var _last_pos: Vector2
var _has_last = false


func _init() -> void:
	cursor = load("res://tools/eraser/cursor.png")


func _ready() -> void:
	filter = generate_filter()


func on_pointer_down(_position: Vector2, _canvas: Canvas) -> void:
	_has_last = true
	_last_pos = _position
	_place_stamp(_last_pos, _canvas)


func on_pointer_move(_position: Vector2, _canvas: Canvas) -> void:
	if filter == null or not _canvas._project or not _has_last:
		return

	var delta = _last_pos - _position
	var dist = delta.length()
	var dir = delta / dist

	var t = 0.0
	while t <= dist:
		if (dir * t).length() > (width / filter.get_width() * 10):
			_place_stamp(_last_pos + dir * t, _canvas)
			_last_pos = _position
		t += (width / filter.get_width() * 10)


func on_pointer_up(_position: Vector2, _canvas: Canvas) -> void:
	_has_last = false


func generate_filter() -> Texture2D:
	if original_stamp == null or original_stamp.get_image() == null:
		return

	var size_px = original_stamp.get_height() * max(width * 2, 10)
	var img = original_stamp.get_image()
	img.resize(size_px, size_px)
	var center = Vector2(size_px * 0.5, size_px * 0.5)
	var radius = size_px * 0.5 * sqrt(2)
	var feather = 1.0 - hardness
	var inner = radius * (1 - feather)

	for y in size_px:
		for x in size_px:
			var distance = center.distance_to(Vector2(x + 0.5, y + 0.5))

			var falloff = 0.0
			if distance <= inner:
				falloff = 1.0
			elif distance < radius:
				falloff = pow(1.0 - (distance - inner) / (radius - inner), 3)
			else:
				falloff = 0

			var src = img.get_pixel(x, y)
			var final_alpha = src.a * falloff
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, final_alpha))

	img = ImageTexture.create_from_image(img)
	return img


func _place_stamp(_position: Vector2, _canvas: Canvas) -> void:
	var tex_w = float(filter.get_width())
	var scale_factor = width / tex_w
	var img = filter.get_image()
	img.resize(
		filter.get_width() * scale_factor,
		filter.get_height() * scale_factor,
		Image.INTERPOLATE_LANCZOS
	)

	var project: Project = _canvas._project
	var current_page: Page = project.frames[project.current_frame]
	var layer: Image = current_page.layers[project.current_layer]

	var filter_width = img.get_width()
	var filter_height = img.get_height()
	var image_width = layer.get_width()
	var image_height = layer.get_height()

	var start_x = int(_position.x - filter_width / 2.0)
	var start_y = int(_position.y - filter_height / 2.0)

	for index_y in range(filter_height):
		var pixel_y = start_y + index_y
		if pixel_y < 0 or pixel_y >= image_height:
			continue

		for index_x in range(filter_width):
			var pixel_x = start_x + index_x
			if pixel_x < 0 or pixel_x >= image_width:
				continue

			var base = layer.get_pixel(pixel_x, pixel_y)
			var filt = img.get_pixel(index_x, index_y)

			# Add the sprite alpha into the image alpha.
			var new_alpha = max(base.a - filt.a, 0.0)

			# Keep RGB the same, only change alpha.
			base.a = new_alpha
			layer.set_pixel(pixel_x, pixel_y, base)

	current_page.set_layer(project.current_layer, layer)
