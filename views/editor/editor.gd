class_name Editor
extends Node

signal tool_changed(tool: Tool)

const UNDO_LIMIT: int = 20

@export var canvas: Canvas
@export var page_controls: PageControls
@export var playback_manager: PlaybackManager
@export var edit_extras: EditExtras
@export var toolset: Toolset

var project: Project
var current_page: Page
var current_tool: Tool:
	set(value):
		current_tool = value
		tool_changed.emit(value)

var _undo_history: Array[Dictionary] = []
var _stroke_tool: Tool


func _ready() -> void:
	canvas.canvas_input.connect(_handle_canvas_input)

	page_controls.menu_toggle.connect(edit_extras.open)
	page_controls.play_toggle.connect(
		func(): playback_manager.is_playing = !playback_manager.is_playing
	)
	page_controls.onion_skin_toggle.connect(canvas.toggle_onion_skin)


## Creates a blank project and loads into the editor.
func new_project() -> void:
	var blank_project = Project.new()
	blank_project.new_project(256, 192)
	load_project(blank_project)


## Loads a provided [param project] into the editor.
func load_project(p: Project) -> void:
	_undo_history.clear()
	_stroke_tool = null
	project = p
	page_controls.attach_project(project)
	canvas.attach_project(project)
	playback_manager.attach_project(project)
	edit_extras.attach_project(project)
	if project:
		project.get_page_by_index(0)


## Loads in a blank project
func unload_project() -> void:
	playback_manager.pause()
	load_project(null)


func _handle_canvas_input(event: InputEvent) -> void:
	if not project or playback_manager.is_playing:
		return
	var canvas_pos = canvas.dynamic_node.get_local_mouse_position()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if current_tool is Tool and not _stroke_tool:
				if canvas.dynamic_node.get_child_count() == 0:
					_save_canvas_state()
					_stroke_tool = current_tool
					_stroke_tool.on_pointer_down(canvas_pos, canvas)
		else:
			_finish_stroke(canvas_pos)
	elif event is InputEventMouseMotion and _stroke_tool:
		_stroke_tool.on_pointer_move(canvas_pos, canvas)


func _save_canvas_state() -> void:
	var page := project.get_current_page()
	var images: Array[Image] = []
	for image in page.layers:
		images.append(image.duplicate())
	_undo_history.append({"page": page, "layers": images, "layer": project.current_layer})
	if _undo_history.size() > UNDO_LIMIT:
		_undo_history.pop_front()


func _finish_stroke(position: Vector2) -> void:
	if _stroke_tool:
		_stroke_tool.on_pointer_up(position, canvas)
		_stroke_tool = null


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and _stroke_tool:
			_finish_stroke(canvas.dynamic_node.get_local_mouse_position())
			get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode != KEY_Z or event.shift_pressed or event.alt_pressed:
		return
	if event.ctrl_pressed or event.meta_pressed:
		var focus := get_viewport().gui_get_focus_owner()
		if focus is LineEdit or focus is TextEdit:
			return
		undo()
		get_viewport().set_input_as_handled()


func undo() -> bool:
	if not project or playback_manager.is_playing or _stroke_tool or _undo_history.is_empty():
		return false
	if canvas.dynamic_node.get_child_count() > 0:
		return false
	var state: Dictionary = _undo_history.pop_back()
	var page: Page = state.page
	if not project.frames.has(page) or page.layers.size() != state.layers.size():
		_undo_history.clear()
		return false
	for index in range(page.layers.size()):
		page.set_layer(index, state.layers[index].duplicate())
	project.set_layer(state.layer)
	project.set_frame(project.frames.find(page))
	return true
