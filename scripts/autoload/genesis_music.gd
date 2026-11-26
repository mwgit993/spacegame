extends Node

# Multi-Ensemble 44.1 kHz Stereo Soundtrack Engine.
# Each stage is scored for its environment. Besides its own instruments, every stage has
# its own tempo, groove (meter + swing), mode, chord voicing, lead register and acoustic
# space (echo time, echo feedback, master filter):
#   Stage 1 (Outer Orbit):     118 BPM  A Aeolian   straight 4/4   80s synthwave: dual-saw bass, Juno pad, gated snare
#   Stage 2 (Starcruiser):     124 BPM  D Dorian    swung funk     FM slap bass, clavinet stabs, m7 chords, dry slapback room
#   Stage 3 (Cloud Base):      116 BPM  F Lydian    3/4 waltz      harp arpeggios, airy organ maj7 chords, long soaring flute
#   Stage 4 (Xeno Forest):     100 BPM  G Dorian    heavy shuffle  marimba, congas & shakers, pentatonic pan-flute call & response
#   Stage 5 (Cryo Glacier):     80 BPM  E Aeolian   half-time      open quartal choir, high music box, swelling glass lead, long icy echo
#   Stage 6 (Magma Core):      152 BPM  C Phrygian  driving 16ths  acid chug bass on the b2, power chords, double kick, war toms
#   Stage 7 (Abyssal Trench):   76 BPM  B Aeolian   swung dub      Rhodes, sonar pings, deep dub echo, muffled underwater filter
#   Stage 8 (Cyber Nexus):     142 BPM  F# Aeolian  four-on-floor  trance: pumping bass, gated hypersaws, bit-crushed digital lead
# Plus 1 universal "Neon Medusa" dark synthwave boss theme.
# All notes come from 7-note diatonic modes, so there are no accidentals.

enum Mode { NONE, TITLE, STAGE, BOSS, HYPERSPACE }

const MIX_RATE: float = 44100.0
const DELAY_MAX: int = 66200 # 1.5 s, room for the glacier's long echo

const SCALE_MINOR: Array[int] = [0, 2, 3, 5, 7, 8, 10]
const SCALE_DORIAN: Array[int] = [0, 2, 3, 5, 7, 9, 10]
const SCALE_MAJOR: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const SCALE_LYDIAN: Array[int] = [0, 2, 4, 6, 7, 9, 11]
const SCALE_PHRYGIAN: Array[int] = [0, 1, 3, 5, 7, 8, 10]

# Per-song arrangement settings. A song dictionary may override any of these;
# the title and hyperspace jingles always use the defaults.
const SONG_DEFAULTS: Dictionary = {
	"bar_steps": 16,          # 16ths per bar: 16 = 4/4, 12 = 3/4
	"swing": 0.0,             # 0 = straight; 0.2 = heavy shuffle (even 16ths 20% longer, odd 20% shorter)
	"voicing": [0, 4, 7, 9],  # pad chord tones, as scale-degree offsets from the chord root
	"lead_oct": 24,           # lead register, in semitones above the song root
	"lead_attack": 165.0,     # lead envelope attack rate (higher = sharper)
	"lead_decay": 1.65,       # lead envelope decay rate (lower = longer notes)
	"harm_int": -2,           # harmony line, in scale degrees relative to the lead
	"delay_beats": 0.75,      # echo time in beats
	"delay_fb": 0.34,         # echo feedback
	"master_lp": 1.0,         # one-pole low-pass coefficient on the whole mix; 1.0 = bypass
	"crush": 1,               # lead sample-and-hold length in samples (bit-crush); 1 = off
}

var current_mode: Mode = Mode.NONE
var current_stage_idx: int = 0
var music_volume: float = 0.80
var paused_duck: bool = false

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback

var _sample_in_step: float = 0.0
var _step: int = 0

# Current song and its arrangement settings, cached by _load_song_params() so the
# per-sample code never does dictionary lookups.
var _song: Dictionary = {}
var _style: int = 0
var _bar_steps: int = 16
var _swing: float = 0.0
var _voicing: Array = [0, 4, 7, 9]
var _lead_oct: int = 24
var _lead_attack: float = 165.0
var _lead_decay: float = 1.65
var _harm_int: int = -2
var _delay_fb: float = 0.34
var _master_lp: float = 1.0
var _master_lp_l: float = 0.0
var _master_lp_r: float = 0.0
var _crush: int = 1
var _crush_count: int = 0
var _crush_hold: float = 0.0

# Bass state
var _bass_p1: float = 0.0
var _bass_p2: float = 0.0
var _bass_sub_p: float = 0.0
var _bass_freq: float = 55.0
var _bass_env: float = 0.0
var _bass_atk: float = 0.0
var _bass_lp1: float = 0.0
var _bass_lp2: float = 0.0

# 4-voice chord bed / stabs / Rhodes / Choir state
var _pad_freqs: Array[float] = [110.0, 165.0, 220.0, 261.6]
var _pad_target_freqs: Array[float] = [110.0, 165.0, 220.0, 261.6]
var _pad_phases_a: Array[float] = [0.0, 0.21, 0.47, 0.73]
var _pad_phases_b: Array[float] = [0.11, 0.35, 0.62, 0.89]
var _pad_lp_l: float = 0.0
var _pad_lp_r: float = 0.0
var _pad_swell: float = 0.0
var _stab_env: float = 0.0

# Pluck / Marimba / Ice-Bell / Sonar Arp state
var _arp_p: float = 0.0
var _arp_m_p: float = 0.0
var _arp_freq: float = 220.0
var _arp_env: float = 0.0
var _arp_atk: float = 0.0
var _arp_lp: float = 0.0

# Lead & Diatonic Harmony state
var _lead_p1: float = 0.0
var _lead_p2: float = 0.0
var _lead_freq: float = 440.0
var _lead_target_freq: float = 440.0
var _lead_env: float = 0.0
var _lead_atk: float = 0.0
var _lead_lp: float = 0.0

var _harm_p: float = 0.0
var _harm_freq: float = 330.0
var _harm_target_freq: float = 330.0
var _harm_env: float = 0.0
var _harm_atk: float = 0.0
var _lfo_phase: float = 0.0
var _hyper_sweep: float = 0.0

# Multi-Kit Percussion States (Kick, Gated Snare, Tight Snare/Rim, Conga/Taiko Tom, Shaker/Hat)
var _kick_env: float = 0.0
var _kick_phase: float = 0.0
var _sidechain: float = 1.0

var _snare_body_env: float = 0.0
var _snare_gate_time: float = 0.0
var _snare_phase: float = 0.0
var _snare_lp_l: float = 0.0
var _snare_lp_r: float = 0.0
var _rim_env: float = 0.0
var _rim_phase: float = 0.0

var _tom_env: float = 0.0
var _tom_freq: float = 140.0
var _tom_phase: float = 0.0

var _hat_env: float = 0.0
var _hat_decay: float = 34.0
var _prev_noise: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Stereo delay buffer
var _delay_l: PackedFloat32Array = PackedFloat32Array()
var _delay_r: PackedFloat32Array = PackedFloat32Array()
var _delay_pos: int = 0
var _delay_len: int = 16000
var _delay_wet: float = 0.32

