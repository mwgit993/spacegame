extends Node2D

enum State { TITLE, STATS, OPTIONS, HANGAR, INTRO_WARP, PLAYING, PAUSED, DRAFT, HYPERSPACE, GAME_OVER_DELAY }

const VIEW_W: float = 480.0
const VIEW_H: float = 270.0
const FONT_SZ: int = 10

const RUN_UPGRADE_POOL: Array[Dictionary] = [
	{
		"id": "option",
		"title": "OPTION ORB",
		"icon": "upg_option",
		"color": Color("#ff9624"),
		"max_rank": 4,
		"desc": "+1 Shadow Orb",
	},
	{
		"id": "spread",
		"title": "SPREAD SHOT",
		"icon": "upg_spread",
		"color": Color("#ffe854"),
		"max_rank": 3,
		"desc": "Wider Shot Fan",
	},
	{
		"id": "laser",
		"title": "PIERCE LASER",
		"icon": "upg_laser",
		"color": Color("#28e8ff"),
		"max_rank": 3,
		"desc": "Piercing Beam",
	},
	{
		"id": "missile",
		"title": "HOMING PODS",
		"icon": "upg_missile",
		"color": Color("#ff4c68"),
		"max_rank": 3,
		"desc": "+Lock Missiles",
	},
	{
		"id": "shield",
		"title": "FORCE SHIELD",
		"icon": "upg_shield",
		"color": Color("#3ce8ff"),
		"max_rank": 3,
		"desc": "+1 Barrier",
	},
	{
		"id": "rapid",
		"title": "RAPID COIL",
		"icon": "upg_rapid",
		"color": Color("#d46bff"),
		"max_rank": 6,
		"desc": "+22% Fire Rate",
	},
	{
		"id": "thruster",
		"title": "AFTERBURNER",
		"icon": "upg_thruster",
		"color": Color("#3ce878"),
		"max_rank": 4,
		"desc": "+Ship Speed",
	},
	{
		"id": "repair",
		"title": "HULL PATCH",
		"icon": "upg_repair",
		"color": Color("#66ff99"),
		"max_rank": 99,
		"desc": "+1 HP & Heal 2",
	},
]

var state: State = State.TITLE

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
var draft_panel: Control
var pause_panel: Control

# Title & Menu focus buttons
var _title_ship_sprite: Sprite2D
var _title_hangar_btn: Button
var _title_menu_btns: Array[Button] = []
var _title_sel_idx: int = 0
var _stats_back_btn: Button
var _stats_body_lbl: Label
var _hangar_launch_btn: Button
var _pause_resume_btn: Button
var _options_from_pause: bool = false

# Options UI controls
var _opt_music_lbl: Label
var _opt_sfx_lbl: Label
var _opt_autofire_btn: Button
var _opt_shake_btn: Button
var _opt_touch_btn: Button
var _opt_fullscreen_btn: Button
var _opt_first_btn: Button

# Analog stick UI navigation repeat timer
var _joy_nav_cooldown: float = 0.0

# Run & Stage progression metrics
var wave: int = 0
var current_stage_idx: int = 0
var score: int = 0
var run_scrap: int = 0
var run_kills: int = 0
var run_bosses: int = 0
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

# Hangar UI state
var _hangar_summary_lbl: Label
var _hangar_scrap_lbl: Label
var _hangar_rows: Array[Dictionary] = []


func _ready() -> void:
	randomize()
	MetaSave.apply_audio_and_display_settings()
	_build_world()
	_build_ui()
	_enter_title()
	if OS.get_cmdline_user_args().has("--smoke-test"):
		_run_smoke_test()


func _run_smoke_test() -> void:
	_enter_stats()
	_enter_options()
	_enter_hangar("TEST SUMMARY")
	_start_run()
	# Exercise Stage 1 opening hyperspace warp-in arrival!
	_update_intro_warp(1.0)
	_update_intro_warp(1.0)
	# Test pause -> options -> resume flow
	_pause_game()
	_options_from_pause = true
	_enter_options()
	_leave_options()
	_resume_game()
	# Test all 8 stages, expanded 24-bar music sections, upgrades, and clear bottom HUD dock
	for upg_id: String in ["option", "option", "spread", "spread", "laser", "missile", "shield", "rapid", "thruster", "repair"]:
		player.apply_run_upgrade(upg_id)
	hud_bar.queue_redraw()
	for st_i: int in range(8):
		starfield.set_stage(st_i)
		starfield._process(0.02)
		GenesisMusic.play_stage(st_i)
		# Step across Verse, Chorus (step 140), and Breakdown/Build (step 280)
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
	_pending_hyperspace = true
	_open_upgrade_draft()
	_pick_draft_card(0)
	_update_hyperspace(1.5)
	_update_hyperspace(1.5)
	player.invuln_timer = 0.0
	player.take_player_hit()
	MetaSave.reset_save()
	print("STAR_VIPER_SMOKE_TEST_PASSED")
	get_tree().quit(0)


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
	btn.add_theme_stylebox_override("normal", _make_ff6_box(Color("#0d1746"), Color("#9ab0de"), 1, 2.0))
	btn.add_theme_stylebox_override("hover", _make_ff6_box(Color("#192b73"), accent, 2, 2.0))
	btn.add_theme_stylebox_override("focus", _make_ff6_box(Color("#192b73"), accent, 2, 2.0))
	btn.add_theme_stylebox_override("pressed", _make_ff6_box(Color("#253f9e"), Color.WHITE, 2, 2.0))


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	hud_bar = Control.new()
	hud_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_bar.draw.connect(_draw_hud)
	ui_layer.add_child(hud_bar)

	# On-screen top-right Pause button (works for Mouse AND Phone Touch!)
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

	# On-screen bottom-right Focus Hold Pad for Phone / Tablet Touch Controls!
	touch_focus_btn = Button.new()
	touch_focus_btn.position = Vector2(412.0, 212.0)
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
	_build_hangar_ui()
	_build_draft_ui()
	_build_pause_ui()


