extends RefCounted

# STAGE 17 sprites (worker thread: Images only). Void-black bodies with violet sheen, lit by
# the accretion disk's orange fire. Every key starts with the stage id (or "boss_<id>").

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const VOID: Array[Color] = [Color("#08040e"), Color("#1c1030"), Color("#3e2a62"), Color("#8a72c8")]
const HUSK: Array[Color] = [Color("#141018"), Color("#2e2830"), Color("#5a5058"), Color("#a09890")]
const FIRE: Array[Color] = [Color("#5a1808"), Color("#c04a10"), Color("#ff9a30"), Color("#fff0c8")]
const VIOLET: Color = Color("#b070ff")
const VIOLET_HI: Color = Color("#e8d0ff")
const BLUE: Color = Color("#80a8ff")
const LID: Array[Color] = [Color("#2a1438"), Color("#4a2660"), Color("#6a3c88"), Color("#9a70c0")]


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(3):
		out[id + "_well_%d" % f] = Kit.outline(_well(f))
		out[id + "_eye_%d" % f] = Kit.outline(_eye(f))
	out[id + "_husk_0"] = Kit.outline(_husk(0))
	out[id + "_husk_1"] = Kit.outline(_husk(1))

	var shot: Image = Kit.blank(7, 7)
	Kit.disc(shot, 3.5, 3.5, 3.5, Color(0.7, 0.4, 1.0, 0.5))
	Kit.disc(shot, 3.5, 3.5, 2.5, VIOLET_HI)
	Kit.disc(shot, 3.0, 3.0, 1.2, Color.WHITE)
	out[id + "_shot"] = shot

	out[id + "_scout"] = Kit.outline(_g_scout())
	out[id + "_swooper"] = Kit.outline(_g_swooper())
	out[id + "_sniper"] = Kit.outline(_g_sniper())
	out[id + "_cruiser"] = Kit.outline(_g_cruiser())
	for f2: int in range(3):
		out["boss_%s_%d" % [id, f2]] = Kit.outline(_devourer(f2))
	return out


