extends Node

# Multi-Ensemble 44.1 kHz Stereo Soundtrack Engine.
# Each stage is scored for its environment. Besides its own instruments, every stage has
# its own tempo, groove (meter + swing), mode, chord voicing, lead register and acoustic
# space (echo time, echo feedback, master filter):
#   Stage 1 (Outer Orbit):     136 BPM  E Mixolydian straight 4/4  heroic launch anthem: galloping picked bass, brass stabs, square lead, rock kit
#   Stage 2 (Starcruiser):     124 BPM  D Dorian    swung funk     FM slap bass, clavinet stabs, m7 chords, dry slapback room
#   Stage 3 (Cloud Base):      116 BPM  F Lydian    3/4 waltz      harp arpeggios, airy organ maj7 chords, long soaring flute
#   Stage 4 (Xeno Forest):     100 BPM  G Dorian    heavy shuffle  marimba, congas & shakers, pentatonic pan-flute call & response
#   Stage 5 (Cryo Glacier):     80 BPM  E Aeolian   half-time      open quartal choir, high music box, swelling glass lead, long icy echo
#   Stage 6 (Magma Core):      152 BPM  C Phrygian  driving 16ths  acid chug bass on the b2, power chords, double kick, war toms
#   Stage 7 (Abyssal Trench):   76 BPM  B Aeolian   swung dub      Rhodes, sonar pings, deep dub echo, muffled underwater filter
#   Stage 8 (Cyber Nexus):     142 BPM  F# Aeolian  four-on-floor  trance: pumping bass, gated hypersaws, bit-crushed digital lead
# Plus 1 universal "Neon Medusa" dark synthwave boss theme.
# All notes come from 7-note diatonic modes, so there are no accidentals.
#
# ALTERNATIVE TRACKS: every slot (title, the 8 stages, boss, hyperspace jump) also has 5
# alternatives in scripts/music_candidates.gd, picked per slot in Options > Soundtrack and
# saved in MetaSave.music_picks (DEFAULT_PICKS sets the shipped choice). They reuse this
# engine: a song's "style" picks the groove (0-8 above, plus 9 chiptune, 10 drum & bass,
# 11 outrun, 12 orchestral, 13 ambient, 14 lo-fi, 15 bossa nova, 16 industrial, 17 6/8),
# "bass"/"pad"/"arp"/"lead" borrow any instrument voice (extra voices are 9+), and
# melodies are composed from a seed by compose_melody(). Originals are untouched: a song
# without those keys renders exactly as before.
#
# STAGE MODULES (stages 9+, scripts/stages/): each module's get_song() is built the same way
# as an alternative and plays as that stage's original; its slot ("stage_9" ...) joins the
# picker automatically, with the module's get_song_alternatives() as its alternatives.
#
# RECORDED TRACKS (scripts/music_tracks.gd): an MP3 from assets/music/ can take over a slot.
# It plays on its own AudioStreamPlayer (looping at its loop points) instead of the synth, is
# the slot's default, and is listed in the picker after the slot's alternatives.

enum Mode { NONE, TITLE, STAGE, BOSS, HYPERSPACE }

const MIX_RATE: float = 44100.0
const DELAY_MAX: int = 66200 # 1.5 s, room for the glacier's long echo

const SCALE_MINOR: Array[int] = [0, 2, 3, 5, 7, 8, 10]
const SCALE_DORIAN: Array[int] = [0, 2, 3, 5, 7, 9, 10]
const SCALE_MAJOR: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const SCALE_LYDIAN: Array[int] = [0, 2, 4, 6, 7, 9, 11]
const SCALE_PHRYGIAN: Array[int] = [0, 1, 3, 5, 7, 8, 10]
const SCALE_MIXOLYDIAN: Array[int] = [0, 2, 4, 5, 7, 9, 10]
const SCALE_HARMONIC_MINOR: Array[int] = [0, 2, 3, 5, 7, 8, 11]
const SCALE_PHRYGIAN_DOM: Array[int] = [0, 1, 4, 5, 7, 8, 10]

# Alternative tracks Matthew can audition and pick per slot (Options > Soundtrack).
const Candidates = preload("res://scripts/music_candidates.gd")
# Recorded MP3 tracks and their loop points.
const Tracks = preload("res://scripts/music_tracks.gd")

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
	"glide": 32.0,            # lead portamento speed between notes; 0 = notes start on pitch (no slide)
	"vib": 0.004,             # lead vibrato depth (fraction of pitch)
	"delay_beats": 0.75,      # echo time in beats
	"delay_fb": 0.34,         # echo feedback
	"master_lp": 1.0,         # one-pole low-pass coefficient on the whole mix; 1.0 = bypass
	"crush": 1,               # lead sample-and-hold length in samples (bit-crush); 1 = off
	# Instrument voices. -1 = use the voice that belongs to "style" (the groove); any
	# other value borrows another style's instrument or one of the extra voices 9+.
	"bass": -1,
	"pad": -1,
	"arp": -1,
	"lead": -1,
	"gv": 0,                  # groove variant (pattern choice) for the extra grooves 9+
	"bass_decay": -1.0,       # envelope decay overrides; -1 = the voice's own value
	"arp_decay": -1.0,
	"stab_decay": -1.0,
	"kick_decay": 9.2,        # drum kit tuning
	"kick_base": 44.0,
	"kick_sweep": 125.0,
	"snare_body": 0.34,
	"snare_noise": 0.19,
	"snare_lp": 0.22,
	"hat_amp": 0.075,
	# Fuller arrangement layers added on top of every groove (see _trigger_layers):
	# crash cymbals at section changes, claps on the backbeat, ghost hi-hats, a build-up
	# snare roll, a countermelody in the chorus, and a sub-octave under the bass.
	"energy": -1,             # 0 calm / 1 normal / 2 intense; -1 = from the groove (GROOVE_ENERGY)
	"bass_gain": 1.45,        # overall bass level
	"sub_mix": -1.0,          # sub-octave sine under the bass; -1 = from the energy
	"kick_gain": 1.25,
	"counter": 1,             # 1 = play the chorus countermelody, 0 = off
}

# How busy the extra layers get for each groove (style 0-17).
const GROOVE_ENERGY: Array[int] = [2, 1, 0, 1, 0, 2, 0, 2, 2, 1, 2, 1, 1, 0, 1, 0, 2, 1]

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
var _glide: float = 32.0
var _vib: float = 0.004
var _delay_fb: float = 0.34
var _master_lp: float = 1.0
var _master_lp_l: float = 0.0
var _master_lp_r: float = 0.0
var _crush: int = 1
var _crush_count: int = 0
var _crush_hold: float = 0.0
var _v_bass: int = 0
var _v_pad: int = 0
var _v_arp: int = 0
var _v_lead: int = 0
var _gv: int = 0
var _bass_dec: float = 5.6
var _bass_atk_rate: float = 420.0
var _arp_dec: float = 8.2
var _stab_dec: float = 11.0
var _kick_dec: float = 9.2
var _kick_base: float = 44.0
var _kick_sweep: float = 125.0
var _snare_body: float = 0.34
var _snare_noise: float = 0.19
var _snare_lp_k: float = 0.22
var _hat_amp: float = 0.075
var _energy: int = 1
var _bass_gain: float = 1.45
var _sub_mix: float = 0.3
var _add_sub: bool = true
var _kick_gain: float = 1.25
var _counter_on: bool = true

# Extra layers: crash cymbal, clap and the chorus countermelody voice.
var _crash_env: float = 0.0
var _crash_prev: float = 0.0
var _clap_env: float = 0.0
var _clap_t: float = 0.0
var _clap_lp: float = 0.0
var _ca_p: float = 0.0
var _ca_freq: float = 440.0
var _ca_env: float = 0.0
var _ca_atk: float = 0.0

# Chosen alternative per slot ("title", "stage_1".."stage_<N>", "boss", "hyperspace");
# 0 or missing = the original track. Set from the save by MetaSave.
var picks: Dictionary = {}
var _preview_slot: String = ""
var _preview_idx: int = 0
var _cand_cache: Dictionary = {}

# Recorded tracks play here instead of through the generator (see _start_recording).
var _file_player: AudioStreamPlayer
var _recordings: Dictionary = {} # file path -> AudioStreamMP3 with its loop set up

