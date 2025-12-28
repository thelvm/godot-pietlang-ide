extends SpinBox

@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter


func _on_pietlang_interpreter_state_updated() -> void:
	max_value = pietlang_interpreter.last_step - 1
	value = pietlang_interpreter.current_step


func _on_value_changed(new_value: float) -> void:
	pietlang_interpreter.load_from_state_history(int(new_value))
