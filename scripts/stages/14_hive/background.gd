extends "res://scripts/stages/stage_background.gd"

# STAGE 14 background: inside the brood nest. Far back, a honeycomb wall whose capped cells hold
# softly glowing eggs; resin pillars at mid depth; amber resin drapes dripping from the ceiling;
# fleshy mounds and pulsing larva sacs on the floor. Rare events: a wave of light rolls through
# the comb, a giant worker crawls across the far wall, a swarm streams past in the distance.
#
# Layers (texture size, screen y, parallax): "sky" 480x270 at 0; "comb" 512x224 at 30 (0.07);
# "pillars" 640x232 at 28 (0.28); "drape" 512x48 at 28 and "mounds" 512x60 at 200 (0.5);
# "near" 640x30 at 232 and "near_top" 640x22 at 28 (0.9); "worker" 2 frames of 104x40.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const COMB_Y: float = 30.0
const COMB_F: float = 0.07
const PILLAR_Y: float = 28.0
const PILLAR_F: float = 0.28
const DRAPE_Y: float = 28.0
const MOUND_Y: float = 200.0
const MID_F: float = 0.5
const NEAR_Y: float = 232.0
const NEAR_TOP_Y: float = 28.0
const NEAR_F: float = 0.9

var _drip_t: float = 0.3
var _pulse_x: float = -1.0
var _pulse_wait: float = 6.0
var _worker_x: float = -1.0
var _worker_y: float = 120.0
var _worker_wait: float = 9.0
var _swarm_x: float = -1.0
var _swarm_y: float = 80.0
var _swarm_wait: float = 4.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1414
	var out: Dictionary = {}

	# Sky: deep umber with a faint warm glow from the chamber's heart.
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#0b0604"))
	Painter.vgrad(sky, 22, 258, PackedColorArray([Color("#0b0604"), Color("#0f0805"), Color("#140b06"), Color("#180e07"), Color("#140b06"), Color("#0e0805")]), 0.5)
	var glow: PackedColorArray = PackedColorArray([Color("#140b06"), Color("#1a0f07"), Color("#211308"), Color("#28170a")])
	for y: int in range(40, 240):
		for x: int in range(120, 420):
			var d: float = Vector2((float(x) - 270.0) / 150.0, (float(y) - 140.0) / 100.0).length()
			if d < 1.0:
				sky.set_pixel(x, y, Painter.ramp_pick(glow, (1.0 - d) * 0.9, x, y))
	out["sky"] = sky

	_paint_comb(out, rng)
	_paint_pillars(out, rng)
	_paint_drape(out, rng)
	_paint_mounds(out, rng)
	_paint_near(out, rng)
	_paint_worker(out)
	return out


