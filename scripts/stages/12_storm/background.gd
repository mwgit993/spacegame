extends "res://scripts/stages/stage_background.gd"

# JOVIAN STORM: deep inside a gas giant's storm bands. Nine horizontal cloud belts stream past at
# different speeds, alternate belts flowing the opposite way, with festoons and little eddies
# curling inside them. The Great Storm Eye turns far away. Thin cloud streamers drift in the
# middle distance; dark thunderhead tops line the bottom edge and a heavy cloud base hangs along
# the top. Wind-driven rain slants across, ammonia ice glints, and lightning flickers inside the
# far clouds.
#
# Layers (paint(), worker thread):
#   "sky"        480x270 at (0,0): deep backdrop gradient (seen only behind gaps)
#   "band0".."band8"  512 wide belts from y 22 to 258, each with its own scroll factor and a
#                ragged top edge that overlaps the belt above
#   "eye"        128x384: 6 frames (128x64 each) of the Great Storm Eye, cycled
#   "wisps"      640x236 at y 22, parallax 0.3: thin translucent streamers
#   "base_top"   512x34 at y 22, parallax 0.55: the cloud base hanging along the top
#   "tops_far"   512x44 at y 214, parallax 0.5: thunderhead tops
#   "tops_near"  512x30 at y 234, parallax 1.0: nearer, darker tops
#   "aerostat"   72x44: a gas-mining aerostat (event sprite)
# Rare events: a big lightning strike from the cloud base to the tops with a brief flash
# (_ev_a), a cyclone vortex wheeling past in the middle distance (_ev_b), and a gas-mining
# aerostat drifting by with blinking lights and a dangling intake hose (_ev_c).
# Readability: the belts are dark and close in value; bright pixels are small or brief.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const BANDS: Array[Vector3] = [
	# y, height, scroll factor (negative = flows the other way)
	Vector3(22.0, 18.0, 0.07), Vector3(40.0, 22.0, -0.035), Vector3(62.0, 26.0, 0.1),
	Vector3(88.0, 24.0, -0.05), Vector3(112.0, 30.0, 0.045), Vector3(142.0, 24.0, -0.075),
	Vector3(166.0, 28.0, 0.11), Vector3(194.0, 24.0, -0.04), Vector3(218.0, 40.0, 0.08),
]
const EYE_W: float = 128.0
const EYE_H: float = 64.0
const EYE_Y: float = 92.0
const LIP: int = 6
const WISP_Y: float = 22.0
const TOPS_FAR_Y: float = 214.0
const TOPS_NEAR_Y: float = 234.0
const RAIN: int = 64

var _rain_x: PackedFloat32Array = PackedFloat32Array()
var _rain_y: PackedFloat32Array = PackedFloat32Array()
var _rain_v: PackedFloat32Array = PackedFloat32Array()
var _flick_t: float = 0.5
var _flick_on: float = 0.0
var _flick_pos: Vector2 = Vector2.ZERO
var _flick_r: float = 16.0
var _flick_bolt: PackedVector2Array = PackedVector2Array()
var _strike: PackedVector2Array = PackedVector2Array()
var _branch: PackedVector2Array = PackedVector2Array()


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1212
	var out: Dictionary = {}
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#080e14"))
	Painter.vgrad(sky, 22, 258, PackedColorArray([Color("#0a121a"), Color("#0b141c"), Color("#0d1820"), Color("#0b141c")]), 0.5)
	out["sky"] = sky
	var ramps: Array[PackedColorArray] = [
		PackedColorArray([Color("#0c131a"), Color("#101921"), Color("#151f29"), Color("#1a2631"), Color("#253442")]),  # slate
		PackedColorArray([Color("#140f0d"), Color("#1a1411"), Color("#211915"), Color("#291f19"), Color("#382a21")]),  # rust
		PackedColorArray([Color("#091417"), Color("#0c1b1f"), Color("#102226"), Color("#142a30"), Color("#1d3a42")]),  # teal
		PackedColorArray([Color("#121210"), Color("#181814"), Color("#1f1f1a"), Color("#27261f"), Color("#37342a")]),  # cream (muted)
	]
	var band_ramp: Array[int] = [0, 2, 0, 3, 2, 1, 0, 3, 2]
	for i: int in range(BANDS.size()):
		out["band%d" % i] = _paint_band(int(BANDS[i].y), ramps[band_ramp[i]], rng, 1300 + i)
	out["eye"] = _paint_eye()
	out["wisps"] = _paint_wisps(rng)
	out["base_top"] = _paint_clouds(rng, 34, false, PackedColorArray([Color("#070b10"), Color("#0b1118"), Color("#101820"), Color("#16212b"), Color("#22303c")]), 22, 0.0)
	out["tops_far"] = _paint_clouds(rng, 44, true, PackedColorArray([Color("#080c12"), Color("#0c121a"), Color("#111a23"), Color("#18242f"), Color("#26364a")]), 16, 30.0)
	out["tops_near"] = _paint_clouds(rng, 30, true, PackedColorArray([Color("#05080c"), Color("#080c12"), Color("#0b1118"), Color("#0f1820"), Color("#18242f")]), 12, 22.0)
	out["aerostat"] = _paint_aerostat()
	return out


