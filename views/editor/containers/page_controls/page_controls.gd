class_name PageControls
extends Node

signal menu_toggle

signal play_toggle(is_playing: bool)

signal onion_skin_toggle

@export var menu_button: Button

@export var next_page_button: Button
@export var page_count_label: Label
@export var prev_page_button: Button

@export var framerate_slider: Slider
@export var framerate_label: Label

@export var play_button: Button
@export var play_icon: Texture2D
@export var pause_icon: Texture2D

@export var onion_skin_button: Button
@export var onion_on_icon: Texture2D
@export var onion_off_icon: Texture2D

@export var undo_button: Button
@export var redo_button: Button

var is_playing = false

var _project: Project


func attach_project(project: Project):
	if _project and _project.new_current_page.is_connected(_update_view):
		_project.new_current_page.disconnect(_update_view)

	_project = project

	if _project:
		_project.new_current_page.connect(_update_view)
		_project.undo_redo.version_changed.connect(update_undo_redo_buttons)

func update_undo_redo_buttons() -> void:
	if _project:
		undo_button.disabled = not _project.undo_redo.has_undo()
		redo_button.disabled = not _project.undo_redo.has_redo()

func _update_view(_page: Page) -> void:
	framerate_slider.value = _project.framerate
	framerate_label.text = str(int(_project.framerate))
	page_count_label.text = "%d/%d" % [_project.current_frame + 1, _project.frames.size()]


func _on_next_button_pressed() -> void:
	if _project:
		_project.next_page(false)


func _on_prev_button_pressed() -> void:
	if _project:
		_project.prev_page()


func _on_play_pressed() -> void:
	is_playing = !is_playing
	play_toggle.emit(is_playing)

	play_button.icon = pause_icon if is_playing else play_icon
	next_page_button.disabled = !next_page_button.disabled
	prev_page_button.disabled = !prev_page_button.disabled


func _on_slider_value_changed(value: float) -> void:
	framerate_label.text = str(int(value))
	_project.framerate = value


func _on_menu_button_pressed() -> void:
	menu_toggle.emit()


func _on_onion_skin_pressed() -> void:
	onion_skin_button.icon = (
		onion_on_icon if onion_skin_button.icon == onion_off_icon else onion_off_icon
	)
	onion_skin_toggle.emit()
