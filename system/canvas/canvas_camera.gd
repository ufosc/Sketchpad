extends Camera2D

@export var max_zoom: float = 30.0
@export var min_zoom: float = 0.1

@export var zoom_speed: float = 1.1
@export var drag_speed: float = 1.0

var movable: bool = false

var is_dragging: bool = false

var touch_points: Dictionary = {}
var previous_touch_distance: float = 0.0
var previous_touch_center: Vector2 = Vector2.ZERO


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
			_handle_touch(event)
		elif event is InputEventScreenDrag:
			_handle_touch_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_points[event.index] = event.position
	else:
		touch_points.erase(event.index)

	if touch_points.size() == 2:
		var points = touch_points.values()
		previous_touch_distance = points[0].distance_to(points[1])
		previous_touch_center = (points[0] + points[1]) / 2.0
	else:
		previous_touch_distance = 0.0


func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	touch_points[event.index] = event.position

	if touch_points.size() == 2:
		var points = touch_points.values()

		var current_touch_distance = points[0].distance_to(points[1])
		var current_touch_center = (points[0] + points[1]) / 2.0

		if previous_touch_distance > 0.0:
			var zoom_factor = current_touch_distance / previous_touch_distance
			_zoom(zoom_factor)

			var drag_diff = ((current_touch_center - previous_touch_center) / zoom) * drag_speed
			position -= drag_diff

		previous_touch_distance = current_touch_distance
		previous_touch_center = current_touch_center


## Zooms the camera by a specified [param factor].
func _zoom(factor: float):
	zoom *= factor
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
