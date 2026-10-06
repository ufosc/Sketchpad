class_name History
extends RefCounted

const MAX_STATES: int = 20

var _states: Array[Dictionary] = []


func save_state(project: Project) -> void:
	var page := project.get_current_page()
	var layer := project.current_layer
	var state := {
		"page": page,
		"layer": layer,
		"layer_count": page.layers.size(),
		"image": page.layers[layer].duplicate(),
	}
	_states.append(state)
	if _states.size() > MAX_STATES:
		_states.pop_front()


func undo(project: Project) -> bool:
	while not _states.is_empty():
		var state: Dictionary = _states.pop_back()
		var page: Page = state.page
		var layer: int = state.layer
		var frame := project.frames.find(page)
		if frame == -1 or page.layers.size() != state.layer_count:
			continue
		if page.layers[layer].get_data() == state.image.get_data():
			continue
		if frame != project.current_frame:
			project.set_frame(frame)
		project.set_layer(layer)
		page.set_layer(layer, state.image)
		return true
	return false
