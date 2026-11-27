extends "res://scripts/stages/stage_background.gd"

# STAGE 17 background: the rim of a black hole. Its shadow sits high in the sky, ringed by a
# thin photon halo, with the far side of the accretion disk lensed up over the top of it; the
# disk itself turns (clumps of hot gas orbit, faster near the middle), and stars drift inward,
# smearing into longer streaks as they fall. Below, a debris belt lit orange by the disk.
# Rare events: a relativistic jet flares from the poles, a star is torn into a streamer and
# swallowed, and a gravitational-wave ripple rolls out across the sky.
#
# Layers: "sky" 480x270; "galaxies" 768x190 at y 30 (0.02); "disk_back"/"disk_front" 320x100
# at the hole; "hole" 96x96 at the hole; "belt" 768x58 at y 212 (0.6).

const Painter = preload("res://scripts/stage_bg_painter.gd")

const BH: Vector2 = Vector2(300.0, 92.0)
const SHADOW_R: float = 21.0
const DISK_IN: float = 30.0
const DISK_OUT: float = 122.0
const SQUASH: float = 0.16
const TILT: float = -0.1
const CLUMPS: int = 96
const INFALL: int = 34
const GAL_F: float = 0.02
const BELT_Y: float = 212.0
const BELT_F: float = 0.6

var _cr: PackedFloat32Array = PackedFloat32Array()
var _ca: PackedFloat32Array = PackedFloat32Array()
var _ir: PackedFloat32Array = PackedFloat32Array()
var _ia: PackedFloat32Array = PackedFloat32Array()
var _jet_t: float = -1.0
var _jet_wait: float = 7.0
var _tde_t: float = -1.0
var _tde_wait: float = 4.0
var _tde_trail: PackedVector2Array = PackedVector2Array()
var _tde_r: float = 0.0
var _tde_a: float = 0.0
var _rip_t: float = -1.0
var _rip_wait: float = 9.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1717
	var out: Dictionary = {}

	# Sky: black with faint violet nebulae; stars near the hole are lensed into arcs.
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#020104"))
	var neb: PackedByteArray = Painter.fast_field(480, 270, 120.0, 4, 1717)
	var neb_ramp: PackedColorArray = PackedColorArray([Color("#020104"), Color("#050209"), Color("#09040f"), Color("#0e0617"), Color("#140820")])
	for y: int in range(22, 260):
		for x: int in range(480):
			var v: float = float(neb[y * 480 + x]) / 255.0
			sky.set_pixel(x, y, Painter.ramp_pick(neb_ramp, clampf((v - 0.35) * 2.0, 0.0, 1.0), x, y))
	# a warm glow round the hole
	var glow: PackedColorArray = PackedColorArray([Color("#0e0617"), Color("#170a1a"), Color("#22100f"), Color("#2e160c")])
	for y2: int in range(22, 200):
		for x2: int in range(120, 480):
			var q: Vector2 = Vector2(float(x2) - BH.x, (float(y2) - BH.y) * 1.6)
			var d: float = q.length()
			if d < 150.0 and d > SHADOW_R:
				var k: float = pow(1.0 - d / 150.0, 1.6)
				if Painter.bayer(x2, y2) < k * 1.4:
					sky.set_pixel(x2, y2, Painter.ramp_pick(glow, k * 1.2, x2, y2))
	for i: int in range(150):
		var sp: Vector2 = Vector2(rng.randf_range(0.0, 480.0), rng.randf_range(24.0, 256.0))
		var rel: Vector2 = sp - BH
		var dist: float = rel.length()
		var bright: bool = i % 6 == 0
		var col: Color = Color("#c8c0e8") if bright else Color("#5a5478")
		if dist < 34.0:
			continue
		if dist < 120.0:
			# lensed: stretched into a short arc round the hole, longer the closer it is
			var arc: float = clampf(4.0 / (dist - 22.0), 0.01, 0.14)
			var a0: float = rel.angle()
			var n: int = maxi(2, int(arc * dist * 2.0))
			for s: int in range(n + 1):
				var a: float = a0 + lerpf(-arc, arc, float(s) / float(n))
				Painter.px(sky, int(BH.x + cos(a) * dist), int(BH.y + sin(a) * dist), col.darkened(0.25))
		else:
			Painter.px(sky, int(sp.x), int(sp.y), col)
	# a faint Einstein ring
	for a2: int in range(240):
		var ang: float = float(a2) / 240.0 * TAU
		if Painter.bayer(a2, 1) < 0.5:
			Painter.px(sky, int(BH.x + cos(ang) * 36.0), int(BH.y + sin(ang) * 36.0), Color("#2a1e38"))
	out["sky"] = sky

	_paint_galaxies(out, rng)
	_paint_disk(out, rng)
	_paint_hole(out)
	_paint_belt(out, rng)
	return out


