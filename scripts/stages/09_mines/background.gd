extends "res://scripts/stages/stage_background.gd"

# ORE MINES: inside a hollowed-out asteroid. Far away, the curved inner wall glitters with colony
# lights and a dusty shaft of starlight falls from a hole in the crust; nearer, open-pit terraces
# with haul roads and cranes, then giant support girders with an ore-cart gantry, a conveyor
# belt along the bottom and a rock ceiling hung with swinging sodium work lamps.
#
# Layers (paint(), worker thread):
#   "sky"       480x270 at (0,0): the inner wall, colony lights, the light shaft
#   "terraces"  768x120 at y 126, parallax 0.05: open-pit benches, roads, huts, cranes
#   "girders"   640x230 at y 28, parallax 0.2: pillars, top/bottom bracing, the gantry rail
#   "conveyor"  512x30 at y 220, parallax 0.45: belt frame, rollers, legs ("belt": its moving surface)
#   "floor"     512x16 at y 242, parallax 0.9: rubble and rails
#   "ceiling"   512x24 at y 28, parallax 0.9: jagged rock, lamp brackets
#   "cart", "engine": gantry cart sprites
# Animation: swinging lamps with faint light cones, carts on the gantry, ore riding the belt,
# cart lights crawling along the far haul roads, crane beacons, dust and falling grit, welding
# sparks. Rare events: a demolition blast on the terraces (_ev_a), a mining laser cutting the far
# bench (_ev_b), and an ore train with a headlight crossing the gantry (_ev_c).
# The playfield stays dark: girders are silhouettes and every bright pixel is small.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const TER_Y: float = 126.0
const GIR_Y: float = 28.0
const CON_Y: float = 220.0
const FLOOR_Y: float = 242.0
const CEIL_Y: float = 28.0
const RAIL_Y: float = 64.0     # gantry rail, in girder-layer rows
const SODIUM: Color = Color("#ffb040")

var _carts_x: PackedFloat32Array = PackedFloat32Array()
var _carts_v: PackedFloat32Array = PackedFloat32Array()
var _ore_x: PackedFloat32Array = PackedFloat32Array()
var _spark_t: float = 1.0
var _laser_from: Vector2 = Vector2.ZERO
var _laser_to0: Vector2 = Vector2.ZERO
var _laser_to1: Vector2 = Vector2.ZERO
var _blast_layer_x: float = 0.0
var _blast_y: float = 0.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9101
	var out: Dictionary = {}
	out["sky"] = _paint_sky(rng)
	_paint_terraces(rng, out)
	_paint_girders(rng, out)
	out["conveyor"] = _paint_conveyor()
	# The belt surface: dashes that slide along faster than the frame (drawn as its own layer).
	var belt: Image = Painter.new_img(512, 1)
	for bx: int in range(0, 512, 4):
		Painter.rect(belt, bx, 0, 2, 1, Color("#2c2016"))
	out["belt"] = belt
	out["floor"] = _paint_floor(rng)
	_paint_ceiling(rng, out)
	out["cart"] = _paint_cart(false)
	out["engine"] = _paint_cart(true)
	return out


static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#090705"))
	Painter.vgrad(sky, 22, 258, PackedColorArray([Color("#090705"), Color("#0d0a07"), Color("#110d09"), Color("#16100b"), Color("#1b130d"), Color("#20160f")]), 0.45)
	# Mottled rock on the far inner wall (very low contrast).
	var nf: PackedByteArray = Painter.fast_field(480, 240, 26.0, 3, 9102)
	for y: int in range(24, 250):
		for x: int in range(480):
			var v: float = float(nf[(y - 24) * 480 + x]) / 255.0
			if v > 0.62 and Painter.bayer(x, y) < (v - 0.62) * 3.0:
				Painter.blend_px(sky, x, y, Color("#2a1e14"), 0.35)
			elif v < 0.33 and Painter.bayer(x, y) < (0.33 - v) * 3.0:
				Painter.blend_px(sky, x, y, Color("#050403"), 0.5)
	# The hole in the crust at the top, with a slice of starfield, and its dusty light shaft.
	Painter.ellipse(sky, 334.0, 25.0, 19.0, 5.0, Color("#05070f"))
	Painter.ellipse(sky, 334.0, 25.0, 16.0, 3.5, Color("#0b1330"))
	for i: int in range(9):
		Painter.px(sky, 320 + rng.randi_range(0, 28), 23 + rng.randi_range(0, 4), Color("#9ab0ff") if i % 3 == 0 else Color("#4a5a9a"))
	Painter.ray_wedge(sky, Vector2(334.0, 22.0), PI * 0.5 + 0.1, 0.17, 236.0, Color("#241a12"), 0.6)
	Painter.ray_wedge(sky, Vector2(334.0, 22.0), PI * 0.5 + 0.08, 0.08, 220.0, Color("#2c2117"), 0.45)
	# Colony lights strung along the curved far wall: arcs of dim dots, a few brighter.
	for arc: int in range(5):
		var cy: float = 330.0 + float(arc) * 22.0
		var r: float = 260.0 + float(arc) * 26.0
		var a0: float = rng.randf_range(-2.3, -2.0)
		var a1: float = rng.randf_range(-1.15, -0.8)
		var a: float = a0
		while a < a1:
			var p: Vector2 = Vector2(240.0, cy) + Vector2.from_angle(a) * r
			if p.y > 34.0 and p.y < 122.0 and rng.randf() < 0.7:
				var c: Color = Color("#4a3014") if rng.randf() < 0.8 else Color("#8a5a20")
				Painter.px(sky, int(p.x), int(p.y), c)
				if rng.randf() < 0.15:
					Painter.px(sky, int(p.x) + 1, int(p.y), Color("#3a2610"))
			a += rng.randf_range(0.004, 0.012)
	# A few clustered settlements.
	for k: int in range(7):
		var cx: float = rng.randf_range(20.0, 460.0)
		var cyy: float = rng.randf_range(44.0, 110.0)
		for d: int in range(16):
			var q: Vector2 = Vector2(cx + rng.randfn(0.0, 7.0), cyy + rng.randfn(0.0, 3.0))
			Painter.px(sky, int(q.x), int(q.y), Color("#5a3a16") if d % 4 else Color("#a06a24"))
	return sky


