extends Node2D

enum State { TITLE, STATS, OPTIONS, HANGAR, LOADOUT, INTRO_WARP, PLAYING, PAUSED, DRAFT, HYPERSPACE, GAME_OVER_DELAY, SOUNDTRACK }

const VIEW_W: float = 480.0
const VIEW_H: float = 270.0
const FONT_SZ: int = 10

const RUN_UPGRADE_POOL: Array[Dictionary] = [
	# --- 5 Signature Elemental / Tech Beam Cores ---
	{
		"id": "laser",
		"cat": "BEAM",
		"title": "PIERCE LASER",
		"icon": "upg_laser",
		"color": Color("#28e8ff"),
		"max_rank": 4,
		"desc": "High-speed beam skewers lines of foes",
	},
	{
		"id": "wave",
		"cat": "BEAM",
		"title": "SONIC WAVE BEAM",
		"icon": "upg_wave",
		"color": Color("#3ce878"),
		"max_rank": 4,
		"desc": "Wide helix crescents sweep the lane",
	},
	{
		"id": "prism",
		"cat": "BEAM",
		"title": "RICOCHET PRISM",
		"icon": "upg_prism",
		"color": Color("#ff4cd4"),
		"max_rank": 4,
		"desc": "Bounces off walls & enemy to enemy!",
	},
	{
		"id": "tesla",
		"cat": "BEAM",
		"title": "TESLA ARC BEAM",
		"icon": "upg_tesla",
		"color": Color("#b86bff"),
		"max_rank": 4,
		"desc": "Chains electric arcs across squads",
	},
	{
		"id": "plasma",
		"cat": "BEAM",
		"title": "SOLAR PLASMA",
		"icon": "upg_plasma",
		"color": Color("#ff6820"),
		"max_rank": 4,
		"desc": "Explosive fireballs blast AoE clusters",
	},

	# --- 7 Physical Ship Addons (visibly mounted on or orbiting your hull!) ---
	{
		"id": "option",
		"cat": "ADDON",
		"title": "OPTION DRONE",
		"icon": "upg_option",
		"color": Color("#ff9624"),
		"max_rank": 4,
		"desc": "Trailing orb copies your main blaster",
	},
	{
		"id": "blades",
		"cat": "ADDON",
		"title": "ORBITAL BLADES",
		"icon": "upg_blades",
		"color": Color("#54f4ff"),
		"max_rank": 4,
		"desc": "Spinning saws shred foes & bullets",
	},
	{
		"id": "turret",
		"cat": "ADDON",
		"title": "AUTO-TURRET",
		"icon": "upg_turret",
		"color": Color("#6eff8c"),
		"max_rank": 4,
		"desc": "360 roof gun auto-aims at threats",
	},
	{
		"id": "missile",
		"cat": "ADDON",
		"title": "HOMING PODS",
		"icon": "upg_missile",
		"color": Color("#ff4c68"),
		"max_rank": 4,
		"desc": "Wing pods fire lock-on missiles",
	},
	{
		"id": "flank",
		"cat": "ADDON",
		"title": "TAIL & FLANK GUN",
		"icon": "upg_flank",
		"color": Color("#ffe854"),
		"max_rank": 3,
		"desc": "Fires aft & diagonal wing blasters",
	},
	{
		"id": "bomb",
		"cat": "ADDON",
		"title": "GRAVITY BOMBS",
		"icon": "upg_bomb",
		"color": Color("#d44cff"),
		"max_rank": 3,
		"desc": "Belly bay lobs vortex AoE torpedoes",
	},
	{
		"id": "nova",
		"cat": "ADDON",
		"title": "NOVA SHOCK COIL",
		"icon": "upg_nova",
		"color": Color("#ffd84c"),
		"max_rank": 3,
		"desc": "Periodic EMP blast zaps foes & shots",
	},

	# --- 6 Core Ship Systems (including Signature Blaster Overclock!) ---
	{
		"id": "overclock",
		"cat": "CORE",
		"title": "BLASTER OVERCLOCK",
		"icon": "upg_overclock",
		"color": Color("#ff9624"),
		"max_rank": 4,
		"desc": "Upgrades your Ship's Signature Gun!",
	},
	{
		"id": "spread",
		"cat": "CORE",
		"title": "SPREAD MATRIX",
		"icon": "upg_spread",
		"color": Color("#ffe854"),
		"max_rank": 3,
		"desc": "Splits main gun into multi-shot fan",
	},
	{
		"id": "rapid",
		"cat": "CORE",
		"title": "RAPID COIL",
		"icon": "upg_rapid",
		"color": Color("#d46bff"),
		"max_rank": 5,
		"desc": "+22% Fire Rate & +10% Damage",
	},
	{
		"id": "shield",
		"cat": "CORE",
		"title": "FORCE SHIELD",
		"icon": "upg_shield",
		"color": Color("#3ce8ff"),
		"max_rank": 3,
		"desc": "+1 Regenerating Aegis Barrier",
	},
	{
		"id": "thruster",
		"cat": "CORE",
		"title": "AFTERBURNER",
		"icon": "upg_thruster",
		"color": Color("#3ce878"),
		"max_rank": 4,
		"desc": "+Ship Speed & agile dodging",
	},
	{
		"id": "repair",
		"cat": "CORE",
		"title": "HULL OVERCLOCK",
		"icon": "upg_repair",
		"color": Color("#66ff99"),
		"max_rank": 6,
		"desc": "+1 Max HP, Heal 2 & +12% Damage",
	},

	# --- 18 DRAFT CARD upgrades: only offered once their Skill Tree node is bought ---
	# (SkillTreeData node with matching "unlocks_upgrade"). "short"/"badge" feed the pause screen.
	{
		"id": "homing",
		"cat": "MOD",
		"title": "SEEKER ROUNDS",
		"icon": "upg_homing",
		"color": Color("#ff4c68"),
		"max_rank": 2,
		"desc": "Main gun shots curve into enemies",
		"short": "Seeker",
		"badge": "badge_seek",
	},
	{
		"id": "shrapnel",
		"cat": "MOD",
		"title": "SHRAPNEL BURST",
		"icon": "upg_shrapnel",
		"color": Color("#ff9624"),
		"max_rank": 2,
		"desc": "Main gun hits burst into fragments",
		"short": "Shrapnel",
		"badge": "badge_shrapnel",
	},
	{
		"id": "crit",
		"cat": "MOD",
		"title": "TACHYON OPTICS",
		"icon": "upg_crit",
		"color": Color("#ffe854"),
		"max_rank": 3,
		"desc": "+12% Crit chance & harder crits",
		"short": "Tachyon",
		"badge": "badge_crit",
	},
	{
		"id": "berserk",
		"cat": "MOD",
		"title": "BERSERKER CORE",
		"icon": "upg_berserk",
		"color": Color("#f03c4e"),
		"max_rank": 2,
		"desc": "+Damage for each missing Hull point",
		"short": "Berserker",
		"badge": "badge_berserk",
	},
	{
		"id": "execute",
		"cat": "MOD",
		"title": "EXECUTE PROTOCOL",
		"icon": "upg_execute",
		"color": Color("#dce8ff"),
		"max_rank": 2,
		"desc": "Hits finish off badly hurt foes",
		"short": "Execute",
		"badge": "badge_execute",
	},
	{
		"id": "ambush",
		"cat": "MOD",
		"title": "AMBUSH TARGETING",
		"icon": "upg_ambush",
		"color": Color("#f03c4e"),
		"max_rank": 2,
		"desc": "+75% Damage vs unhurt enemies",
		"short": "Ambush",
		"badge": "badge_ambush",
	},
	{
		"id": "cryo",
		"cat": "MOD",
		"title": "CRYO ROUNDS",
		"icon": "upg_cryo",
		"color": Color("#8cf4ff"),
		"max_rank": 2,
		"desc": "Hits chill foes, slowing moves & fire",
		"short": "Cryo",
		"badge": "badge_cryo",
	},
	{
		"id": "napalm",
		"cat": "MOD",
		"title": "NAPALM ROUNDS",
		"icon": "upg_napalm",
		"color": Color("#ff6820"),
		"max_rank": 2,
		"desc": "Hits set foes on fire",
		"short": "Napalm",
		"badge": "badge_napalm",
	},
	{
		"id": "leech",
		"cat": "GUARD",
		"title": "VAMPIRE SALVAGE",
		"icon": "upg_leech",
		"color": Color("#3ce878"),
		"max_rank": 3,
		"desc": "Repair 1 Hull every few dozen kills",
		"short": "Vampire",
		"badge": "badge_leech",
	},
	{
		"id": "reflect",
		"cat": "GUARD",
		"title": "MIRROR SHIELD",
		"icon": "upg_reflect",
		"color": Color("#54f4ff"),
		"max_rank": 2,
		"desc": "+1 Shield. Breaking it fires shots back",
		"short": "Mirror",
		"badge": "badge_reflect",
	},
	{
		"id": "last_stand",
		"cat": "GUARD",
		"title": "LAST STAND",
		"icon": "upg_last_stand",
		"color": Color("#ffe854"),
		"max_rank": 1,
		"desc": "At 1 Hull: nova, 3s invincible & shields",
		"short": "Last Stand",
		"badge": "badge_last_stand",
	},
	{
		"id": "chrono",
		"cat": "GUARD",
		"title": "CHRONO FIELD",
		"icon": "upg_chrono",
		"color": Color("#28e8ff"),
		"max_rank": 2,
		"desc": "Enemy shots slow down near you",
		"short": "Chrono",
		"badge": "badge_chrono",
	},
	{
		"id": "graze",
		"cat": "GUARD",
		"title": "GRAZE DYNAMO",
		"icon": "upg_graze",
		"color": Color("#ff9624"),
		"max_rank": 2,
		"desc": "Near-miss enemy shots give XP",
		"short": "Graze",
		"badge": "badge_graze",
	},
	{
		"id": "aura",
		"cat": "TECH",
		"title": "ION STORM AURA",
		"icon": "upg_aura",
		"color": Color("#d44cff"),
		"max_rank": 3,
		"desc": "Crackling field zaps nearby foes",
		"short": "Ion Aura",
		"badge": "badge_aura",
	},
	{
		"id": "chain",
		"cat": "TECH",
		"title": "CHAIN REACTION",
		"icon": "upg_chain",
		"color": Color("#ff9624"),
		"max_rank": 3,
		"desc": "Destroyed foes explode on neighbors",
		"short": "Chain",
		"badge": "badge_chain",
	},
	{
		"id": "orbital",
		"cat": "TECH",
		"title": "ORBITAL STRIKE",
		"icon": "upg_orbital",
		"color": Color("#ffe854"),
		"max_rank": 3,
		"desc": "Sky laser smites the toughest foe",
		"short": "Orbital",
		"badge": "badge_orbital",
	},
	{
		"id": "mines",
		"cat": "TECH",
		"title": "PROXIMITY MINES",
		"icon": "upg_mines",
		"color": Color("#ff4c68"),
		"max_rank": 3,
		"desc": "Drops mines that blast passing foes",
		"short": "Mines",
		"badge": "badge_mines",
	},
	{
		"id": "salvage",
		"cat": "LOOT",
		"title": "SALVAGE CLAWS",
		"icon": "upg_salvage",
		"color": Color("#ffd84c"),
		"max_rank": 2,
		"desc": "+40% Scrap from kills this run",
		"short": "Salvage",
		"badge": "badge_salvage",
	},
]

# Every change goes through _on_state_changed(), so no way out of the flight can leave the
# speed-up running.
var state: State = State.TITLE:
	set(value):
		state = value
		_on_state_changed()

var starfield: StarfieldBg
var world_root: Node2D
var enemy_layer: Node2D
var pickup_layer: Node2D
var bullet_layer: Node2D
var player: PlayerShip
var fx_layer: FxLayer

var ui_layer: CanvasLayer
var hud_bar: Control
var pause_hud_btn: Button
var touch_focus_btn: Button
var banner_label: Label
var title_panel: Control
var stats_panel: Control
var options_panel: Control
var hangar_panel: Control
var loadout_panel: Control
var draft_panel: Control
var pause_panel: Control

# Title & Menu focus buttons
var _title_ship_sprite: Sprite2D
var _title_start_btn: Button
var _title_tree_btn: Button
var _title_loadout_btn: Button
var _title_menu_btns: Array[Button] = []
var _title_sel_idx: int = 0
var _stats_back_btn: Button
var _stats_body_lbl: Label
var _pause_resume_btn: Button
var _pause_info_canvas: Control
var _pause_ship_sprite: Sprite2D
var _options_from_pause: bool = false

# Options UI controls
var _opt_music_lbl: Label
var _opt_sfx_lbl: Label
var _opt_autofire_btn: Button
var _opt_shake_btn: Button
var _opt_touch_btn: Button
var _opt_fullscreen_btn: Button
var _opt_speed_btn: Button
var _opt_soundtrack_btn: Button

# Soundtrack picker (Options > SOUNDTRACK): one row per place music plays
# (GenesisMusic.SLOT_KEYS); left/right picks the original or one of its alternatives.
var soundtrack_panel: Control
var _snd_row_btns: Array[Button] = []
var _snd_value_lbls: Array[Label] = []
var _snd_info_lbl: Label
var _snd_cursor: ColorRect
var _snd_back_btn: Button
var _snd_row_idx: int = 0
var _snd_hyper_timer: float = 0.0
var _snd_resume_mode: GenesisMusic.Mode = GenesisMusic.Mode.TITLE
var _snd_resume_stage: int = 0

# Speed-up (RT / F): runs the flight at 2x, held or toggled per MetaSave.speed_up_toggle.
const SPEED_UP_SCALE: float = 2.0
# Trigger hysteresis: a pull counts once past PRESS and ends only below RELEASE, so a wobbly
# half-pull can't flip TOGGLE mode twice.
const SPEED_TRIGGER_PRESS: float = 0.55
const SPEED_TRIGGER_RELEASE: float = 0.25
var _speed_up_active: bool = false      # 2x currently applied to Engine.time_scale
var _speed_toggle_on: bool = false      # TOGGLE mode: switched on by the last press
var _speed_input_held: bool = false     # RT or F held on the previous update (edge detection)
var _speed_trigger_down: bool = false   # RT inside its hysteresis "pressed" state
var _base_physics_tps: int = 60

# Analog stick UI navigation repeat timer
var _joy_nav_cooldown: float = 0.0

# Run, XP Leveling & Stage progression metrics
var wave: int = 0
var current_stage_idx: int = 0
var score: int = 0
var run_scrap: int = 0
var run_kills: int = 0
var run_bosses: int = 0
var player_level: int = 1
var run_xp: int = 0
var xp_to_next: int = 18
var rerolls_left: int = 0
var _pending_level_ups: int = 0
var _draft_title_lbl: PromptBar
var _draft_reroll_btn: Button
var _draft_pre_speed: float = 1.15
var run_ranks: Dictionary = {}
var _pre_pause_speed: float = 1.15

# Hyperspace transition state
var _pending_hyperspace: bool = false
var _hyper_timer: float = 0.0
var _hyper_duration: float = 2.6
var _hyper_swapped_stage: bool = false
var _intro_timer: float = 0.0
var _intro_flash_done: bool = false
const INTRO_DURATION: float = 1.85

# Wave spawn director
var _spawn_queue: Array[Dictionary] = []
var _wave_clock: float = 0.0
var _wave_clear_delay: float = 0.0
var _banner_timer: float = 0.0
var _death_timer: float = 0.0
var _next_squad_id: int = 1
var _squad_counts: Dictionary = {}

# Visual Draft Cards
var _draft_choices: Array[Dictionary] = []
var _draft_cards: Array[Dictionary] = []

# Rogue Legacy-Style Starforge Skill Tree UI state
var _tree_canvas: Control
var _tree_scrap_lbl: Label
var _tree_summary_lbl: Label
var _tree_node_title_lbl: Label
var _tree_node_desc_lbl: Label
var _tree_buy_btn: Button
var _tree_selected_id: String = "hull_1"
var _tree_cam_offset: Vector2 = Vector2(0.0, -68.0)
var _tree_dragging: bool = false
var _tree_drag_moved: bool = false

# Ship Loadout Fleet Bay UI state
var _loadout_scrap_lbl: Label
var _loadout_count_lbl: Label
var _loadout_ship_btns: Array[Button] = []
var _loadout_ship_icons: Array[TextureRect] = []
var _loadout_ship_names: Array[Label] = []
var _loadout_preview_ship: Sprite2D
var _loadout_preview_bullet: Sprite2D
var _loadout_info_title: Label
var _loadout_info_weapon: Label
var _loadout_info_desc: Label
var _loadout_info_perks: Label
var _loadout_action_btn: Button
var _loadout_cursor_idx: int = 0


func _ready() -> void:
	randomize()
	_base_physics_tps = Engine.physics_ticks_per_second
	MetaSave.apply_audio_and_display_settings()
	_build_world()
	_build_ui()
	_enter_title()
	if OS.get_cmdline_user_args().has("--smoke-test"):
		_run_smoke_test()


