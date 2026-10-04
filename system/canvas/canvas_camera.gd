extends Camera2D

@export var max_zoom: float = 30.0
@export var min_zoom: float = 0.1

@export var zoom_speed: float = 1.1
@export var drag_speed: float = 1.0

var movable: bool = false

var is_dragging: bool = false

# Touch state for pinch zoom and two-finger pan
var touches: Dictionary = {}
var last_pinch_distance: float = 0.0
var last_pinch_center: Vector2 = Vector2.ZERO


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
		# Track which fingers are on the screen
		elif event is InputEventScreenTouch:
			if event.pressed:
				touches[event.index] = event.position
			else:
				touches.erase(event.index)
			last_pinch_distance = 0.0
		# Update finger position, then handle two-finger gesture
		elif event is InputEventScreenDrag:
			touches[event.index] = event.position
			if touches.size() == 2:
				_handle_two_finger_gesture()


## Zooms the camera by a specified [param factor].
func _zoom(factor: float):
	zoom *= factor
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)

## Zooms and pans the camera using two fingers
func _handle_two_finger_gesture() -> void:
	var points: Array = touches.values()
	var distance: float = points[0].distance_to(points[1])
	var center: Vector2 = (points[0] + points[1]) / 2.0

	if last_pinch_distance > 0.0:
		_zoom(distance / last_pinch_distance)
		position -= ((center - last_pinch_center) / zoom) * drag_speed

	last_pinch_distance = distance
	last_pinch_center = center
