extends "res://scripts/bosses/boss_rig.gd"

# A checkpoint boss: a giant dinosaur robot, flown by the boss pilot (see checkpoint_bosses.gd).
# One rig, dressed per species: the head (raptor snout, triceratops frill and horns, pterodactyl
# beak and crest, stego, spinosaurus croc snout, ankylosaurus, the big T-rex head), what rides on
# its back (spikes, plates, a sail, armour spikes, wings that flap) and its tail tip (a club or
# spikes), in the lineup's paint. Its jaw drops open before every attack, the tail sways, the gun
# arm tracks the player and the legs kick with their thrusters. The final MEGA T-REX is bigger.
# Muzzles: mouth (and aimed/spread), arm, back, ring.

const FINAL_SCALE: float = 1.3

var tier: int = 0
var spec: Dictionary = {}
var final_boss: bool = false

var _species: String = "raptor"
var _body_col: Color = Color("#7d8aa8")
var _trim: Color = Color("#ff9624")
var _body: Sprite2D
var _head_j: Node2D
var _head: Sprite2D
var _jaw: Sprite2D
var _eye: Sprite2D
var _arm: Sprite2D
var _cannon: Sprite2D
var _legs: Array[Sprite2D] = []
var _flames: Array[Sprite2D] = []
var _tail: Array[Sprite2D] = []
var _wings: Array[Sprite2D] = []


func build() -> void:
	_species = String(spec.get("species", "raptor"))
	_body_col = Color(String(spec.get("body", "#7d8aa8")))
	_trim = Color(String(spec.get("trim", "#ff9624")))
	var key: String = "mech_%s_" % _species
	if final_boss:
		scale = Vector2(FINAL_SCALE, FINAL_SCALE)

	if _species == "ptero":
		for i: int in range(2):
			var w: Sprite2D = part(self, Kit.cached(key + "wing", _paint_wing.bind(_body_col, _trim)), Vector2(14.0, -16.0 - 4.0 * float(i)), Vector2(50.0, 6.0), -4 + i)
			_wings.append(w)
	# Tail: three segments chained off the hips, the last with the species' tip.
	var prev: Node2D = joint(self, Vector2(34.0, -2.0), -3)
	var sizes: Array[Vector2i] = [Vector2i(30, 16), Vector2i(26, 13), Vector2i(26, 12)]
	for i: int in range(3):
		var sz: Vector2i = sizes[i]
		var tex: Texture2D = Kit.cached(key + "tail_%d" % i, _paint_tail.bind(i, sz, _species, _body_col, _trim))
		var seg: Sprite2D = part(prev, tex, Vector2.ZERO if i == 0 else Vector2(float(sizes[i - 1].x) - 4.0, 0.0), Vector2(2.0, float(sz.y) * 0.5), -1 if i > 0 else 0)
		_tail.append(seg)
		prev = seg
	for i: int in range(2):
		var leg: Sprite2D = part(self, Kit.cached(key + "leg_%d" % i, _paint_leg.bind(_body_col.darkened(0.2 if i == 0 else 0.0), _trim)), Vector2(20.0 - 28.0 * float(i), 20.0), Vector2(12.0, 5.0), -2 if i == 0 else 1)
		var flame: Sprite2D = part(leg, Kit.cached("mech_flame", _paint_flame), Vector2(0.0, 41.0), Vector2(4.0, 0.0), -1)
		flame.use_parent_material = false
		_legs.append(leg)
		_flames.append(flame)
	_body = part(self, Kit.cached(key + "body", _paint_body.bind(_species, _body_col, _trim)), Vector2.ZERO, Vector2(42.0, 46.0), 0)
	marker(_body, "ring", Vector2(0.0, 4.0))
	_cannon = part(_body, Kit.cached(key + "cannon", _paint_cannon.bind(_trim)), Vector2(14.0, -18.0), Vector2(14.0, 6.0), -1)
	marker(_cannon, "back", Vector2(-13.0, -1.0))
	_arm = part(self, Kit.cached(key + "arm", _paint_arm.bind(_body_col, _trim)), Vector2(-24.0, 8.0), Vector2(22.0, 5.0), 2)
	marker(_arm, "arm", Vector2(-22.0, 1.0))
	_head_j = joint(self, Vector2(-34.0, -16.0), 3)
	_head = part(_head_j, Kit.cached(key + "head", _paint_head.bind(_species, _body_col, _trim)), Vector2.ZERO, Vector2(48.0, 18.0), 0)
	_jaw = part(_head, Kit.cached(key + "jaw", _paint_jaw.bind(_species, _body_col)), Vector2(-12.0, 5.0), Vector2(32.0, 2.0), -1)
	marker(_jaw, "mouth", Vector2(-28.0, 0.0))
	marker(_jaw, "aimed", Vector2(-28.0, 0.0))
	marker(_jaw, "spread", Vector2(-28.0, 0.0))
	_eye = part(_head, Kit.cached("mech_eye", _paint_eye), _eye_pos(_species) - Vector2(48.0, 18.0), Vector2(3.0, 3.0), 1)
	_eye.use_parent_material = false
	add_pilot(self, Vector2(-10.0, -26.0), Vector2i(34, 28), 4)


