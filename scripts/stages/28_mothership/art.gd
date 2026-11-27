extends RefCounted

# STAGE 28 sprites (worker thread: Images only). The armada's own colours: gunmetal hulls,
# crimson armour and the crimson sigil (a downward triangle with an eye), cyan reactor lights.
# Every key starts with the stage id (or "boss_<id>").

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const GUN: Array[Color] = [Color("#0e1016"), Color("#262a36"), Color("#454c5e"), Color("#7c869c"), Color("#b8c2d6")]
const CRIM: Array[Color] = [Color("#3a0812"), Color("#7a1022"), Color("#c41e34"), Color("#ff4058"), Color("#ffb0b8")]
const CYAN: Array[Color] = [Color("#0a3a48"), Color("#1aa0c0"), Color("#40e8ff"), Color("#c8faff")]
const VIO: Array[Color] = [Color("#24103e"), Color("#4c2286"), Color("#8a4ad8"), Color("#d0a8ff")]
const BALL: Array[Color] = [Color("#262a36"), Color("#454c5e"), Color("#7c869c"), Color("#b8c2d6")]
const EYE_W: Color = Color("#f0e8d8")


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(3):
		out[id + "_elite_%d" % f] = Kit.outline(_elite(f))
	for f2: int in range(2):
		out[id + "_factory_%d" % f2] = Kit.outline(_factory(f2))
		out[id + "_drone_%d" % f2] = Kit.outline(_drone(f2))
		out[id + "_marshal_%d" % f2] = Kit.outline(_marshal(f2))
		out[id + "_striker_%d" % f2] = Kit.outline(_striker(f2))

	# The stage's own shot ("bullet_b"): a crimson diamond with a white-hot core.
	var shot: Image = Kit.blank(9, 9)
	_poly(shot, [Vector2(4.5, 0.0), Vector2(9.0, 4.5), Vector2(4.5, 9.0), Vector2(0.0, 4.5)], Color(1.0, 0.25, 0.35, 0.45))
	_poly(shot, [Vector2(4.5, 1.0), Vector2(8.0, 4.5), Vector2(4.5, 8.0), Vector2(1.0, 4.5)], CRIM[2])
	_poly(shot, [Vector2(4.5, 2.5), Vector2(6.5, 4.5), Vector2(4.5, 6.5), Vector2(2.5, 4.5)], CRIM[4])
	Kit.put(shot, 4, 4, Color.WHITE)
	out[id + "_shot"] = shot
	# The Overmind's nova orb: violet with a ring.
	var orb: Image = Kit.blank(9, 9)
	Kit.disc(orb, 4.5, 4.5, 4.5, Color(0.6, 0.35, 1.0, 0.45))
	Kit.disc(orb, 4.5, 4.5, 3.4, VIO[2])
	Kit.disc(orb, 4.5, 4.5, 2.2, VIO[3])
	Kit.disc(orb, 4.0, 4.0, 1.0, Color.WHITE)
	out[id + "_orb"] = orb
	# The rail lance segment: a hot white-cyan slug.
	var slug: Image = Kit.blank(7, 7)
	Kit.disc(slug, 3.5, 3.5, 3.5, Color(0.4, 0.9, 1.0, 0.5))
	Kit.disc(slug, 3.5, 3.5, 2.3, CYAN[2])
	Kit.disc(slug, 3.5, 3.5, 1.2, Color.WHITE)
	out[id + "_slug"] = slug

	out[id + "_scout"] = Kit.outline(_g_scout())
	out[id + "_swooper"] = Kit.outline(_g_swooper())
	out[id + "_sniper"] = Kit.outline(_g_sniper())
	out[id + "_cruiser"] = Kit.outline(_g_cruiser())
	for f3: int in range(3):
		out["boss_%s_%d" % [id, f3]] = Kit.outline(_overmind(f3))
	return out


static func _poly(img: Image, pts: Array[Vector2], col: Color) -> void:
	Painter.poly(img, PackedVector2Array(pts), col)


