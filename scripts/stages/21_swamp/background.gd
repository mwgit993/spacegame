extends "res://scripts/stages/stage_background.gd"

# TOXIC SWAMP: a dead, glowing bog at night. A sick green moon hangs behind drifting fog; ranks
# of dead trees stand in the mist with moss hanging off them; nearer, gnarled cypress trunks
# draped in moss, snapped snags, stumps, cypress knees and reeds stand in the water; a canopy of
# dead branches drips moss along the top, and the acid bog at the bottom glows, bubbles and pops.
# Will-o'-wisps wander between the trees.
#
# Layers (paint(), worker thread):
#   "sky"     480x270 at (0,0): murky gradient and clouds, the moon and its halo, horizon haze
#   "far"     640x150 at y 92, parallax 0.07: distant dead-tree silhouettes, misty bases
#   "far2"    640x128 at y 106, parallax 0.13: a nearer rank of dead trees with moss
#   "mid"     768x210 at y 24, parallax 0.22: gnarled trunks, moss curtains, snags, stumps,
#             cypress knees and reeds at the waterline
#   "canopy"  512x36 at y 22, parallax 0.62: dead branches and moss along the top edge
#   "bog"     512x42 at y 216, parallax 0.9 (wobbled below the surface): glow above the surface,
#             the uneven glowing surface edge, murky water with acid slicks, scum, pads and logs
#   "reeds"   512x44 at y 214, parallax 1.1: sparse dark clumps of reeds right in front
#   "fog_a" / "fog_b"  512x40 dithered translucent fog bands, drawn at three depths
# Animation: bubbles that swell and pop (with a puff of gas), acid sheen sliding on the surface,
# pulsing fungus, wandering will-o'-wisps, spores and fireflies, fog drifting at three speeds.
# Rare events: a methane pocket ignites and green fire runs across the bog (_ev_a), a huge bog
# creature surfaces and opens one eye (_ev_b), and a dead tree creaks and topples into the bog
# with a splash (_ev_c). The playfield stays dark and low in contrast.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const FAR_Y: float = 92.0
const FAR2_Y: float = 106.0
const MID_Y: float = 24.0
const MID_GL: int = 204              # the waterline in the mid layer (screen y 228)
const CANOPY_Y: float = 22.0
const BOG_Y: float = 216.0
const BOG_TOP: int = 10              # rows of glow above the surface in the bog layer
const SURFACE: float = 226.0
const REEDS_Y: float = 214.0

const WOOD: PackedColorArray = [Color("#09080c"), Color("#100d14"), Color("#17131d"), Color("#211b29"), Color("#2c2436")]
const MOSS_D: Color = Color("#121a0b")
const MOSS_M: Color = Color("#1a2610")
const MOSS_L: Color = Color("#263616")
const ACID: PackedColorArray = [Color("#1c3a08"), Color("#3e6c12"), Color("#6aa420"), Color("#b4ea48"), Color("#eaffb0")]
const FUNGUS: PackedColorArray = [Color("#3a0a2a"), Color("#7a1a5a"), Color("#c23c8e"), Color("#ff84cc")]

var _bub: PackedVector4Array = PackedVector4Array()    # x, y, age, life
var _pops: PackedVector4Array = PackedVector4Array()   # x, y, age, size
var _puffs: PackedVector4Array = PackedVector4Array()  # x, y, age, vx
var _bub_t: float = 0.2
var _wisps: PackedVector4Array = PackedVector4Array()  # x, y, phase, speed
var _flame_dir: float = -1.0
var _flame_x0: float = 500.0
var _eye_x: float = 300.0
var _eye_bub_t: float = 0.0
var _tree_x: float = 300.0
var _tree_h: float = 80.0
var _tree_dir: float = -1.0
var _tree_splash: bool = false
var _splash: PackedVector4Array = PackedVector4Array()  # x, y, vx, vy
var _splash_age: float = 0.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 21021
	var out: Dictionary = {}
	out["sky"] = _paint_sky(rng)
	out["far"] = _paint_trees(rng, 150, 140, 50.0, 124.0, 2.0, 4.5, 26.0, 52.0, Color("#10160d"), Color("#182013"), Color("#131b0f"), 0.4)
	out["far2"] = _paint_trees(rng, 128, 122, 58.0, 118.0, 3.0, 6.0, 46.0, 92.0, Color("#121a0f"), Color("#1c2717"), Color("#18220f"), 0.25)
	_paint_mid(rng, out)
	out["canopy"] = _paint_canopy(rng)
	out["bog"] = _paint_bog(rng)
	out["reeds"] = _paint_reeds(rng)
	out["fog_a"] = _paint_fog(21031, 0.55)
	out["fog_b"] = _paint_fog(21032, 0.45)
	return out


