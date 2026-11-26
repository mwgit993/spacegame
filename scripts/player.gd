class_name PlayerShip
extends Area2D

signal hp_changed(current_hp: int, max_hp: int, shield_charges: int, max_shield: int)
signal player_died()
signal touch_state_changed()

const MIN_X: float = 18.0
const MAX_X: float = 462.0
const MIN_Y: float = 30.0
const MAX_Y: float = 249.0
const TRAIL_STEP_DIST: float = 2.0
const TRAIL_MAX_POINTS: int = 96
const OPTION_TRAIL_SPACING: int = 12
const MAX_BLADES: int = 5

var bullet_container: Node2D = null
var fx: FxLayer = null

var max_hp: int = 4
var hp: int = 4
var invuln_timer: float = 0.0
var controls_enabled: bool = false
var auto_fire_toggle: bool = true

# Selected Ship Hull & Signature Weapon ("viper", "beetle", "phantom", "dread", "saucer", "eyeball", "neko")
var ship_id: String = "viper"
var signature_weapon: String = "vulcan" # "vulcan", "biowave", "rail", "flak", "saucer", "ocular", "cat"
var _ship_tex_0: String = "player_idle"
var _ship_tex_1: String = "player_flame_2"

# In-run Primary Beam Core & Co-Axial Aux Beam (so Exotic Ships NEVER lose their signature weapon!)
var active_beam: String = "vulcan"
var beam_level: int = 0                 # 1..4 for drafted Elemental/Tech Beam
var aux_beam: String = ""               # Used on Exotic Ships when they also draft a Tech Beam!
var weapon_overclock: int = 0           # 0..4 ranks boosting your ship's main blaster!
var has_revive_charge: bool = false

# In-run Physical Ship Addons (visibly mounted on or orbiting the ship!)
var option_count: int = 0               # 0..4 Gradius trailing Option orbs (mirror your active weapon!)
var missile_level: int = 0              # 0..4 Homing missile wing pods
var flank_level: int = 0                # 0..3 Tail & diagonal flank gun turrets
var blade_level: int = 0                # 0..4 Orbiting chakram sawblades
var turret_level: int = 0               # 0..4 360-degree roof smart auto-turret dome
var bomb_level: int = 0                 # 0..3 Underbelly singularity gravity bomb bay
var nova_level: int = 0                 # 0..3 Wing EMP shockwave capacitor fins

# In-run Core Ship Systems & Meta Stats
var move_speed: float = 155.0
var fire_rate_bonus: float = 1.0
var damage_bonus: float = 1.0
var crit_chance: float = 0.0
var proj_size_mult: float = 1.0
var aoe_scale_mult: float = 1.0
var spread_level: int = 0               # 0..3 Spread fan matrix
var max_shield: int = 0                 # 0..3 Regenerating Force Shield charges
var rapid_level: int = 0                # 0..5 Fire rate coil ranks
var thruster_level: int = 0             # 0..4 Afterburner speed ranks
var shield_charges: int = 0
var shield_regen_timer: float = 0.0

# Touch & Gamepad state
var touch_detected: bool = false
var touch_focus_held: bool = false
var _touch_drag_idx: int = -1
var _touch_origin: Vector2 = Vector2.ZERO
var _touch_current: Vector2 = Vector2.ZERO
var _mouse_drag_sim: bool = false

# Weapon & Addon timers
var _fire_cooldown: float = 0.0
var _missile_cooldown: float = 0.0
var _flank_cooldown: float = 0.0
var _turret_cooldown: float = 0.0
var _bomb_cooldown: float = 0.0
var _nova_cooldown: float = 0.0
var _blade_dmg_timer: float = 0.0
var _blade_orbit_angle: float = 0.0
var _wave_flip: bool = false
var _volley_count: int = 0
var _turret_aim_dir: Vector2 = Vector2.RIGHT

var _anim_timer: float = 0.0
var _flame_alt: bool = false
var _focus_held: bool = false
var _prev_joy_y_btn: bool = false

var _sprite: Sprite2D
var _trail: Array[Vector2] = []
var _option_sprites: Array[Sprite2D] = []
var _blade_sprites: Array[Sprite2D] = []
var _blade_block_cd: Array[float] = []


func _ready() -> void:
	collision_layer = 1
	collision_mask = 4
	monitoring = true
	monitorable = true

	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.tex("player_idle")
	add_child(_sprite)

	# Small fair arcade core hurtbox (radius 3px!)
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 3.0
	col.shape = shape
	add_child(col)

	for i: int in range(4):
		var opt: Sprite2D = Sprite2D.new()
		opt.texture = PixelArt.tex("option_orb")
		opt.top_level = true
		opt.visible = false
		add_child(opt)
		_option_sprites.append(opt)

	for i: int in range(MAX_BLADES):
		var bl: Sprite2D = Sprite2D.new()
		bl.texture = PixelArt.tex("addon_sawblade")
		bl.top_level = true
		bl.visible = false
		add_child(bl)
		_blade_sprites.append(bl)
		_blade_block_cd.append(0.0)

	area_entered.connect(_on_area_entered)


