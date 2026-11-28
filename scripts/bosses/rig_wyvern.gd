extends "res://scripts/bosses/boss_rig.gd"

# STAGE 3 boss: the SKY WYVERN, a cyborg dragon with a pterodactyl riding in its saddle pod.
# Its big wings beat (faster each phase), the neck sways, the jaw drops open as it winds up and it
# roars when it fires, its chest reactor glows before the ring burst, and the tail swishes.
# Muzzles: maw (aimed fan and spread), ring (chest).

const SCALE_C: Color = Color("#c8503c")
const BELLY: Color = Color("#f0d8a0")
const MEMBRANE: Color = Color("#8a2c4a")
const METAL: Color = Color("#9aa8c8")
const GLOW_C: Color = Color("#ffb04c")

var _wings: Array[Sprite2D] = []   # far, near
var _neck: Array[Sprite2D] = []
var _head: Sprite2D
var _jaw: Sprite2D
var _tail: Array[Sprite2D] = []
var _legs: Array[Sprite2D] = []
var _chest: Sprite2D


func build() -> void:
	_wings.append(part(self, Kit.cached("wyv_wing_far", _paint_wing.bind(true)), Vector2(4.0, -10.0), Vector2(7.0, 59.0), -3))
	# Tail behind the body.
	var parent: Node2D = self
	var at: Vector2 = Vector2(34.0, 12.0)
	for i: int in range(4):
		var r: float = 8.0 - float(i) * 1.5
		var seg: Sprite2D = part(parent, Kit.cached("wyv_tail_%d" % i, _paint_tail_seg.bind(r, i == 3)), at, Vector2(1.0, r + 1.0), -1)
		_tail.append(seg)
		parent = seg
		at = Vector2(r * 1.7, 0.0)
	for lp: Vector2 in [Vector2(2.0, 22.0), Vector2(20.0, 24.0)]:
		_legs.append(part(self, Kit.cached("wyv_leg", _paint_leg), lp, Vector2(5.0, 3.0), 1))
	part(self, Kit.cached("wyv_body", _paint_body), Vector2(10.0, 6.0), Vector2(32.0, 22.0), 0)
	_chest = part(self, Kit.cached("wyv_chest", _paint_chest), Vector2(-6.0, 10.0), Vector2(7.0, 7.0), 1)
	_chest.use_parent_material = false
	marker(_chest, "ring", Vector2.ZERO)

	# Neck (two segments) up to the head and its jaw.
	parent = self
	at = Vector2(-14.0, -2.0)
	for i: int in range(2):
		var seg2: Sprite2D = part(parent, Kit.cached("wyv_neck", _paint_neck), at, Vector2(15.0, 8.0), 1)
		_neck.append(seg2)
		parent = seg2
		at = Vector2(-12.0, -2.0)
	_head = part(parent, Kit.cached("wyv_head", _paint_head), at, Vector2(30.0, 12.0), 1)
	_jaw = part(_head, Kit.cached("wyv_jaw", _paint_jaw), Vector2(-6.0, 4.0), Vector2(24.0, 2.0), -1)
	marker(_head, "maw", Vector2(-32.0, 6.0))
	marker(_head, "spread", Vector2(-32.0, 6.0))

	add_pilot(self, Vector2(4.0, -18.0), "ptero", Vector2i(34, 28), 4)
	_wings.append(part(self, Kit.cached("wyv_wing_near", _paint_wing.bind(false)), Vector2(14.0, -6.0), Vector2(7.0, 59.0), 3))


func animate(_delta: float) -> void:
	var nxt: int = next_pattern()
	var w_maw: float = windup if nxt != 2 else 0.0
	var w_ring: float = windup if nxt == 2 else 0.0
	var beat: float = 5.0 + float(phase() - 1) * 1.6 + rage * 4.0
	position = Vector2(hurt_k * 1.5, sin(t * beat) * 2.0)

	# Wing beats (the far wing a touch behind the near one); spread wide in a rage.
	for i: int in range(2):
		var flap: float = sin(t * beat - float(i) * 0.4)
		_wings[i].rotation = -0.55 + flap * 0.42 - rage * 0.3 - (0.12 if i == 0 else 0.0)

	# Neck sways; rears back as it winds up, then snaps forward with the shot.
	var snap: float = kick if pattern != 2 else 0.0
	for i: int in range(_neck.size()):
		_neck[i].rotation = sin(t * 1.7 + float(i) * 0.8) * 0.08 + 0.12 * w_maw - 0.16 * snap
	_head.rotation = sin(t * 2.3) * 0.06 + 0.08 * w_maw - 0.12 * snap
	_jaw.rotation = -(0.08 + 0.5 * maxf(w_maw, snap) + 0.4 * rage)

	# Tail swish and dangling legs.
	for i: int in range(_tail.size()):
		_tail[i].rotation = 0.35 + sin(t * 2.0 + float(i) * 0.9) * 0.18
	for i: int in range(_legs.size()):
		_legs[i].rotation = sin(t * 1.5 + float(i)) * 0.12

	var glow: float = 0.55 + 0.25 * sin(t * 6.0) + 0.6 * w_ring + (0.5 * kick if pattern == 2 else 0.0)
	_chest.scale = Vector2.ONE * (0.9 + 0.35 * clampf(glow - 0.5, 0.0, 1.0))
	_chest.modulate = Color(1.0, 1.0, 1.0, clampf(glow, 0.3, 1.0))


# --- Painting -----------------------------------------------------------------------------------

