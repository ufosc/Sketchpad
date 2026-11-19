class_name ProjectView
extends FullPanel

const GIFExporter = preload("res://addons/gdgifexporter/exporter.gd")
const MedianCutQuantization = preload("res://addons/gdgifexporter/quantization/median_cut.gd")

@export_category("UI Elements")
@export var name_label: Label
@export var date_label: Label
@export var frame_label: Label
@export var file_picker: FileDialog

@export_category("External Connections")
@export var editor: Editor
@export var gallery: Gallery

@export_category("Project Preview")
@export var canvas: Canvas
@export var viewport: SubViewport
@export var playback_manager: PlaybackManager
@export var aspect: AspectRatioContainer

var _project: Project


## Loads in a provided [param project].
func load_in(project: Project):
	_project = project
	load_info()
	super.open()


## Populates the project viewer with the project's information.
func load_info() -> void:
	name_label.text = _project.title
	frame_label.text = str(len(_project.frames)) + " Frames"
	date_label.text = _project.last_saved

	canvas.attach_project(_project)
	playback_manager.attach_project(_project)

	viewport.size_2d_override = Vector2i(_project.width, _project.height)
	if _project.height > 0:
		aspect.ratio = float(_project.width) / float(_project.height)
	playback_manager.play()


## Empties the project viewer when it closes.
func unload_info() -> void:
	name_label.text = ""
	frame_label.text = ""
	date_label.text = ""

	_project = null
	playback_manager.pause()
	canvas.attach_project(_project)
	playback_manager.attach_project(_project)


## Exports a project.
func export_project() -> void:
	if OS.has_feature("web"):
		ResourceSaver.save(_project, "user://temp.res", ResourceSaver.FLAG_COMPRESS)
		var file = FileAccess.open("user://temp.res", FileAccess.READ)
		var buffer = file.get_buffer(file.get_length())
		file.close()
		JavaScriptBridge.download_buffer(
			buffer, "%s.res" % _project.title, "application/octet-stream"
		)
		Toast.show_message("Downloading project file!")
		DirAccess.remove_absolute("user://temp.res")
		return
	file_picker.filters = ["*.res"]
	file_picker.current_file = "%s.res" % _project.title
	file_picker.show()
	var path = await file_picker.file_selected
	if path:
		ResourceSaver.save(_project, path, ResourceSaver.FLAG_COMPRESS)
		Toast.show_message("Saved project file!")


## Removes the project from the SketchpadProjects directory.
func delete_project() -> void:
	OptionDialog.ask(
		"Delete", "Do you want to delete this project?", "Delete", "Cancel", true
	)
	if await OptionDialog.closed:
		DirAccess.remove_absolute("%s/%s.res" % [Consts.PROJ_PATH, _project.title])
		gallery.fetch_projects()
		close()
		Toast.show_message("Project deleted!")


## Triggers a load in the editor.
func trigger_load() -> void:
	editor.load_project(_project)
	close()
	gallery.close()


## Exports the project as a GIF.
func export_gif() -> void:
	var path = ""
	var is_web = OS.has_feature("web")
	file_picker.current_file = "%s.gif" % _project.title
	if not is_web:
		file_picker.filters = ["*.gif"]
		file_picker.show()
		path = await file_picker.file_selected
		if !path:
			return
	var gif = GIFExporter.new(_project.width, _project.height)
	for idx: int in range(_project.frames.size()):
		var frame = _project.frames[idx]
		var img = frame.flatten()
		if img:
			gif.add_frame(img, 1.0 / max(_project.framerate, 1), MedianCutQuantization)
	if is_web:
		JavaScriptBridge.download_buffer(
			gif.export_file_data(), "%s.gif" % _project.title, "image/gif"
		)
		Toast.show_message("Downloading GIF!")
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_buffer(gif.export_file_data())
		file.close()
		Toast.show_message("Saved GIF!")


func close() -> void:
	super.close()
	unload_info()