func animate(delta: float) -> void:
	var shud: float = rage * (1.0 if int(t * 40.0) % 2 == 0 else -1.0) * 1.5
	var bob: float = sin(t * 2.2) * 2.0
	position = Vector2(hurt_k * 1.5 + shud, bob)
	# Jaw drops open as an attack winds up, snaps on the shot.
	var open: float = maxf(windup, kick)
	_jaw.rotation = -0.55 * open
	_head_j.position = Vector2(-34.0, -16.0 + sin(t * 2.2 + 0.6) * 1.5)
	_head.rotation = -0.1 * windup + sin(t * 1.7) * 0.05 + 0.08 * kick
	# The tail sways in a travelling wave.
	for i: int in range(_tail.size()):
		_tail[i].rotation = sin(t * 2.0 - float(i) * 0.9) * (0.16 + 0.07 * float(i)) - 0.08
	for i: int in range(_legs.size()):
		_legs[i].rotation = sin(t * 2.2 + float(i) * PI) * 0.14
		_flames[i].scale = Vector2(1.0, randf_range(0.7, 1.3))
		_flames[i].visible = int(t * 30.0 + float(i)) % 3 != 0
	for i: int in range(_wings.size()):
		_wings[i].rotation = sin(t * 5.0 + float(i) * 0.5) * 0.35 - 0.1
	# The gun arm tracks the player.
	var a: Vector2 = aim()
	var want: float = clampf(wrapf(a.angle() - PI, -PI, PI), -0.6, 0.6)
	_arm.rotation = lerp_angle(_arm.rotation, want, clampf(delta * 4.0, 0.0, 1.0))
	_cannon.position = Vector2(14.0 + 3.0 * kick, -18.0)
	# The eye glows harder as the fight goes on, and strobes in a rage.
	var glow: float = 0.8 + 0.2 * sin(t * (4.0 + float(phase()) * 3.0)) + 0.5 * windup
	_eye.scale = Vector2(glow, glow) * (1.3 if phase() >= 3 else 1.0)
	_eye.modulate = Color(1.0, 0.35, 0.3) if (phase() >= 3 or rage > 0.0) and int(t * 12.0) % 2 == 0 else Color.WHITE


static func _eye_pos(species: String) -> Vector2:
	match species:
		"rex":
			return Vector2(34.0, 10.0)
		"trike":
			return Vector2(30.0, 17.0)
		"stego":
			return Vector2(30.0, 15.0)
	return Vector2(34.0, 12.0)


# --- Painting -----------------------------------------------------------------------------------