# =========================================================================================
# 8 DISTINCT STAGE COMPOSITIONS + INSTRUMENT ENSEMBLE PRESETS ("style" 0..7)
# =========================================================================================
const STAGE_SONGS: Array[Dictionary] = [
	# 0: OUTER ORBIT - Lush 80s Midnight Synthwave (118 BPM, A Minor)
	{
		"style": 0, "root": 45, "bpm": 118.0, "scale": SCALE_MINOR, "delay_wet": 0.32,
		"prog_a": [0, -2, 2, -1,  0, -2, 2, 4],
		"prog_b": [-2, -1, 4, 0,  -2, -1, 2, 4],
		"mel_a": [
			4,-99,-99,5, 4,-99,2,-99,  0,-99,-99,2, 3,-99,2,-99,
			2,-99,-99,4, 6,-99,4,-99,  4,-99,3,2,   1,-99,-99,-99,
			4,-99,-99,7, 6,-99,4,-99,  5,-99,-99,4, 2,-99,0,-99,
			2,-99,3,4,   6,-99,5,4,    4,-99,-99,-99,-99,-99,-99,-99,
		],
		"mel_b": [
			7,-99,-99,6, 4,-99,7,-99,  6,-99,-99,4, 2,-99,4,-99,
			5,-99,6,7,   9,-99,7,6,    7,-99,-99,-99,6,-99,4,-99,
			7,-99,-99,9, 10,-99,9,7,   6,-99,-99,7, 9,-99,7,-99,
			6,-99,5,4,   6,-99,7,-99,  7,-99,-99,-99,-99,-99,-99,-99,
		],
	},
	# 1: STARCRUISER - Swung Slap-FM Funk & Clavinet Stabs in a dry metal hull (124 BPM, D Dorian)
	{
		"style": 1, "root": 38, "bpm": 124.0, "scale": SCALE_DORIAN, "delay_wet": 0.16,
		"swing": 0.10, "voicing": [0, 2, 4, 6], "delay_beats": 0.25, "delay_fb": 0.22,
		"prog_a": [0, 0, 3, 2,  0, 0, -1, 3],
		"prog_b": [2, 3, 0, -1, 2, 3, 4, 4],
		"mel_a": [
			0,-99,2,0,   4,-99,-99,3,  2,0,-99,2,   3,-99,-99,-99,
			0,-99,2,0,   6,-99,5,4,    3,-99,2,0,   -99,-99,-99,-99,
			4,-99,6,4,   7,-99,-99,6,  5,4,-99,2,   4,-99,-99,-99,
			3,4,5,-99,   6,-99,5,3,    4,-99,-99,-99,-99,-99,-99,-99,
		],
		"mel_b": [
			7,-99,7,-99, 9,7,5,-99,    6,-99,6,-99, 7,6,4,-99,
			5,-99,7,9,   7,-99,4,-99,  5,-99,4,2,   3,-99,-99,-99,
			7,-99,9,7,   11,-99,9,7,   6,-99,7,9,   7,-99,4,-99,
			5,6,7,9,     8,-99,7,5,    7,-99,-99,-99,-99,-99,-99,-99,
		],
	},
	# 2: CLOUD BASE - Floating 3/4 Sky Waltz: Harp Arpeggios, Organ maj7 Chords & Soaring Flute (116 BPM, F Lydian)
	# Bars are 12 sixteenths (3 beats), so the melodies are 48 steps (4 bars) long.
	{
		"style": 2, "root": 41, "bpm": 116.0, "scale": SCALE_LYDIAN, "delay_wet": 0.34,
		"bar_steps": 12, "voicing": [0, 2, 4, 6], "lead_decay": 0.9, "delay_beats": 1.0, "delay_fb": 0.38,
		"prog_a": [0, 1, 0, 1,  5, 4, 1, 1],
		"prog_b": [5, 4, 1, 0,  6, 5, 1, 4],
		"mel_a": [
			4,-99,-99,-99, -99,-99,-99,-99, 5,-99,6,-99,
			7,-99,-99,-99, -99,-99,6,-99,   4,-99,-99,-99,
			5,-99,-99,-99, 3,-99,2,-99,     1,-99,-99,-99,
			2,-99,-99,-99, -99,-99,-99,-99, -99,-99,-99,-99,
		],
		"mel_b": [
			9,-99,-99,-99, 10,-99,9,-99,    7,-99,-99,-99,
			6,-99,-99,-99, 7,-99,8,-99,     9,-99,-99,-99,
			11,-99,-99,-99, 10,-99,9,-99,   7,-99,6,-99,
			7,-99,-99,-99, -99,-99,-99,-99, -99,-99,-99,-99,
		],
	},
	# 3: XENO FOREST - Shuffling Tribal Marimba, Congas & Pentatonic Pan-Flute Call-and-Response (100 BPM, G Dorian)
	{
		"style": 3, "root": 43, "bpm": 100.0, "scale": SCALE_DORIAN, "delay_wet": 0.38,
		"swing": 0.22, "voicing": [0, 2, 4, 7], "lead_attack": 95.0, "delay_beats": 0.5, "delay_fb": 0.42,
		"prog_a": [0, 3, 0, 3,  2, 3, 0, 4],
		"prog_b": [2, 3, 4, 0,  2, 3, 4, 6],
		# Melodies stay on the minor pentatonic degrees (0, 2, 3, 4, 6) and leave gaps for the "answer".
		"mel_a": [
			4,-99,-99,6,   -99,-99,4,-99, 3,-99,2,-99,  0,-99,-99,-99,
			-99,-99,-99,-99, 2,-99,3,-99, 4,-99,-99,-99, -99,-99,-99,-99,
			7,-99,-99,6,   -99,-99,4,-99, 6,-99,4,-99,  3,-99,-99,-99,
			2,-99,3,-99,   2,-99,0,-99,   0,-99,-99,-99, -99,-99,-99,-99,
		],
		"mel_b": [
			9,-99,-99,7,   -99,-99,9,-99, 10,-99,9,-99, 7,-99,-99,-99,
			-99,-99,6,-99, 7,-99,9,-99,   7,-99,-99,-99, -99,-99,-99,-99,
			11,-99,-99,10, -99,-99,9,-99, 7,-99,9,-99,  6,-99,-99,-99,
			7,-99,6,-99,   4,-99,3,-99,   4,-99,-99,-99, -99,-99,-99,-99,
		],
	},
	# 4: CRYO GLACIER - Half-Time Frozen Music-Box, Open Quartal Choir & Swelling Glass Lead (80 BPM, E Minor)
	{
		"style": 4, "root": 40, "bpm": 80.0, "scale": SCALE_MINOR, "delay_wet": 0.50,
		"voicing": [0, 4, 8, 11], "lead_attack": 7.0, "lead_decay": 0.75, "delay_beats": 1.5, "delay_fb": 0.50,
		"prog_a": [0, 2, 5, 4,  0, 2, 3, 4],
		"prog_b": [-2, -1, 0, 2, -2, 3, 4, 4],
		"mel_a": [
			7,-99,-99,-99,6,-99,4,-99, 2,-99,-99,-99,4,-99,-99,-99,
			6,-99,-99,-99,5,-99,3,-99, 1,-99,-99,-99,-99,-99,-99,-99,
			7,-99,-99,-99,9,-99,11,-99,9,-99,-99,-99,7,-99,4,-99,
			5,-99,-99,6,  7,-99,6,4,   4,-99,-99,-99,-99,-99,-99,-99,
		],
		"mel_b": [
			9,-99,-99,-99,7,-99,9,-99, 11,-99,-99,-99,7,-99,-99,-99,
			8,-99,-99,7,  6,-99,7,8,   7,-99,-99,-99,-99,-99,-99,-99,
			11,-99,-99,9, 7,-99,6,-99, 5,-99,7,9,    7,-99,4,-99,
			5,-99,6,7,    8,-99,7,6,   7,-99,-99,-99,-99,-99,-99,-99,
		],
	},
	# 5: MAGMA CORE - Driving Phrygian Metal: Acid Chug Bass, Power Chords, Overdriven Guitar & War Toms (152 BPM, C Phrygian)
	# Chord degree 1 is the Phrygian bII (Db) and -2 is bVI (Ab); avoid degree 4, whose fifth is a tritone.
	{
		"style": 5, "root": 36, "bpm": 152.0, "scale": SCALE_PHRYGIAN, "delay_wet": 0.14,
		"voicing": [0, 4, 7, 11], "delay_beats": 0.25, "delay_fb": 0.20,
		"prog_a": [0, 0, 1, 0,  0, 0, -2, 1],
		"prog_b": [-2, -1, 0, 0, -2, -1, 1, 1],
		"mel_a": [
			0,0,2,-99,   4,-99,3,2,    0,-99,6,-99, 5,-99,4,-99,
			0,0,2,-99,   7,-99,6,4,    3,-99,2,1,   0,-99,-99,-99,
			4,4,5,-99,   7,-99,6,4,    5,-99,7,-99, 9,-99,7,-99,
			8,-99,7,5,   4,-99,3,2,    4,-99,-99,-99,-99,-99,-99,-99,
		],
		"mel_b": [
			7,-99,7,8,   7,-99,4,-99,  6,-99,6,7,   6,-99,2,-99,
			5,-99,7,8,   10,-99,9,7,   7,-99,-99,-99,6,-99,4,-99,
			7,-99,9,11,  10,-99,9,7,   8,-99,7,5,   4,-99,7,-99,
			6,-99,7,9,   8,-99,6,4,    7,-99,-99,-99,-99,-99,-99,-99,
		],
	},
	# 6: ABYSSAL TRENCH - Swung Deep-Sea Dub: Tremolo Rhodes, Sonar Pings & Muffled Underwater Filter (76 BPM, B Minor)
	{
		"style": 6, "root": 35, "bpm": 76.0, "scale": SCALE_MINOR, "delay_wet": 0.55,
		"swing": 0.16, "voicing": [0, 2, 4, 6], "lead_attack": 60.0, "lead_decay": 1.0,
		"delay_beats": 0.75, "delay_fb": 0.58, "master_lp": 0.16,
		"prog_a": [0, 4, -2, 3,  0, -1, -2, -1],
		"prog_b": [-2, 2, -1, 4, -2, 3, 0, -1],
		"mel_a": [
			4,-99,-99,-99,-99,-99,6,7, 4,-99,-99,-99,-99,-99,2,0,
			3,-99,-99,-99,4,-99,2,-99, 1,-99,-99,-99,-99,-99,-99,-99,
			4,-99,-99,-99,-99,-99,9,7, 6,-99,-99,-99,4,-99,2,-99,
			3,-99,-99,4,  6,-99,5,3,   4,-99,-99,-99,-99,-99,-99,-99,
		],
		"mel_b": [
			7,-99,-99,-99,9,-99,11,-99,7,-99,-99,-99,6,-99,4,-99,
			5,-99,-99,-99,7,-99,5,-99, 4,-99,-99,-99,-99,-99,-99,-99,
			7,-99,-99,9,  10,-99,9,7,  5,-99,-99,7,  6,-99,4,-99,
			5,-99,4,2,    3,-99,5,6,   7,-99,-99,-99,-99,-99,-99,-99,
		],
	},
	# 7: CYBER NEXUS - 142 BPM Off-Beat Pumping Euphoric Cyber-Trance with a Bit-Crushed Digital Lead (F# Minor)
	{
		"style": 7, "root": 42, "bpm": 142.0, "scale": SCALE_MINOR, "delay_wet": 0.36,
		"crush": 4,
		"prog_a": [0, -2, 2, -1,  3, -2, -1, 4],
		"prog_b": [-2, -1, 2, 0,  -2, -1, 0, 4],
		"mel_a": [
			0,2,4,-99,   7,-99,6,4,    5,-99,7,9,   7,-99,4,-99,
			6,-99,7,9,   11,-99,9,7,   6,-99,5,4,   6,-99,-99,-99,
			7,9,11,-99,  9,-99,7,6,    5,-99,7,9,   7,-99,4,-99,
			3,-99,5,7,   9,-99,8,6,    7,-99,-99,-99,-99,-99,-99,-99,
		],
		"mel_b": [
			11,-99,-99,9,7,-99,11,-99, 9,-99,-99,7, 6,-99,9,-99,
			7,-99,9,11,  12,-99,11,9,  11,-99,-99,-99,9,-99,7,-99,
			11,-99,12,14,11,-99,9,7,   8,-99,9,11,  9,-99,7,-99,
			7,-99,9,11,  10,-99,9,8,   7,-99,-99,-99,-99,-99,-99,-99,
		],
	},
]

