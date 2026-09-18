class_name PaintBucket
extends Tool

@export var title: String = "Paint Bucket"
@export var tolerance: float


func _init() -> void:
	name = "Paint Bucket"
	cursor = load("res://tools/paint_bucket/cursor.png")


func on_pointer_down(_position: Vector2, _canvas: Canvas) -> void:
	var project: Project = _canvas._project
	var current_page: Page = project.frames[project.current_frame]
	var layer: Image = current_page.layers[project.current_layer]

	var directions = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]

	var start_pos = Vector2i(_position)
	var initial_color: Color = layer.get_pixelv(start_pos)
	var initial_vector: Vector3 = Vector3(initial_color.r, initial_color.g, initial_color.b)
	var fill_color: Color = EditorState.color

	if initial_color == fill_color:
		return

	var visited: Dictionary = {}
	var pixels: Array[Vector2i] = [start_pos]
	while !pixels.is_empty():
		var pixel = pixels.pop_back()
		layer.set_pixelv(pixel, fill_color)
		for d in directions:
			var new_pixel = pixel + d

			if new_pixel.x < 0 or new_pixel.x >= project.width:
				continue
			elif new_pixel.y < 0 or new_pixel.y >= project.height:
				continue
			elif visited.has(new_pixel):
				continue

			var new_color: Color = layer.get_pixelv(new_pixel)
			if (
				initial_vector.distance_to(Vector3(new_color.r, new_color.g, new_color.b))
				<= tolerance * sqrt(3)
			):
				pixels.append(new_pixel)
				visited[new_pixel] = true
	current_page.set_layer(project.current_layer, layer)
