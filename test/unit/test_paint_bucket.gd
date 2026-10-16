extends GutTest

var canvas_scene: PackedScene = load("res://system/canvas/canvas.tscn")
var canvas: Canvas
var project: Project
var paint_bucket: PaintBucket
var page: Page
var layer: Image

var width: int = 100
var height: int = 200

var original_color: Color


func before_each():
	canvas = canvas_scene.instantiate()
	add_child_autofree(canvas)

	project = Project.new()
	project.new_project(width, height)
	canvas.attach_project(project)

	page = project.get_current_page()
	layer = page.layers[project.current_layer]

	paint_bucket = PaintBucket.new()
	paint_bucket.tolerance = 0.0

	original_color = EditorState.color
	EditorState.color = Color.RED


func after_each():
	EditorState.color = original_color


# -- Helpers --


## Counts how many pixels of an image match a color.
func _count_pixels(image: Image, color: Color) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y) == color:
				count += 1
	return count


## Fills a vertical column of the layer with a color.
func _draw_column(image: Image, x: int, color: Color) -> void:
	for y in image.get_height():
		image.set_pixel(x, y, color)


# -- Full Fill Test --


func test_fill_blank_layer_fills_every_pixel():
	paint_bucket.on_pointer_down(Vector2(3, 3), canvas)

	assert_eq(_count_pixels(layer, Color.RED), width * height, "Every pixel should be filled")


# -- Contained Region Test --


func test_fill_stays_inside_contained_region():
	var wall_x := 50
	_draw_column(layer, wall_x, Color.BLUE)

	paint_bucket.on_pointer_down(Vector2(1, 1), canvas)

	for y in height:
		for x in width:
			var expected := Color.TRANSPARENT
			if x < wall_x:
				expected = Color.RED
			elif x == wall_x:
				expected = Color.BLUE
			assert_eq(layer.get_pixel(x, y), expected, "Pixel (%d, %d)" % [x, y])

# -- Tolerance Tests --


func test_zero_tolerance_does_not_cross_similar_color():
	layer.fill(Color.BLACK)
	_draw_column(layer, 5, Color(0.0, 0.0, 0.1, 1.0))
	paint_bucket.tolerance = 0.0

	paint_bucket.on_pointer_down(Vector2(0, 0), canvas)

	assert_eq(layer.get_pixel(4, 0), Color.RED, "Identical colors are filled")
	assert_ne(layer.get_pixel(5, 0), Color.RED, "Slightly different color is not filled")
	assert_ne(layer.get_pixel(6, 0), Color.RED, "Region behind the different color is not reached")

# -- Edge Test --


func test_fill_from_every_canvas_edge_does_not_error():
	var positions := [
		# Corners
		Vector2(0, 0),
		Vector2(width - 1, 0),
		Vector2(0, height - 1),
		Vector2(width - 1, height - 1),
		# Edge midpoints
		Vector2(width / 2, 0),
		Vector2(width / 2, height - 1),
		Vector2(0, height / 2),
		Vector2(width - 1, height / 2),
	]

	for position in positions:
		layer.fill(Color.TRANSPARENT)
		paint_bucket.on_pointer_down(position, canvas)
		assert_eq(_count_pixels(layer, Color.RED), width * height, "Fill from %s" % position)