static func _paint_galaxies(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var img: Image = Painter.new_img(768, 190)
	for g: int in range(5):
		var c: Vector2 = Vector2(rng.randf_range(20.0, 748.0), rng.randf_range(20.0, 170.0))
		if g == 2:
			c.y = 160.0
		var sz: float = rng.randf_range(6.0, 12.0)
		var tilt: float = rng.randf_range(-0.6, 0.6)
		for s: int in range(140):
			var t: float = float(s) / 140.0
			for arm: int in range(2):
				var a: float = t * 7.0 + float(arm) * PI
				var r: float = t * sz
				var p: Vector2 = Vector2(cos(a) * r, sin(a) * r * 0.45).rotated(tilt) + c
				Painter.px(img, int(p.x), int(p.y), Color("#2a2240") if t > 0.3 else Color("#4a3e66"))
		Painter.px(img, int(c.x), int(c.y), Color("#8a7aa8"))
	out["galaxies"] = img


# The disk, split into its far half (behind the hole) and near half (in front).
static func _paint_disk(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 320
	var h: int = 100
	var back: Image = Painter.new_img(w, h)
	var front: Image = Painter.new_img(w, h)
	var ramp: PackedColorArray = PackedColorArray([Color("#2e0c06"), Color("#5a1a08"), Color("#8a2e0c"), Color("#c04a12"), Color("#e87a26"), Color("#ffb456"), Color("#ffe6b0")])
	var ox: float = BH.x - 160.0
	var oy: float = BH.y - 50.0
	for y: int in range(h):
		for x: int in range(w):
			var q: Vector2 = (Vector2(float(x) + ox + 0.5, float(y) + oy + 0.5) - BH).rotated(-TILT)
			var u: float = q.x
			var v: float = q.y / SQUASH
			var r: float = sqrt(u * u + v * v)
			if r < DISK_IN or r > DISK_OUT:
				continue
			var t: float = (r - DISK_IN) / (DISK_OUT - DISK_IN)
			var ang: float = atan2(v, u)
			var streak: float = 0.5 + 0.5 * sin(ang * 3.0 + r * 0.22)
			var heat: float = (1.0 - t) * (0.75 + 0.25 * streak)
			heat *= 1.0 + (-u / r) * 0.25  # the side turning toward us is brighter
			var dens: float = (1.0 - t * 0.85) * (0.6 + 0.4 * streak)
			if Painter.bayer(x, y) > dens:
				continue
			var c: Color = Painter.ramp_pick(ramp, clampf(heat * 0.95, 0.0, 1.0), x, y)
			if q.y < 0.0:
				back.set_pixel(x, y, c.darkened(0.15))
			else:
				front.set_pixel(x, y, c)
	out["disk_back"] = back
	out["disk_front"] = front


# The shadow, its photon ring, and the far side of the disk lensed up over the top.
static func _paint_hole(out: Dictionary) -> void:
	var img: Image = Painter.new_img(96, 96)
	var c: Vector2 = Vector2(48.0, 48.0)
	for y: int in range(96):
		for x: int in range(96):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c)
			var dy: float = float(y) + 0.5 - c.y
			if d <= SHADOW_R:
				img.set_pixel(x, y, Color("#000000"))
			elif d <= SHADOW_R + 1.2:
				img.set_pixel(x, y, Color("#ffe6b0"))
			elif d <= SHADOW_R + 2.4:
				img.set_pixel(x, y, Color("#e87a26"))
			elif d < SHADOW_R + 9.0 and dy < 2.0:
				# lensed far disk: a bright band hugging the top of the shadow, thinner below
				var band: float = 1.0 - (d - SHADOW_R - 2.4) / 6.6
				var k: float = band * clampf((-dy + 2.0) / 14.0, 0.15, 1.0)
				if Painter.bayer(x, y) < k * 1.3:
					img.set_pixel(x, y, Color("#ffb456") if k > 0.55 else Color("#c04a12"))
			elif d < SHADOW_R + 4.5 and dy >= 2.0:
				if Painter.bayer(x, y) < 0.35:
					img.set_pixel(x, y, Color("#8a2e0c"))
	out["hole"] = img


# Debris belt along the bottom, its upper edges lit by the disk.
static func _paint_belt(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 58
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 7, 0.6)
	for x: int in range(w):
		var top: int = int(18.0 + (1.0 - prof[x]) * 26.0)
		var lit: bool = prof[x] > prof[posmod(x - 1, w)]
		for y: int in range(top, h):
			var c: Color = Color("#07040a")
			if y == top:
				c = Color("#6a2a10") if lit else Color("#2e140c")
			elif y == top + 1 and lit:
				c = Color("#2e140c")
			elif Painter.bayer(x, y) < 0.15:
				c = Color("#0c0710")
			img.set_pixel(x, y, c)
	# loose rocks floating above the belt
	for k: int in range(16):
		var rx: float = rng.randf_range(0.0, float(w))
		var ry: float = rng.randf_range(4.0, 22.0)
		var rr: float = rng.randf_range(1.5, 4.0)
		Painter.ellipse(img, rx, ry, rr + 1.0, rr, Color("#07040a"))
		Painter.span(img, int(rx - rr * 0.6), int(rx + rr * 0.4), int(ry - rr), Color("#5a240e"))
	out["belt"] = img


# --- animation ----------------------------------------------------------------------------------

func reset() -> void:
	_cr.resize(CLUMPS)
	_ca.resize(CLUMPS)
	for i: int in range(CLUMPS):
		_cr[i] = lerpf(DISK_IN + 2.0, DISK_OUT - 6.0, pow(rng.randf(), 1.4))
		_ca[i] = rng.randf_range(0.0, TAU)
	_ir.resize(INFALL)
	_ia.resize(INFALL)
	for j: int in range(INFALL):
		_ir[j] = rng.randf_range(40.0, 300.0)
		_ia[j] = rng.randf_range(0.0, TAU)
	drift_a.y0 = 30.0
	drift_a.y1 = 250.0
	drift_a.setup(18, rng, -12.0, -4.0, -2.0, 2.0)
	drift_a.par = 0.55
	drift_a.cols = PackedColorArray([Color(1.0, 0.6, 0.3, 0.35), Color(0.7, 0.5, 1.0, 0.3)])
	_jet_t = -1.0
	_jet_wait = rng.randf_range(5.0, 10.0)
	_tde_t = -1.0
	_tde_wait = rng.randf_range(3.0, 7.0)
	_rip_t = -1.0
	_rip_wait = rng.randf_range(6.0, 12.0)


func update() -> void:
	for i: int in range(CLUMPS):
		_ca[i] += 26.0 / pow(_cr[i], 1.1) * dl
	for j: int in range(INFALL):
		var r: float = _ir[j]
		_ir[j] = r - (6.0 + 1800.0 / (r * r) * 10.0) * dl
		_ia[j] += (9.0 / sqrt(maxf(r, 1.0))) * dl
		if _ir[j] < SHADOW_R + 2.0:
			_ir[j] = rng.randf_range(180.0, 320.0)
			_ia[j] = rng.randf_range(0.0, TAU)
	if _jet_t < 0.0:
		_jet_wait -= dl
		if _jet_wait <= 0.0:
			_jet_t = 0.0
	else:
		_jet_t += dl
		if _jet_t > 1.5:
			_jet_t = -1.0
			_jet_wait = rng.randf_range(12.0, 20.0)
	if _tde_t < 0.0:
		_tde_wait -= dl
		if _tde_wait <= 0.0:
			_tde_t = 0.0
			_tde_r = 210.0
			_tde_a = rng.randf_range(0.0, TAU)
			_tde_trail.clear()
	else:
		_tde_t += dl
		_tde_r -= (14.0 + 900.0 / maxf(_tde_r, 20.0)) * dl
		_tde_a += 28.0 / maxf(_tde_r, 20.0) * dl
		var p: Vector2 = BH + Vector2(cos(_tde_a) * _tde_r, sin(_tde_a) * _tde_r * 0.55)
		_tde_trail.insert(0, p)
		if _tde_trail.size() > 28:
			_tde_trail.resize(28)
		if _tde_r < SHADOW_R:
			_tde_t = -1.0
			_tde_wait = rng.randf_range(14.0, 22.0)
	if _rip_t < 0.0:
		_rip_wait -= dl
		if _rip_wait <= 0.0:
			_rip_t = 0.0
	else:
		_rip_t += dl
		if _rip_t > 2.6:
			_rip_t = -1.0
			_rip_wait = rng.randf_range(12.0, 18.0)


func _clump(i: int) -> Vector2:
	return BH + Vector2(cos(_ca[i]) * _cr[i], sin(_ca[i]) * _cr[i] * SQUASH).rotated(TILT)


func _clump_col(i: int) -> Color:
	var t: float = (_cr[i] - DISK_IN) / (DISK_OUT - DISK_IN)
	if t < 0.2:
		return Color(1.0, 0.92, 0.75, 0.9)
	elif t < 0.5:
		return Color(1.0, 0.65, 0.3, 0.8)
	return Color(0.85, 0.35, 0.12, 0.7)


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	layer("galaxies", 30.0, GAL_F)
	# stars falling in, smeared longer the deeper they go
	var segs: PackedVector2Array = PackedVector2Array()
	for j: int in range(INFALL):
		var r: float = _ir[j]
		var len_a: float = clampf(5.0 / r + 120.0 / (r * r), 0.01, 0.9)
		var a0: Vector2 = BH + Vector2(cos(_ia[j]) * r, sin(_ia[j]) * r * 0.7)
		var a1: Vector2 = BH + Vector2(cos(_ia[j] - len_a) * r * 1.03, sin(_ia[j] - len_a) * r * 0.72)
		segs.append(a0.floor() + Vector2(0.5, 0.5))
		segs.append(a1.floor() + Vector2(0.5, 0.5))
	bg.draw_multiline(segs, Color(0.75, 0.75, 1.0, 0.35), 1.0)
	if _jet_t >= 0.0:
		var a: float = sin(_jet_t / 1.5 * PI) * (0.75 + 0.25 * float(int(life * 30.0) % 2))
		bg.draw_rect(Rect2(BH.x - 1.0, 22.0, 3.0, BH.y - 22.0), Color(0.85, 0.75, 1.0, 0.45 * a))
		bg.draw_rect(Rect2(BH.x - 4.0, 22.0, 9.0, BH.y - 22.0), Color(0.6, 0.45, 1.0, 0.08 * a))
		bg.draw_rect(Rect2(BH.x - 1.0, BH.y, 3.0, 160.0), Color(0.85, 0.75, 1.0, 0.2 * a))
	var dp: Vector2 = BH - Vector2(160.0, 50.0)
	bg.draw_texture(tex("disk_back"), dp)
	for i: int in range(CLUMPS):
		if sin(_ca[i]) < 0.0:
			var p: Vector2 = _clump(i)
			bg.draw_rect(Rect2(p.floor(), Vector2(2.0 if i % 3 == 0 else 1.0, 1.0)), _clump_col(i))
	if _tde_t >= 0.0 and _tde_trail.size() > 1:
		bg.draw_polyline(_tde_trail, Color(1.0, 0.85, 0.6, 0.45), 1.0)
		bg.draw_rect(Rect2(_tde_trail[0].floor() - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(1.0, 0.95, 0.85, 0.9))
	bg.draw_texture(tex("hole"), BH - Vector2(48.0, 48.0))
	var pulse: float = 0.5 + 0.5 * sin(life * 2.2)
	bg.draw_arc(BH, SHADOW_R + 3.0, PI, TAU, 32, Color(1.0, 0.85, 0.6, 0.12 + 0.12 * pulse), 2.0)
	bg.draw_texture(tex("disk_front"), dp)
	for i2: int in range(CLUMPS):
		if sin(_ca[i2]) >= 0.0:
			var p2: Vector2 = _clump(i2)
			bg.draw_rect(Rect2(p2.floor(), Vector2(2.0 if i2 % 3 == 0 else 1.0, 1.0)), _clump_col(i2))
	if _rip_t >= 0.0:
		var k: float = _rip_t / 2.6
		bg.draw_arc(BH, 30.0 + 460.0 * k, 0.0, TAU, 64, Color(0.75, 0.6, 1.0, 0.16 * (1.0 - k)), 1.0)
		bg.draw_arc(BH, 22.0 + 440.0 * k, 0.0, TAU, 64, Color(0.75, 0.6, 1.0, 0.07 * (1.0 - k)), 1.0)
	drift_draw(drift_a)
	layer("belt", BELT_Y, BELT_F)
