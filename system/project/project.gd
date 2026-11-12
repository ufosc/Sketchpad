class_name Project
extends Resource

signal new_current_page(page: Page)
signal new_current_layer(idx: int)
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

var undo_redo: UndoRedo

var current_layer: int = 1
var current_frame: int = 0

func _init() -> void:
	undo_redo = UndoRedo.new()
	undo_redo.max_steps = 20

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(undo_redo):
			undo_redo.free()

## Initializes a new project. [br]
## Used instead of [code]_init[/code] to avoid overwriting loaded data.
func new_project(w: int, h: int) -> void:
	width = w
	height = h
	frames.clear()
	current_frame = 0
	current_layer = 1

	var was_frame_update_connected := frames_update.is_connected(_on_frame_update)
	if was_frame_update_connected:
		frames_update.disconnect(_on_frame_update)
	new_page()
	if not frames_update.is_connected(_on_frame_update):
		frames_update.connect(_on_frame_update)
	new_current_page.emit(frames[0])
	print("[Project] New project created")


## Returns the current focused page in the project.
func get_current_page() -> Page:
	if frames.is_empty():
		return null
	_bound_selection()
	return frames[current_frame]


## Sets the current frame to a specific index. [br]
## Returns [code]null[/code] if the page does not exist. [br]
## [param index]: The index of the page.
func get_page_by_index(index: int = 0) -> Page:
	if index >= 0 and index < len(frames):
		current_frame = index
		_bound_selection()
		new_current_page.emit(frames[current_frame])
		return frames[current_frame]
	return null


## Returns a page some distance removed from the focused page in the project. [br]
## Returns [code]null[/code] if the page does not exist. [br]
## [param distance]: Determines how far to grab the page.
func get_distant_page(distance: int = 1) -> Page:
	if _is_valid_frame(current_frame + distance):
		return frames[current_frame + distance]
	return null


## Changes the current project page to the next page. [br]
## [param is_loop]: Goes back to page 0 if at the end. Adds a new page otherwise.
func next_page(is_loop: bool) -> Page:
	if frames.is_empty():
		new_page()
		current_frame = 0
		new_current_page.emit(frames[current_frame])
		return frames[current_frame]

	current_frame += 1
	if len(frames) < (current_frame + 1):
		if is_loop:
			current_frame = 0
		else:
			new_page()
	_bound_selection()
	new_current_page.emit(frames[current_frame])
	return frames[current_frame]


## Changes the current project page to the previous page. Stops at frame 0.
func prev_page() -> Page:
	if frames.is_empty():
		return null
	if current_frame > 0:
		current_frame -= 1
	_bound_selection()
	new_current_page.emit(frames[current_frame])
	return frames[current_frame]


## Triggers project saving elements.
func on_project_save() -> void:
	last_saved = Time.get_datetime_string_from_system(false, true)

	var current_page := get_current_page()
	if current_page == null:
		return

	var tn = current_page.flatten()
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
	var current_page := get_current_page()
	if current_page == null or not _is_valid_layer(idx) or image == null:
		return

	var original = current_page.layers[idx].duplicate() if old_image == null else old_image
	var new = image.duplicate()

	undo_redo.create_action("Edit Layer")
	undo_redo.add_do_method(current_page.set_layer.bind(idx, new))
	undo_redo.add_undo_method(current_page.set_layer.bind(idx, original))
	undo_redo.commit_action()


## Create a new blank page
func new_page() -> void:
	var pg := Page.new(width, height)
	pg.page_update.connect(_on_page_update)
	frames.append(pg)
	frames_update.emit()


## Switch to new frame
func set_frame(idx: int) -> void:
	if not _is_valid_frame(idx):
		return
	current_frame = idx
	_bound_selection()
	new_current_page.emit(frames[current_frame])


## Switch to new layer
func set_layer(idx: int) -> void:
	if not _is_valid_layer(idx):
		return
	current_layer = idx
	new_current_layer.emit(idx)


## Deletes the frame at specified index
func delete_frame(idx: int) -> void:
	if not _is_valid_frame(idx) or frames.size() <= 1:
		return
	frames.remove_at(idx)
	if current_frame >= frames.size():
		current_frame = frames.size() - 1
	_bound_selection()
	new_current_page.emit(frames[current_frame])


func _on_new_current_page(_page: Page) -> void:
	undo_redo.clear_history()

func _on_frame_update() -> void:
	if frames.is_empty():
		return
	_bound_selection()
	new_current_page.emit(frames[current_frame])

func _is_valid_frame(idx: int) -> bool:
	return idx >= 0 and idx < frames.size()

func _is_valid_layer(idx: int) -> bool:
	if not _is_valid_frame(current_frame):
		return false
	return idx >= 0 and idx < frames[current_frame].layers.size()

func _bound_selection() -> void:
	if frames.is_empty():
		current_frame = 0
		current_layer = 0
		return

	current_frame = clampi(current_frame, 0, frames.size() - 1)
	var layer_count := frames[current_frame].layers.size()
	current_layer = clampi(current_layer, 0, maxi(layer_count - 1, 0))
