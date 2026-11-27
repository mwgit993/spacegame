extends "res://scripts/stages/stage_background.gd"

# STORM OCEAN: skimming the surface of a stormy alien sea at night. A heavy slate-indigo cloud
# deck trails grey rain curtains down to the horizon, darker scud races beneath it, and a
# lighthouse on a far rock sweeps its beam through the rain. Below the horizon the sea heaves in
# five bands of swell, from fine far ripples to big near crests capped with foam. Rain slants
# across everything and splashes on the water; spindrift blows off the wave tops.
#
# Layers (paint(), worker thread):
#   "sky"         480x270 at (0,0): storm gradient, horizon glow, the far sea's base colour
#   "clouds_hi"   640x118 at y 20, parallax 0.025: the high cloud deck with rain curtains
#   "clouds_lit"  640x118: the same deck's lit billows (only drawn during a lightning flash)
#   "clouds_lo"   768x40 at y 96, parallax 0.07 (wobbling): dark scud racing below the deck
#   "isles"       1024x16 at y 140, parallax 0.015: far rocks and a headland on the horizon
#   "lighthouse"  28x44: the lighthouse on its rock (its own slow wrap, so it shows most of the time)
#   "sea0".."sea4"  the swell bands (wobbling, heaving), far to near; the water line is ~y 238
# Animation: the sweeping lighthouse beam (and its glare when it points your way), flickers of
# lightning inside the clouds, slanting rain in two depths, splashes, foam sparkle on the crests,
# blinking ship lights on the horizon, spindrift. Rare events: a lightning strike on the sea with a
# low flash that lights the clouds from inside (_ev_a), a rogue wave rearing up on the far sea and
# breaking (_ev_b), and a waterspout twisting down from the clouds and crossing (_ev_c).
# Readability: the sea bands are dark and close in value; foam and sparkle are small or brief.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const HORIZON_Y: float = 150.0
const CLOUD_Y: float = 20.0
const SCUD_Y: float = 96.0
const ISLES_Y: float = 140.0
const LH_PAR: float = 0.02
const LH_SPAN: float = 640.0
# Swell bands: y, height, parallax, wobble amp, wobble band height, heave amp.
const SEA: Array[Vector4] = [Vector4(149.0, 12.0, 0.1, 1.0), Vector4(155.0, 20.0, 0.2, 1.0), Vector4(167.0, 30.0, 0.36, 2.0), Vector4(186.0, 42.0, 0.6, 2.0), Vector4(212.0, 56.0, 0.95, 3.0)]
const SEA_W: Array[int] = [512, 512, 640, 768, 768]
const SEA_BAND: Array[int] = [2, 2, 3, 3, 3]
const SEA_HEAVE: Array[float] = [0.0, 0.5, 1.0, 1.5, 2.0]
const SEA_FREQ: Array[int] = [11, 9, 7, 5, 4]
const SEA_AMP: Array[float] = [1.0, 2.0, 3.5, 6.0, 9.0]
const SEA_CREST: Array[float] = [4.0, 6.0, 9.0, 13.0, 19.0]
const RAIN_FAR: int = 64
const RAIN_NEAR: int = 30
const SPLASHES: int = 10

var _rain: PackedVector2Array = PackedVector2Array()       # far rain then near rain
var _rain_v: PackedFloat32Array = PackedFloat32Array()
var _rain_pts_far: PackedVector2Array = PackedVector2Array()
var _rain_pts_near: PackedVector2Array = PackedVector2Array()
var _spl: PackedVector3Array = PackedVector3Array()         # x, y, age
var _spl_t: float = 0.0
var _flick_t: float = 2.0
var _flick_age: float = 9.0
var _flick_pos: Vector2 = Vector2.ZERO
var _sparkle: PackedVector3Array = PackedVector3Array()     # screen x, y, age
var _sparkle_t: float = 0.1
var _bolt: PackedVector2Array = PackedVector2Array()
var _branch: PackedVector2Array = PackedVector2Array()
var _rogue_x: float = 0.0
var _spout_x: float = 0.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20020
	var out: Dictionary = {}
	out["sky"] = _paint_sky(rng)
	_paint_clouds_hi(out)
	out["clouds_lo"] = _paint_clouds_lo()
	out["isles"] = _paint_isles(rng)
	out["lighthouse"] = _paint_lighthouse()
	var ramps: Array[PackedColorArray] = [
		PackedColorArray([Color("#14232a"), Color("#182a30"), Color("#1d3238"), Color("#24393e")]),
		PackedColorArray([Color("#112026"), Color("#15262c"), Color("#1a2e34"), Color("#22383c")]),
		PackedColorArray([Color("#0e1b20"), Color("#122228"), Color("#172a30"), Color("#203538")]),
		PackedColorArray([Color("#0b161a"), Color("#0f1d22"), Color("#14252a"), Color("#1c3034")]),
		PackedColorArray([Color("#081114"), Color("#0c181c"), Color("#112024"), Color("#182a2e")]),
	]
	var crest_cols: PackedColorArray = PackedColorArray([Color("#2c4448"), Color("#2e464a"), Color("#30484c"), Color("#324c50"), Color("#344e52")])
	var foam_cols: PackedColorArray = PackedColorArray([Color("#3e5658"), Color("#46605f"), Color("#4e6868"), Color("#567070"), Color("#5e7878")])
	for i: int in range(SEA.size()):
		var res: Array = _paint_sea(SEA_W[i], int(SEA[i].y), SEA_CREST[i], SEA_AMP[i], SEA_FREQ[i], 2100 + i * 17, ramps[i], crest_cols[i], foam_cols[i], i)
		out["sea%d" % i] = res[0]
		out["crests%d" % i] = res[1]
	return out


