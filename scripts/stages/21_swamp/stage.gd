extends "res://scripts/stages/stage_module.gd"

# STAGE 21: TOXIC SWAMP. A dead, glowing bog at night: a sick green moon behind drifting fog,
# ranks of dead trees hung with moss, gnarled roots and stumps, and an acid bog that bubbles and
# pops along the bottom of the screen. Will-o'-wisps wander; now and then methane ignites, a bog
# creature surfaces, or a dead tree topples in.
#
# Files in this folder:
#   stage.gd            this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              enemy, shot and boss sprites
#   background.gd       the painted layers plus the per-frame animation
#   enemy_bloater.gd    gas bloater: swells, coughs acid, over-inflates and pops into a gas cloud
#   enemy_crawler.gd    bog crawler: crawls the bog, rears up and lobs acid globs that splash
#   enemy_spitter.gd    carnivorous pod on a vine: tracks you, spits a seed stream and a pollen fan
#   boss.gd             BOG BEHEMOTH: sweeping acid stream, gas belch, rot rain

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Bloater = preload("enemy_bloater.gd")
const Crawler = preload("enemy_crawler.gd")
const Spitter = preload("enemy_spitter.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "swamp"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "TOXIC SWAMP",
		"subtitle": "THE ACID BOGLANDS",
		"boss_name": "BOG BEHEMOTH",
		"sky_top": Color("#050705"),
		"sky_mid": Color("#0d1309"),
		"sky_bot": Color("#192210"),
		"deck_fill": Color("#0e1608"),
		"deck_line": Color("#86d41c"),
		"accent": Color("#b4ea48"),
		"has_ceiling": false,
		"scout_tex": "scout_bio",
		"swooper_tex": "swooper_bio",
		"sniper_tex": "sniper_bio",
		"cruiser_tex": "cruiser_bio",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_pink",
		"bullet_b": ID + "_acid",
		"boss_box": Vector2(92.0, 118.0),
		"boss_x": 408.0,
	}


# Stage 21 of the shared 9-28 curve (k = 13). "hp" is the actual growth past stage 8
# (StageData.stage_hp_growth: 1.34^7 x 1.12^k).
func get_difficulty_row() -> Dictionary:
	return {"hp": 33.86, "shot_speed": 1.376, "fire_rate": 1.61, "groups": 17, "pace": 0.683, "themed": 0.804}


func get_boss_hp() -> float:
	return 37000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"bloater": {"hp": 10.0, "score": 300, "scrap": 2, "xp": 6, "r": 8.0, "col_offset": Vector2(0.0, -3.0), "tex": ID + "_bloater_0", "behaviour": Bloater},
		"crawler": {"hp": 12.0, "score": 340, "scrap": 2, "xp": 7, "box": Vector2(30.0, 11.0), "col_offset": Vector2(1.0, 3.0), "tex": ID + "_crawler_0", "behaviour": Crawler},
		"spitter": {"hp": 9.0, "score": 320, "scrap": 2, "xp": 6, "r": 8.0, "tex": ID + "_spitter_0", "behaviour": Spitter},
	}


# A: a drifting squad of gas bloaters over a bog crawler, with generic scouts.
# B: two spitters (one hanging from the canopy, one rooted in the bog), a bloater and a crawler.
# C (from wave 2): a pair of crawlers along the bog under a spitter and a pair of bloaters;
#    wave 3 adds another crawler and a bloater.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 3 + w.extra
			var sq: int = w.new_squad(n)
			var y0: float = 74.0 if w.top else 130.0
			for k: int in range(n):
				w.spawn("bloater", w.t + float(k) * 0.45, Vector2(508.0 + float(k % 2) * 12.0, y0 + float(k) * 34.0), float(k) * 1.1, sq)
			w.spawn("crawler", w.t + 0.6, Vector2(512.0, 242.0), 0.0, -1, 0)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.2, Vector2(504.0, 100.0 if w.top else 170.0))
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.5, Vector2(504.0, 120.0 if w.top else 150.0), 1.0)
			return 3.3
		1:
			w.spawn("spitter", w.t, Vector2(506.0, 80.0), 0.0, -1, 1)
			w.spawn("spitter", w.t + 0.8, Vector2(506.0, 200.0), 1.0, -1, 0)
			w.spawn("bloater", w.t + 0.4, Vector2(508.0, 140.0 if w.top else 110.0), 0.5, -1, 1)
			w.spawn("crawler", w.t + 1.1, Vector2(512.0, 242.0), 0.0, -1, 1)
			if w.extra > 0:
				w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 1.6, Vector2(504.0, 100.0))
			return 3.5
		_:
			var cn: int = 2 + w.extra
			var sq2: int = w.new_squad(cn)
			for c: int in range(cn):
				w.spawn("crawler", w.t + float(c) * 0.55, Vector2(512.0, 242.0), float(c) * 0.5, sq2, c % 2)
			w.spawn("spitter", w.t + 0.3, Vector2(506.0, 80.0), 0.0, -1, 1)
			w.spawn("bloater", w.t + 0.9, Vector2(508.0, 96.0), 0.0, -1, 0)
			w.spawn("bloater", w.t + 1.3, Vector2(508.0, 168.0), 1.3, -1, 1)
			if w.extra > 0:
				w.spawn("bloater", w.t + 1.8, Vector2(512.0, 132.0), 2.0, -1, 0)
			return 3.8


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Swamp-blues boom-bap in E Phrygian dominant: a heavy swing, upright bass, a drawbar organ, a
# marimba and an overdriven slide-guitar lead through a murky low-pass.
func get_song() -> Dictionary:
	return {
		"seed": 2121, "style": 14, "root": 40, "bpm": 92.0, "scale": Music.PHRYGIAN_DOM, "swing": 0.18,
		"bass": 14, "pad": 11, "arp": 3, "lead": 5, "kit": "lofi", "voicing": [0, 2, 4, 6],
		"lead_attack": 70.0, "lead_decay": 1.1, "glide": 18.0, "vib": 0.006, "mel_lo": -1, "mel_hi": 7,
		"delay_beats": 0.75, "delay_fb": 0.36, "delay_wet": 0.3, "master_lp": 0.78,
		"energy": 1, "bass_gain": 1.6,
		"prog_a": [0, 0, 1, 1, -2, -2, 1, 0],
		"prog_b": [3, 1, 0, -2, 3, 1, 4, 4],
	}


func get_song_alternatives() -> Array:
	return [
		{"name": "BOG DUB", "info": "DUB  76 BPM  B PHRYGIAN", "seed": 2122,
			"style": 6, "root": 35, "bpm": 76.0, "scale": Music.PHRYGIAN,
			"bass": 5, "pad": 6, "arp": 3, "lead": 10, "lead_decay": 1.3,
			"delay_beats": 0.75, "delay_fb": 0.5, "delay_wet": 0.38, "mel_lo": 0, "mel_hi": 7,
			"prog_a": [0, 0, 1, 0, -2, -2, 1, 1], "prog_b": [3, 3, 1, 1, 0, -2, 1, 1]},
	]
