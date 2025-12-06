class_name PietlangInterpreter
extends Node

signal executed_instruction(instruction: StringName)
signal stack_updated()

const DP_RIGHT = 0
const DP_DOWN = 1
const DP_LEFT = 2
const DP_UP = 3

const CC_LEFT = 0
const CC_RIGHT = 1

# "HEX string": [hue, lightness]
const PIET_COLORS: Dictionary[StringName, PackedInt32Array] = {
	"ffc0c0": [0, 2], # light red
	"ff0000": [0, 1], # red
	"c00000": [0, 0], # dark red
	
	"ffffc0": [1, 2], # light yellow
	"ffff00": [1, 1], # yellow
	"c0c000": [1, 0], # dark yellow
	
	"c0ffc0": [2, 2], # light green
	"00ff00": [2, 1], # green
	"00c000": [2, 0], # dark green
	
	"c0ffff": [3, 2], # light cyan
	"00ffff": [3, 1], # cyan
	"00c0c0": [3, 0], # dark cyan
	
	"c0c0ff": [4, 2], # light blue
	"0000ff": [4, 1], # blue
	"0000c0": [4, 0], # dark blue
	
	"ffc0ff": [5, 2], # light magenta
	"ff00ff": [5, 1], # magenta
	"c000c0": [5, 0], # dark magenta
	
	"ffffff": [-1, -1], # white
	"000000": [-1, -1], # black
}

# [hue change, lightness change]: instruction name
const INSTRUCTIONS: Dictionary[Array, StringName] = {
	[0, 0]: &"noop",
	[0, 1]: &"push",
	[0, 2]: &"pop",

	[1, 0]: &"add",
	[1, 1]: &"subtract",
	[1, 2]: &"multiply",

	[2, 0]: &"divide",
	[2, 1]: &"mod",
	[2, 2]: &"not",

	[3, 0]: &"greater",
	[3, 1]: &"pointer",
	[3, 2]: &"switch",

	[4, 0]: &"duplicate",
	[4, 1]: &"roll",
	[4, 2]: &"in_number",

	[5, 0]: &"in_char",
	[5, 1]: &"out_number",
	[5, 2]: &"out_char",
}

var source_image: Image

var stack: PackedByteArray = []
var dp_direction: int = DP_RIGHT
var cc_direction: int = CC_LEFT
var dp_position: Vector2i = Vector2i(0, 0)


func step() -> void:
	var previous_color := source_image.get_pixelv(dp_position)
	
	match dp_direction:
		DP_RIGHT:
			dp_position += Vector2i.RIGHT
		DP_DOWN:
			dp_position += Vector2i.DOWN
		DP_LEFT:
			dp_position += Vector2i.LEFT
		DP_UP:
			dp_position += Vector2i.UP
	
	var instruction := get_instruction(previous_color, source_image.get_pixelv(dp_position))
	match instruction:
		&"switch":
			piet_switch()
	
	executed_instruction.emit(instruction)


static func get_instruction(previous_color: Color, current_color: Color) -> StringName:
	var previous_pietcolor := color_to_pietcolor(previous_color)
	var current_pietcolor := color_to_pietcolor(current_color)
	if not previous_pietcolor.is_empty() and not current_pietcolor.is_empty():
		var hue_diff := posmod(previous_pietcolor[0] - current_pietcolor[0], 6)
		var light_diff := posmod(previous_pietcolor[1] - current_pietcolor[1], 3)
		return INSTRUCTIONS.get([hue_diff, light_diff], &"Unknown instruction")
	else:
		return &"Unknown instruction"
	


static func color_to_pietcolor(color: Color) -> PackedInt32Array:
	var piet_color: PackedInt32Array = PIET_COLORS.get(color.to_html(false), [])
	return piet_color


func piet_switch() -> void:
	if not stack.is_empty():
		var value = stack.get(stack.size())
		stack.remove_at(stack.size() - 1)
		cc_direction = (cc_direction + abs(value)) % 2