static func _paint_terraces(rng: RandomNumberGenerator, out: Dictionary) -> void:
	# The far mine face: a rock overhang on top, then TIERS flat galleries stacked down the wall.
	# Each gallery has a lit ledge with a cart track, a face with timbered tunnel mouths, ladders
	# up to the next level and sheds. Scree slides break some ledges so the tiers don't read as
	# stripes.
	var w: int = 768
	var h: int = 120
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 4, 0.55)
	var nf: PackedByteArray = Painter.fast_field(w, h, 9.0, 2, 9103)
	var tiers: PackedFloat32Array = PackedFloat32Array([20.0, 42.0, 64.0, 86.0, 108.0])
	var face: PackedColorArray = PackedColorArray([Color("#0d0907"), Color("#120d09"), Color("#16100b"), Color("#1a130d")])
	var tops: PackedFloat32Array = PackedFloat32Array()
	tops.resize(w)
	# Per-row shading offset: dark right under each ledge lip, lighter toward the next ledge.
	var row_bias: PackedFloat32Array = PackedFloat32Array()
	row_bias.resize(h)
	for y0: int in range(h):
		var below: int = 99
		for t: float in tiers:
			if float(y0) >= t:
				below = y0 - int(t)
		row_bias[y0] = -0.35 if below < 5 else (0.1 if below > 14 and below < 99 else 0.0)
	var first: int = int(tiers[0])
	for x: int in range(w):
		var top: int = int(3.0 + (1.0 - prof[x]) * 12.0)
		tops[x] = float(top)
		for y: int in range(top, h):
			var n: float = float(nf[y * w + x]) / 255.0 - 0.5
			var v: float = (0.35 + n * 0.6) if y < first else (0.55 + n * 0.5 + row_bias[y])
			img.set_pixel(x, y, Painter.ramp_pick(face, v, x, y))
		img.set_pixel(x, top, Color("#2a1e14"))
	# Ledges with cart tracks.
	for t2: float in tiers:
		var r: int = int(t2)
		Painter.rect(img, 0, r, w, 1, Color("#36281a"))
		Painter.rect(img, 0, r + 1, w, 1, Color("#22180f"))
		Painter.rect(img, 0, r - 1, w, 1, Color("#1c150e"))
		for sx: int in range(0, w, 3):
			Painter.px(img, sx, r - 1, Color("#2c2016"))
	# Scree slides breaking some ledges.
	for t3: int in range(1, tiers.size()):
		for b: int in range(2):
			var bx: int = rng.randi_range(0, w - 1)
			var bw: int = rng.randi_range(16, 30)
			var r0: int = int(tiers[t3 - 1]) - 1
			var r1: int = int(tiers[t3]) + 2
			for y2: int in range(r0, r1):
				var k: float = float(y2 - r0) / float(r1 - r0)
				var half: int = int(float(bw) * (0.25 + 0.75 * k) * 0.5)
				for x2: int in range(bx - half, bx + half + 1):
					var c: Color = face[1 + ((x2 * 7 + y2 * 3) % 3)]
					if x2 == bx - half:
						c = Color("#261b12")
					Painter.px(img, x2, y2, c)
	# Tunnel mouths on every face, sitting on the ledge below them; some have a lamp inside.
	var lit: PackedVector2Array = PackedVector2Array()
	for t4: int in range(tiers.size()):
		var floor_row: int = int(tiers[t4 + 1]) - 1 if t4 + 1 < tiers.size() else h - 2
		if t4 + 1 >= tiers.size():
			continue
		var x3: int = rng.randi_range(0, 60)
		while x3 < w:
			var mw: int = rng.randi_range(8, 12)
			var mh: int = rng.randi_range(9, 12)
			var top3: int = floor_row - mh + 1
			Painter.rect(img, x3 - 1, top3 - 2, mw + 2, mh + 2, Color("#2a1e14"))
			Painter.rect(img, x3 - 2, top3 - 2, mw + 4, 1, Color("#3a2a1c"))
			Painter.rect(img, x3, top3, mw, mh, Color("#060403"))
			Painter.rect(img, x3 + 1, top3 - 1, mw - 2, 1, Color("#060403"))
			if rng.randf() < 0.45:
				Painter.rect(img, x3 + 1, floor_row - 2, mw - 2, 2, Color("#24140a"))
				lit.append(Vector2(float(x3 + mw / 2), float(floor_row - 3)))
			x3 += mw + rng.randi_range(30, 80)
	# Ladders between galleries.
	for l: int in range(10):
		var lx: int = rng.randi_range(0, w - 1)
		var t5: int = rng.randi_range(1, tiers.size() - 1)
		var ya: int = int(tiers[t5 - 1]) + 2
		var yb: int = int(tiers[t5]) - 1
		Painter.vline(img, lx, ya, yb, Color("#2a1e14"))
		Painter.vline(img, lx + 3, ya, yb, Color("#2a1e14"))
		for ry: int in range(ya + 1, yb, 3):
			Painter.rect(img, lx, ry, 4, 1, Color("#221810"))
	# Sheds on the ledges with lit windows.
	var windows: PackedVector2Array = PackedVector2Array()
	for hk: int in range(18):
		var hx: int = rng.randi_range(0, w - 1)
		var hy: int = int(tiers[rng.randi_range(0, tiers.size() - 1)]) - 6
		var hw: int = rng.randi_range(7, 14)
		Painter.rect(img, hx, hy, hw, 5, Color("#1f1710"))
		Painter.rect(img, hx - 1, hy, hw + 2, 1, Color("#3a2a1c"))
		for wx: int in range(hx + 2, hx + hw - 1, 3):
			Painter.px(img, wx, hy + 2, Color("#6a4418"))
			if rng.randf() < 0.4:
				windows.append(Vector2(float(posmod(wx, w)), float(hy + 2)))
	# Tower cranes on the overhang, beacons at the jib tips.
	var beacons: PackedVector2Array = PackedVector2Array()
	for ck: int in range(4):
		var cx: int = 90 + ck * 192 + rng.randi_range(-30, 30)
		var top4: int = int(tops[posmod(cx, w)])
		var mast_top: int = maxi(1, top4 - rng.randi_range(14, 24))
		for y4: int in range(mast_top, top4 + 2):
			Painter.px(img, cx, y4, Color("#1a130d"))
			Painter.px(img, cx + 2, y4, Color("#1a130d"))
			if (y4 - mast_top) % 3 == 0:
				Painter.px(img, cx + 1, y4, Color("#1a130d"))
		var jib: int = rng.randi_range(18, 28)
		Painter.rect(img, cx - jib, mast_top, jib + 10, 1, Color("#1f1710"))
		Painter.line(img, cx + 1, mast_top - 4, cx - jib, mast_top, Color("#1a130d"))
		Painter.line(img, cx + 1, mast_top - 4, cx + 9, mast_top, Color("#1a130d"))
		Painter.vline(img, cx - jib + 6, mast_top, mast_top + 9, Color("#16100b"))
		beacons.append(Vector2(float(posmod(cx - jib, w)), float(mast_top)))
		beacons.append(Vector2(float(posmod(cx + 1, w)), float(mast_top - 4)))
	# Faint cyan ore seams glinting in the faces.
	var glints: PackedVector2Array = PackedVector2Array()
	for g: int in range(44):
		var gx: int = rng.randi_range(0, w - 1)
		var gy: int = rng.randi_range(int(tiers[0]) + 4, h - 3)
		Painter.px(img, gx, gy, Color("#174a52"))
		if g % 3 == 0:
			glints.append(Vector2(float(gx), float(gy)))
	out["terraces"] = img
	out["ter_windows"] = windows
	out["ter_beacons"] = beacons
	out["ter_glints"] = glints
	out["ter_lit"] = lit
	out["ter_tiers"] = tiers