static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#080a14"))
	Painter.vgrad(sky, 18, int(HORIZON_Y) + 1, PackedColorArray([Color("#080a14"), Color("#0a0d18"), Color("#0d111e"), Color("#111725"), Color("#151d2c"), Color("#1b2532"), Color("#202d36")]), 0.5)
	# The glow under the cloud deck along the horizon.
	for y: int in range(int(HORIZON_Y) - 12, int(HORIZON_Y)):
		var k: float = float(y - (int(HORIZON_Y) - 12)) / 12.0
		for x: int in range(480):
			if Painter.bayer(x, y) < k * 0.8:
				Painter.blend_px(sky, x, y, Color("#2a3a42"), 0.5)
	Painter.rect(sky, 0, int(HORIZON_Y), 480, 1, Color("#2e4048"))
	# The far sea (behind the swell bands, seen in gaps).
	Painter.vgrad(sky, int(HORIZON_Y) + 1, 270, PackedColorArray([Color("#182a30"), Color("#13222a"), Color("#0f1c22"), Color("#0c171c"), Color("#091216")]), 0.5)
	for i: int in range(40):
		Painter.px(sky, rng.randi_range(0, 479), rng.randi_range(24, 70), Color("#1a2236"))
	return sky


static func _paint_clouds_hi(out: Dictionary) -> void:
	var w: int = 640
	var h: int = 118
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20031
	# Billows are built upright (flat bases at the bottom, lit tops) and then flipped, so they hang
	# from the overcast with their undersides catching the faint glow from the horizon. A back row
	# of big dark billows and a front row of smaller, lighter ones give the deck depth.
	var back: PackedByteArray = PackedByteArray()
	back.resize(w * h)
	var front: PackedByteArray = PackedByteArray()
	front.resize(w * h)
	var base_y: float = float(h) - 14.0
	var x: float = 0.0
	while x < float(w):
		var wd: float = rng.randf_range(60.0, 120.0)
		Painter.cloud_puff(back, w, h, x, base_y, wd, rng.randf_range(30.0, 50.0), rng, true)
		x += wd * rng.randf_range(0.4, 0.65)
	for y: int in range(int(base_y), h):
		for x2: int in range(w):
			back[y * w + x2] = 1
	x = rng.randf_range(0.0, 30.0)
	while x < float(w):
		var wd2: float = rng.randf_range(36.0, 76.0)
		Painter.cloud_puff(front, w, h, x, base_y - rng.randf_range(8.0, 24.0), wd2, rng.randf_range(16.0, 28.0), rng, false)
		x += wd2 * rng.randf_range(0.7, 1.3)
	var ramp_b: PackedColorArray = PackedColorArray([Color("#080b14"), Color("#0a0e19"), Color("#0d121f"), Color("#111727"), Color("#161d30"), Color("#1c253a")])
	var ramp_f: PackedColorArray = PackedColorArray([Color("#0b0e19"), Color("#0f1422"), Color("#141a2c"), Color("#192136"), Color("#202a42"), Color("#29344e")])
	var img: Image = Painter.new_img(w, h)
	Painter.paint_cloud_mask(img, back, w, h, 0, ramp_b)
	var fimg: Image = Painter.new_img(w, h)
	Painter.paint_cloud_mask(fimg, front, w, h, 0, ramp_f)
	img.flip_y()
	fimg.flip_y()
	img.blend_rect(fimg, Rect2i(0, 0, w, h), Vector2i.ZERO)
	# Mottling in the overcast.
	var mot: PackedByteArray = Painter.fast_field(w, 20, 14.0, 2, 20033)
	for y2: int in range(20):
		for x3: int in range(w):
			var m: float = float(mot[y2 * w + x3]) / 255.0
			if m > 0.62 and Painter.bayer(x3, y2) < (m - 0.62) * 2.5:
				img.set_pixel(x3, y2, ramp_b[2])
	var lit: Image = Painter.new_img(w, h)
	for y3: int in range(h):
		for x4: int in range(w):
			var c: Color = img.get_pixel(x4, y3)
			if c.a <= 0.0:
				continue
			if c == ramp_f[5] or c == ramp_b[5]:
				lit.set_pixel(x4, y3, Color(0.66, 0.68, 1.0, 0.6))
			elif c == ramp_f[4] or c == ramp_b[4]:
				lit.set_pixel(x4, y3, Color(0.62, 0.64, 1.0, 0.35))
			elif c == ramp_f[3] and Painter.bayer(x4, y3) < 0.3:
				lit.set_pixel(x4, y3, Color(0.55, 0.58, 0.95, 0.25))
	# Rain curtains trailing down to the horizon under the heaviest billows.
	var curtains: Array[Vector2] = [Vector2(70.0, 40.0), Vector2(250.0, 58.0), Vector2(420.0, 34.0), Vector2(560.0, 50.0)]
	for cv: Vector2 in curtains:
		for y4: int in range(30, h):
			var fade: float = clampf(float(y4 - 30) / 20.0, 0.0, 1.0) * (1.0 - float(y4 - 30) / float(h - 30) * 0.6)
			for dx: int in range(int(-cv.y), int(cv.y)):
				var x5: int = posmod(int(cv.x) + dx - int(float(y4) * 0.3), w)
				if img.get_pixel(x5, y4).a > 0.0:
					continue
				var across: float = 1.0 - absf(float(dx)) / cv.y
				if (x5 + y4 / 3) % 3 == 0 and Painter.bayer(x5, y4) < across * fade * 0.5:
					img.set_pixel(x5, y4, Color(0.1, 0.13, 0.19, 0.55))
	out["clouds_hi"] = img
	out["clouds_lit"] = lit


