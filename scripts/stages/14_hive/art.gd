extends RefCounted

# STAGE 14 sprites (worker thread: Images only). Hive creatures are plum chitin with amber
# abdomens and acid-green glands; every key starts with the stage id (or "boss_<id>").

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const CHITIN: Array[Color] = [Color("#24101c"), Color("#4e2434"), Color("#80404a"), Color("#c07a66")]
const ARMOR: Array[Color] = [Color("#2a1418"), Color("#5c3030"), Color("#94584a"), Color("#e0a47a")]
const AMBER: Array[Color] = [Color("#5e320a"), Color("#a86410"), Color("#e8a028"), Color("#ffe08a")]
const ACID: Array[Color] = [Color("#2a5a10"), Color("#5cae1c"), Color("#a8f040"), Color("#eaffb0")]
const ACID_DIM: Array[Color] = [Color("#1e3a0e"), Color("#3a6a16"), Color("#62a82a"), Color("#a8e070")]
const SHELL: Array[Color] = [Color("#3c2c14"), Color("#6c5426"), Color("#a08a48"), Color("#d8c47e")]
const GRUB: Array[Color] = [Color("#5a3c30"), Color("#9a7856"), Color("#d2b484"), Color("#fff0c8")]
const RESIN: Array[Color] = [Color("#3a1e08"), Color("#7a4410"), Color("#b87018"), Color("#f0b040")]
const WING: Color = Color(0.82, 0.9, 1.0, 0.5)
const WING_HI: Color = Color(1.0, 1.0, 1.0, 0.75)
const EYE: Color = Color("#8cff4c")
const EYE_HI: Color = Color("#f0ffc0")
const EYE_RED: Color = Color("#ff3c3c")


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(3):
		out[id + "_drone_%d" % f] = Kit.outline(_drone(f))
	for f2: int in range(2):
		out[id + "_guard_%d" % f2] = Kit.outline(_guard(f2))
	for f3: int in range(3):
		out[id + "_egg_%d" % f3] = Kit.outline(_egg(f3))
	for f4: int in range(2):
		out[id + "_larva_%d" % f4] = Kit.outline(_larva(f4))

	var shot: Image = Kit.blank(7, 7)
	Kit.disc(shot, 3.5, 3.5, 3.5, Color(0.55, 1.0, 0.2, 0.45))
	Kit.disc(shot, 3.5, 3.5, 2.5, Color("#b8ff48"))
	Kit.disc(shot, 3.0, 3.0, 1.2, Color.WHITE)
	out[id + "_shot"] = shot
	var glob: Image = Kit.blank(9, 9)
	Kit.disc(glob, 4.5, 4.5, 4.5, Color("#2a5a10"))
	Kit.ball(glob, 4.5, 4.5, 3.6, 3.6, ACID)
	Kit.put(glob, 3, 3, Color.WHITE)
	out[id + "_glob"] = glob

	out[id + "_scout"] = Kit.outline(_g_scout())
	out[id + "_swooper"] = Kit.outline(_g_swooper())
	out[id + "_sniper"] = Kit.outline(_g_sniper())
	out[id + "_cruiser"] = Kit.outline(_g_cruiser())

	for f5: int in range(3):
		out["boss_%s_%d" % [id, f5]] = Kit.outline(_queen(f5))
	return out


# --- helpers -------------------------------------------------------------------------------------