func _run_smoke_test() -> void:
	var smoke_ok: bool = true
	_enter_stats()
	_enter_options()
	if not _smoke_check_input_prompts():
		get_tree().quit(1)
		return
	# Save migration: v1 nodes are refunded (damage_1 2 ranks = 75, starter_turret = 70,
	# xp_scholar ranks 4-5 above the new cap of 3 = 246), owned ships are kept.
	MetaSave._init_default_tree()
	var refund: int = MetaSave.migrate_tree_levels({"damage_1": 2, "starter_turret": 1, "xp_scholar": 5, "ship_neko": 1, "bogus_node": 3})
	if refund != 391 or MetaSave.get_level("xp_scholar") != 3 or not MetaSave.is_ship_unlocked("neko"):
		push_error("SMOKE: tree migration refunded %d (expected 391)" % refund)
		smoke_ok = false
	MetaSave._init_default_tree()
	# With nothing bought, no DRAFT CARD upgrade may be offered.
	for roll_i: int in range(30):
		_roll_draft_choices()
		for choice: Dictionary in _draft_choices:
			if choice.has("short"):
				push_error("SMOKE: locked draft card offered: " + String(choice["id"]))
				smoke_ok = false
	# Buy every node of the Starforge Skill Tree (parents first), then walk the cursor around.
	MetaSave.scrap = 999999
	_enter_hangar("SMOKE TEST SUMMARY")
	for pass_i: int in range(12):
		for def: Dictionary in SkillTreeData.NODES:
			var node_id: String = String(def["id"])
			_tree_selected_id = node_id
			_refresh_skill_tree_ui()
			while MetaSave.can_buy_node(node_id):
				_on_buy_tree_node()
	for def: Dictionary in SkillTreeData.NODES:
		if MetaSave.get_level(String(def["id"])) < int(def["max_level"]):
			push_error("SMOKE: could not max tree node " + String(def["id"]))
			smoke_ok = false
	_tree_selected_id = "core_root"
	for dir: Vector2 in [Vector2.RIGHT, Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.LEFT, Vector2.LEFT, Vector2.DOWN, Vector2.DOWN, Vector2.RIGHT]:
		_move_tree_selection(dir)
	_click_tree_at(_tree_canvas.size * 0.5)
	_tree_canvas.queue_redraw()
	InputPrompts.set_gamepad(not InputPrompts.is_gamepad)
	# Exercise Fleet Ship Loadout Bay across all 7 ships!
	_enter_loadout()
	for s_idx: int in range(SkillTreeData.SHIPS.size()):
		_select_loadout_slot(s_idx)
		InputPrompts.set_gamepad(not InputPrompts.is_gamepad)
	if not _smoke_check_speed_up():
		smoke_ok = false
	if not _smoke_check_soundtrack():
		smoke_ok = false
	MetaSave.select_ship("neko")
	_start_run()
	_update_intro_warp(1.0)
	_update_intro_warp(1.0)
	_pause_game()
	InputPrompts.set_gamepad(not InputPrompts.is_gamepad)
	_options_from_pause = true
	_enter_options()
	_leave_options()
	_resume_game()
	# Exercise all 7 ship signature blasters, beams, addons, rerolls, and Lazarus revive!
	for ship_d: Dictionary in SkillTreeData.SHIPS:
		MetaSave.tree_levels["ship_" + String(ship_d["id"])] = 1
		MetaSave.select_ship(String(ship_d["id"]))
		player.reset_for_new_run()
		player._fire_primary()
	MetaSave.select_ship("neko")
	player.reset_for_new_run()
	for upg_id: String in ["overclock", "prism", "wave", "tesla", "plasma", "laser", "option", "blades", "turret", "missile", "flank", "bomb", "nova", "spread", "shield", "rapid", "thruster", "repair"]:
		player.apply_run_upgrade(upg_id)
		player._fire_primary()
	player._fire_flank_guns()
	player._fire_auto_turret()
	player._fire_gravity_bomb()
	player._trigger_nova_pulse(false)
	player._update_orbiting_blades(0.15)
	# Exercise all 18 DRAFT CARD upgrades (unlocked by the tree above) at max rank.
	var card_count: int = 0
	for def: Dictionary in RUN_UPGRADE_POOL:
		if not def.has("short"):
			continue
		card_count += 1
		var card_id: String = String(def["id"])
		if SkillTreeData.get_upgrade_unlock_node(card_id) == "" or not MetaSave.is_run_upgrade_unlocked(card_id):
			push_error("SMOKE: draft card has no bought tree node: " + card_id)
			smoke_ok = false
		for r_i: int in range(int(def["max_rank"])):
			run_ranks[card_id] = int(run_ranks.get(card_id, 0)) + 1
			player.apply_run_upgrade(card_id)
	if card_count != MetaSave.get_total_draft_card_nodes():
		push_error("SMOKE: %d draft cards vs %d tree unlock nodes" % [card_count, MetaSave.get_total_draft_card_nodes()])
		smoke_ok = false
	_roll_draft_choices()
	player._fire_primary()
	var graze_shot: GameBullet = GameBullet.new()
	bullet_layer.add_child(graze_shot)
	graze_shot.setup(player.global_position + Vector2(10.0, 0.0), Vector2(-60.0, 0.0), 1.0, false, "bullet_enemy_pink", 0, false, 2.5, fx_layer)
	var xp_before: int = run_xp + player_level * 1000
	player._update_run_perks(1.0, true)
	graze_shot._process(0.05)
	if not graze_shot.grazed or graze_shot.slow_timer <= 0.0 or run_xp + player_level * 1000 <= xp_before:
		push_error("SMOKE: graze / chrono field did not affect a nearby enemy shot")
		smoke_ok = false
	player._reflect_burst()
	for b_node: Node in bullet_layer.get_children():
		if b_node is GameBullet and (b_node as GameBullet).life_left > 0.0:
			(b_node as GameBullet)._process(8.0)
	for k_i: int in range(30):
		player.on_enemy_killed(Vector2(300.0, 120.0), false)
	player.hp = 2
	player.invuln_timer = 0.0
	player.shield_charges = 0
	player.take_player_hit()
	if player.hp != 1 or player.invuln_timer < 2.5:
		push_error("SMOKE: Last Stand did not trigger")
		smoke_ok = false
	player.on_stage_cleared()
	if _collect_installed_modules().size() < 20:
		push_error("SMOKE: pause screen lists too few modules")
		smoke_ok = false
	_gain_xp(55)
	hud_bar.queue_redraw()
	for st_i: int in range(8):
		starfield.set_stage(st_i)
		starfield._process(0.02)
		GenesisMusic.play_stage(st_i)
		GenesisMusic._step = 140
		GenesisMusic._process(0.02)
		GenesisMusic._step = 280
		GenesisMusic._process(0.02)
		for t: GameEnemy.Type in [GameEnemy.Type.SCOUT_SINE, GameEnemy.Type.SWOOPER, GameEnemy.Type.SNIPER, GameEnemy.Type.CRUISER, GameEnemy.Type.BOSS]:
			_spawn_enemy_now({"type": t, "pos": Vector2(360.0, 130.0), "hp_mult": 1.0, "phase": 0.0, "squad": 1, "stage": st_i})
	GenesisMusic.play_boss(2)
	GenesisMusic._step = 150
	GenesisMusic._process(0.02)
	for e: Node in enemy_layer.get_children():
		e.call("_process", 0.05)
		e.call("take_damage", 1.5)
	# DRAFT CARD on-hit effects: ambush, cryo, napalm, execute and shrapnel on a live enemy,
	# plus the enemy-targeting perks (ion aura, orbital strike, chain blast).
	for e: Node in enemy_layer.get_children():
		if e is GameEnemy and (e as GameEnemy).enemy_type == GameEnemy.Type.CRUISER and not (e as GameEnemy)._dead:
			var probe_target: GameEnemy = e as GameEnemy
			probe_target.hp = probe_target.max_hp
			var probe: GameBullet = player._spawn_player_bullet(probe_target.global_position, Vector2(300.0, 0.0), 1.0, "bullet_vulcan", 0, false, 3.0)
			probe.split_count = 3
			probe._on_area_entered(probe_target)
			if probe_target._chill_timer <= 0.0 or probe_target._burn_timer <= 0.0:
				push_error("SMOKE: cryo / napalm status not applied")
				smoke_ok = false
			probe_target._process(0.3)
			probe_target.hp = probe_target.max_hp * 0.2
			var probe_2: GameBullet = player._spawn_player_bullet(probe_target.global_position, Vector2(300.0, 0.0), 1.0, "bullet_vulcan", 0, false, 3.0)
			probe_2._on_area_entered(probe_target)
			if not probe_target._dead:
				push_error("SMOKE: execute protocol did not finish a weakened enemy")
				smoke_ok = false
			break
	player._pulse_ion_aura()
	player._fire_orbital_strike()
	player._chain_blast(Vector2(360.0, 130.0))
	for e: Node in enemy_layer.get_children():
		if e is GameEnemy and (e as GameEnemy).enemy_type == GameEnemy.Type.BOSS:
			var boss_test: GameEnemy = e as GameEnemy
			for step_i: int in range(8):
				boss_test._process(0.45)
			hud_bar.queue_redraw()
			boss_test._shoot_from(Vector2(300.0, 134.0), Vector2(-140.0, 0.0), "bullet_enemy_pink")
			for b_node: Node in bullet_layer.get_children():
				b_node.call("_process", 0.12)
			boss_test._start_boss_death_sequence()
			boss_test._process(0.30)
			break
	_open_upgrade_draft()
	InputPrompts.set_gamepad(not InputPrompts.is_gamepad)
	_refresh_draft_card_glyphs()
	InputPrompts.set_gamepad(not InputPrompts.is_gamepad)
	_reroll_draft_cards()
	_pick_draft_card(0)
	_begin_hyperspace_jump()
	_update_hyperspace(1.5)
	_update_hyperspace(1.5)
	player.invuln_timer = 0.0
	player.take_player_hit()
	MetaSave.reset_save()
	if not _smoke_speed_is(false, "at the end of the smoke test"):
		smoke_ok = false
	if not smoke_ok:
		push_error("STAR_VIPER_SMOKE_TEST_FAILED")
		get_tree().quit(1)
		return
	print("STAR_VIPER_SMOKE_TEST_PASSED")
	get_tree().quit(0)


# Device-aware prompts: a press on each device must swap the prompts, while stick drift, a
# tiny mouse nudge and button releases must not. Also builds every glyph strip on both devices.
func _smoke_check_input_prompts() -> bool:
	var pad_btn: InputEventJoypadButton = InputEventJoypadButton.new()
	pad_btn.button_index = JOY_BUTTON_A
	pad_btn.pressed = true
	var pad_release: InputEventJoypadButton = InputEventJoypadButton.new()
	pad_release.button_index = JOY_BUTTON_B
	pad_release.pressed = false
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	var drift: InputEventJoypadMotion = InputEventJoypadMotion.new()
	drift.axis = JOY_AXIS_LEFT_X
	drift.axis_value = 0.2
	var stick: InputEventJoypadMotion = InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_Y
	stick.axis_value = -0.9
	var nudge: InputEventMouseMotion = InputEventMouseMotion.new()
	nudge.relative = Vector2(1.0, 0.0)
	var swipe: InputEventMouseMotion = InputEventMouseMotion.new()
	swipe.relative = Vector2(12.0, 0.0)
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	# [event, expected InputPrompts.is_gamepad afterwards]
	var steps: Array = [
		[pad_btn, true], [key, false], [pad_release, false], [drift, false], [stick, true],
		[nudge, true], [swipe, false], [pad_btn, true], [click, false],
	]
	for step: Array in steps:
		var ev: InputEvent = step[0]
		InputPrompts._input(ev)
		if InputPrompts.is_gamepad != bool(step[1]):
			push_error("InputPrompts: after %s, is_gamepad should be %s" % [ev.get_class(), str(step[1])])
			return false
	for on: bool in [false, true]:
		InputPrompts.set_gamepad(on)
		for act: String in InputPrompts.ACTIONS.keys():
			if InputPrompts.glyph_ids_for(act).size() > 0 and InputPrompts.strip_for(act) == null:
				push_error("InputPrompts: no glyph strip for %s" % act)
				return false
	for g_id: String in InputPrompts.all_glyph_ids():
		InputPrompts.glyph(g_id)
	return true


# Speed-up button: HOLD and TOGGLE reach 2x only while flying, every way out of the flight drops
# to 1x, a jittery trigger pull flips TOGGLE exactly once, shots sweep their path at 2x, and the
# mode saves, loads, and defaults to HOLD for older saves.
func _smoke_check_speed_up() -> bool:
	var ok: bool = true
	var saved_mode: bool = MetaSave.speed_up_toggle

	# --- HOLD ---
	MetaSave.speed_up_toggle = false
	_start_run()
	_update_speed_up(true, 0.0)
	ok = _smoke_speed_is(false, "held during the intro warp") and ok
	_update_intro_warp(1.0)
	_update_intro_warp(1.0)
	_update_speed_up(false, 0.0)
	ok = _smoke_speed_is(false, "idle in flight") and ok
	_update_speed_up(true, 0.0)
	ok = _smoke_speed_is(true, "F held") and ok
	var shot: GameBullet = player._spawn_player_bullet(Vector2(100.0, 120.0), Vector2(520.0, 0.0), 1.0, "bullet_rail", 0, false, 3.2)
	shot._process(1.0 / 30.0)
	if shot._sweep_node == null or shot._sweep_node.disabled or shot._sweep_shape.mid_height < 15.0:
		push_error("SMOKE: speed-up: a 2x shot did not sweep its path")
		ok = false
	_update_speed_up(false, 0.0)
	ok = _smoke_speed_is(false, "F released") and ok
	shot._process(1.0 / 60.0)
	if not shot._sweep_node.disabled:
		push_error("SMOKE: speed-up: shot sweep still on at 1x")
		ok = false
	shot.queue_free()
	_update_speed_up(false, 0.9)
	ok = _smoke_speed_is(true, "RT pulled") and ok
	_update_speed_up(false, 0.4)
	ok = _smoke_speed_is(true, "RT eased back into the hysteresis band") and ok
	_update_speed_up(false, 0.1)
	ok = _smoke_speed_is(false, "RT released") and ok
	_update_speed_up(true, 0.0)
	_pause_game()
	ok = _smoke_speed_is(false, "paused while held") and ok
	_update_speed_up(true, 0.0)
	ok = _smoke_speed_is(false, "held in the pause menu") and ok
	_resume_game()
	_update_speed_up(true, 0.0)
	ok = _smoke_speed_is(true, "still held after resuming") and ok
	_open_upgrade_draft()
	ok = _smoke_speed_is(false, "level-up draft while held") and ok
	_update_speed_up(true, 0.0)
	ok = _smoke_speed_is(false, "held in the draft") and ok
	_pick_draft_card(0)
	_update_speed_up(true, 0.0)
	ok = _smoke_speed_is(true, "still held after the draft") and ok
	_begin_hyperspace_jump()
	_update_speed_up(true, 0.0)
	ok = _smoke_speed_is(true, "held during the hyperspace jump") and ok
	_update_hyperspace(_hyper_duration + 0.5)
	_update_speed_up(true, 0.0)
	_on_player_died()
	ok = _smoke_speed_is(false, "game over while held") and ok
	_update_speed_up(true, 0.0)
	ok = _smoke_speed_is(false, "held during the game-over delay") and ok
	_enter_title()
	_update_speed_up(false, 0.0)

	# --- TOGGLE ---
	MetaSave.speed_up_toggle = true
	_start_run()
	_update_intro_warp(1.0)
	_update_intro_warp(1.0)
	_update_speed_up(false, 0.0)
	ok = _smoke_speed_is(false, "toggle idle") and ok
	for t: float in [0.2, 0.6, 0.9, 0.5, 0.6, 0.35, 0.1, 0.0]:
		_update_speed_up(false, t)
	ok = _smoke_speed_is(true, "toggle after one jittery RT pull") and ok
	for t: float in [0.7, 1.0, 0.3, 0.0]:
		_update_speed_up(false, t)
	ok = _smoke_speed_is(false, "toggle after a second RT pull") and ok
	for k: bool in [true, true, true, false]:
		_update_speed_up(k, 0.0)
	ok = _smoke_speed_is(true, "toggle after one long F press") and ok
	_open_upgrade_draft()
	ok = _smoke_speed_is(false, "toggle in a level-up draft") and ok
	_pick_draft_card(0)
	_update_speed_up(false, 0.0)
	ok = _smoke_speed_is(true, "toggle carries on after the draft") and ok
	_pause_game()
	ok = _smoke_speed_is(false, "toggle on pause") and ok
	_resume_game()
	_update_speed_up(false, 0.0)
	ok = _smoke_speed_is(false, "toggle off after resuming") and ok
	_update_speed_up(true, 0.0)
	_update_speed_up(false, 0.0)
	_pause_game()
	_open_options_from_pause()
	ok = _smoke_speed_is(false, "options opened from pause") and ok
	_leave_options()
	_retire_from_pause()
	_update_speed_up(false, 0.0)
	ok = _smoke_speed_is(false, "after retiring") and ok
	_start_run()
	_update_intro_warp(1.0)
	_update_intro_warp(1.0)
	_update_speed_up(true, 0.0)
	ok = _smoke_speed_is(true, "toggled on in a new run") and ok
	_enter_title()
	ok = _smoke_speed_is(false, "back on the title screen") and ok
	_update_speed_up(false, 0.0)
	_update_speed_up(true, 0.0)
	ok = _smoke_speed_is(false, "F pressed on the title screen") and ok
	_update_speed_up(false, 0.0)

	# --- OPTIONS row, save and load ---
	_open_options_from_title()
	_opt_speed_btn.pressed.emit()
	if MetaSave.speed_up_toggle or not _opt_speed_btn.text.ends_with("HOLD"):
		push_error("SMOKE: speed-up option row did not switch TOGGLE -> HOLD")
		ok = false
	_opt_speed_btn.pressed.emit()
	if not MetaSave.speed_up_toggle or not _opt_speed_btn.text.ends_with("TOGGLE"):
		push_error("SMOKE: speed-up option row did not switch HOLD -> TOGGLE")
		ok = false
	MetaSave.speed_up_toggle = false
	MetaSave.load_game()
	if not MetaSave.speed_up_toggle:
		push_error("SMOKE: speed-up TOGGLE setting did not survive save + load")
		ok = false
	# A save written before this option existed must load as HOLD.
	var save_r: FileAccess = FileAccess.open(MetaSave.SAVE_PATH, FileAccess.READ)
	var save_data: Variant = JSON.parse_string(save_r.get_as_text()) if save_r != null else null
	if save_r != null:
		save_r.close()
	var save_w: FileAccess = null
	if typeof(save_data) == TYPE_DICTIONARY and (save_data as Dictionary).has("speed_up_toggle"):
		save_w = FileAccess.open(MetaSave.SAVE_PATH, FileAccess.WRITE)
	if save_w == null:
		push_error("SMOKE: speed-up setting missing from the save file, or the save can't be rewritten")
		ok = false
	else:
		(save_data as Dictionary).erase("speed_up_toggle")
		save_w.store_string(JSON.stringify(save_data, "\t"))
		save_w.close()
		MetaSave.load_game()
		if MetaSave.speed_up_toggle:
			push_error("SMOKE: an old save without the speed-up setting did not default to HOLD")
			ok = false
	MetaSave.speed_up_toggle = saved_mode
	MetaSave.save_game()
	_leave_options()
	return ok


# Soundtrack: every alternative track builds and renders finite audio, its composed melodies
# fit the song form, and the picker saves picks, previews, and returns to Options.
func _smoke_check_soundtrack() -> bool:
	var ok: bool = true
	var saved_picks: Dictionary = MetaSave.music_picks.duplicate()
	for slot: String in GenesisMusic.SLOT_KEYS:
		var count: int = GenesisMusic.candidate_count(slot)
		if count != 5:
			push_error("SMOKE: soundtrack slot %s has %d alternatives, expected 5" % [slot, count])
			ok = false
		for idx: int in range(count + 1):
			GenesisMusic.preview(slot, idx)
			var song: Dictionary = GenesisMusic._song
			if idx > 0 and song.is_empty():
				push_error("SMOKE: soundtrack %s #%d did not load" % [slot, idx])
				ok = false
				continue
			if idx > 0 and not song.has("hyper"):
				var want_len: int = int(song.get("bar_steps", 16)) * 8
				for which: String in ["mel_a", "mel_b"]:
					var mel: Array = song[which]
					if mel.size() != want_len:
						push_error("SMOKE: soundtrack %s #%d %s has %d steps, expected %d" % [slot, idx, which, mel.size(), want_len])
						ok = false
			var loudest: float = 0.0
			for start: int in [0, 300]:
				GenesisMusic._step = start
				var buf: PackedVector2Array = GenesisMusic._render_block(2048)
				if buf.size() != 2048:
					push_error("SMOKE: soundtrack %s #%d failed to render" % [slot, idx])
					ok = false
				for v: Vector2 in buf:
					if is_nan(v.x) or is_nan(v.y) or absf(v.x) > 1.0 or absf(v.y) > 1.0:
						push_error("SMOKE: soundtrack %s #%d rendered a bad sample" % [slot, idx])
						ok = false
						break
					loudest = maxf(loudest, absf(v.x))
			if loudest < 0.01:
				push_error("SMOKE: soundtrack %s #%d is silent" % [slot, idx])
				ok = false
	GenesisMusic.end_preview()

	_open_options_from_title()
	_enter_soundtrack()
	if state != State.SOUNDTRACK or not soundtrack_panel.visible:
		push_error("SMOKE: soundtrack picker did not open")
		ok = false
	_snd_row_idx = 0
	_snd_move_row(1) # stage 1
	var before: int = GenesisMusic.get_pick("stage_1")
	_snd_change_track(1)
	var after: int = GenesisMusic.get_pick("stage_1")
	if after != (before + 1) % 6 or int(MetaSave.music_picks.get("stage_1", -1)) != after:
		push_error("SMOKE: soundtrack pick did not change (%d -> %d)" % [before, after])
		ok = false
	if GenesisMusic.current_mode != GenesisMusic.Mode.STAGE or GenesisMusic._preview_slot != "stage_1":
		push_error("SMOKE: soundtrack picker is not previewing stage 1")
		ok = false
	MetaSave.music_picks = {}
	MetaSave.load_game()
	if int(MetaSave.music_picks.get("stage_1", -1)) != after:
		push_error("SMOKE: soundtrack pick did not survive save + load")
		ok = false
	for i: int in range(12):
		_snd_move_row(1)
	_on_snd_row_clicked(0)
	_on_snd_row_clicked(0)
	_leave_soundtrack()
	if state != State.OPTIONS or GenesisMusic._preview_slot != "" or GenesisMusic.current_mode != GenesisMusic.Mode.TITLE:
		push_error("SMOKE: leaving the soundtrack picker did not return to Options and the title music")
		ok = false
	_leave_options()
	MetaSave.music_picks = saved_picks
	GenesisMusic.set_picks(MetaSave.music_picks)
	MetaSave.save_game()
	return ok


func _smoke_speed_is(want_fast: bool, what: String) -> bool:
	var want_scale: float = SPEED_UP_SCALE if want_fast else 1.0
	var want_tps: int = roundi(float(_base_physics_tps) * want_scale)
	if _speed_up_active == want_fast and Engine.time_scale == want_scale and Engine.physics_ticks_per_second == want_tps:
		return true
	push_error("SMOKE: speed-up %s: expected %s, got time_scale %.1f and %d physics ticks" % [
		what, "2x" if want_fast else "1x", Engine.time_scale, Engine.physics_ticks_per_second,
	])
	return false


func _build_world() -> void:
	starfield = StarfieldBg.new()
	add_child(starfield)

	world_root = Node2D.new()
	add_child(world_root)

	pickup_layer = Node2D.new()
	world_root.add_child(pickup_layer)

	enemy_layer = Node2D.new()
	world_root.add_child(enemy_layer)

	player = PlayerShip.new()
	world_root.add_child(player)
	player.visible = false

	bullet_layer = Node2D.new()
	world_root.add_child(bullet_layer)

	fx_layer = FxLayer.new()
	world_root.add_child(fx_layer)

	player.bullet_container = bullet_layer
	player.fx = fx_layer
	player.hp_changed.connect(_on_player_hp_changed)
	player.player_died.connect(_on_player_died)
	player.grazed.connect(_on_player_grazed)
	player.touch_state_changed.connect(_sync_touch_hud_visibility)


func _make_ff6_box(bg: Color = Color(0.06, 0.10, 0.34, 0.94), border: Color = Color("#dce6ff"), border_w: int = 2, margin: float = 4.0) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(2)
	sb.set_content_margin_all(margin)
	return sb