static func _paint_wing(far: bool) -> Image:
	var bone: Color = METAL if not far else METAL.darkened(0.3)
	var skin: Color = MEMBRANE if not far else MEMBRANE.darkened(0.3)
	var img: Image = Kit.blank(76, 64)
	var root: Vector2 = Vector2(6, 58)
	var wrist: Vector2 = Vector2(40, 10)
	var tips: Array[Vector2] = [Vector2(74, 3), Vector2(72, 26), Vector2(62, 48)]
	Kit.poly(img, PackedVector2Array([root, wrist, tips[0], Vector2(66, 16), tips[1], Vector2(62, 37), tips[2], Vector2(30, 52)]), skin)
	# Membrane ribs lighter between the spars.
	Kit.line(img, Vector2(44, 18), Vector2(64, 40), skin.lightened(0.15))
	Kit.line(img, Vector2(46, 12), Vector2(68, 14), skin.lightened(0.15))
	Kit.line(img, root, wrist, bone, 3.0)
	for tip: Vector2 in tips:
		Kit.line(img, wrist, tip, bone, 2.0)
	Kit.ellipse(img, wrist.x, wrist.y, 2.5, 2.5, GLOW_C)
	return Kit.finish(img)


static func _paint_body() -> Image:
	var img: Image = Kit.blank(62, 42)
	# A lean body: deep chest at the front, tapering towards the tail.
	Kit.poly(img, PackedVector2Array([Vector2(2, 18), Vector2(12, 8), Vector2(34, 6), Vector2(60, 16), Vector2(60, 24), Vector2(34, 34), Vector2(10, 34)]), SCALE_C)
	Kit.ball(img, 16.0, 22.0, 14.0, 13.0, SCALE_C)
	Kit.poly(img, PackedVector2Array([Vector2(6, 26), Vector2(30, 28), Vector2(52, 24), Vector2(34, 33), Vector2(12, 33)]), BELLY)
	for k: int in range(5):
		Kit.rect(img, 10 + k * 8, 29 - (k % 2), 5, 1, BELLY.darkened(0.25))
	# Cyborg plating on the back.
	Kit.plate(img, 26, 4, 22, 9, METAL, true)
	Kit.plate(img, 44, 10, 12, 12, METAL.darkened(0.1), true)
	return Kit.finish(img)


static func _paint_chest() -> Image:
	var img: Image = Kit.blank(14, 14)
	Kit.glow(img, 7.0, 7.0, 7.0, Color(1.0, 0.5, 0.1, 0.55), GLOW_C, Color("#fff4c0"))
	return img


static func _paint_neck() -> Image:
	var img: Image = Kit.blank(18, 16)
	Kit.ball(img, 9.0, 8.0, 8.5, 7.0, SCALE_C)
	Kit.ellipse(img, 8.0, 12.0, 6.0, 2.5, BELLY)
	Kit.rect(img, 4, 2, 9, 2, METAL)
	return Kit.finish(img)


static func _paint_head() -> Image:
	var img: Image = Kit.blank(36, 20)
	# Horns swept back.
	Kit.poly(img, PackedVector2Array([Vector2(24, 4), Vector2(35, 0), Vector2(28, 7)]), BELLY.darkened(0.1))
	Kit.poly(img, PackedVector2Array([Vector2(26, 8), Vector2(35, 6), Vector2(29, 11)]), BELLY.darkened(0.2))
	Kit.ball(img, 24.0, 10.0, 10.0, 8.0, SCALE_C)
	Kit.poly(img, PackedVector2Array([Vector2(0, 11), Vector2(14, 5), Vector2(24, 6), Vector2(24, 14), Vector2(2, 14)]), SCALE_C)
	Kit.plate(img, 12, 5, 12, 4, METAL)
	for x: int in range(3, 22, 3):
		Kit.put(img, x, 14, Color.WHITE)
	Kit.put(img, 3, 10, Kit.INK)
	# Glowing eye under a heavy brow.
	Kit.ellipse(img, 20.0, 9.0, 2.2, 1.6, GLOW_C)
	Kit.line(img, Vector2(17, 7), Vector2(24, 5), Kit.INK, 1.0)
	return Kit.finish(img)


static func _paint_jaw() -> Image:
	var img: Image = Kit.blank(26, 8)
	Kit.poly(img, PackedVector2Array([Vector2(25, 0), Vector2(25, 5), Vector2(6, 7), Vector2(1, 2), Vector2(1, 0)]), SCALE_C.darkened(0.15))
	Kit.rect(img, 2, 0, 22, 2, Color("#5a1020"))
	for x: int in range(4, 22, 4):
		Kit.put(img, x, 2, Color.WHITE)
	return Kit.finish(img)


static func _paint_tail_seg(r: float, tip: bool) -> Image:
	var w: int = int(ceilf(r * 2.0 + (10.0 if tip else 2.0)))
	var img: Image = Kit.blank(w, int(ceilf(r * 2.0 + 2.0)))
	Kit.ball(img, r + 1.0, r + 1.0, r, r * 0.85, SCALE_C)
	if tip:
		Kit.poly(img, PackedVector2Array([Vector2(r, r - 4.0), Vector2(float(w) - 1.0, r + 1.0), Vector2(r, r + 6.0)]), METAL)
	return Kit.outline(img)


static func _paint_leg() -> Image:
	var img: Image = Kit.blank(14, 18)
	Kit.line(img, Vector2(5, 3), Vector2(7, 12), SCALE_C.darkened(0.2), 4.0)
	for cx: int in [3, 7, 11]:
		Kit.line(img, Vector2(7, 12), Vector2(cx, 17), BELLY, 1.0)
	return Kit.outline(img)
