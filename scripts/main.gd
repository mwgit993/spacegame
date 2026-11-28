extends Node2D

enum State { TITLE, STATS, OPTIONS, HANGAR, LOADOUT, INTRO_WARP, PLAYING, PAUSED, DRAFT, HYPERSPACE, GAME_OVER_DELAY, SOUNDTRACK }

const VIEW_W: float = 480.0
const VIEW_H: float = 270.0
const FONT_SZ: int = 10

# Stage modules (stages 9+, scripts/stages/) queue their wave recipes through this.
const WaveBuilder = preload("res://scripts/stages/wave_builder.gd")
# The smoke test reads their lists of missing sprites and background layers.
const StageEnemyBase = preload("res://scripts/stages/stage_enemy.gd")
const StageBackgroundBase = preload("res://scripts/stages/stage_background.gd")

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
		"title": "PRISM SHARDS",
		"icon": "upg_prism",
		"color": Color("#ff4cd4"),
		"max_rank": 4,
		"desc": "Zigzag crystal shards pierce foes",
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
var touch_swap_btn: Button # touch: cycles the sub weapon (shown once 2+ are owned)
const BOSS_BAR_X: float = 106.0
const BOSS_BAR_W: float = 282.0
var _boss_bar_lag: float = 0.0 # the pale drain strip behind the boss bar (fraction of max HP)
var _boss_bar_hold: float = 0.0
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
var _opt_fps_btn: Button
var _opt_speed_btn: Button
var _opt_soundtrack_btn: Button
var _opt_reset_btn: Button
var _reset_armed_until_ms: int = 0
var _opt_back_btn: Button

# Soundtrack picker (Options > SOUNDTRACK): one row per place music plays
# (GenesisMusic.get_slot_keys()); left/right picks the original or one of its alternatives.
# SND_ROWS rows are on screen; with more slots (stage modules) the list scrolls with the cursor.
const SND_ROWS: int = 11
var soundtrack_panel: Control
var _snd_row_btns: Array[Button] = []
var _snd_value_lbls: Array[Label] = []
var _snd_info_lbl: Label
var _snd_cursor: ColorRect
var _snd_back_btn: Button
var _snd_row_idx: int = 0      # selected slot
var _snd_scroll: int = 0       # slot shown in the top row
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
var run_xp_dropped: int = 0  # XP put on the field this run (kills, squads, boss phases)
var xp_to_next: int = 28
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

# Visual Draft Cards. Sized so the run stays visible around them; 126 px is the narrowest
# width that fits the longest title (BLASTER OVERCLOCK) and every description in 2 lines.
const DRAFT_CARD_W: float = 126.0
const DRAFT_CARD_H: float = 104.0
const DRAFT_CARD_GAP: float = 14.0
const DRAFT_CARD_Y: float = 88.0
const DRAFT_SELECT_LIFT: float = 4.0  # the selected card rises by this much
var _draft_choices: Array[Dictionary] = []
var _draft_cards: Array[Dictionary] = []
var _draft_cursor: TextureRect

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
const LOADOUT_SLOT_W: float = 64.5      # roster slot pitch (61 px buttons)
const LOADOUT_VISIBLE: int = 7          # roster slots on screen at once
var _loadout_row: Control               # scrolling strip holding the roster buttons
var _loadout_first: int = 0             # first roster slot on screen
var _loadout_arrow_l: Button
var _loadout_arrow_r: Button
var _loadout_nav_btns: Array[Button] = []
var _loadout_stats_lbl: Label


func _ready() -> void:
	randomize()
	# Menu focus follows the left stick through _poll_controller_menu_stick (with auto-repeat).
	# Godot's default ui_* actions also map the stick, so one push moved the focus two steps.
	for act: String in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		for ev: InputEvent in InputMap.action_get_events(act):
			if ev is InputEventJoypadMotion:
				InputMap.action_erase_event(act, ev)
	_base_physics_tps = Engine.physics_ticks_per_second
	MetaSave.apply_audio_and_display_settings()
	_build_world()
	_build_ui()
	_enter_title()
	_build_splash()
	if OS.get_cmdline_user_args().has("--smoke-test"):
		_run_smoke_test()


# --- Intro splash ("PRESENTED BY CLAUDE", a placeholder until there's a studio name) ---------
# Drawn on its own CanvasLayer above everything while the title screen sets up behind it.
# Any key, click, tap or gamepad button skips it.
const SPLASH_IN: float = 0.7
const SPLASH_HOLD: float = 1.8
const SPLASH_OUT: float = 0.7
var _splash_layer: CanvasLayer
var _splash_root: Control
var _splash_t: float = -1.0 # < 0 = not showing


func _build_splash() -> void:
	_splash_layer = CanvasLayer.new()
	_splash_layer.layer = 100
	add_child(_splash_layer)
	_splash_root = Control.new()
	_splash_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_splash_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_splash_root.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed) or (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed):
			_end_splash()
	)
	_splash_root.draw.connect(_draw_splash)
	_splash_layer.add_child(_splash_root)
	_splash_t = 0.0


func _splash_showing() -> bool:
	return _splash_t >= 0.0


func _end_splash() -> void:
	if _splash_t < 0.0:
		return
	_splash_t = -1.0
	_splash_layer.visible = false
	_splash_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _update_splash(delta: float) -> void:
	if _splash_t < 0.0:
		return
	_splash_t += delta
	if _splash_t >= SPLASH_IN + SPLASH_HOLD + SPLASH_OUT:
		_end_splash()
		return
	_splash_root.queue_redraw()


func _draw_splash() -> void:
	var t: float = _splash_t
	# Background stays black until the fade-out, then lets the title show through.
	var bg_a: float = 1.0 - clampf((t - SPLASH_IN - SPLASH_HOLD) / SPLASH_OUT, 0.0, 1.0)
	# The text fades out first (end of the hold), so it never ghosts over the title behind.
	var txt_a: float = clampf(t / SPLASH_IN, 0.0, 1.0) * clampf((SPLASH_IN + SPLASH_HOLD + 0.1 - t) / 0.5, 0.0, 1.0)
	_splash_root.draw_rect(Rect2(0.0, 0.0, 480.0, 270.0), Color(0.0, 0.0, 0.02, bg_a))
	# A few twinkling stars.
	for i: int in range(48):
		var sx: float = fmod(float(i) * 97.31, 480.0)
		var sy: float = fmod(float(i) * 53.77 + float(i * i) * 0.37, 270.0)
		var tw: float = 0.35 + 0.65 * absf(sin(t * 2.2 + float(i) * 1.7))
		var sc: Color = Color("#9ab6e8") if i % 3 != 0 else Color("#ffe854")
		_splash_root.draw_rect(Rect2(floorf(sx), floorf(sy), 1.0, 1.0), Color(sc.r, sc.g, sc.b, tw * bg_a * 0.8))
	var font: Font = PixelArt.ui_font if PixelArt.ui_font != null else ThemeDB.fallback_font
	var top: String = "PRESENTED BY"
	var name_txt: String = "CLAUDE"
	var w1: float = font.get_string_size(top, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ).x
	var w2: float = font.get_string_size(name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ * 3).x
	var rise: float = (1.0 - clampf(t / SPLASH_IN, 0.0, 1.0)) * 6.0
	_splash_root.draw_string(font, Vector2(round((480.0 - w1) * 0.5), 112.0 + rise), top, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color(0.6, 0.71, 0.91, txt_a))
	var y2: float = 150.0 + rise
	_splash_root.draw_string(font, Vector2(round((480.0 - w2) * 0.5) + 2.0, y2 + 2.0), name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ * 3, Color(0.24, 0.1, 0.0, txt_a))
	_splash_root.draw_string(font, Vector2(round((480.0 - w2) * 0.5), y2), name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ * 3, Color(1.0, 0.91, 0.33, txt_a))
	var line_w: float = w2 * clampf((t - 0.2) / SPLASH_IN, 0.0, 1.0)
	_splash_root.draw_rect(Rect2(round((480.0 - line_w) * 0.5), y2 + 10.0, line_w, 1.0), Color(1.0, 0.59, 0.14, txt_a))


func _run_smoke_test() -> void:
	var smoke_ok: bool = true
	if not _splash_showing():
		push_error("SMOKE: the intro splash did not open at startup")
		smoke_ok = false
	_update_splash(1.0)
	var skip_key: InputEventKey = InputEventKey.new()
	skip_key.pressed = true
	skip_key.physical_keycode = KEY_SPACE
	_unhandled_input(skip_key)
	if _splash_showing() or _splash_layer.visible:
		push_error("SMOKE: a key press did not skip the intro splash")
		smoke_ok = false
	_enter_stats()
	_enter_options()
	if not _smoke_check_input_prompts():
		get_tree().quit(1)
		return
	if not _smoke_check_options_nav():
		smoke_ok = false
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
	# Fleet Ship Loadout Bay: every ship, and the scrolling roster keeps the cursor on screen
	# (stepping through, paging with the arrows, wrapping around with the keyboard).
	_enter_loadout()
	for s_idx: int in range(SkillTreeData.SHIPS.size()):
		_select_loadout_slot(s_idx)
		InputPrompts.set_gamepad(not InputPrompts.is_gamepad)
		if s_idx < _loadout_first or s_idx >= _loadout_first + LOADOUT_VISIBLE:
			push_error("SMOKE: loadout slot %d selected but scrolled off screen" % s_idx)
			smoke_ok = false
	_page_loadout(-1)
	_page_loadout(-1)
	_page_loadout(-1)
	var wrap_key: InputEventKey = InputEventKey.new()
	wrap_key.pressed = true
	wrap_key.physical_keycode = KEY_LEFT
	wrap_key.keycode = KEY_LEFT
	_unhandled_input(wrap_key)
	if _loadout_cursor_idx != SkillTreeData.SHIPS.size() - 1 or not _loadout_arrow_l.visible or _loadout_arrow_r.visible:
		push_error("SMOKE: loadout paging / wrap-around left the roster in the wrong place")
		smoke_ok = false
	if not _smoke_check_speed_up():
		smoke_ok = false
	if not _smoke_check_soundtrack():
		smoke_ok = false
	if not _smoke_check_fps_option():
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
	if not _smoke_check_themed_enemies():
		smoke_ok = false
	if not _smoke_check_stage_modules():
		smoke_ok = false
	# Exercise every ship's signature blaster, beams, addons, rerolls, and Lazarus revive!
	for ship_d: Dictionary in SkillTreeData.SHIPS:
		MetaSave.tree_levels["ship_" + String(ship_d["id"])] = 1
		MetaSave.select_ship(String(ship_d["id"]))
		player.reset_for_new_run()
		player._fire_primary()
	MetaSave.select_ship("neko")
	player.reset_for_new_run()
	if not _smoke_check_ship_shots():
		smoke_ok = false
	if not _smoke_check_new_weapons():
		smoke_ok = false
	if not _smoke_check_ship_runs():
		smoke_ok = false
	if not _smoke_check_option_trail():
		smoke_ok = false
	if not await _smoke_check_sub_weapons():
		smoke_ok = false
	if not _smoke_check_boss_rigs():
		smoke_ok = false
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
	# Every registered stage, built-in and module: background, song, the generic enemies, the
	# boss and the stage's own enemies.
	for st_i: int in range(StageData.stage_count()):
		starfield.set_stage(st_i)
		starfield._process(0.02)
		GenesisMusic.play_stage(st_i)
		GenesisMusic._step = 140
		GenesisMusic._process(0.02)
		GenesisMusic._step = 280
		GenesisMusic._process(0.02)
		for t: GameEnemy.Type in [GameEnemy.Type.SCOUT_SINE, GameEnemy.Type.SWOOPER, GameEnemy.Type.SNIPER, GameEnemy.Type.CRUISER, GameEnemy.Type.BOSS]:
			_spawn_enemy_now({"type": t, "pos": Vector2(360.0, 130.0), "hp_mult": 1.0, "phase": 0.0, "squad": 1, "stage": st_i})
		# The stage's own enemies too, so the draft-card effects below also hit them.
		for t_key: int in GameEnemy.THEMED.keys():
			if int((GameEnemy.THEMED[t_key] as Dictionary)["stage"]) == st_i:
				_spawn_enemy_now({"type": t_key as GameEnemy.Type, "pos": Vector2(330.0, 120.0), "hp_mult": 1.0, "phase": 0.0, "squad": -1, "stage": st_i})
		var st_module: RefCounted = StageData.get_module(st_i)
		if st_module != null:
			for kind: String in st_module.call("get_enemy_kinds"):
				_spawn_enemy_now({"type": GameEnemy.Type.MODULE, "kind": kind, "pos": Vector2(330.0, 120.0), "hp_mult": 1.0, "phase": 0.0, "squad": -1, "stage": st_i})
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
	if not _smoke_check_draft_selection():
		smoke_ok = false
	InputPrompts.set_gamepad(not InputPrompts.is_gamepad)
	_refresh_draft_selection()
	InputPrompts.set_gamepad(not InputPrompts.is_gamepad)
	_reroll_draft_cards()
	_pick_draft_card(0)
	_begin_hyperspace_jump()
	_update_hyperspace(1.5)
	_update_hyperspace(1.5)
	player.invuln_timer = 0.0
	player.take_player_hit()
	MetaSave.scrap = 777
	_opt_reset_btn.pressed.emit()
	if MetaSave.scrap != 777 or _opt_reset_btn.text != "PRESS AGAIN":
		push_error("SMOKE: one press of RESET SAVE should only ask for confirmation")
		smoke_ok = false
	_opt_reset_btn.pressed.emit()
	if MetaSave.scrap != 0 or _opt_reset_btn.text != "RESET SAVE":
		push_error("SMOKE: a second press of RESET SAVE should wipe the save")
		smoke_ok = false
	MetaSave.reset_save()
	if not _smoke_speed_is(false, "at the end of the smoke test"):
		smoke_ok = false
	_smoke_finish(smoke_ok)


# The last checks need real frames (draw hooks only run inside a frame's draw pass), so the
# result is printed a couple of frames later. Audio is stopped first: sounds that start
# playing in those frames would still be held by the audio server at exit and get reported
# as leaked instances.
func _smoke_finish(smoke_ok: bool) -> void:
	GenesisMusic.stop_music()
	RetroSfx.muted = true
	for p: AudioStreamPlayer in RetroSfx._players:
		p.stop()
	if not await _smoke_check_module_draws():
		smoke_ok = false
	if not smoke_ok:
		push_error("STAR_VIPER_SMOKE_TEST_FAILED")
		get_tree().quit(1)
		return
	print("STAR_VIPER_SMOKE_TEST_PASSED")
	get_tree().quit(0)


