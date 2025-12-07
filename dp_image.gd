extends Sprite2D

@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter
@onready var code_image: TextureRect = %CodeImage


func _process(_delta: float) -> void:
	if code_image.texture:
		visible = true
		var code_texture_aspect_ratio := float(code_image.texture.get_width()) / float(code_image.texture.get_height())
		var code_image_control_aspect_ratio := code_image.size[0] / code_image.size[1]
		var image_scale: float
		if code_texture_aspect_ratio > code_image_control_aspect_ratio:
			# If the texture will be resized by fitting it's width
			image_scale = code_image.size[0] / float(code_image.texture.get_width())
		else:
			# If the texture will be resized by fitting it's height
			image_scale = code_image.size[1] / float(code_image.texture.get_height())
		
		var image_size_on_screen = code_image.texture.get_size() * image_scale
		var codel_size_on_screen := Vector2()
		codel_size_on_screen.x = image_size_on_screen.x / float(code_image.texture.get_width())
		codel_size_on_screen.y = image_size_on_screen.y / float(code_image.texture.get_height())
		
		scale.x = codel_size_on_screen.x / texture.get_width()
		scale.y = codel_size_on_screen.y / texture.get_height()
		
		position.x = pietlang_interpreter.dp_position.x * codel_size_on_screen.x
		position.y = pietlang_interpreter.dp_position.y * codel_size_on_screen.y
		
		# Offset so it's relative to the center of the code image
		position.x += (code_image.size.x / 2) - image_size_on_screen.x / 2
		position.y += (code_image.size.y / 2) - image_size_on_screen.y / 2
		
		# Offset so it's in the middle of the codel
		position.x += codel_size_on_screen.x / 2
		position.y += codel_size_on_screen.y / 2
		
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
