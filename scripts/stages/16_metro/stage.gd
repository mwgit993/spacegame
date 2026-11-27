extends "res://scripts/stages/stage_module.gd"

# STAGE 16: METROPOLIS. A real city at night in the rain (unlike Cyber Nexus, which is inside
# a computer): megatowers on the horizon, giant billboards, sky-lanes of flying traffic, wet
# rooftops and neon signs below.
#
# Files in this folder:
#   stage.gd            stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              every sprite (enemies, shots, generic re-skins, the titan's frames)
#   background.gd       the painted city layers plus the per-frame animation
#   enemy_police.gd     police cruisers sweeping a searchlight; caught in it, you get a burst
#   enemy_billboard.gd  billboard drones that flash a warning screen, then fire a pixel block
#   enemy_biker.gd      hover-bike gangs racing across, some from behind, with drive-by shots
#   boss.gd             CORPORATE TITAN APEX-9's attack patterns

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Police = preload("enemy_police.gd")
const Billboard = preload("enemy_billboard.gd")
const Biker = preload("enemy_biker.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "metro"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "METROPOLIS",
		"subtitle": "NEON SKYWAYS AT MIDNIGHT",
		"boss_name": "CORPORATE TITAN APEX-9",
		"sky_top": Color("#07061a"),
		"sky_mid": Color("#120c2c"),
		"sky_bot": Color("#2a1440"),
		"deck_fill": Color("#141226"),
		"deck_line": Color("#ff3c9c"),
		"accent": Color("#ff5cb0"),
		"has_ceiling": false,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_lime",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(70.0, 140.0),
		"boss_x": 404.0,
	}


# Stage 16 on the shared curve (k = 8). "hp" is StageData.stage_hp_growth(15): 1.34^7 x 1.12^8.
func get_difficulty_row() -> Dictionary:
	return {"hp": 19.21, "shot_speed": 1.316, "fire_rate": 1.51, "groups": 15, "pace": 0.728, "themed": 0.764}


func get_boss_hp() -> float:
	return 29500.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"police": {"hp": 11.0, "score": 400, "scrap": 3, "xp": 8, "r": 8.5, "tex": ID + "_police_0", "behaviour": Police},
		"billboard": {"hp": 15.0, "score": 450, "scrap": 3, "xp": 9, "box": Vector2(28.0, 20.0), "tex": ID + "_board_0", "behaviour": Billboard, "col_offset": Vector2(0.0, -2.0)},
		"biker": {"hp": 4.2, "score": 170, "scrap": 1, "xp": 3, "r": 6.5, "tex": ID + "_biker_0", "behaviour": Biker, "exit_left": -50.0},
	}


# A: a biker gang racing in from the right, with a police cruiser. B: billboards high and low
# and a biker pair coming up from behind. C: a full gang from behind, two cruisers, a billboard.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var lane: float = randf_range(70.0, 200.0)
			var n: int = 3 + w.extra
			var sq: int = w.new_squad(n)
			for k: int in range(n):
				w.spawn("biker", w.t + float(k) * 0.32, Vector2(512.0, clampf(lane + float(k % 2) * 14.0 - 7.0, 44.0, 230.0)), float(k), sq, 0)
			w.spawn("police", w.t + 1.0, Vector2(512.0, 270.0 - lane), 0.0, -1, 0)
			return 2.8
		1:
			w.spawn("billboard", w.t, Vector2(512.0, 74.0), 0.0, -1, 0)
			w.spawn("billboard", w.t + 0.7, Vector2(512.0, 190.0), 0.0, -1, 1)
			var by: float = 135.0 + randf_range(-30.0, 30.0)
			for k2: int in range(2 + w.extra):
				w.spawn("biker", w.t + 1.2 + float(k2) * 0.35, Vector2(-30.0, by + float(k2) * 16.0 - 8.0), float(k2), -1, 1)
			return 3.1
		_:
			var ly: float = 60.0 if w.top else 205.0
			var n2: int = 4 + w.extra
			var sq2: int = w.new_squad(n2)
			for k3: int in range(n2):
				w.spawn("biker", w.t + float(k3) * 0.28, Vector2(-30.0, ly + float(k3 % 2) * 12.0), float(k3), sq2, 1)
			w.spawn("police", w.t + 0.6, Vector2(512.0, 100.0), 0.0, -1, 0)
			w.spawn("police", w.t + 1.1, Vector2(512.0, 170.0), 1.0, -1, 1)
			w.spawn("billboard", w.t + 1.6, Vector2(512.0, 135.0), 0.0, -1, w.idx % 2)
			return 3.6


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Rain-on-neon boom-bap in A Dorian: a swung hip-hop beat with a heavy 808, Rhodes stabs,
# vibraphone and an FM electric-piano lead (the full arrangement layers keep it punchy).
func get_song() -> Dictionary:
	return {
		"seed": 1616, "style": 14, "gv": 1, "root": 45, "bpm": 98.0, "scale": Music.DORIAN, "swing": 0.13,
		"bass": 13, "pad": 6, "arp": 10, "lead": 14, "kit": "808", "voicing": [0, 2, 4, 6],
		"energy": 2, "bass_gain": 1.8, "kick_gain": 1.5, "sub_mix": 0.6,
		"lead_attack": 110.0, "lead_decay": 1.5, "density": 1, "mel_lo": 2, "mel_hi": 10, "lift": 2,
		"delay_beats": 0.75, "delay_fb": 0.38, "delay_wet": 0.3,
		"prog_a": [0, 0, 3, 3, 1, 1, 4, 4],
		"prog_b": [-1, 3, 0, 0, -1, 2, 4, 4],
	}


# The same skyline at full tilt, for the soundtrack picker in Options.
func get_song_alternatives() -> Array:
	return [
		{"name": "SKYWAY RUSH", "info": "LIQUID DRUM & BASS  174 BPM  F DORIAN", "seed": 1617,
			"style": 10, "gv": 1, "root": 41, "bpm": 174.0, "scale": Music.DORIAN,
			"bass": 10, "pad": 6, "arp": 10, "lead": 14, "kit": "dnb", "voicing": [0, 2, 4, 6],
			"energy": 2, "bass_gain": 1.7, "kick_gain": 1.4, "lead_decay": 1.5, "mel_lo": 2, "mel_hi": 10,
			"prog_a": [0, 0, 3, 3, -1, -1, 2, 4], "prog_b": [3, 4, 0, -1, 3, 2, 4, 4]},
	]
