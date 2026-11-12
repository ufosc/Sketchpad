class_name PlaybackManager
extends Node

var is_playing: bool = false

var audio_stream_player: AudioStreamPlayer

var _project: Project
var _timer: float = 0.0

func attach_project(project: Project) -> void:
	# Purge leftover audio players.
	for child in get_children():
		child.queue_free()

	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	is_playing = false
	_project = project
	_timer = 0.0

## Plays the assigned project from the current frame.
func play() -> void:
	if not _project:
		is_playing = false
		return
	_update_audio()
	if audio_stream_player.stream:
		audio_stream_player.play(_get_current_second())
	is_playing = true

## Pauses the assigned project.
func pause() -> void:
	if not _project:
		is_playing = false
		return
	if audio_stream_player.stream:
		audio_stream_player.stop()
	is_playing = false

## Toggles the playback state of the assigned project.
func toggle_playback_state(new_play_state: bool) -> void:
	if new_play_state:
		play()
	else:
		pause()

func _process(delta: float) -> void:
	if not _project or not is_playing:
		return
	if is_playing:
		var frame_time = _get_frame_time()
		_timer += delta
		if _timer >= frame_time:
			_project.next_page(true)
			_timer -= frame_time
		if audio_stream_player.stream and _project.current_frame == 0:
			audio_stream_player.play(_get_current_second())
			audio_stream_player.pitch_scale = _get_audio_pitch()

func _get_frame_time() -> float:
	return 1.0 / max(_project.framerate, 1)

func _get_current_second() -> float:
	return _project.current_frame * _get_frame_time() + _timer

func _get_audio_pitch() -> float:
	return _project.framerate / max(_project.audio_origin_framerate, 1)

func _update_audio() -> void:
	if _project and _project.audio and audio_stream_player.stream != _project.audio:
		audio_stream_player.stream = _project.audio