# Stage-signature enemies: every sprite exists, every type runs its behaviour for a few seconds
# (home stage and first loop, both variants), kills award once, children are capped and give no
# Scrap, and the difficulty table only ever gets harder.
func _smoke_check_themed_enemies() -> bool:
	var ok: bool = true
	for key: String in EnemyArt.KEYS:
		if not PixelArt._cache.has(key):
			push_error("SMOKE: missing enemy sprite " + key)
			ok = false
	for t_key: int in GameEnemy.THEMED.keys():
		var def: Dictionary = GameEnemy.THEMED[t_key]
		if not PixelArt._cache.has(String(def["tex"])):
			push_error("SMOKE: missing sprite for themed enemy %d" % t_key)
			ok = false

	var prev: Dictionary = StageData.get_difficulty(0)
	if float(prev["hp"]) != 1.0 or float(prev["shot_speed"]) != 1.0 or float(prev["fire_rate"]) != 1.0 or float(prev["pace"]) != 1.0:
		push_error("SMOKE: stage 1 must stay the 1.0 difficulty baseline")
		ok = false
	# Every stage, built-in and module, then the first stage of the next loop.
	for st_i: int in range(1, StageData.stage_count() + 1):
		var row: Dictionary = StageData.get_difficulty(st_i)
		for k: String in ["hp", "shot_speed", "fire_rate", "groups"]:
			if float(row[k]) < float(prev[k]):
				push_error("SMOKE: difficulty '%s' drops at stage %d" % [k, st_i + 1])
				ok = false
		if float(row["pace"]) > float(prev["pace"]):
			push_error("SMOKE: difficulty pace eases off at stage %d" % (st_i + 1))
			ok = false
		prev = row

	# Run every type through its behaviour: telegraphs, shots, children, leaving the screen.
	for t_key: int in GameEnemy.THEMED.keys():
		var home: int = int((GameEnemy.THEMED[t_key] as Dictionary)["stage"])
		for loop_i: int in range(2):
			for v: int in range(2):
				var e: GameEnemy = _smoke_spawn(t_key as GameEnemy.Type, Vector2(330.0, 110.0 + 40.0 * float(v)), home + loop_i * StageData.stage_count(), v)
				for step: int in range(70):
					if e._dead:
						break
					e._process(0.05)
					if e.global_position.x < 140.0 and e.global_position.x > -20.0:
						e.global_position.x = 330.0
		_update_wave_director(0.0)
	for b_node: Node in bullet_layer.get_children():
		if b_node is GameBullet and not (b_node as GameBullet).is_player_bullet:
			(b_node as GameBullet)._process(0.6)
	_smoke_clear_enemies()

	# A kill awards score, Scrap and XP exactly once; an asteroid's chunks give XP but no Scrap
	# and don't split again.
	var kills_0: int = run_kills
	var scrap_0: int = run_scrap
	var xp_0: int = run_xp_dropped
	var rock: GameEnemy = _smoke_spawn(GameEnemy.Type.ASTEROID, Vector2(300.0, 130.0), 0, 0)
	var queued_0: int = _spawn_queue.size()
	rock.take_damage(9999.0)
	rock.take_damage(9999.0)
	if run_kills != kills_0 + 1 or run_xp_dropped != xp_0 + rock.xp_drop or run_scrap <= scrap_0:
		push_error("SMOKE: asteroid kill rewards wrong (kills %d, xp %d)" % [run_kills - kills_0, run_xp_dropped - xp_0])
		ok = false
	if _spawn_queue.size() != queued_0 + GameEnemy.ROCK_CHUNKS:
		push_error("SMOKE: asteroid queued %d chunks" % (_spawn_queue.size() - queued_0))
		ok = false
	_update_wave_director(0.0)
	var chunks: Array[GameEnemy] = _smoke_live_enemies(GameEnemy.Type.ROCK_CHUNK)
	if chunks.size() != GameEnemy.ROCK_CHUNKS:
		push_error("SMOKE: %d rock chunks spawned" % chunks.size())
		ok = false
	var scrap_1: int = run_scrap
	var xp_1: int = run_xp_dropped
	var queued_1: int = _spawn_queue.size()
	for c: GameEnemy in chunks:
		c.take_damage(9999.0)
	if run_scrap != scrap_1 or run_xp_dropped != xp_1 + chunks.size() or _spawn_queue.size() != queued_1:
		push_error("SMOKE: rock chunks must give 1 XP, no Scrap, and not split")
		ok = false

	# A mine layer drops exactly MINES_PER_LAYER mines; a mine that bursts on its own isn't a kill.
	_smoke_clear_enemies()
	var layer: GameEnemy = _smoke_spawn(GameEnemy.Type.MINE_LAYER, Vector2(300.0, 100.0), 0, 0)
	var queued_2: int = _spawn_queue.size()
	for i: int in range(80):
		layer.global_position.x = 300.0
		layer._process(0.2)
	if _spawn_queue.size() - queued_2 != GameEnemy.MINES_PER_LAYER:
		push_error("SMOKE: mine layer dropped %d mines" % (_spawn_queue.size() - queued_2))
		ok = false
	_update_wave_director(0.0)
	var kills_2: int = run_kills
	for m: GameEnemy in _smoke_live_enemies(GameEnemy.Type.SPACE_MINE):
		for i: int in range(20):
			if not m._dead:
				m._process(0.2)
	if run_kills != kills_2 or not _smoke_live_enemies(GameEnemy.Type.SPACE_MINE).is_empty():
		push_error("SMOKE: unshot mines must burst on their own without counting as kills")
		ok = false

	# Viruses replicate, but never past VIRUS_MAX_GEN generations or VIRUS_CAP alive, and copies
	# give no Scrap.
	_smoke_clear_enemies()
	for i: int in range(6):
		_smoke_spawn(GameEnemy.Type.VIRUS, Vector2(300.0 + float(i) * 12.0, 60.0 + float(i) * 30.0), 7, 0)
	for round_i: int in range(4):
		for vir: GameEnemy in _smoke_live_enemies(GameEnemy.Type.VIRUS):
			vir._aux_timer = 0.0
			vir._process(0.01)
		_update_wave_director(0.0)
	var viruses: Array[GameEnemy] = _smoke_live_enemies(GameEnemy.Type.VIRUS)
	if viruses.size() > GameEnemy.VIRUS_CAP or viruses.size() <= 6:
		push_error("SMOKE: %d viruses after replicating (cap %d)" % [viruses.size(), GameEnemy.VIRUS_CAP])
		ok = false
	for vir: GameEnemy in viruses:
		if vir.gen > GameEnemy.VIRUS_MAX_GEN or (vir.gen > 0 and vir.scrap_drop != 0):
			push_error("SMOKE: virus copy gen %d gives %d Scrap" % [vir.gen, vir.scrap_drop])
			ok = false

	# Golem shield: 20% damage while closed, 150% while open.
	_smoke_clear_enemies()
	var golem: GameEnemy = _smoke_spawn(GameEnemy.Type.GOLEM, Vector2(380.0, 130.0), 5, 0)
	golem._state = 0
	var hp_a: float = golem.hp
	golem.take_damage(10.0)
	golem._state = 1
	var hp_b: float = golem.hp
	golem.take_damage(10.0)
	if not is_equal_approx(hp_a - hp_b, 2.0) or not is_equal_approx(hp_b - golem.hp, 15.0):
		push_error("SMOKE: golem shield took %.1f / %.1f" % [hp_a - hp_b, hp_b - golem.hp])
		ok = false

	# Leaving the screen is not a kill; a lava blob can't be hit while it's still bubbling.
	var kills_3: int = run_kills
	var score_3: int = score
	var drifter: GameEnemy = _smoke_spawn(GameEnemy.Type.ASTEROID, Vector2(-60.0, 130.0), 0, 0)
	drifter._process(0.05)
	if not drifter._dead or run_kills != kills_3 or score != score_3:
		push_error("SMOKE: an enemy leaving the screen must not count as a kill")
		ok = false
	var blob: GameEnemy = _smoke_spawn(GameEnemy.Type.LAVA_BLOB, Vector2(300.0, 266.0), 5, 0)
	var blob_hp: float = blob.hp
	blob.take_damage(999.0)
	if blob._dead or blob.hp != blob_hp or blob.collision_layer != 0 or blob.is_in_group("enemies"):
		push_error("SMOKE: a bubbling lava blob must be untouchable")
		ok = false
	blob._process(1.0)
	if blob.collision_layer != 4 or not blob.is_in_group("enemies"):
		push_error("SMOKE: lava blob did not leap out")
		ok = false
	var eel: GameEnemy = _smoke_spawn(GameEnemy.Type.EEL, Vector2(400.0, 130.0), 6, 0)
	var eel_shapes: int = 0
	for c_node: Node in eel.get_children():
		if c_node is CollisionShape2D:
			eel_shapes += 1
	if eel_shapes != 1 + GameEnemy.EEL_SEGMENTS:
		push_error("SMOKE: eel has %d hit shapes" % eel_shapes)
		ok = false

	# Frost puffs slow the ship without hurting it; bombs burst on the floor; spores home in.
	var hp_before: int = player.hp
	player.frost_timer = 0.0
	var puff: GameBullet = GameBullet.new()
	bullet_layer.add_child(puff)
	puff.setup(player.global_position, Vector2(-10.0, 0.0), 1.0, false, "bullet_frost_0", 0, false, 5.0, fx_layer)
	puff.make_frost(1.5, 2.6, "bullet_frost_1")
	puff._on_area_entered(player)
	if player.frost_timer <= 0.0 or player.hp != hp_before:
		push_error("SMOKE: frost puff should slow, not damage")
		ok = false
	player.frost_timer = 0.0
	var bomb: GameBullet = GameBullet.new()
	bullet_layer.add_child(bomb)
	bomb.setup(Vector2(200.0, 245.0), Vector2(0.0, 40.0), 1.0, false, "bullet_enemy_bomb", 0, false, 3.5, fx_layer)
	bomb.floor_burst = 3
	var shots_before: int = bullet_layer.get_child_count()
	bomb._process(0.1)
	if bullet_layer.get_child_count() < shots_before + 3:
		push_error("SMOKE: blimp bomb did not burst on the floor")
		ok = false
	var spore: GameBullet = GameBullet.new()
	bullet_layer.add_child(spore)
	spore.setup(player.global_position + Vector2(60.0, -60.0), Vector2(0.0, -60.0), 1.0, false, "bullet_enemy_spore", 0, false, 3.0, fx_layer)
	spore.home_target = player
	spore.home_time = 1.0
	spore.home_rate = 3.0
	var dir_before: float = spore.velocity.angle()
	spore._process(0.2)
	if is_equal_approx(spore.velocity.angle(), dir_before):
		push_error("SMOKE: spore did not turn toward the ship")
		ok = false
	_smoke_clear_enemies()
	return ok


# Stage modules (stages 9+): every module in the registry loads and registers, and every module
# plus the 09_example template (registered only for these checks) is wired end to end: its
# tables, every sprite it refers to, each enemy type through its behaviour and its death, the
# boss through its intro, three phases and death, the background painted and animated, the song
# rendered, and the wave director queueing its four waves.
func _smoke_check_stage_modules() -> bool:
	var ok: bool = true
	var listed: int = 0
	for path: String in StageData.Registry.MODULES:
		if path != "":
			listed += 1
	if StageData.stage_count() != StageData.BUILTIN_STAGES + listed:
		push_error("SMOKE: %d stages registered, expected %d (a module in registry.gd failed to load)" % [StageData.stage_count(), StageData.BUILTIN_STAGES + listed])
		ok = false
	var example: RefCounted = _smoke_register_example()
	if example == null:
		return false
	var saved_wave: int = wave
	var saved_stage: int = current_stage_idx
	for m: RefCounted in StageData.get_modules():
		if not _smoke_check_module(m):
			ok = false
	if not _smoke_no_missing_module_art():
		ok = false
	StageData.unregister_module(example)
	if StageData.stage_count() != StageData.BUILTIN_STAGES + listed:
		push_error("SMOKE: unregistering the example module left %d stages" % StageData.stage_count())
		ok = false
	wave = saved_wave
	current_stage_idx = saved_stage
	_pending_hyperspace = false
	_smoke_clear_enemies()
	_spawn_queue.clear()
	starfield.set_stage(current_stage_idx)
	GenesisMusic.play_stage(current_stage_idx)
	return ok


# A behaviour asked for a sprite, or a background for a layer, that doesn't exist.
func _smoke_no_missing_module_art() -> bool:
	var ok: bool = true
	for key: Variant in StageEnemyBase.missing_sprites.keys():
		push_error("SMOKE: a stage enemy used missing sprite '%s'" % String(key))
		ok = false
	for key2: Variant in StageBackgroundBase.missing_layers.keys():
		push_error("SMOKE: a stage background used missing layer '%s'" % String(key2))
		ok = false
	return ok


func _smoke_register_example() -> RefCounted:
	var example: RefCounted = StageData.load_module(StageData.Registry.EXAMPLE)
	if example == null or StageData.register_module(example) < 0:
		push_error("SMOKE: the example stage module did not load and register")
		return null
	return example


func _smoke_check_module(m: RefCounted) -> bool:
	var ok: bool = true
	var st_i: int = int(m.get("stage_index"))
	var st: Dictionary = StageData.get_stage(st_i)
	var id: String = String(st["id"])
	var tag: String = "stage %d (%s)" % [st_i + 1, id]
	for err: String in StageData.validate_module(m):
		push_error("SMOKE: " + err)
		ok = false
	if StageData.get_module(st_i) != m or not StageData.is_module_stage(st_i):
		push_error("SMOKE: %s is not where the registry put it" % tag)
		ok = false
	# The HUD label must fit at the boss wave, even once the stage number has two digits.
	var font: Font = PixelArt.ui_font
	var hud_head: String = "%d-BOSS " % maxi(st_i + 1, 10)
	if _fit_hud_stage_text(font, hud_head, String(st["name"])) != hud_head + String(st["name"]):
		push_error("SMOKE: %s name '%s' is too long for the HUD (keep '%sNAME' within %d px)" % [tag, String(st["name"]), hud_head, int(HUD_STAGE_TEXT_W)])
		ok = false

	# Sprites: everything the stage refers to exists, and its own keys carry its id.
	StageData.prepare_stage(st_i)
	if not StageData.is_stage_art_ready(st_i):
		push_error("SMOKE: %s sprites were not installed" % tag)
		ok = false
	for key: Variant in (m.call("build_art") as Dictionary).keys():
		if not String(key).contains(id):
			push_error("SMOKE: %s sprite key '%s' must contain the stage id" % [tag, String(key)])
			ok = false
	var need: Array[String] = []
	for k: String in ["scout_tex", "swooper_tex", "sniper_tex", "cruiser_tex", "bullet_a", "bullet_b"]:
		need.append(String(st[k]))
	for f: int in range(3):
		need.append("%s_%d" % [String(st["boss_tex"]), f])
	var kinds: Array[String] = m.call("get_enemy_kinds")
	for kind: String in kinds:
		need.append(String(StageData.get_enemy_def(st_i, kind)["tex"]))
	for key2: String in need:
		if not PixelArt._cache.has(key2):
			push_error("SMOKE: %s is missing sprite %s" % [tag, key2])
			ok = false

	# Background: the module's layers are painted, active and animate.
	starfield.set_stage(st_i)
	if starfield._theme != id or starfield._module_bg == null or starfield._tex.is_empty():
		push_error("SMOKE: %s background did not activate" % tag)
		ok = false
	for i: int in range(40):
		starfield._process(0.05)

	# Music: the stage's song (and any alternatives) render finite, audible audio.
	GenesisMusic.play_stage(st_i)
	if GenesisMusic.current_stage_idx != st_i or GenesisMusic._song.is_empty():
		push_error("SMOKE: %s song did not load" % tag)
		ok = false
	if not _smoke_song_renders(tag):
		ok = false
	var slot: String = "stage_%d" % (st_i + 1)
	if not GenesisMusic.get_slot_keys().has(slot):
		push_error("SMOKE: %s has no soundtrack slot" % tag)
		ok = false
	for alt: int in range(1, GenesisMusic.candidate_count(slot) + 1):
		GenesisMusic.preview(slot, alt)
		if not _smoke_song_renders("%s alternative #%d" % [tag, alt]):
			ok = false
	GenesisMusic.end_preview()

	# Every enemy type runs its behaviour (home stage and first loop, both variants).
	_smoke_clear_enemies()
	for kind: String in kinds:
		for loop_i: int in range(2):
			for v: int in range(2):
				var e: GameEnemy = _smoke_spawn_module(kind, Vector2(330.0, 110.0 + 40.0 * float(v)), st_i + loop_i * StageData.stage_count(), v)
				if e.enemy_type != GameEnemy.Type.MODULE or e._behaviour == null or e.max_hp <= 0.0:
					push_error("SMOKE: %s enemy '%s' did not set up" % [tag, kind])
					ok = false
				for step: int in range(70):
					if e._dead:
						break
					e._process(0.05)
					if e.global_position.x < 140.0 and e.global_position.x > -20.0:
						e.global_position.x = 330.0
			_update_wave_director(0.0)
	for b_node: Node in bullet_layer.get_children():
		if b_node is GameBullet and not (b_node as GameBullet).is_player_bullet:
			(b_node as GameBullet)._process(0.6)
	_smoke_clear_enemies()

	# A kill pays out exactly once; children it spawns give no Scrap.
	for kind: String in kinds:
		var e2: GameEnemy = _smoke_spawn_module(kind, Vector2(300.0, 130.0), st_i, 0)
		for step2: int in range(60):
			if e2._warn_timer <= 0.0:
				break
			e2._process(0.05)
		var kills_0: int = run_kills
		e2.take_damage(1.0e9)
		e2.take_damage(1.0e9)
		if not e2._dead or run_kills != kills_0 + 1:
			push_error("SMOKE: %s enemy '%s' kill counted %d times" % [tag, kind, run_kills - kills_0])
			ok = false
		_update_wave_director(0.0)
		for node: Node in enemy_layer.get_children():
			var child: GameEnemy = node as GameEnemy
			if child != null and child.gen > 0 and child.scrap_drop != 0:
				push_error("SMOKE: %s child enemy '%s' gives Scrap" % [tag, child.module_kind])
				ok = false
		_smoke_clear_enemies()

	# The boss: intro, attacks, all three phases, death.
	var boss: GameEnemy = _spawn_enemy_now({"type": GameEnemy.Type.BOSS, "pos": Vector2(420.0, -110.0), "hp_mult": 1.0, "phase": 0.0, "squad": -1, "stage": st_i})
	if boss._boss_ai == null or boss.max_hp <= 0.0:
		push_error("SMOKE: %s boss has no AI" % tag)
		ok = false
	for step3: int in range(60):
		boss._process(0.05)
	if boss.boss_intro_active:
		push_error("SMOKE: %s boss intro did not finish" % tag)
		ok = false
	var shots_0: int = bullet_layer.get_child_count()
	for step4: int in range(40):
		boss._process(0.1)
	if bullet_layer.get_child_count() <= shots_0:
		push_error("SMOKE: %s boss never fired" % tag)
		ok = false
	for want_phase: int in [2, 3]:
		boss.take_damage(boss.max_hp * 0.4)
		for step5: int in range(30):
			boss._process(0.1)
		if boss.boss_phase != want_phase:
			push_error("SMOKE: %s boss did not reach phase %d" % [tag, want_phase])
			ok = false
	boss._start_boss_death_sequence()
	for step6: int in range(20):
		if not boss._dead:
			boss._process(0.1)
	if not boss._dead:
		push_error("SMOKE: %s boss did not die" % tag)
		ok = false
	_smoke_clear_enemies()
	for b2: Node in bullet_layer.get_children():
		b2.queue_free()

	# The wave director queues the stage's own enemies in its three waves and the boss in the fourth.
	for w: int in range(1, StageData.WAVES_PER_STAGE + 1):
		wave = st_i * StageData.WAVES_PER_STAGE + w - 1
		_begin_next_wave()
		var own: int = 0
		var bosses: int = 0
		for item: Dictionary in _spawn_queue:
			if item.has("kind"):
				own += 1
			if GameEnemy.Type.BOSS == item["type"]:
				bosses += 1
		if current_stage_idx != st_i or (w < StageData.WAVES_PER_STAGE and own == 0) or (w == StageData.WAVES_PER_STAGE and bosses != 1):
			push_error("SMOKE: %s wave %d queued %d own enemies, %d bosses" % [tag, w, own, bosses])
			ok = false
		for step7: int in range(60):
			_update_wave_director(0.1)
		for node2: Node in enemy_layer.get_children():
			if node2 is GameEnemy:
				(node2 as GameEnemy)._process(0.1)
		_smoke_clear_enemies()
		_spawn_queue.clear()
	for b3: Node in bullet_layer.get_children():
		b3.queue_free()
	return ok


