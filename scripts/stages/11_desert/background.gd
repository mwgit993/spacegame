extends "res://scripts/stages/stage_background.gd"

# DESERT WORLD: dusk on a desert planet under twin setting suns. An indigo sky fades to a dusty
# amber horizon where a huge dim orange sun sinks behind the dunes, barred by haze, with a small
# pale companion above it. Distant pyramids, obelisks and a temple with flickering braziers sit on
# the horizon; rolling dune ranges come nearer, then half-buried ruins (columns, a fallen colossus
# head, a toppled obelisk) and the foreground sand.
#
# Layers (paint(), worker thread):
#   "sky"         480x270 at (0,0): gradient, stars, the twin suns
#   "sun_band"    480x34 at y 136: the horizon strip around the big sun, drawn with heat shimmer
#   "far"         768x60 at y 112, parallax 0.03: pyramids, obelisks, temple (heat shimmer)
#   "dunes_far"   640x50 at y 160, parallax 0.08
#   "dunes_mid"   768x56 at y 184, line-scrolled 0.16 -> 0.28
#   "ruins"       896x60 at y 176, parallax 0.42
#   "dunes_near"  512x40 at y 226, line-scrolled 0.62 -> 0.95
#   "barge"       a sail-barge silhouette for the caravan event
# Animation: brazier flames, wind-blown sand streaks and dust motes, sand blowing off the dune
# crests, vultures circling. Rare events: a sandstorm wall rolling through (_ev_a), a giant
# sandworm breaching on the far dunes (_ev_b), a sail-barge caravan crossing (_ev_c).
# The playfield stays dark: dunes are dusky silhouettes lit only along their crests.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const SUN_Y: float = 136.0
const FAR_Y: float = 112.0
const DF_Y: float = 160.0
const DM_Y: float = 184.0
const RU_Y: float = 176.0
const DN_Y: float = 226.0
const SPRAY_CAP: int = 48
const DUST: Color = Color(0.85, 0.6, 0.4)

var _sp_x: PackedFloat32Array = PackedFloat32Array()
var _sp_y: PackedFloat32Array = PackedFloat32Array()
var _sp_vx: PackedFloat32Array = PackedFloat32Array()
var _sp_vy: PackedFloat32Array = PackedFloat32Array()
var _sp_age: PackedFloat32Array = PackedFloat32Array()
var _sp_n: int = 0
var _spray_t: float = 0.3
var _worm_x: float = 200.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1111
	var out: Dictionary = {}
	var sky: Image = _paint_sky(rng)
	out["sky"] = sky
	out["sun_band"] = sky.get_region(Rect2i(0, int(SUN_Y), 480, 34))
	_paint_far(rng, out)
	_paint_dunes_far(rng, out)
	_paint_dunes_mid(rng, out)
	_paint_ruins(rng, out)
	out["dunes_near"] = _paint_dunes_near(rng)
	out["barge"] = _paint_barge()
	return out