func _build_title_ui() -> void:
	title_panel = Control.new()
	title_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(title_panel)

	var logo: Label = Label.new()
	logo.position = Vector2(28.0, 28.0)
	logo.size = Vector2(340.0, 30.0)
	logo.text = "STAR VIPER"
	logo.add_theme_font_size_override("font_size", 20)
	logo.add_theme_color_override("font_color", Color("#28e8ff"))
	title_panel.add_child(logo)

	var sub: Label = Label.new()
	sub.position = Vector2(30.0, 56.0)
	sub.size = Vector2(320.0, 16.0)
	sub.text = "16-BIT GALACTIC ROGUELITE"
	sub.add_theme_font_size_override("font_size", FONT_SZ)
	sub.add_theme_color_override("font_color", Color("#ffe854"))
	title_panel.add_child(sub)

	_title_ship_sprite = Sprite2D.new()
	_title_ship_sprite.texture = PixelArt.tex("player_idle")
	_title_ship_sprite.scale = Vector2(3.0, 3.0)
	_title_ship_sprite.position = Vector2(356.0, 132.0)
	title_panel.add_child(_title_ship_sprite)

	var menu_specs: Array[Dictionary] = [
		{"label": "START RUN", "cb": _start_run, "accent": Color("#3ce878")},
		{"label": "SHIP HANGAR", "cb": _open_hangar_from_title, "accent": Color("#ffe854")},
		{"label": "STATS", "cb": _enter_stats, "accent": Color("#28e8ff")},
		{"label": "OPTIONS", "cb": _open_options_from_title, "accent": Color("#ff78d4")},
		{"label": "QUIT GAME", "cb": _quit_desktop, "accent": Color("#ff4c68")},
	]

	_title_menu_btns.clear()
	for i: int in range(menu_specs.size()):
		var spec: Dictionary = menu_specs[i]
		var btn: Button = Button.new()
		btn.position = Vector2(30.0, 78.0 + float(i) * 28.0)
		btn.size = Vector2(196.0, 24.0)
		btn.text = String(spec["label"])
		_style_menu_btn(btn, spec["accent"])
		var callback: Callable = spec["cb"]
		btn.pressed.connect(func() -> void:
			RetroSfx.play("ui", -7.0, 0.02)
			callback.call()
		)
		title_panel.add_child(btn)
		_title_menu_btns.append(btn)
		if i == 1:
			_title_hangar_btn = btn

	var foot: Label = Label.new()
	foot.position = Vector2(30.0, 226.0)
	foot.size = Vector2(430.0, 14.0)
	foot.text = "Keyboard / Controller / Touch Supported  |  Esc/Start: Pause"
	foot.add_theme_font_size_override("font_size", FONT_SZ)
	foot.add_theme_color_override("font_color", Color("#9ab6e8"))
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
	_stats_back_btn.text = "BACK [ESC/B]"
	_style_menu_btn(_stats_back_btn)
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
	_opt_first_btn = m_minus

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

	var reset_btn: Button = Button.new()
	reset_btn.position = Vector2(50.0, 210.0)
	reset_btn.size = Vector2(158.0, 26.0)
	reset_btn.text = "RESET SAVE"
	_style_menu_btn(reset_btn, Color("#ff4c68"))
	reset_btn.pressed.connect(func() -> void:
		MetaSave.reset_save()
		RetroSfx.play("explode", -8.0, 0.02)
		_refresh_options_ui()
	)
	options_panel.add_child(reset_btn)

	var back_btn: Button = Button.new()
	back_btn.position = Vector2(284.0, 210.0)
	back_btn.size = Vector2(136.0, 26.0)
	back_btn.text = "BACK [ESC/B]"
	_style_menu_btn(back_btn)
	back_btn.pressed.connect(_leave_options)
	options_panel.add_child(back_btn)


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