static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#050705"))
	Painter.vgrad(sky, 20, 236, PackedColorArray([Color("#050705"), Color("#070a06"), Color("#0a0e08"), Color("#0d1309"), Color("#11180b"), Color("#151d0e"), Color("#192210")]), 0.5)
	# Murky low clouds mottling the upper sky.
	var cf: PackedByteArray = Painter.fast_field(480, 110, 34.0, 3, 21025)
	for y0: int in range(20, 130):
		for x0: int in range(480):
			var v0: float = float(cf[(y0 - 20) * 480 + x0]) / 255.0
			if v0 > 0.6 and Painter.bayer(x0, y0) < (v0 - 0.6) * 2.2:
				Painter.blend_px(sky, x0, y0, Color("#121a0e"), 0.6)
			elif v0 < 0.32 and Painter.bayer(x0, y0) < (0.32 - v0) * 2.0:
				Painter.blend_px(sky, x0, y0, Color("#030403"), 0.6)
	# The moon's halo, dithered.
	var mc: Vector2 = Vector2(392.0, 60.0)
	for y: int in range(22, 112):
		for x: int in range(336, 450):
			var d: float = Vector2(float(x) - mc.x, float(y) - mc.y).length() / 46.0
			if d < 1.0 and Painter.bayer(x, y) < (1.0 - d) * 0.55:
				Painter.blend_px(sky, x, y, Color("#26321a"), 0.55)
	# The moon: a sick yellow-green disc lit from the upper left, with a shadowed limb.
	Painter.disc(sky, mc.x, mc.y, 14.0, Color("#4e5a2a"))
	Painter.disc(sky, mc.x - 1.5, mc.y - 1.5, 12.5, Color("#646e34"))
	Painter.disc(sky, mc.x - 3.5, mc.y - 3.5, 7.5, Color("#717d3d"))
	Painter.disc(sky, mc.x - 4.0, mc.y + 4.0, 2.2, Color("#57622e"))
	Painter.disc(sky, mc.x + 5.0, mc.y - 3.0, 1.6, Color("#57622e"))
	for y2: int in range(int(mc.y) - 14, int(mc.y) + 15):
		for x2: int in range(int(mc.x) - 2, int(mc.x) + 15):
			var dd: float = Vector2(float(x2) - mc.x, float(y2) - mc.y).length()
			if dd < 14.0 and Vector2(float(x2) - mc.x + 6.0, float(y2) - mc.y + 4.0).length() > 14.0 and Painter.bayer(x2, y2) < 0.75:
				Painter.px(sky, x2, y2, Color("#3c4622"))
	# One thin wisp of cloud drifting across the lower half of the moon.
	for x3: int in range(350, 452):
		var yy: int = 72 + int(sin(float(x3) * 0.07) * 2.0)
		var edge: float = minf(float(x3) - 350.0, 452.0 - float(x3))
		if edge < 16.0 and Painter.bayer(x3, yy) > edge / 16.0:
			continue
		Painter.px(sky, x3, yy, Color("#121a0e"))
		if x3 % 3 != 0:
			Painter.px(sky, x3, yy + 1, Color("#0e140b"))
	# A few dim stars through the murk.
	for i: int in range(30):
		var sx: int = rng.randi_range(0, 479)
		var sy: int = rng.randi_range(22, 120)
		if Vector2(float(sx) - mc.x, float(sy) - mc.y).length() > 30.0:
			Painter.px(sky, sx, sy, Color("#2a3222") if i % 4 != 0 else Color("#3a4430"))
	# Mottled green haze over the horizon.
	var nf: PackedByteArray = Painter.fast_field(480, 100, 26.0, 3, 21022)
	for y4: int in range(136, 236):
		var env: float = clampf((float(y4) - 136.0) / 70.0, 0.0, 1.0)
		for x4: int in range(480):
			var v: float = float(nf[(y4 - 136) * 480 + x4]) / 255.0
			if v > 0.55 and Painter.bayer(x4, y4) < (v - 0.55) * 2.4 * env:
				Painter.blend_px(sky, x4, y4, Color("#22301a"), 0.5)
	return sky


# A tileable rank of dead trees standing on the horizon, with crooked branches and moss.
static func _paint_trees(rng: RandomNumberGenerator, h: int, horizon: int, h_lo: float, h_hi: float, w_lo: float, w_hi: float, gap_lo: float, gap_hi: float, tree_c: Color, edge_c: Color, moss_c: Color, mist: float) -> Image:
	var w: int = 640
	var img: Image = Painter.new_img(w, h)
	Painter.rect(img, 0, horizon, w, h - horizon, tree_c.darkened(0.2))
	var x: float = rng.randf_range(4.0, 20.0)
	while x < float(w) - 8.0:
		var th: float = rng.randf_range(h_lo, h_hi)
		var tw: float = rng.randf_range(w_lo, w_hi)
		var top_y: float = float(horizon) - th
		var lean: float = rng.randf_range(-0.14, 0.14)
		var px_x: float = x
		var y: float = float(horizon)
		var trunk_pts: PackedVector2Array = PackedVector2Array()
		while y > top_y:
			var t: float = (float(horizon) - y) / th
			var wid: float = maxf(1.0, tw * (1.0 - t * 0.7) + 3.0 * pow(1.0 - t, 10.0))
			Painter.rect(img, int(px_x - wid * 0.5), int(y), int(ceilf(wid)), 1, tree_c)
			Painter.px(img, int(px_x - wid * 0.5), int(y), edge_c)
			trunk_pts.append(Vector2(px_x, y))
			px_x += lean + rng.randf_range(-0.35, 0.35)
			y -= 1.0
		var nb: int = rng.randi_range(3, 6)
		for b: int in range(nb):
			var at: int = int(float(trunk_pts.size()) * rng.randf_range(0.4, 0.95))
			if at >= trunk_pts.size():
				continue
			var bp: Vector2 = trunk_pts[at]
			var side: float = -1.0 if rng.randf() < 0.5 else 1.0
			var ang: float = -PI * 0.5 + side * rng.randf_range(0.6, 1.3)
			var blen: float = rng.randf_range(8.0, 26.0) * (th / 100.0 + 0.3)
			var be: Vector2 = bp + Vector2.from_angle(ang) * blen
			Painter.line(img, int(bp.x), int(bp.y), int(be.x), int(be.y), tree_c)
			if tw > 4.0:
				Painter.line(img, int(bp.x), int(bp.y) + 1, int(be.x), int(be.y) + 1, tree_c)
			var tw2: Vector2 = be + Vector2.from_angle(ang - side * 0.6) * rng.randf_range(3.0, 7.0)
			Painter.line(img, int(be.x), int(be.y), int(tw2.x), int(tw2.y), tree_c)
			for m: int in range(rng.randi_range(1, 4)):
				var mp: Vector2 = bp.lerp(be, rng.randf_range(0.3, 0.95))
				var ml: int = rng.randi_range(4, 16)
				Painter.vline(img, int(mp.x), int(mp.y) + 1, int(mp.y) + ml, moss_c)
		if rng.randf() < 0.3:
			Painter.line(img, int(px_x), int(top_y), int(px_x + 3.0), int(top_y + 4.0), tree_c)
		x += rng.randf_range(gap_lo, gap_hi)
	for i: int in range(140):
		var rx: int = rng.randi_range(0, w - 1)
		Painter.vline(img, rx, horizon - rng.randi_range(2, 7), horizon, tree_c)
	for y2: int in range(horizon - 22, horizon + 1):
		var a: float = 1.0 - float(horizon - y2) / 22.0
		for x2: int in range(w):
			if Painter.bayer(x2, y2) < a * mist:
				Painter.blend_px(img, x2, y2, Color("#1c2614"), 0.45)
	return img


