class_name Canvas
extends Node2D

signal canvas_input(event: InputEventMouse)

@export var camera_movable: bool = false
@export var camera: Camera2D

var _project: Project

@onready var control_node: Control = $Control
@onready var layers_node: Node2D = $Control/Layers
@onready var onion_skin_renderer: OnionSkinRenderer = $Control/OnionSkin
@onready var dynamic_node: Node2D = $Control/Dynamic

@onready var bake_viewport: Viewport = $BakeViewport
@onready var bake_node: Node2D = $BakeViewport/Bake


func _ready() -> void:
	camera.movable = camera_movable


func attach_project(project: Project) -> void:
	if _project and _project.new_current_page.is_connected(render_page):
		_project.new_current_page.disconnect(render_page)

	_project = project

	if _project:
		_project.new_current_page.connect(render_page)
		onion_skin_renderer.attach_project(project)


## Refreshes canvas sprites to current page. [br]
## [param page] - Page to render.
func render_page(page: Page) -> void:
	control_node.size = Vector2(_project.width, _project.height)
	control_node.position = -(control_node.size / 2.0)

	for node in layers_node.get_children():
		layers_node.remove_child(node)
		node.queue_free()

	var textures = page.get_content()
	for texture in textures:
		var sprite = Sprite2D.new()
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		layers_node.add_child(sprite)
		if sprite is Sprite2D:
			sprite.texture = texture

	onion_skin_renderer.render()


func toggle_onion_skin() -> void:
	onion_skin_renderer.toggle()


## Sets the number of ghost frames to display backwards.
func set_onion_skin_depth(new_depth: int) -> void:
	onion_skin_renderer.set_depth(new_depth)


## Bakes [code]dynamic_node[/code] contents to the current page.
func bake_page() -> void:
	# Getting items from our project.
	var current_page = _project.frames[_project.current_frame]
	var current_layer = _project.current_layer

	bake_viewport.size = Vector2(_project.width, _project.height)
	bake_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	bake_viewport.transparent_bg = true

	# Preventing the odd flicker between render and baking.
	for node in dynamic_node.get_children():
		var new_node = node.duplicate()
		bake_node.add_child(new_node)

	# Taking the snapshot of our dynamic node.
	bake_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw

	# Baking ontop of the existing layer.
	var texture_to_bake = bake_viewport.get_texture()
	var image_to_bake = texture_to_bake.get_image()

	# Convert premultiply RGB to normal RGB
	for y in image_to_bake.get_height():
		for x in image_to_bake.get_width():
			var c = image_to_bake.get_pixel(x, y)
			if c.a > 0.0:
				c.r /= c.a
				c.g /= c.a
				c.b /= c.a
			image_to_bake.set_pixel(x, y, c)

	var layer_image = current_page.layers[current_layer]
	layer_image.blend_rect(
		image_to_bake, Rect2(Vector2.ZERO, image_to_bake.get_size()), Vector2.ZERO
	)

	current_page.set_layer(current_layer, layer_image)

	# Clearing dynamic and viewport now that it is baked.
	for node in bake_node.get_children():
		bake_node.remove_child(node)
		node.queue_free()

	for node in dynamic_node.get_children():
		dynamic_node.remove_child(node)
		node.queue_free()

	_project.get_current_page()


func _on_gui_input(event: InputEvent) -> void:
	canvas_input.emit(event)


## Shows [param tool]'s cursor texture while hovering the canvas, or the
## default arrow if the tool has none.
func set_tool_cursor(tool: Tool) -> void:
	if tool and tool.cursor:
		control_node.mouse_default_cursor_shape = Control.CURSOR_CROSS
		Input.set_custom_mouse_cursor(tool.cursor, Input.CURSOR_CROSS, tool.cursor.get_size() / 2.0)
	else:
		control_node.mouse_default_cursor_shape = Control.CURSOR_ARROW