func reset_for_new_run() -> void:
	global_position = Vector2(56.0, 134.0)
	visible = true
	controls_enabled = true
	auto_fire_toggle = MetaSave.default_autofire
	invuln_timer = 1.0
	touch_focus_held = false
	_touch_drag_idx = -1
	_mouse_drag_sim = false

	var ship_def: Dictionary = MetaSave.get_selected_ship_def()
	ship_id = String(ship_def["id"])
	signature_weapon = String(ship_def["weapon_id"])
	_ship_tex_0 = String(ship_def["sprite_0"])
	_ship_tex_1 = String(ship_def["sprite_1"])
	_sprite.texture = PixelArt.tex(_ship_tex_0)

	var opt_tex_key: String = "option_yarn" if ship_id == "neko" else "option_orb"
	for opt: Sprite2D in _option_sprites:
		opt.texture = PixelArt.tex(opt_tex_key)

	max_hp = MetaSave.get_starting_max_hp()
	hp = max_hp
	move_speed = MetaSave.get_starting_speed()
	fire_rate_bonus = MetaSave.get_base_fire_rate_mult()
	damage_bonus = MetaSave.get_base_damage_mult()
	crit_chance = MetaSave.get_crit_chance()
	proj_size_mult = MetaSave.get_projectile_size_mult()
	aoe_scale_mult = MetaSave.get_aoe_scale_mult()
	has_revive_charge = MetaSave.has_lazarus_revive()

	active_beam = signature_weapon
	aux_beam = ""
	beam_level = 0
	weapon_overclock = 0
	spread_level = 0
	rapid_level = 0
	thruster_level = 0

	var starters: Dictionary = MetaSave.get_starter_addons()
	option_count = mini(4, int(starters.get("option", 0)))
	turret_level = mini(4, int(starters.get("turret", 0)))
	missile_level = mini(4, int(starters.get("missile", 0)))
	blade_level = mini(4, int(starters.get("blades", 0)))
	nova_level = mini(3, int(starters.get("nova", 0)))
	bomb_level = mini(3, int(starters.get("bomb", 0)))
	flank_level = mini(3, int(starters.get("flank", 0)))

	max_shield = mini(3, MetaSave.get_starting_shields())
	shield_charges = max_shield
	shield_regen_timer = 0.0

	_fire_cooldown = 0.0
	_missile_cooldown = 0.0
	_flank_cooldown = 0.0
	_turret_cooldown = 0.0
	_bomb_cooldown = 0.0
	_nova_cooldown = 2.0
	_volley_count = 0
	_turret_aim_dir = Vector2.RIGHT
	for i: int in range(MAX_BLADES):
		_blade_block_cd[i] = 0.0

	_trail.clear()
	for i: int in range(TRAIL_MAX_POINTS):
		_trail.append(global_position - Vector2(float(i) * 1.5, 0.0))
	_sync_options()
	_sync_blades()
	hp_changed.emit(hp, max_hp, shield_charges, max_shield)


func clear_touch_drag() -> void:
	_touch_drag_idx = -1
	_mouse_drag_sim = false
	touch_focus_held = false


func is_touch_dragging() -> bool:
	return _touch_drag_idx != -1 or _mouse_drag_sim


func get_touch_origin() -> Vector2:
	return _touch_origin


func get_touch_current() -> Vector2:
	return _touch_current


func set_options_hidden() -> void:
	for opt: Sprite2D in _option_sprites:
		opt.visible = false
	for bl: Sprite2D in _blade_sprites:
		bl.visible = false


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp, shield_charges, max_shield)


func get_committed_tech_beam() -> String:
	if signature_weapon == "vulcan":
		return active_beam if active_beam != "vulcan" else ""
	return aux_beam


func apply_run_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"overclock":
			weapon_overclock = mini(4, weapon_overclock + 1)
			damage_bonus += 0.12
		"laser", "wave", "prism", "tesla", "plasma":
			if signature_weapon == "vulcan":
				if active_beam != upgrade_id:
					active_beam = upgrade_id
					beam_level = maxi(1, beam_level)
				else:
					beam_level = mini(4, beam_level + 1)
			else:
				# Exotic Ships keep their unique signature gun AND mount drafted Tech Beams co-axially!
				if aux_beam != upgrade_id:
					aux_beam = upgrade_id
					beam_level = maxi(1, beam_level)
				else:
					beam_level = mini(4, beam_level + 1)
		"option":
			option_count = mini(4, option_count + 1)
			_sync_options()
		"missile":
			missile_level = mini(4, missile_level + 1)
		"flank":
			flank_level = mini(3, flank_level + 1)
		"blades":
			blade_level = mini(4, blade_level + 1)
			_sync_blades()
		"turret":
			turret_level = mini(4, turret_level + 1)
		"bomb":
			bomb_level = mini(3, bomb_level + 1)
		"nova":
			nova_level = mini(3, nova_level + 1)
			_nova_cooldown = minf(_nova_cooldown, 0.6)
		"spread":
			spread_level = mini(3, spread_level + 1)
		"shield":
			max_shield = mini(3, max_shield + 1)
			shield_charges = max_shield
			shield_regen_timer = 0.0
		"rapid":
			rapid_level = mini(5, rapid_level + 1)
			fire_rate_bonus += 0.22
			damage_bonus += 0.10
		"thruster":
			thruster_level = mini(4, thruster_level + 1)
			move_speed += 25.0
			invuln_timer = maxf(invuln_timer, 0.5)
		"repair":
			max_hp += 1
			hp = mini(max_hp, hp + 2)
			damage_bonus += 0.12
	hp_changed.emit(hp, max_hp, shield_charges, max_shield)