func _build_hangar_ui() -> void:
	hangar_panel = Control.new()
	hangar_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	hangar_panel.visible = false
	ui_layer.add_child(hangar_panel)

	var h_bg: Panel = Panel.new()
	h_bg.position = Vector2(14.0, 10.0)
	h_bg.size = Vector2(452.0, 250.0)
	h_bg.add_theme_stylebox_override("panel", _make_ff6_box())
	hangar_panel.add_child(h_bg)

	var title_lbl: Label = Label.new()
	title_lbl.position = Vector2(26.0, 16.0)
	title_lbl.size = Vector2(260.0, 16.0)
	title_lbl.text = "SHIP HANGAR"
	title_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	title_lbl.add_theme_color_override("font_color", Color("#ffe854"))
	hangar_panel.add_child(title_lbl)

	_hangar_scrap_lbl = Label.new()
	_hangar_scrap_lbl.position = Vector2(276.0, 16.0)
	_hangar_scrap_lbl.size = Vector2(176.0, 16.0)
	_hangar_scrap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hangar_scrap_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_hangar_scrap_lbl.add_theme_color_override("font_color", Color("#3ce878"))
	hangar_panel.add_child(_hangar_scrap_lbl)

	_hangar_summary_lbl = Label.new()
	_hangar_summary_lbl.position = Vector2(26.0, 33.0)
	_hangar_summary_lbl.size = Vector2(428.0, 14.0)
	_hangar_summary_lbl.add_theme_font_size_override("font_size", FONT_SZ)
	_hangar_summary_lbl.add_theme_color_override("font_color", Color("#9ab6e8"))
	hangar_panel.add_child(_hangar_summary_lbl)

	for i: int in range(MetaSave.UPGRADE_DEFS.size()):
		var def: Dictionary = MetaSave.UPGRADE_DEFS[i]
		var ry: float = 52.0 + float(i) * 32.0

		var row_bg: Panel = Panel.new()
		row_bg.position = Vector2(26.0, ry)
		row_bg.size = Vector2(428.0, 29.0)
		row_bg.add_theme_stylebox_override("panel", _make_ff6_box(Color("#081030"), Color("#4c6cb0"), 1))
		hangar_panel.add_child(row_bg)

		var name_lbl: Label = Label.new()
		name_lbl.position = Vector2(32.0, ry + 3.0)
		name_lbl.size = Vector2(290.0, 13.0)
		name_lbl.add_theme_font_size_override("font_size", FONT_SZ)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		hangar_panel.add_child(name_lbl)

		var desc_lbl: Label = Label.new()
		desc_lbl.position = Vector2(32.0, ry + 15.0)
		desc_lbl.size = Vector2(290.0, 13.0)
		desc_lbl.text = String(def["desc"])
		desc_lbl.add_theme_font_size_override("font_size", FONT_SZ)
		desc_lbl.add_theme_color_override("font_color", Color("#88a8dc"))
		hangar_panel.add_child(desc_lbl)

		var buy_btn: Button = Button.new()
		buy_btn.position = Vector2(332.0, ry + 3.0)
		buy_btn.size = Vector2(116.0, 23.0)
		_style_menu_btn(buy_btn, Color("#ffe854"))
		var upg_id: String = String(def["id"])
		buy_btn.pressed.connect(func() -> void: _on_buy_permanent(upg_id))
		hangar_panel.add_child(buy_btn)

		_hangar_rows.append({
			"id": upg_id,
			"name_lbl": name_lbl,
			"buy_btn": buy_btn,
		})

	var title_menu_btn: Button = Button.new()
	title_menu_btn.position = Vector2(26.0, 218.0)
	title_menu_btn.size = Vector2(146.0, 30.0)
	title_menu_btn.text = "TITLE [ESC]"
	_style_menu_btn(title_menu_btn)
	title_menu_btn.pressed.connect(func() -> void:
		RetroSfx.play("ui", -7.0, 0.02)
		_enter_title()
	)
	hangar_panel.add_child(title_menu_btn)

	_hangar_launch_btn = Button.new()
	_hangar_launch_btn.position = Vector2(288.0, 218.0)
	_hangar_launch_btn.size = Vector2(166.0, 30.0)
	_hangar_launch_btn.text = "LAUNCH [SPACE/START]"
	_style_menu_btn(_hangar_launch_btn, Color("#3ce878"))
	_hangar_launch_btn.pressed.connect(_start_run)
	hangar_panel.add_child(_hangar_launch_btn)


