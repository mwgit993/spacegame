extends "res://scripts/bosses/boss_rig.gd"

# STAGE 4 boss: the EMPEROR ORCHID MANTIS, piloted by a triceratops. It sways in a praying stance
# with its scythes folded, wings buzzing; before the scythe volley it raises them cocked and slashes
# them down as it fires; its mandibles gnash before the sweeping stream; antennae twitch.
# Muzzles: scythe_top, scythe_bot (pattern 1), mouth.

const CHITIN: Color = Color("#c05ac8")
const CHITIN_D: Color = Color("#5a2a6a")
const EYE: Color = Color("#ffd23c")
const BIO: Color = Color("#9cff4c")

var _wings: Array[Sprite2D] = []
var _abdomen: Sprite2D
var _head: Sprite2D
var _mandibles: Array[Sprite2D] = []
var _antennae: Array[Sprite2D] = []
var _femurs: Array[Sprite2D] = []
var _blades: Array[Sprite2D] = []
var _legs: Array[Sprite2D] = []


func build() -> void:
	for i: int in range(2):
		var wg: Sprite2D = part(self, Kit.cached("mantis_wing_%d" % i, _paint_wing.bind(i == 0)), Vector2(14.0, -10.0), Vector2(2.0, 12.0), -3)
		_wings.append(wg)
	for lp: Vector2 in [Vector2(20.0, 22.0), Vector2(32.0, 24.0)]:
		_legs.append(part(self, Kit.cached("mantis_leg_back", _paint_leg.bind(true)), lp, Vector2(2.0, 2.0), -2))
	_abdomen = part(self, Kit.cached("mantis_abdomen", _paint_abdomen), Vector2(24.0, 12.0), Vector2(6.0, 18.0), -1)
	part(self, Kit.cached("mantis_thorax", _paint_thorax), Vector2(2.0, 4.0), Vector2(16.0, 22.0), 0)
	for lp2: Vector2 in [Vector2(-2.0, 22.0), Vector2(8.0, 25.0)]:
		_legs.append(part(self, Kit.cached("mantis_leg_front", _paint_leg.bind(false)), lp2, Vector2(14.0, 2.0), 1))

	_head = part(self, Kit.cached("mantis_head", _paint_head), Vector2(-30.0, -12.0), Vector2(22.0, 14.0), 2)
	for i: int in range(2):
		_antennae.append(part(_head, Kit.cached("mantis_antenna", _paint_antenna), Vector2(-8.0 + float(i) * 6.0, -11.0), Vector2(28.0, 22.0), -1))
	for i: int in range(2):
		var md_tex: Texture2D = Kit.cached("mantis_mandible_%d" % i, _paint_mandible.bind(i == 1))
		_mandibles.append(part(_head, md_tex, Vector2(-17.0, 6.0 + float(i) * 4.0), Vector2(8.0, 2.0 if i == 0 else 4.0), 1))
	marker(_head, "mouth", Vector2(-24.0, 9.0))

	for i: int in range(2):
		var sh: Vector2 = Vector2(-10.0, -4.0) if i == 0 else Vector2(-10.0, 14.0)
		var fem: Sprite2D = part(self, Kit.cached("mantis_femur", _paint_femur), sh, Vector2(30.0, 5.0), 3)
		var blade: Sprite2D = part(fem, Kit.cached("mantis_blade", _paint_blade), Vector2(-27.0, 0.0), Vector2(2.0, 6.0), 1)
		marker(blade, "scythe_top" if i == 0 else "scythe_bot", Vector2(30.0, 0.0))
		_femurs.append(fem)
		_blades.append(blade)

	add_pilot(self, Vector2(8.0, -22.0), Vector2i(36, 30), 4)


func animate(_delta: float) -> void:
	var nxt: int = next_pattern()
	var w_slash: float = windup if nxt == 1 else 0.0
	var w_jaw: float = windup if nxt != 1 else 0.0
	var spd: float = 1.0 + 0.3 * float(phase() - 1) + rage
	position = Vector2(hurt_k * 1.5, 0.0)

	# Praying sway; the head tilts and peers.
	var sway: float = sin(t * 1.4 * spd)
	_head.rotation = sway * 0.08 - 0.12 * w_jaw
	for i: int in range(2):
		_antennae[i].rotation = sin(t * 3.0 + float(i) * 1.3) * 0.15 + rage * 0.3
	var gnash: float = 0.15 + 0.15 * absf(sin(t * 6.0)) + 0.4 * maxf(w_jaw, kick if pattern != 1 else 0.0)
	_mandibles[0].rotation = gnash
	_mandibles[1].rotation = -gnash

	# Scythes: folded at rest; raised and cocked in the windup; slash down and out on the attack.
	var slash: float = kick if pattern == 1 else 0.0
	for i: int in range(2):
		var up: float = 1.0 if i == 0 else -1.0
		_femurs[i].rotation = up * (0.45 + 0.35 * w_slash - 0.55 * slash) + sway * 0.05 + rage * up * 0.3
		# The blade hangs folded back along the femur; it swings out as it slashes.
		_blades[i].rotation = up * (0.55 - 0.65 * w_slash + 2.2 * slash)

	# Wings buzz; spread in a rage.
	for i: int in range(2):
		_wings[i].rotation = (-0.55 if i == 0 else -0.95) + sin(t * 55.0 + float(i)) * 0.06 - rage * 0.4
	_abdomen.rotation = sin(t * 1.1) * 0.05
	for i: int in range(_legs.size()):
		_legs[i].rotation = sin(t * 2.0 + float(i) * 1.4) * 0.08