# Dark ragged scud racing low under the deck, against the brighter sky near the horizon: noise
# stretched 3x sideways and thresholded around a band, so it tears into long streamers.
static func _paint_clouds_lo() -> Image:
	var w: int = 768
	var h: int = 40
	var nw: int = 256
	var n: PackedByteArray = Painter.fast_field(nw, h, 9.0, 3, 20041)
	var cloud: PackedByteArray = PackedByteArray()
	cloud.resize(w * h)
	for y: int in range(h):
		var band: float = absf(float(y) - 18.0) / 18.0
		var thr: float = 0.6 + 0.34 * band * band
		for x: int in range(w):
			var v: float = float(n[y * nw + (x * nw / w)]) / 255.0
			if v > thr:
				cloud[y * w + x] = 1
	var ramp: PackedColorArray = PackedColorArray([Color("#07080e"), Color("#0a0c15"), Color("#0e111c"), Color("#1a2133"), Color("#283248")])
	var img: Image = Painter.new_img(w, h)
	for y2: int in range(h):
		for x2: int in range(w):
			if cloud[y2 * w + x2] == 0:
				continue
			var under: bool = y2 + 1 >= h or cloud[(y2 + 1) * w + x2] == 0
			var under2: bool = y2 + 2 >= h or cloud[(y2 + 2) * w + x2] == 0
			var top: bool = y2 == 0 or cloud[(y2 - 1) * w + x2] == 0
			var v2: float = 0.3
			if under:
				v2 = 1.0
			elif under2:
				v2 = 0.7
			elif top:
				v2 = 0.0
			img.set_pixel(x2, y2, Painter.ramp_pick(ramp, v2, x2, y2))
	return img


static func _paint_isles(rng: RandomNumberGenerator) -> Image:
	var w: int = 1024
	var h: int = 16
	var img: Image = Painter.new_img(w, h)
	var isles: Array[Vector3] = [Vector3(120.0, 70.0, 7.0), Vector3(470.0, 26.0, 5.0), Vector3(700.0, 140.0, 9.0), Vector3(930.0, 34.0, 4.0)]
	for s: Vector3 in isles:
		var prof: PackedFloat32Array = Painter.profile(64, rng, 3, 2, 0.5)
		for dx: int in range(int(s.y)):
			var u: float = float(dx) / s.y
			var env: float = sin(u * PI)
			var hh: int = int(s.z * pow(env, 0.6) * (0.75 + 0.25 * prof[dx % 64]))
			if hh <= 0:
				continue
			var x: int = int(s.x) + dx
			Painter.rect(img, x, h - hh, 1, hh, Color("#0b1215"))
			Painter.px(img, x, h - hh, Color("#1c2a2e"))
	return img


static func _paint_lighthouse() -> Image:
	var img: Image = Painter.new_img(28, 44)
	# Rock.
	Painter.ellipse(img, 14.0, 42.0, 13.0, 5.0, Color("#0b1215"))
	Painter.ellipse(img, 11.0, 40.0, 7.0, 3.0, Color("#141e22"))
	Painter.px(img, 5, 39, Color("#1e2c30"))
	Painter.px(img, 9, 38, Color("#1e2c30"))
	# Tapered tower with two dull red bands, a gallery, the lamp room and a dome.
	for y: int in range(12, 39):
		var u: float = float(y - 12) / 27.0
		var hw: int = int(2.0 + u * 2.0)
		var band: bool = (y >= 18 and y < 22) or (y >= 28 and y < 32)
		var c: Color = Color("#3a2226") if band else Color("#3e464e")
		Painter.rect(img, 14 - hw, y, hw * 2 + 1, 1, c)
		Painter.px(img, 14 - hw, y, Color("#5a646c") if not band else Color("#5a3238"))
		Painter.px(img, 14 + hw, y, Color("#262c32"))
	Painter.px(img, 14, 26, Color("#ffd25a"))
	Painter.px(img, 14, 34, Color("#c8a040"))
	Painter.rect(img, 10, 11, 9, 1, Color("#2a3034"))
	Painter.rect(img, 11, 7, 7, 4, Color("#1c1e1a"))
	Painter.rect(img, 12, 8, 5, 2, Color("#ffe27a"))
	Painter.rect(img, 13, 8, 3, 2, Color("#fff8d0"))
	Painter.rect(img, 11, 6, 7, 1, Color("#3a2226"))
	Painter.rect(img, 12, 5, 5, 1, Color("#3a2226"))
	Painter.px(img, 14, 4, Color("#4a2a2e"))
	return img