# Bass state
var _bass_p1: float = 0.0
var _bass_p2: float = 0.0
var _bass_sub_p: float = 0.0
var _bass_bend_p: float = 0.0
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
	# 0: OUTER ORBIT - Heroic Launch Anthem (136 BPM, E Mixolydian)
	# Galloping picked bass, brass-section stabs, a hollow square lead doubled an octave
	# below, and a straight rock kit. The lead starts every note on pitch (no portamento)
	# and stays between E4 and G#5. Section 3 plays its own bridge ("mel_c") instead of
	# the generic high climb.
	# Chords (scale degrees): 0 = I (E), -1 = bVII (D), 3 = IV (A), 4 = v (Bm), -2 = vi (C#m).
	{
		"style": 0, "root": 40, "bpm": 136.0, "scale": SCALE_MIXOLYDIAN, "delay_wet": 0.22,
		"lead_attack": 120.0, "lead_decay": 1.3, "harm_int": -7, "glide": 0.0, "vib": 0.0025,
		"delay_beats": 0.75, "delay_fb": 0.30,
		"prog_a": [0, -1, 3, 0,  0, -1, 3, 4],
		"prog_b": [3, 0, -1, 0,  -2, 3, -1, -1],
		# Verse: a rising call (E-B-E') answered by a falling line over D and A.
		"mel_a": [
			0,-99,-99,4, -99,-99,7,-99,  6,-99,4,-99,  2,-99,4,-99,
			6,-99,-99,-99, 5,-99,3,-99,  1,-99,-99,3,  -99,-99,-99,-99,
			3,-99,-99,5, -99,-99,7,-99,  8,-99,7,-99,  5,-99,3,-99,
			4,-99,-99,-99, -99,-99,-99,-99, 2,-99,3,-99, 4,-99,-99,-99,
		],
		# Chorus: held E' and G#' up top, landing on F#'-D'-F#' over the bVII.
		"mel_b": [
			7,-99,-99,-99, 7,-99,8,-99,  9,-99,-99,8,  -99,-99,7,-99,
			7,-99,-99,-99, -99,-99,4,-99, 5,-99,7,-99, -99,-99,-99,-99,
			8,-99,-99,-99, 6,-99,-99,-99, 5,-99,6,-99, 8,-99,-99,-99,
			7,-99,-99,-99, -99,-99,-99,-99, -99,-99,-99,-99, 3,-99,4,-99,
		],
		# Bridge (8 bars): 4 calm bars over the drum-less breakdown, then a rising
		# arpeggiated build back into the verse.
		"mel_c": [
			4,-99,-99,-99, -99,-99,-99,-99, 2,-99,-99,-99, 4,-99,-99,-99,
			3,-99,-99,-99, -99,-99,-99,-99, 5,-99,-99,-99, -99,-99,-99,-99,
			7,-99,-99,-99, -99,-99,6,-99,   5,-99,-99,-99, 3,-99,-99,-99,
			4,-99,-99,-99, -99,-99,-99,-99, -99,-99,-99,-99, -99,-99,-99,-99,
			5,-99,7,-99, 9,-99,7,-99,  5,-99,7,-99,  9,-99,-99,-99,
			3,-99,5,-99, 7,-99,5,-99,  3,-99,5,-99,  7,-99,-99,-99,
			6,-99,8,-99, 6,-99,5,-99,  3,-99,5,-99,  6,-99,8,-99,
			6,-99,-99,-99, 5,-99,-99,-99, 4,-99,-99,-99, 3,-99,4,5,
		],
	},
	# 1: STARCRUISER - Swung Slap-FM Funk & Clavinet Stabs in a dry metal hull (124 BPM, D Dorian)
	{
		"style": 1, "root": 38, "bpm": 124.0, "scale": SCALE_DORIAN, "delay_wet": 0.16,
		"swing": 0.10, "voicing": [0, 2, 4, 6], "delay_beats": 0.25, "delay_fb": 0.22, "glide": 55.0,
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
	_file_player = AudioStreamPlayer.new()
	_file_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_file_player)
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
	var db: float = -80.0
	if music_volume > 0.01:
		var duck_db: float = -6.5 if paused_duck else 0.0
		db = linear_to_db(music_volume * 0.72) + duck_db
	_player.volume_db = db
	# The recordings are about as loud as the synth (RMS ~0.19 vs 0.17-0.22), so same gain.
	_file_player.volume_db = db


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


# --- Soundtrack slots and alternative tracks -------------------------------------------

# Every slot in picker order: title, one per stage (stage_1 .. stage_<N>, so stage modules get
# theirs automatically), boss, hyperspace.
func get_slot_keys() -> Array[String]:
	var keys: Array[String] = ["title"]
	for i: int in range(StageData.stage_count()):
		keys.append("stage_%d" % (i + 1))
	keys.append("boss")
	keys.append("hyperspace")
	return keys


# The stage module behind a "stage_<N>" slot, or null (stages 1-8 and the other slots).
func _slot_module(slot: String) -> RefCounted:
	if not slot.begins_with("stage_"):
		return null
	var idx: int = int(slot.substr(6)) - 1
	if idx < StageData.BUILTIN_STAGES or idx >= StageData.stage_count():
		return null
	return StageData.get_module(idx)


func is_module_slot(slot: String) -> bool:
	return _slot_module(slot) != null


# A slot's alternatives: music_candidates.gd for the built-in slots, the module's own list for a
# stage module's slot.
func _slot_candidates(slot: String) -> Array:
	var slots: Dictionary = Candidates.SLOTS
	if slots.has(slot):
		return slots[slot]
	var m: RefCounted = _slot_module(slot)
	if m != null:
		return m.call("get_song_alternatives")
	return []


func set_picks(new_picks: Dictionary) -> void:
	picks = new_picks
	_cand_cache.clear()


# Shipped default per slot for players who haven't picked (0 = original, n = alternative #n
# as numbered in the picker). These are Matthew's picks; a slot left out plays its original.
# A slot with a recording (music_tracks.gd) defaults to the recording instead: stage_1 and
# stage_2 play his MP3s (his synth picks there were #3 ORBITAL DRIVE and #2 ENGINE ROOM).
const DEFAULT_PICKS: Dictionary = {
	"title": 2,   # HEROES ASSEMBLE
	"stage_3": 5, # JETSTREAM
	"stage_4": 3, # VINE RUNNER
	"stage_5": 3, # BLIZZARD
	"stage_6": 3, # ERUPTION
	"stage_7": 4, # DEEP CURRENT
	"stage_8": 2, # GLITCH PROTOCOL
	"boss": 1,    # NEON MEDUSA II
}


func get_pick(slot: String) -> int:
	var fallback: int = recording_index(slot) if has_recording(slot) else int(DEFAULT_PICKS.get(slot, 0))
	return clampi(int(picks.get(slot, fallback)), 0, candidate_count(slot))


func candidate_count(slot: String) -> int:
	return _slot_candidates(slot).size() + (1 if has_recording(slot) else 0)


func has_recording(slot: String) -> bool:
	return Tracks.TRACKS.has(slot)


# A recording's place in the slot's list: right after the alternatives (-1 if it has none).
func recording_index(slot: String) -> int:
	return _slot_candidates(slot).size() + 1 if has_recording(slot) else -1


# Index 0 is the original track; 1.. are the alternatives (music_candidates.gd, or a stage
# module's get_song_alternatives()), then the slot's recording if it has one.
func _candidate_entry(slot: String, idx: int) -> Dictionary:
	if idx == recording_index(slot):
		return Tracks.TRACKS[slot]
	var arr: Array = _slot_candidates(slot)
	return arr[idx - 1]


func candidate_name(slot: String, idx: int) -> String:
	if idx <= 0:
		return "ORIGINAL"
	return String(_candidate_entry(slot, idx)["name"])


func candidate_info(slot: String, idx: int) -> String:
	if idx <= 0:
		return "THE TRACK THE GAME SHIPPED WITH"
	return String(_candidate_entry(slot, idx).get("info", ""))


func slot_key(mode: Mode, stage_idx: int) -> String:
	match mode:
		Mode.TITLE:
			return "title"
		Mode.STAGE:
			return "stage_%d" % (StageData.wrap_stage(stage_idx) + 1)
		Mode.BOSS:
			return "boss"
		Mode.HYPERSPACE:
			return "hyperspace"
	return ""


# Plays one slot's track (original or an alternative) regardless of the saved pick,
# for the soundtrack picker. Call end_preview() to go back to the saved picks.
func preview(slot: String, idx: int) -> void:
	_preview_slot = slot
	_preview_idx = idx
	paused_duck = false
	var mode: Mode = Mode.TITLE
	var stage: int = current_stage_idx
	if slot.begins_with("stage_"):
		mode = Mode.STAGE
		stage = int(slot.substr(6)) - 1
	elif slot == "boss":
		mode = Mode.BOSS
	elif slot == "hyperspace":
		mode = Mode.HYPERSPACE
		_hyper_sweep = 0.0
	_switch_state(mode, stage, true)


func end_preview() -> void:
	_preview_slot = ""
	_preview_idx = 0


# Leaves the picker: restarts what was playing before (with any newly saved pick).
func resume_after_preview(mode: Mode, stage_idx: int) -> void:
	end_preview()
	paused_duck = false
	if mode == Mode.HYPERSPACE or mode == Mode.NONE:
		mode = Mode.STAGE if mode == Mode.HYPERSPACE else Mode.TITLE
	_switch_state(mode, stage_idx, true)


func _resolve_song(mode: Mode, stage_idx: int) -> Dictionary:
	if mode == Mode.NONE:
		return {}
	var slot: String = slot_key(mode, stage_idx)
	var idx: int = _preview_idx if slot == _preview_slot else get_pick(slot)
	if idx > 0 and idx == recording_index(slot):
		return Tracks.TRACKS[slot]
	if idx > 0 and idx <= candidate_count(slot):
		return _candidate_song(slot, idx)
	match mode:
		Mode.STAGE:
			if stage_idx < STAGE_SONGS.size():
				return STAGE_SONGS[stage_idx]
			return _module_song(stage_idx)
		Mode.BOSS:
			return BOSS_SONG
	return {}


# A stage module's own song (stages 9+), built like an alternative track.
func _module_song(stage_idx: int) -> Dictionary:
	var m: RefCounted = StageData.get_module(stage_idx)
	if m == null:
		return STAGE_SONGS[posmod(stage_idx, STAGE_SONGS.size())]
	var key: String = "module:" + String(StageData.get_stage(stage_idx)["id"])
	if not _cand_cache.has(key):
		_cand_cache[key] = _build_song(m.call("get_song"))
	return _cand_cache[key]


# Builds the playable song for an alternative.
func _candidate_song(slot: String, idx: int) -> Dictionary:
	var key: String = "%s:%d" % [slot, idx]
	if _cand_cache.has(key):
		return _cand_cache[key]
	var arr: Array = _slot_candidates(slot)
	var song: Dictionary = _build_song(arr[idx - 1])
	_cand_cache[key] = song
	return song


# The shared base settings, the song's own settings, and melodies composed from its seed when
# it doesn't spell them out.
func _build_song(c: Dictionary) -> Dictionary:
	var song: Dictionary = Candidates.BASE.duplicate(true)
	song.merge(c.duplicate(true), true)
	if song.has("kit"):
		var kits: Dictionary = Candidates.KITS
		var kit: Dictionary = kits[String(song["kit"])]
		song.merge(kit, false)
	if not song.has("hyper"):
		if not song.has("mel_a"):
			song["mel_a"] = compose_melody(song, false)
		if not song.has("mel_b"):
			song["mel_b"] = compose_melody(song, true)
	return song


func _switch_state(new_mode: Mode, stage_idx: int, force: bool = false) -> void:
	_apply_volume_db()
	var wrapped_stage: int = StageData.wrap_stage(stage_idx)
	if not force and current_mode == new_mode and (new_mode == Mode.BOSS or current_stage_idx == wrapped_stage) and _player != null and (_player.playing or _file_player.playing):
		return
	current_mode = new_mode
	current_stage_idx = wrapped_stage
	_song = _resolve_song(new_mode, current_stage_idx)
	if _song.has("file"):
		_player.stop()
		_playback = null
		_start_recording(_song)
		return
	_file_player.stop()
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
	_crash_env = 0.0
	_clap_env = 0.0
	_ca_env = 0.0
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


