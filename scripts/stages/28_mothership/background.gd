extends "res://scripts/stages/stage_background.gd"

# STAGE 28 background: inside the armada's flagship. The far end of an immense hangar, where
# the reactor core hangs in a great portal with energy conduits pulsing into it; side walls
# hung with the armada's crimson banners; two tiers of racks with parked fighters (their nav
# lights blinking); a gantry where columns of drone soldiers march in step; cranes trundling
# along the ceiling rail with fighters slung beneath; and down on the floor an assembly line
# whose belt carries half-built drones past welding robots. Rare events: a fighter catapulted
# off the racks, a red-alert sweep, and a reactor surge racing down the conduits.
#
# The Overmind talks to this background through the two static vars below (boss.gd sets
# them): from act III on the hangar stays on red alert, and every act change sends a surge
# into the reactor. When the hyperspace jump starts on this stage (only after the Overmind
# dies), the hangar goes up in a chain of explosions behind you.
#
# Layers: "sky" 480x270 (far end wall, portal, reactor, conduits); "far" 640x200 at y 30
# (0.06); "racks" 768x200 at y 40 (0.2); "gantry" 768x24 at y 138 (0.34); "ceil" 768x24 at
# y 28 (0.55); "line" 768x48 at y 210 (0.75); "items" 768x14 at y 228 (0.75, riding the belt).
# Sprites: "marcher" (two 8x10 frames), "load" (a slung fighter).

const Painter = preload("res://scripts/stage_bg_painter.gd")
const Art = preload("art.gd")

const FAR_Y: float = 30.0
const FAR_F: float = 0.06
const RACK_Y: float = 40.0
const RACK_F: float = 0.2
const GANTRY_Y: float = 138.0
const GANTRY_F: float = 0.34
const CEIL_Y: float = 28.0
const CEIL_F: float = 0.55
const LINE_Y: float = 210.0
const LINE_F: float = 0.75
const ITEMS_Y: float = 228.0
const BELT_SPEED: float = 16.0
const REACTOR: Vector2 = Vector2(352.0, 128.0)
const REACTOR_R: float = 30.0
const MARCH_COLS: Array[float] = [40.0, 236.0, 430.0, 620.0]
const TROLLEYS: Array[float] = [90.0, 470.0]

# Set by the Overmind (boss.gd): its current act, and a counter bumped on every act change.
static var alert: int = 0
static var surge_req: int = 0

var _ev_wait_a: float = 7.0   # catapult launch
var _ev_wait_b: float = 14.0  # red alert
var _ev_wait_c: float = 10.0  # reactor surge
var _launch_t: float = -1.0
var _launch_y: float = 64.0
var _launch_upper: bool = true
var _alert_t: float = -1.0
var _surge_t: float = -1.0
var _surge_seen: int = 0
var _arcs: PackedVector2Array = PackedVector2Array()
var _arc_t: float = 0.0
var _spark_t: float = 0.0
var _flash: float = 0.0
var _finale: bool = false
var _boom_t: float = 0.0
var _finale_t: float = 0.0
var _bx: PackedFloat32Array = PackedFloat32Array()
var _by: PackedFloat32Array = PackedFloat32Array()
var _br: PackedFloat32Array = PackedFloat32Array()
var _ba: PackedFloat32Array = PackedFloat32Array()
var _bl: PackedFloat32Array = PackedFloat32Array()
var _cond_len: PackedFloat32Array = PackedFloat32Array()


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2828
	var out: Dictionary = {}
	_paint_sky(out, rng)
	_paint_far(out, rng)
	_paint_racks(out, rng)
	_paint_gantry(out)
	_paint_ceil(out, rng)
	_paint_line(out, rng)
	_paint_sprites(out)
	return out


# --- painting (worker thread) ------------------------------------------------------------------

static func _ring(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color, back: Color) -> void:
	var steps: int = int((rx + ry) * 3.0)
	for i: int in range(steps):
		var a: float = TAU * float(i) / float(steps)
		var front: bool = sin(a) > 0.0
		Painter.px(img, int(cx + cos(a) * rx), int(cy + sin(a) * ry), c if front else back)


static func _thick(img: Image, a: Vector2, b: Vector2, r: int, c: Color) -> void:
	for oy: int in range(-r, r + 1):
		for ox: int in range(-r, r + 1):
			if ox * ox + oy * oy <= r * r:
				Painter.line(img, int(a.x) + ox, int(a.y) + oy, int(b.x) + ox, int(b.y) + oy, c)