# One swell band: a periodic crest line with chop, a lit strip under the crest fading into the
# dark body, sparse wind streaks on the faces and foam caps on the tallest crests (bigger on the
# near bands). Returns [Image, crest points].
static func _paint_sea(w: int, h: int, crest_base: float, amp: float, freq: int, seed_v: int, ramp: PackedColorArray, crest_col: Color, foam_col: Color, idx: int) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_v
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 4, freq, 0.45)
	var chop: PackedFloat32Array = Painter.profile(w, rng, 3, freq * 5, 0.6)
	var crest: PackedFloat32Array = PackedFloat32Array()
	crest.resize(w)
	for x: int in range(w):
		crest[x] = crest_base + (0.5 - prof[x]) * 2.0 * amp + (0.5 - chop[x]) * (1.0 + float(idx) * 0.4)
	var points: PackedVector2Array = PackedVector2Array()
	var lit_h: float = 2.0 + float(idx) * 1.2
	for x2: int in range(w):
		var c: int = int(crest[x2])
		var slope: float = crest[(x2 + 1) % w] - crest[posmod(x2 - 1, w)]
		var face: float = clampf(0.6 - slope * 0.5, 0.25, 1.0)   # faces tilted toward the horizon glow catch it
		for y: int in range(maxi(0, c), h):
			var depth: float = float(y - c)
			var v: float = 0.0
			if depth < lit_h:
				v = (0.95 - depth / lit_h * 0.55) * face
			else:
				v = clampf(0.38 - (depth - lit_h) / (10.0 + float(idx) * 4.0), 0.0, 0.38)
			img.set_pixel(x2, y, Painter.ramp_pick(ramp, v, x2, y))
		if c >= 0 and c < h:
			img.set_pixel(x2, c, crest_col if face > 0.5 else ramp[2])
		# Foam caps on the tallest crests, spilling down the face.
		if prof[x2] > 0.62:
			var amount: float = (prof[x2] - 0.62) / 0.38
			var thick: int = int(1.0 + amount * (1.0 + float(idx) * 1.2))
			for k: int in range(thick + 2):
				var fy: int = c + k - 1
				var keep: float = amount * 1.5 * (1.0 - float(k) / float(thick + 2))
				if fy >= 0 and fy < h and (keep > 0.55 or (keep > 0.2 and (x2 + fy * 2) % 3 == 0)):
					img.set_pixel(x2, fy, foam_col if k < thick else ramp[3])
			if (x2 % 4) == 0:
				points.append(Vector2(float(x2), float(c)))
	# Sparse wind streaks on the wave faces.
	for s: int in range(w / (10 - idx)):
		var sx: int = rng.randi_range(0, w - 1)
		var sy: int = int(crest[sx]) + rng.randi_range(int(lit_h) + 1, int(lit_h) + 3 + idx * 3)
		if sy < h:
			Painter.span(img, sx, sx + rng.randi_range(3, 6 + idx * 3), sy, ramp[2])
	return [img, points]


# --- Animation -------------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 196.0
	drift_a.y1 = 252.0
	drift_a.setup(24, rng, -70.0, -30.0, -6.0, 2.0)
	drift_a.par = 0.9
	drift_a.sway = 2.0
	drift_a.sway_hz = 1.3
	drift_a.cols = PackedColorArray([Color(0.7, 0.88, 0.9, 0.3), Color(0.55, 0.75, 0.8, 0.35)])
	drift_b.clear()
	_rain.resize(RAIN_FAR + RAIN_NEAR)
	_rain_v.resize(RAIN_FAR + RAIN_NEAR)
	for i: int in range(RAIN_FAR + RAIN_NEAR):
		_rain[i] = Vector2(rng.randf_range(0.0, 520.0), rng.randf_range(20.0, 258.0))
		_rain_v[i] = rng.randf_range(260.0, 330.0) if i < RAIN_FAR else rng.randf_range(380.0, 460.0)
	_rain_pts_far.resize(RAIN_FAR * 2)
	_rain_pts_near.resize(RAIN_NEAR * 2)
	_spl.resize(0)
	_sparkle.resize(0)
	_flick_t = rng.randf_range(1.0, 3.0)
	_flick_age = 9.0
	bg._ev_a.arm(rng, 9.0, 15.0, 3.0, 6.0)     # lightning strike
	bg._ev_b.arm(rng, 18.0, 28.0, 9.0, 13.0)   # rogue wave
	bg._ev_c.arm(rng, 22.0, 32.0, 15.0, 20.0)  # waterspout


