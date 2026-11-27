extends "res://scripts/stages/stage_module.gd"

# STAGE 11: DESERT WORLD. Dusk on a desert planet under twin setting suns: pyramids and temples
# on the horizon, rolling dunes, half-buried ruins, sandstorms and things moving under the sand.
#
# Files in this folder:
#   stage.gd            this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              enemy, shot and boss sprites
#   background.gd       the painted layers plus the per-frame animation
#   enemy_sandworm.gd   erupts from the dunes (ripples first), rears up and spits fans of sand
#   enemy_scarab.gd     weaving drones that hurl energy orbs which burst into glyph shards
#   enemy_dustdevil.gd  obelisk turret in a whirling dust devil, sprays two-arm glyph spirals
#   boss.gd             SPHINX ENGINE: eye beams, sand geysers, glyph rings

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Sandworm = preload("enemy_sandworm.gd")
const Scarab = preload("enemy_scarab.gd")
const Dustdevil = preload("enemy_dustdevil.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "desert"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "DESERT WORLD",
		"subtitle": "TWIN SUN RUINS",
		"boss_name": "SPHINX ENGINE: ANKHERA",
		"sky_top": Color("#0b0a1c"),
		"sky_mid": Color("#2c1938"),
		"sky_bot": Color("#5a2a32"),
		"deck_fill": Color("#3a2420"),
		"deck_line": Color("#e0a050"),
		"accent": Color("#ffb860"),
		"has_ceiling": false,
		"scout_tex": "scout_abyss",
		"swooper_tex": "swooper_mech",
		"sniper_tex": "sniper_abyss",
		"cruiser_tex": "cruiser_mech",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": ID + "_glyph",
		"boss_box": Vector2(96.0, 132.0),
		"boss_x": 404.0,
	}


# Stage 11 of the shared 9-28 curve (k = 3). "hp" is the actual growth past stage 8
# (StageData.stage_hp_growth: 1.34^7 x 1.12^k).
func get_difficulty_row() -> Dictionary:
	return {"hp": 10.90, "shot_speed": 1.256, "fire_rate": 1.41, "groups": 14, "pace": 0.773, "themed": 0.724}


func get_boss_hp() -> float:
	return 22000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"sandworm": {"hp": 16.0, "score": 420, "scrap": 3, "xp": 9, "r": 8.0, "tex": ID + "_worm_0", "behaviour": Sandworm},
		"scarab": {"hp": 6.0, "score": 240, "scrap": 2, "xp": 5, "r": 6.5, "tex": ID + "_scarab_0", "behaviour": Scarab},
		"dustdevil": {"hp": 14.0, "score": 400, "scrap": 3, "xp": 8, "box": Vector2(12.0, 30.0), "tex": ID + "_devil_0", "behaviour": Dustdevil, "exit_left": -30.0},
	}


# A: a squad of scarabs weaving in at different heights, with scouts.
# B: sandworms erupting one after another, swoopers overhead; wave 3 adds a third worm.
# C (from wave 2): a dust devil rolling in on the dunes, covered by scarabs (and a worm in wave 3).
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 3 + w.extra
			var sq: int = w.new_squad(n)
			for k: int in range(n):
				var y: float = lerpf(70.0, 196.0, float(k) / float(maxi(1, n - 1)))
				if not w.top:
					y = 266.0 - y
				w.spawn("scarab", w.t + float(k) * 0.35, Vector2(504.0, y), float(k) * 0.9, sq, k % 2)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.0, Vector2(504.0, 120.0))
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.3, Vector2(504.0, 150.0), 1.0)
			return 3.2
		1:
			var x0: float = 410.0 if w.top else 380.0
			w.spawn("sandworm", w.t, Vector2(x0, 257.0))
			w.spawn("sandworm", w.t + 0.9, Vector2(x0 - 80.0, 257.0))
			if w.extra > 0:
				w.spawn("sandworm", w.t + 1.8, Vector2(x0 - 30.0, 257.0))
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 0.5, Vector2(504.0, 60.0))
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 0.8, Vector2(504.0, 110.0), 1.0)
			return 3.4
		_:
			w.spawn("dustdevil", w.t, Vector2(500.0, 241.0), 0.0, -1, 0 if w.top else 1)
			w.spawn("scarab", w.t + 0.6, Vector2(504.0, 80.0), 0.0, -1, 0)
			w.spawn("scarab", w.t + 1.0, Vector2(504.0, 150.0), 1.5, -1, 1)
			if w.extra > 0:
				w.spawn("sandworm", w.t + 1.6, Vector2(340.0, 257.0))
			return 3.8


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Epic half-time taiko: war drums and low strings under a nylon-guitar arpeggio and a wailing
# violin, in D Phrygian dominant (the "desert" scale: flat 2nd, major 3rd).
func get_song() -> Dictionary:
	return {
		"seed": 1111, "style": 12, "gv": 1, "root": 38, "bpm": 104.0, "scale": Music.PHRYGIAN_DOM,
		"bass": 12, "pad": 10, "arp": 12, "lead": 12, "kit": "orch",
		"energy": 2, "bass_gain": 1.6, "kick_gain": 1.3, "vib": 0.008,
		"lead_attack": 45.0, "lead_decay": 1.1, "mel_lo": 0, "mel_hi": 8, "density": 1,
		"delay_beats": 0.75, "delay_fb": 0.32, "delay_wet": 0.28,
		"prog_a": [0, 1, 0, -1, 0, 1, 3, 1],
		"prog_b": [3, 1, 0, -2, 3, 1, 1, 0],
	}


func get_song_alternatives() -> Array:
	return [
		{"name": "OASIS AT DUSK", "info": "LO-FI HIP-HOP  86 BPM  E PHRYGIAN DOM", "seed": 1112,
			"style": 14, "root": 40, "bpm": 86.0, "scale": Music.PHRYGIAN_DOM, "swing": 0.12,
			"bass": 14, "pad": 6, "arp": 12, "lead": 3, "kit": "lofi",
			"lead_attack": 60.0, "lead_decay": 1.2, "dens_a": 0, "dens_b": 1,
			"prog_a": [0, 1, 0, 1, 3, 1, 0, 0], "prog_b": [-2, 1, 0, -1, -2, 1, 1, 0]},
	]