static func _over(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.3:
		img.set_pixel(x, y, col)


static func _ring(img: Image, c: Vector2, rx: float, ry: float, col: Color, from_a: float = 0.0, to_a: float = TAU) -> void:
	var steps: int = int(maxf(rx, ry) * 7.0)
	for i: int in range(steps + 1):
		var a: float = lerpf(from_a, to_a, float(i) / float(steps))
		Kit.put(img, int(roundf(c.x + cos(a) * rx)), int(roundf(c.y + sin(a) * ry)), col)


# --- enemies ---------------------------------------------------------------------------------------

# Gravity-well mine: a dark core in a ring of four vanes. Frame 1 charging (core lit), frame 2
# active (vanes flared open, core white-hot).
static func _well(frame: int) -> Image:
	var img: Image = Kit.blank(17, 17)
	var c: Vector2 = Vector2(8.5, 8.5)
	var spread: float = 6.5 if frame < 2 else 7.5
	for v: int in range(4):
		var a: float = float(v) * TAU / 4.0 + PI / 4.0
		var d: Vector2 = Vector2.from_angle(a)
		Kit.line(img, c + d * 3.0, c + d * spread, VOID[2])
		Kit.line(img, c + d * 3.0 + d.orthogonal(), c + d * spread + d.orthogonal(), VOID[1])
		Kit.put(img, int(c.x + d.x * spread), int(c.y + d.y * spread), VIOLET if frame > 0 else VOID[3])
	Kit.ball(img, c.x, c.y, 4.0, 4.0, VOID)
	var core: Color = Color("#2a1040")
	if frame == 1:
		core = VIOLET
	elif frame == 2:
		core = VIOLET_HI
	Kit.disc(img, c.x, c.y, 1.8, core)
	_ring(img, c, 5.0, 5.0, Color(0.7, 0.45, 1.0, 0.8) if frame == 2 else VOID[1])
	return img


# Void eye: an eyeball of darkness in a fleshy violet lid. The iris is drawn live (it tracks
# the ship); frame 1 is the lit charging rim, frame 2 closed (armoured lid).
static func _eye(frame: int) -> Image:
	var img: Image = Kit.blank(19, 17)
	Kit.ball(img, 9.5, 8.5, 9.0, 8.0, VOID)
	for t: int in range(5):
		var a: float = -2.4 + float(t) * 0.25
		Kit.line(img, Vector2(9.5, 8.5) + Vector2.from_angle(a) * 8.0, Vector2(9.5, 8.5) + Vector2.from_angle(a) * 11.0, VOID[2])
	if frame == 2:
		Kit.ball(img, 9.5, 8.5, 7.0, 6.0, LID)
		Kit.line(img, Vector2(3, 9), Vector2(16, 9), Color("#140820"))
	else:
		Kit.disc(img, 9.5, 8.5, 6.2, Color("#d8d0e8") if frame == 0 else Color("#fff4ff"))
		_ring(img, Vector2(9.5, 8.5), 6.2, 6.2, Color("#8a72c8") if frame == 0 else VIOLET)
		Kit.put(img, 7, 5, Color.WHITE)
	return img


# Time-frozen husk: a gutted ship-corpse caked in frost-blue time-ice, a stopped clock ring on
# its flank. Frame 1: the clock ring lit (charging a time skip).
static func _husk(frame: int) -> Image:
	var img: Image = Kit.blank(28, 18)
	Painter.poly(img, PackedVector2Array([Vector2(0, 9), Vector2(6, 4), Vector2(20, 3), Vector2(28, 6), Vector2(26, 13), Vector2(18, 15), Vector2(5, 14)]), HUSK[1])
	Painter.poly(img, PackedVector2Array([Vector2(3, 8), Vector2(7, 5), Vector2(20, 4), Vector2(22, 7), Vector2(6, 9)]), HUSK[2])
	Kit.line(img, Vector2(6, 4), Vector2(20, 3), HUSK[3])
	# torn gaps in the hull
	Kit.rect(img, 12, 9, 3, 4, Color(0, 0, 0, 0))
	Kit.rect(img, 21, 8, 2, 3, Color(0, 0, 0, 0))
	# time-ice crust
	for i: int in range(10):
		var x: int = 3 + i * 2
		_over(img, x, 13 - (i % 3), Color("#6a90c8"))
	_over(img, 8, 6, Color("#a8c8ff"))
	# stopped clock ring
	var rc: Color = BLUE if frame == 1 else Color("#3a4a7a")
	_ring(img, Vector2(17.0, 9.0), 3.5, 3.5, rc)
	Kit.line(img, Vector2(17, 9), Vector2(17, 6), rc)
	Kit.line(img, Vector2(17, 9), Vector2(19, 10), rc)
	Kit.put(img, 1, 9, BLUE if frame == 1 else Color("#4a5a8a"))
	return img


# --- generic re-skins ------------------------------------------------------------------------------

static func _g_scout() -> Image:
	var img: Image = Kit.blank(14, 12)
	Kit.ball(img, 7.0, 6.0, 6.0, 5.0, VOID)
	_ring(img, Vector2(7.0, 6.0), 6.5, 2.0, FIRE[2], 0.0, PI)
	Kit.disc(img, 5.0, 6.0, 1.6, VIOLET)
	Kit.put(img, 4, 5, Color.WHITE)
	return img


static func _g_swooper() -> Image:
	var img: Image = Kit.blank(20, 14)
	Painter.poly(img, PackedVector2Array([Vector2(4, 7), Vector2(18, 0), Vector2(14, 7)]), VOID[1])
	Painter.poly(img, PackedVector2Array([Vector2(4, 7), Vector2(14, 7), Vector2(18, 14)]), VOID[1])
	Kit.line(img, Vector2(4, 7), Vector2(18, 0), VIOLET)
	Kit.line(img, Vector2(4, 7), Vector2(18, 14), VOID[2])
	Kit.ball(img, 6.0, 7.0, 4.0, 2.4, VOID)
	Kit.put(img, 3, 7, FIRE[3])
	Kit.rect(img, 12, 6, 3, 2, FIRE[2])
	return img


static func _g_sniper() -> Image:
	var img: Image = Kit.blank(16, 16)
	Kit.ball(img, 8.0, 8.0, 7.0, 7.0, VOID)
	_ring(img, Vector2(8.0, 8.0), 7.5, 7.5, VOID[2])
	Kit.disc(img, 6.0, 8.0, 3.2, Color("#1a0a24"))
	Kit.disc(img, 6.0, 8.0, 2.0, FIRE[2])
	Kit.put(img, 5, 7, FIRE[3])
	return img


static func _g_cruiser() -> Image:
	var img: Image = Kit.blank(30, 20)
	Painter.poly(img, PackedVector2Array([Vector2(0, 10), Vector2(8, 3), Vector2(28, 2), Vector2(30, 10), Vector2(28, 18), Vector2(8, 17)]), VOID[1])
	Painter.poly(img, PackedVector2Array([Vector2(4, 9), Vector2(9, 4), Vector2(27, 3), Vector2(27, 8)]), VOID[2])
	Kit.line(img, Vector2(8, 3), Vector2(28, 2), VOID[3])
	_ring(img, Vector2(16.0, 11.0), 5.0, 4.0, FIRE[2])
	Kit.disc(img, 16.0, 11.0, 2.4, Color("#020104"))
	Kit.rect(img, 28, 7, 2, 6, VIOLET)
	return img


# --- EVENT HORIZON: THE DEVOURER --------------------------------------------------------------------
# A living singularity: a black sphere wrapped in a tilted ring of fire, light filaments curling
# off it, and one vast eye in the dark. Frames 0/1: hot spots travel round the ring and the
# filaments writhe; frame 2: the eye opens wide and the ring flares.

static func _devourer(frame: int) -> Image:
	var img: Image = BossPainter._new_img(124, 164)
	var c: Vector2 = Vector2(66.0, 82.0)
	var tilt: float = -0.32
	var rot: float = float(frame) * 0.35
	# light filaments behind
	for f: int in range(7):
		var a0: float = float(f) * TAU / 7.0 + rot * 0.5
		var pts: PackedVector2Array = PackedVector2Array()
		for s: int in range(14):
			var t: float = float(s) / 13.0
			var r: float = 34.0 + t * 30.0
			var a: float = a0 + t * (1.2 + 0.2 * float(frame))
			pts.append(c + Vector2(cos(a) * r, sin(a) * r * 1.15))
		for s2: int in range(pts.size() - 1):
			var col: Color = Color(0.7, 0.45, 1.0, 0.75 - 0.05 * float(s2)) if f % 2 == 0 else Color(1.0, 0.6, 0.25, 0.7 - 0.05 * float(s2))
			Kit.line(img, pts[s2], pts[s2 + 1], col)
	# back half of the ring (behind the sphere)
	_disk(img, c, tilt, rot, true, frame)
	# the sphere: a shadow ringed by a thin photon halo
	Kit.disc(img, c.x, c.y, 37.0, Color("#3a2050"))
	Kit.disc(img, c.x, c.y, 35.5, Color("#0a0410"))
	Kit.disc(img, c.x, c.y, 34.0, Color("#020104"))
	# a faint violet sheen inside the rim, brightest at the upper left, so the dark reads
	for y: int in range(int(c.y) - 34, int(c.y) + 35):
		for x: int in range(int(c.x) - 34, int(c.x) + 35):
			var d: Vector2 = Vector2(float(x) + 0.5, float(y) + 0.5) - c
			var dl: float = d.length()
			if dl > 34.0 or dl < 22.0:
				continue
			var lit: float = clampf((-d.x - d.y) / (dl * 1.414), 0.0, 1.0)
			var k: float = (dl - 22.0) / 12.0 * (0.35 + 0.65 * lit)
			if Painter.bayer(x, y) < k * 0.8:
				img.set_pixel(x, y, Color("#2a1846") if lit > 0.6 and k > 0.6 else Color("#140a24"))
	_ring(img, c, 36.0, 36.0, Color("#ffd8a0") if frame == 2 else Color("#d0a080"))
	# the eye
	var open: float = 1.0 if frame == 2 else (0.7 if frame == 1 else 0.6)
	var ew: float = 22.0
	var eh: float = 13.0 * open
	for y: int in range(int(c.y - eh) - 1, int(c.y + eh) + 2):
		for x: int in range(int(c.x - ew) - 1, int(c.x + ew) + 2):
			var nx: float = (float(x) + 0.5 - (c.x - 6.0)) / ew
			var ny: float = (float(y) + 0.5 - c.y) / maxf(1.0, eh)
			var lens: float = absf(ny) + nx * nx
			if lens < 1.0:
				var col2: Color = Color("#3a1a10")
				if lens < 0.85:
					col2 = Color("#ff9a30") if lens > 0.6 else Color("#ffe0a0")
				img.set_pixel(x, y, col2)
	Kit.rect(img, int(c.x) - 8, int(c.y - eh * 0.9), 3 if frame < 2 else 4, int(eh * 1.8) + 1, Color("#020104"))
	Kit.put(img, int(c.x) - 12, int(c.y) - 3, Color.WHITE)
	# front half of the ring (over the sphere)
	_disk(img, c, tilt, rot, false, frame)
	return img


# Half of a tilted burning ring: back = the far side (drawn first).
static func _disk(img: Image, c: Vector2, tilt: float, rot: float, back: bool, frame: int) -> void:
	for band: int in range(4):
		var r: float = 44.0 + float(band) * 5.0
		var steps: int = 260
		for i: int in range(steps):
			var a: float = float(i) / float(steps) * TAU
			var far_side: bool = sin(a) < 0.0
			if far_side != back:
				continue
			var p: Vector2 = Vector2(cos(a) * r, sin(a) * r * 0.22).rotated(tilt)
			var hot: float = 0.5 + 0.5 * sin(a * 3.0 + rot * 4.0)
			var col: Color = FIRE[3] if band == 0 else (FIRE[2] if band == 1 else (FIRE[1] if band == 2 else FIRE[0]))
			if hot > 0.85 and band < 3:
				col = FIRE[3]
			if frame == 2 and band == 1:
				col = FIRE[3]
			Kit.put(img, int(roundf(c.x + p.x)), int(roundf(c.y + p.y)), col)
			Kit.put(img, int(roundf(c.x + p.x)), int(roundf(c.y + p.y)) + 1, col.darkened(0.3))
