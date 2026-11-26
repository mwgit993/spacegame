class_name GameBullet
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 1.0
var is_player_bullet: bool = true
var pierce_left: int = 0
var is_homing: bool = false
var homing_turn_rate: float = 5.5
var fx: FxLayer = null

# Special beam, exotic ship & addon projectile modifiers!
var wave_amp: float = 0.0
var wave_freq: float = 18.0
var wave_sign: float = 1.0
var bounces_left: int = 0
var chain_count: int = 0
var aoe_radius: float = 0.0
var aoe_color: Color = Color("#ff7828")
var explode_on_floor: bool = false
var gravity_pull: float = 0.0
var anim_tex_a: String = ""
var anim_tex_b: String = ""
var keep_upright: bool = false
var is_cat_shot: bool = false
var is_crit: bool = false

var _glow_sprite: Sprite2D = null
var _sprite: Sprite2D
var _shape_circle: CircleShape2D
var _hit_ids: Dictionary = {}
var _trail_timer: float = 0.0
var _glow_timer: float = 0.0
var _anim_timer: float = 0.0
var _wave_base_pos: Vector2 = Vector2.ZERO
var _wave_time: float = 0.0


func setup(
	pos: Vector2,
	vel: Vector2,
	dmg: float,
	player_owned: bool,
	tex_key: String,
	pierce: int = 0,
	homing: bool = false,
	hit_radius: float = 3.0,
	fx_ref: FxLayer = null
) -> void:
	global_position = pos
	_wave_base_pos = pos
	velocity = vel
	damage = dmg
	is_player_bullet = player_owned
	pierce_left = pierce
	is_homing = homing
	fx = fx_ref
	anim_tex_a = tex_key

	collision_layer = 2 if is_player_bullet else 8
	collision_mask = 4 if is_player_bullet else 1
	monitoring = true
	monitorable = true

	if not is_player_bullet:
		# Render enemy bullets above player shots, pickups, and explosions with a red danger aura!
		z_index = 6
		_glow_timer = randf_range(0.0, TAU)
		_glow_sprite = Sprite2D.new()
		_glow_sprite.texture = PixelArt.tex("bullet_enemy_glow_0")
		add_child(_glow_sprite)

	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.tex(tex_key)
	add_child(_sprite)
	if is_player_bullet:
		rotation = velocity.angle()

	var shape_node: CollisionShape2D = CollisionShape2D.new()
	_shape_circle = CircleShape2D.new()
	_shape_circle.radius = hit_radius
	shape_node.shape = _shape_circle
	add_child(shape_node)

	area_entered.connect(_on_area_entered)


func apply_size_and_crit(size_mult: float, crit: bool) -> void:
	is_crit = crit
	var total_scale: float = size_mult * (1.22 if crit else 1.0)
	if _sprite != null and total_scale != 1.0:
		_sprite.scale = Vector2(total_scale, total_scale)
	if _sprite != null and crit:
		_sprite.modulate = Color(1.0, 0.96, 0.65)
	if _shape_circle != null and size_mult > 1.0:
		_shape_circle.radius *= size_mult


func _update_visual_orientation() -> void:
	if keep_upright and _sprite != null:
		rotation = 0.0
		_sprite.flip_h = velocity.x < 0.0
		_sprite.rotation = clampf(velocity.y * 0.0022, -0.35, 0.35) * (-1.0 if velocity.x < 0.0 else 1.0)
	else:
		rotation = velocity.angle()


func _process(delta: float) -> void:
	if gravity_pull > 0.0:
		velocity.y += gravity_pull * delta
		_update_visual_orientation()

	if anim_tex_b != "" and _sprite != null:
		_anim_timer += delta
		var alt_f: bool = (int(_anim_timer * 12.0) % 2) == 1
		_sprite.texture = PixelArt.tex(anim_tex_b if alt_f else anim_tex_a)
		if is_cat_shot and fx != null:
			_trail_timer -= delta
			if _trail_timer <= 0.0:
				_trail_timer = 0.055
				fx.spawn_hit_sparks(global_position - velocity.normalized() * 6.0, Color("#ff64b8"), 1)

	if is_homing and is_player_bullet:
		var target: Node2D = _find_nearest_enemy(null)
		if target != null:
			var desired: Vector2 = (target.global_position - global_position).normalized()
			var speed: float = velocity.length()
			var cur_dir: Vector2 = velocity.normalized()
			var new_dir: Vector2 = cur_dir.lerp(desired, clampf(homing_turn_rate * delta, 0.0, 1.0)).normalized()
			velocity = new_dir * minf(speed + 140.0 * delta, 315.0)
			_update_visual_orientation()
		if not is_cat_shot:
			_trail_timer -= delta
			if _trail_timer <= 0.0 and fx != null:
				_trail_timer = 0.035
				fx.spawn_hit_sparks(global_position - velocity.normalized() * 5.0, Color("#ff8833"), 1)
	elif not is_player_bullet and _glow_sprite != null:
		_glow_timer += delta
		var expand: bool = (int(_glow_timer * 11.0) % 2) == 1
		_glow_sprite.texture = PixelArt.tex("bullet_enemy_glow_1" if expand else "bullet_enemy_glow_0")
		_glow_sprite.modulate.a = 0.82 + 0.18 * sin(_glow_timer * 14.0)

	if is_player_bullet and wave_amp > 0.0:
		_wave_time += delta
		_wave_base_pos += velocity * delta
		var perp: Vector2 = velocity.normalized().orthogonal()
		global_position = _wave_base_pos + perp * (sin(_wave_time * wave_freq) * wave_amp * wave_sign)
		if keep_upright:
			_update_visual_orientation()
		else:
			rotation = velocity.angle() + cos(_wave_time * wave_freq) * 0.28 * wave_sign
	else:
		global_position += velocity * delta
		if is_player_bullet and keep_upright:
			_update_visual_orientation()

	# BALL x PIT-style Ricochet wall/floor/ceiling bouncing (Prism, Saucer Rings & Flying Cats!)
	if is_player_bullet and bounces_left > 0:
		var bounced_wall: bool = false
		if global_position.y <= 27.0 and velocity.y < 0.0:
			global_position.y = 27.0
			velocity.y = absf(velocity.y)
			bounced_wall = true
		elif global_position.y >= 254.0 and velocity.y > 0.0:
			global_position.y = 254.0
			velocity.y = -absf(velocity.y)
			bounced_wall = true
		if global_position.x >= 474.0 and velocity.x > 0.0:
			global_position.x = 474.0
			velocity.x = -absf(velocity.x)
			if absf(velocity.y) < 45.0:
				velocity.y = -110.0 if randf() < 0.5 else 110.0
			bounced_wall = true
		elif global_position.x <= 8.0 and velocity.x < 0.0:
			global_position.x = 8.0
			velocity.x = absf(velocity.x)
			bounced_wall = true
		if bounced_wall:
			bounces_left -= 1
			_wave_base_pos = global_position
			_hit_ids.clear()
			_update_visual_orientation()
			if fx != null:
				fx.spawn_hit_sparks(global_position, Color("#ff64b8") if is_cat_shot else Color("#ff4cd4"), 3)
			RetroSfx.play("bounce", -15.0, 0.08)

	# Gravity Bomb floor detonation!
	if is_player_bullet and explode_on_floor and global_position.y >= 254.0:
		_trigger_aoe_detonation(null)
		queue_free()
		return

	if global_position.x < -28.0 or global_position.x > 512.0 or global_position.y < 10.0 or global_position.y > 282.0:
		queue_free()


