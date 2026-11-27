extends "res://scripts/stages/stage_background.gd"

# SOLAR CORONA: skimming a star's surface. The photosphere burns along the bottom edge (seething
# granulation, sunspots, flame tongues licking up); above it a forest of dim chromosphere spicules
# shimmers in the heat, magnetic loops arch far away with plasma beads raining down their legs,
# and faint coronal streamers fan up into a dark crimson sky.
#
# Layers (paint(), worker thread):
#   "sky"      480x270 at (0,0): crimson-black gradient, coronal streamers, a few stars
#   "loops"    768x110 at y 128, parallax 0.04: arcades of magnetic loops (heat shimmer)
#   "chromo"   512x34 at y 204, parallax 0.15: the spicule fringe (heat shimmer)
#   "surface"  512x28 at y 232, line-scrolled 0.35-0.9: photosphere granulation, sunspots
#   "fringe"   512x14 at y 222, parallax 1.0: near flame tongues licking above the limb
# Animation: plasma beads sliding down the loops, a breathing glow over the limb, rising embers,
# far sparks. Rare events: a solar flare jet with a brief flash (_ev_a), a prominence loop that
# grows and snaps (_ev_b), and a coronal mass ejection drifting up (_ev_c).
# The playfield stays dark crimson: only the bottom edge and short bursts are bright.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const LOOP_Y: float = 128.0
const CHROMO_Y: float = 204.0
const SURF_Y: float = 232.0
const FRINGE_Y: float = 222.0

var _flare_x: float = 240.0
var _prom_lx: float = 0.0      # prominence left footpoint, in chromo-layer x
var _prom_w: float = 90.0
var _cme_x: float = 200.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 10101
	var out: Dictionary = {}
	out["sky"] = _paint_sky(rng)
	_paint_loops(rng, out)
	out["chromo"] = _paint_chromo(rng)
	out["surface"] = _paint_surface(rng)
	out["fringe"] = _paint_fringe(rng)
	return out


static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#070208"))
	Painter.vgrad(sky, 20, 240, PackedColorArray([Color("#070208"), Color("#0b0309"), Color("#110409"), Color("#180508"), Color("#220707"), Color("#2e0a06"), Color("#401006")]), 0.5)
	Painter.vgrad(sky, 240, 270, PackedColorArray([Color("#401006"), Color("#6a2008")]), 0.5)
	# Coronal streamers fanning up from far below the horizon.
	for i: int in range(9):
		var ang: float = -PI * 0.5 + rng.randf_range(-0.85, 0.85)
		var origin: Vector2 = Vector2(rng.randf_range(120.0, 360.0), 430.0)
		Painter.ray_wedge(sky, origin, ang, rng.randf_range(0.03, 0.07), 440.0, Color("#341010") if i % 2 == 0 else Color("#2a0a0a"), 0.7)
	for j: int in range(5):
		var ang2: float = -PI * 0.5 + rng.randf_range(-0.6, 0.6)
		Painter.ray_wedge(sky, Vector2(rng.randf_range(160.0, 320.0), 420.0), ang2, 0.022, 420.0, Color("#4a1612"), 0.55)
	# A pale blue companion star high in the sky, with a dithered halo.
	var cs: Vector2 = Vector2(408.0, 40.0)
	for hy: int in range(int(cs.y) - 24, int(cs.y) + 25):
		for hx: int in range(int(cs.x) - 24, int(cs.x) + 25):
			var d: float = Vector2(float(hx) + 0.5, float(hy) + 0.5).distance_to(cs)
			if d < 24.0 and Painter.bayer(hx, hy) < (1.0 - d / 24.0) * 0.5:
				Painter.px(sky, hx, hy, Color("#1a1830"))
	for k2: int in range(4, 22):
		var fade: Color = Color("#3a4070") if k2 < 12 else Color("#262a4c")
		Painter.px(sky, int(cs.x) + k2, int(cs.y), fade)
		Painter.px(sky, int(cs.x) - k2, int(cs.y), fade)
		if k2 < 15:
			Painter.px(sky, int(cs.x), int(cs.y) + k2, fade)
			Painter.px(sky, int(cs.x), int(cs.y) - k2, fade)
	Painter.disc(sky, cs.x, cs.y, 9.0, Color("#262c58"))
	Painter.disc(sky, cs.x, cs.y, 7.0, Color("#4a5694"))
	Painter.disc(sky, cs.x - 0.5, cs.y - 0.5, 5.0, Color("#8090c8"))
	Painter.disc(sky, cs.x - 1.0, cs.y - 1.0, 2.6, Color("#c8d4f4"))
	# A few stars where the sky is darkest.
	for k: int in range(46):
		var sy: int = rng.randi_range(22, 120)
		var c: Color = Color("#4a3a52") if k % 4 else Color("#8a7a9a")
		Painter.px(sky, rng.randi_range(0, 479), sy, c)
	return sky


