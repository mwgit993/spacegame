extends "res://scripts/stages/stage_background.gd"

# MIRROR WORLD: an inverted dimension mirrored about the playfield's centre line. Screen row y
# reflects to row 279 - y, so the playfield (30-249), the decks and every painted layer map onto
# themselves. Each layer's lower half is painted and copied, flipped, onto its upper half with a
# magenta cast (the "reflection"); the lower half keeps a cyan cast.
#
# Layers (paint(), worker thread):
#   "sky"       480x270 at (0,0): near-black void, a negative-film eclipse and its reflection,
#               pale haze at the edges, starfield (mirrored)
#   "far"       768x224 at y 28, parallax 0.06: an inverted skyline of chrome spires rising from
#               the bottom and hanging from the top
#   "mid"       640x224 at y 28, parallax 0.2: broken mirror panes standing on the floor (and
#               hanging from the ceiling), chrome debris; the playfield centre stays clear
#   "near_bot"  512x20 at y 238, parallax 0.8: chrome floor plating
#   "near_top"  512x20 at y 22, parallax 0.8: its reflection
#   "shard_<k>", "shardf_<k>"   dim drifting mirror shards at 8 angles (and flipped)
#   "ghost", "ghostf"           a ghost ship and its reflection
# Animation: drifting mirror shards that turn and catch the light, beacons blinking on the
# spires, glints on the panes, mirrored motes, and a faint shimmer running along the mirror
# plane. Rare events: a crack spreads along the mirror plane and heals with a faint inversion
# pulse (_ev_a), a kaleidoscope bloom and its reflection (_ev_b), and the ghost of a ship flying
# the other way with its reflection (_ev_c).

const Painter = preload("res://scripts/stage_bg_painter.gd")

const LAYER_Y: float = 28.0
const NEAR_BOT_Y: float = 238.0
const NEAR_TOP_Y: float = 22.0
const MIRROR_SUM: float = 279.0
const AXIS: float = 139.5
const FAR_W: float = 768.0
const MID_W: float = 640.0
const SHARD_N: int = 7

const TOP_TINT: Color = Color("#ff4ad0")
const TOP_DARK: Color = Color("#2c0c30")   # the reflection's cast on dark layers

var _sx: PackedFloat32Array = PackedFloat32Array()   # drifting shards: x, y (lower half), speed, spin, angle
var _sy: PackedFloat32Array = PackedFloat32Array()
var _sv: PackedFloat32Array = PackedFloat32Array()
var _ss: PackedFloat32Array = PackedFloat32Array()
var _sa: PackedFloat32Array = PackedFloat32Array()
var _crack: PackedVector3Array = PackedVector3Array()   # segments: x0, x1 and a packed y pair
var _crack_y: PackedVector2Array = PackedVector2Array()  # y offsets (from the plane) of each segment end
var _crack_x0: float = 240.0
var _pulse: float = 0.0
var _pulsed: bool = false
var _kal: Vector2 = Vector2(240.0, 80.0)
var _ghost_y: float = 80.0
var _glint_pos: PackedVector2Array = PackedVector2Array()
var _glint_age: PackedFloat32Array = PackedFloat32Array()
var _glint_t: float = 0.3


# --- Painting ------------------------------------------------------------------------------------

static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 23023
	var out: Dictionary = {}
	out["sky"] = _paint_sky(rng)
	_paint_far(rng, out)
	_paint_mid(rng, out)
	var nb: Image = _paint_near(rng)
	out["near_bot"] = nb
	var nt: Image = nb.duplicate() as Image
	nt.flip_y()
	_tint_all(nt, Color("#7a2a78"), 0.3)
	out["near_top"] = nt
	for k: int in range(8):
		var s: Image = _paint_shard(k)
		out["shard_%d" % k] = s
		var sf: Image = s.duplicate() as Image
		sf.flip_y()
		_tint_all(sf, Color("#7a2a78"), 0.35)
		out["shardf_%d" % k] = sf
	var g: Image = _paint_ghost()
	out["ghost"] = g
	var gf: Image = g.duplicate() as Image
	gf.flip_y()
	_tint_all(gf, TOP_TINT, 0.45)
	out["ghostf"] = gf
	return out