# Plays a recorded track (music_tracks.gd) from the top; it loops by itself after that.
func _start_recording(track: Dictionary) -> void:
	var stream: AudioStreamMP3 = recording_stream(track)
	if stream == null:
		_file_player.stop()
		return
	_file_player.stream = stream
	_file_player.play()


# The track's MP3, loaded once, set to play through once and then repeat loop_start..loop_end.
# AudioStreamMP3 restarts at loop_offset after beat_count beats at its bpm, so the bpm is nudged
# from the song's tempo to make that land exactly on loop_end.
func recording_stream(track: Dictionary) -> AudioStreamMP3:
	var path: String = String(track["file"])
	if _recordings.has(path):
		return _recordings[path]
	var stream: AudioStreamMP3 = load(path) as AudioStreamMP3
	if stream == null:
		push_error("GenesisMusic: could not load recording %s" % path)
		return null
	var loop_end: float = float(track["loop_end"])
	var beats: int = maxi(1, roundi(loop_end / MIX_RATE * float(track["bpm"]) / 60.0))
	stream.loop = true
	# +0.25 sample: Godot rounds the seek down to a whole sample.
	stream.loop_offset = (float(track["loop_start"]) + 0.25) / MIX_RATE
	stream.beat_count = beats
	stream.bpm = float(beats) * 60.0 * MIX_RATE / loop_end
	_recordings[path] = stream
	return stream


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
	_glide = float(_song_param("glide"))
	_vib = float(_song_param("vib"))
	_delay_fb = float(_song_param("delay_fb"))
	_master_lp = float(_song_param("master_lp"))
	_crush = maxi(1, int(_song_param("crush")))
	var vb: int = int(_song_param("bass"))
	var vp: int = int(_song_param("pad"))
	var va: int = int(_song_param("arp"))
	var vl: int = int(_song_param("lead"))
	_v_bass = _style if vb < 0 else vb
	_v_pad = _style if vp < 0 else vp
	_v_arp = _style if va < 0 else va
	_v_lead = _style if vl < 0 else vl
	_gv = int(_song_param("gv"))
	_bass_atk_rate = 14.0 if _v_bass == 12 else 420.0
	_bass_dec = float(_song_param("bass_decay"))
	if _bass_dec <= 0.0:
		match _v_bass:
			1: _bass_dec = 7.5
			4, 6: _bass_dec = 1.1
			0: _bass_dec = 6.5
			9: _bass_dec = 2.2
			10: _bass_dec = 1.0
			11: _bass_dec = 4.5
			12: _bass_dec = 0.9
			13: _bass_dec = 1.3
			14: _bass_dec = 5.0
			_: _bass_dec = 5.6
	_arp_dec = float(_song_param("arp_decay"))
	if _arp_dec <= 0.0:
		match _v_arp:
			2: _arp_dec = 6.0
			3: _arp_dec = 11.0
			4, 6: _arp_dec = 4.8
			9: _arp_dec = 9.0
			10: _arp_dec = 3.0
			11: _arp_dec = 5.0
			12: _arp_dec = 5.5
			_: _arp_dec = 8.2
	_stab_dec = float(_song_param("stab_decay"))
	if _stab_dec <= 0.0:
		match _v_pad:
			6: _stab_dec = 5.5
			0: _stab_dec = 7.0
			13: _stab_dec = 6.0
			_: _stab_dec = 11.0
	_kick_dec = float(_song_param("kick_decay"))
	_kick_base = float(_song_param("kick_base"))
	_kick_sweep = float(_song_param("kick_sweep"))
	_snare_body = float(_song_param("snare_body"))
	_snare_noise = float(_song_param("snare_noise"))
	_snare_lp_k = float(_song_param("snare_lp"))
	_hat_amp = float(_song_param("hat_amp"))
	_energy = int(_song_param("energy"))
	if _energy < 0:
		_energy = GROOVE_ENERGY[clampi(_style, 0, GROOVE_ENERGY.size() - 1)]
	_bass_gain = float(_song_param("bass_gain"))
	_sub_mix = float(_song_param("sub_mix"))
	if _sub_mix < 0.0:
		var sub_by_energy: Array[float] = [0.28, 0.34, 0.40]
		_sub_mix = sub_by_energy[clampi(_energy, 0, 2)]
	# Voices that already carry their own sub, or shouldn't get one (8-bit, 808), skip it.
	_add_sub = not (_v_bass in [0, 5, 7, 8, 9, 10, 13])
	_kick_gain = float(_song_param("kick_gain"))
	_counter_on = int(_song_param("counter")) != 0


func _get_current_bpm() -> float:
	if _song.has("bpm"):
		return float(_song["bpm"])
	match current_mode:
		Mode.TITLE:
			return 98.0
		Mode.HYPERSPACE:
			return 132.0
	return 120.0


func _process(_delta: float) -> void:
	if current_mode == Mode.NONE or _player == null:
		return
	if _song.has("file"):
		return # a recording: _file_player streams it by itself
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

		if _song.is_empty():
			if current_mode == Mode.TITLE:
				buf[i] = _synth_title_frame(dt)
			else:
				buf[i] = _synth_hyperspace_frame(dt)
		else:
			buf[i] = _synth_ensemble_frame(dt, _style)
	return buf


func _set_pad_chord(root_midi: int, scale: Array, chord_deg: int) -> void:
	for k: int in range(4):
		_pad_target_freqs[k] = _midi_to_hz(_deg_to_midi(root_midi + 12, scale, chord_deg + int(_voicing[k])))
	if _pad_swell < 0.05 or _glide <= 0.0:
		for k: int in range(4):
			_pad_freqs[k] = _pad_target_freqs[k]


func _trigger_step() -> void:
	# Original title and hyperspace jingles (no song dictionary).
	if _song.is_empty():
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
	if _song.has("hyper"):
		_trigger_hyper_candidate()
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
	var snare_before: float = maxf(_snare_body_env, _rim_env)
	var hat_before: float = _hat_env
	_trigger_style_rhythm(style, root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)
	_trigger_layers(root, scale, chord_deg, s16, bar8, section, is_breakdown, maxf(_snare_body_env, _rim_env) > snare_before + 0.05, _hat_env > hat_before + 0.02)

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
	elif song.has("mel_c"):
		# Song-specific bridge for the last section (over the breakdown, then the build).
		var mc: Array = song["mel_c"]
		m_deg = int(mc[sec_step % mc.size()])
		use_harmony = (bar8 >= 4)
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
		if _lead_env < 0.15 or _glide <= 0.0:
			_lead_freq = _lead_target_freq
		_lead_env = 0.96
		_lead_atk = 0.0

		if use_harmony:
			_harm_target_freq = _midi_to_hz(_deg_to_midi(root + _lead_oct, scale, m_deg + _harm_int))
			if _harm_env < 0.15 or _glide <= 0.0:
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

		0: # STAGE 1 (OUTER ORBIT): Heroic rock. Galloping 8th-note picked bass (octave pops on the
			# "and" of 2 and 4), brass stabs (on-beat in the verse, syncopated in the chorus),
			# a sparkling arpeggio from section 1 on, and a straight rock kit with a crash on each section.
			var is_chorus: bool = (section == 2 or (section == 3 and bar8 >= 4))
			if is_breakdown:
				if s16 == 0 or s16 == 8:
					_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg))
					_bass_env = 0.85
					_bass_atk = 0.0
			elif s16 % 2 == 0:
				var gallop: Array[int] = [0, 0, 0, 7, 0, 0, 4, 7]
				_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, chord_deg + gallop[s16 / 2]))
				_bass_env = 1.0 if (s16 % 4 == 0) else 0.78
				_bass_atk = 0.0
			if is_chorus:
				if s16 == 0 or s16 == 3 or s16 == 6 or s16 == 10 or s16 == 12:
					_stab_env = 1.0
			elif not is_breakdown and (s16 == 0 or s16 == 8) and (section >= 1 or bar8 >= 2):
				_stab_env = 0.8
			elif is_breakdown and s16 == 0:
				_stab_env = 0.55
			if section >= 1 and not is_breakdown:
				var sparkle: Array[int] = [0, 2, 4, 7]
				if is_chorus or s16 % 2 == 0:
					_arp_freq = _midi_to_hz(_deg_to_midi(root + 24, scale, chord_deg + sparkle[(pos / (1 if is_chorus else 2)) % 4]))
					_arp_env = (0.55 if s16 % 2 == 0 else 0.32) if is_chorus else 0.42
					_arp_atk = 0.0
			if bar8 == 7 and s16 >= 12:
				var fill: Array[float] = [190.0, 150.0, 118.0, 92.0]
				_tom_freq = fill[s16 - 12]
				_tom_env = 0.95
				_tom_phase = 0.0
			elif not is_breakdown:
				if s16 == 0 or s16 == 8 or s16 == 10:
					_kick_env = 1.0
					_kick_phase = 0.0
				if s16 == 4 or s16 == 12:
					_snare_body_env = 0.95
					_snare_gate_time = 0.09
					_snare_phase = 0.0
				if bar8 == 0 and s16 == 0:
					_hat_env = 1.0 # crash at the top of each section
					_hat_decay = 3.5
				elif s16 % 2 == 0 and not (bar8 == 0 and s16 < 6): # 8th hats once the crash has rung
					var open_hat: bool = is_chorus and s16 % 4 == 2
					_hat_env = 0.62 if open_hat else 0.42
					_hat_decay = 16.0 if open_hat else 40.0

		9: _groove_chip(root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)
		10: _groove_dnb(root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)
		11: _groove_outrun(root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)
		12: _groove_orchestra(root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)
		13: _groove_ambient(root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)
		14: _groove_boombap(root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)
		15: _groove_bossa(root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)
		16: _groove_industrial(root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)
		17: _groove_six_eight(root, scale, chord_deg, s16, bar8, section, is_breakdown, pos)

		_: # STYLE 8 (UNIVERSAL NEON MEDUSA BOSS THEME):
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