# The current song renders finite, audible audio from its start and from mid-song.
func _smoke_song_renders(what: String) -> bool:
	var loudest: float = 0.0
	for start: int in [0, 300]:
		GenesisMusic._step = start
		var buf: PackedVector2Array = GenesisMusic._render_block(2048)
		if buf.size() != 2048:
			push_error("SMOKE: %s song failed to render" % what)
			return false
		for v: Vector2 in buf:
			if is_nan(v.x) or is_nan(v.y) or absf(v.x) > 1.0 or absf(v.y) > 1.0:
				push_error("SMOKE: %s song rendered a bad sample" % what)
				return false
			loudest = maxf(loudest, absf(v.x))
	if loudest < 0.01:
		push_error("SMOKE: %s song is silent" % what)
		return false
	return true


# Draw hooks only run inside a frame's draw pass: one background per module stage, plus every
# module enemy (sampled at several ages, to catch its different telegraphs) and boss, are drawn
# together over two frames. A broken draw() shows up as a script error, and a node that was
# never drawn, or a missing sprite or layer, fails the test.
func _smoke_check_module_draws() -> bool:
	var ok: bool = true
	var example: RefCounted = _smoke_register_example()
	if example == null:
		return false
	var holder: Node2D = Node2D.new()
	add_child(holder)
	var drawn: Dictionary = {}
	var nodes: Array[CanvasItem] = []
	for m: RefCounted in StageData.get_modules():
		var st_i: int = int(m.get("stage_index"))
		var sb: StarfieldBg = StarfieldBg.new()
		sb.stage_idx = st_i
		holder.add_child(sb)
		sb.set_process(false)
		sb._process(0.05)
		nodes.append(sb)
		for kind: String in m.call("get_enemy_kinds"):
			for age_i: int in range(8):
				var e: GameEnemy = _smoke_spawn_module(kind, Vector2(330.0, 70.0 + 18.0 * float(age_i)), st_i, age_i % 2)
				for step0: int in range(1 + age_i * 8):
					if e._dead:
						break
					e._process(0.05)
					if e.global_position.x < 140.0:
						e.global_position.x = 330.0
				e.set_process(false)
				nodes.append(e)
		var boss: GameEnemy = _spawn_enemy_now({"type": GameEnemy.Type.BOSS, "pos": Vector2(420.0, -110.0), "hp_mult": 1.0, "phase": 0.0, "squad": -1, "stage": st_i})
		for step: int in range(60):
			boss._process(0.05)
		boss.set_process(false)
		nodes.append(boss)
	for n: CanvasItem in nodes:
		n.draw.connect(func() -> void: drawn[n.get_instance_id()] = true)
		n.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	for n2: CanvasItem in nodes:
		if is_instance_valid(n2) and n2.is_inside_tree() and not drawn.has(n2.get_instance_id()):
			push_error("SMOKE: %s was never drawn" % n2.name)
			ok = false
	if not _smoke_no_missing_module_art():
		ok = false
	holder.queue_free()
	_smoke_clear_enemies()
	StageData.unregister_module(example)
	return ok


# Ships and their shots. Every ship's sprites, shot preview and tree icon exist (texture lookups
# fail silently), and no player shot bounces (Matt's call): each signature weapon and the prism
# beam fly straight on, are freed just past the screen edge, and keep their heading through a hit.
# Options trail the ship by distance flown, whatever the frame rate. At 120 Hz one frame moves
# the ship under PlayerShip.TRAIL_STEP_DIST (more so in focus mode), and the options used to
# freeze there, following only at 2x speed. Fly 0.7 px per 1/120 s frame and they must keep up.
# Only one sub weapon fires at a time (player.SUB_WEAPONS): drafting one switches to it, the
# swap button (E / pad B / touch SWAP) cycles the owned ones, and the others go quiet: their guns
# stop firing and the options and blades leave the screen. A hull perk's addon starts active.
func _smoke_check_sub_weapons() -> bool:
	var ok: bool = true
	_smoke_clear_enemies()
	MetaSave.select_ship("neko")
	player.reset_for_new_run()
	player.global_position = Vector2(80.0, 134.0)
	player.controls_enabled = true
	player.auto_fire_toggle = true
	if player.sub_weapon != "" or not player.owned_sub_weapons().is_empty():
		push_error("SMOKE: a fresh neko run already has a sub weapon (%s)" % player.sub_weapon)
		ok = false
	player.apply_run_upgrade("missile")
	player.swap_sub_weapon() # only one owned: stays
	if player.sub_weapon != "missile":
		push_error("SMOKE: drafting Homing Pods did not make them the sub weapon (%s)" % player.sub_weapon)
		ok = false
	player.apply_run_upgrade("turret")
	player.apply_run_upgrade("option")
	player.apply_run_upgrade("blades")
	player.apply_run_upgrade("laser") # an exotic ship mounts it next to its gun: a sub weapon
	if player.sub_weapon != "beam" or player.owned_sub_weapons() != ["option", "blades", "turret", "missile", "beam"]:
		push_error("SMOKE: sub weapons after drafting are wrong: %s of %s" % [player.sub_weapon, str(player.owned_sub_weapons())])
		ok = false
	# Each one fires (or flies) alone; the swap button walks the owned list and wraps.
	var walk: Array[String] = ["option", "blades", "turret", "missile", "beam"]
	for want: String in walk:
		var key_ev: InputEventKey = InputEventKey.new()
		key_ev.pressed = true
		key_ev.physical_keycode = KEY_E
		player._unhandled_input(key_ev)
		if player.sub_weapon != want:
			push_error("SMOKE: the swap key went to %s, expected %s" % [player.sub_weapon, want])
			ok = false
			continue
		for shot_node: Node in bullet_layer.get_children():
			shot_node.queue_free()
		await get_tree().process_frame
		for f: int in range(90):
			player._process(1.0 / 60.0)
		var counts: Dictionary = {
			"turret": _smoke_count_shots("bullet_dart"), "missile": _smoke_count_shots("bullet_missile"),
			"beam": _smoke_count_shots("bullet_laser"),
		}
		for id: String in counts:
			if (int(counts[id]) > 0) != (id == want):
				push_error("SMOKE: with %s active, %s fired %d shots" % [want, id, int(counts[id])])
				ok = false
		var opts_up: int = 0
		for opt: Sprite2D in player._option_sprites:
			opts_up += 1 if opt.visible else 0
		var blades_up: int = 0
		for bl: Sprite2D in player._blade_sprites:
			blades_up += 1 if bl.visible else 0
		if (opts_up > 0) != (want == "option") or (blades_up > 0) != (want == "blades"):
			push_error("SMOKE: with %s active, %d options and %d blades are out" % [want, opts_up, blades_up])
			ok = false
	var pad_ev: InputEventJoypadButton = InputEventJoypadButton.new()
	pad_ev.pressed = true
	pad_ev.button_index = JOY_BUTTON_B
	player._unhandled_input(pad_ev)
	if player.sub_weapon != "option":
		push_error("SMOKE: pad B did not wrap the sub weapon round to the first (%s)" % player.sub_weapon)
		ok = false
	# A hull perk's built-in addon is the starting sub weapon.
	MetaSave.select_ship("hog")
	player.reset_for_new_run()
	if player.sub_weapon != "turret":
		push_error("SMOKE: the hog does not start with its turret as the sub weapon (%s)" % player.sub_weapon)
		ok = false
	for shot_node: Node in bullet_layer.get_children():
		shot_node.queue_free()
	player.controls_enabled = false
	MetaSave.select_ship("neko")
	player.reset_for_new_run()
	return ok


# The animated stage 1-8 bosses (scripts/bosses/): each rigged stage's boss uses its rig instead of
# the painted frames, has a dino pilot, fires from the rig's muzzles (every attack pattern), runs
# every reaction, and on death the pilot bails out in an escape pod that cleans itself up.
const SMOKE_RIG_MUZZLES: Dictionary = {
	0: ["cannon_top", "cannon_bot", "core", "ring"],
	1: ["stinger", "claw_top", "claw_bot"],
	2: ["maw", "spread", "ring"],
	3: ["scythe_top", "scythe_bot", "mouth"],
}


func _smoke_check_boss_rigs() -> bool:
	var ok: bool = true
	var DinoPilotScript: GDScript = load("res://scripts/bosses/dino_pilot.gd")
	for sp: String in (DinoPilotScript.get("SPECIES") as Dictionary).keys():
		for ex: String in DinoPilotScript.get("EXPRESSIONS"):
			var face: Texture2D = DinoPilotScript.call("face_texture", sp, ex)
			if face == null or face.get_width() < 20:
				push_error("SMOKE: dino pilot %s has no %s face" % [sp, ex])
				ok = false
	for st_i: int in SMOKE_RIG_MUZZLES.keys():
		_smoke_clear_enemies()
		var boss: GameEnemy = _spawn_enemy_now({"type": GameEnemy.Type.BOSS, "pos": Vector2(414.0, 134.0), "hp_mult": 1.0, "phase": 0.0, "squad": 1, "stage": st_i})
		if boss == null or boss._rig == null or boss._rig.pilot == null or boss._sprite.texture != null:
			push_error("SMOKE: stage %d boss is not its animated rig with a dino pilot" % (st_i + 1))
			ok = false
			continue
		boss.boss_intro_active = false
		boss.boss_hp_bar_visible = true
		boss.global_position = Vector2(414.0, 134.0)
		var rig: Node2D = boss._rig
		for f: int in range(10):
			boss._process(1.0 / 60.0)
			rig.call("_process", 1.0 / 60.0)
		for m_name: String in SMOKE_RIG_MUZZLES[st_i]:
			var mz: Vector2 = boss._bm(m_name, Vector2(9999.0, 9999.0))
			if mz.distance_to(boss.global_position) > 130.0:
				push_error("SMOKE: stage %d boss muzzle %s is missing or off the boss (%s)" % [st_i + 1, m_name, str(mz)])
				ok = false
		# Every pattern fires, with the reactions in between.
		for pat: int in range(3):
			boss._boss_pattern = pat
			boss._boss_substep = 0
			var before: int = bullet_layer.get_child_count()
			rig.call("on_attack", pat)
			boss._boss_attack()
			if bullet_layer.get_child_count() <= before:
				push_error("SMOKE: stage %d boss pattern %d fired nothing" % [st_i + 1, pat])
				ok = false
			rig.call("on_hurt")
			for f2: int in range(6):
				rig.call("_process", 1.0 / 60.0)
		rig.call("on_pose")
		boss._enter_next_boss_phase(2)
		boss._enter_next_boss_phase(3)
		for f3: int in range(20):
			boss._process(1.0 / 60.0)
			rig.call("_process", 1.0 / 60.0)
		if not bool(rig.get("pilot").get("low_hp")):
			push_error("SMOKE: stage %d boss pilot is not panicking in phase 3" % (st_i + 1))
			ok = false
		var pods_before: int = _smoke_count_pods()
		boss._start_boss_death_sequence()
		boss._finish_boss_death()
		if _smoke_count_pods() != pods_before + 1:
			push_error("SMOKE: stage %d boss pilot did not bail out in an escape pod" % (st_i + 1))
			ok = false
	# The pods fly off and free themselves.
	for pod: Node in fx_layer.get_children():
		if pod.get_script() != null and String((pod.get_script() as Script).resource_path).ends_with("pilot_pod.gd"):
			for f4: int in range(300):
				pod.call("_process", 1.0 / 60.0)
			if not pod.is_queued_for_deletion():
				push_error("SMOKE: an escape pod never left")
				ok = false
	for shot_node: Node in bullet_layer.get_children():
		shot_node.queue_free()
	_smoke_clear_enemies()
	return ok


func _smoke_count_pods() -> int:
	var n: int = 0
	for node: Node in fx_layer.get_children():
		if node.get_script() != null and String((node.get_script() as Script).resource_path).ends_with("pilot_pod.gd") and not node.is_queued_for_deletion():
			n += 1
	return n


func _smoke_check_option_trail() -> bool:
	var ok: bool = true
	MetaSave.select_ship("neko")
	player.reset_for_new_run()
	var start: Vector2 = Vector2(60.0, 140.0)
	player.global_position = start
	player._trail.clear()
	for i: int in range(PlayerShip.TRAIL_MAX_POINTS):
		player._trail.append(start)
	player.apply_run_upgrade("option")
	var opt: Sprite2D = player._option_sprites[0]
	opt.global_position = start
	for f: int in range(240):
		player.global_position += Vector2(0.7, 0.0)
		player._record_trail_and_options(1.0 / 120.0)
	var lag: float = player.global_position.x - opt.global_position.x
	if lag < 10.0 or lag > 45.0 or absf(opt.global_position.y - start.y) > 1.0:
		push_error("SMOKE: option drone did not follow the ship at 120 fps (ship x %.1f, option x %.1f)" % [player.global_position.x, opt.global_position.x])
		ok = false
	player.reset_for_new_run()
	return ok


func _smoke_check_ship_shots() -> bool:
	var ok: bool = true
	var modes: Array[String] = ["prism"]
	for ship_d: Dictionary in SkillTreeData.SHIPS:
		var ship_id: String = String(ship_d["id"])
		modes.append(String(ship_d["weapon_id"]))
		var opt_mode: String = player._option_mode(String(ship_d["weapon_id"]))
		if not modes.has(opt_mode):
			modes.append(opt_mode)
		var keys: Array[String] = [String(ship_d["sprite_0"]), String(ship_d["sprite_1"]), String(ship_d["bullet_preview"])]
		for def: Dictionary in SkillTreeData.NODES:
			if String(def.get("unlocks_ship", "")) == ship_id:
				keys.append(String(def["icon"]))
		for key: String in keys:
			if not PixelArt._cache.has(key):
				push_error("SMOKE: ship %s refers to missing sprite %s" % [ship_id, key])
				ok = false
	for coat: String in PlayerShip.CAT_SHOT_COATS:
		for key: String in [coat + "_0", coat + "_1"]:
			if not PixelArt._cache.has(key):
				push_error("SMOKE: missing cat shot sprite " + key)
				ok = false
	for key: String in ShipArt.KEYS:
		if not PixelArt._cache.has(key):
			push_error("SMOKE: missing ShipArt sprite " + key)
			ok = false
	for mode: String in modes:
		var mode_tex: String = String(player._get_mode_params(mode, 1)["tex"])
		if not PixelArt._cache.has(mode_tex):
			push_error("SMOKE: weapon %s uses missing sprite %s" % [mode, mode_tex])
			ok = false
	# Off the right, top and bottom edges, with nothing on screen for homing shots to chase. A
	# shot must fly on (never turn back) and be freed just past the edge, or at the end of its own
	# short life (shotgun pellets, sword waves, orbs, seed sentries, rockets that burst).
	# Beam, katana and tongue fire no bullet (null); _smoke_check_new_weapons covers them.
	_smoke_clear_enemies()
	var playfield: Rect2 = Rect2(0.0, 30.0, 480.0, 220.0)
	var near_screen: Rect2 = Rect2(-20.0, -20.0, 520.0, 310.0)
	var starts: Array[Vector2] = [Vector2(466.0, 134.0), Vector2(240.0, 40.0), Vector2(240.0, 240.0)]
	var dirs: Array[Vector2] = [Vector2.RIGHT, Vector2(1.0, -1.0).normalized(), Vector2(1.0, 1.0).normalized()]
	for mode: String in modes:
		var p: Dictionary = player._get_mode_params(mode, 4)
		for i: int in range(starts.size()):
			var shot: GameBullet = player._spawn_mode_shot(mode, 4, starts[i], dirs[i] * float(p["spd"]), 1.0, String(p["tex"]), int(p["pierce"]), 1.0)
			if shot == null:
				continue
			var timed: bool = shot.life_left > 0.0 or shot.star_burst_time > 0.0
			var turned: bool = false
			for step_i: int in range(250):
				shot._process(0.02)
				if shot.is_queued_for_deletion():
					break
				if shot.velocity.dot(dirs[i]) <= 0.0:
					turned = true
			var pos: Vector2 = shot.global_position
			var at_edge: bool = not playfield.has_point(pos) and near_screen.has_point(pos)
			if turned or not shot.is_queued_for_deletion() or not (at_edge or timed):
				push_error("SMOKE: %s shot from %s turned back or was not freed at the screen edge (at %s)" % [mode, str(starts[i]), str(pos)])
				ok = false
			shot.queue_free()
	# An enemy hit: piercing shots fly on with the same heading, the rest are spent.
	var target: GameEnemy = _smoke_spawn(GameEnemy.Type.CRUISER, Vector2(300.0, 134.0), 0, 0)
	for mode: String in modes:
		var p: Dictionary = player._get_mode_params(mode, 4)
		var shot: GameBullet = player._spawn_mode_shot(mode, 4, target.global_position - Vector2(4.0, 0.0), Vector2(float(p["spd"]), 0.0), 0.01, String(p["tex"]), int(p["pierce"]), 1.0)
		if shot == null or shot.collision_mask == 0:
			continue # no bullet, or a seed sentry (it only shoots)
		var pierce_before: int = shot.pierce_left
		target.hp = target.max_hp
		shot._on_area_entered(target)
		if pierce_before > 0:
			if shot.is_queued_for_deletion() or shot.pierce_left != pierce_before - 1 or shot.velocity.x <= 0.0 or absf(shot.velocity.y) > 1.0:
				push_error("SMOKE: an enemy hit stopped or turned a piercing %s shot" % mode)
				ok = false
		elif not shot.is_queued_for_deletion():
			push_error("SMOKE: a spent %s shot was not freed on its hit" % mode)
			ok = false
		shot.queue_free()
	if int(player._get_mode_params("prism", 1)["pierce"]) < 2 or int(player._get_mode_params("cat", 1)["pierce"]) < 2 or int(player._get_mode_params("saucer", 1)["pierce"]) < 2:
		push_error("SMOKE: prism / cat / saucer shots should pierce instead of bouncing")
		ok = false
	_smoke_clear_enemies()
	return ok