# The armada sigil: a downward triangle with an eye, two small wing chevrons beside it.
static func emblem(img: Image, cx: float, cy: float, s: float, main: Color, dark: Color, eye: Color, pupil: Color) -> void:
	_poly(img, [Vector2(cx - s, cy - s * 0.7), Vector2(cx + s, cy - s * 0.7), Vector2(cx, cy + s * 0.95)], main)
	_poly(img, [Vector2(cx - s * 0.62, cy - s * 0.46), Vector2(cx + s * 0.62, cy - s * 0.46), Vector2(cx, cy + s * 0.55)], dark)
	Painter.ellipse(img, cx, cy - s * 0.18, s * 0.42, s * 0.2, eye)
	Painter.ellipse(img, cx, cy - s * 0.18, s * 0.09 + 0.5, s * 0.2, pupil)
	if s >= 6.0:
		_poly(img, [Vector2(cx - s * 1.1, cy - s * 0.55), Vector2(cx - s * 1.45, cy - s * 0.2), Vector2(cx - s * 1.0, cy - s * 0.2)], main)
		_poly(img, [Vector2(cx + s * 1.1, cy - s * 0.55), Vector2(cx + s * 1.45, cy - s * 0.2), Vector2(cx + s * 1.0, cy - s * 0.2)], main)


# --- enemies ---------------------------------------------------------------------------------------

# Armada elite: a forward-swept interceptor, nose left. 0 cruising, 1 locked on (canopy and gun
# pods lit), 2 mid barrel-roll (seen edge-on: thin fuselage, wings as one tall sliver).
static func _elite(frame: int) -> Image:
	var img: Image = Kit.blank(27, 15)
	if frame == 2:
		_poly(img, [Vector2(0, 7.5), Vector2(6, 6), Vector2(25, 6), Vector2(27, 7.5), Vector2(25, 9), Vector2(6, 9)], GUN[2])
		Kit.line(img, Vector2(6, 6), Vector2(24, 6), GUN[4])
		Kit.rect(img, 14, 0, 3, 15, GUN[1])
		Kit.rect(img, 14, 0, 1, 15, CRIM[3])
		Kit.rect(img, 15, 1, 1, 13, CRIM[1])
		Kit.rect(img, 25, 7, 2, 1, CYAN[2])
		Kit.put(img, 1, 7, Color("#ffe0e0"))
		return img
	# wings (forward swept), crimson leading edges
	_poly(img, [Vector2(9, 5), Vector2(19, 0), Vector2(24, 0), Vector2(20, 5.5)], GUN[1])
	_poly(img, [Vector2(9, 10), Vector2(19, 15), Vector2(24, 15), Vector2(20, 9.5)], GUN[1])
	Kit.line(img, Vector2(10, 5), Vector2(19, 0), CRIM[2])
	Kit.line(img, Vector2(10, 10), Vector2(19, 14), CRIM[1])
	# fuselage
	_poly(img, [Vector2(0, 7.5), Vector2(5, 5.5), Vector2(18, 4.5), Vector2(25, 5.5), Vector2(27, 7.5), Vector2(25, 9.5), Vector2(18, 10.5), Vector2(5, 9.5)], GUN[2])
	_poly(img, [Vector2(2, 7.5), Vector2(6, 6), Vector2(24, 5.5), Vector2(24, 7.5)], GUN[3])
	Kit.line(img, Vector2(6, 5), Vector2(18, 4), GUN[4])
	Kit.line(img, Vector2(4, 9), Vector2(24, 9), GUN[1])
	# canopy
	var glass: Color = CRIM[3] if frame == 1 else Color("#5a1424")
	_poly(img, [Vector2(6, 6), Vector2(10, 5), Vector2(13, 7), Vector2(7, 8)], glass)
	Kit.put(img, 8, 6, Color("#ffd0d8") if frame == 1 else Color("#c06070"))
	# gun pods on the wingtips
	var pod: Color = CRIM[4] if frame == 1 else GUN[3]
	Kit.rect(img, 17, 0, 6, 1, GUN[3])
	Kit.rect(img, 17, 14, 6, 1, GUN[3])
	Kit.put(img, 16, 0, pod)
	Kit.put(img, 16, 14, pod)
	# tiny sigil on the hull and engines
	Kit.rect(img, 15, 7, 3, 1, CRIM[2])
	Kit.put(img, 16, 8, CRIM[2])
	Kit.rect(img, 25, 6, 2, 3, CYAN[1])
	Kit.rect(img, 26, 7, 1, 1, CYAN[3])
	return img


