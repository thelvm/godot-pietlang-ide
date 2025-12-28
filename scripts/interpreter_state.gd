class_name InterpreterState
extends RefCounted
## Stores an instataneous state of the interpreter. Used to debug and rewind.

var stack := PackedInt64Array()

var dp_direction: int
var dp_position := Vector2i.ZERO

var cc_direction: int

var last_executed_instruction: StringName = &"noop"