static func _paint_girders(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = 640
	var h: int = 230
	var img: Image = Painter.new_img(w, h)
	var body: Color = Color("#0b0806")
	var face: Color = Color("#141009")
	var rim: Color = Color("#2a1e13")
	var rivet: Color = Color("#3a2a1a")
	var pillars: PackedFloat32Array = PackedFloat32Array()
	for p: int in range(4):
		pillars.append(float(40 + p * 160 + rng.randi_range(-12, 12)))
	# Bracing first (behind the pillars): X trusses in the top and bottom bands only.
	for p2: int in range(4):
		var xa: int = int(pillars[p2]) + 7
		var xb: int = int(pillars[(p2 + 1) % 4]) + (w if p2 == 3 else 0)
		for band: Vector2i in [Vector2i(2, 46), Vector2i(176, 226)]:
			Painter.line(img, xa, band.x, xb, band.y, face)
			Painter.line(img, xa, band.x + 1, xb, band.y + 1, body)
			Painter.line(img, xa, band.y, xb, band.x, face)
			Painter.line(img, xa, band.y + 1, xb, band.x + 1, body)
			Painter.rect(img, xa, band.x, xb - xa, 2, face)
			Painter.rect(img, xa, band.y, xb - xa, 2, face)
	# The gantry rail: a heavy beam across the whole layer, with hangers to the top truss.
	Painter.rect(img, 0, int(RAIL_Y), w, 5, body)
	Painter.rect(img, 0, int(RAIL_Y), w, 1, rim)
	Painter.rect(img, 0, int(RAIL_Y) + 4, w, 1, face)
	for hx: int in range(0, w, 32):
		Painter.vline(img, hx, 47, int(RAIL_Y) - 1, face)
		Painter.px(img, hx, int(RAIL_Y) + 2, rivet)
	# Pillars: I-beams with flanges, rivets and a warm rim light on the lamp side.
	for p3: int in range(4):
		var px0: int = int(pillars[p3])
		Painter.rect(img, px0, 0, 14, h, body)
		Painter.rect(img, px0, 0, 3, h, face)
		Painter.rect(img, px0 + 11, 0, 3, h, face)
		Painter.vline(img, px0, 0, h - 1, rim)
		for ry: int in range(6, h, 12):
			Painter.px(img, px0 + 1, ry, rivet)
			Painter.px(img, px0 + 12, ry, rivet)
		# hazard band at head height of the floor
		for hy: int in range(h - 30, h - 24):
			for hx2: int in range(px0 + 3, px0 + 11):
				if ((hx2 + hy) / 2) % 2 == 0:
					Painter.px(img, hx2, hy, Color("#3a2a10"))
		# a cable bundle snaking down the pillar
		var cx: float = float(px0 + 16)
		for y: int in range(0, h, 1):
			cx += sin(float(y) * 0.11 + float(p3)) * 0.18
			Painter.px(img, int(cx), y, Color("#100c09"))
	out["girders"] = img
	out["pillars"] = pillars


static func _paint_conveyor() -> Image:
	var w: int = 512
	var img: Image = Painter.new_img(w, 30)
	var steel: Color = Color("#1a140f")
	var dark: Color = Color("#0c0907")
	# Legs (A-frames) down to the floor.
	for lx: int in range(20, w, 64):
		Painter.line(img, lx, 10, lx - 6, 29, steel)
		Painter.line(img, lx, 10, lx + 6, 29, steel)
		Painter.rect(img, lx - 4, 20, 9, 1, dark)
	# Belt frame and rollers.
	Painter.rect(img, 0, 5, w, 6, dark)
	Painter.rect(img, 0, 5, w, 1, Color("#2c2016"))
	Painter.rect(img, 0, 10, w, 1, steel)
	for rx: int in range(4, w, 16):
		Painter.disc(img, float(rx) + 0.5, 11.5, 2.0, steel)
		Painter.px(img, rx, 11, Color("#2c2016"))
	# Hazard skirt with dim stripes.
	for sx: int in range(w):
		if (sx / 4) % 2 == 0:
			Painter.px(img, sx, 13, Color("#3a2a10"))
		else:
			Painter.px(img, sx, 13, dark)
	# A loading hopper every 256 px.
	for hx: int in [96, 352]:
		Painter.poly(img, PackedVector2Array([Vector2(hx - 10, 0), Vector2(hx + 10, 0), Vector2(hx + 5, 5), Vector2(hx - 5, 5)]), steel)
		Painter.rect(img, hx - 10, 0, 21, 1, Color("#2c2016"))
	return img


static func _paint_floor(rng: RandomNumberGenerator) -> Image:
	var w: int = 512
	var img: Image = Painter.new_img(w, 16)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 4, 8, 0.6)
	var ramp: PackedColorArray = PackedColorArray([Color("#0c0907"), Color("#130e0a"), Color("#1b140e"), Color("#261c13")])
	for x: int in range(w):
		var top: int = int(1.0 + (1.0 - prof[x]) * 6.0)
		for y: int in range(top, 16):
			var v: float = 0.7 - float(y - top) * 0.09
			img.set_pixel(x, y, Painter.ramp_pick(ramp, v, x, y))
		img.set_pixel(x, top, Color("#2e2216"))
	# Rails with sleepers.
	for sx: int in range(0, w, 6):
		Painter.rect(img, sx, 11, 4, 3, Color("#160f0a"))
	Painter.rect(img, 0, 10, w, 1, Color("#4a3a2a"))
	Painter.rect(img, 0, 13, w, 1, Color("#3a2e22"))
	# Scattered ore pebbles.
	for i: int in range(30):
		Painter.px(img, rng.randi_range(0, w - 1), rng.randi_range(7, 15), Color("#174a52") if i % 4 else Color("#2a8a96"))
	return img


