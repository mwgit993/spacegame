class_name GameEnemy
extends Area2D

enum Type { SCOUT_SINE, SWOOPER, SNIPER, CRUISER, BOSS }

signal destroyed(enemy: GameEnemy, killed_by_player: bool)
signal boss_phase_broken(enemy: GameEnemy, bonus_xp: int)

static var _flash_shader: Shader = null

var enemy_type: Type = Type.SCOUT_SINE
var stage_idx: int = 0
var max_hp: float = 2.0
var hp: float = 2.0
var score_value: int = 100
var scrap_drop: int = 1
var xp_drop: int = 2
var squad_id: int = -1

var player_ref: Node2D = null
var bullet_container: Node2D = null
var fx: FxLayer = null

var _sprite: Sprite2D
var _mat: ShaderMaterial
var _flash_timer: float = 0.0
var _age: float = 0.0
var _base_y: float = 135.0
var _target_x: float = 360.0
var _phase_offset: float = 0.0
var _fire_timer: float = 1.2

# 3-Phase Boss Resilience, Mega Man Intro & Live Animation System!
const BOSS_HP_PIPS: int = 28
var boss_phase: int = 1                 # 1 (100..66%), 2 (66..33%), 3 (33..0%)
var boss_shield_timer: float = 0.0      # Brief invulnerable phase-shift barrier on phase transition
var boss_intro_active: bool = false     # True while Mega Man teleport arrival -> pose -> HP bar fill runs
var boss_hp_bar_visible: bool = false   # Becomes true once boss strikes pose & begins filling HP gauge
var boss_hp_bar_fill: float = 1.0       # 0.0 -> 1.0 pip-by-pip during Mega Man boss intro!

var _boss_intro_stage: int = 0          # 0 = beam arrival, 1 = landing pose, 2 = HP bar fill, 3 = fight
var _boss_intro_timer: float = 0.0
var _boss_hp_pips_filled: int = 0
var _boss_tex_base: String = "boss_space"
var _boss_attack_anim_timer: float = 0.0
var _boss_recoil_x: float = 0.0
var _boss_spark_timer: float = 0.25
var _boss_dying: bool = false
var _boss_death_timer: float = 0.0
var _boss_death_boom_timer: float = 0.0

var _dps_accumulator: float = 0.0       # Tracks burst damage per second to prevent 2-second instant melts
var _boss_pattern: int = 0
var _boss_substep: int = 0
var _boss_spin: float = 0.0
var _bullet_a: String = "bullet_enemy_pink"
var _bullet_b: String = "bullet_enemy_orange"
var _dead: bool = false

# Stage-by-stage exponential Boss HP curve (accounts for Option orbs, Spread, Laser & Rapid upgrades!)
const STAGE_BOSS_HP: Array[float] = [
	360.0,   # Stage 1: Outer Orbit
	820.0,   # Stage 2: Starcruiser
	1650.0,  # Stage 3: Cloud Base
	3100.0,  # Stage 4: Xeno Forest
	5200.0,  # Stage 5: Cryo Glacier
	8200.0,  # Stage 6: Magma Core
	12200.0, # Stage 7: Abyssal Trench
	17500.0, # Stage 8: Cyber Nexus
]


