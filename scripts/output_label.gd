extends Label

@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter


func _ready() -> void:
	pietlang_interpreter.outputed.connect(_on_pietlang_interpreter_char_outputed)


func _on_pietlang_interpreter_char_outputed(char_value: String) -> void:
	text += char_value
