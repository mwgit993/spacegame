extends RefCounted

# STAGE 15 sprites (worker thread: Images only). Rusted teal hulls, sickly green ghost-light,
# hazard-yellow salvage drones. Every key starts with the stage id (or "boss_<id>").

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const HULL: Array[Color] = [Color("#0c1a18"), Color("#1c3834"), Color("#38625c"), Color("#7aa49a")]
const RUST: Array[Color] = [Color("#341a0e"), Color("#643418"), Color("#985a2a"), Color("#d09456")]
const STEEL: Array[Color] = [Color("#1a1e26"), Color("#3a4250"), Color("#6a7688"), Color("#b4c0cc")]
const GHOST: Color = Color("#7cffc8")
const GHOST_HI: Color = Color("#d8fff0")
const GHOST_DIM: Color = Color("#2e8a68")
const HAZARD: Color = Color("#e8c030")
const RED: Color = Color("#ff4040")


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(2):
		out[id + "_ghost_%d" % f] = Kit.outline(_ghost(f))
		out[id + "_salvager_%d" % f] = Kit.outline(_salvager(f))
		out[id + "_plate_%d" % f] = Kit.outline(_plate(f))
		out[id + "_hulk_%d" % f] = Kit.outline(_hulk(f))
		out[id + "_mine_%d" % f] = Kit.outline(_mine(f))
		out[id + "_chunk_%d" % f] = Kit.outline(_chunk(f))

	var shot: Image = Kit.blank(7, 7)
	Kit.disc(shot, 3.5, 3.5, 3.5, Color(0.9, 0.35, 1.0, 0.5))
	Kit.disc(shot, 3.5, 3.5, 2.5, Color("#eebcff"))
	Kit.disc(shot, 3.0, 3.0, 1.2, Color.WHITE)
	out[id + "_shot"] = shot
	# Phantom torpedo: a wailing ghost-fire skull.
	var wisp: Image = Kit.blank(11, 11)
	Kit.disc(wisp, 5.5, 5.5, 5.5, Color(0.3, 1.0, 0.7, 0.35))
	Kit.disc(wisp, 5.5, 5.0, 4.0, Color("#9cffd8"))
	Kit.disc(wisp, 5.5, 4.6, 2.8, GHOST_HI)
	Kit.rect(wisp, 3, 4, 2, 2, Color("#0c3a2a"))
	Kit.rect(wisp, 6, 4, 2, 2, Color("#0c3a2a"))
	Kit.rect(wisp, 4, 7, 3, 1, Color("#0c3a2a"))
	out[id + "_wisp"] = wisp

	out[id + "_scout"] = Kit.outline(_g_scout())
	out[id + "_swooper"] = Kit.outline(_g_swooper())
	out[id + "_sniper"] = Kit.outline(_g_sniper())
	out[id + "_cruiser"] = Kit.outline(_g_cruiser())
	for f2: int in range(3):
		out["boss_%s_%d" % [id, f2]] = Kit.outline(_flagship(f2))
	return out


static func _poly(img: Image, pts: Array[Vector2], col: Color) -> void:
	Painter.poly(img, PackedVector2Array(pts), col)