func _style_menu_btn(btn: Button, accent: Color = Color("#dce6ff")) -> void:
	btn.add_theme_font_size_override("font_size", FONT_SZ)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color("#ffe854"))
	btn.add_theme_color_override("font_focus_color", Color("#ffe854"))
	btn.add_theme_color_override("font_disabled_color", Color("#586c96"))
	btn.add_theme_stylebox_override("normal", _make_ff6_box(Color("#0d1746"), Color("#9ab0de"), 1, 2.0))
	btn.add_theme_stylebox_override("hover", _make_ff6_box(Color("#192b73"), accent, 2, 2.0))
	btn.add_theme_stylebox_override("focus", _make_ff6_box(Color("#192b73"), accent, 2, 2.0))
	btn.add_theme_stylebox_override("pressed", _make_ff6_box(Color("#253f9e"), Color.WHITE, 2, 2.0))
	btn.add_theme_stylebox_override("disabled", _make_ff6_box(Color("#080d28"), Color("#3c4c70"), 1, 2.0))


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	hud_bar = Control.new()
	hud_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_bar.draw.connect(_draw_hud)
	ui_layer.add_child(hud_bar)

	pause_hud_btn = Button.new()
	pause_hud_btn.position = Vector2(436.0, 2.0)
	pause_hud_btn.size = Vector2(40.0, 15.0)
	pause_hud_btn.text = "II"
	pause_hud_btn.focus_mode = Control.FOCUS_NONE
	_style_menu_btn(pause_hud_btn, Color("#ffe854"))
	pause_hud_btn.pressed.connect(func() -> void:
		if state == State.PLAYING:
			_pause_game()
		elif state == State.PAUSED:
			_resume_game()
	)
	ui_layer.add_child(pause_hud_btn)

	touch_focus_btn = Button.new()
	touch_focus_btn.position = Vector2(412.0, 228.0)
	touch_focus_btn.size = Vector2(62.0, 26.0)
	touch_focus_btn.text = "FOCUS"
	touch_focus_btn.focus_mode = Control.FOCUS_NONE
	_style_menu_btn(touch_focus_btn, Color("#28e8ff"))
	touch_focus_btn.button_down.connect(func() -> void: player.touch_focus_held = true)
	touch_focus_btn.button_up.connect(func() -> void: player.touch_focus_held = false)
	touch_focus_btn.visible = false
	ui_layer.add_child(touch_focus_btn)

	banner_label = Label.new()
	banner_label.position = Vector2(0.0, 42.0)
	banner_label.size = Vector2(VIEW_W, 28.0)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", FONT_SZ)
	banner_label.add_theme_color_override("font_color", Color("#ffe854"))
	banner_label.visible = false
	ui_layer.add_child(banner_label)

	_build_title_ui()
	_build_stats_ui()
	_build_options_ui()
	_build_soundtrack_ui()
	_build_skill_tree_ui()
	_build_loadout_ui()
	_build_draft_ui()
	_build_pause_ui()


func _build_title_ui() -> void:
	title_panel = Control.new()
	title_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(title_panel)

	var logo: Label = Label.new()
	logo.position = Vector2(28.0, 22.0)
	logo.size = Vector2(340.0, 30.0)
	logo.text = "STAR VIPER"
	logo.add_theme_font_size_override("font_size", 20)
	logo.add_theme_color_override("font_color", Color("#28e8ff"))
	title_panel.add_child(logo)

	var sub: Label = Label.new()
	sub.position = Vector2(30.0, 50.0)
	sub.size = Vector2(320.0, 16.0)
	sub.text = "16-BIT GALACTIC ROGUELITE"
	sub.add_theme_font_size_override("font_size", FONT_SZ)
	sub.add_theme_color_override("font_color", Color("#ffe854"))
	title_panel.add_child(sub)

	_title_ship_sprite = Sprite2D.new()
	_title_ship_sprite.texture = PixelArt.tex("player_idle")
	_title_ship_sprite.scale = Vector2(3.0, 3.0)
	_title_ship_sprite.position = Vector2(356.0, 134.0)
	title_panel.add_child(_title_ship_sprite)

	var menu_specs: Array[Dictionary] = [
		{"label": "START RUN", "cb": _start_run, "accent": Color("#3ce878")},
		{"label": "SKILL TREE", "cb": _open_hangar_from_title, "accent": Color("#ffe854")},
		{"label": "SHIP LOADOUT", "cb": _enter_loadout, "accent": Color("#ff64b8")},
		{"label": "STATS", "cb": _enter_stats, "accent": Color("#28e8ff")},
		{"label": "OPTIONS", "cb": _open_options_from_title, "accent": Color("#d46bff")},
		{"label": "QUIT GAME", "cb": _quit_desktop, "accent": Color("#ff4c68")},
	]

	_title_menu_btns.clear()
	for i: int in range(menu_specs.size()):
		var spec: Dictionary = menu_specs[i]
		var btn: Button = Button.new()
		btn.position = Vector2(30.0, 72.0 + float(i) * 25.0)
		btn.size = Vector2(214.0, 22.0)
		btn.text = String(spec["label"])
		_style_menu_btn(btn, spec["accent"])
		var callback: Callable = spec["cb"]
		btn.pressed.connect(func() -> void:
			RetroSfx.play("ui", -7.0, 0.02)
			callback.call()
		)
		title_panel.add_child(btn)
		_title_menu_btns.append(btn)
		if i == 0:
			_title_start_btn = btn
		elif i == 1:
			_title_tree_btn = btn
		elif i == 2:
			_title_loadout_btn = btn

	# Controls legend: shows key caps or Xbox buttons for whichever device was used last.
	var foot: PromptBar = PromptBar.new()
	foot.position = Vector2(30.0, 230.0)
	foot.size = Vector2(430.0, 16.0)
	foot.text_color = Color("#9ab6e8")
	foot.set_segments([
		"MOVE ", {"act": "move"}, "  FIRE ", {"act": "fire"}, "  FOCUS ", {"act": "focus"},
		"  AUTOFIRE ", {"act": "autofire"}, "  PAUSE ", {"act": "pause"}, "  SPEED UP ", {"act": "speed"},
	])
	title_panel.add_child(foot)


func _build_stats_ui() -> void:
	stats_panel = Control.new()
	stats_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_panel.visible = false
	ui_layer.add_child(stats_panel)

	var card: Panel = Panel.new()
	card.position = Vector2(40.0, 18.0)
	card.size = Vector2(400.0, 224.0)
	card.add_theme_stylebox_override("panel", _make_ff6_box())
	stats_panel.add_child(card)

	var hdr: Label = Label.new()
	hdr.position = Vector2(58.0, 28.0)
	hdr.size = Vector2(364.0, 16.0)
	hdr.text = "PILOT SERVICE RECORD"
	hdr.add_theme_font_size_override("font_size", FONT_SZ)
	hdr.add_theme_color_override("font_color", Color("#ffe854"))
	stats_panel.add_child(hdr)

	_stats_body_lbl = Label.new()
	_stats_body_lbl.position = Vector2(58.0, 52.0)
	_stats_body_lbl.size = Vector2(364.0, 138.0)
	_stats_body_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_stats_body_lbl.add_theme_color_override("font_color", Color.WHITE)
	stats_panel.add_child(_stats_body_lbl)

	_stats_back_btn = Button.new()
	_stats_back_btn.position = Vector2(176.0, 204.0)
	_stats_back_btn.size = Vector2(128.0, 26.0)
	_stats_back_btn.text = "BACK"
	_style_menu_btn(_stats_back_btn)
	InputPrompts.bind_button(_stats_back_btn, "back")
	_stats_back_btn.pressed.connect(func() -> void:
		RetroSfx.play("ui", -7.0, 0.02)
		_enter_title()
	)
	stats_panel.add_child(_stats_back_btn)


func _build_options_ui() -> void:
	options_panel = Control.new()
	options_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	options_panel.visible = false
	ui_layer.add_child(options_panel)

	var card: Panel = Panel.new()
	card.position = Vector2(32.0, 10.0)
	card.size = Vector2(416.0, 250.0)
	card.add_theme_stylebox_override("panel", _make_ff6_box())
	options_panel.add_child(card)

	var hdr: Label = Label.new()
	hdr.position = Vector2(50.0, 17.0)
	hdr.size = Vector2(380.0, 16.0)
	hdr.text = "CONFIGURATION"
	hdr.add_theme_font_size_override("font_size", FONT_SZ)
	hdr.add_theme_color_override("font_color", Color("#ffe854"))
	options_panel.add_child(hdr)

	_opt_music_lbl = Label.new()
	_opt_music_lbl.position = Vector2(50.0, 42.0)
	_opt_music_lbl.size = Vector2(220.0, 20.0)
	_opt_music_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	options_panel.add_child(_opt_music_lbl)

	var m_minus: Button = Button.new()
	m_minus.position = Vector2(292.0, 38.0)
	m_minus.size = Vector2(60.0, 22.0)
	m_minus.text = "-10%"
	_style_menu_btn(m_minus)
	m_minus.pressed.connect(func() -> void: _adjust_music(-0.10))
	options_panel.add_child(m_minus)

	var m_plus: Button = Button.new()
	m_plus.position = Vector2(360.0, 38.0)
	m_plus.size = Vector2(60.0, 22.0)
	m_plus.text = "+10%"
	_style_menu_btn(m_plus)
	m_plus.pressed.connect(func() -> void: _adjust_music(0.10))
	options_panel.add_child(m_plus)

	_opt_sfx_lbl = Label.new()
	_opt_sfx_lbl.position = Vector2(50.0, 68.0)
	_opt_sfx_lbl.size = Vector2(220.0, 20.0)
	_opt_sfx_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	options_panel.add_child(_opt_sfx_lbl)

	var s_minus: Button = Button.new()
	s_minus.position = Vector2(292.0, 64.0)
	s_minus.size = Vector2(60.0, 22.0)
	s_minus.text = "-10%"
	_style_menu_btn(s_minus)
	s_minus.pressed.connect(func() -> void: _adjust_sfx(-0.10))
	options_panel.add_child(s_minus)

	var s_plus: Button = Button.new()
	s_plus.position = Vector2(360.0, 64.0)
	s_plus.size = Vector2(60.0, 22.0)
	s_plus.text = "+10%"
	_style_menu_btn(s_plus)
	s_plus.pressed.connect(func() -> void: _adjust_sfx(0.10))
	options_panel.add_child(s_plus)

	_opt_autofire_btn = Button.new()
	_opt_autofire_btn.position = Vector2(50.0, 94.0)
	_opt_autofire_btn.size = Vector2(370.0, 23.0)
	_style_menu_btn(_opt_autofire_btn)
	_opt_autofire_btn.pressed.connect(func() -> void:
		MetaSave.default_autofire = not MetaSave.default_autofire
		player.auto_fire_toggle = MetaSave.default_autofire
		MetaSave.save_game()
		RetroSfx.play("ui", -7.0, 0.02)
		_refresh_options_ui()
	)
	options_panel.add_child(_opt_autofire_btn)

	_opt_shake_btn = Button.new()
	_opt_shake_btn.position = Vector2(50.0, 121.0)
	_opt_shake_btn.size = Vector2(370.0, 23.0)
	_style_menu_btn(_opt_shake_btn)
	_opt_shake_btn.pressed.connect(func() -> void:
		MetaSave.screen_shake_enabled = not MetaSave.screen_shake_enabled
		MetaSave.save_game()
		RetroSfx.play("ui", -7.0, 0.02)
		_refresh_options_ui()
	)
	options_panel.add_child(_opt_shake_btn)

	_opt_touch_btn = Button.new()
	_opt_touch_btn.position = Vector2(50.0, 148.0)
	_opt_touch_btn.size = Vector2(370.0, 23.0)
	_style_menu_btn(_opt_touch_btn)
	_opt_touch_btn.pressed.connect(func() -> void:
		MetaSave.touch_mode = (MetaSave.touch_mode + 1) % 3
		MetaSave.save_game()
		RetroSfx.play("ui", -7.0, 0.02)
		_refresh_options_ui()
		_sync_touch_hud_visibility()
	)
	options_panel.add_child(_opt_touch_btn)

	_opt_fullscreen_btn = Button.new()
	_opt_fullscreen_btn.position = Vector2(50.0, 175.0)
	_opt_fullscreen_btn.size = Vector2(370.0, 23.0)
	_style_menu_btn(_opt_fullscreen_btn)
	_opt_fullscreen_btn.pressed.connect(func() -> void:
		MetaSave.fullscreen_enabled = not MetaSave.fullscreen_enabled
		MetaSave.apply_audio_and_display_settings()
		MetaSave.save_game()
		RetroSfx.play("ui", -7.0, 0.02)
		_refresh_options_ui()
	)
	options_panel.add_child(_opt_fullscreen_btn)

	_opt_speed_btn = Button.new()
	_opt_speed_btn.position = Vector2(50.0, 202.0)
	_opt_speed_btn.size = Vector2(370.0, 23.0)
	_style_menu_btn(_opt_speed_btn)
	_opt_speed_btn.pressed.connect(func() -> void:
		MetaSave.speed_up_toggle = not MetaSave.speed_up_toggle
		_speed_toggle_on = false
		MetaSave.save_game()
		RetroSfx.play("ui", -7.0, 0.02)
		_refresh_options_ui()
	)
	options_panel.add_child(_opt_speed_btn)

	var reset_btn: Button = Button.new()
	reset_btn.position = Vector2(50.0, 229.0)
	reset_btn.size = Vector2(116.0, 26.0)
	reset_btn.text = "RESET SAVE"
	_style_menu_btn(reset_btn, Color("#ff4c68"))
	reset_btn.pressed.connect(func() -> void:
		MetaSave.reset_save()
		RetroSfx.play("explode", -8.0, 0.02)
		_refresh_options_ui()
	)
	options_panel.add_child(reset_btn)

	_opt_soundtrack_btn = Button.new()
	_opt_soundtrack_btn.position = Vector2(172.0, 229.0)
	_opt_soundtrack_btn.size = Vector2(128.0, 26.0)
	_opt_soundtrack_btn.text = "SOUNDTRACK"
	_style_menu_btn(_opt_soundtrack_btn, Color("#ffe854"))
	_opt_soundtrack_btn.pressed.connect(_enter_soundtrack)
	options_panel.add_child(_opt_soundtrack_btn)

	var back_btn: Button = Button.new()
	back_btn.position = Vector2(306.0, 229.0)
	back_btn.size = Vector2(114.0, 26.0)
	back_btn.text = "BACK"
	_style_menu_btn(back_btn)
	InputPrompts.bind_button(back_btn, "back")
	back_btn.pressed.connect(_leave_options)
	options_panel.add_child(back_btn)


func _build_soundtrack_ui() -> void:
	soundtrack_panel = Control.new()
	soundtrack_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	soundtrack_panel.visible = false
	ui_layer.add_child(soundtrack_panel)

	var card: Panel = Panel.new()
	card.position = Vector2(32.0, 10.0)
	card.size = Vector2(416.0, 250.0)
	card.add_theme_stylebox_override("panel", _make_ff6_box())
	soundtrack_panel.add_child(card)

	var hdr: Label = Label.new()
	hdr.position = Vector2(50.0, 15.0)
	hdr.size = Vector2(380.0, 14.0)
	hdr.text = "SOUNDTRACK: PICK ONE TRACK PER SLOT"
	hdr.add_theme_font_size_override("font_size", FONT_SZ)
	hdr.add_theme_color_override("font_color", Color("#ffe854"))
	soundtrack_panel.add_child(hdr)

	_snd_cursor = ColorRect.new()
	_snd_cursor.size = Vector2(388.0, 15.0)
	_snd_cursor.color = Color(0.16, 0.42, 1.0, 0.38)
	_snd_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	soundtrack_panel.add_child(_snd_cursor)

	for i: int in range(GenesisMusic.SLOT_KEYS.size()):
		var y: float = 32.0 + float(i) * 16.0
		var row: Button = Button.new()
		row.position = Vector2(46.0, y)
		row.size = Vector2(388.0, 15.0)
		row.flat = true
		row.focus_mode = Control.FOCUS_NONE
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.text = _snd_slot_label(i)
		row.add_theme_font_size_override("font_size", FONT_SZ)
		row.add_theme_color_override("font_color", Color("#dce6ff"))
		row.add_theme_color_override("font_hover_color", Color.WHITE)
		row.add_theme_color_override("font_pressed_color", Color("#ffe854"))
		row.pressed.connect(_on_snd_row_clicked.bind(i))
		soundtrack_panel.add_child(row)
		_snd_row_btns.append(row)

		var val: Label = Label.new()
		val.position = Vector2(176.0, y)
		val.size = Vector2(256.0, 15.0)
		val.mouse_filter = Control.MOUSE_FILTER_IGNORE
		val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		val.add_theme_font_size_override("font_size", FONT_SZ)
		soundtrack_panel.add_child(val)
		_snd_value_lbls.append(val)

	_snd_info_lbl = Label.new()
	_snd_info_lbl.position = Vector2(50.0, 210.0)
	_snd_info_lbl.size = Vector2(380.0, 14.0)
	_snd_info_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_snd_info_lbl.add_theme_color_override("font_color", Color("#28e8ff"))
	soundtrack_panel.add_child(_snd_info_lbl)

	var foot: PromptBar = PromptBar.new()
	foot.position = Vector2(50.0, 233.0)
	foot.size = Vector2(260.0, 16.0)
	foot.text_color = Color("#9ab6e8")
	foot.set_segments([{"act": "move"}, " CHOOSE   ", {"act": "confirm"}, " REPLAY"])
	soundtrack_panel.add_child(foot)

	_snd_back_btn = Button.new()
	_snd_back_btn.position = Vector2(326.0, 229.0)
	_snd_back_btn.size = Vector2(94.0, 24.0)
	_snd_back_btn.text = "BACK"
	_style_menu_btn(_snd_back_btn)
	_snd_back_btn.focus_mode = Control.FOCUS_NONE
	InputPrompts.bind_button(_snd_back_btn, "back")
	_snd_back_btn.pressed.connect(_leave_soundtrack)
	soundtrack_panel.add_child(_snd_back_btn)


func _snd_slot_label(i: int) -> String:
	var slot: String = GenesisMusic.SLOT_KEYS[i]
	if slot.begins_with("stage_"):
		var st: int = int(slot.substr(6))
		var st_def: Dictionary = StageData.get_stage(st - 1)
		return "S%d %s" % [st, String(st_def["name"])]
	match slot:
		"title":
			return "TITLE & MENUS"
		"boss":
			return "BOSS FIGHTS"
		"hyperspace":
			return "HYPERSPACE JUMP"
	return slot.to_upper()


func _enter_soundtrack() -> void:
	RetroSfx.play("ui", -7.0, 0.02)
	# Remember what was playing (title, or the paused run's stage/boss) to resume it on the way out.
	_snd_resume_mode = GenesisMusic.current_mode
	_snd_resume_stage = GenesisMusic.current_stage_idx
	options_panel.visible = false
	soundtrack_panel.visible = true
	state = State.SOUNDTRACK
	_refresh_soundtrack_ui()
	_snd_preview_current()


func _leave_soundtrack() -> void:
	RetroSfx.play("ui", -7.0, 0.02)
	GenesisMusic.end_preview()
	soundtrack_panel.visible = false
	options_panel.visible = true
	state = State.OPTIONS
	# Pick up any changed pick right away: restart whatever was playing before.
	match _snd_resume_mode:
		GenesisMusic.Mode.STAGE, GenesisMusic.Mode.BOSS, GenesisMusic.Mode.HYPERSPACE:
			GenesisMusic.resume_after_preview(_snd_resume_mode, _snd_resume_stage)
			GenesisMusic.set_paused_duck(true)
		_:
			GenesisMusic.resume_after_preview(GenesisMusic.Mode.TITLE, 0)
	_opt_soundtrack_btn.grab_focus()


func _refresh_soundtrack_ui() -> void:
	for i: int in range(_snd_row_btns.size()):
		var slot: String = GenesisMusic.SLOT_KEYS[i]
		var idx: int = GenesisMusic.get_pick(slot)
		var sel: bool = i == _snd_row_idx
		var name_txt: String = GenesisMusic.candidate_name(slot, idx)
		_snd_value_lbls[i].text = ("< %s >" % name_txt) if idx == 0 else ("< #%d  %s >" % [idx, name_txt])
		_snd_value_lbls[i].add_theme_color_override("font_color", Color("#ffe854") if sel else (Color("#9ab6e8") if idx == 0 else Color("#dce6ff")))
	_snd_cursor.position = Vector2(46.0, 32.0 + float(_snd_row_idx) * 16.0)
	var cur_slot: String = GenesisMusic.SLOT_KEYS[_snd_row_idx]
	var cur_idx: int = GenesisMusic.get_pick(cur_slot)
	_snd_info_lbl.text = "%d/%d  %s" % [cur_idx, GenesisMusic.candidate_count(cur_slot), GenesisMusic.candidate_info(cur_slot, cur_idx)]


func _snd_preview_current() -> void:
	var slot: String = GenesisMusic.SLOT_KEYS[_snd_row_idx]
	GenesisMusic.preview(slot, GenesisMusic.get_pick(slot))
	_snd_hyper_timer = 0.0


