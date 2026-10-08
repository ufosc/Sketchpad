extends PanelContainer

@export var tool: LineTool

var tool_manager: ToolManager


func assign_tool(new_tool: Tool) -> void:
	tool = new_tool



func _on_tool_settings_changed() -> void:
	pass
