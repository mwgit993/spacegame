extends RefCounted

# STAGE 24 sprites (worker thread: Images only). Carved grey-green stone, weathered gold and
# glowing jade; eyes and charged glyphs burn a pale sun-gold. Every key starts with the stage id
# (or "boss_<id>").

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const STONE: Array[Color] = [Color("#1a221e"), Color("#36443c"), Color("#5a6a5e"), Color("#92a294")]
const JADE: Array[Color] = [Color("#0c3a2a"), Color("#1d7a56"), Color("#3cc890"), Color("#b0f4d4")]
const GOLD: Array[Color] = [Color("#5a3a10"), Color("#a87020"), Color("#e0b040"), Color("#fff2a8")]
const DARK: Color = Color("#0a0e0c")
const GLOW: Color = Color("#fff0a0")
const HOT: Color = Color("#ffffff")
const MOSS: Color = Color("#1e4a26")

# Carved glyphs (7x7): an eye, a sun cross and a serpent.
const SYMBOLS: Array = [
	[".XXXXX.", "X.....X", "X.XXX.X", "X.X.X.X", "X.XXX.X", "X.....X", ".XXXXX."],
	["...X...", ".X.X.X.", "..XXX..", "XXX.XXX", "..XXX..", ".X.X.X.", "...X..."],
	["XXXXX..", "....X..", ".XXXX..", ".X.....", ".XXXXXX", "......X", "..XXXXX"],
]


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(2):
		out[id + "_guard_%d" % f] = Kit.outline(_guardian(f))
		out[id + "_chakram_%d" % f] = Kit.outline(_chakram(f))
	for s: int in range(3):
		out[id + "_glyph_%d" % s] = Kit.outline(_glyph(s, false))
		out[id + "_glyph_lit_%d" % s] = Kit.outline(_glyph(s, true))

	# The stage's own shot: a jade diamond in a gold rim.
	out[id + "_shot"] = Kit.rows(PackedStringArray([
		"...G...",
		"..GJG..",
		".GJWJG.",
		"GJWWWJG",
		".GJWJG.",
		"..GJG..",
		"...G...",
	]), {"G": GOLD[2], "J": Color("#3cf0a0"), "W": Color("#e8fff4")})
	# Beam pellets (guardian eyes, the idol's gaze): white-hot sun-gold.
	var ray: Image = Kit.blank(7, 7)
	Kit.disc(ray, 3.5, 3.5, 3.5, Color(1.0, 0.62, 0.16, 0.85))
	Kit.disc(ray, 3.5, 3.5, 2.5, GLOW)
	Kit.disc(ray, 3.5, 3.5, 1.3, HOT)
	out[id + "_ray"] = ray
	# The idol's thrown glyph tablet (a big shot that shatters).
	out[id + "_tablet"] = Kit.outline(_glyph(1, true))

	out[id + "_scout"] = Kit.outline(_g_scout())
	out[id + "_swooper"] = Kit.outline(_g_swooper())
	out[id + "_sniper"] = Kit.outline(_g_sniper())
	out[id + "_cruiser"] = Kit.outline(_g_cruiser())
	for f2: int in range(3):
		out["boss_%s_%d" % [id, f2]] = Kit.outline(_idol(f2))
	return out