# Drone factory: a hulking assembly pod with rail clamps underneath (flipped for the ceiling),
# an assembly bay in its nose and the sigil on its flank. 0 bay shut, 1 bay open and lit.
static func _factory(frame: int) -> Image:
	var img: Image = Kit.blank(44, 28)
	# rail clamps and wheels
	for cx: int in [7, 29]:
		Kit.rect(img, cx, 22, 10, 4, GUN[0])
		Kit.rect(img, cx, 22, 10, 1, GUN[2])
		Kit.disc(img, float(cx) + 2.5, 26.0, 1.8, GUN[1])
		Kit.disc(img, float(cx) + 7.5, 26.0, 1.8, GUN[1])
	# hull, sloped nose
	_poly(img, [Vector2(0, 11), Vector2(6, 4), Vector2(40, 3), Vector2(44, 7), Vector2(44, 22), Vector2(2, 22)], GUN[1])
	_poly(img, [Vector2(3, 10), Vector2(7, 6), Vector2(39, 5), Vector2(39, 9), Vector2(3, 12)], GUN[2])
	Kit.line(img, Vector2(6, 4), Vector2(40, 3), GUN[4])
	Kit.line(img, Vector2(44, 7), Vector2(44, 22), GUN[0])
	Kit.rect(img, 2, 21, 42, 1, GUN[0])
	# panel lines and rivets
	for px: int in [16, 26, 36]:
		Kit.line(img, Vector2(px, 6), Vector2(px, 20), GUN[0])
	for rx: int in range(8, 42, 6):
		Kit.put(img, rx, 8, GUN[3])
	# assembly bay in the nose
	Kit.rect(img, 3, 12, 12, 9, Color("#07080c"))
	Kit.rect(img, 3, 12, 12, 1, GUN[0])
	if frame == 1:
		Kit.rect(img, 4, 13, 10, 7, Color("#3a1408"))
		Kit.disc(img, 9.0, 16.5, 3.0, Color("#ff8a30"))
		Kit.disc(img, 9.0, 16.5, 1.6, Color("#ffe0a0"))
		Kit.rect(img, 4, 19, 10, 1, CRIM[3])
	else:
		for sl: int in range(13, 21, 2):
			Kit.rect(img, 4, sl, 10, 1, GUN[1])
	# hazard lip
	for hz: int in range(0, 8):
		Kit.put(img, 3 + hz * 2, 11, CRIM[2] if hz % 2 == 0 else Color("#1a1a10"))
	# sigil on the flank
	emblem(img, 31.0, 14.0, 5.0, CRIM[2], CRIM[0], EYE_W, Color.BLACK)
	# turret socket on top
	Kit.rect(img, 22, 1, 8, 3, GUN[2])
	Kit.rect(img, 22, 1, 8, 1, GUN[4])
	return img


# Attack drone: a round gunmetal pod with a crimson eye and stubby fins. 1 = eye flaring.
static func _drone(frame: int) -> Image:
	var img: Image = Kit.blank(12, 10)
	_poly(img, [Vector2(6, 1), Vector2(10, 0), Vector2(9, 3)], GUN[2])
	_poly(img, [Vector2(6, 9), Vector2(10, 10), Vector2(9, 7)], GUN[2])
	Kit.ball(img, 5.5, 5.0, 4.6, 4.0, BALL)
	Kit.disc(img, 3.5, 5.0, 2.0, Color("#0a0608"))
	Kit.disc(img, 3.5, 5.0, 1.2, CRIM[4] if frame == 1 else CRIM[2])
	if frame == 1:
		Kit.put(img, 3, 5, Color.WHITE)
	Kit.rect(img, 10, 4, 2, 2, CYAN[2])
	return img


