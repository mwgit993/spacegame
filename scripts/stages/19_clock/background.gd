extends "res://scripts/stages/stage_background.gd"

# CLOCKWORK: inside the works of a giant brass fortress. A vaulted wall with dim amber windows
# and a great clock face fills the far distance; in front of it enormous dark gears tick round
# in step with the clock, then come iron columns and catwalks, then brass and copper pipe runs
# with valves, gauges, pistons, chains and lamps, and finally riveted girders with cog racks.
#
# Layers (paint(), worker thread):
#   "sky"       480x270 at (0,0): sepia gradient, vault ribs, arched windows, the great clock dial
#   "far"       768x230 at y 28, parallax 0.1: iron columns, trusses, two small tower clocks
#   "mid"       640x230 at y 28, parallax 0.25: pipe runs, valves, gauges, piston housings,
#               chains, lamps (playfield centre left clear)
#   "near_top"  512x22 at y 28, parallax 0.85: riveted girder with a hanging cog rack
#   "near_bot"  512x26 at y 232, parallax 0.85: floor girder with a cog rack
# Drawn live: the great clock's hands (the second hand ticks once a second), far gears that
# tick round with it (parallax 0.05, properly meshed), smaller brass gears spinning on the pipe
# runs, the tower clocks' hands, pumping piston rods, twitching gauge needles, flickering lamps,
# steam puffs from the vents, sparks off the gears and drifting dust.
# Rare events: the great clock chimes (_ev_a: the hands spin to twelve, bell pulses ring out and
# a giant pendulum swings beneath the dial), a valve bursts into a long steam jet (_ev_b), and a
# train of dark foreground gears grinds past along the floor, throwing sparks (_ev_c).
# Everything in the playfield band is dark and low in contrast.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const FAR_Y: float = 28.0
const MID_Y: float = 28.0
const NEAR_TOP_Y: float = 28.0
const NEAR_BOT_Y: float = 232.0
const FAR_W: float = 768.0
const MID_W: float = 640.0
const GEAR_W: float = 960.0      # virtual strip width of the far gears (parallax GEAR_PAR)
const GEAR_PAR: float = 0.05
const CLOCK_C: Vector2 = Vector2(304.0, 104.0)
const CLOCK_R: float = 62.0
const W_MIN: float = TAU / 40.0  # great clock minute hand: a turn every 40 s
const W_HOUR: float = W_MIN / 12.0

# Far gears: x, y (screen), teeth, parent index (-1 = free), angle from the parent.
# Every far gear has the same tooth pitch, so meshed pairs turn at matching tooth speeds.
const FAR_PITCH: float = 16.0
const FAR_GEARS: Array[Vector4] = [
	Vector4(90.0, 62.0, 28.0, -1.0), Vector4(0.0, 0.92, 16.0, 0.0), Vector4(0.0, -0.55, 12.0, 1.0),
	Vector4(430.0, 236.0, 31.0, -1.0), Vector4(0.0, -2.35, 14.0, 3.0),
	Vector4(700.0, 40.0, 24.0, -1.0), Vector4(0.0, 2.25, 18.0, 5.0),
	Vector4(880.0, 222.0, 20.0, -1.0), Vector4(0.0, -1.9, 11.0, 7.0),
]
const MID_PITCH: float = 6.6
const MID_GEARS: Array[Vector4] = [
	Vector4(70.0, 52.0, 14.0, -1.0), Vector4(0.0, 0.35, 9.0, 0.0),
	Vector4(330.0, 50.0, 18.0, -1.0), Vector4(0.0, 2.7, 10.0, 2.0), Vector4(0.0, 0.5, 8.0, 2.0),
	Vector4(190.0, 226.0, 16.0, -1.0), Vector4(0.0, -0.8, 10.0, 5.0),
	Vector4(500.0, 230.0, 20.0, -1.0), Vector4(0.0, -2.3, 12.0, 7.0),
]

const TRAIN_PITCH: float = TAU * 58.0 / 22.0
const FAR_COLS: PackedColorArray = [Color("#22170c"), Color("#1a1109"), Color("#0b0705"), Color("#3e2a12")]
const MID_COLS: PackedColorArray = [Color("#4a3214"), Color("#3a2810"), Color("#140c06"), Color("#9a7030")]
const TRAIN_COLS: PackedColorArray = [Color("#0d0905"), Color("#0a0704"), Color("#050302"), Color("#3a2812")]
const SKY_RAMP: PackedColorArray = [Color("#0b0705"), Color("#0f0a06"), Color("#130c07"), Color("#170f09"), Color("#1b120a"), Color("#1e140c")]
const BRASS_D: PackedColorArray = [Color("#1e1208"), Color("#3c2810"), Color("#6a4a1c"), Color("#9a7030"), Color("#c8a050")]
const COPPER_D: PackedColorArray = [Color("#1e0c06"), Color("#3e1c0e"), Color("#6a3218"), Color("#94502a"), Color("#c07a48")]
const IRON_D: PackedColorArray = [Color("#0a0806"), Color("#120d09"), Color("#1a130d"), Color("#261c12"), Color("#3a2a1a")]

