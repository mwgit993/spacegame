extends Node

const WAVES_PER_STAGE: int = 4

# Stages 1-8 are built in: their rows are below and their enemies, bosses, backgrounds and songs
# live in the original code paths. Every stage after them is a stage module (scripts/stages/,
# listed in scripts/stages/registry.gd), appended to `stages` and `difficulty` once loaded.
# Nothing may assume 8 stages: use stage_count(), wrap_stage() and loop_of().
const BUILTIN_STAGES: int = 8
const Registry = preload("res://scripts/stages/registry.gd")
const REQUIRED_STAGE_KEYS: Array[String] = [
	"id", "name", "subtitle", "boss_name", "sky_top", "sky_mid", "sky_bot", "deck_fill", "deck_line",
	"accent", "has_ceiling", "scout_tex", "swooper_tex", "sniper_tex", "cruiser_tex", "boss_tex",
	"bullet_a", "bullet_b",
]
const REQUIRED_DIFFICULTY_KEYS: Array[String] = ["hp", "shot_speed", "fire_rate", "groups", "pace", "themed"]
const REQUIRED_ENEMY_KEYS: Array[String] = ["hp", "score", "scrap", "xp", "tex", "behaviour"]

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
# Each loop after the last stage multiplies HP by this on top of the stage's row (GameEnemy also
# applies its own 2.2x per loop), and nudges bullet speed and fire rate up from the last stage's
# values. With more than 8 stages the step grows with the last row (see loop_hp_step()).
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


# The full stage table: STAGES, then one entry per registered stage module. Same for the
# difficulty rows. Read them through stage_count() / get_stage() / get_difficulty(), which make
# sure the registry's modules are registered first.
var stages: Array[Dictionary] = STAGES.duplicate()
var difficulty: Array[Dictionary] = DIFFICULTY.duplicate()

var _modules: Array[RefCounted] = []        # the module of stage BUILTIN_STAGES + i
var _enemy_defs: Array[Dictionary] = []     # its get_enemy_defs(), cached
var _art_ready: Dictionary = {}             # module id -> true once its sprites are in PixelArt
var _art_task: int = -1                     # worker task building a module's sprites
var _art_task_module: RefCounted = null
var _art_task_result: Dictionary = {}


# Registry modules are compiled on worker threads, so they cost nothing at boot: the loads start
# once the main scene is up, and the modules are registered when they finish (during the title
# screen). Anything that needs a module's tables before then (the smoke test, which runs in
# main._ready) registers them on the spot with _ensure_modules(). Stages 1-8 never wait: the
# fast paths below don't need the module tables.
var _module_paths: Array[String] = []
var _loads_requested: bool = false
var _modules_ready: bool = false


func _ready() -> void:
	for path: String in Registry.MODULES:
		if path != "":
			_module_paths.append(path)
	_modules_ready = _module_paths.is_empty()
	set_process(false)
	if not _modules_ready:
		_request_module_loads.call_deferred()


func _exit_tree() -> void:
	if _art_task != -1:
		WorkerThreadPool.wait_for_task_completion(_art_task)
		_art_task = -1


func _process(_delta: float) -> void:
	if not _modules_ready and _module_loads_finished():
		_ensure_modules()
	if _art_task != -1 and WorkerThreadPool.is_task_completed(_art_task):
		_finish_art_task()
	if _modules_ready and _art_task == -1:
		set_process(false)


func _request_module_loads() -> void:
	if _modules_ready:
		return
	_loads_requested = true
	for path: String in _module_paths:
		ResourceLoader.load_threaded_request(path)
	set_process(true)


func _module_loads_finished() -> bool:
	if not _loads_requested:
		return false
	for path: String in _module_paths:
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return false
	return true


# Registers every module in the registry, in order (waiting for any load still in progress).
func _ensure_modules() -> void:
	if _modules_ready:
		return
	_modules_ready = true
	for path: String in _module_paths:
		var scr: Script = null
		if _loads_requested:
			scr = ResourceLoader.load_threaded_get(path) as Script
		else:
			scr = load(path) as Script
		var m: RefCounted = _instance_module(scr, path)
		if m != null:
			register_module(m)


func stage_count() -> int:
	_ensure_modules()
	return stages.size()


# The stage a (possibly looped) stage index plays: 0 .. stage_count() - 1.
func wrap_stage(stage_idx: int) -> int:
	if stage_idx >= 0 and stage_idx < BUILTIN_STAGES:
		return stage_idx
	return posmod(stage_idx, stage_count())


# How many times play has looped back to stage 1 by this stage index.
func loop_of(stage_idx: int) -> int:
	if stage_idx < BUILTIN_STAGES:
		return 0
	return stage_idx / stage_count()


func get_stage(stage_idx: int) -> Dictionary:
	return stages[wrap_stage(stage_idx)]


