class_name Stack
extends RefCounted

var _stack: PackedInt64Array


## Initializes an empty stack
func _init(source_array := PackedInt64Array()) -> void:
	_stack = source_array


## Removes the top element of the stack and returns it.
func pop() -> int:
	if _stack.is_empty():
		return 0
	var value := _stack[-1]
	_stack.remove_at(_stack.size() - 1)
	return value


## Adds an element to the stack.
func push(value: int) -> void:
	_stack.append(value)


## A single roll to depth n is defined as burying the top value on the stack n deep and bringing all values above it up by 1 place.
func roll(depth: int, steps: int) -> void:
	depth = mini(absi(depth), _stack.size())
	# Blunt, unoptimized, but literally the definition of the operation
	# Maybe incorrect?
	if steps > 0:
		for i in range(steps % depth):
			var value := pop()
			_stack.insert(_stack.size() - depth - 1, value)
	if steps < 0:
		for i in range(abs(steps) % depth):
			var value := _stack[_stack.size() - depth - 1]
			_stack.remove_at(_stack.size() - depth - 1)
			_stack.append(value)


## Returns a copy of the stack as an array.
func as_array() -> PackedInt64Array:
	return _stack.duplicate()