static func _paint_ceiling(rng: RandomNumberGenerator, out: Dictionary) -> void:
	var w: int = 512
	var h: int = 24
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 6, 0.6)
	var ramp: PackedColorArray = PackedColorArray([Color("#0a0806"), Color("#110c09"), Color("#18110c"), Color("#22180f")])
	for x: int in range(w):
		var bot: int = int(4.0 + prof[x] * 9.0)
		for y: int in range(0, bot):
			img.set_pixel(x, y, Painter.ramp_pick(ramp, 0.25 + float(y) * 0.05, x, y))
		img.set_pixel(x, bot, Color("#2a1e14"))
	# Stalactite-like rock drips.
	for k: int in range(22):
		var sx: int = rng.randi_range(0, w - 1)
		var sl: int = rng.randi_range(4, 10)
		var base: int = int(4.0 + prof[sx] * 9.0)
		for i: int in range(sl):
			var half: int = maxi(0, (sl - i) / 3)
			Painter.rect(img, sx - half, base + i, half * 2 + 1, 1, ramp[1])
		Painter.px(img, sx, base + sl, Color("#2a1e14"))
	# Steel lamp brackets bolted into the rock; lamps hang from these.
	var anchors: PackedFloat32Array = PackedFloat32Array()
	for ax: int in range(40, w, 96):
		var ax2: int = ax + rng.randi_range(-10, 10)
		Painter.rect(img, ax2 - 4, 2, 9, 3, Color("#1e1712"))
		Painter.rect(img, ax2 - 4, 2, 9, 1, Color("#3a2a1c"))
		Painter.rect(img, ax2, 5, 1, 4, Color("#1e1712"))
		anchors.append(float(ax2))
	# Drill holes.
	for d: int in range(14):
		var dx: int = rng.randi_range(0, w - 1)
		var dy: int = rng.randi_range(1, int(4.0 + prof[dx] * 9.0) - 2)
		Painter.px(img, dx, dy, Color("#050403"))
		Painter.px(img, dx + 1, dy, Color("#050403"))
	out["ceiling"] = img
	out["anchors"] = anchors


