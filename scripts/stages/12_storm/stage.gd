extends "res://scripts/stages/stage_module.gd"

# STAGE 12: JOVIAN STORM. Deep inside a gas giant's storm bands: belts of cloud streaming past in
# opposite directions, the Great Storm Eye turning far away, thunderheads, rain and lightning.
#
# Files in this folder:
#   stage.gd            this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              enemy, shot and boss sprites
#   background.gd       the painted layers plus the per-frame animation
#   enemy_manta.gd      storm manta: big swoops, crackling wingtips, then twin wingtip fans
#   enemy_orb.gd        lightning orbs in squads that link up into short-lived electric fences
#   enemy_gunship.gd    cloud-skimmer gunship: rises out of the clouds, rakes two bursts, sinks
#   boss.gd             STORMCALLER: lightning lances, cyclone spirals, hail

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Manta = preload("enemy_manta.gd")
const Orb = preload("enemy_orb.gd")
const Gunship = preload("enemy_gunship.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "storm"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "JOVIAN STORM",
		"subtitle": "GAS GIANT STORM BANDS",
		"boss_name": "STORMCALLER WEATHER ENGINE",
		"sky_top": Color("#0a121a"),
		"sky_mid": Color("#0d1820"),
		"sky_bot": Color("#0b141c"),
		"deck_fill": Color("#101a24"),
		"deck_line": Color("#5ad8e8"),
		"accent": Color("#8ae8ff"),
		"has_ceiling": false,
		"scout_tex": "scout_aero",
		"swooper_tex": "swooper_aero",
		"sniper_tex": "sniper_mech",
		"cruiser_tex": "cruiser_mech",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_orange",
		"bullet_b": ID + "_spark",
		"boss_box": Vector2(84.0, 136.0),
		"boss_x": 410.0,
	}


# Stage 12 of the shared 9-28 curve (k = 4). "hp" is the actual growth past stage 8
# (StageData.stage_hp_growth: 1.34^7 x 1.12^k).
func get_difficulty_row() -> Dictionary:
	return {"hp": 12.21, "shot_speed": 1.268, "fire_rate": 1.43, "groups": 14, "pace": 0.764, "themed": 0.732}


func get_boss_hp() -> float:
	return 23500.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"manta": {"hp": 12.0, "score": 380, "scrap": 3, "xp": 8, "r": 9.0, "tex": ID + "_manta_0", "behaviour": Manta},
		"orb": {"hp": 7.0, "score": 240, "scrap": 2, "xp": 5, "r": 6.5, "tex": ID + "_orb_0", "behaviour": Orb},
		"gunship": {"hp": 20.0, "score": 560, "scrap": 4, "xp": 11, "box": Vector2(28.0, 10.0), "col_offset": Vector2(0.0, 1.0), "tex": ID + "_gunship_0", "behaviour": Gunship},
	}


# A: a squad of lightning orbs strung out in a line (they fence each other in), scouts behind.
# B: two mantas swooping high and low, and a gunship rising from the far cloud edge.
# C (from wave 2): gunships top and bottom with an orb trio between; wave 3 adds a manta.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 4 + w.extra
			var sq: int = w.new_squad(n)
			var y0: float = 62.0 if w.top else 78.0
			var tilt: float = 12.0 if w.top else -12.0
			for k: int in range(n):
				w.spawn("orb", w.t + float(k) * 0.12, Vector2(506.0 + float(k) * tilt * 0.5, y0 + float(k) * (150.0 / float(n - 1))), float(k), sq)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.4, Vector2(504.0, 100.0))
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.7, Vector2(504.0, 170.0), 1.0)
			return 3.5
		1:
			w.spawn("manta", w.t, Vector2(512.0, 86.0), 0.0, -1, 0)
			w.spawn("manta", w.t + 0.9, Vector2(512.0, 184.0), 1.6, -1, 1)
			w.spawn("gunship", w.t + 1.2, Vector2(400.0, 266.0), 0.0, -1, 0 if w.top else 1)
			if w.extra > 0:
				w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 1.8, Vector2(504.0, 135.0))
			return 3.8
		_:
			w.spawn("gunship", w.t, Vector2(410.0, 266.0), 0.0, -1, 0)
			w.spawn("gunship", w.t + 0.9, Vector2(350.0, 6.0), 0.0, -1, 1)
			var sq2: int = w.new_squad(3)
			for k2: int in range(3):
				w.spawn("orb", w.t + 0.6 + float(k2) * 0.12, Vector2(508.0 + float(k2) * 14.0, 96.0 + float(k2) * 38.0), float(k2), sq2)
			if w.extra > 0:
				w.spawn("manta", w.t + 1.6, Vector2(512.0, 135.0), 0.0, -1, 0)
			return 4.0


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Storm ride in 6/8: a rolling pumping-saw bass, drawbar-organ chords, harp arpeggios and a sync
# square lead over a hard kit, in F minor. Two big beats a bar give it a heaving, galloping swell.
func get_song() -> Dictionary:
	return {
		"seed": 1212, "style": 17, "gv": 1, "bar_steps": 12, "meter": "68",
		"root": 41, "bpm": 136.0, "scale": Music.MINOR,
		"bass": 7, "pad": 11, "arp": 2, "lead": 1, "kit": "hard",
		"energy": 2, "bass_gain": 1.6, "kick_gain": 1.35,
		"lead_decay": 1.6, "mel_lo": 0, "mel_hi": 9, "delay_beats": 0.75, "delay_fb": 0.32, "delay_wet": 0.26,
		"prog_a": [0, 0, -2, -1, 0, 3, -1, 4],
		"prog_b": [3, -2, -1, 0, 3, -2, 4, 4],
	}


func get_song_alternatives() -> Array:
	return [
		{"name": "THUNDERHEAD", "info": "OUTRUN  118 BPM  C MINOR", "seed": 1213,
			"style": 11, "gv": 1, "root": 36, "bpm": 118.0, "scale": Music.MINOR,
			"bass": 7, "pad": 12, "arp": 8, "lead": 11, "kit": "hard",
			"lead_decay": 1.5, "mel_lo": -1, "mel_hi": 7,
			"prog_a": [0, -2, 3, -1, 0, -2, 3, 4], "prog_b": [-2, -1, 0, 0, -2, -1, 4, 4]},
	]