func _build_pause_ui() -> void:
	pause_panel = Control.new()
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	ui_layer.add_child(pause_panel)

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.08, 0.72)
	pause_panel.add_child(dim)

	var box: Panel = Panel.new()
	box.position = Vector2(126.0, 36.0)
	box.size = Vector2(228.0, 186.0)
	box.add_theme_stylebox_override("panel", _make_ff6_box())
	pause_panel.add_child(box)

	var hdr: Label = Label.new()
	hdr.position = Vector2(126.0, 48.0)
	hdr.size = Vector2(228.0, 18.0)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.text = "PAUSED"
	hdr.add_theme_font_size_override("font_size", FONT_SZ)
	hdr.add_theme_color_override("font_color", Color("#ffe854"))
	pause_panel.add_child(hdr)

	var p_specs: Array[Dictionary] = [
		{"label": "RESUME", "cb": _resume_game, "accent": Color("#3ce878")},
		{"label": "OPTIONS", "cb": _open_options_from_pause, "accent": Color("#28e8ff")},
		{"label": "RETIRE TO HANGAR", "cb": _retire_from_pause, "accent": Color("#ffe854")},
		{"label": "QUIT TO TITLE", "cb": _quit_from_pause, "accent": Color("#ff4c68")},
	]

	for i: int in range(p_specs.size()):
		var spec: Dictionary = p_specs[i]
		var btn: Button = Button.new()
		btn.position = Vector2(148.0, 74.0 + float(i) * 34.0)
		btn.size = Vector2(184.0, 26.0)
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
	_enter_hangar("RETIRED ON STAGE %d  |  +%d SCRAP BANKED!" % [current_stage_idx + 1, run_scrap])


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

	var d_title: Label = Label.new()
	d_title.position = Vector2(0.0, 28.0)
	d_title.size = Vector2(VIEW_W, 16.0)
	d_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_title.text = "SELECT MODULE  [1 / 2 / 3  or  D-PAD + A]"
	d_title.add_theme_font_size_override("font_size", FONT_SZ)
	d_title.add_theme_color_override("font_color", Color("#ffe854"))
	draft_panel.add_child(d_title)

	_draft_cards.clear()
	for i: int in range(3):
		var cx: float = 20.0 + float(i) * 150.0
		var cy: float = 52.0
		var cw: float = 140.0
		var ch: float = 156.0

		var btn: Button = Button.new()
		btn.position = Vector2(cx, cy)
		btn.size = Vector2(cw, ch)
		var idx: int = i
		btn.pressed.connect(func() -> void: _pick_draft_card(idx))
		draft_panel.add_child(btn)

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
		short_lbl.position = Vector2(6.0, 118.0)
		short_lbl.size = Vector2(cw - 12.0, 28.0)
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
		})


func _hide_all_menus() -> void:
	title_panel.visible = false
	stats_panel.visible = false
	options_panel.visible = false
	hangar_panel.visible = false
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

	if MetaSave.has_any_affordable_upgrade():
		_title_hangar_btn.text = "HANGAR (%d SCRAP!)" % MetaSave.scrap
	elif MetaSave.scrap > 0:
		_title_hangar_btn.text = "HANGAR (%d)" % MetaSave.scrap
	else:
		_title_hangar_btn.text = "SHIP HANGAR"

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
		+ "HANGAR UPGRADES:   %d / %d" % [MetaSave.get_total_upgrade_ranks(), MetaSave.get_max_upgrade_ranks()]
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

	if summary_msg == "":
		_hangar_summary_lbl.text = "Permanent ship upgrades kept across all runs."
	else:
		_hangar_summary_lbl.text = summary_msg

	_refresh_hangar_ui()
	_hangar_launch_btn.grab_focus()


func _refresh_hangar_ui() -> void:
	_hangar_scrap_lbl.text = "SCRAP: %d" % MetaSave.scrap
	for row: Dictionary in _hangar_rows:
		var id: String = String(row["id"])
		var def: Dictionary = MetaSave.get_upgrade_def(id)
		var lvl: int = MetaSave.get_level(id)
		var max_lvl: int = int(def["max_level"])
		var pips: String = ""
		for p: int in range(max_lvl):
			pips += "■" if p < lvl else "□"

		var n_lbl: Label = row["name_lbl"]
		n_lbl.text = "%s  [%s]" % [String(def["name"]), pips]

		var btn: Button = row["buy_btn"]
		if lvl >= max_lvl:
			btn.text = "MAXED"
			btn.disabled = true
		else:
			var cost: int = MetaSave.get_upgrade_cost(id)
			btn.text = "BUY %d" % cost
			btn.disabled = not MetaSave.can_buy(id)


func _on_buy_permanent(id: String) -> void:
	if MetaSave.buy_upgrade(id):
		RetroSfx.play("powerup", -7.0, 0.03)
		_refresh_hangar_ui()


func _start_run() -> void:
	_unfreeze_world()
	RetroSfx.play("powerup", -5.0, 0.02)
	_clear_entities()
	fx_layer.clear_all()
	_hide_all_menus()

	# Begin with an exciting Hyperspace Warp-In Arrival into Stage 1!
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
	_pending_hyperspace = false
	run_ranks.clear()
	_squad_counts.clear()

	player.reset_for_new_run()
	player.controls_enabled = false
	player.global_position = Vector2(-44.0, 134.0)
	if MetaSave.has_starter_shield():
		run_ranks["shield"] = 1

	GenesisMusic.play_stage(0)
	_show_banner("HYPERSPACE WARP EXIT\nSTAGE 1: OUTER ORBIT", Color("#28e8ff"), INTRO_DURATION)
	hud_bar.queue_redraw()