static func _paint_cart(engine: bool) -> Image:
	# Hangs from the gantry rail: trolley wheels, a hanger bar, then the bucket (or the engine).
	var img: Image = Painter.new_img(20 if engine else 16, 14)
	var steel: Color = Color("#2a2420")
	var mid: Color = Color("#3a322c")
	var hi: Color = Color("#5a4c40")
	var w: int = img.get_width()
	Painter.disc(img, 3.5, 1.5, 1.5, hi)
	Painter.disc(img, float(w) - 3.5, 1.5, 1.5, hi)
	Painter.rect(img, 3, 2, 1, 3, steel)
	Painter.rect(img, w - 4, 2, 1, 3, steel)
	Painter.rect(img, 2, 4, w - 4, 1, mid)
	if engine:
		Painter.rect(img, 1, 5, w - 2, 8, steel)
		Painter.rect(img, 1, 5, w - 2, 1, hi)
		Painter.rect(img, 2, 6, 6, 4, Color("#3a2a16"))
		Painter.rect(img, 3, 7, 4, 2, Color("#ffd27a"))
		for sx: int in range(9, w - 2):
			Painter.px(img, sx, 11, Color("#f2b630") if (sx / 2) % 2 == 0 else Color("#1a1410"))
		Painter.rect(img, 0, 8, 1, 2, Color("#fff2c0"))
	else:
		Painter.poly(img, PackedVector2Array([Vector2(0, 7), Vector2(16, 7), Vector2(13, 13), Vector2(3, 13)]), steel)
		Painter.rect(img, 0, 7, 16, 1, hi)
		Painter.rect(img, 2, 10, 12, 1, mid)
		# a heap of ore poking over the rim
		for i: int in range(6):
			Painter.disc(img, 3.5 + float(i) * 1.9, 6.5 - float(i % 2), 1.4, Color("#4a3e34") if i % 2 == 0 else Color("#6e5e50"))
		Painter.px(img, 5, 5, Color("#1fb4c8"))
		Painter.px(img, 10, 5, Color("#7ef4ff"))
		Painter.px(img, 8, 6, Color("#2a8a96"))
	return img


# --- Animation -------------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 32.0
	drift_a.y1 = 250.0
	drift_a.setup(34, rng, -9.0, -3.0, -2.0, 2.0)
	drift_a.par = 0.35
	drift_a.sway = 2.5
	drift_a.sway_hz = 0.6
	drift_a.cols = PackedColorArray([Color(0.62, 0.5, 0.36, 0.35), Color(0.45, 0.36, 0.26, 0.45), Color(0.8, 0.62, 0.4, 0.25)])
	drift_b.y0 = 30.0
	drift_b.y1 = 250.0
	drift_b.setup(18, rng, -2.0, 2.0, 26.0, 46.0)
	drift_b.par = 0.25
	drift_b.cols = PackedColorArray([Color(0.35, 0.28, 0.2, 0.5), Color(0.25, 0.2, 0.15, 0.6)])
	_carts_x.resize(5)
	_carts_v.resize(5)
	for i: int in range(5):
		_carts_x[i] = rng.randf_range(0.0, 640.0)
		_carts_v[i] = rng.randf_range(10.0, 22.0) * (1.0 if i % 2 == 0 else -1.0)
	_ore_x.resize(24)
	for j: int in range(24):
		_ore_x[j] = rng.randf_range(0.0, 512.0)
	_spark_t = rng.randf_range(0.6, 1.4)
	bg._ev_a.arm(rng, 15.0, 24.0, 5.0, 9.0)    # demolition blast
	bg._ev_b.arm(rng, 17.0, 27.0, 9.0, 14.0)   # mining laser
	bg._ev_c.arm(rng, 10.0, 17.0, 2.5, 5.0)    # ore train


