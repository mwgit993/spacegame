extends Node

# Trailer / screenshot capture driver. Injected as an extra autoload into a scratch copy of
# the project and run under Movie Maker (--write-movie ... --fixed-fps 30), so every step
# below lands on an exact frame. Plays the game on autopilot with the music muted (the
# trailer's soundtrack is laid in afterwards) and the player intangible.

const FPS: float = 30.0

var t: float = 0.0
var main: Node = null
var steps: Array = []
var step_i: int = 0
var pilot_t: float = 0.0
var autopilot: bool = false

var overlay: CanvasLayer
var dim: ColorRect
var flash: ColorRect
var logo_rect: TextureRect
var card_lbl: Label
var sub_lbl: Label
var dim_target: float = 0.0
var flash_a: float = 0.0
var marks: Array = [] # [time, name] for picking screenshots afterwards


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100
	_build_overlay()
	var cut: float = 2.8
	steps = [
		[0.0, func() -> void: _setup(); _card("LOGO", "", 1.0)],
		[1.9, func() -> void: main.call("_start_run"); _give_upgrades(["spread"])],
		[3.0, func() -> void: _hide_card(); autopilot = true],
		[6.0, func() -> void: _mark("stage1_a")],
		[10.5, func() -> void: _mark("stage1_b")],
		[12.6, func() -> void: _card("BLAST THROUGH", "8 ALIEN WORLDS", 0.82)],
		[13.4, func() -> void: _jump_stage(2)],
		[14.6, func() -> void: _hide_card()],
		[14.6 + cut * 0.6, func() -> void: _mark("cloud")],
		[14.6 + cut, func() -> void: _flash(); _jump_stage(3)],
		[14.6 + cut * 1.6, func() -> void: _mark("forest")],
		[14.6 + cut * 2, func() -> void: _flash(); _jump_stage(4)],
		[14.6 + cut * 2.6, func() -> void: _mark("glacier")],
		[14.6 + cut * 3, func() -> void: _flash(); _jump_stage(5)],
		[14.6 + cut * 3.6, func() -> void: _mark("magma")],
		[14.6 + cut * 4, func() -> void: _flash(); _jump_stage(6)],
		[14.6 + cut * 4.6, func() -> void: _mark("trench")],
		[14.6 + cut * 5, func() -> void: _flash(); _jump_stage(7)],
		[14.6 + cut * 5.6, func() -> void: _mark("cyber")],
		[31.6, func() -> void: _card("LEVEL UP", "BUILD WILD LOADOUTS", 0.82)],
		[32.2, func() -> void: _jump_stage(1); _reset_loadout([], "neko"); _give_upgrades(_existing(["option", "option", "missile", "spread", "orbital", "aura", "chain", "mines", "homing", "laser"]))],
		[33.2, func() -> void: _open_draft()],
		[33.4, func() -> void: _hide_card()],
		[34.6, func() -> void: _mark("draft")],
		[36.0, func() -> void: main.call("_pick_draft_card", 1)],
		[39.0, func() -> void: _mark("loadout_action")],
		[41.0, func() -> void: _card("FACE", "GIANT BOSSES", 0.82)],
		[41.6, func() -> void: _reset_loadout(_existing(["orbital"]), "viper"); _jump_boss(7)],
		[42.8, func() -> void: _hide_card()],
		[47.5, func() -> void: _mark("boss")],
		[50.2, func() -> void: _kill_boss()],
		[51.0, func() -> void: _mark("boss_death")],
		[52.6, func() -> void: _card("UPGRADE YOUR SHIP", "BETWEEN RUNS", 0.82)],
		[53.4, func() -> void: autopilot = false; _open_tree()],
		[54.3, func() -> void: _hide_card()],
		[54.9, func() -> void: main.call("_move_tree_selection", Vector2.UP)],
		[55.5, func() -> void: main.call("_move_tree_selection", Vector2.RIGHT); _mark("tree")],
		[56.1, func() -> void: main.call("_move_tree_selection", Vector2.UP)],
		[56.7, func() -> void: main.call("_move_tree_selection", Vector2.LEFT)],
		[57.3, func() -> void: _unlock_ships(); main.call("_enter_loadout"); _loadout_slot(1)],
		[57.9, func() -> void: _loadout_slot(2)],
		[58.5, func() -> void: _loadout_slot(3); _mark("ships")],
		[59.1, func() -> void: _loadout_slot(5)],
		[59.7, func() -> void: _loadout_slot(6)],
		[60.3, func() -> void: _card("LOGO", "COMING SOON TO STEAM", 1.0)],
		[64.4, func() -> void: _finish()],
	]