func _smoke_enemy_shot(pos: Vector2) -> GameBullet:
	var b: GameBullet = GameBullet.new()
	bullet_layer.add_child(b)
	b.setup(pos, Vector2(-60.0, 0.0), 1.0, false, "bullet_enemy_pink", 0, false, 2.5, fx_layer)
	return b


# The hangar-expansion weapons that do more than fly straight: the beam stops at the screen edge
# or the first enemy, the katana cuts shots in its arc only, the tongue has a reach, seed sentries
# are capped and shoot, orbs swallow shots and grind, rockets burst, sonar ripples grow.
func _smoke_check_new_weapons() -> bool:
	var ok: bool = true
	_smoke_clear_enemies()
	player.global_position = Vector2(80.0, 134.0)
	var origin: Vector2 = player.global_position + Vector2(12.0, 0.0)
	player._lance_fx.clear()
	var screen: Rect2 = Rect2(0.0, 0.0, 480.0, 270.0)
	for dir: Vector2 in [Vector2.RIGHT, Vector2(1.0, -0.6).normalized(), Vector2(1.0, 0.6).normalized()]:
		player._fire_lance(origin, dir, 1.0)
		var end: Vector2 = origin + dir * float(player._lance_fx.back()["len"])
		if not screen.grow(1.0).has_point(end) or Rect2(1.0, 24.0, 478.0, 244.0).has_point(end):
			push_error("SMOKE: the solar lance should end at the screen edge, not at %s" % str(end))
			ok = false
	var target: GameEnemy = _smoke_spawn(GameEnemy.Type.CRUISER, Vector2(260.0, 134.0), 0, 0)
	target.hp = target.max_hp
	player._fire_lance(origin, Vector2.RIGHT, 1.0)
	if target.hp >= target.max_hp or origin.x + float(player._lance_fx.back()["len"]) > target.global_position.x:
		push_error("SMOKE: the solar lance should stop at and burn the first enemy in line")
		ok = false
	target.global_position = player.global_position + Vector2(30.0, 0.0)
	target.hp = target.max_hp
	var cut_shot: GameBullet = _smoke_enemy_shot(player.global_position + Vector2(24.0, 8.0))
	var behind_shot: GameBullet = _smoke_enemy_shot(player.global_position + Vector2(-30.0, 0.0))
	player._katana_slash(1.0, 1)
	if target.hp >= target.max_hp or not cut_shot.is_queued_for_deletion() or behind_shot.is_queued_for_deletion():
		push_error("SMOKE: the katana should cut enemies and shots in its arc, and only there")
		ok = false
	behind_shot.queue_free()
	target.global_position = player.global_position + Vector2(100.0, 0.0)
	target.hp = target.max_hp
	player._tongue_lash(origin, 1.0, 1)
	var hit_near: bool = target.hp < target.max_hp
	target.global_position = player.global_position + Vector2(320.0, 0.0)
	target.hp = target.max_hp
	player._tongue_lash(origin, 1.0, 1)
	if not hit_near or target.hp < target.max_hp:
		push_error("SMOKE: the tongue should reach an enemy 100 px away but not one 320 px away")
		ok = false
	for i: int in range(10):
		player._plant_seed(origin, 1.0)
	var live_pods: int = 0
	for pod: GameBullet in player._sentries:
		if is_instance_valid(pod) and not pod.is_queued_for_deletion():
			live_pods += 1
	if live_pods > PlayerShip.SENTRY_CAP or PlayerShip.SENTRY_CAP > 6:
		push_error("SMOKE: %d seed sentries alive (cap %d)" % [live_pods, PlayerShip.SENTRY_CAP])
		ok = false
	var shots_before: int = bullet_layer.get_child_count()
	player._sentries.back()._process(0.35)
	if bullet_layer.get_child_count() <= shots_before:
		push_error("SMOKE: a seed sentry fired no petals")
		ok = false
	var orb: GameBullet = player._spawn_mode_shot("orb", 1, Vector2(200.0, 60.0), Vector2(120.0, 0.0), 1.0, "bullet_orb_0", 99, 1.0)
	var food: GameBullet = _smoke_enemy_shot(Vector2(205.0, 62.0))
	target.global_position = Vector2(212.0, 60.0)
	target.hp = target.max_hp
	orb._process(0.02)
	if not food.is_queued_for_deletion() or target.hp >= target.max_hp or orb.velocity.length() > GameBullet.ORB_GRIP_SPEED + 1.0:
		push_error("SMOKE: a singularity orb should swallow a nearby shot and slow down grinding an enemy")
		ok = false
	orb.queue_free()
	_smoke_clear_enemies()
	var rocket: GameBullet = player._spawn_mode_shot("firework", 1, Vector2(100.0, 200.0), Vector2(250.0, 0.0), 1.0, "bullet_rocket", 0, 1.0)
	for i: int in range(40):
		rocket._process(0.02)
		if rocket.is_queued_for_deletion():
			break
	if not rocket.is_queued_for_deletion() or rocket.star_burst_count != 0:
		push_error("SMOKE: a starburst rocket should burst on its own")
		ok = false
	var ripple: GameBullet = player._spawn_mode_shot("sonar", 1, Vector2(100.0, 100.0), Vector2(230.0, 0.0), 1.0, "bullet_sonar", 99, 1.0)
	var r0: float = ripple._shape_circle.radius
	ripple._process(0.4)
	if ripple._shape_circle.radius <= r0 * 1.5:
		push_error("SMOKE: a sonar ripple should widen as it travels")
		ok = false
	ripple.queue_free()
	return ok


# Every ship in a run: hull, speed and hull perk, its weapon fires, a drafted beam mounts as an
# aux beam (the Viper's nose takes it over instead) and fires, and a second of flight runs clean.
func _smoke_check_ship_runs() -> bool:
	var ok: bool = true
	var tree_hull: int = MetaSave.get_level("hull_1") + MetaSave.get_level("hull_2")
	for ship_d: Dictionary in SkillTreeData.SHIPS:
		var sid: String = String(ship_d["id"])
		var wid: String = String(ship_d["weapon_id"])
		_smoke_clear_enemies()
		for shot_node: Node in bullet_layer.get_children():
			shot_node.queue_free()
		if not MetaSave.select_ship(sid):
			push_error("SMOKE: ship %s is not unlocked after buying the whole tree" % sid)
			ok = false
			continue
		player.reset_for_new_run()
		player.global_position = Vector2(80.0, 134.0)
		if player.max_hp != maxi(2, 4 + int(ship_d["hp_mod"]) + tree_hull) or absf(player.move_speed - float(ship_d["speed"])) > 0.01:
			push_error("SMOKE: ship %s starts with the wrong hull or speed" % sid)
			ok = false
		var perk_ok: bool = true
		match sid:
			"lancer":
				perk_ok = player.max_shield == mini(3, MetaSave.get_tree_shields() + 1)
			"ronin":
				perk_ok = player.last_stand_level == 1 and player.last_stand_ready
			"bloom":
				perk_ok = absf(MetaSave.get_heal_drop_chance() - (0.20 + 0.05 * float(MetaSave.get_level("regen_bay")))) < 0.001
			"orca":
				perk_ok = player.chrono_level == 1
			"hog":
				perk_ok = player.turret_level == 1
			"hanabi":
				perk_ok = absf(player.aoe_scale_mult - 1.25) < 0.001 and absf(MetaSave.get_boss_bounty_mult() - (1.25 + 0.25 * float(MetaSave.get_level("bounty_hunter")))) < 0.001
			"horizon":
				perk_ok = player.graze_level == 1
			"comet":
				perk_ok = player.missile_level == 1
			"gemini":
				perk_ok = MetaSave.get_starting_rerolls() == MetaSave.get_tree_rerolls() + 2 and _smoke_pods_visible()
			"frog":
				perk_ok = player.leech_level == 1
		if not perk_ok:
			push_error("SMOKE: ship %s hull perk did not apply" % sid)
			ok = false
		# Its weapon fires something: bullets, or a beam / cut / lash effect.
		var shots_before: int = bullet_layer.get_child_count()
		var fx_before: int = player._lance_fx.size() + player._slash_fx.size() + player._tongue_fx.size()
		player._fire_primary()
		player._fire_primary()
		var fx_after: int = player._lance_fx.size() + player._slash_fx.size() + player._tongue_fx.size()
		if bullet_layer.get_child_count() <= shots_before and fx_after <= fx_before:
			push_error("SMOKE: ship %s weapon fired nothing" % sid)
			ok = false
		if wid == "comet" and not _smoke_comet_charge_ok():
			ok = false
		player.apply_run_upgrade("laser")
		var mounted: bool = player.active_beam == "laser" if sid == "viper" else (player.aux_beam == "laser" and player.active_beam == wid)
		if not mounted:
			push_error("SMOKE: a drafted beam did not mount on ship %s" % sid)
			ok = false
		var lasers_before: int = _smoke_count_shots("bullet_laser")
		player.controls_enabled = true
		player.auto_fire_toggle = true
		for f: int in range(60):
			player._process(1.0 / 60.0)
		if _smoke_count_shots("bullet_laser") <= lasers_before:
			push_error("SMOKE: ship %s never fired its drafted beam" % sid)
			ok = false
	_smoke_clear_enemies()
	return ok


func _smoke_pods_visible() -> bool:
	for pod: Sprite2D in player._orbit_pods:
		if not pod.visible:
			return false
	return true


func _smoke_count_shots(tex_key: String) -> int:
	var n: int = 0
	for node: Node in bullet_layer.get_children():
		if node is GameBullet and (node as GameBullet).anim_tex_a == tex_key and not node.is_queued_for_deletion():
			n += 1
	return n


# COMET KNIGHT: a full charge fires by itself, a short tap fires nothing, an early release fires.
func _smoke_comet_charge_ok() -> bool:
	player._comet_charge = 0.0
	var n0: int = _smoke_count_shots("bullet_comet")
	player._update_comet_charge(0.4, true)
	var early: int = _smoke_count_shots("bullet_comet")
	player._update_comet_charge(0.4, true)
	var full: int = _smoke_count_shots("bullet_comet")
	player._update_comet_charge(0.05, true)
	player._update_comet_charge(0.0, false)
	var tap: int = _smoke_count_shots("bullet_comet")
	player._update_comet_charge(0.35, true)
	player._update_comet_charge(0.0, false)
	var release: int = _smoke_count_shots("bullet_comet")
	if early != n0 or full <= early or tap != full or release <= tap:
		push_error("SMOKE: comet charge fired wrongly (%d %d %d %d %d)" % [n0, early, full, tap, release])
		return false
	return true


func _smoke_spawn(t: GameEnemy.Type, pos: Vector2, stage: int, variant: int) -> GameEnemy:
	return _spawn_enemy_now({"type": t, "pos": pos, "hp_mult": 1.0, "phase": 0.0, "squad": -1, "stage": stage, "variant": variant})


func _smoke_spawn_module(kind: String, pos: Vector2, stage: int, variant: int) -> GameEnemy:
	return _spawn_enemy_now({"type": GameEnemy.Type.MODULE, "kind": kind, "pos": pos, "hp_mult": 1.0, "phase": 0.0, "squad": -1, "stage": stage, "variant": variant})


func _smoke_live_enemies(t: GameEnemy.Type) -> Array[GameEnemy]:
	var found: Array[GameEnemy] = []
	for node: Node in enemy_layer.get_children():
		if node is GameEnemy:
			var ge: GameEnemy = node as GameEnemy
			if ge.enemy_type == t and not ge._dead and not ge.is_queued_for_deletion():
				found.append(ge)
	return found


# Removes every enemy right away (the smoke test runs inside one frame, so queue_free alone
# would leave them in the tree) and drops pending child spawns, keeping the wave's own queue.
func _smoke_clear_enemies() -> void:
	for node: Node in enemy_layer.get_children():
		enemy_layer.remove_child(node)
		node.queue_free()
	var keep: Array[Dictionary] = []
	for item: Dictionary in _spawn_queue:
		if not item.has("gen"):
			keep.append(item)
	_spawn_queue = keep


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


# Options focus: UP/DOWN/LEFT/RIGHT reach every row, and the bottom row steps RESET SAVE <->
# SOUNDTRACK <-> BACK both ways (focus used to get stuck on SOUNDTRACK). Uses the same focus
# neighbours as the D-pad, arrow keys, left stick and WASD.
func _smoke_check_options_nav() -> bool:
	_open_options_from_title()
	# [direction, where focus must land: a Control, or a Button's text]. Starts on AUTOFIRE.
	var steps: Array = [
		[SIDE_TOP, "-10%"], [SIDE_TOP, "-10%"], [SIDE_RIGHT, "+10%"], [SIDE_RIGHT, "+10%"],
		[SIDE_BOTTOM, "+10%"], [SIDE_LEFT, "-10%"], [SIDE_BOTTOM, _opt_autofire_btn],
		[SIDE_LEFT, _opt_autofire_btn], [SIDE_BOTTOM, _opt_shake_btn], [SIDE_BOTTOM, _opt_touch_btn],
		[SIDE_BOTTOM, _opt_fullscreen_btn], [SIDE_RIGHT, _opt_fps_btn], [SIDE_RIGHT, _opt_fps_btn],
		[SIDE_LEFT, _opt_fullscreen_btn], [SIDE_RIGHT, _opt_fps_btn], [SIDE_BOTTOM, _opt_speed_btn],
		[SIDE_BOTTOM, _opt_soundtrack_btn], [SIDE_LEFT, _opt_reset_btn], [SIDE_LEFT, _opt_reset_btn],
		[SIDE_RIGHT, _opt_soundtrack_btn], [SIDE_RIGHT, _opt_back_btn], [SIDE_RIGHT, _opt_back_btn],
		[SIDE_LEFT, _opt_soundtrack_btn], [SIDE_RIGHT, _opt_back_btn], [SIDE_TOP, _opt_speed_btn],
		[SIDE_BOTTOM, _opt_soundtrack_btn], [SIDE_LEFT, _opt_reset_btn], [SIDE_TOP, _opt_speed_btn],
		[SIDE_BOTTOM, _opt_soundtrack_btn], [SIDE_RIGHT, _opt_back_btn], [SIDE_BOTTOM, "+10%"],
		[SIDE_TOP, _opt_back_btn],
	]
	var ok: bool = true
	for i: int in range(steps.size()):
		var step: Array = steps[i]
		_move_menu_focus(int(step[0]) as Side)
		var foc: Control = get_viewport().gui_get_focus_owner()
		var want: Variant = step[1]
		var hit: bool = (foc == want) if want is Control else (foc is Button and (foc as Button).text == String(want))
		if not hit:
			var got: String = (foc as Button).text if foc is Button else str(foc)
			push_error("SMOKE: options focus step %d (%s) landed on '%s'" % [i + 1, ["LEFT", "UP", "RIGHT", "DOWN"][int(step[0])], got])
			ok = false
			break
	_leave_options()
	return ok