# Universal Boss Theme ("Neon Medusa" Dark Synthwave - Style 8)
const BOSS_SONG: Dictionary = {
	"style": 8, "root": 36, "bpm": 126.0, "scale": SCALE_MINOR, "delay_wet": 0.30,
	"prog_a": [0, 0, -2, -1,   0, 0, 3, -1],
	"prog_b": [-2, -1, 0, 2,   -2, 3, -1, 4],
	"mel_a": [
		4,-99,4,5,   4,-99,2,0,    -99,-99,0,2,  3,-99,2,0,
		4,-99,4,6,   7,-99,5,4,    3,-99,2,1,    2,-99,-99,-99,
		7,-99,7,8,   7,-99,6,4,    5,-99,4,2,    3,-99,4,-99,
		5,-99,6,7,   9,-99,7,6,    7,-99,-99,-99,-99,-99,-99,-99,
	],
	"mel_b": [
		9,-99,-99,7, 9,-99,11,-99, 7,-99,-99,6,  7,-99,9,-99,
		8,-99,7,5,   4,-99,7,-99,  6,-99,5,4,    6,-99,-99,-99,
		9,-99,10,11, 12,-99,11,9,  7,-99,9,11,   9,-99,7,-99,
		8,-99,9,11,  10,-99,9,6,   7,-99,-99,-99,-99,-99,-99,-99,
	],
}


func _ready() -> void:
	_rng.seed = 1986
	_delay_l.resize(DELAY_MAX)
	_delay_r.resize(DELAY_MAX)
	_clear_delay()

	var gen: AudioStreamGenerator = AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.14

	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_volume(music_volume)


func _clear_delay() -> void:
	_delay_l.fill(0.0)
	_delay_r.fill(0.0)
	_delay_pos = 0


func set_volume(linear_val: float) -> void:
	music_volume = clampf(linear_val, 0.0, 1.0)
	_apply_volume_db()


func set_paused_duck(is_paused: bool) -> void:
	paused_duck = is_paused
	_apply_volume_db()


func _apply_volume_db() -> void:
	if _player == null:
		return
	if music_volume <= 0.01:
		_player.volume_db = -80.0
	else:
		var duck_db: float = -6.5 if paused_duck else 0.0
		_player.volume_db = linear_to_db(music_volume * 0.72) + duck_db


func _deg_to_midi(root_midi: int, scale: Array, degree: int) -> int:
	var n: int = scale.size()
	var oct: int = floori(float(degree) / float(n))
	var idx: int = posmod(degree, n)
	return root_midi + oct * 12 + int(scale[idx])


func _midi_to_hz(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)


func play_title() -> void:
	paused_duck = false
	_switch_state(Mode.TITLE, 0)


func play_stage(stage_idx: int) -> void:
	paused_duck = false
	_switch_state(Mode.STAGE, stage_idx)


func play_boss(_stage_idx: int = 0) -> void:
	paused_duck = false
	_switch_state(Mode.BOSS, 0)


func play_hyperspace() -> void:
	paused_duck = false
	_hyper_sweep = 0.0
	_switch_state(Mode.HYPERSPACE, current_stage_idx)


func stop_music() -> void:
	_switch_state(Mode.NONE, current_stage_idx)


func _switch_state(new_mode: Mode, stage_idx: int) -> void:
	_apply_volume_db()
	var wrapped_stage: int = posmod(stage_idx, 8)
	if current_mode == new_mode and (new_mode == Mode.BOSS or current_stage_idx == wrapped_stage) and _player != null and _player.playing:
		return
	current_mode = new_mode
	current_stage_idx = wrapped_stage
	if new_mode == Mode.STAGE:
		_song = STAGE_SONGS[current_stage_idx]
	elif new_mode == Mode.BOSS:
		_song = BOSS_SONG
	else:
		_song = {}
	_load_song_params()
	_step = 0
	_sample_in_step = 999999.0 # fires step 0 on the next sample (see _render_block)
	_bass_env = 0.0
	_arp_env = 0.0
	_lead_env = 0.0
	_harm_env = 0.0
	_pad_swell = 0.0
	_stab_env = 0.0
	_kick_env = 0.0
	_snare_body_env = 0.0
	_snare_gate_time = 0.0
	_rim_env = 0.0
	_tom_env = 0.0
	_hat_env = 0.0
	_master_lp_l = 0.0
	_master_lp_r = 0.0
	_crush_count = 0
	_crush_hold = 0.0
	_clear_delay()

	if new_mode == Mode.NONE:
		_player.stop()
		_playback = null
		return

	var bpm: float = _get_current_bpm()
	var delay_beats: float = float(_song_param("delay_beats"))
	_delay_len = clampi(int((60.0 / bpm) * delay_beats * MIX_RATE), 2000, DELAY_MAX - 1)
	_delay_wet = float(_song.get("delay_wet", 0.34))

	if not _player.playing:
		_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func _song_param(key: String) -> Variant:
	return _song.get(key, SONG_DEFAULTS[key])