# One belt: streaky flow (noise stretched 8x along x) with a wavy top edge LIP rows tall that
# overlaps the belt above (drawn top to bottom, so neighbouring belts shear against each other
# along a ragged line), plume streaks curling off that edge, soft eddies and a pale oval or two.
static func _paint_band(h: int, ramp: PackedColorArray, rng: RandomNumberGenerator, seed_v: int) -> Image:
	var w: int = 512
	var hh: int = h + LIP
	var img: Image = Painter.new_img(w, hh)
	var nw: int = w / 8
	var nf: PackedByteArray = Painter.fast_field(nw, hh, 5.0, 3, seed_v)
	var nf2: PackedByteArray = Painter.fast_field(w, hh, 14.0, 2, seed_v + 50)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 5, 0.6)
	var tops: PackedInt32Array = PackedInt32Array()
	tops.resize(w)
	for x0: int in range(w):
		tops[x0] = int(prof[x0] * float(LIP))
	for y: int in range(hh):
		for x: int in range(w):
			var top: int = tops[x]
			if y < top:
				continue
			var fx: float = float(x) / 8.0
			var i0: int = int(fx) % nw
			var i1: int = (i0 + 1) % nw
			var ft: float = fx - floorf(fx)
			var a: float = lerpf(float(nf[y * nw + i0]), float(nf[y * nw + i1]), ft) / 255.0
			var b: float = float(nf2[y * w + x]) / 255.0
			var depth: float = float(y - top) / float(hh - top)
			var v: float = 0.3 + (a - 0.5) * 0.9 + (b - 0.5) * 0.3 - depth * 0.12
			if y - top == 0:
				v = 0.02
			elif y - top <= 2:
				v += 0.22
			img.set_pixel(x, y, Painter.ramp_pick(ramp, clampf(v, 0.0, 0.9), x, y))
	# Streaks: thin pale lines along the flow.
	for s: int in range(rng.randi_range(3, 6)):
		var sy: int = rng.randi_range(LIP + 2, hh - 3)
		var sx: int = rng.randi_range(0, w - 1)
		var sl: int = rng.randi_range(30, 90)
		for k: int in range(sl):
			var yy: int = sy + int(round(sin(float(k) * 0.05 + float(s)) * 1.5))
			if Painter.bayer(sx + k, yy) < 0.55 - absf(float(k) / float(sl) - 0.5):
				Painter.px(img, sx + k, yy, ramp[3])
	# Plumes curling off the ragged top edge into the belt.
	for pl: int in range(rng.randi_range(3, 6)):
		var px0: int = rng.randi_range(0, w - 1)
		var py: float = float(tops[px0]) + 2.0
		var curl: float = 1.0 if rng.randf() < 0.5 else -1.0
		for k2: int in range(22):
			var t: float = float(k2) / 21.0
			var xx: int = px0 + int(float(k2) * 1.6)
			var yy2: int = int(py + sin(t * 2.6) * float(h) * 0.35 + curl * t * t * 3.0)
			if yy2 < hh and Painter.bayer(xx, yy2) < 0.75 - t * 0.5:
				Painter.px(img, xx, yy2, ramp[3] if k2 < 12 else ramp[2])
	# Soft eddies: oval spirals.
	for e: int in range(rng.randi_range(1, 3)):
		var ec: Vector2 = Vector2(rng.randf_range(0.0, float(w)), float(LIP) + rng.randf_range(5.0, float(h) - 5.0))
		var er: float = minf(rng.randf_range(5.0, 9.0), float(h) * 0.38)
		var dirs: float = 1.0 if rng.randf() < 0.5 else -1.0
		for t2: int in range(70):
			var tt: float = float(t2) / 70.0
			var ang: float = dirs * tt * TAU * 1.8
			var r: float = er * (1.0 - tt * 0.85)
			var q: Vector2 = ec + Vector2(cos(ang) * r * 2.0, sin(ang) * r)
			if Painter.bayer(int(q.x), int(q.y)) < 0.8:
				Painter.px(img, int(q.x), int(q.y), ramp[3] if t2 % 4 != 0 else ramp[4])
	# A pale oval storm now and then.
	if rng.randf() < 0.6:
		var oc: Vector2 = Vector2(rng.randf_range(0.0, float(w)), float(LIP) + float(h) * 0.5)
		var orx: float = rng.randf_range(6.0, 10.0)
		var ory: float = minf(4.0, float(h) * 0.22)
		Painter.ellipse(img, oc.x, oc.y, orx + 1.0, ory + 1.0, ramp[1])
		Painter.ellipse(img, oc.x, oc.y, orx, ory, ramp[3])
		Painter.ellipse(img, oc.x - 1.0, oc.y - 0.5, orx * 0.55, ory * 0.5, ramp[4])
	return img