# Level-up draft: the selected card (D-pad / keys / mouse hover) is lifted with the cursor over
# it and the others sit lower; LEFT/RIGHT walk the row and stop at its ends.
func _smoke_check_draft_selection() -> bool:
	if state != State.DRAFT or _draft_choices.size() < 3:
		push_error("SMOKE: level-up draft did not open with 3 cards")
		return false
	var ok: bool = true
	var btns: Array[Button] = []
	for card: Dictionary in _draft_cards:
		btns.append(card["btn"] as Button)
	# [move (or -1 for a mouse move over card 0), card that must be selected afterwards]
	for step: Array in [[SIDE_RIGHT, 2], [SIDE_RIGHT, 2], [SIDE_LEFT, 1], [SIDE_LEFT, 0], [SIDE_LEFT, 0], [SIDE_TOP, 0], [SIDE_RIGHT, 1], [-1, 0]]:
		if int(step[0]) < 0:
			var hover: InputEventMouseMotion = InputEventMouseMotion.new()
			hover.position = btns[0].size * 0.5
			btns[0].gui_input.emit(hover)
		else:
			_move_menu_focus(int(step[0]) as Side)
		_refresh_draft_selection()
		var want: int = int(step[1])
		for i: int in range(btns.size()):
			var lifted: bool = btns[i].position.y < DRAFT_CARD_Y
			if btns[i].has_focus() != (i == want) or lifted != (i == want):
				push_error("SMOKE: draft card %d selection/lift wrong (wanted card %d selected)" % [i, want])
				ok = false
		var cursor_cx: float = _draft_cursor.position.x + _draft_cursor.texture.get_size().x * 0.5
		var card_cx: float = btns[want].position.x + btns[want].size.x * 0.5
		if not _draft_cursor.visible or absf(cursor_cx - card_cx) > 1.0:
			push_error("SMOKE: draft cursor is not over the selected card %d" % want)
			ok = false
		if not ok:
			break
	return ok


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
# Options -> FPS cycles 30/60/120/UNLOCKED, applies Engine.max_fps, survives save + load, and at
# 30 FPS player shots get the sweep capsule that stops them skipping over small hitboxes.
func _smoke_check_fps_option() -> bool:
	var ok: bool = true
	var saved_cap: int = MetaSave.fps_cap
	_open_options_from_title()
	MetaSave.fps_cap = 60
	MetaSave.apply_frame_rate()
	var want: Array[int] = [120, 0, 30, 60, 120]
	for w: int in want:
		_opt_fps_btn.pressed.emit()
		var label: String = str(w) if w > 0 else "UNLOCKED"
		if MetaSave.fps_cap != w or Engine.max_fps != w or not _opt_fps_btn.text.ends_with(label):
			push_error("SMOKE: FPS option should be %d, got cap %d, max_fps %d, '%s'" % [w, MetaSave.fps_cap, Engine.max_fps, _opt_fps_btn.text])
			ok = false
	MetaSave.fps_cap = 30
	MetaSave.save_game()
	MetaSave.fps_cap = 60
	MetaSave.load_game()
	if MetaSave.fps_cap != 30:
		push_error("SMOKE: FPS option did not survive save + load (got %d)" % MetaSave.fps_cap)
		ok = false
	MetaSave.apply_frame_rate()
	var shot: GameBullet = GameBullet.new()
	bullet_layer.add_child(shot)
	shot.setup(Vector2(100.0, 140.0), Vector2(600.0, 0.0), 1.0, true, "bullet_vulcan")
	shot.global_position = Vector2(110.0, 140.0)
	shot._update_sweep(Vector2(100.0, 140.0))
	if shot._sweep_node == null or shot._sweep_node.disabled:
		push_error("SMOKE: at 30 FPS player shots have no sweep capsule")
		ok = false
	MetaSave.fps_cap = 60
	MetaSave.apply_frame_rate()
	shot._update_sweep(Vector2(100.0, 140.0))
	if shot._sweep_node == null or not shot._sweep_node.disabled:
		push_error("SMOKE: at 60 FPS the sweep capsule should be off")
		ok = false
	shot.queue_free()
	_leave_options()
	MetaSave.fps_cap = saved_cap
	MetaSave.apply_frame_rate()
	MetaSave.save_game()
	return ok


func _smoke_check_soundtrack() -> bool:
	var ok: bool = true
	var saved_picks: Dictionary = MetaSave.music_picks.duplicate()
	var slot_keys: Array[String] = GenesisMusic.get_slot_keys()
	for slot: Variant in GenesisMusic.DEFAULT_PICKS:
		var pick: int = int(GenesisMusic.DEFAULT_PICKS[slot])
		if not slot_keys.has(String(slot)) or pick < 0 or pick > GenesisMusic.candidate_count(String(slot)):
			push_error("SMOKE: default soundtrack pick %s #%d does not exist" % [String(slot), pick])
			ok = false
	for slot: String in GenesisMusic.get_slot_keys():
		var count: int = GenesisMusic.candidate_count(slot)
		var alts: int = count - (1 if GenesisMusic.has_recording(slot) else 0)
		# The built-in slots ship 5 alternatives each; a stage module's are optional.
		if alts != 5 and not GenesisMusic.is_module_slot(slot):
			push_error("SMOKE: soundtrack slot %s has %d alternatives, expected 5" % [slot, alts])
			ok = false
		for idx: int in range(count + 1):
			GenesisMusic.preview(slot, idx)
			if idx > 0 and idx == GenesisMusic.recording_index(slot):
				if not _smoke_check_recording(slot):
					ok = false
				continue
			if GenesisMusic._file_player.playing:
				push_error("SMOKE: soundtrack %s #%d left a recording playing" % [slot, idx])
				ok = false
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
	if after != (before + 1) % (GenesisMusic.candidate_count("stage_1") + 1) or int(MetaSave.music_picks.get("stage_1", -1)) != after:
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
	if not _smoke_check_recording_save():
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


# A recorded track (music_tracks.gd) plays on its own player instead of the synth, loads with its
# loop set up, and Godot's loop really jumps from loop_end to loop_start: one second played from
# half a second before loop_end must end half a second into the loop, with real, finite audio all
# the way. (Within 5 ms: the reported position runs ~60 samples ahead of the audio, since the
# resampler reads ahead. The loop itself was measured exact to the sample.)
func _smoke_check_recording(slot: String) -> bool:
	var track: Dictionary = GenesisMusic._song
	var stream: AudioStreamMP3 = GenesisMusic._file_player.stream as AudioStreamMP3
	if not track.has("file") or stream == null or not GenesisMusic._file_player.playing or GenesisMusic._player.playing:
		push_error("SMOKE: the recording for %s is not playing (or the synth still is)" % slot)
		return false
	var rate: float = GenesisMusic.MIX_RATE
	var loop_start: float = float(track["loop_start"]) / rate
	var loop_end: float = float(track["loop_end"]) / rate
	if not stream.loop or loop_start <= 0.0 or loop_end <= loop_start + 1.0 or loop_end > stream.get_length():
		push_error("SMOKE: the recording for %s has bad loop points (%.3f..%.3f s of %.3f s)" % [slot, loop_start, loop_end, stream.get_length()])
		return false
	var ok: bool = true
	var pb: AudioStreamPlayback = stream.instantiate_playback()
	pb.start(loop_end - 0.5)
	var buf: PackedVector2Array = pb.mix_audio(1.0, int(rate))
	var want: float = loop_start + 0.5
	if pb.get_loop_count() != 1 or absf(pb.get_playback_position() - want) > 0.005:
		push_error("SMOKE: the recording for %s did not loop on its loop points (%d loops, at %.5f s, expected %.5f s)" % [slot, pb.get_loop_count(), pb.get_playback_position(), want])
		ok = false
	var loudest: float = 0.0
	for v: Vector2 in buf:
		if is_nan(v.x) or is_nan(v.y) or is_inf(v.x) or is_inf(v.y):
			push_error("SMOKE: the recording for %s decoded a bad sample" % slot)
			return false
		loudest = maxf(loudest, absf(v.x))
	if buf.size() != int(rate) or loudest < 0.01:
		push_error("SMOKE: the recording for %s is silent or cut short (%d frames)" % [slot, buf.size()])
		ok = false
	return ok


