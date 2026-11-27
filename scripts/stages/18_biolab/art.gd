extends RefCounted

# STAGE 18 sprites (worker thread: Images only). Mutated flesh in pink and violet with toxic
# green ooze; lab hardware in teal-grey steel with hazard stripes. Every key starts with the
# stage id (or "boss_<id>").

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const FLESH: Array[Color] = [Color("#3a1028"), Color("#7a2a50"), Color("#c05a84"), Color("#f0a0c0")]
const FLESH2: Array[Color] = [Color("#2a0c30"), Color("#5a2070"), Color("#9a48b0"), Color("#d890e8")]
const OOZE: Array[Color] = [Color("#1e4a0e"), Color("#3e8a18"), Color("#7ad830"), Color("#d8ff90")]
const STEEL: Array[Color] = [Color("#101c20"), Color("#26383e"), Color("#4e6870"), Color("#9ab4bc")]
const BONE: Color = Color("#f0e6c8")
const EYE: Color = Color("#ffe040")
const RED: Color = Color("#ff3030")
const HAZ: Color = Color("#e8c030")


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(3):
		out[id + "_spec_%d" % f] = Kit.outline(_specimen(f))
	for f2: int in range(2):
		out[id + "_launcher_%d" % f2] = Kit.outline(_launcher(f2))
		out[id + "_turret_%d" % f2] = Kit.outline(_turret(f2))
	out[id + "_blob_0"] = Kit.outline(_blob(7.0, 0))
	out[id + "_blob_1"] = Kit.outline(_blob(5.0, 1))
	out[id + "_blob_2"] = Kit.outline(_blob(3.6, 2))

	var shot: Image = Kit.blank(7, 7)
	Kit.disc(shot, 3.5, 3.5, 3.5, Color("#1e4a0e"))
	Kit.disc(shot, 3.5, 3.5, 2.6, Color("#b8ff50"))
	Kit.disc(shot, 3.0, 3.0, 1.2, Color.WHITE)
	out[id + "_shot"] = shot
	var glob: Image = Kit.blank(10, 10)
	Kit.disc(glob, 5.0, 5.0, 5.0, Color("#14300a"))
	Kit.ball(glob, 5.0, 5.0, 4.0, 4.0, OOZE)
	Kit.put(glob, 4, 3, Color.WHITE)
	out[id + "_glob"] = glob

	out[id + "_scout"] = Kit.outline(_g_scout())
	out[id + "_swooper"] = Kit.outline(_g_swooper())
	out[id + "_sniper"] = Kit.outline(_g_sniper())
	out[id + "_cruiser"] = Kit.outline(_g_cruiser())
	for f3: int in range(3):
		out["boss_%s_%d" % [id, f3]] = Kit.outline(_chimera(f3))
	return out