func _find_nearest_enemy(exclude_node: Node) -> Node2D:
	var best: Node2D = null
	var best_dist: float = 999999.0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == exclude_node:
			continue
		if node is Node2D and is_instance_valid(node):
			var enemy_node: Node2D = node as Node2D
			if enemy_node.global_position.x > 8.0 and enemy_node.global_position.x < 476.0:
				var d: float = global_position.distance_squared_to(enemy_node.global_position)
				if d < best_dist:
					best_dist = d
					best = enemy_node
	return best


func _on_area_entered(area: Area2D) -> void:
	if is_player_bullet:
		if area.has_method("take_damage"):
			var id: int = area.get_instance_id()
			if _hit_ids.has(id):
				return
			_hit_ids[id] = true
			area.call("take_damage", damage)

			if aoe_radius > 0.0:
				_trigger_aoe_detonation(area)
			if chain_count > 0:
				_trigger_tesla_chain(area)

			if fx != null:
				var spark_col: Color = Color("#ffe854")
				if is_cat_shot:
					spark_col = Color("#ff64b8")
				elif bounces_left > 0:
					spark_col = Color("#ff4cd4")
				elif pierce_left > 0:
					spark_col = Color("#28e8ff")
				fx.spawn_hit_sparks(global_position, spark_col, 6 if is_crit else 4)

			if bounces_left > 0:
				bounces_left -= 1
				var spd: float = maxf(255.0, velocity.length())
				var next_target: Node2D = _find_nearest_enemy(area)
				if next_target != null and global_position.distance_to(next_target.global_position) < 220.0:
					velocity = (next_target.global_position - global_position).normalized() * spd
				else:
					var bounce_y: float = -165.0 if (global_position.y > 134.0) else 165.0
					velocity = Vector2(-absf(velocity.x) * 0.72, bounce_y).normalized() * spd
				_wave_base_pos = global_position
				_update_visual_orientation()
				RetroSfx.play("meow" if is_cat_shot else "bounce", -15.5 if is_cat_shot else -14.0, 0.09)
			elif pierce_left > 0:
				pierce_left -= 1
			else:
				queue_free()
	else:
		if area.has_method("take_player_hit"):
			area.call("take_player_hit")
			queue_free()


func _trigger_aoe_detonation(direct_hit: Node) -> void:
	if fx != null:
		fx.spawn_ring_blast(global_position, aoe_radius, aoe_color)
	var r2: float = aoe_radius * aoe_radius
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == direct_hit or not (node is Node2D) or not is_instance_valid(node):
			continue
		var en: Node2D = node as Node2D
		if global_position.distance_squared_to(en.global_position) <= r2 and en.has_method("take_damage"):
			en.call("take_damage", damage * 0.65)


func _trigger_tesla_chain(origin_enemy: Node) -> void:
	var candidates: Array[Node2D] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == origin_enemy or not (node is Node2D) or not is_instance_valid(node):
			continue
		var en: Node2D = node as Node2D
		if global_position.distance_to(en.global_position) <= 125.0 and en.has_method("take_damage"):
			candidates.append(en)
	var hits: int = mini(chain_count, candidates.size())
	var from_pt: Vector2 = global_position
	for i: int in range(hits):
		var target_en: Node2D = candidates[i]
		target_en.call("take_damage", damage * 0.62)
		if fx != null:
			fx.spawn_lightning(from_pt, target_en.global_position, Color("#b86bff"))
			fx.spawn_hit_sparks(target_en.global_position, Color("#28e8ff"), 3)
		from_pt = target_en.global_position
	if hits > 0:
		RetroSfx.play("zap", -14.5, 0.08)
