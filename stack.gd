class_name Stack
extends RefCounted

var _stack: PackedInt64Array


## Initializes an empty stack
func _init() -> void:
	_stack = PackedInt64Array()


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


func as_array() -> PackedInt64Array:
	return _stack.duplicate()