static func _paint_body(species: String, body: Color, trim: Color) -> Image:
	var img: Image = Kit.blank(84, 72)
	var dark: Color = body.darkened(0.4)
	# What rides on the back goes in first, so the torso overlaps its base.
	match species:
		"stego":
			for i: int in range(5):
				var bx: float = 18.0 + float(i) * 11.0
				var h: float = 16.0 + 6.0 * sin(float(i) * 1.3 + 0.5)
				Kit.poly(img, PackedVector2Array([Vector2(bx - 5.0, 30.0), Vector2(bx, 30.0 - h), Vector2(bx + 5.0, 30.0)]), trim if i % 2 == 0 else trim.darkened(0.3))
		"spino":
			Kit.poly(img, PackedVector2Array([Vector2(16, 30), Vector2(24, 8), Vector2(40, 1), Vector2(58, 6), Vector2(70, 30)]), trim.darkened(0.25))
			for rx: int in [24, 32, 40, 48, 56, 63]:
				Kit.line(img, Vector2(rx, 29), Vector2(rx + 2, 6 + absi(rx - 42) / 3), trim.lightened(0.3))
		"ankylo":
			for i: int in range(7):
				var sx: float = 14.0 + float(i) * 9.0
				Kit.poly(img, PackedVector2Array([Vector2(sx - 4.0, 30.0), Vector2(sx, 18.0), Vector2(sx + 4.0, 30.0)]), dark.lightened(0.15))
		"raptor", "rex":
			for i: int in range(4):
				var dx: float = 30.0 + float(i) * 10.0
				Kit.poly(img, PackedVector2Array([Vector2(dx - 3.0, 26.0), Vector2(dx + 1.0, 17.0), Vector2(dx + 4.0, 26.0)]), trim.darkened(0.2))
		"trike":
			Kit.plate(img, 30, 16, 30, 10, dark.lightened(0.1), true)
	# Torso.
	Kit.poly(img, PackedVector2Array([Vector2(4, 44), Vector2(16, 28), Vector2(52, 22), Vector2(76, 30), Vector2(83, 44), Vector2(74, 62), Vector2(42, 71), Vector2(12, 65), Vector2(2, 54)]), body)
	Kit.poly(img, PackedVector2Array([Vector2(8, 52), Vector2(40, 58), Vector2(74, 52), Vector2(70, 62), Vector2(42, 69), Vector2(14, 63)]), dark)
	for pl: Rect2i in [Rect2i(20, 34, 16, 12), Rect2i(40, 31, 18, 14), Rect2i(60, 36, 12, 12)]:
		Kit.plate(img, pl.position.x, pl.position.y, pl.size.x, pl.size.y, body.lightened(0.06), true)
	Kit.rect(img, 10, 48, 66, 2, trim)
	for vx: int in [24, 30, 36, 50, 56]:
		Kit.rect(img, vx, 60, 3, 4, dark.darkened(0.35))
	Kit.glow(img, 66.0, 42.0, 3.0, trim.darkened(0.3), trim, Color.WHITE)
	return Kit.finish(img)