# Blend every opaque pixel toward `c`.
static func _tint_all(img: Image, c: Color, a: float) -> void:
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			var p: Color = img.get_pixel(x, y)
			if p.a > 0.0:
				var q: Color = p.lerp(Color(c.r, c.g, c.b, p.a), a)
				img.set_pixel(x, y, q)


# Copies the lower half of a layer drawn at LAYER_Y (rows h/2..h-1) onto the upper half,
# flipped, with the reflection's magenta cast and a little darker.
static func _mirror_layer(img: Image, cast: float) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y: int in range(h / 2, h):
		var ty: int = h - 1 - y
		for x: int in range(w):
			var p: Color = img.get_pixel(x, y)
			if p.a <= 0.0:
				img.set_pixel(x, ty, p)
				continue
			var q: Color = p.lerp(Color(TOP_DARK.r, TOP_DARK.g, TOP_DARK.b, p.a), cast)
			q.a = p.a
			img.set_pixel(x, ty, q)


static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#05050b"))
	# Lower half: darkest at the mirror plane, a faint cyan-violet toward the floor.
	Painter.vgrad(sky, 140, 262, PackedColorArray([Color("#05050b"), Color("#07070f"), Color("#090914"), Color("#0c0b1a"), Color("#100f22")]), 0.5)
	# Negative-film haze along the floor.
	for y: int in range(214, 262):
		var k: float = float(y - 214) / 48.0
		for x: int in range(480):
			if Painter.bayer(x, y) < k * 0.55:
				Painter.blend_px(sky, x, y, Color("#12324a"), 0.35)
	# A negative eclipse: a black disc with a pale corona ring (the reflection gets mirrored).
	var ec: Vector2 = Vector2(352.0, 206.0)
	for y2: int in range(int(ec.y) - 40, int(ec.y) + 41):
		for x2: int in range(int(ec.x) - 40, int(ec.x) + 41):
			var d: float = Vector2(float(x2) - ec.x, float(y2) - ec.y).length()
			if d > 22.0 and d < 40.0 and Painter.bayer(x2, y2) < (1.0 - (d - 22.0) / 18.0) * 0.5:
				Painter.blend_px(sky, x2, y2, Color("#28405e"), 0.4)
	Painter.disc(sky, ec.x, ec.y, 22.0, Color("#1c2c44"))
	Painter.disc(sky, ec.x, ec.y, 20.0, Color("#020205"))
	Painter.disc(sky, ec.x - 5.0, ec.y - 4.0, 4.0, Color("#07070e"))
	# Stars (negative: pale cyan and silver, a few with cross glints).
	for i: int in range(80):
		var sx: int = rng.randi_range(0, 479)
		var sy: int = rng.randi_range(142, 250)
		var r: float = rng.randf()
		var c: Color = Color("#2a3450")
		if r > 0.6:
			c = Color("#4a5a80")
		if r > 0.9:
			c = Color("#8ad8f0")
		Painter.px(sky, sx, sy, c)
		if r > 0.97:
			Painter.px(sky, sx - 1, sy, Color("#2a3a58"))
			Painter.px(sky, sx + 1, sy, Color("#2a3a58"))
			Painter.px(sky, sx, sy - 1, Color("#2a3a58"))
			Painter.px(sky, sx, sy + 1, Color("#2a3a58"))
	# Mirror the lower half (rows 140..269) onto the upper half (139..10), magenta cast.
	for y3: int in range(140, 270):
		var ty: int = int(MIRROR_SUM) - y3
		if ty < 0:
			continue
		for x3: int in range(480):
			var p: Color = sky.get_pixel(x3, y3)
			var q: Color = p.lerp(TOP_DARK, 0.3) if p.v < 0.12 else p.lerp(Color("#b04aa0"), 0.35)
			q.a = 1.0
			sky.set_pixel(x3, ty, q)
	return sky