# The Great Storm Eye: an oval vortex, rust and cream spiral arms around a dark core, 6 frames
# with the arms rotated a sixth of their spacing each.
static func _paint_eye() -> Image:
	var w: int = int(EYE_W)
	var fh: int = int(EYE_H)
	var img: Image = Painter.new_img(w, fh * 6)
	var ramp: PackedColorArray = PackedColorArray([Color("#1a110d"), Color("#251710"), Color("#321d13"), Color("#402417"), Color("#4f2d1b"), Color("#623a22")])
	var cx: float = float(w) * 0.5
	var cy: float = float(fh) * 0.5
	for f: int in range(6):
		var ph: float = TAU * float(f) / 6.0 / 3.0
		for y: int in range(fh):
			for x: int in range(w):
				var dx: float = (float(x) + 0.5 - cx) / (cx - 1.0)
				var dy: float = (float(y) + 0.5 - cy) / (cy - 1.0)
				var r: float = sqrt(dx * dx + dy * dy)
				if r > 1.0:
					continue
				var ang: float = atan2(dy, dx)
				# Three log-spiral arms, rotating with ph.
				var arm: float = 0.5 + 0.5 * sin(ang * 3.0 + log(maxf(r, 0.04)) * 5.0 - ph * 3.0)
				var v: float = arm * (0.35 + 0.65 * (1.0 - r)) + (1.0 - r) * 0.25
				if r < 0.16:
					v = 0.1 + r * 1.5
				# Fade out toward the rim with dithering so it melts into the belt.
				if r > 0.72 and Painter.bayer(x, y) < (r - 0.72) / 0.28:
					continue
				img.set_pixel(x, y + f * fh, Painter.ramp_pick(ramp, clampf(v, 0.0, 1.0), x, y))
	return img


static func _paint_wisps(rng: RandomNumberGenerator) -> Image:
	var w: int = 640
	var h: int = 236
	var img: Image = Painter.new_img(w, h)
	var cols: Array[Color] = [Color(0.2, 0.28, 0.34, 0.5), Color(0.26, 0.34, 0.4, 0.45), Color(0.3, 0.24, 0.2, 0.45)]
	for s: int in range(26):
		var sy: float = rng.randf_range(10.0, float(h) - 20.0)
		var sx: float = rng.randf_range(0.0, float(w))
		var sl: int = rng.randi_range(40, 140)
		var thick: int = rng.randi_range(1, 3)
		var col: Color = cols[s % cols.size()]
		var amp: float = rng.randf_range(1.0, 4.0)
		for k: int in range(sl):
			var t: float = float(k) / float(sl)
			var taper: float = sin(t * PI)
			var yy: float = sy + sin(t * 4.0 + float(s)) * amp
			for th: int in range(thick):
				var x: int = int(sx) + k
				var y: int = int(yy) + th
				if Painter.bayer(x, y) < taper * 0.55:
					Painter.px(img, x, y, col)
	return img


