extends Control

const ACTIONS = [
	"Brush",
	"Eraser",
	"PaintBucket",
	"Dragger",
]
const CONFIG_PATH = "user://shortcuts.cfg"
const CONFIG_SECTION = "shortcuts"

@export var editor: Editor
var _rebinding_action = ""

func _ready() -> void:
	_load_binds()
	_refresh_labels()

func _set_button(action: String) -> Button:
	return get_node("VBoxContainer/HBox%s/%s" % [action, action])

func _refresh_labels() -> void:
	for action in ACTIONS:
		var button = _set_button(action)
		button.button_pressed = false
		var key = InputMap.action_get_events(action)[0]
		if key != null:
			button.set_text(key.as_text())
		else:
			button.set_text("Unbound")

func _on_brush_pressed() -> void:
	_start_rebind("Brush")

func _on_eraser_pressed() -> void:
	_start_rebind("Eraser")

func _on_paint_bucket_pressed() -> void:
	_start_rebind("PaintBucket")

func _on_dragger_pressed() -> void:
	_start_rebind("Dragger")

func _start_rebind(action: String) -> void:
	_rebinding_action = action
	_set_button(action).text = "Enter a key:"

func _input(event: InputEvent) -> void:
	if _rebinding_action.is_empty() or not event is InputEventKey:
		return
	var key = event as InputEventKey
	if not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	if key.keycode != KEY_ESCAPE:
		_change_key(key.physical_keycode)
	_rebinding_action = ""
	_refresh_labels()

func _change_key(new_key: int) -> void:
	var old_key = _get_keycode(_rebinding_action)
	if new_key == old_key:
		return
	for action in ACTIONS:
		if action != _rebinding_action and _get_keycode(action) == new_key:
			_set_binds(action, old_key)
			Toast.show_message("%s and %s swapped. Duplicates are not allowed.")
			break
	_set_binds(_rebinding_action, new_key)
	_save_binds()

func _get_keycode(action: String) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).physical_keycode
	return 0

func _set_binds(action: String, keycode: int) -> void:
	InputMap.action_erase_events(action)
	if keycode == 0:
		return
	var event = InputEventKey.new()
	event.physical_keycode = keycode as Key
	InputMap.action_add_event(action, event)

func _key_text(keycode: int) -> String:
	var event = InputEventKey.new()
	event.physical_keycode = keycode as Key
	return event.as_text_keycode()

func _save_binds() -> void:
	var config = ConfigFile.new()
	for action in ACTIONS:
		config.set_value(CONFIG_SECTION, action, _get_keycode(action))
	var err = config.save(CONFIG_PATH)
	if err != OK:
		push_warning("Could not save shortcuts (error %d)" % err)
		Toast.show_message("Failed to save shortcuts.")

func _load_binds() -> void:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
			return
	var loaded = {}
	var used_codes = {}
	for action in ACTIONS:
		var code = config.get_value(CONFIG_SECTION, action, 0)
		if typeof(code) != TYPE_INT or code <= 0 or used_codes.has(code):
			push_warning("Invalid shortcut configurations. Using defaults.")
			return
		used_codes[code] = true
		loaded[action] = code
	for action in ACTIONS:
		_set_binds(action, loaded[action])
