extends "res://scripts/stages/stage_background.gd"

# HOLO ARENA: inside a gladiator stadium under an energy dome. The upper tiers curve away above,
# packed with a holographic crowd that bobs and cheers in blocks (and flickers like a hologram);
# a centre-hung scoreboard shows the round and a ticking clock; spotlights on light rigs sweep
# the arena; hologram banners hang under the upper tier. Below, the lower tiers sit behind the
# arena wall, whose posts are strung with pulsing laser barriers; laser-barrier rails run along
# the ceiling and the floor. Camera flashes pop in the crowd and confetti drifts down.
#
# Layers (paint(), worker thread):
#   "sky"            480x270 at (0,0): the dome lattice with stars beyond, dark arena air
#   "top_0/1/2"      768x80 at y 36, parallax 0.08: upper tiers + crowd (rest / bob / cheer),
#                    light rigs on top, the LED ribbon board and banners underneath
#   "bot_0/1/2"      640x36 at y 190, parallax 0.18: lower tiers + bigger crowd
#   "wall"           512x38 at y 210, parallax 0.42: arena wall, ad screens, laser posts
#   "rail_top"       512x9 at y 28, parallax 0.85: ceiling laser-barrier emitters
#   "rail_bot"       512x12 at y 246, parallax 0.85: floor rim with barrier emitters
#   "board"          112x40 drawn at (184, 28): the scoreboard housing (contents drawn live)
# The crowd is drawn in 16-px strips, each picking a frame, so blocks bob, pockets cheer and a
# "wave" can sweep through. Rare events: fireworks over the stands (_ev_a), the crowd doing the
# wave with "CHEER!" on the board (_ev_b), and every spotlight swinging onto the arena floor and
# strobing with "FIGHT!" on the board (_ev_c). The y 100-190 band stays dark; the spotlight
# cones cross it at very low alpha.

const Painter = preload("res://scripts/stage_bg_painter.gd")
const PixFont = preload("pixfont.gd")

const TOP_Y: float = 36.0
const TOP_W: float = 768.0
const TOP_H: float = 80.0
const BOT_Y: float = 190.0
const BOT_W: float = 640.0
const BOT_H: float = 36.0
const WALL_Y: float = 210.0
const RAIL_TOP_Y: float = 28.0
const RAIL_BOT_Y: float = 246.0
const F_TOP: float = 0.08
const F_BOT: float = 0.18
const F_WALL: float = 0.42
const F_RAIL: float = 0.85
const STRIP: float = 16.0
const BOARD_X: float = 184.0
const BOARD_Y: float = 28.0
const LASER_TOP_Y: float = 37.0
const LASER_BOT_Y: float = 247.0
const POST_BEAM_Y: float = 213.0
const FLOOR_Y: float = 246.0

const BODY: PackedColorArray = [Color("#141a3a"), Color("#1c1636"), Color("#122036"), Color("#1e1a30"), Color("#182242"), Color("#123040"), Color("#2e1436")]
const HEAD: PackedColorArray = [Color("#323c6c"), Color("#3c3264"), Color("#2a425c"), Color("#40365a"), Color("#344876"), Color("#2c6074"), Color("#622c60")]
const STICKS: PackedColorArray = [Color("#ff4ad0"), Color("#38e8ff"), Color("#ffd04a")]
const FW_COLS: PackedColorArray = [Color("#ffd04a"), Color("#ff4ad0"), Color("#38e8ff"), Color("#ffffff")]

var _flash_pos: PackedVector2Array = PackedVector2Array()
var _flash_age: PackedFloat32Array = PackedFloat32Array()
var _flash_t: float = 0.1
var _gl_idx: int = -1
var _gl_t: float = 0.0
var _gl_wait: float = 0.5
var _rk: PackedVector4Array = PackedVector4Array()      # rockets: x, y, vx, vy
var _rk_fuse: PackedFloat32Array = PackedFloat32Array()
var _rk_col: PackedInt32Array = PackedInt32Array()
var _rk_queue: int = 0
var _rk_next: float = 0.0
var _sp: PackedVector4Array = PackedVector4Array()      # firework sparks: x, y, vx, vy
var _sp_age: PackedFloat32Array = PackedFloat32Array()
var _sp_col: PackedInt32Array = PackedInt32Array()
var _burst: PackedVector3Array = PackedVector3Array()   # burst flashes: x, y, age


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 22022
	var out: Dictionary = {}
	out["sky"] = _paint_sky(rng)
	_paint_top(rng, out)
	_paint_bot(rng, out)
	out["wall"] = _paint_wall(rng)
	out["rail_top"] = _paint_rail_top()
	out["rail_bot"] = _paint_rail_bot()
	out["board"] = _paint_board()
	return out


static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#05060f"))
	Painter.vgrad(sky, 22, 258, PackedColorArray([Color("#05060f"), Color("#06071a"), Color("#08091e"), Color("#090a22"), Color("#0b0b26"), Color("#0d0c2a")]), 0.4)
	# Stars beyond the dome, then the dome's diamond lattice fading downward.
	for i: int in range(70):
		var c: Color = Color("#2a2e5a") if i % 4 != 0 else Color("#5a5e9a")
		Painter.px(sky, rng.randi_range(0, 479), rng.randi_range(28, 52), c)
	for y: int in range(28, 60):
		var fade: float = 1.0 - float(y - 28) / 32.0
		for x: int in range(480):
			if (x + y * 2) % 26 == 0 or (x - y * 2 + 2600) % 26 == 0:
				if Painter.bayer(x, y) < fade * 0.9:
					Painter.blend_px(sky, x, y, Color("#22306a"), 0.55)
	# A faint haze of spotlight scatter low over the arena floor.
	for y2: int in range(150, 230):
		var k: float = float(y2 - 150) / 80.0
		for x2: int in range(0, 480, 1):
			if Painter.bayer(x2, y2) < k * 0.22:
				Painter.blend_px(sky, x2, y2, Color("#16123a"), 0.6)
	return sky


