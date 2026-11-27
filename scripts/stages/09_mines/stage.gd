extends "res://scripts/stages/stage_module.gd"

# STAGE 9: ORE MINES. An industrial mining colony inside a hollowed-out asteroid: open-pit
# terraces, girders and ore gantries, conveyor belts and swinging sodium lamps.
#
# Files in this folder:
#   stage.gd            this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              enemy, shot and boss sprites
#   background.gd       the painted layers plus the per-frame animation
#   enemy_drillbot.gd   bursts out of the floor or ceiling, aims a lane, fires and dashes
#   enemy_hauler.gd     slow freighter that dumps curtains (or fountains) of falling ore
#   enemy_surveyor.gd   laser surveyor that cuts bending walls of mining-laser bolts
#   boss.gd             MEGA EXCAVATOR: ore spray, crusher shotgun, cave-in

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Drillbot = preload("enemy_drillbot.gd")
const Hauler = preload("enemy_hauler.gd")
const Surveyor = preload("enemy_surveyor.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "mines"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "ORE MINES",
		"subtitle": "HOLLOW ASTEROID COLONY",
		"boss_name": "MEGA EXCAVATOR: MAWGRINDER",
		"sky_top": Color("#090705"),
		"sky_mid": Color("#110d09"),
		"sky_bot": Color("#1b130d"),
		"deck_fill": Color("#241a12"),
		"deck_line": Color("#f2b630"),
		"accent": Color("#ffb22e"),
		"has_ceiling": true,
		"scout_tex": "scout_mech",
		"swooper_tex": "swooper_mech",
		"sniper_tex": "sniper_mech",
		"cruiser_tex": "cruiser_mech",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": ID + "_ore",
		"boss_box": Vector2(92.0, 140.0),
		"boss_x": 408.0,
	}


# Stage 9 of the shared 9-28 curve (k = 1): a step up from stage 8 in every column. "hp" is the
# actual growth past stage 8 (StageData.stage_hp_growth: 1.34^7 x 1.12^k).
func get_difficulty_row() -> Dictionary:
	return {"hp": 8.69, "shot_speed": 1.232, "fire_rate": 1.37, "groups": 13, "pace": 0.791, "themed": 0.708}


func get_boss_hp() -> float:
	return 19000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"drillbot": {"hp": 8.0, "score": 300, "scrap": 2, "xp": 6, "r": 7.0, "tex": ID + "_drill_0", "behaviour": Drillbot},
		"hauler": {"hp": 26.0, "score": 680, "scrap": 4, "xp": 13, "box": Vector2(34.0, 16.0), "col_offset": Vector2(0.0, 2.0), "tex": ID + "_hauler_0", "behaviour": Hauler, "big": true, "exit_left": -60.0},
		"surveyor": {"hp": 11.0, "score": 380, "scrap": 3, "xp": 7, "r": 8.0, "tex": ID + "_surveyor_0", "behaviour": Surveyor},
	}


# A: drill bots bursting out of floor and ceiling in turn, with scouts behind them.
# B: an ore hauler high or low, escorted by swoopers.
# C (from wave 2): a laser surveyor covered by drill bots; wave 3 adds a second hauler.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 3 + w.extra
			for k: int in range(n):
				var x: float = 420.0 - float(k) * 46.0 + randf_range(-10.0, 10.0)
				w.spawn("drillbot", w.t + float(k) * 0.7, Vector2(x, 252.0), 0.0, -1, (k + (0 if w.top else 1)) % 2)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.2, Vector2(504.0, 110.0))
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.5, Vector2(504.0, 160.0), 1.0)
			return 3.3
		1:
			var y: float = 78.0 if w.top else 196.0
			w.spawn("hauler", w.t, Vector2(520.0, y))
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 0.6, Vector2(504.0, 268.0 - y))
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 1.0, Vector2(504.0, 135.0), 1.0)
			if w.extra > 0:
				w.spawn("drillbot", w.t + 1.4, Vector2(360.0, 252.0), 0.0, -1, 0 if w.top else 1)
			return 3.6
		_:
			var sy: float = 100.0 if w.top else 170.0
			w.spawn("surveyor", w.t, Vector2(510.0, sy))
			w.spawn("drillbot", w.t + 0.8, Vector2(400.0, 252.0), 0.0, -1, 0)
			w.spawn("drillbot", w.t + 1.5, Vector2(340.0, 31.0), 0.0, -1, 1)
			if w.extra > 0:
				w.spawn("hauler", w.t + 1.0, Vector2(524.0, 210.0 if w.top else 70.0))
			return 3.9


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Industrial work song: a hammering machine-16th acid bass, saw stabs, clanks and a crunchy
# overdriven guitar lead, in D harmonic minor (the raised 7th gives the V chord its bite).
func get_song() -> Dictionary:
	return {
		"seed": 9090, "style": 16, "gv": 0, "root": 38, "bpm": 124.0, "scale": Music.HARMONIC_MINOR,
		"bass": 5, "arp": 11, "lead": 5, "kit": "hard", "crush": 2,
		"energy": 2, "bass_gain": 1.6, "kick_gain": 1.35,
		"lead_decay": 1.7, "mel_lo": -1, "mel_hi": 7, "delay_beats": 0.5, "delay_fb": 0.26, "delay_wet": 0.2,
		"prog_a": [0, 0, -2, 4, 0, 0, 3, 4],
		"prog_b": [-2, -1, 0, 4, -2, 3, 4, 4],
	}


func get_song_alternatives() -> Array:
	return [
		{"name": "PICK AND SHOVEL", "info": "ROCK  146 BPM  E MINOR", "seed": 9091,
			"style": 0, "root": 40, "bpm": 146.0, "scale": Music.MINOR, "lead": 5, "bass": 0,
			"lead_decay": 1.8, "mel_lo": -2, "mel_hi": 6,
			"prog_a": [0, 0, -2, -1, 0, 0, 3, 4], "prog_b": [-2, -1, 0, 0, -2, 3, 4, 4]},
	]
