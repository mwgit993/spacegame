extends "res://scripts/stages/stage_module.gd"

# STAGE 17: BLACK HOLE. Skimming the rim of a black hole: its shadow ringed by a lensed photon
# halo and a turning accretion disk, stars smeared into streaks as they fall in.
#
# Files in this folder:
#   stage.gd          stage table entry, difficulty, enemies, wave recipes, song
#   art.gd            every sprite (enemies, shot, generic re-skins, the Devourer's frames)
#   background.gd     the painted void plus the animated disk, infall and events
#   enemy_well.gd     gravity-well mines: telegraphed, then bend shots round themselves
#   enemy_eye.gd      void eyes: track the ship, lock a sight line, stare a stream down it
#   enemy_husk.gd     time-frozen husks: skip ahead in time and fire shots that hang, then go
#   boss.gd           EVENT HORIZON THE DEVOURER's attack patterns

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Well = preload("enemy_well.gd")
const Eye = preload("enemy_eye.gd")
const Husk = preload("enemy_husk.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "voidrim"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "BLACK HOLE",
		"subtitle": "THE EVENT HORIZON RIM",
		"boss_name": "EVENT HORIZON THE DEVOURER",
		"sky_top": Color("#020104"),
		"sky_mid": Color("#08040e"),
		"sky_bot": Color("#120818"),
		"deck_fill": Color("#120a1a"),
		"deck_line": Color("#ff9a30"),
		"accent": Color("#ffb060"),
		"has_ceiling": false,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(76.0, 110.0),
		"boss_x": 404.0,
	}


# Stage 17 on the shared curve (k = 9). "hp" is StageData.stage_hp_growth(16): 1.34^7 x 1.12^9.
func get_difficulty_row() -> Dictionary:
	return {"hp": 21.51, "shot_speed": 1.328, "fire_rate": 1.53, "groups": 16, "pace": 0.719, "themed": 0.772}


func get_boss_hp() -> float:
	return 31000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"well": {"hp": 9.0, "score": 380, "scrap": 2, "xp": 7, "r": 7.5, "tex": ID + "_well_0", "behaviour": Well},
		"eye": {"hp": 12.0, "score": 420, "scrap": 3, "xp": 8, "r": 8.5, "tex": ID + "_eye_0", "behaviour": Eye},
		"husk": {"hp": 17.0, "score": 480, "scrap": 3, "xp": 9, "r": 9.0, "tex": ID + "_husk_0", "behaviour": Husk},
	}


# A: void eyes in a column with generic swoopers. B: a gravity well guarding a husk pair.
# C: two wells, an eye between them and a husk behind.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			for k: int in range(2 + w.extra):
				w.spawn("eye", w.t + float(k) * 0.6, Vector2(512.0, 80.0 + 55.0 * float(k)), float(k))
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 0.9, Vector2(504.0, 60.0))
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 1.2, Vector2(504.0, 205.0), 1.0)
			return 3.0
		1:
			var wy: float = 100.0 if w.top else 170.0
			w.spawn("well", w.t, Vector2(512.0, wy))
			w.spawn("husk", w.t + 0.6, Vector2(512.0, 270.0 - wy - 22.0), 0.0)
			w.spawn("husk", w.t + 1.2, Vector2(512.0, 270.0 - wy + 22.0), 1.0)
			if w.extra > 0:
				w.spawn("eye", w.t + 1.6, Vector2(512.0, wy), 0.0)
			return 3.4
		_:
			w.spawn("well", w.t, Vector2(512.0, 70.0), 0.0)
			w.spawn("well", w.t + 0.3, Vector2(512.0, 200.0), 1.0)
			w.spawn("eye", w.t + 0.8, Vector2(512.0, 135.0), 0.0)
			w.spawn("husk", w.t + 1.4, Vector2(512.0, 135.0 + randf_range(-40.0, 40.0)), 0.0)
			if w.extra > 0:
				w.spawn("eye", w.t + 1.9, Vector2(512.0, 100.0), 1.0)
			return 3.7


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Crushing half-time in Bb Phrygian, as if time itself were dragging: a huge 808 bass, warm
# analog pads, sonar pings falling into the dark, and a bit-crushed supersaw lead.
func get_song() -> Dictionary:
	return {
		"seed": 1717, "style": 4, "root": 34, "bpm": 86.0, "scale": Music.PHRYGIAN,
		"bass": 13, "pad": 12, "arp": 6, "lead": 7, "kit": "hard", "crush": 2,
		"energy": 2, "bass_gain": 1.85, "kick_gain": 1.55, "sub_mix": 0.65,
		"lead_attack": 110.0, "lead_decay": 1.6, "density": 1, "mel_lo": -1, "mel_hi": 7, "lift": 3,
		"delay_beats": 0.5, "delay_fb": 0.42, "delay_wet": 0.3,
		"prog_a": [0, 0, 1, 1, 0, 0, -2, 1],
		"prog_b": [-2, -1, 0, 0, -2, 3, 1, 1],
	}