# A row of spectators on one tier. spec = (spacing, head w, head h, body w), body_h rows of
# shoulders under the head. Returns the crowd as [xs, ys (head row), spec, body_h, colour, stick].
static func _tier_crowd(rng: RandomNumberGenerator, w: int, head_y: int, spec: Vector4i, body_h: int, skip: Callable) -> Array:
	var xs: PackedInt32Array = PackedInt32Array()
	var ys: PackedInt32Array = PackedInt32Array()
	var ci: PackedInt32Array = PackedInt32Array()
	var st: PackedInt32Array = PackedInt32Array()
	var x: int = rng.randi_range(0, spec.x - 1)
	while x < w - 1:
		if not bool(skip.call(x)) and rng.randf() > 0.08:
			xs.append(x)
			ys.append(head_y + (1 if rng.randf() < 0.25 else 0))
			var c: int = rng.randi_range(0, 4)
			var r: float = rng.randf()
			if r < 0.14:
				c = 5
			elif r < 0.24:
				c = 6
			ci.append(c)
			st.append(rng.randi_range(0, 2) if rng.randf() < 0.18 else -1)
		x += spec.x + (1 if rng.randf() < 0.15 else 0)
	return [xs, ys, spec, body_h, ci, st]


# Paints a tier's crowd for a frame: 0 rest, 1 every other one bobs up, 2 all cheer (arms up,
# glow sticks). Heads are lighter than the shoulders under them, so rows read as heads; odd rows
# are a shade darker (the hologram's scan lines).
static func _paint_crowd(img: Image, crowd: Array, frame: int, dim: float = 0.0) -> void:
	var xs: PackedInt32Array = crowd[0]
	var ys: PackedInt32Array = crowd[1]
	var spec: Vector4i = crowd[2]
	var body_h: int = int(crowd[3])
	var ci: PackedInt32Array = crowd[4]
	var st: PackedInt32Array = crowd[5]
	var hw: int = spec.y
	var hh: int = spec.z
	var bw: int = spec.w
	var bx0: int = -((bw - hw) / 2)
	for i: int in range(xs.size()):
		var x: int = xs[i]
		var y: int = ys[i]
		if frame == 2 or (frame == 1 and (x / 3 + i) % 2 == 0):
			y -= 1
		var bc: Color = BODY[ci[i]].darkened(dim)
		var hc: Color = HEAD[ci[i]].darkened(dim)
		for yy2: int in range(y + hh, y + hh + body_h):
			var c2: Color = bc if (yy2 & 1) == 0 else bc.darkened(0.2)
			for xx2: int in range(x + bx0, x + bx0 + bw):
				Painter.px(img, xx2, yy2, c2)
		for yy: int in range(y, y + hh):
			var c: Color = hc if (yy & 1) == 0 else hc.darkened(0.15)
			for xx: int in range(x, x + hw):
				Painter.px(img, xx, yy, c)
		if frame == 2:
			Painter.px(img, x + bx0 - 1, y, bc)
			Painter.px(img, x + bx0 + bw, y, bc)
			if hh >= 2:
				Painter.px(img, x + bx0 - 1, y - 1, bc)
				Painter.px(img, x + bx0 + bw, y - 1, bc)
			if st[i] >= 0:
				Painter.px(img, x + bx0 + bw, y - (2 if hh >= 2 else 1), STICKS[st[i]])
		elif frame == 1 and st[i] >= 0 and i % 4 == 0:
			Painter.px(img, x + bx0 + bw, y, STICKS[st[i]].darkened(0.35))


