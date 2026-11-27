extends "res://scripts/stages/stage_module.gd"

# STAGE 24: JADE TEMPLE. Alien ruins of weathered gold and carved jade at dusk: colossal seated
# statues with glowing eye slits, waterfalls pouring off the terraces, a colonnade of glyph
# panels that pulse in sequence, hanging vines and flickering braziers.
#
# Files in this folder:
#   stage.gd            stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              every sprite (enemies, shots, generic re-skins, the idol's frames)
#   background.gd       the painted ruin layers plus the per-frame animation
#   enemy_guardian.gd   floating statue heads: armoured until their eyes open to fire twin beams
#   enemy_glyph.gd      rune stones that take up a sigil formation and hurl its outline at you
#   enemy_chakram.gd    golden discs thrown on a boomerang arc, leaving shots hanging in the air
#   boss.gd             GOD-MACHINE ITZAMAT's attack patterns

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Guardian = preload("enemy_guardian.gd")
const Glyph = preload("enemy_glyph.gd")
const Chakram = preload("enemy_chakram.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "temple"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "JADE TEMPLE",
		"subtitle": "RUINS OF THE FIRST SUN",
		"boss_name": "GOD-MACHINE ITZAMAT",
		"sky_top": Color("#050f0d"),
		"sky_mid": Color("#0a1c18"),
		"sky_bot": Color("#122a22"),
		"deck_fill": Color("#1a1c14"),
		"deck_line": Color("#c89a30"),
		"accent": Color("#5ce0a0"),
		"has_ceiling": false,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_orange",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(84.0, 140.0),
		"boss_x": 396.0,
	}


# Stage 24 on the shared curve (k = 16). "hp" is StageData.stage_hp_growth(23): 1.34^7 x 1.12^16.
func get_difficulty_row() -> Dictionary:
	return {"hp": 47.56, "shot_speed": 1.412, "fire_rate": 1.67, "groups": 18, "pace": 0.656, "themed": 0.828}


func get_boss_hp() -> float:
	return 41000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"guardian": {"hp": 22.0, "score": 520, "scrap": 3, "xp": 10, "r": 12.5, "tex": ID + "_guard_0", "behaviour": Guardian, "big": true},
		"glyph": {"hp": 6.0, "score": 210, "scrap": 1, "xp": 4, "r": 6.5, "tex": ID + "_glyph_0", "behaviour": Glyph},
		"chakram": {"hp": 9.0, "score": 300, "scrap": 2, "xp": 6, "r": 8.0, "tex": ID + "_chakram_0", "behaviour": Chakram},
	}


# A: a sigil of rune stones (triangle, or a diamond in later waves) and a chakram thrown past
# it. B: a guardian head high or low with two chakrams. C: a five-stone ring sigil (squad
# bonus) with a guardian and a chakram behind it (and two
# generic scouts in the third wave).
# Glyph spawns share a squad id (that's how the stones find their sigil); "variant" is the
# shape and "phase" the stone's slot. They enter at the sigil's height and fly to their slots.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var shape: int = 0 if w.sub_wave == 1 else 1
			var n: int = Glyph.shape_size(shape)
			var c: Vector2 = Vector2(512.0, 92.0 if w.top else 176.0)
			var sq: int = w.new_squad(n)
			for k: int in range(n):
				w.spawn("glyph", w.t + float(k) * 0.22, c, float(k), sq, shape)
			w.spawn("chakram", w.t + 0.9, Vector2(512.0, 270.0 - c.y), 0.0, -1, 0 if w.top else 1)
			return 3.2
		1:
			var gy: float = 78.0 if w.top else 190.0
			w.spawn("guardian", w.t, Vector2(512.0, gy), 0.0, -1, 0)
			w.spawn("chakram", w.t + 0.7, Vector2(512.0, 270.0 - gy), 0.0, -1, 1 if w.top else 0)
			w.spawn("chakram", w.t + 1.9, Vector2(512.0, 135.0), 0.0, -1, 0 if w.top else 1)
			return 3.5
		_:
			var n2: int = Glyph.shape_size(2)
			var c2: Vector2 = Vector2(512.0, 134.0)
			var sq2: int = w.new_squad(n2)
			for k2: int in range(n2):
				w.spawn("glyph", w.t + float(k2) * 0.18, c2, float(k2), sq2, 2)
			w.spawn("guardian", w.t + 1.3, Vector2(512.0, 70.0 if w.top else 200.0), 0.0, -1, 0)
			w.spawn("chakram", w.t + 2.0, Vector2(512.0, 200.0 if w.top else 70.0), 0.0, -1, 0 if w.top else 1)
			if w.extra > 0:
				w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 2.4, Vector2(504.0, 120.0))
				w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 2.7, Vector2(504.0, 150.0))
			return 3.8


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# A dusk ritual in A minor on the tribal shuffle groove at 116 BPM: upright bass walking under a
# choir pad, a cascading harp, a taiko-tuned orchestral kit and a breathy whistle lead with a
# long stone-hall echo.
func get_song() -> Dictionary:
	return {
		"seed": 2424, "style": 3, "root": 45, "bpm": 116.0, "scale": Music.MINOR,
		"bass": 14, "pad": 2, "arp": 2, "lead": 13, "kit": "orch",
		"energy": 2, "bass_gain": 1.6, "kick_gain": 1.5, "sub_mix": 0.45,
		"lead_attack": 40.0, "lead_decay": 1.1, "vib": 0.006, "harm_int": -3,
		"density": 1, "mel_lo": 0, "mel_hi": 9, "lift": 3,
		"delay_beats": 0.75, "delay_fb": 0.42, "delay_wet": 0.32,
		"prog_a": [0, 0, -2, -1, 0, 0, 3, -1],
		"prog_b": [-2, -1, 0, 0, -2, -1, 4, 4],
	}


func get_song_alternatives() -> Array:
	return [
		{"name": "SUNKEN SANCTUM", "info": "AMBIENT  92 BPM  D DORIAN", "seed": 2425,
			"style": 13, "gv": 1, "root": 38, "bpm": 92.0, "scale": Music.DORIAN,
			"bass": 3, "pad": 12, "arp": 2, "lead": 4, "energy": 1,
			"lead_attack": 30.0, "lead_decay": 0.9, "density": 0, "mel_lo": 2, "mel_hi": 10,
			"delay_beats": 1.0, "delay_fb": 0.45, "delay_wet": 0.38,
			"prog_a": [0, 3, 0, 3, -2, 1, 4, 4], "prog_b": [3, 4, 0, -2, 3, 1, 4, 4]},
	]