# Fuller arrangement, layered on top of whatever the groove played this step.
# snare_hit / hat_hit say whether the groove itself just hit a snare (or rim) / a hat.
func _trigger_layers(root: int, scale: Array, cd: int, s16: int, bar8: int, section: int, brk: bool, snare_hit: bool, hat_hit: bool) -> void:
	var bar_len: int = _bar_steps
	var cho: bool = section == 2 or (section == 3 and bar8 >= 4)
	# Crash cymbal into the verse, the chorus and the build after the breakdown.
	if _energy >= 1 and s16 == 0 and ((bar8 == 0 and (section == 1 or section == 2)) or (section == 3 and bar8 == 4)):
		_crash_env = 0.85 if _energy == 2 else 0.6
	# Clap layered on the groove's backbeat.
	if _energy >= 1 and snare_hit and not brk:
		var backbeat: bool = (s16 == 4 or s16 == 12) if bar_len == 16 else (s16 == 6 if String(_song.get("meter", "")) == "68" else (s16 == 4 or s16 == 8))
		if backbeat:
			_clap_env = 0.9 if _energy == 2 else 0.6
			_clap_t = 0.0
	# Ghost 16th hi-hats where the groove leaves gaps (only when no hat is ringing).
	if _energy >= 1 and section >= 1 and not brk and not hat_hit and _hat_env < 0.05 and s16 % 2 == 1:
		_hat_env = 0.2 if _energy == 2 else 0.14
		_hat_decay = 70.0
	# Snare roll building into the chorus (intense songs, 4/4 only).
	if _energy == 2 and bar_len == 16 and section == 1 and bar8 == 7 and s16 >= 8 and not snare_hit:
		_snare_body_env = 0.3 + 0.07 * float(s16 - 8)
		_snare_gate_time = 0.03
		_snare_phase = 0.0
	# Countermelody: long guide tones (the chord's 5th, then its 3rd) an octave above the lead's
	# home, on each half bar of the chorus; calm songs also play it in the second verse.
	if _counter_on and (s16 == 0 or s16 == bar_len / 2) and not brk and (cho or (_energy == 0 and section == 1 and bar8 >= 4)):
		var tone: int = 4 if s16 == 0 else 2
		if bar8 % 2 == 1:
			tone += 3 if s16 == 0 else 2
		_ca_freq = _midi_to_hz(_deg_to_midi(root + 36, scale, cd + tone))
		_ca_env = 0.9
		_ca_atk = 0.0


# =========================================================================================
# EXTRA GROOVES (styles 9-17) used by the alternative tracks in music_candidates.gd.
# Each one sets notes and drum hits for one 16th step; "_gv" picks a pattern variant.
# =========================================================================================
func _bn(root: int, scale: Array, deg: int, vel: float) -> void:
	_bass_freq = _midi_to_hz(_deg_to_midi(root, scale, deg))
	_bass_env = vel
	_bass_atk = 0.0


func _an(base_midi: int, scale: Array, deg: int, vel: float) -> void:
	_arp_freq = _midi_to_hz(_deg_to_midi(base_midi, scale, deg))
	_arp_env = vel
	_arp_atk = 0.0


func _kk(vel: float, duck: float = 1.0) -> void:
	_kick_env = vel
	_kick_phase = 0.0
	if duck < 1.0:
		_sidechain = duck


func _sn(vel: float, gate: float) -> void:
	_snare_body_env = vel
	_snare_gate_time = gate
	_snare_phase = 0.0


func _ht(vel: float, decay: float) -> void:
	_hat_env = vel
	_hat_decay = decay


func _tm(freq: float, vel: float) -> void:
	_tom_freq = freq
	_tom_env = vel
	_tom_phase = 0.0


func _is_chorus(section: int, bar8: int) -> bool:
	return section == 2 or (section == 3 and bar8 >= 4)


# 9: 8-BIT CHIPTUNE. Triangle bass (octave 8ths / gallop / walking), a fast broken-chord
# pulse arpeggio, and a noise kit with a snare roll into every 8th bar.
func _groove_chip(root: int, scale: Array, cd: int, s16: int, bar8: int, section: int, brk: bool, pos: int) -> void:
	var cho: bool = _is_chorus(section, bar8)
	if brk:
		if s16 == 0 or s16 == 8:
			_bn(root, scale, cd, 0.9)
	else:
		match _gv:
			1:
				if s16 % 4 != 1:
					var gal: Array[int] = [0, -99, 0, 4]
					_bn(root, scale, cd + gal[s16 % 4], 1.0 if s16 % 4 == 0 else 0.8)
			2:
				if s16 % 2 == 0:
					var walk: Array[int] = [0, 2, 4, 5, 7, 5, 4, 2]
					_bn(root, scale, cd + walk[s16 / 2], 0.95)
			_:
				if s16 % 2 == 0:
					_bn(root, scale, cd + (7 if s16 % 4 == 2 else 0), 0.95)
	if section >= 1 or bar8 >= 4:
		var chord_set: Array[int] = [0, 2, 4]
		if cho:
			chord_set = [0, 2, 4, 7]
		_an(root + 24, scale, cd + chord_set[pos % chord_set.size()], 0.62 if s16 % 4 == 0 else 0.45)
	if brk:
		return
	if bar8 == 7 and s16 >= 12:
		_sn(0.55 + 0.12 * float(s16 - 12), 0.03)
		return
	if s16 == 0 or s16 == 8 or (cho and (s16 == 10 or s16 == 6)):
		_kk(1.0)
	if s16 == 4 or s16 == 12:
		_sn(0.95, 0.05)
	if s16 % 2 == 0:
		_ht(0.5 if s16 % 4 == 2 else 0.3, 60.0)


# 10: DRUM & BASS (play at 160-176 BPM). Two-step breakbeat with ghost snares, a long
# Reese bass, and sparse bell or pluck accents. Variant 1 is "liquid": rolling 16th hats.
func _groove_dnb(root: int, scale: Array, cd: int, s16: int, bar8: int, section: int, brk: bool, pos: int) -> void:
	var cho: bool = _is_chorus(section, bar8)
	if s16 == 0:
		_bn(root, scale, cd, 1.0)
	elif not brk and s16 == 10:
		_bn(root, scale, cd + (0 if _gv == 0 else 4), 0.85)
	elif not brk and s16 == 14 and bar8 % 2 == 1:
		_bn(root, scale, cd + 7, 0.7)
	if section >= 1 or brk:
		if s16 == 0 or s16 == 6 or (s16 == 12 and bar8 % 2 == 1):
			var bell: Array[int] = [4, 2, 7]
			_an(root + 24, scale, cd + bell[(s16 / 6) % 3], 0.75)
		elif cho and s16 == 9:
			_an(root + 36, scale, cd, 0.4)
	if brk:
		return
	if bar8 == 7 and s16 >= 12:
		_sn(0.6 + 0.1 * float(s16 - 12), 0.04)
		return
	if s16 == 0 or s16 == 10 or (_gv == 1 and s16 == 2):
		_kk(1.0, 0.5)
	if s16 == 4 or s16 == 12:
		_sn(1.0, 0.07)
	elif s16 == 7 or s16 == 15 or (cho and s16 == 9):
		_sn(0.26, 0.0)
	if _gv == 1:
		_ht(0.42 if s16 % 4 == 2 else 0.2, 44.0)
	elif s16 % 2 == 0:
		_ht(0.5 if s16 % 4 == 2 else 0.28, 36.0)
	if bar8 == 0 and s16 == 0 and section >= 1:
		_ht(0.9, 4.0)


# 11: OUTRUN / SYNTHWAVE DRIVE. Sequenced 16th-note bass (variant 1: octave 8ths), big gated
# snare, a soft 16th arpeggio from section 1, tom fills, and four-on-the-floor in the chorus.
func _groove_outrun(root: int, scale: Array, cd: int, s16: int, bar8: int, section: int, brk: bool, pos: int) -> void:
	var cho: bool = _is_chorus(section, bar8)
	if brk:
		if s16 % 8 == 0:
			_bn(root, scale, cd, 0.85)
	elif _gv == 1:
		if s16 % 2 == 0:
			_bn(root, scale, cd + (7 if s16 % 4 == 2 else 0), 0.95)
	else:
		_bn(root, scale, cd + (7 if s16 % 8 == 6 else 0), 0.95 if s16 % 4 == 0 else 0.68)
	if (section >= 1 and not brk) or (brk and s16 % 2 == 0):
		var arp_set: Array[int] = [0, 2, 4, 7]
		_an(root + 24, scale, cd + arp_set[pos % 4], 0.5 if brk else 0.36)
	if brk:
		return
	if bar8 == 7 and s16 >= 12:
		var fill: Array[float] = [180.0, 140.0, 110.0, 86.0]
		_tm(fill[s16 - 12], 0.95)
		return
	if s16 == 0 or s16 == 8 or (cho and (s16 == 4 or s16 == 12)):
		_kk(1.0, 0.4)
	if s16 == 4 or s16 == 12:
		_trigger_gated_snare(0.95)
	if bar8 == 0 and s16 == 0:
		_ht(1.0, 3.5)
	elif s16 % 2 == 0:
		_ht(0.5 if s16 % 4 == 2 else 0.3, 30.0)


# 12: ORCHESTRAL. Variant 0 is a march: low strings on beats 1 and 3, timpani on the chord
# root, a rudimental snare and a harp in the chorus. Variant 1 is epic half-time taiko.
func _groove_orchestra(root: int, scale: Array, cd: int, s16: int, bar8: int, section: int, brk: bool, pos: int) -> void:
	var cho: bool = _is_chorus(section, bar8)
	var timp: float = clampf(_midi_to_hz(_deg_to_midi(root - 12, scale, cd)), 48.0, 110.0)
	if _gv == 1:
		if s16 == 0 or s16 == 6 or s16 == 10:
			_bn(root, scale, cd, 0.95 if s16 == 0 else 0.8)
			if not brk:
				_tm(timp * 1.1, 1.0 if s16 == 0 else 0.8)
				if s16 == 0:
					_kk(0.9)
		if not brk:
			if s16 == 8:
				_trigger_gated_snare(1.0)
			elif s16 == 3 or s16 == 7 or s16 == 14 or s16 == 15:
				_tm(165.0 if s16 < 14 else 140.0, 0.45)
	else:
		if s16 == 0:
			_bn(root, scale, cd, 0.95)
		elif s16 == 8 and not brk:
			_bn(root, scale, cd + 4, 0.8)
		if not brk:
			if bar8 == 7 and s16 >= 8:
				_tm(timp, 0.5 + 0.06 * float(s16 - 8))
			elif s16 == 0 or (cho and s16 == 8):
				_tm(timp, 1.0)
				_kk(0.7)
			var march: Array[float] = [0.7, 0.0, 0.0, 0.35, 0.9, 0.0, 0.35, 0.0, 0.6, 0.0, 0.0, 0.35, 0.9, 0.0, 0.4, 0.3]
			if march[s16] > 0.0:
				_sn(march[s16], 0.025)
	if cho or (brk and s16 % 4 == 0):
		if s16 % 2 == 0:
			var harp: Array[int] = [0, 2, 4, 7, 9, 7, 4, 2]
			_an(root + 24, scale, cd + harp[s16 / 2], 0.6)
	if not brk and bar8 == 0 and s16 == 0:
		_ht(1.0, 3.0)


