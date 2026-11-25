class_name PlayerShip
extends Area2D

signal hp_changed(current_hp: int, max_hp: int, shield_charges: int, max_shield: int)
signal player_died()
signal touch_state_changed()

const MIN_X: float = 18.0
const MAX_X: float = 462.0
const MIN_Y: float = 28.0
const MAX_Y: float = 234.0
const TRAIL_STEP_DIST: float = 2.0
const TRAIL_MAX_POINTS: int = 96
const OPTION_TRAIL_SPACING: int = 12

var bullet_container: Node2D = null
var fx: FxLayer = null

var max_hp: int = 4
var hp: int = 4
var invuln_timer: float = 0.0
var controls_enabled: bool = false
var auto_fire_toggle: bool = true

# In-run roguelite upgrades (reset each run!)
var move_speed: float = 155.0
var fire_rate_bonus: float = 1.0
var damage_bonus: float = 1.0
var spread_level: int = 0       # 0..3
var option_count: int = 0       # 0..4 Gradius trailing Option orbs
var missile_level: int = 0      # 0..3 Homing missile pods
var laser_level: int = 0        # 0..3 Piercing plasma laser
var max_shield: int = 0         # 0..3 Regenerating Force Shield charges
var rapid_level: int = 0        # 0..6 Fire rate coil ranks
var thruster_level: int = 0     # 0..4 Afterburner speed ranks
var shield_charges: int = 0
var shield_regen_timer: float = 0.0

# Touch & Gamepad state
var touch_detected: bool = false
var touch_focus_held: bool = false
var _touch_drag_idx: int = -1
var _touch_origin: Vector2 = Vector2.ZERO
var _touch_current: Vector2 = Vector2.ZERO
var _mouse_drag_sim: bool = false

var _fire_cooldown: float = 0.0
var _missile_cooldown: float = 0.0
var _anim_timer: float = 0.0
var _flame_alt: bool = false
var _focus_held: bool = false
var _prev_joy_y_btn: bool = false

var _sprite: Sprite2D
var _trail: Array[Vector2] = []
var _option_sprites: Array[Sprite2D] = []


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

	max_hp = MetaSave.get_starting_max_hp()
	hp = max_hp
	move_speed = 155.0
	fire_rate_bonus = MetaSave.get_base_fire_rate_mult()
	damage_bonus = MetaSave.get_base_damage_mult()
	spread_level = 0
	option_count = 0
	missile_level = 0
	laser_level = 0
	rapid_level = 0
	thruster_level = 0
	max_shield = 1 if MetaSave.has_starter_shield() else 0
	shield_charges = max_shield
	shield_regen_timer = 0.0

	_trail.clear()
	for i: int in range(TRAIL_MAX_POINTS):
		_trail.append(global_position - Vector2(float(i) * 1.5, 0.0))
	_sync_options()
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


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp, shield_charges, max_shield)


func apply_run_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"option":
			option_count = mini(4, option_count + 1)
			_sync_options()
		"spread":
			spread_level = mini(3, spread_level + 1)
		"missile":
			missile_level = mini(3, missile_level + 1)
		"laser":
			laser_level = mini(3, laser_level + 1)
		"shield":
			max_shield = mini(3, max_shield + 1)
			shield_charges = max_shield
			shield_regen_timer = 0.0
		"rapid":
			rapid_level = mini(6, rapid_level + 1)
			fire_rate_bonus += 0.22
			damage_bonus += 0.10
		"thruster":
			thruster_level = mini(4, thruster_level + 1)
			move_speed += 26.0
			invuln_timer = maxf(invuln_timer, 0.5)
		"repair":
			max_hp += 1
			hp = mini(max_hp, hp + 2)
	hp_changed.emit(hp, max_hp, shield_charges, max_shield)


func _sync_options() -> void:
	for i: int in range(4):
		var opt: Sprite2D = _option_sprites[i]
		opt.visible = visible and (i < option_count)
		if opt.visible:
			var idx: int = mini(_trail.size() - 1, (i + 1) * OPTION_TRAIL_SPACING)
			opt.global_position = _trail[idx]


func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 0.06:
		_anim_timer = 0.0
		_flame_alt = not _flame_alt
		_sprite.texture = PixelArt.tex("player_flame_2" if _flame_alt else "player_idle")

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

	# Full Gamepad / Controller Support (Left Stick, D-Pad, Triggers, Bumpers, Face Buttons)
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

		var y_down: bool = Input.is_joy_button_pressed(pad_id, JOY_BUTTON_Y)
		if y_down and not _prev_joy_y_btn:
			_toggle_autofire()
		_prev_joy_y_btn = y_down
		break

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

	# Primary weapon firing
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
		_fire_primary()
		var base_interval: float = 0.155 if laser_level == 0 else 0.165
		_fire_cooldown = base_interval / fire_rate_bonus

	if missile_level > 0:
		_missile_cooldown = maxf(0.0, _missile_cooldown - delta)
		if fire_pressed and _missile_cooldown <= 0.0:
			_fire_missiles()
			_missile_cooldown = maxf(0.32, 0.85 - float(missile_level) * 0.16)

	queue_redraw()


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

	# Real Phone / Tablet Multi-Touch Drag Flight!
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

	# Optional Mouse-Simulated Touch Drag when Touch Mode == ALWAYS ON in Options!
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
	# Exclude top HUD bar (y < 20), bottom module bar (y > 248), and bottom-right FOCUS pad
	if pos.y < 20.0 or pos.y > 248.0:
		return false
	if Rect2(410.0, 208.0, 66.0, 38.0).has_point(pos):
		return false
	return true