static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#0b0a1c"))
	Painter.vgrad(sky, 22, 176, PackedColorArray([Color("#0b0a1c"), Color("#100d24"), Color("#17112c"), Color("#201534"), Color("#2c1938"), Color("#3a1e38"), Color("#4a2434"), Color("#5a2a32")]), 0.5)
	Painter.vgrad(sky, 176, 270, PackedColorArray([Color("#5a2a32"), Color("#4a2430")]), 0.5)
	# Stars in the upper sky, fading toward the horizon.
	for i: int in range(90):
		var y: int = rng.randi_range(24, 110)
		if rng.randf() < float(y - 24) / 100.0:
			continue
		Painter.px(sky, rng.randi_range(0, 479), y, Color("#6a64a0") if i % 4 == 0 else Color("#3a3466"))
	# Thin high cirrus streaks catching the last light.
	for c: int in range(7):
		var cy: int = rng.randi_range(70, 128)
		var cx: int = rng.randi_range(0, 479)
		var cl: int = rng.randi_range(40, 110)
		for x: int in range(cl):
			if Painter.bayer(cx + x, cy) < 0.55 - absf(float(x) / float(cl) - 0.5):
				Painter.blend_px(sky, cx + x, cy, Color("#5a2e40"), 0.6)
				if x % 3 == 0:
					Painter.blend_px(sky, cx + x + 2, cy + 1, Color("#4a263c"), 0.5)
	# The big dim orange sun sinking at the horizon: glow rings, disc, haze bars.
	var sc: Vector2 = Vector2(152.0, 160.0)
	for r: int in range(58, 30, -1):
		var k: float = float(58 - r) / 28.0
		for y2: int in range(int(sc.y) - r, int(sc.y) + r + 1):
			for x2: int in range(int(sc.x) - r, int(sc.x) + r + 1):
				var d: float = Vector2(float(x2), float(y2)).distance_to(sc)
				if d > float(r) or d <= float(r - 1):
					continue
				if Painter.bayer(x2, y2) < k * 0.5:
					Painter.blend_px(sky, x2, y2, Color("#7a3430"), 0.5 + 0.3 * k)
	Painter.disc(sky, sc.x, sc.y, 30.0, Color("#a8462a"))
	Painter.disc(sky, sc.x - 3.0, sc.y - 3.0, 24.0, Color("#bc542c"))
	Painter.disc(sky, sc.x - 6.0, sc.y - 7.0, 14.0, Color("#cc6432"))
	for hy: int in [140, 146, 151, 155, 158]:
		var hw: int = 40 if hy > 150 else 34
		for x3: int in range(int(sc.x) - hw, int(sc.x) + hw):
			var p: Color = Painter.get_px(sky, x3, hy)
			if p.r > 0.55:
				Painter.px(sky, x3, hy, Color("#7a3430"))
	# The small pale companion sun.
	var sc2: Vector2 = Vector2(352.0, 116.0)
	for r2: int in range(16, 7, -1):
		var k2: float = float(16 - r2) / 9.0
		for y4: int in range(int(sc2.y) - r2, int(sc2.y) + r2 + 1):
			for x4: int in range(int(sc2.x) - r2, int(sc2.x) + r2 + 1):
				var d2: float = Vector2(float(x4), float(y4)).distance_to(sc2)
				if d2 <= float(r2) and d2 > float(r2 - 1) and Painter.bayer(x4, y4) < k2 * 0.45:
					Painter.blend_px(sky, x4, y4, Color("#8a7a8a"), 0.6)
	Painter.disc(sky, sc2.x, sc2.y, 6.5, Color("#c8bcb0"))
	Painter.disc(sky, sc2.x - 1.0, sc2.y - 1.0, 4.5, Color("#e8dcc8"))
	return sky