static func _paint_mid(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = 768
	var h: int = 210
	var img: Image = Painter.new_img(w, h)
	var fungus: PackedVector3Array = PackedVector3Array()
	var bark: PackedByteArray = Painter.fast_field(w, h, 5.0, 2, 21023)
	# Thin dead snags snapped off part-way, standing behind the big trunks.
	for s: int in range(7):
		var sx: float = rng.randf_range(0.0, float(w))
		var top: float = rng.randf_range(40.0, 130.0)
		_trunk(img, bark, rng, sx, top, rng.randf_range(4.0, 6.0), rng.randf_range(-14.0, 14.0), false, fungus)
	# Gnarled cypress trunks draped in moss, at uneven spacing.
	var tx: float = 40.0
	var n: int = 0
	while tx < float(w) - 40.0:
		var big: bool = n % 3 != 2
		_trunk(img, bark, rng, tx, -2.0, rng.randf_range(13.0, 19.0) if big else rng.randf_range(8.0, 11.0), rng.randf_range(-24.0, 24.0), true, fungus)
		tx += rng.randf_range(110.0, 220.0)
		n += 1
	# Stumps along the waterline, with shelf fungus or glowing toadstools.
	for s3: int in range(10):
		var stx: float = rng.randf_range(0.0, float(w))
		var sh: float = rng.randf_range(10.0, 26.0)
		var sw: float = rng.randf_range(7.0, 13.0)
		var stop: float = float(MID_GL) - sh
		for x5: int in range(int(stx), int(stx + sw)):
			var jag: float = stop + float((x5 * 7) % 5) * 1.3
			var u2: float = (float(x5) - stx) / sw
			for y5: int in range(int(jag), MID_GL + 4):
				Painter.px(img, x5, y5, Painter.ramp_pick(WOOD, 0.62 - u2 * 0.5, x5, y5))
			Painter.px(img, x5, int(jag), WOOD[4])
		if s3 % 2 == 0:
			var cfx: float = stx + sw * 0.5
			Painter.ellipse(img, cfx + sw * 0.4, stop + 6.0, 3.0, 1.2, FUNGUS[1])
			Painter.px(img, int(cfx + sw * 0.4), int(stop + 5.0), FUNGUS[3])
			fungus.append(Vector3(cfx + sw * 0.4, stop + 5.0, 1.0))
		else:
			for g: int in range(2):
				var gx: int = int(stx + 2.0 + float(g) * 4.0)
				var gy: int = int(stop) + 1 + g
				Painter.rect(img, gx, gy, 1, 3, Color("#2a3418"))
				Painter.rect(img, gx - 1, gy - 1, 3, 1, ACID[2])
				Painter.px(img, gx, gy - 2, ACID[3])
				fungus.append(Vector3(float(gx), float(gy - 1), 0.0))
	# Cypress knees poking out of the water.
	for k: int in range(26):
		var kx: float = rng.randf_range(0.0, float(w))
		var kh: float = rng.randf_range(4.0, 11.0)
		var kw: float = rng.randf_range(2.5, 4.5)
		Painter.poly(img, PackedVector2Array([Vector2(kx - kw, float(MID_GL) + 3.0), Vector2(kx - 0.5, float(MID_GL) - kh), Vector2(kx + 0.5, float(MID_GL) - kh), Vector2(kx + kw, float(MID_GL) + 3.0)]), WOOD[2])
		Painter.line(img, int(kx - kw * 0.6), MID_GL + 1, int(kx - 0.5), int(float(MID_GL) - kh), WOOD[3])
	# Reeds and cattails along the waterline.
	for i: int in range(150):
		var rx: int = rng.randi_range(0, w - 1)
		var rh: int = rng.randi_range(6, 26)
		var lean: float = rng.randf_range(-0.25, 0.25)
		for k2: int in range(rh):
			Painter.px(img, rx + int(lean * float(k2)), MID_GL + 3 - k2, Color("#16200d") if k2 < rh - 3 else Color("#22301a"))
		if i % 5 == 0:
			Painter.rect(img, rx + int(lean * float(rh)) - 1, MID_GL + 3 - rh - 4, 2, 4, Color("#3a2a18"))
	out["mid"] = img
	out["mid_fungus"] = fungus


# A gnarled trunk from the waterline up to top_y (negative = through the canopy): knots, a lean,
# bark ridges, a hollow on the big ones, crooked limbs hung with moss curtains, shelf fungus.
static func _trunk(img: Image, bark: PackedByteArray, rng: RandomNumberGenerator, tx: float, top_y: float, base_w: float, lean: float, limbs: bool, fungus: PackedVector3Array) -> void:
	var w: int = img.get_width()
	var ph: float = rng.randf_range(0.0, TAU)
	var amp: float = rng.randf_range(2.0, 6.0)
	var knots: PackedFloat32Array = PackedFloat32Array([rng.randf_range(0.15, 0.4), rng.randf_range(0.5, 0.8)])
	var gl: float = float(MID_GL) + 3.0
	var span: float = gl - top_y
	var spine: PackedVector2Array = PackedVector2Array()
	var y0: int = maxi(0, int(top_y))
	for y: int in range(y0, int(gl) + 1):
		var t: float = (gl - float(y)) / span
		var cx: float = tx + lean * t + sin(t * 3.6 + ph) * amp + sin(t * 9.0 + ph * 2.0) * 1.2
		var wid: float = base_w * (1.0 - 0.45 * t) + 10.0 * pow(1.0 - t, 9.0) * base_w / 14.0
		for kn: float in knots:
			wid += 2.5 * exp(-pow((t - kn) / 0.035, 2.0))
		var x0: int = int(cx - wid * 0.5)
		var x1: int = int(cx + wid * 0.5)
		for x: int in range(x0, x1 + 1):
			var u: float = float(x - x0) / maxf(1.0, float(x1 - x0))
			var bv: float = float(bark[y * w + posmod(x, w)]) / 255.0
			var v: float = 0.58 - u * 0.48 + (bv - 0.5) * 0.4
			var c: Color = Painter.ramp_pick(WOOD, v, x, y)
			if x == x0 and y % 2 == 0:
				c = WOOD[3]
			Painter.px(img, x, y, c)
		if y % 4 == 0:
			Painter.px(img, int(cx + sin(float(y) * 0.23 + ph) * wid * 0.25), y, WOOD[0])
		spine.append(Vector2(cx, float(y)))
	if spine.is_empty():
		return
	# Snapped top on a snag.
	if top_y > 0.0:
		var tp: Vector2 = spine[0]
		Painter.line(img, int(tp.x - 2.0), int(tp.y), int(tp.x + 1.0), int(tp.y) - 4, WOOD[3])
		Painter.px(img, int(tp.x + 1.0), int(tp.y) - 4, WOOD[4])
	# A dark hollow on the big trunks.
	if base_w > 12.0:
		var hp: Vector2 = spine[int(float(spine.size()) * 0.72)]
		Painter.ellipse(img, hp.x + 1.0, hp.y, 2.6, 4.5, WOOD[3])
		Painter.ellipse(img, hp.x + 1.5, hp.y + 0.5, 1.8, 3.6, Color("#040305"))
	# Roots arching into the water.
	for r: int in range(4 if base_w > 9.0 else 2):
		var side: float = -1.0 if r % 2 == 0 else 1.0
		var bp0: Vector2 = spine[spine.size() - 1]
		var r0: Vector2 = Vector2(bp0.x + side * base_w * 0.3, gl - 16.0 - float(r) * 3.0)
		var r1: Vector2 = Vector2(bp0.x + side * rng.randf_range(base_w * 0.9, base_w * 1.9), gl)
		var steps: int = maxi(2, int(r0.distance_to(r1)))
		for st: int in range(steps):
			var q: Vector2 = r0.lerp(r1, float(st) / float(steps))
			q.y -= sin(float(st) / float(steps) * PI) * 5.0
			var rr: float = lerpf(3.0, 1.0, float(st) / float(steps))
			Painter.rect(img, int(q.x - rr * 0.5), int(q.y), int(ceilf(rr)), 2, WOOD[1])
			Painter.px(img, int(q.x - rr * 0.5), int(q.y), WOOD[3])
	if limbs:
		for b: int in range(rng.randi_range(2, 4)):
			var at: int = int(float(spine.size()) * rng.randf_range(0.03, 0.42))
			var p: Vector2 = spine[at]
			var side2: float = -1.0 if (b + int(ph * 10.0)) % 2 == 0 else 1.0
			var ang: float = -PI * 0.5 + side2 * rng.randf_range(0.9, 1.5)
			var bw: float = 3.5
			for seg: int in range(3):
				var length: float = rng.randf_range(10.0, 22.0)
				var nxt: Vector2 = p + Vector2.from_angle(ang) * length
				var steps2: int = maxi(1, int(p.distance_to(nxt)))
				for s2: int in range(steps2):
					var q2: Vector2 = p.lerp(nxt, float(s2) / float(steps2))
					var ww: float = maxf(1.0, bw - float(s2) / float(steps2))
					Painter.rect(img, int(q2.x), int(q2.y - ww * 0.5), 1, int(ceilf(ww)), WOOD[1])
					Painter.px(img, int(q2.x), int(q2.y - ww * 0.5), WOOD[3])
					# Spanish moss: strands of uneven length, in clumps.
					if s2 % 2 == 0 and seg + s2 > 2:
						var clump: float = 0.5 + 0.5 * sin(float(s2) * 0.5 + float(seg) * 2.0 + ph)
						var ml: int = int((4.0 + clump * 22.0) * (1.0 - float(seg) * 0.2) * rng.randf_range(0.6, 1.1))
						for k: int in range(ml):
							var mc: Color = MOSS_M if k < ml / 2 else MOSS_D
							if k == 0 or (k == 1 and clump > 0.6):
								mc = MOSS_L
							Painter.px(img, int(q2.x) + (1 if k > 7 and s2 % 4 == 0 else 0), int(q2.y + ww * 0.5) + k, mc)
				p = nxt
				ang += side2 * rng.randf_range(-0.5, 0.25) + rng.randf_range(-0.2, 0.2)
				bw = maxf(1.0, bw - 1.0)
			Painter.line(img, int(p.x), int(p.y), int(p.x + side2 * 4.0), int(p.y) - 3, WOOD[2])
	# Shelf fungus in little stacks on the trunk.
	var nf: int = rng.randi_range(1, 3) if base_w > 8.0 else rng.randi_range(0, 1)
	for f: int in range(nf):
		var fi: int = int(float(spine.size()) * rng.randf_range(0.55, 0.92))
		var fp: Vector2 = spine[fi]
		var fside: float = -1.0 if f % 2 == 0 else 1.0
		for sh: int in range(rng.randi_range(1, 2)):
			var fx: float = fp.x + fside * (base_w * 0.4 + 1.5)
			var fy: float = fp.y + float(sh) * 5.0
			var fw: int = 3 - sh
			for dx: int in range(-fw, fw + 1):
				var depth: int = 2 if absi(dx) < fw else 1
				Painter.vline(img, int(fx) + dx, int(fy), int(fy) + depth - 1, FUNGUS[0])
				Painter.px(img, int(fx) + dx, int(fy) - 1, FUNGUS[1])
			Painter.px(img, int(fx) - int(fside), int(fy) - 1, FUNGUS[2])
		fungus.append(Vector3(fp.x + fside * (base_w * 0.45 + 1.0), fp.y, 1.0))


static func _paint_canopy(rng: RandomNumberGenerator) -> Image:
	var w: int = 512
	var h: int = 36
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 4, 3, 0.6)
	for x: int in range(w):
		var y0: float = 1.0 + prof[x] * 7.0
		var thick: int = 2 + int(prof[(x * 3) % w] * 3.0)
		Painter.rect(img, x, 0, 1, int(y0) + thick, Color("#090b07"))
		Painter.px(img, x, int(y0) + thick, Color("#151c10"))
		var m: float = sin(float(x) * 0.21) * 0.5 + sin(float(x) * 0.077 + 1.0) * 0.5
		if m > 0.1 and (x * 13) % 3 != 0:
			var ml: int = int(4.0 + (m - 0.1) * 26.0 + float((x * 7) % 5))
			for k: int in range(ml):
				var c: Color = Color("#121a0c") if k < ml - 3 else Color("#1a2612")
				Painter.px(img, x, int(y0) + thick + 1 + k, c)
	for i: int in range(26):
		var bx: int = rng.randi_range(0, w - 1)
		var blen: int = rng.randi_range(5, 14)
		var dir: int = -1 if i % 2 == 0 else 1
		Painter.line(img, bx, int(1.0 + prof[bx] * 7.0) + 2, bx + dir * blen / 2, int(1.0 + prof[bx] * 7.0) + 2 + blen, Color("#0b0e08"))
	return img


