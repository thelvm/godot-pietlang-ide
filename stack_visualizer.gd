extends VBoxContainer

@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter


func _ready() -> void:
	pietlang_interpreter.stack_updated.connect(_on_pietlang_interpreter_stack_updated)


func _on_pietlang_interpreter_stack_updated() -> void:
	var int_stack := pietlang_interpreter.stack.as_array()
	for child in get_children():
		child.queue_free()
	
	for i in range(int_stack.size() - 1, -1, -1):
		var stack_value_ui := preload("res://stack_value.tscn").instantiate() as StackValueUi
		stack_value_ui.value = int_stack[i]
		add_child(stack_value_ui)
