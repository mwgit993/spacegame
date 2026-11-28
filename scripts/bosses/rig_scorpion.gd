extends "res://scripts/bosses/boss_rig.gd"

# STAGE 2 boss: SCORPIO-REX, a mecha scorpion piloted by a raptor. Six legs scuttle, the
# segmented tail sways over its back and coils before the stinger fires then jabs forward, and
# the two pincers snap open before their spread shots and clamp shut as they fire.
# Muzzles: stinger (patterns 0 and 2), claw_top, claw_bot (pattern 1).

const BODY: Color = Color("#3d7f8f")
const TRIM: Color = Color("#e2c25a")
const JOINT: Color = Color("#2a2340")
const EYE: Color = Color("#ff4c68")
const SEGMENTS: int = 7
const TAIL_BASE: Vector2 = Vector2(44.0, -8.0)

var _body: Sprite2D
var _legs: Array[Sprite2D] = []
var _tail: Array[Sprite2D] = []
var _stinger: Sprite2D
var _arms: Array[Sprite2D] = []
var _jaws_a: Array[Sprite2D] = []
var _jaws_b: Array[Sprite2D] = []
var _eyes: Sprite2D


static func _seg_r(i: int) -> float:
	return 9.0 - float(i) * 0.65


func build() -> void:
	# Far legs (behind), body, near legs (in front).
	for i: int in range(3):
		_legs.append(part(self, Kit.cached("scorp_leg_far", _paint_leg.bind(true)), Vector2(-4.0 + 20.0 * float(i), 30.0), Vector2(3.0, 3.0), -2))
	_body = part(self, Kit.cached("scorp_body", _paint_body), Vector2(14.0, 12.0), Vector2(43.0, 28.0), 0)
	for i: int in range(3):
		_legs.append(part(self, Kit.cached("scorp_leg_near", _paint_leg.bind(false)), Vector2(4.0 + 20.0 * float(i), 34.0), Vector2(3.0, 3.0), 2))
	var head: Sprite2D = part(self, Kit.cached("scorp_head", _paint_head), Vector2(-30.0, 14.0), Vector2(20.0, 16.0), 1)
	_eyes = part(head, Kit.cached("scorp_eyes", _paint_eyes), Vector2(-12.0, -8.0), Vector2(5.0, 3.0), 3)
	_eyes.use_parent_material = false

	# Tail: a chain of overlapping segments from the rear of the carapace, then the stinger.
	var parent: Node2D = self
	var at: Vector2 = TAIL_BASE
	for i: int in range(SEGMENTS):
		var r: float = _seg_r(i)
		var seg: Sprite2D = part(parent, Kit.cached("scorp_seg_%d" % i, _paint_segment.bind(r)), at, Vector2(r + 1.0, r * 2.0), 1)
		_tail.append(seg)
		parent = seg
		at = Vector2(0.0, -r * 1.55)
	_stinger = part(parent, Kit.cached("scorp_stinger", _paint_stinger), at, Vector2(6.0, 25.0), 1)
	marker(_stinger, "stinger", Vector2(0.0, -25.0))

	# Pincers: an arm each, then two jaws that open and shut.
	for i: int in range(2):
		var sh: Vector2 = Vector2(-38.0, 4.0) if i == 0 else Vector2(-38.0, 26.0)
		var arm: Sprite2D = part(self, Kit.cached("scorp_arm", _paint_arm), sh, Vector2(31.0, 5.0), 3 if i == 1 else 2)
		var hand: Node2D = joint(arm, Vector2(-28.0, 0.0), 1)
		var ja: Sprite2D = part(hand, Kit.cached("scorp_jaw", _paint_jaw), Vector2.ZERO, Vector2(22.0, 9.0), 0)
		var jb: Sprite2D = part(hand, Kit.cached("scorp_jaw_low", _paint_jaw_low), Vector2.ZERO, Vector2(22.0, 2.0), 0)
		marker(hand, "claw_top" if i == 0 else "claw_bot", Vector2(-20.0, 0.0))
		_arms.append(arm)
		_jaws_a.append(ja)
		_jaws_b.append(jb)

	add_pilot(self, Vector2(-2.0, -12.0), Vector2i(34, 28), 3)


func animate(_delta: float) -> void:
	var nxt: int = next_pattern()
	var w_tail: float = windup if nxt != 1 else 0.0
	var w_claw: float = windup if nxt == 1 else 0.0
	var speed: float = 1.0 + 0.35 * float(phase() - 1) + rage * 1.5
	position = Vector2(hurt_k * 1.5, 0.0)

	# Scuttling legs.
	for i: int in range(_legs.size()):
		_legs[i].rotation = sin(t * 9.0 * speed + float(i) * 1.7) * 0.2

	# Tail: sways; coils back before a stinger shot, jabs forward when it fires.
	var jab: float = kick if pattern != 1 else 0.0
	for i: int in range(_tail.size()):
		var base_bend: float = 0.25 if i == 0 else -0.36
		var sway: float = sin(t * 2.2 * speed + float(i) * 0.7) * 0.06
		var coil: float = 0.1 * w_tail if i > 0 else -0.3 * w_tail
		var strike: float = -0.09 * jab if i > 0 else 0.25 * jab
		_tail[i].rotation = base_bend + sway + coil + strike + rage * 0.05 * sin(t * 30.0)
	_stinger.rotation = 0.45 - 0.35 * w_tail + 0.3 * jab

	# Pincers: idle snapping, wide open before their volley, clamp shut on it.
	for i: int in range(2):
		var up: float = 1.0 if i == 0 else -1.0
		var reach: float = 0.2 * (kick if pattern == 1 else 0.0)
		_arms[i].rotation = up * (0.28 + 0.1 * w_claw) + sin(t * 1.6 + float(i)) * 0.05 - up * reach
		var open: float = 0.1 + 0.12 * (0.5 + 0.5 * sin(t * 3.0 + float(i) * 2.0)) + 0.45 * w_claw
		if pattern == 1 and kick > 0.6:
			open = 0.0
		_jaws_a[i].rotation = open
		_jaws_b[i].rotation = -open

	_eyes.modulate = Color(1.0, 1.0, 1.0, 0.75 + 0.25 * sin(t * 8.0)) if rage <= 0.0 else Color(1.6, 0.6, 0.6)