static func _paint_bog(rng: RandomNumberGenerator) -> Image:
	var w: int = 512
	var h: int = 42
	var img: Image = Painter.new_img(w, h)
	# Glow hanging over the surface (translucent, dithered).
	for y: int in range(BOG_TOP):
		var a: float = pow(float(y + 1) / float(BOG_TOP), 2.0)
		for x: int in range(w):
			if Painter.bayer(x, y) < a * 0.55:
				img.set_pixel(x, y, Color(0.42, 0.68, 0.16, 0.06 + 0.1 * a))
	# The uneven surface and the water below it.
	var nf: PackedByteArray = Painter.fast_field(w, h, 10.0, 2, 21024)
	var slick: PackedByteArray = Painter.fast_field(w, h, 30.0, 2, 21026)
	var water: PackedColorArray = PackedColorArray([Color("#101809"), Color("#0d1408"), Color("#0a1006"), Color("#080c05")])
	for x2: int in range(w):
		var sy: int = BOG_TOP + int(roundf(sin(float(x2) * 0.05) * 0.7 + sin(float(x2) * 0.13 + 1.0) * 0.6))
		for y2: int in range(sy, h):
			var t: float = float(y2 - BOG_TOP) / float(h - BOG_TOP)
			var c: Color = water[clampi(int(t * 4.0 + Painter.bayer(x2, y2) * 0.8), 0, 3)]
			var v: float = float(nf[y2 * w + x2]) / 255.0
			var sv: float = float(slick[y2 * w + x2]) / 255.0
			if sv > 0.74 and Painter.bayer(x2, y2) < (sv - 0.74) * 6.0:
				c = Color("#16280b") if sv < 0.82 else Color("#1e3810")
				if sv > 0.88 and Painter.bayer(x2, y2) < 0.2:
					c = Color("#2e5612")
			elif v > 0.64 and Painter.bayer(x2, y2) < (v - 0.64) * 3.0:
				c = Color("#14220c")
			elif v < 0.3 and Painter.bayer(x2, y2) < (0.3 - v) * 2.0:
				c = Color("#050803")
			img.set_pixel(x2, y2, c)
		var g: float = 0.5 + 0.5 * sin(float(x2) * 0.09) * sin(float(x2) * 0.031 + 2.0)
		img.set_pixel(x2, sy, ACID[1] if Painter.bayer(x2, sy) < g else ACID[0])
		if (x2 * 11) % 37 == 0:
			img.set_pixel(x2, sy, ACID[2])
		if Painter.bayer(x2, sy + 1) < g * 0.4:
			img.set_pixel(x2, sy + 1, ACID[0])
	# Acid sheen streaks.
	for i: int in range(70):
		Painter.rect(img, rng.randi_range(0, w - 1), rng.randi_range(BOG_TOP + 3, h - 4), rng.randi_range(3, 12), 1, Color("#1c3410") if i % 3 != 0 else Color("#28461a"))
	# Scum and duckweed, lily pads, dead leaves and a couple of floating logs.
	for p: int in range(20):
		var cx: float = rng.randf_range(0.0, float(w))
		var cy: float = rng.randf_range(float(BOG_TOP) + 5.0, float(h) - 4.0)
		var rx: float = rng.randf_range(5.0, 14.0)
		Painter.ellipse(img, cx, cy, rx, rx * 0.22, Color("#16220d"))
		for d: int in range(int(rx)):
			Painter.px(img, int(cx + rng.randf_range(-rx, rx)), int(cy + rng.randf_range(-1.5, 1.5)), Color("#34501a"))
	for l: int in range(10):
		var lx: float = rng.randf_range(0.0, float(w))
		var ly: float = rng.randf_range(float(BOG_TOP) + 6.0, float(h) - 5.0)
		Painter.ellipse(img, lx, ly, 4.5, 1.4, Color("#17280c"))
		Painter.rect(img, int(lx) - 3, int(ly) - 1, 5, 1, Color("#2a4416"))
		Painter.px(img, int(lx) + 1, int(ly), Color("#0a1206"))
	for lg: int in range(3):
		var gx: float = rng.randf_range(0.0, float(w))
		var gy: float = rng.randf_range(float(BOG_TOP) + 8.0, float(h) - 8.0)
		var gl: float = rng.randf_range(26.0, 44.0)
		Painter.rect(img, int(gx), int(gy), int(gl), 3, Color("#17120e"))
		Painter.rect(img, int(gx), int(gy), int(gl), 1, Color("#2a2219"))
		Painter.rect(img, int(gx + gl), int(gy), 1, 3, Color("#3a2e22"))
		Painter.px(img, int(gx + gl * 0.4), int(gy) - 1, Color("#2a2219"))
		Painter.px(img, int(gx + gl * 0.6), int(gy), ACID[2])
	for k: int in range(30):
		Painter.rect(img, rng.randi_range(0, w - 1), rng.randi_range(BOG_TOP + 4, h - 3), 2, 1, Color("#2c2214"))
	return img


