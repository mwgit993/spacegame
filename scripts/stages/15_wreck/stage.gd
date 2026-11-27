extends "res://scripts/stages/stage_module.gd"

# STAGE 15: GRAVEYARD. A dead fleet adrift in a green ghost-haze: snapped capital ships on the
# horizon, sparking hull debris tumbling past, a vast derelict's hull scrolling below.
#
# Files in this folder:
#   stage.gd            stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              every sprite (enemies, shots, generic re-skins, the flagship's frames)
#   background.gd       the painted graveyard layers plus the per-frame animation
#   enemy_ghost.gd      ghost frigates that phase in and out (only hittable while solid)
#   enemy_salvager.gd   salvage drones holding scrap plates as shields, re-grabbing one by tractor
#   enemy_hulk.gd       drifting hulks that drop mines (capped)
#   enemy_mine.gd       the mines (children only from hulks)
#   boss.gd             PHANTOM FLAGSHIP REQUIEM's attack patterns

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Ghost = preload("enemy_ghost.gd")
const Salvager = preload("enemy_salvager.gd")
const Hulk = preload("enemy_hulk.gd")
const Mine = preload("enemy_mine.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "wreck"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "GRAVEYARD",
		"subtitle": "DERELICT FLEET IN THE HAZE",
		"boss_name": "PHANTOM FLAGSHIP REQUIEM",
		"sky_top": Color("#040807"),
		"sky_mid": Color("#08120f"),
		"sky_bot": Color("#0d1c17"),
		"deck_fill": Color("#141c1a"),
		"deck_line": Color("#4cd8a0"),
		"accent": Color("#7cffc8"),
		"has_ceiling": false,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_pink",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(84.0, 140.0),
		"boss_x": 408.0,
	}


# Stage 15 on the shared curve (k = 7). "hp" is StageData.stage_hp_growth(14): 1.34^7 x 1.12^7.
func get_difficulty_row() -> Dictionary:
	return {"hp": 17.15, "shot_speed": 1.304, "fire_rate": 1.49, "groups": 15, "pace": 0.737, "themed": 0.756}


func get_boss_hp() -> float:
	return 28000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"ghost": {"hp": 10.0, "score": 380, "scrap": 2, "xp": 7, "r": 8.0, "tex": ID + "_ghost_0", "behaviour": Ghost},
		"salvager": {"hp": 9.0, "score": 360, "scrap": 2, "xp": 7, "r": 7.5, "tex": ID + "_salvager_0", "behaviour": Salvager},
		"hulk": {"hp": 30.0, "score": 700, "scrap": 5, "xp": 15, "box": Vector2(46.0, 18.0), "tex": ID + "_hulk_0", "behaviour": Hulk, "big": true, "exit_left": -60.0},
		"mine": {"hp": 1.6, "score": 40, "scrap": 1, "xp": 1, "r": 5.5, "tex": ID + "_mine_0", "behaviour": Mine},
	}


# A: ghosts in a staggered line with generic scouts. B: a mine hulk escorted by salvagers.
# C: a ghost pair over a salvager screen, plus a hulk in the third wave.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			for k: int in range(2 + w.extra):
				w.spawn("ghost", w.t + float(k) * 0.7, Vector2(510.0, 70.0 + 65.0 * float(k)), float(k), -1, k % 2)
			var sq: int = w.new_squad(4)
			var lane: float = randf_range(90.0, 180.0)
			for k2: int in range(4):
				w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 0.8 + float(k2) * 0.24, Vector2(504.0, lane), float(k2) * 0.52, sq)
			return 3.1
		1:
			var hy: float = 90.0 if w.top else 175.0
			w.spawn("hulk", w.t, Vector2(530.0, hy))
			w.spawn("salvager", w.t + 0.6, Vector2(510.0, 270.0 - hy - 20.0), 0.0, -1, 0)
			w.spawn("salvager", w.t + 1.0, Vector2(510.0, 270.0 - hy + 20.0), 0.0, -1, 1)
			if w.extra > 0:
				w.spawn("ghost", w.t + 1.6, Vector2(510.0, hy), 0.0, -1, 1)
			return 3.5
		_:
			w.spawn("ghost", w.t, Vector2(510.0, 80.0), 0.0, -1, 0)
			w.spawn("ghost", w.t + 0.4, Vector2(510.0, 190.0), 1.0, -1, 1)
			for k3: int in range(2 + w.extra):
				w.spawn("salvager", w.t + 0.9 + float(k3) * 0.5, Vector2(510.0, 105.0 + 40.0 * float(k3)), 0.0, -1, k3 % 2)
			if w.extra > 0:
				w.spawn("hulk", w.t + 1.4, Vector2(530.0, 135.0))
			return 3.7


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# A haunted waltz in D harmonic minor, as if the dead fleet's ballroom were still playing:
# 3/4 time, fretless bass, a wheezing drawbar organ, a music box, and a theremin-like whistle
# lead swimming in a long echo.
func get_song() -> Dictionary:
	return {
		"seed": 1515, "style": 2, "bar_steps": 12, "root": 38, "bpm": 104.0,
		"scale": Music.HARMONIC_MINOR, "bass": 2, "pad": 11, "arp": 4, "lead": 13,
		"voicing": [0, 2, 4, 6], "energy": 2, "bass_gain": 2.1, "kick_gain": 1.65, "sub_mix": 0.6,
		"lead_attack": 24.0, "lead_decay": 0.9, "vib": 0.013, "glide": 26.0,
		"density": 0, "mel_lo": 0, "mel_hi": 9, "lift": 2,
		"delay_beats": 1.0, "delay_fb": 0.46, "delay_wet": 0.38,
		"prog_a": [0, -2, 3, 4, 0, -2, 4, 4],
		"prog_b": [3, 0, -2, 4, 3, 0, 4, 0],
	}
