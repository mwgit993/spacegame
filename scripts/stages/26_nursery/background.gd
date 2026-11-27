extends "res://scripts/stages/stage_background.gd"

# STAGE 26 background: a stellar nursery. Magenta and teal gas glows along the top and bottom
# of the sky (the middle stays dark for the bullets); towering gas pillars rise from below,
# far ones dim and violet, near ones dark with gold and magenta rims where young suns light
# them. Newborn stars blink awake inside the pillars with diffraction spikes, two little
# protoplanetary disks turn, dust lanes drift across, luminous gas filaments hang from the top
# and slow gas currents flow by. Rare events (countdowns _ev_wait_a/_b/_c): a star ignites in
# the far pillars (flash, spikes and an expanding ring), a young star in the near pillars fires
# bipolar jets, and a shock front from a distant supernova sweeps across the whole sky.
#
# Layers: "sky" 480x270; "far" 768x200 at y 52 (0.03); "dust" 768x36 at y 64 and y 186
# (0.18 / 0.36); "near" 896x158 at y 102 (0.14); "veil" 640x42 at y 22 (0.07, wobbling);
# "front" 1024x40 at y 222 (0.7).

const Painter = preload("res://scripts/stage_bg_painter.gd")

const FAR_Y: float = 52.0
const FAR_F: float = 0.03
const FAR_W: float = 768.0
const NEAR_Y: float = 102.0
const NEAR_F: float = 0.14
const NEAR_W: float = 896.0
const DUST_W: float = 768.0
const VEIL_Y: float = 22.0
const VEIL_F: float = 0.07
const FRONT_Y: float = 222.0
const FRONT_F: float = 0.7
const FRONT_W: float = 1024.0
const IGNITE_T: float = 2.8
const JET_T: float = 2.4
const SHOCK_T: float = 3.4
const CUR_Y: Array[float] = [48.0, 222.0, 138.0]
const CUR_AMP: Array[float] = [9.0, 11.0, 16.0]
const CUR_A: Array[float] = [0.16, 0.16, 0.06]

var _ev_wait_a: float = 6.0
var _ev_wait_b: float = 9.0
var _ev_wait_c: float = 14.0
var _ign_t: float = -1.0
var _ign_pos: Vector2 = Vector2.ZERO
var _jet_t: float = -1.0
var _jet_star: Vector2 = Vector2.ZERO
var _shock_t: float = -1.0
var _shock_y: float = 140.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2626
	var out: Dictionary = {}
	out["sky"] = _paint_sky(rng)
	_paint_far(out, rng)
	_paint_near(out, rng)
	out["dust"] = _paint_dust(rng)
	out["veil"] = _paint_veil()
	out["front"] = _paint_front(rng)
	return out


# Dark violet sky; nebula gas (magenta in one noise field, teal in another) glows brightest
# along the top and bottom edges and fades to near black across the middle of the playfield.
static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#07041a"))
	var fm: PackedByteArray = Painter.fast_field(480, 270, 120.0, 4, 2626)
	var ft: PackedByteArray = Painter.fast_field(480, 270, 86.0, 4, 2629)
	var mag: PackedColorArray = PackedColorArray([Color("#07041a"), Color("#0d0620"), Color("#16092a"), Color("#220e38"), Color("#321446"), Color("#461c56"), Color("#5c2464")])
	var teal: PackedColorArray = PackedColorArray([Color("#07041a"), Color("#070a20"), Color("#091228"), Color("#0c1c32"), Color("#10283e"), Color("#15384a"), Color("#1c4a56")])
	for y: int in range(22, 260):
		var top: float = clampf((84.0 - float(y)) / 56.0, 0.0, 1.0)
		var bot: float = clampf((float(y) - 166.0) / 90.0, 0.0, 1.0)
		var e: float = maxf(top, bot) * 0.78 + 0.22
		for x: int in range(480):
			var i: int = y * 480 + x
			var vm: float = clampf((float(fm[i]) / 255.0 - 0.42) * 2.3, 0.0, 1.0) * e
			var vt: float = clampf((float(ft[i]) / 255.0 - 0.48) * 2.5, 0.0, 1.0) * e
			if vm < 0.08 and vt < 0.08:
				continue
			if vm >= vt:
				sky.set_pixel(x, y, Painter.ramp_pick(mag, vm, x, y))
			else:
				sky.set_pixel(x, y, Painter.ramp_pick(teal, vt, x, y))
	for s: int in range(170):
		var sx: int = rng.randi_range(0, 479)
		var sy: int = rng.randi_range(24, 256)
		var col: Color = Color("#3a3462")
		if s % 9 == 0:
			col = Color("#c8c0ff")
		elif s % 7 == 0:
			col = Color("#ffb0e0")
		elif s % 5 == 0:
			col = Color("#9ae8f0")
		elif s % 2 == 0:
			col = Color("#5a4c86")
		Painter.px(sky, sx, sy, col)
	return sky


