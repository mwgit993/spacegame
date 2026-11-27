extends RefCounted

# MIRROR WORLD sprites. build() runs on a worker thread, so it only paints Images. Every key
# starts with the stage id ("mirror_...", "boss_mirror_..."). Enemies face left, toward the player.
#
# The look is a photographic negative: dark hulls with bright edges, the player's colours
# inverted (cyan canopy -> red-orange, red wingtips -> cyan, yellow flame -> blue-violet), and
# a chromatic outline (cyan on left-facing edges, magenta on right-facing ones, silver on top
# and bottom) in place of the usual dark outline, like a slightly misaligned reflection.

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const EDGE_CYAN: Color = Color("#48d8f0")
const EDGE_MAGENTA: Color = Color("#e050c0")
const EDGE_SILVER: Color = Color("#a0acd0")
const HULL: Array[Color] = [Color("#090b13"), Color("#141827"), Color("#232a42"), Color("#39426a")]
const CHROME: Array[Color] = [Color("#2a3048"), Color("#5a6488"), Color("#a4b0d4"), Color("#eef4ff")]
const EYE: Color = Color("#ff5a30")
const EYE_D: Color = Color("#9c1e0e")
const EYE_HOT: Color = Color("#ffd8c0")
const TIP: Color = Color("#28f0e0")
const TIP_D: Color = Color("#10827a")
const FLAME: Color = Color("#8a7aff")
const FLAME_D: Color = Color("#3a28c8")

# Negative-film palette for the player's ship rows and the generic enemy shapes.
const NEG: Dictionary = {
	"W": Color("#0c0e18"), "L": Color("#1e2236"), "S": Color("#3c4462"), "D": Color("#9aa8d8"), "N": Color("#e4ecff"),
	"C": Color("#ff4a28"), "B": Color("#a8200c"), "R": Color("#28f0e0"), "r": Color("#12807a"),
	"O": Color("#3020c8"), "Y": Color("#7a6aff"), "G": Color("#ff5ad8"), "g": Color("#7a1e66"),
	"P": Color("#b8c2e4"), "p": Color("#4a5070"), "M": Color("#2cffa0"), "K": Color("#8e98b8"), "k": Color("#cad4f0"),
}

# The player's ship (PixelArt "player_idle"), which the mimics and the boss reflect.
const VIPER: PackedStringArray = [
	"....RRRR..................",
	"....rDDRR.................",
	".....DDSSL................",
	"...NNDDSSLLL..............",
	"..NDDSSSSLLLLLL...........",
	".YOSSSSLLBBCCLLLLWW.......",
	"WYOOWWWLLBCCWWLLLLWWWWWW..",
	"WYOOWWWLLBCCWWLLLLWWWWWWWW",
	"WYOOWWWLLBBCCLLLLWWWWWW...",
	".YOSSSSLLLLLLLLLL.........",
	"..NDDSSSSLLLLLL...........",
	"...NNDDSSLLL..............",
	".....DDSSL................",
	"....rDDRR.................",
	"....RRRR..................",
]