# A row of puffy clouds. flat_up = true: tops billowing upward from the bottom of the strip
# (thunderhead tops); false: a cloud base hanging down from the top of the strip.
static func _paint_clouds(rng: RandomNumberGenerator, h: int, flat_up: bool, ramp: PackedColorArray, puff_h: int, base_off: float) -> Image:
	var w: int = 512
	var mask: PackedByteArray = PackedByteArray()
	mask.resize(w * h)
	var x: float = 0.0
	while x < float(w) + 20.0:
		var pw: float = rng.randf_range(26.0, 60.0)
		var ph: float = float(puff_h) * rng.randf_range(0.6, 1.2)
		Painter.cloud_puff(mask, w, h, x, float(h) - 1.0 + 4.0, pw, ph, rng, true)
		x += pw * rng.randf_range(0.45, 0.8)
	# Fill everything below the puffs' base line so the strip is solid at its bottom.
	for y: int in range(int(float(h) - base_off * 0.2), h):
		for xx: int in range(w):
			mask[y * w + xx] = 1
	var img: Image = Painter.new_img(w, h)
	Painter.paint_cloud_mask(img, mask, w, h, 0, ramp)
	if not flat_up:
		img.flip_y()
	return img


static func _paint_aerostat() -> Image:
	var img: Image = Painter.new_img(72, 44)
	var env: PackedColorArray = PackedColorArray([Color("#1e1a18"), Color("#2c2622"), Color("#3c342c"), Color("#52463a")])
	# Envelope: a long ellipse, lit from above, with rust bands.
	for y: int in range(0, 22):
		for x: int in range(4, 68):
			var dx: float = (float(x) + 0.5 - 36.0) / 32.0
			var dy: float = (float(y) + 0.5 - 11.0) / 10.5
			if dx * dx + dy * dy > 1.0:
				continue
			var v: float = 0.55 - dy * 0.45
			var c: Color = Painter.ramp_pick(env, v, x, y)
			if (x / 9) % 2 == 0 and absf(dy) < 0.85:
				c = c.lerp(Color("#5a2a18"), 0.45)
			Painter.px(img, x, y, c)
	# Gondola and rigging.
	Painter.line(img, 26, 20, 30, 26, Color("#1a1614"))
	Painter.line(img, 46, 20, 42, 26, Color("#1a1614"))
	Painter.rect(img, 28, 26, 16, 6, Color("#24201c"))
	Painter.rect(img, 28, 26, 16, 1, Color("#3c342c"))
	for wx: int in range(30, 43, 3):
		Painter.px(img, wx, 28, Color("#c88a34"))
	# Fins.
	Painter.poly(img, PackedVector2Array([Vector2(62, 6), Vector2(71, 2), Vector2(71, 9), Vector2(64, 11)]), Color("#2c2622"))
	Painter.poly(img, PackedVector2Array([Vector2(62, 16), Vector2(71, 20), Vector2(71, 13), Vector2(64, 11)]), Color("#24201c"))
	return img


# --- Animation -------------------------------------------------------------------------------------

func reset() -> void:
	drift_b.y0 = 30.0
	drift_b.y1 = 250.0
	drift_b.setup(22, rng, -16.0, -6.0, -3.0, 3.0)
	drift_b.par = 0.4
	drift_b.blink = 0.7
	drift_b.duty = 0.6
	drift_b.cols = PackedColorArray([Color(0.75, 0.85, 0.95, 0.5), Color(0.6, 0.7, 0.85, 0.4)])
	_rain_x.resize(RAIN)
	_rain_y.resize(RAIN)
	_rain_v.resize(RAIN)
	for i: int in range(RAIN):
		_rain_x[i] = rng.randf_range(0.0, 500.0)
		_rain_y[i] = rng.randf_range(24.0, 256.0)
		_rain_v[i] = rng.randf_range(0.8, 1.3)
	_flick_t = rng.randf_range(0.3, 1.0)
	_flick_on = 0.0
	bg._ev_a.arm(rng, 9.0, 16.0, 4.0, 8.0)     # big lightning strike
	bg._ev_b.arm(rng, 18.0, 28.0, 8.0, 13.0)   # cyclone vortex
	bg._ev_c.arm(rng, 26.0, 40.0, 3.0, 7.0)    # gas-mining aerostat