func _sync_options() -> void:
	for i: int in range(4):
		var opt: Sprite2D = _option_sprites[i]
		opt.visible = visible and (i < option_count)
		if opt.visible:
			var idx: int = mini(_trail.size() - 1, (i + 1) * OPTION_TRAIL_SPACING)
			opt.global_position = _trail[idx]


func _active_blade_count() -> int:
	return 0 if blade_level <= 0 else mini(MAX_BLADES, 1 + blade_level)


func _sync_blades() -> void:
	var count: int = _active_blade_count()
	for i: int in range(MAX_BLADES):
		var bl: Sprite2D = _blade_sprites[i]
		bl.visible = visible and (i < count)
		if bl.visible and count > 0:
			var ang: float = _blade_orbit_angle + TAU * float(i) / float(count)
			bl.global_position = global_position + Vector2(cos(ang), sin(ang)) * 25.0


func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 0.07:
		_anim_timer = 0.0
		_flame_alt = not _flame_alt
		_sprite.texture = PixelArt.tex(_ship_tex_1 if _flame_alt else _ship_tex_0)

	if invuln_timer > 0.0:
		invuln_timer = maxf(0.0, invuln_timer - delta)
		_sprite.modulate.a = 0.35 if int(invuln_timer * 24.0) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0

	if max_shield > 0 and shield_charges < max_shield and visible and controls_enabled:
		shield_regen_timer += delta
		var regen_needed: float = maxf(4.5, 8.5 - float(max_shield) * 1.2)
		if shield_regen_timer >= regen_needed:
			shield_regen_timer = 0.0
			shield_charges += 1
			RetroSfx.play("powerup", -11.0, 0.03)
			hp_changed.emit(hp, max_hp, shield_charges, max_shield)

	if blade_level > 0 and visible:
		_update_orbiting_blades(delta)

	if not controls_enabled or not visible:
		queue_redraw()
		return

	var move_vec: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		move_vec.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		move_vec.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		move_vec.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		move_vec.y += 1.0

	var joy_focus: bool = false
	var joy_fire: bool = false
	var any_joy_y: bool = false

	# Poll ALL connected joypads so multi-controller PCs work seamlessly!
	for pad_id: int in Input.get_connected_joypads():
		var gx: float = Input.get_joy_axis(pad_id, JOY_AXIS_LEFT_X)
		var gy: float = Input.get_joy_axis(pad_id, JOY_AXIS_LEFT_Y)
		if absf(gx) > 0.18:
			move_vec.x += gx
		if absf(gy) > 0.18:
			move_vec.y += gy
		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_DPAD_LEFT):
			move_vec.x -= 1.0
		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_DPAD_RIGHT):
			move_vec.x += 1.0
		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_DPAD_UP):
			move_vec.y -= 1.0
		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_DPAD_DOWN):
			move_vec.y += 1.0

		if (
			Input.is_joy_button_pressed(pad_id, JOY_BUTTON_LEFT_SHOULDER)
			or Input.is_joy_button_pressed(pad_id, JOY_BUTTON_RIGHT_SHOULDER)
			or Input.get_joy_axis(pad_id, JOY_AXIS_TRIGGER_LEFT) > 0.35
		):
			joy_focus = true

		if (
			Input.is_joy_button_pressed(pad_id, JOY_BUTTON_A)
			or Input.is_joy_button_pressed(pad_id, JOY_BUTTON_X)
			or Input.get_joy_axis(pad_id, JOY_AXIS_TRIGGER_RIGHT) > 0.35
		):
			joy_fire = true

		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_Y):
			any_joy_y = true

	if any_joy_y and not _prev_joy_y_btn:
		_toggle_autofire()
	_prev_joy_y_btn = any_joy_y

	if move_vec.length_squared() > 1.0:
		move_vec = move_vec.normalized()

	_focus_held = Input.is_physical_key_pressed(KEY_SHIFT) or joy_focus or touch_focus_held
	var spd: float = move_speed * (0.52 if _focus_held else 1.0)
	var prev_pos: Vector2 = global_position
	global_position += move_vec * spd * delta
	global_position.x = clampf(global_position.x, MIN_X, MAX_X)
	global_position.y = clampf(global_position.y, MIN_Y, MAX_Y)

	var tilt_y: float = move_vec.y
	if is_touch_dragging():
		tilt_y = clampf((_touch_current.y - _touch_origin.y) * 0.05, -1.0, 1.0)
	rotation = lerpf(rotation, tilt_y * 0.09, 14.0 * delta)

	_record_trail_and_options(prev_pos, delta)

	# Primary Weapon & Addons!
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	var fire_pressed: bool = (
		auto_fire_toggle
		or joy_fire
		or is_touch_dragging()
		or Input.is_physical_key_pressed(KEY_SPACE)
		or Input.is_physical_key_pressed(KEY_Z)
		or Input.is_physical_key_pressed(KEY_J)
		or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and MetaSave.touch_mode != 1)
	)
	if fire_pressed and _fire_cooldown <= 0.0:
		var base_interval: float = _fire_primary()
		_fire_cooldown = base_interval / fire_rate_bonus

	if missile_level > 0:
		_missile_cooldown = maxf(0.0, _missile_cooldown - delta)
		if fire_pressed and _missile_cooldown <= 0.0:
			_fire_missiles()
			_missile_cooldown = maxf(0.28, 0.84 - float(missile_level) * 0.13) / (0.55 + 0.45 * fire_rate_bonus)

	if flank_level > 0:
		_flank_cooldown = maxf(0.0, _flank_cooldown - delta)
		if fire_pressed and _flank_cooldown <= 0.0:
			_fire_flank_guns()
			_flank_cooldown = 0.27 / fire_rate_bonus

	if turret_level > 0:
		_turret_cooldown = maxf(0.0, _turret_cooldown - delta)
		_aim_auto_turret(delta)
		if fire_pressed and _turret_cooldown <= 0.0:
			_fire_auto_turret()
			_turret_cooldown = maxf(0.11, 0.30 - float(turret_level) * 0.045) / (0.6 + 0.4 * fire_rate_bonus)

	if bomb_level > 0:
		_bomb_cooldown = maxf(0.0, _bomb_cooldown - delta)
		if fire_pressed and _bomb_cooldown <= 0.0:
			_fire_gravity_bomb()
			_bomb_cooldown = maxf(0.55, 1.35 - float(bomb_level) * 0.22)

	if nova_level > 0:
		_nova_cooldown = maxf(0.0, _nova_cooldown - delta)
		if _nova_cooldown <= 0.0:
			_trigger_nova_pulse(false)
			_nova_cooldown = maxf(3.0, 5.4 - float(nova_level) * 0.75)

	queue_redraw()


