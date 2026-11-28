extends "res://scripts/bosses/boss_rig.gd"

# STAGE 5 boss: the FROST SERAPH, a crystal angel mech with a stegosaurus in its chest cockpit. Six
# ice wings fan slowly and flare open (with the heart crystal blazing) before each ring burst, the
# halo spins, the icicle robe sways, and the lance arm tracks the player for the aimed shot.
# Muzzles: ring (heart crystal), aimed (lance tip).

const ICE: Color = Color("#bfe8ff")
const ICE_D: Color = Color("#5a8ab8")
const CRYSTAL: Color = Color("#7ad8ff")
const GOLD: Color = Color("#ffd27a")

var _wings: Array[Sprite2D] = []
var _wing_base: Array[float] = []
var _halo: Sprite2D
var _robe: Sprite2D
var _core: Sprite2D
var _arm: Sprite2D
var _head: Sprite2D


func build() -> void:
	_halo = part(self, Kit.cached("seraph_halo", _paint_halo), Vector2(-2.0, -62.0), Vector2(23.0, 7.0), -4)
	_halo.use_parent_material = false
	# Six wings: three fanning up and back, three down and back, plus a fainter mirrored set on the
	# far side so it reads as an angel.
	for i: int in range(3):
		_wing_base.append(-0.25 - 0.32 * float(i))
		var far_w: Sprite2D = part(self, Kit.cached("seraph_wing_far", _paint_shard.bind(14, 56, true)), Vector2(-4.0, -20.0), Vector2(8.0, 57.0), -4)
		_wings.append(far_w)
	for i: int in range(3):
		_wing_base.append(0.25 + 0.36 * float(i))
		_wings.append(part(self, Kit.cached("seraph_wing_up", _paint_shard.bind(18, 70, false)), Vector2(8.0, -20.0), Vector2(10.0, 71.0), -3))
	for i: int in range(3):
		_wing_base.append(2.0 + 0.36 * float(i))
		_wings.append(part(self, Kit.cached("seraph_wing_low", _paint_shard.bind(14, 52, false)), Vector2(8.0, 8.0), Vector2(8.0, 53.0), -3))
	_robe = part(self, Kit.cached("seraph_robe", _paint_robe), Vector2(4.0, 24.0), Vector2(21.0, 2.0), -1)
	part(self, Kit.cached("seraph_body", _paint_body), Vector2(0.0, 0.0), Vector2(23.0, 30.0), 0)
	_head = part(self, Kit.cached("seraph_head", _paint_head), Vector2(-2.0, -34.0), Vector2(14.0, 22.0), 1)
	_core = part(self, Kit.cached("seraph_core", _paint_core), Vector2(0.0, 22.0), Vector2(9.0, 9.0), 2)
	_core.use_parent_material = false
	marker(_core, "ring", Vector2.ZERO)
	add_pilot(self, Vector2(0.0, -4.0), "stego", Vector2i(34, 28), 2)
	_arm = part(self, Kit.cached("seraph_arm", _paint_arm), Vector2(-14.0, -14.0), Vector2(52.0, 5.0), 3)
	marker(_arm, "aimed", Vector2(-52.0, 0.0))


func animate(delta: float) -> void:
	var flare: float = maxf(windup, kick)
	position = Vector2(hurt_k * 1.5, 0.0)
	for i: int in range(_wings.size()):
		var k: float = float(i % 3 + 1) / 3.0
		var dir: float = -1.0 if i < 6 else 1.0
		var spread: float = (0.18 * flare + 0.25 * rage) * k * dir
		_wings[i].rotation = _wing_base[i] + sin(t * 1.5 + float(i)) * 0.05 + spread
	_halo.scale = Vector2(0.75 + 0.25 * sin(t * 2.2), 1.0)
	_halo.position = Vector2(-2.0, -62.0 + sin(t * 1.7) * 1.5)
	_halo.modulate = Color(1.0, 1.0, 1.0, 0.7 + 0.3 * flare)
	_robe.rotation = sin(t * 1.3) * 0.05
	_head.rotation = sin(t * 0.9) * 0.04
	var pulse: float = 1.0 + 0.08 * sin(t * 5.0) + 0.5 * flare
	_core.scale = Vector2(pulse, pulse)
	# The lance tracks the player (within reach) and kicks back with each shot.
	var a: Vector2 = aim()
	var rot: float = clampf(wrapf(a.angle() - PI, -PI, PI), -0.5, 0.5)
	_arm.rotation = lerp_angle(_arm.rotation, rot - 0.12 * windup, clampf(delta * 4.0, 0.0, 1.0))
	_arm.position = Vector2(-14.0 + 4.0 * kick, -14.0)


# --- Painting -----------------------------------------------------------------------------------

