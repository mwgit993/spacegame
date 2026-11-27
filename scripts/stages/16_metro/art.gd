extends RefCounted

# STAGE 16 sprites (worker thread: Images only). Gunmetal city machines trimmed with hot-pink
# and teal neon; police in white and navy. Every key starts with the stage id (or "boss_<id>").

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const METAL: Array[Color] = [Color("#16142a"), Color("#2e2c4c"), Color("#5a5a82"), Color("#a8aad0")]
const POLICE: Array[Color] = [Color("#1a2448"), Color("#30448a"), Color("#c8d0e8"), Color("#ffffff")]
const PINK: Color = Color("#ff3c9c")
const PINK_DIM: Color = Color("#8a1c58")
const TEAL: Color = Color("#30f0e0")
const TEAL_DIM: Color = Color("#148078")
const AMBER: Color = Color("#ffb040")
const RED: Color = Color("#ff3030")
const MIS_RAMP: Array[Color] = [Color("#5a1030"), Color("#c02060"), Color("#ff6aa8"), Color("#ffd0e4")]
const RIDER: Array[Color] = [Color("#1a1020"), Color("#3a2440"), Color("#6a4870"), Color("#a080a8")]
const BLUE: Color = Color("#3c78ff")


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(2):
		out[id + "_police_%d" % f] = Kit.outline(_police(f))
		out[id + "_biker_%d" % f] = Kit.outline(_biker(f))
	for f2: int in range(4):
		out[id + "_board_%d" % f2] = Kit.outline(_board(f2))

	var shot: Image = Kit.blank(7, 7)
	Kit.disc(shot, 3.5, 3.5, 3.5, Color(1.0, 0.75, 0.2, 0.5))
	Kit.disc(shot, 3.5, 3.5, 2.5, Color("#ffe060"))
	Kit.disc(shot, 3.0, 3.0, 1.2, Color.WHITE)
	out[id + "_shot"] = shot
	# Missile warhead (round, since enemy shots don't turn to face their heading).
	var mis: Image = Kit.blank(9, 9)
	Kit.disc(mis, 4.5, 4.5, 4.5, Color(1.0, 0.3, 0.5, 0.45))
	Kit.ball(mis, 4.5, 4.5, 3.4, 3.4, MIS_RAMP)
	Kit.put(mis, 4, 4, Color.WHITE)
	out[id + "_missile"] = mis

	out[id + "_scout"] = Kit.outline(_g_scout())
	out[id + "_swooper"] = Kit.outline(_g_swooper())
	out[id + "_sniper"] = Kit.outline(_g_sniper())
	out[id + "_cruiser"] = Kit.outline(_g_cruiser())
	for f3: int in range(3):
		out["boss_%s_%d" % [id, f3]] = Kit.outline(_titan(f3))
	return out


static func _poly(img: Image, pts: Array[Vector2], col: Color) -> void:
	Painter.poly(img, PackedVector2Array(pts), col)


