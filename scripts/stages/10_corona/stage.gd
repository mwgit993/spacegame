extends "res://scripts/stages/stage_module.gd"

# STAGE 10: SOLAR CORONA. Skimming a star's surface: a blazing photosphere along the bottom edge,
# shimmering spicules, magnetic loops raining plasma, coronal streamers, flares and prominences.
#
# Files in this folder:
#   stage.gd           this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd             enemy, shot and boss sprites
#   background.gd      the painted layers plus the per-frame animation
#   enemy_wisp.gd      plasma wisp: wavering drift, a trail of hanging sparks, flares and fires
#   enemy_serpent.gd   flare serpent: leaps out of the surface in an arc, dripping fire, bites
#   enemy_binary.gd    binary drones: an orbiting pair painting a double spiral; enrage alone
#   boss.gd            SUNFORGE CITADEL: focused beam, solar wind, flare spirals

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Wisp = preload("enemy_wisp.gd")
const Serpent = preload("enemy_serpent.gd")
const Binary = preload("enemy_binary.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "corona"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "SOLAR CORONA",
		"subtitle": "STELLAR SURFACE SKIM",
		"boss_name": "SUNFORGE CITADEL: HELIOS",
		"sky_top": Color("#070208"),
		"sky_mid": Color("#180508"),
		"sky_bot": Color("#3a0d06"),
		"deck_fill": Color("#5a1806"),
		"deck_line": Color("#ffd27a"),
		"accent": Color("#ffb040"),
		"has_ceiling": false,
		"scout_tex": "scout_fire",
		"swooper_tex": "swooper_fire",
		"sniper_tex": "sniper_fire",
		"cruiser_tex": "cruiser_fire",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": ID + "_plasma",
		"boss_box": Vector2(84.0, 136.0),
		"boss_x": 410.0,
	}


# Stage 10 of the shared 9-28 curve (k = 2). "hp" is the actual growth past stage 8
# (StageData.stage_hp_growth: 1.34^7 x 1.12^k).
func get_difficulty_row() -> Dictionary:
	return {"hp": 9.73, "shot_speed": 1.244, "fire_rate": 1.39, "groups": 13, "pace": 0.782, "themed": 0.716}


func get_boss_hp() -> float:
	return 20500.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"wisp": {"hp": 6.0, "score": 240, "scrap": 1, "xp": 5, "r": 6.0, "tex": ID + "_wisp_0", "behaviour": Wisp},
		"serpent": {"hp": 15.0, "score": 460, "scrap": 3, "xp": 9, "r": 6.5, "tex": ID + "_serpent_head", "behaviour": Serpent, "exit_left": -70.0},
		"binary": {"hp": 9.0, "score": 320, "scrap": 2, "xp": 6, "r": 6.5, "tex": ID + "_binary_0", "behaviour": Binary},
	}


# A: a staggered column of wisps with a scout behind.
# B: flare serpents leaping out of the surface one after another, wisps between them.
# C (from wave 2): a binary pair crossing mid-screen covered by a serpent; wave 3 adds a second
#    pair.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 3 + w.extra
			for k: int in range(n):
				var y: float = lerpf(64.0, 206.0, float(k) / float(n - 1))
				w.spawn("wisp", w.t + float(k) * 0.35, Vector2(504.0, y), float(k) * 0.9, -1, k % 2)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.4, Vector2(504.0, 135.0))
			return 3.2
		1:
			var x0: float = 430.0 if w.top else 380.0
			w.spawn("serpent", w.t, Vector2(x0, 256.0), 0.0, -1, 0)
			w.spawn("serpent", w.t + 1.1, Vector2(x0 - 50.0, 256.0), 0.0, -1, 1)
			w.spawn("wisp", w.t + 0.5, Vector2(504.0, 90.0), 0.0)
			w.spawn("wisp", w.t + 0.9, Vector2(504.0, 150.0), 1.3, -1, 1)
			if w.extra > 0:
				w.spawn("serpent", w.t + 2.0, Vector2(x0 + 20.0, 256.0), 0.0, -1, 0)
			return 3.5
		_:
			var y2: float = 110.0 if w.top else 160.0
			var sq: int = w.new_squad(2)
			w.spawn("binary", w.t, Vector2(506.0, y2), 0.0, sq, 0)
			w.spawn("binary", w.t, Vector2(506.0, y2), 0.0, sq, 1)
			w.spawn("serpent", w.t + 1.2, Vector2(400.0, 256.0), 0.0, -1, 1)
			if w.extra > 0:
				var sq2: int = w.new_squad(2)
				w.spawn("binary", w.t + 1.6, Vector2(506.0, 270.0 - y2), 1.5, sq2, 0)
				w.spawn("binary", w.t + 1.6, Vector2(506.0, 270.0 - y2), 1.5, sq2, 1)
			return 3.9


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Blazing drum & bass in C# minor: a growling reese bass under a two-step break, gated hypersaw
# chords, pulse plucks and a soaring supersaw lead.
func get_song() -> Dictionary:
	return {
		"seed": 1010, "style": 10, "gv": 0, "root": 37, "bpm": 176.0, "scale": Music.MINOR,
		"bass": 10, "pad": 7, "arp": 8, "lead": 7, "kit": "dnb",
		"energy": 2, "bass_gain": 1.55, "kick_gain": 1.3,
		"density": 1, "lead_decay": 1.4, "mel_lo": 2, "mel_hi": 10, "delay_wet": 0.24,
		"prog_a": [0, 0, -2, -2, 3, 3, -1, -1],
		"prog_b": [-2, -1, 0, 0, -2, -1, 4, 4],
	}


func get_song_alternatives() -> Array:
	return [
		{"name": "SUNSPOT CYCLE", "info": "EURO TRANCE  140 BPM  E LYDIAN", "seed": 1011,
			"style": 7, "root": 40, "bpm": 140.0, "scale": Music.LYDIAN, "lead": 7,
			"lead_decay": 1.8, "mel_lo": 2, "mel_hi": 10,
			"prog_a": [0, 1, 0, 1, -2, -1, 0, 0], "prog_b": [3, 4, 1, 0, 3, 4, 1, 1]},
	]
