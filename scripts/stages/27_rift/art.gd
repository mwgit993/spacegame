extends RefCounted

# STAGE 27 sprites (worker thread: Images only). Violet-crystal bodies lit by the two timelines:
# cyan for the present, amber for the past (echoes), with white rift light on the edges.
# Every key starts with the stage id (or "boss_<id>").

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const VIOLET: Array[Color] = [Color("#140c2c"), Color("#2e2060"), Color("#5a46a8"), Color("#a898f0")]
const STEEL: Array[Color] = [Color("#0e0a1c"), Color("#221a3e"), Color("#3e3468"), Color("#7a70b0")]
const CYAN: Color = Color("#3ce8ff")
const CYAN_HI: Color = Color("#c8faff")
const CYAN_DK: Color = Color("#126a88")
const AMBER: Color = Color("#ffb030")
const AMBER_HI: Color = Color("#ffe8b0")
const AMBER_DK: Color = Color("#7a4410")
const WHITE: Color = Color("#ffffff")
const RIFT: Color = Color("#e4dcff")

# The echo ship's colours, present (cyan/violet) and past (amber).
const SHIP_NOW: Dictionary = {"D": Color("#1a1238"), "M": Color("#3a2c78"), "L": Color("#6a5ac8"), "H": Color("#c8c0ff"),
	"C": Color("#3ce8ff"), "W": Color("#e8fcff"), "A": Color("#ffb030"), "F": Color("#7af0ff"), "G": Color("#ffffff")}
const SHIP_PAST: Dictionary = {"D": Color("#3a1e08"), "M": Color("#7a4612"), "L": Color("#c07a22"), "H": Color("#ffd890"),
	"C": Color("#ffe8b0"), "W": Color("#fff6e0"), "A": Color("#ffb030"), "F": Color("#ffc860"), "G": Color("#fff0c8")}


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(3):
		out[id + "_qubit_%d" % f] = Kit.outline(_qubit(f))
		out[id + "_pbomb_%d" % f] = Kit.outline(_pbomb(f))
	for f2: int in range(2):
		out[id + "_echo_%d" % f2] = Kit.outline(_ship(f2, SHIP_NOW))
		out[id + "_ghost_%d" % f2] = Kit.outline(_ship(f2, SHIP_PAST), Color("#1a0c04"))

	# Amber "past" shot: a small ember with a ring.
	var shot: Image = Kit.blank(7, 7)
	Kit.disc(shot, 3.5, 3.5, 3.5, Color(1.0, 0.65, 0.15, 0.45))
	Kit.disc(shot, 3.5, 3.5, 2.6, AMBER)
	Kit.disc(shot, 3.5, 3.5, 1.4, AMBER_HI)
	Kit.put(shot, 3, 3, WHITE)
	out[id + "_shot"] = shot

	# Violet-white "probability" shot: a little diamond.
	var q: Image = Kit.blank(9, 9)
	Painter.poly(q, PackedVector2Array([Vector2(4.5, 0.0), Vector2(9.0, 4.5), Vector2(4.5, 9.0), Vector2(0.0, 4.5)]), Color(0.75, 0.6, 1.0, 0.45))
	Painter.poly(q, PackedVector2Array([Vector2(4.5, 1.5), Vector2(7.5, 4.5), Vector2(4.5, 7.5), Vector2(1.5, 4.5)]), Color("#c8a8ff"))
	Painter.poly(q, PackedVector2Array([Vector2(4.5, 3.0), Vector2(6.0, 4.5), Vector2(4.5, 6.0), Vector2(3.0, 4.5)]), WHITE)
	out[id + "_qshot"] = q

	out[id + "_scout"] = Kit.outline(_g_scout())
	out[id + "_swooper"] = Kit.outline(_g_swooper())
	out[id + "_sniper"] = Kit.outline(_g_sniper())
	out[id + "_cruiser"] = Kit.outline(_g_cruiser())
	for f3: int in range(3):
		out["boss_%s_%d" % [id, f3]] = Kit.outline(_engine(f3))
	return out


