extends GutTest

var project: Project
var width: int = 200
var height: int = 300


func before_each():
	project = Project.new()
	project.new_project(width, height)


func test_project_creation():
	assert_not_null(project, "Project existence")


func test_current_page():
	var page = project.get_current_page()
	assert_not_null(page, "Page existence")

	var img = page.get_content()
	assert_eq(img[0].get_width(), width, "Width equal")
	assert_eq(img[0].get_height(), height, "Height equal")


func test_distant_page_forward():
	project.next_page(false)
	project.prev_page()
	var page = project.get_distant_page(1)
	assert_not_null(page, "Distant page existance")

	var far_page = project.get_distant_page(2)
	assert_null(far_page)


func test_distant_page_backward():
	project.next_page(false)
	var page = project.get_distant_page(-1)
	assert_not_null(page, "Distant page existance")

	var far_page = project.get_distant_page(-2)
	assert_null(far_page)


func test_get_page_by_index_valid():
	project.new_page()
	watch_signals(project)
	var page = project.get_page_by_index(1)

	assert_not_null(page, "Valid index returns a page")
	assert_eq(page, project.frames[1], "Returned page matches the frame at that index")
	assert_eq(project.current_frame, 1, "Current frame updated to the requested index")
	assert_signal_emitted_with_parameters(project, "new_current_page", [project.frames[1]])


func test_get_page_by_index_negative():
	watch_signals(project)
	var page = project.get_page_by_index(-1)

	assert_null(page, "Negative index returns null")
	assert_eq(project.current_frame, 0, "Current frame unchanged by a negative index")
	assert_signal_not_emitted(project, "new_current_page", "No page change is reported")


func test_get_page_by_index_out_of_bounds():
	watch_signals(project)
	var page = project.get_page_by_index(len(project.frames))

	assert_null(page, "Out of bounds index returns null")
	assert_eq(project.current_frame, 0, "Current frame unchanged by an out of bounds index")
	assert_signal_not_emitted(project, "new_current_page", "No page change is reported")


func test_next_page_creates_frame_when_not_looping():
	var starting_count = len(project.frames)
	var page = project.next_page(false)

	assert_eq(len(project.frames), starting_count + 1, "A frame was appended")
	assert_eq(project.current_frame, 1, "Current frame advanced")
	assert_eq(page, project.frames[1], "Returned page is the new frame")


func test_next_page_loops_to_first_frame():
	var starting_count = len(project.frames)
	var page = project.next_page(true)

	assert_eq(len(project.frames), starting_count, "Looping does not append a frame")
	assert_eq(project.current_frame, 0, "Current frame wrapped to the start")
	assert_eq(page, project.frames[0], "Returned page is the first frame")


func test_next_page_advances_without_creating():
	project.new_page()
	project.new_page()
	watch_signals(project)
	var page = project.next_page(true)

	assert_eq(len(project.frames), 3, "No frame appended while advancing mid timeline")
	assert_eq(project.current_frame, 1, "Current frame advanced by one")
	assert_eq(page, project.frames[1], "Returned page is the next frame")
	assert_signal_emitted_with_parameters(project, "new_current_page", [project.frames[1]])


func test_prev_page_returns_previous_frame():
	project.new_page()
	project.set_frame(1)
	watch_signals(project)
	var page = project.prev_page()

	assert_eq(project.current_frame, 0, "Current frame moved back by one")
	assert_eq(page, project.frames[0], "Returned page is the previous frame")
	assert_signal_emitted_with_parameters(project, "new_current_page", [project.frames[0]])


func test_prev_page_stops_at_first_frame():
	var page = project.prev_page()

	assert_eq(project.current_frame, 0, "Current frame stays at zero")
	assert_eq(page, project.frames[0], "Returned page is still the first frame")


func test_get_thumbnail_returns_placeholder_before_save():
	var texture = project.get_thumbnail()

	assert_not_null(texture, "A texture is returned before the project has been saved")
	assert_true(texture is Texture2D, "Placeholder is a Texture2D")


func test_get_thumbnail_after_save():
	project.on_project_save()
	var texture = project.get_thumbnail()

	assert_not_null(texture, "A texture is returned after saving")
	assert_true(texture is Texture2D, "Thumbnail is a Texture2D")
	assert_eq(texture.get_width(), 128, "Thumbnail width is resized")
	assert_eq(texture.get_height(), 96, "Thumbnail height is resized")


func test_new_page_appends_to_end():
	var starting_count = len(project.frames)
	watch_signals(project)
	project.new_page()
	var added_page = project.frames[starting_count]

	assert_eq(len(project.frames), starting_count + 1, "Frame count increased by one")
	assert_not_null(added_page, "New page sits at the end of the timeline")
	assert_eq(added_page.layers[0].get_width(), width, "New page width matches the project")
	assert_eq(added_page.layers[0].get_height(), height, "New page height matches the project")
	assert_signal_emitted(project, "frames_update", "Adding a page reports a timeline change")


func test_set_frame_updates_current_frame():
	project.new_page()
	watch_signals(project)
	project.set_frame(1)

	assert_eq(project.current_frame, 1, "Current frame set to the requested index")
	assert_signal_emitted_with_parameters(project, "new_current_page", [project.frames[1]])


func test_set_layer_updates_current_layer():
	project.set_layer(0)
	assert_eq(project.current_layer, 0, "Current layer switched to the requested index")

	project.set_layer(1)
	assert_eq(project.current_layer, 1, "Current layer switched back")


func test_delete_frame_removes_requested_frame():
	project.new_page()
	project.new_page()
	var surviving_page = project.frames[2]
	project.delete_frame(1)

	assert_eq(len(project.frames), 2, "Frame count decreased by one")
	assert_eq(project.frames[1], surviving_page, "Later frames shifted down into the gap")


func test_delete_frame_clamps_current_frame():
	project.new_page()
	project.set_frame(1)
	watch_signals(project)
	project.delete_frame(1)

	assert_eq(project.current_frame, 0, "Current frame clamped into the shortened timeline")
	assert_signal_emitted_with_parameters(project, "new_current_page", [project.frames[0]])