static func _over(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.3:
		img.set_pixel(x, y, col)


static func _ell(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	Painter.ellipse(img, cx, cy, rx, ry, col)


# --- enemies ---------------------------------------------------------------------------------------

# Escaped specimen, three mutation stages: 0 a one-eyed blob, 1 sprouting bone spikes and a
# second eye, 2 a swollen armoured horror with a fanged maw.
static func _specimen(form: int) -> Image:
	var s: int = 18 + form * 6
	var img: Image = Kit.blank(s, s)
	var c: float = float(s) * 0.5
	var r: float = 6.0 + float(form) * 2.6
	if form >= 1:
		for sp: int in range(5 + form * 2):
			var a: float = -2.6 + float(sp) * (5.2 / float(4 + form * 2))
			var d: Vector2 = Vector2.from_angle(a)
			Kit.line(img, Vector2(c, c) + d * r * 0.8, Vector2(c, c) + d * (r + 2.0 + float(form)), BONE)
	Kit.ball(img, c + 1.0, c, r, r * 0.9, FLESH if form < 2 else FLESH2)
	# veins
	for v: int in range(3):
		var a2: float = float(v) * 2.1 + 0.4
		Kit.line(img, Vector2(c + 1.0, c) + Vector2.from_angle(a2) * r * 0.3, Vector2(c + 1.0, c) + Vector2.from_angle(a2 + 0.3) * r * 0.85, FLESH[0] if form < 2 else FLESH2[0])
	# eyes
	Kit.disc(img, c - r * 0.35, c - r * 0.25, 2.0 + float(form) * 0.3, Color("#200810"))
	Kit.disc(img, c - r * 0.35, c - r * 0.25, 1.3 + float(form) * 0.3, EYE)
	if form >= 1:
		Kit.disc(img, c + r * 0.15, c - r * 0.5, 1.4, Color("#200810"))
		Kit.put(img, int(c + r * 0.15), int(c - r * 0.5), EYE)
	if form >= 2:
		Kit.disc(img, c + r * 0.4, c - r * 0.1, 1.4, Color("#200810"))
		Kit.put(img, int(c + r * 0.4), int(c - r * 0.1), EYE)
		# fanged maw
		Painter.ellipse(img, c - r * 0.45, c + r * 0.35, r * 0.45, r * 0.28, Color("#200810"))
		for t: int in range(4):
			Kit.put(img, int(c - r * 0.75) + t * 2, int(c + r * 0.22), BONE)
			Kit.put(img, int(c - r * 0.7) + t * 2, int(c + r * 0.5), BONE)
	else:
		Kit.line(img, Vector2(c - r * 0.75, c + r * 0.3), Vector2(c - r * 0.2, c + r * 0.4), Color("#200810"))
	# ooze dripping
	Kit.put(img, int(c), int(c + r * 0.9), OOZE[2])
	Kit.put(img, int(c), int(c + r * 0.9) + 1, OOZE[1])
	return img


# Blob launcher: a floor-mounted pressure tank with a hazard-striped collar and a vent cap
# (frame 1: cap bulging and glowing, about to launch).
static func _launcher(frame: int) -> Image:
	var img: Image = Kit.blank(22, 24)
	Kit.rect(img, 1, 18, 20, 6, STEEL[1])
	Kit.rect(img, 1, 18, 20, 1, STEEL[3])
	for hx: int in range(1, 21, 4):
		Kit.rect(img, hx, 20, 2, 2, HAZ)
		Kit.rect(img, hx + 2, 20, 2, 2, Color("#141414"))
	Kit.rect(img, 4, 6, 14, 12, STEEL[1])
	Kit.rect(img, 4, 6, 2, 12, STEEL[2])
	Kit.rect(img, 16, 6, 2, 12, STEEL[0])
	# glass window with ooze inside
	Kit.rect(img, 7, 8, 8, 8, Color("#0a1a0c"))
	Kit.rect(img, 7, 11, 8, 5, OOZE[1] if frame == 0 else OOZE[2])
	Kit.put(img, 8, 9, Color("#a0c8c0"))
	Kit.put(img, 10, 13, OOZE[3])
	# vent cap
	var bulge: int = 2 if frame == 1 else 0
	Kit.rect(img, 6 - bulge / 2, 2 - bulge, 10 + bulge, 4 + bulge, STEEL[2])
	Kit.rect(img, 6 - bulge / 2, 2 - bulge, 10 + bulge, 1, STEEL[3])
	if frame == 1:
		Kit.rect(img, 8, 0, 6, 2, OOZE[2])
	return img


# Haywire security turret: a dome on a mount with a cracked lens (the barrel is drawn live so
# it can twitch). Frame 1: its alarm light lit.
static func _turret(frame: int) -> Image:
	var img: Image = Kit.blank(20, 14)
	Kit.rect(img, 1, 10, 18, 4, STEEL[1])
	Kit.rect(img, 1, 10, 18, 1, STEEL[3])
	Kit.rect(img, 3, 12, 3, 2, HAZ)
	Kit.rect(img, 14, 12, 3, 2, HAZ)
	Kit.ball(img, 10.0, 8.0, 7.0, 6.0, STEEL)
	Kit.disc(img, 8.0, 7.0, 2.4, Color("#100808"))
	Kit.disc(img, 8.0, 7.0, 1.5, RED)
	Kit.line(img, Vector2(6, 5), Vector2(9, 9), Color("#e0e0e0"))
	Kit.rect(img, 13, 2, 3, 2, RED if frame == 1 else Color("#501010"))
	return img


static func _blob(r: float, size: int) -> Image:
	var s: int = int(ceilf(r * 2.0 + 3.0))
	var img: Image = Kit.blank(s, s)
	var c: float = float(s) * 0.5
	Kit.ball(img, c, c + 0.5, r, r * 0.85, OOZE)
	Kit.disc(img, c - r * 0.3, c - r * 0.1, maxf(1.0, r * 0.25), Color("#14300a"))
	Kit.put(img, int(c - r * 0.3), int(c - r * 0.1), EYE)
	if size == 0:
		Kit.disc(img, c + r * 0.3, c - r * 0.2, 1.2, Color("#14300a"))
		Kit.put(img, int(c + r * 0.3), int(c - r * 0.2), EYE)
	Kit.put(img, int(c - r * 0.5), int(c - r * 0.55), OOZE[3])
	return img


# --- generic re-skins ------------------------------------------------------------------------------

static func _g_scout() -> Image:
	var img: Image = Kit.blank(14, 12)
	Kit.ball(img, 7.0, 6.0, 6.0, 5.0, STEEL)
	Kit.rect(img, 1, 8, 12, 2, HAZ)
	Kit.disc(img, 4.0, 5.0, 1.8, Color("#0a1a0c"))
	Kit.put(img, 4, 5, OOZE[2])
	return img


static func _g_swooper() -> Image:
	var img: Image = Kit.blank(20, 14)
	Painter.poly(img, PackedVector2Array([Vector2(5, 6), Vector2(15, 0), Vector2(19, 2), Vector2(13, 7)]), FLESH[1])
	Painter.poly(img, PackedVector2Array([Vector2(5, 8), Vector2(13, 7), Vector2(19, 12), Vector2(15, 14)]), FLESH[1])
	Kit.line(img, Vector2(6, 6), Vector2(15, 0), FLESH[3])
	for v: int in range(3):
		Kit.line(img, Vector2(8, 7), Vector2(13 + v * 2, 1 + v), FLESH[0])
	Kit.ball(img, 6.0, 7.0, 4.5, 3.0, FLESH)
	Kit.put(img, 3, 6, EYE)
	return img


static func _g_sniper() -> Image:
	var img: Image = Kit.blank(16, 16)
	Kit.ball(img, 8.0, 8.0, 7.0, 7.0, FLESH2)
	Kit.disc(img, 6.0, 8.0, 4.0, BONE)
	Kit.disc(img, 5.5, 8.0, 2.4, Color("#200810"))
	Kit.disc(img, 5.5, 8.0, 1.4, EYE)
	Kit.line(img, Vector2(12, 2), Vector2(15, 0), FLESH2[2])
	Kit.line(img, Vector2(12, 14), Vector2(15, 15), FLESH2[2])
	return img


static func _g_cruiser() -> Image:
	var img: Image = Kit.blank(30, 20)
	Kit.rect(img, 10, 3, 18, 14, STEEL[1])
	Kit.rect(img, 10, 3, 18, 1, STEEL[3])
	Kit.rect(img, 12, 6, 14, 8, Color("#0a1a0c"))
	Kit.rect(img, 12, 9, 14, 5, OOZE[1])
	Kit.put(img, 14, 10, OOZE[3])
	Kit.ball(img, 7.0, 10.0, 7.0, 7.0, FLESH)
	Kit.disc(img, 4.0, 8.0, 1.8, Color("#200810"))
	Kit.put(img, 4, 8, EYE)
	for hx: int in range(10, 28, 4):
		Kit.rect(img, hx, 16, 2, 1, HAZ)
	return img


# --- SUBJECT ZERO: CHIMERA ----------------------------------------------------------------------------
# The failed experiment bursting out of its containment tank: a mass of flesh with a crown of
# eyes, a fanged maw, bone spurs and tentacles, still hooked up to tubes. Frames 0/1: it
# pulses, eyes blink, tentacles writhe; frame 2: maw wide open, every eye blazing.

static func _chimera(frame: int) -> Image:
	var img: Image = BossPainter._new_img(122, 166)
	# the shattered tank behind it (right side)
	Kit.rect(img, 70, 4, 46, 10, STEEL[1])
	Kit.rect(img, 70, 4, 46, 2, STEEL[3])
	Kit.rect(img, 70, 152, 46, 12, STEEL[1])
	Kit.rect(img, 70, 152, 46, 2, STEEL[3])
	for hx: int in range(72, 114, 6):
		Kit.rect(img, hx, 158, 3, 4, HAZ)
	Kit.rect(img, 76, 14, 34, 138, Color(0.1, 0.25, 0.12, 0.55))
	Kit.rect(img, 78, 16, 2, 120, Color(0.75, 0.9, 0.85, 0.5))
	Kit.rect(img, 104, 16, 1, 130, Color(0.75, 0.9, 0.85, 0.35))
	# broken glass edges
	for g: int in range(6):
		var gy: int = 30 + g * 20
		Painter.poly(img, PackedVector2Array([Vector2(76, gy), Vector2(70 - (g % 3) * 3, gy + 6), Vector2(76, gy + 10)]), Color(0.7, 0.9, 0.85, 0.55))
	# tubes and cables from the tank caps into the flesh
	BossPainter._thick_line(img, Vector2(84, 12), Vector2(64, 44), 2, STEEL[1], STEEL[2])
	BossPainter._thick_line(img, Vector2(100, 12), Vector2(78, 58), 1, Color("#2a5a20"), OOZE[2])
	BossPainter._thick_line(img, Vector2(96, 154), Vector2(70, 120), 2, STEEL[1], STEEL[2])
	# tentacles reaching forward
	var sway: float = 0.0 if frame == 0 else (5.0 if frame == 1 else -6.0)
	for t: int in range(4):
		var ty: float = 50.0 + float(t) * 22.0
		var tip: Vector2 = Vector2(6.0 + float(t % 2) * 6.0, ty + sway * (1.0 if t % 2 == 0 else -1.0))
		var mid: Vector2 = Vector2(30.0, ty + (8.0 if t % 2 == 0 else -8.0) - sway * 0.5)
		BossPainter._thick_line(img, Vector2(52, ty + 4.0), mid, 3, FLESH[1], FLESH[2])
		BossPainter._thick_line(img, mid, tip, 2, FLESH2[1], FLESH2[2])
		Kit.disc(img, tip.x, tip.y, 2.0, FLESH2[3])
	# the body mass
	var swell: float = 2.0 if frame == 1 else 0.0
	Kit.ball(img, 66.0, 82.0, 34.0 + swell, 46.0 + swell, FLESH)
	Kit.ball(img, 54.0, 66.0, 20.0, 18.0, FLESH2)
	Kit.ball(img, 70.0, 116.0, 22.0, 16.0, FLESH)
	# veins and tumours
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 18180
	for v: int in range(12):
		var a: Vector2 = Vector2(rng.randf_range(44.0, 94.0), rng.randf_range(44.0, 124.0))
		var b: Vector2 = a + Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-12.0, 12.0))
		var steps: int = int(a.distance_to(b))
		for s: int in range(steps + 1):
			var p: Vector2 = a.lerp(b, float(s) / float(maxi(1, steps)))
			_over(img, int(p.x), int(p.y), FLESH[0])
	for tm: int in range(5):
		var tc: Vector2 = Vector2(rng.randf_range(56.0, 92.0), rng.randf_range(50.0, 130.0))
		Kit.ball(img, tc.x, tc.y, 4.0, 3.5, FLESH2)
	# bone spurs
	for sp: int in range(5):
		var base: Vector2 = Vector2(60.0 + float(sp) * 6.0, 40.0 + float(sp % 2) * 4.0)
		BossPainter._thick_line(img, base, base + Vector2(4.0, -14.0 - float(sp % 3) * 3.0), 1, BONE.darkened(0.3), BONE)
	# a crown of eyes
	var eyes: Array[Vector2] = [Vector2(42, 58), Vector2(52, 50), Vector2(62, 56), Vector2(48, 70), Vector2(60, 68), Vector2(72, 62)]
	for e: int in range(eyes.size()):
		var shut: bool = frame == 1 and e % 3 == 1
		var er: int = 4 if e < 3 else 3
		BossPainter._circle(img, int(eyes[e].x), int(eyes[e].y), er + 1, Color("#200810"))
		if shut:
			Kit.rect(img, int(eyes[e].x) - er, int(eyes[e].y), er * 2 + 1, 1, FLESH[2])
		else:
			BossPainter._circle(img, int(eyes[e].x), int(eyes[e].y), er, EYE if frame != 2 else Color("#fff8a0"))
			Kit.rect(img, int(eyes[e].x) - 1, int(eyes[e].y) - er + 1, 2, er * 2 - 1, Color("#200810"))
	# the maw
	var open: float = 14.0 if frame == 2 else 7.0
	Painter.ellipse(img, 40.0, 96.0, 16.0, open, Color("#1a0408"))
	Painter.ellipse(img, 40.0, 96.0 + open * 0.3, 10.0, open * 0.5, Color("#5a0a18"))
	for tooth: int in range(7):
		var tx: int = 27 + tooth * 4
		Kit.line(img, Vector2(tx, 96.0 - open), Vector2(tx + 1, 96.0 - open + 4.0), BONE)
		Kit.line(img, Vector2(tx + 1, 96.0 + open), Vector2(tx + 2, 96.0 + open - 4.0), BONE)
	if frame == 2:
		Kit.disc(img, 36.0, 96.0, 4.0, OOZE[2])
		Kit.disc(img, 35.0, 95.0, 2.0, OOZE[3])
	# ooze dripping from the jaw
	for d: int in range(3):
		Kit.rect(img, 34 + d * 6, int(96.0 + open) + 1, 1, 3 + d, OOZE[2])
	return img
