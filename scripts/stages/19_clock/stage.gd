extends "res://scripts/stages/stage_module.gd"

# STAGE 19: CLOCKWORK. Flying through the works of a giant steampunk fortress: enormous brass
# gears turning on the far walls, ticking clock faces, pipe runs with valves and gauges, pumping
# pistons, steam and amber lamplight.
#
# Files in this folder:
#   stage.gd          this file: stage table entry, difficulty, enemies, wave recipes, song
#   art.gd            enemy, shot and boss sprites
#   background.gd     the painted layers plus the per-frame animation
#   enemy_cog.gd      cog drone: rolls along the floor/ceiling, spins up, hops and fires a ring
#   enemy_boiler.gd   steam cannon: the gauge climbs into the red, then a fused shell bursts
#   enemy_pendulum.gd pendulum blade: a marked arc, then a swinging blade that flings sparks
#   boss.gd           CHRONOS COLOSSUS: hand volleys, tolling bell, pendulum saws

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Cog = preload("enemy_cog.gd")
const Boiler = preload("enemy_boiler.gd")
const Pendulum = preload("enemy_pendulum.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "clock"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "CLOCKWORK",
		"subtitle": "THE BRASS FORTRESS",
		"boss_name": "CHRONOS COLOSSUS",
		"sky_top": Color("#0c0806"),
		"sky_mid": Color("#140d08"),
		"sky_bot": Color("#1c120a"),
		"deck_fill": Color("#2a1c0e"),
		"deck_line": Color("#d8a848"),
		"accent": Color("#e8c060"),
		"has_ceiling": true,
		"scout_tex": "scout_mech",
		"swooper_tex": "swooper_mech",
		"sniper_tex": "sniper_mech",
		"cruiser_tex": "cruiser_mech",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_pink",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(90.0, 140.0),
		"boss_x": 410.0,
	}


# Stage 19 of the shared 9-28 curve (k = 11). "hp" is the actual growth past stage 8
# (StageData.stage_hp_growth: 1.34^7 x 1.12^k).
func get_difficulty_row() -> Dictionary:
	return {"hp": 26.99, "shot_speed": 1.352, "fire_rate": 1.57, "groups": 16, "pace": 0.701, "themed": 0.788}


func get_boss_hp() -> float:
	return 34000.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"cog": {"hp": 5.5, "score": 200, "scrap": 1, "xp": 4, "r": 7.5, "tex": ID + "_cog_0", "behaviour": Cog},
		"boiler": {"hp": 14.0, "score": 420, "scrap": 3, "xp": 9, "box": Vector2(26.0, 18.0), "col_offset": Vector2(1.0, 2.0), "tex": ID + "_boiler_0", "behaviour": Boiler},
		"pendulum": {"hp": 18.0, "score": 480, "scrap": 3, "xp": 9, "r": 9.0, "tex": ID + "_blade_4", "behaviour": Pendulum, "exit_left": -120.0},
	}


# A: a convoy of cog drones rolling along the floor and the ceiling, with generic scouts.
# B: a steam cannon behind a pair of cogs, with a pendulum swinging in on the ceiling.
# C (from wave 2): two pendulums out of step with each other, a steam cannon between them;
#    wave 3 adds a cog squad.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 4 + w.extra
			var sq: int = w.new_squad(n)
			for k: int in range(n):
				var ceil_side: bool = (k % 2 == 0) == w.top
				w.spawn("cog", w.t + float(k) * 0.45, Vector2(506.0, 37.0 if ceil_side else 249.0), float(k), sq, 1 if ceil_side else 0)
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 0.8, Vector2(504.0, 110.0))
			w.spawn_generic(GameEnemy.Type.SCOUT_SINE, w.t + 1.2, Vector2(504.0, 165.0), 1.0)
			return 3.0
		1:
			w.spawn("boiler", w.t, Vector2(510.0, 100.0 if w.top else 170.0))
			w.spawn("cog", w.t + 0.6, Vector2(506.0, 249.0), 0.0, -1, 0)
			w.spawn("cog", w.t + 1.0, Vector2(506.0, 37.0), 1.0, -1, 1)
			w.spawn("pendulum", w.t + 0.4, Vector2(500.0, 120.0), 0.0, -1, 0 if w.top else 1)
			w.spawn_generic(GameEnemy.Type.SNIPER, w.t + 1.6, Vector2(504.0, 135.0))
			return 3.5
		_:
			w.spawn("pendulum", w.t, Vector2(500.0, 120.0), 0.0, -1, 0)
			w.spawn("pendulum", w.t + 1.5, Vector2(500.0, 120.0), 1.0, -1, 1)
			w.spawn("boiler", w.t + 0.8, Vector2(510.0, 135.0 + randf_range(-40.0, 40.0)))
			if w.extra > 0:
				var sq2: int = w.new_squad(3)
				for k2: int in range(3):
					w.spawn("cog", w.t + 1.0 + float(k2) * 0.4, Vector2(506.0, 249.0), float(k2), sq2, 0)
			return 3.8


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# A clockwork waltz in A harmonic minor: FM keyboard bass, drawbar organ, a music-box arpeggio
# and an FM electric piano lead, with the raised 7th giving it its antique, slightly sinister
# turn.
func get_song() -> Dictionary:
	return {
		"seed": 1919, "style": 2, "bar_steps": 12, "root": 45, "bpm": 148.0, "scale": Music.HARMONIC_MINOR,
		"bass": 11, "pad": 11, "arp": 4, "lead": 14, "kit": "orch",
		"energy": 2, "bass_gain": 1.5, "kick_gain": 1.3,
		"lead_attack": 120.0, "lead_decay": 1.5, "mel_lo": 0, "mel_hi": 9, "harm_int": -2,
		"delay_beats": 1.0, "delay_fb": 0.34, "delay_wet": 0.28,
		"prog_a": [0, 3, 4, 0, -2, 3, 4, 4],
		"prog_b": [3, 4, 0, -2, 3, -1, 4, 4],
	}


func get_song_alternatives() -> Array:
	return [
		{"name": "BRASS & STEAM", "info": "SWUNG FUNK  112 BPM  D DORIAN", "seed": 1920,
			"style": 1, "root": 38, "bpm": 112.0, "scale": Music.DORIAN, "swing": 0.12,
			"bass": 1, "pad": 1, "arp": 3, "lead": 11, "kit": "hard",
			"lead_attack": 90.0, "lead_decay": 1.4, "mel_lo": -1, "mel_hi": 7, "delay_wet": 0.22,
			"prog_a": [0, 3, 0, 3, -2, -1, 0, 4], "prog_b": [3, 3, 0, 0, -2, -1, 4, 4]},
	]