func update() -> void:
	for i: int in range(_carts_x.size()):
		_carts_x[i] = fposmod(_carts_x[i] + _carts_v[i] * dl, 640.0)
	for j: int in range(_ore_x.size()):
		_ore_x[j] = fposmod(_ore_x[j] - 24.0 * dl, 512.0)
	# Welding sparks on a girder now and then.
	_spark_t -= dl
	if _spark_t <= 0.0:
		_spark_t = rng.randf_range(0.7, 1.8)
		var pillars: PackedFloat32Array = meta.get("pillars", PackedFloat32Array())
		if not pillars.is_empty():
			var o: float = off(0.2, 640.0)
			var px0: float = wrap_x(pillars[rng.randi_range(0, pillars.size() - 1)], o, 640.0)
			if px0 > 0.0 and px0 < 470.0:
				var sy: float = GIR_Y + (RAIL_Y + 2.0 if rng.randf() < 0.5 else rng.randf_range(10.0, 40.0))
				for s: int in range(rng.randi_range(4, 7)):
					fx_spawn(StarfieldBg.Fx.SPARK, px0 + 7.0, sy, rng.randf_range(-40.0, 40.0), rng.randf_range(-50.0, 5.0), rng.randf_range(0.4, 0.8), 0.2)
	# Blast: pick a spot on the visible part of the terraces.
	if bg._ev_a.tick(dl, rng):
		bg._ev_a.dur = 3.2
		_blast_layer_x = fposmod(off(0.05, 768.0) + rng.randf_range(60.0, 420.0), 768.0)
		var tiers: PackedFloat32Array = meta.get("ter_tiers", PackedFloat32Array([40.0]))
		_blast_y = TER_Y + tiers[rng.randi_range(0, tiers.size() - 2)] + 9.0
		var sx: float = wrap_x(_blast_layer_x, off(0.05, 768.0), 768.0)
		for b: int in range(10):
			fx_spawn(StarfieldBg.Fx.BOMB, sx, _blast_y, rng.randf_range(-30.0, 30.0), rng.randf_range(-70.0, -30.0), rng.randf_range(0.9, 1.5), 0.05)
		for s2: int in range(7):
			fx_spawn(StarfieldBg.Fx.SMOKE, sx + rng.randf_range(-4.0, 4.0), _blast_y - 2.0, rng.randf_range(-8.0, 8.0), rng.randf_range(-16.0, -6.0), rng.randf_range(2.2, 3.4), 0.05)
	# Mining laser: a beam from a cutter rig sweeping along a bench.
	if bg._ev_b.tick(dl, rng):
		bg._ev_b.dur = 3.4
		var lx: float = rng.randf_range(120.0, 360.0)
		_laser_from = Vector2(lx + rng.randf_range(-90.0, 90.0), 46.0)
		var ly: float = TER_Y + rng.randf_range(34.0, 70.0)
		_laser_to0 = Vector2(lx - 40.0, ly)
		_laser_to1 = Vector2(lx + 40.0, ly + 4.0)
	if bg._ev_b.on and int(life * 30.0) % 2 == 0:
		var u: float = bg._ev_b.t / bg._ev_b.dur
		var hit: Vector2 = _laser_to0.lerp(_laser_to1, u)
		fx_spawn(StarfieldBg.Fx.SPARK, hit.x, hit.y, rng.randf_range(-24.0, 24.0), rng.randf_range(-36.0, -4.0), rng.randf_range(0.3, 0.6), 0.05)
	# Ore train along the gantry.
	if bg._ev_c.tick(dl, rng):
		bg._ev_c.dur = 6.0
		bg._ev_c.x = 520.0


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	# Light shaft breathing slightly.
	var sh: float = 0.5 + 0.5 * sin(life * 0.35)
	bg.draw_colored_polygon(PackedVector2Array([Vector2(326.0, 24.0), Vector2(342.0, 24.0), Vector2(312.0, 250.0), Vector2(262.0, 250.0)]), Color(0.75, 0.6, 0.4, 0.015 + 0.012 * sh))

	# Far terraces with their lights.
	var o_t: float = off(0.05, 768.0)
	layer("terraces", TER_Y, 0.05)
	var wins: PackedVector2Array = meta.get("ter_windows", PackedVector2Array())
	for i: int in range(wins.size()):
		var wx: float = wrap_x(wins[i].x, o_t, 768.0)
		if wx < 0.0 or wx > 480.0:
			continue
		if fposmod(life * 0.13 + float(i) * 0.37, 1.0) < 0.85:
			bg.draw_rect(Rect2(floorf(wx), TER_Y + wins[i].y, 1.0, 1.0), Color("#c88a34"))
	var beacons: PackedVector2Array = meta.get("ter_beacons", PackedVector2Array())
	for b: int in range(beacons.size()):
		var bx: float = wrap_x(beacons[b].x, o_t, 768.0)
		if bx < 0.0 or bx > 480.0:
			continue
		if fposmod(life * 0.8 + float(b) * 0.29, 1.0) < 0.35:
			bg.draw_rect(Rect2(floorf(bx), TER_Y + beacons[b].y, 1.0, 1.0), Color("#ff4030"))
	var glints: PackedVector2Array = meta.get("ter_glints", PackedVector2Array())
	for g: int in range(glints.size()):
		var gx: float = wrap_x(glints[g].x, o_t, 768.0)
		if gx < 0.0 or gx > 480.0:
			continue
		var ph: float = fposmod(life * 0.31 + float(g) * 0.53, 1.0)
		if ph < 0.12:
			bg.draw_rect(Rect2(floorf(gx), TER_Y + glints[g].y, 1.0, 1.0), Color("#7ef4ff"))
	# Lamps flickering inside some tunnel mouths.
	var lit: PackedVector2Array = meta.get("ter_lit", PackedVector2Array())
	for m: int in range(lit.size()):
		var mx: float = wrap_x(lit[m].x, o_t, 768.0)
		if mx < 0.0 or mx > 480.0:
			continue
		var fl: float = 0.55 + 0.45 * sin(life * (2.0 + float(m % 3)) + float(m) * 1.9)
		bg.draw_rect(Rect2(floorf(mx), TER_Y + lit[m].y, 1.0, 1.0), Color(1.0, 0.62, 0.25, 0.5 + 0.5 * fl))
		bg.draw_rect(Rect2(floorf(mx) - 2.0, TER_Y + lit[m].y + 1.0, 5.0, 1.0), Color(1.0, 0.55, 0.2, 0.25 * fl))
	# Cart lights crawling along the gallery tracks.
	var tiers: PackedFloat32Array = meta.get("ter_tiers", PackedFloat32Array())
	for c: int in range(10):
		if tiers.is_empty():
			break
		var lane: int = c % tiers.size()
		var tx: float = fposmod(float(c) * 97.0 + life * (6.0 + float(c % 3) * 3.0) * (1.0 if c % 2 == 0 else -1.0), 768.0)
		var sx: float = wrap_x(tx, o_t, 768.0)
		if sx < 0.0 or sx > 480.0:
			continue
		var ty: float = TER_Y + tiers[lane] - 2.0
		bg.draw_rect(Rect2(floorf(sx), ty, 2.0, 1.0), Color("#3a2a1c"))
		bg.draw_rect(Rect2(floorf(sx) + (0.0 if c % 2 == 0 else 1.0), ty, 1.0, 1.0), Color("#ffe0a0") if c % 2 == 0 else Color("#ff8a3a"))
	_draw_blast()
	_draw_laser()

	drift_draw(drift_b)

	# Girders, the gantry carts and the ore train.
	var o_g: float = off(0.2, 640.0)
	layer("girders", GIR_Y, 0.2)
	var cart: Texture2D = tex("cart")
	for k: int in range(_carts_x.size()):
		var cx: float = wrap_x(_carts_x[k], o_g, 640.0)
		if cx < -16.0 or cx > 480.0:
			continue
		bg.draw_texture(cart, Vector2(floorf(cx), GIR_Y + RAIL_Y + 2.0))
	if bg._ev_c.on:
		var tx2: float = floorf(520.0 - bg._ev_c.t / bg._ev_c.dur * 760.0)
		var eng: Texture2D = tex("engine")
		bg.draw_colored_polygon(PackedVector2Array([Vector2(tx2 + 2.0, GIR_Y + RAIL_Y + 8.0), Vector2(tx2 - 70.0, GIR_Y + RAIL_Y + 2.0), Vector2(tx2 - 70.0, GIR_Y + RAIL_Y + 18.0)]), Color(1.0, 0.85, 0.5, 0.06))
		bg.draw_texture(eng, Vector2(tx2, GIR_Y + RAIL_Y + 2.0))
		bg.draw_rect(Rect2(tx2 - 1.0, GIR_Y + RAIL_Y + 10.0, 2.0, 2.0), Color("#fff2c0"))
		for n: int in range(6):
			bg.draw_texture(cart, Vector2(tx2 + 21.0 + float(n) * 17.0, GIR_Y + RAIL_Y + 2.0))

	# Conveyor with ore riding the belt.
	var o_c: float = off(0.45, 512.0)
	layer("conveyor", CON_Y, 0.45)
	layer("belt", CON_Y + 6.0, 0.45, Color.WHITE, life * 24.0)
	for j: int in range(_ore_x.size()):
		var ox: float = wrap_x(_ore_x[j], o_c, 512.0)
		if ox < 0.0 or ox > 480.0:
			continue
		bg.draw_rect(Rect2(floorf(ox), CON_Y + 4.0, 2.0, 1.0), Color("#3a2e24"))
		if j % 4 == 0:
			bg.draw_rect(Rect2(floorf(ox), CON_Y + 4.0, 1.0, 1.0), Color("#1fb4c8"))

	_draw_lamps()
	layer("ceiling", CEIL_Y, 0.9)
	layer("floor", FLOOR_Y, 0.9)
	fx_draw()
	drift_draw(drift_a)