func _update_orbiting_blades(delta: float) -> void:
	var count: int = _active_blade_count()
	_blade_orbit_angle += delta * (4.4 + float(blade_level) * 0.45)
	_blade_dmg_timer = maxf(0.0, _blade_dmg_timer - delta)
	var deal_slice_tick: bool = (_blade_dmg_timer <= 0.0)
	if deal_slice_tick:
		_blade_dmg_timer = 0.13

	var slice_dmg: float = (1.35 + 0.45 * float(blade_level)) * damage_bonus

	for i: int in range(MAX_BLADES):
		var bl: Sprite2D = _blade_sprites[i]
		if i >= count:
			bl.visible = false
			continue
		bl.visible = true
		_blade_block_cd[i] = maxf(0.0, _blade_block_cd[i] - delta)
		var ang: float = _blade_orbit_angle + TAU * float(i) / float(count)
		var b_pos: Vector2 = global_position + Vector2(cos(ang), sin(ang)) * 25.0
		bl.global_position = b_pos
		bl.rotation += delta * 14.0

		if not controls_enabled:
			continue

		if deal_slice_tick:
			for node: Node in get_tree().get_nodes_in_group("enemies"):
				if node is Node2D and is_instance_valid(node) and node.has_method("take_damage"):
					var en: Node2D = node as Node2D
					var hit_r: float = 48.0 if (en is GameEnemy and (en as GameEnemy).enemy_type == GameEnemy.Type.BOSS) else 14.0
					if b_pos.distance_to(en.global_position) <= hit_r:
						en.call("take_damage", slice_dmg)
						if fx != null:
							fx.spawn_hit_sparks(b_pos, Color("#28e8ff"), 3)

		if _blade_block_cd[i] <= 0.0 and bullet_container != null:
			for child: Node in bullet_container.get_children():
				if child is GameBullet:
					var gb: GameBullet = child as GameBullet
					if not gb.is_player_bullet and b_pos.distance_squared_to(gb.global_position) <= 95.0:
						_blade_block_cd[i] = 0.85
						if fx != null:
							fx.spawn_hit_sparks(gb.global_position, Color("#28e8ff"), 5)
						RetroSfx.play("shield_hit", -14.0, 0.08)
						gb.queue_free()
						break


func _record_trail_and_options(prev_pos: Vector2, delta: float) -> void:
	if _trail.is_empty():
		return
	if global_position.distance_to(_trail[0]) >= TRAIL_STEP_DIST:
		_trail.push_front(global_position)
		if _trail.size() > TRAIL_MAX_POINTS:
			_trail.pop_back()
	elif prev_pos != global_position:
		_trail[0] = global_position

	for i: int in range(option_count):
		var opt: Sprite2D = _option_sprites[i]
		opt.visible = true
		var idx: int = mini(_trail.size() - 1, (i + 1) * OPTION_TRAIL_SPACING)
		opt.global_position = opt.global_position.lerp(_trail[idx], clampf(22.0 * delta, 0.0, 1.0))
		var pulse: float = 0.92 + 0.12 * sin(Time.get_ticks_msec() * 0.015 + float(i))
		opt.scale = Vector2(pulse, pulse)


