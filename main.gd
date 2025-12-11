extends Control

var file_dialog: FileDialog

@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter


func _on_import_source_image_button_pressed() -> void:
	file_dialog = FileDialog.new()
	file_dialog.use_native_dialog = true
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.png, *.jpg, *.jpeg, *.bmp, *.webp",  "Image Files")
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)
	file_dialog.show()


func _on_file_selected(file_path: String) -> void:
	file_dialog.queue_free()
	var image := Image.load_from_file(file_path)
	pietlang_interpreter.source_image = image
