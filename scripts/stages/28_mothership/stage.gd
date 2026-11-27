extends "res://scripts/stages/stage_module.gd"

# STAGE 28: MOTHERSHIP, the final level. Inside the armada's flagship: an immense hangar with
# racks of parked fighters, cranes, assembly lines building drones, drone columns marching
# along the gantries, the reactor core glowing at the far end and the armada's sigil (a crimson
# triangle with an eye) on every banner. Beating THE OVERMIND ends the war ("THE ARMADA IS
# DEFEATED!"); the flagship blows up behind you during the jump and play loops as usual.
#
# Files in this folder:
#   stage.gd            stage table entry, difficulty, enemies, wave recipes, songs
#   art.gd              every sprite (enemies, shots, generic re-skins, the Overmind's frames)
#   background.gd       the painted hangar layers plus the per-frame animation and the finale
#   enemy_elite.gd      armada elite fighters: swoop in, lock a laser sight, fire, barrel-roll
#   enemy_factory.gd    drone factories riding the floor/ceiling rails, building drones
#   enemy_drone.gd      the factory's attack drones (children, capped): home in, fire once
#   enemy_marshal.gd    strike marshals: mark a strip of the screen and call in a strafing run
#   enemy_striker.gd    the strike fighters a marshal calls in from behind (children, capped)
#   boss.gd             THE OVERMIND: five acts of patterns that nod to the earlier bosses

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Elite = preload("enemy_elite.gd")
const Factory = preload("enemy_factory.gd")
const Drone = preload("enemy_drone.gd")
const Marshal = preload("enemy_marshal.gd")
const Striker = preload("enemy_striker.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "mothership"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "MOTHERSHIP",
		"subtitle": "HEART OF THE ARMADA",
		"boss_name": "THE OVERMIND",
		"sky_top": Color("#07080c"),
		"sky_mid": Color("#0c0e14"),
		"sky_bot": Color("#120a10"),
		"deck_fill": Color("#181a22"),
		"deck_line": Color("#c41e34"),
		"accent": Color("#ff4058"),
		"has_ceiling": true,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(100.0, 150.0),
		"boss_x": 398.0,
		"clear_banner": "THE ARMADA IS DEFEATED!",
	}


# Stage 28 on the shared curve (k = 20). "hp" is StageData.stage_hp_growth(27): 1.34^7 x 1.12^20.
func get_difficulty_row() -> Dictionary:
	return {"hp": 74.83, "shot_speed": 1.46, "fire_rate": 1.75, "groups": 19, "pace": 0.62, "themed": 0.85}


func get_boss_hp() -> float:
	return 60000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"elite": {"hp": 9.0, "score": 420, "scrap": 3, "xp": 8, "r": 7.5, "tex": ID + "_elite_0", "behaviour": Elite},
		"factory": {"hp": 26.0, "score": 700, "scrap": 5, "xp": 13, "box": Vector2(38.0, 22.0), "tex": ID + "_factory_0", "behaviour": Factory, "big": true, "exit_left": -50.0},
		"drone": {"hp": 2.6, "score": 90, "scrap": 1, "xp": 2, "r": 5.0, "tex": ID + "_drone_0", "behaviour": Drone},
		"marshal": {"hp": 18.0, "score": 560, "scrap": 4, "xp": 10, "box": Vector2(32.0, 16.0), "tex": ID + "_marshal_0", "behaviour": Marshal, "col_offset": Vector2(0.0, 2.0)},
		"striker": {"hp": 3.0, "score": 110, "scrap": 1, "xp": 2, "r": 5.0, "tex": ID + "_striker_0", "behaviour": Striker, "exit_left": -60.0},
	}