func _update_intro_warp(delta: float) -> void:
	_intro_timer += delta
	var prog: float = clampf(_intro_timer / INTRO_DURATION, 0.0, 1.0)

	if prog < 0.58:
		# Streak in at high velocity through blazing warp ribbons!
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
		_show_banner("WARNING! %s!" % String(st["boss_name"]), Color("#ff4c68"), 2.6)
		RetroSfx.play("big_explode", -7.0, 0.02)
		_queue_enemy(0.8, GameEnemy.Type.BOSS, Vector2(520.0, 134.0), hp_mult, 0.0, -1)
	else:
		_pending_hyperspace = false
		starfield.speed_scale = 1.15 + minf(0.35, float(wave) * 0.025)
		GenesisMusic.play_stage(current_stage_idx)
		if sub_wave == 1:
			_show_banner("STAGE %d: %s\n%s" % [stage_display_num, String(st["name"]), String(st["subtitle"])], st["accent"], 2.3)
		else:
			_show_banner("STAGE %d-%d  //  %s" % [stage_display_num, sub_wave, String(st["name"])], Color("#ffe854"), 1.5)

		# Full-length ~32-42 second arcade waves with 10-14 varied enemy formations!
		var t: float = 0.65
		var num_groups: int = mini(14, 10 + current_stage_idx / 2 + sub_wave - 1)
		for g: int in range(num_groups):
			var roll: int = (wave * 3 + g * 2) % 6
			if roll == 0:
				# 6-Ship Sine Squadron
				var sq_id: int = _next_squad_id
				_next_squad_id += 1
				_squad_counts[sq_id] = 6
				var lane_y: float = randf_range(62.0, 196.0)
				for k: int in range(6):
					_queue_enemy(t + float(k) * 0.24, GameEnemy.Type.SCOUT_SINE, Vector2(500.0, lane_y), hp_mult, float(k) * 0.52, sq_id)
				t += 2.5
			elif roll == 1:
				# Pincer Swooper Dive (top & bottom simultaneous rush)
				var count: int = 4 if wave < 3 else 5
				var sq_id: int = _next_squad_id
				_next_squad_id += 1
				_squad_counts[sq_id] = count
				for k: int in range(count):
					var sy: float = 56.0 if k % 2 == 0 else 206.0
					_queue_enemy(t + float(k) * 0.30, GameEnemy.Type.SWOOPER, Vector2(504.0, sy), hp_mult, float(k), sq_id)
				t += 2.4
			elif roll == 2:
				# Crossfire Sniper Wing + Center Scouts
				var s_count: int = 2 if wave < 3 else 3
				for k: int in range(s_count):
					var py: float = lerpf(58.0, 204.0, float(k) / float(maxi(1, s_count - 1)))
					_queue_enemy(t + float(k) * 0.22, GameEnemy.Type.SNIPER, Vector2(504.0, py), hp_mult, float(k) * 1.1, -1)
				_queue_enemy(t + 0.5, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 134.0), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.8, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, 134.0), hp_mult, 0.8, -1)
				t += 2.7
			elif roll == 3:
				# Heavy Cruiser + Escort Vipers
				var cy: float = randf_range(74.0, 188.0)
				_queue_enemy(t, GameEnemy.Type.CRUISER, Vector2(512.0, cy), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.35, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, clampf(cy - 34.0, 48.0, 214.0)), hp_mult, 0.0, -1)
				_queue_enemy(t + 0.55, GameEnemy.Type.SCOUT_SINE, Vector2(504.0, clampf(cy + 34.0, 48.0, 214.0)), hp_mult, 1.0, -1)
				t += 2.9
			elif roll == 4:
				# V-Formation Scout Swarm (7 ships)
				var sq_id: int = _next_squad_id
				_next_squad_id += 1
				_squad_counts[sq_id] = 7
				var center_y: float = randf_range(96.0, 168.0)
				for k: int in range(7):
					var wing_off: float = float(absi(k - 3)) * 16.0 * (-1.0 if k < 3 else 1.0)
					_queue_enemy(t + float(absi(k - 3)) * 0.22, GameEnemy.Type.SCOUT_SINE, Vector2(502.0, clampf(center_y + wing_off, 48.0, 214.0)), hp_mult, float(k) * 0.4, sq_id)
				t += 2.6
			else:
				# Dual Swooper + Cruiser Ambush (or Twin Cruisers on later stages!)
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
	if state != State.PAUSED and _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			banner_label.visible = false

	# Analog left-stick menu navigation support for controllers!
	_poll_controller_menu_stick(delta)

	if state == State.TITLE and _title_ship_sprite != null:
		var t: float = float(Time.get_ticks_msec()) * 0.003
		_title_ship_sprite.position = Vector2(352.0 + cos(t * 0.7) * 8.0, 132.0 + sin(t) * 10.0)
		var alt: bool = (int(Time.get_ticks_msec() / 65) % 2 == 0)
		_title_ship_sprite.texture = PixelArt.tex("player_flame_2" if alt else "player_idle")

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
		hud_bar.queue_redraw()
	elif state == State.HYPERSPACE:
		_update_hyperspace(delta)
		hud_bar.queue_redraw()
	elif state == State.GAME_OVER_DELAY:
		_death_timer -= delta
		if _death_timer <= 0.0:
			MetaSave.record_run_end(wave, run_scrap, run_kills, score, run_bosses)
			var msg: String = "FELL ON STAGE %d (WAVE %d)  |  +%d SCRAP!" % [current_stage_idx + 1, wave, run_scrap]
			_enter_hangar(msg)