static func _paint_far(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = int(FAR_W)
	var h: int = 224
	var img: Image = Painter.new_img(w, h)
	var body: Color = Color("#08080f")
	var rim_l: Color = Color("#1a2438")
	var rim_r: Color = Color("#1e1830")
	var win: Color = Color("#1e3048")
	var beacons: PackedVector2Array = PackedVector2Array()
	# A low continuous base along the floor.
	var prof: PackedFloat32Array = Painter.profile(w, rng, 4, 5, 0.5)
	for x: int in range(w):
		var top: int = h - 8 - int(prof[x] * 10.0)
		Painter.vline(img, x, top, h - 1, body)
		Painter.px(img, x, top, Color("#161a2c"))
	# Spires and stepped monoliths.
	var x0: float = 6.0
	while x0 < float(w) - 6.0:
		var kind: int = rng.randi_range(0, 2)
		var bw: int = rng.randi_range(6, 14)
		var bh: int = rng.randi_range(26, 72)
		var bx: int = int(x0)
		var top_y: int = h - bh
		if kind == 0:
			# Needle spire: a tapering shaft with a long antenna.
			for yy: int in range(top_y, h):
				var t: float = float(yy - top_y) / float(bh)
				var hw: int = maxi(1, int(float(bw) * 0.5 * (0.25 + 0.75 * t)))
				Painter.span(img, bx - hw, bx + hw, yy, body)
				Painter.px(img, bx - hw, yy, rim_l)
				Painter.px(img, bx + hw, yy, rim_r)
			Painter.vline(img, bx, top_y - 12, top_y, rim_l)
			beacons.append(Vector2(float(bx), float(top_y - 13)))
		else:
			# Stepped monolith: two or three tiers with window rows.
			var tiers: int = 2 + kind - 1
			var tw: int = bw
			var ty: int = top_y
			for tier: int in range(tiers):
				var tier_h: int = maxi(8, (h - ty) / (tiers - tier + 1))
				Painter.rect(img, bx - tw / 2, ty, tw, h - ty, body)
				Painter.vline(img, bx - tw / 2, ty, h - 1, rim_l)
				Painter.vline(img, bx + tw / 2 - 1, ty, h - 1, rim_r)
				Painter.rect(img, bx - tw / 2, ty, tw, 1, Color("#222a44"))
				for wy: int in range(ty + 3, h - 6, 5):
					for wx: int in range(bx - tw / 2 + 2, bx + tw / 2 - 2, 3):
						if rng.randf() < 0.32:
							Painter.px(img, wx, wy, win if rng.randf() < 0.7 else Color("#2a2042"))
				ty += tier_h
				tw += rng.randi_range(4, 8)
			beacons.append(Vector2(float(bx), float(top_y - 1)))
		x0 += float(bw) + rng.randf_range(10.0, 34.0)
	_mirror_layer(img, 0.4)
	out["far"] = img
	out["beacons"] = beacons


static func _paint_mid(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = int(MID_W)
	var h: int = 224
	var img: Image = Painter.new_img(w, h)
	var frame_c: Color = Color("#262c46")
	var frame_hi: Color = Color("#4a5678")
	var glass: Color = Color("#0b0d18")
	var streak: Color = Color("#151a2c")
	var tops: PackedVector2Array = PackedVector2Array()
	var x: float = 24.0
	while x < float(w) - 30.0:
		var pw: float = rng.randf_range(14.0, 26.0)
		var ph: float = rng.randf_range(28.0, 62.0)
		var lean: float = rng.randf_range(-9.0, 9.0)
		var base_y: float = float(h) + 1.0
		var bl: Vector2 = Vector2(x, base_y)
		var br: Vector2 = Vector2(x + pw, base_y)
		var tr: Vector2 = Vector2(x + pw + lean, base_y - ph * rng.randf_range(0.75, 1.0))
		var tl: Vector2 = Vector2(x + lean, base_y - ph)
		var broken: bool = rng.randf() < 0.5
		var pts: PackedVector2Array = PackedVector2Array([bl, tl])
		if broken:
			# A jagged break across the top.
			var n: int = 4
			for k: int in range(1, n):
				var t: float = float(k) / float(n)
				var q: Vector2 = tl.lerp(tr, t) + Vector2(0.0, rng.randf_range(-2.0, 9.0))
				pts.append(q)
		pts.append(tr)
		pts.append(br)
		Painter.poly(img, pts, frame_c)
		# Inset glass.
		var inset: PackedVector2Array = PackedVector2Array()
		var cen: Vector2 = Vector2(x + pw * 0.5 + lean * 0.5, base_y - ph * 0.5)
		for q2: Vector2 in pts:
			inset.append(cen + (q2 - cen) * 0.84)
		Painter.poly(img, inset, glass)
		# Reflection streaks across the glass.
		for s: int in range(2):
			var sy0: float = base_y - ph * rng.randf_range(0.25, 0.8)
			var sx0: float = x + 2.0 + lean * (1.0 - (sy0 - (base_y - ph)) / ph)
			Painter.line(img, int(sx0), int(sy0 + 6.0), int(sx0 + pw * 0.6), int(sy0 - 4.0), streak)
		# Lit left edge.
		Painter.line(img, int(bl.x), int(bl.y) - 1, int(tl.x), int(tl.y), frame_hi)
		Painter.px(img, int(tl.x), int(tl.y), Color("#9fb4e0"))
		tops.append(Vector2(tl.x, tl.y))
		# Chrome debris at the foot.
		for d: int in range(rng.randi_range(1, 3)):
			var dx: float = x + rng.randf_range(-10.0, pw + 10.0)
			var dsz: float = rng.randf_range(2.0, 4.5)
			Painter.poly(img, PackedVector2Array([Vector2(dx, base_y), Vector2(dx + dsz, base_y - dsz * 1.4), Vector2(dx + dsz * 1.8, base_y)]), frame_c)
			Painter.px(img, int(dx + dsz), int(base_y - dsz * 1.4), frame_hi)
		x += pw + rng.randf_range(34.0, 70.0)
	_mirror_layer(img, 0.35)
	out["mid"] = img
	out["pane_tops"] = tops


static func _paint_near(rng: RandomNumberGenerator) -> Image:
	var w: int = 512
	var h: int = 20
	var img: Image = Painter.new_img(w, h)
	# Bollards and rails above the floor.
	for bx: int in range(10, w, 48):
		Painter.rect(img, bx, 3, 3, 6, Color("#1c2236"))
		Painter.px(img, bx, 3, Color("#5a6890"))
		Painter.px(img, bx + 1, 3, Color("#9fe8ff"))
	Painter.rect(img, 0, 5, w, 1, Color("#141a2c"))
	# Floor plates.
	Painter.rect(img, 0, 9, w, 11, Color("#10131f"))
	Painter.rect(img, 0, 9, w, 1, Color("#3a4466"))
	Painter.rect(img, 0, 10, w, 1, Color("#1f263c"))
	for px: int in range(0, w, 32):
		Painter.vline(img, px, 10, 19, Color("#06070d"))
		Painter.vline(img, px + 1, 11, 19, Color("#1a2034"))
		# Reflective diagonal sheen on each plate.
		Painter.line(img, px + 6, 18, px + 14, 11, Color("#182036"))
		if (px / 32) % 2 == 0:
			Painter.rect(img, px + 20, 14, 6, 1, Color("#1e3a52"))
			Painter.px(img, px + 22, 14, Color("#4ad8f0"))
	return img


# A dim, flat mirror shard turning in place (k = 0..7 through a half revolution).
static func _paint_shard(k: int) -> Image:
	var img: Image = Painter.new_img(16, 16)
	var ang: float = float(k) / 8.0 * PI
	var squash: float = 0.25 + 0.75 * absf(cos(ang * 2.0))
	var c: Vector2 = Vector2(8.0, 8.0)
	var pts: PackedVector2Array = PackedVector2Array()
	var shape: Array[Vector2] = [Vector2(-6.5, -1.0), Vector2(2.0, -6.5), Vector2(4.0, -2.0), Vector2(0.0, 5.5)]
	for q: Vector2 in shape:
		pts.append(c + Vector2(q.x * squash, q.y).rotated(ang * 0.5))
	var lit: float = absf(cos(ang * 2.0))
	Painter.poly(img, pts, Color("#0f1322").lerp(Color("#222c48"), lit))
	Painter.line(img, int(pts[0].x), int(pts[0].y), int(pts[1].x), int(pts[1].y), Color("#222a44").lerp(Color("#56689a"), lit))
	Painter.line(img, int(pts[3].x), int(pts[3].y), int(pts[0].x), int(pts[0].y), Color("#181c30"))
	if k == 0:
		Painter.px(img, int(pts[1].x), int(pts[1].y), Color("#bfe8ff"))
	return img


# A ghost ship (the player's silhouette, flying right) in translucent pale cyan.
static func _paint_ghost() -> Image:
	var rows: PackedStringArray = PackedStringArray([
		"....xxxx..................",
		"....xooxx.................",
		".....ooxxx................",
		"...xxooxxxxx..............",
		"..xooxxxxxxxxxx...........",
		".xoxxxxxxooxxxxxxx........",
		"xxoxxxxxxoooxxxxxxxxxxxx..",
		"xxoxxxxxxoooxxxxxxxxxxxxxx",
		"xxoxxxxxxooxxxxxxxxxxxx...",
		".xoxxxxxxxxxxxxxx.........",
		"..xooxxxxxxxxxx...........",
		"...xxooxxxxx..............",
		".....ooxxx................",
		"....xooxx.................",
		"....xxxx..................",
	])
	var img: Image = Painter.new_img(26, 15)
	for y: int in range(rows.size()):
		for x: int in range(rows[y].length()):
			var ch: String = rows[y][x]
			if ch == "x":
				img.set_pixel(x, y, Color(0.55, 0.92, 1.0, 0.55))
			elif ch == "o":
				img.set_pixel(x, y, Color(0.9, 1.0, 1.0, 0.8))
	return img


# --- Animation -------------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 142.0
	drift_a.y1 = 248.0
	drift_a.setup(22, rng, -12.0, -4.0, -2.0, 2.0)
	drift_a.par = 0.35
	drift_a.cols = PackedColorArray([Color(0.55, 0.9, 1.0, 0.4), Color(0.8, 0.85, 1.0, 0.35)])
	drift_b.y0 = 142.0
	drift_b.y1 = 248.0
	drift_b.setup(16, rng, -5.0, -1.0, -1.0, 1.0)
	drift_b.par = 0.1
	drift_b.cols = PackedColorArray([Color(0.4, 0.5, 0.8, 0.3), Color(0.45, 0.4, 0.75, 0.3)])
	_sx.resize(SHARD_N)
	_sy.resize(SHARD_N)
	_sv.resize(SHARD_N)
	_ss.resize(SHARD_N)
	_sa.resize(SHARD_N)
	for i: int in range(SHARD_N):
		_sx[i] = rng.randf_range(0.0, 480.0)
		_sy[i] = rng.randf_range(150.0, 236.0) if i % 3 != 0 else rng.randf_range(196.0, 238.0)
		_sv[i] = rng.randf_range(0.1, 0.22)
		_ss[i] = rng.randf_range(0.4, 1.2) * (1.0 if i % 2 == 0 else -1.0)
		_sa[i] = rng.randf_range(0.0, 8.0)
	_glint_pos.resize(0)
	_glint_age.resize(0)
	_crack.resize(0)
	_crack_y.resize(0)
	_pulse = 0.0
	bg._ev_a.arm(rng, 16.0, 26.0, 5.0, 9.0)     # the mirror plane cracks and heals
	bg._ev_b.arm(rng, 13.0, 21.0, 9.0, 13.0)    # kaleidoscope bloom
	bg._ev_c.arm(rng, 18.0, 28.0, 13.0, 18.0)   # a ghost ship flies the other way


func update() -> void:
	for i: int in range(SHARD_N):
		var nx: float = _sx[i] - ds * _sv[i] - 3.0 * dl
		if nx < -20.0:
			nx += 520.0
			_sy[i] = rng.randf_range(150.0, 238.0)
		_sx[i] = nx
		_sa[i] = fposmod(_sa[i] + _ss[i] * dl * 3.0, 8.0)
	# Glints on the pane tops.
	var gi: int = 0
	while gi < _glint_age.size():
		_glint_age[gi] += dl
		var gp: Vector2 = _glint_pos[gi]
		gp.x -= ds * 0.2
		_glint_pos[gi] = gp
		if _glint_age[gi] > 0.5:
			_glint_age.remove_at(gi)
			_glint_pos.remove_at(gi)
			continue
		gi += 1
	_glint_t -= dl
	if _glint_t <= 0.0:
		_glint_t = rng.randf_range(0.25, 0.6)
		var tops: PackedVector2Array = meta.get("pane_tops", PackedVector2Array())
		if not tops.is_empty() and _glint_age.size() < 4:
			var o: float = off(0.2, MID_W)
			var t: Vector2 = tops[rng.randi_range(0, tops.size() - 1)]
			var gx: float = wrap_x(t.x, o, MID_W)
			if gx > 0.0 and gx < 480.0:
				_glint_pos.append(Vector2(gx, LAYER_Y + t.y))
				_glint_age.append(0.0)
	# A: the crack.
	if bg._ev_a.tick(dl, rng):
		bg._ev_a.dur = 3.6
		_make_crack()
		_pulsed = false
	if bg._ev_a.on and not _pulsed and bg._ev_a.t > 0.75:
		_pulsed = true
		_pulse = 1.0
	_pulse = maxf(0.0, _pulse - dl * 1.8)
	# B: kaleidoscope.
	if bg._ev_b.tick(dl, rng):
		bg._ev_b.dur = 3.2
		_kal = Vector2(rng.randf_range(130.0, 400.0), rng.randf_range(52.0, 96.0))
	# C: ghost ship.
	if bg._ev_c.tick(dl, rng):
		bg._ev_c.dur = 4.6
		_ghost_y = rng.randf_range(176.0, 220.0)


# The crack: a jagged run along the plane from _crack_x0 out to both sides, with mirrored
# branches. Each segment is (x0, x1, branch flag) with its two y offsets in _crack_y.
func _make_crack() -> void:
	_crack.resize(0)
	_crack_y.resize(0)
	_crack_x0 = rng.randf_range(150.0, 330.0)
	for side: float in [-1.0, 1.0]:
		var x: float = _crack_x0
		var y: float = 0.0
		var length: float = rng.randf_range(110.0, 170.0)
		while absf(x - _crack_x0) < length:
			var nx: float = x + side * rng.randf_range(5.0, 10.0)
			var ny: float = clampf(y + rng.randf_range(-1.5, 1.5), 0.0, 3.0)
			_crack.append(Vector3(x, nx, 0.0))
			_crack_y.append(Vector2(y, ny))
			if rng.randf() < 0.13:
				var bl: float = rng.randf_range(5.0, 14.0)
				var lean: float = rng.randf_range(-0.8, 1.2)
				_crack.append(Vector3(nx, nx + side * bl * lean, 1.0))
				_crack_y.append(Vector2(ny, ny + bl))
			x = nx
			y = ny


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	_draw_kaleidoscope()
	layer("far", LAYER_Y, 0.06)
	_draw_beacons()
	_draw_ghost()
	_draw_drift(drift_b)
	_draw_shards()
	layer("mid", LAYER_Y, 0.2)
	_draw_glints()
	_draw_plane()
	_draw_crack()
	layer("near_top", NEAR_TOP_Y, 0.8)
	layer("near_bot", NEAR_BOT_Y, 0.8)
	_draw_drift(drift_a)
	if _pulse > 0.0:
		bg.draw_rect(Rect2(0.0, 22.0, 480.0, 236.0), Color(0.78, 0.95, 1.0, 0.07 * _pulse))


# Motes in the lower half and their reflections.
func _draw_drift(p: StarfieldBg.Drift) -> void:
	var n: int = p.x.size()
	var nc: int = p.cols.size()
	if n == 0 or nc == 0:
		return
	for i: int in range(n):
		var x: float = floorf(p.x[i])
		var y: float = floorf(p.y[i])
		var c: Color = p.cols[i % nc]
		bg.draw_rect(Rect2(x, y, 1.0, 1.0), c)
		bg.draw_rect(Rect2(x, MIRROR_SUM - y, 1.0, 1.0), Color(c.r * 0.9 + 0.1, c.g * 0.7, c.b, c.a * 0.85))


func _draw_beacons() -> void:
	var beacons: PackedVector2Array = meta.get("beacons", PackedVector2Array())
	var o: float = off(0.06, FAR_W)
	for i: int in range(beacons.size()):
		var bx: float = wrap_x(beacons[i].x, o, FAR_W)
		if bx < 0.0 or bx > 480.0:
			continue
		var on: float = fposmod(life * 0.7 + float(i) * 0.31, 1.0)
		if on < 0.35:
			var y: float = floorf(LAYER_Y + beacons[i].y)
			var a: float = 0.9 if on < 0.12 else 0.45
			bg.draw_rect(Rect2(floorf(bx), y, 1.0, 1.0), Color(0.6, 0.95, 1.0, a))
			bg.draw_rect(Rect2(floorf(bx), MIRROR_SUM - y, 1.0, 1.0), Color(1.0, 0.5, 0.9, a))


func _draw_shards() -> void:
	for i: int in range(SHARD_N):
		var k: int = int(_sa[i]) % 8
		var x: float = floorf(_sx[i]) - 8.0
		var y: float = floorf(_sy[i]) - 8.0
		bg.draw_texture(tex("shard_%d" % k), Vector2(x, y), Color(1.0, 1.0, 1.0, 0.65))
		bg.draw_texture(tex("shardf_%d" % k), Vector2(x, MIRROR_SUM - y - 15.0), Color(1.0, 1.0, 1.0, 0.65))
		if k == 0:
			# Catching the light: a small four-point glint on the shard and its reflection.
			var gx: float = x + 8.0
			var gy: float = y + 3.0
			var gc: Color = Color(0.85, 0.97, 1.0, 0.6)
			bg.draw_rect(Rect2(gx - 2.0, gy, 5.0, 1.0), gc)
			bg.draw_rect(Rect2(gx, gy - 2.0, 1.0, 5.0), gc)
			var my: float = MIRROR_SUM - gy
			bg.draw_rect(Rect2(gx - 2.0, my, 5.0, 1.0), Color(1.0, 0.7, 0.95, 0.55))
			bg.draw_rect(Rect2(gx, my - 2.0, 1.0, 5.0), Color(1.0, 0.7, 0.95, 0.55))


func _draw_glints() -> void:
	for s: int in range(_glint_pos.size()):
		var k: float = sin(_glint_age[s] / 0.5 * PI)
		var p: Vector2 = _glint_pos[s].floor()
		var arm: float = 1.0 + floorf(k * 2.5)
		var c: Color = Color(0.9, 0.98, 1.0, 0.8 * k)
		bg.draw_rect(Rect2(p.x - arm, p.y, arm * 2.0 + 1.0, 1.0), c)
		bg.draw_rect(Rect2(p.x, p.y - arm, 1.0, arm * 2.0 + 1.0), c)
		var my: float = MIRROR_SUM - p.y
		var c2: Color = Color(1.0, 0.7, 0.95, 0.7 * k)
		bg.draw_rect(Rect2(p.x - arm, my, arm * 2.0 + 1.0, 1.0), c2)
		bg.draw_rect(Rect2(p.x, my - arm, 1.0, arm * 2.0 + 1.0), c2)


# The mirror plane: a barely-there line on rows 139/140 with soft highlights sliding along it.
func _draw_plane() -> void:
	bg.draw_rect(Rect2(0.0, 139.0, 480.0, 2.0), Color(0.6, 0.85, 1.0, 0.035))
	for i: int in range(3):
		var spd: float = 38.0 + 23.0 * float(i)
		var length: float = 26.0 + 12.0 * float(i)
		var x: float = fposmod(-life * spd + float(i) * 211.0, 560.0) - 40.0
		bg.draw_rect(Rect2(floorf(x), 139.0, length, 1.0), Color(0.75, 0.95, 1.0, 0.07))
		bg.draw_rect(Rect2(floorf(x) + 6.0, 140.0, length, 1.0), Color(1.0, 0.6, 0.92, 0.06))


func _draw_crack() -> void:
	if not bg._ev_a.on or _crack.is_empty():
		return
	var t: float = bg._ev_a.t
	var grow: float = clampf(t / 0.75, 0.0, 1.0)
	var heal: float = clampf((bg._ev_a.dur - t) / 1.3, 0.0, 1.0)
	var reach: float = 180.0 * grow * heal
	var a: float = 0.38 * heal
	for i: int in range(_crack.size()):
		var sg: Vector3 = _crack[i]
		if absf(sg.x - _crack_x0) > reach:
			continue
		var y0: float = _crack_y[i].x
		var y1: float = _crack_y[i].y
		var c: Color = Color(0.92, 0.98, 1.0, a) if sg.z < 0.5 else Color(0.8, 0.9, 1.0, a * 0.7)
		bg.draw_line(Vector2(sg.x, AXIS - 0.5 - y0), Vector2(sg.y, AXIS - 0.5 - y1), c, 1.0)
		bg.draw_line(Vector2(sg.x, AXIS + 0.5 + y0), Vector2(sg.y, AXIS + 0.5 + y1), Color(1.0, 0.75, 0.95, c.a), 1.0)
	if grow < 1.0:
		bg.draw_circle(Vector2(_crack_x0, AXIS), 3.0 + 4.0 * grow, Color(1.0, 1.0, 1.0, 0.3 * (1.0 - grow)))


# Six mirrored petals turning around a point in the upper half, with their reflection below.
func _draw_kaleidoscope() -> void:
	if not bg._ev_b.on:
		return
	var u: float = bg._ev_b.t / bg._ev_b.dur
	var fade: float = minf(1.0, minf(u * 4.0, (1.0 - u) * 3.0))
	var r: float = 12.0 + 38.0 * u
	var rot: float = life * 0.6
	for half: int in range(2):
		var c0: Vector2 = _kal if half == 0 else Vector2(_kal.x, MIRROR_SUM - _kal.y)
		var sgn: float = 1.0 if half == 0 else -1.0
		for k: int in range(12):
			var a0: float = rot * sgn + TAU * float(k) / 12.0
			var a1: float = a0 + TAU / 24.0 * (1.0 if k % 2 == 0 else -1.0)
			var p0: Vector2 = c0 + Vector2.from_angle(a0) * r
			var p1: Vector2 = c0 + Vector2.from_angle(a1) * r * 0.62
			var col: Color = Color(0.4, 0.95, 1.0, 0.12 * fade) if k % 2 == 0 else Color(1.0, 0.45, 0.88, 0.1 * fade)
			bg.draw_primitive(PackedVector2Array([c0, p0, p1]), PackedColorArray([col, col, col]), PackedVector2Array())
		bg.draw_arc(c0, r + 2.0, 0.0, TAU, 24, Color(0.85, 0.95, 1.0, 0.07 * fade), 1.0)


func _draw_ghost() -> void:
	if not bg._ev_c.on:
		return
	var u: float = bg._ev_c.t / bg._ev_c.dur
	var x: float = floorf(-30.0 + 540.0 * u)
	var fade: float = minf(1.0, minf(u * 6.0, (1.0 - u) * 6.0)) * 0.55
	var y: float = floorf(_ghost_y)
	bg.draw_texture(tex("ghost"), Vector2(x, y - 7.0), Color(1.0, 1.0, 1.0, fade))
	bg.draw_texture(tex("ghostf"), Vector2(x, MIRROR_SUM - y - 7.0), Color(1.0, 1.0, 1.0, fade))
	# A thin fading trail behind it (it flies right).
	for k: int in range(4):
		var tx: float = x - 6.0 - float(k) * 7.0
		bg.draw_rect(Rect2(tx, y, 5.0, 1.0), Color(0.6, 0.95, 1.0, fade * 0.25 * (1.0 - float(k) / 4.0)))
		bg.draw_rect(Rect2(tx, MIRROR_SUM - y, 5.0, 1.0), Color(1.0, 0.6, 0.9, fade * 0.25 * (1.0 - float(k) / 4.0)))
