extends GutTest

const CANVAS_SCENE: PackedScene = preload("res://system/canvas/canvas.tscn")
const WIDTH: int = 4
const HEIGHT: int = 3
const SOURCE_COLOR: Color = Color.RED
const FILL_COLOR: Color = Color.BLUE
const NEAR_COLOR: Color = Color(0.8, 0.0, 0.0)

var canvas: Canvas
var project: Project
var paint_bucket: PaintBucket
var original_editor_color: Color

func before_each():
	original_editor_color = EditorState.color
	canvas = CANVAS_SCENE.instantiate()
	add_child(canvas)
	project = Project.new()
	project.new_project(WIDTH, HEIGHT)
	canvas.attach_project(project)
	paint_bucket = PaintBucket.new()

func after_each():
	EditorState.color = original_editor_color
	canvas.free()

func test_fills_uniform_layer():
	var page = project.get_current_page()
	page.layers[project.current_layer].fill(SOURCE_COLOR)
	EditorState.color = FILL_COLOR
	paint_bucket.tolerance = 0.0
	paint_bucket.on_pointer_down(Vector2(WIDTH / 2, HEIGHT / 2), canvas)
	var result: Image = page.layers[project.current_layer]
	for y in range(HEIGHT):
		for x in range(WIDTH):
			assert_eq(
				result.get_pixel(x, y),
				FILL_COLOR,
				"Pixel (%d, %d) should be filled" % [x, y]
			)

func test_fills_contained_region():
	var page = project.get_current_page()
	var layer: Image = page.layers[project.current_layer]
	layer.fill(Color.WHITE)
	layer.set_pixel(1, 1, SOURCE_COLOR)
	layer.set_pixel(2, 1, SOURCE_COLOR)
	EditorState.color = FILL_COLOR
	paint_bucket.tolerance = 0.0
	paint_bucket.on_pointer_down(Vector2(1, 1), canvas)
	var result: Image = page.layers[project.current_layer]
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var expected_color = Color.WHITE
			if (x == 1 and y == 1) or (x == 2 and y == 1):
				expected_color = FILL_COLOR
			assert_eq(
				result.get_pixel(x, y),
				expected_color,
				"Unexpected color at (%d, %d)" % [x, y]
			)

func test_tolerance_excludes_neighbor_outside_threshold():
	var page = project.get_current_page()
	var layer: Image = page.layers[project.current_layer]
	layer.fill(Color.WHITE)
	layer.set_pixel(1, 1, SOURCE_COLOR)
	layer.set_pixel(2, 1, NEAR_COLOR)
	var neighbor_color = layer.get_pixel(2, 1)
	EditorState.color = FILL_COLOR
	paint_bucket.tolerance = 0.05
	paint_bucket.on_pointer_down(Vector2(1, 1), canvas)
	var result: Image = page.layers[project.current_layer]
	assert_eq(result.get_pixel(1, 1), FILL_COLOR, "Seed pixel should be filled")
	assert_eq(
		result.get_pixel(2, 1),
		neighbor_color,
		"Neighbor beyond the tolerance threshold should remain unchanged"
	)
	assert_eq(result.get_pixel(3, 1), Color.WHITE, "Surrounding pixels should remain unchanged")


func test_tolerance_includes_neighbor_inside_threshold():
	var page = project.get_current_page()
	var layer: Image = page.layers[project.current_layer]
	layer.fill(Color.WHITE)
	layer.set_pixel(1, 1, SOURCE_COLOR)
	layer.set_pixel(2, 1, NEAR_COLOR)
	EditorState.color = FILL_COLOR
	paint_bucket.tolerance = 0.2
	paint_bucket.on_pointer_down(Vector2(1, 1), canvas)
	var result: Image = page.layers[project.current_layer]
	assert_eq(result.get_pixel(1, 1), FILL_COLOR, "Seed pixel should be filled")
	assert_eq(result.get_pixel(2, 1), FILL_COLOR, "Neighbor within tolerance should be filled")
	assert_eq(result.get_pixel(3, 1), Color.WHITE, "Surrounding pixels should remain unchanged")

func test_fills_region_touching_canvas_edge():
	var page = project.get_current_page()
	var layer: Image = page.layers[project.current_layer]
	layer.fill(Color.WHITE)
	layer.set_pixel(0, 0, SOURCE_COLOR)
	layer.set_pixel(1, 0, SOURCE_COLOR)
	EditorState.color = FILL_COLOR
	paint_bucket.tolerance = 0.0
	paint_bucket.on_pointer_down(Vector2(0, 0), canvas)
	var result: Image = page.layers[project.current_layer]
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var expected_color = Color.WHITE
			if (x == 0 and y == 0) or (x == 1 and y == 0):
				expected_color = FILL_COLOR
			assert_eq(
				result.get_pixel(x, y),
				expected_color,
				"Unexpected color at (%d, %d)" % [x, y]
			)

func test_fill_updates_page_and_active_layer():
	var page = project.get_current_page()
	var layer: Image = page.layers[project.current_layer]
	layer.fill(Color.WHITE)
	layer.set_pixel(1, 1, SOURCE_COLOR)
	watch_signals(page)
	EditorState.color = FILL_COLOR
	paint_bucket.tolerance = 0.0
	paint_bucket.on_pointer_down(Vector2(1, 1), canvas)
	assert_signal_emitted(page, "page_update", "Filling should update the page")
	assert_eq(
		page.layers[project.current_layer].get_pixel(1, 1),
		FILL_COLOR,
		"Active layer should contain the filled pixel"
	)