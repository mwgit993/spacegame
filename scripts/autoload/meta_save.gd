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

# Rogue Legacy-style Skill Tree node levels & Fleet Loadout!
var tree_levels: Dictionary = {"core_root": 1}
var selected_ship: String = "viper"


func _ready() -> void:
	_init_default_tree()
	load_game()


func _init_default_tree() -> void:
	tree_levels.clear()
	for def: Dictionary in SkillTreeData.NODES:
		var id: String = String(def["id"])
		tree_levels[id] = 1 if id == "core_root" else 0
	selected_ship = "viper"


func apply_audio_and_display_settings() -> void:
	GenesisMusic.set_volume(music_volume)
	RetroSfx.sfx_volume = sfx_volume
	var cur_fs: bool = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	if fullscreen_enabled != cur_fs and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
		)


func get_level(id: String) -> int:
	return int(tree_levels.get(id, 0))


func get_total_upgrade_ranks() -> int:
	var sum: int = 0
	for k: String in tree_levels.keys():
		if k != "core_root":
			sum += int(tree_levels[k])
	return sum


func get_max_upgrade_ranks() -> int:
	var sum: int = 0
	for def: Dictionary in SkillTreeData.NODES:
		if String(def["id"]) != "core_root":
			sum += int(def["max_level"])
	return sum


func get_unlocked_node_count() -> int:
	var count: int = 0
	for def: Dictionary in SkillTreeData.NODES:
		if get_level(String(def["id"])) > 0:
			count += 1
	return count


func is_node_revealed(id: String) -> bool:
	var def: Dictionary = SkillTreeData.get_node_def(id)
	if def.is_empty():
		return false
	var parent_id: String = String(def["parent"])
	if parent_id == "":
		return true
	return get_level(parent_id) > 0


func get_node_cost(id: String) -> int:
	var def: Dictionary = SkillTreeData.get_node_def(id)
	if def.is_empty():
		return 99999
	var lvl: int = get_level(id)
	return int(def["base_cost"]) + lvl * int(def["cost_step"])


func can_buy_node(id: String) -> bool:
	var def: Dictionary = SkillTreeData.get_node_def(id)
	if def.is_empty() or not is_node_revealed(id):
		return false
	var lvl: int = get_level(id)
	if lvl >= int(def["max_level"]):
		return false
	return scrap >= get_node_cost(id)


func buy_node(id: String) -> bool:
	if not can_buy_node(id):
		return false
	var def: Dictionary = SkillTreeData.get_node_def(id)
	var cost: int = get_node_cost(id)
	scrap -= cost
	tree_levels[id] = get_level(id) + 1
	var ship_unlock: String = String(def.get("unlocks_ship", ""))
	if ship_unlock != "":
		selected_ship = ship_unlock
	save_game()
	return true


func has_any_affordable_upgrade() -> bool:
	for def: Dictionary in SkillTreeData.NODES:
		if can_buy_node(String(def["id"])):
			return true
	return false


# --- Ship Unlock & Fleet Loadout Queries ---
func is_ship_unlocked(ship_id: String) -> bool:
	if ship_id == "viper":
		return true
	for def: Dictionary in SkillTreeData.NODES:
		if String(def.get("unlocks_ship", "")) == ship_id and get_level(String(def["id"])) > 0:
			return true
	return false


func get_unlocked_ship_count() -> int:
	var c: int = 0
	for s: Dictionary in SkillTreeData.SHIPS:
		if is_ship_unlocked(String(s["id"])):
			c += 1
	return c


func select_ship(ship_id: String) -> bool:
	if not is_ship_unlocked(ship_id):
		return false
	selected_ship = ship_id
	save_game()
	return true


func get_selected_ship_def() -> Dictionary:
	if not is_ship_unlocked(selected_ship):
		selected_ship = "viper"
	return SkillTreeData.get_ship_def(selected_ship)


# --- Aggregated Run Stat & Starter Perks from Skill Tree + Selected Ship! ---
func get_starting_max_hp() -> int:
	var ship_def: Dictionary = get_selected_ship_def()
	var base: int = 4 + int(ship_def["hp_mod"]) + get_level("hull_1") + get_level("bio_carapace")
	return maxi(2, base)