# Gear state, built in reset(): screen-strip position, pitch radius, teeth, phase, turn ratio.
var _fg_pos: PackedVector2Array = PackedVector2Array()
var _fg_r: PackedFloat32Array = PackedFloat32Array()
var _fg_n: PackedInt32Array = PackedInt32Array()
var _fg_off: PackedFloat32Array = PackedFloat32Array()
var _fg_ratio: PackedFloat32Array = PackedFloat32Array()
var _mg_pos: PackedVector2Array = PackedVector2Array()
var _mg_r: PackedFloat32Array = PackedFloat32Array()
var _mg_n: PackedInt32Array = PackedInt32Array()
var _mg_off: PackedFloat32Array = PackedFloat32Array()
var _mg_ratio: PackedFloat32Array = PackedFloat32Array()
var _ct: float = 0.0             # great clock time (holds during a chime)
var _ct_from: float = 0.0
var _ct_to: float = 0.0
var _hour0: float = 0.0
var _steam_t: float = 0.5
var _spark_t: float = 1.0
var _burst_x: float = 0.0        # mid-layer x of the bursting valve
var _burst_y: float = 0.0
var _burst_dir: float = -1.0
var _train_x: float = 600.0
var _fg_mesh: Array[ArrayMesh] = []
var _mg_mesh: Array[ArrayMesh] = []
var _train_mesh: Array[ArrayMesh] = []


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 19019
	var out: Dictionary = {}
	out["sky"] = _paint_sky(rng)
	_paint_far(rng, out)
	_paint_mid(rng, out)
	out["near_top"] = _paint_near(rng, 22, true)
	out["near_bot"] = _paint_near(rng, 26, false)
	# Gear meshes (vertex + colour arrays; turned into ArrayMeshes in reset() and rotated on the
	# GPU, so a turning gear costs one draw call).
	var far_geom: Array = []
	for d: Vector4 in FAR_GEARS:
		far_geom.append(_gear_geom(int(d.z), FAR_PITCH, 8.0, FAR_COLS))
	var mid_geom: Array = []
	for d2: Vector4 in MID_GEARS:
		mid_geom.append(_gear_geom(int(d2.z), MID_PITCH, 4.0, MID_COLS))
	out["gear_far"] = far_geom
	out["gear_mid"] = mid_geom
	out["gear_train"] = [_gear_geom(22, TRAIN_PITCH, 9.0, TRAIN_COLS), _gear_geom(11, TRAIN_PITCH, 9.0, TRAIN_COLS)]
	return out


# Triangles of a gear at rest (tooth 0 centred on angle 0): teeth, face, lightening holes, hub.
# cols = [teeth/rim, face, holes, hub highlight].
static func _gear_geom(n: int, pitch: float, h: float, cols: PackedColorArray) -> Array:
	var r: float = float(n) * pitch / TAU
	var step: float = TAU / float(n)
	var r_in: float = r - h * 0.5
	var r_out: float = r + h * 0.5
	var poly: PackedVector2Array = PackedVector2Array()
	for k: int in range(n):
		var a0: float = float(k) * step
		poly.append(Vector2.from_angle(a0 - step * 0.34) * r_in)
		poly.append(Vector2.from_angle(a0 - step * 0.2) * r_out)
		poly.append(Vector2.from_angle(a0 + step * 0.2) * r_out)
		poly.append(Vector2.from_angle(a0 + step * 0.34) * r_in)
	var verts: PackedVector2Array = PackedVector2Array()
	var vcols: PackedColorArray = PackedColorArray()
	var idx: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	for i: int in idx:
		verts.append(poly[i])
		vcols.append(cols[0])
	_fan(verts, vcols, Vector2.ZERO, r_in - 1.0, maxi(16, n * 2), cols[1])
	var holes: int = 6 if n >= 16 else 4
	var hr: float = (r_in - r * 0.22) * 0.32
	if hr >= 2.0:
		for j: int in range(holes):
			var hc: Vector2 = Vector2.from_angle(TAU * float(j) / float(holes) + step * 0.5) * (r * 0.22 + r_in) * 0.5
			_fan(verts, vcols, hc, hr, 10, cols[2])
	_fan(verts, vcols, Vector2.ZERO, maxf(2.0, r * 0.2), 12, cols[0])
	_fan(verts, vcols, Vector2.ZERO, maxf(1.0, r * 0.11), 8, cols[3])
	return [verts, vcols]


static func _fan(verts: PackedVector2Array, vcols: PackedColorArray, c: Vector2, r: float, seg: int, col: Color) -> void:
	for i: int in range(seg):
		verts.append(c)
		verts.append(c + Vector2.from_angle(TAU * float(i) / float(seg)) * r)
		verts.append(c + Vector2.from_angle(TAU * float(i + 1) / float(seg)) * r)
		for _k: int in range(3):
			vcols.append(col)


static func _make_mesh(geom: Array) -> ArrayMesh:
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = geom[0]
	arr[Mesh.ARRAY_COLOR] = geom[1]
	var m: ArrayMesh = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


# --- Painting ------------------------------------------------------------------------------------

static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(SKY_RAMP[0])
	Painter.vgrad(sky, 22, 258, SKY_RAMP, 0.45)
	# Riveted iron wall panels, barely there.
	for y: int in range(30, 256, 22):
		Painter.rect(sky, 0, y, 480, 1, Color("#100a06"))
		for x: int in range((y / 22) % 2 * 18, 480, 36):
			Painter.rect(sky, x, y + 1, 1, 21, Color("#120c07"))
			Painter.px(sky, x + 3, y + 3, Color("#2a1c10"))
			Painter.px(sky, x + 32, y + 3, Color("#2a1c10"))
	# Vault ribs: tall pointed arches.
	for ax: int in [0, 160, 320, 480]:
		for k: int in range(240):
			var t: float = float(k) / 239.0
			var y2: int = 28 + k
			var bend: float = sqrt(maxf(0.0, 1.0 - t)) * 70.0
			for side: int in [-1, 1]:
				var x2: int = ax + side * int(80.0 - bend)
				Painter.rect(sky, x2 - 1, y2, 3, 1, Color("#160e08"))
				Painter.px(sky, x2 + side, y2, Color("#22160c"))
	# Arched amber windows between the ribs (very dim), with mullions.
	for wx: int in [40, 118, 200, 440]:
		_arch_window(sky, wx, 60, 22, 70)
	# The great clock: a huge dim dial in an iron bezel.
	var c: Vector2 = CLOCK_C
	Painter.disc(sky, c.x, c.y, CLOCK_R + 9.0, Color("#0e0905"))
	Painter.disc(sky, c.x, c.y, CLOCK_R + 7.0, Color("#3a2812"))
	Painter.disc(sky, c.x - 1.0, c.y - 1.0, CLOCK_R + 5.0, Color("#4e3618"))
	Painter.disc(sky, c.x, c.y, CLOCK_R + 4.0, Color("#33240f"))
	Painter.disc(sky, c.x, c.y, CLOCK_R + 1.0, Color("#140d07"))
	for y3: int in range(int(c.y - CLOCK_R), int(c.y + CLOCK_R) + 1):
		for x3: int in range(int(c.x - CLOCK_R), int(c.x + CLOCK_R) + 1):
			var d: Vector2 = Vector2(float(x3) + 0.5, float(y3) + 0.5) - c
			var r: float = d.length()
			if r > CLOCK_R:
				continue
			var v: float = 0.55 - r / CLOCK_R * 0.25 + (-d.x - d.y) / CLOCK_R * 0.12
			sky.set_pixel(x3, y3, Painter.ramp_pick(PackedColorArray([Color("#1c1610"), Color("#241d15"), Color("#2c241a"), Color("#342b1f")]), v, x3, y3))
	# Chapter ring, minute ticks and blocky hour marks.
	for t2: int in range(60):
		var a: float = -PI * 0.5 + TAU * float(t2) / 60.0
		var dir: Vector2 = Vector2(cos(a), sin(a))
		var big: bool = t2 % 5 == 0
		var r0: float = CLOCK_R - (12.0 if big else 5.0)
		var rr: float = r0
		while rr < CLOCK_R - 2.0:
			var p: Vector2 = c + dir * rr
			Painter.px(sky, int(p.x), int(p.y), Color("#4a3c28") if big else Color("#3a3022"))
			if big:
				var p2: Vector2 = p + Vector2(-dir.y, dir.x)
				Painter.px(sky, int(p2.x), int(p2.y), Color("#4a3c28"))
			rr += 1.0
	for t3: int in range(72):
		var a3: float = TAU * float(t3) / 72.0
		var q: Vector2 = c + Vector2(cos(a3), sin(a3)) * (CLOCK_R - 16.0)
		Painter.px(sky, int(q.x), int(q.y), Color("#30281c"))
	for t4: int in range(12):
		var a4: float = TAU * float(t4) / 12.0
		var q2: Vector2 = c + Vector2(cos(a4), sin(a4)) * (CLOCK_R + 5.5)
		Painter.disc(sky, q2.x, q2.y, 2.0, Color("#5a4020"))
		Painter.px(sky, int(q2.x) - 1, int(q2.y) - 1, Color("#7a5a2c"))
	# Dust specks.
	for i: int in range(70):
		Painter.px(sky, rng.randi_range(0, 479), rng.randi_range(30, 250), Color("#2a1e12") if i % 3 else Color("#3a2a18"))
	return sky


