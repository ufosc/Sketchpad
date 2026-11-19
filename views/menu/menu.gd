class_name Menu
extends FullPanel

@export var gallery: Gallery
@export var editor: Editor
@export var version_label: Label


func _ready() -> void:
	version_label.text = ProjectSettings.get_setting("application/config/version")
	if OS.has_feature("web"):
		JavaScriptBridge.pwa_update_available.connect(_on_pwa_update_available)

func _on_pwa_update_available() -> void:
	OptionDialog.ask(
		"Update Available",
		"Sketchpad has an update available. Would you like to update now?",
		"Update",
		"Later"
	)
	if await OptionDialog.closed:
		Toast.show_message("Updating Sketchpad... Will reload when finished.")
		JavaScriptBridge.pwa_update()

func _new_project_clicked() -> void:
	editor.new_project()
	self.close()


func _on_view_clicked() -> void:
	gallery.open()
	self.close()
