extends RefCounted

# JOVIAN STORM sprites. build() runs on a worker thread, so it only paints Images. Every key
# starts with the stage id ("storm_...", "boss_storm_..."). Enemies face left, toward the player.
# Palette: storm-violet mantas with cyan electric veins, caged plasma orbs, gunmetal gunships
# with a rust stripe, yellow-white sparks and pale hail.

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const VIOLET: Array[Color] = [Color("#2a2a5e"), Color("#4c4c9a"), Color("#8484d4"), Color("#c4c4f4")]
const VEIN: Color = Color("#5af0ff")
const VEIN_D: Color = Color("#2a8aa8")
const GUN: Array[Color] = [Color("#262c34"), Color("#46505c"), Color("#7c8794"), Color("#c0c8d2")]
const RUST: Color = Color("#c05a2c")
const RUST_D: Color = Color("#7a3218")
const SPARK: Color = Color("#fff27a")


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(3):
		out[id + "_manta_%d" % f] = Kit.outline(_manta(f))
	for f2: int in range(2):
		out[id + "_orb_%d" % f2] = Kit.outline(_orb(f2))
		out[id + "_gunship_%d" % f2] = Kit.outline(_gunship(f2))
	out[id + "_spark"] = _spark_shot()
	out[id + "_hail"] = Kit.outline(_hail_shot())
	for f3: int in range(3):
		out["boss_%s_%d" % [id, f3]] = _paint_boss(f3)
	return out


# --- Storm manta: seen from above, nose left, wings spread up and down ---------------------------
# Frame 0 wings spread, 1 wings flapped in, 2 spread with the wingtips charged (telegraph).

static func _manta(frame: int) -> Image:
	var img: Image = Kit.blank(26, 33)
	var span: float = 15.0 if frame != 1 else 11.0
	var tip_x: float = 9.0 if frame != 1 else 12.0
	var cy: float = 16.0
	# Wings: a leading edge from the head out to the tip, a trailing edge back to the tail root.
	for side: float in [-1.0, 1.0]:
		var tip: Vector2 = Vector2(tip_x, cy + side * span)
		var pts: PackedVector2Array = PackedVector2Array([Vector2(6.0, cy + side * 2.0), tip, tip + Vector2(3.0, -side * 1.0), Vector2(19.0, cy + side * 3.0), Vector2(15.0, cy)])
		Painter.poly(img, pts, VIOLET[1])
		# lighter leading half, darker trailing half
		Painter.poly(img, PackedVector2Array([Vector2(6.0, cy + side * 2.0), tip, Vector2(11.0, cy + side * 4.0)]), VIOLET[2])
		# electric vein along the leading edge
		Kit.line(img, Vector2(7.0, cy + side * 3.0), tip + Vector2(0.0, -side * 1.0), VEIN_D if frame == 1 else VEIN)
		var node: Color = Color.WHITE if frame == 2 else (VEIN if frame == 0 else VEIN_D)
		Kit.put(img, int(tip.x), int(tip.y), node)
		Kit.put(img, int(tip.x) + 1, int(tip.y), node if frame == 2 else VIOLET[2])
		if frame == 2:
			Kit.put(img, int(tip.x), int(tip.y) - int(side), SPARK)
	# Body and head with cephalic fins.
	Kit.ball(img, 13.0, cy, 7.0, 4.6, VIOLET)
	Kit.rect(img, 2, int(cy) - 3, 5, 2, VIOLET[1])
	Kit.rect(img, 2, int(cy) + 2, 5, 2, VIOLET[1])
	Kit.put(img, 1, int(cy) - 3, VIOLET[2])
	Kit.put(img, 1, int(cy) + 3, VIOLET[2])
	Kit.put(img, 7, int(cy) - 1, Color("#101030"))
	Kit.put(img, 7, int(cy) + 1, Color("#101030"))
	# Glowing spine and tail whip.
	Kit.line(img, Vector2(9.0, cy), Vector2(18.0, cy), VEIN if frame == 2 else VEIN_D)
	Kit.line(img, Vector2(19.0, cy), Vector2(25.0, cy + (1.0 if frame == 1 else 0.0)), VIOLET[1])
	Kit.put(img, 25, int(cy) + (1 if frame == 1 else 0), VEIN)
	return img


# --- Lightning orb: a plasma core in a steel cage ----------------------------------------------