static func _paint_top(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = int(TOP_W)
	var h: int = int(TOP_H)
	var base: Image = Painter.new_img(w, h)
	# Dome rim beam behind the top tier.
	Painter.rect(base, 0, 6, w, 2, Color("#121834"))
	Painter.rect(base, 0, 6, w, 1, Color("#1e2850"))
	var heights: Array[int] = [5, 6, 6, 7, 7, 8, 8]
	var y: int = 8
	var tiers: Array[Vector2i] = []
	for i: int in range(heights.size()):
		var th: int = heights[i]
		var lift: float = float(i) * 0.012
		Painter.rect(base, 0, y, w, th, Color(0.039 + lift, 0.047 + lift, 0.13 + lift * 1.6) if i % 2 == 0 else Color(0.047 + lift, 0.058 + lift, 0.155 + lift * 1.6))
		Painter.rect(base, 0, y + th - 2, w, 1, Color("#151a3a"))
		Painter.rect(base, 0, y + th - 1, w, 1, Color("#33280f"))
		for px: int in range(0, w, 6):
			Painter.px(base, px, y + th - 1, Color("#5a4418"))
		tiers.append(Vector2i(y, th))
		y += th
	var bottom: int = y   # 55
	# Aisles (stairs) and pillars carrying hologram crests.
	var aisle: Callable = func(x: int) -> bool:
		var m: int = posmod(x, 96)
		var mp: int = posmod(x - 48, 192)
		return m < 5 or mp < 7
	for ax: int in range(0, w, 96):
		Painter.rect(base, ax, 8, 5, bottom - 8, Color("#06070f"))
		for t: Vector2i in tiers:
			Painter.rect(base, ax, t.x + t.y - 1, 5, 1, Color("#141a32"))
	for pxl: int in range(48, w, 192):
		Painter.rect(base, pxl, 2, 7, bottom - 2, Color("#111633"))
		Painter.rect(base, pxl, 2, 1, bottom - 2, Color("#5a4418"))
		Painter.rect(base, pxl + 6, 2, 1, bottom - 2, Color("#2a200c"))
		Painter.rect(base, pxl + 1, 2, 5, 1, Color("#7a5a1c"))
		Painter.px(base, pxl + 3, 12, Color("#6a1e5a"))
		Painter.px(base, pxl + 2, 13, Color("#6a1e5a"))
		Painter.px(base, pxl + 4, 13, Color("#6a1e5a"))
		Painter.px(base, pxl + 3, 14, Color("#9a2a80"))
	# Light rigs: trusses rising above the top tier with a lamp head (spotlight sources).
	var rigs: PackedFloat32Array = PackedFloat32Array()
	for rx: int in range(64, w, 128):
		for ty: int in range(0, 10):
			Painter.px(base, rx - 2, ty, Color("#262c4c"))
			Painter.px(base, rx + 2, ty, Color("#262c4c"))
			if ty % 3 == 0:
				Painter.rect(base, rx - 2, ty, 5, 1, Color("#1c2240"))
			Painter.px(base, rx - 2 + (ty % 5), ty, Color("#1a2038"))
		Painter.rect(base, rx - 3, 0, 7, 2, Color("#3a3a50"))
		Painter.rect(base, rx - 1, 1, 3, 1, Color("#8a8460"))
		rigs.append(float(rx))
	# LED ribbon board under the upper tier.
	Painter.rect(base, 0, bottom, w, 1, Color("#6a5020"))
	Painter.rect(base, 0, bottom + 1, w, 5, Color("#08060f"))
	Painter.rect(base, 0, bottom + 6, w, 1, Color("#4a3814"))
	var seg_cols: PackedColorArray = [Color("#3a1036"), Color("#10303a"), Color("#3a2a10"), Color("#22103a")]
	for sx: int in range(0, w, 24):
		var sc: Color = seg_cols[(sx / 24) % seg_cols.size()]
		Painter.rect(base, sx + 2, bottom + 2, 20, 3, sc)
		for k: int in range(sx + 3, sx + 21, 3):
			Painter.px(base, k, bottom + 3, sc.lightened(0.18))
	# Hologram banners hanging under the board.
	var ban_cols: Array[PackedColorArray] = [
		PackedColorArray([Color("#3a0e34"), Color("#6a1a5c"), Color("#a83088")]),
		PackedColorArray([Color("#0c2a36"), Color("#165064"), Color("#2a8aa0")]),
		PackedColorArray([Color("#2e2008"), Color("#5a4010"), Color("#9a7020")]),
	]
	var bi: int = 0
	for bx: int in range(30, w, 128):
		var bc: PackedColorArray = ban_cols[bi % 3]
		var top: int = bottom + 7
		Painter.rect(base, bx - 1, top, 12, 1, Color("#5a4418"))
		for yy: int in range(0, 15):
			var inset: int = maxi(0, yy - 10)
			for xx: int in range(inset, 10 - inset):
				var c: Color = bc[1]
				if xx == 0 or xx == 9 - inset:
					c = bc[0]
				elif (xx + yy) % 7 == 0:
					c = bc[2]
				Painter.px(base, bx + xx, top + 1 + yy, c)
		# A laurel-and-star emblem.
		Painter.px(base, bx + 4, top + 5, bc[2])
		Painter.px(base, bx + 5, top + 5, bc[2])
		Painter.px(base, bx + 3, top + 6, bc[2])
		Painter.px(base, bx + 6, top + 6, bc[2])
		Painter.px(base, bx + 4, top + 7, Color("#e0c070"))
		Painter.px(base, bx + 5, top + 7, Color("#e0c070"))
		bi += 1
	# The crowd (three frames).
	# Far tiers: 1-px heads over a band of shoulders; nearer tiers: bigger heads, wider shoulders.
	var crowds: Array = []
	for i3: int in range(tiers.size()):
		var t2: Vector2i = tiers[i3]
		var spec: Vector4i = Vector4i(2, 1, 1, 2)
		if i3 >= 5:
			spec = Vector4i(4, 2, 2, 3)
		elif i3 >= 3:
			spec = Vector4i(3, 2, 1, 3)
		var body_h: int = mini(3, t2.y - 2 - spec.z - 1)
		crowds.append(_tier_crowd(rng, w, t2.x + t2.y - 2 - spec.z - body_h, spec, body_h, aisle))
	for f: int in range(3):
		var img: Image = base.duplicate() as Image
		for i4: int in range(crowds.size()):
			_paint_crowd(img, crowds[i4], f, maxf(0.0, 0.3 - 0.06 * float(i4)))
		out["top_%d" % f] = img
	out["rigs"] = rigs
	out["ribbon_y"] = float(bottom + 2)


static func _paint_bot(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = int(BOT_W)
	var h: int = int(BOT_H)
	var base: Image = Painter.new_img(w, h)
	var heights: Array[int] = [7, 8, 9, 10]
	var y: int = 2
	var tiers: Array[Vector2i] = []
	Painter.rect(base, 0, 0, w, 2, Color("#0c0f26"))
	Painter.rect(base, 0, 1, w, 1, Color("#3a2c12"))
	for i: int in range(heights.size()):
		var th: int = heights[i]
		var lift: float = float(i) * 0.01
		Painter.rect(base, 0, y, w, th, Color(0.05 + lift, 0.06 + lift, 0.16 + lift * 1.5) if i % 2 == 0 else Color(0.058 + lift, 0.07 + lift, 0.18 + lift * 1.5))
		Painter.rect(base, 0, y + th - 2, w, 1, Color("#181d40"))
		Painter.rect(base, 0, y + th - 1, w, 1, Color("#3a2c10"))
		for px: int in range(0, w, 8):
			Painter.px(base, px, y + th - 1, Color("#6a5018"))
		tiers.append(Vector2i(y, th))
		y += th
	var aisle: Callable = func(x: int) -> bool:
		return posmod(x, 80) < 6
	for ax: int in range(0, w, 80):
		Painter.rect(base, ax, 2, 6, h - 2, Color("#070812"))
		for t: Vector2i in tiers:
			Painter.rect(base, ax, t.x + t.y - 1, 6, 1, Color("#161c36"))
	var crowds: Array = []
	for i2: int in range(tiers.size()):
		var t2: Vector2i = tiers[i2]
		var spec: Vector4i = Vector4i(4, 2, 2, 3) if i2 < 2 else Vector4i(5, 2, 2, 4)
		var body_h: int = mini(4, t2.y - 2 - spec.z - 1)
		crowds.append(_tier_crowd(rng, w, t2.x + t2.y - 2 - spec.z - body_h, spec, body_h, aisle))
	for f: int in range(3):
		var img: Image = base.duplicate() as Image
		for i3: int in range(crowds.size()):
			_paint_crowd(img, crowds[i3], f)
		out["bot_%d" % f] = img


static func _paint_wall(rng: RandomNumberGenerator) -> Image:
	var w: int = 512
	var img: Image = Painter.new_img(w, 38)
	var top: int = 14
	Painter.rect(img, 0, top, w, 38 - top, Color("#0d1028"))
	Painter.rect(img, 0, top, w, 1, Color("#a07028"))
	Painter.rect(img, 0, top + 1, w, 1, Color("#5a4016"))
	Painter.rect(img, 0, 34, w, 4, Color("#080a1a"))
	for sx: int in range(0, w, 32):
		Painter.rect(img, sx, top + 2, 1, 32 - top, Color("#070918"))
		Painter.px(img, sx + 3, top + 4, Color("#1e2448"))
		Painter.px(img, sx + 28, top + 4, Color("#1e2448"))
		Painter.px(img, sx + 3, 31, Color("#1e2448"))
		Painter.px(img, sx + 28, 31, Color("#1e2448"))
	# Hologram ad screens.
	for ax: int in range(16, w, 128):
		Painter.rect(img, ax, top + 4, 44, 13, Color("#1a1430"))
		Painter.rect(img, ax + 1, top + 5, 42, 11, Color("#07060f"))
		var mag: bool = (ax / 128) % 2 == 0
		var c1: Color = Color("#5a1a50") if mag else Color("#164a5a")
		var c2: Color = Color("#8a2a78") if mag else Color("#2a7a8a")
		# A crossed-blades crest and a bar of "text".
		Painter.line(img, ax + 5, top + 7, ax + 13, top + 14, c2)
		Painter.line(img, ax + 13, top + 7, ax + 5, top + 14, c2)
		Painter.disc(img, float(ax) + 9.5, float(top) + 10.5, 1.6, Color("#9a7020"))
		for k: int in range(3):
			Painter.rect(img, ax + 18, top + 7 + k * 3, 22 - k * 5, 1, c1)
		for sl: int in range(top + 5, top + 16, 2):
			for xx: int in range(ax + 1, ax + 43):
				Painter.blend_px(img, xx, sl, Color("#000000"), 0.25)
	# Laser posts (beams strung between them live).
	for pxl: int in range(80, w, 128):
		Painter.rect(img, pxl - 1, 2, 4, 36, Color("#151a36"))
		Painter.rect(img, pxl - 1, 2, 1, 36, Color("#2a3260"))
		Painter.rect(img, pxl - 2, 0, 6, 3, Color("#a07028"))
		Painter.rect(img, pxl - 2, 0, 6, 1, Color("#e0b048"))
		Painter.px(img, pxl, 3, Color("#ff3cc8"))
		Painter.px(img, pxl + 1, 3, Color("#ff3cc8"))
		Painter.rect(img, pxl - 3, top - 1, 8, 2, Color("#6a4c18"))
	return img


static func _paint_rail_top() -> Image:
	var w: int = 512
	var img: Image = Painter.new_img(w, 9)
	Painter.rect(img, 0, 0, w, 6, Color("#0c0e22"))
	Painter.rect(img, 0, 5, w, 1, Color("#1a1e3c"))
	Painter.rect(img, 0, 6, w, 1, Color("#3a2c12"))
	for ex: int in range(8, w, 32):
		var big: bool = ex % 64 == 8
		Painter.rect(img, ex - 2, 1, 6, 6, Color("#151a34"))
		Painter.rect(img, ex - 2, 1, 6, 1, Color("#2a3260"))
		Painter.rect(img, ex - 1, 6, 4, 2 if big else 1, Color("#8a6420"))
		Painter.rect(img, ex, 7 if big else 6, 2, 1, Color("#ff3cc8") if big else Color("#a02a80"))
		if big:
			Painter.px(img, ex, 8, Color("#ff9ae6"))
	return img


static func _paint_rail_bot() -> Image:
	var w: int = 512
	var img: Image = Painter.new_img(w, 12)
	Painter.rect(img, 0, 2, w, 10, Color("#0a0c1c"))
	Painter.rect(img, 0, 2, w, 1, Color("#5a4016"))
	for gx: int in range(0, w, 4):
		Painter.rect(img, gx, 4, 1, 7, Color("#0f1226"))
	for ex: int in range(8, w, 32):
		var big: bool = ex % 64 == 40
		Painter.rect(img, ex - 2, 2, 6, 5, Color("#141832"))
		Painter.rect(img, ex - 1, 0 if big else 1, 4, 3 if big else 2, Color("#8a6420"))
		Painter.rect(img, ex, 0 if big else 1, 2, 1, Color("#ff3cc8") if big else Color("#a02a80"))
		Painter.rect(img, ex - 1, 8, 4, 1, Color("#2a3050"))
	return img


# The scoreboard housing: cables up to the dome, a gold frame, speakers either side and a dark
# screen (x 8-103, y 15-36), whose contents are drawn live.
static func _paint_board() -> Image:
	var img: Image = Painter.new_img(112, 40)
	for cx: int in [14, 97]:
		Painter.rect(img, cx, 0, 1, 12, Color("#2a3050"))
	Painter.rect(img, 6, 11, 100, 28, Color("#5a4016"))
	Painter.rect(img, 6, 11, 100, 1, Color("#a07028"))
	Painter.rect(img, 7, 12, 98, 26, Color("#161a34"))
	Painter.rect(img, 8, 14, 96, 23, Color("#04050c"))
	Painter.rect(img, 8, 14, 96, 1, Color("#0c0e1c"))
	for sx: int in [0, 106]:
		Painter.rect(img, sx, 16, 6, 16, Color("#121630"))
		Painter.rect(img, sx, 16, 6, 1, Color("#262c52"))
		for gy: int in range(18, 31, 3):
			Painter.rect(img, sx + 1, gy, 4, 1, Color("#07080f"))
	Painter.rect(img, 40, 38, 32, 2, Color("#121630"))
	return img


# --- Animation -------------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 40.0
	drift_a.y1 = 250.0
	drift_a.setup(30, rng, -10.0, -3.0, 6.0, 15.0)
	drift_a.par = 0.25
	drift_a.sway = 3.0
	drift_a.sway_hz = 1.6
	drift_a.blink = 2.2
	drift_a.duty = 0.7
	drift_a.cols = PackedColorArray([Color(1.0, 0.3, 0.8, 0.45), Color(1.0, 0.82, 0.3, 0.45), Color(0.3, 0.9, 1.0, 0.4), Color(1.0, 1.0, 1.0, 0.3)])
	drift_b.y0 = 100.0
	drift_b.y1 = 200.0
	drift_b.setup(14, rng, -6.0, -2.0, -2.0, 2.0)
	drift_b.par = 0.1
	drift_b.cols = PackedColorArray([Color(0.3, 0.8, 1.0, 0.18), Color(0.8, 0.3, 0.9, 0.16)])
	_flash_pos.resize(0)
	_flash_age.resize(0)
	_rk.resize(0)
	_rk_fuse.resize(0)
	_rk_col.resize(0)
	_sp.resize(0)
	_sp_age.resize(0)
	_sp_col.resize(0)
	_burst.resize(0)
	_rk_queue = 0
	bg._ev_a.arm(rng, 12.0, 20.0, 4.0, 8.0)    # fireworks
	bg._ev_b.arm(rng, 15.0, 24.0, 8.0, 13.0)   # the crowd does the wave
	bg._ev_c.arm(rng, 18.0, 28.0, 12.0, 18.0)  # spotlights converge and strobe


func update() -> void:
	# Camera flashes in the crowd.
	var i: int = 0
	while i < _flash_age.size():
		_flash_age[i] += dl
		if _flash_age[i] > 0.14:
			_flash_age.remove_at(i)
			_flash_pos.remove_at(i)
			continue
		i += 1
	_flash_t -= dl
	if _flash_t <= 0.0:
		_flash_t = rng.randf_range(0.05, 0.16) * (0.4 if bg._ev_b.on else 1.0)
		if _flash_age.size() < 10:
			var top_side: bool = rng.randf() < 0.62
			var fy: float = rng.randf_range(TOP_Y + 9.0, TOP_Y + 52.0) if top_side else rng.randf_range(BOT_Y + 3.0, BOT_Y + 30.0)
			_flash_pos.append(Vector2(float(rng.randi_range(4, 476)), floorf(fy)))
			_flash_age.append(0.0)
	# Hologram glitch: one crowd strip jitters now and then.
	_gl_t -= dl
	_gl_wait -= dl
	if _gl_wait <= 0.0:
		_gl_wait = rng.randf_range(0.3, 0.9)
		_gl_t = 0.09
		_gl_idx = rng.randi_range(0, int(TOP_W / STRIP) - 1)
	# Fireworks.
	if bg._ev_a.tick(dl, rng):
		bg._ev_a.dur = 3.6
		_rk_queue = 4
		_rk_next = 0.0
	if _rk_queue > 0:
		_rk_next -= dl
		if _rk_next <= 0.0:
			_rk_next = rng.randf_range(0.3, 0.55)
			_rk_queue -= 1
			_rk.append(Vector4(rng.randf_range(60.0, 420.0), BOT_Y + 4.0, rng.randf_range(-12.0, 12.0), -rng.randf_range(250.0, 290.0)))
			_rk_fuse.append(rng.randf_range(0.5, 0.6))
			_rk_col.append(rng.randi_range(0, FW_COLS.size() - 2))
	var r: int = 0
	while r < _rk.size():
		var v: Vector4 = _rk[r]
		v.w += 180.0 * dl
		v.x += v.z * dl
		v.y += v.w * dl
		_rk[r] = v
		_rk_fuse[r] -= dl
		if _rk_fuse[r] <= 0.0:
			_burst.append(Vector3(v.x, v.y, 0.0))
			for s: int in range(30):
				var a: float = TAU * float(s) / 30.0 + rng.randf_range(-0.08, 0.08)
				var spd: float = rng.randf_range(44.0, 78.0) if s % 2 == 0 else rng.randf_range(24.0, 44.0)
				_sp.append(Vector4(v.x, v.y, cos(a) * spd, sin(a) * spd))
				_sp_age.append(0.0)
				_sp_col.append(_rk_col[r] if s % 4 != 0 else FW_COLS.size() - 1)
			_rk.remove_at(r)
			_rk_fuse.remove_at(r)
			_rk_col.remove_at(r)
			continue
		r += 1
	var j: int = 0
	while j < _sp.size():
		_sp_age[j] += dl
		if _sp_age[j] > 1.3:
			_sp.remove_at(j)
			_sp_age.remove_at(j)
			_sp_col.remove_at(j)
			continue
		var p: Vector4 = _sp[j]
		p.z *= 1.0 - 1.2 * dl
		p.w = p.w * (1.0 - 1.2 * dl) + 40.0 * dl
		p.x += p.z * dl - ds * F_TOP
		p.y += p.w * dl
		_sp[j] = p
		j += 1
	var q: int = 0
	while q < _burst.size():
		var bv: Vector3 = _burst[q]
		bv.z += dl
		bv.x -= ds * F_TOP
		if bv.z > 0.22:
			_burst.remove_at(q)
			continue
		_burst[q] = bv
		q += 1
	if bg._ev_b.tick(dl, rng):
		bg._ev_b.dur = 3.2
	if bg._ev_c.tick(dl, rng):
		bg._ev_c.dur = 3.0


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	drift_draw(drift_b)
	_draw_crowd("top", TOP_Y, F_TOP, TOP_W, TOP_H, 0.0)
	_draw_ribbon()
	_draw_fireworks()
	_draw_board()
	_draw_crowd("bot", BOT_Y, F_BOT, BOT_W, BOT_H, 2.3)
	_draw_flashes()
	layer("wall", WALL_Y, F_WALL)
	_draw_post_beams()
	_draw_spotlights()
	layer("rail_top", RAIL_TOP_Y, F_RAIL)
	layer("rail_bot", RAIL_BOT_Y, F_RAIL)
	_draw_rail_lasers()
	drift_draw(drift_a)


# The crowd in 16-px strips: blocks bob, pockets cheer, the wave sweeps through, and a glitching
# strip jitters.
func _draw_crowd(prefix: String, y: float, factor: float, w: float, h: float, seed_ph: float) -> void:
	var t0: Texture2D = tex(prefix + "_0")
	var t1: Texture2D = tex(prefix + "_1")
	var t2: Texture2D = tex(prefix + "_2")
	var o: float = off(factor, w)
	var wave_x: float = -9999.0
	if bg._ev_b.on:
		wave_x = lerpf(520.0, -80.0, bg._ev_b.t / bg._ev_b.dur)
	var k: int = int(floorf(o / STRIP))
	var guard: int = 0
	while guard < 40:
		guard += 1
		var tx: float = float(k) * STRIP
		var sx: float = tx - o
		k += 1
		if sx >= 480.0:
			break
		var u: float = fposmod(tx, w)
		var idx: int = int(u / STRIP)
		var f: int = 0
		if sin(life * 4.2 + float(idx) * 1.71 + seed_ph) > 0.45:
			f = 1
		if sin(life * 0.55 + float(idx) * 0.83 + seed_ph) > 0.9:
			f = 2
		var d: float = sx - wave_x
		if d >= -8.0 and d < 26.0:
			f = 2
		elif d >= 26.0 and d < 54.0:
			f = 1
		var t: Texture2D = t0
		if f == 1:
			t = t1
		elif f == 2:
			t = t2
		var dx: float = 0.0
		var mod: Color = Color.WHITE
		if idx == _gl_idx and _gl_t > 0.0 and prefix == "top":
			dx = 1.0
			mod = Color(0.7, 1.0, 1.0, 0.7)
		bg.draw_texture_rect_region(t, Rect2(sx + dx, y, STRIP, h), Rect2(u, 0.0, STRIP, h), mod)


# A bright window sweeps along the LED ribbon under the upper tier.
func _draw_ribbon() -> void:
	var ry: float = TOP_Y + float(meta.get("ribbon_y", 57.0))
	var x: float = 480.0 - fposmod(life * 140.0, 640.0)
	var cols: PackedColorArray = [Color(1.0, 0.3, 0.8, 0.22), Color(0.3, 0.9, 1.0, 0.2), Color(1.0, 0.8, 0.3, 0.2)]
	var c: Color = cols[int(life * 140.0 / 640.0) % 3]
	bg.draw_rect(Rect2(floorf(x), ry, 60.0, 3.0), c)
	bg.draw_rect(Rect2(floorf(x) + 22.0, ry + 1.0, 16.0, 1.0), Color(1.0, 1.0, 1.0, 0.18))


func _draw_board() -> void:
	var sway: float = roundf(sin(life * 0.6) * 1.0)
	var bx: float = BOARD_X + sway
	bg.draw_texture(tex("board"), Vector2(bx, BOARD_Y))
	var cx: float = bx + 56.0
	var amber: Color = Color(1.0, 0.7, 0.2, 0.8)
	if bg._ev_c.on and fposmod(life * 4.0, 1.0) < 0.7:
		PixFont.draw_centered(bg, "FIGHT!", Vector2(cx, BOARD_Y + 25.0), 2.0, Color(1.0, 0.82, 0.3, 0.85))
	elif bg._ev_b.on and fposmod(life * 3.0, 1.0) < 0.7:
		PixFont.draw_centered(bg, "CHEER!", Vector2(cx, BOARD_Y + 25.0), 2.0, Color(1.0, 0.3, 0.8, 0.85))
	else:
		var cyc: int = int(life / 91.0)
		var secs: int = 90 - int(fposmod(life, 91.0))
		PixFont.draw_centered(bg, "ROUND %d" % (1 + cyc % 9), Vector2(cx, BOARD_Y + 18.5), 1.0, Color(0.3, 0.9, 1.0, 0.7))
		PixFont.draw_centered(bg, "%d:%02d" % [secs / 60, secs % 60], Vector2(cx, BOARD_Y + 29.0), 2.0, amber if secs > 10 or fposmod(life, 1.0) < 0.5 else Color(1.0, 0.25, 0.3, 0.9))
		# Crowd-noise meters either side of the clock.
		for m: int in range(5):
			var hl: float = floorf(2.0 + 4.0 * (0.5 + 0.5 * sin(life * (7.0 + float(m)) + float(m) * 1.9)))
			var hr: float = floorf(2.0 + 4.0 * (0.5 + 0.5 * sin(life * (6.0 + float(m)) + float(m) * 2.7)))
			bg.draw_rect(Rect2(bx + 12.0 + float(m) * 3.0, BOARD_Y + 35.0 - hl, 2.0, hl), Color(1.0, 0.3, 0.8, 0.6))
			bg.draw_rect(Rect2(bx + 87.0 + float(m) * 3.0, BOARD_Y + 35.0 - hr, 2.0, hr), Color(0.3, 0.9, 1.0, 0.6))
	# Chase lights along the frame.
	var lit: int = int(life * 10.0) % 12
	for d: int in range(12):
		var lc: Color = Color(1.0, 0.85, 0.4, 0.9) if d == lit or d == (lit + 6) % 12 else Color(0.5, 0.36, 0.12, 0.6)
		bg.draw_rect(Rect2(bx + 10.0 + float(d) * 8.0, BOARD_Y + 11.0, 2.0, 1.0), lc)
		bg.draw_rect(Rect2(bx + 100.0 - float(d) * 8.0, BOARD_Y + 38.0, 2.0, 1.0), lc)


func _draw_flashes() -> void:
	for i: int in range(_flash_pos.size()):
		var k: float = 1.0 - _flash_age[i] / 0.14
		var p: Vector2 = _flash_pos[i]
		bg.draw_rect(Rect2(p.x, p.y, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.95 * k))
		if k > 0.5:
			var c: Color = Color(1.0, 1.0, 0.9, 0.45 * k)
			bg.draw_rect(Rect2(p.x - 1.0, p.y, 3.0, 1.0), c)
			bg.draw_rect(Rect2(p.x, p.y - 1.0, 1.0, 3.0), c)


func _draw_fireworks() -> void:
	for r: int in range(_rk.size()):
		var v: Vector4 = _rk[r]
		var c: Color = FW_COLS[_rk_col[r]]
		bg.draw_rect(Rect2(floorf(v.x), floorf(v.y), 1.0, 2.0), Color(1.0, 0.95, 0.8, 0.8))
		bg.draw_rect(Rect2(floorf(v.x - v.z * 0.03), floorf(v.y - v.w * 0.03), 1.0, 3.0), Color(c.r, c.g, c.b, 0.35))
	for q: int in range(_burst.size()):
		var k: float = _burst[q].z / 0.22
		bg.draw_circle(Vector2(_burst[q].x, _burst[q].y), 3.0 + 9.0 * k, Color(1.0, 0.95, 0.8, 0.3 * (1.0 - k)))
		bg.draw_circle(Vector2(_burst[q].x, _burst[q].y), 1.5 + 2.0 * k, Color(1.0, 1.0, 1.0, 0.7 * (1.0 - k)))
	for j: int in range(_sp.size()):
		var p: Vector4 = _sp[j]
		var a: float = 1.0 - _sp_age[j] / 1.3
		var c2: Color = FW_COLS[_sp_col[j]]
		if a < 0.35 and (j + int(life * 20.0)) % 3 == 0:
			continue
		var sz: float = 2.0 if _sp_age[j] < 0.35 else 1.0
		bg.draw_rect(Rect2(floorf(p.x), floorf(p.y), sz, sz), Color(c2.r, c2.g, c2.b, 0.95 * a))
		if _sp_age[j] < 0.6:
			bg.draw_rect(Rect2(floorf(p.x - p.z * 0.06), floorf(p.y - p.w * 0.06), 1.0, 1.0), Color(c2.r, c2.g, c2.b, 0.4 * a))


func _draw_post_beams() -> void:
	var o: float = off(F_WALL, 512.0)
	var pulse: float = 0.18 + 0.1 * sin(life * 6.0)
	# Posts every 128 px from texture x 80: the first one at or left of the screen's left edge.
	var first: float = fposmod(80.0 - o, 128.0) - 128.0
	for k: int in range(6):
		var x0: float = first + float(k) * 128.0 + 3.0
		var x1: float = x0 + 124.0
		if x1 <= 0.0 or x0 >= 480.0:
			continue
		bg.draw_rect(Rect2(x0, POST_BEAM_Y, 124.0, 1.0), Color(1.0, 0.24, 0.78, pulse))
		var dot: float = x0 + fposmod(life * 90.0 + float(k) * 37.0, 120.0)
		bg.draw_rect(Rect2(floorf(dot), POST_BEAM_Y, 3.0, 1.0), Color(1.0, 0.7, 0.95, pulse + 0.25))


# Spotlights on the light rigs sweep the arena floor (very low alpha cones) and leave pools of
# light on it; during _ev_c they all swing onto the centre of the floor and strobe.
func _draw_spotlights() -> void:
	var rigs: PackedFloat32Array = meta.get("rigs", PackedFloat32Array())
	var o: float = off(F_TOP, TOP_W)
	var conv: float = 0.0
	var strobe: float = 1.0
	if bg._ev_c.on:
		var u: float = bg._ev_c.t / bg._ev_c.dur
		conv = clampf(minf(u * 5.0, (1.0 - u) * 5.0), 0.0, 1.0)
		if u > 0.2 and u < 0.8:
			strobe = 2.2 if fposmod(life * 9.0, 1.0) < 0.5 else 0.25
	var target: Vector2 = Vector2(240.0, FLOOR_Y)
	for i: int in range(rigs.size()):
		var sx: float = wrap_x(rigs[i], o, TOP_W)
		if sx < -60.0 or sx > 540.0:
			continue
		var src: Vector2 = Vector2(sx, TOP_Y + 1.0)
		var a: float = PI * 0.5 + sin(life * 0.42 + float(i) * 1.37) * 0.55
		var to_t: float = (target - src).angle()
		a = lerp_angle(a, to_t, conv)
		var dist: float = (FLOOR_Y - src.y) / maxf(0.2, sin(a))
		var hw: float = 0.07
		var p1: Vector2 = src + Vector2.from_angle(a - hw) * dist
		var p2: Vector2 = src + Vector2.from_angle(a + hw) * dist
		var al: float = 0.032 * strobe
		var c: Color = Color(1.0, 0.95, 0.75, al)
		bg.draw_primitive(PackedVector2Array([src, p1, p2]), PackedColorArray([Color(1.0, 0.95, 0.75, al * 1.6), c, c]), PackedVector2Array())
		var core1: Vector2 = src + Vector2.from_angle(a - hw * 0.35) * dist
		var core2: Vector2 = src + Vector2.from_angle(a + hw * 0.35) * dist
		bg.draw_primitive(PackedVector2Array([src, core1, core2]), PackedColorArray([Color(1.0, 1.0, 0.9, al), Color(1.0, 1.0, 0.9, al * 0.6), Color(1.0, 1.0, 0.9, al * 0.6)]), PackedVector2Array())
		# The pool of light on the floor and the lamp itself.
		var pool: Vector2 = (p1 + p2) * 0.5
		bg.draw_set_transform(pool, 0.0, Vector2(1.0, 0.22))
		bg.draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.95, 0.75, 0.06 * strobe))
		bg.draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.95, 0.8, 0.06 * strobe))
		bg.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		bg.draw_rect(Rect2(floorf(sx) - 1.0, TOP_Y, 3.0, 2.0), Color(1.0, 0.97, 0.85, 0.85))


# Laser-barrier lines under the ceiling rail and over the floor rim, with pulses running along.
func _draw_rail_lasers() -> void:
	var pulse: float = 0.32 + 0.14 * sin(life * 7.0)
	bg.draw_rect(Rect2(0.0, LASER_TOP_Y, 480.0, 1.0), Color(1.0, 0.24, 0.78, pulse))
	bg.draw_rect(Rect2(0.0, LASER_BOT_Y, 480.0, 1.0), Color(1.0, 0.24, 0.78, pulse))
	for k: int in range(3):
		var x: float = fposmod(life * 210.0 + float(k) * 170.0, 520.0) - 20.0
		bg.draw_rect(Rect2(floorf(x), LASER_TOP_Y, 8.0, 1.0), Color(1.0, 0.75, 0.95, 0.55))
		var x2: float = 500.0 - fposmod(life * 190.0 + float(k) * 160.0, 520.0)
		bg.draw_rect(Rect2(floorf(x2), LASER_BOT_Y, 8.0, 1.0), Color(1.0, 0.75, 0.95, 0.55))