# Sparse clumps of reeds right in front, almost black.
static func _paint_reeds(rng: RandomNumberGenerator) -> Image:
	var w: int = 512
	var h: int = 44
	var img: Image = Painter.new_img(w, h)
	var cx: float = 30.0
	while cx < float(w) - 30.0:
		var blades: int = rng.randi_range(6, 12)
		for b: int in range(blades):
			var bx: float = cx + rng.randf_range(-9.0, 9.0)
			var bh: float = rng.randf_range(12.0, 40.0)
			var bend: float = rng.randf_range(-0.35, 0.35)
			for k: int in range(int(bh)):
				var t: float = float(k) / bh
				var x: int = int(bx + bend * t * t * bh * 0.5)
				Painter.px(img, x, h - 1 - k, Color("#050804"))
				if k % 3 == 0 and t > 0.3:
					Painter.px(img, x - 1, h - 1 - k, Color("#0e160a"))
			if b % 3 == 0:
				var tx: int = int(bx + bend * bh * 0.5)
				Painter.rect(img, tx - 1, h - int(bh) - 5, 2, 5, Color("#1a120a"))
				Painter.px(img, tx - 1, h - int(bh) - 5, Color("#2c2014"))
		cx += rng.randf_range(80.0, 150.0)
	return img


static func _paint_fog(seed_v: int, density: float) -> Image:
	var w: int = 512
	var h: int = 40
	var img: Image = Painter.new_img(w, h)
	var nf: PackedByteArray = Painter.fast_field(w, h, 38.0, 3, seed_v)
	for y: int in range(h):
		var env: float = sin(float(y) / float(h - 1) * PI)
		for x: int in range(w):
			var v: float = (float(nf[y * w + x]) / 255.0 - 0.35) * 1.6 * env
			if v <= 0.0:
				continue
			var b: float = Painter.bayer(x, y)
			if b < v * density:
				img.set_pixel(x, y, Color(0.5, 0.64, 0.38, 0.13 if b < v * density * 0.5 else 0.08))
	return img


