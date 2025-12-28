extends Label

@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter


func _ready() -> void:
	pietlang_interpreter.executed_instruction.connect(_on_interpreter_executed_instruction)


func _on_interpreter_executed_instruction(instruction: StringName) -> void:
	text = instruction
