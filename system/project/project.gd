class_name Project
extends Resource

signal new_current_page(page: Page)
signal frames_update

@export var title: String = "New Animation"
@export var framerate: float = 1.0

@export var width: int = 256
@export var height: int = 192

@export var frames: Array[Page]

@export var audio: AudioStream
@export var audio_origin_framerate: float = 1.0
@export var audio_clips: Dictionary[int, AudioStream]

@export var thumbnail: Image

@export var last_saved: String = "No Date"

var undo_redo: UndoRedo = UndoRedo.new()

var current_layer: int = 1
var current_frame: int = 0

func _init() -> void:
	undo_redo.max_steps = 20

## Initializes a new project. [br]
## Used instead of [code]_init[/code] to avoid overwriting loaded data.
func new_project(w: int, h: int) -> void:
	width = w
	height = h

	new_page()
	new_current_page.emit(frames[0])

	frames_update.connect(_on_frame_update)
	print("[Project] New project created")


## Returns the current focused page in the project.
func get_current_page() -> Page:
	return frames[current_frame]


## Sets the current frame to a specific index. [br]
## Returns [code]null[/code] if the page does not exist. [br]
## [param index]: The index of the page.
func get_page_by_index(index: int = 0) -> Page:
	if index >= 0 and index < len(frames):
		current_frame = index
		new_current_page.emit(frames[current_frame])
		return frames[current_frame]
	return null


## Returns a page some distance removed from the focused page in the project. [br]
## Returns [code]null[/code] if the page does not exist. [br]
## [param distance]: Determines how far to grab the page.
func get_distant_page(distance: int = 1) -> Page:
	if current_frame + distance >= 0 and current_frame + distance < len(frames):
		return frames[current_frame + distance]
	return null


## Changes the current project page to the next page. [br]
## [param is_loop]: Goes back to page 0 if at the end. Adds a new page otherwise.
func next_page(is_loop: bool) -> Page:
	current_frame += 1
	if len(frames) < (current_frame + 1):
		if is_loop:
			current_frame = 0
		else:
			new_page()
	new_current_page.emit(frames[current_frame])
	return frames[current_frame]


## Changes the current project page to the previous page. Stops at frame 0.
func prev_page() -> Page:
	if current_frame > 0:
		current_frame -= 1
	new_current_page.emit(frames[current_frame])
	return frames[current_frame]


## Triggers project saving elements.
func on_project_save() -> void:
	last_saved = Time.get_datetime_string_from_system(false, true)

	var tn = frames[current_frame].flatten()
	if tn:
		tn.resize(128, 96, Image.INTERPOLATE_NEAREST)
		thumbnail = tn


## Obtains the project's thumbnail as a Texture2D.
func get_thumbnail() -> Texture2D:
	var img = thumbnail
	if img != null:
		return ImageTexture.create_from_image(img)
	return load("res://system/project/placeholder_thumbnail.png")


## Emit signal when page updates
func _on_page_update() -> void:
	frames_update.emit()


## Edits the active layer with a new image.
func edit_current_layer(idx: int, image: Image, old_image: Image = null) -> void:
	var original = frames[current_frame].layers[idx].duplicate() if old_image == null else old_image
	var new = image.duplicate()

	undo_redo.create_action("Edit Layer")
	undo_redo.add_do_method(frames[current_frame].set_layer.bind(idx, new))
	undo_redo.add_undo_method(frames[current_frame].set_layer.bind(idx, original))
	undo_redo.commit_action()


## Create a new blank page
func new_page() -> void:
	var pg := Page.new(width, height)
	pg.page_update.connect(_on_page_update)
	frames.append(pg)
	frames_update.emit()


## Switch to new frame
func set_frame(idx: int) -> void:
	current_frame = idx
	new_current_page.emit(frames[current_frame])


func set_layer(idx: int) -> void:
	current_layer = idx


func delete_frame(idx: int) -> void:
	frames.remove_at(idx)
	if current_frame >= frames.size():
		current_frame = frames.size() - 1
	new_current_page.emit(frames[current_frame])


func _on_frame_update() -> void:
	new_current_page.emit(frames[current_frame])
