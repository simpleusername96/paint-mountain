class_name QueueRail
extends VBoxContainer

@onready var _now = %NowToken
@onready var _next_one = %NextOne
@onready var _next_two = %NextTwo

func configure(tokens: Array[BallToken]) -> void:
	_now.configure(tokens[0] if tokens.size() > 0 else null, true)
	_next_one.configure(tokens[1] if tokens.size() > 1 else null)
	_next_two.configure(tokens[2] if tokens.size() > 2 else null)