static func _over(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.3:
		img.set_pixel(x, y, col)


static func _symbol(img: Image, sym: int, x0: int, y0: int, col: Color) -> void:
	var rows: Array = SYMBOLS[sym]
	for y: int in range(rows.size()):
		var row: String = String(rows[y])
		for x: int in range(row.length()):
			if row[x] == "X":
				Kit.put(img, x0 + x, y0 + y, col)


static func _poly(img: Image, pts: Array, col: Color) -> void:
	Painter.poly(img, PackedVector2Array(pts), col)


# --- enemies ---------------------------------------------------------------------------------------

# Guardian: a colossal carved head broken off its statue, floating on the jade light leaking from
# its sheared neck: a domed helmet with a gold band and jade studs, a heavy brow over deep eye
# sockets, a broad nose, thick lips, gold ear flares; cracked and mossy. Frame 1: its eyes and
# the neck light blaze.
static func _guardian(frame: int) -> Image:
	var img: Image = Kit.blank(32, 32)
	# helmet dome and face mass
	Kit.ball(img, 16.0, 13.0, 14.0, 12.0, STONE)
	Kit.rect(img, 3, 13, 26, 13, STONE[1])
	Kit.rect(img, 3, 13, 2, 13, STONE[2])
	Kit.rect(img, 27, 13, 2, 13, STONE[0])
	Kit.ball(img, 16.0, 24.0, 12.0, 5.0, STONE)
	# sheared neck: jagged break with jade light in the cracks
	for x: int in range(6, 26):
		var jag: int = 27 + int(absf(sin(float(x) * 1.7)) * 3.0)
		Kit.rect(img, x, 26, 1, jag - 26, STONE[1])
		Kit.put(img, x, jag, JADE[2] if frame == 1 else JADE[1])
		if x % 3 == 0:
			Kit.put(img, x, jag + 1, JADE[3] if frame == 1 else JADE[2])
	# helmet band with jade studs and a little crest
	Kit.rect(img, 3, 8, 26, 4, GOLD[1])
	Kit.rect(img, 3, 8, 26, 1, GOLD[2])
	Kit.rect(img, 3, 11, 26, 1, GOLD[0])
	for s: int in range(5):
		Kit.rect(img, 5 + s * 5, 9, 2, 2, JADE[2])
		Kit.put(img, 5 + s * 5, 9, JADE[3])
	_poly(img, [Vector2(12, 3), Vector2(16, 0), Vector2(20, 3)], GOLD[2])
	# heavy brow
	Kit.rect(img, 4, 12, 24, 2, STONE[3])
	Kit.rect(img, 4, 14, 24, 1, DARK)
	# eye sockets and eyes
	for ex: int in [7, 19]:
		Kit.rect(img, ex - 1, 15, 8, 3, DARK)
		if frame == 0:
			Kit.rect(img, ex, 16, 6, 1, STONE[0])
		else:
			Kit.rect(img, ex, 15, 6, 3, GOLD[2])
			Kit.rect(img, ex + 1, 15, 4, 3, GLOW)
			Kit.rect(img, ex + 2, 16, 2, 1, HOT)
	# broad nose
	Kit.rect(img, 13, 16, 6, 5, STONE[2])
	Kit.rect(img, 13, 16, 1, 5, STONE[3])
	Kit.rect(img, 12, 20, 8, 1, STONE[0])
	Kit.put(img, 14, 20, DARK)
	Kit.put(img, 17, 20, DARK)
	# thick lips (parted and glowing in frame 1)
	Kit.rect(img, 9, 22, 14, 2, STONE[2])
	Kit.rect(img, 9, 24, 14, 1, STONE[2])
	Kit.rect(img, 10, 23, 12, 1, GOLD[2] if frame == 1 else DARK)
	# gold ear flares
	for sx: int in [1, 28]:
		Kit.disc(img, float(sx) + 1.5, 18.0, 2.6, GOLD[1])
		Kit.put(img, sx + 1, 18, DARK)
		Kit.put(img, sx + 1, 16, GOLD[3])
	# cracks and moss
	Kit.line(img, Vector2(24, 4), Vector2(22, 10), STONE[0])
	Kit.line(img, Vector2(25, 15), Vector2(26, 21), STONE[0])
	Kit.line(img, Vector2(6, 19), Vector2(8, 22), STONE[0])
	for m: int in range(6):
		_over(img, 5 + m * 4, 4 + (m % 2) * 2, MOSS)
	_over(img, 4, 22, MOSS)
	_over(img, 27, 24, MOSS)
	return img


# Glyph sentinel: a floating rune tablet with a gold cap, its symbol carved (dim) or burning
# jade (lit, while its sigil charges).
static func _glyph(sym: int, lit: bool) -> Image:
	var img: Image = Kit.blank(13, 15)
	Kit.rect(img, 1, 1, 11, 13, STONE[1])
	Kit.rect(img, 1, 1, 11, 1, STONE[3])
	Kit.rect(img, 1, 1, 1, 13, STONE[2])
	Kit.rect(img, 11, 2, 1, 12, STONE[0])
	Kit.rect(img, 1, 13, 11, 1, STONE[0])
	# rounded corners
	for c: Vector2i in [Vector2i(1, 1), Vector2i(11, 1), Vector2i(1, 13), Vector2i(11, 13)]:
		img.set_pixel(c.x, c.y, Color(0, 0, 0, 0))
	# gold cap and foot
	Kit.rect(img, 3, 0, 7, 1, GOLD[2])
	Kit.rect(img, 4, 14, 5, 1, GOLD[1])
	if lit:
		# glow bleeding round the carving
		for y: int in range(3, 12):
			for x: int in range(2, 11):
				if Painter.bayer(x, y) < 0.35:
					Kit.put(img, x, y, JADE[0])
		_symbol(img, sym, 3, 4, JADE[3])
		Kit.put(img, 6, 7, HOT)
	else:
		_symbol(img, sym, 3, 4, DARK)
		# the carving's lit lower edge
		var rows2: Array = SYMBOLS[sym]
		for y2: int in range(rows2.size()):
			var row2: String = String(rows2[y2])
			for x2: int in range(row2.length()):
				var below: String = String(rows2[y2 + 1]) if y2 + 1 < rows2.size() else "......."
				if row2[x2] == "X" and below[x2] != "X":
					Kit.put(img, 3 + x2, 5 + y2, JADE[1])
	return img


# Sun chakram: a gold ring with six hooked blades round a jade gem. Frame 1: thrown, the blades
# white-hot along their edges.
static func _chakram(frame: int) -> Image:
	var img: Image = Kit.blank(21, 21)
	var c: Vector2 = Vector2(10.5, 10.5)
	for b: int in range(6):
		var a: float = float(b) * TAU / 6.0
		var p0: Vector2 = c + Vector2.from_angle(a - 0.32) * 6.5
		var p1: Vector2 = c + Vector2.from_angle(a + 0.42) * 10.2
		var p2: Vector2 = c + Vector2.from_angle(a + 0.36) * 6.5
		_poly(img, [p0, p1, p2], GOLD[1])
		Kit.line(img, p0, p1, GOLD[3] if frame == 1 else GOLD[2])
	Kit.disc(img, c.x, c.y, 7.0, GOLD[0])
	Kit.disc(img, c.x, c.y, 6.2, GOLD[1])
	Kit.disc(img, c.x - 0.6, c.y - 0.6, 5.0, GOLD[2])
	Kit.disc(img, c.x, c.y, 3.6, DARK)
	Kit.disc(img, c.x, c.y, 2.6, JADE[1])
	Kit.disc(img, c.x - 0.4, c.y - 0.4, 1.6, JADE[2])
	Kit.put(img, 9, 9, JADE[3])
	# carved notches on the ring
	for n: int in range(8):
		var q: Vector2 = c + Vector2.from_angle(float(n) * TAU / 8.0 + 0.2) * 5.2
		Kit.put(img, int(q.x), int(q.y), GOLD[0])
	if frame == 1:
		Kit.put(img, 7, 6, GOLD[3])
		Kit.put(img, 13, 14, GOLD[3])
	return img


# --- generic re-skins ------------------------------------------------------------------------------

# Scout: a jade dart-drone with a gold beak.
static func _g_scout() -> Image:
	var img: Image = Kit.blank(15, 11)
	_poly(img, [Vector2(0, 5), Vector2(6, 1), Vector2(14, 2), Vector2(14, 8), Vector2(6, 9)], JADE[1])
	_poly(img, [Vector2(1, 5), Vector2(6, 2), Vector2(12, 3), Vector2(6, 5)], JADE[2])
	_poly(img, [Vector2(0, 5), Vector2(4, 3), Vector2(4, 7)], GOLD[2])
	Kit.rect(img, 9, 4, 4, 3, STONE[1])
	Kit.put(img, 5, 4, GLOW)
	Kit.line(img, Vector2(13, 2), Vector2(14, 0), GOLD[1])
	Kit.line(img, Vector2(13, 8), Vector2(14, 10), GOLD[1])
	return img


# Swooper: a feathered gold serpent-bird construct.
static func _g_swooper() -> Image:
	var img: Image = Kit.blank(20, 14)
	_poly(img, [Vector2(6, 6), Vector2(14, 0), Vector2(19, 1), Vector2(13, 6)], GOLD[1])
	_poly(img, [Vector2(6, 8), Vector2(13, 8), Vector2(19, 13), Vector2(14, 14)], GOLD[1])
	for f: int in range(3):
		Kit.line(img, Vector2(9 + f * 3, 5), Vector2(13 + f * 2, 1), GOLD[2])
		Kit.line(img, Vector2(9 + f * 3, 9), Vector2(13 + f * 2, 13), GOLD[0])
	Kit.ball(img, 7.0, 7.0, 5.0, 3.0, JADE)
	_poly(img, [Vector2(0, 7), Vector2(3, 5), Vector2(3, 9)], GOLD[2])
	Kit.put(img, 4, 6, GLOW)
	return img


# Sniper: a stone eye-totem with gold rings.
static func _g_sniper() -> Image:
	var img: Image = Kit.blank(14, 18)
	Kit.rect(img, 2, 1, 10, 16, STONE[1])
	Kit.rect(img, 2, 1, 10, 1, STONE[3])
	Kit.rect(img, 2, 1, 1, 16, STONE[2])
	Kit.rect(img, 1, 4, 12, 2, GOLD[1])
	Kit.rect(img, 1, 13, 12, 2, GOLD[1])
	Kit.disc(img, 6.0, 9.5, 3.2, DARK)
	Kit.disc(img, 5.5, 9.5, 2.0, GOLD[2])
	Kit.put(img, 5, 9, GLOW)
	Kit.put(img, 3, 16, MOSS)
	return img


# Cruiser: a floating stone barge with a gold-roofed shrine and jade lanterns.
static func _g_cruiser() -> Image:
	var img: Image = Kit.blank(30, 20)
	_poly(img, [Vector2(0, 12), Vector2(4, 9), Vector2(29, 9), Vector2(29, 17), Vector2(5, 17)], STONE[1])
	Kit.rect(img, 4, 9, 25, 1, STONE[3])
	Kit.rect(img, 5, 16, 24, 1, STONE[0])
	for g: int in range(4):
		_symbol_small(img, 9 + g * 5, 12)
	Kit.rect(img, 12, 3, 14, 6, STONE[2])
	_poly(img, [Vector2(10, 4), Vector2(19, 0), Vector2(28, 4)], GOLD[1])
	Kit.line(img, Vector2(10, 4), Vector2(19, 0), GOLD[3])
	Kit.rect(img, 14, 5, 3, 4, DARK)
	Kit.rect(img, 21, 5, 3, 4, DARK)
	Kit.put(img, 15, 6, JADE[2])
	Kit.put(img, 22, 6, JADE[2])
	Kit.disc(img, 3.0, 13.0, 2.0, GOLD[2])
	Kit.put(img, 2, 12, GLOW)
	Kit.rect(img, 8, 17, 18, 2, Color(0.24, 0.78, 0.56, 0.6))
	return img


static func _symbol_small(img: Image, x: int, y: int) -> void:
	Kit.rect(img, x, y, 3, 1, JADE[1])
	Kit.put(img, x + 1, y + 1, JADE[2])
	Kit.rect(img, x, y + 2, 3, 1, JADE[1])


# --- GOD-MACHINE ITZAMAT --------------------------------------------------------------------------
# A towering idol of stone and gold floating on a stepped throne of light: a jade mask under a
# feathered gold headdress, a sun disc halo blazing behind its head, four arms holding glyph
# tablets. Frames 0/1: the halo's rays turn and its eyes smoulder; frame 2: eyes, mouth and
# tablets blaze, arms flung wide.
# Local anchors (sprite centre = image (66, 86)): eyes (-4,-32)/(14,-32), halo centre (12,-24),
# tablets upper-left (-47,-29), lower-left (-47,35), upper-right (51,-31), lower-right (49,39).

static func _idol(frame: int) -> Image:
	var img: Image = BossPainter._new_img(132, 172)
	var hc: Vector2 = Vector2(78.0, 62.0)
	# --- sun disc halo
	var turn: float = 0.0 if frame == 0 else (TAU / 32.0 if frame == 1 else TAU / 64.0)
	var ray_col: Color = GOLD[3] if frame == 2 else GOLD[2]
	for r: int in range(16):
		var a: float = turn + float(r) * TAU / 16.0
		var long: float = 58.0 if r % 2 == 0 else 52.0
		var p0: Vector2 = hc + Vector2.from_angle(a - 0.09) * 42.0
		var p1: Vector2 = hc + Vector2.from_angle(a) * long
		var p2: Vector2 = hc + Vector2.from_angle(a + 0.09) * 42.0
		_poly(img, [p0, p1, p2], GOLD[1])
		Kit.line(img, hc + Vector2.from_angle(a) * 43.0, p1, ray_col)
	Kit.disc(img, hc.x, hc.y, 44.0, GOLD[0])
	Kit.disc(img, hc.x, hc.y, 42.5, GOLD[1])
	Kit.disc(img, hc.x, hc.y, 39.0, STONE[0])
	Kit.disc(img, hc.x, hc.y, 37.0, STONE[1])
	# carved rings and jade inlays round the disc
	for ring: float in [33.0, 26.0]:
		for k: int in range(int(ring * 4.0)):
			var q: Vector2 = hc + Vector2.from_angle(float(k) / (ring * 4.0) * TAU) * ring
			Kit.put(img, int(q.x), int(q.y), STONE[0] if ring > 30.0 else STONE[2])
	for j: int in range(12):
		var q2: Vector2 = hc + Vector2.from_angle(turn * 2.0 + float(j) * TAU / 12.0) * 40.5
		Kit.rect(img, int(q2.x) - 1, int(q2.y) - 1, 2, 2, JADE[2] if frame != 2 else JADE[3])
	# --- stepped throne of light below
	for st: int in range(3):
		var w: int = 76 - st * 16
		var x0: int = 66 - w / 2 + 6
		var y0: int = 148 + st * 7
		BossPainter._armor_plate(img, x0, y0, w, 7, STONE[1], STONE[2], STONE[0], false)
		Kit.rect(img, x0 + 2, y0 + 3, w - 4, 1, JADE[2] if frame == 2 else JADE[1])
	for b: int in range(6):
		Kit.rect(img, 40 + b * 10, 168, 4, 4, Color(0.24, 0.9, 0.6, 0.55))
	# --- back (right) arms, behind the body
	var lift: float = -4.0 if frame == 2 else 0.0
	BossPainter._thick_line(img, Vector2(98, 94), Vector2(114, 66 + lift), 4, STONE[1], STONE[2])
	BossPainter._thick_line(img, Vector2(98, 116), Vector2(112, 132), 4, STONE[1], STONE[2])
	_tablet(img, 110, 46 + int(lift), frame == 2, 0)
	_tablet(img, 108, 116, frame == 2, 2)
	# --- torso
	BossPainter._armor_plate(img, 50, 82, 52, 66, STONE[1], STONE[2], STONE[0])
	Kit.rect(img, 54, 92, 44, 2, GOLD[1])
	for g: int in range(5):
		Kit.rect(img, 56 + g * 8, 98, 5, 5, DARK)
		Kit.rect(img, 57 + g * 8, 99, 3, 3, JADE[1] if frame != 2 else JADE[2])
	Kit.rect(img, 50, 118, 52, 6, GOLD[1])
	Kit.rect(img, 50, 118, 52, 1, GOLD[2])
	Kit.rect(img, 50, 123, 52, 1, GOLD[0])
	Kit.disc(img, 76.0, 121.0, 5.0, GOLD[2])
	Kit.disc(img, 76.0, 121.0, 3.0, JADE[2] if frame != 2 else GLOW)
	for p: int in range(4):
		Kit.rect(img, 54 + p * 12, 126, 8, 18, STONE[2] if p % 2 == 0 else STONE[1])
		Kit.rect(img, 54 + p * 12, 142, 8, 2, STONE[0])
	# moss and cracks
	Kit.line(img, Vector2(88, 84), Vector2(92, 110), STONE[0])
	Kit.line(img, Vector2(92, 110), Vector2(88, 116), STONE[0])
	for m: int in range(10):
		_over(img, 52 + m * 5, 146 - (m % 3), MOSS)
	# --- headdress plumes (gold feathers fanning up)
	for f: int in range(7):
		var fa: float = -PI * 0.5 + (float(f) - 3.0) * 0.26
		var base: Vector2 = Vector2(72.0, 40.0)
		var tip: Vector2 = base + Vector2.from_angle(fa) * (26.0 + float(3 - absi(f - 3)) * 3.0)
		BossPainter._thick_line(img, base, tip, 2, GOLD[1], GOLD[2])
		Kit.disc(img, tip.x, tip.y, 2.0, JADE[2])
	Kit.rect(img, 52, 34, 40, 6, GOLD[1])
	Kit.rect(img, 52, 34, 40, 1, GOLD[3])
	for s: int in range(5):
		Kit.rect(img, 55 + s * 8, 36, 3, 3, JADE[2])
	# --- jade mask
	Kit.rect(img, 54, 40, 36, 38, JADE[1])
	Kit.rect(img, 54, 40, 36, 2, JADE[2])
	Kit.rect(img, 54, 40, 2, 38, JADE[2])
	Kit.rect(img, 88, 42, 2, 36, JADE[0])
	Kit.rect(img, 56, 76, 32, 2, JADE[0])
	for c: Vector2i in [Vector2i(54, 40), Vector2i(89, 40), Vector2i(54, 77), Vector2i(89, 77)]:
		img.set_pixel(c.x, c.y, Color(0, 0, 0, 0))
	# brow, cheek bars, nose
	Kit.rect(img, 56, 48, 32, 2, JADE[0])
	Kit.rect(img, 57, 60, 6, 2, GOLD[2])
	Kit.rect(img, 81, 60, 6, 2, GOLD[2])
	Kit.rect(img, 70, 52, 5, 10, JADE[2])
	Kit.rect(img, 70, 61, 5, 1, JADE[0])
	# eyes
	for ex: int in [58, 76]:
		Kit.rect(img, ex, 51, 10, 6, DARK)
		match frame:
			0:
				Kit.rect(img, ex + 2, 53, 6, 2, GOLD[1])
				Kit.rect(img, ex + 4, 53, 2, 2, GOLD[2])
			1:
				Kit.rect(img, ex + 2, 53, 6, 2, GOLD[2])
				Kit.rect(img, ex + 4, 53, 2, 2, GLOW)
			_:
				Kit.rect(img, ex + 1, 52, 8, 4, GOLD[2])
				Kit.rect(img, ex + 2, 53, 6, 2, GLOW)
				Kit.rect(img, ex + 4, 53, 2, 2, HOT)
	# mouth with gold teeth (wide open, burning in frame 2)
	var mo: int = 6 if frame == 2 else 3
	Kit.rect(img, 61, 66, 22, mo, DARK)
	for t: int in range(5):
		Kit.rect(img, 63 + t * 4, 66, 2, 2, GOLD[2])
	if frame == 2:
		Kit.rect(img, 65, 69, 14, 2, GLOW)
	# ear plugs
	for ox: int in [50, 90]:
		Kit.disc(img, float(ox) + 2.0, 58.0, 4.0, GOLD[1])
		Kit.disc(img, float(ox) + 2.0, 58.0, 2.0, JADE[2])
	# --- front (left) arms over the body
	BossPainter._thick_line(img, Vector2(54, 92), Vector2(28, 66 + lift), 4, STONE[1], STONE[2])
	BossPainter._thick_line(img, Vector2(54, 114), Vector2(26, 124), 4, STONE[1], STONE[2])
	for bc: Vector2 in [Vector2(40, 79 + lift * 0.5), Vector2(40, 119)]:
		Kit.rect(img, int(bc.x) - 3, int(bc.y) - 3, 7, 6, GOLD[1])
		Kit.rect(img, int(bc.x) - 3, int(bc.y) - 3, 7, 1, GOLD[3])
	_tablet(img, 12, 48 + int(lift), frame == 2, 1)
	_tablet(img, 12, 112, frame == 2, 0)
	return img


static func _tablet(img: Image, x: int, y: int, lit: bool, sym: int) -> void:
	BossPainter._armor_plate(img, x, y, 15, 19, STONE[1], STONE[3], STONE[0], false)
	Kit.rect(img, x + 2, y, 11, 1, GOLD[2])
	Kit.rect(img, x + 2, y + 18, 11, 1, GOLD[1])
	if lit:
		Kit.rect(img, x + 3, y + 4, 9, 11, JADE[0])
		_symbol(img, sym, x + 4, y + 6, JADE[3])
	else:
		_symbol(img, sym, x + 4, y + 6, DARK)