static func _paint_head(species: String, body: Color, trim: Color) -> Image:
	var img: Image = Kit.blank(56, 36)
	var dark: Color = body.darkened(0.4)
	var pts: PackedVector2Array
	match species:
		"trike":
			Kit.ellipse(img, 46.0, 14.0, 10.0, 14.0, trim.darkened(0.25))
			Kit.ellipse(img, 46.0, 14.0, 7.0, 11.0, dark.lightened(0.1))
			pts = PackedVector2Array([Vector2(4, 20), Vector2(18, 13), Vector2(36, 12), Vector2(46, 17), Vector2(46, 29), Vector2(22, 31), Vector2(6, 27)])
		"ptero":
			Kit.poly(img, PackedVector2Array([Vector2(38, 12), Vector2(54, 0), Vector2(56, 4), Vector2(46, 16)]), trim)
			pts = PackedVector2Array([Vector2(0, 19), Vector2(28, 13), Vector2(44, 10), Vector2(52, 14), Vector2(50, 24), Vector2(28, 23)])
		"stego":
			pts = PackedVector2Array([Vector2(8, 19), Vector2(22, 13), Vector2(38, 12), Vector2(46, 18), Vector2(42, 27), Vector2(16, 27)])
		"spino":
			pts = PackedVector2Array([Vector2(0, 19), Vector2(12, 15), Vector2(40, 10), Vector2(52, 14), Vector2(52, 25), Vector2(26, 26), Vector2(4, 24)])
		"ankylo":
			for sx: float in [14.0, 26.0, 38.0]:
				Kit.poly(img, PackedVector2Array([Vector2(sx - 3.0, 12.0), Vector2(sx, 5.0), Vector2(sx + 3.0, 12.0)]), dark.lightened(0.2))
			pts = PackedVector2Array([Vector2(4, 17), Vector2(18, 11), Vector2(42, 10), Vector2(52, 16), Vector2(50, 27), Vector2(16, 29), Vector2(4, 25)])
		"rex":
			pts = PackedVector2Array([Vector2(1, 14), Vector2(16, 5), Vector2(44, 3), Vector2(55, 10), Vector2(55, 28), Vector2(34, 31), Vector2(3, 26)])
		_:
			pts = PackedVector2Array([Vector2(0, 17), Vector2(14, 10), Vector2(38, 6), Vector2(50, 11), Vector2(50, 25), Vector2(30, 26), Vector2(6, 24)])
	Kit.poly(img, pts, body)
	# Upper teeth along the mouth line, a trim stripe and the eye socket.
	var mouth_y: int = 25 if species == "rex" else 22
	for tx: int in range(6, 34, 4):
		Kit.poly(img, PackedVector2Array([Vector2(tx, mouth_y), Vector2(tx + 1.5, mouth_y + 3), Vector2(tx + 3, mouth_y)]), Color("#f4f0e8"))
	Kit.rect(img, 12, 16 if species != "rex" else 12, 26, 2, trim)
	var eye: Vector2 = _eye_pos(species)
	Kit.ellipse(img, eye.x, eye.y, 4.0, 3.0, Color("#160c18"))
	if species == "trike":
		Kit.poly(img, PackedVector2Array([Vector2(24, 14), Vector2(0, 6), Vector2(26, 11)]), Color("#ece4d0"))
		Kit.poly(img, PackedVector2Array([Vector2(32, 13), Vector2(8, 3), Vector2(34, 10)]), Color("#ece4d0"))
		Kit.poly(img, PackedVector2Array([Vector2(8, 20), Vector2(0, 15), Vector2(11, 17)]), Color("#ece4d0"))
	return Kit.finish(img)


static func _paint_jaw(species: String, body: Color) -> Image:
	var img: Image = Kit.blank(36, 12)
	var w: float = 36.0 if species == "rex" else 32.0
	Kit.poly(img, PackedVector2Array([Vector2(36.0 - w, 2), Vector2(32, 0), Vector2(36, 4), Vector2(30, 10), Vector2(38.0 - w, 9)]), body.darkened(0.15))
	for tx: int in range(int(38.0 - w) + 2, 30, 4):
		Kit.poly(img, PackedVector2Array([Vector2(tx, 2), Vector2(tx + 1.5, -1), Vector2(tx + 3, 2)]), Color("#f4f0e8"))
	return Kit.finish(img)


static func _paint_leg(body: Color, trim: Color) -> Image:
	var img: Image = Kit.blank(24, 46)
	Kit.ellipse(img, 12.0, 9.0, 10.0, 9.0, body)
	Kit.poly(img, PackedVector2Array([Vector2(6, 14), Vector2(18, 14), Vector2(16, 34), Vector2(8, 34)]), body.darkened(0.2))
	Kit.rect(img, 7, 22, 10, 2, trim)
	Kit.poly(img, PackedVector2Array([Vector2(2, 34), Vector2(20, 34), Vector2(22, 40), Vector2(0, 40)]), body.darkened(0.3))
	Kit.rect(img, 8, 40, 8, 4, Color("#2a3048"))
	Kit.glow(img, 12.0, 42.0, 2.0, Color("#3c8cff"), Color("#28e8ff"), Color.WHITE)
	return Kit.finish(img)


