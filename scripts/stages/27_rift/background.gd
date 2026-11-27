extends "res://scripts/stages/stage_background.gd"

# STAGE 27 background: the quantum rift. A violet void folded by faint time currents. Far off
# hangs impossible geometry (a Penrose triangle, an endless stair, wire cubes, a shattered halo)
# and stopped clocks whose hands run at the wrong speeds, with a lagging amber echo of all of it
# wavering behind. Nearer, floating shards are windows onto other times (a red giant's sky, a
# blue world, a golden dawn, a deep starfield, an aurora), their edges lit with rift light, and
# jagged rifts of white light unzip and seal in the dark. Dust drifts at three different time
# rates: forwards up high, backwards (amber) through the middle, and in stuttering skips low
# down. Along the bottom, broken ruins float with debris frozen in mid-fall.
# Rare events: a TIME SKIP (the distance stutters backwards with tear lines and snaps back), a
# RIFT TEAR (a great crack opens across the upper sky onto amber light and seals), and a GHOST
# FLEET from another time crossing far away.
#
# Layers: "sky" 480x270; "far" 768x200 at y 26 (0.03); "shards" 768x190 at y 34 (0.14);
# "ruins" 768x46 at y 212 (0.8).

const Painter = preload("res://scripts/stage_bg_painter.gd")

const W: float = 768.0
const FAR_Y: float = 26.0
const FAR_F: float = 0.03
const RIFT_F: float = 0.07
const SHARD_Y: float = 34.0
const SHARD_F: float = 0.14
const RUIN_Y: float = 212.0
const RUIN_F: float = 0.8
const STUTTER: int = 22
const SKIP_DUR: float = 0.75
const TEAR_DUR: float = 3.4
const FLEET_DUR: float = 7.5

const VOID: Color = Color("#05030c")
const RIM: Color = Color("#c8c0f0")

var _ev_wait_a: float = 9.0   # time skip
var _ev_wait_b: float = 5.0   # rift tear
var _ev_wait_c: float = 14.0  # ghost fleet
var _skip_t: float = -1.0
var _skip_y: PackedFloat32Array = PackedFloat32Array()
var _tear_t: float = -1.0
var _fleet_t: float = -1.0
var _fleet_y: float = 80.0
var _sx: PackedFloat32Array = PackedFloat32Array()
var _sy: PackedFloat32Array = PackedFloat32Array()
var _svx: PackedFloat32Array = PackedFloat32Array()
var _step_t: float = 0.0
var _step_acc: float = 0.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2727
	var out: Dictionary = {}
	_paint_sky(out, rng)
	_paint_far(out, rng)
	_paint_shards(out, rng)
	_paint_rifts(out, rng)
	_paint_ruins(out, rng)
	_paint_tear(out, rng)
	_paint_fleet(out)
	return out