# --- Painting -----------------------------------------------------------------------------------

static func _paint_body() -> Image:
	var img: Image = Kit.blank(86, 56)
	Kit.ball(img, 43.0, 29.0, 42.0, 26.0, BODY)
	# Armour bands across the carapace.
	for k: int in range(6):
		var x: float = 12.0 + float(k) * 12.0
		Kit.line(img, Vector2(x, 6), Vector2(x - 3.0, 52), JOINT)
		Kit.line(img, Vector2(x + 1.0, 7), Vector2(x - 2.0, 50), BODY.lightened(0.35))
	Kit.rect(img, 6, 30, 74, 2, TRIM)
	for k2: int in range(5):
		Kit.glow(img, 22.0 + float(k2) * 12.0, 18.0, 2.0, Color(0.2, 0.9, 1.0, 0.6), Color("#3cf4ff"), Color.WHITE)
	return Kit.finish(img)


static func _paint_head() -> Image:
	var img: Image = Kit.blank(40, 32)
	Kit.ball(img, 22.0, 16.0, 18.0, 14.0, BODY.lightened(0.06))
	# Mandibles at the front.
	Kit.poly(img, PackedVector2Array([Vector2(0, 20), Vector2(9, 12), Vector2(12, 26)]), BODY.darkened(0.15))
	Kit.poly(img, PackedVector2Array([Vector2(1, 28), Vector2(10, 22), Vector2(14, 31)]), BODY.darkened(0.25))
	Kit.rect(img, 4, 22, 26, 2, TRIM)
	return Kit.finish(img)


static func _paint_eyes() -> Image:
	var img: Image = Kit.blank(12, 7)
	for ex: float in [2.5, 8.0]:
		Kit.glow(img, ex, 3.5, 2.6, Color(1.0, 0.2, 0.3, 0.6), EYE, Color.WHITE)
	return img


static func _paint_leg(far: bool) -> Image:
	var c: Color = JOINT.lightened(0.25) if not far else JOINT
	var img: Image = Kit.blank(20, 26)
	Kit.line(img, Vector2(3, 3), Vector2(11, 11), c, 4.0)
	Kit.line(img, Vector2(11, 11), Vector2(7, 24), c, 3.0)
	Kit.ellipse(img, 11.0, 11.0, 2.0, 2.0, TRIM)
	return Kit.outline(img)


static func _paint_segment(r: float) -> Image:
	var d: int = int(ceilf(r * 2.0)) + 2
	var img: Image = Kit.blank(d, int(ceilf(r * 2.0 + 2.0)))
	Kit.ball(img, r + 1.0, r + 1.0, r, r, BODY)
	Kit.rect(img, 1, int(r) + 1, d - 2, 1, TRIM)
	return Kit.outline(img)


static func _paint_stinger() -> Image:
	var img: Image = Kit.blank(12, 26)
	Kit.ellipse(img, 6.0, 21.0, 5.5, 5.0, BODY)
	Kit.poly(img, PackedVector2Array([Vector2(1, 19), Vector2(11, 19), Vector2(7, 6), Vector2(6, 0), Vector2(5, 6)]), TRIM)
	Kit.line(img, Vector2(6, 3), Vector2(6, 16), Color("#ff4c68"))
	return Kit.finish(img)


static func _paint_arm() -> Image:
	var img: Image = Kit.blank(34, 11)
	Kit.ball(img, 17.0, 5.5, 16.5, 5.0, BODY.darkened(0.08))
	Kit.ellipse(img, 30.0, 5.5, 4.0, 4.0, JOINT)
	Kit.ellipse(img, 4.0, 5.5, 3.5, 3.5, JOINT)
	Kit.rect(img, 9, 5, 16, 1, TRIM)
	return Kit.outline(img)


static func _paint_jaw() -> Image:
	var img: Image = Kit.blank(24, 11)
	Kit.poly(img, PackedVector2Array([Vector2(23, 10), Vector2(13, 1), Vector2(3, 1), Vector2(0, 7), Vector2(8, 6), Vector2(15, 10)]), BODY.lightened(0.1))
	Kit.line(img, Vector2(1, 7), Vector2(18, 9), TRIM)
	for tx: int in [5, 9, 13]:
		Kit.put(img, tx, 7, Color.WHITE)
	return Kit.finish(img)


static func _paint_jaw_low() -> Image:
	return Kit.flip_v(_paint_jaw())
