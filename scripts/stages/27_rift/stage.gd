extends "res://scripts/stages/stage_module.gd"

# STAGE 27: QUANTUM RIFT. A place where time has come apart: jagged rifts of white light open
# and close in the void, floating shards show the skies of other times, impossible geometry
# and broken clocks hang in the distance, and a lagging amber echo of everything trails behind.
# Two timelines share the screen: cyan is the present, amber is the past (echoes).
#
# Files in this folder:
#   stage.gd            stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              every sprite (enemies, shots, generic re-skins, the Paradox Engine's frames)
#   background.gd       the painted void, shards and ruins plus the per-frame animation
#   enemy_qubit.gd      superposition drones: flicker between two places until seen or hit
#   enemy_echo.gd       time-echo ships: fly and fire, recording it for their echo to replay
#   enemy_ghost.gd      the amber echo itself (a capped child): replays the recorded flight
#   enemy_pbomb.gd      probability bombs: show candidate bursts, collapse to one, burst
#   boss.gd             THE PARADOX ENGINE's attack patterns

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Qubit = preload("enemy_qubit.gd")
const Echo = preload("enemy_echo.gd")
const Ghost = preload("enemy_ghost.gd")
const PBomb = preload("enemy_pbomb.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "rift"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "QUANTUM RIFT",
		"subtitle": "WHERE TIME COMES APART",
		"boss_name": "THE PARADOX ENGINE",
		"sky_top": Color("#05030c"),
		"sky_mid": Color("#0c0820"),
		"sky_bot": Color("#140c2c"),
		"deck_fill": Color("#120c24"),
		"deck_line": Color("#46d8f0"),
		"accent": Color("#8ceeff"),
		"has_ceiling": false,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(78.0, 128.0),
		"boss_x": 404.0,
	}


# Stage 27 on the shared curve (k = 19). "hp" is StageData.stage_hp_growth(26): 1.34^7 x 1.12^19.
func get_difficulty_row() -> Dictionary:
	return {"hp": 66.82, "shot_speed": 1.448, "fire_rate": 1.73, "groups": 19, "pace": 0.629, "themed": 0.85}


func get_boss_hp() -> float:
	return 45500.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"qubit": {"hp": 10.0, "score": 420, "scrap": 2, "xp": 8, "r": 7.5, "tex": ID + "_qubit_0", "behaviour": Qubit},
		"echo": {"hp": 15.0, "score": 480, "scrap": 3, "xp": 9, "r": 8.0, "tex": ID + "_echo_0", "behaviour": Echo},
		"ghost": {"hp": 6.0, "score": 160, "scrap": 1, "xp": 2, "r": 7.5, "tex": ID + "_ghost_0", "behaviour": Ghost},
		"pbomb": {"hp": 18.0, "score": 520, "scrap": 3, "xp": 10, "r": 9.0, "tex": ID + "_pbomb_0", "behaviour": PBomb, "big": true},
	}


# A: a column of superposition drones with a generic sniper behind. B: a pair of echo ships (one
# high, one low), whose echoes replay them a second later. C: a probability bomb escorted by
# drones and a twice-echoed ship; the third wave adds a second bomb.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var sq: int = w.new_squad(3)
			for k: int in range(3):
				var y: float = 66.0 + 46.0 * float(k) + (0.0 if w.top else 18.0)
				w.spawn("qubit", w.t + float(k) * 0.45, Vector2(508.0, y), float(k) * 1.3, sq, k % 2)
			w.spawn_generic(GameEnemy.Type.SNIPER, w.t + 1.1, Vector2(504.0, 134.0))
			return 2.9
		1:
			var y1: float = 70.0 if w.top else 196.0
			# variant 1 echoes twice: both do in the second wave, neither in the third (whose
			# tougher ships already fire for longer)
			w.spawn("echo", w.t, Vector2(512.0, y1), 0.0, -1, 1 if w.sub_wave == 2 else 0)
			w.spawn("echo", w.t + 0.7, Vector2(512.0, 266.0 - y1), 1.0, -1, 0 if w.sub_wave == 3 else 1)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.0, Vector2(504.0, 134.0))
			return 3.2
		_:
			var by: float = 110.0 if w.top else 160.0
			w.spawn("pbomb", w.t, Vector2(512.0, by), 0.0, -1, w.idx % 2)
			w.spawn("qubit", w.t + 0.5, Vector2(508.0, 60.0), 0.0, -1, 0)
			w.spawn("qubit", w.t + 0.8, Vector2(508.0, 210.0), 1.0, -1, 1)
			w.spawn("echo", w.t + 1.3, Vector2(512.0, 270.0 - by), 0.0, -1, 1)
			if w.extra > 0:
				w.spawn("pbomb", w.t + 2.0, Vector2(512.0, 270.0 - by), 1.0, -1, 1 - w.idx % 2)
			return 3.6


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# "Time echo dub" in Eb minor: the dub groove pushed to full energy, a growling reese bass, warm
# analog pads, a vibraphone and a PWM lead that keeps coming back to itself through a long,
# deep echo, as if every phrase were heard twice, once now and once from the past.
func get_song() -> Dictionary:
	return {
		"seed": 2727, "style": 6, "root": 39, "bpm": 100.0, "scale": Music.MINOR, "swing": 0.08,
		"bass": 10, "pad": 12, "arp": 10, "lead": 10, "kit": "hard",
		"energy": 2, "bass_gain": 1.75, "kick_gain": 1.5, "sub_mix": 0.6,
		"lead_attack": 120.0, "lead_decay": 1.4, "vib": 0.005, "density": 1,
		"mel_lo": -1, "mel_hi": 7, "lift": 3,
		"delay_beats": 0.75, "delay_fb": 0.56, "delay_wet": 0.4,
		"prog_a": [0, 0, -2, -2, 3, 3, 4, 4],
		"prog_b": [5, 4, 3, -2, 5, 4, 1, 4],
	}


# The same rift at double speed, for the soundtrack picker in Options.
func get_song_alternatives() -> Array:
	return [
		{"name": "PARADOX LOOP", "info": "DRUM & BASS  172 BPM  G# DORIAN", "seed": 2728,
			"style": 10, "gv": 1, "root": 44, "bpm": 172.0, "scale": Music.DORIAN,
			"bass": 10, "pad": 7, "arp": 4, "lead": 6, "kit": "dnb", "crush": 2,
			"energy": 2, "lead_decay": 1.8, "mel_lo": 0, "mel_hi": 8,
			"delay_beats": 0.375, "delay_fb": 0.48, "delay_wet": 0.3,
			"prog_a": [0, 0, 3, 3, -2, -2, 4, 4], "prog_b": [3, 4, 0, -2, 3, 4, 5, 4]},
	]