# --- Animation -------------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 40.0
	drift_a.y1 = 250.0
	drift_a.setup(22, rng, -12.0, -4.0, -6.0, -1.0)
	drift_a.par = 0.35
	drift_a.sway = 3.0
	drift_a.sway_hz = 0.9
	drift_a.blink = 0.45
	drift_a.duty = 0.6
	drift_a.cols = PackedColorArray([Color(0.75, 1.0, 0.4, 0.55), Color(0.95, 0.95, 0.45, 0.45), Color(0.55, 0.85, 0.3, 0.5)])
	drift_b.y0 = 60.0
	drift_b.y1 = 236.0
	drift_b.setup(18, rng, -4.0, -1.0, -3.0, 1.0)
	drift_b.par = 0.1
	drift_b.cols = PackedColorArray([Color(0.4, 0.55, 0.28, 0.35), Color(0.32, 0.42, 0.22, 0.4)])
	_bub.resize(0)
	_pops.resize(0)
	_puffs.resize(0)
	_splash.resize(0)
	_wisps.resize(0)
	for i: int in range(5):
		_wisps.append(Vector4(rng.randf_range(0.0, 480.0), rng.randf_range(120.0, 214.0), rng.randf_range(0.0, TAU), rng.randf_range(0.6, 1.2)))
	bg._ev_a.arm(rng, 13.0, 21.0, 5.0, 9.0)    # methane ignites and fire runs across the bog
	bg._ev_b.arm(rng, 17.0, 26.0, 10.0, 15.0)  # the bog creature surfaces and opens an eye
	bg._ev_c.arm(rng, 15.0, 24.0, 14.0, 19.0)  # a dead tree topples into the bog


func update() -> void:
	# Bubbles: swell on the surface, then pop (with a puff of gas).
	var i: int = 0
	while i < _bub.size():
		var b: Vector4 = _bub[i]
		b.z += dl
		b.x -= ds * 0.9
		if b.z >= b.w:
			_pops.append(Vector4(b.x, b.y, 0.0, 1.0 + floorf(b.w * 1.6)))
			if rng.randf() < 0.55 and _puffs.size() < 12:
				_puffs.append(Vector4(b.x, b.y - 2.0, 0.0, rng.randf_range(-6.0, 2.0)))
			_bub.remove_at(i)
			continue
		_bub[i] = b
		i += 1
	_bub_t -= dl
	if _bub_t <= 0.0:
		_bub_t = rng.randf_range(0.08, 0.24)
		if _bub.size() < 14:
			_bub.append(Vector4(rng.randf_range(0.0, 480.0), rng.randf_range(229.0, 252.0), 0.0, rng.randf_range(0.5, 1.3)))
	if bg._ev_b.on and bg._ev_b.t < 1.8:
		_eye_bub_t -= dl
		if _eye_bub_t <= 0.0 and _bub.size() < 22:
			_eye_bub_t = 0.05
			_bub.append(Vector4(_eye_x + rng.randf_range(-34.0, 34.0), rng.randf_range(228.0, 236.0), 0.0, rng.randf_range(0.3, 0.7)))
	var j: int = 0
	while j < _pops.size():
		var p: Vector4 = _pops[j]
		p.z += dl
		p.x -= ds * 0.9
		if p.z > 0.4:
			_pops.remove_at(j)
			continue
		_pops[j] = p
		j += 1
	var k: int = 0
	while k < _puffs.size():
		var f: Vector4 = _puffs[k]
		f.z += dl
		f.x += f.w * dl - ds * 0.85
		f.y -= 7.0 * dl
		if f.z > 2.2:
			_puffs.remove_at(k)
			continue
		_puffs[k] = f
		k += 1
	# Will-o'-wisps wander between the trees.
	for w: int in range(_wisps.size()):
		var ws: Vector4 = _wisps[w]
		ws.z += dl * ws.w
		ws.x += (sin(ws.z * 0.7) * 9.0 - 3.0) * dl - ds * 0.15
		ws.y += cos(ws.z * 0.9) * 6.0 * dl
		if ws.x < -12.0:
			ws.x = 492.0
			ws.y = rng.randf_range(120.0, 214.0)
		_wisps[w] = ws
	# Event A: methane ignites at one edge and the fire runs across the bog.
	if bg._ev_a.tick(dl, rng):
		bg._ev_a.dur = 2.8
		_flame_dir = -1.0 if rng.randf() < 0.6 else 1.0
		_flame_x0 = 500.0 if _flame_dir < 0.0 else -20.0
	# Event B: the bog creature.
	if bg._ev_b.tick(dl, rng):
		bg._ev_b.dur = 7.4
		_eye_x = rng.randf_range(160.0, 400.0)
		_eye_bub_t = 0.0
	if bg._ev_b.on:
		_eye_x -= ds * 0.22
	# Event C: a dead tree topples.
	if bg._ev_c.tick(dl, rng):
		bg._ev_c.dur = 3.6
		_tree_x = rng.randf_range(200.0, 420.0)
		_tree_h = rng.randf_range(84.0, 116.0)
		_tree_dir = -1.0 if rng.randf() < 0.5 else 1.0
		_tree_splash = false
		_splash.resize(0)
	if bg._ev_c.on:
		_tree_x -= ds * 0.13
		if not _tree_splash and bg._ev_c.t >= 1.95:
			_tree_splash = true
			_splash_age = 0.0
			var tip_x: float = _tree_x + _tree_dir * _tree_h * 0.95
			for s: int in range(16):
				var a: float = -PI * 0.5 + rng.randf_range(-0.9, 0.9)
				var sp: float = rng.randf_range(30.0, 95.0)
				var sx: float = lerpf(_tree_x, tip_x, rng.randf_range(0.3, 1.0))
				_splash.append(Vector4(sx, SURFACE - 1.0, cos(a) * sp * 0.6, sin(a) * sp))
	if not _splash.is_empty():
		_splash_age += dl
		for q: int in range(_splash.size()):
			var v: Vector4 = _splash[q]
			v.w += 170.0 * dl
			v.x += v.z * dl - ds * 0.13
			v.y += v.w * dl
			_splash[q] = v
		if _splash_age > 1.0:
			_splash.resize(0)


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	layer("fog_b", 46.0, 0.12, Color(1.0, 1.0, 1.0, 0.55), life * 6.0)
	drift_draw(drift_b)
	layer("far", FAR_Y, 0.07)
	layer("far2", FAR2_Y, 0.13)
	layer("fog_a", 150.0, 0.3, Color(1.0, 1.0, 1.0, 0.7), life * 9.0)
	_draw_tree()
	layer("mid", MID_Y, 0.22)
	_draw_fungus_glow()
	_draw_creature()
	_draw_wisps()
	layer("canopy", CANOPY_Y, 0.62)
	_draw_bog()
	_draw_surface()
	_draw_flames()
	layer("reeds", REEDS_Y, 1.1)
	layer("fog_b", 200.0, 0.5, Color(1.0, 1.0, 1.0, 0.75), life * 14.0)
	drift_draw(drift_a)