# The void: violet folds from a noise field, faint sinuous time currents, dim stars.
static func _paint_sky(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(VOID)
	var neb: PackedByteArray = Painter.fast_field(480, 270, 110.0, 4, 2727)
	var ramp: PackedColorArray = PackedColorArray([Color("#05030c"), Color("#08051a"), Color("#0c0724"), Color("#110a2e"), Color("#170e3a")])
	for y: int in range(22, 260):
		for x: int in range(480):
			var v: float = float(neb[y * 480 + x]) / 255.0
			var k: float = clampf((v - 0.36) * 2.1, 0.0, 1.0)
			# time currents: thin sinuous bands a shade brighter
			var cur: float = sin(float(x) * 0.013 + float(y) * 0.045 + 2.2 * sin(float(x) * 0.006))
			if cur > 0.94:
				k = minf(1.0, k + 0.25)
			sky.set_pixel(x, y, Painter.ramp_pick(ramp, k, x, y))
	for i: int in range(130):
		var sx: int = rng.randi_range(0, 479)
		var sy: int = rng.randi_range(24, 256)
		var col: Color = Color("#3e386a")
		match i % 9:
			0:
				col = Color("#a8a0e0")
			1:
				col = Color("#2e6a80")
			2:
				col = Color("#7a5a2a")
		Painter.px(sky, sx, sy, col)
	out["sky"] = sky


# Far: impossible geometry and stopped clocks, dim violet with faint cyan/amber rims.
static func _paint_far(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var img: Image = Painter.new_img(768, 200)
	var fill: Color = Color("#140f2e")
	var face: Color = Color("#221a4c")
	var dark: Color = Color("#0e0a22")
	var edge: Color = Color("#2e2660")
	# Penrose triangle
	var p: Array[Vector2] = [Vector2(70.0, 150.0), Vector2(150.0, 20.0), Vector2(230.0, 150.0)]
	var cen: Vector2 = (p[0] + p[1] + p[2]) / 3.0
	var q: Array[Vector2] = []
	var m: Array[Vector2] = []
	for i: int in range(3):
		var d: Vector2 = (cen - p[i]).normalized()
		q.append(p[i] + d * 30.0)
		m.append(p[i] + d * 15.0)
	var rims: Array[Color] = [Color("#2e6a88"), Color("#463a88"), Color("#7a5426")]
	for b: int in range(3):
		_bar(img, p, q, m, b, 0.0, 1.0, face, dark, rims[b])
	_bar(img, p, q, m, 0, 0.0, 0.3, face, dark, rims[0])
	# a tesseract: a cube inside a cube, every corner joined to its twin
	var tc: Vector2 = Vector2(410.0, 104.0)
	var outer: Array[Vector2] = _cube_pts(tc, 30.0, Vector2(14.0, -11.0))
	var inner: Array[Vector2] = _cube_pts(tc + Vector2(3.0, -2.0), 13.0, Vector2(6.0, -5.0))
	var t_edges: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 0), Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 4), Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7)]
	for e0: Vector2i in t_edges:
		Painter.line(img, int(outer[e0.x].x), int(outer[e0.x].y), int(outer[e0.y].x), int(outer[e0.y].y), Color("#1e1a44"))
		Painter.line(img, int(inner[e0.x].x), int(inner[e0.x].y), int(inner[e0.y].x), int(inner[e0.y].y), Color("#262052"))
	for v: int in range(8):
		Painter.line(img, int(outer[v].x), int(outer[v].y), int(inner[v].x), int(inner[v].y), Color("#18143a") if v % 2 == 0 else Color("#1a3448"))
		Painter.px(img, int(outer[v].x), int(outer[v].y), Color("#3a3270"))
	# wire cubes
	for cube: int in range(2):
		var cc: Vector2 = Vector2(560.0 + 130.0 * float(cube), 60.0 + 70.0 * float(cube))
		var sz: float = 22.0 - 6.0 * float(cube)
		var doff: Vector2 = Vector2(sz * 0.55, -sz * 0.45)
		var f0: Array[Vector2] = [cc + Vector2(-sz, -sz) * 0.5, cc + Vector2(sz, -sz) * 0.5, cc + Vector2(sz, sz) * 0.5, cc + Vector2(-sz, sz) * 0.5]
		var col: Color = Color("#2a2458")
		for e: int in range(4):
			var a2: Vector2 = f0[e]
			var b3: Vector2 = f0[(e + 1) % 4]
			Painter.line(img, int(a2.x), int(a2.y), int(b3.x), int(b3.y), col)
			Painter.line(img, int(a2.x + doff.x), int(a2.y + doff.y), int(b3.x + doff.x), int(b3.y + doff.y), col)
			Painter.line(img, int(a2.x), int(a2.y), int(a2.x + doff.x), int(a2.y + doff.y), Color("#3a3474") if e == 1 else col)
	# a shattered halo
	var hc: Vector2 = Vector2(300.0, 70.0)
	for seg: int in range(9):
		var a0: float = float(seg) * TAU / 9.0 + rng.randf_range(0.0, 0.2)
		var a1: float = a0 + rng.randf_range(0.3, 0.5)
		var r: float = 44.0 + rng.randf_range(-3.0, 3.0)
		for k: int in range(30):
			var aa: float = lerpf(a0, a1, float(k) / 29.0)
			Painter.px(img, int(hc.x + cos(aa) * r), int(hc.y + sin(aa) * r * 0.5), Color("#2a2252"))
	# clock faces (hands are drawn live)
	var clocks: PackedVector3Array = PackedVector3Array([Vector3(250.0, 150.0, 22.0), Vector3(660.0, 150.0, 17.0), Vector3(520.0, 168.0, 11.0)])
	for c: Vector3 in clocks:
		Painter.disc(img, c.x, c.y, c.z + 2.0, Color("#0a0818"))
		Painter.disc(img, c.x, c.y, c.z, dark)
		for t: int in range(12):
			var ta: float = float(t) * TAU / 12.0
			var r0: float = c.z - (4.0 if t % 3 == 0 else 2.0)
			Painter.line(img, int(c.x + cos(ta) * r0), int(c.y + sin(ta) * r0), int(c.x + cos(ta) * (c.z - 1.0)), int(c.y + sin(ta) * (c.z - 1.0)), Color("#4a3e82") if t % 3 == 0 else Color("#2e2660"))
		for ra: int in range(int(c.z * 6.0)):
			var ang: float = float(ra) / (c.z * 6.0) * TAU
			Painter.px(img, int(c.x + cos(ang) * (c.z + 1.0)), int(c.y + sin(ang) * (c.z + 1.0)), Color("#3a2e6a"))
	out["far"] = img
	out["clocks"] = clocks