# A slot with a recording defaults to it. A save written before the slot had one loses its pick
# there, once (so the player hears the new song), and keeps its other picks; a pick made after
# that sticks.
func _smoke_check_recording_save() -> bool:
	var ok: bool = true
	var keep: Dictionary = MetaSave.music_picks.duplicate()
	GenesisMusic.set_picks({})
	for slot: String in GenesisMusic.get_slot_keys():
		if GenesisMusic.has_recording(slot) and GenesisMusic.get_pick(slot) != GenesisMusic.recording_index(slot):
			push_error("SMOKE: soundtrack slot %s does not default to its recording" % slot)
			ok = false
	var rec_slot: String = String(GenesisMusic.Tracks.TRACKS.keys()[0])
	# An old save: a synth pick on that slot, and no "music_recordings" list.
	MetaSave.music_picks = {rec_slot: 2, "title": 1}
	MetaSave.save_game()
	var rf: FileAccess = FileAccess.open(MetaSave.SAVE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(rf.get_as_text())
	rf.close()
	var data: Dictionary = parsed as Dictionary
	data.erase("music_recordings")
	var wf: FileAccess = FileAccess.open(MetaSave.SAVE_PATH, FileAccess.WRITE)
	wf.store_string(JSON.stringify(data, "\t"))
	wf.close()
	MetaSave.load_game()
	if MetaSave.music_picks.has(rec_slot) or int(MetaSave.music_picks.get("title", -1)) != 1:
		push_error("SMOKE: loading an old save did not drop its %s pick for the recording, or lost another pick: %s" % [rec_slot, str(MetaSave.music_picks)])
		ok = false
	MetaSave.music_picks[rec_slot] = 2
	MetaSave.save_game()
	MetaSave.load_game()
	if int(MetaSave.music_picks.get(rec_slot, -1)) != 2:
		push_error("SMOKE: a %s pick made after its recording arrived did not survive save + load" % rec_slot)
		ok = false
	MetaSave.music_picks = keep
	GenesisMusic.set_picks(keep)
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
	player.sub_weapon_changed.connect(func(_id: String) -> void: _sync_touch_hud_visibility())


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

	touch_swap_btn = Button.new()
	touch_swap_btn.position = Vector2(412.0, 196.0)
	touch_swap_btn.size = Vector2(62.0, 26.0)
	touch_swap_btn.text = "SWAP"
	touch_swap_btn.focus_mode = Control.FOCUS_NONE
	_style_menu_btn(touch_swap_btn, Color("#ffe854"))
	touch_swap_btn.pressed.connect(func() -> void: player.swap_sub_weapon())
	touch_swap_btn.visible = false
	ui_layer.add_child(touch_swap_btn)

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
	_opt_fullscreen_btn.size = Vector2(182.0, 23.0)
	_style_menu_btn(_opt_fullscreen_btn)
	_opt_fullscreen_btn.pressed.connect(func() -> void:
		MetaSave.fullscreen_enabled = not MetaSave.fullscreen_enabled
		MetaSave.apply_audio_and_display_settings()
		MetaSave.save_game()
		RetroSfx.play("ui", -7.0, 0.02)
		_refresh_options_ui()
	)
	options_panel.add_child(_opt_fullscreen_btn)

	_opt_fps_btn = Button.new()
	_opt_fps_btn.position = Vector2(238.0, 175.0)
	_opt_fps_btn.size = Vector2(182.0, 23.0)
	_style_menu_btn(_opt_fps_btn)
	_opt_fps_btn.pressed.connect(_cycle_fps_cap)
	options_panel.add_child(_opt_fps_btn)

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
	# Wiping the save takes two presses within 3 s (a controller can land on this button by accident).
	reset_btn.pressed.connect(func() -> void:
		if Time.get_ticks_msec() < _reset_armed_until_ms:
			_disarm_reset()
			MetaSave.reset_save()
			RetroSfx.play("explode", -8.0, 0.02)
			_refresh_options_ui()
		else:
			_reset_armed_until_ms = Time.get_ticks_msec() + 3000
			reset_btn.text = "PRESS AGAIN"
			RetroSfx.play("ui", -4.0, 0.0)
			get_tree().create_timer(3.0).timeout.connect(func() -> void:
				if Time.get_ticks_msec() >= _reset_armed_until_ms:
					_disarm_reset()
			)
	)
	reset_btn.focus_exited.connect(_disarm_reset)
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
	_opt_reset_btn = reset_btn
	_opt_back_btn = back_btn

	# Explicit focus paths. Godot's automatic search takes the nearest control whose far edge
	# lies past this one's, so LEFT/RIGHT on the bottom row jumped up to the full-width SPEED UP
	# row (4 px above, nearer than RESET SAVE / BACK 6 px to the side), and DOWN from there came
	# back to SOUNDTRACK: RESET SAVE and BACK were unreachable by D-pad, stick and keys.
	_link_focus_grid([
		[m_minus, m_plus],
		[s_minus, s_plus],
		[_opt_autofire_btn],
		[_opt_shake_btn],
		[_opt_touch_btn],
		[_opt_fullscreen_btn, _opt_fps_btn],
		[_opt_speed_btn],
		[reset_btn, _opt_soundtrack_btn, back_btn],
	])


# Sets every focus neighbour of a menu given as rows of sibling controls (top to bottom, each
# left to right). LEFT/RIGHT step along a row and stop at its ends; UP/DOWN go to the control in
# the next row whose centre is closest horizontally, wrapping between the last and first rows.
func _link_focus_grid(rows: Array) -> void:
	for r: int in range(rows.size()):
		var row: Array = rows[r]
		var above: Array = rows[posmod(r - 1, rows.size())]
		var below: Array = rows[posmod(r + 1, rows.size())]
		for c: int in range(row.size()):
			var ctrl: Control = row[c] as Control
			var left: Control = (row[c - 1] as Control) if c > 0 else ctrl
			var right: Control = (row[c + 1] as Control) if c < row.size() - 1 else ctrl
			ctrl.focus_neighbor_left = ctrl.get_path_to(left)
			ctrl.focus_neighbor_right = ctrl.get_path_to(right)
			ctrl.focus_neighbor_top = ctrl.get_path_to(_closest_in_row(ctrl, above))
			ctrl.focus_neighbor_bottom = ctrl.get_path_to(_closest_in_row(ctrl, below))


func _closest_in_row(from: Control, row: Array) -> Control:
	var from_x: float = from.position.x + from.size.x * 0.5
	var best: Control = row[0] as Control
	var best_d: float = INF
	for item: Variant in row:
		var ctrl: Control = item as Control
		var d: float = absf(ctrl.position.x + ctrl.size.x * 0.5 - from_x)
		if d < best_d:
			best_d = d
			best = ctrl
	return best


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

	for i: int in range(SND_ROWS):
		var y: float = 32.0 + float(i) * 16.0
		var row: Button = Button.new()
		row.position = Vector2(46.0, y)
		row.size = Vector2(388.0, 15.0)
		row.flat = true
		row.focus_mode = Control.FOCUS_NONE
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# Labels are filled in by _refresh_soundtrack_ui() (asking for them here would make
		# StageData register the stage modules during startup).
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
	var slot: String = GenesisMusic.get_slot_keys()[i]
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
	var keys: Array[String] = GenesisMusic.get_slot_keys()
	_snd_row_idx = clampi(_snd_row_idx, 0, keys.size() - 1)
	# Scroll just enough to keep the selected slot on screen.
	_snd_scroll = clampi(_snd_scroll, maxi(0, _snd_row_idx - SND_ROWS + 1), mini(_snd_row_idx, maxi(0, keys.size() - SND_ROWS)))
	for i: int in range(_snd_row_btns.size()):
		var si: int = _snd_scroll + i
		_snd_row_btns[i].visible = si < keys.size()
		_snd_value_lbls[i].visible = si < keys.size()
		if si >= keys.size():
			continue
		var slot: String = keys[si]
		var idx: int = GenesisMusic.get_pick(slot)
		var sel: bool = si == _snd_row_idx
		var name_txt: String = GenesisMusic.candidate_name(slot, idx)
		_snd_row_btns[i].text = _snd_slot_label(si)
		_snd_value_lbls[i].text = ("< %s >" % name_txt) if idx == 0 else ("< #%d  %s >" % [idx, name_txt])
		_snd_value_lbls[i].add_theme_color_override("font_color", Color("#ffe854") if sel else (Color("#9ab6e8") if idx == 0 else Color("#dce6ff")))
	_snd_cursor.position = Vector2(46.0, 32.0 + float(_snd_row_idx - _snd_scroll) * 16.0)
	var cur_slot: String = keys[_snd_row_idx]
	var cur_idx: int = GenesisMusic.get_pick(cur_slot)
	_snd_info_lbl.text = "%d/%d  %s" % [cur_idx, GenesisMusic.candidate_count(cur_slot), GenesisMusic.candidate_info(cur_slot, cur_idx)]


# The selected soundtrack slot.
func _snd_slot() -> String:
	var keys: Array[String] = GenesisMusic.get_slot_keys()
	return keys[clampi(_snd_row_idx, 0, keys.size() - 1)]


func _snd_preview_current() -> void:
	var slot: String = _snd_slot()
	GenesisMusic.preview(slot, GenesisMusic.get_pick(slot))
	_snd_hyper_timer = 0.0


func _snd_move_row(dir: int) -> void:
	var n: int = GenesisMusic.get_slot_keys().size()
	_snd_row_idx = posmod(_snd_row_idx + dir, n)
	RetroSfx.play("ui", -11.0, 0.03)
	_refresh_soundtrack_ui()
	_snd_preview_current()


func _snd_change_track(dir: int) -> void:
	var slot: String = _snd_slot()
	var count: int = GenesisMusic.candidate_count(slot) + 1
	var idx: int = posmod(GenesisMusic.get_pick(slot) + dir, count)
	MetaSave.music_picks[slot] = idx
	GenesisMusic.set_picks(MetaSave.music_picks)
	MetaSave.save_game()
	_refresh_soundtrack_ui()
	_snd_preview_current()


# Mouse / touch: tap a row to select it (and hear it); tap the selected row again for its next track.
# i is the on-screen row; the list may be scrolled.
func _on_snd_row_clicked(i: int) -> void:
	var si: int = _snd_scroll + i
	if si == _snd_row_idx:
		_snd_change_track(1)
	else:
		_snd_row_idx = si
		RetroSfx.play("ui", -11.0, 0.03)
		_refresh_soundtrack_ui()
		_snd_preview_current()


func _disarm_reset() -> void:
	_reset_armed_until_ms = 0
	if _opt_reset_btn != null:
		_opt_reset_btn.text = "RESET SAVE"


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
# FLEET SHIP LOADOUT BAY (every ship in a scrolling roster, signature weapons & starter perks)
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

	# Ship roster across the top (y = 32..98): a row of slots that scrolls so the cursor stays in
	# view, LOADOUT_VISIBLE at a time, with page arrows at the ends when more ships are off screen.
	var row_clip: Control = Control.new()
	row_clip.position = Vector2(15.0, 32.0)
	row_clip.size = Vector2(LOADOUT_SLOT_W * float(LOADOUT_VISIBLE) - 3.5, 66.0)
	row_clip.clip_contents = true
	row_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loadout_panel.add_child(row_clip)
	_loadout_row = Control.new()
	_loadout_row.size = Vector2(LOADOUT_SLOT_W * float(SkillTreeData.SHIPS.size()), 66.0)
	_loadout_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_clip.add_child(_loadout_row)
	_loadout_arrow_l = _make_loadout_arrow("<", Vector2(2.0, 50.0), -1)
	_loadout_arrow_r = _make_loadout_arrow(">", Vector2(467.0, 50.0), 1)

	_loadout_ship_btns.clear()
	_loadout_ship_icons.clear()
	_loadout_ship_names.clear()
	for i: int in range(SkillTreeData.SHIPS.size()):
		var btn: Button = Button.new()
		btn.position = Vector2(float(i) * LOADOUT_SLOT_W, 0.0)
		btn.size = Vector2(61.0, 66.0)
		var slot_i: int = i
		btn.focus_entered.connect(func() -> void: _select_loadout_slot(slot_i))
		btn.pressed.connect(func() -> void: _activate_loadout_slot(slot_i))
		_loadout_row.add_child(btn)
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
	# Left / right wrap around the roster (the keyboard handler wraps too).
	var ship_n: int = _loadout_ship_btns.size()
	for i: int in range(ship_n):
		_loadout_ship_btns[i].focus_neighbor_left = _loadout_ship_btns[(i - 1 + ship_n) % ship_n].get_path()
		_loadout_ship_btns[i].focus_neighbor_right = _loadout_ship_btns[(i + 1) % ship_n].get_path()

	# Live Ship Showcase & Loadout Spec Card (y = 104..224)
	var spec_card: Panel = Panel.new()
	spec_card.position = Vector2(15.0, 104.0)
	spec_card.size = Vector2(450.0, 118.0)
	spec_card.add_theme_stylebox_override("panel", _make_ff6_box(Color("#060c28"), Color("#5c7cc4"), 1, 4.0))
	loadout_panel.add_child(spec_card)

	_loadout_stats_lbl = Label.new()
	_loadout_stats_lbl.position = Vector2(21.0, 106.0)
	_loadout_stats_lbl.size = Vector2(136.0, 12.0)
	_loadout_stats_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_loadout_stats_lbl.add_theme_color_override("font_color", Color("#9cb4e8"))
	loadout_panel.add_child(_loadout_stats_lbl)

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
	_loadout_nav_btns = [l_title_btn, l_tree_btn, _loadout_action_btn]


func _make_loadout_arrow(txt: String, pos: Vector2, dir: int) -> Button:
	var b: Button = Button.new()
	b.position = pos
	b.size = Vector2(11.0, 30.0)
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", FONT_SZ)
	b.add_theme_color_override("font_color", Color("#ffe854"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _make_ff6_box(Color("#0d1746"), Color("#ffe854"), 1, 1.0))
	b.add_theme_stylebox_override("hover", _make_ff6_box(Color("#253f9e"), Color.WHITE, 1, 1.0))
	b.add_theme_stylebox_override("pressed", _make_ff6_box(Color("#253f9e"), Color.WHITE, 1, 1.0))
	b.pressed.connect(func() -> void: _page_loadout(dir))
	loadout_panel.add_child(b)
	return b


# Page arrows: jump the cursor a screenful of ships left or right.
func _page_loadout(dir: int) -> void:
	_select_loadout_slot(clampi(_loadout_cursor_idx + dir * LOADOUT_VISIBLE, 0, SkillTreeData.SHIPS.size() - 1))
	_loadout_ship_btns[_loadout_cursor_idx].grab_focus()
	RetroSfx.play("ui", -11.0, 0.03)


# Scrolls the roster just far enough that slot idx is on screen.
func _scroll_loadout_to(idx: int, snap: bool) -> void:
	if idx < _loadout_first:
		_loadout_first = idx
	elif idx >= _loadout_first + LOADOUT_VISIBLE:
		_loadout_first = idx - LOADOUT_VISIBLE + 1
	_loadout_first = clampi(_loadout_first, 0, maxi(0, SkillTreeData.SHIPS.size() - LOADOUT_VISIBLE))
	_loadout_arrow_l.visible = _loadout_first > 0
	_loadout_arrow_r.visible = _loadout_first + LOADOUT_VISIBLE < SkillTreeData.SHIPS.size()
	if snap:
		_loadout_row.position.x = -float(_loadout_first) * LOADOUT_SLOT_W
	# Up from the bottom bar lands on the ship under the cursor, never on an off-screen one.
	for nav: Button in _loadout_nav_btns:
		nav.focus_neighbor_top = _loadout_ship_btns[idx].get_path()


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

	_scroll_loadout_to(_loadout_cursor_idx, true)
	_refresh_loadout_ui()
	_loadout_ship_btns[_loadout_cursor_idx].grab_focus()


func _select_loadout_slot(idx: int) -> void:
	_loadout_cursor_idx = clampi(idx, 0, SkillTreeData.SHIPS.size() - 1)
	_scroll_loadout_to(_loadout_cursor_idx, false)
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
		_loadout_stats_lbl.text = "HULL %d  SPEED %d" % [4 + int(cur["hp_mod"]), int(float(cur["speed"]))]
	else:
		_loadout_stats_lbl.text = "HULL ?  SPEED ?"

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
	if MetaSave.get_tree_shields() > 0:
		tags.append("Shield x%d" % MetaSave.get_tree_shields())
	if MetaSave.has_lazarus_revive():
		tags.append("Lazarus Revive")
	if MetaSave.get_tree_rerolls() > 0:
		tags.append("%d Rerolls" % MetaSave.get_tree_rerolls())
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


# A sub weapon's pause-screen entry: dimmed unless it's the one firing (see player.SUB_WEAPONS).
func _sub_module(id: String, entry: Dictionary) -> Dictionary:
	if not player.is_sub_active(id):
		entry["col"] = (entry["col"] as Color).darkened(0.5)
	return entry


func _collect_installed_modules() -> Array[Dictionary]:
	var modules: Array[Dictionary] = []
	var main_lvl: int = player.beam_level if (player.signature_weapon == "vulcan" and player.active_beam != "vulcan") else (
		1 + player.weapon_overclock
	)
	modules.append(_get_beam_badge_info(player.active_beam, main_lvl))
	if player.aux_beam != "":
		modules.append(_sub_module("beam", _get_beam_badge_info(player.aux_beam, player.beam_level)))
	if player.option_count > 0:
		modules.append(_sub_module("option", {"icon": "badge_option", "name": "Option Drone", "val": "x%d" % player.option_count, "col": Color("#ff9624")}))
	if player.blade_level > 0:
		modules.append(_sub_module("blades", {"icon": "badge_blades", "name": "Orbital Blades", "val": "Lv%d" % player.blade_level, "col": Color("#54f4ff")}))
	if player.turret_level > 0:
		modules.append(_sub_module("turret", {"icon": "badge_turret", "name": "Auto-Turret", "val": "Lv%d" % player.turret_level, "col": Color("#6eff8c")}))
	if player.missile_level > 0:
		modules.append(_sub_module("missile", {"icon": "badge_missile", "name": "Homing Pods", "val": "Lv%d" % player.missile_level, "col": Color("#ff4c68")}))
	if player.flank_level > 0:
		modules.append(_sub_module("flank", {"icon": "badge_flank", "name": "Flank Guns", "val": "Lv%d" % player.flank_level, "col": Color("#ffe854")}))
	if player.bomb_level > 0:
		modules.append(_sub_module("bomb", {"icon": "badge_bomb", "name": "Gravity Bombs", "val": "Lv%d" % player.bomb_level, "col": Color("#d44cff")}))
	if player.nova_level > 0:
		modules.append(_sub_module("nova", {"icon": "badge_nova", "name": "Nova Coil", "val": "Lv%d" % player.nova_level, "col": Color("#ffd84c")}))
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

	# A light dim only, so the frozen run stays visible around the cards.
	var dim: ColorRect = ColorRect.new()
	dim.position = Vector2(0.0, 20.0)
	dim.size = Vector2(VIEW_W, 230.0)
	dim.color = Color(0.02, 0.03, 0.10, 0.5)
	draft_panel.add_child(dim)

	_draft_title_lbl = PromptBar.new()
	_draft_title_lbl.position = Vector2(0.0, 54.0)
	_draft_title_lbl.size = Vector2(VIEW_W, 16.0)
	_draft_title_lbl.align = HORIZONTAL_ALIGNMENT_CENTER
	_draft_title_lbl.text_color = Color("#ffe854")
	_draft_title_lbl.set_segments(["LEVEL UP! SELECT UPGRADE  ", {"act": "draft_pick"}])
	draft_panel.add_child(_draft_title_lbl)
	InputPrompts.device_changed.connect(func(_is_pad: bool) -> void: _refresh_draft_selection())

	_draft_cards.clear()
	var cw: float = DRAFT_CARD_W
	var row_x: float = floorf((VIEW_W - 3.0 * cw - 2.0 * DRAFT_CARD_GAP) * 0.5)
	var card_btns: Array[Button] = []
	for i: int in range(3):
		var btn: Button = Button.new()
		btn.position = Vector2(row_x + float(i) * (cw + DRAFT_CARD_GAP), DRAFT_CARD_Y)
		btn.size = Vector2(cw, DRAFT_CARD_H)
		# _refresh_draft_selection swaps the normal/hover faces itself; no extra focus overlay.
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var idx: int = i
		btn.pressed.connect(func() -> void: _pick_draft_card(idx))
		btn.focus_entered.connect(_refresh_draft_selection, CONNECT_DEFERRED)
		btn.focus_exited.connect(_refresh_draft_selection, CONNECT_DEFERRED)
		# Moving the mouse over a card selects it, so hover and D-pad / keys share one highlight.
		btn.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseMotion and not btn.has_focus():
				btn.grab_focus()
		)
		draft_panel.add_child(btn)
		card_btns.append(btn)

		var title_lbl: Label = Label.new()
		title_lbl.position = Vector2(0.0, 4.0)
		title_lbl.size = Vector2(cw, 12.0)
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_font_size_override("font_size", FONT_SZ)
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(title_lbl)

		# Second line: what picks this card (key cap 1/2/3, or A on the selected card), then the
		# category and rank pips. _refresh_draft_selection centres the pair.
		var pick_glyph: TextureRect = TextureRect.new()
		pick_glyph.position = Vector2(4.0, 16.0)
		pick_glyph.stretch_mode = TextureRect.STRETCH_KEEP
		pick_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(pick_glyph)

		var pips_lbl: Label = Label.new()
		pips_lbl.position = Vector2(0.0, 17.0)
		pips_lbl.size = Vector2(cw, 12.0)
		pips_lbl.add_theme_font_size_override("font_size", FONT_SZ)
		pips_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(pips_lbl)

		var art_bg: Panel = Panel.new()
		art_bg.position = Vector2(floorf((cw - 68.0) * 0.5), 30.0)
		art_bg.size = Vector2(68.0, 44.0)
		art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_bg.add_theme_stylebox_override("panel", _make_ff6_box(Color("#050818"), Color("#4c6cb0"), 1))
		btn.add_child(art_bg)

		# 28x18 card art at exactly 2x.
		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.position = Vector2(art_bg.position.x + 6.0, 34.0)
		icon_rect.size = Vector2(56.0, 36.0)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_rect)

		var short_lbl: Label = Label.new()
		short_lbl.position = Vector2(3.0, 77.0)
		short_lbl.size = Vector2(cw - 6.0, 22.0)
		short_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		short_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		short_lbl.add_theme_font_size_override("font_size", FONT_SZ)
		short_lbl.add_theme_color_override("font_color", Color.WHITE)
		short_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(short_lbl)

		# Selected: brighter fill and a thick white frame that sticks out 2 px past the card.
		var box_sel: StyleBoxFlat = _make_ff6_box(Color("#1d3796"), Color.WHITE, 3)
		box_sel.set_expand_margin_all(2.0)
		var box_press: StyleBoxFlat = _make_ff6_box(Color("#2c50c4"), Color.WHITE, 3)
		box_press.set_expand_margin_all(2.0)
		_draft_cards.append({
			"btn": btn,
			"title_lbl": title_lbl,
			"pips_lbl": pips_lbl,
			"icon_rect": icon_rect,
			"short_lbl": short_lbl,
			"pick_glyph": pick_glyph,
			"box_idle": _make_ff6_box(Color("#0a1236"), Color.WHITE, 2),  # border = card colour
			"box_sel": box_sel,
			"box_press": box_press,
		})
	# LEFT/RIGHT walk the row and stop at the ends; UP/DOWN stay put.
	_link_focus_grid([card_btns])

	_draft_cursor = TextureRect.new()
	_draft_cursor.texture = PixelArt.tex("ui_cursor_down")
	_draft_cursor.stretch_mode = TextureRect.STRETCH_KEEP
	_draft_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draft_panel.add_child(_draft_cursor)

	_draft_reroll_btn = Button.new()
	_draft_reroll_btn.position = Vector2(160.0, 200.0)
	_draft_reroll_btn.size = Vector2(160.0, 22.0)
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
	touch_swap_btn.visible = false
	banner_label.visible = false


func _sync_touch_hud_visibility() -> void:
	var show_touch: bool = (state == State.PLAYING) and (
		MetaSave.touch_mode == 1 or (MetaSave.touch_mode == 0 and player.touch_detected)
	)
	touch_focus_btn.visible = show_touch
	touch_swap_btn.visible = show_touch and player.owned_sub_weapons().size() >= 2


func _pause_game() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	_pre_pause_speed = starfield.speed_scale
	starfield.speed_scale = 0.0
	player.clear_touch_drag()
	world_root.process_mode = Node.PROCESS_MODE_DISABLED
	touch_focus_btn.visible = false
	touch_swap_btn.visible = false
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
	_opt_fullscreen_btn.text = "DISPLAY: %s" % ("FULLSCREEN" if MetaSave.fullscreen_enabled else "WINDOWED")
	_opt_fps_btn.text = "FPS: %s" % (str(MetaSave.fps_cap) if MetaSave.fps_cap > 0 else "UNLOCKED")
	_opt_speed_btn.text = "SPEED UP:          %s" % ("TOGGLE" if MetaSave.speed_up_toggle else "HOLD")


# Options -> FPS cycles 30 -> 60 -> 120 -> UNLOCKED.
func _cycle_fps_cap() -> void:
	var i: int = MetaSave.FPS_CHOICES.find(MetaSave.fps_cap)
	MetaSave.fps_cap = MetaSave.FPS_CHOICES[(i + 1) % MetaSave.FPS_CHOICES.size()]
	MetaSave.apply_frame_rate()
	MetaSave.save_game()
	RetroSfx.play("ui", -7.0, 0.02)
	_refresh_options_ui()


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
	run_xp_dropped = 0
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
	# Stage modules (stages 9+): this stage's sprites must be ready, and the next stage's are
	# built on a worker thread meanwhile (no-ops for stages 1-8).
	StageData.prepare_stage(current_stage_idx)
	StageData.prefetch_stage(current_stage_idx + 1)
	starfield.set_stage(current_stage_idx)

	var st: Dictionary = StageData.get_stage(current_stage_idx)
	var sub_wave: int = StageData.get_wave_in_stage(wave)
	var is_boss: bool = StageData.is_boss_wave(wave)
	var stage_display_num: int = current_stage_idx + 1

	_wave_clock = 0.0
	_wave_clear_delay = 0.70
	_spawn_queue.clear()

	var hp_mult: float = StageData.stage_hp_growth(current_stage_idx) * (1.0 + float(sub_wave - 1) * 0.16)

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

		# Groups alternate between the stage's own enemies (share = "themed") and the generic
		# fodder patterns; later stages have more groups, packed closer together ("pace").
		var diff: Dictionary = StageData.get_difficulty(current_stage_idx)
		var pace: float = float(diff["pace"])
		var share: float = float(diff["themed"])
		var t: float = 0.65
		var num_groups: int = mini(15, int(diff["groups"]) + sub_wave - 1)
		var themed_acc: float = 1.0 - share  # the first group of every wave is a themed one
		var themed_idx: int = 0
		for g: int in range(num_groups):
			themed_acc += share
			var gap: float = 0.0
			if themed_acc >= 0.999:
				themed_acc -= 1.0
				gap = _queue_themed_group(themed_idx, sub_wave, t, hp_mult)
				themed_idx += 1
			else:
				gap = _queue_generic_group((wave * 3 + g * 2) % 6, sub_wave, t, hp_mult)
			t += gap * pace

	hud_bar.queue_redraw()


