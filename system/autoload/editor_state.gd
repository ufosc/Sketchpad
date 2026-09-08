extends Node

signal color_changed(value: Color)

var color: Color = Color.BLACK:
	set(value):
		if value == color:
			return
		color = value
		color_changed.emit(color)
