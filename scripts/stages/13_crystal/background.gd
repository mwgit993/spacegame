extends "res://scripts/stages/stage_background.gd"

# CRYSTAL CAVE: a near-black violet cavern grown over with amethyst. Far away, dim geode walls
# glow from within; nearer, clusters of amethyst, rose, emerald and gold crystal hang from the
# ceiling and rise from the floor; light leaking through ceiling cracks refracts into faint
# rainbow shafts, facets glint and luminous motes drift.
#
# Layers (paint(), worker thread):
#   "sky"       480x270 at (0,0): the void, a mottled distant wall, deep glows, glitter
#   "far"       768x230 at y 28, parallax 0.06: dim crystal walls top and bottom, geodes
#   "mid"       640x230 at y 28, parallax 0.22: coloured crystal clusters (playfield centre clear)
#   "near_top"  512x22 at y 28, parallax 0.8: ceiling rock with bright crystal points
#   "near_bot"  512x26 at y 232, parallax 0.8: floor rock with bright crystal points
# Animation: rainbow light shafts from the far ceiling cracks, pulsing geodes, sparkles on
# crystal tips, motes. Rare events: a white beam splitting into a rainbow fan (_ev_a), a shard
# breaking off a hanging cluster and shattering on the floor (_ev_b), and a chain of geodes
# lighting up one after another (_ev_c). The playfield stays dark and low in contrast.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const FAR_Y: float = 28.0
const MID_Y: float = 28.0
const NEAR_TOP_Y: float = 28.0
const NEAR_BOT_Y: float = 232.0
const RAINBOW: PackedColorArray = [Color(1.0, 0.25, 0.3), Color(1.0, 0.6, 0.2), Color(1.0, 0.95, 0.3), Color(0.3, 1.0, 0.45), Color(0.3, 0.6, 1.0), Color(0.7, 0.35, 1.0)]
const GEODE_COLS: PackedColorArray = [Color(0.75, 0.35, 1.0), Color(1.0, 0.35, 0.75), Color(0.3, 1.0, 0.6), Color(1.0, 0.8, 0.3)]

const FAR_RAMP: PackedColorArray = [Color("#0a0612"), Color("#1c1032"), Color("#281846"), Color("#36225e"), Color("#523888")]
const MID_A: PackedColorArray = [Color("#0c0616"), Color("#24104a"), Color("#3e1e6c"), Color("#5e3496"), Color("#9a74cc")]
const MID_R: PackedColorArray = [Color("#12040e"), Color("#3e0a2e"), Color("#66164e"), Color("#963274"), Color("#cc7cae")]
const MID_E: PackedColorArray = [Color("#03100b"), Color("#09321f"), Color("#10523a"), Color("#22825a"), Color("#74c8a2")]
const MID_G: PackedColorArray = [Color("#120b03"), Color("#3e2c0e"), Color("#644a18"), Color("#927028"), Color("#cfb676")]
const MID_RAMPS: Array[PackedColorArray] = [MID_A, MID_R, MID_E, MID_G]
const NEAR_A: PackedColorArray = [Color("#12081f"), Color("#3a1868"), Color("#6a30a8"), Color("#a870e8"), Color("#f0dcff")]
const NEAR_R: PackedColorArray = [Color("#1c0614"), Color("#6a1048"), Color("#b02878"), Color("#f070b8"), Color("#ffe0f4")]
const NEAR_E: PackedColorArray = [Color("#04140e"), Color("#0e5a3a"), Color("#1ca068"), Color("#5ae8a8"), Color("#e0fff0")]
const NEAR_G: PackedColorArray = [Color("#1a1004"), Color("#7a5410"), Color("#c8901c"), Color("#ffd25a"), Color("#fffae0")]
const NEAR_RAMPS: Array[PackedColorArray] = [NEAR_A, NEAR_R, NEAR_E, NEAR_G]