# Strike marshal: a command ship with an antenna mast, a beacon dome and a big sigil. Frame 1 =
# calling a strike (dish and antenna tips lit).
static func _marshal(frame: int) -> Image:
	var img: Image = Kit.blank(38, 24)
	# antenna mast and dish
	Kit.line(img, Vector2(24, 8), Vector2(28, 0), GUN[3])
	Kit.line(img, Vector2(26, 8), Vector2(32, 2), GUN[3])
	Kit.put(img, 28, 0, CRIM[4] if frame == 1 else CRIM[1])
	Kit.put(img, 32, 2, CRIM[4] if frame == 1 else CRIM[1])
	Painter.ellipse(img, 15.0, 6.0, 5.0, 2.0, GUN[3] if frame == 0 else CYAN[2])
	Kit.line(img, Vector2(15, 6), Vector2(17, 9), GUN[2])
	# hull
	_poly(img, [Vector2(0, 14), Vector2(6, 10), Vector2(30, 8), Vector2(37, 11), Vector2(38, 17), Vector2(33, 22), Vector2(6, 21)], GUN[1])
	_poly(img, [Vector2(3, 14), Vector2(7, 11), Vector2(29, 9.5), Vector2(29, 13), Vector2(4, 15)], GUN[2])
	Kit.line(img, Vector2(6, 10), Vector2(30, 8), GUN[4])
	Kit.rect(img, 5, 20, 28, 1, GUN[0])
	# crimson armour band and the sigil
	Kit.rect(img, 4, 16, 30, 3, CRIM[1])
	Kit.rect(img, 4, 16, 30, 1, CRIM[2])
	emblem(img, 20.0, 15.0, 5.0, CRIM[3], CRIM[0], EYE_W, Color.BLACK)
	# bridge windows
	for wx: int in range(7, 14, 2):
		Kit.put(img, wx, 12, CYAN[2] if frame == 1 else CYAN[1])
	# engines
	Kit.rect(img, 36, 12, 2, 4, CYAN[1])
	Kit.rect(img, 37, 13, 1, 2, CYAN[3])
	return img


# Strike fighter: a small dart flying LEFT TO RIGHT (nose right), crimson fins, engine flame at
# the back. Frame 1 = afterburner.
static func _striker(frame: int) -> Image:
	var img: Image = Kit.blank(18, 9)
	var fl: int = 3 if frame == 0 else 5
	Kit.rect(img, 5 - fl, 3, fl, 3, Color("#ff9a30"))
	Kit.rect(img, 5 - fl + 1, 4, fl - 1, 1, Color("#fff0a0"))
	_poly(img, [Vector2(5, 3), Vector2(13, 3), Vector2(18, 4.5), Vector2(13, 6), Vector2(5, 6)], GUN[2])
	Kit.line(img, Vector2(5, 3), Vector2(13, 3), GUN[4])
	_poly(img, [Vector2(5, 3), Vector2(9, 3), Vector2(6, 0)], CRIM[2])
	_poly(img, [Vector2(5, 6), Vector2(9, 6), Vector2(6, 9)], CRIM[1])
	Kit.rect(img, 11, 4, 3, 1, CRIM[3])
	return img


# --- generic re-skins: armada line craft ---------------------------------------------------------

static func _g_scout() -> Image:
	var img: Image = Kit.blank(15, 10)
	_poly(img, [Vector2(0, 5), Vector2(5, 2), Vector2(12, 1), Vector2(15, 5), Vector2(12, 9), Vector2(5, 8)], GUN[2])
	Kit.line(img, Vector2(5, 2), Vector2(12, 1), GUN[4])
	_poly(img, [Vector2(8, 1), Vector2(13, 0), Vector2(11, 3)], CRIM[2])
	_poly(img, [Vector2(8, 9), Vector2(13, 10), Vector2(11, 7)], CRIM[1])
	Kit.rect(img, 3, 4, 4, 2, CRIM[3])
	Kit.rect(img, 13, 4, 2, 2, CYAN[2])
	return img


static func _g_swooper() -> Image:
	var img: Image = Kit.blank(21, 14)
	_poly(img, [Vector2(4, 6), Vector2(16, 0), Vector2(20, 1), Vector2(13, 6)], GUN[1])
	_poly(img, [Vector2(4, 8), Vector2(13, 8), Vector2(20, 13), Vector2(16, 14)], GUN[1])
	Kit.line(img, Vector2(5, 6), Vector2(16, 0), CRIM[2])
	Kit.line(img, Vector2(5, 8), Vector2(16, 14), CRIM[1])
	_poly(img, [Vector2(0, 7), Vector2(4, 5), Vector2(16, 5.5), Vector2(16, 8.5), Vector2(4, 9)], GUN[2])
	Kit.rect(img, 4, 6, 4, 2, Color("#5a1424"))
	Kit.rect(img, 16, 6, 2, 2, CYAN[2])
	return img


