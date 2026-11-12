extends GutTest

const OnionSkinRenderer = preload("res://system/canvas/onion_skin.gd")

var onion_skin: OnionSkinRenderer
var project: Project

var width: int = 100
var height: int = 200


func before_each():
	onion_skin = OnionSkinRenderer.new()
	add_child(onion_skin)
	project = Project.new()
	project.new_project(width, height)
	onion_skin.attach_project(project)


func after_each():
	for child in onion_skin.get_children():
		onion_skin.remove_child(child)
		child.free()
	onion_skin.free()


# -- Onion Skin Tests --


func test_onion_skin_default_disabled():
	assert_false(onion_skin.enabled, "Onion skin should be disabled by default")


func test_onion_skin_toggle():
	onion_skin.toggle()
	assert_true(onion_skin.enabled, "Onion skin should be enabled after toggle")
	onion_skin.toggle()
	assert_false(onion_skin.enabled, "Onion skin should be disabled after second toggle")


func test_onion_skin_default_depth():
	assert_eq(onion_skin.depth, 1, "Default onion skin depth should be 1")


func test_onion_skin_set_depth():
	onion_skin.set_depth(3)
	assert_eq(onion_skin.depth, 3, "Onion skin depth should update to 3")


func test_onion_skin_depth_minimum():
	onion_skin.set_depth(0)
	assert_eq(onion_skin.depth, 1, "Onion skin depth should not go below 1")

	onion_skin.set_depth(-5)
	assert_eq(onion_skin.depth, 1, "Negative depth should clamp to 1")


func test_onion_skin_no_ghosts_on_first_frame():
	onion_skin.toggle()
	onion_skin.render()
	assert_eq(onion_skin.get_child_count(), 0, "No ghost frames on first frame (no previous page)")


func test_onion_skin_ghost_on_second_frame():
	project.next_page(false)
	onion_skin.toggle()
	onion_skin.render()
	assert_gt(onion_skin.get_child_count(), 0, "Ghost frame should appear on second frame")


func test_onion_skin_ghost_opacity():
	project.next_page(false)
	onion_skin.toggle()
	onion_skin.render()
	var first_ghost = onion_skin.get_child(0) as Sprite2D
	assert_almost_eq(
		first_ghost.modulate.a,
		OnionSkinRenderer.BASE_OPACITY,
		0.01,
		"Ghost opacity should match base opacity"
	)


func test_onion_skin_disabled_clears_ghosts():
	project.next_page(false)
	onion_skin.toggle()
	onion_skin.render()
	assert_gt(onion_skin.get_child_count(), 0, "Ghosts should exist when enabled")
	onion_skin.toggle()
	assert_eq(onion_skin.get_child_count(), 0, "Ghosts should be cleared when disabled")


func test_onion_skin_multiple_depth():
	project.next_page(false)
	project.next_page(false)
	onion_skin.set_depth(2)
	onion_skin.toggle()
	onion_skin.render()

	# Page has 2 layers (background + foreground), so 2 frames * 2 layers = 4 sprites
	var page_layers = project.get_current_page().layers.size()
	assert_eq(
		onion_skin.get_child_count(), 2 * page_layers, "Should show ghosts for 2 previous frames"
	)


func test_onion_skin_depth_exceeds_available():
	project.next_page(false)
	onion_skin.set_depth(5)
	onion_skin.toggle()
	onion_skin.render()

	# Only 1 previous frame exists, so only that one should render
	var page_layers = project.get_current_page().layers.size()
	assert_eq(
		onion_skin.get_child_count(),
		1 * page_layers,
		"Should only show ghosts for available frames"
	)