func _load_song_params() -> void:
	_style = int(_song.get("style", 0))
	_bar_steps = int(_song_param("bar_steps"))
	_swing = float(_song_param("swing"))
	_voicing = _song_param("voicing")
	_lead_oct = int(_song_param("lead_oct"))
	_lead_attack = float(_song_param("lead_attack"))
	_lead_decay = float(_song_param("lead_decay"))
	_harm_int = int(_song_param("harm_int"))
	_delay_fb = float(_song_param("delay_fb"))
	_master_lp = float(_song_param("master_lp"))
	_crush = maxi(1, int(_song_param("crush")))


func _get_current_bpm() -> float:
	match current_mode:
		Mode.TITLE:
			return 98.0
		Mode.HYPERSPACE:
			return 132.0
		Mode.BOSS:
			return float(BOSS_SONG["bpm"])
		Mode.STAGE:
			return float(STAGE_SONGS[current_stage_idx]["bpm"])
	return 120.0


func _process(_delta: float) -> void:
	if current_mode == Mode.NONE or _player == null:
		return
	if not _player.playing:
		_player.play()
	if _playback == null:
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
		if _playback == null:
			return

	var frames: int = _playback.get_frames_available()
	if frames > 0:
		_playback.push_buffer(_render_block(frames))


# Renders the next `frames` stereo samples of the current music. Separate from _process
# so the soundtrack can also be rendered offline (e.g. to a WAV for listening tests).
func _render_block(frames: int) -> PackedVector2Array:
	var buf: PackedVector2Array = PackedVector2Array()
	buf.resize(frames)
	var bpm: float = _get_current_bpm()
	var samples_per_16th: float = (60.0 / bpm) * 0.25 * MIX_RATE
	var long_step: float = samples_per_16th * (1.0 + _swing)
	var short_step: float = samples_per_16th * (1.0 - _swing)
	var dt: float = 1.0 / MIX_RATE

	for i: int in range(frames):
		_sample_in_step += 1.0
		# Swing: the step now sounding (_step - 1) is long if even, short if odd.
		var step_len: float = long_step if posmod(_step - 1, 2) == 0 else short_step
		if _sample_in_step >= step_len:
			# Reset (rather than subtract) after the large value set by _switch_state, so a new
			# song fires step 0 once instead of a burst of catch-up steps that skipped ~11 bars.
			_sample_in_step = 0.0 if _sample_in_step > step_len * 2.0 else _sample_in_step - step_len
			_trigger_step()
			_step += 1

		if current_mode == Mode.TITLE:
			buf[i] = _synth_title_frame(dt)
		elif current_mode == Mode.HYPERSPACE:
			buf[i] = _synth_hyperspace_frame(dt)
		else:
			buf[i] = _synth_ensemble_frame(dt, _style)
	return buf


func _set_pad_chord(root_midi: int, scale: Array, chord_deg: int) -> void:
	for k: int in range(4):
		_pad_target_freqs[k] = _midi_to_hz(_deg_to_midi(root_midi + 12, scale, chord_deg + int(_voicing[k])))
	if _pad_swell < 0.05:
		for k: int in range(4):
			_pad_freqs[k] = _pad_target_freqs[k]


func _trigger_step() -> void:
	if current_mode == Mode.TITLE:
		var pos256: int = _step % 256
		var t_prog: Array[int] = [0, -2, 2, -1,  0, 3, -2, -1]
		var c_deg: int = t_prog[(pos256 / 16) % 8]
		if pos256 % 16 == 0:
			_bass_freq = _midi_to_hz(_deg_to_midi(45, SCALE_MINOR, c_deg - 7))
			_bass_env = 1.0
			_bass_atk = 0.0
			_set_pad_chord(45, SCALE_MINOR, c_deg)
		var arp_degs: Array[int] = [0, 2, 4, 6, 7, 6, 4, 2]
		_arp_freq = _midi_to_hz(_deg_to_midi(57, SCALE_MINOR, c_deg + arp_degs[pos256 % 8]))
		_arp_env = 0.78
		_arp_atk = 0.0
		if pos256 >= 64 and pos256 % 8 == 0:
			var title_lead_degs: Array[int] = [4, 6, 7, 4, 2, 3, 4, 2, 4, 7, 9, 7, 6, 4, 3, 4]
			var ld: int = title_lead_degs[((pos256 - 64) / 8) % title_lead_degs.size()]
			_lead_target_freq = _midi_to_hz(_deg_to_midi(57, SCALE_MINOR, ld))
			if _lead_env < 0.12:
				_lead_freq = _lead_target_freq
			_lead_env = 0.80
			_lead_atk = 0.0
		return

	if current_mode == Mode.HYPERSPACE:
		var h_degs: Array[int] = [0, 2, 4, 6, 7, 9, 11, 14]
		var d: int = h_degs[_step % 8] + (_step / 8)
		_arp_freq = _midi_to_hz(_deg_to_midi(45, SCALE_MINOR, mini(21, d)))
		_arp_env = 0.95
		_arp_atk = 0.0
		_set_pad_chord(45, SCALE_MINOR, 0)
		if _step % 4 == 0:
			_kick_env = 0.85
			_kick_phase = 0.0
		return

	var song: Dictionary = _song
	var style: int = _style
	var root: int = int(song["root"])
	var scale: Array = song["scale"]

	# Song form: 4 sections x 8 bars. A bar is _bar_steps sixteenths (16 in 4/4, 12 in 3/4).
	var bar_len: int = _bar_steps
	var pos: int = _step % (bar_len * 32)
	var section: int = pos / (bar_len * 8)
	var sec_step: int = pos % (bar_len * 8)
	var bar8: int = sec_step / bar_len
	var s16: int = sec_step % bar_len # step within the bar

	var prog: Array = song["prog_b"] if (section == 2 or (section == 3 and bar8 >= 4)) else song["prog_a"]
	var chord_deg: int = int(prog[bar8])

	if s16 == 0:
		_set_pad_chord(root, scale, chord_deg)

	var is_breakdown: bool = (section == 3 and bar8 < 4)

	# --- STYLE-SPECIFIC RHYTHM, BASS, CHORD STABS, ARPEGGIOS & PERCUSSION! ---
	_trigger_style_rhythm(style, root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)

	# --- MELODIC LEAD & PURE DIATONIC HARMONY ---
	# Melodies are 4 bars long (64 steps in 4/4, 48 in 3/4) and repeat twice per section.
	var m_deg: int = -99
	var use_harmony: bool = false

	if section == 0:
		if bar8 >= 2 or style == 8:
			var ma0: Array = song["mel_a"]
			m_deg = int(ma0[sec_step % ma0.size()])
	elif section == 1:
		var ma1: Array = song["mel_a"]
		m_deg = int(ma1[sec_step % ma1.size()])
		use_harmony = (bar8 >= 4)
	elif section == 2:
		var mb: Array = song["mel_b"]
		m_deg = int(mb[sec_step % mb.size()])
		use_harmony = true
	else:
		if bar8 >= 4:
			var climb: Array[int] = [0,-99,2,4, 6,-99,4,2, 4,-99,6,7, 9,-99,7,6]
			var climb_deg: int = climb[s16 % climb.size()]
			if climb_deg != -99:
				m_deg = chord_deg + 7 + climb_deg
			use_harmony = (bar8 >= 6)
		elif s16 == 0 or s16 == 6:
			m_deg = chord_deg + (7 if s16 == 0 else 9)

	if m_deg != -99:
		_lead_target_freq = _midi_to_hz(_deg_to_midi(root + _lead_oct, scale, m_deg))
		if _lead_env < 0.15:
			_lead_freq = _lead_target_freq
		_lead_env = 0.96
		_lead_atk = 0.0

		if use_harmony:
			_harm_target_freq = _midi_to_hz(_deg_to_midi(root + _lead_oct, scale, m_deg + _harm_int))
			if _harm_env < 0.15:
				_harm_freq = _harm_target_freq
			_harm_env = 0.75
			_harm_atk = 0.0