static func _ell(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	for y: int in range(int(floorf(cy - ry)), int(ceilf(cy + ry)) + 1):
		for x: int in range(int(floorf(cx - rx)), int(ceilf(cx + rx)) + 1):
			var nx: float = (float(x) + 0.5 - cx) / rx
			var ny: float = (float(y) + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				Kit.put(img, x, y, col)


# Recolours pixels that are already painted (stripes, plates, veins on a body).
static func _over(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.3:
		img.set_pixel(x, y, col)


static func _over_line(img: Image, a: Vector2, b: Vector2, col: Color) -> void:
	var steps: int = int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i: int in range(steps + 1):
		var p: Vector2 = a.lerp(b, 0.0 if steps == 0 else float(i) / float(steps))
		_over(img, int(roundf(p.x)), int(roundf(p.y)), col)


static func _leg(img: Image, pts: PackedVector2Array, col: Color) -> void:
	for i: int in range(pts.size() - 1):
		Kit.line(img, pts[i], pts[i + 1], col)


# --- enemies ---------------------------------------------------------------------------------------

# Drone: frame 0 wings up, 1 wings down, 2 diving (red eye, wings swept back).
static func _drone(frame: int) -> Image:
	var img: Image = Kit.blank(17, 13)
	if frame == 0:
		_ell(img, 6.5, 3.2, 3.0, 2.6, WING)
		_ell(img, 10.0, 2.8, 3.4, 2.4, WING)
		Kit.line(img, Vector2(6, 5), Vector2(9, 1), WING_HI)
	elif frame == 1:
		_ell(img, 6.5, 10.4, 3.0, 1.7, WING)
		_ell(img, 10.0, 10.8, 3.4, 1.7, WING)
		Kit.line(img, Vector2(6, 9), Vector2(10, 11), WING_HI)
	else:
		_ell(img, 11.5, 3.6, 4.6, 1.5, WING)
		_ell(img, 11.5, 9.4, 4.6, 1.5, WING)
	Kit.ball(img, 11.5, 6.5, 4.2, 3.0, AMBER)
	for sx: int in [10, 12, 14]:
		_over_line(img, Vector2(sx, 3), Vector2(sx, 10), CHITIN[0])
	Kit.put(img, 16, 7, CHITIN[1])
	Kit.ball(img, 6.5, 6.5, 2.6, 2.4, CHITIN)
	Kit.ball(img, 3.0, 6.4, 2.4, 2.2, CHITIN)
	var eye: Color = EYE_RED if frame == 2 else EYE
	Kit.put(img, 2, 6, eye)
	Kit.put(img, 2, 5, EYE_HI if frame < 2 else Color("#ffd0a0"))
	Kit.put(img, 1, 6, eye)
	Kit.put(img, 0, 8, CHITIN[2])
	Kit.line(img, Vector2(5, 8), Vector2(4, 11), CHITIN[1])
	Kit.line(img, Vector2(7, 8), Vector2(8, 11), CHITIN[1])
	return img


# Acid guard: armoured head with mandibles, an acid gland on its back. Frame 1: mandibles open
# and the gland flares (the telegraph, and when it's vulnerable).
static func _guard(frame: int) -> Image:
	var img: Image = Kit.blank(28, 22)
	_leg(img, PackedVector2Array([Vector2(12, 14), Vector2(9, 18), Vector2(7, 21)]), CHITIN[1])
	_leg(img, PackedVector2Array([Vector2(15, 15), Vector2(15, 19), Vector2(13, 21)]), CHITIN[1])
	_leg(img, PackedVector2Array([Vector2(18, 14), Vector2(21, 18), Vector2(23, 21)]), CHITIN[1])
	Kit.ball(img, 20.5, 10.5, 6.5, 6.5, CHITIN)
	Kit.ball(img, 21.0, 9.0, 4.4, 3.8, ACID if frame == 1 else ACID_DIM)
	_over_line(img, Vector2(18, 4), Vector2(18, 16), CHITIN[0])
	_over_line(img, Vector2(23, 4), Vector2(24, 16), CHITIN[0])
	if frame == 1:
		Kit.put(img, 20, 7, Color.WHITE)
	Kit.ball(img, 13.0, 11.0, 4.2, 4.2, CHITIN)
	Kit.ball(img, 7.5, 10.0, 6.2, 5.6, ARMOR)
	Kit.line(img, Vector2(3, 6), Vector2(10, 5), ARMOR[3])
	_over_line(img, Vector2(6, 5), Vector2(9, 14), ARMOR[0])
	Kit.put(img, 3, 8, EYE)
	Kit.put(img, 4, 8, EYE)
	Kit.put(img, 4, 7, EYE_HI)
	Kit.put(img, 6, 8, EYE)
	if frame == 0:
		Kit.line(img, Vector2(3, 13), Vector2(0, 14), ARMOR[2])
		Kit.line(img, Vector2(3, 14), Vector2(1, 16), ARMOR[2])
		Kit.put(img, 0, 15, ARMOR[3])
	else:
		Kit.line(img, Vector2(3, 11), Vector2(0, 9), ARMOR[2])
		Kit.put(img, 0, 10, ARMOR[3])
		Kit.line(img, Vector2(3, 15), Vector2(0, 18), ARMOR[2])
		Kit.put(img, 1, 18, ARMOR[3])
		Kit.disc(img, 2.0, 13.5, 1.6, ACID[2])
		Kit.put(img, 1, 13, ACID[3])
		Kit.put(img, 2, 16, ACID[2])
	return img


# Egg sac on a resin base (the floor version; the ceiling one is flipped). Frames: 0 dim,
# 1 the embryo glowing, 2 cracking open.
static func _egg(frame: int) -> Image:
	var img: Image = Kit.blank(15, 19)
	Kit.ball(img, 7.5, 16.4, 6.6, 2.4, RESIN)
	Kit.ball(img, 7.5, 8.6, 5.4, 7.6, SHELL)
	var glow: Color = Color(0.66, 1.0, 0.3, 0.55 if frame == 0 else 0.9)
	_ell(img, 7.5, 9.5, 2.6, 3.6, Color(0.24, 0.36, 0.1) if frame == 0 else Color(0.4, 0.62, 0.16))
	_ell(img, 7.0, 9.0, 1.4, 2.0, glow)
	Kit.line(img, Vector2(3, 5), Vector2(4, 12), SHELL[1])
	Kit.line(img, Vector2(11, 4), Vector2(11, 12), SHELL[1])
	Kit.line(img, Vector2(6, 2), Vector2(8, 4), SHELL[3])
	if frame == 2:
		Kit.line(img, Vector2(4, 4), Vector2(6, 6), ACID[2])
		Kit.line(img, Vector2(6, 6), Vector2(5, 8), ACID[2])
		Kit.line(img, Vector2(10, 3), Vector2(9, 6), ACID[2])
		Kit.line(img, Vector2(9, 6), Vector2(11, 8), ACID[2])
		Kit.put(img, 7, 1, Color(0, 0, 0, 0))
		Kit.put(img, 8, 1, Color(0, 0, 0, 0))
		Kit.put(img, 7, 2, ACID[3])
	return img


static func _larva(frame: int) -> Image:
	var img: Image = Kit.blank(17, 11)
	var sign_f: float = 1.0 if frame == 0 else -1.0
	for s: int in range(4, 0, -1):
		var wig: float = sin(float(s) * 1.6) * 1.2 * sign_f
		var r: float = 3.0 - float(s) * 0.3
		Kit.ball(img, 3.5 + float(s) * 3.0, 5.5 + wig, r, r, GRUB)
		_over_line(img, Vector2(2.0 + float(s) * 3.0, 3.0 + wig), Vector2(2.0 + float(s) * 3.0, 8.0 + wig), GRUB[0])
		Kit.put(img, int(3.5 + float(s) * 3.0), int(4.5 + wig), Color(0.6, 1.0, 0.3, 0.95) if s % 2 == 1 else GRUB[3])
	Kit.ball(img, 3.0, 5.5, 2.6, 2.6, CHITIN)
	Kit.put(img, 1, 5, EYE)
	Kit.put(img, 2, 4, EYE_HI)
	Kit.line(img, Vector2(1, 7), Vector2(0, 9), CHITIN[3])
	return img


# --- generic re-skins (the four shared enemy types in hive colours) ------------------------------

static func _g_scout() -> Image:
	var img: Image = Kit.blank(14, 12)
	Kit.line(img, Vector2(4, 9), Vector2(3, 11), CHITIN[1])
	Kit.line(img, Vector2(8, 9), Vector2(9, 11), CHITIN[1])
	Kit.ball(img, 7.5, 6.0, 5.5, 4.6, CHITIN)
	_over_line(img, Vector2(7, 1), Vector2(9, 10), AMBER[2])
	_over_line(img, Vector2(8, 1), Vector2(10, 10), AMBER[1])
	Kit.ball(img, 2.6, 6.0, 2.2, 2.0, ARMOR)
	Kit.put(img, 1, 5, EYE)
	Kit.put(img, 2, 5, EYE_HI)
	return img


static func _g_swooper() -> Image:
	var img: Image = Kit.blank(19, 15)
	# moth wings swept back, each with an eye spot
	Painter.poly(img, PackedVector2Array([Vector2(6, 6), Vector2(13, 0), Vector2(19, 1), Vector2(15, 6)]), Color("#7a4818"))
	Painter.poly(img, PackedVector2Array([Vector2(6, 8), Vector2(15, 8), Vector2(19, 14), Vector2(12, 14)]), Color("#7a4818"))
	Kit.line(img, Vector2(7, 6), Vector2(13, 1), Color("#c08030"))
	Kit.line(img, Vector2(7, 8), Vector2(12, 13), Color("#5a3010"))
	Kit.disc(img, 15.0, 3.0, 1.4, Color("#2a1408"))
	Kit.put(img, 15, 3, EYE)
	Kit.disc(img, 15.0, 11.5, 1.4, Color("#2a1408"))
	Kit.put(img, 15, 11, EYE)
	Kit.ball(img, 8.5, 7.0, 5.0, 2.2, AMBER)
	_over_line(img, Vector2(9, 5), Vector2(9, 9), CHITIN[0])
	_over_line(img, Vector2(11, 5), Vector2(11, 9), CHITIN[0])
	Kit.ball(img, 3.0, 7.0, 2.2, 2.0, CHITIN)
	Kit.put(img, 2, 7, EYE)
	Kit.line(img, Vector2(2, 5), Vector2(0, 2), CHITIN[2])
	return img


static func _g_sniper() -> Image:
	var img: Image = Kit.blank(16, 16)
	Kit.ball(img, 9.0, 8.0, 6.8, 7.0, CHITIN)
	for a: int in range(5):
		var ang: float = -1.2 + float(a) * 0.6
		_over_line(img, Vector2(9, 8) + Vector2.from_angle(ang) * 3.0, Vector2(9, 8) + Vector2.from_angle(ang) * 7.0, CHITIN[0])
	Kit.ball(img, 5.5, 8.0, 4.0, 4.0, SHELL)
	Kit.disc(img, 4.5, 8.0, 2.4, Color("#1e3a0e"))
	Kit.disc(img, 4.5, 8.0, 1.5, EYE)
	Kit.put(img, 4, 7, EYE_HI)
	return img


static func _g_cruiser() -> Image:
	var img: Image = Kit.blank(30, 22)
	for l: int in range(4):
		var lx: int = 9 + l * 5
		_leg(img, PackedVector2Array([Vector2(lx, 15), Vector2(lx - 2, 19), Vector2(lx - 3, 21)]), CHITIN[1])
	for s: int in range(4):
		Kit.ball(img, 24.0 - float(s) * 5.0, 10.5, 5.6, 7.6 - float(s) * 0.3, ARMOR if s % 2 == 0 else CHITIN)
	for s2: int in range(3):
		_over_line(img, Vector2(21 - s2 * 5, 3), Vector2(21 - s2 * 5, 18), ARMOR[0])
	Kit.ball(img, 6.5, 10.5, 6.0, 6.4, ARMOR)
	Kit.disc(img, 3.0, 12.0, 2.6, Color("#1e0a10"))
	Kit.disc(img, 3.0, 12.0, 1.5, ACID[2])
	Kit.put(img, 4, 7, EYE)
	Kit.put(img, 6, 6, EYE)
	Kit.line(img, Vector2(5, 4), Vector2(12, 3), ARMOR[3])
	Kit.ball(img, 21.0, 9.0, 2.4, 2.0, AMBER)
	return img


# --- BROOD QUEEN VESPERA ---------------------------------------------------------------------------
# Frames: 0 and 1 idle (wings beat, the egg sac pulses), 2 attacking (crest flares, mandibles
# open, scythes raised).

const SAC: Array[Color] = [Color("#4a2808"), Color("#7e4c12"), Color("#b0741c"), Color("#e0aa48")]


static func _queen(frame: int) -> Image:
	var img: Image = BossPainter._new_img(116, 164)
	var lift: float = 0.0 if frame == 0 else (6.0 if frame == 1 else -5.0)
	# wings, behind everything: translucent membranes with dark veins
	var wing: Color = Color(0.92, 0.78, 0.45, 0.42)
	var wing2: Color = Color(0.85, 0.66, 0.36, 0.5)
	var vein: Color = Color(0.36, 0.2, 0.08, 0.9)
	var root: Vector2 = Vector2(62.0, 62.0)
	var upper: PackedVector2Array = PackedVector2Array([root, Vector2(70.0, 10.0 + lift * 0.5), Vector2(96.0, 2.0 + lift), Vector2(114.0, 8.0 + lift), Vector2(106.0, 24.0 + lift * 0.8), Vector2(80.0, 52.0)])
	var lower: PackedVector2Array = PackedVector2Array([root + Vector2(2.0, 6.0), Vector2(90.0, 34.0 + lift * 0.6), Vector2(114.0, 44.0 + lift * 0.6), Vector2(108.0, 56.0 + lift * 0.4), Vector2(84.0, 66.0)])
	Painter.poly(img, upper, wing)
	Painter.poly(img, lower, wing2)
	for v: int in range(1, 5):
		Kit.line(img, root, upper[v], vein)
	for v2: int in range(1, 4):
		Kit.line(img, root + Vector2(2.0, 6.0), lower[v2], vein)
	Kit.line(img, Vector2(84.0, 26.0 + lift * 0.7), Vector2(100.0, 14.0 + lift), vein)
	Kit.line(img, Vector2(86.0, 18.0 + lift * 0.7), Vector2(108.0, 18.0 + lift), vein)

	# legs behind the body
	BossPainter._thick_line(img, Vector2(62, 96), Vector2(56, 126), 2, CHITIN[1], CHITIN[2])
	BossPainter._thick_line(img, Vector2(56, 126), Vector2(44, 142), 1, CHITIN[1], CHITIN[2])
	BossPainter._thick_line(img, Vector2(70, 98), Vector2(72, 132), 2, CHITIN[1], CHITIN[2])
	BossPainter._thick_line(img, Vector2(72, 132), Vector2(64, 150), 1, CHITIN[1], CHITIN[2])

	# the egg-sac abdomen: a stretched, segmented membrane with eggs glowing through it
	var sac_r: float = 30.0 if frame == 1 else 28.5
	Kit.ball(img, 82.0, 112.0, sac_r, sac_r * 1.34, SAC)
	for band: int in range(6):
		var by: float = 78.0 + float(band) * 13.0
		for x: int in range(48, 116):
			var yy: int = int(by + absf(float(x) - 80.0) * 0.16)
			_over(img, x, yy, CHITIN[1])
			_over(img, x, yy + 1, SAC[0])
	var eggs: Array[Vector2] = [Vector2(72, 94), Vector2(86, 98), Vector2(98, 108), Vector2(78, 112), Vector2(92, 122), Vector2(70, 128), Vector2(84, 136), Vector2(98, 134), Vector2(76, 146)]
	for e: int in range(eggs.size()):
		var lit: bool = (e + frame) % 3 != 0
		_ell(img, eggs[e].x, eggs[e].y, 3.6, 4.2, Color("#2c3c0e"))
		_ell(img, eggs[e].x, eggs[e].y, 2.8, 3.4, Color("#5a8a1a") if lit else Color("#3e5a14"))
		_ell(img, eggs[e].x - 0.6, eggs[e].y - 0.8, 1.2, 1.6, Color("#d8ff80") if lit else Color("#7aa040"))
	# ovipositor
	BossPainter._thick_line(img, Vector2(86, 150), Vector2(74, 161), 2, CHITIN[1], ACID[1])
	BossPainter._glow_orb(img, 74, 160, 2, Color("#2a5a10"), ACID[2], Color.WHITE)

	# thorax with a spiked royal collar
	Kit.ball(img, 56.0, 80.0, 17.0, 19.0, ARMOR)
	for p: int in range(3):
		_over_line(img, Vector2(44 + p * 9, 63), Vector2(42 + p * 9, 97), ARMOR[0])
	Kit.line(img, Vector2(46, 64), Vector2(62, 62), ARMOR[3])
	for sp: int in range(4):
		var sx: float = 46.0 + float(sp) * 7.0
		BossPainter._thick_line(img, Vector2(sx, 64), Vector2(sx + 4.0, 54.0 - float(sp % 2) * 3.0), 1, ARMOR[1], ARMOR[3])
	BossPainter._glow_orb(img, 58, 84, 3, Color("#2a5a10"), ACID[2], ACID[3])

	# scythe forelimbs
	var raise: int = -10 if frame == 2 else (2 if frame == 1 else 0)
	BossPainter._thick_line(img, Vector2(46, 90), Vector2(30, 108 + raise), 3, CHITIN[1], CHITIN[3])
	BossPainter._thick_line(img, Vector2(30, 108 + raise), Vector2(12, 98 + raise), 2, ARMOR[1], ARMOR[3])
	BossPainter._thick_line(img, Vector2(12, 98 + raise), Vector2(6, 106 + raise), 1, ARMOR[2], Color.WHITE)
	BossPainter._thick_line(img, Vector2(50, 96), Vector2(38, 122 + raise / 2), 3, CHITIN[1], CHITIN[3])
	BossPainter._thick_line(img, Vector2(38, 122 + raise / 2), Vector2(20, 118 + raise / 2), 2, ARMOR[1], ARMOR[3])
	BossPainter._thick_line(img, Vector2(20, 118 + raise / 2), Vector2(14, 126 + raise / 2), 1, ARMOR[2], Color.WHITE)

	# head: long crowned skull with mandibles
	Kit.ball(img, 30.0, 70.0, 18.0, 12.0, CHITIN)
	Kit.ball(img, 28.0, 66.0, 13.0, 7.0, ARMOR)
	var crest_lift: int = 4 if frame == 2 else 0
	for c: int in range(5):
		var cx: float = 18.0 + float(c) * 7.0
		var tip: Vector2 = Vector2(cx + 6.0, 44.0 - float(crest_lift) + float(absi(2 - c)) * 3.0)
		BossPainter._thick_line(img, Vector2(cx, 60), tip, 1, AMBER[1], AMBER[3])
		BossPainter._glow_orb(img, int(tip.x), int(tip.y), 1, AMBER[1], ACID[2] if frame == 2 else AMBER[3], Color.WHITE)
	for ey: int in range(3):
		BossPainter._glow_orb(img, 18 + ey * 6, 70 - ey, 2, Color("#1e3a0e"), EYE, EYE_HI)
	var jaw: int = 8 if frame == 2 else 2
	BossPainter._thick_line(img, Vector2(16, 76), Vector2(4, 76 - jaw), 2, ARMOR[1], ARMOR[3])
	BossPainter._thick_line(img, Vector2(16, 80), Vector2(4, 82 + jaw), 2, ARMOR[1], ARMOR[3])
	if frame == 2:
		Kit.disc(img, 8.0, 79.0, 3.6, ACID[1])
		Kit.disc(img, 7.0, 78.0, 2.0, ACID[3])
	return img
