class_name WindController
extends Node

signal snapshot_changed(snapshot: WindSnapshot)
signal strong_episode_started(episode_id: int, snapshot: WindSnapshot)

const FNV_OFFSET_BASIS: int = 2166136261
const FNV_PRIME: int = 16777619

var _profile: WindProfile
var _schedule_seed: int = 0
var _elapsed_ticks: int = 0
var _running: bool = false
var _strong_episode_id: int = 0
var _was_strong: bool = false
var _snapshot: WindSnapshot


func configure(profile: WindProfile, schedule_seed: int) -> bool:
	if profile == null or not profile.is_valid():
		return false
	_profile = profile
	_schedule_seed = schedule_seed
	reset()
	return true


func reset() -> void:
	_elapsed_ticks = 0
	_running = false
	_strong_episode_id = 0
	_was_strong = false
	_snapshot = sample_for_tick(_profile, _schedule_seed, 0) if _profile != null else null
	_update_strong_state()
	if _snapshot != null:
		snapshot_changed.emit(_snapshot)


func start() -> void:
	if _profile != null:
		_running = true


func stop() -> void:
	_running = false


func is_running() -> bool:
	return _running


func elapsed_ticks() -> int:
	return _elapsed_ticks


func current_snapshot() -> WindSnapshot:
	return _snapshot


func schedule_identity() -> StringName:
	return _schedule_identity(_profile, _schedule_seed)


func sample_at_tick(physics_tick: int) -> WindSnapshot:
	return sample_for_tick(_profile, _schedule_seed, physics_tick)


func sample_at_offset(offset_ticks: int) -> WindSnapshot:
	return sample_at_tick(_elapsed_ticks + maxi(0, offset_ticks))


## Stable intervals reuse one prediction. Any horizon that contains a wind
## change advances in small fixed buckets so Fire never performs the query.
func prediction_epoch(maximum_steps: int, changing_bucket_ticks: int = 3) -> int:
	return prediction_epoch_for(
		_profile,
		_schedule_seed,
		_elapsed_ticks,
		maximum_steps,
		changing_bucket_ticks
	)


func _physics_process(_delta: float) -> void:
	if not _running or _profile == null:
		return
	_elapsed_ticks += 1
	_snapshot = sample_for_tick(_profile, _schedule_seed, _elapsed_ticks)
	_update_strong_state()
	snapshot_changed.emit(_snapshot)


func _update_strong_state() -> void:
	if _snapshot == null or _profile == null:
		return
	_snapshot.strong = _snapshot.normalized_strength >= _profile.strong_wind_threshold
	if _snapshot.strong and not _was_strong:
		_strong_episode_id += 1
		_snapshot.strong_episode_id = _strong_episode_id
		strong_episode_started.emit(_strong_episode_id, _snapshot)
	else:
		_snapshot.strong_episode_id = _strong_episode_id
	_was_strong = _snapshot.strong


static func sample_for_tick(
		profile: WindProfile,
		schedule_seed: int,
		physics_tick: int,
		physics_ticks_per_second: int = 60
) -> WindSnapshot:
	if profile == null or not profile.is_valid():
		return null
	var safe_tick := maxi(0, physics_tick)
	var interval_ticks := profile.interval_ticks(physics_ticks_per_second)
	var transition_ticks := profile.transition_ticks(physics_ticks_per_second)
	var keyframe_index := safe_tick / interval_ticks
	var local_tick := safe_tick % interval_ticks
	var current_target := _keyframe_acceleration(profile, schedule_seed, keyframe_index)
	var next_target := _keyframe_acceleration(profile, schedule_seed, keyframe_index + 1)
	var transition_progress := 0.0
	var acceleration := current_target
	if transition_ticks > 0 and local_tick >= interval_ticks - transition_ticks:
		transition_progress = float(local_tick - (interval_ticks - transition_ticks)) \
				/ float(transition_ticks)
		transition_progress = smoothstep(0.0, 1.0, transition_progress)
		acceleration = current_target.lerp(next_target, transition_progress)
	var maximum := maxf(profile.maximum_acceleration, 0.000001)
	return WindSnapshot.new(
		safe_tick,
		acceleration,
		next_target,
		clampf(acceleration.length() / maximum, 0.0, 1.0),
		clampf(next_target.length() / maximum, 0.0, 1.0),
		float(interval_ticks - local_tick) / float(maxi(1, physics_ticks_per_second)),
		transition_progress,
		_schedule_identity(profile, schedule_seed)
	)


## Builds a fixed horizon with one profile validation and cached keyframes.
## Ballistic solvers use this instead of rebuilding a WindSnapshot per step.
static func acceleration_range(
		profile: WindProfile,
		schedule_seed: int,
		start_tick: int,
		count: int,
		physics_ticks_per_second: int = 60
) -> PackedVector3Array:
	var result := PackedVector3Array()
	if profile == null or not profile.is_valid() or count <= 0:
		return result
	result.resize(count)
	var interval_ticks := profile.interval_ticks(physics_ticks_per_second)
	var transition_ticks := profile.transition_ticks(physics_ticks_per_second)
	var cached_keyframe_index := -1
	var current_target := Vector3.ZERO
	var next_target := Vector3.ZERO
	for offset in range(count):
		var safe_tick := maxi(start_tick + offset, 0)
		var keyframe_index := safe_tick / interval_ticks
		if keyframe_index != cached_keyframe_index:
			cached_keyframe_index = keyframe_index
			current_target = _keyframe_acceleration(
				profile, schedule_seed, keyframe_index
			)
			next_target = _keyframe_acceleration(
				profile, schedule_seed, keyframe_index + 1
			)
		var local_tick := safe_tick % interval_ticks
		var acceleration := current_target
		if (
			transition_ticks > 0
			and local_tick >= interval_ticks - transition_ticks
		):
			var progress := (
				float(local_tick - (interval_ticks - transition_ticks))
				/ float(transition_ticks)
			)
			acceleration = current_target.lerp(
				next_target, smoothstep(0.0, 1.0, progress)
			)
		result[offset] = acceleration
	return result