func _poll_controller_menu_stick(delta: float) -> void:
	if state == State.INTRO_WARP or state == State.PLAYING or state == State.HYPERSPACE or state == State.GAME_OVER_DELAY:
		return
	_joy_nav_cooldown = maxf(0.0, _joy_nav_cooldown - delta)
	if _joy_nav_cooldown > 0.0 or Input.get_connected_joypads().is_empty():
		return
	var pad: int = Input.get_connected_joypads()[0]
	var ax: float = Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
	var ay: float = Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)
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
	# Gamepad button handling across gameplay & menus
	if event is InputEventJoypadButton:
		var jb: InputEventJoypadButton = event as InputEventJoypadButton
		if not jb.pressed:
			return
		if jb.button_index == JOY_BUTTON_START:
			if state == State.PLAYING:
				_pause_game()
			elif state == State.PAUSED:
				_resume_game()
			elif state == State.TITLE or state == State.HANGAR:
				_start_run()
			return
		if jb.button_index == JOY_BUTTON_B and state != State.PLAYING:
			if state == State.PAUSED:
				_resume_game()
			elif state == State.OPTIONS:
				_leave_options()
			elif state == State.STATS or state == State.HANGAR:
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
		elif state == State.HANGAR:
			if k == KEY_SPACE or k == KEY_ENTER:
				_start_run()
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
		_wave_clear_delay -= delta
		if _wave_clear_delay <= 0.0:
			_open_upgrade_draft()


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


func _on_enemy_destroyed(enemy: GameEnemy, killed_by_player: bool) -> void:
	var sq: int = enemy.squad_id
	if not killed_by_player:
		if sq > 0 and _squad_counts.has(sq):
			_squad_counts.erase(sq)
		return

	run_kills += 1
	if enemy.enemy_type == GameEnemy.Type.BOSS:
		run_bosses += 1
	score += enemy.score_value
	var e_pos: Vector2 = enemy.global_position

	var drops: int = enemy.scrap_drop
	var crystal_count: int = mini(8, drops)
	var val_each: int = maxi(1, drops / maxi(1, crystal_count))
	for i: int in range(crystal_count):
		var offset: Vector2 = Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
		_spawn_pickup_deferred(e_pos + offset, GamePickup.Kind.SCRAP, val_each)

	if player.hp < player.max_hp and (enemy.enemy_type == GameEnemy.Type.BOSS or randf() < 0.10):
		_spawn_pickup_deferred(e_pos, GamePickup.Kind.HEAL, 1)

	if sq > 0 and _squad_counts.has(sq):
		var left: int = int(_squad_counts[sq]) - 1
		if left <= 0:
			_squad_counts.erase(sq)
			score += 500
			fx_layer.spawn_popup(e_pos + Vector2(-24.0, -10.0), "SQUAD +4!", Color("#28e8ff"))
			RetroSfx.play("powerup", -8.0, 0.03)
			for b: int in range(4):
				_spawn_pickup_deferred(e_pos + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)), GamePickup.Kind.SCRAP, 1)
		else:
			_squad_counts[sq] = left


func _spawn_pickup_deferred(pos: Vector2, kind: GamePickup.Kind, amount: int) -> void:
	call_deferred("_do_spawn_pickup", pos, int(kind), amount)


func _do_spawn_pickup(pos: Vector2, kind_int: int, amount: int) -> void:
	if state != State.PLAYING and state != State.DRAFT and state != State.HYPERSPACE:
		return
	var p: GamePickup = GamePickup.new()
	pickup_layer.add_child(p)
	var k: GamePickup.Kind = GamePickup.Kind.SCRAP if kind_int == int(GamePickup.Kind.SCRAP) else GamePickup.Kind.HEAL
	p.setup(pos, k, amount, player)
	p.collected.connect(_on_pickup_collected)


func _on_pickup_collected(kind_val: int, amount: int, pos: Vector2) -> void:
	if kind_val == int(GamePickup.Kind.SCRAP):
		var gained: int = maxi(1, int(round(float(amount) * MetaSave.get_scrap_mult())))
		run_scrap += gained
		score += gained * 25
		RetroSfx.play("scrap", -11.0, 0.06)
		fx_layer.spawn_popup(pos + Vector2(-6.0, -8.0), "+%d" % gained, Color("#ffe854"))
	else:
		player.heal(amount)
		RetroSfx.play("powerup", -7.0, 0.03)
		fx_layer.spawn_popup(pos + Vector2(-12.0, -8.0), "HULL +1", Color("#3ce878"))


