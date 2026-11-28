extends "res://scripts/bosses/boss_rig.gd"

# STAGE 6 boss: the INFERNO SKULL, a horned demon-skull war machine with a spinosaurus in its
# forehead dome. Flames roar off its crown (higher each phase), fire flickers in its eye sockets and
# flares before the eye shot, the jaw chomps, drops open before the fan of fireballs and snaps shut
# as it fires, and lava drips from the cracks.
# Muzzles: mouth (fan), eye (aimed burst).

const BONE: Color = Color("#d8c8a8")
const CHAR: Color = Color("#3a2a2a")
const LAVA: Color = Color("#ff6820")
const FIRE: Color = Color("#ffd23c")
const DRIPS: Array[Vector2] = [Vector2(-22.0, 24.0), Vector2(10.0, 20.0), Vector2(26.0, 2.0)]

var _flames: Array[Sprite2D] = []
var _eyes: Array[Sprite2D] = []
var _jaw: Sprite2D
var _drips: Array[Sprite2D] = []
var _drip_t: Array[float] = []


func build() -> void:
	for f: Vector3 in [Vector3(-12.0, -42.0, 0.9), Vector3(4.0, -50.0, 1.2), Vector3(20.0, -46.0, 1.0), Vector3(34.0, -32.0, 0.8)]:
		var fl: Sprite2D = part(self, Kit.cached("skull_flame", _paint_flame), Vector2(f.x, f.y), Vector2(9.0, 26.0), -4)
		fl.use_parent_material = false
		fl.scale = Vector2(f.z, f.z)
		_flames.append(fl)
	part(self, Kit.cached("skull_horn", _paint_horn), Vector2(18.0, -30.0), Vector2(2.0, 32.0), -2)
	part(self, Kit.cached("skull_horn_far", _paint_horn_far), Vector2(30.0, -22.0), Vector2(2.0, 26.0), -3)
	part(self, Kit.cached("skull_cranium", _paint_cranium), Vector2(6.0, -6.0), Vector2(43.0, 41.0), 0)
	for e: Vector3 in [Vector3(-14.0, -14.0, 1.0), Vector3(-33.0, -12.0, 0.7)]:
		var eye: Sprite2D = part(self, Kit.cached("skull_eye", _paint_eye), Vector2(e.x, e.y), Vector2(6.0, 6.0), 1)
		eye.use_parent_material = false
		eye.scale = Vector2(e.z, e.z)
		_eyes.append(eye)
	marker(_eyes[0], "eye", Vector2.ZERO)
	_jaw = part(self, Kit.cached("skull_jaw", _paint_jaw), Vector2(6.0, 12.0), Vector2(52.0, 4.0), 1)
	marker(_jaw, "mouth", Vector2(-40.0, -2.0))
	for d: Vector2 in DRIPS:
		var dr: Sprite2D = part(self, Kit.cached("skull_drip", _paint_drip), d, Vector2(2.0, 0.0), 2)
		dr.use_parent_material = false
		_drips.append(dr)
		_drip_t.append(randf())
	add_pilot(self, Vector2(10.0, -32.0), "spino", Vector2i(36, 28), 3)


func animate(delta: float) -> void:
	var nxt: int = next_pattern()
	var w_jaw: float = windup if nxt == 0 else 0.0
	var w_eye: float = windup if nxt != 0 else 0.0
	var shake: float = rage * (1.0 if int(t * 36.0) % 2 == 0 else -1.0) * 1.5
	position = Vector2(hurt_k * 1.5 + shake, 0.0)
	# Crown of fire, taller with each phase and in a rage.
	var heat: float = 0.85 + 0.2 * float(phase() - 1) + 0.4 * rage
	for i: int in range(_flames.size()):
		var f: Sprite2D = _flames[i]
		f.scale = Vector2(randf_range(0.85, 1.1), randf_range(0.85, 1.25)) * heat
	for i: int in range(_eyes.size()):
		var s: float = (1.0 if i == 0 else 0.7) * (0.9 + randf() * 0.2 + 0.6 * w_eye + (0.5 * kick if pattern != 0 else 0.0))
		_eyes[i].scale = Vector2(s, s)
	# Jaw: idle chomp, gapes before the fan, snaps shut as it fires.
	var gape: float = 0.06 + 0.06 * absf(sin(t * 3.0)) + 0.45 * w_jaw
	if pattern == 0 and kick > 0.55:
		gape = 0.0
	_jaw.rotation = -gape
	# Lava drips fall from the cracks and start again.
	for i: int in range(_drips.size()):
		_drip_t[i] = fmod(_drip_t[i] + delta * 0.9, 1.0)
		_drips[i].position = DRIPS[i] + Vector2(0.0, _drip_t[i] * 30.0)
		_drips[i].modulate.a = 1.0 - _drip_t[i]