var _spark_pos: PackedVector2Array = PackedVector2Array()   # active sparkles (screen space)
var _spark_age: PackedFloat32Array = PackedFloat32Array()
var _spark_t: float = 0.2
var _beam_x: float = 200.0
var _shard_layer_x: float = 0.0
var _shard_y0: float = 60.0
var _shard_col: int = 0
var _bits: PackedVector4Array = PackedVector4Array()       # shatter bits: x, y, vx, vy
var _bits_age: float = 0.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 13013
	var out: Dictionary = {}
	out["sky"] = _paint_sky(rng)
	_paint_far(rng, out)
	_paint_mid(rng, out)
	out["near_top"] = _paint_near(rng, 22, true)
	out["near_bot"] = _paint_near(rng, 26, false)
	return out


static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#07040c"))
	Painter.vgrad(sky, 22, 258, PackedColorArray([Color("#07040c"), Color("#090510"), Color("#0c0615"), Color("#10081b"), Color("#130a21"), Color("#170c27")]), 0.45)
	# Deep glows far behind the walls (magenta, violet, a hint of emerald), dithered.
	var glows: Array[Vector4] = [Vector4(120.0, 120.0, 80.0, 0.0), Vector4(330.0, 160.0, 95.0, 1.0), Vector4(430.0, 80.0, 60.0, 2.0)]
	var gcols: PackedColorArray = [Color("#1e0c2e"), Color("#24082a"), Color("#0a1e1c")]
	for g: Vector4 in glows:
		for y: int in range(maxi(24, int(g.y - g.z)), mini(256, int(g.y + g.z))):
			for x: int in range(maxi(0, int(g.x - g.z)), mini(480, int(g.x + g.z))):
				var d: float = Vector2(float(x) - g.x, float(y) - g.y).length() / g.z
				if d < 1.0 and Painter.bayer(x, y) < (1.0 - d) * 0.75:
					Painter.blend_px(sky, x, y, gcols[int(g.w)], 0.6)
	# A mottled distant wall.
	var nf: PackedByteArray = Painter.fast_field(480, 236, 22.0, 3, 13014)
	for y2: int in range(24, 256):
		for x2: int in range(480):
			var v: float = float(nf[(y2 - 24) * 480 + x2]) / 255.0
			if v > 0.66 and Painter.bayer(x2, y2) < (v - 0.66) * 3.0:
				Painter.blend_px(sky, x2, y2, Color("#22143a"), 0.35)
			elif v < 0.3 and Painter.bayer(x2, y2) < (0.3 - v) * 3.0:
				Painter.blend_px(sky, x2, y2, Color("#030206"), 0.5)
	# Glitter.
	for i: int in range(110):
		var c: Color = Color("#2e2048")
		var r: float = rng.randf()
		if r > 0.6:
			c = Color("#4a3470")
		if r > 0.88:
			c = Color("#7a5aa8")
		if r > 0.97:
			c = Color("#1e5a46") if i % 2 == 0 else Color("#6a5020")
		Painter.px(sky, rng.randi_range(0, 479), rng.randi_range(30, 250), c)
	return sky