# One rim-lit gas pillar, painted row by row from its base up. It leans and wobbles as it
# rises, with little globules budding off its edge. The side facing the light (upper right)
# carries a thin bright rim that fades lower down, the shadow side a faint back-lit edge, and
# the tip is lit through with a halo of evaporating gas round it. Returns the tip position.
static func _pillar(img: Image, cx: float, base_y: float, height: float, width: float, lean: float, seed_f: float,
		body: Color, inner: Color, rim: Color, tip_col: Color) -> Vector2:
	var tip: Vector2 = Vector2(cx, base_y - height)
	for row: int in range(int(height)):
		var t: float = float(row) / height
		var y: int = int(base_y) - row
		var hw: float = width * pow(maxf(0.0, 1.0 - pow(t, 2.0)), 0.6)
		hw *= 1.0 + 0.16 * sin(t * 13.0 + seed_f) + 0.08 * sin(t * 37.0 + seed_f * 2.0)
		# globules budding off the edges
		hw += maxf(0.0, sin(t * 23.0 + seed_f * 3.0) - 0.75) * width * 0.9
		if hw < 0.6:
			continue
		var c: float = cx + lean * t * height + sin(t * 4.0 + seed_f) * width * 0.25
		var x0: int = int(floorf(c - hw))
		var x1: int = int(ceilf(c + hw))
		var light: float = clampf((t - 0.15) / 0.85, 0.0, 1.0)  # rims brighten toward the top
		for x: int in range(x0, x1 + 1):
			var u: float = (float(x) + 0.5 - c) / hw
			var col: Color = body
			if u > 0.25 and Painter.bayer(x, y) < (u - 0.25) * 0.7:
				col = inner
			if u > 0.78:
				var rk: float = (u - 0.78) / 0.22
				if Painter.bayer(x, y) < rk * (0.35 + 0.65 * light):
					col = rim.lerp(body, 0.55 * (1.0 - light)) if rk > 0.6 else inner
			elif u < -0.88 and light > 0.3:
				col = inner
			if t > 0.8:
				var tk: float = (t - 0.8) / 0.2
				if Painter.bayer(x, y) < tk * (0.3 + 0.7 * (u + 1.0) * 0.5):
					col = tip_col if u > 0.0 or tk > 0.7 else rim
			Painter.px(img, x, y, col)
		tip = Vector2(c, float(y))
	# a soft halo round the tip, where the gas is evaporating in the starlight
	for g: int in range(40):
		var a: float = float(g) * 2.399
		var r: float = 2.0 + fposmod(float(g) * 1.37, 9.0)
		var gp: Vector2 = tip + Vector2(cos(a) * r * 1.1, sin(a) * r * 0.8 - 1.0)
		if Painter.get_px(img, int(gp.x), int(gp.y)).a < 0.5:
			var al: float = 0.55 * (1.0 - r / 11.0)
			Painter.px(img, int(gp.x), int(gp.y), Color(tip_col.r, tip_col.g, tip_col.b, al))
	return tip


