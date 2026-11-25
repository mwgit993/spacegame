class_name GameBullet
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 1.0
var is_player_bullet: bool = true
var pierce_left: int = 0
var is_homing: bool = false
var homing_turn_rate: float = 5.5
var fx: FxLayer = null

var _sprite: Sprite2D
var _hit_ids: Dictionary = {}
var _trail_timer: float = 0.0


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
	velocity = vel
	damage = dmg
	is_player_bullet = player_owned
	pierce_left = pierce
	is_homing = homing
	fx = fx_ref

	collision_layer = 2 if is_player_bullet else 8
	collision_mask = 4 if is_player_bullet else 1
	monitoring = true
	monitorable = true

	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.tex(tex_key)
	add_child(_sprite)
	if is_player_bullet:
		rotation = velocity.angle()

	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = hit_radius
	shape_node.shape = circle
	add_child(shape_node)

	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if is_homing and is_player_bullet:
		var target: Node2D = _find_nearest_enemy()
		if target != null:
			var desired: Vector2 = (target.global_position - global_position).normalized()
			var speed: float = velocity.length()
			var cur_dir: Vector2 = velocity.normalized()
			var new_dir: Vector2 = cur_dir.lerp(desired, clampf(homing_turn_rate * delta, 0.0, 1.0)).normalized()
			velocity = new_dir * minf(speed + 140.0 * delta, 290.0)
			rotation = velocity.angle()
		_trail_timer -= delta
		if _trail_timer <= 0.0 and fx != null:
			_trail_timer = 0.035
			fx.spawn_hit_sparks(global_position - velocity.normalized() * 5.0, Color("#ff8833"), 1)

	global_position += velocity * delta

	if global_position.x < -24.0 or global_position.x > 508.0 or global_position.y < 12.0 or global_position.y > 274.0:
		queue_free()


func _find_nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_dist: float = 999999.0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
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
			if fx != null:
				var spark_col: Color = Color("#28e8ff") if pierce_left > 0 else Color("#ffe854")
				fx.spawn_hit_sparks(global_position, spark_col, 4)
			if pierce_left > 0:
				pierce_left -= 1
			else:
				queue_free()
	else:
		if area.has_method("take_player_hit"):
			area.call("take_player_hit")
			queue_free()
