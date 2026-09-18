extends Node

## Makes every Button show the OS's pointing-hand cursor on hover,
## using a recursive walk of the scene tree in addition to checking for
## future nodes being added.


func _ready() -> void:
	get_tree().node_added.connect(_apply_cursor)
	_apply_cursor_recursive(get_tree().root)


func _apply_cursor_recursive(node: Node) -> void:
	_apply_cursor(node)
	for child in node.get_children():
		_apply_cursor_recursive(child)


func _apply_cursor(node: Node) -> void:
	if node is Button:
		node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