static func _arch_window(img: Image, x: int, y: int, w: int, h: int) -> void:
	var hw: float = float(w) * 0.5
	for yy: int in range(h):
		var span_hw: float = hw
		if yy < int(hw):
			var dy: float = hw - float(yy)
			span_hw = sqrt(maxf(0.0, hw * hw - dy * dy))
		var x0: int = int(float(x) + hw - span_hw)
		var x1: int = int(float(x) + hw + span_hw)
		Painter.span(img, x0 - 2, x1 + 2, y + yy, Color("#120b06"))
		var glow: Color = Color("#2c1a0a") if yy > h / 3 else Color("#24160a")
		Painter.span(img, x0, x1, y + yy, glow)
		if (yy + x) % 3 == 0:
			Painter.px(img, x0 + 2 + (yy * 7) % maxi(1, x1 - x0 - 3), y + yy, Color("#3a240e"))
	Painter.rect(img, x + w / 2, y + 2, 1, h - 2, Color("#120b06"))
	Painter.rect(img, x, y + h / 2, w + 1, 1, Color("#120b06"))
	Painter.rect(img, x - 2, y + h, w + 5, 3, Color("#1e140c"))


static func _paint_far(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = int(FAR_W)
	var h: int = 230
	var img: Image = Painter.new_img(w, h)
	# Upper truss: a beam with X bracing.
	Painter.rect(img, 0, 0, w, 6, IRON_D[1])
	Painter.rect(img, 0, 5, w, 1, IRON_D[3])
	Painter.rect(img, 0, 20, w, 4, IRON_D[1])
	Painter.rect(img, 0, 20, w, 1, IRON_D[3])
	for x: int in range(0, w, 24):
		Painter.line(img, x, 6, x + 24, 20, IRON_D[2])
		Painter.line(img, x + 24, 6, x, 20, IRON_D[2])
		Painter.rect(img, x, 6, 2, 14, IRON_D[2])
	# Lower gallery: a railing on a ledge.
	Painter.rect(img, 0, 206, w, 24, IRON_D[1])
	Painter.rect(img, 0, 206, w, 1, IRON_D[4])
	Painter.rect(img, 0, 192, w, 2, IRON_D[2])
	for x2: int in range(0, w, 8):
		Painter.rect(img, x2, 194, 1, 12, IRON_D[2])
	for x3: int in range(4, w, 32):
		Painter.px(img, x3, 210, IRON_D[4])
	# Columns with capitals and bases.
	var clocks: PackedVector3Array = PackedVector3Array()
	var cx: int = 40
	var n: int = 0
	while cx < w - 10:
		var cw: int = 16 + (n % 2) * 6
		Painter.rect(img, cx, 0, cw, h, IRON_D[1])
		Painter.rect(img, cx, 0, 2, h, IRON_D[3])
		Painter.rect(img, cx + cw - 2, 0, 2, h, IRON_D[0])
		Painter.rect(img, cx + cw / 2, 0, 1, h, IRON_D[2])
		Painter.rect(img, cx - 3, 24, cw + 6, 5, IRON_D[2])
		Painter.rect(img, cx - 3, 24, cw + 6, 1, IRON_D[4])
		Painter.rect(img, cx - 3, 186, cw + 6, 6, IRON_D[2])
		Painter.rect(img, cx - 3, 186, cw + 6, 1, IRON_D[4])
		for ry: int in range(36, 180, 12):
			Painter.px(img, cx + 3, ry, IRON_D[4])
			Painter.px(img, cx + cw - 4, ry, IRON_D[4])
		# Every other column carries a small tower clock.
		if n % 2 == 1:
			var ccx: float = float(cx) + float(cw) * 0.5
			var ccy: float = 52.0
			Painter.disc(img, ccx, ccy, 15.0, Color("#100a06"))
			Painter.disc(img, ccx, ccy, 14.0, Color("#3a2812"))
			Painter.disc(img, ccx, ccy, 12.0, Color("#2a2219"))
			Painter.disc(img, ccx - 1.0, ccy - 1.0, 10.0, Color("#30271c"))
			for t: int in range(12):
				var a: float = TAU * float(t) / 12.0
				var q: Vector2 = Vector2(ccx, ccy) + Vector2(cos(a), sin(a)) * 10.0
				Painter.px(img, int(q.x), int(q.y), Color("#4e4030"))
			clocks.append(Vector3(ccx, ccy, 12.0))
		cx += rng.randi_range(150, 200)
		n += 1
	out["far"] = img
	out["far_clocks"] = clocks


static func _hpipe(img: Image, x0: int, x1: int, y: int, th: int, ramp: PackedColorArray, flange_every: int) -> void:
	for k: int in range(th):
		var v: float = 1.0 - float(k) / float(maxi(1, th - 1))
		var col: Color = ramp[1]
		if k == 0:
			col = ramp[0]
		elif k == 1:
			col = ramp[3]
		elif v > 0.55:
			col = ramp[2]
		elif k == th - 1:
			col = ramp[0]
		Painter.span(img, x0, x1, y + k, col)
	if flange_every > 0:
		var fx: int = x0 + flange_every / 2
		while fx < x1 - 2:
			Painter.rect(img, fx, y - 1, 3, th + 2, ramp[1])
			Painter.rect(img, fx, y - 1, 1, th + 2, ramp[3])
			Painter.px(img, fx + 1, y, ramp[4])
			Painter.px(img, fx + 1, y + th - 1, ramp[0])
			fx += flange_every


static func _vpipe(img: Image, x: int, y0: int, y1: int, tw: int, ramp: PackedColorArray) -> void:
	for k: int in range(tw):
		var col: Color = ramp[2]
		if k == 0:
			col = ramp[0]
		elif k == 1:
			col = ramp[3]
		elif k == tw - 1:
			col = ramp[0]
		elif k >= tw - 2:
			col = ramp[1]
		Painter.rect(img, x + k, mini(y0, y1), 1, absi(y1 - y0) + 1, col)


static func _valve(img: Image, cx: int, cy: int, r: int) -> void:
	Painter.disc(img, float(cx), float(cy), float(r), Color("#1a0e06"))
	Painter.disc(img, float(cx), float(cy), float(r) - 0.6, BRASS_D[3])
	Painter.disc(img, float(cx), float(cy), float(r) - 2.0, Painter.CLEAR)
	for s: int in range(4):
		var a: float = PI * 0.25 + PI * 0.5 * float(s)
		Painter.line(img, cx, cy, cx + int(cos(a) * float(r - 1)), cy + int(sin(a) * float(r - 1)), BRASS_D[2])
	Painter.disc(img, float(cx), float(cy), 1.2, BRASS_D[4])


static func _gauge(img: Image, cx: int, cy: int) -> void:
	Painter.disc(img, float(cx), float(cy), 5.0, Color("#1a0e06"))
	Painter.disc(img, float(cx), float(cy), 4.4, BRASS_D[3])
	Painter.disc(img, float(cx), float(cy), 3.4, Color("#8a7c62"))
	Painter.px(img, cx + 2, cy - 2, Color("#9a3020"))
	Painter.px(img, cx + 3, cy - 1, Color("#9a3020"))
	Painter.px(img, cx - 2, cy - 2, Color("#a89a7c"))


static func _paint_mid(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = int(MID_W)
	var h: int = 230
	var img: Image = Painter.new_img(w, h)
	var gauges: PackedVector2Array = PackedVector2Array()
	var valves: PackedVector2Array = PackedVector2Array()
	var vents: PackedVector2Array = PackedVector2Array()
	var lamps: PackedVector2Array = PackedVector2Array()
	var pistons: PackedVector3Array = PackedVector3Array()   # x, y of the housing mouth, +-1 direction
	# Top band: a big brass main, a copper line under it, drops and hangers.
	_hpipe(img, 0, w - 1, 22, 8, BRASS_D, 64)
	_hpipe(img, 0, w - 1, 34, 5, COPPER_D, 0)
	# Bottom band: risers, a brass main and a copper return.
	_hpipe(img, 0, w - 1, 186, 5, COPPER_D, 0)
	_hpipe(img, 0, w - 1, 198, 8, BRASS_D, 72)
	var x: int = 18
	var k: int = 0
	while x < w - 20:
		match k % 5:
			0:
				# Drop with a valve, a gauge and a steam vent at its foot.
				_vpipe(img, x, 39, 56, 5, COPPER_D)
				_valve(img, x + 2, 46, 5)
				valves.append(Vector2(float(x + 2), 46.0))
				Painter.rect(img, x - 1, 56, 7, 3, BRASS_D[2])
				Painter.rect(img, x - 1, 56, 7, 1, BRASS_D[4])
				vents.append(Vector2(float(x + 2), 60.0))
				_gauge(img, x + 12, 30)
				gauges.append(Vector2(float(x + 12), 30.0))
			1:
				# A hanging piston housing.
				Painter.rect(img, x - 1, 30, 12, 26, IRON_D[1])
				Painter.rect(img, x, 31, 10, 24, BRASS_D[1])
				Painter.rect(img, x, 31, 2, 24, BRASS_D[3])
				Painter.rect(img, x + 8, 31, 2, 24, BRASS_D[0])
				Painter.rect(img, x - 2, 52, 14, 4, BRASS_D[2])
				Painter.rect(img, x - 2, 52, 14, 1, BRASS_D[4])
				pistons.append(Vector3(float(x + 5), 56.0, 1.0))
			2:
				# A hanging lamp on a chain, and a long chain beside it.
				for cy: int in range(40, 60, 2):
					Painter.px(img, x + 4, cy, IRON_D[4] if cy % 4 == 0 else IRON_D[3])
				Painter.rect(img, x + 1, 60, 7, 2, BRASS_D[3])
				Painter.rect(img, x + 2, 62, 5, 4, Color("#4a2c0c"))
				Painter.rect(img, x + 3, 63, 3, 2, Color("#7a4a14"))
				Painter.rect(img, x + 2, 66, 5, 1, BRASS_D[2])
				lamps.append(Vector2(float(x + 4), 64.0))
				var clen: int = rng.randi_range(40, 90)
				for cy2: int in range(40, 40 + clen, 2):
					Painter.px(img, x + 14, cy2, IRON_D[3] if cy2 % 4 == 0 else IRON_D[2])
					if cy2 % 4 == 0:
						Painter.px(img, x + 13, cy2, IRON_D[2])
						Painter.px(img, x + 15, cy2, IRON_D[2])
				Painter.rect(img, x + 12, 40 + clen, 5, 3, IRON_D[3])
			3:
				# Riser from the floor with a valve and a gauge.
				_vpipe(img, x, 160, 186, 5, BRASS_D)
				_valve(img, x + 2, 172, 5)
				valves.append(Vector2(float(x + 2), 172.0))
				vents.append(Vector2(float(x + 2), 158.0))
				Painter.rect(img, x - 1, 157, 7, 3, BRASS_D[2])
				Painter.rect(img, x - 1, 157, 7, 1, BRASS_D[4])
				_gauge(img, x + 14, 194)
				gauges.append(Vector2(float(x + 14), 194.0))
			_:
				# A piston housing rising from the floor.
				Painter.rect(img, x - 1, 206, 12, 24, IRON_D[1])
				Painter.rect(img, x, 207, 10, 23, BRASS_D[1])
				Painter.rect(img, x, 207, 2, 23, BRASS_D[3])
				Painter.rect(img, x + 8, 207, 2, 23, BRASS_D[0])
				Painter.rect(img, x - 2, 204, 14, 4, BRASS_D[2])
				Painter.rect(img, x - 2, 204, 14, 1, BRASS_D[4])
				pistons.append(Vector3(float(x + 5), 204.0, -1.0))
				lamps.append(Vector2(float(x + 22), 212.0))
				Painter.rect(img, x + 19, 209, 7, 6, IRON_D[2])
				Painter.rect(img, x + 20, 210, 5, 4, Color("#4a2c0c"))
				Painter.rect(img, x + 21, 211, 3, 2, Color("#7a4a14"))
		x += rng.randi_range(46, 74)
		k += 1
	# Verdigris streaks on the mains.
	for i: int in range(40):
		var vx: int = rng.randi_range(0, w - 1)
		var top: bool = i % 2 == 0
		Painter.px(img, vx, 27 if top else 203, Color("#1e403a"))
		Painter.px(img, vx + 1, 28 if top else 204, Color("#18322e"))
	out["mid"] = img
	out["gauges"] = gauges
	out["valves"] = valves
	out["vents"] = vents
	out["lamps"] = lamps
	out["pistons"] = pistons


static func _paint_near(rng: RandomNumberGenerator, h: int, ceiling: bool) -> Image:
	var w: int = 512
	var img: Image = Painter.new_img(w, h)
	var body_h: int = 9 if ceiling else 18
	var y0: int = 0 if ceiling else h - body_h
	# Riveted girder body.
	Painter.rect(img, 0, y0, w, body_h, IRON_D[2])
	for yy: int in range(body_h):
		var col: Color = IRON_D[2]
		var edge: int = yy if ceiling else body_h - 1 - yy
		if (ceiling and yy == body_h - 1) or (not ceiling and yy == 0):
			col = BRASS_D[3]
		elif (ceiling and yy == body_h - 2) or (not ceiling and yy == 1):
			col = BRASS_D[1]
		elif edge < 2:
			col = IRON_D[1]
		Painter.rect(img, 0, y0 + yy, w, 1, col)
	for rx: int in range(6, w, 16):
		var ry: int = y0 + (3 if ceiling else 6)
		Painter.px(img, rx, ry, BRASS_D[3])
		Painter.px(img, rx + 1, ry + 1, IRON_D[0])
		if not ceiling:
			Painter.px(img, rx + 8, ry + 6, BRASS_D[3])
			Painter.px(img, rx + 9, ry + 7, IRON_D[0])
	for px2: int in range(0, w, 128):
		Painter.rect(img, px2, y0, 2, body_h, IRON_D[0])
	# The cog rack: square teeth along the edge facing the playfield.
	var ty0: int = body_h if ceiling else y0 - 4
	for tx: int in range(0, w, 8):
		Painter.rect(img, tx + 1, ty0, 5, 4, BRASS_D[2])
		Painter.rect(img, tx + 1, ty0 + (3 if ceiling else 0), 5, 1, BRASS_D[4] if not ceiling else BRASS_D[0])
		Painter.rect(img, tx + 1, ty0, 1, 4, BRASS_D[3])
		Painter.rect(img, tx + 5, ty0, 1, 4, BRASS_D[1])
	# A copper conduit with clamps on the floor girder.
	if not ceiling:
		_hpipe(img, 0, w - 1, h - 9, 4, COPPER_D, 0)
		for cx: int in range(20, w, 48):
			Painter.rect(img, cx, h - 10, 3, 6, BRASS_D[2])
			Painter.px(img, cx + 1, h - 10, BRASS_D[4])
	else:
		for cx2: int in range(rng.randi_range(10, 30), w, 96):
			Painter.rect(img, cx2, 0, 8, 6, BRASS_D[1])
			Painter.rect(img, cx2 + 1, 1, 6, 1, BRASS_D[3])
	return img


# --- Gears ---------------------------------------------------------------------------------------

# Lays out a gear train: [positions, pitch radii, teeth, phases, turn signs]. Every gear in a
# train has the same tooth pitch, so meshed gears share one rim speed (rot = phase + sign * s / r).
func _build_gears(defs: Array[Vector4], pitch: float) -> Array:
	var pos: PackedVector2Array = PackedVector2Array()
	var rad: PackedFloat32Array = PackedFloat32Array()
	var teeth: PackedInt32Array = PackedInt32Array()
	var offs: PackedFloat32Array = PackedFloat32Array()
	var sgn: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(defs.size()):
		var d: Vector4 = defs[i]
		var n: int = int(d.z)
		var r: float = float(n) * pitch / TAU
		var step: float = TAU / float(n)
		teeth.append(n)
		rad.append(r)
		if d.w < 0.0:
			pos.append(Vector2(d.x, d.y))
			offs.append(rng.randf() * step)
			sgn.append(1.0)
		else:
			var p: int = int(d.w)
			var phi: float = d.y
			pos.append(pos[p] + Vector2.from_angle(phi) * (rad[p] + r))
			sgn.append(-sgn[p])
			# Mesh: the parent's tooth phase at the contact plus this gear's must be half a tooth.
			var ph1: float = fposmod((phi - offs[p]) / (TAU / float(teeth[p])), 1.0)
			offs.append(phi + PI - step * (0.5 - ph1))
	return [pos, rad, teeth, offs, sgn]


func _draw_gear(m: ArrayMesh, c: Vector2, r_in: float, rot: float, hi: Color) -> void:
	bg.draw_mesh(m, null, Transform2D(rot, c))
	bg.draw_arc(c, r_in - 2.0, PI * 0.95, PI * 1.55, 10, hi, 1.0)


# The far gears tick: each second they advance, easing over the first quarter second.
func _tick_angle() -> float:
	var f: float = fposmod(_ct, 1.0)
	var e: float = clampf(f / 0.28, 0.0, 1.0)
	return (floorf(_ct) + e * e * (3.0 - 2.0 * e)) * 0.11


# --- Animation -------------------------------------------------------------------------------------

func reset() -> void:
	var fg: Array = _build_gears(FAR_GEARS, FAR_PITCH)
	_fg_pos = fg[0]
	_fg_r = fg[1]
	_fg_n = fg[2]
	_fg_off = fg[3]
	_fg_ratio = fg[4]
	var mg: Array = _build_gears(MID_GEARS, MID_PITCH)
	_mg_pos = mg[0]
	_mg_r = mg[1]
	_mg_n = mg[2]
	_mg_off = mg[3]
	_mg_ratio = mg[4]
	_fg_mesh.clear()
	for g: Variant in meta.get("gear_far", []):
		_fg_mesh.append(_make_mesh(g as Array))
	_mg_mesh.clear()
	for g2: Variant in meta.get("gear_mid", []):
		_mg_mesh.append(_make_mesh(g2 as Array))
	_train_mesh.clear()
	for g3: Variant in meta.get("gear_train", []):
		_train_mesh.append(_make_mesh(g3 as Array))
	_ct = rng.randf_range(0.0, 30.0)
	_hour0 = rng.randf() * TAU
	drift_a.y0 = 34.0
	drift_a.y1 = 250.0
	drift_a.setup(26, rng, -9.0, -2.0, -4.0, 2.0)
	drift_a.par = 0.35
	drift_a.sway = 2.0
	drift_a.sway_hz = 0.6
	drift_a.blink = 0.25
	drift_a.duty = 0.8
	drift_a.cols = PackedColorArray([Color(1.0, 0.75, 0.4, 0.35), Color(0.9, 0.6, 0.3, 0.28), Color(0.85, 0.8, 0.7, 0.22)])
	drift_b.clear()
	_steam_t = 0.4
	_spark_t = 1.2
	bg._ev_a.arm(rng, 18.0, 26.0, 5.0, 9.0)    # the great clock chimes
	bg._ev_b.arm(rng, 11.0, 17.0, 9.0, 13.0)   # a valve bursts
	bg._ev_c.arm(rng, 20.0, 30.0, 14.0, 20.0)  # foreground gear train


func update() -> void:
	# Great clock time: runs, except while a chime spins the hands to twelve and holds them.
	if bg._ev_a.on:
		var t: float = bg._ev_a.t
		if t < 0.8:
			var e: float = t / 0.8
			_ct = lerpf(_ct_from, _ct_to, e * e * (3.0 - 2.0 * e))
		else:
			_ct = _ct_to
	else:
		_ct += dl
	if bg._ev_a.tick(dl, rng):
		bg._ev_a.dur = 5.2
		_ct_from = _ct
		var period: float = TAU / W_MIN
		_ct_to = ceilf(_ct_from / period) * period
		if _ct_to - _ct_from < 1.0:
			_ct_to += period
	# Steam from the vents.
	_steam_t -= dl
	if _steam_t <= 0.0:
		_steam_t = rng.randf_range(0.25, 0.6)
		var vents: PackedVector2Array = meta.get("vents", PackedVector2Array())
		if not vents.is_empty():
			var o: float = off(0.25, MID_W)
			var v: Vector2 = vents[rng.randi_range(0, vents.size() - 1)]
			var sx: float = wrap_x(v.x, o, MID_W)
			if sx > -10.0 and sx < 490.0:
				var up: float = -1.0 if v.y > 115.0 else 1.0
				for i: int in range(3):
					fx_spawn(StarfieldBg.Fx.STEAM, sx + rng.randf_range(-1.0, 1.0), MID_Y + v.y, rng.randf_range(-14.0, 6.0), up * rng.randf_range(8.0, 22.0), rng.randf_range(0.9, 1.6), 0.25)
	# Sparks off a meshing pair of mid gears now and then.
	_spark_t -= dl
	if _spark_t <= 0.0:
		_spark_t = rng.randf_range(0.9, 2.2)
		var gi: int = rng.randi_range(0, _mg_pos.size() - 1)
		if MID_GEARS[gi].w >= 0.0:
			var par_i: int = int(MID_GEARS[gi].w)
			var o2: float = off(0.25, MID_W)
			var contact: Vector2 = _mg_pos[par_i] + Vector2.from_angle(MID_GEARS[gi].y) * _mg_r[par_i]
			var sx2: float = wrap_x(contact.x, o2, MID_W)
			if sx2 > 0.0 and sx2 < 480.0:
				for s: int in range(5):
					fx_spawn(StarfieldBg.Fx.SPARK, sx2, contact.y, rng.randf_range(-50.0, 30.0), rng.randf_range(-70.0, -10.0), rng.randf_range(0.4, 0.8), 0.25)
	# Event B: a valve bursts.
	if bg._ev_b.tick(dl, rng):
		bg._ev_b.dur = 2.8
		bg._ev_b.k = -1
		var valves: PackedVector2Array = meta.get("valves", PackedVector2Array())
		if not valves.is_empty():
			var o3: float = off(0.25, MID_W)
			var start: int = rng.randi_range(0, valves.size() - 1)
			for n: int in range(valves.size()):
				var vv: Vector2 = valves[(start + n) % valves.size()]
				var sx3: float = wrap_x(vv.x, o3, MID_W)
				if sx3 > 200.0 and sx3 < 470.0:
					bg._ev_b.k = 1
					_burst_x = vv.x
					_burst_y = vv.y
					break
		if bg._ev_b.k < 0:
			bg._ev_b.on = false
			bg._ev_b.t = 2.0
	if bg._ev_b.on and bg._ev_b.k > 0 and bg._ev_b.t < 2.2:
		var bx: float = wrap_x(_burst_x, off(0.25, MID_W), MID_W)
		if rng.randf() < 0.6:
			fx_spawn(StarfieldBg.Fx.STEAM, bx - 4.0, MID_Y + _burst_y, rng.randf_range(-160.0, -90.0), rng.randf_range(-10.0, 10.0), rng.randf_range(0.8, 1.3), 0.25)
	# Event C: a train of foreground gears.
	if bg._ev_c.tick(dl, rng):
		bg._ev_c.dur = 9.0
		_train_x = 560.0
	if bg._ev_c.on:
		_train_x -= (ds * 1.05 + 12.0 * dl)
		if _train_x < -200.0:
			bg._ev_c.on = false
			bg._ev_c.t = rng.randf_range(bg._ev_c.lo, bg._ev_c.hi)
		elif rng.randf() < 0.35:
			var cp: Vector2 = _train_contact()
			if cp.x > 0.0 and cp.x < 480.0:
				fx_spawn(StarfieldBg.Fx.SPARK, cp.x, cp.y, rng.randf_range(-60.0, 40.0), rng.randf_range(-110.0, -40.0), rng.randf_range(0.4, 0.8), 0.0)


func _train_contact() -> Vector2:
	var a: Vector2 = Vector2(_train_x, 302.0)
	return a + Vector2.from_angle(PI + 0.95) * 58.0


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	_draw_great_clock()
	_draw_far_gears()
	layer("far", FAR_Y, 0.1)
	_draw_far_clocks()
	_draw_mid_gears()
	layer("mid", MID_Y, 0.25)
	_draw_mid_live()
	_draw_steam_jet()
	fx_draw()
	layer("near_top", NEAR_TOP_Y, 0.85)
	layer("near_bot", NEAR_BOT_Y, 0.85)
	_draw_train()
	drift_draw(drift_a)


func _draw_great_clock() -> void:
	var c: Vector2 = CLOCK_C
	var chime: bool = bg._ev_a.on
	var t: float = bg._ev_a.t
	# Bell pulses: three tolls once the hands reach twelve.
	if chime and t > 0.8:
		for i: int in range(3):
			var u: float = (t - 0.8 - float(i) * 1.1) / 1.4
			if u > 0.0 and u < 1.0:
				bg.draw_arc(c, CLOCK_R + 6.0 + u * 90.0, 0.0, TAU, 48, Color(1.0, 0.78, 0.4, 0.16 * (1.0 - u)), 2.0)
				bg.draw_circle(c, CLOCK_R, Color(1.0, 0.82, 0.5, 0.07 * (1.0 - u)))
		_draw_giant_pendulum(t - 0.8)
	var m: float = -PI * 0.5 + _ct * W_MIN
	var hr: float = -PI * 0.5 + _hour0 + _ct * W_HOUR
	var s: float = -PI * 0.5 + floorf(_ct) * TAU / 60.0
	_dim_hand(c, hr, 34.0, 3.0, Color("#100a06"), Color("#4a3418"))
	_dim_hand(c, m, 50.0, 2.0, Color("#100a06"), Color("#4a3418"))
	var sd: Vector2 = Vector2.from_angle(s)
	bg.draw_line(c - sd * 10.0, c + sd * 54.0, Color("#5a1c12"), 1.0)
	bg.draw_circle(c, 4.0, Color("#3a2812"))
	bg.draw_circle(c, 2.0, Color("#6a4a20"))


func _dim_hand(c: Vector2, a: float, length: float, width: float, col: Color, edge: Color) -> void:
	var dir: Vector2 = Vector2.from_angle(a)
	var nrm: Vector2 = Vector2(-dir.y, dir.x)
	var pts: PackedVector2Array = PackedVector2Array([c - dir * 6.0 + nrm * width * 0.5, c + dir * length * 0.6 + nrm * width, c + dir * length, c + dir * length * 0.6 - nrm * width, c - dir * 6.0 - nrm * width * 0.5])
	bg.draw_colored_polygon(pts, col)
	bg.draw_line(c, c + dir * (length - 2.0), edge, 1.0)


func _draw_giant_pendulum(t: float) -> void:
	var env: float = clampf(t / 0.6, 0.0, 1.0) * clampf((3.8 - t) / 0.6, 0.0, 1.0)
	if env <= 0.0:
		return
	var pv: Vector2 = CLOCK_C + Vector2(0.0, CLOCK_R + 4.0)
	var a: float = sin(t * TAU / 2.4) * 0.42 * env
	var bob: Vector2 = pv + Vector2(sin(a), cos(a)) * 96.0
	bg.draw_line(pv, bob, Color("#120b06"), 3.0)
	bg.draw_line(pv, bob, Color("#3a2812"), 1.0)
	bg.draw_circle(bob, 17.0, Color("#0e0905"))
	bg.draw_circle(bob, 15.0, Color("#2a1c0e"))
	bg.draw_arc(bob, 13.0, PI * 0.95, PI * 1.6, 10, Color("#5a4020"), 1.0)
	bg.draw_circle(bob, 4.0, Color("#3a2812"))


func _draw_far_gears() -> void:
	var o: float = fposmod(scroll * GEAR_PAR, GEAR_W)
	var tick: float = _tick_angle()
	for i: int in range(_fg_pos.size()):
		var gp: Vector2 = _fg_pos[i]
		var r: float = _fg_r[i]
		var sx: float = fposmod(gp.x - o, GEAR_W)
		if sx > 480.0 + r + 6.0:
			sx -= GEAR_W
		if sx < -r - 6.0 or sx > 480.0 + r + 6.0:
			continue
		var rot: float = _fg_off[i] + _fg_ratio[i] * tick * 30.0 / r
		if i < _fg_mesh.size():
			_draw_gear(_fg_mesh[i], Vector2(floorf(sx), gp.y), r - 4.0, rot, Color("#4a3418"))


func _draw_far_clocks() -> void:
	var clocks: PackedVector3Array = meta.get("far_clocks", PackedVector3Array())
	var o: float = off(0.1, FAR_W)
	for i: int in range(clocks.size()):
		var sx: float = wrap_x(clocks[i].x, o, FAR_W)
		if sx < -16.0 or sx > 496.0:
			continue
		var c: Vector2 = Vector2(sx, FAR_Y + clocks[i].y)
		var m: float = -PI * 0.5 + (_ct + float(i) * 7.0) * TAU / 20.0
		var hh: float = m / 12.0 + float(i)
		bg.draw_line(c, c + Vector2.from_angle(hh) * 6.0, Color("#140d07"), 2.0)
		bg.draw_line(c, c + Vector2.from_angle(m) * 9.0, Color("#140d07"), 1.0)
		bg.draw_rect(Rect2(c.x, c.y, 1.0, 1.0), Color("#6a4a20"))


func _draw_mid_gears() -> void:
	var o: float = off(0.25, MID_W)
	var spin: float = life * 0.9
	for i: int in range(_mg_pos.size()):
		var gp: Vector2 = _mg_pos[i]
		var r: float = _mg_r[i]
		var sx: float = wrap_x(gp.x, o, MID_W)
		if sx < -r - 4.0 or sx > 480.0 + r + 4.0:
			continue
		var rot: float = _mg_off[i] + _mg_ratio[i] * spin * 14.0 / r
		if i < _mg_mesh.size():
			_draw_gear(_mg_mesh[i], Vector2(sx, gp.y), r - 2.0, rot, Color("#9a7030"))


func _draw_mid_live() -> void:
	var o: float = off(0.25, MID_W)
	# Pistons: rods pumping out of their housings.
	var pistons: PackedVector3Array = meta.get("pistons", PackedVector3Array())
	for i: int in range(pistons.size()):
		var sx: float = wrap_x(pistons[i].x, o, MID_W)
		if sx < -8.0 or sx > 488.0:
			continue
		var dirn: float = pistons[i].z
		var ext: float = 4.0 + (0.5 + 0.5 * sin(life * 3.2 + float(i) * 1.7)) * 16.0
		var y0: float = MID_Y + pistons[i].y
		var y1: float = y0 + dirn * ext
		bg.draw_rect(Rect2(sx - 1.0, minf(y0, y1), 3.0, absf(y1 - y0)), Color("#6a7480"))
		bg.draw_rect(Rect2(sx - 1.0, minf(y0, y1), 1.0, absf(y1 - y0)), Color("#a8b4c0"))
		bg.draw_rect(Rect2(sx - 4.0, y1 - (0.0 if dirn > 0.0 else 3.0), 9.0, 3.0), Color("#6a4a1c"))
		bg.draw_rect(Rect2(sx - 4.0, y1 - (0.0 if dirn > 0.0 else 3.0), 9.0, 1.0), Color("#c8a050"))
	# Gauge needles twitching.
	var gauges: PackedVector2Array = meta.get("gauges", PackedVector2Array())
	for i2: int in range(gauges.size()):
		var gx: float = wrap_x(gauges[i2].x, o, MID_W)
		if gx < -6.0 or gx > 486.0:
			continue
		var a: float = -PI * 0.5 + sin(life * 1.3 + float(i2)) * 0.9 + sin(life * 17.0 + float(i2) * 3.0) * 0.08
		var c: Vector2 = Vector2(gx, MID_Y + gauges[i2].y)
		bg.draw_line(c, c + Vector2.from_angle(a) * 3.0, Color("#1a0c06"), 1.0)
	# Lamps flickering.
	var lamps: PackedVector2Array = meta.get("lamps", PackedVector2Array())
	for i3: int in range(lamps.size()):
		var lx: float = wrap_x(lamps[i3].x, o, MID_W)
		if lx < -14.0 or lx > 494.0:
			continue
		var fl: float = 0.75 + 0.15 * sin(life * 11.0 + float(i3) * 2.3) + 0.1 * sin(life * 29.0 + float(i3))
		if fposmod(life * 0.37 + float(i3) * 0.61, 1.0) < 0.03:
			fl = 0.25
		var lc: Vector2 = Vector2(floorf(lx), MID_Y + lamps[i3].y)
		bg.draw_circle(lc, 9.0, Color(1.0, 0.62, 0.22, 0.05 * fl))
		bg.draw_circle(lc, 4.0, Color(1.0, 0.7, 0.3, 0.12 * fl))
		bg.draw_rect(Rect2(lc.x - 1.0, lc.y - 1.0, 2.0, 2.0), Color(1.0, 0.8, 0.45, 0.85 * fl))


func _draw_steam_jet() -> void:
	if not (bg._ev_b.on and bg._ev_b.k > 0):
		return
	var t: float = bg._ev_b.t
	var env: float = clampf(t / 0.25, 0.0, 1.0) * clampf((bg._ev_b.dur - t) / 0.8, 0.0, 1.0)
	var bx: float = wrap_x(_burst_x, off(0.25, MID_W), MID_W)
	var by: float = MID_Y + _burst_y
	var length: float = minf(1.0, t * 2.5) * 210.0
	var dx: float = 0.0
	while dx < length:
		var u: float = dx / 210.0
		var r: float = 2.0 + u * 11.0
		var wob: float = sin(life * 9.0 + dx * 0.15) * u * 3.0
		bg.draw_circle(Vector2(bx - 6.0 - dx, by + wob), r, Color(0.85, 0.88, 0.92, 0.09 * env * (1.0 - u * 0.7)))
		dx += 14.0
	bg.draw_circle(Vector2(bx - 4.0, by), 3.0, Color(1.0, 1.0, 1.0, 0.35 * env))


func _draw_train() -> void:
	if not bg._ev_c.on:
		return
	var a: Vector2 = Vector2(floorf(_train_x), 302.0)
	var t: float = -_train_x / 58.0
	if _train_mesh.size() < 2:
		return
	_draw_gear(_train_mesh[0], a, 58.0 - 4.5, t, Color("#3a2812"))
	var b_c: Vector2 = a + Vector2.from_angle(PI + 0.95) * (58.0 + 29.0)
	_draw_gear(_train_mesh[1], b_c.floor(), 29.0 - 4.5, -t * 58.0 / 29.0 + 0.14, Color("#3a2812"))
