class_name CanvasCamera
extends Camera2D

signal touch_gesture_started
signal touch_gesture_ended

@export var max_zoom: float = 30.0
@export var min_zoom: float = 0.1

@export var zoom_speed: float = 1.1
@export var drag_speed: float = 1.0

var movable: bool = false

var is_dragging: bool = false

var touch_positions: Dictionary[int, Vector2] = {}
var previous_touch_center: Vector2
var previous_touch_distance: float = 0.0
var touch_gesture_active: bool = false


func _input(event: InputEvent) -> void:
	if movable:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				is_dragging = event.pressed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(1.0 / zoom_speed)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom(zoom_speed)
		elif event is InputEventMouseMotion:
			if is_dragging:
				var drag_diff = (event.relative / zoom) * drag_speed
				position -= drag_diff
		elif event is InputEventScreenTouch:
			_handle_screen_touch(event)
		elif event is InputEventScreenDrag:
			_handle_screen_drag(event)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_positions[event.index] = event.position
		if touch_positions.size() >= 2 and not touch_gesture_active:
			touch_gesture_active = true
			touch_gesture_started.emit()
	else:
		touch_positions.erase(event.index)
		if touch_positions.is_empty() and touch_gesture_active:
			touch_gesture_active = false
			touch_gesture_ended.emit()

	_reset_touch_gesture()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not touch_positions.has(event.index):
		return

	touch_positions[event.index] = event.position
	if touch_positions.size() != 2:
		_reset_touch_gesture()
		return

	var touches: Array[Vector2] = []
	for touch_position: Vector2 in touch_positions.values():
		touches.append(touch_position)

	var touch_center := (touches[0] + touches[1]) / 2.0
	var touch_distance := touches[0].distance_to(touches[1])
	if previous_touch_distance > 0.0:
		var drag_diff := ((touch_center - previous_touch_center) / zoom) * drag_speed
		position -= drag_diff

		if touch_distance > 0.0:
			_zoom(touch_distance / previous_touch_distance)

	previous_touch_center = touch_center
	previous_touch_distance = touch_distance


func _reset_touch_gesture() -> void:
	previous_touch_distance = 0.0
	if touch_positions.size() != 2:
		return

	var touches: Array[Vector2] = []
	for touch_position: Vector2 in touch_positions.values():
		touches.append(touch_position)

	previous_touch_center = (touches[0] + touches[1]) / 2.0
	previous_touch_distance = touches[0].distance_to(touches[1])


## Zooms the camera by a specified [param factor].
func _zoom(factor: float) -> void:
	zoom *= factor
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
