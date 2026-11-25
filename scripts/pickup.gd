class_name GamePickup
extends Node2D

enum Kind { SCRAP, HEAL }

var kind: Kind = Kind.SCRAP
var value: int = 1
var player_ref: Node2D = null
var velocity: Vector2 = Vector2(-36.0, 0.0)
var _bob_phase: float = 0.0
var _sprite: Sprite2D

signal collected(kind_val: int, amount: int, pos: Vector2)


func setup(pos: Vector2, pickup_kind: Kind, amount: int, target_player: Node2D) -> void:
	global_position = pos
	kind = pickup_kind
	value = amount
	player_ref = target_player
	_bob_phase = randf_range(0.0, TAU)
	velocity = Vector2(randf_range(-44.0, -26.0), randf_range(-24.0, 24.0))

	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.tex("pickup_scrap" if kind == Kind.SCRAP else "pickup_heal")
	add_child(_sprite)


func _process(delta: float) -> void:
	_bob_phase += delta * 6.0
	velocity.y = lerpf(velocity.y, sin(_bob_phase) * 14.0, 4.0 * delta)
	velocity.x = lerpf(velocity.x, -34.0, 2.5 * delta)

	if player_ref != null and is_instance_valid(player_ref) and player_ref.visible:
		var to_player: Vector2 = player_ref.global_position - global_position
		var dist: float = to_player.length()
		var mag_radius: float = MetaSave.get_magnet_radius()
		if dist < 12.0:
			collected.emit(int(kind), value, global_position)
			queue_free()
			return
		elif dist < mag_radius:
			var pull_strength: float = lerpf(150.0, 360.0, 1.0 - (dist / mag_radius))
			velocity = to_player.normalized() * pull_strength

	global_position += velocity * delta
	if global_position.x < -20.0:
		queue_free()