# `s16` is the step within the bar: 0..15 in 4/4, 0..11 for the 3/4 Cloud Base waltz.
func _trigger_style_rhythm(style: int, root: int, scale: Array, chord_deg: int, s16: int, bar8: int, section: int, is_breakdown: bool, pos: int) -> void:
	var chord_tones: Array[int] = [0, 2, 4, 7, 9]

	match style:
		1: # STAGE 2 (STARCRUISER): Funky Slap-FM Bass + Staccato Clavinet Stabs + Syncopated Breakbeat!
			var slap_pat: Array[int] = [0, -99, 7, 0,  -99, 4, -99, 7,  -99, 0, 7, -99,  4, 0, -99, 7]
			var b_off: int = slap_pat[s16]
			if not is_breakdown and b_off != -99:
				_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg + b_off))
				_bass_env = 1.0
				_bass_atk = 0.0
			# Syncopated Clavinet / Brass Chord Stabs!
			if s16 == 0 or s16 == 3 or s16 == 6 or s16 == 10 or s16 == 14:
				_stab_env = 1.0
			# Tight breakbeat drums (kick on 0, 6, 10; crisp tight snare/rim on 4 & 12!)
			if not is_breakdown:
				if s16 == 0 or s16 == 6 or s16 == 10:
					_kick_env = 1.0
					_kick_phase = 0.0
				if s16 == 4 or s16 == 12 or (bar8 == 7 and s16 == 15):
					_rim_env = 1.0
					_rim_phase = 0.0
					_snare_body_env = 0.75
					_snare_phase = 0.0
				_hat_env = 0.55 if (s16 % 2 == 0) else 0.25
				_hat_decay = 48.0

		2: # STAGE 3 (CLOUD BASE): 3/4 Sky Waltz. Fretless bass "oom" on beat 1 (fifth on beat 3),
			# harp arpeggio rising and falling on every 8th, soft brushed snare on beats 2 & 3.
			# One bar = 12 sixteenths: beats fall on steps 0, 4 and 8.
			if s16 == 0:
				_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg))
				_bass_env = 0.95 if not is_breakdown else 0.70
				_bass_atk = 0.0
			elif s16 == 8 and not is_breakdown:
				_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg + 4))
				_bass_env = 0.55
				_bass_atk = 0.0
			if s16 % 2 == 0:
				var harp: Array[int] = [0, 2, 4, 7, 4, 2]
				_arp_freq = _midi_to_hz(_deg_to_midi(root + 24, scale, chord_deg + harp[(s16 / 2) % harp.size()]))
				_arp_env = 0.80
				_arp_atk = 0.0
			if not is_breakdown:
				if s16 == 0:
					_kick_env = 0.70
					_kick_phase = 0.0
				if s16 == 4 or s16 == 8:
					_snare_body_env = 0.32
					_snare_gate_time = 0.06
					_snare_phase = 0.0
				if s16 % 2 == 0:
					_hat_env = 0.30
					_hat_decay = 40.0

		3: # STAGE 4 (XENO FOREST): Deep Log-Sub + Wooden Kalimba/Marimba Polyrhythm + Tribal Congas & Shakers!
			if s16 == 0 or s16 == 6 or s16 == 10:
				_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg))
				_bass_env = 0.95
				_bass_atk = 0.0
			# Polyrhythmic 3-against-4 Marimba / Kalimba wooden mallets!
			var marimba_pat: Array[int] = [0, 4, 2, 7, 4, 9, 2, 7, 0, 4, 7, 9, 4, 2, 7, 4]
			_arp_freq = _midi_to_hz(_deg_to_midi(root + 12, scale, chord_deg + marimba_pat[s16]))
			_arp_env = 0.92 if (s16 % 3 == 0 or s16 % 4 == 0) else 0.48
			_arp_atk = 0.0
			# Tribal Conga Hand-Drums (High Conga 290Hz, Mid Conga 215Hz, Low Djembe 115Hz) + Shakers!
			if not is_breakdown:
				if s16 == 0 or s16 == 8:
					_tom_freq = 108.0
					_tom_env = 0.90
					_tom_phase = 0.0
				elif s16 == 3 or s16 == 7 or s16 == 11:
					_tom_freq = 275.0
					_tom_env = 0.72
					_tom_phase = 0.0
				elif s16 == 6 or s16 == 14:
					_tom_freq = 205.0
					_tom_env = 0.80
					_tom_phase = 0.0
			_hat_env = 0.42 if (s16 % 2 == 0) else 0.22
			_hat_decay = 24.0 # Soft organic shaker!

		4: # STAGE 5 (CRYO GLACIER): Sustained Sub-Pedal + Sparse High Music-Box + Half-Time Heartbeat
			if s16 == 0:
				_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg))
				_bass_env = 1.0
				_bass_atk = 0.0
			# Music box two octaves above the lead's home, in 8ths with gaps so the echo can ring.
			var box: Array[int] = [0, -99, 4, -99, 7, -99, 11, -99, 9, -99, -99, -99, 7, -99, 4, -99]
			var box_deg: int = box[s16]
			if box_deg != -99:
				_arp_freq = _midi_to_hz(_deg_to_midi(root + 36, scale, chord_deg + box_deg))
				_arp_env = 0.80
				_arp_atk = 0.0
			# Half-time heartbeat: one soft kick per bar and a crystal rim on beat 3 (no snare, barely any hats).
			if not is_breakdown:
				if s16 == 0:
					_kick_env = 0.70
					_kick_phase = 0.0
				if s16 == 8:
					_rim_env = 0.60
					_rim_phase = 0.0
				if s16 == 4 or s16 == 12:
					_hat_env = 0.30
					_hat_decay = 14.0

		5: # STAGE 6 (MAGMA CORE): Growling Acid Saw Bass + Heavy Double-Kick & War Taiko Toms!
			# Palm-muted chug that keeps leaning on the Phrygian b2 (offset 1) for the metal crunch.
			var magma_b: Array[int] = [0, 0, 0, 7,  0, 0, 1, 0,  0, 0, 0, 7,  4, 1, 0, -1]
			if not is_breakdown:
				_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg + magma_b[s16]))
				_bass_env = 1.0
				_bass_atk = 0.0
			if s16 == 0 or s16 == 6 or s16 == 12:
				_stab_env = 1.0 # Low brass hits!
			if not is_breakdown:
				# Thunderous double-kick & war toms!
				if s16 % 2 == 0 and (s16 < 4 or s16 >= 8):
					_kick_env = 1.0
					_kick_phase = 0.0
				if s16 == 4 or s16 == 12:
					_trigger_gated_snare(1.0)
				if s16 == 7 or s16 == 14 or s16 == 15:
					_tom_freq = 92.0 if s16 == 15 else 128.0
					_tom_env = 0.95
					_tom_phase = 0.0
				_hat_env = 0.55 if (s16 % 4 == 2) else 0.25
				_hat_decay = 30.0

		6: # STAGE 7 (ABYSSAL TRENCH): Deep Liquid Dub Sub + Tremolo Rhodes Chords + Echoing Sonar Plucks!
			if s16 == 0 or s16 == 10:
				_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg))
				_bass_env = 1.0
				_bass_atk = 0.0
			if s16 == 0 or s16 == 8:
				_stab_env = 1.0 # Warm Fender-Rhodes electric piano bell-chord!
			# A lone high sonar ping every other bar, plus a few deep droplets; the dub echo fills the rest.
			if s16 == 0 and bar8 % 2 == 0:
				_arp_freq = _midi_to_hz(_deg_to_midi(root + 36, scale, chord_deg + 4))
				_arp_env = 1.0
				_arp_atk = 0.0
			elif s16 == 6 or s16 == 11:
				var drop_notes: Array[int] = [4, 7, 9, 7]
				_arp_freq = _midi_to_hz(_deg_to_midi(root + 24, scale, chord_deg + drop_notes[bar8 % 4]))
				_arp_env = 0.65
				_arp_atk = 0.0
			# Soft muted underwater beat (soft sub-kick + crisp rim-click on beat 3)
			if not is_breakdown:
				if s16 == 0 or s16 == 6:
					_kick_env = 0.80
					_kick_phase = 0.0
				if s16 == 8:
					_rim_env = 0.85
					_rim_phase = 0.0

		7: # STAGE 8 (CYBER NEXUS): 142 BPM Off-Beat Trance Bass + Gated Hypersaws + 303 Arp + Club 909!
			# Classic Trance offbeat octave bass (pumping on "&" steps 2, 6, 10, 14!)
			if not is_breakdown and (s16 % 4 == 2 or s16 % 4 == 3):
				var oct: int = 7 if (s16 % 4 == 2) else 0
				_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg + oct))
				_bass_env = 1.0
				_bass_atk = 0.0
			# Trance rhythmic hypersaw gate pattern!
			if s16 == 0 or s16 == 3 or s16 == 6 or s16 == 8 or s16 == 11 or s16 == 14:
				_stab_env = 0.95
			_arp_freq = _midi_to_hz(_deg_to_midi(root + 12, scale, chord_deg + chord_tones[pos % 5]))
			_arp_env = 0.85
			_arp_atk = 0.0
			if not is_breakdown:
				if s16 % 4 == 0: # 4-on-the-floor Trance Kick!
					_kick_env = 1.0
					_kick_phase = 0.0
					_sidechain = 0.28
				if s16 == 4 or s16 == 12:
					_trigger_gated_snare(0.85)
				if s16 % 4 == 2: # Open 909 offbeat trance hat!
					_hat_env = 0.72
					_hat_decay = 15.0

		_: # STYLE 0 (STAGE 1 OUTER ORBIT) & STYLE 8 (UNIVERSAL NEON MEDUSA BOSS THEME):
			var is_boss: bool = (style == 8)
			if is_breakdown:
				if s16 == 0 or s16 == 8:
					_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg))
					_bass_env = 0.95
					_bass_atk = 0.0
			else:
				var pat: Array[int] = [0, 0, 7, 0, 0, 0, 7, 0, 0, 0, 7, 0, 0, 7, 4, 7]
				_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg + pat[s16]))
				_bass_env = 1.0 if (s16 % 4 == 0) else 0.85
				_bass_atk = 0.0
			_arp_freq = _midi_to_hz(_deg_to_midi(root + 12, scale, chord_deg + chord_tones[pos % 5]))
			_arp_env = 0.80 if (s16 % 2 == 0) else 0.50
			_arp_atk = 0.0
			if bar8 == 7 and s16 >= 10:
				_tom_freq = 175.0 if s16 < 12 else (130.0 if s16 < 14 else 92.0)
				_tom_env = 0.95
				_tom_phase = 0.0
			elif not is_breakdown:
				if s16 == 0 or s16 == 8 or (is_boss and (s16 == 4 or s16 == 14)):
					_kick_env = 1.0
					_kick_phase = 0.0
					_sidechain = 0.35
				if s16 == 4 or s16 == 12:
					_trigger_gated_snare(1.0)
				if s16 % 4 == 2:
					_hat_env = 0.62
					_hat_decay = 18.0
				elif is_boss or section >= 1:
					_hat_env = 0.28
					_hat_decay = 42.0