static func _paint_loops(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = 768
	var h: int = 110
	var img: Image = Painter.new_img(w, h)
	var arcs: PackedVector4Array = PackedVector4Array()
	var site_x: float = 40.0
	while site_x < float(w) - 30.0:
		var nest: int = rng.randi_range(2, 4)
		var rx0: float = rng.randf_range(24.0, 50.0)
		var ry0: float = rng.randf_range(52.0, 104.0)
		for n: int in range(nest):
			var rx: float = rx0 * (1.0 - float(n) * 0.2)
			var ry: float = ry0 * (1.0 - float(n) * 0.22)
			var base: float = float(h - 2)
			arcs.append(Vector4(site_x, base, rx, ry))
			var steps: int = int(PI * maxf(rx, ry) * 1.4)
			for i: int in range(steps + 1):
				var t: float = PI * float(i) / float(steps)
				var x: float = site_x + cos(t) * rx
				var y: float = base - sin(t) * ry
				var foot: float = 1.0 - sin(t)
				# Soft glow around the strand, then the strand, hottest near the footpoints.
				for gy: int in range(-2, 3):
					for gx: int in range(-2, 3):
						if absi(gx) + absi(gy) >= 2 and Painter.bayer(int(x) + gx, int(y) + gy) < 0.35:
							if Painter.get_px(img, int(x) + gx, int(y) + gy).a == 0.0:
								Painter.px(img, int(x) + gx, int(y) + gy, Color("#2e0a08"))
				var body: Color = Color("#8a2a0e") if foot > 0.5 else (Color("#6e200c") if foot > 0.15 else Color("#561a0a"))
				var core: Color = Color("#d8641c") if foot > 0.6 else (Color("#a83c12") if foot > 0.25 else Color("#7a2a0e"))
				Painter.px(img, int(x), int(y), core)
				Painter.px(img, int(x) + 1, int(y), body)
				Painter.px(img, int(x) - 1, int(y), body if n == 0 else core.darkened(0.3))
		site_x += rng.randf_range(110.0, 170.0)
	# Footpoint glows where the loops plant into the surface.
	for a: Vector4 in arcs:
		for side: float in [-1.0, 1.0]:
			var fx: int = int(a.x + side * a.z)
			Painter.rect(img, fx - 2, h - 5, 5, 4, Color("#9a3210"))
			Painter.rect(img, fx - 1, h - 4, 3, 3, Color("#e07a22"))
	out["loops"] = img
	out["arcs"] = arcs


static func _paint_chromo(rng: RandomNumberGenerator) -> Image:
	var w: int = 512
	var h: int = 34
	var img: Image = Painter.new_img(w, h)
	# A dense forest of thin spicules, taller ones in clumps, dim red with slightly hotter tips.
	var prof: PackedFloat32Array = Painter.profile(w, rng, 4, 6, 0.6)
	for x: int in range(w):
		var tall: float = 6.0 + prof[x] * 18.0 + rng.randf_range(0.0, 7.0)
		if x % 2 == 1:
			tall *= rng.randf_range(0.5, 0.85)
		var top: int = h - int(tall)
		for y: int in range(top, h):
			var k: float = float(y - top) / maxf(1.0, tall)
			var c: Color = Color("#5a180a") if k < 0.2 else (Color("#3a0e08") if k < 0.6 else Color("#541608"))
			img.set_pixel(x, y, c)
		Painter.px(img, x, top, Color("#8a2c10"))
	# The base merges into a glowing band just above the limb.
	for y2: int in range(h - 6, h):
		for x2: int in range(w):
			if Painter.bayer(x2, y2) < float(y2 - (h - 6)) / 6.0:
				img.set_pixel(x2, y2, Color("#9a3410"))
	return img


static func _paint_surface(rng: RandomNumberGenerator) -> Image:
	var w: int = 512
	var h: int = 28
	var img: Image = Painter.new_img(w, h)
	# Granulation: bright cells split by darker lanes, stretched flat (seen at a grazing angle).
	var nw: int = w / 2
	var na: PackedByteArray = Painter.fast_field(nw, h, 4.0, 2, 10102)
	var nb: PackedByteArray = Painter.fast_field(nw, h, 11.0, 2, 10103)
	var ramp: PackedColorArray = PackedColorArray([Color("#c04414"), Color("#e8701e"), Color("#ff9a30"), Color("#ffc450"), Color("#ffe48a"), Color("#fff6d0")])
	for y: int in range(h):
		var depth: float = float(y) / float(h - 1)   # 0 = far limb, 1 = right below us
		for x: int in range(w):
			var a: float = float(na[y * nw + (x / 2)]) / 255.0
			var b: float = float(nb[y * nw + (x / 2)]) / 255.0
			var lane: float = 1.0 - clampf(absf(a - 0.5) * 6.0, 0.0, 1.0)
			var v: float = 0.52 + depth * 0.4 + (b - 0.5) * 0.25 - lane * 0.32
			img.set_pixel(x, y, Painter.ramp_pick(ramp, v, x, y))
	# Sunspots: dark umbra in a rusty penumbra, squashed by perspective.
	for s: int in range(3):
		var sx: float = rng.randf_range(0.0, float(w))
		var sy: float = rng.randf_range(8.0, 20.0)
		var sr: float = rng.randf_range(6.0, 12.0)
		Painter.ellipse(img, sx, sy, sr * 1.6, sr * 0.36, Color("#8a2a0c"))
		Painter.ellipse(img, sx, sy, sr * 1.2, sr * 0.26, Color("#6a1c08"))
		Painter.ellipse(img, sx - 1.0, sy, sr * 0.6, sr * 0.16, Color("#2a0804"))
	# The limb: a bright rim line where the surface meets the chromosphere.
	Painter.rect(img, 0, 0, w, 1, Color("#fff0b0"))
	Painter.rect(img, 0, 1, w, 1, Color("#ffc450"))
	return img


static func _paint_fringe(rng: RandomNumberGenerator) -> Image:
	# Sparse tongues of flame rising from the limb (their roots tuck under the surface layer).
	var w: int = 512
	var h: int = 14
	var img: Image = Painter.new_img(w, h)
	var x: int = 0
	while x < w:
		var tw: int = rng.randi_range(2, 7)
		var th: int = rng.randi_range(3, 13) if rng.randf() < 0.7 else rng.randi_range(2, 5)
		var lean: float = rng.randf_range(-0.45, 0.45)
		for y: int in range(th):
			var k: float = float(y) / float(th)
			var half: float = float(tw) * 0.5 * (1.0 - k * 0.85)
			var cx: float = float(x) + float(tw) * 0.5 + lean * float(y)
			var c: Color = Color("#fff0b0") if k < 0.3 else (Color("#ffb848") if k < 0.65 else Color("#e8641c"))
			Painter.span(img, int(cx - half), int(cx + half), h - 1 - y, c)
		x += tw + (rng.randi_range(1, 5) if rng.randf() < 0.45 else rng.randi_range(10, 34))
	return img


# --- Animation ---------------------------------------------------------------------------------

func reset() -> void:
	# Embers rising off the surface.
	drift_a.y0 = 60.0
	drift_a.y1 = 252.0
	drift_a.setup(30, rng, -14.0, -4.0, -26.0, -10.0)
	drift_a.par = 0.5
	drift_a.sway = 3.0
	drift_a.sway_hz = 1.3
	drift_a.blink = 0.7
	drift_a.duty = 0.8
	drift_a.cols = PackedColorArray([Color(1.0, 0.62, 0.22, 0.55), Color(1.0, 0.8, 0.4, 0.45), Color(0.9, 0.35, 0.12, 0.5)])
	# Faint far sparks drifting with the plasma.
	drift_b.y0 = 120.0
	drift_b.y1 = 228.0
	drift_b.setup(20, rng, -6.0, -2.0, -6.0, -1.0)
	drift_b.par = 0.1
	drift_b.cols = PackedColorArray([Color(0.7, 0.25, 0.1, 0.45), Color(0.55, 0.18, 0.08, 0.5)])
	bg._ev_a.arm(rng, 13.0, 21.0, 4.0, 8.0)    # solar flare
	bg._ev_b.arm(rng, 18.0, 28.0, 8.0, 13.0)   # prominence loop
	bg._ev_c.arm(rng, 20.0, 32.0, 12.0, 18.0)  # coronal mass ejection


func update() -> void:
	if bg._ev_a.tick(dl, rng):
		bg._ev_a.dur = 2.6
		_flare_x = rng.randf_range(70.0, 410.0)
		for i: int in range(14):
			fx_spawn(StarfieldBg.Fx.SPARK, _flare_x + rng.randf_range(-4.0, 4.0), SURF_Y - 2.0, rng.randf_range(-50.0, 50.0), rng.randf_range(-150.0, -70.0), rng.randf_range(0.8, 1.5), 0.3)
		for j: int in range(8):
			fx_spawn(StarfieldBg.Fx.BOMB, _flare_x, SURF_Y - 4.0, rng.randf_range(-30.0, 30.0), rng.randf_range(-110.0, -60.0), rng.randf_range(1.0, 1.6), 0.3)
	if bg._ev_b.tick(dl, rng):
		bg._ev_b.dur = 5.6
		_prom_w = rng.randf_range(70.0, 120.0)
		_prom_lx = fposmod(off(0.15, 512.0) + rng.randf_range(60.0, 300.0), 512.0)
	if bg._ev_b.on:
		var u: float = bg._ev_b.t / bg._ev_b.dur
		if u > 0.7 and u - dl / bg._ev_b.dur <= 0.7:
			var top: Vector2 = _prom_point(0.5, 1.0)
			for k: int in range(10):
				fx_spawn(StarfieldBg.Fx.BOMB, top.x, top.y, rng.randf_range(-40.0, 40.0), rng.randf_range(-70.0, -20.0), rng.randf_range(1.0, 1.8), 0.15)
	if bg._ev_c.tick(dl, rng):
		bg._ev_c.dur = 7.5
		_cme_x = rng.randf_range(120.0, 380.0)


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	_draw_cme()
	layer_wobble("loops", LOOP_Y, 0.04, 4, 1.0, 0.6, 1.6, 30)
	_draw_beads()
	_draw_prominence()
	drift_draw(drift_b)
	layer_wobble("chromo", CHROMO_Y, 0.15, 2, 1.0, 0.9, 3.4, 0)
	# Bloom over the limb, breathing.
	var g: float = 0.5 + 0.5 * sin(life * 1.4)
	for band: int in range(6):
		var by: float = 202.0 + float(band) * 5.0
		bg.draw_rect(Rect2(0.0, by, 480.0, 5.0), Color(1.0, 0.5 + 0.04 * float(band), 0.16, (0.012 + 0.016 * float(band)) * (0.8 + 0.4 * g)))
	_draw_flare()
	layer_wobble("fringe", FRINGE_Y, 1.0, 2, 1.5, 1.3, 7.0, 0)
	layer_rows("surface", SURF_Y, 2, 0.35, 0.9)
	fx_draw()
	drift_draw(drift_a)


# Plasma beads draining down both legs of every loop on screen (coronal rain).
func _draw_beads() -> void:
	var arcs: PackedVector4Array = meta.get("arcs", PackedVector4Array())
	var o: float = off(0.04, 768.0)
	for i: int in range(arcs.size()):
		var a: Vector4 = arcs[i]
		var cx: float = wrap_x(a.x, o, 768.0)
		if cx < -a.z - 4.0 or cx > 480.0 + a.z:
			continue
		for b: int in range(2):
			var u: float = fposmod(life * (0.07 + 0.02 * float(i % 3)) + float(b) * 0.5 + float(i) * 0.31, 1.0)
			# u 0 -> 1 runs from the loop top down one leg; alternate legs per bead.
			var t: float = PI * 0.5 + (u * PI * 0.5) * (1.0 if b == 0 else -1.0)
			var x: float = cx + cos(t) * a.z
			var y: float = LOOP_Y + a.y - sin(t) * a.w
			var al: float = 0.55 + 0.45 * sin(u * PI)
			bg.draw_rect(Rect2(floorf(x) - 1.0, floorf(y) - 1.0, 3.0, 3.0), Color(1.0, 0.5, 0.15, 0.3 * al))
			bg.draw_rect(Rect2(floorf(x), floorf(y), 1.0, 1.0), Color(1.0, 0.9, 0.6, al))


# A point on the prominence arc: s 0..1 from the left foot to the right, scaled by growth g.
func _prom_point(s: float, g: float) -> Vector2:
	var lx: float = wrap_x(_prom_lx, off(0.15, 512.0), 512.0)
	var t: float = PI * (1.0 - s)
	var cx: float = lx + _prom_w * 0.5
	return Vector2(cx + cos(t) * _prom_w * 0.5, CHROMO_Y + 30.0 - sin(t) * _prom_w * 0.85 * g)


func _draw_prominence() -> void:
	if not bg._ev_b.on:
		return
	var u: float = bg._ev_b.t / bg._ev_b.dur
	var grow: float = clampf(u / 0.45, 0.0, 1.0)
	var bright: float = clampf((u - 0.3) / 0.3, 0.0, 1.0)
	var fade: float = 1.0 if u < 0.7 else clampf(1.0 - (u - 0.7) / 0.3, 0.0, 1.0)
	var pts_l: PackedVector2Array = PackedVector2Array()
	var pts_r: PackedVector2Array = PackedVector2Array()
	var n: int = 18
	for i: int in range(n + 1):
		var s: float = float(i) / float(n) * 0.5
		if u < 0.7:
			# Growing: both legs rise toward the top, joining once fully grown.
			if s > grow * 0.5:
				break
			pts_l.append(_prom_point(s, grow))
			pts_r.append(_prom_point(1.0 - s, grow))
		else:
			# Snapped: the halves fall back, shortening toward their feet.
			var keep: float = 0.5 * fade
			if s > keep:
				break
			var droop: Vector2 = Vector2(0.0, (1.0 - fade) * 20.0 * s * 2.0)
			pts_l.append(_prom_point(s, 1.0) + droop)
			pts_r.append(_prom_point(1.0 - s, 1.0) + droop)
	var glow: Color = Color(1.0, 0.35, 0.1, (0.18 + 0.12 * bright) * fade)
	var outer: Color = Color(1.0, 0.5, 0.15, (0.55 + 0.25 * bright) * fade)
	var inner: Color = Color(1.0, 0.9, 0.6, (0.6 + 0.4 * bright) * fade)
	for pts: PackedVector2Array in [pts_l, pts_r]:
		if pts.size() >= 2:
			bg.draw_polyline(pts, glow, 7.0)
			bg.draw_polyline(pts, outer, 3.0)
			bg.draw_polyline(pts, inner, 1.0)


func _draw_flare() -> void:
	if not bg._ev_a.on:
		return
	var u: float = bg._ev_a.t / bg._ev_a.dur
	var rise: float = clampf(u / 0.3, 0.0, 1.0)
	var fade: float = clampf(1.0 - (u - 0.35) / 0.65, 0.0, 1.0)
	var h: float = 140.0 * (1.0 - pow(1.0 - rise, 2.0))
	var base: Vector2 = Vector2(floorf(_flare_x), SURF_Y + 1.0)
	var bend: float = 46.0 * (1.0 if int(_flare_x) % 2 == 0 else -1.0)
	# A curving jet: a polygon along a bent spine, wide at the root, thin at the top.
	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	var core_l: PackedVector2Array = PackedVector2Array()
	var core_r: PackedVector2Array = PackedVector2Array()
	for i: int in range(9):
		var sv: float = float(i) / 8.0
		var spine: Vector2 = base + Vector2(bend * sv * sv, -h * sv) + Vector2(sin(life * 19.0 + sv * 6.0) * 1.5 * sv, 0.0)
		var wid: float = lerpf(10.0, 2.0, sv)
		left.append(spine - Vector2(wid, 0.0))
		right.insert(0, spine + Vector2(wid, 0.0))
		core_l.append(spine - Vector2(wid * 0.4, 0.0))
		core_r.insert(0, spine + Vector2(wid * 0.4, 0.0))
	bg.draw_colored_polygon(left + right, Color(1.0, 0.45, 0.12, 0.4 * fade))
	bg.draw_colored_polygon(core_l + core_r, Color(1.0, 0.92, 0.65, 0.75 * fade))
	var head: Vector2 = base + Vector2(bend, -h)
	bg.draw_circle(head, 4.0 + 8.0 * rise * (1.0 - fade * 0.4), Color(1.0, 0.7, 0.3, 0.35 * fade))
	bg.draw_circle(head, 2.0 + 2.0 * rise, Color(1.0, 0.95, 0.8, 0.8 * fade))
	bg.draw_circle(base, 10.0 + 8.0 * rise, Color(1.0, 0.8, 0.4, 0.3 * fade))
	# The flash: a short, low-alpha wash over the screen at the eruption's start.
	var fl: float = maxf(0.0, 1.0 - u * 5.0)
	if fl > 0.0:
		bg.draw_rect(Rect2(0.0, 20.0, 480.0, 238.0), Color(1.0, 0.88, 0.65, 0.09 * fl))


func _draw_cme() -> void:
	if not bg._ev_c.on:
		return
	var u: float = bg._ev_c.t / bg._ev_c.dur
	var r: float = 12.0 + u * 120.0
	var c: Vector2 = Vector2(_cme_x - u * 60.0, 230.0 - u * 150.0)
	var a: float = sin(u * PI) * 0.3
	# The shell: a ragged arc whose radius ripples, over a soft wide glow.
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	for i: int in range(41):
		var ang: float = PI * 0.95 + PI * 1.1 * float(i) / 40.0
		var rip: float = sin(ang * 7.0 + life * 2.0) * 3.0 + sin(ang * 13.0 - life * 3.0) * 1.5
		outer.append(c + Vector2.from_angle(ang) * (r + rip))
		inner.append(c + Vector2.from_angle(ang) * (r * 0.78 + rip * 0.6))
	bg.draw_polyline(outer, Color(1.0, 0.4, 0.15, a * 0.45), 6.0)
	bg.draw_polyline(outer, Color(1.0, 0.62, 0.32, a), 1.0)
	bg.draw_polyline(inner, Color(1.0, 0.75, 0.45, a * 0.5), 1.0)
	# Short filaments streaming back from the shell.
	for f: int in range(6):
		var ang2: float = PI * 1.15 + float(f) * PI * 0.14
		var p0: Vector2 = c + Vector2.from_angle(ang2) * r * 0.78
		bg.draw_line(p0, p0 + Vector2.from_angle(ang2 + PI) * (14.0 + 6.0 * float(f % 3)), Color(1.0, 0.55, 0.25, a * 0.45), 1.0)