# The original six patterns of re-skinned generic enemies. Returns the time until the next group.
func _queue_generic_group(roll: int, sub_wave: int, t: float, hp_mult: float) -> float:
	if roll == 0:
		var sq_id: int = _new_squad(6)
		var lane_y: float = randf_range(62.0, 196.0)
		for k: int in range(6):
			_queue_enemy(t + float(k) * 0.24, GameEnemy.Type.SCOUT_SINE, Vector2(500.0, lane_y), hp_mult, float(k) * 0.52, sq_id)
		return 2.5
	elif roll == 1:
		var count: int = 4 if wave < 3 else 5
		var sq_id: int = _new_squad(count)
		for k: int in range(count):
			var sy: float = 56.0 if k % 2 == 0 else 206.0
			_queue_enemy(t + float(k) * 0.30, GameEnemy.Type.SWOOPER, Vector2(504.0, sy), hp_mult, float(k), sq_id)
		return 2.4
	elif roll == 2:
		var s_count: int = 2 if wave < 3 else 3
		for k: int in range(s_count):
			var py: float = lerpf(58.0, 204.0, float(k) / float(maxi(1, s_count - 1)))
			_queue_enemy(t + float(k) * 0.22, GameEnemy.Type.SNIPER, Vector2(504.0, py), hp_mult, float(k) * 1.1, -1)
		_queue_enemy(t + 0.5, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 134.0), hp_mult, 0.0, -1)
		_queue_enemy(t + 0.8, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 134.0), hp_mult, 0.8, -1)
		return 2.7
	elif roll == 3:
		var cy: float = randf_range(74.0, 188.0)
		_queue_enemy(t, GameEnemy.Type.CRUISER, Vector2(512.0, cy), hp_mult, 0.0, -1)
		_queue_enemy(t + 0.35, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, clampf(cy - 34.0, 48.0, 214.0)), hp_mult, 0.0, -1)
		_queue_enemy(t + 0.55, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, clampf(cy + 34.0, 48.0, 214.0)), hp_mult, 1.0, -1)
		return 2.9
	elif roll == 4:
		var sq_id: int = _new_squad(7)
		var center_y: float = randf_range(96.0, 168.0)
		for k: int in range(7):
			var wing_off: float = float(absi(k - 3)) * 16.0 * (-1.0 if k < 3 else 1.0)
			_queue_enemy(t + float(absi(k - 3)) * 0.22, GameEnemy.Type.SCOUT_SINE, Vector2(502.0, clampf(center_y + wing_off, 48.0, 214.0)), hp_mult, float(k) * 0.4, sq_id)
		return 2.6
	_queue_enemy(t, GameEnemy.Type.CRUISER, Vector2(512.0, randf_range(72.0, 120.0)), hp_mult, 0.0, -1)
	if current_stage_idx >= 1 or sub_wave >= 2:
		_queue_enemy(t + 0.7, GameEnemy.Type.CRUISER, Vector2(518.0, randf_range(148.0, 196.0)), hp_mult, 1.5, -1)
	_queue_enemy(t + 0.4, GameEnemy.Type.SWOOPER, Vector2(504.0, 62.0), hp_mult, 0.0, -1)
	_queue_enemy(t + 0.8, GameEnemy.Type.SWOOPER, Vector2(504.0, 202.0), hp_mult, 1.2, -1)
	return 3.1


func _new_squad(count: int) -> int:
	var sq_id: int = _next_squad_id
	_next_squad_id += 1
	_squad_counts[sq_id] = count
	return sq_id


