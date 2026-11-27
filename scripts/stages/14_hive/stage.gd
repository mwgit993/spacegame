extends "res://scripts/stages/stage_module.gd"

# STAGE 14: ALIEN HIVE. Deep inside an insect brood nest: honeycomb walls lit by glowing eggs,
# resin dripping from the ceiling, pulsing larva sacs on the floor.
#
# Files in this folder:
#   stage.gd         stage table entry, difficulty, enemies, wave recipes, song
#   art.gd           every sprite (enemies, shots, generic re-skins, the queen's frames)
#   background.gd    the painted hive layers plus the per-frame animation
#   enemy_drone.gd   drones that fly as a swirling flock, then dive at the ship one by one
#   enemy_guard.gd   armoured acid-spitting guards: lobbed acid globs and spit fans
#   enemy_egg.gd     egg sacs on the floor and ceiling that hatch into larvae if left alone
#   enemy_larva.gd   the hatchlings (children only from eggs; capped)
#   boss.gd          BROOD QUEEN VESPERA's attack patterns

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Drone = preload("enemy_drone.gd")
const Guard = preload("enemy_guard.gd")
const Egg = preload("enemy_egg.gd")
const Larva = preload("enemy_larva.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "hive"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "ALIEN HIVE",
		"subtitle": "XENO BROOD NEST",
		"boss_name": "BROOD QUEEN VESPERA",
		"sky_top": Color("#0e0805"),
		"sky_mid": Color("#1a0f07"),
		"sky_bot": Color("#26160a"),
		"deck_fill": Color("#2a170b"),
		"deck_line": Color("#d89428"),
		"accent": Color("#ffc040"),
		"has_ceiling": true,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(78.0, 136.0),
		"boss_x": 410.0,
	}


# Stage 14 on the shared curve (k = 6). "hp" is StageData.stage_hp_growth(13): 1.34^7 x 1.12^6.
func get_difficulty_row() -> Dictionary:
	return {"hp": 15.31, "shot_speed": 1.292, "fire_rate": 1.47, "groups": 15, "pace": 0.746, "themed": 0.748}


func get_boss_hp() -> float:
	return 26500.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"drone": {"hp": 3.4, "score": 130, "scrap": 1, "xp": 2, "r": 5.5, "tex": ID + "_drone_0", "behaviour": Drone},
		"guard": {"hp": 16.0, "score": 420, "scrap": 3, "xp": 9, "r": 10.0, "tex": ID + "_guard_0", "behaviour": Guard, "col_offset": Vector2(-2.0, 0.0)},
		"egg": {"hp": 7.5, "score": 260, "scrap": 2, "xp": 5, "r": 7.5, "tex": ID + "_egg_0", "behaviour": Egg},
		"larva": {"hp": 2.2, "score": 60, "scrap": 1, "xp": 1, "r": 5.0, "tex": ID + "_larva_0", "behaviour": Larva},
	}


# A: a drone flock (they spawn together and swirl round one centre), plus an egg on the floor
#    or ceiling. B: a guard with an egg on each side and a small flock. C: two flocks crossing
#    and a guard.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 5 + w.extra
			var lane: float = randf_range(80.0, 190.0)
			var sq: int = w.new_squad(n)
			for k: int in range(n):
				w.spawn("drone", w.t, Vector2(512.0, lane), float(k), sq, 0 if w.top else 1)
			w.spawn("egg", w.t + 0.8, Vector2(504.0, 0.0), 0.0, -1, 0 if w.top else 1)
			w.spawn_generic(GameEnemy.Type.SNIPER, w.t + 1.4, Vector2(504.0, 270.0 - lane))
			return 2.7
		1:
			var gy: float = 88.0 if w.top else 182.0
			w.spawn("guard", w.t, Vector2(512.0, gy))
			w.spawn("egg", w.t + 0.5, Vector2(504.0, 0.0), 0.0, -1, 0)
			w.spawn("egg", w.t + 1.3, Vector2(504.0, 0.0), 0.0, -1, 1)
			if w.extra > 0:
				w.spawn("guard", w.t + 1.6, Vector2(512.0, 270.0 - gy), 0.0, -1, 1)
			var sq_b: int = w.new_squad(3)
			for k: int in range(3):
				w.spawn("drone", w.t + 0.9, Vector2(512.0, 270.0 - gy), float(k), sq_b, 1 if w.top else 0)
			return 2.9
		_:
			for f: int in range(2):
				var n2: int = 4 + w.extra
				var sq2: int = w.new_squad(n2)
				var ly: float = 70.0 if f == 0 else 200.0
				for k2: int in range(n2):
					w.spawn("drone", w.t + float(f) * 1.1, Vector2(512.0, ly), float(k2), sq2, f)
			w.spawn("guard", w.t + 0.6, Vector2(512.0, 135.0), 0.0, -1, 0)
			return 3.5


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# "Swarm metal" in F# harmonic minor: the driving double-kick 16ths of the metal groove under
# a reese bass, a dark choir, marimba "clicks" like mandibles and a buzzing PWM lead with a
# wide insect vibrato.
func get_song() -> Dictionary:
	return {
		"seed": 1414, "style": 5, "root": 42, "bpm": 144.0, "scale": Music.HARMONIC_MINOR,
		"bass": 10, "pad": 2, "arp": 3, "lead": 10, "kit": "hard",
		"energy": 2, "bass_gain": 1.0, "kick_gain": 1.15, "sub_mix": 0.4,
		"lead_attack": 90.0, "lead_decay": 1.4, "vib": 0.011, "harm_int": -2,
		"mel_lo": -1, "mel_hi": 7, "lift": 3, "density": 1,
		"delay_beats": 0.5, "delay_fb": 0.3, "delay_wet": 0.22,
		"prog_a": [0, 3, 0, 4, -2, 3, 4, 4],
		"prog_b": [3, 3, 0, 0, -2, -2, 4, 4],
	}
