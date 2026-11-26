extends Node

const MIX_RATE: int = 22050
const POOL_SIZE: int = 12

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_idx: int = 0
var muted: bool = false
var sfx_volume: float = 0.85


func _ready() -> void:
	for i: int in range(POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_players.append(p)
	_generate_sfx()


func play(sfx_name: String, vol_db: float = -8.0, pitch_jitter: float = 0.06) -> void:
	if muted or sfx_volume <= 0.01 or not _streams.has(sfx_name):
		return
	var p: AudioStreamPlayer = _players[_next_idx]
	_next_idx = (_next_idx + 1) % POOL_SIZE
	p.stream = _streams[sfx_name]
	p.volume_db = vol_db + linear_to_db(sfx_volume)
	p.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	p.play()


func _generate_sfx() -> void:
	_streams["shoot"] = _synth_tone(0.065, 880.0, 260.0, 0, 0.45)
	_streams["laser"] = _synth_tone(0.085, 1320.0, 520.0, 0, 0.42)
	_streams["missile"] = _synth_tone(0.12, 240.0, 110.0, 2, 0.5)
	_streams["hit"] = _synth_tone(0.045, 220.0, 90.0, 2, 0.5)
	_streams["explode"] = _synth_tone(0.22, 180.0, 42.0, 2, 0.7)
	_streams["big_explode"] = _synth_tone(0.55, 130.0, 28.0, 2, 0.85)
	_streams["player_hit"] = _synth_tone(0.28, 320.0, 65.0, 2, 0.8)
	_streams["shield_hit"] = _synth_tone(0.14, 620.0, 980.0, 1, 0.6)
	_streams["scrap"] = _synth_arpeggio([660.0, 990.0], 0.04, 0.45)
	_streams["powerup"] = _synth_arpeggio([440.0, 554.0, 659.0, 880.0], 0.055, 0.55)
	_streams["ui"] = _synth_arpeggio([520.0, 780.0], 0.035, 0.4)
	_streams["boss_siren"] = _synth_tone(0.28, 390.0, 780.0, 0, 0.50)
	_streams["boss_beam"] = _synth_tone(0.24, 1520.0, 310.0, 0, 0.52)
	_streams["boss_pose"] = _synth_arpeggio([220.0, 277.2, 330.0, 440.0, 659.3], 0.045, 0.56)
	_streams["boss_hp_tick"] = _synth_tone(0.028, 988.0, 1175.0, 0, 0.42)
	_streams["xp"] = _synth_tone(0.032, 740.0, 1180.0, 1, 0.36)
	_streams["level_up"] = _synth_arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.052, 0.56)
	_streams["zap"] = _synth_tone(0.075, 1650.0, 280.0, 2, 0.44)
	_streams["bounce"] = _synth_tone(0.035, 1120.0, 1560.0, 1, 0.34)
	_streams["meow"] = _synth_tone(0.095, 590.0, 940.0, 1, 0.36)
	_streams["unlock_ship"] = _synth_arpeggio([440.0, 554.37, 659.25, 880.0, 1108.7, 1318.5], 0.055, 0.58)


# wave_type: 0 = pulse/square, 1 = triangle, 2 = crunchy 16-bit noise+pulse
func _synth_tone(duration: float, f_start: float, f_end: float, wave_type: int, amp: float) -> AudioStreamWAV:
	var count: int = maxi(1, int(duration * float(MIX_RATE)))
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)
	var phase: float = 0.0
	var noise_hold: float = 0.0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(f_start * 100.0 + duration * 1000.0)

	for i: int in range(count):
		var t: float = float(i) / float(count)
		var freq: float = lerpf(f_start, f_end, pow(t, 0.75))
		phase += freq / float(MIX_RATE)
		var env: float = pow(1.0 - t, 1.35)
		var sample: float = 0.0
		var frac: float = phase - floorf(phase)
		if wave_type == 0:
			sample = 1.0 if frac < 0.35 else -1.0
		elif wave_type == 1:
			sample = 4.0 * absf(frac - 0.5) - 1.0
		else:
			if i % maxi(1, int(lerpf(3.0, 14.0, t))) == 0:
				noise_hold = rng.randf_range(-1.0, 1.0)
			var sq: float = 1.0 if frac < 0.5 else -1.0
			sample = noise_hold * 0.75 + sq * 0.25

		var pcm: int = clampi(int(sample * env * amp * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, pcm)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	return wav


func _synth_arpeggio(notes: Array[float], note_len: float, amp: float) -> AudioStreamWAV:
	var per_note: int = maxi(1, int(note_len * float(MIX_RATE)))
	var total: int = per_note * notes.size()
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total * 2)
	var phase: float = 0.0

	for n_idx: int in range(notes.size()):
		var freq: float = notes[n_idx]
		for j: int in range(per_note):
			var i: int = n_idx * per_note + j
			var local_t: float = float(j) / float(per_note)
			phase += freq / float(MIX_RATE)
			var frac: float = phase - floorf(phase)
			var sq: float = 1.0 if frac < 0.25 else -1.0
			var env: float = (1.0 - local_t * 0.65)
			var pcm: int = clampi(int(sq * env * amp * 32767.0), -32768, 32767)
			bytes.encode_s16(i * 2, pcm)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	return wav
