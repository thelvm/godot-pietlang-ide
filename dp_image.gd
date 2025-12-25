extends Sprite2D

@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter
@onready var source_code_image: SourceCodeTextureRect = %SourceCodeImage


func _update() -> void:
	if source_code_image.texture:
		visible = true
		position = source_code_image.pixel_position_to_local_position(pietlang_interpreter.dp_position)
		
		scale.x = source_code_image.codel_size_on_screen.x / texture.get_size().x
		scale.y = source_code_image.codel_size_on_screen.y / texture.get_size().y
		
		match pietlang_interpreter.dp_direction:
			PietlangInterpreter.DP_RIGHT:
				rotation_degrees = 0
			PietlangInterpreter.DP_DOWN:
				rotation_degrees = 90
			PietlangInterpreter.DP_LEFT:
				rotation_degrees = 180
			PietlangInterpreter.DP_UP:
				rotation_degrees = 270
		match pietlang_interpreter.cc_direction:
			PietlangInterpreter.CC_LEFT:
				flip_v = false
			PietlangInterpreter.CC_RIGHT:
				flip_v = true
	else:
		visible = 0