static func _paint_arm(body: Color, trim: Color) -> Image:
	var img: Image = Kit.blank(28, 12)
	Kit.rect(img, 0, 3, 18, 5, Color("#3a4058"))
	Kit.rect(img, 0, 3, 3, 5, trim)
	Kit.ellipse(img, 22.0, 5.0, 5.5, 5.0, body)
	return Kit.finish(img)


static func _paint_cannon(trim: Color) -> Image:
	var img: Image = Kit.blank(20, 12)
	Kit.rect(img, 0, 3, 14, 5, Color("#3a4058"))
	Kit.rect(img, 0, 3, 2, 5, trim)
	Kit.plate(img, 10, 1, 9, 10, Color("#5a6280"), true)
	return Kit.finish(img)


static func _paint_tail(i: int, sz: Vector2i, species: String, body: Color, trim: Color) -> Image:
	var img: Image = Kit.blank(sz.x + 6, sz.y + 8)
	var h: float = float(sz.y)
	var oy: float = 4.0
	if i < 2:
		Kit.poly(img, PackedVector2Array([Vector2(0, oy), Vector2(float(sz.x), oy + 2.0), Vector2(float(sz.x), oy + h - 2.0), Vector2(0, oy + h)]), body.darkened(0.08 * float(i)))
		Kit.rect(img, 2, int(oy + h * 0.5), sz.x - 4, 1, trim)
	else:
		Kit.poly(img, PackedVector2Array([Vector2(0, oy), Vector2(float(sz.x) - 2.0, oy + h * 0.5), Vector2(0, oy + h)]), body.darkened(0.16))
		match species:
			"ankylo":
				Kit.ball(img, float(sz.x) - 5.0, oy + h * 0.5, 6.0, 6.0, body.darkened(0.25))
			"stego":
				for sx: float in [8.0, 15.0]:
					Kit.poly(img, PackedVector2Array([Vector2(sx - 2.0, oy + 2.0), Vector2(sx + 2.0, 0.0), Vector2(sx + 2.0, oy + 2.0)]), Color("#ece4d0"))
					Kit.poly(img, PackedVector2Array([Vector2(sx - 2.0, oy + h - 2.0), Vector2(sx + 2.0, oy + h + 4.0), Vector2(sx + 2.0, oy + h - 2.0)]), Color("#ece4d0"))
	return Kit.finish(img)


static func _paint_wing(body: Color, trim: Color) -> Image:
	var img: Image = Kit.blank(56, 44)
	Kit.poly(img, PackedVector2Array([Vector2(52, 4), Vector2(0, 40), Vector2(22, 34), Vector2(34, 42), Vector2(54, 14)]), body.darkened(0.25))
	for r: Vector2 in [Vector2(10, 37), Vector2(24, 36), Vector2(38, 30)]:
		Kit.line(img, Vector2(52, 6), r, trim.darkened(0.2))
	return Kit.finish(img)


static func _paint_eye() -> Image:
	var img: Image = Kit.blank(7, 7)
	Kit.glow(img, 3.5, 3.5, 3.4, Color("#a01828"), Color("#ff3c4e"), Color("#fff0c0"))
	return img


static func _paint_flame() -> Image:
	var img: Image = Kit.blank(8, 12)
	Kit.poly(img, PackedVector2Array([Vector2(0, 0), Vector2(8, 0), Vector2(4, 12)]), Color("#28a8ff"))
	Kit.poly(img, PackedVector2Array([Vector2(2, 0), Vector2(6, 0), Vector2(4, 7)]), Color("#d8f8ff"))
	return img