# 13: AMBIENT. No drums: a long bass note each bar, sustained pad and slow arpeggio plucks
# (variant 1: a steady rising 8th arpeggio). Soft shaker and kick only in the chorus.
func _groove_ambient(root: int, scale: Array, cd: int, s16: int, bar8: int, section: int, brk: bool, pos: int) -> void:
	var cho: bool = _is_chorus(section, bar8)
	if s16 == 0:
		_bn(root, scale, cd, 0.8)
	if _gv == 1:
		if section >= 1 and s16 % 2 == 0:
			var up: Array[int] = [0, 2, 4, 7, 9, 7, 4, 2]
			_an(root + 24, scale, cd + up[s16 / 2], 0.45)
	elif s16 == 0 or s16 == 6 or s16 == 10:
		var pl: Array[int] = [4, 7, 9]
		_an(root + 24, scale, cd + pl[(s16 + bar8) % 3], 0.6)
	if cho and not brk:
		if s16 % 2 == 0:
			_ht(0.22, 30.0)
		if s16 == 0:
			_kk(0.5)
		elif s16 == 8:
			_rim_env = 0.35
			_rim_phase = 0.0


# 14: LO-FI BOOM-BAP (use "swing"). Kick on 1, the "and" of 2 and 3, snare on 2 and 4,
# electric-piano stabs that anticipate the beat, vibes in the chorus.
func _groove_boombap(root: int, scale: Array, cd: int, s16: int, bar8: int, section: int, brk: bool, pos: int) -> void:
	var cho: bool = _is_chorus(section, bar8)
	if s16 == 0:
		_bn(root, scale, cd, 1.0)
	elif not brk and s16 == 7:
		_bn(root, scale, cd + (7 if _gv == 1 else 0), 0.75)
	elif not brk and s16 == 10:
		_bn(root, scale, cd + (4 if bar8 % 2 == 1 else 0), 0.9)
	if s16 == 0 or (_gv == 0 and (s16 == 6 or s16 == 11)) or (_gv == 1 and s16 == 10):
		_stab_env = 1.0 if s16 == 0 else 0.75
	if cho and (s16 == 4 or s16 == 14):
		_an(root + 24, scale, cd + (4 if s16 == 4 else 7), 0.55)
	if brk:
		return
	if s16 == 0 or s16 == 7 or s16 == 10:
		_kk(1.0 if s16 != 7 else 0.7)
	if s16 == 4 or s16 == 12:
		_sn(0.85, 0.05)
	if s16 % 2 == 0:
		_ht(0.42 if s16 % 4 == 0 else 0.26, 40.0)
	elif s16 == 15 and bar8 % 2 == 1:
		_ht(0.5, 12.0)


# 15: BOSSA NOVA. Bass on 1 and 3 with anticipated fifths, strummed-guitar comping on the
# 2-bar bossa pattern, cross-stick clave, soft kick and a 16th shaker.
func _groove_bossa(root: int, scale: Array, cd: int, s16: int, bar8: int, section: int, brk: bool, pos: int) -> void:
	var cho: bool = _is_chorus(section, bar8)
	if s16 == 0:
		_bn(root, scale, cd, 1.0)
	elif s16 == 6:
		_bn(root, scale, cd + 4, 0.75)
	elif s16 == 8:
		_bn(root, scale, cd, 0.9)
	elif s16 == 14:
		_bn(root, scale, cd + 4, 0.7)
	var comp: Array[int] = [2, 6, 8, 12]
	if bar8 % 2 == 0:
		comp = [0, 3, 6, 10, 12]
	if comp.has(s16):
		_stab_env = 0.9
	if cho and (s16 == 0 or s16 == 10):
		_an(root + 24, scale, cd + (4 if s16 == 0 else 2), 0.55)
	if brk:
		return
	var clave: Array[int] = [4, 8]
	if bar8 % 2 == 0:
		clave = [0, 6, 12]
	if clave.has(s16):
		_rim_env = 0.7
		_rim_phase = 0.0
	if s16 == 0 or s16 == 8:
		_kk(0.6)
	elif s16 == 6 or s16 == 14:
		_kk(0.35)
	_ht(0.32 if s16 % 2 == 0 else 0.16, 45.0)


# 16: INDUSTRIAL / EBM. Machine 16th bass (variant 1: offbeat octave pump), saw stabs,
# four-on-the-floor with sidechain, gated snare, metallic clanks and 16th hats.
func _groove_industrial(root: int, scale: Array, cd: int, s16: int, bar8: int, section: int, brk: bool, pos: int) -> void:
	var cho: bool = _is_chorus(section, bar8)
	if brk:
		if s16 == 0:
			_bn(root, scale, cd, 0.9)
	elif _gv == 1:
		if s16 % 4 == 2:
			_bn(root, scale, cd, 1.0)
		elif s16 % 4 == 3:
			_bn(root, scale, cd + 7, 0.6)
	else:
		var mach: Array[int] = [0, 0, 7, 0, 0, 0, 7, 0, 0, 0, 7, 0, 0, 1, 0, 7]
		_bn(root, scale, cd + mach[s16], 1.0 if s16 % 4 == 0 else 0.72)
	if s16 == 0 or s16 == 10 or (cho and s16 == 6):
		_stab_env = 1.0
	if brk:
		return
	if bar8 == 7 and s16 >= 12:
		_tm(150.0 - 18.0 * float(s16 - 12), 0.9)
	if s16 % 4 == 0:
		_kk(1.0, 0.3)
	if s16 == 4 or s16 == 12:
		_trigger_gated_snare(0.9)
	if s16 == 6 or s16 == 14:
		_rim_env = 0.8
		_rim_phase = 0.0
	_ht(0.5 if s16 % 4 == 2 else 0.24, 50.0)
	if bar8 == 0 and s16 == 0:
		_ht(1.0, 3.5)


# 17: 6/8 BALLAD / EPIC (bar_steps 12, "meter": "68"): two dotted-quarter beats per bar.
# Kick on 1, a big snare on 2, 8th hats, an 8th-note arpeggio; variant 1 rolls the bass.
func _groove_six_eight(root: int, scale: Array, cd: int, s16: int, bar8: int, section: int, brk: bool, pos: int) -> void:
	var cho: bool = _is_chorus(section, bar8)
	if _gv == 1 and not brk:
		if s16 % 2 == 0:
			var roll: Array[int] = [0, 4, 7, 4, 7, 4]
			_bn(root, scale, cd + roll[s16 / 2], 0.9 if s16 == 0 else 0.65)
	elif s16 == 0:
		_bn(root, scale, cd, 1.0)
	elif s16 == 6 and not brk:
		_bn(root, scale, cd + 4, 0.75)
	if (section >= 1 or brk) and s16 % 2 == 0:
		var arp6: Array[int] = [0, 2, 4, 7, 4, 2]
		if cho:
			arp6 = [0, 4, 7, 9, 7, 4]
		_an(root + 24, scale, cd + arp6[s16 / 2], 0.5)
	if brk:
		return
	if bar8 == 7 and s16 >= 6:
		_tm(170.0 - 16.0 * float(s16 - 6), 0.9)
		return
	if s16 == 0 or (cho and s16 == 10):
		_kk(1.0)
	if s16 == 6:
		_trigger_gated_snare(0.95)
	if s16 % 2 == 0:
		_ht(0.4 if s16 % 6 == 0 else 0.26, 34.0)
	if bar8 == 0 and s16 == 0:
		_ht(1.0, 3.5)


# Short hyperspace-jump jingles (song has "hyper"). Each list is indexed by 16th step from
# the jump; -99 = nothing. The jump lasts ~2.6 s (about 22-26 steps).
func _trigger_hyper_candidate() -> void:
	var song: Dictionary = _song
	var root: int = int(song["root"])
	var scale: Array = song["scale"]
	var s: int = _step
	if s == 0:
		_set_pad_chord(root, scale, int(song.get("h_chord", 0)))
	var chords: Array = song.get("h_chords", [])
	if s < chords.size() and int(chords[s]) != -99:
		_set_pad_chord(root, scale, int(chords[s]))
		_stab_env = 1.0
	var arp: Array = song.get("h_arp", [])
	if s < arp.size() and int(arp[s]) != -99:
		_an(root + int(song.get("arp_oct", 24)), scale, int(arp[s]), 0.9)
	var lead: Array = song.get("h_lead", [])
	if s < lead.size() and int(lead[s]) != -99:
		_lead_target_freq = _midi_to_hz(_deg_to_midi(root + _lead_oct, scale, int(lead[s])))
		_lead_freq = _lead_target_freq
		_lead_env = 0.96
		_lead_atk = 0.0
	var bass: Array = song.get("h_bass", [])
	if s < bass.size() and int(bass[s]) != -99:
		_bn(root, scale, int(bass[s]), 1.0)
	var kicks: Array = song.get("h_kick", [])
	if kicks.has(s):
		_kk(0.9)
	var snares: Array = song.get("h_snare", [])
	if snares.has(s):
		_sn(0.35 + 0.65 * float(s) / 24.0, 0.04)
	var toms: Array = song.get("h_tom", [])
	if toms.has(s):
		_tm(200.0 - 5.0 * float(s), 0.85)
	var riser: int = int(song.get("h_riser", 0))
	if s < riser:
		_ht(0.2 + 0.8 * float(s) / float(riser), 14.0)
	if s == int(song.get("h_crash", -1)):
		_ht(1.0, 3.0)


