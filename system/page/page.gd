class_name Page
extends Resource

signal page_update

@export var layers: Array[Image] = []
@export var names: Array[String] = []

var textures: Array[ImageTexture] = []


func _init(w: int = 0, h: int = 0) -> void:
	if w != 0 and h != 0:
		create_layer(w, h, Color.WHITE)
		create_layer(w, h)
		print("[Page] Page created")


## Creates a layer in the page. [br]
## [param w] - Width of layer. [br]
## [param h] - Height of layer. [br]
## [param c] - Color of background. Defaults to transparent.
func create_layer(w: int, h: int, c: Color = Color.TRANSPARENT, idx: int = -1) -> void:
	if idx == -1:
		idx = layers.size()
	layers.insert(idx, Image.create_empty(w, h, false, Image.FORMAT_RGBA8))
	layers[idx].fill(c)
	var new_name = "layer " + str(layers.size() - 1)
	names.insert(idx, new_name)
	textures.insert(idx, ImageTexture.create_from_image(layers[idx]))
	page_update.emit()


## Returns the Page as an array of ImageTextures.
func get_content() -> Array[ImageTexture]:
	for i in range(layers.size()):
		if i < textures.size():
			textures[i].update(layers[i])
		else:
			textures.append(ImageTexture.create_from_image(layers[i]))
			names.append("layer " + str(i))
	return textures


## Updates Page contents with live textures.
func set_content() -> void:
	for i in range(layers.size()):
		if i < textures.size():
			layers[i] = textures[i].get_image()
	page_update.emit()


## Updates layer content with provided image.[br]
## [param idx] - Index of layer. [br]
## [param image] - Image to replace layer with.
func set_layer(idx: int, image: Image) -> void:
	layers[idx] = image
	textures[idx].update(layers[idx])
	page_update.emit()


## Flattens the page into a single page. [br]
## Useful for exports and thumbnails.
func flatten() -> Image:
	if not layers.is_empty():
		var out = layers[0].duplicate()
		for i in range(1, len(layers)):
			var img = layers[i]
			out.blend_rect(img, Rect2(Vector2.ZERO, img.get_size()), Vector2.ZERO)
		return out
	return null


## Updates the name of a layer
func rename(idx: int, new_name: String) -> void:
	names[idx] = new_name
	page_update.emit()


func delete_layer(idx: int) -> void:
	layers.remove_at(idx)
	textures.remove_at(idx)
	names.remove_at(idx)
	page_update.emit()


func insert_layer(idx: int, layer: Image, new_name: String) -> void:
	layers.insert(idx, layer)
	textures.insert(idx, ImageTexture.create_from_image(layers[idx]))
	names.insert(idx, new_name)
	page_update.emit()