static func _paint_far(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = 768
	var h: int = 60
	var img: Image = Painter.new_img(w, h)
	var body: Color = Color("#1e1226")
	var lit: Color = Color("#2e1a2e")
	var rim: Color = Color("#5a3034")
	var braziers: PackedVector2Array = PackedVector2Array()
	# Low horizon ridge.
	var prof: PackedFloat32Array = Painter.profile(w, rng, 3, 3, 0.5)
	for x: int in range(w):
		var top: int = int(50.0 + (1.0 - prof[x]) * 6.0)
		Painter.vline(img, x, top, h - 1, body)
	# Pyramids: a big one, a middle and a small one per group, lit on the left face.
	for g: int in range(3):
		var gx: float = 70.0 + float(g) * 256.0 + rng.randf_range(-20.0, 20.0)
		for p: int in range(3):
			var half: float = [34.0, 22.0, 13.0][p]
			var cx: float = gx + [0.0, 46.0, 76.0][p]
			var base_y: float = 58.0
			var apex: Vector2 = Vector2(cx, base_y - half * 0.95)
			Painter.poly(img, PackedVector2Array([Vector2(cx - half, base_y), apex, Vector2(cx + half, base_y)]), body)
			Painter.poly(img, PackedVector2Array([Vector2(cx - half, base_y), apex, Vector2(cx - half * 0.15, base_y)]), lit)
			Painter.line(img, int(cx - half), int(base_y), int(apex.x), int(apex.y), rim)
			# courses of stone
			for cy: int in range(int(apex.y) + 4, int(base_y), 4):
				var t: float = (float(cy) - apex.y) / (base_y - apex.y)
				Painter.rect(img, int(cx - half * t) + 1, cy, int(half * t * 0.85), 1, Color("#26162c"))
			if p == 0:
				Painter.px(img, int(apex.x), int(apex.y), Color("#c8a060"))
				braziers.append(Vector2(apex.x, apex.y - 1.0))
	# Obelisks.
	for o: int in range(5):
		var ox: int = rng.randi_range(0, w - 1)
		var oh: int = rng.randi_range(16, 26)
		Painter.rect(img, ox, 58 - oh, 3, oh, body)
		Painter.px(img, ox + 1, 57 - oh, rim)
		Painter.vline(img, ox, 58 - oh, 57, lit)
	# A temple with a colonnade and two braziers.
	for t: int in range(2):
		var tx: int = 200 + t * 384 + rng.randi_range(-20, 20)
		Painter.rect(img, tx, 40, 52, 18, body)
		Painter.rect(img, tx - 3, 38, 58, 3, lit)
		Painter.rect(img, tx - 3, 38, 58, 1, rim)
		for cxx: int in range(tx + 3, tx + 50, 7):
			Painter.rect(img, cxx, 42, 3, 16, lit)
			Painter.rect(img, cxx + 3, 42, 4, 16, Color("#150c1a"))
		Painter.rect(img, tx + 22, 46, 8, 12, Color("#0e0812"))
		braziers.append(Vector2(float(tx - 2), 36.0))
		braziers.append(Vector2(float(tx + 54), 36.0))
	out["far"] = img
	out["braziers"] = braziers


static func _paint_dunes_far(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = 640
	var h: int = 50
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 4, 3, 0.45)
	var crest: PackedFloat32Array = PackedFloat32Array()
	crest.resize(w)
	for x: int in range(w):
		var top: int = int(4.0 + (1.0 - prof[x]) * 18.0)
		crest[x] = float(top)
		var slope: float = prof[(x + 1) % w] - prof[posmod(x - 1, w)]
		for y: int in range(top, h):
			var c: Color = Color("#24162a")
			if slope > 0.0 and y < top + 6:
				c = Color("#2e1c2c")
			if (y - top) % 5 == 2 and Painter.bayer(x, y) < 0.35:
				c = Color("#2a1a2c")
			img.set_pixel(x, y, c)
		img.set_pixel(x, top, Color("#5a3236") if slope > 0.0 else Color("#3a2230"))
	out["dunes_far"] = img
	out["df_crest"] = crest


static func _paint_dunes_mid(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = 768
	var h: int = 56
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 3, 3, 0.45)
	var ramp: PackedColorArray = PackedColorArray([Color("#1a0e18"), Color("#22121c"), Color("#2c1822"), Color("#381e26"), Color("#48262a"), Color("#5a302e")])
	var crest: PackedFloat32Array = PackedFloat32Array()
	crest.resize(w)
	for x: int in range(w):
		var top: int = int(4.0 + (1.0 - prof[x]) * 24.0)
		crest[x] = float(top)
		var light: float = _dune_light(prof, x, w)
		for y: int in range(top, h):
			var depth: float = float(y - top) / float(h - top + 1)
			var v: float = lerpf(0.18, 0.78, light) * (1.0 - depth * 0.55)
			if (y - top) % 6 == 3 and Painter.bayer(x, y) < 0.5:
				v += 0.12
			img.set_pixel(x, y, Painter.ramp_pick(ramp, v, x, y))
		img.set_pixel(x, top, Color("#8a4c34") if light > 0.55 else Color("#3e2228"))
		if light > 0.7:
			img.set_pixel(x, top + 1, Color("#6a3a30"))
	out["dunes_mid"] = img
	out["dm_crest"] = crest


# 0 (shadowed lee side) .. 1 (sunlit side) from the dune profile's slope over a wide window.
static func _dune_light(prof: PackedFloat32Array, x: int, w: int) -> float:
	var slope: float = prof[(x + 7) % w] - prof[posmod(x - 7, w)]
	return clampf(0.5 + slope * 5.0, 0.0, 1.0)


static func _paint_ruins(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = 896
	var h: int = 60
	var img: Image = Painter.new_img(w, h)
	var stone: Color = Color("#22141a")
	var lit: Color = Color("#3a2224")
	var rim: Color = Color("#6a4030")
	var dark: Color = Color("#140a10")
	# Broken columns: fluted shafts at different heights, capitals on some.
	for c: int in range(9):
		var cx: int = 30 + c * 100 + rng.randi_range(-24, 24)
		var ch: int = rng.randi_range(14, 44)
		var cw: int = rng.randi_range(7, 10)
		Painter.rect(img, cx, h - ch, cw, ch, stone)
		Painter.rect(img, cx, h - ch, 2, ch, lit)
		Painter.vline(img, cx, h - ch, h - 1, rim)
		for fx: int in range(cx + 3, cx + cw - 1, 2):
			Painter.vline(img, fx, h - ch + 2, h - 1, dark)
		# a jagged broken top
		for bx: int in range(cx, cx + cw):
			var notch: int = (bx * 7 + c * 3) % 4
			Painter.vline(img, bx, h - ch, h - ch + notch, Color(0, 0, 0, 0))
		if ch > 30 and c % 2 == 0:
			Painter.rect(img, cx - 2, h - ch - 3, cw + 4, 3, lit)
			Painter.rect(img, cx - 2, h - ch - 3, cw + 4, 1, rim)
	# A fallen colossus head, half buried, facing up-left.
	var hx: float = 470.0
	Painter.ellipse(img, hx, 48.0, 26.0, 18.0, stone)
	Painter.ellipse(img, hx - 6.0, 44.0, 18.0, 13.0, lit)
	Painter.poly(img, PackedVector2Array([Vector2(hx - 30, 60), Vector2(hx - 24, 26), Vector2(hx + 4, 20), Vector2(hx + 30, 34), Vector2(hx + 34, 60)]), stone)
	for sy: int in range(24, 60, 4):
		Painter.line(img, int(hx) - 24 + (sy - 24) / 6, sy, int(hx) + 30, sy + 4, Color("#2a1820"))
	Painter.ellipse(img, hx - 12.0, 40.0, 4.0, 2.0, dark)
	Painter.rect(img, int(hx) - 20, 48, 9, 2, dark)
	Painter.line(img, int(hx) - 24, 26, int(hx) + 4, 20, rim)
	# A toppled obelisk lying across the sand.
	Painter.poly(img, PackedVector2Array([Vector2(640, 54), Vector2(712, 46), Vector2(718, 50), Vector2(642, 60)]), stone)
	Painter.line(img, 640, 54, 712, 46, rim)
	Painter.poly(img, PackedVector2Array([Vector2(712, 46), Vector2(722, 47), Vector2(718, 50)]), lit)
	# An arch (a gateway) still standing.
	Painter.rect(img, 780, 18, 8, 42, stone)
	Painter.rect(img, 812, 18, 8, 42, stone)
	Painter.rect(img, 776, 12, 48, 8, lit)
	Painter.rect(img, 776, 12, 48, 1, rim)
	Painter.vline(img, 780, 18, 59, rim)
	# Sand drifted against everything along the bottom.
	var prof: PackedFloat32Array = Painter.profile(w, rng, 4, 8, 0.5)
	for x: int in range(w):
		var top: int = int(52.0 + (1.0 - prof[x]) * 6.0)
		Painter.vline(img, x, top, h - 1, Color("#2a1820"))
		Painter.px(img, x, top, Color("#4a2a2a"))
	out["ruins"] = img


static func _paint_dunes_near(rng: RandomNumberGenerator) -> Image:
	var w: int = 512
	var h: int = 40
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 3, 4, 0.45)
	var ramp: PackedColorArray = PackedColorArray([Color("#1e1018"), Color("#2a161c"), Color("#361e20"), Color("#442624"), Color("#563028")])
	for x: int in range(w):
		var top: int = int(2.0 + (1.0 - prof[x]) * 14.0)
		var light: float = _dune_light(prof, x, w)
		for y: int in range(top, h):
			var v: float = lerpf(0.25, 0.85, light) - float(y - top) * 0.018
			if (y - top) % 5 == 2 and Painter.bayer(x, y) < 0.45:
				v += 0.14
			img.set_pixel(x, y, Painter.ramp_pick(ramp, v, x, y))
		img.set_pixel(x, top, Color("#9a5a3a") if light > 0.55 else Color("#5a3428"))
	# Pebbles and a few bleached bones.
	for i: int in range(24):
		var px0: int = rng.randi_range(0, w - 1)
		var py0: int = rng.randi_range(20, h - 3)
		Painter.px(img, px0, py0, Color("#5a3a2a"))
	for b: int in range(3):
		var bx: int = rng.randi_range(0, w - 12)
		Painter.rect(img, bx, 26, 8, 1, Color("#a89880"))
		Painter.px(img, bx - 1, 25, Color("#a89880"))
		Painter.px(img, bx + 8, 25, Color("#a89880"))
	return img


static func _paint_barge() -> Image:
	var img: Image = Painter.new_img(64, 30)
	var sil: Color = Color("#140a14")
	var rim: Color = Color("#4a2a2e")
	# Hull on skids, two triangular sails, oars, a lit cabin.
	Painter.poly(img, PackedVector2Array([Vector2(2, 22), Vector2(62, 22), Vector2(56, 28), Vector2(8, 28)]), sil)
	Painter.rect(img, 2, 22, 60, 1, rim)
	Painter.rect(img, 6, 29, 52, 1, sil)
	Painter.rect(img, 22, 16, 14, 6, sil)
	Painter.px(img, 25, 18, Color("#a86a2a"))
	Painter.px(img, 29, 18, Color("#a86a2a"))
	Painter.vline(img, 16, 2, 22, sil)
	Painter.vline(img, 42, 6, 22, sil)
	Painter.poly(img, PackedVector2Array([Vector2(17, 2), Vector2(32, 18), Vector2(17, 18)]), Color("#1c1018"))
	Painter.poly(img, PackedVector2Array([Vector2(43, 6), Vector2(56, 19), Vector2(43, 19)]), Color("#1c1018"))
	Painter.line(img, 17, 2, 32, 18, rim)
	Painter.line(img, 43, 6, 56, 19, rim)
	for ox: int in range(10, 56, 6):
		Painter.line(img, ox, 24, ox - 3, 29, sil)
	return img


# --- Animation -------------------------------------------------------------------------------------

func reset() -> void:
	# Wind-blown sand streaks.
	drift_a.y0 = 120.0
	drift_a.y1 = 254.0
	drift_a.setup(30, rng, -150.0, -80.0, -4.0, 4.0)
	drift_a.par = 0.3
	drift_a.cols = PackedColorArray([Color(0.85, 0.6, 0.4, 0.22), Color(0.7, 0.48, 0.34, 0.28), Color(0.95, 0.75, 0.5, 0.16)])
	# Slow dust motes higher up.
	drift_b.y0 = 34.0
	drift_b.y1 = 220.0
	drift_b.setup(22, rng, -26.0, -10.0, -3.0, 3.0)
	drift_b.par = 0.15
	drift_b.sway = 3.0
	drift_b.sway_hz = 0.7
	drift_b.cols = PackedColorArray([Color(0.75, 0.55, 0.45, 0.3), Color(0.55, 0.4, 0.4, 0.35)])
	_sp_x.resize(SPRAY_CAP)
	_sp_y.resize(SPRAY_CAP)
	_sp_vx.resize(SPRAY_CAP)
	_sp_vy.resize(SPRAY_CAP)
	_sp_age.resize(SPRAY_CAP)
	_sp_n = 0
	bg._ev_a.arm(rng, 22.0, 34.0, 10.0, 16.0)   # sandstorm wall
	bg._ev_b.arm(rng, 16.0, 26.0, 5.0, 9.0)     # sandworm breach
	bg._ev_c.arm(rng, 20.0, 30.0, 2.0, 5.0)     # sail-barge caravan


func _spray(x: float, y: float, vx: float, vy: float) -> void:
	if _sp_n >= SPRAY_CAP:
		return
	_sp_x[_sp_n] = x
	_sp_y[_sp_n] = y
	_sp_vx[_sp_n] = vx
	_sp_vy[_sp_n] = vy
	_sp_age[_sp_n] = 0.0
	_sp_n += 1


func update() -> void:
	# Sand blowing off the mid and near dune crests.
	_spray_t -= dl
	if _spray_t <= 0.0:
		_spray_t = rng.randf_range(0.05, 0.14)
		var crest: PackedFloat32Array = meta.get("dm_crest", PackedFloat32Array())
		if not crest.is_empty():
			var sx: float = rng.randf_range(0.0, 480.0)
			var tx: int = int(fposmod(sx + off(0.2, 768.0), 768.0))
			var cy: float = DM_Y + crest[tx]
			for k: int in range(rng.randi_range(2, 4)):
				_spray(sx + rng.randf_range(-2.0, 2.0), cy, rng.randf_range(-60.0, -30.0), rng.randf_range(-14.0, -3.0))
	var i: int = 0
	while i < _sp_n:
		_sp_age[i] += dl
		if _sp_age[i] > 1.2 or _sp_x[i] < -4.0:
			_sp_n -= 1
			_sp_x[i] = _sp_x[_sp_n]
			_sp_y[i] = _sp_y[_sp_n]
			_sp_vx[i] = _sp_vx[_sp_n]
			_sp_vy[i] = _sp_vy[_sp_n]
			_sp_age[i] = _sp_age[_sp_n]
			continue
		_sp_vy[i] += 14.0 * dl
		_sp_x[i] += _sp_vx[i] * dl - ds * 0.2
		_sp_y[i] += _sp_vy[i] * dl
		i += 1
	if bg._ev_a.tick(dl, rng):
		bg._ev_a.dur = 8.0
	drift_a.wind = -120.0 * _storm_amount()
	if bg._ev_b.tick(dl, rng):
		bg._ev_b.dur = 4.6
		_worm_x = rng.randf_range(80.0, 300.0)
	if bg._ev_c.tick(dl, rng):
		bg._ev_c.dur = 16.0


# 0..1: how much of the sandstorm wall is over the screen.
func _storm_amount() -> float:
	if not bg._ev_a.on:
		return 0.0
	var u: float = bg._ev_a.t / bg._ev_a.dur
	return clampf(minf(u * 4.0, (1.0 - u) * 3.0), 0.0, 1.0)


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	layer_wobble("sun_band", SUN_Y, 0.0, 2, 1.2, 0.9, 2.4)
	_draw_vultures()
	layer_wobble("far", FAR_Y, 0.03, 3, 0.9, 0.55, 2.8, 30)
	var o_f: float = off(0.03, 768.0)
	var braz: PackedVector2Array = meta.get("braziers", PackedVector2Array())
	for b: int in range(braz.size()):
		var bx: float = wrap_x(braz[b].x, o_f, 768.0)
		if bx < -4.0 or bx > 484.0:
			continue
		var fl: float = 0.5 + 0.5 * sin(life * 9.0 + float(b) * 2.1) * sin(life * 5.3 + float(b))
		var by: float = FAR_Y + braz[b].y
		bg.draw_circle(Vector2(floorf(bx) + 0.5, by), 3.0 + fl, Color(1.0, 0.55, 0.2, 0.12 + 0.08 * fl))
		bg.draw_rect(Rect2(floorf(bx), by - (1.0 if fl > 0.5 else 0.0), 1.0, 2.0), Color(1.0, 0.75, 0.3, 0.8))
		bg.draw_rect(Rect2(floorf(bx), by + 1.0, 1.0, 1.0), Color("#ffe0a0"))
	_draw_worm_breach()
	layer_wobble("dunes_far", DF_Y, 0.08, 2, 0.8, 0.7, 2.0)
	_draw_barge()
	layer_rows("dunes_mid", DM_Y, 2, 0.16, 0.28)
	drift_draw(drift_b)
	layer("ruins", RU_Y, 0.42)
	layer_rows("dunes_near", DN_Y, 2, 0.62, 0.95)
	# Crest spray.
	for i: int in range(_sp_n):
		var a: float = 1.0 - _sp_age[i] / 1.2
		bg.draw_rect(Rect2(floorf(_sp_x[i]), floorf(_sp_y[i]), 1.0, 1.0), Color(DUST.r, DUST.g, DUST.b, 0.45 * a))
	drift_draw(drift_a, 6.0)
	_draw_storm()


func _draw_vultures() -> void:
	for v: int in range(3):
		var cx: float = 260.0 + float(v) * 60.0 + sin(life * 0.05 + float(v)) * 40.0
		var a: float = life * (0.5 + 0.1 * float(v)) + float(v) * 2.0
		var p: Vector2 = Vector2(cx + cos(a) * 18.0, 70.0 + float(v) * 9.0 + sin(a) * 6.0)
		var flap: float = 1.0 if int(life * 3.0 + float(v)) % 3 == 0 else 0.0
		var col: Color = Color("#1a1024")
		bg.draw_rect(Rect2(floorf(p.x), floorf(p.y), 1.0, 1.0), col)
		bg.draw_rect(Rect2(floorf(p.x) - 2.0, floorf(p.y) - flap, 2.0, 1.0), col)
		bg.draw_rect(Rect2(floorf(p.x) + 1.0, floorf(p.y) - flap, 2.0, 1.0), col)


# A giant worm arcing out of the far dunes and diving back in.
func _draw_worm_breach() -> void:
	if not bg._ev_b.on:
		return
	var u: float = bg._ev_b.t / bg._ev_b.dur
	var base_y: float = DF_Y + 14.0
	var span: float = 130.0
	var x0: float = _worm_x - u * 30.0
	var head: float = u * 1.5
	var sil: Color = Color("#140a16")
	var rim: Color = Color("#5a3236")
	for s: int in range(24):
		var t: float = head - float(s) * 0.03
		if t < 0.0 or t > 1.0:
			continue
		var p: Vector2 = Vector2(x0 + t * span, base_y - sin(t * PI) * 46.0)
		var r: float = 6.5 - float(s) * 0.12
		bg.draw_circle(p, r + 1.0, sil)
		if s % 3 == 0:
			bg.draw_rect(Rect2(floorf(p.x) - 1.0, floorf(p.y - r), 3.0, 1.0), rim)
		if s == 0:
			bg.draw_rect(Rect2(floorf(p.x) - 4.0, floorf(p.y) - 1.0, 2.0, 2.0), Color(1.0, 0.5, 0.25, 0.8))
	# Sand fountains where it breaks the surface.
	for e: float in [0.0, 1.0]:
		# Each fountain lasts while the body is passing through that point.
		var k: float = clampf(1.0 - absf(head - e - 0.35) * 2.2, 0.0, 1.0)
		if k <= 0.0:
			continue
		var ex: float = x0 + e * span
		for d: int in range(6):
			var dy: float = fposmod(life * 30.0 + float(d) * 5.0, 14.0) * k
			bg.draw_rect(Rect2(floorf(ex + float(d - 3) * 3.0), floorf(base_y - dy), 1.0, 1.0), Color(DUST.r, DUST.g, DUST.b, 0.5 * k))
		bg.draw_circle(Vector2(ex, base_y), 6.0 * k, Color(0.55, 0.36, 0.3, 0.25 * k))


func _draw_barge() -> void:
	if not bg._ev_c.on:
		return
	var u: float = bg._ev_c.t / bg._ev_c.dur
	var x: float = floorf(500.0 - u * 600.0)
	var y: float = DF_Y + 6.0 + floorf(sin(life * 1.4) * 1.0)
	bg.draw_texture(tex("barge"), Vector2(x, y))
	# A string of skiffs in its wake.
	for k: int in range(3):
		var sx: float = x + 72.0 + float(k) * 16.0
		bg.draw_rect(Rect2(sx, y + 24.0, 9.0, 2.0), Color("#140a14"))
		bg.draw_rect(Rect2(sx + 4.0, y + 17.0, 1.0, 7.0), Color("#140a14"))
		bg.draw_colored_polygon(PackedVector2Array([Vector2(sx + 5.0, y + 17.0), Vector2(sx + 10.0, y + 23.0), Vector2(sx + 5.0, y + 23.0)]), Color("#1c1018"))


# The sandstorm: a wall of dust rolling in from the right, tinting and streaking what it covers.
# Drawn as strips whose opacity ramps up at the leading edge and fades out behind.
func _draw_storm() -> void:
	if not bg._ev_a.on:
		return
	var u: float = bg._ev_a.t / bg._ev_a.dur
	var body: float = 320.0
	var front: float = 500.0 - u * (520.0 + body)
	var strip: float = 16.0
	var sx: float = floorf(maxf(0.0, front) / strip) * strip
	while sx < minf(480.0, front + body):
		var k: float = (sx + strip * 0.5 - front) / body
		var env: float = clampf(k / 0.2, 0.0, 1.0) * clampf((1.0 - k) / 0.45, 0.0, 1.0)
		if env > 0.0:
			bg.draw_rect(Rect2(sx, 28.0, strip, 230.0), Color(0.55, 0.34, 0.22, (0.11 + 0.02 * sin(life * 1.7 + sx * 0.05)) * env))
		sx += strip
	# Streaks of driven sand inside the wall.
	for s2: int in range(34):
		var k2: float = fposmod(float(s2) * 0.137, 1.0)
		var px: float = front + k2 * body - fposmod(life * 220.0 + float(s2) * 37.0, 60.0)
		if px < -12.0 or px > 480.0:
			continue
		var py: float = 34.0 + fposmod(float(s2) * 37.0 + life * 7.0, 220.0)
		var env2: float = clampf(k2 / 0.2, 0.0, 1.0) * clampf((1.0 - k2) / 0.45, 0.0, 1.0)
		bg.draw_rect(Rect2(floorf(px), floorf(py), 12.0, 1.0), Color(0.92, 0.68, 0.45, 0.22 * env2))