# The DIFFICULTY row for a stage index (which keeps counting past the last stage when the game
# loops).
func get_difficulty(stage_idx: int) -> Dictionary:
	var k: int = wrap_stage(stage_idx)
	var loop: int = loop_of(stage_idx)
	var row: Dictionary = difficulty[k].duplicate()
	if loop > 0:
		var last: Dictionary = difficulty[difficulty.size() - 1]
		row["hp"] = float(row["hp"]) * pow(loop_hp_step(), float(loop))
		# Caps keep looped play sane, but never below the last stage's own values (with 28 stages
		# the last rows already pass the old fixed 1.40 / 1.70 caps).
		var shot_cap: float = maxf(1.40, float(last["shot_speed"]) + 0.12)
		var fire_cap: float = maxf(1.70, float(last["fire_rate"]) + 0.24)
		row["shot_speed"] = minf(shot_cap, maxf(float(row["shot_speed"]), float(last["shot_speed"])) + 0.04 * float(loop))
		row["fire_rate"] = minf(fire_cap, maxf(float(row["fire_rate"]), float(last["fire_rate"])) + 0.08 * float(loop))
		row["pace"] = minf(float(row["pace"]), float(last["pace"]))
		row["groups"] = maxi(int(row["groups"]), int(last["groups"]))
	return row


# The documented HP step from the last stage back to stage 1 of the next loop: 10.4 with the 8
# built-in stages, one more 1.34x stage step past the last row when there are more.
func loop_hp_step() -> float:
	return maxf(LOOP_HP_STEP, float(difficulty[difficulty.size() - 1]["hp"]) * 1.34)


func get_stage_index_for_wave(wave_num: int) -> int:
	return maxi(0, (wave_num - 1) / WAVES_PER_STAGE)


func get_wave_in_stage(wave_num: int) -> int:
	return ((maxi(1, wave_num) - 1) % WAVES_PER_STAGE) + 1


func is_boss_wave(wave_num: int) -> bool:
	return get_wave_in_stage(wave_num) == WAVES_PER_STAGE


# ---------------------------------------------------------------------------------------------
# Stage modules (stages 9+). See scripts/stages/stage_module.gd.
# ---------------------------------------------------------------------------------------------

func is_module_stage(stage_idx: int) -> bool:
	return wrap_stage(stage_idx) >= BUILTIN_STAGES


# The module that plays this (possibly looped) stage index, or null for stages 1-8.
func get_module(stage_idx: int) -> RefCounted:
	var k: int = wrap_stage(stage_idx) - BUILTIN_STAGES
	if k < 0:
		return null
	return _modules[k]


func get_module_by_id(id: String) -> RefCounted:
	_ensure_modules()
	for i: int in range(_modules.size()):
		if String(stages[BUILTIN_STAGES + i]["id"]) == id:
			return _modules[i]
	return null


func get_modules() -> Array[RefCounted]:
	_ensure_modules()
	return _modules.duplicate()


# One of a module stage's enemy definitions (see stage_module.gd get_enemy_defs()).
func get_enemy_def(stage_idx: int, kind: String) -> Dictionary:
	var k: int = wrap_stage(stage_idx) - BUILTIN_STAGES
	if k < 0:
		return {}
	return _enemy_defs[k].get(kind, {})


# Loads a module that isn't in the registry (the smoke test's example). Register it with
# register_module().
func load_module(path: String) -> RefCounted:
	return _instance_module(load(path) as Script, path)


func _instance_module(scr: Script, path: String) -> RefCounted:
	if scr == null:
		push_error("StageData: can't load stage module " + path)
		return null
	var m: RefCounted = scr.new() as RefCounted
	if m == null or not m.has_method("get_stage_def"):
		push_error("StageData: %s doesn't extend scripts/stages/stage_module.gd" % path)
		return null
	return m


# Everything wrong with a module's tables (an empty list means it can be registered).
func validate_module(m: RefCounted) -> PackedStringArray:
	var errs: PackedStringArray = PackedStringArray()
	var def: Dictionary = m.call("get_stage_def")
	var id: String = String(def.get("id", ""))
	for key: String in REQUIRED_STAGE_KEYS:
		if not def.has(key):
			errs.append("stage '%s' has no \"%s\"" % [id, key])
	if id == "":
		return errs
	for st: Dictionary in stages:
		if String(st["id"]) == id and get_module_by_id(id) != m:
			errs.append("stage id '%s' is already used" % id)
	var row: Dictionary = m.call("get_difficulty_row")
	for key2: String in REQUIRED_DIFFICULTY_KEYS:
		if not row.has(key2):
			errs.append("stage '%s' difficulty row has no \"%s\"" % [id, key2])
	if float(m.call("get_boss_hp")) <= 0.0:
		errs.append("stage '%s' has no boss HP" % id)
	if m.call("create_boss") == null:
		errs.append("stage '%s' has no boss (create_boss)" % id)
	if m.call("create_background") == null:
		errs.append("stage '%s' has no background (create_background)" % id)
	if (m.call("get_song") as Dictionary).is_empty():
		errs.append("stage '%s' has no song" % id)
	var defs: Dictionary = m.call("get_enemy_defs")
	if defs.is_empty():
		errs.append("stage '%s' has no enemies" % id)
	for kind: Variant in defs.keys():
		var e_def: Dictionary = defs[kind]
		for key3: String in REQUIRED_ENEMY_KEYS:
			if not e_def.has(key3):
				errs.append("stage '%s' enemy '%s' has no \"%s\"" % [id, String(kind), key3])
		if not e_def.has("r") and not e_def.has("box"):
			errs.append("stage '%s' enemy '%s' needs \"r\" or \"box\"" % [id, String(kind)])
	return errs


