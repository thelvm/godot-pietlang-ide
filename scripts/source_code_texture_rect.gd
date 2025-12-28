class_name SourceCodeTextureRect
extends TextureRect

@onready var pietlang_interpreter: PietlangInterpreter = %PietlangInterpreter

var image_size_on_screen: Vector2
var codel_size_on_screen: Vector2


func _on_pietlang_interpreter_source_image_set() -> void:
	texture = ImageTexture.create_from_image(pietlang_interpreter.source_image)
	visible = true


## Given a pixel position in the source image, transform it in screenspace.
func pixel_position_to_local_position(pixel_position: Vector2) -> Vector2:
	if not texture:
		return Vector2.ZERO
	
	var local_position := Vector2()
	local_position.x = pixel_position.x * codel_size_on_screen.x
	local_position.y = pixel_position.y * codel_size_on_screen.y
	
	# Offset so it's relative to the center of the code image
	local_position.x += (size.x / 2) - image_size_on_screen.x / 2
	local_position.y += (size.y / 2) - image_size_on_screen.y / 2
	
	# Offset so it's in the middle of the codel
	local_position.x += codel_size_on_screen.x / 2
	local_position.y += codel_size_on_screen.y / 2
	
	return local_position


func _on_resized() -> void:
	_update_sizes()


func _update_sizes() -> void:
	if not texture:
		return
	var code_texture_aspect_ratio := float(texture.get_width()) / float(texture.get_height())
	var code_image_control_aspect_ratio := size.x / size.y
	var image_scale: float
	if code_texture_aspect_ratio > code_image_control_aspect_ratio:
		# If the texture will be resized by fitting it's width
		image_scale = size.x / float(texture.get_width())
	else:
		# If the texture will be resized by fitting it's height
		image_scale = size.y / float(texture.get_height())
	
	image_size_on_screen = texture.get_size() * image_scale
	
	codel_size_on_screen.x = image_size_on_screen.x / float(texture.get_width())
	codel_size_on_screen.y = image_size_on_screen.y / float(texture.get_height())