static func _orb(frame: int) -> Image:
	var img: Image = Kit.blank(15, 15)
	var core: Array[Color] = [Color("#2a52c8"), Color("#4a9aff"), Color("#a8e4ff"), Color.WHITE]
	Kit.ball(img, 7.5, 7.5, 5.2, 5.2, core)
	# Cage: two rings (vertical and tilted), steel with highlights.
	for a: int in range(24):
		var ang: float = TAU * float(a) / 24.0
		var p: Vector2 = Vector2(7.0 + cos(ang) * 6.6, 7.0 + sin(ang) * 6.6)
		if a % 3 != 0:
			Kit.put(img, int(round(p.x)), int(round(p.y)), GUN[2] if sin(ang) < 0.0 else GUN[1])
	Kit.line(img, Vector2(7.0, 0.0), Vector2(7.0, 14.0), GUN[1])
	Kit.put(img, 7, 0, GUN[3])
	Kit.put(img, 7, 14, GUN[2])
	# Crackle pixels that jump between frames.
	var crackle: Array[Vector2i] = [Vector2i(3, 4), Vector2i(11, 9), Vector2i(4, 11)]
	if frame == 1:
		crackle = [Vector2i(10, 3), Vector2i(3, 9), Vector2i(11, 12)]
	for c: Vector2i in crackle:
		Kit.put(img, c.x, c.y, SPARK)
	Kit.put(img, 6, 6, Color.WHITE)
	return img


# --- Cloud-skimmer gunship: sleek gunmetal hull, rust stripe, chin turret, searchlight ------------

static func _gunship(frame: int) -> Image:
	var img: Image = Kit.blank(32, 15)
	# Hull: a long wedge, nose left.
	Painter.poly(img, PackedVector2Array([Vector2(1, 7), Vector2(9, 3), Vector2(27, 3), Vector2(31, 6), Vector2(31, 10), Vector2(9, 11)]), GUN[1])
	Painter.poly(img, PackedVector2Array([Vector2(1, 7), Vector2(9, 3), Vector2(27, 3), Vector2(28, 5), Vector2(8, 6)]), GUN[2])
	Kit.rect(img, 9, 10, 20, 1, GUN[0])
	# Rust stripe and hull number pips.
	Kit.rect(img, 12, 7, 15, 1, RUST)
	Kit.rect(img, 12, 8, 15, 1, RUST_D)
	Kit.put(img, 20, 5, GUN[3])
	Kit.put(img, 22, 5, GUN[3])
	# Canopy.
	Kit.rect(img, 8, 4, 5, 2, Color("#2a3a48"))
	Kit.rect(img, 9, 4, 3, 1, Color("#ffd27a"))
	# Top fin and tail booms.
	Painter.poly(img, PackedVector2Array([Vector2(20, 3), Vector2(25, 0), Vector2(28, 0), Vector2(27, 3)]), GUN[1])
	Kit.rect(img, 25, 0, 3, 1, GUN[2])
	# Chin turret with barrel; flash on the firing frame.
	Kit.rect(img, 10, 11, 5, 2, GUN[0])
	Kit.rect(img, 11, 11, 3, 1, GUN[2])
	Kit.rect(img, 5, 12, 6, 1, GUN[2])
	if frame == 1:
		Kit.rect(img, 2, 11, 3, 3, SPARK)
		Kit.put(img, 1, 12, Color.WHITE)
	# Searchlight in the nose and engine glow at the back.
	Kit.put(img, 2, 7, Color("#fff2c0"))
	Kit.put(img, 1, 7, Color.WHITE)
	Kit.rect(img, 31, 7, 1, 3, Color("#ff9a3a"))
	Kit.put(img, 30, 8, Color("#ffe07a"))
	return img


# --- Shots ---------------------------------------------------------------------------------------

# A yellow-white electric spark (round enough to read in any direction).
static func _spark_shot() -> Image:
	var img: Image = Kit.blank(7, 7)
	Kit.disc(img, 3.5, 3.5, 3.4, Color(1.0, 0.9, 0.3, 0.5))
	Kit.rect(img, 3, 0, 1, 7, Color("#ffe94a"))
	Kit.rect(img, 0, 3, 7, 1, Color("#ffe94a"))
	Kit.disc(img, 3.5, 3.5, 1.8, Color("#fff7b0"))
	Kit.put(img, 3, 3, Color.WHITE)
	Kit.put(img, 1, 1, Color("#fff27a"))
	Kit.put(img, 5, 5, Color("#fff27a"))
	return img


# A lump of pale hail (falls with gravity, so it may rotate).
static func _hail_shot() -> Image:
	var img: Image = Kit.blank(6, 6)
	var ice: Array[Color] = [Color("#5a7aa8"), Color("#a8c8f0"), Color("#e4f2ff"), Color.WHITE]
	Kit.ball(img, 3.0, 3.0, 2.9, 2.9, ice)
	Kit.put(img, 4, 1, Color("#e4f2ff"))
	return img


