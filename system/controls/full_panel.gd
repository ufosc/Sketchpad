class_name FullPanel
extends Control

@export var anim_speed: float = 0.5


## Opens the full panel.
func open():
	if !visible:
		visible = true

		var top = get_viewport_rect().size.y
		position.y = top

		var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position:y", 0, anim_speed)


## Closes and hides the full panel.
func close():
	if visible:
		var top = get_viewport_rect().size.y

		var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position:y", top, anim_speed)
		await tween.finished

		visible = false


## Toggles the full panel open or closed.
func toggle():
	if visible:
		close()
	else:
		open()
