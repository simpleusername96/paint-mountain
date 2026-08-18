class_name BallToken
extends RefCounted

var _kind: int
var _channel: int

var kind: int:
	get:
		return _kind

var channel: int:
	get:
		return _channel


func _init(token_kind: int = BallKind.Value.STANDARD, token_channel: int = PaintChannel.Value.RED) -> void:
	_kind = token_kind
	_channel = token_channel


func is_valid() -> bool:
	return BallKind.is_valid(_kind) and PaintChannel.is_valid(_channel)


func stable_key() -> StringName:
	if not is_valid():
		return &""
	return StringName("%s_%s" % [
		BallKind.stable_id(_kind),
		PaintChannel.stable_id(_channel),
	])


func matches(other: BallToken) -> bool:
	return other != null and _kind == other.kind and _channel == other.channel
