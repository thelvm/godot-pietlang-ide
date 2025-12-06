extends VBoxContainer

@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter


func _ready() -> void:
	pietlang_interpreter.stack_updated.connect(_on_pietlang_interpreter_stack_updated)


func _on_pietlang_interpreter_stack_updated() -> void:
	for child in get_children():
		child.queue_free()
	
	for i in range(pietlang_interpreter.stack.size() - 1, -1, -1):
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_FILL
		hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var label_int := Label.new()
		label_int.text = str(int(pietlang_interpreter.stack[i]))
		hbox.add_child(label_int)
		
		var label_char := Label.new()
		label_char.text = pietlang_interpreter.stack.slice(i, i + 1).get_string_from_ascii()
		hbox.add_child(label_char)
		
		add_child(hbox)