# The four generic enemy shapes (PixelArt), re-coloured as negatives for this stage.
const SCOUT: PackedStringArray = [
	"......CC......",
	".....CCCC.....",
	"...CCLLLLCC...",
	"..CCLBBBBLLC..",
	".CCLBYYYYBLCC.",
	"CCLBYYWWYYBLCC",
	"CLBBYWWWWYBBLC",
	"CCLBYYWWYYBLCC",
	".CCLBYYYYBLCC.",
	"..CCLBBBBLLC..",
	"...CCLLLLCC...",
	".....CCCC.....",
	"......CC......",
]
const SWOOPER: PackedStringArray = [
	"..........RRRRRR..",
	"........rrRRRRRRr.",
	"......rrRRRRLLRRRr",
	"...rrrRRRRLLLLLR..",
	".rrRRRRYYLLLLk....",
	"WRRRRRYYWWLLkO....",
	"WWRRRRYYWWLLkYW...",
	"WRRRRRYYLLLLkO....",
	".rrRRRRYYLLLLk....",
	"...rrrRRRRLLLLLR..",
	"......rrRRRRLLRRRr",
	"........rrRRRRRRr.",
	"..........RRRRRR..",
]
const SNIPER: PackedStringArray = [
	"....pppppppp....",
	"..ppPPPPPPPPpp..",
	".pPPKKKKKKKKPPp.",
	"pPPKKkNNNNkKKPPp",
	"pPKKkNCCCCNkKPPp",
	"PPKkNCCWWCCNkKPP",
	"MPKkNCWWWWCNkKPP",
	"WMKkNCWWWWCNkKPP",
	"MPKkNCCWWCCNkKPP",
	"PPKkNCCCCNkKKPPp",
	"pPKKkNNNNkKKKPPp",
	"pPPKKKKKKKKKKPPp",
	".pPPPPPPPPPPPPp.",
	"..ppPPPPPPPPpp..",
	"....pppppppp....",
]
const CRUISER: PackedStringArray = [
	"..........kkkkkkkkkk........",
	".......kkkKKKKKKKKKKkkk.....",
	"....kkkKKKKLLLLLLLLKKKKkk...",
	"..RRKKKKLLLSSSSSSSSLLLKKKk..",
	".WRRKKKLLSSDDDDDDDDSSLLKKKk.",
	"WWRRKKLLSSDDNNNNNNDDSSLLKKKk",
	"..kkkkLLSSDNNRRRRNNDSSLLKKYO",
	"....kKLLSSDNRRYYRRNDSSLLKKYW",
	"...RRKLLSSDNRYYYYRNDSSLLKKYW",
	".WWRRKLLSSDNRYYYYRNDSSLLKKYO",
	".WWRRKLLSSDNRYYYYRNDSSLLKKYO",
	"...RRKLLSSDNRYYYYRNDSSLLKKYW",
	"....kKLLSSDNRRYYRRNDSSLLKKYW",
	"..kkkkLLSSDNNRRRRNNDSSLLKKYO",
	"WWRRKKLLSSDDNNNNNNDDSSLLKKKk",
	".WRRKKKLLSSDDDDDDDDSSLLKKKk.",
	"..RRKKKKLLLSSSSSSSSLLLKKKk..",
	"....kkkKKKKLLLLLLLLKKKKkk...",
	".......kkkKKKKKKKKKKkkk.....",
	"..........kkkkkkkkkk........",
]

const TILT_DEG: Array[float] = [-24.0, -12.0, 0.0, 12.0, 24.0]


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(2):
		out[id + "_mimic_%d" % f] = chroma_outline(_mimic(f))
	for f2: int in range(6):
		out[id + "_reflector_%d" % f2] = chroma_outline(_reflector(f2))
	for f3: int in range(5):
		out[id + "_shard_%d" % f3] = chroma_outline(_shard(f3))
	var scout_pal: Dictionary = NEG.duplicate()
	scout_pal["C"] = Color("#8ad8f0")
	scout_pal["L"] = Color("#232a42")
	scout_pal["B"] = Color("#141827")
	scout_pal["Y"] = EYE
	out[id + "_scout"] = chroma_outline(Kit.rows(SCOUT, scout_pal))
	out[id + "_swooper"] = chroma_outline(Kit.rows(SWOOPER, NEG))
	var sniper_pal: Dictionary = NEG.duplicate()
	sniper_pal["P"] = Color("#39426a")
	sniper_pal["p"] = Color("#1e2438")
	sniper_pal["K"] = Color("#141827")
	sniper_pal["k"] = Color("#5a6488")
	sniper_pal["N"] = Color("#a4b0d4")
	sniper_pal["M"] = TIP
	out[id + "_sniper"] = chroma_outline(Kit.rows(SNIPER, sniper_pal))
	out[id + "_cruiser"] = chroma_outline(Kit.rows(CRUISER, NEG))
	out[id + "_shot"] = _shot()
	out[id + "_echo"] = _echo()
	out[id + "_sliver"] = _sliver()
	for f4: int in range(3):
		out["boss_%s_%d" % [id, f4]] = _paint_boss(f4)
	return out


# --- Outline ------------------------------------------------------------------------------------

# The sprite 2 px larger with a chromatic edge: cyan where the shape's left side is, magenta on
# its right side, silver above and below.
static func chroma_outline(img: Image) -> Image:
	var sw: int = img.get_width()
	var sh: int = img.get_height()
	var out: Image = Image.create(sw + 2, sh + 2, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(0, 0, sw, sh), Vector2i(1, 1))
	_edge_pass(out)
	return out