# --- Painting -----------------------------------------------------------------------------------

static func _paint_wing(far: bool) -> Image:
	var img: Image = Kit.blank(62, 22)
	var a: float = 0.28 if far else 0.42
	Kit.ellipse(img, 31.0, 11.0, 30.0, 9.0, Color(0.78, 1.0, 0.86, a))
	for k: int in range(4):
		Kit.line(img, Vector2(2, 11), Vector2(58, 4.0 + float(k) * 4.5), Color(0.6, 0.95, 0.75, a + 0.25))
	Kit.line(img, Vector2(2, 11), Vector2(60, 10), Color(0.9, 1.0, 0.95, a + 0.4))
	return img


static func _paint_abdomen() -> Image:
	var img: Image = Kit.blank(62, 38)
	Kit.poly(img, PackedVector2Array([Vector2(2, 10), Vector2(30, 2), Vector2(58, 14), Vector2(60, 22), Vector2(34, 36), Vector2(4, 28)]), CHITIN)
	for k: int in range(5):
		var x: float = 12.0 + float(k) * 9.0
		Kit.line(img, Vector2(x, 4.0 + float(k)), Vector2(x - 2.0, 33.0 - float(k)), CHITIN_D)
	for k2: int in range(4):
		Kit.glow(img, 16.0 + float(k2) * 10.0, 24.0, 1.8, Color(0.6, 1.0, 0.3, 0.5), BIO, Color.WHITE)
	return Kit.finish(img)


static func _paint_thorax() -> Image:
	var img: Image = Kit.blank(32, 44)
	Kit.ball(img, 16.0, 22.0, 14.0, 20.0, CHITIN)
	Kit.rect(img, 6, 20, 20, 2, CHITIN_D)
	Kit.glow(img, 16.0, 30.0, 3.0, Color(0.6, 1.0, 0.3, 0.5), BIO, Color.WHITE)
	return Kit.finish(img)


static func _paint_head() -> Image:
	var img: Image = Kit.blank(38, 26)
	Kit.poly(img, PackedVector2Array([Vector2(1, 12), Vector2(14, 2), Vector2(30, 0), Vector2(37, 9), Vector2(30, 22), Vector2(12, 24)]), CHITIN.lightened(0.08))
	# Huge compound eyes.
	Kit.ball(img, 24.0, 7.0, 7.0, 6.0, EYE)
	for k: int in range(6):
		Kit.put(img, 20 + (k % 3) * 3, 5 + (k / 3) * 3, EYE.darkened(0.35))
	Kit.ball(img, 31.0, 14.0, 4.5, 5.0, EYE.darkened(0.15))
	Kit.line(img, Vector2(16, 3), Vector2(27, 1), Kit.INK, 1.0)
	return Kit.finish(img)


static func _paint_antenna() -> Image:
	var img: Image = Kit.blank(30, 24)
	Kit.line(img, Vector2(28, 22), Vector2(14, 8), CHITIN_D)
	Kit.line(img, Vector2(14, 8), Vector2(1, 1), CHITIN_D)
	Kit.put(img, 1, 1, BIO)
	return img


static func _paint_mandible(lower: bool) -> Image:
	var img: Image = Kit.blank(10, 6)
	Kit.poly(img, PackedVector2Array([Vector2(9, 1), Vector2(9, 4), Vector2(2, 5), Vector2(0, 2)]), CHITIN_D.lightened(0.2))
	Kit.put(img, 1, 3, Color.WHITE)
	var out: Image = Kit.outline(img)
	return Kit.flip_v(out) if lower else out


static func _paint_femur() -> Image:
	var img: Image = Kit.blank(32, 10)
	Kit.ball(img, 16.0, 5.0, 15.5, 4.2, CHITIN)
	Kit.ellipse(img, 29.0, 5.0, 3.0, 3.0, CHITIN_D)
	Kit.ellipse(img, 3.0, 5.0, 2.5, 2.5, CHITIN_D)
	return Kit.outline(img)


static func _paint_blade() -> Image:
	var img: Image = Kit.blank(34, 12)
	Kit.poly(img, PackedVector2Array([Vector2(0, 4), Vector2(30, 2), Vector2(33, 0), Vector2(31, 6), Vector2(2, 9)]), CHITIN.lightened(0.2))
	Kit.line(img, Vector2(3, 8), Vector2(30, 5), Color("#f4ead0"))
	for x: int in range(5, 29, 4):
		Kit.put(img, x, 9 - x / 10, Color("#f4ead0"))
	return Kit.finish(img)


static func _paint_leg(back: bool) -> Image:
	var img: Image = Kit.blank(18, 24)
	if back:
		Kit.line(img, Vector2(2, 2), Vector2(12, 10), CHITIN_D, 2.0)
		Kit.line(img, Vector2(12, 10), Vector2(15, 22), CHITIN_D, 2.0)
	else:
		Kit.line(img, Vector2(14, 2), Vector2(5, 11), CHITIN_D.lightened(0.15), 2.0)
		Kit.line(img, Vector2(5, 11), Vector2(3, 22), CHITIN_D.lightened(0.15), 2.0)
	return Kit.outline(img)