static func _ring(img: Image, c: Vector2, rx: float, ry: float, col: Color, from_a: float = 0.0, to_a: float = TAU) -> void:
	var steps: int = int(maxf(rx, ry) * 7.0) + 4
	for i: int in range(steps + 1):
		var a: float = lerpf(from_a, to_a, float(i) / float(steps))
		Kit.put(img, int(roundf(c.x + cos(a) * rx)), int(roundf(c.y + sin(a) * ry)), col)


static func _over(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.3:
		img.set_pixel(x, y, col)


# --- enemies ---------------------------------------------------------------------------------------

# Superposition drone: an octahedral crystal round a lens, two orbiting quanta. Frame 0 is its
# uncertain self (hollow facets, dim lens), frame 1 collapsed and solid, frame 2 charging.
static func _qubit(frame: int) -> Image:
	var img: Image = Kit.blank(19, 19)
	var c: Vector2 = Vector2(9.5, 9.5)
	var top: Vector2 = Vector2(9.5, 0.5)
	var bot: Vector2 = Vector2(9.5, 18.5)
	var lft: Vector2 = Vector2(1.0, 9.5)
	var rgt: Vector2 = Vector2(18.0, 9.5)
	var mid_l: Vector2 = Vector2(7.0, 9.5)
	if frame == 0:
		Painter.poly(img, PackedVector2Array([top, rgt, bot, lft]), Color("#120c2a"))
		Kit.line(img, top, lft, CYAN)
		Kit.line(img, lft, bot, CYAN_DK)
		Kit.line(img, top, rgt, VIOLET[3])
		Kit.line(img, rgt, bot, VIOLET[2])
		Kit.line(img, top, mid_l, Color("#2e5a78"))
		Kit.line(img, mid_l, bot, Color("#2e5a78"))
		Kit.line(img, lft, rgt, Color("#3a2c70"))
		Kit.disc(img, c.x - 1.5, c.y, 2.2, Color("#1a3a58"))
		Kit.disc(img, c.x - 1.5, c.y, 1.0, CYAN)
	else:
		Painter.poly(img, PackedVector2Array([top, mid_l, lft]), VIOLET[3])
		Painter.poly(img, PackedVector2Array([top, rgt, mid_l]), VIOLET[2])
		Painter.poly(img, PackedVector2Array([lft, mid_l, bot]), VIOLET[1])
		Painter.poly(img, PackedVector2Array([mid_l, rgt, bot]), VIOLET[0])
		Kit.line(img, top, lft, RIFT)
		Kit.line(img, top, rgt, VIOLET[3])
		Kit.line(img, top, mid_l, Color("#d8d0ff"))
		var lens: Color = CYAN if frame == 1 else WHITE
		Kit.disc(img, c.x - 1.5, c.y, 3.0, Color("#0a1a2a"))
		Kit.disc(img, c.x - 1.5, c.y, 2.0, lens)
		Kit.put(img, int(c.x) - 3, int(c.y) - 1, WHITE)
		if frame == 2:
			_ring(img, Vector2(c.x - 1.5, c.y), 3.5, 3.5, AMBER)
	# the two quanta on their tilted orbit
	var q0: Vector2 = c + Vector2(cos(0.6) * 8.5, sin(0.6) * 3.0)
	var q1: Vector2 = c - Vector2(cos(0.6) * 8.5, sin(0.6) * 3.0)
	Kit.put(img, int(q0.x), int(q0.y), CYAN_HI if frame > 0 else CYAN)
	Kit.put(img, int(q1.x), int(q1.y), AMBER if frame > 0 else AMBER_DK)
	return img


# Echo ship: a swept dart with a tall tail fin, a cyan canopy and an amber clock ring on its flank.
# Frame 1 has the long engine flame.
static func _ship(frame: int, pal: Dictionary) -> Image:
	var rows: PackedStringArray = PackedStringArray([
		"...............DDH.......",
		"..............DMMH.......",
		".............DMLLH.......",
		"......DDDDDDDMLLLHDD.....",
		"...DDMMLLLLLLLLLLLMMDF...",
		"DDMMLLHHCCWLLLAALMMMMDFF.",
		"HHLLHHHCCCWLLAMMALLLMDFFG",
		"DDMMLLLLLLLLLLAALMMMMDFF.",
		"...DDMMMMMMMMMMMMMMMDF...",
		"......DDDDMMMMDDDDDD.....",
		"..........DMMLD..........",
		"...........DDLH..........",
		"............DDH..........",
	])
	if frame == 1:
		rows[5] = "DDMMLLHHCCWLLLAALMMMMDFFGG"
		rows[6] = "HHLLHHHCCCWLLAMMALLLMDFFGGG"
		rows[7] = "DDMMLLLLLLLLLLAALMMMMDFFGG"
	# pad every row to the same width so both frames stay centred alike
	for r: int in range(rows.size()):
		while rows[r].length() < 27:
			rows[r] = rows[r] + "."
	return Kit.rows(rows, pal)


# Probability bomb: a dark sphere banded with a ring of white pips (a die that never settles),
# split by a cyan and an amber meridian. The pips turn round it frame by frame; frame 2 glows.
static func _pbomb(frame: int) -> Image:
	var img: Image = Kit.blank(21, 21)
	var c: Vector2 = Vector2(10.5, 10.5)
	Kit.ball(img, c.x, c.y, 9.5, 9.5, VIOLET)
	# meridians
	for y: int in range(2, 19):
		var t: float = (float(y) + 0.5 - c.y) / 9.0
		var hw: float = sqrt(maxf(0.0, 1.0 - t * t)) * 9.0
		var rot: float = float(frame) * 0.7
		var mx0: float = c.x + sin(rot) * hw
		var mx1: float = c.x + sin(rot + PI * 0.5) * hw
		_over(img, int(mx0), y, CYAN_DK if cos(rot) > 0.0 else Color("#0e3a50"))
		_over(img, int(mx1), y, AMBER_DK if cos(rot + PI * 0.5) > 0.0 else Color("#4a2808"))
	# equatorial band: a cyan half and an amber half, with pips turning round it
	for x: int in range(2, 19):
		var e: float = (float(x) + 0.5 - c.x) / 9.0
		var ey: int = int(c.y + 1.0 + sqrt(maxf(0.0, 1.0 - e * e)) * 1.2)
		_over(img, x, ey, CYAN if e < -0.1 else (AMBER if e > 0.1 else WHITE))
		_over(img, x, ey + 1, CYAN_DK if e < 0.0 else AMBER_DK)
	for i: int in range(6):
		var a: float = float(i) * TAU / 6.0 + float(frame) * 0.45
		var front: float = cos(a)
		if front < -0.2:
			continue
		var px: float = c.x + sin(a) * 8.0
		var py: float = c.y - 1.0 + cos(a) * 1.2
		var col: Color = WHITE if front > 0.5 else Color("#9a8ad0")
		Kit.put(img, int(px), int(py), col)
		if front > 0.7:
			Kit.put(img, int(px), int(py) - 1, Color("#d8d0ff"))
	# fuse cap with a tiny clock face
	Kit.rect(img, 8, 0, 5, 2, STEEL[2])
	Kit.put(img, 10, 0, AMBER if frame == 2 else STEEL[3])
	if frame == 2:
		Kit.disc(img, c.x - 2.0, c.y - 2.0, 2.2, Color("#f0e8ff"))
		_ring(img, c, 9.8, 9.8, Color(0.85, 0.75, 1.0, 0.9))
	else:
		Kit.disc(img, c.x - 3.0, c.y - 3.0, 1.4, Color("#c8c0f0"))
	return img


# --- generic re-skins ------------------------------------------------------------------------------

# Scout: a small crystal shard with a cyan eye.
static func _g_scout() -> Image:
	var img: Image = Kit.blank(15, 11)
	Painter.poly(img, PackedVector2Array([Vector2(0, 5.5), Vector2(8, 0), Vector2(15, 3), Vector2(12, 5.5), Vector2(15, 8), Vector2(8, 11)]), VIOLET[1])
	Painter.poly(img, PackedVector2Array([Vector2(0, 5.5), Vector2(8, 0), Vector2(10, 5.5)]), VIOLET[3])
	Painter.poly(img, PackedVector2Array([Vector2(0, 5.5), Vector2(10, 5.5), Vector2(8, 11)]), VIOLET[2])
	Kit.disc(img, 6.0, 5.5, 1.6, CYAN)
	Kit.put(img, 5, 5, WHITE)
	Kit.put(img, 14, 5, AMBER)
	return img


# Swooper: two hourglass blades swept back from a lens.
static func _g_swooper() -> Image:
	var img: Image = Kit.blank(21, 15)
	Painter.poly(img, PackedVector2Array([Vector2(3, 7.5), Vector2(20, 0), Vector2(15, 7.5)]), VIOLET[1])
	Painter.poly(img, PackedVector2Array([Vector2(3, 7.5), Vector2(15, 7.5), Vector2(20, 15)]), VIOLET[0])
	Kit.line(img, Vector2(3, 7), Vector2(20, 0), CYAN)
	Kit.line(img, Vector2(3, 8), Vector2(20, 15), AMBER_DK)
	Kit.ball(img, 6.0, 7.5, 4.0, 2.6, VIOLET)
	Kit.put(img, 4, 7, CYAN_HI)
	Kit.rect(img, 13, 6, 3, 3, AMBER)
	return img


# Sniper: a clock face with ticks round a lens.
static func _g_sniper() -> Image:
	var img: Image = Kit.blank(17, 17)
	Kit.ball(img, 8.5, 8.5, 8.0, 8.0, STEEL)
	for i: int in range(12):
		var a: float = float(i) * TAU / 12.0
		Kit.put(img, int(roundf(8.5 + cos(a) * 6.5)), int(roundf(8.5 + sin(a) * 6.5)), AMBER if i % 3 == 0 else Color("#8a7ac8"))
	Kit.disc(img, 7.0, 8.5, 3.2, Color("#0a0818"))
	Kit.disc(img, 7.0, 8.5, 2.0, CYAN)
	Kit.put(img, 6, 7, WHITE)
	Kit.line(img, Vector2(8.5, 8.5), Vector2(8.5, 3.0), AMBER_HI)
	return img


# Cruiser: a heavy prism hull with an hourglass emblem and amber windows.
static func _g_cruiser() -> Image:
	var img: Image = Kit.blank(32, 21)
	Painter.poly(img, PackedVector2Array([Vector2(0, 10.5), Vector2(9, 2), Vector2(30, 1), Vector2(32, 10.5), Vector2(30, 20), Vector2(9, 19)]), VIOLET[1])
	Painter.poly(img, PackedVector2Array([Vector2(0, 10.5), Vector2(9, 2), Vector2(30, 1), Vector2(26, 10.5)]), VIOLET[2])
	Painter.poly(img, PackedVector2Array([Vector2(0, 10.5), Vector2(26, 10.5), Vector2(30, 20), Vector2(9, 19)]), VIOLET[0])
	Kit.line(img, Vector2(9, 2), Vector2(30, 1), RIFT)
	Kit.line(img, Vector2(0, 10), Vector2(9, 2), VIOLET[3])
	# hourglass emblem
	Painter.poly(img, PackedVector2Array([Vector2(15, 5), Vector2(21, 5), Vector2(18, 10.5)]), CYAN_DK)
	Painter.poly(img, PackedVector2Array([Vector2(18, 10.5), Vector2(21, 16), Vector2(15, 16)]), AMBER_DK)
	Kit.put(img, 18, 7, CYAN)
	Kit.put(img, 18, 14, AMBER)
	for wx: int in [6, 10, 25]:
		Kit.put(img, wx, 12, AMBER)
	Kit.rect(img, 30, 7, 2, 7, CYAN)
	return img


# --- THE PARADOX ENGINE -----------------------------------------------------------------------------
# An hourglass held in an impossible (Penrose) triangle: its upper bulb holds the present (cyan
# light), the lower the past (amber), a stream of white light falling through an aperture at
# the waist. Behind it a broken clock ring. Frames 0/1: the light sifts and the frame's rim
# lights travel; frame 2: the aperture opens wide.

const ENG_W: int = 120
const ENG_H: int = 160


static func _engine(frame: int) -> Image:
	var img: Image = BossPainter._new_img(ENG_W, ENG_H)
	var c: Vector2 = Vector2(64.0, 80.0)
	# broken clock ring behind (a gap where time leaks out)
	for band: int in range(3):
		var r: float = 56.0 + float(band)
		var col: Color = [Color("#2a2050"), Color("#4a3c88"), Color("#1a1438")][band]
		_ring(img, c, r, r, col, 0.5, TAU - 0.35)
	for i: int in range(12):
		var a: float = float(i) * TAU / 12.0 + 0.2
		if a > TAU - 0.35 or a < 0.5:
			continue
		var d: Vector2 = Vector2.from_angle(a)
		var tick_col: Color = AMBER if i % 3 == 0 else Color("#8a7ac8")
		Kit.line(img, c + d * 52.0, c + d * (55.0 if i % 3 != 0 else 50.0), tick_col)
	_penrose(img, c, frame)
	_hourglass(img, c, frame)
	return img


# Three bars of an impossible triangle (cyan, violet, amber), each passing over the next at one
# corner and under it at the other.
static func _penrose(img: Image, c: Vector2, frame: int) -> void:
	var p: Array[Vector2] = [Vector2(6.0, 80.0), Vector2(114.0, 12.0), Vector2(114.0, 148.0)]
	var centroid: Vector2 = (p[0] + p[1] + p[2]) / 3.0
	var q: Array[Vector2] = []
	var m: Array[Vector2] = []
	for i: int in range(3):
		var dir: Vector2 = (centroid - p[i]).normalized()
		q.append(p[i] + dir * 22.0)
		m.append(p[i] + dir * 11.0)
	var lights: Array[Color] = [Color("#3a9ac0"), Color("#46388a"), Color("#c0862e")]
	var darks: Array[Color] = [Color("#123a58"), Color("#1e1844"), Color("#5a3410")]
	var rims: Array[Color] = [CYAN_HI, Color("#c8b8ff"), AMBER_HI]
	for i2: int in range(3):
		_bar(img, p, q, m, i2, 0.0, 1.0, lights[i2], darks[i2], rims[i2], frame)
	# bar 0 crosses back over bar 2 at the first corner: the impossible joint
	_bar(img, p, q, m, 0, 0.0, 0.3, lights[0], darks[0], rims[0], frame)


static func _bar(img: Image, p: Array[Vector2], q: Array[Vector2], m: Array[Vector2], i: int, t0: float, t1: float, light: Color, dark: Color, rim: Color, frame: int) -> void:
	var j: int = (i + 1) % 3
	var a0: Vector2 = p[i].lerp(p[j], t0)
	var a1: Vector2 = p[i].lerp(p[j], t1)
	var b0: Vector2 = m[i].lerp(m[j], t0)
	var b1: Vector2 = m[i].lerp(m[j], t1)
	var c0: Vector2 = q[i].lerp(q[j], t0)
	var c1: Vector2 = q[i].lerp(q[j], t1)
	Painter.poly(img, PackedVector2Array([a0, a1, b1, b0]), light)
	Painter.poly(img, PackedVector2Array([b0, b1, c1, c0]), dark)
	Kit.line(img, a0, a1, rim)
	Kit.line(img, c0, c1, Color("#0a0818"))
	Kit.line(img, b0, b1, light.darkened(0.25))
	# a travelling rim light
	var k: float = fposmod(0.15 + float(frame) * 0.33 + float(i) * 0.21, 1.0)
	if k >= t0 and k <= t1:
		var hp: Vector2 = p[i].lerp(p[j], k)
		Kit.disc(img, hp.x, hp.y, 1.4, WHITE)


static func _hourglass(img: Image, c: Vector2, frame: int) -> void:
	var waist: float = c.y
	var top_y: float = c.y - 50.0
	var bot_y: float = c.y + 50.0
	# frame posts and caps
	for sx: float in [-24.0, 24.0]:
		Kit.rect(img, int(c.x + sx) - 1, int(top_y), 3, int(bot_y - top_y), STEEL[1])
		Kit.rect(img, int(c.x + sx), int(top_y), 1, int(bot_y - top_y), STEEL[3])
	for cy: float in [top_y - 4.0, bot_y]:
		BossPainter._armor_plate(img, int(c.x) - 30, int(cy), 60, 6, STEEL[2], STEEL[3], STEEL[0], false)
		Kit.rect(img, int(c.x) - 28, int(cy) + 2, 56, 1, AMBER_DK)
	# glass bulbs: half-width as a function of y
	var sand_top: float = c.y - 30.0 + float(frame) * 3.0
	var pile: float = 14.0 + float(frame) * 2.0
	for y: int in range(int(top_y) + 2, int(bot_y)):
		var fy: float = float(y) + 0.5
		var t: float = absf(fy - waist) / 50.0
		var hw: float = 2.0 + 18.0 * pow(sin(minf(t, 1.0) * PI * 0.5), 0.8)
		if t > 0.9:
			hw *= 1.0 - (t - 0.9) * 3.0
		for x: int in range(int(c.x - hw), int(c.x + hw) + 1):
			var col: Color = Color("#0a0818")
			var fx: float = float(x) + 0.5
			if fy < waist:
				if fy > sand_top:
					var k: float = (fy - sand_top) / maxf(1.0, waist - sand_top)
					col = Color("#3ab8d8") if Painter.bayer(x, y) < 0.4 + k * 0.5 else Color("#1a6a90")
					if absf(fx - c.x) < 1.0 and k < 0.15:
						col = CYAN_HI
			else:
				var mound: float = bot_y - pile * (1.0 - pow(absf(fx - c.x) / 20.0, 2.0))
				if fy > mound:
					col = AMBER if Painter.bayer(x, y) < 0.55 else Color("#b06a18")
					if fy < mound + 1.5:
						col = AMBER_HI
			# glass edge and highlight
			if x == int(c.x - hw) or x == int(c.x + hw):
				col = Color("#9ab0e8")
			elif x == int(c.x - hw) + 2 and t > 0.25:
				col = col.lerp(Color("#d8e8ff"), 0.45)
			img.set_pixel(x, y, col)
	# the falling stream of light
	var stream_end: float = bot_y - pile + 1.0
	for y2: int in range(int(waist) - 2, int(stream_end)):
		var on: bool = (y2 + frame * 2) % 5 != 0
		if on:
			img.set_pixel(int(c.x), y2, WHITE if y2 < int(waist) + 6 else Color("#ffe8c0"))
	# aperture at the waist, facing the ship
	var ax: float = c.x - 16.0
	var open: float = 2.0 if frame < 2 else 5.5
	BossPainter._armor_plate(img, int(ax) - 9, int(waist) - 8, 14, 16, STEEL[2], STEEL[3], STEEL[0], false)
	for y3: int in range(int(waist - open), int(waist + open) + 1):
		var w: float = (open - absf(float(y3) - waist)) * 1.2 + 1.0
		for x3: int in range(int(ax - w), int(ax + w) + 1):
			img.set_pixel(x3, y3, WHITE if frame == 2 else Color("#c8a8ff"))
	Kit.put(img, int(ax) - 1, int(waist) - 1, WHITE)
	if frame == 2:
		BossPainter._glow_orb(img, int(ax), int(waist), 4, Color("#7a5ae8"), Color("#e0d8ff"), WHITE)