func _snd_move_row(dir: int) -> void:
	var n: int = GenesisMusic.SLOT_KEYS.size()
	_snd_row_idx = posmod(_snd_row_idx + dir, n)
	RetroSfx.play("ui", -11.0, 0.03)
	_refresh_soundtrack_ui()
	_snd_preview_current()


func _snd_change_track(dir: int) -> void:
	var slot: String = GenesisMusic.SLOT_KEYS[_snd_row_idx]
	var count: int = GenesisMusic.candidate_count(slot) + 1
	var idx: int = posmod(GenesisMusic.get_pick(slot) + dir, count)
	MetaSave.music_picks[slot] = idx
	GenesisMusic.set_picks(MetaSave.music_picks)
	MetaSave.save_game()
	_refresh_soundtrack_ui()
	_snd_preview_current()


# Mouse / touch: tap a row to select it (and hear it); tap the selected row again for its next track.
func _on_snd_row_clicked(i: int) -> void:
	if i == _snd_row_idx:
		_snd_change_track(1)
	else:
		_snd_row_idx = i
		RetroSfx.play("ui", -11.0, 0.03)
		_refresh_soundtrack_ui()
		_snd_preview_current()


func _leave_options() -> void:
	RetroSfx.play("ui", -7.0, 0.02)
	if _options_from_pause:
		_options_from_pause = false
		options_panel.visible = false
		hud_bar.visible = true
		pause_hud_btn.visible = true
		pause_panel.visible = true
		state = State.PAUSED
		_pause_resume_btn.grab_focus()
	else:
		_enter_title()


# =================================================================================
# ROGUE LEGACY-STYLE 30-NODE PANNABLE STARFORGE SKILL TREE!
# =================================================================================
func _build_skill_tree_ui() -> void:
	hangar_panel = Control.new()
	hangar_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	hangar_panel.visible = false
	ui_layer.add_child(hangar_panel)

	var top_bar: Panel = Panel.new()
	top_bar.position = Vector2(6.0, 4.0)
	top_bar.size = Vector2(468.0, 22.0)
	top_bar.add_theme_stylebox_override("panel", _make_ff6_box(Color("#081030"), Color("#9ab6e8"), 1, 2.0))
	hangar_panel.add_child(top_bar)

	var title_lbl: Label = Label.new()
	title_lbl.position = Vector2(14.0, 8.0)
	title_lbl.size = Vector2(170.0, 14.0)
	title_lbl.text = "STARFORGE SKILL TREE"
	title_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	title_lbl.add_theme_color_override("font_color", Color("#ffe854"))
	hangar_panel.add_child(title_lbl)

	_tree_summary_lbl = Label.new()
	_tree_summary_lbl.position = Vector2(162.0, 8.0)
	_tree_summary_lbl.size = Vector2(186.0, 14.0)
	_tree_summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tree_summary_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_tree_summary_lbl.add_theme_color_override("font_color", Color("#9ab6e8"))
	hangar_panel.add_child(_tree_summary_lbl)

	_tree_scrap_lbl = Label.new()
	_tree_scrap_lbl.position = Vector2(342.0, 8.0)
	_tree_scrap_lbl.size = Vector2(124.0, 14.0)
	_tree_scrap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tree_scrap_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_tree_scrap_lbl.add_theme_color_override("font_color", Color("#3ce878"))
	hangar_panel.add_child(_tree_scrap_lbl)

	# Pannable Interactive Blueprint Canvas (y = 28..202)
	var canvas_frame: Panel = Panel.new()
	canvas_frame.position = Vector2(6.0, 28.0)
	canvas_frame.size = Vector2(468.0, 174.0)
	canvas_frame.add_theme_stylebox_override("panel", _make_ff6_box(Color(0.02, 0.04, 0.14, 0.94), Color("#5c7cc4"), 1, 0.0))
	hangar_panel.add_child(canvas_frame)

	_tree_canvas = Control.new()
	_tree_canvas.position = Vector2(7.0, 29.0)
	_tree_canvas.size = Vector2(466.0, 172.0)
	_tree_canvas.clip_contents = true
	_tree_canvas.draw.connect(_draw_skill_tree_canvas)
	_tree_canvas.gui_input.connect(_on_tree_canvas_gui_input)
	hangar_panel.add_child(_tree_canvas)

	# Bottom Node Inspector & Action Dock (y = 204..266)
	var bot_box: Panel = Panel.new()
	bot_box.position = Vector2(6.0, 204.0)
	bot_box.size = Vector2(468.0, 62.0)
	bot_box.add_theme_stylebox_override("panel", _make_ff6_box(Color("#081034"), Color("#dce6ff"), 1, 3.0))
	hangar_panel.add_child(bot_box)

	_tree_node_title_lbl = Label.new()
	_tree_node_title_lbl.position = Vector2(14.0, 206.0)
	_tree_node_title_lbl.size = Vector2(310.0, 14.0)
	_tree_node_title_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_tree_node_title_lbl.add_theme_color_override("font_color", Color("#ffe854"))
	hangar_panel.add_child(_tree_node_title_lbl)

	_tree_node_desc_lbl = Label.new()
	_tree_node_desc_lbl.position = Vector2(14.0, 217.0)
	_tree_node_desc_lbl.size = Vector2(314.0, 22.0)
	_tree_node_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tree_node_desc_lbl.add_theme_constant_override("line_spacing", 0)
	_tree_node_desc_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_tree_node_desc_lbl.add_theme_color_override("font_color", Color.WHITE)
	hangar_panel.add_child(_tree_node_desc_lbl)

	_tree_buy_btn = Button.new()
	_tree_buy_btn.position = Vector2(332.0, 208.0)
	_tree_buy_btn.size = Vector2(136.0, 26.0)
	_tree_buy_btn.focus_mode = Control.FOCUS_NONE
	_style_menu_btn(_tree_buy_btn, Color("#ffe854"))
	_tree_buy_btn.pressed.connect(_on_buy_tree_node)
	hangar_panel.add_child(_tree_buy_btn)

	var t_title_btn: Button = Button.new()
	t_title_btn.position = Vector2(14.0, 239.0)
	t_title_btn.size = Vector2(92.0, 22.0)
	t_title_btn.focus_mode = Control.FOCUS_NONE
	t_title_btn.text = "TITLE"
	_style_menu_btn(t_title_btn)
	InputPrompts.bind_button(t_title_btn, "back")
	t_title_btn.pressed.connect(func() -> void:
		RetroSfx.play("ui", -7.0, 0.02)
		_enter_title()
	)
	hangar_panel.add_child(t_title_btn)

	var t_loadout_btn: Button = Button.new()
	t_loadout_btn.position = Vector2(114.0, 239.0)
	t_loadout_btn.size = Vector2(174.0, 22.0)
	t_loadout_btn.focus_mode = Control.FOCUS_NONE
	t_loadout_btn.text = "SHIP LOADOUT"
	_style_menu_btn(t_loadout_btn, Color("#ff64b8"))
	InputPrompts.bind_button(t_loadout_btn, "swap_menu")
	t_loadout_btn.pressed.connect(func() -> void:
		RetroSfx.play("ui", -7.0, 0.02)
		_enter_loadout()
	)
	hangar_panel.add_child(t_loadout_btn)

	var t_launch_btn: Button = Button.new()
	t_launch_btn.position = Vector2(296.0, 239.0)
	t_launch_btn.size = Vector2(172.0, 22.0)
	t_launch_btn.focus_mode = Control.FOCUS_NONE
	t_launch_btn.text = "LAUNCH RUN"
	_style_menu_btn(t_launch_btn, Color("#3ce878"))
	InputPrompts.bind_button(t_launch_btn, "launch")
	t_launch_btn.pressed.connect(_start_run)
	hangar_panel.add_child(t_launch_btn)