# Honeycomb: pointy-top hexagons 16 px wide on 12 px rows (32 columns tile the 512 px width).
static func _paint_comb(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 512
	var h: int = 224
	var img: Image = Painter.new_img(w, h)
	img.fill(Color("#1d1209"))
	var tone: PackedByteArray = Painter.fast_field(w, h, 70.0, 2, 1414)
	var eggs: PackedVector2Array = PackedVector2Array()
	var outer: PackedVector2Array = PackedVector2Array([Vector2(0, -8), Vector2(8, -4), Vector2(8, 4), Vector2(0, 8), Vector2(-8, 4), Vector2(-8, -4)])
	for r: int in range(-1, 20):
		var cy: float = float(r * 12 + 4)
		for c: int in range(32):
			var cx: float = float(c * 16 + (8 if r % 2 != 0 else 0))
			var shade: float = float(tone[clampi(int(cy), 0, h - 1) * w + posmod(int(cx), w)]) / 255.0
			var roll: float = rng.randf()
			var inner: PackedVector2Array = PackedVector2Array()
			for v: Vector2 in outer:
				inner.append(Vector2(cx, cy) + v * 0.74)
			var interior: Color = Color("#140b05") if shade > 0.45 else Color("#100804")
			if roll < 0.2:
				interior = Color("#24150a") if shade > 0.5 else Color("#1f1209")
			elif roll < 0.25:
				interior = Color("#070302")
			Painter.poly(img, inner, interior)
			# rim: lit upper-left walls, shadowed lower-right walls
			var p: PackedVector2Array = PackedVector2Array()
			for v2: Vector2 in outer:
				p.append(Vector2(cx, cy) + v2)
			Painter.line(img, int(p[4].x), int(p[4].y), int(p[5].x), int(p[5].y), Color("#2c1b0c"))
			Painter.line(img, int(p[5].x), int(p[5].y), int(p[0].x), int(p[0].y), Color("#2c1b0c"))
			Painter.line(img, int(p[1].x), int(p[1].y), int(p[2].x), int(p[2].y), Color("#120a05"))
			Painter.line(img, int(p[2].x), int(p[2].y), int(p[3].x), int(p[3].y), Color("#120a05"))
			if roll < 0.2:
				# capped cell: wax lid with a soft highlight
				Painter.line(img, int(cx - 3.0), int(cy - 2.0), int(cx + 1.0), int(cy - 4.0), Color("#33200e"))
				if roll < 0.075 and cy > 6.0 and cy < float(h - 6):
					Painter.ellipse(img, cx, cy + 0.5, 3.0, 3.6, Color("#252c14"))
					Painter.px(img, int(cx) - 1, int(cy) - 1, Color("#3a4620"))
					eggs.append(Vector2(cx, cy))
			else:
				# open cell: shadow inside the top-left rim
				Painter.line(img, int(inner[5].x), int(inner[5].y) + 1, int(inner[0].x), int(inner[0].y) + 1, Color("#0b0603"))
	# two brood chambers: round openings with a thick resin lip, deep and dark inside
	for k: int in range(2):
		var hx: float = 110.0 + float(k) * 256.0 + rng.randf_range(-30.0, 30.0)
		var hy: float = rng.randf_range(80.0, 140.0)
		var hr: float = rng.randf_range(15.0, 20.0)
		var ph: float = rng.randf_range(0.0, TAU)
		for y: int in range(int(hy - hr * 1.5), int(hy + hr * 1.5)):
			for x: int in range(int(hx - hr * 1.9), int(hx + hr * 1.9)):
				var dx: float = (float(x) + 0.5 - hx) / (hr * 1.45)
				var dy: float = (float(y) + 0.5 - hy) / (hr * 1.15)
				var ang: float = atan2(dy, dx)
				var edge: float = 1.0 + 0.06 * sin(ang * 3.0 + ph) + 0.04 * sin(ang * 5.0 - ph)
				var d: float = sqrt(dx * dx + dy * dy) / edge
				if d < 0.78:
					# the inside falls away: darker toward the far (lower right) wall
					var depth: float = clampf(0.5 + dx * 0.4 + dy * 0.5, 0.0, 1.0)
					var c: Color = Color("#070402") if Painter.bayer(x, y) < depth else Color("#0d0704")
					if d > 0.66 and dy > 0.1:
						c = Color("#1a0f06")
					Painter.px(img, x, y, c)
				elif d < 1.0:
					var lit: float = -(dx * 0.6 + dy * 0.8)
					var c2: Color = Color("#2a190b")
					if lit > 0.35:
						c2 = Color("#4a2c10") if d < 0.92 else Color("#3a2410")
					elif lit < -0.35:
						c2 = Color("#0f0804")
					Painter.px(img, x, y, c2)
	# soft dithered fade into the sky at the top and bottom edges
	for y2: int in range(h):
		var e: float = minf(float(y2) / 14.0, float(h - 1 - y2) / 14.0)
		if e >= 1.0:
			continue
		for x2: int in range(w):
			if Painter.bayer(x2, y2) > e:
				img.set_pixel(x2, y2, Color(0, 0, 0, 0))
	out["comb"] = img
	out["comb_eggs"] = eggs


# Resin pillars joining ceiling and floor: dark, amber rim light on the left.
static func _paint_pillars(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 640
	var h: int = 232
	var img: Image = Painter.new_img(w, h)
	var eggs: PackedVector2Array = PackedVector2Array()
	var xs: Array[float] = [70.0, 250.0, 395.0, 560.0]
	for i: int in range(xs.size()):
		var px0: float = xs[i] + rng.randf_range(-15.0, 15.0)
		var bw: float = rng.randf_range(7.0, 12.0)
		var ph: float = rng.randf_range(0.0, TAU)
		for y: int in range(h):
			var flare: float = maxf(0.0, 1.0 - float(y) / 40.0) * 16.0 + maxf(0.0, 1.0 - float(h - y) / 46.0) * 20.0
			var hw: float = bw + sin(float(y) * 0.06 + ph) * 2.5 + sin(float(y) * 0.17 + ph * 2.0) * 1.2 + flare
			var cx: float = px0 + sin(float(y) * 0.025 + ph) * 6.0
			var x0: int = int(cx - hw)
			var x1: int = int(cx + hw)
			Painter.span(img, x0, x1, y, Color("#160c05"))
			Painter.span(img, x0, x0 + 1, y, Color("#3c230b") if (y + i) % 9 != 0 else Color("#4e2e10"))
			Painter.px(img, x0 + 2, y, Color("#22130a"))
			Painter.span(img, x1 - 2, x1, y, Color("#0b0603"))
			# resin streaks running down the face
			if int(float(y) * 0.5 + float(i) * 7.0) % 23 == 0:
				Painter.px(img, int(cx - hw * 0.3), y, Color("#2a1708"))
		for k: int in range(3):
			var ey: float = rng.randf_range(50.0, 190.0)
			var ex: float = px0 + sin(ey * 0.025 + ph) * 6.0 + rng.randf_range(-3.0, 3.0)
			Painter.ellipse(img, ex, ey, 3.0, 3.8, Color("#0a0603"))
			Painter.ellipse(img, ex, ey, 2.0, 2.8, Color("#232c12"))
			eggs.append(Vector2(ex, ey))
	out["pillars"] = img
	out["pillar_eggs"] = eggs


# Ceiling: glossy amber resin drapes and stalactites; the tips drip.
static func _paint_drape(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 512
	var h: int = 48
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 6, 0.6)
	var tips: PackedVector2Array = PackedVector2Array()
	var len_arr: PackedFloat32Array = PackedFloat32Array()
	len_arr.resize(w)
	for x: int in range(w):
		len_arr[x] = 4.0 + prof[x] * 13.0
	# a few long stalactites
	for s: int in range(14):
		var sx: int = rng.randi_range(0, w - 1)
		var sl: float = rng.randf_range(20.0, 42.0)
		var sw: int = rng.randi_range(3, 6)
		for dx: int in range(-sw, sw + 1):
			var k: float = 1.0 - float(absi(dx)) / float(sw + 1)
			var xx: int = posmod(sx + dx, w)
			len_arr[xx] = maxf(len_arr[xx], sl * k * k + 6.0)
		tips.append(Vector2(float(sx), sl + 5.0))
	for x2: int in range(w):
		var l: int = int(len_arr[x2])
		var lit: bool = len_arr[posmod(x2 - 1, w)] < len_arr[x2] - 0.4
		var dark: bool = len_arr[(x2 + 1) % w] < len_arr[x2] - 0.4
		for y: int in range(l):
			var c: Color = Color("#3e230b")
			if lit:
				c = Color("#8a5418")
			elif dark:
				c = Color("#1c0f05")
			elif y > l - 3:
				c = Color("#2a1708")
			elif (x2 * 3 + y) % 17 == 0:
				c = Color("#5a3510")
			img.set_pixel(x2, y, c)
		if l > 2 and not dark:
			img.set_pixel(x2, l - 1, Color("#c07a22") if lit else Color("#4a2a0c"))
	out["drape"] = img
	out["drape_tips"] = tips


# Floor: fleshy resin mounds with small egg clusters.
static func _paint_mounds(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 512
	var h: int = 60
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 4, 0.55)
	for x: int in range(w):
		var top: int = int(20.0 + (1.0 - prof[x]) * 30.0)
		var lit: bool = prof[x] > prof[posmod(x - 2, w)]
		for y: int in range(top, h):
			var c: Color = Color("#1c1008")
			var d: int = y - top
			if d == 0:
				c = Color("#5a3612") if lit else Color("#3a220c")
			elif d < 3:
				c = Color("#301c0a") if lit else Color("#24150a")
			elif Painter.bayer(x, y) < 0.18:
				c = Color("#140b05")
			img.set_pixel(x, y, c)
	for k: int in range(12):
		var ex: int = rng.randi_range(0, w - 1)
		var ey: float = 20.0 + (1.0 - prof[ex]) * 30.0
		for j: int in range(3):
			var ox: float = float(ex) + float(j) * 4.0 - 4.0
			Painter.ellipse(img, ox, ey - 1.0 - float(j % 2), 2.2, 2.8, Color("#3c3216"))
			Painter.px(img, int(ox) - 1, int(ey) - 3, Color("#625628"))
	out["mounds"] = img


# Near floor bulbs (with larva sacs) and near ceiling tendrils: dark foreground silhouettes.
static func _paint_near(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 640
	var near: Image = Painter.new_img(w, 30)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 5, 0.6)
	for x: int in range(w):
		var top: int = int(10.0 + (1.0 - prof[x]) * 18.0)
		for y: int in range(top, 30):
			near.set_pixel(x, y, Color("#0d0704") if y > top else Color("#3a220c"))
	var sacs: PackedVector3Array = PackedVector3Array()
	for k: int in range(9):
		var sx: float = (float(k) + rng.randf_range(0.2, 0.8)) * float(w) / 9.0
		var top2: float = 10.0 + (1.0 - prof[int(sx)]) * 18.0
		var r: float = rng.randf_range(4.0, 6.0)
		var sy: float = top2 - r * 0.4
		Painter.ellipse(near, sx, sy, r + 1.0, r * 0.8 + 1.0, Color("#1a0e05"))
		Painter.ellipse(near, sx, sy, r, r * 0.8, Color("#4a2c0e"))
		Painter.ellipse(near, sx - r * 0.3, sy - r * 0.3, r * 0.45, r * 0.3, Color("#6e4416"))
		sacs.append(Vector3(sx, sy, r))
	out["near"] = near
	out["sacs"] = sacs

	var top_img: Image = Painter.new_img(w, 22)
	var prof2: PackedFloat32Array = Painter.profile(w, rng, 4, 6, 0.6)
	for x2: int in range(w):
		var l: int = int(2.0 + prof2[x2] * 8.0)
		if posmod(x2 * 7 + 3, 61) < 3:
			l += 10
		for y2: int in range(l):
			top_img.set_pixel(x2, y2, Color("#0c0603") if y2 < l - 1 else Color("#2a1708"))
	out["near_top"] = top_img


# A giant worker's silhouette, two leg poses stacked vertically (104 x 40 each).
static func _paint_worker(out: Dictionary) -> void:
	var img: Image = Painter.new_img(104, 80)
	for f: int in range(2):
		var oy: float = float(f) * 40.0
		var body: Color = Color("#0c0703")
		var rim: Color = Color("#2a1909")
		for l: int in range(3):
			var lx: float = 32.0 + float(l) * 16.0
			var swing: float = (5.0 if (l + f) % 2 == 0 else -5.0)
			Painter.line(img, int(lx), int(oy + 22.0), int(lx - 6.0 + swing), int(oy + 30.0), body)
			Painter.line(img, int(lx - 6.0 + swing), int(oy + 30.0), int(lx - 10.0 + swing), int(oy + 39.0), body)
			Painter.line(img, int(lx), int(oy + 18.0), int(lx - 4.0 - swing), int(oy + 8.0), body)
			Painter.line(img, int(lx - 4.0 - swing), int(oy + 8.0), int(lx - 9.0 - swing), int(oy + 1.0), body)
		Painter.ellipse(img, 76.0, oy + 21.0, 24.0, 11.0, body)
		Painter.ellipse(img, 44.0, oy + 20.0, 14.0, 8.0, body)
		Painter.ellipse(img, 22.0, oy + 19.0, 10.0, 8.0, body)
		Painter.line(img, 14, int(oy + 14.0), 2, int(oy + 6.0 + float(f) * 2.0), body)
		Painter.line(img, 14, int(oy + 15.0), 4, int(oy + 3.0 + float(f) * 2.0), body)
		Painter.line(img, 58, int(oy + 11.0), 96, int(oy + 12.0), rim)
		Painter.line(img, 34, int(oy + 13.0), 54, int(oy + 12.0), rim)
		Painter.px(img, 16, int(oy + 17.0), Color("#3a4a16"))
	out["worker"] = img


# --- animation ----------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 32.0
	drift_a.y1 = 250.0
	drift_a.setup(26, rng, -8.0, 4.0, -9.0, -2.0)
	drift_a.par = 0.6
	drift_a.sway = 2.5
	drift_a.sway_hz = 1.1
	drift_a.cols = PackedColorArray([Color(1.0, 0.72, 0.3, 0.42), Color(0.85, 0.55, 0.22, 0.32), Color(0.75, 1.0, 0.4, 0.28)])
	drift_b.y0 = 40.0
	drift_b.y1 = 200.0
	drift_b.setup(12, rng, -46.0, -28.0, -4.0, 4.0)
	drift_b.par = 0.1
	drift_b.sway = 3.0
	drift_b.sway_hz = 3.0
	drift_b.blink = 6.0
	drift_b.duty = 0.6
	drift_b.cols = PackedColorArray([Color(0.55, 0.36, 0.16, 0.5)])
	_drip_t = 0.2
	_pulse_x = -1.0
	_pulse_wait = rng.randf_range(4.0, 7.0)
	_worker_x = -1.0
	_worker_wait = rng.randf_range(6.0, 12.0)
	_swarm_x = -1.0
	_swarm_wait = rng.randf_range(2.0, 5.0)


func update() -> void:
	# resin drips from the stalactite tips on screen
	_drip_t -= dl
	if _drip_t <= 0.0:
		_drip_t = rng.randf_range(0.07, 0.2)
		var tips: PackedVector2Array = meta.get("drape_tips", PackedVector2Array())
		if not tips.is_empty():
			var tip: Vector2 = tips[rng.randi_range(0, tips.size() - 1)]
			var sx: float = wrap_x(tip.x, off(MID_F, 512.0), 512.0)
			if sx > 0.0 and sx < 480.0:
				fx_spawn(StarfieldBg.Fx.DROPLET, sx, DRAPE_Y + tip.y, 0.0, rng.randf_range(4.0, 14.0), rng.randf_range(1.2, 1.7), MID_F)
	# a wave of light rolling through the comb
	if _pulse_x < 0.0:
		_pulse_wait -= dl
		if _pulse_wait <= 0.0:
			_pulse_x = 540.0
	else:
		_pulse_x -= 150.0 * dl
		if _pulse_x < -60.0:
			_pulse_x = -1.0
			_pulse_wait = rng.randf_range(9.0, 15.0)
	# a giant worker crawling across the far wall
	if _worker_x < 0.0:
		_worker_wait -= dl
		if _worker_wait <= 0.0:
			_worker_x = 500.0
			_worker_y = rng.randf_range(70.0, 150.0)
	else:
		_worker_x -= (14.0 + 4.0 * maxf(0.0, sin(life * 3.0))) * dl + ds * COMB_F
		if _worker_x < -110.0:
			_worker_x = -1.0
			_worker_wait = rng.randf_range(16.0, 26.0)
	# a distant swarm streaming past
	if _swarm_x < 0.0:
		_swarm_wait -= dl
		if _swarm_wait <= 0.0:
			_swarm_x = 520.0
			_swarm_y = rng.randf_range(50.0, 120.0)
	else:
		_swarm_x -= 95.0 * dl
		if _swarm_x < -120.0:
			_swarm_x = -1.0
			_swarm_wait = rng.randf_range(10.0, 18.0)


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	layer("comb", COMB_Y, COMB_F)
	var comb: Texture2D = tex("comb")
	if _pulse_x >= 0.0:
		# the pulse brightens a band of the comb, strongest in its middle
		var oc: float = scroll * COMB_F
		for b: int in range(3):
			var half: float = 26.0 - float(b) * 9.0
			var x0: float = maxf(0.0, _pulse_x - half)
			var x1: float = minf(480.0, _pulse_x + half)
			if x1 > x0:
				bg._band(comb, COMB_Y, 0.0, 224.0, oc, x0, x1, Color(1.7, 1.25, 0.7, 0.22))
	var o_comb: float = off(COMB_F, 512.0)
	var eggs: PackedVector2Array = meta.get("comb_eggs", PackedVector2Array())
	for i: int in range(eggs.size()):
		var ex: float = wrap_x(eggs[i].x, o_comb, 512.0)
		if ex < -2.0 or ex > 482.0:
			continue
		var k: float = 0.5 + 0.5 * sin(life * 1.3 + float(i) * 2.1)
		if _pulse_x >= 0.0 and absf(ex - _pulse_x) < 30.0:
			k = 1.0
		var ey: float = COMB_Y + eggs[i].y
		bg.draw_rect(Rect2(floorf(ex) - 1.0, ey - 1.0, 3.0, 4.0), Color(0.55, 0.85, 0.2, 0.08 + 0.14 * k))
		bg.draw_rect(Rect2(floorf(ex), ey, 1.0, 2.0), Color(0.75, 1.0, 0.35, 0.22 + 0.3 * k))
	if _worker_x >= 0.0:
		var fr: int = int(life * 3.0) % 2
		bg.draw_texture_rect_region(tex("worker"), Rect2(floorf(_worker_x), floorf(_worker_y), 104.0, 40.0), Rect2(0.0, float(fr * 40), 104.0, 40.0))
	if _swarm_x >= 0.0:
		for s: int in range(26):
			var sx: float = _swarm_x + float(s % 7) * 9.0 + float(s / 7) * 5.0 + sin(life * 2.0 + float(s)) * 4.0
			var sy: float = _swarm_y + float(s / 7) * 5.0 + sin(life * 3.1 + float(s) * 1.7) * 3.0 + sin(sx * 0.02) * 10.0
			bg.draw_rect(Rect2(floorf(sx), floorf(sy), 2.0 if s % 3 == 0 else 1.0, 1.0), Color(0.45, 0.3, 0.14, 0.7))
	drift_draw(drift_b)

	layer("pillars", PILLAR_Y, PILLAR_F)
	var o_p: float = off(PILLAR_F, 640.0)
	var peggs: PackedVector2Array = meta.get("pillar_eggs", PackedVector2Array())
	for j: int in range(peggs.size()):
		var px: float = wrap_x(peggs[j].x, o_p, 640.0)
		if px < -2.0 or px > 482.0:
			continue
		var k2: float = 0.5 + 0.5 * sin(life * 1.7 + float(j) * 1.3)
		bg.draw_rect(Rect2(floorf(px) - 1.0, PILLAR_Y + peggs[j].y - 1.0, 2.0, 3.0), Color(0.7, 1.0, 0.3, 0.12 + 0.22 * k2))

	layer("mounds", MOUND_Y, MID_F)
	layer("drape", DRAPE_Y, MID_F)
	fx_draw()
	drift_draw(drift_a)

	layer("near", NEAR_Y, NEAR_F)
	var o_n: float = off(NEAR_F, 640.0)
	var sacs: PackedVector3Array = meta.get("sacs", PackedVector3Array())
	for s2: int in range(sacs.size()):
		var sx2: float = wrap_x(sacs[s2].x, o_n, 640.0)
		if sx2 < -10.0 or sx2 > 490.0:
			continue
		var r: float = sacs[s2].z
		var sy2: float = NEAR_Y + sacs[s2].y
		var beat: float = 0.5 + 0.5 * sin(life * 2.4 + float(s2) * 1.9)
		var wig: float = floorf(sin(life * 3.3 + float(s2)) * r * 0.35)
		bg.draw_rect(Rect2(floorf(sx2 - r * 0.5) + wig, floorf(sy2) - 1.0, floorf(r), 2.0), Color(0.12, 0.06, 0.02, 0.85))
		bg.draw_rect(Rect2(floorf(sx2 - r * 0.7), floorf(sy2 - r * 0.6), floorf(r * 1.4), floorf(r * 1.1)), Color(1.0, 0.6, 0.15, 0.05 + 0.1 * beat))
		bg.draw_rect(Rect2(floorf(sx2 - 1.0) + wig, floorf(sy2) - 1.0, 1.0, 1.0), Color(0.7, 1.0, 0.3, 0.3 + 0.5 * beat))
	layer("near_top", NEAR_TOP_Y, NEAR_F)