func get_starting_speed() -> float:
	var ship_def: Dictionary = get_selected_ship_def()
	return float(ship_def["speed"]) * (1.0 + 0.07 * float(get_level("thruster_1")))


func get_base_fire_rate_mult() -> float:
	return 1.0 + 0.10 * float(get_level("fire_rate_1"))


func get_base_damage_mult() -> float:
	var ship_bonus: float = 0.12 if selected_ship == "dread" else 0.0
	return 1.0 + ship_bonus + 0.12 * float(get_level("damage_1")) + 0.10 * float(get_level("bio_carapace")) + 0.12 * float(get_level("heavy_ordnance"))


func get_crit_chance() -> float:
	var ship_crit: float = 0.20 if selected_ship == "phantom" else 0.0
	return clampf(ship_crit + 0.07 * float(get_level("crit_optics")), 0.0, 0.75)


func get_aoe_scale_mult() -> float:
	return 1.0 + 0.15 * float(get_level("heavy_ordnance")) + 0.10 * float(get_level("weird_science"))


func get_projectile_size_mult() -> float:
	return 1.0 + 0.10 * float(get_level("weird_science"))


func get_magnet_radius() -> float:
	var saucer_mag: float = 35.0 if selected_ship == "saucer" else 0.0
	return 56.0 + saucer_mag + 26.0 * float(get_level("magnet_1"))


func get_scrap_mult() -> float:
	var neko_bonus: float = 0.15 if selected_ship == "neko" else 0.0
	return 1.0 + neko_bonus + 0.15 * float(get_level("scrap_greed"))


func get_xp_mult() -> float:
	var eye_bonus: float = 0.18 if selected_ship == "eyeball" else 0.0
	return 1.0 + eye_bonus + 0.12 * float(get_level("xp_scholar"))


func get_boss_bounty_mult() -> float:
	return 1.0 + 0.25 * float(get_level("bounty_hunter"))


func get_stage_heal_amount() -> int:
	var scarab_heal: int = 1 if selected_ship == "beetle" else 0
	return scarab_heal + (1 if get_level("regen_bay") > 0 else 0)


func get_heal_drop_chance() -> float:
	return 0.10 + 0.05 * float(get_level("regen_bay"))


func get_starting_shields() -> int:
	return get_level("aegis_core")


func has_starter_shield() -> bool:
	return get_starting_shields() > 0


func get_starting_rerolls() -> int:
	return get_level("draft_reroll")


func has_lazarus_revive() -> bool:
	return get_level("phoenix_cell") > 0


func has_veteran_drop() -> bool:
	return get_level("veteran_drop") > 0


func get_starter_addons() -> Dictionary:
	return {
		"option": get_level("starter_option"),
		"turret": get_level("starter_turret"),
		"missile": get_level("starter_missile"),
		"blades": get_level("starter_blades") + (1 if selected_ship == "saucer" else 0),
		"nova": get_level("starter_nova"),
		"bomb": get_level("starter_bomb"),
		"flank": 1 if selected_ship == "dread" else 0,
	}


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
	_init_default_tree()
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
		"selected_ship": selected_ship,
		"tree_levels": tree_levels,
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
	selected_ship = String(data.get("selected_ship", "viper"))

	_init_default_tree()
	var saved_tree: Variant = data.get("tree_levels", {})
	if typeof(saved_tree) == TYPE_DICTIONARY:
		var td: Dictionary = saved_tree
		for key: String in tree_levels.keys():
			if td.has(key):
				tree_levels[key] = int(td[key])
	else:
		# Migrate legacy 5-row Hangar saves seamlessly into the new Starforge Skill Tree!
		var legacy_upg: Variant = data.get("upgrades", {})
		if typeof(legacy_upg) == TYPE_DICTIONARY:
			var lu: Dictionary = legacy_upg
			tree_levels["hull_1"] = int(lu.get("hull", 0))
			tree_levels["fire_rate_1"] = int(lu.get("fire_rate", 0))
			tree_levels["damage_1"] = int(lu.get("damage", 0))
			tree_levels["magnet_1"] = int(lu.get("magnet", 0))
			tree_levels["aegis_core"] = int(lu.get("starter_shield", 0))
	tree_levels["core_root"] = 1
	if not is_ship_unlocked(selected_ship):
		selected_ship = "viper"
