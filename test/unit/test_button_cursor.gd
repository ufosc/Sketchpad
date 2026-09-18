extends GutTest


func test_button_gets_pointing_hand_cursor():
	var button := Button.new()
	add_child_autofree(button)

	assert_eq(button.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, "Button cursor shape")


func test_button_already_in_tree_gets_pointing_hand_cursor():
	var menu_scene: PackedScene = load("res://views/menu/menu.tscn")
	var menu := menu_scene.instantiate()
	add_child_autofree(menu)

	var new_button: Button = menu.get_node("VBoxContainer/Options/NewButton")
	assert_eq(
		new_button.mouse_default_cursor_shape,
		Control.CURSOR_POINTING_HAND,
		"Pre-existing menu button cursor shape"
	)