static func _solid(img: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return false
	return img.get_pixel(x, y).a > 0.5


static func _edge_pass(img: Image) -> void:
	var src: Image = img.duplicate() as Image
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			if _solid(src, x, y):
				continue
			var r: bool = _solid(src, x + 1, y)
			var l: bool = _solid(src, x - 1, y)
			if r and not l:
				img.set_pixel(x, y, EDGE_CYAN)
			elif l and not r:
				img.set_pixel(x, y, EDGE_MAGENTA)
			elif l or r or _solid(src, x, y - 1) or _solid(src, x, y + 1):
				img.set_pixel(x, y, EDGE_SILVER)


# --- Mimic: the player's ship, turned to face left, in negative ---------------------------------
# Frame 1: charged (canopy white-hot, engines flaring).

static func _mimic(frame: int) -> Image:
	var rows: PackedStringArray = PackedStringArray()
	for r: String in VIPER:
		var rev: String = ""
		for i: int in range(r.length() - 1, -1, -1):
			rev += r[i]
		rows.append(rev)
	var pal: Dictionary = NEG.duplicate()
	if frame == 1:
		pal["C"] = EYE_HOT
		pal["B"] = EYE
		pal["Y"] = Color("#d0c8ff")
		pal["O"] = FLAME
	var img: Image = Kit.rows(rows, pal)
	return img


# --- Reflector: a chrome core behind a tilting mirror pane --------------------------------------
# Frames 0-4: the pane tilted -24, -12, 0 (facing straight left), 12, 24 degrees. Frame 5: the
# pane swung up out of the way and the core's eye lit (open, vulnerable, about to fire).

static func _reflector(frame: int) -> Image:
	var img: Image = Kit.blank(30, 34)
	var core: Vector2 = Vector2(20.0, 17.0)
	var open: bool = frame == 5
	# Rear thruster fins.
	Painter.poly(img, PackedVector2Array([Vector2(24.0, 11.0), Vector2(29.0, 8.0), Vector2(29.0, 12.0), Vector2(25.0, 14.0)]), CHROME[0])
	Painter.poly(img, PackedVector2Array([Vector2(24.0, 23.0), Vector2(29.0, 26.0), Vector2(29.0, 22.0), Vector2(25.0, 20.0)]), CHROME[0])
	Kit.put(img, 28, 9, CHROME[2])
	Kit.put(img, 28, 25, CHROME[2])
	# Core: a dark chrome ball with a lens.
	var ramp: Array[Color] = [HULL[1], HULL[3], CHROME[1], CHROME[3]]
	Kit.ball(img, core.x, core.y, 7.0, 7.0, ramp)
	Kit.disc(img, core.x - 3.0, core.y, 3.4, Color("#05060c"))
	Kit.disc(img, core.x - 3.0, core.y, 1.8, EYE_HOT if open else EYE_D)
	if open:
		Kit.disc(img, core.x - 3.0, core.y, 0.9, Color.WHITE)
	else:
		Kit.put(img, int(core.x) - 3, int(core.y), EYE)
	# The mirror pane.
	var c: Vector2 = Vector2(8.0, 17.0)
	var th: float = deg_to_rad(TILT_DEG[clampi(frame, 0, 4)])
	var half: float = 14.0
	if open:
		c = Vector2(13.0, 3.0)
		th = deg_to_rad(90.0)
		half = 11.0
	var u: Vector2 = Vector2(sin(th), cos(th))       # along the pane
	var n: Vector2 = Vector2(-cos(th), sin(th))      # its mirror face's normal (left at 0 degrees)
	# Struts from the core to the pane's ends.
	var e1: Vector2 = c + u * (half - 2.0)
	var e2: Vector2 = c - u * (half - 2.0)
	Kit.line(img, e1 - n * 0.5, core + Vector2(-2.0, -5.0) if not open else core + Vector2(-2.0, -6.0), CHROME[1])
	if not open:
		Kit.line(img, e2 - n * 0.5, core + Vector2(-2.0, 5.0), CHROME[1])
	# Back (chrome) then the bright mirror face toward n.
	var a: Vector2 = c + u * half
	var b: Vector2 = c - u * half
	Painter.poly(img, PackedVector2Array([a - n * 1.2, b - n * 1.2, b + n * 1.6, a + n * 1.6]), CHROME[0])
	Painter.poly(img, PackedVector2Array([a + n * 0.4, b + n * 0.4, b + n * 1.6, a + n * 1.6]), Color("#d8e4ff") if frame == 2 else CHROME[2])
	# Shine: a white streak across the face; brightest when facing straight left.
	var s0: Vector2 = c + u * 6.0 + n * 1.0
	var s1: Vector2 = c + u * 1.0 + n * 1.0
	Kit.line(img, s0, s1, Color.WHITE if frame == 2 else CHROME[3])
	Kit.put(img, int(roundf((c - u * 8.0 + n).x)), int(roundf((c - u * 8.0 + n).y)), Color("#bff6ff"))
	# Rim caps.
	Kit.put(img, int(roundf(a.x)), int(roundf(a.y)), CHROME[3])
	Kit.put(img, int(roundf(b.x)), int(roundf(b.y)), CHROME[3])
	return img


# --- Shard: a spinning chrome sliver --------------------------------------------------------------
# Frames 0-3 turn through half a revolution; frame 4 is the white-hot flash before it fires.

static func _shard(frame: int) -> Image:
	var img: Image = Kit.blank(17, 17)
	var ang: float = (float(frame % 4) / 4.0) * PI
	var c: Vector2 = Vector2(8.5, 8.5)
	var tip: Vector2 = c + Vector2(-7.5, 0.5).rotated(ang)
	var b1: Vector2 = c + Vector2(5.5, -6.0).rotated(ang)
	var b2: Vector2 = c + Vector2(4.0, 6.5).rotated(ang)
	var mid: Vector2 = c + Vector2(1.5, 0.0).rotated(ang)
	var hot: bool = frame == 4
	# Dark mirror glass: a lit facet and a shadowed one, with a bright rim on the lit edges.
	Painter.poly(img, PackedVector2Array([tip, b1, b2]), Color("#3a4a7c") if hot else HULL[1])
	Painter.poly(img, PackedVector2Array([tip, b1, mid]), Color("#6a80c0") if hot else (HULL[3] if frame % 2 == 0 else Color("#2e3a60")))
	Painter.poly(img, PackedVector2Array([b1, b2, mid]), Color("#2c3a66") if hot else HULL[2])
	Kit.line(img, tip, b1, CHROME[3] if not hot else Color.WHITE)
	Kit.line(img, b1, b2, CHROME[1] if not hot else Color("#ffd0f4"))
	Kit.line(img, tip, mid, CHROME[2] if not hot else Color("#bff6ff"))
	# A reflected "eye" in the glass; white-hot in the flash frame.
	Kit.put(img, int(roundf(mid.x)), int(roundf(mid.y)), Color.WHITE if hot else EYE)
	if hot:
		Kit.put(img, int(roundf(mid.x)) - 1, int(roundf(mid.y)), EYE_HOT)
	return img


# --- Shots ---------------------------------------------------------------------------------------

# The stage's own shot: a silver diamond with a cyan/magenta fringe.
static func _shot() -> Image:
	var img: Image = Kit.blank(9, 9)
	Painter.poly(img, PackedVector2Array([Vector2(3.5, 0.0), Vector2(7.5, 4.5), Vector2(3.5, 9.0), Vector2(-0.5, 4.5)]), Color(0.3, 0.95, 1.0, 0.75))
	Painter.poly(img, PackedVector2Array([Vector2(5.5, 0.0), Vector2(9.5, 4.5), Vector2(5.5, 9.0), Vector2(1.5, 4.5)]), Color(1.0, 0.35, 0.85, 0.75))
	Painter.poly(img, PackedVector2Array([Vector2(4.5, 0.5), Vector2(8.0, 4.5), Vector2(4.5, 8.5), Vector2(1.0, 4.5)]), Color("#f4f8ff"))
	Painter.poly(img, PackedVector2Array([Vector2(4.5, 2.5), Vector2(6.0, 4.5), Vector2(4.5, 6.5), Vector2(3.0, 4.5)]), Color.WHITE)
	return img


# A reflected shot: a silver ring around a white dot, so a bounced-back hit reads differently.
static func _echo() -> Image:
	var img: Image = Kit.blank(9, 9)
	for y: int in range(9):
		for x: int in range(9):
			var d: float = Vector2(float(x) - 4.0, float(y) - 4.0).length()
			if d <= 4.3 and d >= 2.6:
				img.set_pixel(x, y, Color("#bff6ff") if x < 4 else (Color("#ffb8ee") if x > 4 else Color("#f0f4ff")))
			elif d < 1.6:
				img.set_pixel(x, y, Color.WHITE)
	return img


# A laser sliver (boss lasers and mirror streams): an elongated bolt, rotated by the shooter.
static func _sliver() -> Image:
	var img: Image = Kit.blank(13, 5)
	Painter.ellipse(img, 6.5, 2.5, 6.4, 2.5, Color(0.35, 0.95, 1.0, 0.55))
	Painter.ellipse(img, 6.5, 2.5, 5.0, 1.4, Color("#e8f8ff"))
	Painter.rect(img, 3, 2, 7, 1, Color.WHITE)
	return img


# --- Boss: DARK VIPER ---------------------------------------------------------------------------
# A giant negative of the player's ship facing left: black hull with bright edges, a red-orange
# canopy eye, cyan wingtips, blue-violet engines, wing gun pods and a nose cannon. The upper half
# is painted and mirrored, so it is exactly symmetric about its centre line (rows 59/60).
# Frame 0 idle, 1 idle with the engines and wingtip lights pulsing, 2 attacking (guns lit).

const BW: int = 124
const BH: int = 120


static func _paint_boss(frame: int) -> Image:
	var img: Image = Kit.blank(BW, BH)
	# Wing (behind the fuselage).
	Painter.poly(img, PackedVector2Array([Vector2(46.0, 54.0), Vector2(74.0, 27.0), Vector2(94.0, 8.0), Vector2(106.0, 6.0), Vector2(111.0, 12.0), Vector2(103.0, 30.0), Vector2(99.0, 54.0)]), HULL[1])
	Painter.poly(img, PackedVector2Array([Vector2(46.0, 54.0), Vector2(74.0, 27.0), Vector2(94.0, 8.0), Vector2(98.0, 10.0), Vector2(78.0, 30.0), Vector2(52.0, 54.0)]), HULL[3])
	Painter.poly(img, PackedVector2Array([Vector2(52.0, 54.0), Vector2(78.0, 30.0), Vector2(98.0, 10.0), Vector2(100.0, 14.0), Vector2(82.0, 33.0), Vector2(58.0, 54.0)]), HULL[2])
	Painter.line(img, 64, 50, 98, 18, HULL[0])
	Painter.line(img, 76, 50, 101, 26, HULL[0])
	# Negative chevron emblem on the wing.
	Painter.poly(img, PackedVector2Array([Vector2(82.0, 38.0), Vector2(90.0, 30.0), Vector2(93.0, 31.0), Vector2(86.0, 39.0)]), Color("#cfd8f4"))
	Painter.poly(img, PackedVector2Array([Vector2(86.0, 42.0), Vector2(94.0, 34.0), Vector2(96.0, 36.0), Vector2(89.0, 43.0)]), TIP_D)
	# Wingtip cap.
	Painter.poly(img, PackedVector2Array([Vector2(94.0, 8.0), Vector2(106.0, 6.0), Vector2(111.0, 12.0), Vector2(104.0, 15.0), Vector2(97.0, 12.0)]), TIP)
	Painter.poly(img, PackedVector2Array([Vector2(97.0, 12.0), Vector2(104.0, 15.0), Vector2(111.0, 12.0), Vector2(110.0, 15.0), Vector2(104.0, 17.0)]), TIP_D)
	# Wing gun pod with its barrel pointing left (muzzle at 49,30).
	Painter.rect(img, 54, 27, 22, 7, HULL[2])
	Painter.rect(img, 54, 27, 22, 2, CHROME[1])
	Painter.rect(img, 56, 33, 18, 1, HULL[0])
	Painter.rect(img, 49, 29, 6, 3, CHROME[0])
	Painter.rect(img, 49, 29, 6, 1, CHROME[2])
	for rv: int in range(58, 76, 5):
		Kit.put(img, rv, 30, CHROME[1])
	# Tail fin.
	Painter.poly(img, PackedVector2Array([Vector2(92.0, 47.0), Vector2(105.0, 30.0), Vector2(113.0, 30.0), Vector2(111.0, 47.0)]), HULL[1])
	Painter.line(img, 93, 46, 105, 31, HULL[3])
	Painter.line(img, 106, 31, 112, 31, CHROME[1])
	# Fuselage (upper half).
	Painter.poly(img, PackedVector2Array([Vector2(1.0, 60.0), Vector2(10.0, 57.0), Vector2(26.0, 52.0), Vector2(46.0, 46.0), Vector2(76.0, 43.0), Vector2(102.0, 44.0), Vector2(116.0, 48.0), Vector2(120.0, 54.0), Vector2(120.0, 60.0)]), HULL[1])
	Painter.poly(img, PackedVector2Array([Vector2(10.0, 57.0), Vector2(26.0, 52.0), Vector2(46.0, 46.0), Vector2(76.0, 43.0), Vector2(102.0, 44.0), Vector2(102.0, 46.0), Vector2(76.0, 45.5), Vector2(46.0, 48.5), Vector2(26.0, 54.5), Vector2(12.0, 58.5)]), HULL[3])
	Painter.poly(img, PackedVector2Array([Vector2(26.0, 54.5), Vector2(46.0, 48.5), Vector2(76.0, 45.5), Vector2(102.0, 46.0), Vector2(102.0, 49.0), Vector2(76.0, 49.0), Vector2(46.0, 52.0), Vector2(30.0, 56.0)]), HULL[2])
	Painter.rect(img, 34, 57, 80, 1, HULL[0])
	for px: int in [44, 62, 80, 96]:
		Painter.rect(img, px, 50, 1, 7, HULL[0])
		Kit.put(img, px + 2, 52, HULL[3])
	# Intake vents along the spine.
	for vx: int in range(66, 92, 4):
		Painter.rect(img, vx, 53, 2, 2, Color("#05060c"))
	# Canard.
	Painter.poly(img, PackedVector2Array([Vector2(22.0, 55.0), Vector2(30.0, 44.0), Vector2(38.0, 44.0), Vector2(36.0, 53.0)]), HULL[2])
	Painter.line(img, 23, 54, 30, 45, CHROME[1])
	Kit.put(img, 31, 44, TIP)
	# Engine pod and nozzle.
	Painter.rect(img, 100, 48, 18, 9, CHROME[0])
	Painter.rect(img, 100, 48, 18, 2, CHROME[1])
	Painter.rect(img, 104, 51, 12, 1, HULL[0])
	Painter.rect(img, 117, 49, 3, 7, HULL[3])
	Painter.rect(img, 119, 50, 1, 5, Color("#05060c"))

	# Mirror the upper half onto the lower half (rows y <-> BH - 1 - y).
	for y: int in range(BH / 2):
		for x: int in range(BW):
			img.set_pixel(x, BH - 1 - y, img.get_pixel(x, y))

	# Centre-line parts: the canopy eye and the nose cannon.
	var cy: float = float(BH) * 0.5
	Painter.ellipse(img, 31.0, cy, 11.0, 5.0, Color("#05060c"))
	Painter.ellipse(img, 31.0, cy, 9.5, 4.0, EYE_D)
	Painter.ellipse(img, 30.0, cy, 7.0, 2.6, EYE if frame < 2 else EYE_HOT)
	Painter.rect(img, 24, int(cy) - 2, 5, 1, Color("#ffb090"))
	Painter.rect(img, 26, int(cy) - 1, 2, 1, Color.WHITE)
	Painter.rect(img, 2, int(cy) - 2, 12, 4, CHROME[0])
	Painter.rect(img, 2, int(cy) - 2, 12, 1, CHROME[2])
	Painter.rect(img, 0, int(cy) - 1, 3, 2, HULL[3])

	# Engine flames, wingtip lights and gun glows by frame.
	var flame_len: int = [2, 3, 2][frame]
	for ey: int in [50, BH - 1 - 54]:
		Painter.rect(img, 120, ey, flame_len, 5, FLAME_D)
		Painter.rect(img, 120, ey + 1, flame_len, 3, FLAME if frame >= 1 else FLAME_D)
		if frame >= 1:
			Painter.rect(img, 120, ey + 2, flame_len - 1, 1, Color("#e0dcff"))
	if frame >= 1:
		for ty: int in [9, BH - 1 - 9]:
			Kit.put(img, 108, ty, Color.WHITE)
			Kit.put(img, 107, ty, Color("#bffcf6"))
	if frame == 2:
		for gy: int in [30, BH - 1 - 30]:
			BossPainter._glow_orb(img, 49, gy, 3, Color("#7a2ab8"), Color("#ff8ae8"), Color.WHITE)
		BossPainter._glow_orb(img, 2, int(cy) - 1, 3, Color("#2a6ab8"), Color("#9af4ff"), Color.WHITE)

	# Chromatic negative-film edge (needs the 1-px margin left above).
	_edge_pass(img)
	return img