func update() -> void:
	# Wind-driven rain: fast, slanting down-left.
	for i: int in range(RAIN):
		var nx: float = _rain_x[i] - (230.0 * _rain_v[i]) * dl - ds * 0.6
		var ny: float = _rain_y[i] + 70.0 * _rain_v[i] * dl
		if nx < -10.0 or ny > 258.0:
			nx = rng.randf_range(480.0, 560.0) if nx < -10.0 else rng.randf_range(0.0, 560.0)
			ny = rng.randf_range(20.0, 200.0) if nx > 470.0 else 24.0
		_rain_x[i] = nx
		_rain_y[i] = ny
	# Lightning flickering inside the far belts.
	if _flick_on > 0.0:
		_flick_on -= dl
	else:
		_flick_t -= dl
		if _flick_t <= 0.0:
			_flick_t = rng.randf_range(0.5, 1.9)
			_flick_on = rng.randf_range(0.1, 0.24)
			_flick_pos = Vector2(rng.randf_range(20.0, 460.0), rng.randf_range(44.0, 214.0))
			_flick_r = rng.randf_range(12.0, 26.0)
			_flick_bolt = _jagged(_flick_pos + Vector2(rng.randf_range(-8.0, 8.0), -_flick_r * 0.6), _flick_pos + Vector2(rng.randf_range(-14.0, 14.0), _flick_r * 0.7), 5, 4.0)
	# Big strike: a bolt from the cloud base to the tops, with one branch.
	if bg._ev_a.tick(dl, rng):
		bg._ev_a.dur = 0.55
		var sx: float = rng.randf_range(70.0, 420.0)
		_strike = _jagged(Vector2(sx, 46.0), Vector2(sx + rng.randf_range(-60.0, 60.0), 226.0), 14, 9.0)
		var bi: int = rng.randi_range(4, 8)
		_branch = _jagged(_strike[bi], _strike[bi] + Vector2(rng.randf_range(-50.0, 50.0), rng.randf_range(30.0, 60.0)), 5, 6.0)
	if bg._ev_b.tick(dl, rng):
		bg._ev_b.dur = 10.0
		bg._ev_b.y = rng.randf_range(110.0, 170.0)
	if bg._ev_c.tick(dl, rng):
		bg._ev_c.dur = 30.0
		bg._ev_c.y = rng.randf_range(54.0, 86.0)