static func _over(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.3:
		img.set_pixel(x, y, col)


# --- enemies ---------------------------------------------------------------------------------------

# Police cruiser: a flying patrol car, nose left, light bar on the roof (the lights themselves
# are drawn live so they can flash), searchlight under the nose.
static func _police(frame: int) -> Image:
	var img: Image = Kit.blank(28, 14)
	_poly(img, [Vector2(0, 8), Vector2(4, 5), Vector2(9, 5), Vector2(12, 1), Vector2(21, 1), Vector2(25, 5), Vector2(28, 6), Vector2(28, 11), Vector2(2, 11)], POLICE[1])
	_poly(img, [Vector2(1, 8), Vector2(4, 6), Vector2(27, 6), Vector2(27, 8)], POLICE[2])
	_poly(img, [Vector2(10, 5), Vector2(13, 2), Vector2(20, 2), Vector2(23, 5)], Color("#1a3050"))
	Kit.line(img, Vector2(13, 2), Vector2(16, 2), Color("#8ab0e0"))
	Kit.rect(img, 2, 11, 24, 2, POLICE[0])
	Kit.rect(img, 5, 12, 5, 2, METAL[1])
	Kit.rect(img, 18, 12, 5, 2, METAL[1])
	Kit.rect(img, 14, 0, 4, 1, Color("#202020"))
	Kit.put(img, 0, 8, Color("#fff8c0"))
	Kit.put(img, 1, 9, Color("#fff8c0"))
	Kit.rect(img, 27, 7, 1, 2, RED)
	Kit.line(img, Vector2(6, 9), Vector2(24, 9), POLICE[0])
	Kit.rect(img, 7, 13, 3, 1, TEAL if frame == 0 else TEAL_DIM)
	Kit.rect(img, 19, 13, 3, 1, TEAL if frame == 1 else TEAL_DIM)
	return img


# Hover-bike gang member: low bike, rider hunched forward, neon underglow (frame 1 flickers).
static func _biker(frame: int) -> Image:
	var img: Image = Kit.blank(22, 12)
	_poly(img, [Vector2(0, 7), Vector2(5, 5), Vector2(16, 5), Vector2(22, 7), Vector2(20, 10), Vector2(3, 10)], METAL[1])
	Kit.line(img, Vector2(5, 5), Vector2(16, 5), METAL[3])
	Kit.rect(img, 16, 6, 5, 2, METAL[2])
	Kit.put(img, 0, 7, Color("#fff8c0"))
	# rider
	Kit.ball(img, 11.0, 3.0, 3.6, 2.6, RIDER)
	Kit.disc(img, 7.5, 2.5, 2.0, Color("#202030"))
	Kit.rect(img, 6, 2, 2, 1, PINK)
	Kit.line(img, Vector2(9, 4), Vector2(5, 6), Color("#3a2440"))
	var glow: Color = PINK if frame == 0 else Color("#ff8ac8")
	Kit.rect(img, 3, 10, 16, 1, glow)
	Kit.rect(img, 5, 11, 12, 1, Color(1.0, 0.24, 0.6, 0.7))
	Kit.rect(img, 21, 7, 1, 2, TEAL)
	return img


# Billboard drone: a hovering ad screen in a metal frame. Frames 0-2 are three looping ads;
# frame 3 is the red warning screen (the attack telegraph).
static func _board(frame: int) -> Image:
	var img: Image = Kit.blank(30, 24)
	Kit.rect(img, 0, 0, 30, 20, METAL[1])
	Kit.rect(img, 0, 0, 30, 1, METAL[3])
	Kit.rect(img, 0, 19, 30, 1, METAL[0])
	Kit.rect(img, 2, 2, 26, 16, Color("#06040e"))
	match frame:
		0:  # a smiling mascot face
			Kit.disc(img, 15.0, 10.0, 6.5, PINK)
			Kit.disc(img, 15.0, 10.0, 5.2, Color("#ffd0e4"))
			Kit.rect(img, 12, 8, 2, 2, Color("#200818"))
			Kit.rect(img, 17, 8, 2, 2, Color("#200818"))
			Kit.line(img, Vector2(12, 12), Vector2(15, 14), Color("#200818"))
			Kit.line(img, Vector2(15, 14), Vector2(18, 12), Color("#200818"))
			for s: int in range(4):
				Kit.put(img, 4 + s * 7, 3, AMBER)
		1:  # a soda can with a starburst
			Kit.rect(img, 12, 4, 7, 12, TEAL)
			Kit.rect(img, 12, 4, 2, 12, Color("#b0fff8"))
			Kit.rect(img, 12, 8, 7, 3, PINK)
			Kit.rect(img, 13, 3, 5, 1, METAL[3])
			for r: int in range(6):
				var d: Vector2 = Vector2.from_angle(float(r) * TAU / 6.0)
				Kit.line(img, Vector2(6, 6) + d * 1.5, Vector2(6, 6) + d * 3.5, AMBER)
		2:  # glyph columns and a price tag
			for col: int in range(4):
				for row: int in range(3):
					var gx: int = 4 + col * 6
					var gy: int = 4 + row * 5
					Kit.rect(img, gx, gy, 3, 1, TEAL)
					Kit.rect(img, gx + 1, gy, 1, 3, TEAL)
					if (col + row) % 2 == 0:
						Kit.rect(img, gx, gy + 2, 3, 1, TEAL)
			Kit.rect(img, 20, 13, 7, 4, AMBER)
		_:  # warning: red screen with a big "!"
			Kit.rect(img, 2, 2, 26, 16, Color("#8a0c18"))
			for st: int in range(0, 26, 4):
				Kit.line(img, Vector2(2 + st, 17), Vector2(6 + st, 2), Color("#b01828"))
			Kit.rect(img, 14, 4, 3, 8, Color.WHITE)
			Kit.rect(img, 14, 14, 3, 2, Color.WHITE)
	# scanlines on the screen
	for y: int in range(3, 18, 2):
		for x: int in range(2, 28):
			var c: Color = img.get_pixel(x, y)
			img.set_pixel(x, y, c.darkened(0.25))
	# antigrav pods under the frame
	Kit.rect(img, 4, 20, 6, 2, METAL[2])
	Kit.rect(img, 20, 20, 6, 2, METAL[2])
	Kit.rect(img, 5, 22, 4, 2, TEAL_DIM)
	Kit.rect(img, 21, 22, 4, 2, TEAL_DIM)
	return img


# --- generic re-skins ------------------------------------------------------------------------------

static func _g_scout() -> Image:
	var img: Image = Kit.blank(14, 10)
	_poly(img, [Vector2(0, 5), Vector2(4, 2), Vector2(12, 2), Vector2(14, 5), Vector2(12, 8), Vector2(4, 8)], METAL[1])
	Kit.line(img, Vector2(4, 2), Vector2(12, 2), METAL[3])
	Kit.rect(img, 4, 4, 6, 2, PINK)
	Kit.put(img, 1, 5, Color("#fff8c0"))
	Kit.rect(img, 3, 9, 8, 1, TEAL)
	return img


static func _g_swooper() -> Image:
	var img: Image = Kit.blank(20, 13)
	_poly(img, [Vector2(4, 6), Vector2(16, 0), Vector2(19, 1), Vector2(13, 6)], METAL[1])
	_poly(img, [Vector2(4, 7), Vector2(13, 7), Vector2(19, 12), Vector2(16, 13)], METAL[1])
	Kit.line(img, Vector2(5, 6), Vector2(16, 0), PINK)
	Kit.line(img, Vector2(5, 7), Vector2(16, 13), PINK_DIM)
	_poly(img, [Vector2(0, 6), Vector2(4, 4), Vector2(15, 5), Vector2(15, 8), Vector2(4, 9)], METAL[2])
	Kit.rect(img, 5, 5, 4, 2, Color("#1a3050"))
	Kit.rect(img, 15, 6, 2, 2, TEAL)
	return img


static func _g_sniper() -> Image:
	var img: Image = Kit.blank(16, 16)
	Kit.rect(img, 3, 1, 12, 14, METAL[1])
	Kit.rect(img, 3, 1, 12, 1, METAL[3])
	Kit.rect(img, 3, 1, 1, 14, METAL[2])
	Kit.disc(img, 6.0, 8.0, 3.6, Color("#06040e"))
	Kit.disc(img, 6.0, 8.0, 2.2, RED)
	Kit.put(img, 5, 7, Color.WHITE)
	Kit.rect(img, 11, 3, 3, 1, TEAL)
	Kit.rect(img, 11, 12, 3, 1, PINK)
	Kit.rect(img, 0, 7, 3, 2, METAL[2])
	return img


static func _g_cruiser() -> Image:
	var img: Image = Kit.blank(30, 18)
	_poly(img, [Vector2(0, 9), Vector2(6, 3), Vector2(26, 2), Vector2(30, 6), Vector2(30, 13), Vector2(26, 16), Vector2(6, 15)], METAL[1])
	_poly(img, [Vector2(3, 8), Vector2(7, 4), Vector2(25, 3), Vector2(25, 7)], METAL[2])
	Kit.line(img, Vector2(6, 3), Vector2(26, 2), METAL[3])
	Kit.rect(img, 10, 9, 14, 3, Color("#06040e"))
	for x: int in range(11, 24, 2):
		Kit.put(img, x, 10, PINK if x % 4 == 1 else TEAL)
	Kit.rect(img, 28, 6, 2, 6, TEAL)
	Kit.rect(img, 2, 15, 22, 1, PINK)
	return img


# --- CORPORATE TITAN: APEX-9 -------------------------------------------------------------------------
# A skyscraper on legs: a tower torso with lit office floors and a neon corporate sigil, a
# turret head with a sweeping visor, missile pods on the shoulders and a gatling arm. Frames
# 0/1: the sigil and windows flicker; frame 2: pods open, muzzles blazing.

static func _titan(frame: int) -> Image:
	var img: Image = BossPainter._new_img(114, 168)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 16160
	# legs / thruster struts
	BossPainter._thick_line(img, Vector2(66, 130), Vector2(56, 160), 4, METAL[1], METAL[2])
	BossPainter._thick_line(img, Vector2(84, 130), Vector2(90, 160), 4, METAL[1], METAL[2])
	Kit.rect(img, 48, 158, 18, 6, METAL[0])
	Kit.rect(img, 84, 158, 16, 6, METAL[0])
	Kit.rect(img, 50, 164, 14, 3, TEAL if frame != 1 else TEAL_DIM)
	Kit.rect(img, 86, 164, 12, 3, TEAL if frame != 1 else TEAL_DIM)
	# tower torso, slightly tapered, with setbacks
	_poly(img, [Vector2(52, 30), Vector2(98, 26), Vector2(102, 136), Vector2(48, 138)], METAL[0])
	_poly(img, [Vector2(55, 34), Vector2(95, 30), Vector2(98, 132), Vector2(52, 134)], METAL[1])
	Kit.line(img, Vector2(52, 30), Vector2(98, 26), METAL[3])
	Kit.line(img, Vector2(55, 34), Vector2(52, 134), METAL[2])
	# lit office floors
	for fy: int in range(40, 128, 5):
		for fx: int in range(58, 94, 3):
			var on: bool = rng.randf() < 0.55
			if on:
				var c: Color = AMBER if rng.randf() < 0.75 else Color("#fff0c0")
				if frame == 1 and rng.randf() < 0.2:
					c = Color("#5a3a18")
				Kit.rect(img, fx, fy, 2, 2, c.darkened(0.35))
	# neon corporate sigil: a triangle "A" in a ring
	var sig: Vector2 = Vector2(75.0, 74.0)
	var sig_col: Color = PINK if frame != 1 else Color("#ff8ac8")
	BossPainter._circle(img, int(sig.x), int(sig.y), 13, Color("#100818"))
	for a: int in range(48):
		var d: Vector2 = Vector2.from_angle(float(a) * TAU / 48.0) * 12.0
		Kit.put(img, int(sig.x + d.x), int(sig.y + d.y), TEAL)
	Kit.line(img, sig + Vector2(-7, 6), sig + Vector2(0, -8), sig_col)
	Kit.line(img, sig + Vector2(0, -8), sig + Vector2(7, 6), sig_col)
	Kit.line(img, sig + Vector2(-4, 1), sig + Vector2(4, 1), sig_col)
	Kit.line(img, sig + Vector2(-6, 6), sig + Vector2(0, -7), sig_col)
	# roof crown and antenna spire
	_poly(img, [Vector2(58, 26), Vector2(92, 24), Vector2(86, 14), Vector2(64, 15)], METAL[1])
	Kit.line(img, Vector2(64, 15), Vector2(86, 14), METAL[3])
	Kit.line(img, Vector2(76, 14), Vector2(76, 0), METAL[2])
	Kit.put(img, 76, 0, RED)
	Kit.put(img, 76, 1, RED)
	# turret head on the left of the crown, with a sweeping visor
	Kit.ball(img, 50.0, 24.0, 13.0, 10.0, METAL)
	Kit.rect(img, 37, 21, 18, 5, Color("#06040e"))
	Kit.rect(img, 38, 22, 16, 3, RED if frame == 2 else Color("#c01828"))
	Kit.rect(img, 40 + frame * 4, 22, 4, 3, Color("#ffd0d0"))
	# shoulder missile pods
	for pod: int in range(2):
		var py: int = 34 if pod == 0 else 112
		Kit.rect(img, 34, py, 22, 14, METAL[1])
		Kit.rect(img, 34, py, 22, 1, METAL[3])
		for tube: int in range(3):
			var ty: int = py + 2 + tube * 4
			Kit.rect(img, 35, ty, 4, 3, Color("#06040e"))
			if frame == 2:
				Kit.rect(img, 36, ty, 2, 3, Color("#ff6aa8"))
		Kit.rect(img, 52, py + 3, 3, 8, PINK_DIM if frame != 2 else PINK)
	# gatling arm reaching forward
	BossPainter._thick_line(img, Vector2(54, 82), Vector2(30, 88), 4, METAL[1], METAL[2])
	Kit.rect(img, 8, 82, 24, 12, METAL[1])
	Kit.rect(img, 8, 82, 24, 1, METAL[3])
	for bar: int in range(3):
		Kit.rect(img, 0, 84 + bar * 3, 9, 2, METAL[2] if bar != 1 else METAL[3])
	if frame == 2:
		Kit.disc(img, 2.0, 88.0, 3.5, Color(1.0, 0.85, 0.3, 0.9))
		Kit.disc(img, 2.0, 88.0, 2.0, Color.WHITE)
	Kit.rect(img, 14, 85, 12, 2, TEAL)
	# neon trim down the tower edges
	for y2: int in range(36, 132, 2):
		Kit.put(img, 97, y2, TEAL if (y2 / 2 + frame) % 6 != 0 else TEAL_DIM)
		Kit.put(img, 53, y2 + 1, PINK_DIM)
	return img