# Swinging sodium lamps on cables from the ceiling brackets, each with a faint cone of light.
func _draw_lamps() -> void:
	var anchors: PackedFloat32Array = meta.get("anchors", PackedFloat32Array())
	var o: float = off(0.9, 512.0)
	for i: int in range(anchors.size()):
		var ax: float = wrap_x(anchors[i], o, 512.0)
		if ax < -40.0 or ax > 520.0:
			continue
		var cable: float = 14.0 + float(i % 3) * 5.0
		var ang: float = sin(life * 1.1 + float(i) * 1.7) * 0.22
		var top: Vector2 = Vector2(floorf(ax) + 0.5, CEIL_Y + 8.0)
		var lamp: Vector2 = top + Vector2(sin(ang), cos(ang)) * cable
		bg.draw_line(top, lamp, Color("#0c0907"), 1.0)
		var dirv: Vector2 = Vector2(sin(ang), cos(ang))
		var side: Vector2 = Vector2(dirv.y, -dirv.x)
		var flick: float = 1.0 if fposmod(life * 3.1 + float(i) * 2.3, 9.0) > 0.08 else 0.4
		var cone: Color = Color(1.0, 0.7, 0.32, 0.035 * flick)
		bg.draw_primitive(PackedVector2Array([lamp + side * 2.0, lamp - side * 2.0, lamp + dirv * 70.0 - side * 22.0, lamp + dirv * 70.0 + side * 22.0]), PackedColorArray([cone, cone, cone, cone]), PackedVector2Array())
		bg.draw_rect(Rect2(floorf(lamp.x) - 2.0, floorf(lamp.y) - 1.0, 5.0, 2.0), Color("#2a2018"))
		bg.draw_rect(Rect2(floorf(lamp.x) - 1.0, floorf(lamp.y) + 1.0, 3.0, 1.0), Color(SODIUM.r, SODIUM.g, SODIUM.b, flick))
		bg.draw_rect(Rect2(floorf(lamp.x), floorf(lamp.y) + 1.0, 1.0, 1.0), Color(1.0, 0.95, 0.8, flick))


