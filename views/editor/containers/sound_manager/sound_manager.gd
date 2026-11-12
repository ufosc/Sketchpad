extends Control

@export var sound_label: Label
@export var remove_sound_button: Button
@export var sound_file_dialog: FileDialog

var file_access_web: FileAccessWeb
var _project: Project


func _ready() -> void:
	if OS.has_feature("web"):
		_ensure_file_access_web()


func attach_project(project: Project) -> void:
	_project = project
	if _project and _project.audio:
		sound_label.text = "Audio: %ds" % _project.audio.get_length()
		remove_sound_button.disabled = false
	else:
		sound_label.text = "No audio assigned."
		remove_sound_button.disabled = true


## Attaches audio to the project.
func _set_audio() -> void:
	if not _project:
		return
	if OS.has_feature("web"):
		_ensure_file_access_web()
		file_access_web.open(".mp3")
		return
	var current_project = _project
	sound_file_dialog.show()
	var path = await sound_file_dialog.file_selected
	if path and _project and current_project == _project:
		var stream = AudioStreamMP3.load_from_file(path)
		if stream:
			_project.audio = stream
			_project.audio_origin_framerate = _project.framerate
			Toast.show_message("Imported %s!" % path.get_file())

			sound_label.text = "Audio: %ds" % _project.audio.get_length()
			remove_sound_button.disabled = false
		else:
			Toast.show_message("Failed to load audio file.")
	else:
		Toast.show_message("Failed to load audio file.")


## Removes audio from the project.
func _remove_audio() -> void:
	if not _project:
		return
	_project.audio = null
	_project.audio_origin_framerate = 1.0
	Toast.show_message("Removed audio from project.")
	sound_label.text = "No audio assigned."
	remove_sound_button.disabled = true


# Web File Access Handlers
func _on_file_loaded(_file_name: String, _file_type: String, base64_data: String) -> void:
	if not _project:
		return
	var bytes = Marshalls.base64_to_raw(base64_data)

	var file = FileAccess.open("user://temp.mp3", FileAccess.WRITE)
	if not file:
		Toast.show_message("Failed to process file data.")
		return
	file.store_buffer(bytes)
	file.close()

	var stream = AudioStreamMP3.load_from_buffer(bytes)
	if stream == null:
		DirAccess.remove_absolute("user://temp.mp3")
		Toast.show_message("Failed to load audio file.")
		return

	_project.audio = stream
	_project.audio_origin_framerate = _project.framerate

	Toast.show_message("Imported %s!" % _file_name)

	sound_label.text = "Audio: %ds" % _project.audio.get_length()
	remove_sound_button.disabled = false

	DirAccess.remove_absolute("user://temp.mp3")


func _on_file_error() -> void:
	Toast.show_message("Failed to read the selected file.")


func _on_file_cancelled() -> void:
	Toast.show_message("File selection cancelled.")


func _ensure_file_access_web() -> void:
	if file_access_web:
		return
	file_access_web = FileAccessWeb.new()
	file_access_web.loaded.connect(_on_file_loaded)
	file_access_web.error.connect(_on_file_error)
	file_access_web.upload_cancelled.connect(_on_file_cancelled)
