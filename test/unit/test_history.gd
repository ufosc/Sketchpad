extends GutTest

var width: int = 100
var height: int = 200
var project: Project
var history: History


func before_each():
	project = Project.new()
	project.new_project(width, height)
	history = History.new()


func _draw_pixel(color: Color) -> void:
	var page = project.get_current_page()
	var layer = page.layers[project.current_layer]
	layer.set_pixel(0, 0, color)
	page.set_layer(project.current_layer, layer)


func _get_pixel() -> Color:
	return project.get_current_page().layers[project.current_layer].get_pixel(0, 0)


func test_undo_restores_previous_state():
	history.save_state(project)
	_draw_pixel(Color.RED)
	assert_true(history.undo(project), "Undo should succeed")
	assert_eq(_get_pixel(), Color.TRANSPARENT, "Pixel should be reverted")


func test_undo_empty_history():
	assert_false(history.undo(project), "Undo should fail with no saved states")


func test_keeps_max_states():
	for i in range(History.MAX_STATES + 5):
		history.save_state(project)
		_draw_pixel(Color(i / 255.0, 0, 0))

	var undo_count = 0
	while history.undo(project):
		undo_count += 1
	assert_eq(undo_count, History.MAX_STATES, "Only the last 20 states should be kept")


func test_undo_skips_unchanged_states():
	history.save_state(project)
	_draw_pixel(Color.RED)
	history.save_state(project)
	assert_true(history.undo(project), "Undo should succeed")
	assert_eq(_get_pixel(), Color.TRANSPARENT, "Undo should skip states with no changes")


func test_undo_switches_to_edited_frame():
	history.save_state(project)
	_draw_pixel(Color.RED)
	project.next_page(false)
	history.undo(project)
	assert_eq(project.current_frame, 0, "Undo should go back to the edited frame")


func test_undo_ignores_deleted_frames():
	project.next_page(false)
	history.save_state(project)
	_draw_pixel(Color.RED)
	project.delete_frame(1)
	assert_false(history.undo(project), "Undo should ignore states from deleted frames")


func test_undo_ignores_changed_layer_layout():
	history.save_state(project)
	_draw_pixel(Color.RED)
	project.get_current_page().create_layer(width, height, Color.TRANSPARENT, 0)
	assert_false(history.undo(project), "Undo should ignore states after layers change")
