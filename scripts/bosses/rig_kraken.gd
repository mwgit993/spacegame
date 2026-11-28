extends "res://scripts/bosses/boss_rig.gd"

# STAGE 7 boss: the ABYSSAL KRAKEN, a cyber-squid with a plesiosaur (snorkel and all) in a dome on
# its mantle. Six tentacles ripple; before each volley they coil back and then lash forward as the
# shots leave their tips; its big eyes follow the player; bioluminescent spots pulse.
# Muzzles: arm0..arm5 (tentacle tips).

const SKIN: Color = Color("#6a3ab8")
const SPOT: Color = Color("#3cf4ff")
const SUCKER: Color = Color("#f0b0e0")
const SEGS: int = 8
# Tentacle bases on the rig, and their resting angle (positive lifts a tentacle's tip).
const BASES: Array[Vector3] = [
	Vector3(10.0, 0.0, -0.3), Vector3(22.0, 2.0, -0.7), Vector3(32.0, -2.0, -1.05),
	Vector3(-8.0, 2.0, -0.15), Vector3(2.0, 6.0, -0.5), Vector3(14.0, 6.0, -0.9),
]

var _tentacles: Array = []   # Array of Array[Sprite2D]
var _spots: Sprite2D
var _pupils: Array[Sprite2D] = []
var _mantle: Sprite2D


func build() -> void:
	# Back tentacles, mantle, eyes, front tentacles.
	for k: int in range(3):
		_tentacles.append(_build_tentacle(k, -2))
	_mantle = part(self, Kit.cached("kraken_mantle", _paint_mantle), Vector2(16.0, -14.0), Vector2(36.0, 42.0), 0)
	_spots = part(_mantle, Kit.cached("kraken_spots", _paint_spots), Vector2.ZERO, Vector2(36.0, 42.0), 1)
	_spots.use_parent_material = false
	for e: Vector2 in [Vector2(-12.0, -12.0), Vector2(4.0, -16.0)]:
		part(self, Kit.cached("kraken_eye", _paint_eye), e, Vector2(6.0, 6.0), 1)
		var pu: Sprite2D = part(self, Kit.cached("kraken_pupil", _paint_pupil), e, Vector2(2.0, 3.0), 2)
		_pupils.append(pu)
	for k2: int in range(3, 6):
		_tentacles.append(_build_tentacle(k2, 2))
	add_pilot(self, Vector2(24.0, -36.0), Vector2i(34, 28), 3)


func _build_tentacle(k: int, z: int) -> Array[Sprite2D]:
	var segs: Array[Sprite2D] = []
	var parent: Node2D = self
	var b: Vector3 = BASES[k]
	var at: Vector2 = Vector2(b.x, b.y)
	for i: int in range(SEGS):
		var r: float = 7.0 - float(i) * 0.6
		var s: Sprite2D = part(parent, Kit.cached("kraken_seg_%d" % i, _paint_seg.bind(r)), at, Vector2(r * 2.0, r + 1.0), z if i == 0 else 1)
		segs.append(s)
		parent = s
		at = Vector2(-r * 1.6, 0.0)
	marker(parent, "arm%d" % k, at)
	return segs


func animate(_delta: float) -> void:
	var lash: float = kick
	var coil: float = windup
	position = Vector2(hurt_k * 1.5, 0.0)
	_mantle.scale = Vector2(1.0, 1.0 + 0.04 * sin(t * 2.0))
	_spots.modulate = Color(1.0, 1.0, 1.0, 0.45 + 0.4 * (0.5 + 0.5 * sin(t * 3.0)) + 0.3 * rage)
	for k: int in range(_tentacles.size()):
		var segs: Array[Sprite2D] = _tentacles[k]
		var b: Vector3 = BASES[k]
		for i: int in range(segs.size()):
			var wave: float = sin(t * (2.2 + 0.3 * float(phase())) - float(i) * 0.8 + float(k) * 1.3) * 0.16
			var r: float = wave
			if i == 0:
				r += b.z + 0.5 * coil - 0.6 * lash + rage * 0.2 * sin(t * 12.0 + float(k))
			else:
				r += 0.06 * coil - 0.05 * lash
			segs[i].rotation = r
	# The eyes follow the player.
	var a: Vector2 = aim()
	for p: Sprite2D in _pupils:
		p.offset = Vector2(-2.0, -3.0) + a * 2.0


# --- Painting -----------------------------------------------------------------------------------

static func _paint_mantle() -> Image:
	var img: Image = Kit.blank(72, 62)
	Kit.ball(img, 40.0, 28.0, 30.0, 26.0, SKIN)
	Kit.ball(img, 22.0, 40.0, 20.0, 18.0, SKIN)
	# Fins at the top of the mantle.
	Kit.poly(img, PackedVector2Array([Vector2(56, 10), Vector2(71, 2), Vector2(66, 20)]), SKIN.lightened(0.15))
	# Cyber plating band.
	Kit.plate(img, 26, 20, 26, 6, Color("#9aa8c8"), true)
	return Kit.finish(img)


static func _paint_spots() -> Image:
	var img: Image = Kit.blank(74, 64)
	for p: Vector2 in [Vector2(46, 12), Vector2(58, 22), Vector2(40, 36), Vector2(60, 38), Vector2(24, 50), Vector2(50, 50), Vector2(14, 40)]:
		Kit.glow(img, p.x, p.y, 2.2, Color(0.2, 0.9, 1.0, 0.5), SPOT, Color.WHITE)
	return img


static func _paint_eye() -> Image:
	var img: Image = Kit.blank(12, 12)
	Kit.ball(img, 6.0, 6.0, 5.5, 5.5, Color("#ffe854"))
	return Kit.outline(img)


static func _paint_pupil() -> Image:
	var img: Image = Kit.blank(4, 6)
	Kit.rect(img, 1, 0, 2, 6, Color("#1a0a1a"))
	Kit.put(img, 0, 2, Color("#1a0a1a"))
	Kit.put(img, 3, 2, Color("#1a0a1a"))
	return img


static func _paint_seg(r: float) -> Image:
	var w: int = int(ceilf(r * 2.0)) + 2
	var img: Image = Kit.blank(w, w)
	Kit.ball(img, r + 1.0, r + 1.0, r, r, SKIN.lightened(0.05))
	Kit.ellipse(img, r + 1.0, r * 1.6 + 1.0, maxf(1.0, r * 0.45), 1.0, SUCKER)
	return Kit.outline(img)