# Far pillars: dim violet columns rising out of a low gas bank, with tiny newborn stars and
# two protoplanetary disks among them (their positions go to the animator).
static func _paint_far(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = int(FAR_W)
	var h: int = 200
	var img: Image = Painter.new_img(w, h)
	var body: Color = Color("#100a22")
	var inner: Color = Color("#170f2c")
	var rim: Color = Color("#3e2858")
	var tip_col: Color = Color("#8a5a96")
	var prof: PackedFloat32Array = Painter.profile(w, rng, 4, 3, 0.55)
	for x: int in range(w):
		var top: int = h - int(14.0 + prof[x] * 26.0)
		Painter.rect(img, x, top, 1, h - top, body)
		Painter.px(img, x, top, rim)
	var stars: PackedVector3Array = PackedVector3Array()
	var px_list: Array[float] = [60.0, 200.0, 330.0, 470.0, 610.0, 720.0]
	for i: int in range(px_list.size()):
		var height: float = rng.randf_range(90.0, 170.0)
		var width: float = rng.randf_range(10.0, 20.0)
		var tip: Vector2 = _pillar(img, px_list[i] + rng.randf_range(-20.0, 20.0), float(h) - 18.0, height, width, rng.randf_range(-0.25, 0.25), float(i) * 1.9, body, inner, rim, tip_col)
		stars.append(Vector3(tip.x + rng.randf_range(-3.0, 3.0), tip.y + rng.randf_range(4.0, 14.0), 1.0))
		if i % 2 == 0:
			# a smaller finger beside the big one
			var tip2: Vector2 = _pillar(img, px_list[i] + width + rng.randf_range(4.0, 12.0), float(h) - 18.0, height * 0.55, width * 0.55, rng.randf_range(-0.3, 0.1), float(i) * 3.1, body, inner, rim, tip_col)
			stars.append(Vector3(tip2.x, tip2.y + 6.0, 0.0))
	for s: int in range(10):
		stars.append(Vector3(rng.randf_range(0.0, float(w)), rng.randf_range(6.0, 120.0), 0.0))
	out["far"] = img
	out["far_stars"] = stars
	out["disks"] = PackedVector3Array([Vector3(250.0, 40.0, 12.0), Vector3(560.0, 70.0, 9.0)])


# Near pillars: big dark columns with gold rims on the sunlit side and magenta tips, young
# stars embedded in them (the jets event fires from one of these).
static func _paint_near(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = int(NEAR_W)
	var h: int = 158
	var img: Image = Painter.new_img(w, h)
	var body: Color = Color("#0a0614")
	var inner: Color = Color("#170d22")
	var rim: Color = Color("#c8864a")
	var tip_col: Color = Color("#f0a0c8")
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 4, 0.6)
	for x: int in range(w):
		var top: int = h - int(10.0 + prof[x] * 22.0)
		Painter.rect(img, x, top, 1, h - top, body)
		Painter.px(img, x, top, Color("#3a2030"))
	var stars: PackedVector3Array = PackedVector3Array()
	var x_at: float = 40.0
	var n: int = 0
	while x_at < float(w) - 40.0:
		var height: float = rng.randf_range(80.0, 145.0)
		var width: float = rng.randf_range(9.0, 17.0)
		var tip: Vector2 = _pillar(img, x_at, float(h) - 8.0, height, width, rng.randf_range(-0.3, 0.3), float(n) * 2.3 + 0.7, body, inner, rim, tip_col)
		# a young star buried part way up, glowing through the gas
		var sy: float = lerpf(tip.y, float(h) - 20.0, rng.randf_range(0.25, 0.55))
		var sx: float = lerpf(x_at, tip.x, (sy - (float(h) - 8.0)) / minf(-1.0, tip.y - (float(h) - 8.0)))
		for g: int in range(18):
			var a: float = float(g) * 2.399
			var r: float = 1.0 + fposmod(float(g) * 1.3, 4.0)
			Painter.px(img, int(sx + cos(a) * r), int(sy + sin(a) * r), Color("#3a1a2a") if r > 3.0 else Color("#6a3048"))
		stars.append(Vector3(sx, sy, 1.0))
		if n % 2 == 0:
			# a slimmer finger leaning off the big one
			_pillar(img, x_at + width + rng.randf_range(3.0, 8.0), float(h) - 8.0, height * rng.randf_range(0.45, 0.65), width * 0.55, rng.randf_range(0.0, 0.35), float(n) * 4.1, body, inner, rim, tip_col)
		x_at += width * 2.0 + rng.randf_range(60.0, 120.0)
		n += 1
	out["near"] = img
	out["near_stars"] = stars


# A drifting dust lane: dark, half-transparent, dithered blobs.
static func _paint_dust(rng: RandomNumberGenerator) -> Image:
	var w: int = int(DUST_W)
	var h: int = 36
	var img: Image = Painter.new_img(w, h)
	var f: PackedByteArray = Painter.fast_field(w, h, 40.0, 3, 2631)
	for y: int in range(h):
		var band: float = 1.0 - absf(float(y) - float(h) * 0.5) / (float(h) * 0.5)
		for x: int in range(w):
			var v: float = (float(f[y * w + x]) / 255.0 - 0.38) * 2.2 * band
			if v <= 0.0 or Painter.bayer(x, y) > v:
				continue
			img.set_pixel(x, y, Color(0.03, 0.015, 0.05, 0.62) if v < 0.6 else Color(0.06, 0.03, 0.06, 0.8))
	# a few lit motes riding the lane
	for m: int in range(30):
		Painter.px(img, rng.randi_range(0, w - 1), rng.randi_range(8, h - 8), Color(0.75, 0.5, 0.55, 0.6))
	return img


# Luminous filaments hanging from the top edge: teal and magenta streaks fading downward.
static func _paint_veil() -> Image:
	var w: int = 640
	var h: int = 42
	var img: Image = Painter.new_img(w, h)
	var f: PackedByteArray = Painter.fast_field(w, 8, 22.0, 3, 2633)
	var hue: PackedByteArray = Painter.fast_field(w, 8, 90.0, 2, 2634)
	var tealr: PackedColorArray = PackedColorArray([Color(0, 0, 0, 0), Color(0.1, 0.35, 0.42, 0.45), Color(0.16, 0.55, 0.62, 0.6), Color(0.4, 0.85, 0.86, 0.7)])
	var magr: PackedColorArray = PackedColorArray([Color(0, 0, 0, 0), Color(0.35, 0.1, 0.38, 0.45), Color(0.6, 0.2, 0.55, 0.6), Color(0.95, 0.55, 0.85, 0.7)])
	for x: int in range(w):
		var strength: float = clampf((float(f[w * 3 + x]) / 255.0 - 0.3) * 1.8, 0.0, 1.0)
		var reach: float = 10.0 + strength * 32.0
		var use_mag: bool = float(hue[w * 3 + x]) / 255.0 > 0.5
		for y: int in range(h):
			var v: float = strength * pow(maxf(0.0, 1.0 - float(y) / reach), 1.4)
			if v < 0.06:
				continue
			img.set_pixel(x, y, Painter.ramp_pick(magr if use_mag else tealr, v, x, y))
	return img


# Foreground gas clumps along the bottom, dark with a faint lit edge.
static func _paint_front(rng: RandomNumberGenerator) -> Image:
	var w: int = int(FRONT_W)
	var h: int = 40
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 6, 0.65)
	for x: int in range(w):
		var top: int = int(10.0 + (1.0 - prof[x]) * 26.0)
		var lit: bool = prof[x] > prof[posmod(x - 1, w)]
		for y: int in range(top, h):
			var c: Color = Color("#06030c")
			if y == top:
				c = Color("#5a2a4a") if lit else Color("#2a1428")
			elif y < top + 3 and Painter.bayer(x, y) < 0.3:
				c = Color("#140a1c")
			img.set_pixel(x, y, c)
	return img


