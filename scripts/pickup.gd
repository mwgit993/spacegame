class_name GamePickup
extends Node2D

enum Kind { XP, HEAL }

var kind: Kind = Kind.XP
var value: int = 1
var player_ref: Node2D = null
var velocity: Vector2 = Vector2(-34.0, 0.0)
var force_vacuum: bool = false
var _bob_phase: float = 0.0
var _sprite: Sprite2D

signal collected(kind_val: int, amount: int, pos: Vector2)


func setup(pos: Vector2, pickup_kind: Kind, amount: int, target_player: Node2D) -> void:
	global_position = pos
	kind = pickup_kind
	value = amount
	player_ref = target_player
	_bob_phase = randf_range(0.0, TAU)
	velocity = Vector2(randf_range(-46.0, 18.0), randf_range(-34.0, 34.0))

	_sprite = Sprite2D.new()
	if kind == Kind.HEAL:
		_sprite.texture = PixelArt.tex("pickup_heal")
	else:
		var xp_tex: String = "pickup_xp_big" if amount >= 7 else ("pickup_xp_med" if amount >= 4 else "pickup_xp_small")
		_sprite.texture = PixelArt.tex(xp_tex)
	add_child(_sprite)


func _process(delta: float) -> void:
	_bob_phase += delta * 7.0
	if _sprite != null and kind == Kind.XP:
		var pulse: float = 0.92 + 0.12 * sin(_bob_phase * 1.4)
		_sprite.scale = Vector2(pulse, pulse)

	if player_ref != null and is_instance_valid(player_ref) and player_ref.visible:
		var to_player: Vector2 = player_ref.global_position - global_position
		var dist: float = to_player.length()
		var mag_radius: float = MetaSave.get_magnet_radius()
		if dist < 13.0:
			collected.emit(int(kind), value, global_position)
			queue_free()
			return
		elif force_vacuum:
			velocity = to_player.normalized() * 480.0
			global_position += velocity * delta
			return
		elif dist < mag_radius:
			var pull_strength: float = lerpf(165.0, 390.0, 1.0 - (dist / mag_radius))
			velocity = to_player.normalized() * pull_strength
			global_position += velocity * delta
			return

	velocity.y = lerpf(velocity.y, sin(_bob_phase) * 14.0, 4.5 * delta)
	velocity.x = lerpf(velocity.x, -30.0, 3.0 * delta)
	global_position += velocity * delta
	if not force_vacuum and global_position.x < -22.0:
		queue_free()