# --- Painting -----------------------------------------------------------------------------------

static func _paint_flame() -> Image:
	var img: Image = Kit.blank(18, 28)
	Kit.poly(img, PackedVector2Array([Vector2(9, 0), Vector2(17, 14), Vector2(14, 27), Vector2(4, 27), Vector2(1, 14)]), Color(1.0, 0.4, 0.1, 0.85))
	Kit.poly(img, PackedVector2Array([Vector2(9, 8), Vector2(13, 17), Vector2(11, 26), Vector2(7, 26), Vector2(5, 17)]), FIRE)
	Kit.ellipse(img, 9.0, 23.0, 2.0, 3.0, Color("#fff4c0"))
	return img


static func _paint_horn() -> Image:
	var img: Image = Kit.blank(30, 34)
	Kit.poly(img, PackedVector2Array([Vector2(0, 33), Vector2(4, 22), Vector2(10, 12), Vector2(20, 4), Vector2(29, 0), Vector2(24, 8), Vector2(16, 18), Vector2(11, 33)]), BONE)
	Kit.line(img, Vector2(6, 26), Vector2(20, 8), BONE.darkened(0.25))
	return Kit.finish(img)


static func _paint_horn_far() -> Image:
	var img: Image = Kit.blank(26, 28)
	Kit.poly(img, PackedVector2Array([Vector2(0, 27), Vector2(5, 15), Vector2(14, 6), Vector2(25, 0), Vector2(18, 10), Vector2(10, 27)]), BONE.darkened(0.3))
	return Kit.finish(img)


static func _paint_cranium() -> Image:
	var img: Image = Kit.blank(86, 70)
	Kit.ball(img, 54.0, 30.0, 31.0, 28.0, BONE)
	Kit.poly(img, PackedVector2Array([Vector2(4, 30), Vector2(18, 12), Vector2(40, 8), Vector2(56, 30), Vector2(48, 58), Vector2(10, 58)]), BONE)
	# Eye sockets, nose cavity, cheekbone shadow.
	Kit.ellipse(img, 29.0, 27.0, 10.0, 9.0, CHAR)
	Kit.ellipse(img, 10.0, 29.0, 6.0, 8.0, CHAR)
	Kit.poly(img, PackedVector2Array([Vector2(4, 40), Vector2(10, 36), Vector2(12, 46)]), CHAR)
	Kit.line(img, Vector2(22, 42), Vector2(46, 46), BONE.darkened(0.3), 2.0)
	# Upper teeth.
	for x: int in range(6, 50, 5):
		Kit.poly(img, PackedVector2Array([Vector2(x, 56), Vector2(x + 4, 56), Vector2(x + 2, 62)]), Color("#f4ead0"))
	# Glowing lava cracks.
	for c: Array in [[Vector2(60, 6), Vector2(66, 18), Vector2(62, 28)], [Vector2(78, 26), Vector2(70, 36), Vector2(74, 48)], [Vector2(44, 10), Vector2(50, 20)]]:
		for i: int in range(c.size() - 1):
			Kit.line(img, c[i] as Vector2, c[i + 1] as Vector2, LAVA)
	return Kit.finish(img)


static func _paint_eye() -> Image:
	var img: Image = Kit.blank(12, 12)
	Kit.glow(img, 6.0, 6.0, 6.0, Color(1.0, 0.35, 0.05, 0.7), LAVA, FIRE)
	return img


static func _paint_jaw() -> Image:
	var img: Image = Kit.blank(56, 20)
	Kit.poly(img, PackedVector2Array([Vector2(55, 0), Vector2(55, 10), Vector2(40, 18), Vector2(8, 18), Vector2(0, 8), Vector2(2, 4), Vector2(30, 6)]), BONE.darkened(0.08))
	for x: int in range(4, 44, 5):
		Kit.poly(img, PackedVector2Array([Vector2(x, 5), Vector2(x + 4, 5), Vector2(x + 2, 0)]), Color("#f4ead0"))
	Kit.line(img, Vector2(10, 14), Vector2(40, 14), BONE.darkened(0.3))
	return Kit.finish(img)


static func _paint_drip() -> Image:
	var img: Image = Kit.blank(4, 6)
	Kit.ellipse(img, 2.0, 3.5, 1.6, 2.4, LAVA)
	Kit.put(img, 1, 2, FIRE)
	return img
