extends "res://scripts/stages/stage_background.gd"

# STAGE 15 background: a fleet graveyard in a green ghost-haze. A dead sun behind the fog;
# snapped capital ships on the horizon with failing lights; banks of haze rolling past; hull
# debris tumbling at mid depth, sparking; the hull of a vast derelict scrolling underneath and
# broken girders hanging from above. Rare events: a phantom ship glides through the haze, a
# far wreck's reactor flashes, and a distress beacon sweeps the fog.
#
# Layers: "sky" 480x270; "far" 768x110 at y 58 (0.04); "haze" 512x90 drawn twice (0.12/0.2);
# "debris" 4 chunks of 48x32; "near" 768x50 at y 214 (0.85); "girders" 896x58 at y 0 (0.95);
# "phantom" 128x44.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const FAR_Y: float = 58.0
const FAR_F: float = 0.04
const NEAR_Y: float = 214.0
const NEAR_F: float = 0.85
const GIRDER_Y: float = 0.0
const GIRDER_F: float = 0.95
const DEBRIS_N: int = 6

var _dx: PackedFloat32Array = PackedFloat32Array()
var _dy: PackedFloat32Array = PackedFloat32Array()
var _dr: PackedFloat32Array = PackedFloat32Array()
var _dw: PackedFloat32Array = PackedFloat32Array()
var _dp: PackedFloat32Array = PackedFloat32Array()
var _dk: PackedInt32Array = PackedInt32Array()
var _spark_t: float = 0.4
var _phantom_x: float = -999.0
var _phantom_y: float = 90.0
var _phantom_wait: float = 8.0
var _flash_t: float = -1.0
var _flash_i: int = 0
var _flash_wait: float = 5.0
var _beacon_t: float = -1.0
var _beacon_wait: float = 3.0
var _beacon_x: float = 0.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1515
	var out: Dictionary = {}

	# Sky: black-green, fog banks, a dead sun drowned in haze, a few dimmed stars.
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#030605"))
	Painter.vgrad(sky, 22, 258, PackedColorArray([Color("#030605"), Color("#040807"), Color("#060b09"), Color("#07100c"), Color("#09140f"), Color("#0a1712")]), 0.5)
	var fog: PackedByteArray = Painter.fast_field(480, 270, 110.0, 4, 1515)
	var fog_ramp: PackedColorArray = PackedColorArray([Color("#040807"), Color("#060c0a"), Color("#08110d"), Color("#0b1712"), Color("#0e1e17"), Color("#12261d")])
	for y: int in range(24, 258):
		var vy: float = 1.0 - absf(float(y) - 140.0) / 150.0
		for x: int in range(480):
			var v: float = float(fog[y * 480 + x]) / 255.0
			var band: float = 0.6 + 0.4 * sin(float(y) * 0.04 + float(x) * 0.005)
			var f: float = clampf((v - 0.22) * 1.5 * band * (0.55 + 0.45 * vy), 0.0, 1.0)
			sky.set_pixel(x, y, Painter.ramp_pick(fog_ramp, f, x, y))
	var sun: Vector2 = Vector2(392.0, 72.0)
	for y2: int in range(40, 104):
		for x2: int in range(356, 428):
			var d: float = Vector2(float(x2) + 0.5, float(y2) + 0.5).distance_to(sun)
			if d < 15.0:
				sky.set_pixel(x2, y2, Color("#2a4a3a") if d < 13.0 else Color("#1e3a2e"))
			elif d < 34.0 and Painter.bayer(x2, y2) < (1.0 - (d - 15.0) / 19.0) * 0.6:
				sky.set_pixel(x2, y2, Color("#13281f"))
	for i: int in range(70):
		var sx: int = rng.randi_range(0, 479)
		var sy: int = rng.randi_range(24, 200)
		if sky.get_pixel(sx, sy).g < 0.07:
			sky.set_pixel(sx, sy, Color("#4a6a5c") if i % 4 == 0 else Color("#24382f"))
	out["sky"] = sky

	_paint_far(out, rng)
	_paint_haze(out, rng)
	_paint_debris(out, rng)
	_paint_near(out, rng)
	_paint_girders(out, rng)
	_paint_phantom(out)
	return out