static func _bar(img: Image, p: Array[Vector2], q: Array[Vector2], m: Array[Vector2], i: int, t0: float, t1: float, light: Color, dark: Color, rim: Color) -> void:
	var j: int = (i + 1) % 3
	var a0: Vector2 = p[i].lerp(p[j], t0)
	var a1: Vector2 = p[i].lerp(p[j], t1)
	var b0: Vector2 = m[i].lerp(m[j], t0)
	var b1: Vector2 = m[i].lerp(m[j], t1)
	var c0: Vector2 = q[i].lerp(q[j], t0)
	var c1: Vector2 = q[i].lerp(q[j], t1)
	Painter.poly(img, PackedVector2Array([a0, a1, b1, b0]), light)
	Painter.poly(img, PackedVector2Array([b0, b1, c1, c0]), dark)
	Painter.line(img, int(a0.x), int(a0.y), int(a1.x), int(a1.y), rim)
	Painter.line(img, int(c0.x), int(c0.y), int(c1.x), int(c1.y), Color("#08061a"))


# A cube's 8 corners: front face (0-3) and the back face (4-7) shifted by depth.
static func _cube_pts(c: Vector2, half: float, depth: Vector2) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for k: int in range(2):
		var o: Vector2 = c + depth * (float(k) - 0.5)
		pts.append(o + Vector2(-half, -half))
		pts.append(o + Vector2(half, -half))
		pts.append(o + Vector2(half, half))
		pts.append(o + Vector2(-half, half))
	return pts


static func _inside(pts: PackedVector2Array, x: float, y: float) -> bool:
	var c: bool = false
	var n: int = pts.size()
	var j: int = n - 1
	for i: int in range(n):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[j]
		if ((a.y > y) != (b.y > y)) and x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x:
			c = not c
		j = i
	return c