func _open_upgrade_draft() -> void:
	for b: Node in bullet_layer.get_children():
		b.queue_free()

	var available: Array[Dictionary] = []
	for def: Dictionary in RUN_UPGRADE_POOL:
		var id: String = String(def["id"])
		var cur_rank: int = int(run_ranks.get(id, 0))
		if cur_rank < int(def["max_rank"]):
			available.append(def)

	available.shuffle()
	_draft_choices.clear()
	for i: int in range(mini(3, available.size())):
		_draft_choices.append(available[i])

	if _draft_choices.is_empty():
		_proceed_after_draft()
		return

	state = State.DRAFT
	player.controls_enabled = false
	player.clear_touch_drag()
	touch_focus_btn.visible = false
	pause_hud_btn.visible = false
	starfield.speed_scale = 1.65
	draft_panel.visible = true
	RetroSfx.play("ui", -7.0, 0.02)

	for i: int in range(3):
		var card: Dictionary = _draft_cards[i]
		var btn: Button = card["btn"]
		if i < _draft_choices.size():
			var choice: Dictionary = _draft_choices[i]
			var id: String = String(choice["id"])
			var cur: int = int(run_ranks.get(id, 0))
			var max_r: int = int(choice["max_rank"])
			var col: Color = choice["color"]

			btn.visible = true
			btn.add_theme_stylebox_override("normal", _make_ff6_box(Color("#0c1540"), col, 2))
			btn.add_theme_stylebox_override("hover", _make_ff6_box(Color("#192c75"), Color.WHITE, 2))
			btn.add_theme_stylebox_override("focus", _make_ff6_box(Color("#192c75"), Color.WHITE, 2))

			var title_lbl: Label = card["title_lbl"]
			title_lbl.text = "[%d] %s" % [i + 1, String(choice["title"])]
			title_lbl.add_theme_color_override("font_color", col)

			var pips_lbl: Label = card["pips_lbl"]
			if max_r <= 6:
				var pips: String = ""
				for r: int in range(max_r):
					pips += "■" if r <= cur else "□"
				pips_lbl.text = pips
			else:
				pips_lbl.text = "LV %d" % (cur + 1)
			pips_lbl.add_theme_color_override("font_color", Color("#b8ccf2"))

			var icon_rect: TextureRect = card["icon_rect"]
			icon_rect.texture = PixelArt.tex(String(choice["icon"]))

			var short_lbl: Label = card["short_lbl"]
			short_lbl.text = String(choice["desc"])
		else:
			btn.visible = false

	# Focus middle or first card so Gamepad D-Pad Left/Right + A works immediately!
	var focus_idx: int = 1 if _draft_choices.size() >= 2 else 0
	var first_btn: Button = _draft_cards[focus_idx]["btn"]
	first_btn.grab_focus()


func _pick_draft_card(index: int) -> void:
	if state != State.DRAFT or index < 0 or index >= _draft_choices.size():
		return
	var chosen: Dictionary = _draft_choices[index]
	var id: String = String(chosen["id"])
	run_ranks[id] = int(run_ranks.get(id, 0)) + 1
	player.apply_run_upgrade(id)

	RetroSfx.play("powerup", -6.0, 0.02)
	fx_layer.spawn_popup(player.global_position + Vector2(-20.0, -16.0), "+%s" % String(chosen["title"]), chosen["color"])

	draft_panel.visible = false
	_proceed_after_draft()


func _proceed_after_draft() -> void:
	if _pending_hyperspace:
		_begin_hyperspace_jump()
	else:
		state = State.PLAYING
		pause_hud_btn.visible = true
		player.controls_enabled = true
		_sync_touch_hud_visibility()
		_begin_next_wave()


func _on_player_hp_changed(_hp: int, _max_hp: int, _sh: int, _max_sh: int) -> void:
	hud_bar.queue_redraw()


func _on_player_died() -> void:
	state = State.GAME_OVER_DELAY
	_death_timer = 1.65
	pause_hud_btn.visible = false
	touch_focus_btn.visible = false
	starfield.hyperspace_active = false
	starfield.speed_scale = 0.35
	GenesisMusic.stop_music()
	_show_banner("SHIP DESTROYED! SALVAGING SCRAP...", Color("#ff4c68"), 1.6)


