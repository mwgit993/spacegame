extends "res://scripts/stages/stage_module.gd"

# STAGE 22: HOLO ARENA. A gladiator stadium in space under an energy dome: tiered stands packed
# with a cheering holographic crowd, a centre-hung scoreboard, sweeping spotlights, hologram
# banners and laser barriers strung along the arena wall.
#
# Files in this folder:
#   stage.gd            this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd              enemy, shot and boss sprites
#   background.gd       the painted layers plus the per-frame animation
#   pixfont.gd          a 3x5 pixel font for the scoreboard and the bots' "ROUND" call
#   enemy_gladiator.gd  shield-and-blade duelists that take turns lunging along a marked line
#   enemy_bot.gd        combat bots that warp in for a round and fire together on the beat
#   enemy_turret.gd     floor/ceiling emitters that pop up and raise laser-barrier walls
#   boss.gd             GRAND CHAMPION AUREUS: trident thrusts, a thrown net, shield barriers

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Gladiator = preload("enemy_gladiator.gd")
const Bot = preload("enemy_bot.gd")
const Turret = preload("enemy_turret.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "arena"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "HOLO ARENA",
		"subtitle": "GLADIATORS OF THE VOID",
		"boss_name": "GRAND CHAMPION AUREUS",
		"sky_top": Color("#05060f"),
		"sky_mid": Color("#090a20"),
		"sky_bot": Color("#0d0c2a"),
		"deck_fill": Color("#120a24"),
		"deck_line": Color("#e040c0"),
		"accent": Color("#ffc840"),
		"has_ceiling": true,
		"scout_tex": "scout_mech",
		"swooper_tex": "swooper_mech",
		"sniper_tex": "sniper_mech",
		"cruiser_tex": "cruiser_mech",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_pink",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(90.0, 138.0),
		"boss_x": 404.0,
	}


# Stage 22 of the shared 9-28 curve (k = 14). "hp" is the actual growth past stage 8
# (StageData.stage_hp_growth: 1.34^7 x 1.12^k).
func get_difficulty_row() -> Dictionary:
	return {"hp": 37.92, "shot_speed": 1.388, "fire_rate": 1.63, "groups": 17, "pace": 0.674, "themed": 0.812}


func get_boss_hp() -> float:
	return 38500.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"gladiator": {"hp": 18.0, "score": 620, "scrap": 4, "xp": 12, "r": 10.0, "tex": ID + "_gladiator_0", "behaviour": Gladiator, "exit_left": -50.0},
		"bot": {"hp": 7.0, "score": 220, "scrap": 1, "xp": 4, "r": 7.5, "tex": ID + "_bot_0", "behaviour": Bot},
		"turret": {"hp": 11.0, "score": 380, "scrap": 2, "xp": 7, "r": 8.0, "tex": ID + "_turret_0", "behaviour": Turret},
	}


# A (DUEL): a pair of gladiators taking turns, high and low, with a generic swooper and sniper;
#    wave 3 adds two more swoopers.
# B (ROUND): a squad of combat bots warps in as one formation (its leader calls the round
#    number), with generic scouts; wave 3 adds a bot and a generic sniper.
# C (HAZARD, from wave 2): a floor and a ceiling turret raise barrier walls with a shared gap,
#    while bots warp in and a generic swooper heads for the gap; wave 3 adds two generic scouts.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var ya: float = 84.0 if w.top else 186.0
			w.spawn("gladiator", w.t, Vector2(514.0, ya), 0.0, -1, 0)
			w.spawn("gladiator", w.t + 0.5, Vector2(514.0, 270.0 - ya), 1.7, -1, 1)
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 1.2, Vector2(504.0, 135.0))
			w.spawn_generic(GameEnemy.Type.SNIPER, w.t + 2.0, Vector2(504.0, 135.0 + (40.0 if w.top else -40.0)))
			if w.extra > 0:
				w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 2.4, Vector2(504.0, 70.0))
				w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 2.7, Vector2(504.0, 200.0), 1.0)
			return 4.4
		1:
			var n: int = 4 + w.extra
			var sq: int = w.new_squad(n)
			var rows: int = n / 2
			var cy: float = randf_range(100.0, 170.0)
			for k: int in range(n):
				var col: int = k / rows
				var row: int = k % rows
				var y: float = cy + (float(row) - float(rows - 1) * 0.5) * 30.0
				var x: float = 404.0 + float(col) * 30.0 + float(row % 2) * 8.0
				w.spawn("bot", w.t + 0.2, Vector2(x, y), float(w.idx + 1), sq, 1 if k == 0 else 0)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 0.6, Vector2(504.0, 64.0))
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 0.9, Vector2(504.0, 206.0), 1.0)
			if w.extra > 0:
				w.spawn_generic(GameEnemy.Type.SNIPER, w.t + 1.4, Vector2(504.0, cy))
			return 3.9
		_:
			var gap: float = randf_range(92.0, 178.0)
			w.spawn("turret", w.t, Vector2(500.0, 249.0), gap, -1, 0)
			w.spawn("turret", w.t, Vector2(500.0, 37.0), gap, -1, 1)
			w.spawn_generic(GameEnemy.Type.SWOOPER, w.t + 0.8, Vector2(504.0, gap))
			var sq2: int = w.new_squad(4)
			var by: float = 92.0 if w.top else 178.0
			for k2: int in range(4):
				w.spawn("bot", w.t + 1.6, Vector2(396.0 + float(k2 / 2) * 28.0 + float(k2 % 2) * 8.0, by + float(k2 % 2) * 26.0 - 13.0), float(w.idx + 1), sq2, 1 if k2 == 0 else 0)
			if w.extra > 0:
				w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.0, Vector2(504.0, 270.0 - by))
				w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.3, Vector2(504.0, 270.0 - by), 1.2)
			return 4.2


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Stadium EDM in E minor: four-on-the-floor kick with claps, a pumping saw bass, gated hypersaw
# chords and a supersaw lead for the crowd to chant along to.
func get_song() -> Dictionary:
	return {
		"seed": 2222, "style": 7, "root": 40, "bpm": 140.0, "scale": Music.MINOR,
		"bass": 7, "pad": 7, "arp": 8, "lead": 7, "kit": "hard",
		"energy": 2, "bass_gain": 1.5, "kick_gain": 1.35,
		"lead_attack": 120.0, "lead_decay": 1.5, "mel_lo": 0, "mel_hi": 9, "lift": 3,
		"delay_beats": 0.75, "delay_fb": 0.32, "delay_wet": 0.24,
		"prog_a": [0, -2, 2, -1, 0, -2, 3, -1],
		"prog_b": [-2, -1, 0, 2, -2, -1, 4, 4],
	}


func get_song_alternatives() -> Array:
	return [
		{"name": "HALFTIME SHOW", "info": "BOSSA NOVA  132 BPM  A DORIAN", "seed": 2223,
			"style": 15, "root": 45, "bpm": 132.0, "scale": Music.DORIAN,
			"bass": 14, "pad": 6, "arp": 12, "lead": 11, "kit": "lofi", "voicing": [0, 2, 4, 6],
			"lead_attack": 60.0, "lead_decay": 1.3, "mel_lo": 0, "mel_hi": 8, "delay_wet": 0.22,
			"prog_a": [0, 3, 1, 4, 0, 3, -1, -1], "prog_b": [2, -1, 0, 3, 2, 5, 4, 4]},
	]