static func _paint_halo() -> Image:
	var img: Image = Kit.blank(46, 14)
	for k: int in range(120):
		var a: float = TAU * float(k) / 120.0
		var x: int = int(roundf(23.0 + cos(a) * 21.0))
		var y: int = int(roundf(7.0 + sin(a) * 5.0))
		Kit.put(img, x, y, Color("#e8fbff"))
		Kit.put(img, x, y + 1, Color(0.48, 0.85, 1.0, 0.7))
	return img


static func _paint_shard(w: int, h: int, far: bool) -> Image:
	var img: Image = Kit.blank(w + 2, h + 2)
	var cx: float = float(w) * 0.5 + 1.0
	Kit.poly(img, PackedVector2Array([Vector2(cx, 0), Vector2(float(w), float(h) * 0.3), Vector2(cx + 2.0, float(h)), Vector2(cx - 2.0, float(h)), Vector2(1, float(h) * 0.3)]), CRYSTAL)
	Kit.poly(img, PackedVector2Array([Vector2(cx, 1), Vector2(float(w) - 2.0, float(h) * 0.3), Vector2(cx, float(h) - 2.0)]), ICE)
	Kit.line(img, Vector2(cx, 2), Vector2(cx, float(h) - 3.0), Color.WHITE)
	if far:
		for y: int in range(img.get_height()):
			for x: int in range(img.get_width()):
				var c: Color = img.get_pixel(x, y)
				if c.a > 0.0:
					img.set_pixel(x, y, Color(c.darkened(0.25), c.a))
	return Kit.finish(img)


static func _paint_robe() -> Image:
	var img: Image = Kit.blank(42, 42)
	var pts: PackedVector2Array = PackedVector2Array([Vector2(8, 0), Vector2(34, 0)])
	for k: int in range(7):
		var x: float = 40.0 - float(k) * 6.0
		pts.append(Vector2(x, 28.0 + float(k % 2) * 12.0))
		pts.append(Vector2(x - 3.0, 26.0))
	pts.append(Vector2(2, 30))
	Kit.poly(img, pts, ICE)
	for k2: int in range(5):
		Kit.line(img, Vector2(10.0 + float(k2) * 6.0, 3), Vector2(8.0 + float(k2) * 6.0, 28), ICE_D)
	Kit.rect(img, 8, 0, 26, 2, GOLD)
	return Kit.finish(img)


static func _paint_body() -> Image:
	var img: Image = Kit.blank(46, 60)
	Kit.poly(img, PackedVector2Array([Vector2(8, 4), Vector2(38, 4), Vector2(44, 18), Vector2(36, 58), Vector2(10, 58), Vector2(2, 18)]), ICE)
	# Shoulder pads and gold trim.
	Kit.ball(img, 8.0, 10.0, 8.0, 7.0, CRYSTAL)
	Kit.ball(img, 38.0, 10.0, 8.0, 7.0, CRYSTAL)
	Kit.rect(img, 10, 40, 26, 2, GOLD)
	Kit.line(img, Vector2(23, 42), Vector2(23, 56), ICE_D)
	Kit.ellipse(img, 23.0, 52.0, 8.0, 7.0, ICE_D)
	return Kit.finish(img)


static func _paint_head() -> Image:
	var img: Image = Kit.blank(28, 26)
	for sp: Vector3 in [Vector3(6, 6, 6), Vector3(12, 2, 8), Vector3(18, 2, 8), Vector3(24, 6, 6)]:
		Kit.poly(img, PackedVector2Array([Vector2(sp.x - 3.0, 12), Vector2(sp.x, sp.y - sp.z * 0.2), Vector2(sp.x + 3.0, 12)]), GOLD)
	Kit.ball(img, 14.0, 16.0, 10.0, 9.0, ICE)
	Kit.rect(img, 4, 14, 14, 3, Color("#3cf4ff"))
	Kit.rect(img, 4, 15, 14, 1, Color.WHITE)
	return Kit.finish(img)


static func _paint_core() -> Image:
	var img: Image = Kit.blank(18, 18)
	Kit.poly(img, PackedVector2Array([Vector2(9, 0), Vector2(17, 9), Vector2(9, 17), Vector2(1, 9)]), Color(0.5, 0.9, 1.0, 0.6))
	Kit.poly(img, PackedVector2Array([Vector2(9, 3), Vector2(14, 9), Vector2(9, 14), Vector2(4, 9)]), Color("#bff4ff"))
	Kit.ellipse(img, 9.0, 9.0, 2.5, 2.5, Color.WHITE)
	return img


static func _paint_arm() -> Image:
	var img: Image = Kit.blank(56, 11)
	Kit.ball(img, 46.0, 5.0, 8.0, 4.0, ICE)
	Kit.line(img, Vector2(2, 5), Vector2(40, 5), GOLD, 2.0)
	Kit.poly(img, PackedVector2Array([Vector2(0, 5), Vector2(10, 1), Vector2(14, 5), Vector2(10, 9)]), CRYSTAL)
	Kit.line(img, Vector2(2, 5), Vector2(12, 5), Color.WHITE)
	return Kit.finish(img)