func _draw_hud() -> void:
	var font: Font = PixelArt.ui_font if PixelArt.ui_font != null else ThemeDB.fallback_font

	# --- 1) Top FF6 Royal-Blue Status Bar (y = 0..19) ---
	hud_bar.draw_rect(Rect2(0.0, 0.0, VIEW_W, 19.0), Color("#0b133b"))
	hud_bar.draw_line(Vector2(0.0, 19.0), Vector2(VIEW_W, 19.0), Color("#b8ccf2"), 1.0)

	hud_bar.draw_string(font, Vector2(6.0, 14.0), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#dce8ff"))

	var px: float = 23.0
	for i: int in range(player.max_hp):
		var filled: bool = i < player.hp
		hud_bar.draw_rect(Rect2(px, 6.0, 7.0, 7.0), Color("#f03c4e") if filled else Color("#281c36"))
		if filled:
			hud_bar.draw_rect(Rect2(px + 1.0, 7.0, 5.0, 2.0), Color("#ff9aa6"))
		px += 9.0

	if player.max_shield > 0:
		px += 2.0
		for i: int in range(player.max_shield):
			var s_on: bool = i < player.shield_charges
			hud_bar.draw_rect(Rect2(px, 6.0, 6.0, 7.0), Color("#28e8ff") if s_on else Color("#142c4a"))
			px += 8.0

	var st: Dictionary = StageData.get_stage(current_stage_idx)
	var sub_w: int = StageData.get_wave_in_stage(wave)
	var st_txt: String = "%d-%s %s" % [
		current_stage_idx + 1,
		"BOSS" if StageData.is_boss_wave(wave) else str(sub_w),
		String(st["name"]),
	]
	hud_bar.draw_string(font, Vector2(142.0, 14.0), st_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, st["accent"])

	var scrap_txt: String = "SCRAP %d" % run_scrap
	hud_bar.draw_string(font, Vector2(288.0, 14.0), scrap_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#ffe854"))

	var score_txt: String = "%07d" % score
	hud_bar.draw_string(font, Vector2(368.0, 14.0), score_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color.WHITE)

	# --- 1b) Prominent 3-Phase Top Boss Health Bar when fighting any Stage Boss! ---
	for node: Node in enemy_layer.get_children():
		if node is GameEnemy:
			var ge: GameEnemy = node as GameEnemy
			if ge.enemy_type == GameEnemy.Type.BOSS and ge.hp > 0.0:
				var b_ratio: float = clampf(ge.hp / ge.max_hp, 0.0, 1.0)
				var bar_col: Color = Color("#28e8ff") if ge.boss_shield_timer > 0.0 else (
					Color("#ff3868") if ge.boss_phase == 3 else (Color("#ff9624") if ge.boss_phase == 2 else Color("#ffe854"))
				)
				hud_bar.draw_rect(Rect2(98.0, 22.0, 284.0, 8.0), Color("#0b1029"))
				hud_bar.draw_rect(Rect2(99.0, 23.0, 282.0 * b_ratio, 6.0), bar_col)
				# 33% and 66% Phase Threshold Divider Notches
				hud_bar.draw_line(Vector2(99.0 + 94.0, 22.0), Vector2(99.0 + 94.0, 30.0), Color("#dce6ff"), 1.0)
				hud_bar.draw_line(Vector2(99.0 + 188.0, 22.0), Vector2(99.0 + 188.0, 30.0), Color("#dce6ff"), 1.0)
				hud_bar.draw_rect(Rect2(98.0, 22.0, 284.0, 8.0), Color("#dce6ff"), false, 1.0)
				break

	# --- 2) Virtual Touch Thumbstick Feedback Ring (when dragging on Phone / Touch) ---
	if player.is_touch_dragging():
		var orig: Vector2 = player.get_touch_origin()
		var cur: Vector2 = player.get_touch_current()
		var knob: Vector2 = orig + (cur - orig).limit_length(22.0)
		hud_bar.draw_arc(orig, 20.0, 0.0, TAU, 24, Color(0.16, 0.91, 1.0, 0.35), 1.0)
		hud_bar.draw_circle(knob, 6.0, Color(0.16, 0.91, 1.0, 0.55))

	# --- 3) Clear Pictorial Bottom Ship Upgrades Dock (y = 250..270, NO cryptic abbreviations!) ---
	hud_bar.draw_rect(Rect2(0.0, 250.0, VIEW_W, 20.0), Color("#081032"))
	hud_bar.draw_line(Vector2(0.0, 250.0), Vector2(VIEW_W, 250.0), Color("#9ab4e8"), 1.0)

	var modules: Array[Dictionary] = []
	if player.option_count > 0:
		modules.append({"icon": "badge_option", "name": "Option", "val": "x%d" % player.option_count, "col": Color("#ff9624")})
	if player.spread_level > 0:
		modules.append({"icon": "badge_spread", "name": "Spread", "val": "Lv%d" % player.spread_level, "col": Color("#ffe854")})
	if player.laser_level > 0:
		modules.append({"icon": "badge_laser", "name": "Laser", "val": "Lv%d" % player.laser_level, "col": Color("#28e8ff")})
	if player.missile_level > 0:
		modules.append({"icon": "badge_missile", "name": "Missile", "val": "Lv%d" % player.missile_level, "col": Color("#ff4c68")})
	if player.max_shield > 0:
		modules.append({"icon": "badge_shield", "name": "Shield", "val": "Lv%d" % player.max_shield, "col": Color("#3ce8ff")})
	if player.rapid_level > 0:
		modules.append({"icon": "badge_rapid", "name": "Rapid", "val": "Lv%d" % player.rapid_level, "col": Color("#d46bff")})
	if player.thruster_level > 0:
		modules.append({"icon": "badge_thruster", "name": "Speed", "val": "Lv%d" % player.thruster_level, "col": Color("#3ce878")})

	if modules.is_empty():
		hud_bar.draw_string(font, Vector2(8.0, 264.0), "Upgrades: None yet (clear wave to install modules)", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color("#7c96c8"))
		return

	var compact: bool = modules.size() >= 7
	var bx: float = 4.0
	for mod: Dictionary in modules:
		var label_str: String = "%s %s" % [
			String(mod["name"]),
			String(mod["val"]).replace("Lv", "") if compact else String(mod["val"]),
		]
		var text_w: float = font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ).x
		var chip_w: float = 16.0 + text_w + 5.0
		var col: Color = mod["col"]

		# Framed module pill with colored accent bar + 11x11 pixel picture + full readable English name!
		hud_bar.draw_rect(Rect2(bx, 252.0, chip_w, 16.0), Color("#111d4a"))
		hud_bar.draw_rect(Rect2(bx, 267.0, chip_w, 1.0), col)
		var icon_tex: Texture2D = PixelArt.tex(String(mod["icon"]))
		if icon_tex != null:
			hud_bar.draw_texture(icon_tex, Vector2(bx + 2.0, 255.0))
		hud_bar.draw_string(font, Vector2(bx + 15.0, 264.0), label_str, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, Color.WHITE)
		bx += chip_w + 4.0