# =========================================================================================
# MELODY COMPOSER for the alternative tracks. Builds an 8-bar melody over the song's
# 8-bar progression: a 2-bar motif, a development bar and a half cadence, then the motif
# again (moved onto the new chords), a climax bar and a full cadence. Strong beats always
# land on chord tones; weak beats move by step or skip; big leaps are followed by a step
# back the other way. Deterministic per "seed".
# =========================================================================================
const MEL_RHYTHMS: Dictionary = {
	"44": [
		["x.......x.......", "x.......x...x...", "x...........x...", "x.....x...x.....", "x.......x.....x.", "x...x.......x..."],
		["x...x...x.x.x...", "x..x..x.x...x...", "x.x...x.x...x...", "x...x.x...x.x...", "x..x..x...x.x...", "x.....x.x.x.x...", "x.x.x...x...x.x.", "x...x..x..x.x..."],
		["x.xxx.x.x.xxx.x.", "x.x.x.xxx.x.x...", "xx.x.x.xx.x.x...", "x.xx.x.x.xx.x.x.", "x.x.xxx.x.x.xx..", "xxx.x.x.xxx.x.x."],
		["x...x...x.......", "x.x.x...........", "x.......x.......", "x.....x.x.......", "x...x.x.x.......", "x..x..x........."],
	],
	"34": [
		["x...........", "x.......x...", "x...x.......", "x.......x.x."],
		["x...x...x...", "x.....x.x...", "x...x.x.x...", "x.x.x...x...", "x...x...x.x."],
		["x.x.x.x.x.x.", "x.xxx.x.x.x.", "x.x.x.xxx.x."],
		["x...x.......", "x...........", "x.x.x......."],
	],
	"68": [
		["x.....x.....", "x.........x.", "x...x.x....."],
		["x...x.x...x.", "x.x.x.x.....", "x.....x.x.x.", "x...x.x.x.x."],
		["x.x.x.x.x.x.", "xxx.x.x.x.x.", "x.x.xxx.x.x."],
		["x.....x.....", "x.x.x.......", "x..........."],
	],
}


func compose_melody(song: Dictionary, chorus: bool) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(song.get("seed", 1)) * 7919 + (104729 if chorus else 0)
	var bar_len: int = int(song.get("bar_steps", 16))
	var meter: String = String(song.get("meter", "44" if bar_len == 16 else "34"))
	var prog: Array = song["prog_b"] if chorus else song["prog_a"]
	var lo: int = int(song.get("mel_lo", 0))
	var hi: int = int(song.get("mel_hi", 9))
	if chorus:
		var lift: int = int(song.get("lift", 2))
		lo += lift
		hi += lift
	var dens: int = clampi(int(song.get("dens_b" if chorus else "dens_a", song.get("density", 1))), 0, 2)
	var lib: Array = MEL_RHYTHMS[meter]
	var pool: Array = lib[dens]
	var cad_pool: Array = lib[3]
	var r1: String = String(pool[rng.randi() % pool.size()])
	var r2: String = r1 if rng.randf() < 0.45 else String(pool[rng.randi() % pool.size()])
	var r3: String = String(pool[rng.randi() % pool.size()])
	var c1: String = String(cad_pool[rng.randi() % cad_pool.size()])
	var c2: String = String(cad_pool[rng.randi() % cad_pool.size()])
	var plan: Array[String] = [r1, r2, r1, c1, r1, r2, r3, c2]
	var strong: Array[int] = [0, 4, 8, 12]
	if meter == "68":
		strong = [0, 6]
	elif bar_len == 12:
		strong = [0, 4, 8]
	var mid: int = (lo + hi) / 2
	var targets: Array[int] = [mid - 1, mid, mid + 1, mid, mid - 1, mid, hi - 1, lo + 2]
	if chorus:
		targets = [hi - 2, hi - 1, mid + 1, mid, hi - 2, hi - 1, hi, mid - 1]
	var use_seq: bool = rng.randf() < 0.5
	var out: Array = []
	out.resize(bar_len * 8)
	out.fill(-99)
	var prev: int = targets[0]
	var prev2: int = prev
	for bar: int in range(8):
		var chord: int = int(prog[bar])
		if bar == 4 or bar == 5 or (bar == 1 and use_seq):
			# Bars 5-6 restate bars 1-2; bar 2 may be a sequence (bar 1 moved with the chord root).
			var src_bar: int = 0 if bar == 1 else bar - 4
			var shift: int = 0
			if bar == 1:
				# Move the whole bar by the chord-root step, in whichever octave keeps it in range.
				var base_shift: int = chord - int(prog[0])
				var best_out: int = 999999
				for cand_shift: int in [base_shift, base_shift - 7, base_shift + 7]:
					var spill: int = 0
					for st2: int in range(bar_len):
						var sv: int = int(out[st2])
						if sv != -99:
							spill += maxi(0, sv + cand_shift - hi) + maxi(0, lo - (sv + cand_shift))
					if spill < best_out or (spill == best_out and absi(cand_shift) < absi(shift)):
						best_out = spill
						shift = cand_shift
			for st: int in range(bar_len):
				var src: int = int(out[src_bar * bar_len + st])
				if src == -99:
					continue
				var v: int = clampi(src + shift, lo, hi)
				if strong.has(st) and not _is_chord_tone(v, chord):
					v = _nearest_chord_tone(v, chord, lo, hi)
				out[bar * bar_len + st] = v
				prev2 = prev
				prev = v
			continue
		var pattern: String = plan[bar]
		var onsets: Array[int] = []
		for st: int in range(mini(bar_len, pattern.length())):
			if pattern[st] == "x":
				onsets.append(st)
		for k: int in range(onsets.size()):
			var st: int = onsets[k]
			var v: int = prev
			if (bar == 3 or bar == 7) and k == onsets.size() - 1:
				var goal: Array[int] = [chord + 2, chord + 4, chord - 3, chord - 5, chord + 9, chord + 11]
				if bar == 7:
					goal = [chord, chord + 7, chord - 7, chord + 14]
				v = _nearest_in(prev, goal, lo, hi)
			elif k == 0 or strong.has(st):
				v = _pick_chord_tone(rng, prev, targets[bar], chord, lo, hi)
			else:
				v = _pick_step(rng, prev, prev2, targets[bar], lo, hi)
			out[bar * bar_len + st] = v
			prev2 = prev
			prev = v
	return out


func _is_chord_tone(deg: int, chord: int) -> bool:
	var rel: int = posmod(deg - chord, 7)
	return rel == 0 or rel == 2 or rel == 4


func _nearest_chord_tone(v: int, chord: int, lo: int, hi: int) -> int:
	var best: int = v
	var best_d: int = 999
	for c: int in range(lo, hi + 1):
		if _is_chord_tone(c, chord) and absi(c - v) < best_d:
			best_d = absi(c - v)
			best = c
	return best


func _nearest_in(v: int, goals: Array[int], lo: int, hi: int) -> int:
	var best: int = v
	var best_d: int = 999
	for g: int in goals:
		if g >= lo and g <= hi and absi(g - v) < best_d:
			best_d = absi(g - v)
			best = g
	return best


func _pick_chord_tone(rng: RandomNumberGenerator, prev: int, target: int, chord: int, lo: int, hi: int) -> int:
	var best: int = prev
	var best_score: float = 1e9
	for c: int in range(lo, hi + 1):
		if not _is_chord_tone(c, chord):
			continue
		var d: int = absi(c - prev)
		var score: float = 0.6 * float(d) + 0.7 * float(absi(c - target)) + rng.randf() * 1.3
		if d == 0:
			score += 3.0
		if d > 5:
			score += 3.0
		if score < best_score:
			best_score = score
			best = c
	return best


