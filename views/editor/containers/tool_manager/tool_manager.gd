class_name ToolManager
extends Control

@export var tool_tab: TabContainer
@export var editor: Editor

var _project: Project


func _ready() -> void:
	_on_tool_list_tab_changed(0)


func attach_project(project: Project) -> void:
	_project = project



func _on_tool_list_tab_changed(tab: int) -> void:
	var brush_circle: Texture2D
	var paint_bucket: Texture2D
	var dragger: Texture2D

	editor.current_tool = tool_tab.get_tab_control(tab).tool

	if (editor.current_tool.name == "Base"):
		brush_circle = preload("res://tools/brush/big_circle/brush_template.png")
		var brush_circle_image = brush_circle.get_image()
		
		# this was the only way I found to separate the eraser case, as it as the same name as the brush
		if (editor.current_tool.resource_path == "res://tools/eraser/big_circle/big_circle.tres"):
			brush_circle_image.fill(Color.WHITE)
		else:
			brush_circle_image.fill(editor.current_tool.color)
		Input.set_custom_mouse_cursor(brush_circle_image)
		
		
	if (editor.current_tool.name == "Dragger"):
		dragger = preload("res://assets/icons/dragger.png")
		var dragger_image = dragger.get_image()
		Input.set_custom_mouse_cursor(dragger_image)
	if (editor.current_tool.name == "Paint Bucket"):
		paint_bucket = preload("res://assets/icons/paint_bucket.png")
		var paint_bucket_image = paint_bucket.get_image()
		Input.set_custom_mouse_cursor(paint_bucket_image)
