extends Node

const MIX_RATE := 22050
const SFX_POOL_SIZE := 6

var _music: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0
var _audio_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audio_enabled = DisplayServer.get_name() != "headless"
	if not _audio_enabled:
		return
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.bus = &"Music"
	_music.stream = _music_stream()
	_music.volume_db = -11.0
	add_child(_music)
	for index in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "Sfx%02d" % (index + 1)
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)
	_apply_saved_volumes()
	_music.play()


func _exit_tree() -> void:
	if _music != null:
		_music.stop()
		_music.stream = null
	for player in _sfx_players:
		player.stop()
		player.stream = null
	_sfx_players.clear()


func play_cue(cue: StringName) -> void:
	if not _audio_enabled or _sfx_players.is_empty():
		return
	var frequencies := Vector2(360.0, 480.0)
	var duration := 0.12
	var volume := -10.0
	match cue:
		&"ui":
			frequencies = Vector2(520.0, 660.0)
			duration = 0.075
			volume = -15.0
		&"fire":
			frequencies = Vector2(150.0, 72.0)
			duration = 0.24
			volume = -6.0
		&"impact":
			frequencies = Vector2(110.0, 58.0)
			duration = 0.2
			volume = -8.0
		&"mechanism":
			frequencies = Vector2(420.0, 820.0)
			duration = 0.28
			volume = -7.0
		&"clear":
			frequencies = Vector2(440.0, 880.0)
			duration = 0.5
			volume = -6.0
		&"fail":
			frequencies = Vector2(240.0, 120.0)
			duration = 0.42
			volume = -9.0
	var player := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	player.stop()
	player.stream = _tone_stream(frequencies.x, frequencies.y, duration)
	player.volume_db = volume
	player.play()


func _apply_saved_volumes() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return
	for entry in [["Master", "master_volume"], ["Music", "music_volume"], ["SFX", "sfx_volume"]]:
		var bus_index := AudioServer.get_bus_index(entry[0])
		if bus_index < 0:
			continue
		var normalized := float(game_state.settings.get(entry[1], 1.0))
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(normalized, 0.001)))
		AudioServer.set_bus_mute(bus_index, normalized <= 0.001)


func _music_stream() -> AudioStreamWAV:
	var duration := 4.0
	var sample_count := roundi(float(MIX_RATE) * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var chord := PackedFloat32Array([110.0, 164.81, 220.0])
	for index in range(sample_count):
		var time := float(index) / float(MIX_RATE)
		var phrase := 0.74 + 0.26 * sin(TAU * time / duration)
		var sample := 0.0
		for frequency in chord:
			sample += sin(TAU * frequency * time) / float(chord.size())
		sample *= 0.085 * phrase
		data.encode_s16(index * 2, roundi(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


func _tone_stream(start_frequency: float, end_frequency: float, duration: float) -> AudioStreamWAV:
	var sample_count := maxi(1, roundi(float(MIX_RATE) * duration))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0
	for index in range(sample_count):
		var progress := float(index) / float(sample_count - 1)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / float(MIX_RATE)
		var envelope := pow(1.0 - progress, 1.7) * minf(1.0, progress * 24.0)
		var sample := (sin(phase) + 0.22 * sin(phase * 2.03)) * 0.36 * envelope
		data.encode_s16(index * 2, roundi(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