func _draw_blast() -> void:
	if not bg._ev_a.on:
		return
	var u: float = bg._ev_a.t / bg._ev_a.dur
	var sx: float = wrap_x(_blast_layer_x, off(0.05, 768.0), 768.0)
	var fl: float = maxf(0.0, 1.0 - u * 6.0)
	if fl > 0.0:
		bg.draw_circle(Vector2(sx, _blast_y), 3.0 + (1.0 - fl) * 9.0, Color(1.0, 0.85, 0.55, 0.5 * fl))
		bg.draw_circle(Vector2(sx, _blast_y), 2.0, Color(1.0, 1.0, 0.9, fl))
		bg.draw_rect(Rect2(0.0, 28.0, 480.0, 230.0), Color(1.0, 0.7, 0.4, 0.035 * fl))
	# Dust cloud lingering over the spot.
	var dc: float = clampf(u * 3.0, 0.0, 1.0) * (1.0 - u)
	bg.draw_circle(Vector2(sx, _blast_y - 6.0 - u * 10.0), 6.0 + u * 16.0, Color(0.3, 0.24, 0.18, 0.3 * dc))


func _draw_laser() -> void:
	if not bg._ev_b.on:
		return
	var u: float = bg._ev_b.t / bg._ev_b.dur
	var ramp: float = minf(1.0, minf(u * 8.0, (1.0 - u) * 8.0))
	var hit: Vector2 = _laser_to0.lerp(_laser_to1, u)
	bg.draw_rect(Rect2(_laser_from.x - 3.0, _laser_from.y - 2.0, 7.0, 4.0), Color("#1a1410"))
	bg.draw_line(_laser_from, hit, Color(1.0, 0.25, 0.15, 0.25 * ramp), 3.0)
	bg.draw_line(_laser_from, hit, Color(1.0, 0.7, 0.5, 0.75 * ramp), 1.0)
	bg.draw_circle(hit, 2.5, Color(1.0, 0.8, 0.5, 0.6 * ramp))
	# Glowing cut left behind along the bench.
	bg.draw_line(_laser_to0, hit, Color(1.0, 0.4, 0.15, 0.35 * ramp), 1.0)