func _trigger_gated_snare(vel: float) -> void:
	_snare_body_env = vel
	_snare_gate_time = 0.19
	_snare_phase = 0.0


func _synth_title_frame(dt: float) -> Vector2:
	_lfo_phase += 1.5 * dt
	_pad_swell = minf(1.0, _pad_swell + dt * 0.8)

	_bass_atk = minf(1.0, _bass_atk + dt * 50.0)
	_bass_env = maxf(0.0, _bass_env - dt * 0.32)
	_bass_p1 = fmod(_bass_p1 + _bass_freq * dt, 1.0)
	var sub: float = sin(_bass_p1 * TAU) * _bass_env * _bass_atk * 0.24

	var pad_lr: Vector2 = _tick_stereo_pad(dt, 0.14, 0)

	_arp_atk = minf(1.0, _arp_atk + dt * 220.0)
	_arp_env = maxf(0.0, _arp_env - dt * 3.2)
	_arp_p = fmod(_arp_p + _arp_freq * dt, 1.0)
	var bell: float = sin(_arp_p * TAU + sin(_arp_p * 2.0 * TAU) * _arp_env) * (_arp_env * _arp_env) * _arp_atk * 0.15

	var lead: float = 0.0
	if _lead_env > 0.002:
		_lead_freq = lerpf(_lead_freq, _lead_target_freq, clampf(dt * 18.0, 0.0, 1.0))
		_lead_atk = minf(1.0, _lead_atk + dt * 65.0)
		_lead_env = maxf(0.0, _lead_env - dt * 0.95)
		var vib: float = 1.0 + 0.004 * sin(_lfo_phase * TAU * 2.5)
		_lead_p1 = fmod(_lead_p1 + _lead_freq * vib * dt, 1.0)
		var raw_l: float = (2.0 * _lead_p1 - 1.0) * 0.5 + sin(_lead_p1 * TAU) * 0.6
		_lead_lp += 0.12 * (raw_l - _lead_lp)
		lead = _lead_lp * _lead_env * _lead_atk * 0.22

	return _apply_stereo_delay(sub + pad_lr.x, sub + pad_lr.y, bell * 0.8 + lead * 0.6, bell * 0.5 + lead)


func _synth_hyperspace_frame(dt: float) -> Vector2:
	_hyper_sweep = minf(1.0, _hyper_sweep + dt * 0.55)
	_pad_swell = minf(1.0, _pad_swell + dt * 2.0)
	var pad_lr: Vector2 = _tick_stereo_pad(dt, 0.16, 0)

	_arp_atk = minf(1.0, _arp_atk + dt * 280.0)
	_arp_env = maxf(0.0, _arp_env - dt * 6.0)
	_arp_p = fmod(_arp_p + _arp_freq * dt, 1.0)
	var arp: float = sin(_arp_p * TAU) * _arp_env * _arp_atk * 0.22
	var kick: float = _tick_kick(dt) * 0.7
	return _apply_stereo_delay(pad_lr.x + kick, pad_lr.y + kick, arp, arp * 0.7)


