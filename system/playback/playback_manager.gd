class_name PlaybackManager
extends Node

var is_playing: bool = false

var _project: Project
var _timer: float = 0.0

func attach_project(project: Project) -> void:
	_project = project

func _process(delta: float) -> void:
	if is_playing:
		var frame_time = (1.0 / max(_project.framerate, 1))
		_timer += delta
		if _timer >= frame_time:
			_project.next_page(true)
			_timer -= frame_time
