class_name PietlangInterpreter
extends Node

## Emitted when the source image image is set or replaced.
signal source_image_set
## Emitted when an instruction has finished executing.
signal executed_instruction(instruction: StringName)
## Effectively acts like an stdout stream.
signal outputed(value: String)
## Emitted when the stack has been modified in any way.
signal stack_updated
## Emitted when the state of the interpreter changes in any way.
signal state_updated

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

## The "source code", but as an image, because this is Piet.
var source_image: Image: set = _set_source_image

var stack: Stack
var dp_direction: int = DP_RIGHT
var cc_direction: int = CC_LEFT
var dp_position: Vector2i = Vector2i(0, 0)

var current_step: int = 0
## The last step of the program execution. -1 if unknown. 
var last_step: int = -1
var last_executed_instruction: StringName = &"noop"
var state_history: Array[InterpreterState]


func _ready() -> void:
	stack = Stack.new()
	state_history.append(InterpreterState.new())
	state_updated.emit()


## Steps through the program using the current Direction Pointer location and direction and the Codel Chooser direction.
func step() -> void:
	current_step += 1
	# If the last step has been determined and we're trying to step byond it.
	if last_step != -1 and current_step > last_step:
		# Bypass the step and keep the counter at last_step.
		current_step = last_step
		return
	
	# Load step from the state history if it's a step we already computed.
	#TODO invalidate step history on picture change
	if state_history.size() > current_step:
		load_from_state_history(current_step)
		return
	
	#TODO make ColorBlock class to hold all the information about a color block.
	var previous_color := source_image.get_pixelv(dp_position)
	var color_block := get_color_block(dp_position, previous_color)
	
	var valid_next_position := false
	var rotations := 0
	while not valid_next_position:
		# Iterate through all 8 posible code block exits.
		var potential_position := get_next_codel_from_color_block(color_block)
		
		if potential_position.x < source_image.get_width() and 0 <= potential_position.x and potential_position.y < source_image.get_height() and 0 <= potential_position.y and source_image.get_pixelv(potential_position) != Color.BLACK:
			# If not out of bounds or black.
			valid_next_position = true
			dp_position = potential_position
		else:
			# Aternates between switching the Codel Chooser and Rotating the Codel Pointer.
			if rotations % 2 == 0:
				cc_direction = (cc_direction + 1) % 2
			if rotations % 2 == 1:
				dp_direction = (dp_direction + 1) % 4
			rotations += 1
			# Until we have tested all possible exits, in which case the program is over.
			if rotations >= 8:
				print("Program ended.")
				last_step = current_step
				return
	
	var instruction := get_instruction(previous_color, source_image.get_pixelv(dp_position))
	
	match instruction:
		&"add":
			piet_add()
		&"substract":
			piet_substract()
		&"multiply":
			piet_multiply()
		&"divide":
			piet_divide()
		&"switch":
			piet_switch()
		&"mod":
			piet_mod()
		&"greater":
			piet_greater()
		&"push":
			piet_push(color_block.size())
		&"switch":
			piet_switch()
		&"pointer":
			piet_pointer()
		&"duplicate":
			piet_duplicate()
		&"pop":
			piet_pop()
		&"roll":
			piet_roll()
		&"out_char":
			piet_out_char()
		&"out_number":
			piet_out_number()
	
	last_executed_instruction = instruction
	_increment_state_history()
	executed_instruction.emit(last_executed_instruction)
	state_updated.emit()


## Goes back one step in the state history.
func step_back() -> void:
	if current_step <= 0:
		return
	current_step -= 1
	load_from_state_history(current_step)


## Tries to execute the entire program, caching every step in history. Stops early if more than max_steps are necessary to end the program.
func traverse(max_steps: int = 1000, seek_to_start: bool = true):
	while last_step == -1 and current_step <= max_steps:
		step()
	if seek_to_start:
		load_from_state_history(0)


## Translates the difference between two colors into a Pier instruction.
static func get_instruction(previous_color: Color, current_color: Color) -> StringName:
	var previous_pietcolor := color_to_pietcolor(previous_color)
	var current_pietcolor := color_to_pietcolor(current_color)
	if not previous_pietcolor.is_empty() and not current_pietcolor.is_empty():
		var hue_diff := posmod(current_pietcolor[0] - previous_pietcolor[0], 6)
		var light_diff := posmod(previous_pietcolor[1] - current_pietcolor[1], 3)
		return INSTRUCTIONS.get([hue_diff, light_diff], &"Unknown instruction")
	else:
		return &"Unknown instruction"


