extends "res://scripts/stages/stage_module.gd"

# STAGE 23: MIRROR WORLD. A reflective, inverted-colour dimension: everything is mirrored about
# the playfield's centre line (y 139.5), the colours are a photographic negative (dark chrome,
# pale cyan, silver, magenta fringes), and chrome mirror shards drift through the void.
#
# Files in this folder:
#   stage.gd            this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              enemy, shot, generic re-skin and boss sprites
#   background.gd       the painted mirrored layers plus the per-frame animation
#   enemy_mimic.gd      a negative copy of your ship that mirrors your movement, fires on your line
#   enemy_reflector.gd  a tilting mirror pane sends your shots back at the mirrored angle
#   enemy_shard.gd      mirror shards in symmetric pairs that cross the centre line and fire fans
#   boss.gd             DARK VIPER: mirror vulcans, mirror lasers, reflection spirals and lances

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Mimic = preload("enemy_mimic.gd")
const Reflector = preload("enemy_reflector.gd")
const Shard = preload("enemy_shard.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "mirror"

# Mirror axis: screen row y reflects to row 279 - y (the playfield 30-249 maps onto itself).
const AXIS: float = 139.5


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "MIRROR WORLD",
		"subtitle": "THE INVERTED DIMENSION",
		"boss_name": "DARK VIPER: REFLECTION",
		"sky_top": Color("#0b0a18"),
		"sky_mid": Color("#06060e"),
		"sky_bot": Color("#0b0a18"),
		"deck_fill": Color("#10101f"),
		"deck_line": Color("#9fe8ff"),
		"accent": Color("#ff7ae8"),
		"has_ceiling": true,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_pink",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(96.0, 104.0),
		"boss_x": 408.0,
	}


# Stage 23 of the shared 9-28 curve (k = 15). "hp" is the actual growth past stage 8
# (StageData.stage_hp_growth: 1.34^7 x 1.12^k).
func get_difficulty_row() -> Dictionary:
	return {"hp": 42.48, "shot_speed": 1.40, "fire_rate": 1.65, "groups": 18, "pace": 0.665, "themed": 0.82}


func get_boss_hp() -> float:
	return 40000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"mimic": {"hp": 10.0, "score": 320, "scrap": 2, "xp": 6, "r": 7.0, "tex": ID + "_mimic_0", "behaviour": Mimic},
		"reflector": {"hp": 16.0, "score": 520, "scrap": 3, "xp": 10, "box": Vector2(24.0, 30.0), "tex": ID + "_reflector_2", "behaviour": Reflector, "exit_left": -50.0},
		"shard": {"hp": 4.0, "score": 140, "scrap": 1, "xp": 3, "r": 6.5, "tex": ID + "_shard_0", "behaviour": Shard},
	}


# Everything comes in mirrored pairs: a spawn at y and its twin at 279 - y.
# A: a swarm of shard pairs, with a mimic behind them.
# B: a reflector holding the middle, two mimics (one mirrors your height, one reflects you
#    through the centre), and a pair of generic swoopers.
# C (from wave 2): two reflectors mirrored top and bottom with shard pairs between them; wave 3
#    adds a mimic.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var pairs: int = 3 + w.extra
			var sq: int = w.new_squad(pairs * 2)
			for k: int in range(pairs):
				var d: float = 34.0 + float((k * 29) % 3) * 22.0 + randf_range(-6.0, 6.0)
				var at: float = w.t + float(k) * 0.45
				w.spawn("shard", at, Vector2(506.0, AXIS - d), float(k), sq, 0)
				w.spawn("shard", at, Vector2(506.0, AXIS + d), float(k), sq, 1)
			w.spawn("mimic", w.t + 1.3, Vector2(510.0, 80.0 if w.top else 199.0), 0.0, -1, 0)
			return 3.3
		1:
			w.spawn("reflector", w.t, Vector2(516.0, AXIS + randf_range(-24.0, 24.0)))
			w.spawn("mimic", w.t + 0.6, Vector2(510.0, 70.0), 0.0, -1, 0)
			w.spawn("mimic", w.t + 0.6, Vector2(510.0, 209.0), 1.0, -1, 1)
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 1.4, Vector2(504.0, 60.0))
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 1.4, Vector2(504.0, 219.0), 1.0)
			return 3.8
		_:
			w.spawn("reflector", w.t, Vector2(516.0, 78.0), 0.0, -1, 0)
			w.spawn("reflector", w.t, Vector2(516.0, 201.0), 0.0, -1, 1)
			var sq2: int = w.new_squad(4)
			for k2: int in range(2):
				var d2: float = 22.0 + float(k2) * 20.0
				w.spawn("shard", w.t + 0.7 + float(k2) * 0.4, Vector2(506.0, AXIS - d2), float(k2), sq2, 0)
				w.spawn("shard", w.t + 0.7 + float(k2) * 0.4, Vector2(506.0, AXIS + d2), float(k2), sq2, 1)
			if w.extra > 0:
				w.spawn("mimic", w.t + 1.6, Vector2(510.0, 120.0 if w.top else 159.0), 0.0, -1, 1)
			return 3.9


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Glassy half-time pulse in G# harmonic minor: a dark reese bass, a choir pad, vibraphone
# plucks and a glass-bell lead with a long mirror echo; energy 2 adds the claps, ghost hats and
# fills that drive it.
func get_song() -> Dictionary:
	return {
		"seed": 2323, "style": 4, "root": 44, "bpm": 124.0, "scale": Music.HARMONIC_MINOR,
		"bass": 10, "pad": 2, "arp": 10, "lead": 4, "kit": "hard",
		"energy": 2, "bass_gain": 1.5, "kick_gain": 1.4, "voicing": [0, 2, 4, 6],
		"lead_attack": 110.0, "lead_decay": 1.2, "mel_lo": 0, "mel_hi": 9, "density": 1,
		"delay_beats": 0.75, "delay_fb": 0.46, "delay_wet": 0.34,
		"prog_a": [0, -2, 3, 4, 0, -2, -3, 4],
		"prog_b": [3, 4, 0, -2, 3, 4, 5, 4],
	}


func get_song_alternatives() -> Array:
	return [
		{"name": "LOOKING GLASS LOUNGE", "info": "BOSSA NOVA  132 BPM  D LYDIAN", "seed": 2324,
			"style": 15, "root": 38, "bpm": 132.0, "scale": Music.LYDIAN,
			"arp": 10, "lead": 14, "lead_attack": 70.0, "lead_decay": 1.3,
			"mel_lo": 0, "mel_hi": 8, "delay_beats": 0.75, "delay_fb": 0.36, "delay_wet": 0.3,
			"prog_a": [0, 1, -1, 1, 0, 1, 4, 4], "prog_b": [3, 1, 0, -1, 3, 4, 1, 1]},
	]
