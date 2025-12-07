extends VBoxContainer

@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter


func _ready() -> void:
	pietlang_interpreter.stack_updated.connect(_on_pietlang_interpreter_stack_updated)


func _on_pietlang_interpreter_stack_updated() -> void:
	var int_stack := pietlang_interpreter.stack.as_array()
	for child in get_children():
		child.queue_free()
	
	for i in range(int_stack.size() - 1, -1, -1):
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_FILL
		
		var label_int := Label.new()
		label_int.text = str(int_stack[i])
		hbox.add_child(label_int)
		
		var label_char := Label.new()
		label_char.text = char(int_stack[i])
		hbox.add_child(label_char)
		
		add_child(hbox)