# The bog layer: the glow and surface rows stay put, the water below ripples.
func _draw_bog() -> void:
	layer_wobble("bog", BOG_Y, 0.9, 2, 1.6, 0.6, 1.4, BOG_TOP + 2)


func _draw_fungus_glow() -> void:
	var fungus: PackedVector3Array = meta.get("mid_fungus", PackedVector3Array())
	var o: float = off(0.22, 768.0)
	for f: int in range(fungus.size()):
		var fx: float = wrap_x(fungus[f].x, o, 768.0)
		if fx < -6.0 or fx > 486.0:
			continue
		var pulse: float = 0.5 + 0.5 * sin(life * 1.3 + float(f) * 2.3)
		var c: Color = FUNGUS[2] if fungus[f].z > 0.5 else ACID[2]
		bg.draw_circle(Vector2(floorf(fx), MID_Y + fungus[f].y), 3.0 + pulse, Color(c.r, c.g, c.b, 0.06 + 0.07 * pulse))


func _draw_wisps() -> void:
	for w: int in range(_wisps.size()):
		var ws: Vector4 = _wisps[w]
		var vis: float = clampf(sin(ws.z * 0.5) * 1.6, 0.0, 1.0)
		if vis <= 0.02:
			continue
		var p: Vector2 = Vector2(floorf(ws.x), floorf(ws.y))
		bg.draw_circle(p, 6.0, Color(0.6, 1.0, 0.35, 0.05 * vis))
		bg.draw_circle(p, 3.0, Color(0.7, 1.0, 0.45, 0.12 * vis))
		bg.draw_rect(Rect2(p.x, p.y, 1.0, 1.0), Color(0.9, 1.0, 0.7, 0.85 * vis))
		bg.draw_rect(Rect2(p.x + 2.0, p.y + floorf(sin(ws.z * 3.0)), 2.0, 1.0), Color(0.6, 0.9, 0.4, 0.25 * vis))


# Bubbles, pops, gas puffs and the sheen on the bog.
func _draw_surface() -> void:
	var o: float = off(0.9, 512.0)
	for s: int in range(7):
		var sx: float = wrap_x(float(s) * 73.0 + 11.0, o, 512.0)
		var a: float = 0.5 + 0.5 * sin(life * 1.7 + float(s) * 1.9)
		if a > 0.55 and sx > -8.0 and sx < 488.0:
			bg.draw_rect(Rect2(floorf(sx), SURFACE + 2.0 + float(s % 3) * 6.0, 4.0 + float(s % 3) * 2.0, 1.0), Color(0.75, 1.0, 0.4, (a - 0.55) * 0.8))
	for i: int in range(_bub.size()):
		var b: Vector4 = _bub[i]
		var r: float = floorf(1.0 + (b.z / b.w) * 2.2)
		var p: Vector2 = Vector2(floorf(b.x), floorf(b.y))
		bg.draw_rect(Rect2(p.x - r, p.y - r, r * 2.0 + 1.0, r * 2.0), Color(0.16, 0.3, 0.07, 0.9))
		bg.draw_rect(Rect2(p.x - r + 1.0, p.y - r, r * 2.0 - 1.0, 1.0), Color(0.55, 0.85, 0.25, 0.9))
		bg.draw_rect(Rect2(p.x - r + 1.0, p.y - r + 1.0, 1.0, 1.0), Color(0.9, 1.0, 0.65, 0.9))
	for j: int in range(_pops.size()):
		var pp: Vector4 = _pops[j]
		var u: float = pp.z / 0.4
		var rr: float = pp.w + u * 4.0
		var c: Color = Color(0.7, 1.0, 0.35, 0.7 * (1.0 - u))
		var q: Vector2 = Vector2(floorf(pp.x), floorf(pp.y))
		bg.draw_rect(Rect2(q.x - rr, q.y, rr * 2.0 + 1.0, 1.0), c)
		bg.draw_rect(Rect2(q.x - 1.0, q.y - 1.0 - floorf(u * 6.0), 1.0, 1.0), c)
		bg.draw_rect(Rect2(q.x + 2.0, q.y - floorf(u * 4.0), 1.0, 1.0), c)
	for k: int in range(_puffs.size()):
		var f: Vector4 = _puffs[k]
		var u2: float = f.z / 2.2
		var r2: float = floorf(1.0 + u2 * 4.0)
		bg.draw_rect(Rect2(floorf(f.x) - r2, floorf(f.y) - r2, r2 * 2.0 + 1.0, r2 * 2.0), Color(0.55, 0.75, 0.3, 0.16 * (1.0 - u2)))


# Event A: green methane fire running across the bog: a sheet of flickering tongues behind the
# bright front, with sparks, dying out as it passes.
func _draw_flames() -> void:
	if not bg._ev_a.on:
		return
	var t: float = bg._ev_a.t
	var front: float = _flame_x0 + _flame_dir * 300.0 * t
	var u: float = t / bg._ev_a.dur
	var flash: float = minf(1.0, minf(u * 8.0, (1.0 - u) * 3.0))
	bg.draw_rect(Rect2(0.0, 196.0, 480.0, 62.0), Color(0.45, 1.0, 0.25, 0.03 * flash))
	var tick: int = int(life * 14.0)
	var x: float = 0.0
	while x < 480.0:
		# passed > 0: the front went by this column `passed` px ago.
		var passed: float = (front - x) * _flame_dir
		var dt: float = passed / 300.0
		if dt > 0.0 and dt < 0.65:
			var k: float = 1.0 - dt / 0.65
			var shape: float = float((int(x) * 37) % 23) / 23.0
			var hsh: int = (int(x) * 73 + tick * 151) % 97
			var flick: float = 0.7 + 0.3 * float(hsh) / 97.0
			var fh: float = floorf((3.0 + 28.0 * k * k * (0.25 + 0.75 * shape)) * flick)
			var wob: float = floorf(sin(life * 9.0 + x * 0.3) * 1.5)
			bg.draw_rect(Rect2(x - 1.0, SURFACE - fh * 0.55, 5.0, fh * 0.55), Color(0.18, 0.55, 0.1, 0.35 * k))
			bg.draw_rect(Rect2(x + wob * 0.5, SURFACE - fh, 2.0, fh), Color(0.42, 0.88, 0.2, 0.5 * k))
			bg.draw_rect(Rect2(x, SURFACE - fh * 0.35, 2.0, fh * 0.35), Color(0.9, 1.0, 0.65, 0.75 * k))
			if hsh % 9 == 0:
				bg.draw_rect(Rect2(x + 1.0, SURFACE - fh - 4.0 - float(hsh % 5) * 3.0, 1.0, 1.0), Color(0.9, 1.0, 0.6, 0.85 * k))
		x += 4.0
	if front > -10.0 and front < 490.0:
		bg.draw_circle(Vector2(front, SURFACE - 6.0), 10.0, Color(0.6, 1.0, 0.35, 0.1))
		bg.draw_circle(Vector2(front, SURFACE - 4.0), 4.0, Color(0.9, 1.0, 0.6, 0.3))