# Shards: windows onto other times, dimmed so the playfield stays dark, edged with rift light.
static func _paint_shards(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var img: Image = Painter.new_img(768, 190)
	var polys: Array[PackedVector2Array] = []
	var dim: Color = Color("#0a0818")
	for i: int in range(7):
		var cx: float = float(i) * 110.0 + rng.randf_range(20.0, 80.0)
		var cy: float = rng.randf_range(24.0, 60.0) if i % 2 == 0 else rng.randf_range(120.0, 160.0)
		var rad: float = rng.randf_range(15.0, 26.0)
		var n: int = rng.randi_range(4, 6)
		var pts: PackedVector2Array = PackedVector2Array()
		var a0: float = rng.randf_range(0.0, TAU)
		for k: int in range(n):
			var a: float = a0 + TAU * (float(k) + rng.randf_range(-0.25, 0.25)) / float(n)
			var rr: float = rad * rng.randf_range(0.65, 1.15)
			pts.append(Vector2(cx + cos(a) * rr, cy + sin(a) * rr * 1.2))
		polys.append(pts)
		var kind: int = i % 5
		var x0: int = int(cx - rad * 1.3)
		var x1: int = int(cx + rad * 1.3)
		var y0: int = maxi(0, int(cy - rad * 1.5))
		var y1: int = mini(189, int(cy + rad * 1.5))
		var sun: Vector2 = Vector2(cx + rad * 0.5, cy - rad * 0.4)
		for y: int in range(y0, y1 + 1):
			for x: int in range(x0, x1 + 1):
				if not _inside(pts, float(x) + 0.5, float(y) + 0.5):
					continue
				var u: float = (float(y) - (cy - rad)) / (rad * 2.4)
				var col: Color = Color.BLACK
				match kind:
					0:  # a red giant's sky
						col = Color("#3a0a14").lerp(Color("#120410"), u)
						var ds: float = Vector2(float(x), float(y)).distance_to(sun)
						if ds < rad * 0.7:
							col = Color("#a02818") if ds < rad * 0.6 else Color("#6a1a14")
					1:  # a blue world: a planet's rim low in the window
						col = Color("#061428").lerp(Color("#0a2a48"), u)
						var dp: float = Vector2(float(x), float(y)).distance_to(Vector2(cx - rad * 0.2, cy + rad * 2.2))
						if dp < rad * 1.9:
							col = Color("#0e3a58") if dp > rad * 1.8 else Color("#08203a")
					2:  # a golden dawn with cloud bands
						col = Color("#4a2a0c").lerp(Color("#140a06"), u)
						if sin(float(y) * 0.5 + sin(float(x) * 0.15) * 2.0) > 0.7:
							col = col.lerp(Color("#7a4a18"), 0.6)
					3:  # a deep starfield
						col = Color("#060a22")
						if Painter.bayer(x * 7, y * 3) > 0.94:
							col = Color("#6a78c0")
					_:  # an aurora
						col = Color("#04121a")
						var band: float = sin(float(x) * 0.18 + float(y) * 0.05) * 0.5 + 0.5
						if absf(float(y) - (cy - rad * 0.2 + band * rad * 0.6)) < 3.0:
							col = Color("#1a6a48") if Painter.bayer(x, y) < 0.6 else Color("#0e3a2a")
				col = col.lerp(dim, 0.42)
				Painter.px(img, x, y, col)
		# rift-light edges, an outer dark line, and a glint
		for k2: int in range(n):
			var a3: Vector2 = pts[k2]
			var b3: Vector2 = pts[(k2 + 1) % n]
			Painter.line(img, int(a3.x), int(a3.y), int(b3.x), int(b3.y), Color("#8a80c8") if k2 % 2 == 0 else Color("#5a5098"))
		var g0: Vector2 = pts[0].lerp(pts[1], 0.3)
		Painter.px(img, int(g0.x), int(g0.y), RIM)
		# a crack through some of them
		if i % 3 == 1:
			var c0: Vector2 = pts[0].lerp(cen_of(pts), 0.2)
			var c1: Vector2 = pts[n / 2].lerp(cen_of(pts), 0.2)
			Painter.line(img, int(c0.x), int(c0.y), int(c1.x), int(c1.y), Color("#4a4288"))
	out["shards"] = img
	out["shard_polys"] = polys


static func cen_of(pts: PackedVector2Array) -> Vector2:
	var s: Vector2 = Vector2.ZERO
	for v: Vector2 in pts:
		s += v
	return s / float(maxi(1, pts.size()))


# Small rifts: jagged vertical cracks (as polylines round their centre), kept out of the middle.
static func _paint_rifts(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var lines: Array[PackedVector2Array] = []
	var info: PackedVector4Array = PackedVector4Array()  # x, y, period, phase
	for i: int in range(7):
		var h: float = rng.randf_range(26.0, 60.0)
		var pts: PackedVector2Array = PackedVector2Array()
		var x: float = 0.0
		var y: float = -h * 0.5
		while y < h * 0.5:
			pts.append(Vector2(roundf(x), roundf(y)))
			y += rng.randf_range(3.0, 6.0)
			x = clampf(x + rng.randf_range(-3.5, 3.5), -6.0, 6.0)
		pts.append(Vector2(roundf(x), roundf(h * 0.5)))
		lines.append(pts)
		var ry: float = rng.randf_range(52.0, 92.0) if i % 2 == 0 else rng.randf_range(176.0, 214.0)
		info.append(Vector4(float(i) * 110.0 + rng.randf_range(10.0, 90.0), ry, rng.randf_range(4.5, 8.0), rng.randf_range(0.0, 1.0)))
	out["rift_lines"] = lines
	out["rift_info"] = info


# Ruins along the bottom: floating fractured ground, broken pillars, gears, a toppled hourglass.
static func _paint_ruins(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 46
	var img: Image = Painter.new_img(w, h)
	var body: Color = Color("#0a0716")
	var rim: Color = Color("#2a2052")
	var glints: PackedVector2Array = PackedVector2Array()
	var x: int = 0
	while x < w:
		var cw: int = rng.randi_range(40, 90)
		var top: float = rng.randf_range(22.0, 30.0)
		var pts: PackedVector2Array = PackedVector2Array()
		pts.append(Vector2(float(x), top + rng.randf_range(0.0, 3.0)))
		pts.append(Vector2(float(x + cw) * 0.5 + float(x) * 0.5, top - rng.randf_range(0.0, 3.0)))
		pts.append(Vector2(float(x + cw), top + rng.randf_range(0.0, 3.0)))
		pts.append(Vector2(float(x + cw) - 6.0, float(h) - rng.randf_range(4.0, 8.0)))
		pts.append(Vector2(float(x) + float(cw) * 0.5, float(h) + 2.0))
		pts.append(Vector2(float(x) + 5.0, float(h) - rng.randf_range(3.0, 9.0)))
		Painter.poly(img, pts, body)
		Painter.line(img, int(pts[0].x), int(pts[0].y), int(pts[1].x), int(pts[1].y), rim)
		Painter.line(img, int(pts[1].x), int(pts[1].y), int(pts[2].x), int(pts[2].y), rim)
		# what stands on the fragment
		var mid: int = x + cw / 2
		match rng.randi_range(0, 3):
			0:  # broken pillar
				var ph: int = rng.randi_range(10, 20)
				Painter.rect(img, mid - 4, int(top) - ph, 8, ph, Color("#100c22"))
				Painter.vline(img, mid - 4, int(top) - ph, int(top), Color("#241c48"))
				Painter.line(img, mid - 4, int(top) - ph, mid + 3, int(top) - ph + 3, Color("#2e2660"))
				Painter.line(img, mid, int(top) - ph + 4, mid - 2, int(top) - 2, Color("#06040e"))
			1:  # gear fragment
				var gr: float = rng.randf_range(6.0, 9.0)
				Painter.disc(img, float(mid), top - gr * 0.6, gr, Color("#100c22"))
				for tt: int in range(8):
					var ga: float = float(tt) * TAU / 8.0
					Painter.rect(img, int(float(mid) + cos(ga) * (gr + 1.0)) - 1, int(top - gr * 0.6 + sin(ga) * (gr + 1.0)) - 1, 2, 2, Color("#1c1638"))
				Painter.disc(img, float(mid), top - gr * 0.6, 2.0, Color("#2a2052"))
			2:  # crystal growth
				for cr: int in range(3):
					var cx: float = float(mid - 6 + cr * 6)
					var chh: float = rng.randf_range(6.0, 12.0)
					var cc: Color = Color("#1a4a5a") if cr % 2 == 0 else Color("#5a3a14")
					Painter.poly(img, PackedVector2Array([Vector2(cx - 2.0, top), Vector2(cx, top - chh), Vector2(cx + 2.0, top)]), cc)
					glints.append(Vector2(cx, top - chh + 1.0))
			_:  # a toppled hourglass
				Painter.poly(img, PackedVector2Array([Vector2(float(mid) - 10.0, top - 9.0), Vector2(float(mid), top - 5.0), Vector2(float(mid) - 10.0, top - 1.0)]), Color("#141030"))
				Painter.poly(img, PackedVector2Array([Vector2(float(mid) + 10.0, top - 9.0), Vector2(float(mid), top - 5.0), Vector2(float(mid) + 10.0, top - 1.0)]), Color("#141030"))
				Painter.rect(img, mid - 12, int(top) - 10, 2, 10, Color("#241c48"))
				Painter.rect(img, mid + 10, int(top) - 10, 2, 10, Color("#241c48"))
				Painter.rect(img, mid + 4, int(top) - 4, 5, 2, Color("#5a3a14"))
				glints.append(Vector2(float(mid) + 6.0, top - 4.0))
		x += cw + rng.randi_range(6, 26)
	out["ruins"] = img
	out["ruin_glints"] = glints
	var debris: PackedVector3Array = PackedVector3Array()
	for d: int in range(16):
		debris.append(Vector3(rng.randf_range(0.0, float(w)), rng.randf_range(-14.0, 14.0), rng.randf_range(1.0, 3.0)))
	out["debris"] = debris


# The great tear: a jagged upper and lower edge across the sky (offsets from its centre line).
static func _paint_tear(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var top: PackedFloat32Array = PackedFloat32Array()
	var bot: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(61):
		var spike: bool = rng.randf() < 0.18
		top.append(rng.randf_range(0.9, 1.4) if spike else rng.randf_range(0.25, 0.75))
		bot.append(rng.randf_range(0.9, 1.3) if rng.randf() < 0.18 else rng.randf_range(0.25, 0.75))
	out["tear_top"] = top
	out["tear_bot"] = bot


# The ghost fleet's silhouette: a long warship, drawn amber and translucent when it passes.
static func _paint_fleet(out: Dictionary) -> void:
	var img: Image = Painter.new_img(30, 10)
	Painter.poly(img, PackedVector2Array([Vector2(0, 5), Vector2(8, 2), Vector2(26, 1), Vector2(30, 4), Vector2(30, 7), Vector2(24, 9), Vector2(8, 8)]), Color("#b06a18"))
	Painter.poly(img, PackedVector2Array([Vector2(2, 5), Vector2(8, 3), Vector2(26, 2), Vector2(26, 5)]), Color("#ffb030"))
	Painter.rect(img, 12, 0, 6, 2, Color("#c07a22"))
	Painter.span(img, 2, 26, 2, Color("#ffe8b0"))
	Painter.span(img, 0, 2, 5, Color("#fff0c8"))
	Painter.rect(img, 28, 3, 2, 4, Color("#fff6e0"))
	out["fleet"] = img


# --- animation ----------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 34.0
	drift_a.y1 = 98.0
	drift_a.setup(18, rng, -16.0, -6.0, -2.0, 2.0)
	drift_a.par = 0.35
	drift_a.cols = PackedColorArray([Color(0.35, 0.9, 1.0, 0.45), Color(0.6, 0.85, 1.0, 0.3)])
	drift_b.y0 = 104.0
	drift_b.y1 = 166.0
	drift_b.setup(16, rng, 14.0, 26.0, -2.0, 2.0)
	drift_b.par = 0.0
	drift_b.sway = 1.5
	drift_b.sway_hz = 0.7
	drift_b.cols = PackedColorArray([Color(1.0, 0.7, 0.25, 0.4), Color(1.0, 0.85, 0.5, 0.28)])
	_sx.resize(STUTTER)
	_sy.resize(STUTTER)
	_svx.resize(STUTTER)
	for i: int in range(STUTTER):
		_sx[i] = rng.randf_range(0.0, 480.0)
		_sy[i] = rng.randf_range(172.0, 244.0)
		_svx[i] = rng.randf_range(-40.0, -18.0)
	_skip_t = -1.0
	_tear_t = -1.0
	_fleet_t = -1.0
	_ev_wait_a = rng.randf_range(7.0, 12.0)
	_ev_wait_b = rng.randf_range(4.0, 8.0)
	_ev_wait_c = rng.randf_range(12.0, 18.0)


func update() -> void:
	# dust low down moves in skips: time there only ticks four times a second
	_step_t -= dl
	_step_acc += ds * 0.5
	if _step_t <= 0.0:
		_step_t = 0.25
		for i: int in range(STUTTER):
			_sx[i] += _svx[i] * 0.25 - _step_acc
			if _sx[i] < -4.0:
				_sx[i] += 488.0
				_sy[i] = rng.randf_range(172.0, 244.0)
		_step_acc = 0.0
	if _skip_t < 0.0:
		_ev_wait_a -= dl
		if _ev_wait_a <= 0.0:
			_skip_t = 0.0
			_skip_y.clear()
			for k: int in range(4):
				_skip_y.append(rng.randf_range(34.0, 240.0))
	else:
		_skip_t += dl
		if _skip_t > SKIP_DUR:
			_skip_t = -1.0
			_ev_wait_a = rng.randf_range(14.0, 22.0)
	if _tear_t < 0.0:
		_ev_wait_b -= dl
		if _ev_wait_b <= 0.0:
			_tear_t = 0.0
	else:
		var was: float = _tear_t
		_tear_t += dl
		if was < 0.5 and _tear_t >= 0.5:
			for s: int in range(14):
				fx_spawn(StarfieldBg.Fx.SPARK, rng.randf_range(80.0, 400.0), rng.randf_range(54.0, 66.0), rng.randf_range(-40.0, 40.0), rng.randf_range(-30.0, 30.0), rng.randf_range(0.5, 1.0), 0.0)
		if _tear_t > TEAR_DUR:
			_tear_t = -1.0
			_ev_wait_b = rng.randf_range(16.0, 26.0)
	if _fleet_t < 0.0:
		_ev_wait_c -= dl
		if _ev_wait_c <= 0.0:
			_fleet_t = 0.0
			_fleet_y = rng.randf_range(40.0, 60.0)
	else:
		_fleet_t += dl
		if _fleet_t > FLEET_DUR:
			_fleet_t = -1.0
			_ev_wait_c = rng.randf_range(22.0, 32.0)


# Extra layer offset during a time skip: the distance jumps back, holds, then snaps forward.
func _skip_off() -> float:
	if _skip_t < 0.0:
		return 0.0
	var k: float = _skip_t / SKIP_DUR
	if k < 0.12:
		return -26.0 * (k / 0.12)
	if k < 0.7:
		return -26.0 + 4.0 * float(int(_skip_t * 20.0) % 2)
	return -26.0 * (1.0 - (k - 0.7) / 0.3)


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	var sk: float = _skip_off()
	# the far geometry and its lagging amber echo
	var lag: float = 7.0 + 5.0 * sin(life * 0.6)
	layer("far", FAR_Y + 2.0, FAR_F, Color(1.0, 0.68, 0.3, 0.2), sk + lag)
	layer("far", FAR_Y, FAR_F, Color.WHITE, sk)
	_draw_clocks(sk)
	if _fleet_t >= 0.0:
		_draw_fleet()
	if _tear_t >= 0.0:
		_draw_tear()
	_draw_rifts(sk)
	layer("shards", SHARD_Y, SHARD_F, Color.WHITE, sk * 0.6)
	_draw_shard_glints(sk * 0.6)
	drift_draw(drift_a)
	drift_draw(drift_b, 2.0)
	for i: int in range(STUTTER):
		var c: Color = Color(0.8, 0.75, 1.0, 0.45) if i % 3 != 0 else Color(0.4, 0.9, 1.0, 0.4)
		bg.draw_rect(Rect2(floorf(_sx[i]), floorf(_sy[i]), 1.0, 1.0), c)
		bg.draw_rect(Rect2(floorf(_sx[i]) + 4.0, floorf(_sy[i]), 1.0, 1.0), Color(c.r, c.g, c.b, 0.15))
	layer("ruins", RUIN_Y, RUIN_F)
	_draw_ruin_life()
	fx_draw()
	if _skip_t >= 0.0:
		var k: float = _skip_t / SKIP_DUR
		var fl: float = 0.06 * (1.0 - k)
		bg.draw_rect(Rect2(0.0, 28.0, 480.0, 230.0), Color(0.85, 0.8, 1.0, fl))
		for y: float in _skip_y:
			var wob: float = sin(_skip_t * 40.0 + y) * 12.0
			bg.draw_rect(Rect2(0.0, floorf(y), 480.0, 1.0), Color(0.8, 0.9, 1.0, 0.18 * (1.0 - k)))
			bg.draw_rect(Rect2(floorf(wob) + 120.0, floorf(y) + 1.0, 160.0, 1.0), Color(1.0, 0.75, 0.35, 0.14 * (1.0 - k)))


func _draw_clocks(sk: float) -> void:
	var o: float = fposmod(off(FAR_F, W) + sk, W)
	var clocks: PackedVector3Array = meta.get("clocks", PackedVector3Array())
	var segs: PackedVector2Array = PackedVector2Array()
	var segs_hot: PackedVector2Array = PackedVector2Array()
	for i: int in range(clocks.size()):
		var cx: float = wrap_x(clocks[i].x, o, W)
		if cx < -30.0 or cx > 510.0:
			continue
		var c: Vector2 = Vector2(floorf(cx) + 0.5, FAR_Y + clocks[i].y + 0.5)
		var r: float = clocks[i].z
		# hour hand runs backwards, minute hand races, second hand ticks in fits
		var hour: float = -life * (0.25 + 0.1 * float(i))
		var minute: float = life * (2.6 - 0.7 * float(i))
		var sec: float = floorf(life * (3.0 + float(i))) * 0.52 + sin(life * 7.0) * 0.08
		segs.append(c)
		segs.append(c + Vector2.from_angle(hour) * r * 0.5)
		segs.append(c)
		segs.append(c + Vector2.from_angle(minute) * r * 0.8)
		segs_hot.append(c)
		segs_hot.append(c + Vector2.from_angle(sec) * (r - 1.0))
	if not segs.is_empty():
		bg.draw_multiline(segs, Color(0.55, 0.48, 0.9, 0.7), 1.0)
		bg.draw_multiline(segs_hot, Color(1.0, 0.7, 0.3, 0.6), 1.0)


func _draw_rifts(sk: float) -> void:
	var o: float = fposmod(off(RIFT_F, W) + sk * 0.5, W)
	var lines: Array = meta.get("rift_lines", [])
	var info: PackedVector4Array = meta.get("rift_info", PackedVector4Array())
	for i: int in range(mini(lines.size(), info.size())):
		var nf: Vector4 = info[i]
		var rx: float = wrap_x(nf.x, o, W)
		if rx < -12.0 or rx > 492.0:
			continue
		# each rift unzips from its middle and seals again on its own cycle
		var ph: float = fposmod(life / nf.z + nf.w, 1.0)
		var open: float = clampf(sin(ph * TAU) * 1.6 - 0.25, 0.0, 1.0)
		if open <= 0.02:
			continue
		var base: PackedVector2Array = lines[i]
		var pts: PackedVector2Array = PackedVector2Array()
		pts.resize(base.size())
		var c: Vector2 = Vector2(floorf(rx) + 0.5, nf.y + 0.5)
		for k: int in range(base.size()):
			pts[k] = c + Vector2(base[k].x, floorf(base[k].y * open))
		var amber: bool = i % 2 == 1
		var leak: Color = Color(1.0, 0.7, 0.3, 0.35 * open) if amber else Color(0.35, 0.9, 1.0, 0.35 * open)
		bg.draw_polyline(pts, Color(0.75, 0.7, 1.0, 0.08 * open), 5.0)
		var side: PackedVector2Array = pts.duplicate()
		for k2: int in range(side.size()):
			side[k2] += Vector2(1.0, 0.0)
		bg.draw_polyline(side, leak, 1.0)
		bg.draw_polyline(pts, Color(1.0, 1.0, 1.0, 0.7 * open), 1.0)


func _draw_shard_glints(sk: float) -> void:
	# a point of rift light runs round the edge of each shard in turn
	var o: float = fposmod(off(SHARD_F, W) + sk, W)
	var polys: Array = meta.get("shard_polys", [])
	for i: int in range(polys.size()):
		var pts: PackedVector2Array = polys[i]
		var n: int = pts.size()
		if n < 3:
			continue
		var gx: float = wrap_x(pts[0].x, o, W)
		if gx < -60.0 or gx > 540.0:
			continue
		var dx: float = gx - pts[0].x
		var tt: float = fposmod(life * 0.35 + float(i) * 0.37, 1.0) * float(n)
		var e: int = int(tt) % n
		var p: Vector2 = pts[e].lerp(pts[(e + 1) % n], tt - floorf(tt))
		var sp: Vector2 = Vector2(floorf(p.x + dx), floorf(SHARD_Y + p.y))
		bg.draw_rect(Rect2(sp, Vector2(1.0, 1.0)), Color(1.0, 1.0, 1.0, 0.85))
		bg.draw_rect(Rect2(sp - Vector2(1.0, 0.0), Vector2(3.0, 1.0)), Color(0.85, 0.8, 1.0, 0.3))


func _draw_tear() -> void:
	var top: PackedFloat32Array = meta.get("tear_top", PackedFloat32Array())
	var bot: PackedFloat32Array = meta.get("tear_bot", PackedFloat32Array())
	var n: int = mini(top.size(), bot.size())
	if n < 2:
		return
	var t: float = _tear_t
	var open: float = 0.0
	if t < 0.8:
		open = t / 0.8
	elif t < 1.9:
		open = 1.0
	else:
		open = maxf(0.0, 1.0 - (t - 1.9) / 1.5)
	# it opens from the middle out
	var spread: float = clampf(t / 0.9, 0.0, 1.0)
	var cy: float = 60.0
	var x0: float = 50.0
	var x1: float = 430.0
	var upper: PackedVector2Array = PackedVector2Array()
	var lower: PackedVector2Array = PackedVector2Array()
	for i: int in range(n):
		var u: float = float(i) / float(n - 1)
		var from_mid: float = absf(u - 0.5) * 2.0
		var reach: float = clampf((spread - from_mid) * 4.0, 0.0, 1.0)
		var taper: float = sin(u * PI) * reach * open
		var x: float = floorf(lerpf(x0, x1, u)) + 0.5
		upper.append(Vector2(x, floorf(cy - 8.0 * top[i] * taper) + 0.5))
		lower.append(Vector2(x, floorf(cy + 6.0 * bot[i] * taper) + 0.5))
	if open > 0.05:
		_strip(upper, lower, Color(1.0, 0.7, 0.3, 0.5 * open))
		# the other time shows through: a brighter amber core
		var c_top: PackedVector2Array = PackedVector2Array()
		var c_bot: PackedVector2Array = PackedVector2Array()
		for i2: int in range(n):
			c_top.append(Vector2(upper[i2].x, lerpf(upper[i2].y, lower[i2].y, 0.35)))
			c_bot.append(Vector2(upper[i2].x, lerpf(upper[i2].y, lower[i2].y, 0.7)))
		_strip(c_top, c_bot, Color(1.0, 0.95, 0.8, 0.65 * open))
	bg.draw_polyline(upper, Color(1.0, 1.0, 1.0, 0.75 * open + 0.1), 1.0)
	bg.draw_polyline(lower, Color(0.8, 0.95, 1.0, 0.6 * open + 0.1), 1.0)
	bg.draw_polyline(upper, Color(0.8, 0.75, 1.0, 0.1 * open), 5.0)


# A filled band between two polylines of equal length, as explicit triangles (the band pinches
# to nothing at its ends, which a polygon fill can't triangulate).
func _strip(top: PackedVector2Array, bot: PackedVector2Array, col: Color) -> void:
	var n: int = mini(top.size(), bot.size())
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var idx: PackedInt32Array = PackedInt32Array()
	for i: int in range(n):
		pts.append(top[i])
		pts.append(bot[i])
		cols.append(col)
		cols.append(col)
	for i2: int in range(n - 1):
		var a: int = i2 * 2
		idx.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))
	RenderingServer.canvas_item_add_triangle_array(bg.get_canvas_item(), idx, pts, cols)


func _draw_fleet() -> void:
	var tx: Texture2D = tex("fleet")
	var k: float = _fleet_t / FLEET_DUR
	var fade: float = minf(1.0, minf(_fleet_t / 0.8, (FLEET_DUR - _fleet_t) / 0.8))
	var lead_x: float = lerpf(520.0, -160.0, k)
	for s: int in range(6):
		var sx: float = floorf(lead_x + float(s) * 22.0)
		var sy: float = floorf(_fleet_y + float(s % 3) * 9.0 - float(s / 3) * 4.0)
		var flick: float = 0.32 + 0.1 * float(int(life * 18.0 + float(s)) % 2)
		bg.draw_texture(tx, Vector2(sx, sy), Color(1.0, 1.0, 1.0, flick * fade))
		bg.draw_rect(Rect2(sx + 30.0, sy + 4.0, 3.0 + float(int(life * 20.0 + float(s)) % 3), 2.0), Color(1.0, 0.85, 0.5, 0.35 * fade))


func _draw_ruin_life() -> void:
	var o: float = off(RUIN_F, W)
	var glints: PackedVector2Array = meta.get("ruin_glints", PackedVector2Array())
	for g: int in range(glints.size()):
		var tw: float = fposmod(life * 0.7 + float(g) * 0.31, 1.0)
		if tw < 0.12:
			var gx: float = wrap_x(glints[g].x, o, W)
			if gx > 0.0 and gx < 480.0:
				var col: Color = Color(0.5, 0.95, 1.0, 0.9) if g % 2 == 0 else Color(1.0, 0.8, 0.4, 0.9)
				bg.draw_rect(Rect2(floorf(gx), RUIN_Y + glints[g].y, 1.0, 1.0), col)
	# debris frozen in mid-fall: hovering, trembling a pixel now and then
	var o2: float = off(RUIN_F * 0.9, W)
	var debris: PackedVector3Array = meta.get("debris", PackedVector3Array())
	for d: int in range(debris.size()):
		var dx: float = wrap_x(debris[d].x, o2, W)
		if dx < -4.0 or dx > 484.0:
			continue
		var dy: float = RUIN_Y + 6.0 + debris[d].y + floorf(sin(life * 0.9 + float(d)) * 2.0)
		var sz: float = debris[d].z
		bg.draw_rect(Rect2(floorf(dx), dy, sz + 1.0, sz), Color("#100c22"))
		bg.draw_rect(Rect2(floorf(dx), dy, sz + 1.0, 1.0), Color("#2e2660"))