func _toggle_autofire() -> void:
	auto_fire_toggle = not auto_fire_toggle
	if fx != null:
		fx.spawn_popup(global_position + Vector2(-18.0, -14.0), "AUTOFIRE ON" if auto_fire_toggle else "AUTOFIRE OFF", Color("#28e8ff"))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo and ke.physical_keycode == KEY_C and controls_enabled:
			_toggle_autofire()
			return

	if not controls_enabled or not visible or MetaSave.touch_mode == 2:
		return

	if event is InputEventScreenTouch:
		var te: InputEventScreenTouch = event as InputEventScreenTouch
		if not touch_detected:
			touch_detected = true
			touch_state_changed.emit()
		if te.pressed and _touch_drag_idx == -1 and _is_in_touch_playfield(te.position):
			_touch_drag_idx = te.index
			_touch_origin = te.position
			_touch_current = te.position
		elif not te.pressed and te.index == _touch_drag_idx:
			_touch_drag_idx = -1

	elif event is InputEventScreenDrag:
		var de: InputEventScreenDrag = event as InputEventScreenDrag
		if de.index == _touch_drag_idx:
			_touch_current = de.position
			var mult: float = 0.62 if _focus_held else 1.18
			global_position.x = clampf(global_position.x + de.relative.x * mult, MIN_X, MAX_X)
			global_position.y = clampf(global_position.y + de.relative.y * mult, MIN_Y, MAX_Y)

	elif MetaSave.touch_mode == 1 and event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _is_in_touch_playfield(mb.position):
				_mouse_drag_sim = true
				_touch_origin = mb.position
				_touch_current = mb.position
			elif not mb.pressed:
				_mouse_drag_sim = false
	elif MetaSave.touch_mode == 1 and _mouse_drag_sim and event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_touch_current = mm.position
		var mult2: float = 0.62 if _focus_held else 1.18
		global_position.x = clampf(global_position.x + mm.relative.x * mult2, MIN_X, MAX_X)
		global_position.y = clampf(global_position.y + mm.relative.y * mult2, MIN_Y, MAX_Y)


func _is_in_touch_playfield(pos: Vector2) -> bool:
	if pos.y < 23.0 or pos.y > 264.0:
		return false
	if Rect2(410.0, 224.0, 66.0, 38.0).has_point(pos):
		return false
	return true


func _get_mode_params(mode: String, rank: int) -> Dictionary:
	match mode:
		"laser":
			return {"tex": "bullet_laser", "spd": 435.0, "pierce": rank, "dmg": 1.32 + 0.34 * float(rank - 1), "cd": 0.160, "sfx": "laser"}
		"wave":
			return {"tex": "bullet_wave", "spd": 315.0, "pierce": 1 + rank / 2, "dmg": 1.25 + 0.30 * float(rank - 1), "cd": 0.172, "sfx": "laser"}
		"prism":
			return {"tex": "bullet_prism", "spd": 335.0, "pierce": 0, "dmg": 1.18 + 0.28 * float(rank - 1), "cd": 0.168, "sfx": "shoot"}
		"tesla":
			return {"tex": "bullet_tesla", "spd": 395.0, "pierce": 0, "dmg": 1.22 + 0.28 * float(rank - 1), "cd": 0.164, "sfx": "zap"}
		"plasma":
			return {"tex": "bullet_plasma", "spd": 278.0, "pierce": 0, "dmg": 1.68 + 0.42 * float(rank - 1), "cd": 0.210, "sfx": "missile"}
		"biowave":
			return {"tex": "bullet_biowave", "spd": 305.0, "pierce": 1 + rank / 2, "dmg": 1.34 + 0.32 * float(rank - 1), "cd": 0.170, "sfx": "laser"}
		"rail":
			return {"tex": "bullet_rail", "spd": 520.0, "pierce": 2 + rank, "dmg": 1.46 + 0.36 * float(rank - 1), "cd": 0.175, "sfx": "laser"}
		"flak":
			return {"tex": "bullet_flak", "spd": 288.0, "pierce": 0, "dmg": 1.60 + 0.38 * float(rank - 1), "cd": 0.205, "sfx": "missile"}
		"saucer":
			return {"tex": "bullet_ufo_ring", "spd": 320.0, "pierce": 0, "dmg": 1.24 + 0.28 * float(rank - 1), "cd": 0.168, "sfx": "shoot"}
		"ocular":
			return {"tex": "bullet_eyeball", "spd": 310.0, "pierce": 0, "dmg": 1.26 + 0.28 * float(rank - 1), "cd": 0.168, "sfx": "zap"}
		"cat":
			return {"tex": "bullet_cat_0", "spd": 318.0, "pierce": 0, "dmg": 1.35 + 0.32 * float(rank - 1), "cd": 0.172, "sfx": "shoot"}
		_:
			return {"tex": "bullet_vulcan", "spd": 355.0, "pierce": 0, "dmg": 1.0 + 0.24 * float(rank - 1), "cd": 0.148, "sfx": "shoot"}


