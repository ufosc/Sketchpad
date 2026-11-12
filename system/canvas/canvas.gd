class_name Canvas
extends Node2D

signal canvas_input(event: InputEvent)

@export var camera_movable: bool = false
@export var camera: CanvasCamera

var _project: Project

@onready var control_node: Control = $Control
@onready var layers_node: Node2D = $ProjectViewport/Layers
@onready var onion_skin_renderer: OnionSkinRenderer = $ProjectViewport/OnionSkin
@onready var dynamic_node: Node2D = $ProjectViewport/Dynamic

@onready var project_viewport: Viewport = $ProjectViewport
@onready var project_render: Sprite2D = $Control/ProjectRender

@onready var bake_viewport: Viewport = $BakeViewport
@onready var bake_node: Node2D = $BakeViewport/Bake


func _ready() -> void:
	camera.movable = camera_movable
	project_render.texture = project_viewport.get_texture()
	project_render.centered = false
	project_render.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

## Shows [param tool] cursor while the mouse is over the drawing area
func set_tool_cursor(tool: Tool) -> void:
	if tool and tool.cursor:
		Input.set_custom_mouse_cursor(tool.cursor, Input.CURSOR_CROSS, tool.cursor_hotspot)
		control_node.mouse_default_cursor_shape = Control.CURSOR_CROSS
	else:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_CROSS)
		control_node.mouse_default_cursor_shape = Control.CURSOR_ARROW


func attach_project(project: Project) -> void:
	if _project:
		if _project.new_current_page.is_connected(render_page):
			_project.new_current_page.disconnect(render_page)
		if _project.new_current_layer.is_connected(_update_dynamic):
			_project.new_current_layer.disconnect(_update_dynamic)

	_project = project

	if _project:
		_project.new_current_page.connect(render_page)
		_project.new_current_layer.connect(_update_dynamic)
		onion_skin_renderer.attach_project(project)

		var project_size := Vector2i(_project.width, _project.height)
		project_viewport.size = project_size
		control_node.size = Vector2(project_size)
		control_node.position = -control_node.size / 2.0
		project_render.texture = project_viewport.get_texture()

		layers_node.position = Vector2.ZERO
		onion_skin_renderer.position = Vector2.ZERO
		dynamic_node.position = Vector2.ZERO

		layers_node.scale = Vector2.ONE
		onion_skin_renderer.scale = Vector2.ONE
		dynamic_node.scale = Vector2.ONE

		_update_dynamic(_project.current_layer)
	else:
		_clear_rendered_layers()
		for node in dynamic_node.get_children():
			dynamic_node.remove_child(node)
			node.queue_free()
		onion_skin_renderer.attach_project(null)


## Refreshes canvas sprites to current page. [br]
## [param page] - Page to render.
func render_page(page: Page) -> void:
	control_node.size = Vector2(_project.width, _project.height)
	control_node.position = -(control_node.size / 2.0)

	for node in layers_node.get_children():
		layers_node.remove_child(node)
		node.queue_free()

	var textures = page.get_content()
	var i = 1
	for texture in textures:
		var sprite = Sprite2D.new()
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		layers_node.add_child(sprite)
		if sprite is Sprite2D:
			sprite.texture = texture
			sprite.z_index = i
		i += 3

	onion_skin_renderer.render()


func get_project_mouse_position() -> Vector2:
	return control_node.get_local_mouse_position()


func _clear_rendered_layers() -> void:
	for node in layers_node.get_children():
		layers_node.remove_child(node)
		node.queue_free()


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

	var layer_image = current_page.layers[current_layer].duplicate()
	layer_image.blend_rect(
		image_to_bake, Rect2(Vector2.ZERO, image_to_bake.get_size()), Vector2.ZERO
	)

	#current_page.set_layer(current_layer, layer_image)
	_project.edit_current_layer(current_layer, layer_image)

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


func _update_dynamic(idx: int) -> void:
	dynamic_node.z_index = idx + 2
