extends "res://scripts/stages/stage_module.gd"

# STAGE 13: CRYSTAL CAVE. A near-black violet cavern grown over with amethyst, rose, emerald and
# gold crystal; glowing geodes, glinting facets and faint rainbow light refracted through the
# ceiling cracks.
#
# Files in this folder:
#   stage.gd         this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd           enemy, shot and boss sprites
#   background.gd    the painted layers plus the per-frame animation
#   enemy_prism.gd   floor/ceiling prism turret: facets charge, its bolt splits into 3 shards
#   enemy_bat.gd     crystal bats in erratic swarms that shriek, then dive with a spread
#   enemy_golem.gd   gem golem that reflects hits while it shimmers, then bursts open
#   boss.gd          PRISM HYDRA: head beams, split orbs, spectrum spiral

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Prism = preload("enemy_prism.gd")
const Bat = preload("enemy_bat.gd")
const Golem = preload("enemy_golem.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "crystal"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "CRYSTAL CAVE",
		"subtitle": "PRISMATIC GEODE DEPTHS",
		"boss_name": "PRISM HYDRA: SPECTRA",
		"sky_top": Color("#07040c"),
		"sky_mid": Color("#0c0615"),
		"sky_bot": Color("#170c27"),
		"deck_fill": Color("#1a0f2c"),
		"deck_line": Color("#c070ff"),
		"accent": Color("#e090ff"),
		"has_ceiling": true,
		"scout_tex": "scout_cyber",
		"swooper_tex": "swooper_cyber",
		"sniper_tex": "sniper_cyber",
		"cruiser_tex": "cruiser_cyber",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_orange",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(88.0, 140.0),
		"boss_x": 410.0,
	}


# Stage 13 of the shared 9-28 curve (k = 5). "hp" is the actual growth past stage 8
# (StageData.stage_hp_growth: 1.34^7 x 1.12^k).
func get_difficulty_row() -> Dictionary:
	return {"hp": 13.67, "shot_speed": 1.28, "fire_rate": 1.45, "groups": 14, "pace": 0.755, "themed": 0.74}


func get_boss_hp() -> float:
	return 25000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"prism": {"hp": 9.0, "score": 320, "scrap": 2, "xp": 6, "r": 8.0, "tex": ID + "_prism_0", "behaviour": Prism},
		"bat": {"hp": 4.0, "score": 160, "scrap": 1, "xp": 3, "r": 6.0, "tex": ID + "_bat_0", "behaviour": Bat},
		"golem": {"hp": 26.0, "score": 720, "scrap": 5, "xp": 15, "r": 13.0, "tex": ID + "_golem_0", "behaviour": Golem, "big": true, "exit_left": -50.0},
	}


# A: a swarm of crystal bats with a prism turret on the ceiling or floor.
# B: a gem golem with a couple of bats, generic scouts and a prism turret.
# C (from wave 2): a pair of prism turrets (floor and ceiling) under a bat swarm; wave 3 adds a
#    golem.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 6 + w.extra
			var sq: int = w.new_squad(n)
			var y: float = 84.0 if w.top else 186.0
			for k: int in range(n):
				w.spawn("bat", w.t + float(k) * 0.2, Vector2(504.0 + float(k % 2) * 10.0, y + float((k * 13) % 5 - 2) * 9.0), float(k), sq)
			w.spawn("prism", w.t + 0.4, Vector2(500.0, 36.0), 0.0, -1, 1 if w.top else 0)
			return 3.2
		1:
			w.spawn("golem", w.t, Vector2(516.0, 135.0 + randf_range(-30.0, 30.0)))
			w.spawn("bat", w.t + 0.8, Vector2(504.0, 70.0), 0.0)
			w.spawn("bat", w.t + 1.0, Vector2(504.0, 200.0), 1.0)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.4, Vector2(504.0, 110.0))
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.7, Vector2(504.0, 160.0), 1.0)
			w.spawn("prism", w.t + 1.2, Vector2(500.0, 248.0 if w.top else 36.0), 0.0, -1, 0 if w.top else 1)
			return 3.8
		_:
			w.spawn("prism", w.t, Vector2(500.0, 248.0), 0.0, -1, 0)
			w.spawn("prism", w.t + 0.6, Vector2(500.0, 36.0), 0.0, -1, 1)
			var sq2: int = w.new_squad(4)
			for k2: int in range(4):
				w.spawn("bat", w.t + 0.5 + float(k2) * 0.22, Vector2(504.0, 120.0 + float(k2 % 2) * 30.0), float(k2), sq2)
			if w.extra > 0:
				w.spawn("golem", w.t + 1.4, Vector2(520.0, 100.0 if w.top else 170.0))
			return 3.9


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Shimmering synth drive in F# Lydian (the raised 4th gives it the glassy, wondrous lift):
# octave-pumping saw bass, warm analog pad, an ice-bell arpeggio and a sine-bell lead.
func get_song() -> Dictionary:
	return {
		"seed": 1313, "style": 11, "gv": 1, "root": 42, "bpm": 118.0, "scale": Music.LYDIAN,
		"bass": 7, "pad": 12, "arp": 4, "lead": 6, "kit": "hard",
		"energy": 2, "bass_gain": 1.55, "kick_gain": 1.3,
		"lead_attack": 90.0, "lead_decay": 1.4, "mel_lo": 0, "mel_hi": 9,
		"delay_beats": 0.75, "delay_fb": 0.38, "delay_wet": 0.32,
		"prog_a": [0, 1, 0, 1, -2, -1, 1, 1],
		"prog_b": [-2, -1, 0, 1, 3, 1, 4, 4],
	}


func get_song_alternatives() -> Array:
	return [
		{"name": "GEODE GLITTER", "info": "CHIPTUNE  150 BPM  B LYDIAN", "seed": 1314,
			"style": 9, "gv": 2, "root": 35, "bpm": 150.0, "scale": Music.LYDIAN,
			"bass": 9, "pad": 9, "arp": 4, "lead": 9, "kit": "chip", "vib": 0.006,
			"lead_decay": 2.4, "harm_int": -7, "mel_lo": 0, "mel_hi": 8, "delay_wet": 0.2,
			"prog_a": [0, 1, 0, 1, 4, 1, 0, 0], "prog_b": [-2, -1, 0, 1, -2, 1, 4, 4]},
	]