func _fire_primary() -> float:
	if bullet_container == null:
		return 0.15

	var emitters: Array[Vector2] = [global_position + Vector2(12.0, 0.0)]
	for i: int in range(option_count):
		emitters.append(_option_sprites[i].global_position + Vector2(6.0, 0.0))

	_wave_flip = not _wave_flip
	_volley_count += 1
	var eff_rank: int = maxi(1, beam_level if (signature_weapon == "vulcan" and active_beam != "vulcan") else (1 + weapon_overclock))
	if signature_weapon == "vulcan" and active_beam != "vulcan":
		eff_rank = beam_level + weapon_overclock

	var p: Dictionary = _get_mode_params(active_beam, eff_rank)
	var tex_key: String = String(p["tex"])
	var speed: float = float(p["spd"])
	var pierce: int = int(p["pierce"])
	var dmg: float = float(p["dmg"]) * damage_bonus
	var interval: float = float(p["cd"])
	var sfx_key: String = String(p["sfx"])

	for e_idx: int in range(emitters.size()):
		var origin: Vector2 = emitters[e_idx]
		var is_ship: bool = (e_idx == 0)
		var mul: float = 1.0 if is_ship else 0.65

		if spread_level == 0:
			if active_beam == "prism" or active_beam == "cat" or active_beam == "saucer":
				var diag: float = 0.12 if _wave_flip else -0.12
				_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0).rotated(diag), dmg * mul, tex_key, pierce, 1.0)
			elif (active_beam == "wave" or active_beam == "biowave") and eff_rank >= 2:
				_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0), dmg * 0.68 * mul, tex_key, pierce, 1.0)
				_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0), dmg * 0.68 * mul, tex_key, pierce, -1.0)
			else:
				_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0), dmg * mul, tex_key, pierce, 1.0 if _wave_flip else -1.0)
		elif spread_level == 1:
			var fan1: float = 0.09 if (active_beam == "prism" or active_beam == "cat" or active_beam == "saucer") else 0.0
			_spawn_mode_shot(active_beam, eff_rank, origin + Vector2(0.0, -3.5), Vector2(speed, 0.0).rotated(-fan1), dmg * 0.78 * mul, tex_key, pierce, 1.0)
			_spawn_mode_shot(active_beam, eff_rank, origin + Vector2(0.0, 3.5), Vector2(speed, 0.0).rotated(fan1), dmg * 0.78 * mul, tex_key, pierce, -1.0)
		elif spread_level == 2:
			_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0), dmg * 0.85 * mul, tex_key, pierce, 1.0 if _wave_flip else -1.0)
			_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0).rotated(-0.18), dmg * 0.68 * mul, tex_key, pierce, 1.0)
			_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0).rotated(0.18), dmg * 0.68 * mul, tex_key, pierce, -1.0)
		else:
			_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0), dmg * 0.85 * mul, tex_key, pierce, 1.0 if _wave_flip else -1.0)
			if is_ship:
				_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0).rotated(-0.15), dmg * 0.62, tex_key, pierce, 1.0)
				_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0).rotated(0.15), dmg * 0.62, tex_key, pierce, -1.0)
				_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0).rotated(-0.32), dmg * 0.55, tex_key, pierce, 1.0)
				_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0).rotated(0.32), dmg * 0.55, tex_key, pierce, -1.0)
			else:
				_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0).rotated(-0.17), dmg * 0.55 * mul, tex_key, pierce, 1.0)
				_spawn_mode_shot(active_beam, eff_rank, origin, Vector2(speed, 0.0).rotated(0.17), dmg * 0.55 * mul, tex_key, pierce, -1.0)

	# Co-Axial Aux Tech Beam on Exotic Ships (every 2nd shot fires your drafted Elemental/Tech Beam too!)
	if aux_beam != "" and (_volley_count % 2 == 0):
		var ap: Dictionary = _get_mode_params(aux_beam, maxi(1, beam_level))
		_spawn_mode_shot(
			aux_beam,
			maxi(1, beam_level),
			global_position + Vector2(12.0, 0.0),
			Vector2(float(ap["spd"]), 0.0),
			float(ap["dmg"]) * damage_bonus * 0.85,
			String(ap["tex"]),
			int(ap["pierce"]),
			1.0 if _wave_flip else -1.0
		)

	if active_beam == "cat" and (_volley_count % 5 == 1):
		RetroSfx.play("meow", -14.0, 0.08)
	else:
		RetroSfx.play(sfx_key, -15.5 if sfx_key == "zap" else -12.5, 0.05)
	return interval


func _spawn_mode_shot(mode: String, rank: int, pos: Vector2, vel: Vector2, dmg: float, tex_key: String, pierce: int, w_sign: float) -> void:
	var hit_r: float = 5.0 if (mode == "wave" or mode == "biowave" or mode == "plasma" or mode == "cat") else 3.2
	var is_ocular: bool = (mode == "ocular")
	var b: GameBullet = _spawn_player_bullet(pos, vel, dmg, tex_key, pierce, is_ocular, hit_r)
	if is_ocular:
		b.homing_turn_rate = 2.8
		b.keep_upright = true
		b.chain_count = 1 + rank / 2

	match mode:
		"wave":
			b.wave_amp = 13.0 + float(rank) * 3.0
			b.wave_freq = 16.5
			b.wave_sign = w_sign
		"biowave":
			b.wave_amp = 11.0 + float(rank) * 2.5
			b.wave_freq = 13.5
			b.wave_sign = w_sign
			if rank >= 3:
				b.aoe_radius = 15.0 * aoe_scale_mult
				b.aoe_color = Color("#3ce878")
		"prism":
			b.bounces_left = 1 + rank
		"saucer":
			b.bounces_left = 1 + rank
			b.wave_amp = 8.0
			b.wave_freq = 14.0
			b.wave_sign = w_sign
		"tesla":
			b.chain_count = rank
		"plasma":
			b.aoe_radius = (22.0 + float(rank) * 5.0) * aoe_scale_mult
			b.aoe_color = Color("#ff6820")
		"flak":
			b.aoe_radius = (26.0 + float(rank) * 5.0) * aoe_scale_mult
			b.aoe_color = Color("#ff9624")
		"cat":
			b.anim_tex_b = "bullet_cat_1"
			b.keep_upright = true
			b.is_cat_shot = true
			b.bounces_left = 2 + rank / 2
			b.wave_amp = 5.5
			b.wave_freq = 14.0
			b.wave_sign = w_sign