static func prediction_epoch_for(
		profile: WindProfile,
		schedule_seed: int,
		elapsed_ticks: int,
		maximum_steps: int,
		changing_bucket_ticks: int = 3,
		physics_ticks_per_second: int = 60
) -> int:
	var safe_tick := maxi(elapsed_ticks, 0)
	var bucket_ticks := maxi(changing_bucket_ticks, 1)
	if profile == null or not profile.is_valid() or maximum_steps < 0:
		return safe_tick / bucket_ticks
	if _acceleration_is_constant_through(
		profile,
		schedule_seed,
		safe_tick,
		safe_tick + maximum_steps,
		physics_ticks_per_second
	):
		return -1 - safe_tick / profile.interval_ticks(physics_ticks_per_second)
	return safe_tick / bucket_ticks


static func _acceleration_is_constant_through(
		profile: WindProfile,
		schedule_seed: int,
		start_tick: int,
		end_tick: int,
		physics_ticks_per_second: int
) -> bool:
	var interval_ticks := profile.interval_ticks(physics_ticks_per_second)
	var transition_ticks := profile.transition_ticks(physics_ticks_per_second)
	var reference := _acceleration_for_tick(
		profile,
		schedule_seed,
		start_tick,
		physics_ticks_per_second
	)
	var first_keyframe := start_tick / interval_ticks
	var last_keyframe := end_tick / interval_ticks
	for keyframe_index in range(first_keyframe, last_keyframe + 1):
		var boundary_tick := (keyframe_index + 1) * interval_ticks
		var transition_start := boundary_tick - transition_ticks
		if transition_ticks > 0 and _candidate_acceleration_differs(
			profile,
			schedule_seed,
			transition_start + 1,
			start_tick,
			end_tick,
			physics_ticks_per_second,
			reference
		):
			return false
		if _candidate_acceleration_differs(
			profile,
			schedule_seed,
			boundary_tick - 1,
			start_tick,
			end_tick,
			physics_ticks_per_second,
			reference
		):
			return false
		if _candidate_acceleration_differs(
			profile,
			schedule_seed,
			boundary_tick,
			start_tick,
			end_tick,
			physics_ticks_per_second,
			reference
		):
			return false
	return _acceleration_for_tick(
		profile,
		schedule_seed,
		end_tick,
		physics_ticks_per_second
	).is_equal_approx(reference)


static func _candidate_acceleration_differs(
		profile: WindProfile,
		schedule_seed: int,
		candidate_tick: int,
		start_tick: int,
		end_tick: int,
		physics_ticks_per_second: int,
		reference: Vector3
) -> bool:
	if candidate_tick < start_tick or candidate_tick > end_tick:
		return false
	return not _acceleration_for_tick(
		profile,
		schedule_seed,
		candidate_tick,
		physics_ticks_per_second
	).is_equal_approx(reference)


static func _acceleration_for_tick(
		profile: WindProfile,
		schedule_seed: int,
		physics_tick: int,
		physics_ticks_per_second: int
) -> Vector3:
	var safe_tick := maxi(physics_tick, 0)
	var interval_ticks := profile.interval_ticks(physics_ticks_per_second)
	var transition_ticks := profile.transition_ticks(physics_ticks_per_second)
	var keyframe_index := safe_tick / interval_ticks
	var local_tick := safe_tick % interval_ticks
	var current_target := _keyframe_acceleration(profile, schedule_seed, keyframe_index)
	if transition_ticks <= 0 or local_tick < interval_ticks - transition_ticks:
		return current_target
	var next_target := _keyframe_acceleration(profile, schedule_seed, keyframe_index + 1)
	var progress := float(local_tick - (interval_ticks - transition_ticks)) \
			/ float(transition_ticks)
	return current_target.lerp(next_target, smoothstep(0.0, 1.0, progress))


static func _keyframe_acceleration(
		profile: WindProfile,
		schedule_seed: int,
		keyframe_index: int
) -> Vector3:
	var direction_unit := _sample_unit(schedule_seed, keyframe_index, &"direction")
	var strength_unit := _sample_unit(schedule_seed, keyframe_index, &"strength")
	var angle := direction_unit * TAU
	var strength := lerpf(profile.minimum_strength, profile.maximum_strength, strength_unit)
	return Vector3(sin(angle), 0.0, -cos(angle)) \
			* profile.maximum_acceleration * strength


static func _sample_unit(schedule_seed: int, keyframe_index: int, field: StringName) -> float:
	var key := "paint_mountain:wind:v1:%d:%d:%s" % [
		schedule_seed,
		keyframe_index,
		String(field),
	]
	return float(_fnv1a32(key) & 0x7fffffff) / 2147483647.0


static func _schedule_identity(profile: WindProfile, schedule_seed: int) -> StringName:
	if profile == null:
		return &""
	return StringName("wind-v%d-%d" % [profile.schedule_version, schedule_seed])


static func _fnv1a32(value: String) -> int:
	var result: int = FNV_OFFSET_BASIS
	for byte in value.to_utf8_buffer():
		result = (result ^ byte) & 0xffffffff
		result = (result * FNV_PRIME) & 0xffffffff
	return result