func setup(
	t: Type,
	spawn_pos: Vector2,
	hp_scale: float,
	p_ref: Node2D,
	b_container: Node2D,
	fx_ref: FxLayer,
	p_offset: float = 0.0,
	formation_squad: int = -1,
	st_idx: int = 0
) -> void:
	add_to_group("enemies")
	enemy_type = t
	stage_idx = posmod(st_idx, 8)
	var loop_count: int = maxi(0, st_idx / 8)
	var loop_mult: float = pow(2.2, float(loop_count))

	global_position = spawn_pos
	_base_y = spawn_pos.y
	_phase_offset = p_offset
	squad_id = formation_squad
	player_ref = p_ref
	bullet_container = b_container
	fx = fx_ref

	var st: Dictionary = StageData.get_stage(stage_idx)
	_bullet_a = String(st["bullet_a"])
	_bullet_b = String(st["bullet_b"])

	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true

	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = "shader_type canvas_item;\nuniform float flash : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n\tvec4 tex = texture(TEXTURE, UV);\n\tCOLOR = vec4(mix(tex.rgb, vec3(1.0), flash), tex.a);\n}\n"

	_mat = ShaderMaterial.new()
	_mat.shader = _flash_shader

	_sprite = Sprite2D.new()
	_sprite.material = _mat
	add_child(_sprite)

	var col: CollisionShape2D = CollisionShape2D.new()

	match enemy_type:
		Type.SCOUT_SINE:
			_sprite.texture = PixelArt.tex(String(st["scout_tex"]))
			max_hp = 2.2 * hp_scale * loop_mult
			score_value = 100
			scrap_drop = 1
			xp_drop = 2
			_fire_timer = randf_range(1.4, 2.4)
			var s1: CircleShape2D = CircleShape2D.new()
			s1.radius = 6.5
			col.shape = s1
		Type.SWOOPER:
			_sprite.texture = PixelArt.tex(String(st["swooper_tex"]))
			max_hp = 3.0 * hp_scale * loop_mult
			score_value = 150
			scrap_drop = 1
			xp_drop = 3
			_fire_timer = randf_range(0.8, 1.5)
			var s2: CircleShape2D = CircleShape2D.new()
			s2.radius = 7.0
			col.shape = s2
		Type.SNIPER:
			_sprite.texture = PixelArt.tex(String(st["sniper_tex"]))
			max_hp = 6.5 * hp_scale * loop_mult
			score_value = 250
			scrap_drop = 2
			xp_drop = 5
			_target_x = randf_range(325.0, 430.0)
			_fire_timer = 0.90
			var s3: CircleShape2D = CircleShape2D.new()
			s3.radius = 7.5
			col.shape = s3
		Type.CRUISER:
			_sprite.texture = PixelArt.tex(String(st["cruiser_tex"]))
			max_hp = 22.0 * hp_scale * loop_mult
			score_value = 600
			scrap_drop = 5
			xp_drop = 14
			_target_x = randf_range(340.0, 425.0)
			_fire_timer = 1.15
			var s4: CircleShape2D = CircleShape2D.new()
			s4.radius = 11.0
			col.shape = s4
		Type.BOSS:
			_boss_tex_base = String(st["boss_tex"])
			_sprite.texture = PixelArt.tex(_boss_tex_base + "_0")
			max_hp = STAGE_BOSS_HP[stage_idx] * loop_mult
			score_value = 5000 + stage_idx * 1500
			scrap_drop = 28 + stage_idx * 4
			xp_drop = 48 + stage_idx * 12
			_target_x = 424.0 if stage_idx == 0 else 414.0
			_fire_timer = 1.20

			# Launch Mega Man-style Boss Teleport Arrival -> Signature Pose -> 28-Pip HP Bar Fill!
			boss_intro_active = true
			boss_hp_bar_visible = false
			boss_hp_bar_fill = 0.0
			_boss_intro_stage = 0
			_boss_intro_timer = 0.0
			_boss_hp_pips_filled = 0
			global_position = Vector2(_target_x, -110.0)
			_sprite.scale = Vector2(0.18, 1.95)
			_mat.set_shader_parameter("flash", 1.0)
			RetroSfx.play("boss_beam", -5.0, 0.02)

			var box: RectangleShape2D = RectangleShape2D.new()
			box.size = Vector2(88.0, 176.0) if stage_idx == 0 else Vector2(82.0, 146.0)
			col.shape = box

	hp = max_hp
	add_child(col)