func _fire_missiles() -> void:
	if bullet_container == null:
		return
	var m_dmg: float = (1.85 + 0.55 * float(missile_level)) * damage_bonus
	_spawn_player_bullet(global_position + Vector2(2.0, 7.0), Vector2(145.0, 65.0), m_dmg, "bullet_missile", 0, true, 4.0)
	if missile_level >= 2:
		_spawn_player_bullet(global_position + Vector2(2.0, -7.0), Vector2(145.0, -65.0), m_dmg, "bullet_missile", 0, true, 4.0)
	if missile_level >= 3:
		_spawn_player_bullet(global_position + Vector2(-2.0, 10.0), Vector2(125.0, 105.0), m_dmg * 0.85, "bullet_missile", 0, true, 4.0)
	if missile_level >= 4:
		_spawn_player_bullet(global_position + Vector2(-2.0, -10.0), Vector2(125.0, -105.0), m_dmg * 0.85, "bullet_missile", 0, true, 4.0)
	RetroSfx.play("missile", -11.5, 0.06)


func _fire_flank_guns() -> void:
	if bullet_container == null:
		return
	var f_dmg: float = (0.95 + 0.30 * float(flank_level)) * damage_bonus
	var f_pierce: int = 1 if flank_level >= 3 else 0
	var angles: Array[float] = [PI, 2.35, -2.35]
	if flank_level >= 2:
		angles = [PI, 2.15, -2.15, 1.35, -1.35]
	if flank_level >= 3:
		angles = [PI, 2.35, -2.35, PI * 0.5, -PI * 0.5]
	for ang: float in angles:
		var dir: Vector2 = Vector2.from_angle(ang)
		_spawn_player_bullet(global_position + dir * 8.0, dir * 310.0, f_dmg, "bullet_flank", f_pierce, false, 3.0)


func _find_closest_threat() -> Node2D:
	var best: Node2D = null
	var best_d2: float = 999999.0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node):
			var en: Node2D = node as Node2D
			if en.global_position.x > 6.0 and en.global_position.x < 476.0:
				var d2: float = global_position.distance_squared_to(en.global_position)
				if d2 < best_d2:
					best_d2 = d2
					best = en
	return best


func _aim_auto_turret(delta: float) -> void:
	var target: Node2D = _find_closest_threat()
	var desired: Vector2 = Vector2.RIGHT
	if target != null:
		desired = (target.global_position - (global_position + Vector2(-1.0, -6.0))).normalized()
	_turret_aim_dir = _turret_aim_dir.lerp(desired, clampf(16.0 * delta, 0.0, 1.0)).normalized()


func _fire_auto_turret() -> void:
	if bullet_container == null:
		return
	var t_dmg: float = (0.92 + 0.28 * float(turret_level)) * damage_bonus
	var muzzle: Vector2 = global_position + Vector2(-1.0, -6.0) + _turret_aim_dir * 6.0
	_spawn_player_bullet(muzzle, _turret_aim_dir * 425.0, t_dmg, "bullet_dart", 1 if turret_level >= 4 else 0, false, 3.0)


func _fire_gravity_bomb() -> void:
	if bullet_container == null:
		return
	var b_dmg: float = (2.8 + 0.9 * float(bomb_level)) * damage_bonus
	var b: GameBullet = _spawn_player_bullet(global_position + Vector2(0.0, 8.0), Vector2(185.0, -28.0), b_dmg, "bullet_bomb", 0, false, 4.5)
	b.gravity_pull = 245.0
	b.aoe_radius = (36.0 + float(bomb_level) * 9.0) * aoe_scale_mult
	b.aoe_color = Color("#b84cff")
	b.explode_on_floor = true
	RetroSfx.play("missile", -12.0, 0.06)


func _trigger_nova_pulse(reactive_burst: bool) -> void:
	var radius: float = (74.0 + float(nova_level) * 14.0) * aoe_scale_mult * (1.18 if reactive_burst else 1.0)
	var n_dmg: float = (3.2 + 1.4 * float(nova_level)) * damage_bonus
	if fx != null:
		fx.spawn_ring_blast(global_position, radius, Color("#28e8ff") if reactive_burst else Color("#ffe854"))
		fx.add_shake(2.5)
	RetroSfx.play("zap", -9.0, 0.04)

	var r2: float = radius * radius
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node) and node.has_method("take_damage"):
			var en: Node2D = node as Node2D
			if global_position.distance_squared_to(en.global_position) <= r2:
				en.call("take_damage", n_dmg)

	var clear_r2: float = (radius * 0.78) * (radius * 0.78)
	if bullet_container != null:
		for child: Node in bullet_container.get_children():
			if child is GameBullet:
				var gb: GameBullet = child as GameBullet
				if not gb.is_player_bullet and global_position.distance_squared_to(gb.global_position) <= clear_r2:
					if fx != null:
						fx.spawn_hit_sparks(gb.global_position, Color("#ffe854"), 3)
					gb.queue_free()


func _spawn_player_bullet(pos: Vector2, vel: Vector2, dmg: float, tex_key: String, pierce: int, homing: bool, hit_r: float = 3.0) -> GameBullet:
	var crit: bool = crit_chance > 0.0 and randf() < crit_chance
	var final_dmg: float = dmg * (2.0 if crit else 1.0)
	var b: GameBullet = GameBullet.new()
	bullet_container.add_child(b)
	b.setup(pos, vel, final_dmg, true, tex_key, pierce, homing, hit_r, fx)
	b.apply_size_and_crit(proj_size_mult, crit)
	return b


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_contact_damage"):
			area.call("take_contact_damage", 4.0)
		take_player_hit()


