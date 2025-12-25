extends Line2D

@onready var source_code_image: SourceCodeTextureRect = %SourceCodeImage
@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter


func _on_pietlang_interpreter_state_updated() -> void:
	width = minf(1.0, source_code_image.codel_size_on_screen.x / 10.0)
	_update_points()


func _update_points() -> void:
	clear_points()
	for state in pietlang_interpreter.state_history:
		var point_position := source_code_image.pixel_position_to_local_position(state.dp_position)
		add_point(point_position)
