extends "res://scripts/stages/stage_module.gd"

# STAGE 20: STORM OCEAN. Skimming the surface of a stormy alien sea at night: low churning storm
# clouds, slanting rain, a lighthouse sweeping its beam from a rock on the horizon, and heaving
# green-grey swells with foam on the crests. Lightning strikes the sea now and then.
#
# Files in this folder:
#   stage.gd            this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              enemy, shot and boss sprites
#   background.gd       the painted layers plus the per-frame animation
#   enemy_gunboat.gd    patrol gunboat riding the swell: lobs flare-orange mortar shells
#   enemy_flyfish.gd    flying-fish schools that leap out of the waves and spit droplets
#   enemy_tentacle.gd   a kraken arm that rises from a whirlpool, curls back and slams the sea
#   boss.gd             MAELSTROM KRAKEN: tentacle lash, geysers, maelstrom spiral

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Gunboat = preload("enemy_gunboat.gd")
const Flyfish = preload("enemy_flyfish.gd")
const Tentacle = preload("enemy_tentacle.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "ocean"
# The water line the stage's enemies ride, leap from and rise out of.
const WATER_Y: float = 238.0


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "STORM OCEAN",
		"subtitle": "THE TEMPEST SEA",
		"boss_name": "MAELSTROM KRAKEN",
		"sky_top": Color("#090b16"),
		"sky_mid": Color("#121726"),
		"sky_bot": Color("#0f1c1e"),
		"deck_fill": Color("#0c1618"),
		"deck_line": Color("#5aa8b0"),
		"accent": Color("#8ee4f0"),
		"has_ceiling": false,
		"scout_tex": "scout_mech",
		"swooper_tex": "swooper_mech",
		"sniper_tex": "sniper_mech",
		"cruiser_tex": "cruiser_mech",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_pink",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(84.0, 138.0),
		"boss_x": 408.0,
	}


# Stage 20 of the shared 9-28 curve (k = 12). "hp" is the actual growth past stage 8
# (StageData.stage_hp_growth: 1.34^7 x 1.12^k).
func get_difficulty_row() -> Dictionary:
	return {"hp": 30.23, "shot_speed": 1.364, "fire_rate": 1.59, "groups": 17, "pace": 0.692, "themed": 0.796}


func get_boss_hp() -> float:
	return 35500.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"gunboat": {"hp": 16.0, "score": 420, "scrap": 3, "xp": 9, "box": Vector2(30.0, 12.0), "col_offset": Vector2(1.0, 2.0), "tex": ID + "_gunboat_0", "behaviour": Gunboat, "exit_left": -50.0},
		"flyfish": {"hp": 3.0, "score": 130, "scrap": 1, "xp": 2, "r": 5.5, "tex": ID + "_fish_0", "behaviour": Flyfish},
		"tentacle": {"hp": 22.0, "score": 640, "scrap": 4, "xp": 13, "r": 7.0, "tex": ID + "_tip_0", "behaviour": Tentacle, "big": true, "exit_left": -60.0},
	}


# A: a school of flying fish leaping in a staggered line, a gunboat rounding in behind them,
#    a generic scout and sniper.
# B: a kraken arm rising out of a whirlpool, with a flying-fish pair and generic swoopers
#    (wave 3: two more fish).
# C (from wave 2): two gunboats on the swell and a kraken arm between them, under a school of
#    fish; wave 3 adds a fish and two generic swoopers.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 5 + w.extra
			var sq: int = w.new_squad(n)
			var x0: float = 470.0 if w.top else 430.0
			for k: int in range(n):
				w.spawn("flyfish", w.t + float(k) * 0.16, Vector2(x0 - float(k) * 9.0, WATER_Y), float(k), sq, k % 2)
			w.spawn("gunboat", w.t + 0.8, Vector2(516.0, WATER_Y))
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.2, Vector2(504.0, 80.0 if w.top else 120.0))
			w.spawn_generic(GameEnemy.Type.SNIPER, w.t + 1.6, Vector2(504.0, 150.0 if w.top else 60.0))
			return 3.1
		1:
			w.spawn("tentacle", w.t, Vector2(randf_range(380.0, 436.0), WATER_Y))
			w.spawn("flyfish", w.t + 0.9, Vector2(450.0, WATER_Y), 0.0, -1, 0)
			w.spawn("flyfish", w.t + 1.05, Vector2(462.0, WATER_Y), 1.0, -1, 1)
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 1.3, Vector2(504.0, 70.0))
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 1.6, Vector2(504.0, 150.0), 1.0)
			if w.extra > 0:
				w.spawn("flyfish", w.t + 1.8, Vector2(430.0, WATER_Y), 2.0, -1, 1)
				w.spawn("flyfish", w.t + 1.95, Vector2(418.0, WATER_Y), 3.0, -1, 0)
			return 3.5
		_:
			w.spawn("gunboat", w.t, Vector2(516.0, WATER_Y))
			w.spawn("gunboat", w.t + 1.4, Vector2(530.0, WATER_Y), 1.0, -1, 1)
			w.spawn("tentacle", w.t + 0.6, Vector2(randf_range(356.0, 400.0), WATER_Y), 0.0, -1, 1)
			var n2: int = 3 + w.extra
			var sq2: int = w.new_squad(n2)
			for k2: int in range(n2):
				w.spawn("flyfish", w.t + 1.0 + float(k2) * 0.2, Vector2(440.0 - float(k2) * 10.0, WATER_Y), float(k2), sq2, k2 % 2)
			if w.extra > 0:
				w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 2.0, Vector2(504.0, 60.0))
				w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 2.3, Vector2(504.0, 110.0), 1.0)
			return 3.9


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Storm-epic rock in D minor: low strings bass, a string section pad and a soaring violin lead
# over a straight, driving rock kit.
func get_song() -> Dictionary:
	return {
		"seed": 2020, "style": 0, "root": 38, "bpm": 164.0, "scale": Music.MINOR,
		"bass": 12, "pad": 10, "arp": 2, "lead": 12, "kit": "hard",
		"energy": 2, "bass_gain": 1.5, "kick_gain": 1.3,
		"lead_attack": 60.0, "lead_decay": 1.1, "glide": 18.0, "vib": 0.006,
		"mel_lo": -1, "mel_hi": 8, "density": 1, "lift": 3,
		"delay_beats": 0.75, "delay_fb": 0.34, "delay_wet": 0.26,
		"prog_a": [0, -2, -4, -3, 0, -2, -3, -1],
		"prog_b": [-2, -3, 0, -1, -2, -3, -1, -1],
	}


# A sea shanty in 6/8 for the soundtrack picker.
func get_song_alternatives() -> Array:
	return [
		{"name": "HEAVE HO", "info": "SEA SHANTY 6/8  112 BPM  D DORIAN", "seed": 2021,
			"style": 17, "gv": 0, "bar_steps": 12, "meter": "68", "root": 38, "bpm": 112.0, "scale": Music.DORIAN,
			"bass": 14, "pad": 11, "arp": 2, "lead": 13, "kit": "orch",
			"lead_attack": 90.0, "lead_decay": 1.4, "mel_lo": 0, "mel_hi": 9, "density": 1,
			"delay_beats": 1.5, "delay_fb": 0.28, "delay_wet": 0.22,
			"prog_a": [0, 0, -1, -1, 0, 0, -3, -1], "prog_b": [3, 3, 0, 0, -1, -1, -3, -3]},
	]
