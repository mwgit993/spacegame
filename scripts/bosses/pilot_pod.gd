extends Node2D

# The dino pilot bailing out of an exploding boss: the pod rockets up out of the wreck and brakes
# to a hover while the dino shakes its fist at the player, then it turns to face right, its warp
# drive spins up and it streaks away off the right of the screen (Matthew's request). Lives in the
# FX layer (so it outlives the boss) and frees itself once it's gone.

const Kit = preload("res://scripts/bosses/boss_kit.gd")
const LIFE: float = 4.0
const HOVER_AT: float = 0.45   # the rocket burn ends
const CHARGE_AT: float = 1.3   # turns right, the warp drive spins up
const WARP_AT: float = 1.75    # and it's off
const WARP_SPEED: float = 1100.0
const WARP_COL: Color = Color("#7ce8ff")

var _t: float = 0.0
var _vel: Vector2 = Vector2(-60.0, -150.0)
var _pod: Node2D
var _arm: Sprite2D
var _flame: Sprite2D
var _fx: Node = null
var _warped: bool = false
var _trail: float = 0.0        # length of the warp streak behind the pod


# face: the pilot's angry face (DinoPilot.face_texture).
func setup(face_tex: Texture2D, fx: Node) -> void:
	_fx = fx
	_pod = Node2D.new()
	add_child(_pod)
	_arm = Sprite2D.new()
	_arm.texture = Kit.cached("pod_fist", _paint_fist)
	_arm.centered = false
	_arm.offset = Vector2(-2.0, -9.0)
	_arm.position = Vector2(3.0, -4.0)
	_pod.add_child(_arm)
	var face: Sprite2D = Sprite2D.new()
	face.texture = face_tex
	face.position = Vector2(0.0, -9.0)
	_pod.add_child(face)
	var body: Sprite2D = Sprite2D.new()
	body.texture = Kit.cached("pod_body", _paint_pod)
	body.position = Vector2(0.0, 2.0)
	_pod.add_child(body)
	_flame = Sprite2D.new()
	_flame.texture = Kit.cached("pod_flame", _paint_flame)
	_flame.position = Vector2(0.0, 13.0)
	_pod.add_child(_flame)
	if _fx != null and _fx.has_method("spawn_popup"):
		_fx.call("spawn_popup", global_position + Vector2(-20.0, -26.0), "GRRR!!", Color("#ff4c68"))


func _process(delta: float) -> void:
	_t += delta
	if _t < HOVER_AT:
		_vel.y += 140.0 * delta
		_flame.visible = int(_t * 30.0) % 3 != 0
		_flame.scale = Vector2(1.0, randf_range(0.8, 1.3))
		if _fx != null and _fx.has_method("spawn_hit_sparks") and int(_t * 40.0) % 4 == 0:
			_fx.call("spawn_hit_sparks", global_position + Vector2(0.0, 14.0), Color("#ffb04c"), 1)
	elif _t < CHARGE_AT:
		# Brake to a hover and shake a fist at the player.
		_vel = _vel.lerp(Vector2(0.0, sin(_t * 5.0) * 10.0), clampf(6.0 * delta, 0.0, 1.0))
		_flame.visible = int(_t * 20.0) % 2 == 0
		_flame.scale = Vector2(0.7, 0.5)
		rotation = sin(_t * 3.4) * 0.12
		_arm.rotation = -0.6 + sin(_t * 26.0) * 0.45
	elif _t < WARP_AT:
		# Turn to face right; the warp drive spins up with a shiver.
		_vel = Vector2.ZERO
		rotation = 0.0
		_pod.scale = Vector2(-1.0, 1.0)
		_arm.rotation = -0.2
		_flame.visible = false
		_pod.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).round()
	else:
		if not _warped:
			_warped = true
			_pod.position = Vector2.ZERO
			_vel = Vector2(360.0, 0.0)
			RetroSfx.play("warp", -6.0, 0.04)
			if _fx != null and _fx.has_method("spawn_ring_blast"):
				_fx.call("spawn_ring_blast", global_position, 26.0, WARP_COL)
		var k: float = _t - WARP_AT
		_vel.x = move_toward(_vel.x, WARP_SPEED, 2600.0 * delta)
		_pod.scale = Vector2(-(1.0 + minf(k * 6.0, 1.6)), maxf(0.45, 1.0 - k * 3.0))
		_trail = minf(_trail + _vel.x * delta, 160.0)
	global_position += _vel * delta
	queue_redraw()
	if _t > LIFE or global_position.x > 540.0 or global_position.x < -40.0 or global_position.y > 300.0:
		queue_free()


func _draw() -> void:
	if _t >= CHARGE_AT and _t < WARP_AT:
		# The drive charging: sparks of light rushing in.
		var k: float = (_t - CHARGE_AT) / (WARP_AT - CHARGE_AT)
		var r: float = lerpf(26.0, 6.0, k)
		for i: int in range(8):
			var a: float = float(i) * TAU / 8.0 + _t * 6.0
			var p: Vector2 = Vector2.from_angle(a) * r
			draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(WARP_COL, 0.4 + 0.6 * k))
		draw_circle(Vector2(-12.0, 2.0), 2.0 + 3.0 * k, Color(1, 1, 1, 0.5 + 0.5 * k))
	elif _warped:
		# The streak it leaves behind.
		draw_rect(Rect2(-_trail, -3.0, _trail, 6.0), Color(WARP_COL, 0.35))
		draw_rect(Rect2(-_trail * 0.8, -1.0, _trail * 0.8, 2.0), Color(1, 1, 1, 0.8))


static func _paint_pod() -> Image:
	var img: Image = Kit.blank(24, 16)
	Kit.ball(img, 12.0, 8.0, 11.5, 7.5, Color("#b8c6e0"))
	Kit.rect(img, 1, 6, 22, 3, Color("#e8344a"))
	Kit.rect(img, 1, 6, 22, 1, Color("#ff7a8a"))
	Kit.glow(img, 5.0, 11.0, 1.6, Color("#ff9624"), Color("#ffe854"), Color.WHITE)
	Kit.glow(img, 19.0, 11.0, 1.6, Color("#ff9624"), Color("#ffe854"), Color.WHITE)
	return Kit.finish(img)


static func _paint_fist() -> Image:
	var img: Image = Kit.blank(5, 10)
	Kit.rect(img, 1, 3, 2, 7, Color("#9fb0c8"))
	Kit.ellipse(img, 2.0, 2.0, 2.2, 2.2, Color("#e8d27a"))
	return Kit.outline(img)


static func _paint_flame() -> Image:
	var img: Image = Kit.blank(8, 12)
	Kit.poly(img, PackedVector2Array([Vector2(0, 0), Vector2(8, 0), Vector2(4, 12)]), Color("#ff6820"))
	Kit.poly(img, PackedVector2Array([Vector2(2, 0), Vector2(6, 0), Vector2(4, 7)]), Color("#ffe854"))
	return img
