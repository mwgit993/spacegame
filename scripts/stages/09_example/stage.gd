extends "res://scripts/stages/stage_module.gd"

# TEMPORARY EXAMPLE STAGE: a template for stage modules, not a real level.
#
# It isn't listed in scripts/stages/registry.gd, so it never appears in a run; the smoke test
# registers it for the length of its checks to prove the module system end to end. To make a
# real stage, copy this folder to scripts/stages/<NN>_<id>/, change ID (and every "example"
# key prefix) to your stage id, replace the content, and put the path of your stage.gd in its
# slot in registry.gd. See "Adding a stage" in CLAUDE.md.
#
# Files in this folder:
#   stage.gd          this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd            every sprite (enemies, their shot, the boss frames), painted into Images
#   background.gd     the painted still layers plus the per-frame animation
#   enemy_orb.gd      enemy 1: sine-wave drifter that splits in two when shot
#   enemy_lancer.gd   enemy 2: locks on with a laser sight, then dashes across the screen
#   boss.gd           the boss's attack patterns

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Orb = preload("enemy_orb.gd")
const Lancer = preload("enemy_lancer.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "example"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "TEST RANGE",
		"subtitle": "TEMPLATE STAGE",
		"boss_name": "TEMPLATE CORE",
		"sky_top": Color("#0a0a1c"),
		"sky_mid": Color("#141433"),
		"sky_bot": Color("#1f1e4a"),
		"deck_fill": Color("#1b1a3a"),
		"deck_line": Color("#8a7cff"),
		"accent": Color("#a898ff"),
		"has_ceiling": false,
		# The generic enemies can reuse any existing skin, or use sprites from art.gd.
		"scout_tex": "scout_cyber",
		"swooper_tex": "swooper_space",
		"sniper_tex": "sniper_cyber",
		"cruiser_tex": "cruiser_space",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": ID + "_shot",
	}


# Starts from stage 8's row and gets a little harder in every column ("hp" is 1.34^8).
func get_difficulty_row() -> Dictionary:
	return {"hp": 10.40, "shot_speed": 1.24, "fire_rate": 1.38, "groups": 13, "pace": 0.80, "themed": 0.70}


func get_boss_hp() -> float:
	return 23000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"orb": {"hp": 7.0, "score": 260, "scrap": 2, "xp": 6, "r": 7.0, "tex": ID + "_orb_0", "behaviour": Orb},
		"lancer": {"hp": 11.0, "score": 340, "scrap": 2, "xp": 7, "r": 7.5, "tex": ID + "_lancer_0", "behaviour": Lancer},
	}


# Recipes A and B from the first wave, C from the second; w.extra adds a unit in the third.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:  # A: a staggered column of orbs, with a generic scout behind them
			for k: int in range(3 + w.extra):
				w.spawn("orb", w.t + float(k) * 0.5, Vector2(504.0, 70.0 + 50.0 * float(k)), float(k) * 0.9)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.0, Vector2(504.0, 135.0))
			return 3.0
		1:  # B: two lancers, one high and one low (which first alternates per group)
			var y: float = 80.0 if w.top else 190.0
			w.spawn("lancer", w.t, Vector2(510.0, y))
			w.spawn("lancer", w.t + 0.9, Vector2(510.0, 270.0 - y), 0.0, -1, 1)
			if w.extra > 0:
				w.spawn("orb", w.t + 1.4, Vector2(504.0, 135.0))
			return 3.2
		_:  # C: a lancer behind a squad of four orbs (killing all four pays the squad bonus)
			w.spawn("lancer", w.t + 1.2, Vector2(510.0, 135.0))
			var sq: int = w.new_squad(4)
			for k: int in range(4):
				w.spawn("orb", w.t + float(k) * 0.3, Vector2(504.0, 60.0 + 50.0 * float(k)), float(k) * 0.6, sq)
			return 3.6


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Chiptune in E minor; the melodies are composed from the seed (change it for a new tune).
func get_song() -> Dictionary:
	return {
		"seed": 909, "style": 9, "gv": 1, "root": 40, "bpm": 138.0, "scale": Music.MINOR,
		"bass": 9, "pad": 9, "arp": 9, "lead": 9, "kit": "chip",
		"lead_decay": 2.0, "mel_lo": 0, "mel_hi": 8, "delay_wet": 0.18,
		"prog_a": [0, -2, 3, 4, 0, -2, 3, 4],
		"prog_b": [3, 4, 0, -2, 3, 4, 5, 4],
	}


# One alternative for Options > SOUNDTRACK (optional: most stages can return []).
func get_song_alternatives() -> Array:
	return [
		{"name": "RANGE DRILL", "info": "DRUM & BASS  170 BPM  E MINOR", "seed": 919,
			"style": 10, "root": 40, "bpm": 170.0, "scale": Music.MINOR,
			"bass": 10, "pad": 12, "arp": 8, "lead": 10, "kit": "dnb",
			"prog_a": [0, 0, -2, -2, 3, 3, 4, 4], "prog_b": [-2, -1, 0, 0, -2, 3, 4, 4]},
	]
