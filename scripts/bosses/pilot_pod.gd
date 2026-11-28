extends Node2D

# The dino pilot bailing out of an exploding boss: the pod rockets up out of the wreck, pops a
# striped parachute and drifts off left while the dino shakes its fist at the player. Lives in the
# FX layer (so it outlives the boss) and frees itself after a few seconds or once off screen.

const Kit = preload("res://scripts/bosses/boss_kit.gd")
const LIFE: float = 4.2
const CHUTE_AT: float = 0.5

var _t: float = 0.0
var _vel: Vector2 = Vector2(-60.0, -150.0)
var _pod: Node2D
var _chute: Sprite2D
var _arm: Sprite2D
var _flame: Sprite2D
var _fx: Node = null


# face: the pilot's angry face (DinoPilot.face_texture).
func setup(face_tex: Texture2D, fx: Node) -> void:
	_fx = fx
	_chute = Sprite2D.new()
	_chute.texture = Kit.cached("pod_chute", _paint_chute)
	_chute.position = Vector2(0.0, -26.0)
	_chute.scale = Vector2(0.1, 0.1)
	_chute.visible = false
	add_child(_chute)
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
	if _t < CHUTE_AT:
		_vel.y += 140.0 * delta
		_flame.visible = int(_t * 30.0) % 3 != 0
		_flame.scale = Vector2(1.0, randf_range(0.8, 1.3))
		if _fx != null and _fx.has_method("spawn_hit_sparks") and int(_t * 40.0) % 4 == 0:
			_fx.call("spawn_hit_sparks", global_position + Vector2(0.0, 14.0), Color("#ffb04c"), 1)
	else:
		if not _chute.visible:
			_chute.visible = true
			_flame.visible = false
		# The chute pops with a little overshoot, then the pod sways under it.
		var k: float = clampf((_t - CHUTE_AT) / 0.28, 0.0, 1.0)
		var s: float = 1.0 + sin(k * PI) * 0.25 if k < 1.0 else 1.0
		_chute.scale = Vector2(k * s, k * s)
		_vel = _vel.lerp(Vector2(-38.0, 26.0), clampf(4.0 * delta, 0.0, 1.0))
		rotation = sin(_t * 3.4) * 0.16
		# Fist shake.
		_arm.rotation = -0.6 + sin(_t * 26.0) * 0.45
	global_position += _vel * delta
	if _t > LIFE or global_position.x < -40.0 or global_position.y > 300.0:
		queue_free()


static func _paint_pod() -> Image:
	var img: Image = Kit.blank(24, 16)
	Kit.ball(img, 12.0, 8.0, 11.5, 7.5, Color("#b8c6e0"))
	Kit.rect(img, 1, 6, 22, 3, Color("#e8344a"))
	Kit.rect(img, 1, 6, 22, 1, Color("#ff7a8a"))
	Kit.glow(img, 5.0, 11.0, 1.6, Color("#ff9624"), Color("#ffe854"), Color.WHITE)
	Kit.glow(img, 19.0, 11.0, 1.6, Color("#ff9624"), Color("#ffe854"), Color.WHITE)
	return Kit.finish(img)


static func _paint_chute() -> Image:
	var img: Image = Kit.blank(34, 22)
	for x: int in range(34):
		for y: int in range(14):
			var nx: float = (float(x) + 0.5 - 17.0) / 16.5
			var ny: float = (float(y) + 0.5 - 14.0) / 13.5
			if nx * nx + ny * ny <= 1.0:
				var stripe: bool = int(floorf((nx + 1.0) * 3.0)) % 2 == 0
				Kit.put(img, x, y, Color("#ff4c68") if stripe else Color("#f4f0e8"))
	for sx: float in [1.0, 11.0, 23.0, 33.0]:
		Kit.line(img, Vector2(sx, 13), Vector2(17, 21), Color("#dce6ff"))
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