# Snapped capital ships on the horizon, very dark, with a faint rim and scattered lights.
static func _paint_far(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 110
	var img: Image = Painter.new_img(w, h)
	var lights: PackedVector2Array = PackedVector2Array()
	# Each ship: x, centre y, length, tilt; two of them are snapped in half and drifting apart.
	var specs: Array[Vector4] = [Vector4(20.0, 46.0, 250.0, 0.05), Vector4(318.0, 70.0, 190.0, -0.08), Vector4(560.0, 38.0, 180.0, 0.03)]
	for si: int in range(specs.size()):
		var s: Vector4 = specs[si]
		var thick: float = rng.randf_range(20.0, 26.0) * (1.0 if si != 1 else 0.8)
		var gap0: float = rng.randf_range(0.48, 0.58) * s.z
		var gap1: float = gap0 + rng.randf_range(12.0, 22.0)
		var towers: Array[Vector3] = []
		for k: int in range(3):
			towers.append(Vector3(rng.randf_range(0.2, 0.82) * s.z, rng.randf_range(10.0, 18.0) * thick / 24.0, rng.randf_range(8.0, 16.0)))
		for i: int in range(int(s.z)):
			var fi: float = float(i)
			if fi > gap0 and fi < gap1:
				continue
			var t: float = fi / s.z
			var half_drop: float = 6.0 + (fi - gap1) * 0.04 if fi >= gap1 else 0.0
			var cy: float = s.y + fi * s.w + half_drop
			var th: float = thick * minf(1.0, 0.25 + t * 6.0)
			if t > 0.9:
				th = thick * 1.35
			var top: int = int(cy - th * 0.5)
			var bot: int = int(cy + th * 0.5)
			var x: int = int(s.x) + i
			for y: int in range(top, bot + 1):
				var c: Color = Color("#08120f")
				if y > int(cy) + 2:
					c = Color("#060d0b")
				if (y - top) % 6 == 5:
					c = Color("#050b09")
				Painter.px(img, x, y, c)
			Painter.px(img, x, top, Color("#1c3c34"))
			Painter.px(img, x, top + 1, Color("#10221d"))
			for tw: Vector3 in towers:
				if fi > tw.x and fi < tw.x + tw.z:
					var tt: int = top - int(tw.y)
					Painter.vline(img, x, tt, top, Color("#08120f"))
					Painter.px(img, x, tt, Color("#1c3c34"))
					if int(fi - tw.x) % 4 == 2 and rng.randf() < 0.5:
						lights.append(Vector2(float(x), float(tt + 3)))
			# jagged broken edges at the snap
			if absf(fi - gap0) < 3.0 or absf(fi - gap1) < 3.0:
				Painter.vline(img, x, top - rng.randi_range(0, 6), bot + rng.randi_range(0, 5), Color("#08120f"))
			# engine nozzles at the stern
			if t > 0.97:
				Painter.rect(img, x, int(cy) - 6, 1, 4, Color("#0e2a22"))
				Painter.rect(img, x, int(cy) + 3, 1, 4, Color("#0e2a22"))
			if rng.randf() < 0.035:
				lights.append(Vector2(float(x), float(rng.randi_range(top + 3, bot - 2))))
		# chunks floating in the gap and a snapped antenna mast
		for c2: int in range(3):
			var gx: float = s.x + gap0 + rng.randf_range(2.0, gap1 - gap0 - 2.0)
			var gy: float = s.y + gap0 * s.w + rng.randf_range(-thick, thick)
			Painter.rect(img, int(gx), int(gy), rng.randi_range(2, 4), rng.randi_range(2, 3), Color("#0b1714"))
		var mx: int = int(s.x + s.z * 0.3)
		var my: int = int(s.y + s.z * 0.3 * s.w - thick * 0.5)
		Painter.line(img, mx, my, mx + 10, my - 24, Color("#1c3c34"))
		Painter.line(img, mx + 10, my - 24, mx + 4, my - 28, Color("#10221d"))
	out["far"] = img
	out["far_lights"] = lights


# Tileable fog bank: dithered translucent green.
static func _paint_haze(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 512
	var h: int = 90
	var img: Image = Painter.new_img(w, h)
	var n: PackedByteArray = Painter.fast_field(w, h, 60.0, 3, 1516)
	for y: int in range(h):
		var fade: float = sin(float(y) / float(h - 1) * PI)
		for x: int in range(w):
			var v: float = (float(n[y * w + x]) / 255.0 - 0.42) * 2.4 * fade
			if v > 0.0 and Painter.bayer(x, y) < v:
				img.set_pixel(x, y, Color(0.35, 0.85, 0.6, 0.07 + 0.05 * minf(1.0, v)))
	out["haze"] = img


# Four hull fragments (48x32 each, side by side), dark with a rim and rust.
static func _paint_debris(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var img: Image = Painter.new_img(192, 32)
	for k: int in range(4):
		var ox: float = float(k) * 48.0
		var pts: PackedVector2Array = PackedVector2Array()
		var n: int = 7
		for i: int in range(n):
			var a: float = TAU * float(i) / float(n) + rng.randf_range(-0.25, 0.25)
			var r: float = rng.randf_range(8.0, 14.0)
			pts.append(Vector2(ox + 24.0 + cos(a) * r * 1.4, 16.0 + sin(a) * r * 0.9))
		Painter.poly(img, pts, Color("#0c1714"))
		for i2: int in range(n):
			var a2: Vector2 = pts[i2]
			var b2: Vector2 = pts[(i2 + 1) % n]
			if (b2 - a2).angle() < 0.4 and (b2 - a2).angle() > -2.6:
				Painter.line(img, int(a2.x), int(a2.y), int(b2.x), int(b2.y), Color("#1e3a33"))
		Painter.line(img, int(ox + 14.0), 16, int(ox + 34.0), 15, Color("#14241f"))
		Painter.rect(img, int(ox + 20.0), 12, 4, 3, Color("#2a1810"))
		Painter.px(img, int(ox + 28.0), 18, Color("#1a3a2e"))
	out["debris"] = img


# The vast derelict below: plated hull, ribs, portholes and torn cables.
static func _paint_near(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 50
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 3, 3, 0.5)
	var ports: PackedVector2Array = PackedVector2Array()
	var cables: PackedVector2Array = PackedVector2Array()
	for x: int in range(w):
		var top: int = int(18.0 + (1.0 - prof[x]) * 10.0)
		var panel: bool = (x / 24) % 2 == 0
		for y: int in range(top, h):
			var c: Color = Color("#0a1311") if panel else Color("#0c1614")
			var d: int = y - top
			if d == 0:
				c = Color("#2e5048")
			elif d == 1:
				c = Color("#1a302c")
			elif d % 8 == 0 or x % 24 == 0:
				c = Color("#060c0b")
			elif d % 8 == 1:
				c = Color("#14221f")
			elif d % 8 == 4 and x % 6 == 3:
				c = Color("#1c302b")
			img.set_pixel(x, y, c)
		if x % 32 == 16 and rng.randf() < 0.7:
			ports.append(Vector2(float(x), float(top + 6)))
			Painter.rect(img, x - 1, top + 5, 3, 3, Color("#050a09"))
	# hull breaches: dark holes with ribs and a dim glow deep inside
	for hb: int in range(4):
		var bx: float = rng.randf_range(0.0, float(w))
		var btop: float = 18.0 + (1.0 - prof[int(bx)]) * 10.0
		var brx: float = rng.randf_range(9.0, 15.0)
		Painter.ellipse(img, bx, btop + 12.0, brx + 1.0, 8.0, Color("#1a302c"))
		Painter.ellipse(img, bx, btop + 12.0, brx, 7.0, Color("#040807"))
		Painter.ellipse(img, bx + 1.0, btop + 14.0, brx * 0.5, 3.0, Color("#0c2a1f"))
		for rr: int in range(-int(brx) + 3, int(brx) - 2, 4):
			Painter.vline(img, int(bx) + rr, int(btop) + 6, int(btop) + 18, Color("#162824"))
	# deck turrets with broken barrels
	for tu: int in range(3):
		var tx: int = 120 + tu * 250 + rng.randi_range(-30, 30)
		var ttop: int = int(18.0 + (1.0 - prof[tx]) * 10.0)
		Painter.ellipse(img, float(tx), float(ttop), 8.0, 5.0, Color("#0e1a17"))
		Painter.span(img, tx - 7, tx + 5, ttop - 4, Color("#2a4842"))
		Painter.line(img, tx - 2, ttop - 2, tx - 16, ttop - 9, Color("#0e1a17"))
		Painter.line(img, tx - 2, ttop - 3, tx - 15, ttop - 10, Color("#24403a"))
	# ribs and broken frames sticking up
	for r: int in range(9):
		var rx: int = rng.randi_range(0, w - 1)
		var top2: int = int(18.0 + (1.0 - prof[rx]) * 10.0)
		var rh: int = rng.randi_range(8, 18)
		Painter.rect(img, rx, top2 - rh, 3, rh, Color("#0b1512"))
		Painter.vline(img, rx, top2 - rh, top2, Color("#22403a"))
		Painter.line(img, rx + 1, top2 - rh, rx + 6, top2 - rh - 4, Color("#0b1512"))
		cables.append(Vector2(float(rx + 6), float(top2 - rh - 4)))
	# rust streaks
	for k: int in range(30):
		var sx: int = rng.randi_range(0, w - 1)
		var top3: int = int(18.0 + (1.0 - prof[sx]) * 10.0)
		Painter.vline(img, sx, top3 + 2, top3 + rng.randi_range(5, 14), Color("#24160e"))
	out["near"] = img
	out["near_ports"] = ports
	out["near_cables"] = cables


# Broken girder trusses hanging from above, here and there.
static func _paint_girders(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 896
	var h: int = 58
	var img: Image = Painter.new_img(w, h)
	var body: Color = Color("#081210")
	var rim: Color = Color("#1a3530")
	for g: int in range(3):
		var gx: int = 80 + g * 300 + rng.randi_range(-40, 40)
		var gl: int = rng.randi_range(30, 52)
		var lean: float = rng.randf_range(-0.35, 0.35)
		for y: int in range(gl):
			var ox: int = int(float(y) * lean)
			Painter.px(img, gx + ox, y, rim)
			Painter.px(img, gx + ox + 7, y, body)
			if y % 7 == 0:
				Painter.line(img, gx + ox, y, gx + ox + 7, y + 6, body)
		# a dangling cable at the end
		for c: int in range(10):
			Painter.px(img, gx + int(float(gl) * lean) + 3 + int(sin(float(c) * 0.6) * 1.5), gl + c, body)
	out["girders"] = img


# Phantom ship: a translucent galleon-like silhouette of ghost-light.
static func _paint_phantom(out: Dictionary) -> void:
	var img: Image = Painter.new_img(128, 44)
	var c: Color = Color(0.45, 1.0, 0.75, 0.55)
	var c2: Color = Color(0.7, 1.0, 0.85, 0.8)
	Painter.poly(img, PackedVector2Array([Vector2(2, 30), Vector2(18, 26), Vector2(116, 26), Vector2(126, 22), Vector2(120, 36), Vector2(16, 38)]), c)
	for m: int in range(3):
		var mx: int = 40 + m * 28
		Painter.vline(img, mx, 4, 26, c2)
		Painter.poly(img, PackedVector2Array([Vector2(mx - 12, 8), Vector2(mx + 10, 6), Vector2(mx + 12, 22), Vector2(mx - 10, 23)]), Color(0.4, 0.9, 0.7, 0.3))
	Painter.line(img, 2, 30, 116, 26, c2)
	for p: int in range(8):
		Painter.px(img, 24 + p * 11, 32, c2)
	out["phantom"] = img


# --- animation ----------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 30.0
	drift_a.y1 = 252.0
	drift_a.setup(22, rng, -6.0, 6.0, -10.0, -3.0)
	drift_a.par = 0.5
	drift_a.sway = 3.0
	drift_a.sway_hz = 0.7
	drift_a.cols = PackedColorArray([Color(0.5, 1.0, 0.75, 0.35), Color(0.4, 0.85, 0.65, 0.25), Color(0.8, 1.0, 0.9, 0.3)])
	drift_b.y0 = 40.0
	drift_b.y1 = 230.0
	drift_b.setup(10, rng, -16.0, -8.0, -2.0, 2.0)
	drift_b.par = 0.2
	drift_b.size = 2.0
	drift_b.cols = PackedColorArray([Color(0.4, 0.9, 0.7, 0.1)])
	_dx.resize(DEBRIS_N)
	_dy.resize(DEBRIS_N)
	_dr.resize(DEBRIS_N)
	_dw.resize(DEBRIS_N)
	_dp.resize(DEBRIS_N)
	_dk.resize(DEBRIS_N)
	for i: int in range(DEBRIS_N):
		_dx[i] = rng.randf_range(0.0, 560.0)
		_dy[i] = rng.randf_range(50.0, 200.0)
		_dr[i] = rng.randf_range(0.0, TAU)
		_dw[i] = rng.randf_range(-0.5, 0.5)
		_dp[i] = rng.randf_range(0.3, 0.5)
		_dk[i] = i % 4
	_phantom_x = -999.0
	_phantom_wait = rng.randf_range(6.0, 12.0)
	_flash_t = -1.0
	_flash_wait = rng.randf_range(3.0, 7.0)
	_beacon_t = -1.0
	_beacon_wait = rng.randf_range(2.0, 5.0)


func update() -> void:
	for i: int in range(DEBRIS_N):
		_dx[i] -= ds * _dp[i] + 6.0 * dl
		_dy[i] += sin(life * 0.3 + float(i)) * 3.0 * dl
		_dr[i] += _dw[i] * dl
		if _dx[i] < -40.0:
			_dx[i] = 520.0 + rng.randf_range(0.0, 60.0)
			_dy[i] = rng.randf_range(50.0, 200.0)
			_dk[i] = rng.randi_range(0, 3)
	# sparks off debris and the cables of the hull below
	_spark_t -= dl
	if _spark_t <= 0.0:
		_spark_t = rng.randf_range(0.12, 0.45)
		if rng.randf() < 0.5:
			var j: int = rng.randi_range(0, DEBRIS_N - 1)
			if _dx[j] > 0.0 and _dx[j] < 480.0:
				for s: int in range(3):
					fx_spawn(StarfieldBg.Fx.SPARK, _dx[j] + rng.randf_range(-10.0, 10.0), _dy[j] + rng.randf_range(-5.0, 5.0), rng.randf_range(-40.0, 40.0), rng.randf_range(-50.0, 10.0), rng.randf_range(0.3, 0.6), _dp[j])
		else:
			var cables: PackedVector2Array = meta.get("near_cables", PackedVector2Array())
			if not cables.is_empty():
				var c: Vector2 = cables[rng.randi_range(0, cables.size() - 1)]
				var cx: float = wrap_x(c.x, off(NEAR_F, 768.0), 768.0)
				if cx > 0.0 and cx < 480.0:
					for s2: int in range(4):
						fx_spawn(StarfieldBg.Fx.SPARK, cx, NEAR_Y + c.y, rng.randf_range(-30.0, 30.0), rng.randf_range(-60.0, -10.0), rng.randf_range(0.3, 0.7), NEAR_F)
	# phantom ship
	if _phantom_x < -500.0:
		_phantom_wait -= dl
		if _phantom_wait <= 0.0:
			_phantom_x = -130.0
			_phantom_y = rng.randf_range(60.0, 130.0)
	else:
		_phantom_x += 22.0 * dl
		if _phantom_x > 500.0:
			_phantom_x = -999.0
			_phantom_wait = rng.randf_range(18.0, 28.0)
	# reactor flash on a far wreck
	if _flash_t < 0.0:
		_flash_wait -= dl
		if _flash_wait <= 0.0:
			_flash_t = 0.0
			var lights: PackedVector2Array = meta.get("far_lights", PackedVector2Array())
			_flash_i = rng.randi_range(0, maxi(0, lights.size() - 1))
	else:
		_flash_t += dl
		if _flash_t > 1.4:
			_flash_t = -1.0
			_flash_wait = rng.randf_range(10.0, 18.0)
	# distress beacon sweep
	if _beacon_t < 0.0:
		_beacon_wait -= dl
		if _beacon_wait <= 0.0:
			_beacon_t = 0.0
			_beacon_x = rng.randf_range(60.0, 420.0)
	else:
		_beacon_t += dl
		if _beacon_t > 4.0:
			_beacon_t = -1.0
			_beacon_wait = rng.randf_range(8.0, 14.0)


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	if _beacon_t >= 0.0:
		var a: float = sin(_beacon_t / 4.0 * PI)
		var ang: float = -2.6 + _beacon_t * 0.55
		var o: Vector2 = Vector2(_beacon_x, 118.0)
		var d: Vector2 = Vector2.from_angle(ang)
		bg.draw_line(o, o + d * 420.0, Color(1.0, 0.4, 0.3, 0.06 * a), 5.0)
		bg.draw_line(o, o + d * 420.0, Color(1.0, 0.55, 0.45, 0.14 * a), 1.0)
		if int(life * 4.0) % 2 == 0:
			bg.draw_rect(Rect2(o - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(1.0, 0.4, 0.3, 0.8 * a))
	var haze: Texture2D = tex("haze")
	var ha: float = 0.65 + 0.35 * sin(life * 0.31)
	bg._band(haze, 46.0, 0.0, 90.0, scroll * 0.12 + life * 5.0, 0.0, 480.0, Color(1.0, 1.0, 1.0, ha))
	if _phantom_x > -500.0:
		var pa: float = (0.2 + 0.12 * sin(life * 2.3)) * clampf(minf(_phantom_x + 130.0, 500.0 - _phantom_x) / 80.0, 0.0, 1.0)
		var bob: float = floorf(sin(life * 0.9) * 3.0)
		bg.draw_texture(tex("phantom"), Vector2(floorf(_phantom_x), _phantom_y + bob), Color(1.0, 1.0, 1.0, pa))
	layer("far", FAR_Y, FAR_F)
	var o_far: float = off(FAR_F, 768.0)
	var lights: PackedVector2Array = meta.get("far_lights", PackedVector2Array())
	for i: int in range(lights.size()):
		var lx: float = wrap_x(lights[i].x, o_far, 768.0)
		if lx < 0.0 or lx > 480.0:
			continue
		var h: int = (int(life * 7.0) + i * 13) % 23
		if h < 15 or (h > 17 and h < 20):
			bg.draw_rect(Rect2(floorf(lx), FAR_Y + lights[i].y, 1.0, 1.0), Color("#5aff9c") if i % 5 != 0 else Color("#ff5a4a"))
	if _flash_t >= 0.0 and _flash_i < lights.size():
		var fx2: float = wrap_x(lights[_flash_i].x, o_far, 768.0)
		var fy: float = FAR_Y + lights[_flash_i].y
		var k: float = _flash_t / 1.4
		bg.draw_circle(Vector2(fx2, fy), 3.0 + 6.0 * (1.0 - k), Color(0.85, 1.0, 0.9, 0.5 * (1.0 - k)))
		bg.draw_arc(Vector2(fx2, fy), 4.0 + 40.0 * k, 0.0, TAU, 28, Color(0.5, 1.0, 0.75, 0.35 * (1.0 - k)), 1.0)
	drift_draw(drift_b)
	bg._band(haze, 132.0, 0.0, 90.0, scroll * 0.2 - life * 3.0 + 200.0, 0.0, 480.0, Color(1.0, 1.0, 1.0, 1.0 - ha * 0.5))
	var deb: Texture2D = tex("debris")
	for d2: int in range(DEBRIS_N):
		if _dx[d2] < -40.0 or _dx[d2] > 520.0:
			continue
		bg.draw_set_transform(Vector2(floorf(_dx[d2]), floorf(_dy[d2])), _dr[d2], Vector2.ONE)
		bg.draw_texture_rect_region(deb, Rect2(-24.0, -16.0, 48.0, 32.0), Rect2(float(_dk[d2]) * 48.0, 0.0, 48.0, 32.0))
	bg.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	fx_draw()
	drift_draw(drift_a)
	layer("near", NEAR_Y, NEAR_F)
	var o_n: float = off(NEAR_F, 768.0)
	var ports: PackedVector2Array = meta.get("near_ports", PackedVector2Array())
	for p: int in range(ports.size()):
		var px: float = wrap_x(ports[p].x, o_n, 768.0)
		if px < 0.0 or px > 480.0:
			continue
		var h2: int = (int(life * 5.0) + p * 7) % 17
		if h2 < 11:
			bg.draw_rect(Rect2(floorf(px), NEAR_Y + ports[p].y, 1.0, 1.0), Color(0.45, 1.0, 0.7, 0.55 if h2 % 3 != 0 else 0.3))
	layer("girders", GIRDER_Y, GIRDER_F)