func _draw_skill_tree_canvas() -> void:
	var font: Font = PixelArt.ui_font if PixelArt.ui_font != null else ThemeDB.fallback_font
	var c_size: Vector2 = _tree_canvas.size
	var origin: Vector2 = (c_size * 0.5 - _tree_cam_offset).round()

	# 1) Blueprint Coordinate Grid
	var grid_step: float = 32.0
	var gx_start: float = fposmod(origin.x, grid_step)
	var gy_start: float = fposmod(origin.y, grid_step)
	var gx: float = gx_start
	while gx < c_size.x:
		_tree_canvas.draw_line(Vector2(gx, 0.0), Vector2(gx, c_size.y), Color(0.14, 0.22, 0.45, 0.35), 1.0)
		gx += grid_step
	var gy: float = gy_start
	while gy < c_size.y:
		_tree_canvas.draw_line(Vector2(0.0, gy), Vector2(c_size.x, gy), Color(0.14, 0.22, 0.45, 0.35), 1.0)
		gy += grid_step

	# 2) Directional Wing Labels
	_tree_canvas.draw_string(font, origin + Vector2(-46.0, -34.0), "NORTH: HULL & SHIELDS", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color(0.94, 0.35, 0.45, 0.55))
	_tree_canvas.draw_string(font, origin + Vector2(30.0, -16.0), "EAST: WEAPON MODS", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color(1.0, 0.65, 0.25, 0.55))
	_tree_canvas.draw_string(font, origin + Vector2(-46.0, 44.0), "SOUTH: SCRAP & XP", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color(1.0, 0.91, 0.33, 0.55))
	_tree_canvas.draw_string(font, origin + Vector2(-132.0, -16.0), "WEST: WEIRD LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color(1.0, 0.38, 0.78, 0.55))

	# 3) Parent -> Child Conduits
	for def: Dictionary in SkillTreeData.NODES:
		var p_id: String = String(def["parent"])
		if p_id == "":
			continue
		var p_def: Dictionary = SkillTreeData.get_node_def(p_id)
		if p_def.is_empty():
			continue
		var id: String = String(def["id"])
		var pa: Vector2 = origin + Vector2(p_def["pos"])
		var pb: Vector2 = origin + Vector2(def["pos"])
		var child_lvl: int = MetaSave.get_level(id)
		var revealed: bool = MetaSave.is_node_revealed(id)
		var line_col: Color = Color(0.18, 0.24, 0.42, 0.55)
		var line_w: float = 1.0
		if child_lvl > 0:
			var ncol: Color = def["color"]
			line_col = Color(ncol.r, ncol.g, ncol.b, 0.92)
			line_w = 2.0
		elif revealed:
			line_col = Color(0.55, 0.75, 1.0, 0.72)
			line_w = 1.5
		_tree_canvas.draw_line(pa, pb, line_col, line_w)

	# 4) Visual Skill Tree Nodes (24x24 icon boxes + rank indicators + selection cursor)
	var pulse: float = 0.55 + 0.45 * sin(float(Time.get_ticks_msec()) * 0.008)
	for def: Dictionary in SkillTreeData.NODES:
		var id: String = String(def["id"])
		var np: Vector2 = origin + Vector2(def["pos"])
		if np.x < -30.0 or np.x > c_size.x + 30.0 or np.y < -30.0 or np.y > c_size.y + 30.0:
			continue

		var lvl: int = MetaSave.get_level(id)
		var max_lvl: int = int(def["max_level"])
		var revealed: bool = MetaSave.is_node_revealed(id)
		var affordable: bool = MetaSave.can_buy_node(id)
		var ncol: Color = def["color"]
		var is_ship_node: bool = String(def.get("unlocks_ship", "")) != ""
		var half: float = 13.0 if is_ship_node else 11.0
		var box_r: Rect2 = Rect2(np.x - half, np.y - half, half * 2.0, half * 2.0)

		var bg_col: Color = Color("#090f26")
		var border_col: Color = Color("#2c3a60")
		if lvl >= max_lvl:
			bg_col = ncol.darkened(0.68)
			border_col = ncol.lightened(0.25)
		elif lvl > 0:
			bg_col = Color("#122254")
			border_col = ncol
		elif affordable:
			bg_col = Color("#122844")
			border_col = Color("#3ce878").lerp(Color("#ffe854"), pulse)
		elif revealed:
			bg_col = Color("#0d1838")
			border_col = Color("#6c88c4")

		_tree_canvas.draw_rect(box_r, bg_col)
		_tree_canvas.draw_rect(box_r, border_col, false, 2.0 if (lvl > 0 or affordable or is_ship_node) else 1.0)
		if String(def.get("unlocks_upgrade", "")) != "":
			_draw_tree_card_tag(Vector2(box_r.end.x - 3.0, box_r.position.y - 3.0), lvl > 0)

		if revealed or lvl > 0:
			var icon_tex: Texture2D = PixelArt.tex(String(def["icon"]))
			if icon_tex != null:
				_tree_canvas.draw_texture(icon_tex, (np - Vector2(5.0, 5.0)).round())
			if id != "core_root":
				# (The FF6 bitmap font has no star glyph, so maxed nodes say MAX.)
				var r_str: String = "MAX" if lvl >= max_lvl else "%d/%d" % [lvl, max_lvl]
				var r_col: Color = Color("#ffe854") if lvl >= max_lvl else (Color.WHITE if lvl > 0 else Color("#8ca8dc"))
				_tree_canvas.draw_string(font, Vector2(np.x - 9.0, np.y + half + 9.0), r_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, r_col)
		else:
			_tree_canvas.draw_string(font, Vector2(np.x - 3.0, np.y + 4.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#4e6294"))

		if id == _tree_selected_id:
			var sel_r: Rect2 = box_r.grow(3.0)
			_tree_canvas.draw_rect(sel_r, Color.WHITE, false, 2.0)

	# 5) Legend for DRAFT CARD nodes (fixed in the canvas corner, on a backing so nodes behind don't clash)
	var legend: String = "= NEW DRAFT CARD"
	var legend_w: float = font.get_string_size(legend, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ).x
	_tree_canvas.draw_rect(Rect2(2.0, c_size.y - 15.0, legend_w + 17.0, 13.0), Color(0.02, 0.04, 0.14, 0.88))
	_draw_tree_card_tag(Vector2(5.0, c_size.y - 13.0), true)
	_tree_canvas.draw_string(font, Vector2(14.0, c_size.y - 5.0), legend, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color(0.75, 0.82, 1.0, 0.85))


# Small playing-card glyph marking skill tree nodes that add a draft upgrade.
func _draw_tree_card_tag(top_left: Vector2, owned: bool) -> void:
	var r: Rect2 = Rect2(top_left.round(), Vector2(6.0, 8.0))
	_tree_canvas.draw_rect(r, Color("#ffe854") if owned else Color("#2c3a60"))
	_tree_canvas.draw_rect(r, Color.WHITE if owned else Color("#8ca8dc"), false, 1.0)
	_tree_canvas.draw_rect(Rect2(r.position + Vector2(2.0, 3.0), Vector2(2.0, 2.0)), Color("#d44cff") if owned else Color("#6c88c4"))


func _on_tree_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_tree_dragging = true
				_tree_drag_moved = false
			else:
				if _tree_dragging and not _tree_drag_moved:
					_click_tree_at(mb.position)
				_tree_dragging = false
	elif event is InputEventMouseMotion and _tree_dragging:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if mm.relative.length_squared() > 1.5:
			_tree_drag_moved = true
		_tree_cam_offset -= mm.relative
		_tree_canvas.queue_redraw()


func _click_tree_at(local_pos: Vector2) -> void:
	var origin: Vector2 = _tree_canvas.size * 0.5 - _tree_cam_offset
	for def: Dictionary in SkillTreeData.NODES:
		var id: String = String(def["id"])
		var np: Vector2 = origin + Vector2(def["pos"])
		if local_pos.distance_to(np) <= 15.0:
			if _tree_selected_id == id and MetaSave.can_buy_node(id):
				_on_buy_tree_node()
			else:
				_tree_selected_id = id
				RetroSfx.play("ui", -10.0, 0.03)
				_refresh_skill_tree_ui()
			return


func _move_tree_selection(dir: Vector2) -> void:
	if dir.length_squared() < 0.05:
		return
	var cur_def: Dictionary = SkillTreeData.get_node_def(_tree_selected_id)
	if cur_def.is_empty():
		_tree_selected_id = "core_root"
		_refresh_skill_tree_ui()
		return
	var cur_pos: Vector2 = cur_def["pos"]
	var norm_dir: Vector2 = dir.normalized()
	var best_id: String = ""
	var best_score: float = 999999.0

	for def: Dictionary in SkillTreeData.NODES:
		var cid: String = String(def["id"])
		if cid == _tree_selected_id:
			continue
		var delta_v: Vector2 = Vector2(def["pos"]) - cur_pos
		var dist: float = delta_v.length()
		if dist < 1.0:
			continue
		var align: float = norm_dir.dot(delta_v / dist)
		if align < 0.36:
			continue
		var score_val: float = dist / (align * align)
		if score_val < best_score:
			best_score = score_val
			best_id = cid

	if best_id != "":
		_tree_selected_id = best_id
		RetroSfx.play("ui", -11.0, 0.03)
		_refresh_skill_tree_ui()


func _refresh_skill_tree_ui() -> void:
	_tree_scrap_lbl.text = "SCRAP: %d" % MetaSave.scrap
	var def: Dictionary = SkillTreeData.get_node_def(_tree_selected_id)
	if def.is_empty():
		return

	var id: String = String(def["id"])
	var lvl: int = MetaSave.get_level(id)
	var max_lvl: int = int(def["max_level"])
	var revealed: bool = MetaSave.is_node_revealed(id)

	if revealed or lvl > 0:
		var pips: String = ""
		for p_i: int in range(max_lvl):
			pips += "■" if p_i < lvl else "□"
		_tree_node_title_lbl.text = "%s  [%s]  (%s)" % [String(def["name"]), pips, String(def["cat"])]
		_tree_node_title_lbl.add_theme_color_override("font_color", def["color"])
		_tree_node_desc_lbl.text = String(def["desc"])

		if lvl >= max_lvl:
			_tree_buy_btn.text = "UNLOCKED / MAX"
			_tree_buy_btn.disabled = true
			InputPrompts.bind_button(_tree_buy_btn, "")
		else:
			var cost: int = MetaSave.get_node_cost(id)
			_tree_buy_btn.text = "UNLOCK %d" % cost
			_tree_buy_btn.disabled = not MetaSave.can_buy_node(id)
			InputPrompts.bind_button(_tree_buy_btn, "buy")
	else:
		# Not reachable yet: still say what the node gives, so players can plan a route to it.
		var p_def: Dictionary = SkillTreeData.get_node_def(String(def["parent"]))
		var p_name: String = String(p_def.get("name", "PARENT NODE"))
		_tree_node_title_lbl.text = "%s (NEEDS %s)" % [String(def["name"]), p_name]
		_tree_node_title_lbl.add_theme_color_override("font_color", Color("#7c96c8"))
		_tree_node_desc_lbl.text = String(def["desc"])
		_tree_buy_btn.text = "LOCKED"
		_tree_buy_btn.disabled = true
		InputPrompts.bind_button(_tree_buy_btn, "")

	_tree_canvas.queue_redraw()


func _on_buy_tree_node() -> void:
	var def: Dictionary = SkillTreeData.get_node_def(_tree_selected_id)
	var ship_id: String = String(def.get("unlocks_ship", ""))
	if MetaSave.buy_node(_tree_selected_id):
		if ship_id != "":
			RetroSfx.play("unlock_ship", -5.0, 0.01)
			var s_def: Dictionary = SkillTreeData.get_ship_def(ship_id)
			_tree_summary_lbl.text = "NEW SHIP: %s!" % String(s_def["short"])
		else:
			RetroSfx.play("powerup", -6.5, 0.03)
			_tree_summary_lbl.text = "NODES: %d / %d" % [MetaSave.get_unlocked_node_count(), SkillTreeData.NODES.size()]
		_refresh_skill_tree_ui()


# =================================================================================
# FLEET SHIP LOADOUT BAY (Shows All 7 Ships, Signature Weapons & Starter Perks!)
# =================================================================================
func _build_loadout_ui() -> void:
	loadout_panel = Control.new()
	loadout_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	loadout_panel.visible = false
	ui_layer.add_child(loadout_panel)

	var bg: Panel = Panel.new()
	bg.position = Vector2(8.0, 6.0)
	bg.size = Vector2(464.0, 258.0)
	bg.add_theme_stylebox_override("panel", _make_ff6_box())
	loadout_panel.add_child(bg)

	var hdr: Label = Label.new()
	hdr.position = Vector2(18.0, 12.0)
	hdr.size = Vector2(190.0, 16.0)
	hdr.text = "FLEET SHIP LOADOUT"
	hdr.add_theme_font_size_override("font_size", FONT_SZ)
	hdr.add_theme_color_override("font_color", Color("#ffe854"))
	loadout_panel.add_child(hdr)

	_loadout_count_lbl = Label.new()
	_loadout_count_lbl.position = Vector2(190.0, 12.0)
	_loadout_count_lbl.size = Vector2(140.0, 16.0)
	_loadout_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loadout_count_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_loadout_count_lbl.add_theme_color_override("font_color", Color("#54f4ff"))
	loadout_panel.add_child(_loadout_count_lbl)

	_loadout_scrap_lbl = Label.new()
	_loadout_scrap_lbl.position = Vector2(336.0, 12.0)
	_loadout_scrap_lbl.size = Vector2(126.0, 16.0)
	_loadout_scrap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_loadout_scrap_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_loadout_scrap_lbl.add_theme_color_override("font_color", Color("#3ce878"))
	loadout_panel.add_child(_loadout_scrap_lbl)

	# 7 Visual Ship Roster Slots across the top (y = 32..98)
	_loadout_ship_btns.clear()
	_loadout_ship_icons.clear()
	_loadout_ship_names.clear()
	for i: int in range(SkillTreeData.SHIPS.size()):
		var sx: float = 15.0 + float(i) * 64.5
		var btn: Button = Button.new()
		btn.position = Vector2(sx, 32.0)
		btn.size = Vector2(61.0, 66.0)
		var slot_i: int = i
		btn.focus_entered.connect(func() -> void: _select_loadout_slot(slot_i))
		btn.pressed.connect(func() -> void: _activate_loadout_slot(slot_i))
		loadout_panel.add_child(btn)
		_loadout_ship_btns.append(btn)

		var tex_r: TextureRect = TextureRect.new()
		tex_r.position = Vector2(6.0, 8.0)
		tex_r.size = Vector2(49.0, 34.0)
		tex_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex_r)
		_loadout_ship_icons.append(tex_r)

		var n_lbl: Label = Label.new()
		n_lbl.position = Vector2(1.0, 47.0)
		n_lbl.size = Vector2(59.0, 14.0)
		n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n_lbl.add_theme_font_size_override("font_size", FONT_SZ)
		n_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(n_lbl)
		_loadout_ship_names.append(n_lbl)

	# Live Ship Showcase & Loadout Spec Card (y = 104..224)
	var spec_card: Panel = Panel.new()
	spec_card.position = Vector2(15.0, 104.0)
	spec_card.size = Vector2(450.0, 118.0)
	spec_card.add_theme_stylebox_override("panel", _make_ff6_box(Color("#060c28"), Color("#5c7cc4"), 1, 4.0))
	loadout_panel.add_child(spec_card)

	_loadout_preview_ship = Sprite2D.new()
	_loadout_preview_ship.position = Vector2(64.0, 152.0)
	_loadout_preview_ship.scale = Vector2(3.0, 3.0)
	loadout_panel.add_child(_loadout_preview_ship)

	_loadout_preview_bullet = Sprite2D.new()
	_loadout_preview_bullet.position = Vector2(128.0, 152.0)
	_loadout_preview_bullet.scale = Vector2(2.0, 2.0)
	loadout_panel.add_child(_loadout_preview_bullet)

	_loadout_info_title = Label.new()
	_loadout_info_title.position = Vector2(162.0, 110.0)
	_loadout_info_title.size = Vector2(296.0, 15.0)
	_loadout_info_title.add_theme_font_size_override("font_size", FONT_SZ)
	loadout_panel.add_child(_loadout_info_title)

	_loadout_info_weapon = Label.new()
	_loadout_info_weapon.position = Vector2(162.0, 126.0)
	_loadout_info_weapon.size = Vector2(296.0, 14.0)
	_loadout_info_weapon.add_theme_font_size_override("font_size", FONT_SZ)
	_loadout_info_weapon.add_theme_color_override("font_color", Color("#ffe854"))
	loadout_panel.add_child(_loadout_info_weapon)

	_loadout_info_desc = Label.new()
	_loadout_info_desc.position = Vector2(162.0, 142.0)
	_loadout_info_desc.size = Vector2(296.0, 34.0)
	_loadout_info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loadout_info_desc.add_theme_font_size_override("font_size", FONT_SZ)
	_loadout_info_desc.add_theme_color_override("font_color", Color.WHITE)
	loadout_panel.add_child(_loadout_info_desc)

	_loadout_info_perks = Label.new()
	_loadout_info_perks.position = Vector2(22.0, 184.0)
	_loadout_info_perks.size = Vector2(436.0, 34.0)
	_loadout_info_perks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loadout_info_perks.add_theme_font_size_override("font_size", FONT_SZ)
	_loadout_info_perks.add_theme_color_override("font_color", Color("#88e8ff"))
	loadout_panel.add_child(_loadout_info_perks)

	# Bottom Loadout Navigation Bar
	var l_title_btn: Button = Button.new()
	l_title_btn.position = Vector2(15.0, 229.0)
	l_title_btn.size = Vector2(104.0, 26.0)
	l_title_btn.text = "TITLE"
	_style_menu_btn(l_title_btn)
	InputPrompts.bind_button(l_title_btn, "back")
	l_title_btn.pressed.connect(func() -> void:
		RetroSfx.play("ui", -7.0, 0.02)
		_enter_title()
	)
	loadout_panel.add_child(l_title_btn)

	var l_tree_btn: Button = Button.new()
	l_tree_btn.position = Vector2(128.0, 229.0)
	l_tree_btn.size = Vector2(154.0, 26.0)
	l_tree_btn.text = "SKILL TREE"
	_style_menu_btn(l_tree_btn, Color("#ffe854"))
	InputPrompts.bind_button(l_tree_btn, "swap_menu")
	l_tree_btn.pressed.connect(func() -> void:
		RetroSfx.play("ui", -7.0, 0.02)
		_enter_hangar("")
	)
	loadout_panel.add_child(l_tree_btn)

	_loadout_action_btn = Button.new()
	_loadout_action_btn.position = Vector2(290.0, 229.0)
	_loadout_action_btn.size = Vector2(175.0, 26.0)
	_style_menu_btn(_loadout_action_btn, Color("#3ce878"))
	InputPrompts.bind_button(_loadout_action_btn, "confirm")
	_loadout_action_btn.pressed.connect(func() -> void: _activate_loadout_slot(_loadout_cursor_idx))
	loadout_panel.add_child(_loadout_action_btn)


func _enter_loadout() -> void:
	_unfreeze_world()
	state = State.LOADOUT
	_hide_all_menus()
	loadout_panel.visible = true
	starfield.hyperspace_active = false
	starfield.speed_scale = 0.65
	player.visible = false
	player.controls_enabled = false
	player.set_options_hidden()
	_clear_entities()
	GenesisMusic.play_title()

	_loadout_cursor_idx = 0
	for i: int in range(SkillTreeData.SHIPS.size()):
		if String(SkillTreeData.SHIPS[i]["id"]) == MetaSave.selected_ship:
			_loadout_cursor_idx = i
			break

	_refresh_loadout_ui()
	_loadout_ship_btns[_loadout_cursor_idx].grab_focus()


func _select_loadout_slot(idx: int) -> void:
	_loadout_cursor_idx = clampi(idx, 0, SkillTreeData.SHIPS.size() - 1)
	_refresh_loadout_ui()


func _activate_loadout_slot(idx: int) -> void:
	_loadout_cursor_idx = clampi(idx, 0, SkillTreeData.SHIPS.size() - 1)
	var s_def: Dictionary = SkillTreeData.SHIPS[_loadout_cursor_idx]
	var s_id: String = String(s_def["id"])
	if MetaSave.is_ship_unlocked(s_id):
		if MetaSave.selected_ship != s_id:
			MetaSave.select_ship(s_id)
			RetroSfx.play("powerup", -6.0, 0.02)
			_refresh_loadout_ui()
		else:
			_start_run()
	else:
		RetroSfx.play("hit", -10.0, 0.02)
		_enter_hangar("UNLOCK %s IN THE SKILL TREE!" % String(s_def["short"]))


func _refresh_loadout_ui() -> void:
	_loadout_count_lbl.text = "SHIPS: %d / %d" % [MetaSave.get_unlocked_ship_count(), SkillTreeData.SHIPS.size()]
	_loadout_scrap_lbl.text = "SCRAP: %d" % MetaSave.scrap

	for i: int in range(SkillTreeData.SHIPS.size()):
		var sd: Dictionary = SkillTreeData.SHIPS[i]
		var sid: String = String(sd["id"])
		var unlocked: bool = MetaSave.is_ship_unlocked(sid)
		var equipped: bool = (MetaSave.selected_ship == sid)
		var col: Color = sd["color"]

		var btn: Button = _loadout_ship_btns[i]
		var b_border: Color = Color("#3ce878") if equipped else (col if unlocked else Color("#36466e"))
		var b_bg: Color = Color("#132b5e") if equipped else (Color("#0c1640") if unlocked else Color("#070b1e"))
		btn.add_theme_stylebox_override("normal", _make_ff6_box(b_bg, b_border, 2 if equipped else 1, 2.0))
		btn.add_theme_stylebox_override("hover", _make_ff6_box(Color("#1b347a"), Color.WHITE, 2, 2.0))
		btn.add_theme_stylebox_override("focus", _make_ff6_box(Color("#1b347a"), Color("#ffe854"), 2, 2.0))

		var icon_r: TextureRect = _loadout_ship_icons[i]
		icon_r.texture = PixelArt.tex(String(sd["sprite_0"]))
		icon_r.modulate = Color.WHITE if unlocked else Color(0.08, 0.12, 0.24, 0.9)

		var n_lbl: Label = _loadout_ship_names[i]
		n_lbl.text = String(sd["short"]) if unlocked else "???"
		n_lbl.add_theme_color_override("font_color", Color("#3ce878") if equipped else (Color.WHITE if unlocked else Color("#586c96")))

	var cur: Dictionary = SkillTreeData.SHIPS[_loadout_cursor_idx]
	var cur_id: String = String(cur["id"])
	var cur_unlocked: bool = MetaSave.is_ship_unlocked(cur_id)
	var cur_equipped: bool = (MetaSave.selected_ship == cur_id)

	_loadout_preview_ship.texture = PixelArt.tex(String(cur["sprite_0"]))
	_loadout_preview_ship.modulate = Color.WHITE if cur_unlocked else Color(0.06, 0.10, 0.22, 0.95)
	_loadout_preview_bullet.texture = PixelArt.tex(String(cur["bullet_preview"]))
	_loadout_preview_bullet.visible = cur_unlocked

	if cur_unlocked:
		var eq_tag: String = "  [EQUIPPED]" if cur_equipped else ""
		_loadout_info_title.text = "%s%s" % [String(cur["name"]), eq_tag]
		_loadout_info_title.add_theme_color_override("font_color", cur["color"])
		_loadout_info_weapon.text = "BLASTER: %s" % String(cur["weapon_name"])
		_loadout_info_desc.text = String(cur["weapon_desc"])
		_loadout_info_perks.text = "SHIP PERK: %s\nSKILL TREE: %s" % [String(cur["perk_desc"]), _format_active_starters()]
		_loadout_action_btn.text = "LAUNCH RUN" if cur_equipped else "EQUIP SHIP"
	else:
		_loadout_info_title.text = "LOCKED CLASSIFIED HULL"
		_loadout_info_title.add_theme_color_override("font_color", Color("#7c96c8"))
		_loadout_info_weapon.text = "BLASTER: ???"
		_loadout_info_desc.text = String(cur["unlock_hint"])
		_loadout_info_perks.text = "Spend Scrap in the Starforge Skill Tree to unlock this spacecraft!"
		_loadout_action_btn.text = "GO TO SKILL TREE"


func _format_active_starters() -> String:
	var tags: Array[String] = []
	var bonus_hull: int = MetaSave.get_level("hull_1") + MetaSave.get_level("hull_2")
	if bonus_hull > 0:
		tags.append("+%d Hull" % bonus_hull)
	if MetaSave.get_starting_shields() > 0:
		tags.append("Shield x%d" % MetaSave.get_starting_shields())
	if MetaSave.has_lazarus_revive():
		tags.append("Lazarus Revive")
	if MetaSave.get_starting_rerolls() > 0:
		tags.append("%d Rerolls" % MetaSave.get_starting_rerolls())
	tags.append("%d/%d Draft Cards" % [MetaSave.get_unlocked_draft_card_count(), MetaSave.get_total_draft_card_nodes()])
	return ", ".join(tags)


func _build_pause_ui() -> void:
	pause_panel = Control.new()
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	ui_layer.add_child(pause_panel)

	var dim: ColorRect = ColorRect.new()
	dim.position = Vector2(0.0, 23.0)
	dim.size = Vector2(VIEW_W, VIEW_H - 23.0)
	dim.color = Color(0.01, 0.02, 0.08, 0.78)
	pause_panel.add_child(dim)

	# --- LEFT SIDE: Small Individual FF6 Boxes for Pause Options + Active Ship Badge ---
	var hdr_box: Panel = Panel.new()
	hdr_box.position = Vector2(12.0, 30.0)
	hdr_box.size = Vector2(136.0, 22.0)
	hdr_box.add_theme_stylebox_override("panel", _make_ff6_box(Color("#081034"), Color("#ffe854"), 1, 2.0))
	pause_panel.add_child(hdr_box)

	var hdr: Label = Label.new()
	hdr.position = Vector2(12.0, 34.0)
	hdr.size = Vector2(136.0, 14.0)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.text = "PAUSED"
	hdr.add_theme_font_size_override("font_size", FONT_SZ)
	hdr.add_theme_color_override("font_color", Color("#ffe854"))
	pause_panel.add_child(hdr)

	var p_specs: Array[Dictionary] = [
		{"label": "RESUME", "cb": _resume_game, "accent": Color("#3ce878")},
		{"label": "OPTIONS", "cb": _open_options_from_pause, "accent": Color("#28e8ff")},
		{"label": "RETIRE RUN", "cb": _retire_from_pause, "accent": Color("#ffe854")},
		{"label": "QUIT TITLE", "cb": _quit_from_pause, "accent": Color("#ff4c68")},
	]

	for i: int in range(p_specs.size()):
		var spec: Dictionary = p_specs[i]
		var btn: Button = Button.new()
		btn.position = Vector2(12.0, 58.0 + float(i) * 30.0)
		btn.size = Vector2(136.0, 25.0)
		btn.text = String(spec["label"])
		_style_menu_btn(btn, spec["accent"])
		var cb: Callable = spec["cb"]
		btn.pressed.connect(func() -> void:
			RetroSfx.play("ui", -7.0, 0.02)
			cb.call()
		)
		pause_panel.add_child(btn)
		if i == 0:
			_pause_resume_btn = btn
			InputPrompts.bind_button(btn, "resume")

	var ship_card: Panel = Panel.new()
	ship_card.position = Vector2(12.0, 182.0)
	ship_card.size = Vector2(136.0, 78.0)
	ship_card.add_theme_stylebox_override("panel", _make_ff6_box(Color("#081034"), Color("#6c88c4"), 1, 2.0))
	pause_panel.add_child(ship_card)

	_pause_ship_sprite = Sprite2D.new()
	_pause_ship_sprite.position = Vector2(80.0, 206.0)
	_pause_ship_sprite.scale = Vector2(2.0, 2.0)
	pause_panel.add_child(_pause_ship_sprite)

	# --- RIGHT SIDE: Current Ship Stats & Installed Upgrades Panel ---
	var right_box: Panel = Panel.new()
	right_box.position = Vector2(156.0, 30.0)
	right_box.size = Vector2(312.0, 230.0)
	right_box.add_theme_stylebox_override("panel", _make_ff6_box(Color("#060d2b"), Color("#dce6ff"), 2, 4.0))
	pause_panel.add_child(right_box)

	_pause_info_canvas = Control.new()
	_pause_info_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_info_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_info_canvas.draw.connect(_draw_pause_stats_and_upgrades)
	pause_panel.add_child(_pause_info_canvas)


func _collect_installed_modules() -> Array[Dictionary]:
	var modules: Array[Dictionary] = []
	var main_lvl: int = player.beam_level if (player.signature_weapon == "vulcan" and player.active_beam != "vulcan") else (
		1 + player.weapon_overclock
	)
	modules.append(_get_beam_badge_info(player.active_beam, main_lvl))
	if player.aux_beam != "":
		modules.append(_get_beam_badge_info(player.aux_beam, player.beam_level))
	if player.option_count > 0:
		modules.append({"icon": "badge_option", "name": "Option Drone", "val": "x%d" % player.option_count, "col": Color("#ff9624")})
	if player.blade_level > 0:
		modules.append({"icon": "badge_blades", "name": "Orbital Blades", "val": "Lv%d" % player.blade_level, "col": Color("#54f4ff")})
	if player.turret_level > 0:
		modules.append({"icon": "badge_turret", "name": "Auto-Turret", "val": "Lv%d" % player.turret_level, "col": Color("#6eff8c")})
	if player.missile_level > 0:
		modules.append({"icon": "badge_missile", "name": "Homing Pods", "val": "Lv%d" % player.missile_level, "col": Color("#ff4c68")})
	if player.flank_level > 0:
		modules.append({"icon": "badge_flank", "name": "Flank Guns", "val": "Lv%d" % player.flank_level, "col": Color("#ffe854")})
	if player.bomb_level > 0:
		modules.append({"icon": "badge_bomb", "name": "Gravity Bombs", "val": "Lv%d" % player.bomb_level, "col": Color("#d44cff")})
	if player.nova_level > 0:
		modules.append({"icon": "badge_nova", "name": "Nova Coil", "val": "Lv%d" % player.nova_level, "col": Color("#ffd84c")})
	if player.spread_level > 0:
		modules.append({"icon": "badge_spread", "name": "Spread Matrix", "val": "Lv%d" % player.spread_level, "col": Color("#ffe854")})
	if player.max_shield > 0:
		modules.append({"icon": "badge_shield", "name": "Force Shield", "val": "Lv%d" % player.max_shield, "col": Color("#3ce8ff")})
	if player.rapid_level > 0:
		modules.append({"icon": "badge_rapid", "name": "Rapid Coil", "val": "Lv%d" % player.rapid_level, "col": Color("#d46bff")})
	if player.thruster_level > 0:
		modules.append({"icon": "badge_thruster", "name": "Afterburner", "val": "Lv%d" % player.thruster_level, "col": Color("#3ce878")})
	if int(run_ranks.get("repair", 0)) > 0:
		modules.append({"icon": "badge_bio", "name": "Hull Overclock", "val": "Lv%d" % int(run_ranks.get("repair", 0)), "col": Color("#66ff99")})
	# DRAFT CARD upgrades (Skill Tree unlocks) carry their own pause-screen name & badge.
	for def: Dictionary in RUN_UPGRADE_POOL:
		if not def.has("short"):
			continue
		var c_rank: int = int(run_ranks.get(String(def["id"]), 0))
		if c_rank > 0:
			var c_val: String = "Lv%d" % c_rank if int(def["max_rank"]) > 1 else ""
			modules.append({"icon": String(def["badge"]), "name": String(def["short"]), "val": c_val, "col": def["color"]})
	return modules


func _draw_pause_stats_and_upgrades() -> void:
	var font: Font = PixelArt.ui_font if PixelArt.ui_font != null else ThemeDB.fallback_font
	var s_def: Dictionary = MetaSave.get_selected_ship_def()

	# Left Ship Mini-Card Text (under _pause_ship_sprite)
	_pause_info_canvas.draw_string(font, Vector2(18.0, 234.0), String(s_def["short"]), HORIZONTAL_ALIGNMENT_CENTER, 124, FONT_SZ, s_def["color"])
	_pause_info_canvas.draw_string(
		font,
		Vector2(18.0, 248.0),
		"KILLS %d  |  REROLL %d" % [run_kills, rerolls_left],
		HORIZONTAL_ALIGNMENT_CENTER,
		124,
		FONT_SZ,
		Color("#9ab6e8")
	)

	# Right Panel: Section 1 — Current Ship Stats
	var rx: float = 166.0
	var ry: float = 44.0
	_pause_info_canvas.draw_string(font, Vector2(rx, ry), "CURRENT SHIP STATS", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#ffe854"))
	if player.has_revive_charge:
		_pause_info_canvas.draw_string(font, Vector2(rx + 178.0, ry), "[LAZARUS READY]", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#3ce878"))

	var dmg_pct: int = int(round(player.damage_bonus * 100.0))
	var rate_pct: int = int(round(player.fire_rate_bonus * 100.0))
	var crit_pct: int = int(round(player.crit_chance * 100.0))
	var mag_px: int = int(round(MetaSave.get_magnet_radius()))
	var xp_pct: int = int(round(MetaSave.get_xp_mult() * 100.0))
	var scr_pct: int = int(round(MetaSave.get_scrap_mult() * 100.0))

	var left_stats: Array[String] = [
		"HULL:      %d / %d" % [player.hp, player.max_hp],
		"SHIELD:    %d / %d" % [player.shield_charges, player.max_shield],
		"DAMAGE:    %d%%" % dmg_pct,
		"FIRE RATE: %d%%" % rate_pct,
	]
	var right_stats: Array[String] = [
		"SPEED:     %d" % int(round(player.move_speed)),
		"CRIT:      %d%%" % crit_pct,
		"MAGNET:    %d px" % mag_px,
		"XP/SCRAP:  %d%%/%d%%" % [xp_pct, scr_pct],
	]

	for row_i: int in range(4):
		var sy: float = ry + 14.0 + float(row_i) * 12.0
		_pause_info_canvas.draw_string(font, Vector2(rx, sy), left_stats[row_i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color.WHITE)
		_pause_info_canvas.draw_string(font, Vector2(rx + 148.0, sy), right_stats[row_i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#dce8ff"))

	# Divider & Section 2 — Installed Weapons & Upgrades (2-Column Pictorial Grid)
	_pause_info_canvas.draw_line(Vector2(164.0, 99.0), Vector2(460.0, 99.0), Color("#4c6cb0"), 1.0)
	_pause_info_canvas.draw_string(
		font,
		Vector2(rx, 112.0),
		"INSTALLED WEAPONS & UPGRADES  (LV %d  |  XP %d/%d)" % [player_level, run_xp, xp_to_next],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		FONT_SZ,
		Color("#54f4ff")
	)

	# Up to 14 modules: roomy 2-column cards. With draft-card perks a run can hold many more,
	# so switch to compact 12px rows (2 columns up to 22, then 3 columns up to 33).
	var mods: Array[Dictionary] = _collect_installed_modules()
	var cols: int = 2
	var row_step: float = 19.0
	var ch: float = 16.0
	if mods.size() > 14:
		row_step = 12.0
		ch = 11.0
		if mods.size() > 22:
			cols = 3
	var cw: float = 145.0 if cols == 2 else 96.0
	var col_step: float = 149.0 if cols == 2 else 99.0
	var max_mods: int = cols * (7 if row_step > 12.0 else 11)
	for m_i: int in range(mini(max_mods, mods.size())):
		var mod: Dictionary = mods[m_i]
		var col_idx: int = m_i % cols
		var row_idx: int = m_i / cols
		var cx: float = 164.0 + float(col_idx) * col_step
		var cy: float = 118.0 + float(row_idx) * row_step
		var accent: Color = mod["col"]

		_pause_info_canvas.draw_rect(Rect2(cx, cy, cw, ch), Color("#101c4a"))
		_pause_info_canvas.draw_rect(Rect2(cx, cy + ch - 1.0, cw, 1.0), accent)
		var icon_tex: Texture2D = PixelArt.tex(String(mod["icon"]))
		var pad_y: float = 3.0 if ch > 11.0 else 1.0
		if icon_tex != null:
			_pause_info_canvas.draw_texture(icon_tex, Vector2(cx + 3.0, cy + pad_y))
		var m_lbl: String = ("%s %s" % [String(mod["name"]), String(mod["val"])]).strip_edges()
		var max_w: float = cw - 19.0
		if font.get_string_size(m_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ).x > max_w:
			m_lbl = String(mod["name"]) # Narrow column: drop the level before cutting the name.
		while m_lbl.length() > 3 and font.get_string_size(m_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ).x > max_w:
			m_lbl = m_lbl.substr(0, m_lbl.length() - 1)
		_pause_info_canvas.draw_string(font, Vector2(cx + 17.0, cy + pad_y + 9.0), m_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color.WHITE)


func _open_hangar_from_title() -> void:
	_enter_hangar("")


func _open_options_from_title() -> void:
	_options_from_pause = false
	_enter_options()


func _open_options_from_pause() -> void:
	_options_from_pause = true
	pause_panel.visible = false
	_enter_options()


func _retire_from_pause() -> void:
	_unfreeze_world()
	MetaSave.record_run_end(wave, run_scrap, run_kills, score, run_bosses)
	_enter_hangar("RETIRED S%d  |  +%d SCRAP!" % [current_stage_idx + 1, run_scrap])


func _quit_from_pause() -> void:
	_unfreeze_world()
	_enter_title()


func _quit_desktop() -> void:
	get_tree().quit()


func _build_draft_ui() -> void:
	draft_panel = Control.new()
	draft_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	draft_panel.visible = false
	ui_layer.add_child(draft_panel)

	var dim: ColorRect = ColorRect.new()
	dim.position = Vector2(0.0, 20.0)
	dim.size = Vector2(VIEW_W, 230.0)
	dim.color = Color(0.02, 0.03, 0.10, 0.78)
	draft_panel.add_child(dim)

	_draft_title_lbl = PromptBar.new()
	_draft_title_lbl.position = Vector2(0.0, 27.0)
	_draft_title_lbl.size = Vector2(VIEW_W, 16.0)
	_draft_title_lbl.align = HORIZONTAL_ALIGNMENT_CENTER
	_draft_title_lbl.text_color = Color("#ffe854")
	_draft_title_lbl.set_segments(["LEVEL UP! SELECT UPGRADE  ", {"act": "draft_pick"}])
	draft_panel.add_child(_draft_title_lbl)
	InputPrompts.device_changed.connect(func(_is_pad: bool) -> void: _refresh_draft_card_glyphs())

	_draft_cards.clear()
	for i: int in range(3):
		var cx: float = 20.0 + float(i) * 150.0
		var cy: float = 48.0
		var cw: float = 140.0
		var ch: float = 158.0

		var btn: Button = Button.new()
		btn.position = Vector2(cx, cy)
		btn.size = Vector2(cw, ch)
		var idx: int = i
		btn.pressed.connect(func() -> void: _pick_draft_card(idx))
		btn.focus_entered.connect(_refresh_draft_card_glyphs, CONNECT_DEFERRED)
		btn.focus_exited.connect(_refresh_draft_card_glyphs, CONNECT_DEFERRED)
		draft_panel.add_child(btn)

		# What picks this card: key cap 1/2/3, or the A button on the focused card.
		var pick_glyph: TextureRect = TextureRect.new()
		pick_glyph.position = Vector2(4.0, 6.0)
		pick_glyph.stretch_mode = TextureRect.STRETCH_KEEP
		pick_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(pick_glyph)

		var key_lbl: Label = Label.new()
		key_lbl.position = Vector2(0.0, 7.0)
		key_lbl.size = Vector2(cw, 14.0)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.add_theme_font_size_override("font_size", FONT_SZ)
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(key_lbl)

		var pips_lbl: Label = Label.new()
		pips_lbl.position = Vector2(0.0, 22.0)
		pips_lbl.size = Vector2(cw, 12.0)
		pips_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pips_lbl.add_theme_font_size_override("font_size", FONT_SZ)
		pips_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(pips_lbl)

		var art_bg: Panel = Panel.new()
		art_bg.position = Vector2(20.0, 38.0)
		art_bg.size = Vector2(100.0, 68.0)
		art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_bg.add_theme_stylebox_override("panel", _make_ff6_box(Color("#050818"), Color("#4c6cb0"), 1))
		btn.add_child(art_bg)

		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.position = Vector2(28.0, 45.0)
		icon_rect.size = Vector2(84.0, 54.0)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_rect)

		var short_lbl: Label = Label.new()
		short_lbl.position = Vector2(6.0, 116.0)
		short_lbl.size = Vector2(cw - 12.0, 34.0)
		short_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		short_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		short_lbl.add_theme_font_size_override("font_size", FONT_SZ)
		short_lbl.add_theme_color_override("font_color", Color.WHITE)
		short_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(short_lbl)

		_draft_cards.append({
			"btn": btn,
			"title_lbl": key_lbl,
			"pips_lbl": pips_lbl,
			"icon_rect": icon_rect,
			"short_lbl": short_lbl,
			"pick_glyph": pick_glyph,
		})

	_draft_reroll_btn = Button.new()
	_draft_reroll_btn.position = Vector2(160.0, 214.0)
	_draft_reroll_btn.size = Vector2(160.0, 24.0)
	_draft_reroll_btn.focus_mode = Control.FOCUS_NONE
	_style_menu_btn(_draft_reroll_btn, Color("#d46bff"))
	InputPrompts.bind_button(_draft_reroll_btn, "reroll")
	_draft_reroll_btn.pressed.connect(_reroll_draft_cards)
	draft_panel.add_child(_draft_reroll_btn)


func _hide_all_menus() -> void:
	title_panel.visible = false
	stats_panel.visible = false
	options_panel.visible = false
	soundtrack_panel.visible = false
	hangar_panel.visible = false
	loadout_panel.visible = false
	draft_panel.visible = false
	pause_panel.visible = false
	hud_bar.visible = false
	pause_hud_btn.visible = false
	touch_focus_btn.visible = false
	banner_label.visible = false


func _sync_touch_hud_visibility() -> void:
	var show_touch: bool = (state == State.PLAYING) and (
		MetaSave.touch_mode == 1 or (MetaSave.touch_mode == 0 and player.touch_detected)
	)
	touch_focus_btn.visible = show_touch


func _pause_game() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	_pre_pause_speed = starfield.speed_scale
	starfield.speed_scale = 0.0
	player.clear_touch_drag()
	world_root.process_mode = Node.PROCESS_MODE_DISABLED
	touch_focus_btn.visible = false
	pause_panel.visible = true
	if _pause_ship_sprite != null:
		var s_def: Dictionary = MetaSave.get_selected_ship_def()
		_pause_ship_sprite.texture = PixelArt.tex(String(s_def["sprite_0"]))
	if _pause_info_canvas != null:
		_pause_info_canvas.queue_redraw()
	GenesisMusic.set_paused_duck(true)
	RetroSfx.play("ui", -7.0, 0.02)
	_pause_resume_btn.grab_focus()
	hud_bar.queue_redraw()


func _resume_game() -> void:
	if state != State.PAUSED:
		return
	_unfreeze_world()
	pause_panel.visible = false
	state = State.PLAYING
	starfield.speed_scale = _pre_pause_speed
	_sync_touch_hud_visibility()
	RetroSfx.play("ui", -7.0, 0.02)
	hud_bar.queue_redraw()


func _unfreeze_world() -> void:
	world_root.process_mode = Node.PROCESS_MODE_INHERIT
	GenesisMusic.set_paused_duck(false)


# Called by the `state` setter on every change: 2x only runs while flying (PLAYING or the
# hyperspace jump), so pause, drafts, game over, retire, title and every menu drop to 1x.
func _on_state_changed() -> void:
	var flying: bool = state == State.PLAYING or state == State.HYPERSPACE
	if not flying:
		_set_speed_up(false)
	# A TOGGLE-mode 2x carries on after a level-up draft (drafts pop up on their own), but
	# pausing or leaving the run switches it off.
	if not flying and state != State.DRAFT:
		_speed_toggle_on = false


# Strongest right trigger across all pads (0..1).
func _read_speed_trigger() -> float:
	var strongest: float = 0.0
	for pad: int in Input.get_connected_joypads():
		strongest = maxf(strongest, Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT))
	return strongest


# Runs every frame with the raw speed-up inputs (F key, right trigger). The smoke test calls it
# directly with fake values.
func _update_speed_up(key_held: bool, trigger: float) -> void:
	if _speed_trigger_down:
		_speed_trigger_down = trigger > SPEED_TRIGGER_RELEASE
	else:
		_speed_trigger_down = trigger >= SPEED_TRIGGER_PRESS
	var held: bool = key_held or _speed_trigger_down
	var just_pressed: bool = held and not _speed_input_held
	_speed_input_held = held
	var flying: bool = state == State.PLAYING or state == State.HYPERSPACE
	if not MetaSave.speed_up_toggle:
		_speed_toggle_on = false
		_set_speed_up(flying and held)
		return
	if just_pressed and flying:
		_speed_toggle_on = not _speed_toggle_on
	_set_speed_up(flying and _speed_toggle_on)


func _set_speed_up(on: bool) -> void:
	var time_scale_val: float = SPEED_UP_SCALE if on else 1.0
	# Physics here only checks Area2D overlaps. Raising its tick rate with the clock keeps those
	# checks at 60 per game second on displays faster than 60 Hz. Fast shots are handled by
	# GameBullet._update_sweep, because they move in _process and extra ticks can't see them.
	var tps: int = roundi(float(_base_physics_tps) * time_scale_val)
	if on == _speed_up_active and Engine.time_scale == time_scale_val and Engine.physics_ticks_per_second == tps:
		return
	_speed_up_active = on
	Engine.time_scale = time_scale_val
	Engine.physics_ticks_per_second = tps
	if hud_bar != null:
		hud_bar.queue_redraw()


func _enter_title() -> void:
	_unfreeze_world()
	state = State.TITLE
	_hide_all_menus()
	title_panel.visible = true
	starfield.hyperspace_active = false
	starfield.set_stage(0)
	starfield.speed_scale = 0.70
	player.visible = false
	player.controls_enabled = false
	player.set_options_hidden()
	_clear_entities()
	GenesisMusic.play_title()

	var ship_def: Dictionary = MetaSave.get_selected_ship_def()
	_title_start_btn.text = "START RUN [%s]" % String(ship_def["short"])
	_title_ship_sprite.texture = PixelArt.tex(String(ship_def["sprite_0"]))

	if MetaSave.has_any_affordable_upgrade():
		_title_tree_btn.text = "SKILL TREE (%d SCRAP!)" % MetaSave.scrap
	elif MetaSave.scrap > 0:
		_title_tree_btn.text = "SKILL TREE (%d)" % MetaSave.scrap
	else:
		_title_tree_btn.text = "SKILL TREE"

	_title_loadout_btn.text = "SHIP LOADOUT (%d/%d)" % [MetaSave.get_unlocked_ship_count(), SkillTreeData.SHIPS.size()]

	_title_sel_idx = clampi(_title_sel_idx, 0, _title_menu_btns.size() - 1)
	_title_menu_btns[_title_sel_idx].grab_focus()


func _enter_stats() -> void:
	state = State.STATS
	_hide_all_menus()
	stats_panel.visible = true
	GenesisMusic.play_title()
	var best_st: int = StageData.get_stage_index_for_wave(maxi(1, MetaSave.best_wave)) + 1
	_stats_body_lbl.text = (
		"HIGH SCORE:        %07d\n" % MetaSave.best_score
		+ "FURTHEST STAGE:    STAGE %d (WAVE %d)\n" % [best_st if MetaSave.best_wave > 0 else 0, MetaSave.best_wave]
		+ "SORTIES FLOWN:     %d\n" % MetaSave.total_runs
		+ "HOSTILES DOWNED:   %d\n" % MetaSave.total_kills
		+ "BOSSES DEFEATED:   %d\n" % MetaSave.bosses_defeated
		+ "BANKED SCRAP:      %d (TOTAL %d)\n" % [MetaSave.scrap, MetaSave.lifetime_scrap]
		+ "SKILL TREE RANKS:  %d / %d  |  SHIPS: %d / %d" % [
			MetaSave.get_total_upgrade_ranks(),
			MetaSave.get_max_upgrade_ranks(),
			MetaSave.get_unlocked_ship_count(),
			SkillTreeData.SHIPS.size(),
		]
	)
	_stats_back_btn.grab_focus()


func _enter_options() -> void:
	state = State.OPTIONS
	if not _options_from_pause:
		_hide_all_menus()
		GenesisMusic.play_title()
	options_panel.visible = true
	_refresh_options_ui()
	_opt_autofire_btn.grab_focus()


func _refresh_options_ui() -> void:
	_opt_music_lbl.text = "MUSIC VOL:  %d%%" % int(round(MetaSave.music_volume * 100.0))
	_opt_sfx_lbl.text = "SFX VOL:    %d%%" % int(round(MetaSave.sfx_volume * 100.0))
	_opt_autofire_btn.text = "DEFAULT AUTOFIRE:  %s" % ("ON" if MetaSave.default_autofire else "OFF")
	_opt_shake_btn.text = "SCREEN SHAKE:      %s" % ("ON" if MetaSave.screen_shake_enabled else "OFF")
	var t_names: Array[String] = ["AUTO (PHONE/TABLET)", "ALWAYS ON", "OFF"]
	_opt_touch_btn.text = "TOUCH CONTROLS:    %s" % t_names[clampi(MetaSave.touch_mode, 0, 2)]
	_opt_fullscreen_btn.text = "DISPLAY MODE:      %s" % ("FULLSCREEN" if MetaSave.fullscreen_enabled else "WINDOWED")
	_opt_speed_btn.text = "SPEED UP:          %s" % ("TOGGLE" if MetaSave.speed_up_toggle else "HOLD")


func _adjust_music(delta_vol: float) -> void:
	MetaSave.music_volume = clampf(roundf((MetaSave.music_volume + delta_vol) * 10.0) / 10.0, 0.0, 1.0)
	GenesisMusic.set_volume(MetaSave.music_volume)
	MetaSave.save_game()
	RetroSfx.play("ui", -7.0, 0.02)
	_refresh_options_ui()


func _adjust_sfx(delta_vol: float) -> void:
	MetaSave.sfx_volume = clampf(roundf((MetaSave.sfx_volume + delta_vol) * 10.0) / 10.0, 0.0, 1.0)
	RetroSfx.sfx_volume = MetaSave.sfx_volume
	MetaSave.save_game()
	RetroSfx.play("shoot", -8.0, 0.02)
	_refresh_options_ui()


func _enter_hangar(summary_msg: String) -> void:
	_unfreeze_world()
	state = State.HANGAR
	_hide_all_menus()
	hangar_panel.visible = true
	starfield.hyperspace_active = false
	starfield.speed_scale = 0.60
	player.visible = false
	player.controls_enabled = false
	player.set_options_hidden()
	_clear_entities()
	GenesisMusic.play_title()

	if MetaSave.migration_refund_notice > 0:
		_tree_summary_lbl.text = "TREE REWORK REFUND +%d" % MetaSave.migration_refund_notice
		MetaSave.migration_refund_notice = 0
	elif summary_msg == "":
		_tree_summary_lbl.text = "NODES: %d / %d" % [MetaSave.get_unlocked_node_count(), SkillTreeData.NODES.size()]
	else:
		_tree_summary_lbl.text = summary_msg

	_refresh_skill_tree_ui()


func _start_run() -> void:
	_unfreeze_world()
	RetroSfx.play("powerup", -5.0, 0.02)
	_clear_entities()
	fx_layer.clear_all()
	_hide_all_menus()

	state = State.INTRO_WARP
	_intro_timer = 0.0
	_intro_flash_done = false
	current_stage_idx = 0
	starfield.set_stage(0)
	starfield.hyperspace_active = true
	starfield.hyperspace_progress = 0.25
	starfield.speed_scale = 2.4
	hud_bar.visible = true
	pause_hud_btn.visible = false

	wave = 0
	score = 0
	run_scrap = 0
	run_kills = 0
	run_bosses = 0
	player_level = 1
	run_xp = 0
	xp_to_next = _calc_xp_for_level(1)
	rerolls_left = MetaSave.get_starting_rerolls()
	_pending_level_ups = 0
	_pending_hyperspace = false
	run_ranks.clear()
	_squad_counts.clear()

	player.reset_for_new_run()
	player.controls_enabled = false
	player.global_position = Vector2(-44.0, 134.0)

	# Sync run_ranks with ship-hull addons & tree starting shields (so draft rank caps stay right).
	var starters: Dictionary = MetaSave.get_starter_addons()
	for k: String in starters.keys():
		var v: int = int(starters[k])
		if v > 0:
			run_ranks[k] = v
	if MetaSave.get_starting_shields() > 0:
		run_ranks["shield"] = MetaSave.get_starting_shields()

	var ship_def: Dictionary = MetaSave.get_selected_ship_def()
	GenesisMusic.play_stage(0)
	_show_banner("%s LAUNCHING!\nSTAGE 1: OUTER ORBIT" % String(ship_def["name"]), ship_def["color"], INTRO_DURATION)
	hud_bar.queue_redraw()


func _update_intro_warp(delta: float) -> void:
	_intro_timer += delta
	var prog: float = clampf(_intro_timer / INTRO_DURATION, 0.0, 1.0)

	if prog < 0.58:
		var t_in: float = prog / 0.58
		starfield.hyperspace_progress = lerpf(0.25, 0.55, t_in)
		player.global_position.x = lerpf(-44.0, 96.0, 1.0 - pow(1.0 - t_in, 2.4))
		player.global_position.y = 134.0
	else:
		if not _intro_flash_done:
			_intro_flash_done = true
			starfield.hyperspace_active = false
			starfield.hyperspace_progress = 0.0
			fx_layer.spawn_hit_sparks(player.global_position, Color("#28e8ff"), 16)
			fx_layer.add_shake(3.5)
			RetroSfx.play("shield_hit", -7.0, 0.03)
		var t_settle: float = (prog - 0.58) / 0.42
		starfield.speed_scale = lerpf(2.2, 1.15, t_settle)
		player.global_position.x = lerpf(96.0, 58.0, clampf(t_settle * 1.25, 0.0, 1.0))

	if _intro_timer >= INTRO_DURATION:
		starfield.hyperspace_active = false
		starfield.hyperspace_progress = 0.0
		starfield.speed_scale = 1.15
		state = State.PLAYING
		pause_hud_btn.visible = true
		player.controls_enabled = true
		_sync_touch_hud_visibility()
		_begin_next_wave()


func _clear_entities() -> void:
	for c: Node in enemy_layer.get_children():
		c.queue_free()
	for c: Node in bullet_layer.get_children():
		c.queue_free()
	for c: Node in pickup_layer.get_children():
		c.queue_free()
	_spawn_queue.clear()


func _begin_next_wave() -> void:
	wave += 1
	current_stage_idx = StageData.get_stage_index_for_wave(wave)
	starfield.set_stage(current_stage_idx)

	var st: Dictionary = StageData.get_stage(current_stage_idx)
	var sub_wave: int = StageData.get_wave_in_stage(wave)
	var is_boss: bool = StageData.is_boss_wave(wave)
	var stage_display_num: int = current_stage_idx + 1

	_wave_clock = 0.0
	_wave_clear_delay = 0.70
	_spawn_queue.clear()

	var hp_mult: float = pow(1.34, float(current_stage_idx)) * (1.0 + float(sub_wave - 1) * 0.16)

	if is_boss:
		_pending_hyperspace = true
		starfield.speed_scale = 1.40
		GenesisMusic.play_boss(current_stage_idx)
		_show_banner("WARNING! %s!" % String(st["boss_name"]), Color("#ff4c68"), 2.8)
		RetroSfx.play("boss_siren", -5.5, 0.0)
		_queue_enemy(0.35, GameEnemy.Type.BOSS, Vector2(420.0, -110.0), hp_mult, 0.0, -1)
	else:
		_pending_hyperspace = false
		starfield.speed_scale = 1.15 + minf(0.35, float(wave) * 0.025)
		GenesisMusic.play_stage(current_stage_idx)
		if sub_wave == 1:
			_show_banner("STAGE %d: %s\n%s" % [stage_display_num, String(st["name"]), String(st["subtitle"])], st["accent"], 2.3)
		else:
			_show_banner("STAGE %d-%d  //  %s" % [stage_display_num, sub_wave, String(st["name"])], Color("#ffe854"), 1.5)

		var t: float = 0.65
		var num_groups: int = mini(14, 10 + current_stage_idx / 2 + sub_wave - 1)
		for g: int in range(num_groups):
			var roll: int = (wave * 3 + g * 2) % 6
			if roll == 0:
				var sq_id: int = _next_squad_id
				_next_squad_id += 1
				_squad_counts[sq_id] = 6
				var lane_y: float = randf_range(62.0, 196.0)
				for k: int in range(6):
					_queue_enemy(t + float(k) * 0.24, GameEnemy.Type.SCOUT_SINE, Vector2(500.0, lane_y), hp_mult, float(k) * 0.52, sq_id)
				t += 2.5
			elif roll == 1:
				var count: int = 4 if wave < 3 else 5
				var sq_id: int = _next_squad_id
				_next_squad_id += 1
				_squad_counts[sq_id] = count
				for k: int in range(count):
					var sy: float = 56.0 if k % 2 == 0 else 206.0
					_queue_enemy(t + float(k) * 0.30, GameEnemy.Type.SWOOPER, Vector2(504.0, sy), hp_mult, float(k), sq_id)
				t += 2.4
			elif roll == 2:
				var s_count: int = 2 if wave < 3 else 3
				for k: int in range(s_count):
					var py: float = lerpf(58.0, 204.0, float(k) / float(maxi(1, s_count - 1)))
					_queue_enemy(t + float(k) * 0.22, GameEnemy.Type.SNIPER, Vector2(504.0, py), hp_mult, float(k) * 1.1, -1)
				_queue_enemy(t + 0.5, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 134.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.8, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 134.0), hp_mult, 0.8, -1)
				t += 2.7
			elif roll == 3:
				var cy: float = randf_range(74.0, 188.0)
				_queue_enemy(t, GameEnemy.Type.CRUISER, Vector2(512.0, cy), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.35, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, clampf(cy - 34.0, 48.0, 214.0)), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.55, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, clampf(cy + 34.0, 48.0, 214.0)), hp_mult, 1.0, -1)
				t += 2.9
			elif roll == 4:
				var sq_id: int = _next_squad_id
				_next_squad_id += 1
				_squad_counts[sq_id] = 7
				var center_y: float = randf_range(96.0, 168.0)
				for k: int in range(7):
					var wing_off: float = float(absi(k - 3)) * 16.0 * (-1.0 if k < 3 else 1.0)
					_queue_enemy(t + float(absi(k - 3)) * 0.22, GameEnemy.Type.SCOUT_SINE, Vector2(502.0, clampf(center_y + wing_off, 48.0, 214.0)), hp_mult, float(k) * 0.4, sq_id)
				t += 2.6
			else:
				_queue_enemy(t, GameEnemy.Type.CRUISER, Vector2(512.0, randf_range(72.0, 120.0)), hp_mult, 0.0, -1)
				if current_stage_idx >= 1 or sub_wave >= 2:
					_queue_enemy(t + 0.7, GameEnemy.Type.CRUISER, Vector2(518.0, randf_range(148.0, 196.0)), hp_mult, 1.5, -1)
				_queue_enemy(t + 0.4, GameEnemy.Type.SWOOPER, Vector2(504.0, 62.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.8, GameEnemy.Type.SWOOPER, Vector2(504.0, 202.0), hp_mult, 1.2, -1)
				t += 3.1

	hud_bar.queue_redraw()


func _queue_enemy(spawn_time: float, e_type: GameEnemy.Type, pos: Vector2, hp_mult: float, phase: float, sq_id: int) -> void:
	_spawn_queue.append({
		"time": spawn_time,
		"type": e_type,
		"pos": pos,
		"hp_mult": hp_mult,
		"phase": phase,
		"squad": sq_id,
		"stage": current_stage_idx,
	})


func _show_banner(txt: String, col: Color, duration: float) -> void:
	banner_label.text = txt
	banner_label.add_theme_color_override("font_color", col)
	banner_label.visible = true
	_banner_timer = duration


func _begin_hyperspace_jump() -> void:
	state = State.HYPERSPACE
	_hyper_timer = 0.0
	_hyper_swapped_stage = false
	player.controls_enabled = false
	player.clear_touch_drag()
	touch_focus_btn.visible = false
	pause_hud_btn.visible = false
	starfield.hyperspace_active = true
	starfield.hyperspace_progress = 0.0
	starfield.speed_scale = 2.0

	player.on_stage_cleared()
	var stage_heal: int = MetaSave.get_stage_heal_amount()
	if stage_heal > 0 and player.hp < player.max_hp:
		player.heal(stage_heal)
		fx_layer.spawn_popup(player.global_position + Vector2(-18.0, -16.0), "NANITE +%d HP!" % stage_heal, Color("#3ce878"))

	var next_stage: Dictionary = StageData.get_stage(current_stage_idx + 1)
	_show_banner("HYPERSPACE JUMP!\nNEXT: %s" % String(next_stage["name"]), Color("#28e8ff"), _hyper_duration)
	GenesisMusic.play_hyperspace()
	RetroSfx.play("powerup", -5.0, 0.02)


func _update_hyperspace(delta: float) -> void:
	_hyper_timer += delta
	var prog: float = clampf(_hyper_timer / _hyper_duration, 0.0, 1.0)
	starfield.hyperspace_progress = prog

	player.global_position = player.global_position.lerp(Vector2(68.0, 134.0), clampf(delta * 4.5, 0.0, 1.0))

	if prog >= 0.55 and not _hyper_swapped_stage:
		_hyper_swapped_stage = true
		starfield.set_stage(current_stage_idx + 1)

	if _hyper_timer >= _hyper_duration:
		starfield.hyperspace_active = false
		starfield.hyperspace_progress = 0.0
		_pending_hyperspace = false
		state = State.PLAYING
		pause_hud_btn.visible = true
		player.controls_enabled = true
		_sync_touch_hud_visibility()
		_begin_next_wave()


func _process(delta: float) -> void:
	_update_speed_up(Input.is_physical_key_pressed(KEY_F), _read_speed_trigger())

	if state != State.PAUSED and _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			banner_label.visible = false

	_poll_controller_menu_stick(delta)

	if state == State.SOUNDTRACK and GenesisMusic.SLOT_KEYS[_snd_row_idx] == "hyperspace":
		_snd_hyper_timer += delta
		if _snd_hyper_timer >= 3.4:
			_snd_preview_current()

	if state == State.TITLE and _title_ship_sprite != null:
		var t: float = float(Time.get_ticks_msec()) * 0.003
		_title_ship_sprite.position = Vector2(354.0 + cos(t * 0.7) * 8.0, 134.0 + sin(t) * 10.0)
		var alt: bool = (int(Time.get_ticks_msec() / 75) % 2 == 0)
		var s_def: Dictionary = MetaSave.get_selected_ship_def()
		_title_ship_sprite.texture = PixelArt.tex(String(s_def["sprite_1" if alt else "sprite_0"]))

	elif state == State.HANGAR:
		if not _tree_dragging:
			var sel_def: Dictionary = SkillTreeData.get_node_def(_tree_selected_id)
			if not sel_def.is_empty():
				_tree_cam_offset = _tree_cam_offset.lerp(Vector2(sel_def["pos"]), clampf(10.0 * delta, 0.0, 1.0))
		_tree_canvas.queue_redraw()

	elif state == State.LOADOUT and _loadout_preview_ship != null:
		var lt: float = float(Time.get_ticks_msec()) * 0.004
		_loadout_preview_ship.position = Vector2(64.0, 148.0 + sin(lt) * 4.5)
		var cur_s: Dictionary = SkillTreeData.SHIPS[_loadout_cursor_idx]
		var l_alt: bool = (int(Time.get_ticks_msec() / 85) % 2 == 0)
		_loadout_preview_ship.texture = PixelArt.tex(String(cur_s["sprite_1" if l_alt else "sprite_0"]))
		if _loadout_preview_bullet.visible:
			_loadout_preview_bullet.position = Vector2(120.0 + fposmod(lt * 22.0, 26.0), 148.0 + sin(lt * 2.5) * 3.0)
			if String(cur_s["id"]) == "neko":
				_loadout_preview_bullet.texture = PixelArt.tex("bullet_cat_1" if l_alt else "bullet_cat_0")

	if state != State.PAUSED and fx_layer.shake_strength > 0.1:
		var s: float = fx_layer.shake_strength
		world_root.position = Vector2(randf_range(-s, s), randf_range(-s, s)).round()
	else:
		world_root.position = Vector2.ZERO

	if state == State.INTRO_WARP:
		_update_intro_warp(delta)
		hud_bar.queue_redraw()
	elif state == State.PLAYING:
		_update_wave_director(delta)
		if _pending_level_ups > 0 and not _any_boss_dying():
			_pending_level_ups -= 1
			_open_upgrade_draft()
		hud_bar.queue_redraw()
	elif state == State.HYPERSPACE:
		_update_hyperspace(delta)
		hud_bar.queue_redraw()
	elif state == State.GAME_OVER_DELAY:
		_death_timer -= delta
		if _death_timer <= 0.0:
			MetaSave.record_run_end(wave, run_scrap, run_kills, score, run_bosses)
			var msg: String = "FELL ON S%d-W%d  |  +%d SCRAP!" % [current_stage_idx + 1, wave, run_scrap]
			_enter_hangar(msg)


func _poll_controller_menu_stick(delta: float) -> void:
	if state == State.INTRO_WARP or state == State.PLAYING or state == State.HYPERSPACE or state == State.GAME_OVER_DELAY:
		return
	_joy_nav_cooldown = maxf(0.0, _joy_nav_cooldown - delta)
	if _joy_nav_cooldown > 0.0 or Input.get_connected_joypads().is_empty():
		return
	var ax: float = 0.0
	var ay: float = 0.0
	for pad: int in Input.get_connected_joypads():
		var px: float = Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
		var py: float = Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)
		if absf(px) > absf(ax):
			ax = px
		if absf(py) > absf(ay):
			ay = py

	if state == State.SOUNDTRACK:
		if absf(ay) > 0.55 and absf(ay) >= absf(ax):
			_snd_move_row(1 if ay > 0.0 else -1)
			_joy_nav_cooldown = 0.19
		elif absf(ax) > 0.55:
			_snd_change_track(1 if ax > 0.0 else -1)
			_joy_nav_cooldown = 0.24
		return

	if state == State.HANGAR:
		if absf(ax) > 0.52 or absf(ay) > 0.52:
			_move_tree_selection(Vector2(ax, ay))
			_joy_nav_cooldown = 0.19
		return

	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused == null:
		return
	var next_ctrl: Control = null
	if ay < -0.55:
		next_ctrl = focused.find_valid_focus_neighbor(SIDE_TOP)
	elif ay > 0.55:
		next_ctrl = focused.find_valid_focus_neighbor(SIDE_BOTTOM)
	elif ax < -0.55:
		next_ctrl = focused.find_valid_focus_neighbor(SIDE_LEFT)
	elif ax > 0.55:
		next_ctrl = focused.find_valid_focus_neighbor(SIDE_RIGHT)
	if next_ctrl != null:
		next_ctrl.grab_focus()
		RetroSfx.play("ui", -11.0, 0.03)
		_joy_nav_cooldown = 0.19


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		var jb: InputEventJoypadButton = event as InputEventJoypadButton
		if not jb.pressed:
			return
		if jb.button_index == JOY_BUTTON_START:
			if state == State.PLAYING:
				_pause_game()
			elif state == State.PAUSED:
				_resume_game()
			elif state == State.TITLE or state == State.HANGAR or state == State.LOADOUT:
				_start_run()
			return
		if jb.button_index == JOY_BUTTON_X:
			if state == State.HANGAR:
				RetroSfx.play("ui", -7.0, 0.02)
				_enter_loadout()
				return
			elif state == State.LOADOUT:
				RetroSfx.play("ui", -7.0, 0.02)
				_enter_hangar("")
				return
		if jb.button_index == JOY_BUTTON_Y and state == State.DRAFT:
			_reroll_draft_cards()
			return
		if state == State.HANGAR:
			if jb.button_index == JOY_BUTTON_DPAD_UP:
				_move_tree_selection(Vector2.UP)
				return
			elif jb.button_index == JOY_BUTTON_DPAD_DOWN:
				_move_tree_selection(Vector2.DOWN)
				return
			elif jb.button_index == JOY_BUTTON_DPAD_LEFT:
				_move_tree_selection(Vector2.LEFT)
				return
			elif jb.button_index == JOY_BUTTON_DPAD_RIGHT:
				_move_tree_selection(Vector2.RIGHT)
				return
			elif jb.button_index == JOY_BUTTON_A:
				_on_buy_tree_node()
				return
		if state == State.SOUNDTRACK:
			match jb.button_index:
				JOY_BUTTON_DPAD_UP:
					_snd_move_row(-1)
				JOY_BUTTON_DPAD_DOWN:
					_snd_move_row(1)
				JOY_BUTTON_DPAD_LEFT:
					_snd_change_track(-1)
				JOY_BUTTON_DPAD_RIGHT:
					_snd_change_track(1)
				JOY_BUTTON_A:
					_snd_preview_current()
				JOY_BUTTON_B:
					_leave_soundtrack()
			return
		if jb.button_index == JOY_BUTTON_B and state != State.PLAYING:
			if state == State.PAUSED:
				_resume_game()
			elif state == State.OPTIONS:
				_leave_options()
			elif state == State.STATS or state == State.HANGAR or state == State.LOADOUT:
				RetroSfx.play("ui", -7.0, 0.02)
				_enter_title()
			return
		if jb.button_index == JOY_BUTTON_A and state != State.PLAYING:
			var foc: Control = get_viewport().gui_get_focus_owner()
			if foc is Button:
				var b: Button = foc as Button
				if not b.disabled:
					b.pressed.emit()
			return

	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if not ke.pressed or ke.echo:
			return
		var k: Key = ke.physical_keycode
		if state == State.PLAYING:
			if k == KEY_ESCAPE or k == KEY_P:
				_pause_game()
		elif state == State.PAUSED:
			if k == KEY_ESCAPE or k == KEY_P:
				_resume_game()
		elif state == State.TITLE:
			if k == KEY_W or k == KEY_UP:
				_title_sel_idx = (_title_sel_idx - 1 + _title_menu_btns.size()) % _title_menu_btns.size()
				_title_menu_btns[_title_sel_idx].grab_focus()
				RetroSfx.play("ui", -11.0, 0.03)
			elif k == KEY_S or k == KEY_DOWN:
				_title_sel_idx = (_title_sel_idx + 1) % _title_menu_btns.size()
				_title_menu_btns[_title_sel_idx].grab_focus()
				RetroSfx.play("ui", -11.0, 0.03)
		elif state == State.STATS:
			if k == KEY_ESCAPE or k == KEY_BACKSPACE:
				RetroSfx.play("ui", -7.0, 0.02)
				_enter_title()
		elif state == State.OPTIONS:
			if k == KEY_ESCAPE or k == KEY_BACKSPACE:
				_leave_options()
		elif state == State.SOUNDTRACK:
			if k == KEY_W or k == KEY_UP:
				_snd_move_row(-1)
			elif k == KEY_S or k == KEY_DOWN:
				_snd_move_row(1)
			elif k == KEY_A or k == KEY_LEFT:
				_snd_change_track(-1)
			elif k == KEY_D or k == KEY_RIGHT:
				_snd_change_track(1)
			elif k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
				_snd_preview_current()
			elif k == KEY_ESCAPE or k == KEY_BACKSPACE:
				_leave_soundtrack()
		elif state == State.HANGAR:
			if k == KEY_W or k == KEY_UP:
				_move_tree_selection(Vector2.UP)
			elif k == KEY_S or k == KEY_DOWN:
				_move_tree_selection(Vector2.DOWN)
			elif k == KEY_A or k == KEY_LEFT:
				_move_tree_selection(Vector2.LEFT)
			elif k == KEY_D or k == KEY_RIGHT:
				_move_tree_selection(Vector2.RIGHT)
			elif k == KEY_SPACE or k == KEY_ENTER:
				_on_buy_tree_node()
			elif k == KEY_TAB:
				RetroSfx.play("ui", -7.0, 0.02)
				_enter_loadout()
			elif k == KEY_ESCAPE:
				RetroSfx.play("ui", -7.0, 0.02)
				_enter_title()
		elif state == State.LOADOUT:
			if k == KEY_A or k == KEY_LEFT:
				_select_loadout_slot((_loadout_cursor_idx - 1 + SkillTreeData.SHIPS.size()) % SkillTreeData.SHIPS.size())
				_loadout_ship_btns[_loadout_cursor_idx].grab_focus()
				RetroSfx.play("ui", -11.0, 0.03)
			elif k == KEY_D or k == KEY_RIGHT:
				_select_loadout_slot((_loadout_cursor_idx + 1) % SkillTreeData.SHIPS.size())
				_loadout_ship_btns[_loadout_cursor_idx].grab_focus()
				RetroSfx.play("ui", -11.0, 0.03)
			elif k == KEY_SPACE or k == KEY_ENTER:
				_activate_loadout_slot(_loadout_cursor_idx)
			elif k == KEY_TAB:
				RetroSfx.play("ui", -7.0, 0.02)
				_enter_hangar("")
			elif k == KEY_ESCAPE:
				RetroSfx.play("ui", -7.0, 0.02)
				_enter_title()
		elif state == State.DRAFT:
			if k == KEY_1:
				_pick_draft_card(0)
			elif k == KEY_2:
				_pick_draft_card(1)
			elif k == KEY_3:
				_pick_draft_card(2)
			elif k == KEY_R:
				_reroll_draft_cards()


func _any_boss_dying() -> bool:
	for node: Node in enemy_layer.get_children():
		if node is GameEnemy:
			var ge: GameEnemy = node as GameEnemy
			if ge.enemy_type == GameEnemy.Type.BOSS and ge._boss_dying:
				return true
	return false


func _calc_xp_for_level(lvl: int) -> int:
	return int(18.0 + float(lvl - 1) * 12.0 + pow(float(lvl - 1), 1.42) * 4.5)


func _gain_xp(raw_amount: int) -> void:
	var boosted: int = maxi(1, int(round(float(raw_amount) * MetaSave.get_xp_mult())))
	run_xp += boosted
	while run_xp >= xp_to_next:
		run_xp -= xp_to_next
		player_level += 1
		xp_to_next = _calc_xp_for_level(player_level)
		_pending_level_ups += 1
		RetroSfx.play("level_up", -5.0, 0.02)
		if fx_layer != null and player != null:
			fx_layer.spawn_ring_blast(player.global_position, 44.0, Color("#ffe854"))
			fx_layer.spawn_popup(player.global_position + Vector2(-24.0, -18.0), "LEVEL %d!" % player_level, Color("#ffe854"))


func _spawn_xp_burst(origin: Vector2, total_xp: int) -> void:
	if total_xp <= 0:
		return
	var remaining: int = total_xp
	while remaining > 0:
		var chunk: int = remaining
		if remaining >= 16:
			chunk = 8
		elif remaining >= 8:
			chunk = 5
		elif remaining >= 5:
			chunk = 5
		remaining -= chunk
		var offset: Vector2 = Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
		_spawn_pickup_deferred(origin + offset, GamePickup.Kind.XP, chunk)


func _update_wave_director(delta: float) -> void:
	_wave_clock += delta

	var i: int = 0
	while i < _spawn_queue.size():
		var item: Dictionary = _spawn_queue[i]
		if _wave_clock >= float(item["time"]):
			_spawn_enemy_now(item)
			_spawn_queue.remove_at(i)
		else:
			i += 1

	if _spawn_queue.is_empty() and enemy_layer.get_child_count() == 0:
		if _pending_hyperspace:
			for p_node: Node in pickup_layer.get_children():
				if p_node is GamePickup:
					(p_node as GamePickup).force_vacuum = true
			_wave_clear_delay -= delta
			if (pickup_layer.get_child_count() == 0 and _wave_clear_delay <= 0.15) or _wave_clear_delay <= -0.9:
				if _pending_level_ups == 0:
					_begin_hyperspace_jump()
		else:
			_wave_clear_delay -= delta
			if _wave_clear_delay <= 0.0:
				_begin_next_wave()


func _spawn_enemy_now(item: Dictionary) -> void:
	var e: GameEnemy = GameEnemy.new()
	enemy_layer.add_child(e)
	var e_type: GameEnemy.Type = item["type"]
	e.setup(
		e_type,
		Vector2(item["pos"]),
		float(item["hp_mult"]),
		player,
		bullet_layer,
		fx_layer,
		float(item["phase"]),
		int(item["squad"]),
		int(item.get("stage", current_stage_idx))
	)
	e.destroyed.connect(_on_enemy_destroyed)
	e.boss_phase_broken.connect(_on_boss_phase_broken)


func _on_boss_phase_broken(enemy: GameEnemy, bonus_xp: int) -> void:
	var b_xp: int = int(round(float(bonus_xp) * MetaSave.get_boss_bounty_mult()))
	_spawn_xp_burst(enemy.global_position + Vector2(-28.0, 0.0), b_xp)


func _on_enemy_destroyed(enemy: GameEnemy, killed_by_player: bool) -> void:
	var sq: int = enemy.squad_id
	if not killed_by_player:
		if sq > 0 and _squad_counts.has(sq):
			_squad_counts.erase(sq)
		return

	run_kills += 1
	var is_boss_kill: bool = (enemy.enemy_type == GameEnemy.Type.BOSS)
	if is_boss_kill:
		run_bosses += 1
	score += enemy.score_value
	var e_pos: Vector2 = enemy.global_position

	# Automatic Scrap banking on kill!
	var bounty_mult: float = MetaSave.get_boss_bounty_mult() if is_boss_kill else 1.0
	var auto_scrap: int = maxi(1, int(round(float(enemy.scrap_drop) * MetaSave.get_scrap_mult() * player.get_run_scrap_mult() * bounty_mult)))
	run_scrap += auto_scrap
	player.on_enemy_killed(e_pos, is_boss_kill)

	var drop_xp: int = int(round(float(enemy.xp_drop) * bounty_mult))
	_spawn_xp_burst(e_pos, drop_xp)

	if player.hp < player.max_hp and (is_boss_kill or randf() < MetaSave.get_heal_drop_chance()):
		_spawn_pickup_deferred(e_pos, GamePickup.Kind.HEAL, 1)

	if sq > 0 and _squad_counts.has(sq):
		var left: int = int(_squad_counts[sq]) - 1
		if left <= 0:
			_squad_counts.erase(sq)
			score += 500
			var sq_scrap: int = maxi(1, int(round(4.0 * MetaSave.get_scrap_mult() * player.get_run_scrap_mult())))
			run_scrap += sq_scrap
			fx_layer.spawn_popup(e_pos + Vector2(-26.0, -10.0), "SQUAD +XP!", Color("#28e8ff"))
			RetroSfx.play("powerup", -8.0, 0.03)
			_spawn_xp_burst(e_pos, 8)
		else:
			_squad_counts[sq] = left


func _spawn_pickup_deferred(pos: Vector2, kind: GamePickup.Kind, amount: int) -> void:
	call_deferred("_do_spawn_pickup", pos, int(kind), amount)


func _do_spawn_pickup(pos: Vector2, kind_int: int, amount: int) -> void:
	if state != State.PLAYING and state != State.DRAFT and state != State.HYPERSPACE:
		return
	var p: GamePickup = GamePickup.new()
	pickup_layer.add_child(p)
	var k: GamePickup.Kind = GamePickup.Kind.XP if kind_int == int(GamePickup.Kind.XP) else GamePickup.Kind.HEAL
	p.setup(pos, k, amount, player)
	p.collected.connect(_on_pickup_collected)


func _on_pickup_collected(kind_val: int, amount: int, pos: Vector2) -> void:
	if kind_val == int(GamePickup.Kind.XP):
		score += amount * 15
		RetroSfx.play("xp", -13.5, 0.08)
		_gain_xp(amount)
	else:
		player.heal(amount)
		RetroSfx.play("powerup", -7.0, 0.03)
		fx_layer.spawn_popup(pos + Vector2(-12.0, -8.0), "HULL +1", Color("#3ce878"))


func _roll_draft_choices() -> void:
	var beams: Array[Dictionary] = []
	var addons: Array[Dictionary] = []
	var others: Array[Dictionary] = []
	var committed_beam: String = player.get_committed_tech_beam()

	for def: Dictionary in RUN_UPGRADE_POOL:
		var id: String = String(def["id"])
		var cat: String = String(def["cat"])
		var cur_rank: int = int(run_ranks.get(id, 0))
		if cur_rank >= int(def["max_rank"]):
			continue
		if not MetaSave.is_run_upgrade_unlocked(id):
			continue
		if cat == "BEAM" and committed_beam != "" and id != committed_beam:
			continue
		if cat == "BEAM":
			beams.append(def)
		elif cat == "ADDON":
			addons.append(def)
		else:
			others.append(def)

	beams.shuffle()
	addons.shuffle()
	others.shuffle()

	_draft_choices.clear()
	if committed_beam == "" and not beams.is_empty() and not addons.is_empty():
		_draft_choices.append(beams.pop_back())
		_draft_choices.append(addons.pop_back())

	var combined: Array[Dictionary] = []
	combined.append_array(beams)
	combined.append_array(addons)
	combined.append_array(others)
	combined.shuffle()
	for entry: Dictionary in combined:
		if _draft_choices.size() >= 3:
			break
		_draft_choices.append(entry)


func _populate_draft_cards_ui() -> void:
	if _draft_title_lbl != null:
		_draft_title_lbl.set_segments(["LEVEL %d! CHOOSE POWERUP  " % player_level, {"act": "draft_pick"}])
	if _draft_reroll_btn != null:
		_draft_reroll_btn.visible = rerolls_left > 0
		_draft_reroll_btn.text = "REROLL (%d)" % rerolls_left

	for i: int in range(3):
		var card: Dictionary = _draft_cards[i]
		var btn: Button = card["btn"]
		if i < _draft_choices.size():
			var choice: Dictionary = _draft_choices[i]
			var id: String = String(choice["id"])
			var cat_tag: String = String(choice["cat"])
			var cur: int = int(run_ranks.get(id, 0))
			var max_r: int = int(choice["max_rank"])
			var col: Color = choice["color"]

			btn.visible = true
			btn.add_theme_stylebox_override("normal", _make_ff6_box(Color("#0c1540"), col, 2))
			btn.add_theme_stylebox_override("hover", _make_ff6_box(Color("#192c75"), Color.WHITE, 2))
			btn.add_theme_stylebox_override("focus", _make_ff6_box(Color("#192c75"), Color.WHITE, 2))

			var title_lbl: Label = card["title_lbl"]
			title_lbl.text = String(choice["title"])
			title_lbl.add_theme_color_override("font_color", col)

			var pips_lbl: Label = card["pips_lbl"]
			var pips: String = ""
			for r: int in range(max_r):
				pips += "■" if r <= cur else "□"
			pips_lbl.text = "%s  %s" % [cat_tag, pips]
			pips_lbl.add_theme_color_override("font_color", Color("#b8ccf2"))

			var icon_rect: TextureRect = card["icon_rect"]
			icon_rect.texture = PixelArt.tex(String(choice["icon"]))

			var short_lbl: Label = card["short_lbl"]
			short_lbl.text = String(choice["desc"])
		else:
			btn.visible = false

	var focus_idx: int = 1 if _draft_choices.size() >= 2 else 0
	if not _draft_choices.is_empty():
		var first_btn: Button = _draft_cards[focus_idx]["btn"]
		first_btn.grab_focus()
	_refresh_draft_card_glyphs()


# Key caps 1/2/3 on every card for keyboard players; for gamepad players, the A button on
# whichever card is focused. The glyph sits just left of the card title, centred as a pair.
func _refresh_draft_card_glyphs() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	for i: int in range(_draft_cards.size()):
		var card: Dictionary = _draft_cards[i]
		var btn: Button = card["btn"]
		var pick_glyph: TextureRect = card["pick_glyph"]
		var title_lbl: Label = card["title_lbl"]
		if InputPrompts.is_gamepad:
			pick_glyph.texture = InputPrompts.glyph("pad_a") if btn == focus_owner else null
		else:
			pick_glyph.texture = InputPrompts.glyph("key_%d" % (i + 1))
		if pick_glyph.texture == null:
			title_lbl.position.x = 0.0
			title_lbl.size.x = btn.size.x
			continue
		var font: Font = title_lbl.get_theme_font("font")
		var title_w: float = font.get_string_size(title_lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ).x
		var glyph_w: float = float(pick_glyph.texture.get_width())
		var x0: float = maxf(4.0, floorf((btn.size.x - glyph_w - 3.0 - title_w) * 0.5))
		pick_glyph.position = Vector2(x0, 6.0)
		title_lbl.position.x = x0 + glyph_w + 3.0
		title_lbl.size.x = title_w + 2.0


func _reroll_draft_cards() -> void:
	if state != State.DRAFT or rerolls_left <= 0:
		return
	rerolls_left -= 1
	RetroSfx.play("ui", -6.0, 0.04)
	_roll_draft_choices()
	_populate_draft_cards_ui()


func _open_upgrade_draft() -> void:
	_roll_draft_choices()
	if _draft_choices.is_empty():
		return

	state = State.DRAFT
	_draft_pre_speed = starfield.speed_scale
	starfield.speed_scale = 0.22
	player.controls_enabled = false
	player.clear_touch_drag()
	world_root.process_mode = Node.PROCESS_MODE_DISABLED
	GenesisMusic.set_paused_duck(true)
	touch_focus_btn.visible = false
	pause_hud_btn.visible = false
	draft_panel.visible = true
	_populate_draft_cards_ui()


func _pick_draft_card(index: int) -> void:
	if state != State.DRAFT or index < 0 or index >= _draft_choices.size():
		return
	var chosen: Dictionary = _draft_choices[index]
	var id: String = String(chosen["id"])
	run_ranks[id] = int(run_ranks.get(id, 0)) + 1
	player.apply_run_upgrade(id)
	player.invuln_timer = maxf(player.invuln_timer, 0.65)

	RetroSfx.play("powerup", -6.0, 0.02)
	fx_layer.spawn_popup(player.global_position + Vector2(-20.0, -16.0), "+%s" % String(chosen["title"]), chosen["color"])

	draft_panel.visible = false
	_unfreeze_world()
	starfield.speed_scale = _draft_pre_speed
	state = State.PLAYING
	pause_hud_btn.visible = true
	player.controls_enabled = true
	_sync_touch_hud_visibility()
	hud_bar.queue_redraw()


func _on_player_hp_changed(_hp: int, _max_hp: int, _sh: int, _max_sh: int) -> void:
	hud_bar.queue_redraw()


func _on_player_grazed(xp: int) -> void:
	score += 25 * xp
	_gain_xp(xp)


func _on_player_died() -> void:
	state = State.GAME_OVER_DELAY
	_death_timer = 1.65
	pause_hud_btn.visible = false
	touch_focus_btn.visible = false
	starfield.hyperspace_active = false
	starfield.speed_scale = 0.35
	GenesisMusic.stop_music()
	_show_banner("SHIP DESTROYED! SALVAGING SCRAP...", Color("#ff4c68"), 1.6)


func _get_beam_badge_info(mode: String, lvl: int) -> Dictionary:
	var lv_s: String = "Lv%d" % maxi(1, lvl) if lvl > 0 else ""
	match mode:
		"laser":
			return {"icon": "badge_laser", "name": "Pierce", "val": lv_s, "col": Color("#28e8ff")}
		"wave":
			return {"icon": "badge_wave", "name": "Wave", "val": lv_s, "col": Color("#3ce878")}
		"prism":
			return {"icon": "badge_prism", "name": "Prism", "val": lv_s, "col": Color("#ff4cd4")}
		"tesla":
			return {"icon": "badge_tesla", "name": "Tesla", "val": lv_s, "col": Color("#b86bff")}
		"plasma":
			return {"icon": "badge_plasma", "name": "Plasma", "val": lv_s, "col": Color("#ff6820")}
		"biowave":
			return {"icon": "badge_bio", "name": "BioWave", "val": lv_s, "col": Color("#3ce878")}
		"rail":
			return {"icon": "badge_laser", "name": "Rail", "val": lv_s, "col": Color("#54f4ff")}
		"flak":
			return {"icon": "badge_plasma", "name": "Flak", "val": lv_s, "col": Color("#ff9624")}
		"saucer":
			return {"icon": "badge_ufo", "name": "Rings", "val": lv_s, "col": Color("#6eff8c")}
		"ocular":
			return {"icon": "badge_eye", "name": "Gaze", "val": lv_s, "col": Color("#d44cff")}
		"cat":
			return {"icon": "badge_cat", "name": "Cats!", "val": lv_s, "col": Color("#ff64b8")}
		_:
			return {"icon": "badge_vulcan", "name": "Vulcan", "val": lv_s, "col": Color("#ffe854")}


func _draw_hud() -> void:
	var font: Font = PixelArt.ui_font if PixelArt.ui_font != null else ThemeDB.fallback_font

	# --- 1) Top FF6 Royal-Blue Status Bar (y = 0..19) ---
	hud_bar.draw_rect(Rect2(0.0, 0.0, VIEW_W, 19.0), Color("#0b133b"))
	hud_bar.draw_line(Vector2(0.0, 19.0), Vector2(VIEW_W, 19.0), Color("#b8ccf2"), 1.0)

	hud_bar.draw_string(font, Vector2(6.0, 14.0), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#dce8ff"))

	var px: float = 23.0
	var hp_step: float = 7.0 if player.max_hp >= 8 else 8.5
	var hp_w: float = 5.5 if player.max_hp >= 8 else 7.0
	for i: int in range(player.max_hp):
		var filled: bool = i < player.hp
		hud_bar.draw_rect(Rect2(px, 6.0, hp_w, 7.0), Color("#f03c4e") if filled else Color("#281c36"))
		if filled:
			hud_bar.draw_rect(Rect2(px + 1.0, 7.0, maxf(2.0, hp_w - 2.0), 2.0), Color("#ff9aa6"))
		px += hp_step

	if player.max_shield > 0:
		px += 2.0
		for i: int in range(player.max_shield):
			var s_on: bool = i < player.shield_charges
			hud_bar.draw_rect(Rect2(px, 6.0, 6.0, 7.0), Color("#28e8ff") if s_on else Color("#142c4a"))
			px += 7.5

	var st: Dictionary = StageData.get_stage(current_stage_idx)
	var sub_w: int = StageData.get_wave_in_stage(wave)
	var lv_txt: String = "LV %d" % player_level
	hud_bar.draw_string(font, Vector2(120.0, 14.0), lv_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#54f4ff"))

	var st_txt: String = "%d-%s %s" % [
		current_stage_idx + 1,
		"BOSS" if StageData.is_boss_wave(wave) else str(sub_w),
		String(st["name"]),
	]
	hud_bar.draw_string(font, Vector2(158.0, 14.0), st_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, st["accent"])

	var scrap_txt: String = "SCRAP %d" % run_scrap
	hud_bar.draw_string(font, Vector2(294.0, 14.0), scrap_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#ffe854"))

	var score_txt: String = "%07d" % score
	hud_bar.draw_string(font, Vector2(370.0, 14.0), score_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color.WHITE)

	# --- 1a) Full-Width Glowing XP Progress Bar Ribbon (y = 19..23) ---
	var xp_ratio: float = clampf(float(run_xp) / float(maxi(1, xp_to_next)), 0.0, 1.0)
	hud_bar.draw_rect(Rect2(0.0, 19.0, VIEW_W, 4.0), Color("#070c24"))
	if xp_ratio > 0.0:
		var xp_w: float = VIEW_W * xp_ratio
		hud_bar.draw_rect(Rect2(0.0, 19.0, xp_w, 3.0), Color("#28e8ff"))
		hud_bar.draw_rect(Rect2(0.0, 19.0, xp_w, 1.0), Color("#bffaff"))
	hud_bar.draw_line(Vector2(0.0, 22.0), Vector2(VIEW_W, 22.0), Color("#4c6cb0"), 1.0)

	# --- 1b) Mega Man-Style 28-Pip Segmented Top Boss Health Bar! ---
	for node: Node in enemy_layer.get_children():
		if node is GameEnemy:
			var ge: GameEnemy = node as GameEnemy
			if ge.enemy_type == GameEnemy.Type.BOSS and ge.boss_hp_bar_visible:
				var b_ratio: float = ge.boss_hp_bar_fill if ge.boss_intro_active else clampf(ge.hp / ge.max_hp, 0.0, 1.0)
				var bar_col: Color = Color("#28e8ff") if ge.boss_shield_timer > 0.0 else (
					Color("#ff3868") if ge.boss_phase == 3 else (Color("#ff9624") if ge.boss_phase == 2 else Color("#ffe854"))
				)
				var hi_col: Color = bar_col.lightened(0.55)
				var bar_x: float = 108.0
				var bar_y: float = 24.0
				var total_pips: int = GameEnemy.BOSS_HP_PIPS

				hud_bar.draw_rect(Rect2(72.0, bar_y, 318.0, 9.0), Color("#0b1029"))
				hud_bar.draw_string(font, Vector2(75.0, bar_y + 8.0), "BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#ff4c68"))

				var exact_pips: float = b_ratio * float(total_pips)
				var full_pips: int = int(floorf(exact_pips))
				var frac_pip: float = exact_pips - float(full_pips)

				for p_idx: int in range(total_pips):
					var px_pip: float = bar_x + float(p_idx) * 10.0
					hud_bar.draw_rect(Rect2(px_pip, bar_y + 1.0, 8.0, 7.0), Color("#182042"))
					if p_idx < full_pips:
						var is_leading_intro_pip: bool = ge.boss_intro_active and (p_idx == full_pips - 1) and full_pips < total_pips
						var pip_c: Color = Color.WHITE if is_leading_intro_pip else bar_col
						hud_bar.draw_rect(Rect2(px_pip, bar_y + 1.0, 8.0, 7.0), pip_c)
						hud_bar.draw_rect(Rect2(px_pip, bar_y + 1.0, 8.0, 2.0), hi_col)
					elif p_idx == full_pips and frac_pip > 0.05 and not ge.boss_intro_active:
						var part_w: float = maxf(1.0, roundf(8.0 * frac_pip))
						hud_bar.draw_rect(Rect2(px_pip, bar_y + 1.0, part_w, 7.0), bar_col)
						hud_bar.draw_rect(Rect2(px_pip, bar_y + 1.0, part_w, 2.0), hi_col)

				hud_bar.draw_line(Vector2(bar_x + 93.0, bar_y), Vector2(bar_x + 93.0, bar_y + 9.0), Color("#dce6ff"), 1.0)
				hud_bar.draw_line(Vector2(bar_x + 186.0, bar_y), Vector2(bar_x + 186.0, bar_y + 9.0), Color("#dce6ff"), 1.0)
				hud_bar.draw_rect(Rect2(72.0, bar_y, 318.0, 9.0), Color("#dce6ff"), false, 1.0)
				hud_bar.draw_line(Vector2(105.0, bar_y), Vector2(105.0, bar_y + 9.0), Color("#dce6ff"), 1.0)
				break

	# --- 1c) Speed-up ">> x2" badge, under the pause button and clear of the boss gauge ---
	if _speed_up_active:
		var ff_box: Rect2 = Rect2(436.0, 24.0, 40.0, 9.0)
		hud_bar.draw_rect(ff_box, Color("#0b1029"))
		hud_bar.draw_rect(ff_box, Color("#ffe854"), false, 1.0)
		var arrows_lit: bool = (Time.get_ticks_msec() / 250) % 2 == 0
		hud_bar.draw_string(font, Vector2(442.0, 32.0), ">>", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#ffe854") if arrows_lit else Color("#ff9624"))
		hud_bar.draw_string(font, Vector2(458.0, 32.0), "x2", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color.WHITE)

	# --- 2) Virtual Touch Thumbstick Feedback Ring ---
	if player.is_touch_dragging():
		var orig: Vector2 = player.get_touch_origin()
		var cur: Vector2 = player.get_touch_current()
		var knob: Vector2 = orig + (cur - orig).limit_length(22.0)
		hud_bar.draw_arc(orig, 20.0, 0.0, TAU, 24, Color(0.16, 0.91, 1.0, 0.35), 1.0)
		hud_bar.draw_circle(knob, 6.0, Color(0.16, 0.91, 1.0, 0.55))