func _jagged(a: Vector2, b: Vector2, segs: int, jit: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(segs + 1):
		var t: float = float(i) / float(segs)
		var p: Vector2 = a.lerp(b, t)
		if i > 0 and i < segs:
			p += Vector2(rng.randf_range(-jit, jit), rng.randf_range(-jit * 0.3, jit * 0.3))
		pts.append(p.floor() + Vector2(0.5, 0.5))
	return pts


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	for i: int in range(BANDS.size()):
		layer("band%d" % i, BANDS[i].x - float(LIP), BANDS[i].z)
	# The Great Storm Eye, turning slowly inside the middle belt.
	var eye: Texture2D = tex("eye")
	var ex: float = floorf(fposmod(300.0 - scroll * 0.025, 680.0) - 100.0)
	if ex > -EYE_W and ex < 480.0:
		var frame: int = int(life * 1.6) % 6
		bg.draw_texture_rect_region(eye, Rect2(ex, EYE_Y, EYE_W, EYE_H), Rect2(0.0, float(frame) * EYE_H, EYE_W, EYE_H))
	# Lightning flicker lighting up a patch of cloud from inside.
	if _flick_on > 0.0:
		var a: float = clampf(_flick_on * 6.0, 0.0, 1.0)
		bg.draw_circle(_flick_pos, _flick_r, Color(0.55, 0.62, 0.9, 0.07 * a))
		bg.draw_circle(_flick_pos, _flick_r * 0.5, Color(0.7, 0.75, 1.0, 0.07 * a))
		bg.draw_polyline(_flick_bolt, Color(0.85, 0.88, 1.0, 0.45 * a), 1.0)
	_draw_aerostat()
	layer("wisps", WISP_Y, 0.3)
	_draw_cyclone()
	drift_draw(drift_b)
	layer("base_top", 22.0, 0.55)
	layer("tops_far", TOPS_FAR_Y, 0.5)
	_draw_strike()
	# Rain, batched into one call.
	var segs: PackedVector2Array = PackedVector2Array()
	for r: int in range(RAIN):
		var p: Vector2 = Vector2(floorf(_rain_x[r]) + 0.5, floorf(_rain_y[r]) + 0.5)
		segs.append(p)
		segs.append(p + Vector2(5.0, -2.0) * _rain_v[r])
	bg.draw_multiline(segs, Color(0.55, 0.68, 0.78, 0.22), 1.0)
	layer("tops_near", TOPS_NEAR_Y, 1.0)


func _draw_strike() -> void:
	if not bg._ev_a.on or _strike.size() < 2:
		return
	var u: float = bg._ev_a.t / bg._ev_a.dur
	# Strike, a dark gap, then a re-strike.
	var vis: float = 1.0 if u < 0.25 else (0.0 if u < 0.38 else maxf(0.0, 1.0 - (u - 0.38) / 0.62))
	if vis <= 0.0:
		return
	bg.draw_rect(Rect2(0.0, 22.0, 480.0, 236.0), Color(0.7, 0.75, 1.0, 0.06 * vis))
	bg.draw_polyline(_strike, Color(0.55, 0.6, 1.0, 0.3 * vis), 3.0)
	bg.draw_polyline(_branch, Color(0.55, 0.6, 1.0, 0.25 * vis), 2.0)
	bg.draw_polyline(_strike, Color(0.95, 0.96, 1.0, 0.95 * vis), 1.0)
	bg.draw_polyline(_branch, Color(0.9, 0.92, 1.0, 0.7 * vis), 1.0)
	bg.draw_circle(_strike[_strike.size() - 1], 10.0, Color(0.7, 0.75, 1.0, 0.18 * vis))


# A cyclone wheeling past in the middle distance: two rotating spiral arms of pale cloud and a
# dark core.
func _draw_cyclone() -> void:
	if not bg._ev_b.on:
		return
	var u: float = bg._ev_b.t / bg._ev_b.dur
	var c: Vector2 = Vector2(floorf(540.0 - u * 640.0), floorf(bg._ev_b.y))
	var fade: float = minf(1.0, minf(u * 6.0, (1.0 - u) * 6.0))
	bg.draw_circle(c, 7.0, Color(0.03, 0.05, 0.07, 0.35 * fade))
	for arm: int in range(2):
		var pts: PackedVector2Array = PackedVector2Array()
		for k: int in range(22):
			var t: float = float(k) / 21.0
			var ang: float = -life * 1.8 + float(arm) * PI + t * 4.2
			var r: float = 6.0 + t * 30.0
			pts.append((c + Vector2(cos(ang) * r * 1.5, sin(ang) * r * 0.75)).floor() + Vector2(0.5, 0.5))
		bg.draw_polyline(pts, Color(0.42, 0.5, 0.56, 0.22 * fade), 2.0)
		bg.draw_polyline(pts, Color(0.6, 0.66, 0.7, 0.18 * fade), 1.0)


func _draw_aerostat() -> void:
	if not bg._ev_c.on:
		return
	var u: float = bg._ev_c.t / bg._ev_c.dur
	var p: Vector2 = Vector2(floorf(520.0 - u * 680.0), floorf(bg._ev_c.y + sin(life * 0.5) * 2.0))
	bg.draw_texture(tex("aerostat"), p)
	# Intake hose dangling down into the clouds, swaying.
	var prev: Vector2 = p + Vector2(36.5, 32.5)
	for s: int in range(1, 9):
		var nx: Vector2 = p + Vector2(36.5 + sin(life * 0.9 + float(s) * 0.5) * float(s) * 0.8, 32.5 + float(s) * 7.0)
		bg.draw_line(prev, nx, Color("#1a1614"), 1.0)
		prev = nx
	# Blinking nav lights.
	if fposmod(life, 1.4) < 0.25:
		bg.draw_rect(Rect2(p.x + 4.0, p.y + 10.0, 1.0, 1.0), Color("#ff4030"))
	if fposmod(life + 0.7, 1.4) < 0.25:
		bg.draw_rect(Rect2(p.x + 67.0, p.y + 10.0, 1.0, 1.0), Color("#40ff80"))
	if fposmod(life * 2.0, 1.0) < 0.12:
		bg.draw_rect(Rect2(p.x + 36.0, p.y, 1.0, 1.0), Color("#fff2c0"))
