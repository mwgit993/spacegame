extends Node

const WAVES_PER_STAGE: int = 4

# Per-stage difficulty curve, one row per stage. Regular enemies read it through
# get_difficulty(); bosses keep their own numbers (GameEnemy.STAGE_BOSS_HP and _boss_attack).
#   hp          enemy HP multiplier (later waves of a stage add +16% per wave on top)
#   shot_speed  multiplier on every regular enemy's bullet speed
#   fire_rate   multiplier on how often regular enemies fire (their cooldowns are divided by it)
#   groups      spawn groups in the stage's first wave (+1 for each later wave)
#   pace        multiplier on the gap between groups (lower = more enemies on screen at once)
#   themed      share of groups built from the stage's own enemies (the rest are generic fodder)
# Stage 1 is the baseline (all 1.0), so it plays exactly like before the themed enemies.
const DIFFICULTY: Array[Dictionary] = [
	{"hp": 1.00, "shot_speed": 1.00, "fire_rate": 1.00, "groups": 10, "pace": 1.00, "themed": 0.40},
	{"hp": 1.34, "shot_speed": 1.03, "fire_rate": 1.05, "groups": 10, "pace": 0.97, "themed": 0.50},
	{"hp": 1.80, "shot_speed": 1.06, "fire_rate": 1.10, "groups": 11, "pace": 0.94, "themed": 0.55},
	{"hp": 2.41, "shot_speed": 1.09, "fire_rate": 1.15, "groups": 11, "pace": 0.91, "themed": 0.60},
	{"hp": 3.22, "shot_speed": 1.12, "fire_rate": 1.20, "groups": 12, "pace": 0.88, "themed": 0.60},
	{"hp": 4.32, "shot_speed": 1.15, "fire_rate": 1.25, "groups": 12, "pace": 0.85, "themed": 0.65},
	{"hp": 5.79, "shot_speed": 1.18, "fire_rate": 1.30, "groups": 13, "pace": 0.82, "themed": 0.65},
	{"hp": 7.76, "shot_speed": 1.22, "fire_rate": 1.35, "groups": 13, "pace": 0.80, "themed": 0.70},
]
# Each loop after stage 8 multiplies HP by this on top of the stage's row (GameEnemy also applies
# its own 2.2x per loop), and nudges bullet speed and fire rate up from the stage-8 values.
const LOOP_HP_STEP: float = 10.4

