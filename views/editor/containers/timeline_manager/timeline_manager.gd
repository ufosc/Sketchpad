class_name TimelineManager
extends Control

@export var image_timeline: HBoxContainer
@export var audio_timeline: HBoxContainer
@export var new_layer_button: Button
@export var copy_layer_button: Button
@export var cut_layer_button: Button
@export var paste_layer_button: Button
@export var delete_layer_button: Button

var current_list: LayersList
var pasteboard_images: Array[Image]
var pasteboard_names: Array[String]

var _project: Project
var _buttons_connected: bool = false


func attach_project(proj: Project) -> void:
	if _project and _project.frames_update.is_connected(_on_frames_update):
		_project.frames_update.disconnect(_on_frames_update)

	_project = proj

	if not _buttons_connected:
		new_layer_button.pressed.connect(_creating_new_layer)
		copy_layer_button.pressed.connect(_on_click_copy)
		cut_layer_button.pressed.connect(_on_click_cut)
		paste_layer_button.pressed.connect(_on_click_paste)
		delete_layer_button.pressed.connect(_deleting_layers)
		_buttons_connected = true

	if not _project:
		for child in image_timeline.get_children():
			child.queue_free()
		return

	_project.frames_update.connect(_on_frames_update)
	setup_image_timeline()


func setup_image_timeline() -> void:
	if not _project:
		return

	for child in image_timeline.get_children():
		if child is Control:
			child.release_focus()
		child.queue_free()

	var frames := _project.frames

	for frame_index in range(frames.size()):
		var layers_list := LayersList.new()

		layers_list.frame_index = frame_index

		layers_list.title = "Frame " + str(frame_index + 1)
		layers_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		layers_list.size_flags_vertical = Control.SIZE_EXPAND_FILL

		image_timeline.add_child(layers_list)
		layers_list.selection_changed.connect(_on_layers_list_selection_changed)
		layers_list.copy_layers.connect(_copying_layers)

		layers_list.set_data(frames[frame_index])

		if frame_index == _project.current_frame:
			layers_list.current_layer = _project.current_layer

		layers_list.update_cell_styles()


func _on_layers_list_selection_changed(source: LayersList) -> void:
	if not _project:
		return
	for child in image_timeline.get_children():
		var layers_list := child as LayersList

		if layers_list == null:
			continue

		if layers_list != source:
			layers_list.clear_selection()
			if source.selected_indices.size() == 1:
				layers_list.current_layer = -1

	if source.selected_indices.size() == 1:
		_project.set_frame(source.frame_index)
		_project.set_layer(source.selected_indices[0])
		source.current_layer = _project.current_layer
		current_list = source


func _creating_new_layer() -> void:
	if not _project:
		return
	var frame_idx := _project.current_frame
	var layer_idx := _project.current_layer + 1
	var w := _project.width
	var h := _project.height
	_project.frames[frame_idx].create_layer(w, h, Color.TRANSPARENT, layer_idx)


func _deleting_layers() -> void:
	if not current_list or not _project:
		return

	var deleting_idx := current_list.selected_indices
	deleting_idx.sort()
	deleting_idx.reverse()

	var frames := _project.frames

	for idx in deleting_idx:
		if frames.size() == 1 && deleting_idx.size() == frames[0].layers.size():
			return
		current_list.displayed_page.delete_layer(idx)

	for frame_index in range(frames.size() - 1, -1, -1):
		if frames[frame_index].layers.is_empty() && frames.size() > 1:
			_project.delete_frame(frame_index)

	if _project.current_frame >= frames.size():
		_project.set_frame(frames.size() - 1)

	if _project.current_layer >= frames[_project.current_frame].layers.size():
		_project.set_layer(frames[_project.current_frame].layers.size() - 1)

	setup_image_timeline()


func _copying_layers(pasteboard: Array[Image], names: Array[String]) -> void:
	pasteboard_images = pasteboard
	pasteboard_names = names


func _on_click_copy() -> void:
	if not current_list:
		return

	current_list.copy()
	setup_image_timeline()


func _on_click_cut() -> void:
	if not current_list:
		return

	current_list.cut()
	setup_image_timeline()


func _on_click_paste() -> void:
	if not current_list:
		return
	current_list.paste(pasteboard_images, pasteboard_names)
	setup_image_timeline()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and _project:
		var command_or_ctrl_pressed = event.ctrl_pressed or event.meta_pressed

		if not command_or_ctrl_pressed:
			match event.keycode:
				KEY_DELETE:
					_deleting_layers()

				KEY_BACKSPACE:
					_deleting_layers()

		else:
			match event.keycode:
				KEY_C:
					_on_click_copy()

				KEY_X:
					_on_click_cut()

				KEY_V:
					_on_click_paste()


func _on_frames_update() -> void:
	call_deferred("setup_image_timeline")
