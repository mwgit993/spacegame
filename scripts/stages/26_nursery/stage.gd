extends "res://scripts/stages/stage_module.gd"

# STAGE 26: STAR NURSERY. A stellar nursery deep in a nebula: towering gas pillars rim-lit
# by young suns, newborn stars blinking awake inside them, protoplanetary disks turning, dust
# lanes and slow luminous gas currents drifting past.
#
# Files in this folder:
#   stage.gd          stage table entry, difficulty, enemies, wave recipes, song
#   art.gd            every sprite (enemies, shots, generic re-skins, the protostar's frames)
#   background.gd     the painted nebula layers plus the per-frame animation and rare events
#   enemy_seed.gd     star seeds: embers that grow into young stars, then flare stars, then go nova
#   enemy_jelly.gd    cosmic jellies: ride a gas current and pulse out motes that hang, then flow
#   enemy_wraith.gd   dust wraiths: gather out of the dust, lunge, and leave a wake of dust motes
#   boss.gd           PROTOSTAR GUARDIAN SOLENNE's attack patterns

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Seed = preload("enemy_seed.gd")
const Jelly = preload("enemy_jelly.gd")
const Wraith = preload("enemy_wraith.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "nursery"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "STAR NURSERY",
		"subtitle": "CRADLE OF NEWBORN SUNS",
		"boss_name": "PROTOSTAR GUARDIAN SOLENNE",
		"sky_top": Color("#08041a"),
		"sky_mid": Color("#0c0622"),
		"sky_bot": Color("#100a1e"),
		"deck_fill": Color("#140c26"),
		"deck_line": Color("#e85cc8"),
		"accent": Color("#ffc8f0"),
		"has_ceiling": false,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_pink",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(64.0, 120.0),
		"boss_x": 404.0,
	}


# Stage 26 on the shared curve (k = 18). "hp" is StageData.stage_hp_growth(25): 1.34^7 x 1.12^18.
func get_difficulty_row() -> Dictionary:
	return {"hp": 59.66, "shot_speed": 1.436, "fire_rate": 1.71, "groups": 19, "pace": 0.638, "themed": 0.844}


func get_boss_hp() -> float:
	return 44000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"seed": {"hp": 7.0, "score": 380, "scrap": 2, "xp": 7, "r": 5.5, "tex": ID + "_seed_0", "behaviour": Seed},
		"jelly": {"hp": 19.0, "score": 520, "scrap": 3, "xp": 10, "r": 10.0, "col_offset": Vector2(0.0, -3.0), "tex": ID + "_jelly_0", "behaviour": Jelly, "big": true},
		"wraith": {"hp": 11.0, "score": 440, "scrap": 2, "xp": 8, "r": 7.5, "tex": ID + "_wraith_0", "behaviour": Wraith},
	}


# A: a cluster of star seeds with two generic scouts. B: two jellies riding one current, a
# dust wraith gathering behind them (and, in every other group of the first two waves, a
# generic sniper). C: a seed bloom round a jelly, wraiths from both sides.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var cy: float = randf_range(90.0, 180.0)
			var sq: int = w.new_squad(3)
			for k: int in range(3):
				var off: Vector2 = Vector2(float(k % 2) * 26.0, (float(k) - 1.0) * 34.0)
				w.spawn("seed", w.t + float(k) * 0.35, Vector2(504.0, cy) + off, float(k) * 1.3, sq)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.0, Vector2(504.0, 62.0))
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.3, Vector2(504.0, 210.0), 1.0)
			return 3.0
		1:
			var y: float = randf_range(80.0, 190.0)
			var ph: float = randf() * TAU
			w.spawn("jelly", w.t, Vector2(516.0, y), ph, -1, 0)
			w.spawn("jelly", w.t + 1.6, Vector2(516.0, y), ph, -1, 0)
			w.spawn("wraith", w.t + 1.0, Vector2(516.0, 270.0 - y), 0.0, -1, 0 if w.top else 1)
			if w.extra == 0 and (w.idx / 2) % 2 == 0:
				w.spawn_generic(GameEnemy.Type.SNIPER, w.t + 1.8, Vector2(504.0, y), 0.0)
			return 3.3
		_:
			var cy2: float = randf_range(100.0, 170.0)
			w.spawn("jelly", w.t + 0.4, Vector2(516.0, cy2), randf() * TAU, -1, 1)
			for k2: int in range(2):
				var a: float = PI * float(k2) + 0.5
				w.spawn("seed", w.t + float(k2) * 0.3, Vector2(510.0, cy2) + Vector2(cos(a) * 18.0, sin(a) * 46.0), float(k2))
			w.spawn("wraith", w.t + 1.4, Vector2(516.0, 80.0), 0.0, -1, 0)
			w.spawn("wraith", w.t + 1.9, Vector2(516.0, 190.0), 1.0, -1, 1)
			return 3.7


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Euphoric trance in A Lydian at 138 BPM: a pumping saw bass under a warm analog pad, an
# ice-bell arpeggio sparkling on the off-beats, and a glass-bell lead ringing out over the top
# with a long, wide echo (newborn stars blinking awake).
func get_song() -> Dictionary:
	return {
		"seed": 2626, "style": 7, "root": 45, "bpm": 138.0, "scale": Music.LYDIAN,
		"bass": 7, "pad": 12, "arp": 4, "lead": 4, "kit": "hard",
		"energy": 2, "bass_gain": 1.6, "kick_gain": 1.45, "sub_mix": 0.5,
		"lead_attack": 120.0, "lead_decay": 1.3, "density": 1, "mel_lo": 1, "mel_hi": 9, "lift": 3,
		"voicing": [0, 2, 4, 6],
		"delay_beats": 0.75, "delay_fb": 0.4, "delay_wet": 0.32,
		"prog_a": [0, 1, -2, 4, 0, 1, 5, 4],
		"prog_b": [3, 4, 5, 1, 3, 4, 1, 1],
	}


# The nebula without the drums, for the soundtrack picker: slow ambient pads and harp.
func get_song_alternatives() -> Array:
	return [
		{"name": "PILLARS OF LIGHT", "info": "AMBIENT  88 BPM  D LYDIAN", "seed": 2627,
			"style": 13, "gv": 1, "root": 38, "bpm": 88.0, "scale": Music.LYDIAN,
			"bass": 3, "bass_decay": 0.9, "pad": 12, "arp": 2, "lead": 6,
			"lead_attack": 24.0, "lead_decay": 0.9, "density": 0, "mel_lo": 2, "mel_hi": 10,
			"delay_beats": 1.0, "delay_fb": 0.48, "delay_wet": 0.42,
			"prog_a": [0, 1, 0, 1, 5, 4, 1, 1], "prog_b": [3, 1, 4, 0, 3, 5, 1, 1]},
	]
