extends CanvasLayer

signal closed(choice: bool)

@export var title_widget: Label
@export var desc_widget: Label
@export var true_button: Button
@export var false_button: Button
@export var panel: FullPanel


## Shows a true/false popup with provided information. [br]
## Use the [code]closed[/code] signal to get the result. [br]
## [param title]: The title of the popup. [br]
## [param desc]: The description of the popup. [br]
## [param btrue]: The text of the true button. [br]
## [param bfalse]: The text of the false button.
## [param danger]: If true, the false button will be styled as a danger button.
func ask(
	title: String,
	desc: String,
	btrue: String = "Yes",
	bfalse: String = "No",
	danger: bool = false):
	if visible:
		panel.close()
	title_widget.text = title
	desc_widget.text = desc
	true_button.text = btrue
	false_button.text = bfalse
	if danger:
		true_button.add_theme_stylebox_override(
			"normal",
			load("res://assets/theme/styleboxes/button/danger/danger_button.tres"))
		true_button.add_theme_stylebox_override(
			"pressed",
			load("res://assets/theme/styleboxes/button/danger/danger_button_pressed.tres"))
		true_button.add_theme_stylebox_override(
			"hover",
			load("res://assets/theme/styleboxes/button/danger/danger_button_hover.tres"))
		true_button.add_theme_stylebox_override(
			"hover_pressed",
			load("res://assets/theme/styleboxes/button/danger/danger_button_hover_pressed.tres"))
	else:
		true_button.remove_theme_stylebox_override("normal")
		true_button.remove_theme_stylebox_override("pressed")
		true_button.remove_theme_stylebox_override("hover")
		true_button.remove_theme_stylebox_override("hover_pressed")
	panel.open()


func on_true_picked() -> void:
	panel.close()
	closed.emit(true)


func on_false_picked() -> void:
	panel.close()
	closed.emit(false)