static func _g_sniper() -> Image:
	var img: Image = Kit.blank(17, 17)
	_poly(img, [Vector2(4, 1), Vector2(16, 3), Vector2(16, 14), Vector2(4, 16), Vector2(2, 8.5)], GUN[1])
	Kit.line(img, Vector2(4, 1), Vector2(16, 3), GUN[3])
	Kit.disc(img, 7.0, 8.5, 4.0, Color("#0a0608"))
	Kit.disc(img, 7.0, 8.5, 2.6, CRIM[2])
	Kit.disc(img, 6.5, 8.0, 1.0, CRIM[4])
	Kit.rect(img, 0, 8, 3, 1, GUN[3])
	Kit.rect(img, 13, 5, 2, 7, CRIM[1])
	Kit.rect(img, 16, 7, 1, 3, CYAN[2])
	return img


static func _g_cruiser() -> Image:
	var img: Image = Kit.blank(32, 19)
	_poly(img, [Vector2(0, 9.5), Vector2(6, 3), Vector2(27, 2), Vector2(32, 6), Vector2(32, 13), Vector2(27, 17), Vector2(6, 16)], GUN[1])
	_poly(img, [Vector2(3, 9), Vector2(7, 4), Vector2(26, 3), Vector2(26, 8)], GUN[2])
	Kit.line(img, Vector2(6, 3), Vector2(27, 2), GUN[4])
	Kit.rect(img, 4, 11, 24, 3, CRIM[1])
	Kit.rect(img, 4, 11, 24, 1, CRIM[2])
	emblem(img, 18.0, 9.0, 5.0, CRIM[3], CRIM[0], EYE_W, Color.BLACK)
	Kit.rect(img, 30, 7, 2, 5, CYAN[1])
	Kit.rect(img, 0, 9, 3, 1, GUN[4])
	return img


# --- THE OVERMIND ----------------------------------------------------------------------------------
# A giant brain-core cradled in a crimson armoured crescent that bears the sigil, a cage of
# gunmetal ribs over the brain, one huge eye in front, four lenses along the shell and two long
# cannon arms. Frames 0/1: the brain's neural lights pulse, the eye half-lidded; frame 2: eye
# wide open, lenses blazing, muzzles glowing and the shell plates spread.