# One group of the current stage's signature enemies, usually with some generic fodder.
# Recipe C unlocks from the stage's second wave, and the third wave adds an extra unit to
# most recipes. Returns the time until the next group.
func _queue_themed_group(idx: int, sub_wave: int, t: float, hp_mult: float) -> float:
	var stage_k: int = StageData.wrap_stage(current_stage_idx)
	var module: RefCounted = StageData.get_module(stage_k)
	if module != null:
		# Stages 9+: the stage module queues its own recipes through a WaveBuilder.
		return float(module.call("queue_themed_group", WaveBuilder.new(self, idx, sub_wave, t, hp_mult)))
	var recipes: int = 3 if sub_wave >= 2 else 2
	var r: int = (idx + sub_wave - 1) % recipes
	var extra: int = 1 if sub_wave >= 3 else 0
	var top: bool = idx % 2 == 0
	match stage_k:
		0: # OUTER ORBIT: drifting asteroids that split, mine layers
			if r == 0:
				var n: int = 3 + extra
				for k: int in range(n):
					var y: float = lerpf(64.0, 200.0, (float(k) + randf_range(-0.25, 0.25)) / float(maxi(1, n - 1)))
					_queue_enemy(t + float(k) * 0.9, GameEnemy.Type.ASTEROID, Vector2(504.0, y), hp_mult, 0.0, -1, k % 2)
				return 3.0
			elif r == 1:
				var ly: float = 70.0 if top else 196.0
				_queue_enemy(t, GameEnemy.Type.MINE_LAYER, Vector2(510.0, ly), hp_mult, 0.0, -1)
				for k: int in range(2 + extra):
					_queue_enemy(t + 0.6 + float(k) * 0.3, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 268.0 - ly), hp_mult, float(k) * 0.6, -1)
				return 3.4
			_queue_enemy(t, GameEnemy.Type.ASTEROID, Vector2(504.0, 92.0), hp_mult, 0.0, -1, 0)
			_queue_enemy(t + 0.8, GameEnemy.Type.ASTEROID, Vector2(504.0, 176.0), hp_mult, 0.0, -1, 1)
			_queue_enemy(t + 0.4, GameEnemy.Type.MINE_LAYER, Vector2(510.0, 134.0), hp_mult, 0.0, -1)
			return 3.4
		1: # STARCRUISER: floor/ceiling turrets, patrolling security drones
			if r == 0:
				_queue_enemy(t, GameEnemy.Type.TURRET, Vector2(500.0, 0.0), hp_mult, 0.0, -1, 0)
				_queue_enemy(t + 1.4, GameEnemy.Type.TURRET, Vector2(500.0, 0.0), hp_mult, 0.0, -1, 1)
				var sq_id: int = _new_squad(3 + extra)
				var lane: float = randf_range(90.0, 180.0)
				for k: int in range(3 + extra):
					_queue_enemy(t + 0.5 + float(k) * 0.26, GameEnemy.Type.SCOUT_SINE, Vector2(500.0, lane), hp_mult, float(k) * 0.52, sq_id)
				return 3.0
			elif r == 1:
				_queue_enemy(t, GameEnemy.Type.SEC_DRONE, Vector2(504.0, 92.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.5, GameEnemy.Type.SEC_DRONE, Vector2(504.0, 178.0), hp_mult, 1.0, -1)
				if extra > 0:
					_queue_enemy(t + 1.0, GameEnemy.Type.SEC_DRONE, Vector2(504.0, 135.0), hp_mult, 0.5, -1)
				_queue_enemy(t + 0.8, GameEnemy.Type.SWOOPER, Vector2(504.0, 60.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 1.1, GameEnemy.Type.SWOOPER, Vector2(504.0, 210.0), hp_mult, 1.0, -1)
				return 3.0
			_queue_enemy(t, GameEnemy.Type.TURRET, Vector2(500.0, 0.0), hp_mult, 0.0, -1, 0)
			_queue_enemy(t + 0.2, GameEnemy.Type.TURRET, Vector2(520.0, 0.0), hp_mult, 0.0, -1, 1)
			_queue_enemy(t + 0.6, GameEnemy.Type.SEC_DRONE, Vector2(504.0, 135.0), hp_mult, 0.0, -1)
			return 3.3
		2: # CLOUD BASE: bomber blimps, jet formations (some from behind)
			if r == 0:
				_queue_enemy(t, GameEnemy.Type.BLIMP, Vector2(520.0, randf_range(54.0, 76.0)), hp_mult, 0.0, -1)
				_queue_jet_vee(t + 0.9, 3 + extra * 2, randf_range(150.0, 200.0), hp_mult)
				return 3.4
			elif r == 1:
				_queue_jet_vee(t, 5, randf_range(80.0, 190.0), hp_mult)
				return 2.6
			for k: int in range(3):
				_queue_enemy(t + float(k) * 0.35, GameEnemy.Type.JET, Vector2(-26.0, 70.0 + float(k) * 62.0), hp_mult, float(k - 1), -1, 1)
			_queue_enemy(t + 1.2, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 100.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 1.5, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 170.0), hp_mult, 1.0, -1)
			if extra > 0:
				_queue_enemy(t + 0.6, GameEnemy.Type.BLIMP, Vector2(520.0, 62.0), hp_mult, 0.0, -1)
			return 3.2
		3: # XENO FOREST: spore pods on floor and ceiling, charging beetles
			if r == 0:
				_queue_enemy(t, GameEnemy.Type.SPORE_POD, Vector2(500.0, 0.0), hp_mult, 0.0, -1, 0)
				_queue_enemy(t + 1.0, GameEnemy.Type.SPORE_POD, Vector2(500.0, 0.0), hp_mult, 0.0, -1, 1)
				var sq_id: int = _new_squad(4 + extra)
				var lane: float = randf_range(96.0, 172.0)
				for k: int in range(4 + extra):
					_queue_enemy(t + 0.4 + float(k) * 0.24, GameEnemy.Type.SCOUT_SINE, Vector2(500.0, lane), hp_mult, float(k) * 0.52, sq_id)
				return 3.2
			elif r == 1:
				_queue_enemy(t, GameEnemy.Type.BEETLE, Vector2(504.0, 80.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.9, GameEnemy.Type.BEETLE, Vector2(504.0, 190.0), hp_mult, 0.0, -1)
				if extra > 0:
					_queue_enemy(t + 1.8, GameEnemy.Type.BEETLE, Vector2(504.0, 135.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.4, GameEnemy.Type.SNIPER, Vector2(504.0, 135.0), hp_mult, 0.0, -1)
				return 3.2
			_queue_enemy(t, GameEnemy.Type.SPORE_POD, Vector2(500.0, 0.0), hp_mult, 0.0, -1, 0)
			_queue_enemy(t + 0.5, GameEnemy.Type.SPORE_POD, Vector2(500.0, 0.0), hp_mult, 0.0, -1, 1)
			_queue_enemy(t + 1.0, GameEnemy.Type.BEETLE, Vector2(504.0, 135.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 0.6, GameEnemy.Type.SWOOPER, Vector2(504.0, 64.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 0.9, GameEnemy.Type.SWOOPER, Vector2(504.0, 206.0), hp_mult, 1.0, -1)
			return 3.6
		4: # CRYO GLACIER: ice crystals that shatter, snow drones trailing frost
			if r == 0:
				var cy: float = randf_range(90.0, 180.0)
				_queue_enemy(t, GameEnemy.Type.ICE_CRYSTAL, Vector2(504.0, cy), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.4, GameEnemy.Type.ICE_CRYSTAL, Vector2(504.0, cy - 46.0), hp_mult, 1.2, -1)
				_queue_enemy(t + 0.8, GameEnemy.Type.ICE_CRYSTAL, Vector2(504.0, cy + 46.0), hp_mult, 2.4, -1)
				if extra > 0:
					_queue_enemy(t + 1.2, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, cy), hp_mult, 0.0, -1)
				return 3.2
			elif r == 1:
				_queue_enemy(t, GameEnemy.Type.SNOW_DRONE, Vector2(504.0, 100.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.7, GameEnemy.Type.SNOW_DRONE, Vector2(504.0, 170.0), hp_mult, PI, -1)
				_queue_enemy(t + 0.5, GameEnemy.Type.SWOOPER, Vector2(504.0, 58.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.8, GameEnemy.Type.SWOOPER, Vector2(504.0, 212.0), hp_mult, 1.0, -1)
				if extra > 0:
					_queue_enemy(t + 1.3, GameEnemy.Type.SNOW_DRONE, Vector2(504.0, 135.0), hp_mult, 1.5, -1)
				return 3.0
			_queue_enemy(t, GameEnemy.Type.ICE_CRYSTAL, Vector2(504.0, 80.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 0.5, GameEnemy.Type.ICE_CRYSTAL, Vector2(504.0, 190.0), hp_mult, 1.0, -1)
			_queue_enemy(t + 0.9, GameEnemy.Type.SNOW_DRONE, Vector2(504.0, 135.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 0.3, GameEnemy.Type.SNIPER, Vector2(504.0, 135.0), hp_mult, 0.0, -1)
			return 3.4
		5: # MAGMA CORE: lava blobs leaping from the floor, shielded rock golems
			if r == 0:
				var xs: Array[float] = [392.0, 300.0, 432.0, 340.0, 250.0]
				for k: int in range(4 + extra):
					_queue_enemy(t + float(k) * 0.45, GameEnemy.Type.LAVA_BLOB, Vector2(xs[k], 266.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.6, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 90.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.9, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 150.0), hp_mult, 1.0, -1)
				return 3.2
			elif r == 1:
				_queue_enemy(t, GameEnemy.Type.GOLEM, Vector2(512.0, randf_range(100.0, 170.0)), hp_mult, 0.0, -1)
				_queue_enemy(t + 1.0, GameEnemy.Type.LAVA_BLOB, Vector2(330.0, 266.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 1.6, GameEnemy.Type.LAVA_BLOB, Vector2(260.0, 266.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.5, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 70.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.8, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 200.0), hp_mult, 1.0, -1)
				return 3.6
			_queue_enemy(t, GameEnemy.Type.GOLEM, Vector2(512.0, 135.0), hp_mult, 0.0, -1)
			var xs2: Array[float] = [410.0, 350.0, 290.0, 380.0, 320.0]
			for k: int in range(4 + extra):
				_queue_enemy(t + 0.8 + float(k) * 0.5, GameEnemy.Type.LAVA_BLOB, Vector2(xs2[k], 266.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 0.4, GameEnemy.Type.SWOOPER, Vector2(504.0, 60.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 0.7, GameEnemy.Type.SWOOPER, Vector2(504.0, 210.0), hp_mult, 1.0, -1)
			return 4.0
		6: # ABYSSAL TRENCH: jellyfish rings, weaving eels, the anglerfish
			if r == 0:
				_queue_enemy(t, GameEnemy.Type.JELLYFISH, Vector2(504.0, 84.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.8, GameEnemy.Type.JELLYFISH, Vector2(504.0, 186.0), hp_mult, 0.0, -1)
				var sq_id: int = _new_squad(3 + extra)
				for k: int in range(3 + extra):
					_queue_enemy(t + 0.4 + float(k) * 0.26, GameEnemy.Type.SCOUT_SINE, Vector2(500.0, 135.0), hp_mult, float(k) * 0.52, sq_id)
				return 3.2
			elif r == 1:
				_queue_enemy(t, GameEnemy.Type.EEL, Vector2(510.0, 96.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 1.0, GameEnemy.Type.EEL, Vector2(510.0, 174.0), hp_mult, PI, -1)
				_queue_enemy(t + 0.5, GameEnemy.Type.JELLYFISH, Vector2(504.0, 135.0), hp_mult, 0.0, -1)
				if extra > 0:
					_queue_enemy(t + 1.8, GameEnemy.Type.EEL, Vector2(510.0, 135.0), hp_mult, 1.5, -1)
				return 3.4
			_queue_enemy(t, GameEnemy.Type.ANGLER, Vector2(516.0, randf_range(110.0, 160.0)), hp_mult, 0.0, -1)
			_queue_enemy(t + 0.6, GameEnemy.Type.JELLYFISH, Vector2(504.0, 70.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 1.0, GameEnemy.Type.JELLYFISH, Vector2(504.0, 200.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 1.6, GameEnemy.Type.EEL, Vector2(510.0, 135.0), hp_mult, 0.0, -1)
			return 4.0
		_: # CYBER NEXUS: replicating viruses, teleporting glitches, firewalls
			if r == 0:
				for k: int in range(3 + extra):
					_queue_enemy(t + float(k) * 0.3, GameEnemy.Type.VIRUS, Vector2(504.0, randf_range(60.0, 210.0)), hp_mult, float(k), -1)
				_queue_enemy(t + 0.5, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 100.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.8, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 170.0), hp_mult, 1.0, -1)
				return 3.0
			elif r == 1:
				_queue_enemy(t, GameEnemy.Type.GLITCH, Vector2(504.0, 90.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.7, GameEnemy.Type.GLITCH, Vector2(504.0, 180.0), hp_mult, 0.0, -1)
				for k: int in range(2 + extra):
					_queue_enemy(t + 0.4 + float(k) * 0.4, GameEnemy.Type.VIRUS, Vector2(504.0, randf_range(60.0, 210.0)), hp_mult, float(k), -1)
				return 3.2
			_queue_firewall(t, hp_mult)
			_queue_enemy(t + 1.6, GameEnemy.Type.GLITCH, Vector2(504.0, 135.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 0.5, GameEnemy.Type.SWOOPER, Vector2(504.0, 60.0), hp_mult, 0.0, -1)
			_queue_enemy(t + 0.8, GameEnemy.Type.SWOOPER, Vector2(504.0, 210.0), hp_mult, 1.0, -1)
			return 4.2


# A V of jets with the leader in front; each jet breaks toward the player on its own.
func _queue_jet_vee(t: float, count: int, center_y: float, hp_mult: float) -> void:
	var sq_id: int = _new_squad(count)
	for k: int in range(count):
		var slot: int = (k + 1) / 2 * (1 if k % 2 == 1 else -1)  # 0, 1, -1, 2, -2
		var y: float = clampf(center_y + float(slot) * 16.0, 44.0, 232.0)
		_queue_enemy(t, GameEnemy.Type.JET, Vector2(500.0 + float(absi(slot)) * 20.0, y), hp_mult, float(slot), sq_id)


# A column of firewall blocks with a two-block gap to fly through, as one squad.
func _queue_firewall(t: float, hp_mult: float) -> void:
	var slots: int = 9
	var gap: int = randi_range(1, slots - 3)
	var sq_id: int = _new_squad(slots - 2)
	for k: int in range(slots):
		if k == gap or k == gap + 1:
			continue
		var links: int = 0
		if k > 0 and k - 1 != gap + 1:
			links |= 1
		if k < slots - 1 and k + 1 != gap:
			links |= 2
		var y: float = 40.0 + float(k) * 24.5
		_queue_enemy(t, GameEnemy.Type.FIREWALL, Vector2(500.0, y), hp_mult, float(k), sq_id, links)

# kind names a stage module's enemy (e_type GameEnemy.Type.MODULE).
func _queue_enemy(spawn_time: float, e_type: GameEnemy.Type, pos: Vector2, hp_mult: float, phase: float, sq_id: int, variant: int = 0, kind: String = "") -> void:
	var item: Dictionary = {
		"time": spawn_time,
		"type": e_type,
		"pos": pos,
		"hp_mult": hp_mult,
		"phase": phase,
		"squad": sq_id,
		"stage": current_stage_idx,
		"variant": variant,
	}
	if kind != "":
		item["kind"] = kind
	_spawn_queue.append(item)


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
	touch_swap_btn.visible = false
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
	var clear_head: String = String(StageData.get_stage(current_stage_idx).get("clear_banner", "HYPERSPACE JUMP!"))
	_show_banner("%s\nNEXT: %s" % [clear_head, String(next_stage["name"])], Color("#28e8ff"), _hyper_duration)
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
	_update_splash(delta)
	_update_speed_up(Input.is_physical_key_pressed(KEY_F), _read_speed_trigger())

	if state != State.PAUSED and _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			banner_label.visible = false

	_poll_controller_menu_stick(delta)

	if state == State.SOUNDTRACK and _snd_slot() == "hyperspace":
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
		var row_target: float = -float(_loadout_first) * LOADOUT_SLOT_W
		_loadout_row.position.x = lerpf(_loadout_row.position.x, row_target, clampf(16.0 * delta, 0.0, 1.0))
		if absf(_loadout_row.position.x - row_target) < 0.5:
			_loadout_row.position.x = row_target
		var lt: float = float(Time.get_ticks_msec()) * 0.004
		_loadout_preview_ship.position = Vector2(64.0, 148.0 + sin(lt) * 4.5)
		var cur_s: Dictionary = SkillTreeData.SHIPS[_loadout_cursor_idx]
		var l_alt: bool = (int(Time.get_ticks_msec() / 85) % 2 == 0)
		_loadout_preview_ship.texture = PixelArt.tex(String(cur_s["sprite_1" if l_alt else "sprite_0"]))
		if _loadout_preview_bullet.visible:
			_loadout_preview_bullet.position = Vector2(120.0 + fposmod(lt * 22.0, 26.0), 148.0 + sin(lt * 2.5) * 3.0)
			if String(cur_s["id"]) == "neko":
				# The cat is wider than the other shots: a shorter slide keeps it clear of the ship
				# and the text, and each pass shows the next coat.
				var cat_pass: float = lt * 22.0 / 16.0
				_loadout_preview_bullet.position.x = 124.0 + 16.0 * (cat_pass - floorf(cat_pass))
				var coat: String = PlayerShip.CAT_SHOT_COATS[int(cat_pass) % PlayerShip.CAT_SHOT_COATS.size()]
				_loadout_preview_bullet.texture = PixelArt.tex(coat + ("_1" if l_alt else "_0"))

	elif state == State.DRAFT:
		_update_draft_cursor()

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

	var moved: bool = false
	if ay < -0.55:
		moved = _move_menu_focus(SIDE_TOP)
	elif ay > 0.55:
		moved = _move_menu_focus(SIDE_BOTTOM)
	elif ax < -0.55:
		moved = _move_menu_focus(SIDE_LEFT)
	elif ax > 0.55:
		moved = _move_menu_focus(SIDE_RIGHT)
	if moved:
		_joy_nav_cooldown = 0.19


# Moves keyboard/gamepad focus to the focused control's neighbour on that side (left stick and
# WASD; arrow keys and the D-pad go through Godot's ui_* actions, which use the same neighbours).
func _move_menu_focus(side: Side) -> bool:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused == null:
		return false
	var next_ctrl: Control = focused.find_valid_focus_neighbor(side)
	if next_ctrl == null or next_ctrl == focused:
		return false
	next_ctrl.grab_focus()
	RetroSfx.play("ui", -11.0, 0.03)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if _splash_showing():
		var skip: bool = (event is InputEventKey and (event as InputEventKey).pressed) or (event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed)
		if skip:
			_end_splash()
			get_viewport().set_input_as_handled()
		return
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
			elif k == KEY_W:
				_move_menu_focus(SIDE_TOP)
			elif k == KEY_S:
				_move_menu_focus(SIDE_BOTTOM)
			elif k == KEY_A:
				_move_menu_focus(SIDE_LEFT)
			elif k == KEY_D:
				_move_menu_focus(SIDE_RIGHT)
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


# XP needed to go from `lvl` to `lvl + 1`. The first few levels need extra (x1.6 for level 2,
# tapering to x1.0 by level 8) so the opening draft cards don't come every few seconds;
# from level 8 on it's the original curve.
func _calc_xp_for_level(lvl: int) -> int:
	var base: float = 18.0 + float(lvl - 1) * 12.0 + pow(float(lvl - 1), 1.42) * 4.5
	var early: float = 1.0 + 0.6 * maxf(0.0, float(8 - lvl) / 7.0)
	return int(base * early)


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
	run_xp_dropped += total_xp
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


func _spawn_enemy_now(item: Dictionary) -> GameEnemy:
	var e: GameEnemy = GameEnemy.new()
	enemy_layer.add_child(e)
	var e_type: GameEnemy.Type = item["type"]
	e.module_kind = String(item.get("kind", ""))
	e.setup(
		e_type,
		Vector2(item["pos"]),
		float(item["hp_mult"]),
		player,
		bullet_layer,
		fx_layer,
		float(item["phase"]),
		int(item["squad"]),
		int(item.get("stage", current_stage_idx)),
		int(item.get("variant", 0)),
		int(item.get("gen", 0))
	)
	if item.has("vel"):
		e.set_launch_velocity(Vector2(item["vel"]))
	e.destroyed.connect(_on_enemy_destroyed)
	e.boss_phase_broken.connect(_on_boss_phase_broken)
	e.spawn_requested.connect(_on_enemy_spawn_requested)
	return e


# A child enemy (rock chunk, mine, virus copy) spawns on the next director update. Going through
# the spawn queue keeps the wave from ending while it's pending and connects its signals.
func _on_enemy_spawn_requested(item: Dictionary) -> void:
	item["time"] = _wave_clock
	_spawn_queue.append(item)


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

	# Automatic Scrap banking on kill! Child enemies (rock chunks, mines, virus copies) give none.
	var bounty_mult: float = MetaSave.get_boss_bounty_mult() if is_boss_kill else 1.0
	var auto_scrap: int = 0
	if enemy.scrap_drop > 0:
		auto_scrap = maxi(1, int(round(float(enemy.scrap_drop) * MetaSave.get_scrap_mult() * player.get_run_scrap_mult() * bounty_mult)))
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
			var box_idle: StyleBoxFlat = card["box_idle"]
			box_idle.border_color = col

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
	_refresh_draft_selection()


# Shows which card is selected (focused by D-pad, stick, arrow keys or mouse hover): it gets a
# brighter face with a thick white frame, lifts DRAFT_SELECT_LIFT px and has the bouncing cursor
# above it, while the others dim. Pick glyphs: key caps 1/2/3 on every card for keyboard
# players; for gamepad players, the A button on the selected card only.
func _refresh_draft_selection() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	for i: int in range(_draft_cards.size()):
		var card: Dictionary = _draft_cards[i]
		var btn: Button = card["btn"]
		var selected: bool = btn == focus_owner
		var face: StyleBox = card["box_sel"] if selected else card["box_idle"]
		btn.add_theme_stylebox_override("normal", face)
		btn.add_theme_stylebox_override("hover", face)
		btn.add_theme_stylebox_override("pressed", card["box_press"] as StyleBox)
		btn.modulate = Color.WHITE if selected else Color(0.6, 0.62, 0.72)
		btn.position.y = DRAFT_CARD_Y - (DRAFT_SELECT_LIFT if selected else 0.0)

		var pick_glyph: TextureRect = card["pick_glyph"]
		var pips_lbl: Label = card["pips_lbl"]
		if InputPrompts.is_gamepad:
			pick_glyph.texture = InputPrompts.glyph("pad_a") if selected else null
		else:
			pick_glyph.texture = InputPrompts.glyph("key_%d" % (i + 1))
		var font: Font = pips_lbl.get_theme_font("font")
		var text_w: float = font.get_string_size(pips_lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ).x
		var glyph_w: float = 0.0 if pick_glyph.texture == null else float(pick_glyph.texture.get_width()) + 3.0
		var x0: float = floorf((btn.size.x - glyph_w - text_w) * 0.5)
		pick_glyph.position.x = x0
		pips_lbl.position.x = x0 + glyph_w
		pips_lbl.size.x = text_w + 2.0
	_update_draft_cursor()


# The cursor sits centred above the selected card and bobs 0-2 px (called every frame in DRAFT).
func _update_draft_cursor() -> void:
	var sel_btn: Button = null
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	for card: Dictionary in _draft_cards:
		var btn: Button = card["btn"]
		if btn == focus_owner and btn.visible:
			sel_btn = btn
	_draft_cursor.visible = sel_btn != null
	if sel_btn == null:
		return
	var bob: float = roundf(1.0 + sin(float(Time.get_ticks_msec()) * 0.008))
	var cursor_size: Vector2 = _draft_cursor.texture.get_size()
	# 2 px of frame stick out above the card, then a 2 px gap.
	_draft_cursor.position = Vector2(
		sel_btn.position.x + floorf((sel_btn.size.x - cursor_size.x) * 0.5),
		sel_btn.position.y - 4.0 - cursor_size.y - bob
	)


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
	touch_swap_btn.visible = false
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
	touch_swap_btn.visible = false
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
	# The hangar-expansion ships label their signature weapon in their SHIPS entry.
	for ship_d: Dictionary in SkillTreeData.SHIPS:
		if String(ship_d["weapon_id"]) == mode and ship_d.has("badge"):
			return {"icon": String(ship_d["badge"]), "name": String(ship_d["badge_name"]), "val": lv_s, "col": ship_d["color"]}
	return {"icon": "badge_vulcan", "name": "Vulcan", "val": lv_s, "col": Color("#ffe854")}


# The HUD's "S-W NAME" label runs from x 158 and must stop short of SCRAP at x 294. Two-digit
# stage numbers (stage 10+, and every loop) and long names can overflow it, so the name loses
# whole words from the end (then letters) until it fits.
const HUD_STAGE_TEXT_W: float = 132.0


func _fit_hud_stage_text(font: Font, head: String, stage_name: String) -> String:
	var txt: String = head + stage_name
	var name_part: String = stage_name
	while name_part != "" and font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ).x > HUD_STAGE_TEXT_W:
		var cut: int = name_part.rfind(" ")
		name_part = name_part.substr(0, cut) if cut > 0 else name_part.substr(0, name_part.length() - 1)
		txt = head + name_part
	return txt


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

	var st_head: String = "%d-%s " % [
		current_stage_idx + 1,
		"BOSS" if StageData.is_boss_wave(wave) else str(sub_w),
	]
	var st_txt: String = _fit_hud_stage_text(font, st_head, String(st["name"]))
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

	# --- 1b) Boss health: one solid bar (phase colour; a pale strip drains behind it after hits) ---
	var boss_shown: bool = false
	for node: Node in enemy_layer.get_children():
		if node is GameEnemy:
			var ge: GameEnemy = node as GameEnemy
			if ge.enemy_type == GameEnemy.Type.BOSS and ge.boss_hp_bar_visible:
				boss_shown = true
				var b_ratio: float = ge.boss_hp_bar_fill if ge.boss_intro_active else clampf(ge.hp / ge.max_hp, 0.0, 1.0)
				var bar_col: Color = Color("#28e8ff") if ge.boss_shield_timer > 0.0 else (
					Color("#ff3868") if ge.boss_phase == 3 else (Color("#ff9624") if ge.boss_phase == 2 else Color("#ffe854"))
				)
				# The drain strip catches up after a short hold; it never trails a filling bar.
				if b_ratio >= _boss_bar_lag or ge.boss_intro_active:
					_boss_bar_lag = b_ratio
					_boss_bar_hold = 0.35
				else:
					var dt: float = get_process_delta_time()
					_boss_bar_hold -= dt
					if _boss_bar_hold <= 0.0:
						_boss_bar_lag = move_toward(_boss_bar_lag, b_ratio, dt * 0.55)
				var bar_y: float = 24.0
				var x0: float = BOSS_BAR_X
				var full_w: float = BOSS_BAR_W
				hud_bar.draw_rect(Rect2(72.0, bar_y, 318.0, 9.0), Color("#0b1029"))
				hud_bar.draw_string(font, Vector2(75.0, bar_y + 8.0), "BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#ff4c68"))
				hud_bar.draw_rect(Rect2(x0, bar_y + 1.0, full_w, 7.0), Color("#182042"))
				var lag_w: float = roundf(full_w * _boss_bar_lag)
				var fill_w: float = roundf(full_w * b_ratio)
				if lag_w > fill_w:
					hud_bar.draw_rect(Rect2(x0 + fill_w, bar_y + 1.0, lag_w - fill_w, 7.0), Color("#fff1e0"))
				if fill_w > 0.0:
					hud_bar.draw_rect(Rect2(x0, bar_y + 1.0, fill_w, 7.0), bar_col)
					hud_bar.draw_rect(Rect2(x0, bar_y + 1.0, fill_w, 2.0), bar_col.lightened(0.55))
					hud_bar.draw_rect(Rect2(x0, bar_y + 7.0, fill_w, 1.0), bar_col.darkened(0.35))
					if ge.boss_intro_active and fill_w < full_w:
						hud_bar.draw_rect(Rect2(x0 + fill_w - 2.0, bar_y + 1.0, 2.0, 7.0), Color.WHITE)
				# Phase marks at 2/3 and 1/3 (phase 2 and 3 start there).
				for frac: float in [2.0 / 3.0, 1.0 / 3.0]:
					var mx: float = x0 + roundf(full_w * frac)
					hud_bar.draw_line(Vector2(mx, bar_y + 1.0), Vector2(mx, bar_y + 8.0), Color(0.86, 0.9, 1.0, 0.75), 1.0)
				hud_bar.draw_rect(Rect2(72.0, bar_y, 318.0, 9.0), Color("#dce6ff"), false, 1.0)
				hud_bar.draw_line(Vector2(105.0, bar_y), Vector2(105.0, bar_y + 9.0), Color("#dce6ff"), 1.0)
				break
	if not boss_shown:
		_boss_bar_lag = 0.0

	# --- 1b2) Active sub weapon (left of the boss bar row), with the swap button once 2+ are owned ---
	if player.sub_weapon != "":
		var icon_key: String = "badge_" + player.sub_weapon
		if player.sub_weapon == "beam":
			icon_key = String(_get_beam_badge_info(player.aux_beam, player.beam_level)["icon"])
		hud_bar.draw_rect(Rect2(2.0, 24.0, 68.0, 11.0), Color(0.04, 0.06, 0.16, 0.72))
		hud_bar.draw_texture(PixelArt.tex(icon_key), Vector2(4.0, 25.0))
		hud_bar.draw_string(font, Vector2(17.0, 33.0), player.sub_weapon_name(player.sub_weapon), HORIZONTAL_ALIGNMENT_LEFT, 40.0, FONT_SZ, Color("#ffe854"))
		if player.owned_sub_weapons().size() >= 2:
			var strip: Texture2D = InputPrompts.strip_for("swap_weapon")
			if strip != null:
				hud_bar.draw_texture(strip, Vector2(69.0 - float(strip.get_width()), 24.0 + floorf((11.0 - float(strip.get_height())) * 0.5)))

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