func _process(delta: float) -> void:
	if _dead:
		return
	_age += delta

	if _flash_timer > 0.0 and not boss_intro_active and not _boss_dying:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		_mat.set_shader_parameter("flash", 1.0 if _flash_timer > 0.0 else 0.0)

	if enemy_type == Type.BOSS:
		_process_boss(delta)
		return

	match enemy_type:
		Type.SCOUT_SINE:
			var freq: float = 4.6 if stage_idx == 3 else 3.6
			var spd: float = 96.0 if stage_idx == 7 else 84.0
			global_position.x -= spd * delta
			global_position.y = clampf(_base_y + sin(_age * freq + _phase_offset) * 26.0, 32.0, 232.0)
			_fire_timer -= delta
			if _fire_timer <= 0.0 and global_position.x > 90.0 and global_position.x < 455.0:
				_fire_timer = 2.3
				if randf() < 0.52:
					_shoot_aimed(125.0 + float(stage_idx) * 4.0, _bullet_b)

		Type.SWOOPER:
			var vx: float = -132.0 if (stage_idx == 2 or stage_idx == 4) else -122.0
			var vy: float = sin(_age * 5.0 + _phase_offset) * 75.0
			if _age > 0.55 and _age < 1.85 and player_ref != null and is_instance_valid(player_ref):
				vy = clampf((player_ref.global_position.y - global_position.y) * 2.5, -115.0, 115.0)
			global_position += Vector2(vx, vy) * delta
			global_position.y = clampf(global_position.y, 32.0, 232.0)
			_fire_timer -= delta
			if _fire_timer <= 0.0 and global_position.x > 120.0:
				_fire_timer = 1.6
				_shoot_aimed(144.0 + float(stage_idx) * 4.0, _bullet_a)

		Type.SNIPER:
			if _age < 6.0:
				global_position.x = lerpf(global_position.x, _target_x, 3.2 * delta)
				global_position.y = clampf(_base_y + sin(_age * 2.0 + _phase_offset) * 14.0, 34.0, 230.0)
			else:
				global_position.x -= 95.0 * delta
			_fire_timer -= delta
			if _fire_timer <= 0.0 and global_position.x < 465.0 and global_position.x > 80.0:
				_fire_timer = 1.4
				if stage_idx >= 3:
					_shoot_spread(2, 0.20, 148.0, _bullet_a)
				else:
					_shoot_aimed(155.0, _bullet_a)

		Type.CRUISER:
			if _age < 10.0:
				global_position.x = lerpf(global_position.x, _target_x, 2.2 * delta)
				global_position.y = clampf(_base_y + sin(_age * 1.3 + _phase_offset) * 28.0, 42.0, 224.0)
			else:
				global_position.x -= 55.0 * delta
			_fire_timer -= delta
			if _fire_timer <= 0.0 and global_position.x < 460.0:
				_fire_timer = 1.55
				_shoot_spread(4 if stage_idx >= 4 else 3, 0.22, 138.0 + float(stage_idx) * 4.0, _bullet_b)
			queue_redraw()

		_:
			pass

	if global_position.x < -36.0:
		_dead = true
		destroyed.emit(self, false)
		queue_free()