# --- animation ----------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 30.0
	drift_a.y1 = 250.0
	drift_a.setup(26, rng, -10.0, -3.0, -3.0, 3.0)
	drift_a.par = 0.5
	drift_a.sway = 2.0
	drift_a.sway_hz = 0.6
	drift_a.cols = PackedColorArray([Color(1.0, 0.75, 0.45, 0.35), Color(1.0, 0.55, 0.85, 0.3), Color(0.6, 0.95, 0.95, 0.28)])
	drift_b.y0 = 30.0
	drift_b.y1 = 250.0
	drift_b.setup(18, rng, -4.0, -1.0, -1.0, 1.0)
	drift_b.par = 0.2
	drift_b.blink = 0.4
	drift_b.duty = 0.6
	drift_b.cols = PackedColorArray([Color(0.75, 0.8, 1.0, 0.45), Color(0.9, 0.7, 1.0, 0.35)])
	_ign_t = -1.0
	_jet_t = -1.0
	_shock_t = -1.0
	_ev_wait_a = rng.randf_range(4.0, 8.0)
	_ev_wait_b = rng.randf_range(7.0, 12.0)
	_ev_wait_c = rng.randf_range(12.0, 18.0)


func update() -> void:
	if _ign_t < 0.0:
		_ev_wait_a -= dl
		if _ev_wait_a <= 0.0:
			_ign_t = 0.0
			_ign_pos = Vector2(rng.randf_range(150.0, 460.0), rng.randf_range(40.0, 96.0) if rng.randf() < 0.6 else rng.randf_range(190.0, 232.0))
	else:
		_ign_t += dl
		if _ign_t > IGNITE_T:
			_ign_t = -1.0
			_ev_wait_a = rng.randf_range(10.0, 16.0)
	if _jet_t < 0.0:
		_ev_wait_b -= dl
		if _ev_wait_b <= 0.0:
			var stars: PackedVector3Array = meta.get("near_stars", PackedVector3Array())
			var o: float = off(NEAR_F, NEAR_W)
			for i: int in range(stars.size()):
				var sx: float = wrap_x(stars[i].x, o, NEAR_W)
				if sx > 140.0 and sx < 440.0:
					_jet_star = Vector2(stars[i].x, stars[i].y)
					_jet_t = 0.0
					break
			if _jet_t < 0.0:
				_ev_wait_b = 1.0
	else:
		_jet_t += dl
		if _jet_t > JET_T:
			_jet_t = -1.0
			_ev_wait_b = rng.randf_range(11.0, 18.0)
	if _shock_t < 0.0:
		_ev_wait_c -= dl
		if _ev_wait_c <= 0.0:
			_shock_t = 0.0
			_shock_y = rng.randf_range(100.0, 170.0)
	else:
		_shock_t += dl
		if _shock_t > SHOCK_T:
			_shock_t = -1.0
			_ev_wait_c = rng.randf_range(18.0, 26.0)