func _process(delta: float) -> void:
	if main == null:
		main = get_tree().current_scene
		if main == null:
			return
	t += delta
	while step_i < steps.size() and t >= float(steps[step_i][0]) - 0.0001:
		var c: Callable = steps[step_i][1]
		step_i += 1
		c.call()
	GenesisMusic.set_volume(0.0)
	var p: Node2D = main.get("player")
	if p != null:
		p.set("collision_layer", 0)
		p.set("collision_mask", 0)
		p.set("auto_fire_toggle", true)
		if int(p.get("hp")) < int(p.get("max_hp")):
			p.set("hp", int(p.get("max_hp")))
	main.set("xp_to_next", 999999)
	if autopilot:
		_pilot(delta)
	dim.color.a = move_toward(dim.color.a, dim_target, delta * 4.0)
	flash_a = maxf(0.0, flash_a - delta * 3.2)
	flash.color.a = flash_a


func _setup() -> void:
	var ip: Node = get_node_or_null("/root/InputPrompts")
	if ip != null:
		ip.call("set_gamepad", true)
	MetaSave.set("default_autofire", true)
	# One rank of every skill-tree node, so level-up drafts can offer the tree's draft cards.
	MetaSave.set("scrap", 999999)
	for pass_i: int in range(12):
		for n: Dictionary in SkillTreeData.NODES:
			var id: String = String(n["id"])
			if MetaSave.get_level(id) == 0 and MetaSave.can_buy_node(id):
				MetaSave.buy_node(id)
	MetaSave.select_ship("viper")


func _pilot(delta: float) -> void:
	var p: Node2D = main.get("player")
	var world: Node = main.get("world_root")
	if p == null or not bool(p.get("controls_enabled")) or world.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	pilot_t += delta
	var target_y: float = 140.0 + sin(pilot_t * 0.9) * 60.0
	var best: float = INF
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		var e2: Node2D = e as Node2D
		if e2 == null:
			continue
		var dx: float = e2.global_position.x - p.global_position.x
		if dx > 24.0 and e2.global_position.x < 470.0 and dx < best:
			best = dx
			target_y = e2.global_position.y + sin(pilot_t * 3.0) * 6.0
	var tx: float = 72.0 + sin(pilot_t * 0.45) * 26.0
	var pos: Vector2 = p.global_position
	pos.x = lerpf(pos.x, tx, clampf(delta * 2.0, 0.0, 1.0))
	pos.y = lerpf(pos.y, clampf(target_y, 44.0, 236.0), clampf(delta * 3.2, 0.0, 1.0))
	p.global_position = pos


func _give_upgrades(ids: Array) -> void:
	var p: Node = main.get("player")
	var ranks: Dictionary = main.get("run_ranks")
	for id: String in ids:
		p.call("apply_run_upgrade", id)
		ranks[id] = int(ranks.get(id, 0)) + 1


# Jump the run straight to the first wave of `stage`, with some enemies on screen at once.
func _jump_stage(stage: int) -> void:
	main.call("_clear_entities")
	main.set("wave", stage * 4)
	main.call("_begin_next_wave")
	for i: int in range(4):
		var types: Array = [GameEnemy.Type.SCOUT_SINE, GameEnemy.Type.SWOOPER, GameEnemy.Type.CRUISER, GameEnemy.Type.SNIPER]
		main.call("_spawn_enemy_now", {"type": types[i], "pos": Vector2(300.0 + 40.0 * float(i), 70.0 + 45.0 * float(i)), "hp_mult": 3.0, "phase": float(i), "squad": -1, "stage": stage})


func _reset_loadout(ids: Array, ship: String) -> void:
	MetaSave.select_ship(ship)
	main.get("player").call("reset_for_new_run")
	(main.get("run_ranks") as Dictionary).clear()
	_give_upgrades(ids)


func _jump_boss(stage: int) -> void:
	main.call("_clear_entities")
	main.set("wave", stage * 4 + 3)
	main.call("_begin_next_wave")


