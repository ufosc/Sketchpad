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
var current_tool: Tool:
	set(value):
		current_tool = value
		tool_changed.emit(value)


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

func _unhandled_key_input(event: InputEvent) -> void:
	if project == null or not event.is_pressed() or event.is_echo():
		return
	for tool in toolset.tools:
		var action := tool.name.replace(" ", "")
		if InputMap.has_action(action) and event.is_action_pressed(action, false, true):
			current_tool = tool
			get_viewport().set_input_as_handled()
			return

func _handle_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var canvas_pos = canvas.dynamic_node.get_local_mouse_position()
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
