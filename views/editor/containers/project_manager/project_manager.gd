extends FullPanel

@export var line_edit: LineEdit
@export var menu: Menu
@export var edit_extras: FullPanel
@export var editor: Editor

var _project: Project


func attach_project(project: Project) -> void:
	if _project:
		line_edit.text = ""

	_project = project

	if _project:
		line_edit.text = _project.title


## Saves the attached project to the filesystem.
func save_project() -> void:
	if _project:
		DirAccess.make_dir_absolute(Consts.PROJ_PATH)
		_project.on_project_save()
		var save = ResourceSaver.save(
			_project, "%s/%s.res" % [Consts.PROJ_PATH, _project.title], ResourceSaver.FLAG_COMPRESS
		)
		if save == OK:
			Toast.show_message("Saved project %s!" % _project.title)
		else:
			Toast.show_message("Failed to save project %s!" % _project.title)


func _on_text_changed(new_text: String) -> void:
	if _project:
		if new_text:
			_project.title = new_text
		else:
			_project.title = "New Animation"


func _on_menu_button_pressed() -> void:
	await menu.open()
	edit_extras.close()
	editor.unload_project()