func _pick_step(rng: RandomNumberGenerator, prev: int, prev2: int, target: int, lo: int, hi: int) -> int:
	var best: int = prev
	var best_score: float = 1e9
	var last_leap: int = prev - prev2
	for c: int in range(maxi(lo, prev - 2), mini(hi, prev + 2) + 1):
		var d: int = c - prev
		var score: float = 0.6 * float(absi(c - target)) + 0.8 * float(absi(d) - 1) + rng.randf() * 1.0
		if d == 0:
			score += 2.6
		if absi(last_leap) >= 3 and d != 0 and signi(d) == signi(last_leap):
			score += 2.5
		elif last_leap != 0 and absi(last_leap) <= 2 and signi(d) == signi(last_leap):
			score -= 0.5 # keep a scale run going rather than wobbling back and forth
		if score < best_score:
			best_score = score
			best = c
	return best


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

	var pad_lr: Vector2 = _tick_stereo_pad(dt, 0.14, 8)

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
	var pad_lr: Vector2 = _tick_stereo_pad(dt, 0.16, 8)

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
	_stab_env = maxf(0.0, _stab_env - dt * _stab_dec)

	# --- 1) STAGE-SPECIFIC BASS INSTRUMENT ---
	var bass_sig: float = 0.0
	if _bass_env > 0.001:
		_bass_atk = minf(1.0, _bass_atk + dt * _bass_atk_rate)
		_bass_env = maxf(0.0, _bass_env - dt * _bass_dec)
		_bass_p1 = fmod(_bass_p1 + _bass_freq * dt, 1.0)
		_bass_p2 = fmod(_bass_p2 + _bass_freq * 1.006 * dt, 1.0)
		_bass_sub_p = fmod(_bass_sub_p + _bass_freq * 0.5 * dt, 1.0)

		var vb: int = _v_bass
		if vb == 1:
			# Slap-FM Metallic Funk Bass (2:1 + 3:1 snappy FM pop!)
			var fm_mod: float = sin(_bass_p1 * 2.0 * TAU) * (_bass_env * _bass_env * 3.2 + 0.4)
			bass_sig = sin(_bass_p1 * TAU + fm_mod) * _bass_env * _bass_atk * 0.38
		elif vb == 2:
			# Bouncy Fretless Triangle + Warm Octave Harmonic Bass
			var tri_b: float = 4.0 * absf(_bass_p1 - 0.5) - 1.0
			bass_sig = (tri_b * 0.75 + sin(_bass_p1 * 2.0 * TAU) * 0.25) * _bass_env * _bass_atk * 0.36
		elif vb == 3 or vb == 4 or vb == 6:
			# Deep Pure Sub / Log-Drum / Liquid Dub Bass (warm round sine + subtle 2nd harmonic)
			bass_sig = (sin(_bass_p1 * TAU) * 0.82 + sin(_bass_p1 * 2.0 * TAU) * 0.22 * _bass_env) * _bass_env * _bass_atk * 0.38
		elif vb == 5:
			# Aggressive Volcanic Acid-Resonant Sawtooth Bass!
			var saw_f: float = 2.0 * _bass_p1 - 1.0
			var cut_f: float = clampf(0.05 + 0.36 * (_bass_env * _bass_env), 0.03, 0.52)
			_bass_lp1 += cut_f * (saw_f - _bass_lp1)
			var over: float = (_bass_lp1 * 1.7) / (1.0 + absf(_bass_lp1 * 1.7))
			bass_sig = (over * 0.8 + sin(_bass_sub_p * TAU) * 0.4) * _bass_env * _bass_atk * 0.36
		elif vb == 0:
			# Picked Rock Bass: saw + square through an envelope-swept 2-pole low-pass, plus a sub
			var pick: float = (2.0 * _bass_p1 - 1.0) * 0.6 + (0.5 if _bass_p1 < 0.5 else -0.5)
			var p_cut: float = clampf(0.06 + 0.30 * (_bass_env * _bass_env * _bass_env), 0.04, 0.45)
			_bass_lp1 += p_cut * (pick - _bass_lp1)
			_bass_lp2 += p_cut * (_bass_lp1 - _bass_lp2)
			bass_sig = (_bass_lp2 * 0.9 + sin(_bass_sub_p * TAU) * 0.35) * _bass_env * _bass_atk * 0.36
		elif vb == 9:
			# 8-bit triangle bass: a 16-step stair-stepped triangle, like a game console's bass channel
			var tri9: float = 4.0 * absf(_bass_p1 - 0.5) - 1.0
			bass_sig = (floorf((tri9 + 1.0) * 7.5) / 7.5 - 1.0) * _bass_env * _bass_atk * 0.42
		elif vb == 10:
			# Reese bass: two slightly detuned saws slowly phasing against each other, darkly filtered
			var reese: float = (2.0 * _bass_p1 - 1.0) * 0.55 + (2.0 * _bass_p2 - 1.0) * 0.55
			var r_cut: float = 0.05 + 0.06 * _bass_env
			_bass_lp1 += r_cut * (reese - _bass_lp1)
			_bass_lp2 += r_cut * (_bass_lp1 - _bass_lp2)
			bass_sig = (_bass_lp2 + sin(_bass_sub_p * TAU) * 0.45) * _bass_env * _bass_atk * 0.36
		elif vb == 11:
			# FM synth bass (80s keyboard bass): 1:1 FM whose brightness follows the envelope
			var fm11: float = sin(_bass_p1 * TAU) * (0.9 + 2.4 * _bass_env * _bass_env)
			bass_sig = sin(_bass_p1 * TAU + fm11) * _bass_env * _bass_atk * 0.36
		elif vb == 12:
			# Orchestral low strings: bowed (slow attack) detuned saws through a dark low-pass
			var bow: float = (2.0 * _bass_p1 - 1.0) * 0.5 + (2.0 * _bass_p2 - 1.0) * 0.5
			_bass_lp1 += 0.06 * (bow - _bass_lp1)
			_bass_lp2 += 0.06 * (_bass_lp1 - _bass_lp2)
			bass_sig = (_bass_lp2 * 1.1 + sin(_bass_p1 * TAU) * 0.25) * _bass_env * _bass_atk * 0.36
		elif vb == 13:
			# 808 boom: a long sine with a pitch drop at the start, lightly saturated
			var e4: float = _bass_env * _bass_env * _bass_env * _bass_env
			_bass_bend_p = fmod(_bass_bend_p + _bass_freq * 1.2 * e4 * dt, 1.0)
			var boom: float = sin((_bass_p1 + _bass_bend_p) * TAU) * 1.5
			bass_sig = (boom / (1.0 + absf(boom))) * _bass_env * _bass_atk * 0.50
		elif vb == 14:
			# Upright / acoustic bass: round sine-triangle pluck with a quick thump
			var tri14: float = 4.0 * absf(_bass_p1 - 0.5) - 1.0
			bass_sig = (sin(_bass_p1 * TAU) * 0.75 + tri14 * 0.25) * (_bass_env * sqrt(_bass_env)) * _bass_atk * 0.46
		else:
			# Dual-Saw Synthwave / Trance Pumping Bass (Style 7, 8)
			var dual_saw: float = (2.0 * _bass_p1 - 1.0) * 0.55 + (2.0 * _bass_p2 - 1.0) * 0.55
			var b_cut: float = clampf(0.045 + 0.22 * (_bass_env * _bass_env), 0.025, 0.44)
			_bass_lp1 += b_cut * (dual_saw - _bass_lp1)
			_bass_lp2 += b_cut * (_bass_lp1 - _bass_lp2)
			bass_sig = (_bass_lp2 + sin(_bass_sub_p * TAU) * 0.50) * _bass_env * _bass_atk * (0.45 + 0.55 * _sidechain) * 0.34
		if _add_sub:
			bass_sig += sin(_bass_sub_p * TAU) * _sub_mix * _bass_env * _bass_atk * 0.32
		bass_sig *= _bass_gain

	# --- 2) STAGE-SPECIFIC CHORD / PAD / RHODES / CLAVINET INSTRUMENT ---
	var pad_lr: Vector2 = _tick_stereo_pad(dt, 0.15 * _sidechain, _v_pad)

	# --- 3) STAGE-SPECIFIC ARPEGGIATOR / MARIMBA / CELESTA / SONAR ---
	var arp_sig: float = 0.0
	if _arp_env > 0.001:
		_arp_atk = minf(1.0, _arp_atk + dt * 420.0)
		_arp_env = maxf(0.0, _arp_env - dt * _arp_dec)
		_arp_p = fmod(_arp_p + _arp_freq * dt, 1.0)

		var va: int = _v_arp
		if va == 2:
			# Concert Harp Pluck (sine + soft octave that fades faster than the body)
			arp_sig = (sin(_arp_p * TAU) + sin(_arp_p * 2.0 * TAU) * 0.3 * _arp_env) * (_arp_env * _arp_env) * _arp_atk * 0.17
		elif va == 3:
			# Wooden Marimba / Kalimba Mallet (fundamental sine + fast-decaying 4x hollow wood overtone!)
			var wood_hit: float = sin(_arp_p * 4.0 * TAU) * (_arp_env * _arp_env * _arp_env) * 0.65
			arp_sig = (sin(_arp_p * TAU) + wood_hit) * _arp_env * _arp_atk * 0.20
		elif va == 4:
			# Sparkling FM Ice-Bell Celesta (3.5x crystalline bell modulator!)
			_arp_m_p = fmod(_arp_m_p + _arp_freq * 3.5 * dt, 1.0)
			var ice_mod: float = sin(_arp_m_p * TAU) * (_arp_env * 1.6 + 0.25)
			arp_sig = sin(_arp_p * TAU + ice_mod) * (_arp_env * _arp_env) * _arp_atk * 0.16
		elif va == 6:
			# Liquid Underwater Sonar Harp Pluck
			arp_sig = sin(_arp_p * TAU + sin(_arp_p * TAU) * _arp_env * 0.8) * (_arp_env * _arp_env) * _arp_atk * 0.18
		elif va == 9:
			# 8-bit pulse arpeggio (12.5% duty, unfiltered, flat-topped envelope)
			arp_sig = (0.875 if _arp_p < 0.125 else -0.125) * minf(1.0, _arp_env * 1.6) * _arp_atk * 0.17
		elif va == 10:
			# Vibraphone: sine bar + bright strike overtone, with motor tremolo
			var trem: float = 0.82 + 0.18 * sin(_lfo_phase * 1.1 * TAU)
			arp_sig = (sin(_arp_p * TAU) + sin(_arp_p * 4.0 * TAU) * 0.22 * _arp_env * _arp_env) * _arp_env * trem * _arp_atk * 0.17
		elif va == 11:
			# Steel drum: FM with a 2x modulator that settles as the note rings
			var pan_mod: float = sin(_arp_p * 2.0 * TAU) * (0.35 + 1.1 * _arp_env)
			arp_sig = (sin(_arp_p * TAU + pan_mod) + sin(_arp_p * 3.0 * TAU) * 0.18 * _arp_env) * _arp_env * _arp_atk * 0.16
		elif va == 12:
			# Nylon guitar pluck: saw through a low-pass that closes as the string decays
			var nyl: float = 2.0 * _arp_p - 1.0
			_arp_lp += (0.04 + 0.42 * _arp_env * _arp_env) * (nyl - _arp_lp)
			arp_sig = _arp_lp * _arp_env * _arp_atk * 0.24
		else:
			var arp_raw: float = (0.75 if _arp_p < 0.30 else -0.75) + sin(_arp_p * 2.0 * TAU) * 0.35
			_arp_lp += (0.09 + 0.30 * _arp_env) * (arp_raw - _arp_lp)
			arp_sig = _arp_lp * (_arp_env * _arp_env) * _arp_atk * 0.13

	# --- 4) STAGE-SPECIFIC SOLO LEAD INSTRUMENT ---
	var lead_sig: float = 0.0
	if _lead_env > 0.002:
		if _glide > 0.0:
			_lead_freq = lerpf(_lead_freq, _lead_target_freq, clampf(dt * _glide, 0.0, 1.0))
		else:
			_lead_freq = _lead_target_freq
		_lead_atk = minf(1.0, _lead_atk + dt * _lead_attack)
		_lead_env = maxf(0.0, _lead_env - dt * _lead_decay)
		var vib_depth: float = _vib
		if _v_lead == 5:
			vib_depth = 0.0065
		elif _v_lead == 9:
			vib_depth = _vib * (1.0 - _lead_env) * 2.0
		var vib: float = 1.0 + vib_depth * sin(_lfo_phase * TAU)
		_lead_p1 = fmod(_lead_p1 + _lead_freq * vib * dt, 1.0)
		_lead_p2 = fmod(_lead_p2 + _lead_freq * vib * 1.006 * dt, 1.0)

		var raw_lead: float = 0.0
		match _v_lead:
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
			9: # 8-bit 25% pulse lead (its vibrato fades in as the note is held)
				raw_lead = (0.75 if _lead_p1 < 0.25 else -0.25) * 1.15
			10: # Pulse-width-modulated lead: the pulse width sweeps slowly for a chorused, singing tone
				var pw: float = 0.5 + 0.34 * sin(_lfo_phase * 0.12 * TAU)
				raw_lead = (0.62 if _lead_p1 < pw else -0.62) + sin(_lead_p1 * TAU) * 0.2
			11: # Brass / horn: two saws, brightened by the attack (see its cutoff below)
				raw_lead = ((2.0 * _lead_p1 - 1.0) + (2.0 * _lead_p2 - 1.0)) * 0.48
			12: # Violin: bright saw with a gentle sine body (vibrato comes from "vib")
				raw_lead = (2.0 * _lead_p1 - 1.0) * 0.7 + sin(_lead_p1 * TAU) * 0.3
			13: # Whistle / ocarina: nearly pure sine
				raw_lead = sin(_lead_p1 * TAU) * 0.95 + sin(_lead_p1 * 2.0 * TAU) * 0.08
			14: # FM electric-piano lead: bell-like attack mellowing into a sine
				raw_lead = sin(_lead_p1 * TAU + sin(_lead_p1 * TAU) * (0.4 + 1.8 * _lead_env * _lead_env)) * 0.9
			_: # Stage 1: Hollow Square "Brass" Lead (square + soft octave saw + sine body, one oscillator, no detune)
				var oct_p: float = fmod(_lead_p1 * 2.0, 1.0)
				raw_lead = (0.62 if _lead_p1 < 0.5 else -0.62) + (2.0 * oct_p - 1.0) * 0.18 + sin(_lead_p1 * TAU) * 0.30

		var l_cut: float = 0.15 + 0.28 * _lead_env
		match _v_lead:
			3, 4, 6: l_cut = 0.28
			0: l_cut = 0.10 + 0.20 * _lead_env
			9: l_cut = 0.6
			10, 14: l_cut = 0.3
			11: l_cut = 0.05 + 0.32 * _lead_atk * _lead_env
			12: l_cut = 0.22
			13: l_cut = 0.35
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

	# --- 7) EXTRA LAYERS: crash, clap, countermelody ---
	var crash: float = 0.0
	if _crash_env > 0.002:
		_crash_env = maxf(0.0, _crash_env - dt * 1.5)
		var cn: float = _rng.randf_range(-1.0, 1.0)
		crash = (cn - _crash_prev) * _crash_env * _crash_env * 0.085
		_crash_prev = cn
	var clap: float = 0.0
	if _clap_env > 0.002:
		_clap_t += dt
		_clap_env = maxf(0.0, _clap_env - dt * 10.0)
		# Three quick bursts then a tail, like hands slightly out of sync.
		var burst: float = 1.0 if (_clap_t < 0.006 or (_clap_t > 0.010 and _clap_t < 0.016) or _clap_t > 0.020) else 0.2
		var pn: float = _rng.randf_range(-1.0, 1.0)
		_clap_lp += 0.35 * (pn - _clap_lp)
		clap = (pn - _clap_lp * 0.6) * _clap_env * burst * 0.13
	var ca_sig: float = 0.0
	if _ca_env > 0.002:
		_ca_atk = minf(1.0, _ca_atk + dt * 24.0)
		_ca_env = maxf(0.0, _ca_env - dt * 0.85)
		_ca_p = fmod(_ca_p + _ca_freq * (1.0 + 0.003 * sin(_lfo_phase * 1.2)) * dt, 1.0)
		var ca_tri: float = 4.0 * absf(_ca_p - 0.5) - 1.0
		ca_sig = (ca_tri * 0.65 + sin(_ca_p * TAU) * 0.35) * _ca_env * _ca_atk * 0.085

	var dry_l: float = bass_sig + pad_lr.x + kick + snare_lr.x + rim + tom + hat + crash * 0.85 + clap
	var dry_r: float = bass_sig + pad_lr.y + kick + snare_lr.y + rim + tom + hat + crash + clap * 0.9
	var send_l: float = arp_sig * 0.9 + lead_sig * 0.65 + harm_sig * 0.95 + ca_sig * 0.45
	var send_r: float = arp_sig * 0.45 + lead_sig * 0.95 + harm_sig * 0.45 + ca_sig

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
		elif style == 0:
			# Outer Orbit: Brass Section (saw + square) that swells on each stab over a soft sustain
			var brass_g: float = 0.30 + 0.90 * _stab_env
			var br_a: float = (2.0 * _pad_phases_a[i] - 1.0) * 0.7 + (0.6 if _pad_phases_a[i] < 0.5 else -0.6) * 0.3
			var br_b: float = (2.0 * _pad_phases_b[i] - 1.0) * 0.7 + (0.6 if _pad_phases_b[i] < 0.5 else -0.6) * 0.3
			sum_l += br_a * brass_g
			sum_r += br_b * brass_g
		elif style == 7:
			# Cyber Nexus: Rhythmic Trance Gate Hypersaws!
			var gate_mul: float = 0.30 + 0.70 * _stab_env
			sum_l += (2.0 * _pad_phases_a[i] - 1.0) * gate_mul
			sum_r += (2.0 * _pad_phases_b[i] - 1.0) * gate_mul
		elif style == 9:
			# 8-bit pulse chord, quiet between hits (the arpeggio carries chip harmony)
			var g9: float = 0.18 + 0.82 * _stab_env
			sum_l += (0.75 if _pad_phases_a[i] < 0.25 else -0.25) * g9
			sum_r += (0.75 if _pad_phases_b[i] < 0.25 else -0.25) * g9
		elif style == 10:
			# String section: detuned saws, warm and sustained
			sum_l += (2.0 * _pad_phases_a[i] - 1.0) * 1.15
			sum_r += (2.0 * _pad_phases_b[i] - 1.0) * 1.15
		elif style == 11:
			# Drawbar organ with a rotary-speaker wobble
			var rot: float = 1.0 + 0.16 * sin(_lfo_phase * 1.3 * TAU + float(i))
			var oa: float = _pad_phases_a[i] * TAU
			var ob: float = _pad_phases_b[i] * TAU
			sum_l += (sin(oa) + sin(oa * 2.0) * 0.5 + sin(oa * 3.0) * 0.3 + sin(oa * 4.0) * 0.18) * 0.62 * rot
			sum_r += (sin(ob) + sin(ob * 2.0) * 0.5 + sin(ob * 3.0) * 0.3 + sin(ob * 4.0) * 0.18) * 0.62 * (2.0 - rot)
		elif style == 12:
			# Warm analog pad (saw; its filter breathes slowly, see the cutoff below)
			sum_l += (2.0 * _pad_phases_a[i] - 1.0) * 1.2
			sum_r += (2.0 * _pad_phases_b[i] - 1.0) * 1.2
		elif style == 13:
			# Strummed guitar chord: plucked triangle+saw that rings out after each stab
			var g13: float = (0.05 + 0.95 * _stab_env * _stab_env) * 1.3
			var ta: float = 4.0 * absf(_pad_phases_a[i] - 0.5) - 1.0
			var tb: float = 4.0 * absf(_pad_phases_b[i] - 0.5) - 1.0
			sum_l += (ta * 0.6 + (2.0 * _pad_phases_a[i] - 1.0) * 0.4) * g13
			sum_r += (tb * 0.6 + (2.0 * _pad_phases_b[i] - 1.0) * 0.4) * g13
		else:
			# Lush Analog Juno/OB-X Sawtooth Pad (Volcano Brass, Boss, title & hyperspace)
			var boost: float = (1.0 + _stab_env * 0.6) if style == 5 else 1.0
			sum_l += (2.0 * _pad_phases_a[i] - 1.0) * boost
			sum_r += (2.0 * _pad_phases_b[i] - 1.0) * boost

	var cut: float = 0.065
	match style:
		1, 7: cut = 0.14
		0: cut = 0.10
		9: cut = 0.30
		10: cut = 0.05
		11: cut = 0.12
		12: cut = 0.045 + 0.035 * sin(_lfo_phase * 0.06 * TAU)
		13: cut = 0.16
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
	_kick_env = maxf(0.0, _kick_env - dt * _kick_dec)
	var e3: float = _kick_env * _kick_env * _kick_env
	var k_freq: float = _kick_base + _kick_sweep * e3
	_kick_phase = fmod(_kick_phase + k_freq * dt, 1.0)
	# Body plus a short beater click at the start for punch.
	var click: float = sin(_kick_phase * 5.0 * TAU) * e3 * e3 * 0.18
	return (sin(_kick_phase * TAU) * _kick_env * 0.45 + click) * _kick_gain


func _tick_gated_snare(dt: float) -> Vector2:
	if _snare_gate_time <= 0.0 and _snare_body_env <= 0.001:
		return Vector2.ZERO
	_snare_body_env = maxf(0.0, _snare_body_env - dt * 14.0)
	_snare_gate_time = maxf(0.0, _snare_gate_time - dt)

	_snare_phase = fmod(_snare_phase + (118.0 + 82.0 * _snare_body_env) * dt, 1.0)
	var body: float = sin(_snare_phase * TAU) * _snare_body_env * _snare_body

	var gate_env: float = clampf(_snare_gate_time / 0.04, 0.0, 1.0) * 0.55 + _snare_body_env * 0.45
	var nl: float = _rng.randf_range(-1.0, 1.0)
	var nr: float = _rng.randf_range(-1.0, 1.0)
	_snare_lp_l += _snare_lp_k * (nl - _snare_lp_l)
	_snare_lp_r += _snare_lp_k * (nr - _snare_lp_r)
	return Vector2(body + _snare_lp_l * gate_env * _snare_noise, body + _snare_lp_r * gate_env * _snare_noise)


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
	return hp * (_hat_env * _hat_env) * _hat_amp