func _kill_boss() -> void:
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if e is GameEnemy and (e as GameEnemy).enemy_type == GameEnemy.Type.BOSS:
			e.call("_start_boss_death_sequence")


func _open_draft() -> void:
	main.call("_open_upgrade_draft")


func _open_tree() -> void:
	main.call("_clear_entities")
	# Show a partly bought tree rather than the everything-at-rank-1 one used for the run.
	if MetaSave.has_method("_init_default_tree"):
		MetaSave.call("_init_default_tree")
	MetaSave.set("scrap", 4000)
	main.call("_enter_hangar", "")
	var bought: int = 0
	for n: Dictionary in SkillTreeData.NODES:
		var id: String = String(n["id"])
		if bought < 9 and MetaSave.can_buy_node(id):
			main.set("_tree_selected_id", id)
			main.call("_on_buy_tree_node")
			bought += 1
	main.call("_enter_hangar", "")


# Keep only upgrade ids this build knows (draft cards exist only after the skill-tree rework).
func _existing(ids: Array) -> Array:
	var known: Array = []
	for id: String in ids:
		if not MetaSave.has_method("is_run_upgrade_unlocked") or MetaSave.call("is_run_upgrade_unlocked", id) or id in ["option", "missile", "spread", "laser", "blades", "rapid", "flank", "turret"]:
			known.append(id)
	return known


func _unlock_ships() -> void:
	var levels: Dictionary = MetaSave.get("tree_levels")
	for ship_d: Dictionary in SkillTreeData.SHIPS:
		var id: String = String(ship_d["id"])
		if id != "viper":
			levels["ship_" + id] = 1


func _loadout_slot(i: int) -> void:
	main.call("_select_loadout_slot", i)


func _mark(name: String) -> void:
	marks.append([t, name])


func _finish() -> void:
	var f: FileAccess = FileAccess.open(OS.get_environment("CAPTURE_MARKS"), FileAccess.WRITE)
	if f != null:
		for m: Array in marks:
			f.store_line("%d %s" % [int(round(float(m[0]) * FPS)), String(m[1])])
		f.close()
	MetaSave.call("reset_save")
	get_tree().quit()


# --- Title cards ---------------------------------------------------------------------------

func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 120
	add_child(overlay)
	dim = ColorRect.new()
	dim.color = Color(0.016, 0.024, 0.06, 0.0)
	dim.size = Vector2(480.0, 270.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	logo_rect = TextureRect.new()
	var logo_path: String = OS.get_environment("CAPTURE_LOGO")
	var img: Image = Image.load_from_file(logo_path)
	if img != null:
		img.resize(img.get_width() / 10, img.get_height() / 10, Image.INTERPOLATE_NEAREST)
		logo_rect.texture = ImageTexture.create_from_image(img)
		logo_rect.scale = Vector2(2.0, 2.0)
		logo_rect.position = Vector2(roundf((480.0 - img.get_width() * 2.0) * 0.5), 78.0)
	logo_rect.visible = false
	overlay.add_child(logo_rect)
	card_lbl = _make_label(20, Color("#ffe854"))
	sub_lbl = _make_label(20, Color("#28e8ff"))
	flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.0)
	flash.size = Vector2(480.0, 270.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(flash)


func _make_label(size: int, col: Color) -> Label:
	var l: Label = Label.new()
	l.size = Vector2(480.0, 30.0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", load("res://assets/fonts/ff6_font.fnt"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color("#0b0f24"))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.visible = false
	overlay.add_child(l)
	return l


func _card(title: String, sub: String, alpha: float) -> void:
	dim_target = alpha
	if title == "LOGO":
		logo_rect.visible = true
		card_lbl.visible = false
		sub_lbl.text = sub
		sub_lbl.position = Vector2(0.0, 150.0)
		sub_lbl.visible = sub != ""
		if dim.color.a < alpha:
			dim.color.a = alpha
	else:
		logo_rect.visible = false
		card_lbl.text = title
		card_lbl.position = Vector2(0.0, 104.0)
		card_lbl.visible = true
		sub_lbl.text = sub
		sub_lbl.position = Vector2(0.0, 132.0)
		sub_lbl.visible = true


func _hide_card() -> void:
	dim_target = 0.0
	logo_rect.visible = false
	card_lbl.visible = false
	sub_lbl.visible = false


func _flash() -> void:
	flash_a = 0.85