func _fire_primary() -> void:
	if bullet_container == null:
		return

	var emitters: Array[Vector2] = [global_position + Vector2(12.0, 0.0)]
	for i: int in range(option_count):
		emitters.append(_option_sprites[i].global_position + Vector2(6.0, 0.0))

	var is_laser: bool = laser_level > 0
	var tex_key: String = "bullet_laser" if is_laser else "bullet_vulcan"
	var speed: float = 410.0 if is_laser else 340.0
	var pierce: int = laser_level if is_laser else 0
	var base_dmg: float = (1.35 + 0.35 * float(laser_level - 1)) if is_laser else 1.0
	var dmg: float = base_dmg * damage_bonus

	for origin: Vector2 in emitters:
		var is_ship: bool = (origin == emitters[0])
		var mul: float = 1.0 if is_ship else 0.65
		if spread_level == 0:
			_spawn_player_bullet(origin, Vector2(speed, 0.0), dmg * mul, tex_key, pierce, false)
		elif spread_level == 1:
			_spawn_player_bullet(origin + Vector2(0.0, -3.0), Vector2(speed, 0.0), dmg * 0.78 * mul, tex_key, pierce, false)
			_spawn_player_bullet(origin + Vector2(0.0, 3.0), Vector2(speed, 0.0), dmg * 0.78 * mul, tex_key, pierce, false)
		elif spread_level == 2:
			_spawn_player_bullet(origin, Vector2(speed, 0.0), dmg * 0.85 * mul, tex_key, pierce, false)
			_spawn_player_bullet(origin, Vector2(speed, 0.0).rotated(-0.17), dmg * 0.68 * mul, tex_key, pierce, false)
			_spawn_player_bullet(origin, Vector2(speed, 0.0).rotated(0.17), dmg * 0.68 * mul, tex_key, pierce, false)
		else:
			_spawn_player_bullet(origin, Vector2(speed, 0.0), dmg * 0.85 * mul, tex_key, pierce, false)
			if is_ship:
				_spawn_player_bullet(origin, Vector2(speed, 0.0).rotated(-0.14), dmg * 0.62, tex_key, pierce, false)
				_spawn_player_bullet(origin, Vector2(speed, 0.0).rotated(0.14), dmg * 0.62, tex_key, pierce, false)
				_spawn_player_bullet(origin, Vector2(speed, 0.0).rotated(-0.30), dmg * 0.55, tex_key, pierce, false)
				_spawn_player_bullet(origin, Vector2(speed, 0.0).rotated(0.30), dmg * 0.55, tex_key, pierce, false)
			else:
				_spawn_player_bullet(origin, Vector2(speed, 0.0).rotated(-0.16), dmg * 0.55 * mul, tex_key, pierce, false)
				_spawn_player_bullet(origin, Vector2(speed, 0.0).rotated(0.16), dmg * 0.55 * mul, tex_key, pierce, false)

	RetroSfx.play("laser" if is_laser else "shoot", -12.5, 0.05)


func _fire_missiles() -> void:
	if bullet_container == null:
		return
	var m_dmg: float = (1.9 + 0.6 * float(missile_level)) * damage_bonus
	_spawn_player_bullet(global_position + Vector2(2.0, 7.0), Vector2(145.0, 65.0), m_dmg, "bullet_missile", 0, true)
	if missile_level >= 2:
		_spawn_player_bullet(global_position + Vector2(2.0, -7.0), Vector2(145.0, -65.0), m_dmg, "bullet_missile", 0, true)
	if missile_level >= 3 and option_count > 0:
		_spawn_player_bullet(_option_sprites[0].global_position, Vector2(165.0, 0.0), m_dmg * 0.8, "bullet_missile", 0, true)
	RetroSfx.play("missile", -11.0, 0.06)


func _spawn_player_bullet(pos: Vector2, vel: Vector2, dmg: float, tex_key: String, pierce: int, homing: bool) -> void:
	var b: GameBullet = GameBullet.new()
	bullet_container.add_child(b)
	b.setup(pos, vel, dmg, true, tex_key, pierce, homing, 4.0 if homing else 3.0, fx)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_contact_damage"):
			area.call("take_contact_damage", 4.0)
		take_player_hit()


func take_player_hit() -> void:
	if invuln_timer > 0.0 or not visible or not controls_enabled:
		return

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


func _draw() -> void:
	if not visible:
		return
	if shield_charges > 0:
		var pulse: float = 0.55 + 0.25 * sin(Time.get_ticks_msec() * 0.012)
		var col: Color = Color(0.16, 0.91, 1.0, pulse)
		draw_arc(Vector2(1.0, 0.0), 15.0, 0.0, TAU, 24, col, 1.0)
		if shield_charges >= 2:
			draw_arc(Vector2(1.0, 0.0), 17.5, -1.1, 1.1, 12, Color(0.55, 0.98, 1.0, pulse), 1.0)

	if _focus_held:
		draw_circle(Vector2.ZERO, 3.5, Color(0.16, 0.91, 1.0, 0.85))
		draw_circle(Vector2.ZERO, 1.8, Color.WHITE)