func update() -> void:
	# Rain: far drops fall slower and slant less than near ones; both wrap.
	for i: int in range(_rain.size()):
		var near: bool = i >= RAIN_FAR
		var vy: float = _rain_v[i]
		var p: Vector2 = _rain[i]
		p.y += vy * dl
		p.x -= vy * (0.34 if near else 0.26) * dl + ds * (0.9 if near else 0.4)
		if p.y > (262.0 if near else 252.0) or p.x < -12.0:
			if near and _spl.size() < SPLASHES and p.y > 200.0:
				_spl.append(Vector3(p.x, rng.randf_range(206.0, 252.0), 0.0))
			p = Vector2(rng.randf_range(0.0, 540.0), rng.randf_range(4.0, 40.0))
		_rain[i] = p
		var ln: float = 8.0 if near else 4.0
		var tail: Vector2 = p - Vector2(-(0.34 if near else 0.26), 1.0) * ln
		if near:
			var j: int = (i - RAIN_FAR) * 2
			_rain_pts_near[j] = p.floor()
			_rain_pts_near[j + 1] = tail.floor()
		else:
			_rain_pts_far[i * 2] = p.floor()
			_rain_pts_far[i * 2 + 1] = tail.floor()
	# Splashes where drops hit the sea (plus a few far ones).
	_spl_t -= dl
	if _spl_t <= 0.0:
		_spl_t = rng.randf_range(0.03, 0.08)
		if _spl.size() < SPLASHES:
			_spl.append(Vector3(rng.randf_range(0.0, 480.0), rng.randf_range(158.0, 250.0), 0.0))
	var k: int = 0
	while k < _spl.size():
		var s: Vector3 = _spl[k]
		s.z += dl
		s.x -= ds * (0.3 + 0.65 * clampf((s.y - 150.0) / 100.0, 0.0, 1.0))
		if s.z > 0.22:
			_spl.remove_at(k)
			continue
		_spl[k] = s
		k += 1
	# Foam sparkle on the near crests.
	_sparkle_t -= dl
	if _sparkle_t <= 0.0:
		_sparkle_t = rng.randf_range(0.05, 0.14)
		var band: int = 2 + rng.randi_range(0, 2)
		var pts: PackedVector2Array = meta.get("crests%d" % band, PackedVector2Array())
		if not pts.is_empty() and _sparkle.size() < 12:
			var o: float = off(SEA[band].z, float(SEA_W[band]))
			var cp: Vector2 = pts[rng.randi_range(0, pts.size() - 1)]
			var sx: float = wrap_x(cp.x, o, float(SEA_W[band]))
			if sx > 0.0 and sx < 480.0:
				_sparkle.append(Vector3(sx, SEA[band].x + cp.y, 0.0))
	var m: int = 0
	while m < _sparkle.size():
		var sp: Vector3 = _sparkle[m]
		sp.z += dl
		sp.x -= ds * 0.6
		if sp.z > 0.35:
			_sparkle.remove_at(m)
			continue
		_sparkle[m] = sp
		m += 1
	# Flickers of lightning inside the clouds.
	_flick_age += dl
	_flick_t -= dl
	if _flick_t <= 0.0:
		_flick_t = rng.randf_range(1.6, 4.2)
		_flick_age = 0.0
		_flick_pos = Vector2(rng.randf_range(20.0, 460.0), rng.randf_range(34.0, 96.0))
	# Event A: a lightning strike on the sea.
	if bg._ev_a.tick(dl, rng):
		bg._ev_a.dur = 0.75
		var x0: float = rng.randf_range(60.0, 420.0)
		_bolt = _jagged(Vector2(x0, 58.0 + rng.randf_range(0.0, 20.0)), Vector2(x0 + rng.randf_range(-30.0, 30.0), HORIZON_Y + 3.0), 9, 7.0)
		var mid: Vector2 = _bolt[rng.randi_range(2, 5)]
		_branch = _jagged(mid, mid + Vector2(rng.randf_range(-40.0, 40.0), rng.randf_range(18.0, 34.0)), 4, 4.0)
	# Event B: a rogue wave rearing up on the far sea.
	if bg._ev_b.tick(dl, rng):
		bg._ev_b.dur = 9.0
		_rogue_x = 560.0
	if bg._ev_b.on:
		_rogue_x -= 36.0 * dl + ds * 0.12
	# Event C: a waterspout crossing the middle distance.
	if bg._ev_c.tick(dl, rng):
		bg._ev_c.dur = 16.0
		_spout_x = 540.0
	if bg._ev_c.on:
		_spout_x -= 22.0 * dl + ds * 0.2


