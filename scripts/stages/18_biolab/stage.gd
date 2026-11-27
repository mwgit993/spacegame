extends "res://scripts/stages/stage_module.gd"

# STAGE 18: MUTANT LAB. A research lab that lost containment: specimen tanks bubbling (some
# smashed and empty), warning beacons turning, vines growing through the machinery, ooze
# pooling on the floor.
#
# Files in this folder:
#   stage.gd             stage table entry, difficulty, enemies, wave recipes, song
#   art.gd               every sprite (enemies, shots, generic re-skins, the Chimera's frames)
#   background.gd        the painted lab layers plus the per-frame animation
#   enemy_specimen.gd    escaped specimens that mutate into nastier forms as they're hurt
#   enemy_launcher.gd    floor and ceiling tanks that lob ooze blobs (capped)
#   enemy_blob.gd        ooze blobs that bounce toward the ship and split when shot (capped)
#   enemy_turret.gd      security turrets gone haywire: twitchy aim, locked bursts, spin sprays
#   boss.gd              SUBJECT ZERO CHIMERA's attack patterns

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Specimen = preload("enemy_specimen.gd")
const Launcher = preload("enemy_launcher.gd")
const Blob = preload("enemy_blob.gd")
const Turret = preload("enemy_turret.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "biolab"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "MUTANT LAB",
		"subtitle": "CONTAINMENT BREACH",
		"boss_name": "SUBJECT ZERO CHIMERA",
		"sky_top": Color("#060c0e"),
		"sky_mid": Color("#0c1618"),
		"sky_bot": Color("#122022"),
		"deck_fill": Color("#1a2426"),
		"deck_line": Color("#e8c030"),
		"accent": Color("#9cff4c"),
		"has_ceiling": true,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_orange",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(80.0, 130.0),
		"boss_x": 406.0,
	}


# Stage 18 on the shared curve (k = 10). "hp" is StageData.stage_hp_growth(17): 1.34^7 x 1.12^10.
func get_difficulty_row() -> Dictionary:
	return {"hp": 24.09, "shot_speed": 1.34, "fire_rate": 1.55, "groups": 16, "pace": 0.71, "themed": 0.78}


func get_boss_hp() -> float:
	return 32500.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"specimen": {"hp": 15.0, "score": 450, "scrap": 3, "xp": 9, "r": 8.0, "tex": ID + "_spec_0", "behaviour": Specimen},
		"launcher": {"hp": 18.0, "score": 480, "scrap": 3, "xp": 9, "box": Vector2(20.0, 22.0), "tex": ID + "_launcher_0", "behaviour": Launcher},
		"blob": {"hp": 4.0, "score": 140, "scrap": 1, "xp": 2, "r": 6.0, "tex": ID + "_blob_0", "behaviour": Blob},
		"turret": {"hp": 13.0, "score": 380, "scrap": 2, "xp": 8, "r": 8.0, "tex": ID + "_turret_0", "behaviour": Turret},
	}


# A: specimens loose in the lab, with a ceiling turret. B: a launcher on the floor and a
# turret on the ceiling (both sides in the third wave), plus a stray blob. C: a specimen pack,
# a launcher and a big blob.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			for k: int in range(2 + w.extra):
				w.spawn("specimen", w.t + float(k) * 0.6, Vector2(512.0, 80.0 + 60.0 * float(k)), float(k))
			w.spawn("turret", w.t + 0.4, Vector2(504.0, 0.0), 0.0, -1, 1)
			return 3.0
		1:
			w.spawn("launcher", w.t, Vector2(504.0, 0.0), 0.0, -1, 0)
			w.spawn("turret", w.t + 0.8, Vector2(504.0, 0.0), 0.0, -1, 1)
			if w.extra > 0:
				w.spawn("launcher", w.t + 1.4, Vector2(504.0, 0.0), 0.0, -1, 1)
				w.spawn("turret", w.t + 1.8, Vector2(504.0, 0.0), 0.0, -1, 0)
			w.spawn("blob", w.t + 1.0, Vector2(512.0, 120.0), 0.0)
			return 3.4
		_:
			var sq: int = w.new_squad(3)
			for k2: int in range(3):
				w.spawn("specimen", w.t + float(k2) * 0.45, Vector2(512.0, 70.0 + 65.0 * float(k2)), float(k2), sq)
			w.spawn("launcher", w.t + 0.9, Vector2(504.0, 0.0), 0.0, -1, w.idx % 2)
			w.spawn("blob", w.t + 1.5, Vector2(512.0, 100.0), 1.0)
			return 3.7


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Mad-lab chiptune in G harmonic minor at a frantic 164 BPM: a creeping walking acid bass,
# clavinet stabs, pulse plucks and a bit-crushed sync-square lead.
func get_song() -> Dictionary:
	return {
		"seed": 1818, "style": 9, "gv": 2, "root": 43, "bpm": 164.0, "scale": Music.HARMONIC_MINOR,
		"bass": 5, "pad": 1, "arp": 8, "lead": 1, "kit": "chip", "crush": 2, "vib": 0.006,
		"energy": 2, "bass_gain": 1.7, "kick_gain": 1.5, "sub_mix": 0.55,
		"lead_attack": 150.0, "lead_decay": 2.4, "harm_int": -7, "density": 2,
		"mel_lo": 0, "mel_hi": 8, "lift": 2,
		"delay_beats": 0.5, "delay_fb": 0.3, "delay_wet": 0.2,
		"prog_a": [0, 0, 3, 4, 0, -2, 3, 4],
		"prog_b": [-2, 3, 0, 4, -2, 3, 4, 4],
	}