# =========================================================================================
# MULTI-INSTRUMENT ENSEMBLE SYNTHESIS PER STAGE!
# =========================================================================================
func _synth_ensemble_frame(dt: float, style: int) -> Vector2:
	_lfo_phase += 5.0 * dt
	_pad_swell = minf(1.0, _pad_swell + dt * 1.6)
	_sidechain = minf(1.0, _sidechain + dt * 6.5)
	_stab_env = maxf(0.0, _stab_env - dt * (5.5 if style == 6 else 11.0))

	# --- 1) STAGE-SPECIFIC BASS INSTRUMENT ---
	var bass_sig: float = 0.0
	if _bass_env > 0.001:
		_bass_atk = minf(1.0, _bass_atk + dt * 420.0)
		var b_decay: float = 7.5 if style == 1 else (1.1 if (style == 4 or style == 6) else 5.6)
		_bass_env = maxf(0.0, _bass_env - dt * b_decay)
		_bass_p1 = fmod(_bass_p1 + _bass_freq * dt, 1.0)
		_bass_p2 = fmod(_bass_p2 + _bass_freq * 1.006 * dt, 1.0)
		_bass_sub_p = fmod(_bass_sub_p + _bass_freq * 0.5 * dt, 1.0)

		if style == 1:
			# Slap-FM Metallic Funk Bass (2:1 + 3:1 snappy FM pop!)
			var fm_mod: float = sin(_bass_p1 * 2.0 * TAU) * (_bass_env * _bass_env * 3.2 + 0.4)
			bass_sig = sin(_bass_p1 * TAU + fm_mod) * _bass_env * _bass_atk * 0.38
		elif style == 2:
			# Bouncy Fretless Triangle + Warm Octave Harmonic Bass
			var tri_b: float = 4.0 * absf(_bass_p1 - 0.5) - 1.0
			bass_sig = (tri_b * 0.75 + sin(_bass_p1 * 2.0 * TAU) * 0.25) * _bass_env * _bass_atk * 0.36
		elif style == 3 or style == 4 or style == 6:
			# Deep Pure Sub / Log-Drum / Liquid Dub Bass (warm round sine + subtle 2nd harmonic)
			bass_sig = (sin(_bass_p1 * TAU) * 0.82 + sin(_bass_p1 * 2.0 * TAU) * 0.22 * _bass_env) * _bass_env * _bass_atk * 0.38
		elif style == 5:
			# Aggressive Volcanic Acid-Resonant Sawtooth Bass!
			var saw_f: float = 2.0 * _bass_p1 - 1.0
			var cut_f: float = clampf(0.05 + 0.36 * (_bass_env * _bass_env), 0.03, 0.52)
			_bass_lp1 += cut_f * (saw_f - _bass_lp1)
			var over: float = (_bass_lp1 * 1.7) / (1.0 + absf(_bass_lp1 * 1.7))
			bass_sig = (over * 0.8 + sin(_bass_sub_p * TAU) * 0.4) * _bass_env * _bass_atk * 0.36
		else:
			# Dual-Saw Synthwave / Trance Pumping Bass (Style 0, 7, 8)
			var dual_saw: float = (2.0 * _bass_p1 - 1.0) * 0.55 + (2.0 * _bass_p2 - 1.0) * 0.55
			var b_cut: float = clampf(0.045 + 0.22 * (_bass_env * _bass_env), 0.025, 0.44)
			_bass_lp1 += b_cut * (dual_saw - _bass_lp1)
			_bass_lp2 += b_cut * (_bass_lp1 - _bass_lp2)
			bass_sig = (_bass_lp2 + sin(_bass_sub_p * TAU) * 0.50) * _bass_env * _bass_atk * (0.45 + 0.55 * _sidechain) * 0.34

	# --- 2) STAGE-SPECIFIC CHORD / PAD / RHODES / CLAVINET INSTRUMENT ---
	var pad_lr: Vector2 = _tick_stereo_pad(dt, 0.15 * _sidechain, style)

	# --- 3) STAGE-SPECIFIC ARPEGGIATOR / MARIMBA / CELESTA / SONAR ---
	var arp_sig: float = 0.0
	if _arp_env > 0.001:
		_arp_atk = minf(1.0, _arp_atk + dt * 420.0)
		var a_dec: float = 8.2
		match style:
			2: a_dec = 6.0
			3: a_dec = 11.0
			4, 6: a_dec = 4.8
		_arp_env = maxf(0.0, _arp_env - dt * a_dec)
		_arp_p = fmod(_arp_p + _arp_freq * dt, 1.0)

		if style == 2:
			# Concert Harp Pluck (sine + soft octave that fades faster than the body)
			arp_sig = (sin(_arp_p * TAU) + sin(_arp_p * 2.0 * TAU) * 0.3 * _arp_env) * (_arp_env * _arp_env) * _arp_atk * 0.17
		elif style == 3:
			# Wooden Marimba / Kalimba Mallet (fundamental sine + fast-decaying 4x hollow wood overtone!)
			var wood_hit: float = sin(_arp_p * 4.0 * TAU) * (_arp_env * _arp_env * _arp_env) * 0.65
			arp_sig = (sin(_arp_p * TAU) + wood_hit) * _arp_env * _arp_atk * 0.20
		elif style == 4:
			# Sparkling FM Ice-Bell Celesta (3.5x crystalline bell modulator!)
			_arp_m_p = fmod(_arp_m_p + _arp_freq * 3.5 * dt, 1.0)
			var ice_mod: float = sin(_arp_m_p * TAU) * (_arp_env * 1.6 + 0.25)
			arp_sig = sin(_arp_p * TAU + ice_mod) * (_arp_env * _arp_env) * _arp_atk * 0.16
		elif style == 6:
			# Liquid Underwater Sonar Harp Pluck
			arp_sig = sin(_arp_p * TAU + sin(_arp_p * TAU) * _arp_env * 0.8) * (_arp_env * _arp_env) * _arp_atk * 0.18
		else:
			var arp_raw: float = (0.75 if _arp_p < 0.30 else -0.75) + sin(_arp_p * 2.0 * TAU) * 0.35
			_arp_lp += (0.09 + 0.30 * _arp_env) * (arp_raw - _arp_lp)
			arp_sig = _arp_lp * (_arp_env * _arp_env) * _arp_atk * 0.13

	# --- 4) STAGE-SPECIFIC SOLO LEAD INSTRUMENT ---
	var lead_sig: float = 0.0
	if _lead_env > 0.002:
		var glide_spd: float = 55.0 if style == 1 else 32.0
		_lead_freq = lerpf(_lead_freq, _lead_target_freq, clampf(dt * glide_spd, 0.0, 1.0))
		_lead_atk = minf(1.0, _lead_atk + dt * _lead_attack)
		_lead_env = maxf(0.0, _lead_env - dt * _lead_decay)
		var vib_depth: float = 0.0065 if style == 5 else 0.0040
		var vib: float = 1.0 + vib_depth * sin(_lfo_phase * TAU)
		_lead_p1 = fmod(_lead_p1 + _lead_freq * vib * dt, 1.0)
		_lead_p2 = fmod(_lead_p2 + _lead_freq * vib * 1.006 * dt, 1.0)

		var raw_lead: float = 0.0
		match style:
			1: # Starcruiser: Punchy Funky Sync-Square Lead
				raw_lead = (0.85 if _lead_p1 < 0.25 else -0.85) * 0.7 + sin(_lead_p1 * 3.0 * TAU) * 0.35
			2: # Cloud Base: Bright Soaring Bell-Flute Lead
				var tri2: float = 4.0 * absf(_lead_p1 - 0.5) - 1.0
				raw_lead = sin(_lead_p1 * TAU) * 0.65 + tri2 * 0.35 + sin(_lead_p1 * 2.0 * TAU) * 0.30
			3: # Xeno Forest: Warm Breathy Pan-Flute / Ocarina (pure sine + subtle airy chiff!)
				var chiff: float = _rng.randf_range(-1.0, 1.0) * (1.0 - _lead_atk) * 0.25
				raw_lead = sin(_lead_p1 * TAU) * 0.90 + sin(_lead_p1 * 3.0 * TAU) * 0.14 + chiff
			4: # Cryo Glacier: Crystalline Glass Flute-Bell
				raw_lead = sin(_lead_p1 * TAU + sin(_lead_p1 * 2.0 * TAU) * 0.55) * 0.9
			5, 8: # Volcano & Boss: Screaming Overdriven Guitar / Neon Medusa Lead!
				var g_mix: float = (2.0 * _lead_p1 - 1.0) + (2.0 * _lead_p2 - 1.0)
				raw_lead = (g_mix * 1.65) / (1.0 + absf(g_mix * 1.65))
			6: # Abyssal Trench: Warm Mellow Underwater Sine-Bell Lead
				raw_lead = sin(_lead_p1 * TAU) * 0.8 + sin(_lead_p2 * 2.0 * TAU) * 0.25 * _lead_env
			7: # Cyber Nexus: Detuned Euphoric Trance Supersaw Lead!
				var p3: float = fmod(_lead_p1 * 0.993, 1.0)
				raw_lead = ((2.0 * _lead_p1 - 1.0) + (2.0 * _lead_p2 - 1.0) + (2.0 * p3 - 1.0)) * 0.45
			_: # Stage 1: Classic Midnight Lush Dual-Saw Lead
				raw_lead = (2.0 * _lead_p1 - 1.0) * 0.55 + (2.0 * _lead_p2 - 1.0) * 0.55 + sin(_lead_p1 * TAU) * 0.35

		var l_cut: float = 0.28 if (style == 3 or style == 4 or style == 6) else (0.15 + 0.28 * _lead_env)
		_lead_lp += l_cut * (raw_lead - _lead_lp)
		lead_sig = _lead_lp * _lead_env * _lead_atk * 0.23

		if _crush > 1:
			# Digital bit-crush: hold each value for _crush samples and quantize it to coarse steps.
			_crush_count += 1
			if _crush_count >= _crush:
				_crush_count = 0
				_crush_hold = snappedf(lead_sig, 0.012)
			lead_sig = _crush_hold

	# --- 5) PURE DIATONIC HARMONY LEAD ---
	var harm_sig: float = 0.0
	if _harm_env > 0.002:
		_harm_freq = lerpf(_harm_freq, _harm_target_freq, clampf(dt * 34.0, 0.0, 1.0))
		_harm_atk = minf(1.0, _harm_atk + dt * 140.0)
		_harm_env = maxf(0.0, _harm_env - dt * 1.75)
		_harm_p = fmod(_harm_p + _harm_freq * dt, 1.0)
		var h_raw: float = sin(_harm_p * TAU) * 0.7 + (2.0 * _harm_p - 1.0) * 0.3
		harm_sig = h_raw * _harm_env * _harm_atk * 0.13

	# --- 6) PERCUSSION MIX ---
	var kick: float = _tick_kick(dt)
	var snare_lr: Vector2 = _tick_gated_snare(dt)
	var rim: float = _tick_rim(dt)
	var tom: float = _tick_tom(dt)
	var hat: float = _tick_hat(dt)

	var dry_l: float = bass_sig + pad_lr.x + kick + snare_lr.x + rim + tom + hat
	var dry_r: float = bass_sig + pad_lr.y + kick + snare_lr.y + rim + tom + hat
	var send_l: float = arp_sig * 0.9 + lead_sig * 0.65 + harm_sig * 0.95
	var send_r: float = arp_sig * 0.45 + lead_sig * 0.95 + harm_sig * 0.45

	return _apply_stereo_delay(dry_l, dry_r, send_l, send_r)