# Event B: a huge bog creature surfaces near the waterline, opens one eye, looks about, sinks.
func _draw_creature() -> void:
	if not bg._ev_b.on:
		return
	var t: float = bg._ev_b.t
	var dur: float = bg._ev_b.dur
	var rise: float = clampf(t / 1.5, 0.0, 1.0) * clampf((dur - t) / 1.3, 0.0, 1.0)
	var hump_h: float = floorf(26.0 * (rise * (2.0 - rise)))
	if hump_h < 1.0:
		return
	var cx: float = floorf(_eye_x)
	var base: float = SURFACE + 2.0
	var rx: float = 46.0
	# The back: a dark mossy hump with a ridge of knobs, moss hanging off it.
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(17):
		var a: float = PI + PI * float(i) / 16.0
		var bump: float = 1.0 + 0.06 * sin(float(i) * 2.3)
		pts.append(Vector2(cx + cos(a) * rx, base + sin(a) * hump_h * bump))
	bg.draw_colored_polygon(pts, Color("#0b0e08"))
	for r: int in range(7):
		var kx: float = cx - 26.0 + float(r) * 9.0
		var top: float = base - hump_h * sqrt(maxf(0.0, 1.0 - pow((kx - cx) / rx, 2.0)))
		bg.draw_rect(Rect2(kx, top - 2.0, 3.0, 3.0), Color("#141a0e"))
		bg.draw_rect(Rect2(kx, top - 2.0, 1.0, 1.0), Color("#222c16"))
		if r % 2 == 1:
			bg.draw_line(Vector2(kx + 1.0, top + 1.0), Vector2(kx + 1.0, top + 6.0 + float(r)), Color("#18240e"), 1.0)
	bg.draw_line(Vector2(cx - 36.0, base - hump_h * 0.55), Vector2(cx - 16.0, base - hump_h * 0.93), Color("#1c2412"), 1.0)
	# The eye opens, glances about, blinks once, closes.
	var open: float = clampf((t - 1.5) / 0.45, 0.0, 1.0) * clampf((dur - 1.4 - t) / 0.4, 0.0, 1.0)
	if t > 3.6 and t < 3.8:
		open *= 0.1
	if open > 0.05 and hump_h > 14.0:
		var e: Vector2 = Vector2(cx - 18.0, base - hump_h + 9.0)
		var ry: float = maxf(1.0, 4.5 * open)
		bg.draw_circle(e, 14.0, Color(1.0, 0.75, 0.2, 0.05 * open))
		bg.draw_set_transform(e, 0.0, Vector2(1.0, ry / 8.0))
		bg.draw_circle(Vector2.ZERO, 8.0, Color("#9a6a14"))
		bg.draw_circle(Vector2(-1.0, -1.0), 6.0, Color("#d49a24"))
		bg.draw_circle(Vector2(-2.0, -2.0), 2.5, Color("#f0c850"))
		bg.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var look: float = floorf(sin((t - 1.5) * 1.2) * 3.0) - 1.0
		bg.draw_rect(Rect2(e.x + look, e.y - ry + 1.0, 2.0, maxf(1.0, ry * 2.0 - 1.0)), Color("#120804"))
		bg.draw_rect(Rect2(e.x - 9.0, e.y - ry - 1.0, 18.0, 1.0), Color("#0b0e08"))
		bg.draw_rect(Rect2(e.x - 8.0, e.y - ry - 2.0, 16.0, 1.0), Color("#151c0e"))


# Event C: a dead tree creaks, topples into the bog and splashes.
func _draw_tree() -> void:
	if bg._ev_c.on:
		var t: float = bg._ev_c.t
		var ang: float = 0.0
		if t < 0.75:
			ang = sin(t * 26.0) * 0.03 * (t / 0.75)
		else:
			var u: float = clampf((t - 0.75) / 1.2, 0.0, 1.0)
			ang = (PI * 0.5 - 0.12) * u * u
		var fade: float = clampf((bg._ev_c.dur - t) / 0.8, 0.0, 1.0)
		var sink: float = maxf(0.0, t - 2.2) * 4.0
		var base: Vector2 = Vector2(floorf(_tree_x), SURFACE + 1.0 + sink)
		var dir: Vector2 = Vector2(sin(ang * _tree_dir), -cos(ang))
		var nrm: Vector2 = Vector2(-dir.y, dir.x)
		var col: Color = Color(0.025, 0.032, 0.02, fade)
		var rim: Color = Color(0.12, 0.15, 0.09, fade)
		var top: Vector2 = base + dir * _tree_h
		bg.draw_line(base, base + dir * (_tree_h * 0.5), col, 5.0)
		bg.draw_line(base + dir * (_tree_h * 0.45), top, col, 3.0)
		bg.draw_line(base - nrm * 2.0, base + dir * (_tree_h * 0.5) - nrm * 2.0, rim, 1.0)
		for b: int in range(4):
			var bp: Vector2 = base + dir * (_tree_h * (0.42 + float(b) * 0.15))
			var side: float = -1.0 if b % 2 == 0 else 1.0
			var be: Vector2 = bp + dir.rotated(side * 0.9) * (20.0 - float(b) * 3.0)
			bg.draw_line(bp, be, col, 2.0)
			bg.draw_line(be, be + dir.rotated(side * 0.3) * 6.0, col, 1.0)
			bg.draw_line(be, be + Vector2(0.0, 7.0 + float(b) * 2.0), Color(0.07, 0.1, 0.045, fade * 0.9), 1.0)
	if not _splash.is_empty():
		var a: float = 1.0 - clampf(_splash_age / 1.0, 0.0, 1.0)
		for q: int in range(_splash.size()):
			var v: Vector4 = _splash[q]
			if v.y <= SURFACE:
				bg.draw_rect(Rect2(floorf(v.x), floorf(v.y), 1.0, 2.0), Color(0.6, 0.9, 0.35, 0.8 * a))
		var tip_x: float = _tree_x + _tree_dir * _tree_h * 0.7
		var rr: float = 6.0 + _splash_age * 34.0
		bg.draw_rect(Rect2(floorf(tip_x - rr), SURFACE - 1.0, floorf(rr * 2.0), 1.0), Color(0.65, 1.0, 0.35, 0.5 * a))