# A newborn star: a core pixel with diffraction spikes that breathe in and out.
func _star(p: Vector2, big: bool, k: float, col: Color) -> void:
	var x: float = floorf(p.x)
	var y: float = floorf(p.y)
	var l: float = floorf((3.0 if big else 2.0) + k * (4.0 if big else 2.0))
	var a: float = 0.25 + 0.45 * k
	var sc: Color = Color(col.r, col.g, col.b, a)
	bg.draw_rect(Rect2(x - l, y, l * 2.0 + 1.0, 1.0), sc)
	bg.draw_rect(Rect2(x, y - l, 1.0, l * 2.0 + 1.0), sc)
	bg.draw_rect(Rect2(x - 1.0, y - 1.0, 3.0, 3.0), Color(col.r, col.g, col.b, 0.35 + 0.3 * k))
	bg.draw_rect(Rect2(x, y, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.7 + 0.3 * k))


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	var shock_boost: float = 0.0
	var shock_x: float = -999.0
	if _shock_t >= 0.0:
		shock_x = lerpf(560.0, -120.0, _shock_t / SHOCK_T)
	layer("far", FAR_Y, FAR_F)
	# far newborn stars and the turning protoplanetary disks
	var o_f: float = off(FAR_F, FAR_W)
	var fstars: PackedVector3Array = meta.get("far_stars", PackedVector3Array())
	for i: int in range(fstars.size()):
		var sx: float = wrap_x(fstars[i].x, o_f, FAR_W)
		if sx < -8.0 or sx > 488.0:
			continue
		var k: float = 0.5 + 0.5 * sin(life * (1.1 + float(i % 4) * 0.37) + float(i) * 2.1)
		if shock_x > -900.0 and absf(sx - shock_x) < 30.0:
			k = 1.0
		var col: Color = Color(0.75, 0.95, 1.0) if i % 3 != 1 else Color(1.0, 0.8, 0.95)
		_star(Vector2(sx, FAR_Y + fstars[i].y), fstars[i].z > 0.5, k, col)
	var disks: PackedVector3Array = meta.get("disks", PackedVector3Array())
	for d: int in range(disks.size()):
		var dx: float = wrap_x(disks[d].x, o_f, FAR_W)
		if dx < -20.0 or dx > 500.0:
			continue
		var c: Vector2 = Vector2(floorf(dx), FAR_Y + disks[d].y)
		var r: float = disks[d].z
		bg.draw_rect(Rect2(c.x - r - 2.0, c.y, r * 2.0 + 5.0, 1.0), Color(0.25, 0.12, 0.3, 0.8))
		for j: int in range(22):
			var a: float = life * (0.9 - float(d) * 0.25) + float(j) * TAU / 22.0
			var rr: float = r * (0.55 + 0.45 * fposmod(float(j) * 0.37, 1.0))
			var q: Vector2 = c + Vector2(cos(a) * rr, sin(a) * rr * 0.3)
			var front: bool = sin(a) > 0.0
			bg.draw_rect(Rect2(q.floor(), Vector2.ONE), Color(1.0, 0.75, 0.5, 0.75) if front else Color(0.7, 0.4, 0.6, 0.45))
		bg.draw_rect(Rect2(c.x - 1.0, c.y - 1.0, 3.0, 3.0), Color(1.0, 0.9, 0.7, 0.8))
		bg.draw_rect(Rect2(c.x, c.y - 3.0, 1.0, 7.0), Color(1.0, 0.95, 0.85, 0.35))
	# rare event: a star ignites in the far nebula: a flash, long tapering spikes and a soft,
	# broken shell of light blowing outward
	if _ign_t >= 0.0:
		var k2: float = _ign_t / IGNITE_T
		var flash: float = clampf(1.0 - k2 * 1.6, 0.0, 1.0)
		var ip: Vector2 = _ign_pos.floor()
		var sl: float = 4.0 + 30.0 * sin(minf(1.0, k2 * 3.0) * PI * 0.5) * (1.0 - k2 * 0.7)
		for seg: int in range(3):
			var f: float = float(seg + 1) / 3.0
			var al: float = (0.55 - 0.15 * float(seg)) * (1.0 - k2)
			bg.draw_rect(Rect2(ip.x - sl * f, ip.y, sl * f * 2.0 + 1.0, 1.0), Color(1.0, 0.92, 1.0, al))
			bg.draw_rect(Rect2(ip.x, ip.y - sl * f * 0.6, 1.0, sl * f * 1.2 + 1.0), Color(1.0, 0.92, 1.0, al))
		bg.draw_circle(ip + Vector2(0.5, 0.5), 3.0 + 24.0 * sqrt(k2), Color(1.0, 0.55, 0.85, 0.12 * (1.0 - k2)))
		bg.draw_circle(ip + Vector2(0.5, 0.5), 2.0 + 9.0 * flash, Color(1.0, 0.8, 0.95, 0.55 * flash))
		for shell: int in range(2):
			var rr: float = (6.0 + 70.0 * sqrt(k2)) * (1.0 - 0.3 * float(shell))
			var sa: float = (0.55 - 0.2 * float(shell)) * (1.0 - k2)
			for d: int in range(32):
				var a: float = float(d) * TAU / 32.0 + sin(float(d) * 3.7) * 0.08 + float(shell) * 0.1
				if (d * 7 + shell) % 5 == 0:
					continue
				var q: Vector2 = ip + Vector2(cos(a), sin(a) * 0.85) * (rr + sin(float(d) * 2.3) * 3.0)
				bg.draw_rect(Rect2(q.floor(), Vector2(2.0, 2.0)), Color(1.0, 0.6, 0.9, sa) if (d + shell) % 2 == 0 else Color(0.6, 0.95, 1.0, sa))
		bg.draw_rect(Rect2(ip.x - 1.0, ip.y - 1.0, 3.0, 3.0), Color(1.0, 1.0, 1.0, 0.5 + 0.5 * (1.0 - k2)))
	layer("dust", 64.0, 0.18)
	_draw_currents()
	drift_draw(drift_b)
	layer("near", NEAR_Y, NEAR_F)
	var o_n: float = off(NEAR_F, NEAR_W)
	var nstars: PackedVector3Array = meta.get("near_stars", PackedVector3Array())
	for n: int in range(nstars.size()):
		var nx: float = wrap_x(nstars[n].x, o_n, NEAR_W)
		if nx < -10.0 or nx > 490.0:
			continue
		var k3: float = 0.5 + 0.5 * sin(life * 0.8 + float(n) * 1.9)
		if shock_x > -900.0 and absf(nx - shock_x) < 30.0:
			k3 = 1.0
		_star(Vector2(nx, NEAR_Y + nstars[n].y), true, k3, Color(1.0, 0.85, 0.6))
	# rare event: bipolar jets from a young star in the near pillars
	if _jet_t >= 0.0:
		var jx: float = floorf(wrap_x(_jet_star.x, o_n, NEAR_W))
		var jy: float = NEAR_Y + _jet_star.y
		var k4: float = _jet_t / JET_T
		var grow: float = minf(1.0, _jet_t / 0.45)
		var fade: float = 1.0 - clampf((k4 - 0.6) / 0.4, 0.0, 1.0)
		var up: float = (jy - 30.0) * grow
		var dn: float = (250.0 - jy) * grow
		bg.draw_rect(Rect2(jx, jy - up, 1.0, up), Color(0.7, 1.0, 1.0, 0.45 * fade))
		bg.draw_rect(Rect2(jx - 1.0, jy - up, 3.0, up), Color(0.4, 0.85, 0.95, 0.12 * fade))
		bg.draw_rect(Rect2(jx, jy, 1.0, dn), Color(0.7, 1.0, 1.0, 0.45 * fade))
		bg.draw_rect(Rect2(jx - 1.0, jy, 3.0, dn), Color(0.4, 0.85, 0.95, 0.12 * fade))
		for kn: int in range(3):
			var dist: float = fposmod(_jet_t * 70.0 + float(kn) * 30.0, 100.0) + 6.0
			if dist < up:
				bg.draw_rect(Rect2(jx - 1.0, jy - dist - 1.0, 3.0, 3.0), Color(0.85, 1.0, 1.0, 0.6 * fade))
			if dist < dn:
				bg.draw_rect(Rect2(jx - 1.0, jy + dist - 1.0, 3.0, 3.0), Color(0.85, 1.0, 1.0, 0.6 * fade))
		bg.draw_circle(Vector2(jx + 0.5, jy + 0.5), 4.0, Color(1.0, 0.9, 0.7, 0.35 * fade))
	layer("dust", 186.0, 0.36, Color(1.0, 1.0, 1.0, 0.9), 301.0)
	layer_wobble("veil", VEIL_Y, VEIL_F, 3, 1.5, 0.35, 1.3)
	layer("front", FRONT_Y, FRONT_F)
	fx_draw()
	drift_draw(drift_a)
	# rare event: a supernova shock front sweeping right to left across the sky, the gas
	# glittering where it passes
	if _shock_t >= 0.0:
		var k5: float = _shock_t / SHOCK_T
		var amp: float = sin(k5 * PI)
		var cc: Vector2 = Vector2(shock_x + 380.0, _shock_y)
		bg.draw_arc(cc, 380.0, PI * 0.72, PI * 1.28, 48, Color(0.75, 0.95, 1.0, 0.14 * amp), 1.0)
		bg.draw_arc(cc, 384.0, PI * 0.74, PI * 1.26, 48, Color(1.0, 0.6, 0.9, 0.08 * amp), 3.0)
		bg.draw_arc(cc, 392.0, PI * 0.76, PI * 1.24, 48, Color(0.75, 0.95, 1.0, 0.04 * amp), 8.0)
		for g: int in range(18):
			var a: float = PI + (fposmod(float(g) * 0.61 + floorf(life * 12.0) * 0.37, 1.0) - 0.5) * 0.52
			var q: Vector2 = cc + Vector2.from_angle(a) * (380.0 + fposmod(float(g) * 5.3, 14.0))
			bg.draw_rect(Rect2(q.floor(), Vector2.ONE), Color(0.9, 1.0, 1.0, 0.5 * amp))


# Slow luminous gas currents: dashed sine streaks flowing left near the top and bottom of
# the screen (and one very faint one through the middle), batched into one draw each.
func _draw_currents() -> void:
	for c: int in range(3):
		var cy: float = CUR_Y[c]
		var amp: float = CUR_AMP[c]
		var alpha: float = CUR_A[c]
		var flow: float = life * (26.0 + float(c) * 8.0)
		var segs: PackedVector2Array = PackedVector2Array()
		var x: float = -fposmod(flow, 14.0)
		while x < 480.0:
			var y0: float = cy + sin(x * 0.018 + float(c) * 2.0 + life * 0.3) * amp
			var y1: float = cy + sin((x + 7.0) * 0.018 + float(c) * 2.0 + life * 0.3) * amp
			segs.append(Vector2(floorf(x) + 0.5, floorf(y0) + 0.5))
			segs.append(Vector2(floorf(x + 7.0) + 0.5, floorf(y1) + 0.5))
			x += 14.0
		bg.draw_multiline(segs, Color(0.55, 0.95, 0.95, alpha) if c != 1 else Color(1.0, 0.6, 0.9, alpha), 1.0)