static func _overmind(frame: int) -> Image:
	var w: int = 148
	var h: int = 184
	var img: Image = BossPainter._new_img(w, h)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2800
	var spread: float = 4.0 if frame == 2 else 0.0
	# hanging cables under the core
	for c: int in range(5):
		var cx: float = 54.0 + float(c) * 9.0
		var prev: Vector2 = Vector2(cx, 136.0)
		for s: int in range(1, 9):
			var t: float = float(s) / 8.0
			var p: Vector2 = Vector2(cx + sin(t * 4.0 + float(c)) * 3.0, 136.0 + t * (34.0 + float(c % 3) * 6.0))
			Kit.line(img, prev, p, GUN[1] if c % 2 == 0 else Color("#3a1830"))
			prev = p
		Kit.put(img, int(prev.x), int(prev.y), CYAN[1] if frame == 1 else CRIM[2])
	# cannon arms (behind the shell), upper and lower
	for arm: int in range(2):
		var ay: float = 38.0 - spread if arm == 0 else 146.0 + spread
		BossPainter._thick_line(img, Vector2(96, 92.0 + (ay - 92.0) * 0.4), Vector2(74, ay), 5, GUN[1], GUN[2])
		BossPainter._armor_plate(img, 18, int(ay) - 7, 60, 14, GUN[1], GUN[3], GUN[0])
		Kit.rect(img, 4, int(ay) - 4, 16, 8, GUN[2])
		Kit.rect(img, 4, int(ay) - 4, 16, 1, GUN[4])
		Kit.rect(img, 0, int(ay) - 3, 5, 6, GUN[0])
		for ring: int in range(3):
			Kit.rect(img, 22 + ring * 14, int(ay) - 7, 2, 14, CRIM[1])
		Kit.rect(img, 30, int(ay) - 2, 40, 1, CRIM[2] if frame != 0 else CRIM[1])
		# crimson shroud at the shoulder, cyan coils on the barrel
		BossPainter._armor_plate(img, 54, int(ay) - 9, 22, 18, CRIM[1], CRIM[3], CRIM[0], false)
		for coil: int in range(3):
			var cc: Color = CYAN[2] if (coil + frame) % 3 == 0 else CYAN[1]
			Kit.rect(img, 8 + coil * 4, int(ay) - 5, 2, 10, cc)
		if frame == 2:
			BossPainter._glow_orb(img, 3, int(ay), 5, Color("#7a1022"), Color("#ff4058"), Color.WHITE)
	# the crescent shell
	var shell: Array[Vector2] = [Vector2(62, 8 - spread), Vector2(100, 0), Vector2(132, 14), Vector2(146, 54), Vector2(148, 92),
		Vector2(146, 130), Vector2(132, 170), Vector2(100, 184), Vector2(62, 176 + spread), Vector2(86, 156), Vector2(100, 124),
		Vector2(104, 92), Vector2(100, 60), Vector2(86, 28)]
	_poly(img, shell, CRIM[0])
	var inner: Array[Vector2] = [Vector2(70, 12 - spread), Vector2(100, 5), Vector2(128, 18), Vector2(141, 56), Vector2(143, 92),
		Vector2(141, 128), Vector2(128, 166), Vector2(100, 179), Vector2(70, 172 + spread), Vector2(90, 154), Vector2(105, 124),
		Vector2(109, 92), Vector2(105, 60), Vector2(90, 30)]
	_poly(img, inner, CRIM[1])
	# outer band of darker armour, plate seams with lit top edges, rivets
	var outer: Array[Vector2] = [Vector2(100, 5), Vector2(128, 18), Vector2(141, 56), Vector2(143, 92), Vector2(141, 128), Vector2(128, 166), Vector2(100, 179)]
	for oi: int in range(outer.size() - 1):
		BossPainter._thick_line(img, outer[oi], outer[oi + 1], 2, Color("#5a0c1a"), Color("#5a0c1a"))
	for seam: int in range(7):
		var sy: float = 16.0 + float(seam) * 25.0
		var x0: float = 100.0 + absf(sy - 92.0) * 0.1
		Kit.line(img, Vector2(x0, sy), Vector2(142, sy + 2.0), CRIM[0])
		Kit.line(img, Vector2(x0 + 1.0, sy + 1.0), Vector2(141, sy + 3.0), CRIM[2])
		for rv: int in range(3):
			Kit.put(img, int(x0) + 8 + rv * 11, int(sy) + 5, CRIM[3])
	Kit.line(img, Vector2(100, 5), Vector2(128, 18), CRIM[3])
	Kit.line(img, Vector2(128, 18), Vector2(141, 56), CRIM[2])
	Kit.line(img, Vector2(70, 12 - spread), Vector2(100, 5), CRIM[2])
	# gunmetal trim along the inner curve
	var trim: Array[Vector2] = [Vector2(70, 12 - spread), Vector2(90, 30), Vector2(105, 60), Vector2(109, 92), Vector2(105, 124), Vector2(90, 154), Vector2(70, 172 + spread)]
	for ti: int in range(trim.size() - 1):
		BossPainter._thick_line(img, trim[ti], trim[ti + 1], 2, GUN[1], GUN[3])
	for tb: int in range(1, trim.size() - 1):
		BossPainter._circle(img, int(trim[tb].x), int(trim[tb].y), 3, GUN[2])
		Kit.put(img, int(trim[tb].x) - 1, int(trim[tb].y) - 1, GUN[4])
	# crown spikes
	for sp: int in range(4):
		var bx: float = 76.0 + float(sp) * 16.0
		var by: float = 10.0 - float(sp % 2) * 2.0 - spread
		_poly(img, [Vector2(bx - 4, by + 4), Vector2(bx + 4, by + 4), Vector2(bx + 1.0, by - 10.0 - float(sp % 2) * 4.0)], GUN[2])
		Kit.line(img, Vector2(bx - 3, by + 3), Vector2(bx + 1.0, by - 9.0 - float(sp % 2) * 4.0), GUN[4])
	# the brain
	var bc: Vector2 = Vector2(64.0, 92.0)
	Kit.ball(img, bc.x, bc.y, 40.0, 50.0, VIO)
	# fissures: sinuous dark folds
	for f: int in range(9):
		var fy: float = 52.0 + float(f) * 10.0
		var prev2: Vector2 = Vector2(30.0 + absf(float(f) - 4.0) * 3.0, fy)
		for s2: int in range(1, 12):
			var x2: float = prev2.x + 5.0
			if x2 > 100.0:
				break
			var p2: Vector2 = Vector2(x2, fy + sin(float(s2) * 1.3 + float(f) * 2.1) * 3.0)
			if (p2 - bc).length() < 46.0:
				Kit.line(img, prev2, p2, VIO[0])
			prev2 = p2
	Kit.line(img, Vector2(64, 44), Vector2(64, 140), VIO[0])
	# neural lights
	for n: int in range(26):
		var a: float = rng.randf() * TAU
		var r: float = sqrt(rng.randf()) * 38.0
		var np: Vector2 = bc + Vector2(cos(a) * r * 0.8, sin(a) * r * 1.1)
		var lit: bool = (n + frame) % 3 != 0
		Kit.put(img, int(np.x), int(np.y), CYAN[2] if lit else CYAN[1])
		if lit and frame >= 1 and n % 4 == 0:
			Kit.put(img, int(np.x) + 1, int(np.y), CYAN[3])
	# the gunmetal cage of ribs over the brain
	for rib: int in range(5):
		var ry: float = 48.0 + float(rib) * 22.0
		var tip: Vector2 = Vector2(26.0 + absf(float(rib) - 2.0) * 7.0, ry + (float(rib) - 2.0) * 3.0)
		BossPainter._thick_line(img, Vector2(98, 92.0 + (ry - 92.0) * 1.15), tip, 2, GUN[1], GUN[3])
	# the eye
	var ec: Vector2 = Vector2(36.0, 92.0)
	BossPainter._circle(img, int(ec.x), int(ec.y), 17, GUN[0])
	BossPainter._circle(img, int(ec.x), int(ec.y), 15, Color("#1a0810"))
	var open: float = 7.0 if frame == 0 else (9.0 if frame == 1 else 13.0)
	Painter.ellipse(img, ec.x, ec.y, 13.0, open, EYE_W)
	Painter.ellipse(img, ec.x - 2.0, ec.y, 8.0, minf(open, 8.0), CRIM[2])
	Painter.ellipse(img, ec.x - 2.0, ec.y, 6.0, minf(open, 6.0) - 0.5, CRIM[3])
	Painter.ellipse(img, ec.x - 2.0, ec.y, 1.6, minf(open, 7.0), Color.BLACK)
	Kit.put(img, int(ec.x) - 5, int(ec.y) - 3, Color.WHITE)
	if frame != 2:
		# heavy eyelid plates
		Kit.rect(img, int(ec.x) - 14, int(ec.y - open) - 3, 28, 3, GUN[2])
		Kit.rect(img, int(ec.x) - 14, int(ec.y + open) + 1, 28, 3, GUN[1])
	# lenses along the shell
	for ln: Vector2 in [Vector2(118, 30), Vector2(132, 64), Vector2(132, 120), Vector2(118, 154)]:
		BossPainter._circle(img, int(ln.x), int(ln.y), 5, GUN[0])
		if frame == 2:
			BossPainter._glow_orb(img, int(ln.x), int(ln.y), 4, Color("#7a1022"), Color("#ff4058"), Color("#ffe0e4"))
		else:
			BossPainter._circle(img, int(ln.x), int(ln.y), 3, CRIM[1] if frame == 0 else CRIM[2])
			Kit.put(img, int(ln.x) - 1, int(ln.y) - 1, CRIM[4])
	# the big sigil on the shell
	emblem(img, 126.0, 92.0, 13.0, CRIM[3], CRIM[0], EYE_W, Color.BLACK)
	Kit.line(img, Vector2(113, 83), Vector2(139, 83), CRIM[4])
	return img