static func _over(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.3:
		img.set_pixel(x, y, col)


static func _over_line(img: Image, a: Vector2, b: Vector2, col: Color) -> void:
	var steps: int = int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i: int in range(steps + 1):
		var p: Vector2 = a.lerp(b, 0.0 if steps == 0 else float(i) / float(steps))
		_over(img, int(roundf(p.x)), int(roundf(p.y)), col)


# --- enemies ---------------------------------------------------------------------------------------

# Ghost frigate: a derelict hull lit from inside by green ghost-fire. Frame 1: windows flicker.
static func _ghost(frame: int) -> Image:
	var img: Image = Kit.blank(28, 16)
	Kit.line(img, Vector2(17, 4), Vector2(14, 0), HULL[2])
	Kit.line(img, Vector2(14, 0), Vector2(19, 1), HULL[1])
	_poly(img, [Vector2(0, 9), Vector2(8, 4), Vector2(25, 4), Vector2(28, 6), Vector2(28, 12), Vector2(23, 13), Vector2(8, 13)], HULL[1])
	_poly(img, [Vector2(3, 8), Vector2(8, 5), Vector2(24, 5), Vector2(24, 7), Vector2(6, 8)], HULL[2])
	Kit.line(img, Vector2(8, 4), Vector2(24, 4), HULL[3])
	_poly(img, [Vector2(6, 11), Vector2(24, 11), Vector2(23, 13), Vector2(8, 13)], HULL[0])
	for wx: int in range(9, 23, 3):
		var lit: bool = (wx / 3 + frame) % 3 != 0
		Kit.put(img, wx, 9, GHOST if lit else GHOST_DIM)
	_poly(img, [Vector2(26, 6), Vector2(28, 6), Vector2(28, 12), Vector2(26, 12)], Color("#0e2a22"))
	Kit.rect(img, 27, 7, 1, 4, GHOST if frame == 0 else GHOST_HI)
	# torn plating: a ragged notch in the hull
	Kit.put(img, 15, 12, Color(0, 0, 0, 0))
	Kit.put(img, 16, 12, Color(0, 0, 0, 0))
	Kit.put(img, 16, 11, GHOST_DIM)
	Kit.put(img, 2, 9, GHOST_HI)
	return img


# Salvage drone: hazard-striped pod with a red eye and a claw arm reaching forward.
static func _salvager(frame: int) -> Image:
	var img: Image = Kit.blank(17, 15)
	Kit.line(img, Vector2(7, 9), Vector2(2, 11), STEEL[2])
	Kit.line(img, Vector2(2, 11), Vector2(0, 9), STEEL[3])
	Kit.line(img, Vector2(7, 5), Vector2(2, 3), STEEL[2])
	Kit.line(img, Vector2(2, 3), Vector2(0, 5), STEEL[3])
	Kit.ball(img, 10.0, 7.5, 6.0, 5.5, STEEL)
	for hx: int in range(5, 17):
		if (hx / 2) % 2 == 0:
			_over(img, hx, 11, HAZARD)
			_over(img, hx, 12, Color("#a07a10"))
	Kit.disc(img, 7.0, 7.0, 2.2, Color("#200808"))
	Kit.disc(img, 7.0, 7.0, 1.3, RED if frame == 0 else Color("#ffb060"))
	Kit.put(img, 6, 6, Color.WHITE)
	Kit.rect(img, 15, 3, 2, 2, GHOST_DIM)
	Kit.line(img, Vector2(11, 2), Vector2(12, 0), STEEL[2])
	return img


# The scrap plate a salvager holds up as a shield (frame 1: cracked).
static func _plate(frame: int) -> Image:
	var img: Image = Kit.blank(8, 20)
	_poly(img, [Vector2(2, 0), Vector2(7, 2), Vector2(8, 18), Vector2(3, 20), Vector2(0, 10)], RUST[1])
	Kit.line(img, Vector2(2, 1), Vector2(0, 10), RUST[3])
	Kit.line(img, Vector2(1, 4), Vector2(2, 16), RUST[2])
	_over_line(img, Vector2(6, 3), Vector2(7, 17), RUST[0])
	for ry: int in [4, 9, 14]:
		Kit.put(img, 4, ry, STEEL[3])
	_over_line(img, Vector2(3, 6), Vector2(6, 7), HULL[2])
	if frame == 1:
		_over_line(img, Vector2(1, 7), Vector2(4, 11), Color("#140806"))
		_over_line(img, Vector2(4, 11), Vector2(2, 15), Color("#140806"))
		_over_line(img, Vector2(4, 11), Vector2(7, 12), Color("#140806"))
	return img


# Mine-laying hulk: a broken hull section leaking ghost-light, with a mine hatch underneath
# (frame 1: hatch open and glowing, the drop telegraph).
static func _hulk(frame: int) -> Image:
	var img: Image = Kit.blank(52, 26)
	_poly(img, [Vector2(3, 8), Vector2(10, 4), Vector2(14, 6), Vector2(20, 2), Vector2(44, 3), Vector2(49, 6), Vector2(52, 4), Vector2(50, 12), Vector2(52, 19), Vector2(44, 22), Vector2(10, 22), Vector2(0, 16)], RUST[1])
	_poly(img, [Vector2(6, 9), Vector2(20, 4), Vector2(44, 5), Vector2(46, 9), Vector2(8, 11)], RUST[2])
	_poly(img, [Vector2(6, 17), Vector2(46, 17), Vector2(44, 21), Vector2(10, 21)], RUST[0])
	Kit.line(img, Vector2(20, 2), Vector2(44, 3), RUST[3])
	# teal patch plates and rivet rows
	Kit.rect(img, 24, 10, 10, 6, HULL[1])
	Kit.rect(img, 24, 10, 10, 1, HULL[3])
	Kit.rect(img, 37, 11, 7, 5, HULL[1])
	for rx: int in range(8, 48, 4):
		_over(img, rx, 13, RUST[0])
	# ghost-light seeping from cracks
	_over_line(img, Vector2(14, 7), Vector2(18, 13), GHOST)
	_over_line(img, Vector2(18, 13), Vector2(16, 18), GHOST_DIM)
	_over_line(img, Vector2(40, 4), Vector2(42, 9), GHOST)
	Kit.put(img, 17, 11, GHOST_HI)
	# broken turret on top
	Kit.rect(img, 30, 0, 6, 3, STEEL[1])
	Kit.line(img, Vector2(30, 1), Vector2(25, 0), STEEL[3])
	# mine hatch
	var hatch: Color = Color("#ff5050") if frame == 1 else Color("#401010")
	Kit.rect(img, 24, 21, 8, 3, STEEL[0])
	Kit.rect(img, 25, 22, 6, 2, hatch)
	if frame == 1:
		Kit.rect(img, 26, 24, 4, 2, Color("#ffb0a0"))
	return img


# Drifting mine: spiked shell, warning light (frame 1 lit).
static func _mine(frame: int) -> Image:
	var img: Image = Kit.blank(13, 13)
	for a: int in range(8):
		var d: Vector2 = Vector2.from_angle(float(a) * TAU / 8.0)
		Kit.line(img, Vector2(6.5, 6.5) + d * 4.0, Vector2(6.5, 6.5) + d * 6.2, STEEL[2])
	Kit.ball(img, 6.5, 6.5, 4.2, 4.2, RUST)
	Kit.disc(img, 6.0, 6.0, 1.6, Color("#ff5050") if frame == 1 else Color("#501010"))
	if frame == 1:
		Kit.put(img, 5, 5, Color.WHITE)
	return img


# A chunk of hull debris (for the salvager's tractor beam).
static func _chunk(frame: int) -> Image:
	var img: Image = Kit.blank(10, 10)
	_poly(img, [Vector2(1, 2), Vector2(6, 0), Vector2(10, 4), Vector2(8, 10), Vector2(2, 8)], RUST[1] if frame == 0 else HULL[1])
	Kit.line(img, Vector2(1, 2), Vector2(6, 0), RUST[3] if frame == 0 else HULL[3])
	Kit.put(img, 5, 5, STEEL[3])
	return img


# --- generic re-skins ------------------------------------------------------------------------------

static func _g_scout() -> Image:
	var img: Image = Kit.blank(14, 12)
	Kit.ball(img, 7.0, 6.0, 6.0, 4.6, RUST)
	_over_line(img, Vector2(1, 6), Vector2(13, 6), RUST[0])
	Kit.disc(img, 4.0, 6.0, 1.6, Color("#0e2a22"))
	Kit.put(img, 4, 6, GHOST)
	Kit.line(img, Vector2(9, 1), Vector2(11, 0), STEEL[2])
	return img


static func _g_swooper() -> Image:
	var img: Image = Kit.blank(20, 14)
	_poly(img, [Vector2(5, 6), Vector2(14, 0), Vector2(20, 0), Vector2(16, 6)], HULL[1])
	_poly(img, [Vector2(5, 8), Vector2(16, 8), Vector2(20, 14), Vector2(13, 14)], HULL[1])
	Kit.line(img, Vector2(5, 6), Vector2(14, 0), HULL[3])
	Kit.put(img, 17, 1, Color(0, 0, 0, 0))
	Kit.put(img, 18, 12, Color(0, 0, 0, 0))
	_poly(img, [Vector2(0, 7), Vector2(5, 5), Vector2(17, 5), Vector2(17, 9), Vector2(5, 9)], RUST[1])
	Kit.line(img, Vector2(5, 5), Vector2(17, 5), RUST[3])
	Kit.put(img, 4, 7, GHOST)
	Kit.rect(img, 17, 6, 2, 2, GHOST_DIM)
	return img


static func _g_sniper() -> Image:
	var img: Image = Kit.blank(16, 16)
	Kit.ball(img, 9.0, 8.0, 6.6, 6.8, HULL)
	Kit.rect(img, 9, 1, 2, 14, HULL[0])
	Kit.disc(img, 5.0, 8.0, 3.6, STEEL[1])
	Kit.disc(img, 4.5, 8.0, 2.4, Color("#0c3a2a"))
	Kit.disc(img, 4.5, 8.0, 1.4, GHOST)
	Kit.put(img, 4, 7, GHOST_HI)
	return img


static func _g_cruiser() -> Image:
	var img: Image = Kit.blank(30, 20)
	_poly(img, [Vector2(0, 10), Vector2(8, 4), Vector2(28, 3), Vector2(30, 10), Vector2(28, 17), Vector2(8, 16)], RUST[1])
	_poly(img, [Vector2(4, 9), Vector2(9, 5), Vector2(27, 4), Vector2(27, 8)], RUST[2])
	Kit.line(img, Vector2(8, 4), Vector2(28, 3), RUST[3])
	Kit.rect(img, 12, 9, 12, 4, HULL[1])
	for wx: int in range(13, 24, 3):
		Kit.put(img, wx, 10, GHOST)
	Kit.rect(img, 16, 0, 5, 4, STEEL[1])
	Kit.rect(img, 28, 7, 2, 6, GHOST_DIM)
	_over_line(img, Vector2(6, 13), Vector2(10, 16), Color("#140806"))
	return img


# --- PHANTOM FLAGSHIP: REQUIEM ---------------------------------------------------------------------
# A dreadnought's prow, broken open and burning with ghost-fire. Frames 0/1: the ghost-light in
# its cracks and windows shifts; frame 2: every gun port blazes (attacking).

static func _flagship(frame: int) -> Image:
	var img: Image = BossPainter._new_img(122, 166)
	var cy: float = 83.0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 15150
	# main wedge hull: steel-teal upper deck, rusted lower hull, torn-off stern on the right
	var stern: Array[Vector2] = []
	for s: int in range(12):
		var sy: float = 16.0 + float(s) * 12.0
		stern.append(Vector2(116.0 + float((s * 7) % 5) - 2.0, sy))
	var hull: Array[Vector2] = [Vector2(8, cy), Vector2(70, 22), Vector2(116, 14)]
	hull.append_array(stern)
	hull.append_array([Vector2(116, 152), Vector2(70, 146)])
	_poly(img, hull, RUST[0])
	_poly(img, [Vector2(14, cy), Vector2(70, 27), Vector2(114, 20), Vector2(114, 80), Vector2(60, 80)], HULL[1])
	_poly(img, [Vector2(14, cy), Vector2(60, 86), Vector2(114, 86), Vector2(114, 148), Vector2(70, 140)], RUST[1])
	Kit.line(img, Vector2(14, cy), Vector2(70, 27), HULL[3])
	Kit.line(img, Vector2(70, 27), Vector2(114, 20), HULL[2])
	Kit.line(img, Vector2(15, cy + 2.0), Vector2(70, 141), RUST[0])
	# weathering: speckled grime and rust over the plating
	for i: int in range(900):
		var x: int = rng.randi_range(10, 118)
		var y: int = rng.randi_range(16, 150)
		var up: bool = y < int(cy)
		_over(img, x, y, (HULL[0] if rng.randf() < 0.6 else RUST[1]) if up else (RUST[0] if rng.randf() < 0.6 else RUST[2]))
	# plating seams: horizontal decks and vertical frames, with rivets
	for d: int in range(6):
		var dy: float = 32.0 + float(d) * 20.0
		if absf(dy - cy) < 6.0:
			continue
		_over_line(img, Vector2(24, dy), Vector2(118, dy), HULL[0] if dy < cy else RUST[0])
		for rx: int in range(30, 116, 6):
			_over(img, rx, int(dy) + 2, HULL[2] if dy < cy else RUST[2])
	for b: int in range(4):
		var bx: float = 46.0 + float(b) * 18.0
		_over_line(img, Vector2(bx, 30.0 - float(b) * 2.0), Vector2(bx, 140.0 + float(b) * 2.0), RUST[0])
	# exposed ribs where the stern was torn away
	for rb: int in range(6):
		var ry: int = 22 + rb * 22
		Kit.rect(img, 112, ry, 8, 12, Color("#06100d"))
		for r2: int in range(3):
			Kit.rect(img, 113 + r2 * 3, ry, 1, 12, RUST[2] if r2 != 1 else RUST[1])
		Kit.rect(img, 113, ry + 4, 6, 3, GHOST_DIM if (rb + frame) % 2 == 0 else Color("#123a2c"))
	# keel spine
	Kit.line(img, Vector2(14, cy), Vector2(118, cy), RUST[0])
	Kit.line(img, Vector2(14, cy + 1.0), Vector2(118, cy + 1.0), RUST[3])
	# twin deck turrets
	for tt: int in range(2):
		var tp: Vector2 = Vector2(70.0, 40.0) if tt == 0 else Vector2(74.0, 126.0)
		Kit.ball(img, tp.x, tp.y, 7.0, 5.0, STEEL)
		Kit.rect(img, int(tp.x) - 16, int(tp.y) - 2, 12, 2, STEEL[2])
		Kit.rect(img, int(tp.x) - 16, int(tp.y) + 1, 12, 2, STEEL[1])
		Kit.put(img, int(tp.x) - 17, int(tp.y) - 1, Color("#ff60c0") if frame == 2 else STEEL[0])
	# bridge tower: two decks, windows, a broken radar mast
	_poly(img, [Vector2(78, 6), Vector2(106, 6), Vector2(110, 20), Vector2(76, 22)], STEEL[1])
	_poly(img, [Vector2(84, 0), Vector2(100, 0), Vector2(102, 6), Vector2(82, 6)], STEEL[0])
	Kit.line(img, Vector2(78, 6), Vector2(106, 6), STEEL[3])
	Kit.line(img, Vector2(84, 0), Vector2(100, 0), STEEL[2])
	for w: int in range(4):
		Kit.rect(img, 81 + w * 6, 11, 3, 3, GHOST if (w + frame) % 2 == 0 else GHOST_DIM)
	for w2: int in range(3):
		Kit.rect(img, 86 + w2 * 5, 2, 2, 2, GHOST_DIM if (w2 + frame) % 2 == 0 else GHOST)
	Kit.line(img, Vector2(96, 0), Vector2(91, 0), STEEL[3])
	# ghost-fire cracks
	var crack_col: Color = GHOST if frame != 1 else GHOST_HI
	_over_line(img, Vector2(52, 44), Vector2(60, 60), crack_col)
	_over_line(img, Vector2(60, 60), Vector2(56, 72), crack_col)
	_over_line(img, Vector2(60, 60), Vector2(72, 66), GHOST_DIM)
	_over_line(img, Vector2(74, 104), Vector2(66, 118), crack_col)
	_over_line(img, Vector2(66, 118), Vector2(76, 130), GHOST_DIM)
	_over_line(img, Vector2(100, 110), Vector2(106, 124), crack_col)
	BossPainter._glow_orb(img, 64, 112, 4, Color("#0e4a36"), GHOST, GHOST_HI)
	# hull breach: a ragged hole glowing inside
	Painter.ellipse(img, 84.0, 60.0, 7.0, 5.0, Color("#06120e"))
	Painter.ellipse(img, 84.0, 61.0, 4.0, 3.0, GHOST_DIM if frame == 0 else GHOST)
	# gun ports along both prow edges
	var ports: Array[Vector2] = [Vector2(25, 71), Vector2(39, 55), Vector2(53, 40), Vector2(25, 95), Vector2(39, 111), Vector2(53, 126)]
	for pt: Vector2 in ports:
		Kit.disc(img, pt.x, pt.y, 4.0, STEEL[0])
		Kit.disc(img, pt.x, pt.y, 2.6, Color("#ff60c0") if frame == 2 else Color("#2a0a1e"))
		if frame == 2:
			Kit.disc(img, pt.x - 0.5, pt.y - 0.5, 1.2, Color.WHITE)
		Kit.line(img, pt + Vector2(-3.0, 0.0), pt + Vector2(-7.0, 0.0), STEEL[2])
	# spectral figurehead on the prow: a skull with burning eyes
	Kit.ball(img, 16.0, cy, 7.0, 8.0, HULL)
	Kit.disc(img, 13.0, cy - 2.0, 1.8, Color("#06120e"))
	Kit.disc(img, 18.0, cy - 2.0, 1.8, Color("#06120e"))
	Kit.put(img, 13, int(cy) - 2, GHOST_HI if frame == 2 else GHOST)
	Kit.put(img, 18, int(cy) - 2, GHOST_HI if frame == 2 else GHOST)
	Kit.rect(img, 12, int(cy) + 3, 8, 1, Color("#06120e"))
	for t: int in range(4):
		Kit.put(img, 13 + t * 2, int(cy) + 4, HULL[3])
	# ghost-light seeping round every crack and breach
	var glow_pts: Array[Vector2] = [Vector2(56, 58), Vector2(84, 60), Vector2(70, 120), Vector2(104, 118), Vector2(64, 112)]
	for gp: Vector2 in glow_pts:
		for gy: int in range(-6, 7):
			for gx: int in range(-6, 7):
				var dd: float = Vector2(float(gx), float(gy)).length()
				var px: int = int(gp.x) + gx
				var py: int = int(gp.y) + gy
				if dd < 6.0 and Painter.bayer(px, py) < (1.0 - dd / 6.0) * (0.55 if frame == 1 else 0.4) and img.get_pixel(px, py).g < 0.45:
					_over(img, px, py, GHOST_DIM)
	return img