# Appends a module as the next stage (after the registry's). Returns its stage index, or -1 if
# its tables are broken.
func register_module(m: RefCounted) -> int:
	_ensure_modules()
	var errs: PackedStringArray = validate_module(m)
	if not errs.is_empty():
		for e: String in errs:
			push_error("StageData: " + e)
		return -1
	var def: Dictionary = (m.call("get_stage_def") as Dictionary).duplicate()
	var idx: int = stages.size()
	def["num"] = idx + 1
	stages.append(def)
	difficulty.append((m.call("get_difficulty_row") as Dictionary).duplicate())
	_modules.append(m)
	_enemy_defs.append(m.call("get_enemy_defs"))
	m.set("stage_index", idx)
	return idx


# Removes a registered module (the smoke test uses this for the example). Later stages move up.
func unregister_module(m: RefCounted) -> void:
	_ensure_modules()
	var k: int = _modules.find(m)
	if k < 0:
		return
	_modules.remove_at(k)
	_enemy_defs.remove_at(k)
	stages.remove_at(BUILTIN_STAGES + k)
	difficulty.remove_at(BUILTIN_STAGES + k)
	m.set("stage_index", -1)
	for i: int in range(k, _modules.size()):
		_modules[i].set("stage_index", BUILTIN_STAGES + i)
		stages[BUILTIN_STAGES + i]["num"] = BUILTIN_STAGES + i + 1


# Makes sure a module stage's sprites are in PixelArt's cache, building them now if the
# prefetch hasn't. A cheap no-op for stages 1-8 and for stages already built.
func prepare_stage(stage_idx: int) -> void:
	var m: RefCounted = get_module(stage_idx)
	if m == null:
		return
	if _art_ready.has(String(get_stage(stage_idx)["id"])):
		return
	if _art_task != -1 and _art_task_module == m:
		_finish_art_task()
		return
	_install_art(m, m.call("build_art"))


# Starts building a module stage's sprites on a worker thread (main calls this for the next
# stage whenever a wave begins), so the hyperspace jump into it doesn't stall.
func prefetch_stage(stage_idx: int) -> void:
	var m: RefCounted = get_module(stage_idx)
	if m == null or _art_task != -1:
		return
	if _art_ready.has(String(get_stage(stage_idx)["id"])):
		return
	_art_task_module = m
	_art_task_result = {}
	_art_task = WorkerThreadPool.add_task(_thread_build_art.bind(m), false, "Stage module art prebuild")
	set_process(true)


func is_stage_art_ready(stage_idx: int) -> bool:
	return get_module(stage_idx) == null or _art_ready.has(String(get_stage(stage_idx)["id"]))


func _thread_build_art(m: RefCounted) -> void:
	_art_task_result = m.call("build_art")


func _finish_art_task() -> void:
	WorkerThreadPool.wait_for_task_completion(_art_task)
	_art_task = -1
	var m: RefCounted = _art_task_module
	_art_task_module = null
	var built: Dictionary = _art_task_result
	_art_task_result = {}
	if m != null:
		_install_art(m, built)


# Turns a module's Images into textures in PixelArt's cache (main thread only).
func _install_art(m: RefCounted, built: Dictionary) -> void:
	for key: Variant in built.keys():
		var v: Variant = built[key]
		if v is Image:
			PixelArt._cache[String(key)] = ImageTexture.create_from_image(v as Image)
		elif v is Texture2D:
			PixelArt._cache[String(key)] = v
	var def: Dictionary = m.call("get_stage_def")
	var boss_tex: String = String(def.get("boss_tex", ""))
	if boss_tex != "" and not PixelArt._cache.has(boss_tex) and PixelArt._cache.has(boss_tex + "_0"):
		PixelArt._cache[boss_tex] = PixelArt._cache[boss_tex + "_0"]
	_art_ready[String(def.get("id", ""))] = true


# Enemy HP growth by stage index. The built-in stages 1-8 keep their original steep curve
# (`base` per stage, 1.34 for regular enemies). Past stage 8 it grows 12% per stage, so stage
# 28 is ~75x stage 1 instead of ~2,700x (a full run's upgrades can't keep up with the latter).
func stage_hp_growth(stage_index: int, base: float = 1.34) -> float:
	var early: int = mini(stage_index, 7)
	var late: int = maxi(0, stage_index - 7)
	return pow(base, float(early)) * pow(1.12, float(late))