const STAGES: Array[Dictionary] = [
	{
		"id": "space",
		"num": 1,
		"name": "OUTER ORBIT",
		"subtitle": "DEEP SPACE PERIMETER",
		"boss_name": "NEMESIS DREADNOUGHT WALL",
		"sky_top": Color("#050614"),
		"sky_mid": Color("#090d26"),
		"sky_bot": Color("#10173d"),
		"deck_fill": Color("#141f3f"),
		"deck_line": Color("#3b68bd"),
		"accent": Color("#28e8ff"),
		"has_ceiling": false,
		"scout_tex": "scout_space",
		"swooper_tex": "swooper_space",
		"sniper_tex": "sniper_space",
		"cruiser_tex": "cruiser_space",
		"boss_tex": "boss_space",
		"bullet_a": "bullet_enemy_pink",
		"bullet_b": "bullet_enemy_orange",
	},
	{
		"id": "starcruiser",
		"num": 2,
		"name": "STARCRUISER",
		"subtitle": "REACTOR CORRIDOR",
		"boss_name": "MECHA SCORPION: SCORPIO-REX",
		"sky_top": Color("#0a0d16"),
		"sky_mid": Color("#121826"),
		"sky_bot": Color("#182133"),
		"deck_fill": Color("#232c3d"),
		"deck_line": Color("#ff9624"),
		"accent": Color("#ffaa38"),
		"has_ceiling": true,
		"scout_tex": "scout_mech",
		"swooper_tex": "swooper_mech",
		"sniper_tex": "sniper_mech",
		"cruiser_tex": "cruiser_mech",
		"boss_tex": "boss_mech",
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": "bullet_enemy_orange",
	},
	{
		"id": "planet_base",
		"num": 3,
		"name": "CLOUD BASE",
		"subtitle": "PLANETARY DESCENT",
		"boss_name": "SKY SERPENT: VALKYRIE WYVERN",
		"sky_top": Color("#0d1c42"),
		"sky_mid": Color("#1d447a"),
		"sky_bot": Color("#3c78a8"),
		"deck_fill": Color("#1e2d48"),
		"deck_line": Color("#7ce8ff"),
		"accent": Color("#7ce8ff"),
		"has_ceiling": false,
		"scout_tex": "scout_aero",
		"swooper_tex": "swooper_aero",
		"sniper_tex": "sniper_aero",
		"cruiser_tex": "cruiser_aero",
		"boss_tex": "boss_aero",
		"bullet_a": "bullet_enemy_orange",
		"bullet_b": "bullet_enemy_pink",
	},
	{
		"id": "forest",
		"num": 4,
		"name": "XENO FOREST",
		"subtitle": "BIOLUMINESCENT CANOPY",
		"boss_name": "EMPEROR STAG-MANTIS",
		"sky_top": Color("#061612"),
		"sky_mid": Color("#0c281e"),
		"sky_bot": Color("#143d29"),
		"deck_fill": Color("#133320"),
		"deck_line": Color("#3ce878"),
		"accent": Color("#5eff94"),
		"has_ceiling": true,
		"scout_tex": "scout_bio",
		"swooper_tex": "swooper_bio",
		"sniper_tex": "sniper_bio",
		"cruiser_tex": "cruiser_bio",
		"boss_tex": "boss_bio",
		"bullet_a": "bullet_enemy_lime",
		"bullet_b": "bullet_enemy_pink",
	},
	{
		"id": "ice",
		"num": 5,
		"name": "CRYO GLACIER",
		"subtitle": "FROZEN CITADEL",
		"boss_name": "FROST SERAPH TITAN",
		"sky_top": Color("#08142b"),
		"sky_mid": Color("#122b52"),
		"sky_bot": Color("#214c7d"),
		"deck_fill": Color("#2a5b8c"),
		"deck_line": Color("#aef4ff"),
		"accent": Color("#88eeff"),
		"has_ceiling": true,
		"scout_tex": "scout_ice",
		"swooper_tex": "swooper_ice",
		"sniper_tex": "sniper_ice",
		"cruiser_tex": "cruiser_ice",
		"boss_tex": "boss_ice",
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": "bullet_enemy_pink",
	},
	{
		"id": "volcano",
		"num": 6,
		"name": "MAGMA CORE",
		"subtitle": "VOLCANIC CALDERA",
		"boss_name": "INFERNO SKULL: BALROG",
		"sky_top": Color("#180608"),
		"sky_mid": Color("#2e0c0e"),
		"sky_bot": Color("#4d1612"),
		"deck_fill": Color("#d94814"),
		"deck_line": Color("#ffe854"),
		"accent": Color("#ff7830"),
		"has_ceiling": true,
		"scout_tex": "scout_fire",
		"swooper_tex": "swooper_fire",
		"sniper_tex": "sniper_fire",
		"cruiser_tex": "cruiser_fire",
		"boss_tex": "boss_fire",
		"bullet_a": "bullet_enemy_orange",
		"bullet_b": "bullet_enemy_pink",
	},
	{
		"id": "abyss",
		"num": 7,
		"name": "ABYSSAL TRENCH",
		"subtitle": "SUNKEN MEGALOPOLIS",
		"boss_name": "ABYSSAL KRAKEN: CHARYBDIS",
		"sky_top": Color("#041222"),
		"sky_mid": Color("#08243d"),
		"sky_bot": Color("#0e3858"),
		"deck_fill": Color("#0d283d"),
		"deck_line": Color("#28d8c8"),
		"accent": Color("#38f0d8"),
		"has_ceiling": false,
		"scout_tex": "scout_abyss",
		"swooper_tex": "swooper_abyss",
		"sniper_tex": "sniper_abyss",
		"cruiser_tex": "cruiser_abyss",
		"boss_tex": "boss_abyss",
		"bullet_a": "bullet_enemy_cyan",
		"bullet_b": "bullet_enemy_lime",
	},
	{
		"id": "cyber",
		"num": 8,
		"name": "CYBER NEXUS",
		"subtitle": "OMEGA MAINFRAME",
		"boss_name": "NEON MEDUSA OVERMIND",
		"sky_top": Color("#0d041c"),
		"sky_mid": Color("#190833"),
		"sky_bot": Color("#260c4a"),
		"deck_fill": Color("#1b0936"),
		"deck_line": Color("#ff38b8"),
		"accent": Color("#ff4cd4"),
		"has_ceiling": true,
		"scout_tex": "scout_cyber",
		"swooper_tex": "swooper_cyber",
		"sniper_tex": "sniper_cyber",
		"cruiser_tex": "cruiser_cyber",
		"boss_tex": "boss_cyber",
		"bullet_a": "bullet_enemy_pink",
		"bullet_b": "bullet_enemy_cyan",
	},
]


func get_stage(stage_idx: int) -> Dictionary:
	var wrapped: int = posmod(stage_idx, STAGES.size())
	return STAGES[wrapped]


# The DIFFICULTY row for a stage index (which keeps counting past 8 when the game loops).
func get_difficulty(stage_idx: int) -> Dictionary:
	var k: int = posmod(stage_idx, STAGES.size())
	var loop: int = maxi(0, stage_idx / STAGES.size())
	var row: Dictionary = DIFFICULTY[k].duplicate()
	if loop > 0:
		var last: Dictionary = DIFFICULTY[DIFFICULTY.size() - 1]
		row["hp"] = float(row["hp"]) * pow(LOOP_HP_STEP, float(loop))
		row["shot_speed"] = minf(1.40, maxf(float(row["shot_speed"]), float(last["shot_speed"])) + 0.04 * float(loop))
		row["fire_rate"] = minf(1.70, maxf(float(row["fire_rate"]), float(last["fire_rate"])) + 0.08 * float(loop))
		row["pace"] = minf(float(row["pace"]), float(last["pace"]))
		row["groups"] = maxi(int(row["groups"]), int(last["groups"]))
	return row


func get_stage_index_for_wave(wave_num: int) -> int:
	return maxi(0, (wave_num - 1) / WAVES_PER_STAGE)


func get_wave_in_stage(wave_num: int) -> int:
	return ((maxi(1, wave_num) - 1) % WAVES_PER_STAGE) + 1


func is_boss_wave(wave_num: int) -> bool:
	return get_wave_in_stage(wave_num) == WAVES_PER_STAGE
