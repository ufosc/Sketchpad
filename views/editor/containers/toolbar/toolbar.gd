extends Control

@export var editor: Editor

@export var toolstrip: VBoxContainer

func assign_tool(tool: Tool) -> void:
	editor.current_tool = tool

func _ready() -> void:
	editor.tool_changed.connect(_on_tool_change)
	for tool in editor.toolset.tools:
		var button = Button.new()
		button.icon = tool.icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.custom_minimum_size = Vector2(32, 32)
		button.connect("pressed", Callable(self, "_tool_selected").bind(tool))
		toolstrip.add_child(button)

func _tool_selected(tool: Tool) -> void:
	if(editor.current_tool == tool):
		editor.edit_extras.change_tab(1)
		editor.edit_extras.open()
	else:
		editor.current_tool = tool

func _on_tool_change(tool: Tool) -> void:
	if tool is Brush:
		Input.set_custom_mouse_cursor(load('res://tools/brush/crosshair.png'),
											Input.CURSOR_CROSS, Vector2(8, 8))
	elif tool is Eraser:
		Input.set_custom_mouse_cursor(load('res://tools/eraser/crosshair.png'),
											Input.CURSOR_CROSS, Vector2(8, 8))
	elif tool is Dragger:
		Input.set_custom_mouse_cursor(load('res://tools/dragger/dragger.png'),
											Input.CURSOR_CROSS, Vector2(8, 8))
	elif tool is PaintBucket:
		Input.set_custom_mouse_cursor(load('res://tools/paint_bucket/paint_bucket.png'),
											Input.CURSOR_CROSS, Vector2(8, 8))
