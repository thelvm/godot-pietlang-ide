class_name StackValueUi
extends Control

var value: int: set = _set_value

@onready var int_value_label: Label = %IntValueLabel
@onready var ascii_value_label: Label = %ASCIIValueLabel
@onready var hex_value_label: Label = %HexValueLabel


func _ready() -> void:
	_set_label_values()


func _set_value(new_value: int) -> void:
	value = new_value
	_set_label_values()


func _set_label_values() -> void:
	if int_value_label:
		int_value_label.text = str(value)
	if ascii_value_label:
		ascii_value_label.text = char(value)
	if hex_value_label:
		hex_value_label.text = "%X" % value
