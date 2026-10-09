class_name Editor
extends Node

signal tool_changed(tool: Tool)

@export var canvas: Canvas
@export var page_controls: PageControls
@export var playback_manager: PlaybackManager
@export var edit_extras: EditExtras
@export var toolset: Toolset

var project: Project
var current_page: Page
var touch_gesture_active: bool = false
var emulated_touch_pending: bool = false
var emulated_touch_start: Vector2
var emulated_touch_stroke_active: bool = false
var current_tool: Tool:
	set(value):
		current_tool = value
		tool_changed.emit(value)


func _ready() -> void:
	canvas.canvas_input.connect(_handle_canvas_input)
	canvas.camera.touch_gesture_started.connect(_on_touch_gesture_started)
	canvas.camera.touch_gesture_ended.connect(_on_touch_gesture_ended)

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
	if event is InputEventMouse:
		var canvas_pos = canvas.dynamic_node.get_local_mouse_position()
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			_handle_emulated_touch_mouse(event, canvas_pos)
			return

		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if current_tool is Tool:
					if event.pressed:
						current_tool.on_pointer_down(canvas_pos, canvas)
					else:
						current_tool.on_pointer_up(canvas_pos, canvas)
		elif event is InputEventMouseMotion:
			if current_tool is Tool:
				current_tool.on_pointer_move(canvas_pos, canvas)


func _handle_emulated_touch_mouse(event: InputEventMouse, canvas_pos: Vector2) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			if not touch_gesture_active:
				emulated_touch_start = canvas_pos
				emulated_touch_pending = true
		elif not touch_gesture_active and current_tool is Tool:
			if emulated_touch_pending and not emulated_touch_stroke_active:
				current_tool.on_pointer_down(emulated_touch_start, canvas)
			if emulated_touch_pending or emulated_touch_stroke_active:
				current_tool.on_pointer_up(canvas_pos, canvas)
			emulated_touch_pending = false
			emulated_touch_stroke_active = false
	elif event is InputEventMouseMotion:
		if touch_gesture_active or not emulated_touch_pending or not (current_tool is Tool):
			return
		if not emulated_touch_stroke_active:
			current_tool.on_pointer_down(emulated_touch_start, canvas)
			emulated_touch_stroke_active = true
		current_tool.on_pointer_move(canvas_pos, canvas)


func _finish_emulated_touch_stroke(canvas_pos: Vector2) -> void:
	if emulated_touch_stroke_active and current_tool is Tool:
		current_tool.on_pointer_up(canvas_pos, canvas)
	emulated_touch_pending = false
	emulated_touch_stroke_active = false


func _on_touch_gesture_started() -> void:
	touch_gesture_active = true
	_finish_emulated_touch_stroke(canvas.dynamic_node.get_local_mouse_position())


func _on_touch_gesture_ended() -> void:
	touch_gesture_active = false
	emulated_touch_pending = false
	emulated_touch_stroke_active = false
