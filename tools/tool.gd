class_name Tool
extends Resource

signal settings_changed

@export var name: String = "Base"
@export var icon: Texture2D = PlaceholderTexture2D.new()
@export var cursor: Texture2D
@export var cursor_hotspot: Vector2 = Vector2.ZERO
@export var handler: PackedScene
@export var handler_bar: PackedScene


## Triggers when the pointer is pressed down on the canvas. [br]
## [param _position] - Position of pointer. [br]
## [param _canvas] - The active canvas node.
func on_pointer_down(_position: Vector2, _canvas: Canvas) -> void:
	pass


## Triggers when the pointer is released from the canvas. [br]
## [param _position] - Position of pointer. [br]
## [param _canvas] - The active canvas node.
func on_pointer_up(_position: Vector2, _canvas: Canvas) -> void:
	pass


## Triggers when the pointer is moved around the canvas. [br]
## [param _position] - Position of pointer. [br]
## [param _canvas] - The active canvas node.
func on_pointer_move(_position: Vector2, _canvas: Canvas) -> void:
	pass
