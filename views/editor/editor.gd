extends Node

var project: Project
var current_page: Page

var current_tool: Tool

@onready var canvas = $CanvasContainer/CanvasViewport/Canvas
@onready var page_controls = $PageControls
@onready var playback_manager = $PlaybackManager

func _ready() -> void:
	project = Project.new()

	page_controls.attach_project(project)
	canvas.attach_project(project)
	playback_manager.attach_project(project)

	page_controls.play_toggle.connect(
		func(): playback_manager.is_playing = !playback_manager.is_playing
		)

	project.new_project(256, 192)

	current_tool = Brush.new() # Placeholder for now.

func _input(event: InputEvent) -> void:
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