## Maps a color to one of the 20 defined Pier colors. Only maps correctly if the color is exactly the right value. Colors outside the range of the defined colors are returned as [code []].
static func color_to_pietcolor(color: Color) -> PackedInt32Array:
	var piet_color: PackedInt32Array = PIET_COLORS.get(color.to_html(false), [])
	return piet_color


## Returns all the codels belonging to the color block of which start_codel is a part of.
func get_color_block(start_codel: Vector2i, start_codel_color: Color) -> Array[Vector2i]:
	var to_explore: Array[Vector2i] = [start_codel]
	var part_of_block: Array[Vector2i] = []
	
	while not to_explore.is_empty():
		var current: Vector2i = to_explore.pop_back()
		part_of_block.append(current)
		
		# right
		if current.x + 1 < source_image.get_width():
			var right := Vector2i(current.x + 1, current.y)
			if source_image.get_pixelv(right) == start_codel_color and not part_of_block.has(right) and not to_explore.has(right):
				to_explore.append(right)

		# left
		if current.x - 1 >= 0:
			var left := Vector2i(current.x - 1, current.y)
			if source_image.get_pixelv(left) == start_codel_color and not part_of_block.has(left) and not to_explore.has(left):
				to_explore.append(left)

		# down
		if current.y + 1 < source_image.get_height():
			var down := Vector2i(current.x, current.y + 1)
			if source_image.get_pixelv(down) == start_codel_color and not part_of_block.has(down) and not to_explore.has(down):
				to_explore.append(down)

		# up
		if current.y - 1 >= 0:
			var up := Vector2i(current.x, current.y - 1)
			if source_image.get_pixelv(up) == start_codel_color and not part_of_block.has(up) and not to_explore.has(up):
				to_explore.append(up)
	
	return part_of_block


## Given the color block, uses the current dp_position, dp_direction and cc_direction to figure out the next codel.
func get_next_codel_from_color_block(color_block: Array[Vector2i]) -> Vector2i:
	var target_codel := dp_position

	if dp_direction == DP_RIGHT:
		# Find rightmost codel
		for codel in color_block:
			if codel.x >= target_codel.x:
				target_codel = codel
		
		if cc_direction == CC_LEFT:
			# Among rightmost, choose topmost
			for codel in color_block:
				if codel.x == target_codel.x and codel.y < target_codel.y:
					target_codel = codel
		elif cc_direction == CC_RIGHT:
			# Among rightmost, choose bottommost
			for codel in color_block:
				if codel.x == target_codel.x and codel.y > target_codel.y:
					target_codel = codel
		
		return target_codel + Vector2i(1, 0)

	elif dp_direction == DP_LEFT:
		# Find leftmost codel
		for codel in color_block:
			if codel.x <= target_codel.x:
				target_codel = codel
		
		if cc_direction == CC_LEFT:
			# Among leftmost, choose bottommost
			for codel in color_block:
				if codel.x == target_codel.x and codel.y > target_codel.y:
					target_codel = codel
		elif cc_direction == CC_RIGHT:
			# Among leftmost, choose topmost
			for codel in color_block:
				if codel.x == target_codel.x and codel.y < target_codel.y:
					target_codel = codel
		
		return target_codel + Vector2i(-1, 0)

	elif dp_direction == DP_UP:
		# Find topmost codel
		for codel in color_block:
			if codel.y <= target_codel.y:
				target_codel = codel
		
		if cc_direction == CC_LEFT:
			# Among topmost, choose leftmost
			for codel in color_block:
				if codel.y == target_codel.y and codel.x < target_codel.x:
					target_codel = codel
		elif cc_direction == CC_RIGHT:
			# Among topmost, choose rightmost
			for codel in color_block:
				if codel.y == target_codel.y and codel.x > target_codel.x:
					target_codel = codel
		
		return target_codel + Vector2i(0, -1)

	elif dp_direction == DP_DOWN:
		# Find bottommost codel
		for codel in color_block:
			if codel.y >= target_codel.y:
				target_codel = codel
		
		if cc_direction == CC_LEFT:
			# Among bottommost, choose rightmost
			for codel in color_block:
				if codel.y == target_codel.y and codel.x > target_codel.x:
					target_codel = codel
		elif cc_direction == CC_RIGHT:
			# Among bottommost, choose leftmost
			for codel in color_block:
				if codel.y == target_codel.y and codel.x < target_codel.x:
					target_codel = codel
		
		return target_codel + Vector2i(0, 1)
	
	return Vector2i(-1, -1) # Something went wrong