static func _paint_far(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = 768
	var h: int = 230
	var img: Image = Painter.new_img(w, h)
	var tp: PackedFloat32Array = Painter.profile(w, rng, 5, 4, 0.55)
	var bp: PackedFloat32Array = Painter.profile(w, rng, 5, 4, 0.55)
	var rock: Color = Color("#0b0713")
	var tops: PackedFloat32Array = PackedFloat32Array()
	var bots: PackedFloat32Array = PackedFloat32Array()
	tops.resize(w)
	bots.resize(w)
	for x: int in range(w):
		var t: int = int(5.0 + tp[x] * 22.0)
		var b: int = h - int(8.0 + bp[x] * 30.0)
		tops[x] = float(t)
		bots[x] = float(b)
		Painter.vline(img, x, 0, t, rock)
		Painter.px(img, x, t, Color("#1e1430"))
		Painter.vline(img, x, b, h - 1, rock)
		Painter.px(img, x, b, Color("#241838"))
	# Hanging and rising crystals, dim and desaturated with distance.
	for i: int in range(42):
		var cx: int = rng.randi_range(0, w - 1)
		Painter.crystal(img, float(cx), tops[cx] - 1.0, PI + rng.randf_range(-0.35, 0.35), rng.randf_range(10.0, 50.0), rng.randf_range(4.0, 9.0), FAR_RAMP)
	for i2: int in range(48):
		var bx: int = rng.randi_range(0, w - 1)
		Painter.crystal(img, float(bx), bots[bx] + 1.0, rng.randf_range(-0.4, 0.4), rng.randf_range(10.0, 64.0), rng.randf_range(4.0, 10.0), FAR_RAMP)
	# Geodes: rock lumps split open around a ring of crystal points with a glowing heart.
	var geodes: PackedVector3Array = PackedVector3Array()
	for g: int in range(9):
		var gx: float = 40.0 + float(g) * 82.0 + rng.randf_range(-16.0, 16.0)
		var top_side: bool = g % 3 == 1
		var gy: float = (tops[int(gx) % w] + 6.0) if top_side else (bots[int(gx) % w] - 2.0)
		var rx: float = rng.randf_range(12.0, 17.0)
		var ry: float = rx * 0.75
		var ci: int = g % 4
		var lining: Color = [Color("#7a44b8"), Color("#b0387e"), Color("#2a9a6a"), Color("#b08a30")][ci]
		var lining_hi: Color = [Color("#c49aff"), Color("#f08ac8"), Color("#8ae8c0"), Color("#f0d890")][ci]
		var heart: Color = [Color("#2a1248"), Color("#3a0e30"), Color("#0c3022"), Color("#3a2a0c")][ci]
		# Lumpy outer rock with a lit upper-left face.
		var p2: float = rng.randf_range(0.0, TAU)
		var p3: float = rng.randf_range(0.0, TAU)
		var outer: PackedVector2Array = PackedVector2Array()
		var outer_lit: PackedVector2Array = PackedVector2Array()
		for k: int in range(22):
			var a: float = TAU * float(k) / 22.0
			var rr: float = 1.0 + 0.12 * sin(3.0 * a + p2) + 0.08 * sin(5.0 * a + p3)
			outer.append(Vector2(gx + cos(a) * rx * rr, gy + sin(a) * ry * rr))
			outer_lit.append(Vector2(gx - 1.5 + cos(a) * (rx * rr - 2.0), gy - 1.5 + sin(a) * (ry * rr - 2.0)))
		Painter.poly(img, outer, Color("#060409"))
		var inner_rock: PackedVector2Array = PackedVector2Array()
		for q: Vector2 in outer:
			inner_rock.append(Vector2(gx, gy) + (q - Vector2(gx, gy)) * 0.93)
		Painter.poly(img, inner_rock, Color("#1a1226"))
		Painter.poly(img, outer_lit, Color("#221a32"))
		# Jagged cavity lined with crystal teeth pointing in.
		var cav: PackedVector2Array = PackedVector2Array()
		var jags: int = 12
		for k2: int in range(jags * 2):
			var a2: float = TAU * float(k2) / float(jags * 2)
			var rr2: float = 0.66 if k2 % 2 == 0 else 0.5
			cav.append(Vector2(gx + cos(a2) * rx * rr2, gy + sin(a2) * ry * rr2))
		Painter.poly(img, cav, lining)
		for k3: int in range(jags):
			var a3: float = TAU * float(k3) / float(jags)
			var base_a: Vector2 = Vector2(gx + cos(a3 - 0.18) * rx * 0.6, gy + sin(a3 - 0.18) * ry * 0.6)
			var base_b: Vector2 = Vector2(gx + cos(a3 + 0.18) * rx * 0.6, gy + sin(a3 + 0.18) * ry * 0.6)
			var tip: Vector2 = Vector2(gx + cos(a3) * rx * 0.22, gy + sin(a3) * ry * 0.22)
			Painter.poly(img, PackedVector2Array([base_a, base_b, tip]), lining_hi if k3 % 3 == 0 else lining)
		Painter.ellipse(img, gx, gy, rx * 0.2, ry * 0.2, heart)
		Painter.px(img, int(gx) - 1, int(gy) - 1, lining_hi)
		geodes.append(Vector3(gx, gy, float(ci)))
	# Cracks in the far ceiling where light gets in.
	var cracks: PackedFloat32Array = PackedFloat32Array()
	for c: int in range(4):
		var crx: int = 90 + c * 192 + rng.randi_range(-30, 30)
		var ct: int = int(tops[crx % w])
		Painter.rect(img, crx - 2, ct - 3, 5, 3, Color("#3a2e52"))
		Painter.rect(img, crx - 1, ct - 4, 3, 5, Color("#5a4a7a"))
		cracks.append(float(crx))
	out["far"] = img
	out["geodes"] = geodes
	out["cracks"] = cracks
	out["far_tops"] = tops


static func _paint_mid(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = 640
	var h: int = 230
	var img: Image = Painter.new_img(w, h)
	var tips: PackedVector2Array = PackedVector2Array()
	var hang: PackedVector3Array = PackedVector3Array()
	var x: float = 20.0
	var n: int = 0
	while x < float(w) - 20.0:
		var top: bool = (n % 2 == 0) != (rng.randf() < 0.25)
		var ramp_i: int = rng.randi_range(0, MID_RAMPS.size() - 1)
		var ramp: PackedColorArray = MID_RAMPS[ramp_i]
		var by: float = 0.0 if top else float(h)
		# Rock mound the cluster grows from.
		Painter.ellipse(img, x, by, rng.randf_range(14.0, 22.0), rng.randf_range(6.0, 10.0), Color("#0d0915"))
		Painter.ellipse(img, x - 2.0, by + (1.0 if top else -1.0), 10.0, 4.0, Color("#16101f"))
		var count: int = rng.randi_range(3, 6)
		for k: int in range(count):
			var spread: float = (float(k) / float(maxi(1, count - 1)) - 0.5) * 1.1 + rng.randf_range(-0.12, 0.12)
			var length: float = rng.randf_range(16.0, 52.0) if top else rng.randf_range(18.0, 62.0)
			if k == count / 2:
				length *= 1.25
			var bx: float = x + spread * 14.0
			var ang: float = (PI - spread) if top else spread
			var tip: Vector2 = Painter.crystal(img, bx, by + (2.0 if top else -2.0), ang, length, rng.randf_range(5.0, 9.0), ramp)
			tips.append(tip)
			if top:
				hang.append(Vector3(tip.x, tip.y, float(ramp_i)))
		x += rng.randf_range(52.0, 86.0)
		n += 1
	out["mid"] = img
	out["mid_tips"] = tips
	out["mid_hang"] = hang


static func _paint_near(rng: RandomNumberGenerator, h: int, ceiling: bool) -> Image:
	var w: int = 512
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 7, 0.6)
	var ramp: PackedColorArray = PackedColorArray([Color("#07040c"), Color("#0e0916"), Color("#151020"), Color("#1e162c")])
	for x: int in range(w):
		var depth: int = int(3.0 + prof[x] * 8.0)
		for k: int in range(depth):
			var y: int = k if ceiling else h - 1 - k
			img.set_pixel(x, y, Painter.ramp_pick(ramp, 0.25 + float(depth - k) * 0.06, x, y))
		var edge: int = depth if ceiling else h - 1 - depth
		img.set_pixel(x, edge, Color("#2a2040"))
	# Bright crystal points along the edge (bright detail lives at the screen edges).
	for i: int in range(34):
		var cx: int = rng.randi_range(4, w - 5)
		var depth2: float = 3.0 + prof[cx] * 8.0
		var ramp_c: PackedColorArray = NEAR_RAMPS[rng.randi_range(0, NEAR_RAMPS.size() - 1)]
		var length: float = rng.randf_range(5.0, float(h) - depth2 - 2.0)
		if ceiling:
			Painter.crystal(img, float(cx), depth2, PI + rng.randf_range(-0.4, 0.4), length, rng.randf_range(3.0, 5.0), ramp_c)
		else:
			Painter.crystal(img, float(cx), float(h) - depth2 - 1.0, rng.randf_range(-0.4, 0.4), length, rng.randf_range(3.0, 5.0), ramp_c)
	return img


# --- Animation -------------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 34.0
	drift_a.y1 = 248.0
	drift_a.setup(30, rng, -10.0, -3.0, -5.0, 2.0)
	drift_a.par = 0.3
	drift_a.sway = 3.0
	drift_a.sway_hz = 0.7
	drift_a.blink = 0.35
	drift_a.duty = 0.7
	drift_a.cols = PackedColorArray([Color(0.8, 0.5, 1.0, 0.55), Color(1.0, 0.5, 0.8, 0.45), Color(0.45, 1.0, 0.7, 0.45), Color(1.0, 0.85, 0.45, 0.45)])
	drift_b.y0 = 34.0
	drift_b.y1 = 248.0
	drift_b.setup(20, rng, -5.0, -1.0, -3.0, 3.0)
	drift_b.par = 0.12
	drift_b.cols = PackedColorArray([Color(0.55, 0.35, 0.8, 0.3), Color(0.4, 0.25, 0.6, 0.35)])
	_spark_pos.resize(0)
	_spark_age.resize(0)
	_bits.resize(0)
	bg._ev_a.arm(rng, 14.0, 22.0, 4.0, 8.0)    # white beam split into a rainbow fan
	bg._ev_b.arm(rng, 11.0, 18.0, 8.0, 12.0)   # shard falls and shatters
	bg._ev_c.arm(rng, 16.0, 26.0, 12.0, 17.0)  # geode chain lights up


func update() -> void:
	# Sparkles on crystal tips.
	var i: int = 0
	while i < _spark_age.size():
		_spark_age[i] += dl
		var sp: Vector2 = _spark_pos[i]
		sp.x -= ds * 0.22
		_spark_pos[i] = sp
		if _spark_age[i] > 0.45:
			_spark_age.remove_at(i)
			_spark_pos.remove_at(i)
			continue
		i += 1
	_spark_t -= dl
	if _spark_t <= 0.0:
		_spark_t = rng.randf_range(0.12, 0.3)
		var tips: PackedVector2Array = meta.get("mid_tips", PackedVector2Array())
		if not tips.is_empty() and _spark_age.size() < 7:
			var o: float = off(0.22, 640.0)
			var t: Vector2 = tips[rng.randi_range(0, tips.size() - 1)]
			var sx: float = wrap_x(t.x, o, 640.0)
			if sx > 0.0 and sx < 480.0:
				_spark_pos.append(Vector2(sx, MID_Y + t.y))
				_spark_age.append(0.0)
	# Event A: the beam comes through a crack visible on screen.
	if bg._ev_a.tick(dl, rng):
		bg._ev_a.dur = 3.4
		_beam_x = rng.randf_range(170.0, 400.0)
	# Event B: a shard breaks off a hanging cluster.
	if bg._ev_b.tick(dl, rng):
		bg._ev_b.dur = 2.4
		var hang: PackedVector3Array = meta.get("mid_hang", PackedVector3Array())
		bg._ev_b.k = -1
		if not hang.is_empty():
			var o2: float = off(0.22, 640.0)
			var start: int = rng.randi_range(0, hang.size() - 1)
			for n: int in range(hang.size()):
				var hv: Vector3 = hang[(start + n) % hang.size()]
				var sx2: float = wrap_x(hv.x, o2, 640.0)
				if sx2 > 60.0 and sx2 < 440.0:
					bg._ev_b.k = 1
					_shard_layer_x = hv.x
					_shard_y0 = MID_Y + hv.y
					_shard_col = int(hv.z)
					break
		_bits.resize(0)
		if bg._ev_b.k < 0:
			bg._ev_b.on = false
			bg._ev_b.t = 3.0
	if bg._ev_b.on and bg._ev_b.k > 0:
		var fall_y: float = _shard_y0 + 0.5 * 260.0 * bg._ev_b.t * bg._ev_b.t
		if fall_y >= 250.0 and _bits.is_empty():
			var sx3: float = wrap_x(_shard_layer_x, off(0.22, 640.0), 640.0)
			for b: int in range(12):
				var a: float = PI + float(b) / 11.0 * PI
				_bits.append(Vector4(sx3, 248.0, cos(a) * rng.randf_range(30.0, 80.0), sin(a) * rng.randf_range(40.0, 90.0)))
			_bits_age = 0.0
			bg._ev_b.k = 2
	if not _bits.is_empty():
		_bits_age += dl
		for j: int in range(_bits.size()):
			var v: Vector4 = _bits[j]
			v.w += 180.0 * dl
			v.x += v.z * dl - ds * 0.22
			v.y += v.w * dl
			_bits[j] = v
		if _bits_age > 0.9:
			_bits.resize(0)
	if bg._ev_c.tick(dl, rng):
		bg._ev_c.dur = 3.2


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	_draw_shafts()

	var o_f: float = off(0.06, 768.0)
	layer("far", FAR_Y, 0.06)
	# Geodes breathing light (and the chain event).
	var geodes: PackedVector3Array = meta.get("geodes", PackedVector3Array())
	var chain_u: float = bg._ev_c.t / bg._ev_c.dur if bg._ev_c.on else -1.0
	for g: int in range(geodes.size()):
		var gx: float = wrap_x(geodes[g].x, o_f, 768.0)
		if gx < -20.0 or gx > 500.0:
			continue
		var col: Color = GEODE_COLS[int(geodes[g].z)]
		var pulse: float = 0.5 + 0.5 * sin(life * 0.9 + float(g) * 1.7)
		var a: float = 0.05 + 0.05 * pulse
		if chain_u >= 0.0:
			var hit: float = chain_u * 1.3 - gx / 480.0
			if hit > 0.0 and hit < 0.35:
				a += 0.35 * sin(hit / 0.35 * PI)
		var c: Vector2 = Vector2(floorf(gx), FAR_Y + geodes[g].y)
		bg.draw_circle(c, 9.0, Color(col.r, col.g, col.b, a * 0.5))
		bg.draw_circle(c, 4.0, Color(col.r, col.g, col.b, a))
		if a > 0.2:
			bg.draw_rect(Rect2(c.x - 1.0, c.y - 1.0, 2.0, 2.0), Color(1.0, 1.0, 1.0, a))

	drift_draw(drift_b)
	layer("mid", MID_Y, 0.22)
	for s: int in range(_spark_pos.size()):
		var k: float = sin(_spark_age[s] / 0.45 * PI)
		var p: Vector2 = Vector2(floorf(_spark_pos[s].x), floorf(_spark_pos[s].y))
		var arm: float = 1.0 + floorf(k * 2.5)
		var sc: Color = Color(1.0, 0.95, 1.0, 0.85 * k)
		bg.draw_rect(Rect2(p.x - arm, p.y, arm * 2.0 + 1.0, 1.0), sc)
		bg.draw_rect(Rect2(p.x, p.y - arm, 1.0, arm * 2.0 + 1.0), sc)
	_draw_refraction()
	layer("near_top", NEAR_TOP_Y, 0.8)
	layer("near_bot", NEAR_BOT_Y, 0.8)
	_draw_shard()
	drift_draw(drift_a)


# Faint rainbow shafts slanting down from the far ceiling cracks.
func _draw_shafts() -> void:
	var cracks: PackedFloat32Array = meta.get("cracks", PackedFloat32Array())
	var tops: PackedFloat32Array = meta.get("far_tops", PackedFloat32Array())
	var o: float = off(0.06, 768.0)
	for c: int in range(cracks.size()):
		var cx: float = wrap_x(cracks[c], o, 768.0)
		if cx < -40.0 or cx > 640.0:
			continue
		var top_y: float = FAR_Y + (tops[int(cracks[c]) % 768] if not tops.is_empty() else 20.0) - 2.0
		var breathe: float = 0.6 + 0.4 * sin(life * 0.4 + float(c) * 2.1)
		var sway: float = sin(life * 0.15 + float(c)) * 10.0
		for b: int in range(RAINBOW.size()):
			var col: Color = RAINBOW[b]
			var x0: float = cx + float(b) * 1.0
			var x1: float = cx - 70.0 + sway + float(b) * 7.0
			var sc: Color = Color(col.r, col.g, col.b, 0.028 * breathe)
			# draw_primitive draws the quad without the triangulation draw_colored_polygon does.
			bg.draw_primitive(PackedVector2Array([Vector2(x0, top_y), Vector2(x0 + 1.5, top_y), Vector2(x1 + 7.0, 250.0), Vector2(x1, 250.0)]), PackedColorArray([sc, sc, sc, sc]), PackedVector2Array())


func _draw_refraction() -> void:
	if not bg._ev_a.on:
		return
	var u: float = bg._ev_a.t / bg._ev_a.dur
	var ramp: float = minf(1.0, minf(u * 5.0, (1.0 - u) * 4.0))
	var top: Vector2 = Vector2(_beam_x, 30.0)
	var p: Vector2 = Vector2(_beam_x - 26.0, 104.0)
	bg.draw_line(top, p, Color(1.0, 1.0, 1.0, 0.14 * ramp), 3.0)
	bg.draw_line(top, p, Color(1.0, 1.0, 1.0, 0.4 * ramp), 1.0)
	for b: int in range(RAINBOW.size()):
		var col: Color = RAINBOW[b]
		var a0: float = PI * 0.62 + float(b) * 0.075
		var d0: Vector2 = Vector2.from_angle(a0) * 260.0
		var d1: Vector2 = Vector2.from_angle(a0 + 0.07) * 260.0
		var fc: Color = Color(col.r, col.g, col.b, 0.07 * ramp)
		bg.draw_primitive(PackedVector2Array([p, p + d0, p + d1]), PackedColorArray([fc, fc, fc]), PackedVector2Array())
	var fl: float = 0.6 + 0.4 * sin(life * 20.0)
	bg.draw_circle(p, 4.0, Color(1.0, 1.0, 1.0, 0.35 * ramp * fl))
	bg.draw_rect(Rect2(p.x - 1.0, p.y - 1.0, 3.0, 3.0), Color(1.0, 1.0, 1.0, 0.8 * ramp))


func _draw_shard() -> void:
	if bg._ev_b.on and bg._ev_b.k == 1:
		var sx: float = wrap_x(_shard_layer_x, off(0.22, 640.0), 640.0)
		var y: float = _shard_y0 + 0.5 * 260.0 * bg._ev_b.t * bg._ev_b.t
		var ramp: PackedColorArray = NEAR_RAMPS[_shard_col % NEAR_RAMPS.size()]
		var pts: PackedVector2Array = PackedVector2Array([Vector2(sx, y - 8.0), Vector2(sx + 2.0, y - 2.0), Vector2(sx, y + 3.0), Vector2(sx - 2.0, y - 2.0)])
		bg.draw_colored_polygon(pts, ramp[2])
		bg.draw_line(Vector2(sx - 1.0, y - 6.0), Vector2(sx - 1.0, y), ramp[4], 1.0)
		bg.draw_rect(Rect2(sx - 1.0, y - 12.0, 1.0, 3.0), Color(ramp[3].r, ramp[3].g, ramp[3].b, 0.4))
	if not _bits.is_empty():
		var fade: float = 1.0 - clampf(_bits_age / 0.9, 0.0, 1.0)
		var ramp2: PackedColorArray = NEAR_RAMPS[_shard_col % NEAR_RAMPS.size()]
		for j: int in range(_bits.size()):
			var c: Color = ramp2[3] if j % 3 != 0 else Color.WHITE
			bg.draw_rect(Rect2(floorf(_bits[j].x), floorf(_bits[j].y), 1.0 + float(j % 2), 1.0), Color(c.r, c.g, c.b, fade))