# The far end of the hangar: a panelled bulkhead, the round portal with the reactor core
# hanging in its rings, struts, and four conduits running into the portal.
static func _paint_sky(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var img: Image = Painter.new_img(480, 270)
	img.fill(Color("#06070a"))
	Painter.vgrad(img, 20, 262, PackedColorArray([Color("#07080c"), Color("#0a0b11"), Color("#0c0e15"), Color("#0a0b11"), Color("#08080c")]), 0.5)
	# bulkhead panels
	for py: int in range(28, 262, 38):
		Painter.span(img, 0, 479, py, Color("#050609"))
		for px: int in range(0, 480, 64):
			var ox: int = px + (19 if (py / 38) % 2 == 0 else 0)
			Painter.vline(img, ox, py, py + 37, Color("#050609"))
			Painter.span(img, ox + 1, ox + 62, py + 1, Color("#0e1018"))
	# big structural pillars
	for pl: int in [40, 168, 470]:
		Painter.rect(img, pl - 7, 28, 14, 234, Color("#090a0f"))
		Painter.vline(img, pl - 7, 28, 261, Color("#10121a"))
		for by: int in range(40, 262, 26):
			Painter.rect(img, pl - 9, by, 18, 3, Color("#0c0e14"))
	var c: Vector2 = REACTOR
	# the portal: an octagon frame
	var oct: PackedVector2Array = PackedVector2Array()
	var oct_in: PackedVector2Array = PackedVector2Array()
	for k: int in range(8):
		var a: float = TAU * (float(k) + 0.5) / 8.0
		oct.append(c + Vector2(cos(a), sin(a)) * 84.0)
		oct_in.append(c + Vector2(cos(a), sin(a)) * 74.0)
	Painter.poly(img, oct, Color("#151821"))
	Painter.poly(img, oct_in, Color("#040508"))
	for k2: int in range(8):
		var a2: Vector2 = oct[k2]
		var b2: Vector2 = oct[(k2 + 1) % 8]
		Painter.line(img, int(a2.x), int(a2.y), int(b2.x), int(b2.y), Color("#222634"))
		Painter.rect(img, int(a2.x) - 2, int(a2.y) - 2, 4, 4, Color("#2a1016"))
	# struts from the frame to the core
	for s: int in range(4):
		var sa: float = TAU * (float(s) + 0.5) / 4.0
		_thick(img, c + Vector2(cos(sa), sin(sa)) * 74.0, c + Vector2(cos(sa), sin(sa)) * (REACTOR_R + 4.0), 1, Color("#10131b"))
	# the core: a dim cyan sphere with a darker band, and its rings
	var core: Array[Color] = [Color("#05161c"), Color("#082630"), Color("#0e3a48"), Color("#1a6476")]
	EnemyArt._ball(img, c.x, c.y, REACTOR_R, REACTOR_R, core)
	Painter.ellipse(img, c.x, c.y, REACTOR_R, 3.0, Color("#06141a"))
	Painter.disc(img, c.x - 8.0, c.y - 9.0, 5.0, Color("#246e80"))
	_ring(img, c.x, c.y, 56.0, 11.0, Color("#1e3a46"), Color("#0e1c24"))
	_ring(img, c.x, c.y, 11.0, 54.0, Color("#1a3440"), Color("#0c1820"))
	_ring(img, c.x, c.y, 44.0, 44.0, Color("#101e26"), Color("#0c161c"))
	# conduits into the portal (their pulses are drawn live)
	var conduits: Array = [
		PackedVector2Array([Vector2(-4, 62), Vector2(96, 62), Vector2(190, 82), Vector2(280, 100)]),
		PackedVector2Array([Vector2(-4, 200), Vector2(96, 200), Vector2(190, 178), Vector2(280, 158)]),
		PackedVector2Array([Vector2(484, 44), Vector2(440, 50), Vector2(412, 66)]),
		PackedVector2Array([Vector2(484, 214), Vector2(440, 206), Vector2(412, 190)]),
	]
	for cd: Variant in conduits:
		var pts: PackedVector2Array = cd
		for i: int in range(pts.size() - 1):
			_thick(img, pts[i], pts[i + 1], 2, Color("#0e1118"))
		for i2: int in range(pts.size() - 1):
			Painter.line(img, int(pts[i2].x), int(pts[i2].y) - 2, int(pts[i2 + 1].x), int(pts[i2 + 1].y) - 2, Color("#181c26"))
			Painter.line(img, int(pts[i2].x), int(pts[i2].y), int(pts[i2 + 1].x), int(pts[i2 + 1].y), Color("#0a2a34"))
		for j: int in range(1, pts.size() - 1):
			Painter.rect(img, int(pts[j].x) - 3, int(pts[j].y) - 4, 6, 8, Color("#141822"))
	out["conduits"] = conduits
	# a few dim amber work lights scattered on the bulkhead
	for i3: int in range(18):
		var lx: int = rng.randi_range(0, 479)
		var ly: int = rng.randi_range(34, 250)
		if Vector2(float(lx), float(ly)).distance_to(c) < 90.0:
			continue
		Painter.px(img, lx, ly, Color("#3a2a14") if i3 % 3 != 0 else Color("#14303a"))
	out["sky"] = img


# Side walls: ribs and a beam up top with crimson banners hanging between the ribs, and a lower
# bulkhead with rows of observation windows. The middle is open (the far end shows through).
static func _paint_far(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 640
	var h: int = 200
	var img: Image = Painter.new_img(w, h)
	var eyes: PackedVector2Array = PackedVector2Array()
	# upper beam
	Painter.rect(img, 0, 50, w, 8, Color("#0f1118"))
	Painter.span(img, 0, w - 1, 50, Color("#1a1d27"))
	Painter.span(img, 0, w - 1, 57, Color("#07080b"))
	for rx: int in range(0, w, 16):
		Painter.px(img, rx + 4, 53, Color("#1c202a"))
	# lower bulkhead
	Painter.rect(img, 0, 150, w, 50, Color("#0b0c12"))
	Painter.span(img, 0, w - 1, 150, Color("#181b25"))
	Painter.span(img, 0, w - 1, 151, Color("#12141c"))
	for wy: int in [160, 172]:
		for wx: int in range(6, w, 9):
			var lit: float = rng.randf()
			var col: Color = Color("#07080b")
			if lit < 0.18:
				col = Color("#3a2c16")
			elif lit < 0.26:
				col = Color("#123038")
			Painter.rect(img, wx, wy, 5, 3, col)
	for bx: int in range(0, w, 40):
		Painter.rect(img, bx, 184, 20, 4, Color("#0e1016"))
	# ribs
	for x: int in range(0, w, 80):
		Painter.poly(img, PackedVector2Array([Vector2(x - 6, 0), Vector2(x + 6, 0), Vector2(x + 5, 58), Vector2(x - 5, 58)]), Color("#0d0f15"))
		Painter.vline(img, x - 6, 0, 57, Color("#161922"))
		Painter.poly(img, PackedVector2Array([Vector2(x - 5, 150), Vector2(x + 5, 150), Vector2(x + 7, 200), Vector2(x - 7, 200)]), Color("#0d0f15"))
		Painter.vline(img, x - 5, 150, 199, Color("#161922"))
	# banners in every other bay
	for bi: int in range(0, w / 80):
		if bi % 2 == 1:
			continue
		var cx: float = float(bi * 80 + 40)
		var top: int = 0
		var bh: int = 44 + (bi % 3) * 2
		Painter.rect(img, int(cx) - 13, top, 26, bh, Color("#3a0a12"))
		Painter.poly(img, PackedVector2Array([Vector2(cx - 13, bh), Vector2(cx + 13, bh), Vector2(cx, bh + 9)]), Color("#3a0a12"))
		Painter.rect(img, int(cx) - 13, top, 26, 3, Color("#1a1d27"))
		for fy: int in range(top + 4, bh, 1):
			Painter.px(img, int(cx) - 13, fy, Color("#2a060c"))
			Painter.px(img, int(cx) + 12, fy, Color("#2a060c"))
			if fy % 9 < 5:
				Painter.px(img, int(cx) - 6, fy, Color("#44101a"))
				Painter.px(img, int(cx) + 6, fy, Color("#320810"))
		Art.emblem(img, cx, 22.0, 8.0, Color("#7a1424"), Color("#26060c"), Color("#6a645a"), Color("#0a0606"))
		eyes.append(Vector2(cx, 22.0 - 8.0 * 0.18))
	out["far"] = img
	out["eyes"] = eyes


static func _fighter(img: Image, x: float, y: float, kind: int, body: Color, hi: Color, stripe: Color) -> void:
	match kind:
		0:  # scout dart
			Painter.poly(img, PackedVector2Array([Vector2(x, y + 5), Vector2(x + 5, y + 2), Vector2(x + 13, y + 1), Vector2(x + 16, y + 5), Vector2(x + 13, y + 9), Vector2(x + 5, y + 8)]), body)
			Painter.line(img, int(x) + 5, int(y) + 2, int(x) + 13, int(y) + 1, hi)
			Painter.rect(img, int(x) + 7, int(y) + 4, 4, 2, stripe)
		1:  # swooper bat-wing
			Painter.poly(img, PackedVector2Array([Vector2(x + 4, y + 6), Vector2(x + 16, y), Vector2(x + 20, y + 1), Vector2(x + 13, y + 6)]), body)
			Painter.poly(img, PackedVector2Array([Vector2(x + 4, y + 8), Vector2(x + 13, y + 8), Vector2(x + 20, y + 13), Vector2(x + 16, y + 14)]), body)
			Painter.poly(img, PackedVector2Array([Vector2(x, y + 7), Vector2(x + 4, y + 5), Vector2(x + 16, y + 5.5), Vector2(x + 16, y + 8.5), Vector2(x + 4, y + 9)]), body.lightened(0.08))
			Painter.line(img, int(x) + 5, int(y) + 6, int(x) + 16, int(y), hi)
		2:  # sniper pod
			Painter.poly(img, PackedVector2Array([Vector2(x + 4, y), Vector2(x + 15, y + 2), Vector2(x + 15, y + 13), Vector2(x + 4, y + 15), Vector2(x + 2, y + 7.5)]), body)
			Painter.disc(img, x + 7.0, y + 7.5, 3.0, Color("#07080b"))
			Painter.line(img, int(x) + 4, int(y), int(x) + 15, int(y) + 2, hi)
		_:  # cruiser
			Painter.poly(img, PackedVector2Array([Vector2(x, y + 8), Vector2(x + 6, y + 2), Vector2(x + 26, y + 1), Vector2(x + 30, y + 5), Vector2(x + 30, y + 12), Vector2(x + 26, y + 15), Vector2(x + 6, y + 14)]), body)
			Painter.line(img, int(x) + 6, int(y) + 2, int(x) + 26, int(y) + 1, hi)
			Painter.rect(img, int(x) + 4, int(y) + 9, 22, 2, stripe)


# Two tiers of fighter racks: the upper rack's fighters hang under an I-beam, the lower rack's
# sit on top of one. Some clamps are empty. Each fighter's nav light blinks live.
static func _paint_racks(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var img: Image = Painter.new_img(w, 200)
	var navs: PackedVector3Array = PackedVector3Array()
	var body: Color = Color("#141821")
	var hi: Color = Color("#232936")
	var stripe: Color = Color("#3a0c14")
	for tier: int in range(2):
		var beam_y: int = 14 if tier == 0 else 160
		# pylons
		for px: int in range(24, w, 192):
			if tier == 0:
				Painter.rect(img, px, 0, 5, beam_y, Color("#0e1118"))
				Painter.vline(img, px, 0, beam_y, Color("#181c26"))
			else:
				Painter.rect(img, px, beam_y, 5, 200 - beam_y, Color("#0e1118"))
				Painter.vline(img, px, beam_y, 199, Color("#181c26"))
		# the I-beam
		Painter.rect(img, 0, beam_y, w, 6, Color("#10131b"))
		Painter.span(img, 0, w - 1, beam_y, Color("#20242f"))
		Painter.span(img, 0, w - 1, beam_y + 5, Color("#08090d"))
		for hx: int in range(0, w, 12):
			Painter.px(img, hx + 3, beam_y + 2, Color("#1a1e28"))
		# fighters in their clamps
		for slot: int in range(w / 40):
			var sx: float = float(slot * 40) + 6.0
			if rng.randf() < 0.18:
				# empty clamp, arms open
				var cy: int = beam_y + 6 if tier == 0 else beam_y - 1
				var d: int = 1 if tier == 0 else -1
				Painter.line(img, int(sx) + 8, cy, int(sx) + 5, cy + 8 * d, Color("#1a1e28"))
				Painter.line(img, int(sx) + 14, cy, int(sx) + 17, cy + 8 * d, Color("#1a1e28"))
				continue
			var kind: int = rng.randi_range(0, 3)
			var fh: float = 15.0 if kind == 2 else (14.0 if kind == 1 else (16.0 if kind == 3 else 10.0))
			var fy: float = float(beam_y) + 9.0 if tier == 0 else float(beam_y) - 2.0 - fh
			if kind == 3:
				sx -= 4.0
			# clamp arms
			var arm_x: int = int(sx) + 8
			if tier == 0:
				Painter.rect(img, arm_x, beam_y + 6, 2, 4, Color("#1a1e28"))
			else:
				Painter.rect(img, arm_x, int(fy + fh) - 1, 2, beam_y - int(fy + fh) + 1, Color("#1a1e28"))
			_fighter(img, sx, fy, kind, body, hi, stripe)
			navs.append(Vector3(sx + 12.0, fy + (1.0 if kind != 2 else 2.0), float(tier)))
	out["racks"] = img
	out["navs"] = navs


# The mid gantry: a catwalk with railings and a truss underneath. Drone columns march on it.
static func _paint_gantry(out: Dictionary) -> void:
	var w: int = 768
	var img: Image = Painter.new_img(w, 24)
	Painter.span(img, 0, w - 1, 3, Color("#141822"))
	for px: int in range(0, w, 12):
		Painter.vline(img, px, 3, 12, Color("#11141c"))
	Painter.rect(img, 0, 13, w, 3, Color("#12151e"))
	Painter.span(img, 0, w - 1, 13, Color("#1e222d"))
	Painter.span(img, 0, w - 1, 15, Color("#08090d"))
	for tx: int in range(0, w, 16):
		Painter.line(img, tx, 16, tx + 8, 23, Color("#0d1017"))
		Painter.line(img, tx + 8, 23, tx + 16, 16, Color("#0d1017"))
	Painter.span(img, 0, w - 1, 23, Color("#0d1017"))
	out["gantry"] = img


# Ceiling machinery: the crane rail, strip-light housings, cable bundles and sigil plaques.
static func _paint_ceil(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var img: Image = Painter.new_img(w, 24)
	Painter.rect(img, 0, 0, w, 7, Color("#0f1219"))
	Painter.span(img, 0, w - 1, 6, Color("#1c202b"))
	Painter.span(img, 0, w - 1, 2, Color("#151821"))
	for lx: int in range(0, w, 24):
		Painter.rect(img, lx + 8, 7, 8, 3, Color("#0b0d13"))
	# cable bundles sagging between hangers
	for cx: int in range(0, w, 96):
		var span_w: int = 96
		var sag: float = rng.randf_range(5.0, 9.0)
		for x: int in range(span_w):
			var t: float = float(x) / float(span_w)
			var y: int = 8 + int(sin(t * PI) * sag)
			Painter.px(img, cx + x, y, Color("#0d1016"))
			Painter.px(img, cx + x, y + 1, Color("#10131a"))
		Painter.rect(img, cx, 6, 3, 4, Color("#181c26"))
	# sigil plaques
	for ex: int in range(48, w, 192):
		Painter.rect(img, ex - 10, 7, 20, 15, Color("#0c0e14"))
		Painter.span(img, ex - 10, ex + 9, 7, Color("#1a1e28"))
		Art.emblem(img, float(ex), 14.0, 5.0, Color("#5a1020"), Color("#1a0408"), Color("#4a463e"), Color("#0a0606"))
	out["ceil"] = img


# The assembly line: welding frames over a belt, rollers, floor plating and hazard stripes.
# The welding robots' arms are drawn live from "arms" (layer x, base y).
static func _paint_line(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var img: Image = Painter.new_img(w, 48)
	var arms: PackedVector2Array = PackedVector2Array()
	# floor plating
	Painter.rect(img, 0, 40, w, 8, Color("#0c0e14"))
	Painter.span(img, 0, w - 1, 40, Color("#1a1d27"))
	for fx: int in range(0, w, 32):
		Painter.vline(img, fx, 41, 47, Color("#07080b"))
	# welding frames
	for gx: int in range(20, w, 128):
		var fw: int = 56 + rng.randi_range(0, 12)
		Painter.rect(img, gx, 4, fw, 4, Color("#11141c"))
		Painter.span(img, gx, gx + fw - 1, 4, Color("#22262f"))
		Painter.rect(img, gx, 8, 4, 24, Color("#0e1118"))
		Painter.rect(img, gx + fw - 4, 8, 4, 24, Color("#0e1118"))
		Painter.vline(img, gx, 8, 31, Color("#1a1e28"))
		for hz: int in range(gx, gx + fw, 6):
			Painter.rect(img, hz, 2, 3, 2, Color("#3a0c14"))
		arms.append(Vector2(float(gx + 16), 8.0))
		arms.append(Vector2(float(gx + fw - 18), 8.0))
		# a control box with a dim screen on a post
		Painter.rect(img, gx + fw + 10, 18, 12, 14, Color("#0f1219"))
		Painter.rect(img, gx + fw + 12, 20, 8, 4, Color("#071a20"))
	# belt, its frame and rollers
	Painter.rect(img, 0, 31, w, 1, Color("#3a0c14"))
	for hx: int in range(0, w, 8):
		Painter.rect(img, hx, 31, 4, 1, Color("#0a0a0c"))
	Painter.rect(img, 0, 32, w, 4, Color("#14161c"))
	Painter.span(img, 0, w - 1, 32, Color("#22252e"))
	for tr: int in range(0, w, 5):
		Painter.px(img, tr, 34, Color("#0e1014"))
	Painter.rect(img, 0, 36, w, 4, Color("#0a0b10"))
	for rx: int in range(0, w, 12):
		Painter.disc(img, float(rx) + 6.0, 38.0, 1.8, Color("#181b24"))
	out["line"] = img
	out["arms"] = arms
	# half-built drones riding the belt: bare frame -> plated -> finished with the crimson eye
	var items: Image = Painter.new_img(w, 14)
	for i: int in range(w / 32):
		var x: float = float(i * 32) + 8.0
		var stage: int = i % 4
		Painter.rect(items, int(x) - 2, 12, 16, 2, Color("#101218"))
		match stage:
			0:
				Painter.line(items, int(x), 11, int(x) + 6, 3, Color("#2a2e38"))
				Painter.line(items, int(x) + 6, 3, int(x) + 12, 11, Color("#2a2e38"))
				Painter.line(items, int(x) + 2, 7, int(x) + 10, 7, Color("#22262f"))
			1:
				Painter.ellipse(items, x + 6.0, 7.0, 6.0, 4.5, Color("#1a1d26"))
				Painter.line(items, int(x) + 1, 7, int(x) + 11, 7, Color("#2a2e38"))
				Painter.rect(items, int(x) + 3, 3, 3, 3, Color("#0c0e12"))
			2:
				Painter.ellipse(items, x + 6.0, 7.0, 6.0, 4.5, Color("#232733"))
				Painter.ellipse(items, x + 5.0, 6.0, 4.0, 2.5, Color("#2c313e"))
			_:
				Painter.ellipse(items, x + 6.0, 7.0, 6.0, 4.5, Color("#232733"))
				Painter.rect(items, int(x), 8, 12, 1, Color("#4a0e18"))
				Painter.disc(items, x + 3.0, 6.0, 1.5, Color("#5a1420"))
	out["items"] = items


# Small live sprites: a marching drone soldier (two frames) and a fighter slung from a crane.
static func _paint_sprites(out: Dictionary) -> void:
	var m: Image = Painter.new_img(16, 10)
	for f: int in range(2):
		var ox: int = f * 8
		Painter.rect(m, ox + 2, 0, 4, 3, Color("#1c202a"))
		Painter.px(m, ox + 2, 1, Color("#7a1424"))
		Painter.rect(m, ox + 1, 3, 6, 4, Color("#171a23"))
		Painter.span(m, ox + 1, ox + 6, 3, Color("#242936"))
		if f == 0:
			Painter.vline(m, ox + 2, 7, 9, Color("#141720"))
			Painter.vline(m, ox + 5, 7, 9, Color("#141720"))
		else:
			Painter.line(m, ox + 3, 7, ox + 1, 9, Color("#141720"))
			Painter.line(m, ox + 4, 7, ox + 6, 9, Color("#141720"))
		Painter.px(m, ox + 6, 4, Color("#20242e"))
	out["marcher"] = m
	var ld: Image = Painter.new_img(28, 14)
	_fighter(ld, 0.0, 0.0, 1, Color("#1a1e28"), Color("#2c3240"), Color("#4a0e18"))
	Painter.rect(ld, 20, 6, 2, 2, Color("#123038"))
	out["load"] = ld


# --- animation ----------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 34.0
	drift_a.y1 = 250.0
	drift_a.setup(24, rng, -7.0, -2.0, -3.0, 3.0)
	drift_a.par = 0.5
	drift_a.sway = 1.5
	drift_a.sway_hz = 0.7
	drift_a.cols = PackedColorArray([Color(0.55, 0.6, 0.7, 0.22), Color(0.4, 0.75, 0.85, 0.2), Color(0.6, 0.6, 0.6, 0.15)])
	drift_b.y0 = 196.0
	drift_b.y1 = 250.0
	drift_b.setup(10, rng, -4.0, 4.0, -8.0, -3.0)
	drift_b.par = 0.7
	drift_b.blink = 1.3
	drift_b.duty = 0.6
	drift_b.cols = PackedColorArray([Color(1.0, 0.6, 0.2, 0.5), Color(1.0, 0.4, 0.15, 0.4)])
	alert = 0
	_surge_seen = surge_req
	_launch_t = -1.0
	_alert_t = -1.0
	_surge_t = -1.0
	_finale = false
	_flash = 0.0
	_clear_booms()
	_ev_wait_a = rng.randf_range(4.0, 8.0)
	_ev_wait_b = rng.randf_range(12.0, 18.0)
	_ev_wait_c = rng.randf_range(7.0, 11.0)
	_cond_len.resize(0)
	var conduits: Array = meta.get("conduits", [])
	for cd: Variant in conduits:
		var pts: PackedVector2Array = cd
		var total: float = 0.0
		for i: int in range(pts.size() - 1):
			total += pts[i].distance_to(pts[i + 1])
		_cond_len.append(total)


func _clear_booms() -> void:
	_bx.resize(0)
	_by.resize(0)
	_br.resize(0)
	_ba.resize(0)
	_bl.resize(0)


func update() -> void:
	# rare event A: a fighter catapulted off a rack
	if _launch_t < 0.0:
		_ev_wait_a -= dl
		if _ev_wait_a <= 0.0:
			_launch_t = 0.0
			_launch_upper = not _launch_upper
			_launch_y = 62.0 if _launch_upper else 182.0
			for s: int in range(6):
				fx_spawn(StarfieldBg.Fx.STEAM, 468.0, _launch_y + 7.0, rng.randf_range(-20.0, 10.0), rng.randf_range(-14.0, 14.0), rng.randf_range(0.6, 1.1), 0.0)
	else:
		_launch_t += dl
		if _launch_t > 1.8:
			_launch_t = -1.0
			_ev_wait_a = rng.randf_range(9.0, 15.0)
	# rare event B: red alert (permanent once the Overmind reaches act V)
	if _alert_t < 0.0:
		_ev_wait_b -= dl
		if _ev_wait_b <= 0.0 or alert >= 5:
			_alert_t = 0.0
	else:
		_alert_t += dl
		if _alert_t > 3.6 and alert < 5:
			_alert_t = -1.0
			_ev_wait_b = rng.randf_range(16.0, 24.0)
	# rare event C: reactor surge (also on every act change of the Overmind)
	if surge_req != _surge_seen:
		_surge_seen = surge_req
		_surge_t = 0.0
		_flash = maxf(_flash, 0.18)
	if _surge_t < 0.0:
		_ev_wait_c -= dl
		if _ev_wait_c <= 0.0:
			_surge_t = 0.0
	else:
		_surge_t += dl
		_arc_t -= dl
		if _arc_t <= 0.0:
			_arc_t = 0.07
			_build_arcs()
		if _surge_t > 2.4:
			_surge_t = -1.0
			_ev_wait_c = rng.randf_range(10.0, 16.0)
	# welding sparks on the assembly line
	_spark_t -= dl
	if _spark_t <= 0.0:
		_spark_t = 0.09
		var tips: PackedVector2Array = _weld_tips(true)
		for t: Vector2 in tips:
			fx_spawn(StarfieldBg.Fx.SPARK, t.x, t.y, rng.randf_range(-45.0, 45.0), rng.randf_range(-40.0, 5.0), rng.randf_range(0.25, 0.5), LINE_F)
	# the finale: the flagship blows up behind the jump
	if bg.hyperspace_active and not _finale:
		_finale = true
		_boom_t = 0.0
		_finale_t = 0.0
		_flash = 0.6
		_surge_t = 0.0
	if _finale:
		_finale_t += dl
		_boom_t -= dl
		while _boom_t <= 0.0:
			_boom_t += 0.045
			_add_boom()
	var i: int = 0
	while i < _ba.size():
		_ba[i] += dl
		if _ba[i] >= _bl[i]:
			var last: int = _ba.size() - 1
			_bx[i] = _bx[last]
			_by[i] = _by[last]
			_br[i] = _br[last]
			_ba[i] = _ba[last]
			_bl[i] = _bl[last]
			_bx.resize(last)
			_by.resize(last)
			_br.resize(last)
			_ba.resize(last)
			_bl.resize(last)
			continue
		i += 1
	_flash = maxf(0.0, _flash - dl * 1.2)


func _add_boom() -> void:
	if _ba.size() >= 40:
		return
	var x: float = 480.0 - pow(rng.randf(), 0.7) * 420.0
	var y: float = rng.randf_range(36.0, 250.0)
	_bx.append(x)
	_by.append(y)
	_br.append(rng.randf_range(8.0, 24.0))
	_ba.append(0.0)
	_bl.append(rng.randf_range(0.45, 0.8))
	for s: int in range(3):
		fx_spawn(StarfieldBg.Fx.BOMB, x, y, rng.randf_range(-80.0, 80.0), rng.randf_range(-90.0, 20.0), rng.randf_range(0.4, 0.8), 0.0)
	fx_spawn(StarfieldBg.Fx.SMOKE, x, y, rng.randf_range(-20.0, 20.0), rng.randf_range(-20.0, 0.0), rng.randf_range(0.8, 1.2), 0.0)


func _build_arcs() -> void:
	_arcs.resize(0)
	for a: int in range(3):
		var ang: float = rng.randf() * TAU
		var p: Vector2 = REACTOR + Vector2.from_angle(ang) * REACTOR_R
		for s: int in range(5):
			var q: Vector2 = p + Vector2.from_angle(ang + rng.randf_range(-0.9, 0.9)) * rng.randf_range(5.0, 10.0)
			_arcs.append(p)
			_arcs.append(q)
			p = q


# Screen positions of the welding robots' torch tips (only those welding right now if
# `welding_only`), on screen.
func _weld_tips(welding_only: bool) -> PackedVector2Array:
	var outp: PackedVector2Array = PackedVector2Array()
	var arms: PackedVector2Array = meta.get("arms", PackedVector2Array())
	var o: float = off(LINE_F, 768.0)
	for i: int in range(arms.size()):
		var sx: float = wrap_x(arms[i].x, o, 768.0)
		if sx < -20.0 or sx > 500.0:
			continue
		var t: float = fposmod(life * 0.62 + float(i) * 0.37, 1.0)
		if welding_only and t > 0.35:
			continue
		outp.append(_arm_tip(sx, LINE_Y + arms[i].y, i))
	return outp


func _arm_elbow(sx: float, by: float, i: int) -> Vector2:
	return Vector2(sx, by) + Vector2.from_angle(PI * 0.5 + sin(life * 1.3 + float(i) * 1.9) * 0.55) * 10.0


func _arm_tip(sx: float, by: float, i: int) -> Vector2:
	var e: Vector2 = _arm_elbow(sx, by, i)
	return e + Vector2.from_angle(PI * 0.5 - sin(life * 1.3 + float(i) * 1.9) * 0.7) * 11.0


func _conduit_point(pts: PackedVector2Array, d: float) -> Vector2:
	var left: float = d
	for i: int in range(pts.size() - 1):
		var seg: float = pts[i].distance_to(pts[i + 1])
		if left <= seg:
			return pts[i].lerp(pts[i + 1], left / maxf(0.001, seg))
		left -= seg
	return pts[pts.size() - 1]


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	var surging: bool = _surge_t >= 0.0
	var red: bool = _alert_t >= 0.0 or alert >= 3
	# the reactor's glow, its rings' running lights and the surge
	var pulse: float = 0.5 + 0.5 * sin(life * 2.2)
	var sk: float = 0.0
	if surging:
		sk = clampf(1.0 - _surge_t / 2.4, 0.0, 1.0)
	bg.draw_circle(REACTOR, REACTOR_R + 8.0 + 3.0 * pulse, Color(0.2, 0.85, 1.0, 0.035 + 0.02 * pulse + 0.08 * sk))
	bg.draw_circle(REACTOR, REACTOR_R - 4.0, Color(0.3, 0.9, 1.0, 0.04 + 0.03 * pulse + 0.18 * sk))
	for k: int in range(3):
		var t: float = life * 1.1 + float(k) * TAU / 3.0
		var front: float = sin(t)
		var hp: Vector2 = REACTOR + Vector2(cos(t) * 56.0, front * 11.0)
		bg.draw_rect(Rect2(floorf(hp.x), floorf(hp.y), 2.0, 1.0), Color(0.4, 0.95, 1.0, 0.35 + 0.35 * maxf(0.0, front)))
		var t2: float = -life * 0.8 + float(k) * TAU / 3.0
		var vp: Vector2 = REACTOR + Vector2(sin(t2) * 11.0, cos(t2) * 54.0)
		bg.draw_rect(Rect2(floorf(vp.x), floorf(vp.y), 1.0, 2.0), Color(0.4, 0.95, 1.0, 0.3 + 0.3 * maxf(0.0, sin(t2))))
	if surging:
		var u: float = fposmod(_surge_t, 0.8) / 0.8
		bg.draw_arc(REACTOR, REACTOR_R + 6.0 + 70.0 * u, 0.0, TAU, 40, Color(0.5, 0.95, 1.0, 0.3 * (1.0 - u)), 1.0)
		if not _arcs.is_empty():
			bg.draw_multiline(_arcs, Color(0.75, 1.0, 1.0, 0.75), 1.0)
	# energy pulses running down the conduits into the portal
	var conduits: Array = meta.get("conduits", [])
	for ci: int in range(mini(conduits.size(), _cond_len.size())):
		var pts: PackedVector2Array = conduits[ci]
		var total: float = _cond_len[ci]
		var n: int = 6 if surging else 2
		var spd: float = 190.0 if surging else 55.0
		for j: int in range(n):
			var d: float = fposmod(life * spd + float(j) * total / float(n) + float(ci) * 37.0, total)
			var q: Vector2 = _conduit_point(pts, d)
			var q2: Vector2 = _conduit_point(pts, maxf(0.0, d - 5.0))
			var col: Color = Color(0.5, 1.0, 1.0, 0.9) if surging else Color(0.3, 0.85, 1.0, 0.55)
			bg.draw_rect(Rect2(floorf(q.x) - 1.0, floorf(q.y) - 1.0, 2.0, 2.0), col)
			bg.draw_rect(Rect2(floorf(q2.x), floorf(q2.y), 1.0, 1.0), col * Color(1.0, 1.0, 1.0, 0.5))
	# side walls and their banners (the sigil's eye glows)
	layer("far", FAR_Y, FAR_F)
	var o_f: float = off(FAR_F, 640.0)
	var eyes: PackedVector2Array = meta.get("eyes", PackedVector2Array())
	for e: int in range(eyes.size()):
		var ex: float = wrap_x(eyes[e].x, o_f, 640.0)
		if ex < -4.0 or ex > 484.0:
			continue
		var ea: float = 0.35 + 0.3 * sin(life * 1.5 + float(e))
		if red:
			ea = 0.6 + 0.4 * float(int(life * 6.0) % 2)
		bg.draw_rect(Rect2(floorf(ex) - 1.0, FAR_Y + eyes[e].y - 1.0, 2.0, 2.0), Color(1.0, 0.2, 0.25, ea))
	# fighter racks and their nav lights
	layer("racks", RACK_Y, RACK_F)
	var o_r: float = off(RACK_F, 768.0)
	var navs: PackedVector3Array = meta.get("navs", PackedVector3Array())
	for nv: int in range(navs.size()):
		if fposmod(life * 0.7 + float(nv) * 0.31, 1.0) > 0.3:
			continue
		var nx: float = wrap_x(navs[nv].x, o_r, 768.0)
		if nx < 0.0 or nx > 480.0:
			continue
		var nc: Color = Color(1.0, 0.25, 0.3, 0.8) if int(navs[nv].z) == 0 else Color(0.3, 1.0, 0.5, 0.7)
		bg.draw_rect(Rect2(floorf(nx), RACK_Y + navs[nv].y, 1.0, 1.0), nc)
	# event A: the catapult launch along a rack
	if _launch_t >= 0.0:
		var lt: float = _launch_t
		var lx: float = 470.0 - (30.0 * lt + 260.0 * lt * lt * lt)
		var ld: Texture2D = tex("load")
		bg.draw_texture(ld, Vector2(floorf(lx), _launch_y), Color(0.95, 0.95, 1.0, 1.0))
		var flame: float = 4.0 + 10.0 * minf(1.0, lt)
		bg.draw_rect(Rect2(floorf(lx) + 21.0, _launch_y + 6.0, flame, 2.0), Color(1.0, 0.6, 0.2, 0.85))
		bg.draw_rect(Rect2(floorf(lx) + 21.0, _launch_y + 6.0, flame * 0.5, 2.0), Color(1.0, 0.95, 0.7, 0.9))
		if lt > 0.4:
			bg.draw_rect(Rect2(floorf(lx) + 22.0, _launch_y + 7.0, 90.0 * minf(1.0, lt - 0.3), 1.0), Color(1.0, 0.7, 0.4, 0.35))
	# the gantry and the drone columns marching on it, all in step
	layer("gantry", GANTRY_Y, GANTRY_F)
	var o_g: float = off(GANTRY_F, 768.0)
	var mt: Texture2D = tex("marcher")
	var step: int = int(life * 3.4) % 2
	for col_i: int in range(MARCH_COLS.size()):
		var base: float = fposmod(MARCH_COLS[col_i] - life * 11.0, 768.0)
		for m: int in range(6):
			var mx: float = wrap_x(fposmod(base + float(m) * 10.0, 768.0), o_g, 768.0)
			if mx < -10.0 or mx > 482.0:
				continue
			var bob: float = 0.0 if step == 0 else -1.0
			bg.draw_texture_rect_region(mt, Rect2(floorf(mx), GANTRY_Y + 3.0 + bob, 8.0, 10.0), Rect2(float(step * 8), 0.0, 8.0, 10.0))
	# the ceiling and the cranes running along its rail
	layer("ceil", CEIL_Y, CEIL_F)
	var o_c: float = off(CEIL_F, 768.0)
	var ldt: Texture2D = tex("load")
	for tr: int in range(TROLLEYS.size()):
		var tx: float = wrap_x(fposmod(TROLLEYS[tr] + life * 16.0, 768.0), o_c, 768.0)
		if tx < -30.0 or tx > 510.0:
			continue
		var sway: float = sin(life * 1.1 + float(tr) * 2.0) * 2.0
		var ty: float = CEIL_Y + 4.0
		var load_y: float = CEIL_Y + 30.0 + float(tr) * 6.0
		bg.draw_rect(Rect2(floorf(tx) - 7.0, ty, 14.0, 4.0), Color("#262b37"))
		bg.draw_rect(Rect2(floorf(tx) - 7.0, ty, 14.0, 1.0), Color("#353b49"))
		bg.draw_line(Vector2(floorf(tx) - 4.0, ty + 4.0), Vector2(floorf(tx + sway) + 2.0, load_y), Color("#1c2029"), 1.0)
		bg.draw_line(Vector2(floorf(tx) + 4.0, ty + 4.0), Vector2(floorf(tx + sway) + 14.0, load_y), Color("#1c2029"), 1.0)
		bg.draw_texture(ldt, Vector2(floorf(tx + sway) - 6.0, load_y - 2.0), Color(0.85, 0.85, 0.9, 1.0))
	# strip lights along the ceiling: a slow chase, red on alert
	var chase: int = int(life * 7.0)
	for k2: int in range(32):
		var lx2: float = wrap_x(float(k2 * 24 + 9), o_c, 768.0)
		if lx2 < -8.0 or lx2 > 480.0:
			continue
		var on: bool = posmod(chase - k2, 8) == 0
		var lc: Color = Color(0.3, 0.85, 1.0, 0.65 if on else 0.22)
		if red:
			var blink: bool = int(life * 5.0) % 2 == 0
			lc = Color(1.0, 0.18, 0.22, 0.9 if blink else 0.35)
		bg.draw_rect(Rect2(floorf(lx2), CEIL_Y + 8.0, 6.0, 1.0), lc)
	drift_draw(drift_b)
	# the assembly line: belt, the drones riding it, the welding robots
	layer("line", LINE_Y, LINE_F)
	layer("items", ITEMS_Y, LINE_F, Color.WHITE, life * BELT_SPEED)
	var arms: PackedVector2Array = meta.get("arms", PackedVector2Array())
	var o_l: float = off(LINE_F, 768.0)
	for ai: int in range(arms.size()):
		var sx: float = wrap_x(arms[ai].x, o_l, 768.0)
		if sx < -20.0 or sx > 500.0:
			continue
		var b: Vector2 = Vector2(floorf(sx), LINE_Y + arms[ai].y)
		var e2: Vector2 = _arm_elbow(b.x, b.y, ai)
		var tip: Vector2 = _arm_tip(b.x, b.y, ai)
		bg.draw_line(b, e2, Color("#0a0c10"), 3.0)
		bg.draw_line(b, e2, Color("#222733"), 1.0)
		bg.draw_line(e2, tip, Color("#0a0c10"), 3.0)
		bg.draw_line(e2, tip, Color("#2a303d"), 1.0)
		bg.draw_rect(Rect2(b.x - 2.0, b.y - 1.0, 4.0, 3.0), Color("#1a1e28"))
		var t3: float = fposmod(life * 0.62 + float(ai) * 0.37, 1.0)
		if t3 < 0.35:
			var fl: float = 0.6 + 0.4 * float(int(life * 30.0 + float(ai)) % 2)
			bg.draw_circle(tip, 4.0, Color(1.0, 0.75, 0.3, 0.12 * fl))
			bg.draw_rect(Rect2(floorf(tip.x) - 1.0, floorf(tip.y) - 1.0, 2.0, 2.0), Color(1.0, 0.95, 0.75, fl))
	fx_draw()
	drift_draw(drift_a)
	# event B: red alert, a band of red light sweeping the hangar and the edges pulsing
	if _alert_t >= 0.0:
		var sweep: float = fposmod(_alert_t * 300.0, 720.0) - 120.0
		bg.draw_rect(Rect2(sweep, 28.0, 60.0, 230.0), Color(1.0, 0.1, 0.12, 0.035))
		bg.draw_rect(Rect2(sweep + 18.0, 28.0, 24.0, 230.0), Color(1.0, 0.1, 0.12, 0.04))
		var vp2: float = maxf(0.0, sin(_alert_t * 8.0))
		bg.draw_rect(Rect2(0.0, 28.0, 480.0, 10.0), Color(1.0, 0.1, 0.1, 0.07 * vp2))
		bg.draw_rect(Rect2(0.0, 248.0, 480.0, 10.0), Color(1.0, 0.1, 0.1, 0.07 * vp2))
	# the finale: the reactor going critical, explosions ripping through the hangar
	if _finale:
		var mk: float = clampf(_finale_t / 1.4, 0.0, 1.0)
		bg.draw_circle(REACTOR, REACTOR_R + 150.0 * mk, Color(0.7, 0.95, 1.0, 0.18 * (1.0 - mk) + 0.06))
		bg.draw_circle(REACTOR, REACTOR_R + 40.0 * mk, Color(1.0, 1.0, 1.0, 0.5 * (1.0 - mk) + 0.2))
	for bi: int in range(_ba.size()):
		var kk: float = _ba[bi] / _bl[bi]
		var c: Vector2 = Vector2(_bx[bi], _by[bi])
		var r: float = _br[bi] * (0.5 + 0.5 * sqrt(kk))
		var fade: float = 1.0 - kk
		if kk < 0.15:
			bg.draw_circle(c, r * 1.1, Color(1.0, 0.97, 0.85, 0.9))
		bg.draw_circle(c, r, Color(0.35, 0.1, 0.06, 0.5 * fade))
		bg.draw_circle(c, r * 0.85, Color(1.0, 0.42, 0.1, 0.9 * fade))
		bg.draw_circle(c, r * 0.55 * (1.0 - kk * 0.4), Color(1.0, 0.8, 0.3, 0.95 * fade))
		bg.draw_circle(c, r * 0.25 * fade, Color(1.0, 1.0, 0.9, fade))
		bg.draw_arc(c, r + 2.0 + 10.0 * kk, 0.0, TAU, 20, Color(1.0, 0.75, 0.4, 0.6 * fade), 1.0)
	if _flash > 0.0:
		bg.draw_rect(Rect2(0.0, 22.0, 480.0, 236.0), Color(1.0, 0.92, 0.85, _flash) if _finale else Color(0.6, 0.95, 1.0, _flash * 0.5))
