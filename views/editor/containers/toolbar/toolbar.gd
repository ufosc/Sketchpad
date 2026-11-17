extends Control

@export var editor: Editor

@export var toolstrip: VBoxContainer

func assign_tool(tool: Tool) -> void:
	editor.current_tool = tool

func _ready() -> void:
	for tool in editor.toolset.tools:
		var button = Button.new()
		button.icon = tool.icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.custom_minimum_size = Vector2(32, 32)
		if tool.shortcut:
			button.shortcut = tool.shortcut
		button.tooltip_text = tool.name
		button.connect("pressed", Callable(self, "_tool_selected").bind(tool))
		toolstrip.add_child(button)

func _tool_selected(tool: Tool) -> void:
	if(editor.current_tool == tool):
		editor.edit_extras.change_tab(1)
		editor.edit_extras.open()
	else:
		editor.current_tool = tool