func _jagged(a: Vector2, b: Vector2, segs: int, jit: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(segs + 1):
		var t: float = float(i) / float(segs)
		var p: Vector2 = a.lerp(b, t)
		if i > 0 and i < segs:
			p.x += rng.randf_range(-jit, jit)
		pts.append(p.floor())
	return pts


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	# Lightning flickering inside the cloud deck (behind it, so only the gaps glow).
	if _flick_age < 0.3:
		var fa: float = (1.0 - _flick_age / 0.3) * (0.6 + 0.4 * sin(_flick_age * 70.0))
		bg.draw_circle(_flick_pos, 26.0, Color(0.55, 0.55, 0.95, 0.07 * fa))
		bg.draw_circle(_flick_pos, 12.0, Color(0.75, 0.75, 1.0, 0.08 * fa))
	layer("clouds_hi", CLOUD_Y, 0.025)
	var flash: float = _flash()
	if _flick_age < 0.25:
		var fb: float = (1.0 - _flick_age / 0.25) * (0.5 + 0.5 * sin(_flick_age * 60.0))
		var cl: Color = Color(1.0, 1.0, 1.0, 0.18 * fb)
		var o_hi: float = off(0.025, 640.0)
		var lx: float = clampf(fposmod(_flick_pos.x + o_hi, 640.0) - 40.0, 0.0, 560.0)
		bg.draw_texture_rect_region(tex("clouds_lit"), Rect2(_flick_pos.x - 40.0, CLOUD_Y, 80.0, 100.0), Rect2(lx, 0.0, 80.0, 100.0), cl)
	if flash > 0.0:
		bg.draw_rect(Rect2(0.0, 20.0, 480.0, HORIZON_Y - 20.0), Color(0.55, 0.6, 1.0, 0.05 * flash))
		layer("clouds_lit", CLOUD_Y, 0.025, Color(1.0, 1.0, 1.0, 0.7 * flash))
		_draw_bolt(flash)
	layer_wobble("clouds_lo", SCUD_Y, 0.07, 5, 1.0, 0.35, 0.6)
	# Horizon: far rocks, ship lights, the lighthouse and its beam.
	layer("isles", ISLES_Y, 0.015)
	_draw_ships()
	_draw_lighthouse()
	# The sea, far to near, with the rogue wave and the waterspout between the bands.
	for i: int in range(SEA.size()):
		var sv: Vector4 = SEA[i]
		var heave: float = roundf(sin(life * 0.85 + float(i) * 0.9) * SEA_HEAVE[i])
		layer_wobble("sea%d" % i, sv.x + heave, sv.z, SEA_BAND[i], sv.w, 0.5 + float(i) * 0.08, 0.9 + float(i) * 0.15)
		if i == 0:
			if flash > 0.0:
				_draw_reflection(flash)
			if bg._ev_b.on:
				_draw_rogue()
		elif i == 1 and bg._ev_c.on:
			_draw_spout()
	for s: int in range(_sparkle.size()):
		var sp: Vector3 = _sparkle[s]
		var a: float = sin(sp.z / 0.35 * PI)
		bg.draw_rect(Rect2(floorf(sp.x), floorf(sp.y) - 1.0, 1.0, 1.0), Color(0.85, 0.97, 1.0, 0.75 * a))
		if a > 0.7:
			bg.draw_rect(Rect2(floorf(sp.x) - 1.0, floorf(sp.y) - 1.0, 3.0, 1.0), Color(0.75, 0.92, 0.95, 0.35))
	for q: int in range(_spl.size()):
		var sq: Vector3 = _spl[q]
		var u: float = sq.z / 0.22
		var px: float = floorf(sq.x)
		var py: float = floorf(sq.y)
		var sc: Color = Color(0.75, 0.9, 0.95, 0.55 * (1.0 - u))
		bg.draw_rect(Rect2(px - 1.0 - floorf(u * 2.0), py - floorf(u * 3.0), 1.0, 1.0), sc)
		bg.draw_rect(Rect2(px + 1.0 + floorf(u * 2.0), py - floorf(u * 3.0), 1.0, 1.0), sc)
		bg.draw_rect(Rect2(px - 1.0, py, 3.0, 1.0), Color(sc.r, sc.g, sc.b, sc.a * 0.6))
	bg.draw_multiline(_rain_pts_far, Color(0.42, 0.5, 0.68, 0.28), 1.0)
	drift_draw(drift_a)
	bg.draw_multiline(_rain_pts_near, Color(0.6, 0.7, 0.86, 0.32), 1.0)


# Lightning strike brightness (two quick strokes, then a fade).
func _flash() -> float:
	if not bg._ev_a.on:
		return 0.0
	var t: float = bg._ev_a.t
	if t < 0.07:
		return 1.0
	if t < 0.13:
		return 0.15
	if t < 0.24:
		return 0.9
	return maxf(0.0, 1.0 - (t - 0.24) / 0.5) * 0.6


func _draw_bolt(flash: float) -> void:
	if _bolt.size() < 2:
		return
	bg.draw_polyline(_bolt, Color(0.6, 0.62, 1.0, 0.3 * flash), 3.0)
	bg.draw_polyline(_bolt, Color(0.96, 0.96, 1.0, 0.95 * flash), 1.0)
	if _branch.size() >= 2:
		bg.draw_polyline(_branch, Color(0.85, 0.86, 1.0, 0.6 * flash), 1.0)
	var end: Vector2 = _bolt[_bolt.size() - 1]
	bg.draw_circle(end, 5.0, Color(0.8, 0.85, 1.0, 0.35 * flash))


# The strike's shimmering reflection on the far sea.
func _draw_reflection(flash: float) -> void:
	if _bolt.size() < 2:
		return
	var end: Vector2 = _bolt[_bolt.size() - 1]
	for i: int in range(9):
		var y: float = end.y + 2.0 + float(i) * 3.0
		var wv: float = 2.0 + float(i) * 0.8
		var jx: float = sin(life * 30.0 + float(i) * 1.7) * 2.0
		bg.draw_rect(Rect2(floorf(end.x - wv * 0.5 + jx), y, floorf(wv), 1.0), Color(0.75, 0.8, 1.0, 0.4 * flash * (1.0 - float(i) / 9.0)))


func _draw_lighthouse() -> void:
	var lx: float = 470.0 - fposmod(scroll * LH_PAR + 120.0, LH_SPAN)
	var lt: Texture2D = tex("lighthouse")
	var top_left: Vector2 = Vector2(floorf(lx) - 14.0, HORIZON_Y + 3.0 - 44.0)
	var lamp: Vector2 = top_left + Vector2(14.5, 9.0)
	# The beam: a rotating light seen from the side, so its cone swings left and right through the
	# rain, shortening as it turns toward or away from you, with a glare when it faces you.
	var th: float = life * TAU / 7.0
	var cx: float = cos(th)
	var toward: float = sin(th)
	var length: float = 30.0 + 300.0 * absf(cx)
	var dir: Vector2 = Vector2(signf(cx) if cx != 0.0 else 1.0, -0.06).normalized()
	var half: float = 0.035 + 0.05 * maxf(0.0, toward)
	var a0: float = 0.12 + 0.08 * maxf(0.0, toward)
	var p1: Vector2 = lamp + dir.rotated(-half) * length
	var p2: Vector2 = lamp + dir.rotated(half) * length
	var cn: Color = Color(1.0, 0.86, 0.45, a0)
	var cf: Color = Color(1.0, 0.86, 0.45, 0.0)
	if lx > -340.0 and lx < 820.0:
		bg.draw_primitive(PackedVector2Array([lamp, p1, p2]), PackedColorArray([cn, cf, cf]), PackedVector2Array())
	if lx < -20.0 or lx > 500.0:
		return
	bg.draw_texture(lt, top_left)
	var glare: float = maxf(0.0, toward) ** 6
	bg.draw_circle(lamp, 2.0 + 4.0 * glare, Color(1.0, 0.9, 0.55, 0.25 + 0.4 * glare))
	if glare > 0.3:
		bg.draw_rect(Rect2(lamp.x - 10.0 * glare, lamp.y, 20.0 * glare + 1.0, 1.0), Color(1.0, 0.92, 0.6, 0.5 * glare))
		bg.draw_rect(Rect2(lamp.x, lamp.y - 5.0 * glare, 1.0, 10.0 * glare + 1.0), Color(1.0, 0.92, 0.6, 0.35 * glare))
	# Its flicker on the water below.
	for i: int in range(4):
		var y: float = HORIZON_Y + 4.0 + float(i) * 3.0
		var wv: float = 1.0 + float(i) + 2.0 * glare
		bg.draw_rect(Rect2(floorf(lamp.x - wv * 0.5 + sin(life * 5.0 + float(i)) * 1.5), y, floorf(wv), 1.0), Color(1.0, 0.85, 0.45, (0.2 + 0.25 * glare) * (1.0 - float(i) * 0.22)))


# Two freighters far out on the horizon: dark hulls and blinking running lights.
func _draw_ships() -> void:
	for i: int in range(2):
		var x: float = 500.0 - fposmod(scroll * 0.012 + life * (2.0 + float(i)) + float(i) * 260.0, 560.0)
		if x < -10.0 or x > 490.0:
			continue
		var y: float = HORIZON_Y - 1.0 + float(i)
		bg.draw_rect(Rect2(floorf(x), y, 7.0, 1.0), Color("#0b1215"))
		bg.draw_rect(Rect2(floorf(x) + 4.0, y - 1.0, 2.0, 1.0), Color("#0b1215"))
		if fposmod(life * 0.8 + float(i) * 0.5, 1.0) < 0.55:
			bg.draw_rect(Rect2(floorf(x), y - 1.0, 1.0, 1.0), Color("#ff5a4a"))
		bg.draw_rect(Rect2(floorf(x) + 6.0, y - 1.0, 1.0, 1.0), Color("#7aff9a") if i == 0 else Color("#ffe27a"))


# A rogue wave: a long swell that rears up on the far sea, its face steepening and catching the
# horizon glow, then curls over and breaks in a plume of spray.
func _draw_rogue() -> void:
	var u: float = bg._ev_b.t / bg._ev_b.dur
	var hgt: float = 22.0 * sin(clampf(u * 1.5, 0.0, 1.0) * PI * 0.5) * (1.0 - clampf((u - 0.75) / 0.25, 0.0, 1.0))
	if hgt < 0.5:
		return
	var base_y: float = HORIZON_Y + 12.0
	var w: float = 170.0
	var x0: float = _rogue_x - w * 0.5
	var steep: float = clampf(u * 1.8, 0.0, 1.0)
	var top: PackedVector2Array = PackedVector2Array()
	for i: int in range(21):
		var t: float = float(i) / 20.0
		# A long gentle back on the right, a steep face on the left that gets steeper.
		var peak: float = lerpf(0.5, 0.3, steep)
		var bump: float = 0.0
		if t < peak:
			bump = pow(sin(t / peak * PI * 0.5), lerpf(1.5, 3.0, steep))
		else:
			bump = pow(cos((t - peak) / (1.0 - peak) * PI * 0.5), 1.3)
		top.append(Vector2(x0 + t * w, base_y - hgt * bump))
	var body: PackedVector2Array = top.duplicate()
	body.append(Vector2(x0 + w, base_y + 3.0))
	body.append(Vector2(x0, base_y + 3.0))
	bg.draw_colored_polygon(body, Color("#102024"))
	# The lit face: a band just under the crest line on the steep side.
	var pk: int = int(lerpf(0.5, 0.3, steep) * 20.0)
	for i2: int in range(20):
		var a: Vector2 = top[i2].floor()
		var b: Vector2 = top[i2 + 1].floor()
		bg.draw_line(a, b, Color("#2e484c") if i2 < pk + 2 else Color("#223a3e"), 1.0)
		if i2 < pk:
			bg.draw_line(a + Vector2(1.0, 2.0), b + Vector2(1.0, 2.0), Color("#1a3034"), 1.0)
	var crest: Vector2 = top[pk].floor()
	# Streaks running down the face.
	for s: int in range(5):
		var sx: float = crest.x - 6.0 - float(s) * 7.0 * (0.5 + steep * 0.5)
		if sx > x0 + 4.0:
			bg.draw_rect(Rect2(floorf(sx), floorf(base_y - hgt * 0.4 + float(s % 2) * 3.0), 3.0, 1.0), Color("#1c3236"))
	if u > 0.48:
		# Breaking: the lip throws forward and a plume of spray bursts.
		var br: float = clampf((u - 0.48) / 0.3, 0.0, 1.0)
		for f: int in range(16):
			var ft: float = fposmod(float(f) * 0.137 + br * 0.6, 1.0)
			var fx: float = crest.x - 4.0 - ft * 34.0 * (0.5 + br)
			var fy: float = crest.y - 3.0 - sin(ft * PI) * (8.0 + 6.0 * br) + float(f % 3)
			bg.draw_rect(Rect2(floorf(fx), floorf(fy), 1.0 + float(f % 2), 1.0), Color(0.72, 0.86, 0.88, 0.6 * (1.0 - ft * 0.6) * (1.0 - br * 0.4)))
		bg.draw_rect(Rect2(crest.x - 14.0 * br, crest.y - 1.0, 14.0 * br + 4.0, 1.0), Color(0.7, 0.84, 0.86, 0.5))
	else:
		bg.draw_rect(Rect2(crest.x - 4.0, crest.y, 9.0, 1.0), Color(0.55, 0.72, 0.74, 0.45))


# A waterspout: a twisting grey funnel hanging from a lowered lump of cloud down to a skirt of
# spray on the sea, with bands of spray spiralling up it.
func _draw_spout() -> void:
	var u: float = bg._ev_c.t / bg._ev_c.dur
	var vis: float = clampf(u * 5.0, 0.0, 1.0) * clampf((1.0 - u) * 5.0, 0.0, 1.0)
	if vis <= 0.0 or _spout_x < -40.0 or _spout_x > 520.0:
		return
	var top_y: float = 84.0
	var bot_y: float = HORIZON_Y + 22.0
	# The wall cloud it hangs from.
	bg.draw_rect(Rect2(floorf(_spout_x - 22.0), top_y - 8.0, 44.0, 6.0), Color(0.07, 0.08, 0.12, 0.8 * vis))
	bg.draw_rect(Rect2(floorf(_spout_x - 14.0), top_y - 3.0, 28.0, 4.0), Color(0.07, 0.08, 0.12, 0.8 * vis))
	var rows: int = int((bot_y - top_y) / 2.0)
	for i: int in range(rows):
		var t: float = float(i) / float(rows - 1)
		var y: float = top_y + float(i) * 2.0
		var wdt: float = lerpf(12.0, 2.0, pow(t, 0.45)) + 6.0 * pow(t, 10.0)
		var x: float = _spout_x + sin(life * 1.1 + t * 3.2) * 8.0 * t
		var lx: float = floorf(x - wdt * 0.5)
		bg.draw_rect(Rect2(lx, y, floorf(wdt) + 1.0, 2.0), Color(0.3, 0.35, 0.42, 0.28 * vis))
		bg.draw_rect(Rect2(lx + floorf(wdt), y, 1.0, 2.0), Color(0.55, 0.62, 0.7, 0.3 * vis))
		var ph: float = fposmod(t * 6.0 - life * 2.2, 1.0)
		if ph < 0.25:
			bg.draw_rect(Rect2(lx + floorf(ph * 4.0 * wdt), y, 1.0, 2.0), Color(0.7, 0.76, 0.84, 0.35 * vis))
	var bx: float = _spout_x + sin(life * 1.1 + 3.2) * 8.0
	for s: int in range(16):
		var t2: float = fposmod(life * 1.3 + float(s) * 0.0625, 1.0)
		var ang: float = float(s) * 2.4
		var r: float = 3.0 + t2 * 14.0
		bg.draw_rect(Rect2(floorf(bx + cos(ang) * r), floorf(bot_y - t2 * 8.0 + sin(ang) * r * 0.25), 1.0, 1.0), Color(0.75, 0.85, 0.9, 0.55 * vis * (1.0 - t2)))
