extends GutTest

var canvas_scene: PackedScene = load("res://system/canvas/canvas.tscn")
var canvas: Canvas
var project: Project

var width: int = 100
var height: int = 200


func before_each():
	var rs = RenderingServer
	canvas = canvas_scene.instantiate()
	add_child(canvas)
	add_child(rs)
	project = Project.new()
	project.new_project(width, height)
	canvas.attach_project(project)


# -- Canvas Tests --


func test_canvas_render_page():
	var page = project.get_current_page()
	canvas.render_page(page)
	assert_eq(
		canvas.layers_node.get_child_count(), page.layers.size(), "Canvas should render all layers"
	)


func test_canvas_has_onion_skin_renderer():
	var renderer = canvas.get_node("Control/OnionSkin")
	assert_not_null(renderer, "Canvas should have onion skin renderer node")


func test_canvas_toggle_onion_skin_works():
	var renderer = canvas.onion_skin_renderer

	assert_false(renderer.enabled, "Onion skin should start disabled")

	canvas.toggle_onion_skin()
	assert_true(renderer.enabled, "toggle_onion_skin should enable onion skin")

	canvas.toggle_onion_skin()
	assert_false(renderer.enabled, "toggle_onion_skin should disable onion skin again")


func test_canvas_set_onion_skin_depth_works():
	var renderer = canvas.onion_skin_renderer

	canvas.set_onion_skin_depth(5)
	assert_eq(renderer.depth, 5, "Depth should be set to 5")

	canvas.set_onion_skin_depth(1)
	assert_eq(renderer.depth, 1, "Depth should be set to 1")

	canvas.set_onion_skin_depth(0)
	assert_eq(renderer.depth, 1, "Depth should never be lower than 1")


func test_set_tool_cursor_uses_tool_cursor_texture():
	var brush := Brush.new()
	canvas.set_tool_cursor(brush)

	assert_eq(
		canvas.control_node.mouse_default_cursor_shape,
		Control.CURSOR_CROSS,
		"Canvas should switch to the custom cursor shape when a tool has a cursor texture"
	)


func test_set_tool_cursor_falls_back_to_arrow_without_cursor_texture():
	var tool := Tool.new()
	canvas.set_tool_cursor(tool)

	assert_eq(
		canvas.control_node.mouse_default_cursor_shape,
		Control.CURSOR_ARROW,
		"Canvas should fall back to the arrow cursor when the tool has no cursor texture"
	)

# TODO - Create unit tests and investigate GUT and RenderingServer issues.
# func test_bake():
# 	var rect = ColorRect.new()
# 	canvas.dynamic_node.add_child(rect)

# 	canvas.bake_page()

# 	assert_eq(canvas.dynamic_node.get_child_count(), 0, "Verify bake clearing dynamic")
# 	assert_eq(canvas.bake_node.get_child_count(), 0, "Verify bake clearing viewport")