# A: an elite squadron in a staggered V, with a drone factory on one rail. B: a strike marshal
# covered by two elites (a second factory in the third wave). C: factories on both rails, a
# marshal and an elite pair behind a generic cruiser.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 3 + w.extra
			var sq: int = w.new_squad(n)
			var cy: float = randf_range(90.0, 180.0)
			for k: int in range(n):
				var off: float = float((k + 1) / 2) * 34.0 * (-1.0 if k % 2 == 1 else 1.0)
				w.spawn("elite", w.t + float((k + 1) / 2) * 0.35, Vector2(512.0, clampf(cy + off, 46.0, 226.0)), float(k), sq, k % 2)
			w.spawn("factory", w.t + 0.6, Vector2(530.0, 0.0), 0.0, -1, w.idx % 2)
			return 3.1
		1:
			var my: float = 80.0 if w.top else 190.0
			w.spawn("marshal", w.t, Vector2(512.0, my), 0.0, -1, 0)
			w.spawn("elite", w.t + 0.5, Vector2(512.0, 270.0 - my), 0.0, -1, 0)
			w.spawn("elite", w.t + 0.9, Vector2(512.0, 135.0), 1.0, -1, 1)
			if w.extra > 0:
				w.spawn("factory", w.t + 1.2, Vector2(530.0, 0.0), 0.0, -1, 1 if w.top else 0)
			return 3.3
		_:
			w.spawn("factory", w.t, Vector2(530.0, 0.0), 0.0, -1, 0)
			w.spawn("factory", w.t + 0.7, Vector2(530.0, 0.0), 0.0, -1, 1)
			w.spawn("marshal", w.t + 1.0, Vector2(512.0, 135.0 + randf_range(-40.0, 40.0)), 0.0, -1, 0)
			var sq2: int = w.new_squad(2 + w.extra)
			for k2: int in range(2 + w.extra):
				w.spawn("elite", w.t + 1.5 + float(k2) * 0.3, Vector2(512.0, 70.0 + 65.0 * float(k2)), float(k2), sq2, k2 % 2)
			w.spawn_generic(GameEnemy.Type.CRUISER, w.t + 0.4, Vector2(518.0, randf_range(110.0, 160.0)))
			return 3.8


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# The finale: the boss groove driven harder, in E harmonic minor at 168 BPM. Pumping saw bass,
# gated hypersaw chords, pulse plucks and a soaring supersaw lead over a hard kit.
func get_song() -> Dictionary:
	return {
		"seed": 2828, "style": 8, "root": 40, "bpm": 168.0, "scale": Music.HARMONIC_MINOR,
		"bass": 7, "pad": 7, "arp": 8, "lead": 7, "kit": "hard",
		"energy": 2, "bass_gain": 1.7, "kick_gain": 1.5, "sub_mix": 0.55,
		"lead_attack": 150.0, "lead_decay": 1.6, "harm_int": -2, "density": 2,
		"mel_lo": 0, "mel_hi": 9, "lift": 3, "vib": 0.005,
		"delay_beats": 0.75, "delay_fb": 0.32, "delay_wet": 0.22,
		"prog_a": [0, 0, -2, -1, 0, 3, -1, -1],
		"prog_b": [3, 4, 0, -2, 3, 4, -1, 4],
	}


# The same war at the end of all things, orchestral, for the soundtrack picker in Options.
func get_song_alternatives() -> Array:
	return [
		{"name": "ARMADA'S END", "info": "ORCHESTRAL TAIKO  132 BPM  C HARMONIC MINOR", "seed": 2829,
			"style": 12, "gv": 1, "root": 36, "bpm": 132.0, "scale": Music.HARMONIC_MINOR,
			"bass": 12, "pad": 10, "arp": 2, "lead": 11, "kit": "orch",
			"energy": 2, "lead_attack": 40.0, "lead_decay": 1.1, "density": 1, "mel_lo": 2, "mel_hi": 10,
			"delay_beats": 1.5, "delay_fb": 0.3, "delay_wet": 0.26,
			"prog_a": [0, 0, -3, -3, -2, -2, -1, -1], "prog_b": [3, 3, -2, -2, 0, 3, -1, 4]},
	]
