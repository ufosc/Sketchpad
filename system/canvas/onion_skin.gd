class_name OnionSkinRenderer
extends Node2D

const BASE_OPACITY: float = 0.3

var enabled: bool = false
var depth: int = 1

var _project: Project


func attach_project(project: Project) -> void:
	_project = project


func toggle() -> void:
	enabled = !enabled
	render()


func set_depth(new_depth: int) -> void:
	depth = max(new_depth, 1)
	render()


func render() -> void:
	_clear_children()

	if not enabled or _project == null:
		return

	for i in range(1, depth + 1):
		var opacity = BASE_OPACITY / float(i)
		var prev_page = _project.get_distant_page(-i)
		if prev_page:
			_add_frame(prev_page, opacity)


func _add_frame(page: Page, opacity: float) -> void:
	var textures = page.get_content()
	for i in range(1, textures.size()):
		var texture = textures[i]
		var sprite = Sprite2D.new()
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.modulate = Color(1, 1, 1, opacity)
		sprite.texture = texture
		add_child(sprite)


func _clear_children() -> void:
	for node in get_children():
		remove_child(node)
		node.queue_free()