## Pops the top two values off the stack, adds them, and pushes the result back on the stack.
func piet_add() -> void:
	stack.push(stack.pop() + stack.pop())
	stack_updated.emit()


## Pops the top two values off the stack, calculates the second top value minus the top value, and pushes the result back on the stack.
func piet_substract() -> void:
	var top_value := stack.pop()
	var bottom_value := stack.pop()
	stack.push(bottom_value - top_value)
	stack_updated.emit()


## Pops the top two values off the stack, multiplies them, and pushes the result back on the stack.
func piet_multiply() -> void:
	stack.push(stack.pop() * stack.pop())
	stack_updated.emit()


## Pops the top two values off the stack, calculates the integer division of the second top value by the top value, and pushes the result back on the stack.
func piet_divide() -> void:
	var top_value := stack.pop()
	var bottom_value := stack.pop()
	if bottom_value == 0:
		return
	
	@warning_ignore("integer_division")
	stack.push(bottom_value / top_value)
	stack_updated.emit()


## Pops the top two values off the stack, calculates the second top value modulo the top value, and pushes the result back on the stack. The result has the same sign as the divisor (the top value).
func piet_mod() -> void:
	var top_value := stack.pop()
	var bottom_value := stack.pop()
	if top_value == 0:
		return
	var value: int = posmod(bottom_value, top_value) * sign(top_value)
	stack.push(value)
	stack_updated.emit()


##  Pops the top two values off the stack, and pushes 1 on to the stack if the second top value is greater than the top value, and pushes 0 if it is not greater.
func piet_greater() -> void:
	var top_value := stack.pop()
	var bottom_value := stack.pop()
	stack.push(bottom_value > top_value)


## Pushes the value of the colour block just exited on to the stack.
func piet_push(value: int) -> void:
	stack.push(value)
	stack_updated.emit()


## Pops the top value off the stack and toggles the CC that many times (the absolute value of that many times if negative).
func piet_switch() -> void:
	var value = stack.pop()
	cc_direction = (cc_direction + abs(value)) % 2


## Pops the top value off the stack and rotates the DP clockwise that many steps (anticlockwise if negative).
func piet_pointer() -> void:
	var value := stack.pop()
	dp_direction = posmod(dp_direction + value, 4)


## Pushes a copy of the top value on the stack on to the stack.
func piet_duplicate() -> void:
	var value := stack.pop()
	stack.push(value)
	stack.push(value)
	stack_updated.emit()


## Pops the top value off the stack and discards it.
func piet_pop() -> void:
	stack.pop()


## Pops the top two values off the stack and "rolls" the remaining stack entries to a depth equal to the second value popped, by a number of rolls equal to the first value popped. A single roll to depth n is defined as burying the top value on the stack n deep and bringing all values above it up by 1 place. A negative number of rolls rolls in the opposite direction.
func piet_roll() -> void:
	var roll_steps := stack.pop()
	var roll_depth := stack.pop()
	stack.roll(roll_depth, roll_steps)
	stack_updated.emit()


## Pops the top value off the stack and emits [signal char_outputed] with the value as single character string argument.
func piet_out_char() -> void:
	var char_string := char(stack.pop())
	outputed.emit(char_string)
	stack_updated.emit()


## Pops the top value off the stack and emits [signal outputed] with a string representation of the value as argument.
func piet_out_number() -> void:
	var number_string := str(stack.pop())
	outputed.emit(number_string)
	stack_updated.emit()


func _set_source_image(new_image: Image) -> void:
	source_image = new_image
	source_image_set.emit()
	state_updated.emit()


## Appends the current state to the history. 
func _increment_state_history() -> void:
	var state := InterpreterState.new()
	state.stack = stack.as_array()
	state.dp_position = dp_position
	state.dp_direction = dp_direction
	state.cc_direction = cc_direction
	state.last_executed_instruction = last_executed_instruction
	
	state_history.append(state)


## Loads a state from the state history and replaces the current one.
func load_from_state_history(step_index: int) -> void:
	var state := state_history[step_index]
	stack = Stack.new(state.stack)
	dp_direction = state.dp_direction
	dp_position = state.dp_position
	cc_direction = state.cc_direction
	last_executed_instruction = state.last_executed_instruction
	current_step = step_index
	stack_updated.emit()
	state_updated.emit()
	executed_instruction.emit(last_executed_instruction)