func _process_boss(delta: float) -> void:
	# 1) Dramatic Boss Chain-Explosion Meltdown on Defeat!
	if _boss_dying:
		_boss_death_timer -= delta
		_boss_death_boom_timer -= delta
		_sprite.texture = PixelArt.tex(_boss_tex_base + "_2")
		_sprite.position = Vector2(randf_range(-4.5, 4.5), randf_range(-4.5, 4.5))
		_mat.set_shader_parameter("flash", 1.0 if (int(_age * 26.0) % 2 == 0) else 0.0)
		if _boss_death_boom_timer <= 0.0:
			_boss_death_boom_timer = 0.13
			if fx != null:
				fx.spawn_explosion(global_position + Vector2(randf_range(-38.0, 24.0), randf_range(-58.0, 58.0)), true)
				fx.add_shake(5.0)
			RetroSfx.play("explode", -6.0, 0.09)
		if _boss_death_timer <= 0.0:
			_finish_boss_death()
			return
		queue_redraw()
		return

	# 2) Mega Man-Style 3-Stage Boss Intro Sequence!
	if boss_intro_active:
		_update_boss_intro(delta)
		queue_redraw()
		return

	# 3) Active Boss Combat & Multi-Frame Procedural Animation!
	var max_dps_allowed: float = max_hp * 0.062
	_dps_accumulator = maxf(0.0, _dps_accumulator - max_dps_allowed * delta)
	if boss_shield_timer > 0.0:
		boss_shield_timer = maxf(0.0, boss_shield_timer - delta)

	var bob_amp: float = 10.0 if stage_idx == 0 else (22.0 + float(boss_phase) * 4.0)
	var bob_spd: float = (0.9 if stage_idx == 0 else 1.2) + float(boss_phase - 1) * 0.25
	var sway_x: float = 0.0 if stage_idx == 0 else (-sin(_age * bob_spd * 2.0) * float(boss_phase) * 3.2)
	global_position.x = lerpf(global_position.x, _target_x + sway_x, 3.5 * delta)
	global_position.y = 134.0 + sin(_age * bob_spd) * bob_amp

	# Decay weapon recoil & attack squash/stretch smoothly
	_boss_recoil_x = lerpf(_boss_recoil_x, 0.0, clampf(delta * 14.0, 0.0, 1.0))
	_sprite.scale = _sprite.scale.lerp(Vector2.ONE, clampf(delta * 12.0, 0.0, 1.0))
	if _boss_attack_anim_timer > 0.0:
		_boss_attack_anim_timer = maxf(0.0, _boss_attack_anim_timer - delta)

	# Select animated boss sprite frame (_0, _1, or _2 for roar/attack/phase-burst)
	if _boss_attack_anim_timer > 0.0 or boss_shield_timer > 0.0:
		_sprite.texture = PixelArt.tex(_boss_tex_base + "_2")
	else:
		var anim_fps: float = 3.2 + float(boss_phase) * 1.5
		var idle_idx: int = int(_age * anim_fps) % 2
		_sprite.texture = PixelArt.tex(_boss_tex_base + ("_1" if idle_idx == 1 else "_0"))

	if boss_shield_timer > 0.0:
		_sprite.position = Vector2(_boss_recoil_x + randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	else:
		_sprite.position = Vector2(_boss_recoil_x, 0.0)
	_sprite.rotation = 0.0 if stage_idx == 0 else sin(_age * (1.8 + float(boss_phase) * 0.45)) * 0.036

	# Phase 3 Berserk damage sparks venting from hull
	if boss_phase >= 3:
		_boss_spark_timer -= delta
		if _boss_spark_timer <= 0.0:
			_boss_spark_timer = 0.26
			if fx != null:
				fx.spawn_hit_sparks(global_position + Vector2(randf_range(-32.0, 20.0), randf_range(-50.0, 50.0)), Color("#ff6828"), 4)

	_fire_timer -= delta
	if _fire_timer <= 0.0 and global_position.x < 465.0:
		_boss_attack()
		_boss_attack_anim_timer = 0.28
		_boss_recoil_x = 5.5
		_sprite.scale = Vector2(1.06, 0.95)

	queue_redraw()


func _update_boss_intro(delta: float) -> void:
	_boss_intro_timer += delta

	if _boss_intro_stage == 0:
		# Stage 0: Vertical Mega Man Teleport Beam streak-in to arena perch!
		var t0: float = clampf(_boss_intro_timer / 0.46, 0.0, 1.0)
		global_position.x = _target_x
		global_position.y = lerpf(-110.0, 134.0, 1.0 - pow(1.0 - t0, 2.2))
		_sprite.scale = Vector2(lerpf(0.16, 0.36, t0), lerpf(1.95, 1.42, t0))
		_mat.set_shader_parameter("flash", 1.0)

		if _boss_intro_timer >= 0.46:
			_boss_intro_stage = 1
			_boss_intro_timer = 0.0
			global_position = Vector2(_target_x, 134.0)
			_sprite.scale = Vector2(1.24, 0.80)
			_sprite.texture = PixelArt.tex(_boss_tex_base + "_2")
			RetroSfx.play("boss_pose", -4.5, 0.01)
			if fx != null:
				fx.add_shake(6.5)
				fx.spawn_hit_sparks(global_position + Vector2(-20.0, 0.0), Color("#28e8ff"), 18)

	elif _boss_intro_stage == 1:
		# Stage 1: Materialization Flash & Signature 2-Beat Boss Taunt / Power Pose!
		var t1: float = clampf(_boss_intro_timer / 0.68, 0.0, 1.0)
		_sprite.scale = _sprite.scale.lerp(Vector2.ONE, clampf(delta * 12.0, 0.0, 1.0))
		_mat.set_shader_parameter("flash", maxf(0.0, 1.0 - t1 * 2.8))
		var pose_suf: String = "_1" if (t1 > 0.28 and t1 < 0.52) else "_2"
		_sprite.texture = PixelArt.tex(_boss_tex_base + pose_suf)
		_sprite.position = Vector2(-6.0 * sin(t1 * PI), 0.0)

		if _boss_intro_timer >= 0.68:
			_boss_intro_stage = 2
			_boss_intro_timer = 0.0
			_sprite.scale = Vector2.ONE
			_sprite.position = Vector2.ZERO
			_mat.set_shader_parameter("flash", 0.0)
			boss_hp_bar_visible = true
			_boss_hp_pips_filled = 0
			boss_hp_bar_fill = 0.0

	else:
		# Stage 2: Classic Mega Man Tick-by-Tick Boss HP Bar Fill (28 pips)!
		while _boss_intro_timer >= 0.038 and _boss_hp_pips_filled < BOSS_HP_PIPS:
			_boss_intro_timer -= 0.038
			_boss_hp_pips_filled += 1
			boss_hp_bar_fill = float(_boss_hp_pips_filled) / float(BOSS_HP_PIPS)
			RetroSfx.play("boss_hp_tick", -9.0, 0.0)

		var fill_suf: String = "_2" if _boss_hp_pips_filled >= BOSS_HP_PIPS - 4 else (
			"_1" if (_boss_hp_pips_filled / 3) % 2 == 1 else "_0"
		)
		_sprite.texture = PixelArt.tex(_boss_tex_base + fill_suf)

		if _boss_hp_pips_filled >= BOSS_HP_PIPS:
			boss_hp_bar_fill = 1.0
			boss_intro_active = false
			_boss_intro_stage = 3
			boss_shield_timer = 0.0
			_age = 0.0
			_fire_timer = 0.35
			_boss_attack_anim_timer = 0.22
			RetroSfx.play("shield_hit", -6.0, 0.02)


func _boss_attack() -> void:
	# Faster cooldowns & higher bullet velocity in Phase 2 (<=66% HP) and Phase 3 (<=33% HP)!
	var rate_mult: float = 1.0 if boss_phase == 1 else (0.78 if boss_phase == 2 else 0.62)
	var spd_bonus: float = float(boss_phase - 1) * 18.0 + float(stage_idx) * 5.0

	_boss_substep += 1
	if _boss_substep >= 4:
		_boss_substep = 0
		_boss_pattern = (_boss_pattern + 1) % 3
		# In Phase 2 & 3 on Stages 2+, summon a pair of escort fighters to keep pressure high!
		if boss_phase >= 2 and stage_idx >= 1 and get_parent() != null:
			_spawn_boss_escort()

	match stage_idx:
		0: # STAGE 1: NEMESIS DREADNOUGHT WALL
			if _boss_pattern == 0:
				var gap_idx: int = 2 + ((_boss_substep * 2 + int(_age)) % 5)
				for slot: int in range(9):
					if slot == gap_idx or slot == gap_idx + 1:
						continue
					var wy: float = 36.0 + float(slot) * 24.0
					_shoot_from(Vector2(global_position.x - 42.0, wy), Vector2(-(134.0 + spd_bonus), 0.0), _bullet_b)
				_fire_timer = 1.00 * rate_mult
			elif _boss_pattern == 1:
				var ang_off: float = sin(float(_boss_substep) * 0.9) * 0.24
				var b_spd: float = 150.0 + spd_bonus
				_shoot_from(global_position + Vector2(-50.0, -50.0), Vector2(-b_spd, 38.0).rotated(ang_off), _bullet_b)
				_shoot_from(global_position + Vector2(-50.0, -50.0), Vector2(-b_spd, 0.0).rotated(ang_off), _bullet_b)
				_shoot_from(global_position + Vector2(-50.0, 50.0), Vector2(-b_spd, -38.0).rotated(-ang_off), _bullet_b)
				_shoot_from(global_position + Vector2(-50.0, 50.0), Vector2(-b_spd, 0.0).rotated(-ang_off), _bullet_b)
				if boss_phase >= 3:
					_shoot_aimed_from(global_position + Vector2(-36.0, 0.0), b_spd + 15.0, _bullet_a, 0.0)
				_fire_timer = 0.66 * rate_mult
			else:
				_shoot_ring(7 + boss_phase * 2, 136.0 + spd_bonus, _bullet_a, _boss_spin)
				_boss_spin += 0.28
				_fire_timer = 0.82 * rate_mult

		1: # STAGE 2: MECHA SCORPION
			if _boss_pattern == 0:
				var stinger_pos: Vector2 = global_position + Vector2(-38.0, -52.0)
				for k: int in range(4 + boss_phase):
					var vel: Vector2 = Vector2(-(158.0 + spd_bonus), 18.0 + float(k) * 20.0)
					_shoot_from(stinger_pos, vel, _bullet_a)
				_fire_timer = 0.88 * rate_mult
			elif _boss_pattern == 1:
				_shoot_from_spread(global_position + Vector2(-46.0, -16.0), 2 + boss_phase, 0.19, 148.0 + spd_bonus, _bullet_b)
				_shoot_from_spread(global_position + Vector2(-46.0, 38.0), 2 + boss_phase, 0.19, 148.0 + spd_bonus, _bullet_b)
				_fire_timer = 0.92 * rate_mult
			else:
				_shoot_aimed_from(global_position + Vector2(-38.0, -52.0), 178.0 + spd_bonus, _bullet_a, -0.10)
				_shoot_aimed_from(global_position + Vector2(-38.0, -52.0), 182.0 + spd_bonus, _bullet_a, 0.0)
				_shoot_aimed_from(global_position + Vector2(-38.0, -52.0), 178.0 + spd_bonus, _bullet_a, 0.10)
				_fire_timer = 0.72 * rate_mult

		2: # STAGE 3: SKY WYVERN
			if _boss_pattern == 0:
				_shoot_spread(4 + boss_phase * 2, 0.16, 158.0 + spd_bonus, _bullet_a)
				_fire_timer = 0.84 * rate_mult
			elif _boss_pattern == 1:
				var maw: Vector2 = global_position + Vector2(-38.0, -4.0)
				for k: int in range(-boss_phase, boss_phase + 1):
					_shoot_aimed_from(maw, 174.0 + spd_bonus, _bullet_b, float(k) * 0.11)
				_fire_timer = 0.80 * rate_mult
			else:
				_shoot_ring(8 + boss_phase * 2, 146.0 + spd_bonus, _bullet_a, _boss_spin)
				_boss_spin += 0.25
				_fire_timer = 0.78 * rate_mult

		3: # STAGE 4: EMPEROR STAG-MANTIS BUG
			if _boss_pattern == 0:
				var s_off: float = sin(_age * 4.5) * 42.0
				_shoot_from(global_position + Vector2(-34.0, s_off), Vector2(-(150.0 + spd_bonus), 20.0), _bullet_a)
				_shoot_from(global_position + Vector2(-34.0, -s_off), Vector2(-(150.0 + spd_bonus), -20.0), _bullet_b)
				if boss_phase >= 2:
					_shoot_from(global_position + Vector2(-34.0, 0.0), Vector2(-(160.0 + spd_bonus), sin(_age * 6.0) * 35.0), _bullet_a)
				_fire_timer = 0.42 * rate_mult
			else:
				_shoot_from_spread(global_position + Vector2(-42.0, -34.0), 3 + boss_phase, 0.17, 156.0 + spd_bonus, _bullet_a)
				_shoot_from_spread(global_position + Vector2(-42.0, 34.0), 3 + boss_phase, 0.17, 156.0 + spd_bonus, _bullet_b)
				_fire_timer = 0.86 * rate_mult

		4: # STAGE 5: FROST SERAPH TITAN
			_shoot_ring(8 + boss_phase * 2, 142.0 + spd_bonus, _bullet_a if _boss_substep % 2 == 0 else _bullet_b, _boss_spin)
			if boss_phase >= 2 and _boss_substep % 2 == 0:
				_shoot_aimed(176.0 + spd_bonus, _bullet_b, 0.0)
			_boss_spin += 0.21
			_fire_timer = 0.76 * rate_mult

		5: # STAGE 6: INFERNO SKULL BALROG
			if _boss_pattern == 0:
				_shoot_from_spread(global_position + Vector2(-32.0, 14.0), 5 + boss_phase * 2, 0.18, 155.0 + spd_bonus, _bullet_a)
				_fire_timer = 0.86 * rate_mult
			else:
				for k: int in range(-boss_phase, boss_phase + 1):
					_shoot_aimed_from(global_position + Vector2(-20.0, -16.0), 178.0 + spd_bonus, _bullet_b, float(k) * 0.09)
				_fire_timer = 0.74 * rate_mult

		6: # STAGE 7: ABYSSAL KRAKEN
			for arm: int in range(4 + boss_phase):
				var ang: float = PI + sin(_age * 3.0 + float(arm) * 0.5) * 0.58 + float(arm - 2) * 0.19
				_shoot_from(global_position + Vector2(-40.0, float(arm - 2) * 20.0), Vector2.from_angle(ang) * (146.0 + spd_bonus), _bullet_a)
			_fire_timer = 0.68 * rate_mult

		_: # STAGE 8: NEON MEDUSA OVERMIND
			if _boss_pattern == 0:
				var safe_lane: int = (_boss_substep * 2 + 1) % 6
				for lane: int in range(8):
					if lane == safe_lane or lane == safe_lane + 1:
						continue
					var ly: float = 36.0 + float(lane) * 26.0
					_shoot_from(Vector2(global_position.x - 36.0, ly), Vector2(-(172.0 + spd_bonus), 0.0), _bullet_a)
				_fire_timer = 0.80 * rate_mult
			else:
				_shoot_ring(10 + boss_phase * 2, 154.0 + spd_bonus, _bullet_b, _boss_spin)
				_boss_spin -= 0.25
				_fire_timer = 0.72 * rate_mult


func _spawn_boss_escort() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= 5:
		return
	for offset_y: float in [-62.0, 62.0]:
		var esc: GameEnemy = GameEnemy.new()
		get_parent().add_child(esc)
		var esc_hp_scale: float = pow(1.32, float(stage_idx))
		esc.setup(
			Type.SWOOPER,
			Vector2(492.0, clampf(global_position.y + offset_y, 38.0, 226.0)),
			esc_hp_scale,
			player_ref,
			bullet_container,
			fx,
			offset_y,
			-1,
			stage_idx
		)


func _shoot_ring(count: int, speed: float, tex_key: String, rot_offset: float) -> void:
	for i: int in range(count):
		var ang: float = rot_offset + (TAU * float(i) / float(count))
		var vel: Vector2 = Vector2.from_angle(ang) * speed
		if vel.x < 35.0:
			_shoot_from(global_position + Vector2(-24.0, 0.0), vel, tex_key)


func _shoot_aimed(speed: float, tex_key: String, angle_offset: float = 0.0) -> void:
	_shoot_aimed_from(global_position + Vector2(-8.0, 0.0), speed, tex_key, angle_offset)


func _shoot_aimed_from(origin: Vector2, speed: float, tex_key: String, angle_offset: float = 0.0) -> void:
	if bullet_container == null:
		return
	var dir: Vector2 = Vector2.LEFT
	if player_ref != null and is_instance_valid(player_ref) and player_ref.visible:
		dir = (player_ref.global_position - origin).normalized()
	dir = dir.rotated(angle_offset)
	_shoot_from(origin, dir * speed, tex_key)


func _shoot_spread(count: int, step_angle: float, speed: float, tex_key: String) -> void:
	_shoot_from_spread(global_position + Vector2(-10.0, 0.0), count, step_angle, speed, tex_key)


func _shoot_from_spread(origin: Vector2, count: int, step_angle: float, speed: float, tex_key: String) -> void:
	var half: float = float(count - 1) * 0.5
	for i: int in range(count):
		var ang: float = (float(i) - half) * step_angle
		var vel: Vector2 = Vector2(-speed, 0.0).rotated(ang)
		_shoot_from(origin, vel, tex_key)


func _shoot_from(pos: Vector2, vel: Vector2, tex_key: String) -> void:
	if bullet_container == null:
		return
	var b: GameBullet = GameBullet.new()
	bullet_container.add_child(b)
	b.setup(pos, vel, 1.0, false, tex_key, 0, false, 2.5, fx)


func take_contact_damage(dmg: float) -> void:
	if enemy_type != Type.BOSS:
		take_damage(dmg)


func take_damage(dmg: float) -> void:
	if _dead or _boss_dying:
		return

	if enemy_type == Type.BOSS:
		if boss_intro_active or boss_shield_timer > 0.0:
			return
		# Smooth Adaptive Boss Plating: caps ultra-high stacked multi-ray burst so bosses never melt in 2 seconds!
		var cap_window: float = max_hp * 0.095
		var effective_dmg: float = dmg
		if _dps_accumulator > cap_window:
			effective_dmg = dmg * 0.18
		elif _dps_accumulator > cap_window * 0.6:
			effective_dmg = dmg * 0.45
		_dps_accumulator += effective_dmg
		hp = maxf(0.0, hp - effective_dmg)

		# Check 3-Phase Thresholds (66% -> Phase 2, 33% -> Phase 3)!
		var ratio: float = hp / max_hp
		if boss_phase == 1 and ratio <= 0.66 and hp > 0.0:
			_enter_next_boss_phase(2)
			return
		elif boss_phase == 2 and ratio <= 0.33 and hp > 0.0:
			_enter_next_boss_phase(3)
			return
	else:
		hp -= dmg

	_flash_timer = 0.055
	_mat.set_shader_parameter("flash", 1.0)
	if hp <= 0.0:
		if enemy_type == Type.BOSS:
			_start_boss_death_sequence()
		else:
			_die()
	else:
		RetroSfx.play("hit", -14.0, 0.08)


func _enter_next_boss_phase(new_phase: int) -> void:
	boss_phase = new_phase
	boss_shield_timer = 0.95 # Brief phase-transition energy shield!
	_dps_accumulator = 0.0
	_fire_timer = 0.45
	_boss_attack_anim_timer = 0.95
	_sprite.scale = Vector2(1.14, 0.88)
	RetroSfx.play("explode", -5.0, 0.04)
	if fx != null:
		fx.spawn_explosion(global_position + Vector2(-20.0, 0.0), true)
		fx.add_shake(6.5)
		fx.spawn_popup(
			global_position + Vector2(-58.0, -40.0),
			"PHASE 2: OVERDRIVE!" if new_phase == 2 else "PHASE 3: BERSERK!",
			Color("#ffe854") if new_phase == 2 else Color("#ff4c68")
		)
	boss_phase_broken.emit(self, 18 + stage_idx * 4)


func _start_boss_death_sequence() -> void:
	_boss_dying = true
	_boss_death_timer = 1.15
	_boss_death_boom_timer = 0.02
	hp = 0.0
	collision_layer = 0
	monitorable = false
	_sprite.rotation = 0.0
	_sprite.scale = Vector2(1.08, 1.08)
	# Cancel all active enemy bullets on screen as an immediate boss-kill reward!
	if bullet_container != null:
		for child: Node in bullet_container.get_children():
			if child is GameBullet:
				var gb: GameBullet = child as GameBullet
				if not gb.is_player_bullet:
					if fx != null:
						fx.spawn_hit_sparks(gb.global_position, Color("#ff4c68"), 3)
					gb.queue_free()


func _finish_boss_death() -> void:
	_dead = true
	if fx != null:
		fx.spawn_explosion(global_position, true)
		for k: int in range(7):
			fx.spawn_explosion(global_position + Vector2(randf_range(-36.0, 26.0), randf_range(-58.0, 58.0)), true)
		fx.add_shake(13.0)
	RetroSfx.play("big_explode", -3.5, 0.05)
	destroyed.emit(self, true)
	queue_free()


func _die() -> void:
	_dead = true
	var is_big: bool = (enemy_type == Type.CRUISER or enemy_type == Type.BOSS)
	if fx != null:
		fx.spawn_explosion(global_position, is_big)
		if enemy_type == Type.CRUISER:
			fx.add_shake(4.0)
	RetroSfx.play("big_explode" if is_big else "explode", -4.0 if is_big else -8.5, 0.07)
	destroyed.emit(self, true)
	queue_free()


func _draw() -> void:
	if enemy_type == Type.CRUISER and hp < max_hp:
		var ratio: float = clampf(hp / max_hp, 0.0, 1.0)
		draw_rect(Rect2(-12.0, -14.0, 24.0, 3.0), Color("#14182e"))
		draw_rect(Rect2(-12.0, -14.0, 24.0 * ratio, 3.0), Color("#ff4c5e"))
	elif enemy_type == Type.BOSS:
		if boss_intro_active:
			if _boss_intro_stage == 0:
				# Mega Man vertical cyan-white teleport arrival beam!
				draw_rect(Rect2(-12.0, -220.0, 24.0, 300.0), Color(0.16, 0.91, 1.0, 0.38))
				draw_rect(Rect2(-4.0, -220.0, 8.0, 300.0), Color(1.0, 1.0, 1.0, 0.92))
			elif _boss_intro_stage == 1:
				# Expanding signature pose shockwave ring!
				var pt: float = clampf(_boss_intro_timer / 0.68, 0.0, 1.0)
				draw_arc(Vector2(-10.0, 0.0), lerpf(16.0, 76.0, pt), 0.0, TAU, 32, Color(1.0, 0.91, 0.33, 1.0 - pt), 2.0)
		elif boss_shield_timer > 0.0:
			# Glowing cyan phase-shift energy barrier around the boss!
			draw_arc(Vector2(-8.0, 0.0), 58.0, 0.0, TAU, 32, Color(0.16, 0.91, 1.0, 0.65), 2.0)
		elif not _boss_dying and _fire_timer > 0.0 and _fire_timer < 0.22:
			# Pre-attack weapon charge glint right before firing a volley!
			var ct: float = 1.0 - (_fire_timer / 0.22)
			var r_glint: float = lerpf(3.0, 8.5, ct)
			draw_circle(Vector2(-36.0, 0.0), r_glint, Color(1.0, 0.16, 0.28, 0.55))
			draw_circle(Vector2(-36.0, 0.0), r_glint * 0.48, Color(1.0, 0.95, 0.75, 0.92))