func take_player_hit() -> void:
	if invuln_timer > 0.0 or not visible or not controls_enabled:
		return

	if nova_level > 0:
		_trigger_nova_pulse(true)

	if shield_charges > 0:
		shield_charges -= 1
		shield_regen_timer = 0.0
		invuln_timer = 0.9
		RetroSfx.play("shield_hit", -6.0, 0.04)
		if fx != null:
			fx.add_shake(3.0)
			fx.spawn_hit_sparks(global_position, Color("#28e8ff"), 14)
			fx.spawn_popup(global_position + Vector2(-14.0, -14.0), "SHIELD!", Color("#28e8ff"))
		hp_changed.emit(hp, max_hp, shield_charges, max_shield)
		return

	hp = maxi(0, hp - 1)
	invuln_timer = 1.35
	shield_regen_timer = 0.0
	RetroSfx.play("player_hit", -4.0, 0.03)
	if fx != null:
		fx.add_shake(5.5)
		fx.spawn_explosion(global_position, false)

	# Lazarus Blackbox Skill Tree Keystone: Once-per-run Supernova Revive!
	if hp <= 0 and has_revive_charge:
		has_revive_charge = false
		hp = maxi(2, (max_hp + 1) / 2)
		invuln_timer = 2.4
		RetroSfx.play("unlock_ship", -4.0, 0.01)
		if fx != null:
			fx.spawn_ring_blast(global_position, 150.0, Color("#ffe854"))
			fx.add_shake(8.0)
			fx.spawn_popup(global_position + Vector2(-34.0, -18.0), "LAZARUS REVIVE!", Color("#ffe854"))
		if bullet_container != null:
			for child: Node in bullet_container.get_children():
				if child is GameBullet and not (child as GameBullet).is_player_bullet:
					child.queue_free()
		hp_changed.emit(hp, max_hp, shield_charges, max_shield)
		return

	hp_changed.emit(hp, max_hp, shield_charges, max_shield)

	if hp <= 0:
		visible = false
		controls_enabled = false
		clear_touch_drag()
		set_options_hidden()
		if fx != null:
			fx.add_shake(9.0)
			fx.spawn_explosion(global_position, true)
		RetroSfx.play("big_explode", -2.0, 0.02)
		player_died.emit()


func _get_beam_nose_color() -> Color:
	var check_b: String = aux_beam if aux_beam != "" else active_beam
	match check_b:
		"laser", "rail":
			return Color("#28e8ff")
		"wave", "biowave", "saucer":
			return Color("#3ce878")
		"prism", "cat":
			return Color("#ff4cd4")
		"tesla", "ocular":
			return Color("#b86bff")
		"plasma", "flak":
			return Color("#ff6820")
		_:
			return Color("#ffe854")


func _draw() -> void:
	if not visible:
		return

	# --- Visibly Mounted Hull Addons & Active Beam Nose Barrel! ---
	if active_beam != "vulcan" or aux_beam != "":
		var nose_col: Color = _get_beam_nose_color()
		draw_rect(Rect2(11.0, -2.0, 4.0, 4.0), nose_col)
		draw_rect(Rect2(12.0, -1.0, 3.0, 2.0), Color.WHITE)

	if missile_level > 0:
		draw_rect(Rect2(-1.0, -9.0, 6.0, 3.0), Color("#f03c4e"))
		draw_rect(Rect2(-1.0, 6.0, 6.0, 3.0), Color("#f03c4e"))

	if flank_level > 0:
		draw_rect(Rect2(-13.0, -2.0, 5.0, 4.0), Color("#8ca6d8"))
		draw_rect(Rect2(-5.0, -10.0, 4.0, 3.0), Color("#ffe854"))
		draw_rect(Rect2(-5.0, 7.0, 4.0, 3.0), Color("#ffe854"))

	if bomb_level > 0:
		draw_rect(Rect2(-4.0, 6.0, 6.0, 4.0), Color("#681d94"))
		draw_circle(Vector2(-1.0, 8.0), 1.5, Color("#ff4cd4"))

	if nova_level > 0:
		draw_line(Vector2(-6.0, -8.0), Vector2(-10.0, -12.0), Color("#ffe854"), 1.5)
		draw_line(Vector2(-6.0, 8.0), Vector2(-10.0, 12.0), Color("#ffe854"), 1.5)

	if turret_level > 0:
		var dome_pos: Vector2 = Vector2(-1.0, -6.0)
		var local_aim: Vector2 = _turret_aim_dir.rotated(-rotation)
		draw_circle(dome_pos, 3.2, Color("#197a44"))
		draw_circle(dome_pos, 2.0, Color("#3ce878"))
		draw_line(dome_pos, dome_pos + local_aim * 6.5, Color("#dce8ff"), 1.5)

	if shield_charges > 0:
		var pulse: float = 0.55 + 0.25 * sin(Time.get_ticks_msec() * 0.012)
		var col: Color = Color(0.16, 0.91, 1.0, pulse)
		draw_arc(Vector2(1.0, 0.0), 15.0, 0.0, TAU, 24, col, 1.0)
		if shield_charges >= 2:
			draw_arc(Vector2(1.0, 0.0), 17.5, -1.1, 1.1, 12, Color(0.55, 0.98, 1.0, pulse), 1.0)

	if _focus_held:
		draw_circle(Vector2.ZERO, 3.5, Color(0.16, 0.91, 1.0, 0.85))
		draw_circle(Vector2.ZERO, 1.8, Color.WHITE)
