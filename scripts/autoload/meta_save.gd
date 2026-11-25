extends Node

const SAVE_PATH: String = "user://star_viper_save.json"

var scrap: int = 0
var lifetime_scrap: int = 0
var best_wave: int = 0
var best_score: int = 0
var total_runs: int = 0
var total_kills: int = 0
var bosses_defeated: int = 0

# Options / Settings (persisted to disk)
var music_volume: float = 0.80
var sfx_volume: float = 0.85
var screen_shake_enabled: bool = true
var default_autofire: bool = true
var fullscreen_enabled: bool = false
var touch_mode: int = 0 # 0 = AUTO (shows on touch), 1 = ALWAYS ON (phone/mouse test), 2 = OFF

# Permanent upgrade levels
var upgrades: Dictionary = {
	"hull": 0,
	"fire_rate": 0,
	"damage": 0,
	"magnet": 0,
	"starter_shield": 0,
}

const UPGRADE_DEFS: Array[Dictionary] = [
	{
		"id": "hull",
		"name": "REINFORCED HULL",
		"desc": "+1 Max Hull per rank",
		"max_level": 5,
		"base_cost": 25,
		"cost_step": 25,
	},
	{
		"id": "fire_rate",
		"name": "CYCLER CAPACITOR",
		"desc": "+10% Base Fire Rate",
		"max_level": 5,
		"base_cost": 30,
		"cost_step": 30,
	},
	{
		"id": "damage",
		"name": "PLASMA CORE",
		"desc": "+15% Weapon Damage",
		"max_level": 5,
		"base_cost": 35,
		"cost_step": 35,
	},
	{
		"id": "magnet",
		"name": "TRACTOR ARRAY",
		"desc": "+25px Magnet & +10% Scrap",
		"max_level": 4,
		"base_cost": 20,
		"cost_step": 25,
	},
	{
		"id": "starter_shield",
		"name": "AEGIS GENERATOR",
		"desc": "Start runs w/ Force Shield",
		"max_level": 1,
		"base_cost": 80,
		"cost_step": 80,
	},
]


func _ready() -> void:
	load_game()


func apply_audio_and_display_settings() -> void:
	GenesisMusic.set_volume(music_volume)
	RetroSfx.sfx_volume = sfx_volume
	var cur_fs: bool = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	if fullscreen_enabled != cur_fs and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
		)


func get_level(id: String) -> int:
	return int(upgrades.get(id, 0))


func get_total_upgrade_ranks() -> int:
	var sum: int = 0
	for k: String in upgrades.keys():
		sum += int(upgrades[k])
	return sum


func get_max_upgrade_ranks() -> int:
	var sum: int = 0
	for def: Dictionary in UPGRADE_DEFS:
		sum += int(def["max_level"])
	return sum


func has_any_affordable_upgrade() -> bool:
	for def: Dictionary in UPGRADE_DEFS:
		if can_buy(String(def["id"])):
			return true
	return false


func get_upgrade_def(id: String) -> Dictionary:
	for def: Dictionary in UPGRADE_DEFS:
		if String(def["id"]) == id:
			return def
	return {}


func get_upgrade_cost(id: String) -> int:
	var def: Dictionary = get_upgrade_def(id)
	if def.is_empty():
		return 9999
	var lvl: int = get_level(id)
	return int(def["base_cost"]) + lvl * int(def["cost_step"])


func can_buy(id: String) -> bool:
	var def: Dictionary = get_upgrade_def(id)
	if def.is_empty():
		return false
	var lvl: int = get_level(id)
	if lvl >= int(def["max_level"]):
		return false
	return scrap >= get_upgrade_cost(id)


func buy_upgrade(id: String) -> bool:
	if not can_buy(id):
		return false
	var cost: int = get_upgrade_cost(id)
	scrap -= cost
	upgrades[id] = get_level(id) + 1
	save_game()
	return true


func get_starting_max_hp() -> int:
	return 4 + get_level("hull")


func get_base_fire_rate_mult() -> float:
	return 1.0 + 0.10 * float(get_level("fire_rate"))


func get_base_damage_mult() -> float:
	return 1.0 + 0.15 * float(get_level("damage"))


func get_magnet_radius() -> float:
	return 48.0 + 25.0 * float(get_level("magnet"))


func get_scrap_mult() -> float:
	return 1.0 + 0.10 * float(get_level("magnet"))


func has_starter_shield() -> bool:
	return get_level("starter_shield") > 0


func record_run_end(wave_reached: int, run_scrap: int, kills: int, run_score: int, run_bosses: int) -> void:
	scrap += run_scrap
	lifetime_scrap += run_scrap
	total_runs += 1
	total_kills += kills
	bosses_defeated += run_bosses
	if wave_reached > best_wave:
		best_wave = wave_reached
	if run_score > best_score:
		best_score = run_score
	save_game()


func reset_save() -> void:
	scrap = 0
	lifetime_scrap = 0
	best_wave = 0
	best_score = 0
	total_runs = 0
	total_kills = 0
	bosses_defeated = 0
	for key: String in upgrades.keys():
		upgrades[key] = 0
	save_game()


func save_game() -> void:
	var data: Dictionary = {
		"scrap": scrap,
		"lifetime_scrap": lifetime_scrap,
		"best_wave": best_wave,
		"best_score": best_score,
		"total_runs": total_runs,
		"total_kills": total_kills,
		"bosses_defeated": bosses_defeated,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"screen_shake_enabled": screen_shake_enabled,
		"default_autofire": default_autofire,
		"fullscreen_enabled": fullscreen_enabled,
		"touch_mode": touch_mode,
		"upgrades": upgrades,
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	scrap = int(data.get("scrap", 0))
	lifetime_scrap = int(data.get("lifetime_scrap", scrap))
	best_wave = int(data.get("best_wave", 0))
	best_score = int(data.get("best_score", 0))
	total_runs = int(data.get("total_runs", 0))
	total_kills = int(data.get("total_kills", 0))
	bosses_defeated = int(data.get("bosses_defeated", 0))
	music_volume = float(data.get("music_volume", 0.80))
	sfx_volume = float(data.get("sfx_volume", 0.85))
	screen_shake_enabled = bool(data.get("screen_shake_enabled", true))
	default_autofire = bool(data.get("default_autofire", true))
	fullscreen_enabled = bool(data.get("fullscreen_enabled", false))
	touch_mode = int(data.get("touch_mode", 0))
	var saved_upg: Variant = data.get("upgrades", {})
	if typeof(saved_upg) == TYPE_DICTIONARY:
		var upg_dict: Dictionary = saved_upg
		for key: String in upgrades.keys():
			if upg_dict.has(key):
				upgrades[key] = int(upg_dict[key])