func _tick_stereo_pad(dt: float, gain: float, style: int) -> Vector2:
	var sum_l: float = 0.0
	var sum_r: float = 0.0
	var chorus_mod: float = 0.003 * sin(_lfo_phase * 0.4 * TAU)

	for i: int in range(4):
		_pad_freqs[i] = lerpf(_pad_freqs[i], _pad_target_freqs[i], clampf(dt * 12.0, 0.0, 1.0))
		var f: float = _pad_freqs[i]
		_pad_phases_a[i] = fmod(_pad_phases_a[i] + f * (1.0 - 0.004 - chorus_mod) * dt, 1.0)
		_pad_phases_b[i] = fmod(_pad_phases_b[i] + f * (1.0 + 0.004 + chorus_mod) * dt, 1.0)

		if style == 1:
			# Funky Staccato Clavinet / Brass Stabs (gated by _stab_env!)
			var cl_a: float = (0.9 if _pad_phases_a[i] < 0.22 else -0.9) * _stab_env
			var cl_b: float = (0.9 if _pad_phases_b[i] < 0.22 else -0.9) * _stab_env
			sum_l += cl_a
			sum_r += cl_b
		elif style == 2 or style == 4:
			# Airy Flute-Organ / Ethereal Glass Choir Pad (pure sine + octave + 3rd harmonic vowel!)
			var v_a: float = sin(_pad_phases_a[i] * TAU) * 0.7 + sin(_pad_phases_a[i] * 2.0 * TAU) * 0.3
			var v_b: float = sin(_pad_phases_b[i] * TAU) * 0.7 + sin(_pad_phases_b[i] * 2.0 * TAU) * 0.3
			sum_l += v_a
			sum_r += v_b
		elif style == 3:
			# Forest: Very soft warm ambient sine breath so Marimbas & Congas shine!
			sum_l += sin(_pad_phases_a[i] * TAU) * 0.55
			sum_r += sin(_pad_phases_b[i] * TAU) * 0.55
		elif style == 6:
			# Abyssal Trench: Warm Fender-Rhodes Electric Piano with Stereo Auto-Pan Tremolo!
			var tine: float = sin(_pad_phases_a[i] * 4.0 * TAU) * (_stab_env * _stab_env) * 0.35
			var ep: float = (sin(_pad_phases_a[i] * TAU) + tine) * (0.35 + 0.65 * _stab_env)
			var pan_l: float = 0.55 + 0.40 * sin(_lfo_phase * 0.8 * TAU)
			var pan_r: float = 0.55 - 0.40 * sin(_lfo_phase * 0.8 * TAU)
			sum_l += ep * pan_l
			sum_r += ep * pan_r
		elif style == 7:
			# Cyber Nexus: Rhythmic Trance Gate Hypersaws!
			var gate_mul: float = 0.30 + 0.70 * _stab_env
			sum_l += (2.0 * _pad_phases_a[i] - 1.0) * gate_mul
			sum_r += (2.0 * _pad_phases_b[i] - 1.0) * gate_mul
		else:
			# Lush Analog Juno/OB-X Sawtooth Pad (Stage 1, Volcano Brass, Boss)
			var boost: float = (1.0 + _stab_env * 0.6) if style == 5 else 1.0
			sum_l += (2.0 * _pad_phases_a[i] - 1.0) * boost
			sum_r += (2.0 * _pad_phases_b[i] - 1.0) * boost

	var cut: float = 0.14 if (style == 1 or style == 7) else 0.065
	_pad_lp_l += cut * (sum_l * 0.28 - _pad_lp_l)
	_pad_lp_r += cut * (sum_r * 0.28 - _pad_lp_r)
	return Vector2(_pad_lp_l * gain * _pad_swell, _pad_lp_r * gain * _pad_swell)


func _apply_stereo_delay(dry_l: float, dry_r: float, send_l: float, send_r: float) -> Vector2:
	var dl: float = _delay_l[_delay_pos]
	var dr: float = _delay_r[_delay_pos]
	_delay_l[_delay_pos] = send_l + dr * _delay_fb
	_delay_r[_delay_pos] = send_r + dl * _delay_fb
	_delay_pos = (_delay_pos + 1) % _delay_len

	var out_l: float = dry_l + send_l + dl * _delay_wet
	var out_r: float = dry_r + send_r + dr * _delay_wet
	if _master_lp < 1.0:
		# Whole-mix low-pass (Abyssal Trench "underwater" muffle), drifting slowly like a current.
		var lp_a: float = _master_lp * (0.8 + 0.2 * sin(_lfo_phase * 0.02 * TAU))
		_master_lp_l += lp_a * (out_l - _master_lp_l)
		_master_lp_r += lp_a * (out_r - _master_lp_r)
		out_l = _master_lp_l
		out_r = _master_lp_r
	out_l = out_l / (1.0 + maxf(0.0, absf(out_l) - 0.65) * 0.85)
	out_r = out_r / (1.0 + maxf(0.0, absf(out_r) - 0.65) * 0.85)
	return Vector2(clampf(out_l, -0.96, 0.96), clampf(out_r, -0.96, 0.96))


func _tick_kick(dt: float) -> float:
	if _kick_env <= 0.001:
		return 0.0
	_kick_env = maxf(0.0, _kick_env - dt * 9.2)
	var e3: float = _kick_env * _kick_env * _kick_env
	var k_freq: float = 44.0 + 125.0 * e3
	_kick_phase = fmod(_kick_phase + k_freq * dt, 1.0)
	return sin(_kick_phase * TAU) * _kick_env * 0.45


func _tick_gated_snare(dt: float) -> Vector2:
	if _snare_gate_time <= 0.0 and _snare_body_env <= 0.001:
		return Vector2.ZERO
	_snare_body_env = maxf(0.0, _snare_body_env - dt * 14.0)
	_snare_gate_time = maxf(0.0, _snare_gate_time - dt)

	_snare_phase = fmod(_snare_phase + (118.0 + 82.0 * _snare_body_env) * dt, 1.0)
	var body: float = sin(_snare_phase * TAU) * _snare_body_env * 0.34

	var gate_env: float = clampf(_snare_gate_time / 0.04, 0.0, 1.0) * 0.55 + _snare_body_env * 0.45
	var nl: float = _rng.randf_range(-1.0, 1.0)
	var nr: float = _rng.randf_range(-1.0, 1.0)
	_snare_lp_l += 0.22 * (nl - _snare_lp_l)
	_snare_lp_r += 0.22 * (nr - _snare_lp_r)
	return Vector2(body + _snare_lp_l * gate_env * 0.19, body + _snare_lp_r * gate_env * 0.19)


func _tick_rim(dt: float) -> float:
	if _rim_env <= 0.001:
		return 0.0
	_rim_env = maxf(0.0, _rim_env - dt * 28.0)
	_rim_phase = fmod(_rim_phase + 520.0 * dt, 1.0)
	var click: float = sin(_rim_phase * TAU) + sin(_rim_phase * 2.7 * TAU) * 0.5
	return click * (_rim_env * _rim_env) * 0.22


func _tick_tom(dt: float) -> float:
	if _tom_env <= 0.001:
		return 0.0
	_tom_env = maxf(0.0, _tom_env - dt * 8.5)
	var f: float = _tom_freq * (0.72 + 0.42 * _tom_env)
	_tom_phase = fmod(_tom_phase + f * dt, 1.0)
	return sin(_tom_phase * TAU) * _tom_env * 0.36


func _tick_hat(dt: float) -> float:
	if _hat_env <= 0.001:
		return 0.0
	_hat_env = maxf(0.0, _hat_env - dt * _hat_decay)
	var n: float = _rng.randf_range(-1.0, 1.0)
	var hp: float = n - _prev_noise
	_prev_noise = n
	return hp * (_hat_env * _hat_env) * 0.075