# --- Boss: STORMCALLER, a weather-control engine -------------------------------------------------
# A turbine column with stacked rings, a great storm lens, two tesla coils and an anemometer on
# top that turns between frames. On the attack frame the lens blazes and arcs jump between the
# coil toroids.

const BW: int = 124
const BH: int = 152
const LENS: Vector2i = Vector2i(34, 76)
const COIL_TOP: Vector2i = Vector2i(30, 22)
const COIL_BOT: Vector2i = Vector2i(30, 130)


static func _paint_boss(frame: int) -> Image:
	var img: Image = BossPainter._new_img(BW, BH)
	var base: Color = Color("#4a5664")
	var hi: Color = Color("#9aaabb")
	var sh: Color = Color("#222a34")
	var dark: Color = Color("#12171e")
	var teal: Color = Color("#2ad8d0")
	var hot: bool = frame == 2

	# Thruster vents at the bottom with a pale exhaust that flickers between frames.
	for vx: int in [66, 82, 98]:
		BossPainter._armor_plate(img, vx, 134, 12, 10, sh, base, dark, false)
		var fl: int = 3 + (vx / 16 + frame) % 3
		BossPainter._rect(img, vx + 3, 144, 6, fl, Color("#2a8aa8"))
		BossPainter._rect(img, vx + 4, 144, 4, fl - 1, Color("#5af0ff"))
		BossPainter._rect(img, vx + 5, 144, 2, maxi(1, fl - 2), Color("#d8f8ff"))

	# Turbine column.
	BossPainter._armor_plate(img, 60, 16, 52, 122, sh, base, dark)
	BossPainter._armor_plate(img, 66, 24, 40, 106, base, hi, sh)
	# Panel seams.
	for sx: int in [78, 94]:
		BossPainter._rect(img, sx, 26, 1, 102, sh)
		BossPainter._rect(img, sx + 1, 26, 1, 102, hi)
	# Stacked turbine rings with light slits that cycle per frame.
	var ring_ys: Array[int] = [34, 58, 98, 120]
	for ri: int in range(ring_ys.size()):
		var ry: int = ring_ys[ri]
		BossPainter._armor_plate(img, 54, ry, 64, 9, sh, base, dark, false)
		for k: int in range(6):
			var lit: bool = (k + frame + ri) % 3 == 0
			BossPainter._rect(img, 58 + k * 10, ry + 3, 6, 2, teal if lit else Color("#1a4a50"))
	# Cream instrument panel with warning lights.
	BossPainter._armor_plate(img, 80, 70, 24, 22, Color("#8a8070"), Color("#d8ceb8"), Color("#4a4438"), false)
	for li: int in range(3):
		var on: bool = (li + frame) % 2 == 0
		BossPainter._glow_orb(img, 85 + li * 7, 76, 1, Color("#5a1a10"), Color("#ff6a3a") if on else Color("#7a3218"), Color.WHITE)
	BossPainter._rect(img, 84, 82, 16, 6, Color("#1a2028"))
	for g: int in range(8):
		BossPainter._rect(img, 85 + g * 2, 87 - ((g * 3 + frame * 2) % 5), 1, ((g * 3 + frame * 2) % 5) + 1, teal)

	# Tesla coil stems from the column out to the left, stacked coil discs and toroids.
	for c: Vector2i in [COIL_TOP, COIL_BOT]:
		var stem_y: int = c.y
		BossPainter._armor_plate(img, c.x + 6, stem_y - 4, 30, 9, sh, base, dark, false)
		for d: int in range(4):
			BossPainter._rect(img, c.x + 8 + d * 6, stem_y - 6, 3, 13, Color("#b87a3a") if d % 2 == 0 else Color("#7a4a22"))
		# toroid: an elliptical ring
		for a: int in range(32):
			var ang: float = TAU * float(a) / 32.0
			var px: int = c.x + int(round(cos(ang) * 4.0))
			var py: int = stem_y + int(round(sin(ang) * 9.0))
			BossPainter._circle(img, px, py, 2, sh)
		for a2: int in range(32):
			var ang2: float = TAU * float(a2) / 32.0
			var px2: int = c.x + int(round(cos(ang2) * 4.0))
			var py2: int = stem_y + int(round(sin(ang2) * 9.0))
			BossPainter._circle(img, px2, py2, 1, hi if cos(ang2) < 0.2 else base)
		BossPainter._glow_orb(img, c.x, stem_y, 2, Color("#1a4a80"), Color("#5af0ff") if not hot else Color("#ffffff"), Color.WHITE)

	# The storm lens: a heavy ring housing with glass that brightens toward its core.
	var lr: int = 18
	BossPainter._circle(img, LENS.x + 10, LENS.y, lr + 6, dark)
	BossPainter._armor_plate(img, LENS.x + 4, LENS.y - 26, 26, 52, sh, base, dark, false)
	BossPainter._circle(img, LENS.x, LENS.y, lr + 3, sh)
	BossPainter._circle(img, LENS.x, LENS.y, lr + 1, hi)
	BossPainter._circle(img, LENS.x, LENS.y, lr, Color("#0a1430"))
	var glass: Array[Color] = [Color("#12285a"), Color("#1e4a9a"), Color("#3a8ae0"), Color("#9ad8ff")]
	if hot:
		glass = [Color("#2a5ab8"), Color("#5aa8ff"), Color("#b8ecff"), Color.WHITE]
	for gi: int in range(4):
		var gr: int = lr - 2 - gi * 4
		BossPainter._circle(img, LENS.x - gi, LENS.y - gi, gr, glass[gi])
	# Swirl lines in the glass, rotated per frame: a storm caught in the lens.
	for s: int in range(3):
		var a0: float = float(s) * TAU / 3.0 + float(frame) * 0.7
		for t: int in range(14):
			var r: float = 3.0 + float(t) * 1.0
			var ang3: float = a0 + float(t) * 0.32
			BossPainter._px(img, LENS.x + int(round(cos(ang3) * r)), LENS.y + int(round(sin(ang3) * r)), Color("#d8f4ff") if hot else Color("#6ab8f0"))
	BossPainter._circle(img, LENS.x - 4, LENS.y - 5, 2, Color.WHITE)
	# Rivets around the housing.
	for rv: int in range(12):
		var ra: float = TAU * float(rv) / 12.0
		BossPainter._px(img, LENS.x + int(round(cos(ra) * float(lr + 2))), LENS.y + int(round(sin(ra) * float(lr + 2))), dark)

	# Domed cap on the column with an anemometer mast: three cups on arms seen at an angle,
	# turning 40 degrees per frame.
	BossPainter._circle(img, 86, 18, 15, dark)
	BossPainter._circle(img, 86, 18, 14, sh)
	BossPainter._circle(img, 86, 18, 12, base)
	BossPainter._circle(img, 82, 13, 6, hi)
	BossPainter._rect(img, 70, 18, 33, 6, sh)
	var mast: Vector2i = Vector2i(86, 4)
	BossPainter._rect(img, mast.x - 1, mast.y, 3, 6, base)
	BossPainter._rect(img, mast.x - 1, mast.y, 1, 6, hi)
	for arm: int in range(3):
		var aa: float = TAU * float(arm) / 3.0 + deg_to_rad(40.0 * float(frame))
		var tip: Vector2 = Vector2(float(mast.x) + cos(aa) * 19.0, float(mast.y) + sin(aa) * 4.0)
		BossPainter._thick_line(img, Vector2(mast.x, mast.y), tip, 1, sh, hi)
		var cup_r: int = 4 if sin(aa) > 0.0 else 3
		BossPainter._circle(img, int(tip.x), int(tip.y), cup_r + 1, Color("#4a4438"))
		BossPainter._circle(img, int(tip.x), int(tip.y), cup_r, Color("#b8ae98"))
		BossPainter._circle(img, int(tip.x) - 1, int(tip.y) - 1, maxi(1, cup_r - 2), Color("#ece4d0"))
		BossPainter._px(img, int(tip.x) + 1, int(tip.y) + 1, Color("#4a4438"))
	BossPainter._glow_orb(img, mast.x, mast.y, 2, Color("#5a1a10"), Color("#ff6a3a"), Color.WHITE)

	# Arcs on the attack frame: jagged bolts between the toroids and into the lens.
	if hot:
		var pts: Array[Vector2] = []
		var n: int = 12
		for i: int in range(n + 1):
			var t2: float = float(i) / float(n)
			var y: float = lerpf(float(COIL_TOP.y + 9), float(COIL_BOT.y - 9), t2)
			var x: float = float(COIL_TOP.x) - 6.0 + sin(t2 * 23.0) * 4.0 + (3.0 if i % 2 == 0 else -3.0)
			if t2 > 0.35 and t2 < 0.65:
				x = float(LENS.x - lr - 2) + (2.0 if i % 2 == 0 else -2.0)
			pts.append(Vector2(x, y))
		for j: int in range(pts.size() - 1):
			BossPainter._thick_line(img, pts[j], pts[j + 1], 0, Color("#8aa8ff"), Color.WHITE)
			Kit.line(img, pts[j], pts[j + 1], Color.WHITE)
	return img
