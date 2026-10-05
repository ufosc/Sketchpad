extends GutTest

var editor: Editor
var project: Project
var canvas: Canvas


func before_each():
	project = Project.new()
	project.new_project(8, 8)
	canvas = load("res://system/canvas/canvas.tscn").instantiate()
	add_child_autofree(canvas)
	canvas.attach_project(project)
	canvas.render_page(project.get_current_page())
	editor = Editor.new()
	editor.project = project
	editor.canvas = canvas
	editor.page_controls = PageControls.new()
	editor.add_child(editor.page_controls)
	editor.playback_manager = PlaybackManager.new()
	editor.add_child(editor.playback_manager)
	editor.edit_extras = EditExtras.new()
	editor.add_child(editor.edit_extras)
	add_child_autofree(editor)
	EditorState.color = Color.BLACK


func after_each():
	await wait_process_frames(2)


func test_shortcuts_restore_canvas_and_leave_text_fields_alone():
	assert_false(editor.undo())
	editor.current_tool = PaintBucket.new()
	for command in [false, true]:
		_stroke()
		var key := InputEventKey.new()
		key.keycode = KEY_Z
		key.pressed = true
		key.meta_pressed = command
		key.ctrl_pressed = not command
		get_viewport().push_input(key)
		assert_eq(project.frames[0].layers[1].get_pixel(0, 0), Color.TRANSPARENT)
		assert_eq(project.frames[0].textures[1].get_image().get_pixel(0, 0), Color.TRANSPARENT)
	_stroke()
	var field := LineEdit.new()
	add_child_autofree(field)
	field.grab_focus()
	var text_key := InputEventKey.new()
	text_key.keycode = KEY_Z
	text_key.pressed = true
	text_key.meta_pressed = true
	editor._unhandled_key_input(text_key)
	assert_eq(project.frames[0].layers[1].get_pixel(0, 0), Color.BLACK)
	assert_true(editor.undo())
	assert_false(editor.undo())


func test_history_keeps_twenty_independent_states():
	editor.current_tool = PaintBucket.new()
	for index in range(25):
		EditorState.color = Color.from_rgba8(index + 1, 0, 0)
		_stroke()
	for index in range(20):
		assert_true(editor.undo())
	assert_false(editor.undo())
	assert_eq(project.frames[0].layers[1].get_pixel(0, 0), Color.from_rgba8(5, 0, 0))


func test_eraser_and_drag_each_take_one_step():
	var page := project.get_current_page()
	page.layers[1].fill(Color.BLACK)
	page.set_layer(1, page.layers[1])
	var original := page.layers[1].get_data()
	var eraser := Eraser.new()
	eraser.width = 2
	eraser.filter = _stamp()
	editor.current_tool = eraser
	_stroke()
	assert_ne(page.layers[1].get_data(), original)
	assert_true(editor.undo())
	assert_eq(page.layers[1].get_data(), original)
	assert_false(editor.undo())
	editor.current_tool = Dragger.new()
	_press()
	editor._finish_stroke(Vector2(2, 0))
	await wait_process_frames(1)
	assert_eq(page.layers[1].get_pixel(0, 0).a, 0.0)
	assert_true(editor.undo())
	assert_eq(page.layers[1].get_data(), original)
	assert_false(editor.undo())


func test_history_does_not_restore_into_another_project_or_layer_layout():
	editor.current_tool = PaintBucket.new()
	_stroke()
	project.frames[0].create_layer(8, 8)
	assert_false(editor.undo())
	_stroke()
	var other := Project.new()
	other.new_project(8, 8)
	editor.project = other
	canvas.attach_project(other)
	assert_false(editor.undo())
	assert_eq(other.frames[0].layers[1].get_pixel(0, 0), Color.TRANSPARENT)


func test_brush_undo_waits_for_baking():
	if DisplayServer.get_name() == "headless":
		pending("Brush baking needs a rendered run")
		return
	var brush := Brush.new()
	brush.width = 2
	brush.stamp_tex = _stamp()
	editor.current_tool = brush
	var original := project.frames[0].layers[1].get_data()
	_press()
	assert_false(editor.undo())
	_release()
	assert_false(editor.undo())
	await wait_until(func(): return canvas.dynamic_node.get_child_count() == 0, 3)
	assert_ne(project.frames[0].layers[1].get_data(), original)
	assert_true(editor.undo())
	assert_eq(project.frames[0].layers[1].get_data(), original)
	assert_false(editor.undo())


func _stroke():
	_press()
	_release()


func _press():
	canvas.dynamic_node.position += canvas.dynamic_node.get_local_mouse_position()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	editor._handle_canvas_input(event)


func _release():
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	editor._input(event)


func _stamp() -> ImageTexture:
	var image := Image.create_empty(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)
