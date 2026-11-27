extends "res://scripts/stages/stage_background.gd"

# STAGE 25 background: the exterior of a colossal orbital battle station. Deep space with a
# glare of sunlight behind the HUD and a small grey moon; the station's distant superstructure
# (modules, spokes, a docking ring) along the top with slow-blinking lights; the planet below
# turning slowly, its day side cloudy blue and green, a dithered terminator and cities
# glittering on the night side, a thin atmosphere rim along the curved horizon; solar arrays
# and docking arms rising from the station, a sun glint sweeping across the cells, beacons on
# the docking collars and maintenance drones flitting about; and, closest, the hull itself,
# with turret batteries that track far-off targets and fire flak puffs into the distance,
# running lights and lit ports. Rare events: a supply shuttle on approach, the station's
# searchlights sweeping the sky, and a capital-ship gun on the far superstructure firing at a
# distant target.
#
# Layers: "sky" 480x270; "ring" 768x80 at y 30 (0.02); "planet" 768x132 at y 126 (line
# scrolled 0.006-0.02); "night" 480x132 and "limb" 480x44 overlays (screen-fixed: the sun
# doesn't move); "far" 768x96 at y 150 (0.05); "arrays" 1024x150 at y 96 (0.12); "hull"
# 768x42 at y 216 (0.3); "shuttle" 30x12.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const RING_Y: float = 30.0
const RING_F: float = 0.02
const PLANET_Y: float = 126.0
const PLANET_H: int = 132
const PLANET_FT: float = 0.006
const PLANET_FB: float = 0.02
const LIMB_Y: float = 118.0
const FAR_Y: float = 150.0
const FAR_F: float = 0.05
const ARR_Y: float = 96.0
const ARR_F: float = 0.12
const ARR_W: float = 1024.0
const HULL_Y: float = 216.0
const HULL_F: float = 0.3
const HORIZON_R: float = 1500.0
const HORIZON_CX: float = 250.0
const SHUTTLE_TIME: float = 15.0
const SEARCH_TIME: float = 6.5
const GUN_TIME: float = 1.8

var _ev_wait_a: float = 8.0    # supply shuttle
var _ev_wait_b: float = 5.0    # searchlights
var _ev_wait_c: float = 11.0   # capital gun
var _shuttle_t: float = -1.0
var _shuttle_y0: float = 70.0
var _shuttle_y1: float = 110.0
var _search_t: float = -1.0
var _gun_t: float = -1.0
var _gun_from: Vector2 = Vector2(372.0, 58.0)
# flak puffs from the hull turrets, far away in the sky: x, y, age (negative = still in flight)
var _puffs: PackedVector3Array = PackedVector3Array()
var _turret_cd: PackedFloat32Array = PackedFloat32Array()
var _flash: PackedFloat32Array = PackedFloat32Array()


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2525
	var out: Dictionary = {}
	var sky: Image = _paint_sky(rng)
	out["sky"] = sky
	_paint_ring(out, rng)
	_paint_planet(out, rng)
	_paint_limb(out, sky)
	_paint_night(out)
	_paint_far(out, rng)
	_paint_arrays(out, rng)
	_paint_hull(out, rng)
	_paint_shuttle(out)
	return out


static func horizon_y(x: float) -> float:
	var dx: float = x - HORIZON_CX
	return PLANET_Y + HORIZON_R - sqrt(HORIZON_R * HORIZON_R - dx * dx)


static func terminator_x(y: float) -> float:
	return 258.0 + (y - PLANET_Y) * 0.35


static func _paint_sky(rng: RandomNumberGenerator) -> Image:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#02040e"))
	Painter.vgrad(sky, 20, 160, PackedColorArray([Color("#02040e"), Color("#030716"), Color("#040a1c"), Color("#060d24"), Color("#08112c")]), 0.5)
	# sun glare behind the HUD (top left), faint below it
	var sun: Vector2 = Vector2(38.0, 5.0)
	for y: int in range(0, 60):
		for x: int in range(0, 110):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(sun)
			if d < 7.0:
				sky.set_pixel(x, y, Color("#fff6dc"))
			elif d < 10.0:
				sky.set_pixel(x, y, Color("#d8d0b0") if Painter.bayer(x, y) < 0.6 else Color("#8a8a80"))
			elif d < 54.0:
				var k: float = 1.0 - (d - 10.0) / 44.0
				if Painter.bayer(x, y) < k * k * 0.55:
					sky.set_pixel(x, y, Color("#1a2236") if d > 26.0 else Color("#2a3048"))
	# a small grey moon, top right
	Painter.disc(sky, 432.0, 50.0, 8.0, Color("#1c2234"))
	Painter.disc(sky, 430.0, 48.5, 6.5, Color("#262e44"))
	Painter.disc(sky, 435.0, 51.0, 6.0, Color("#1c2234"))
	Painter.px(sky, 428, 46, Color("#36405a"))
	Painter.px(sky, 431, 49, Color("#161c2c"))
	# stars
	for i: int in range(170):
		var sx: int = rng.randi_range(0, 479)
		var sy: int = rng.randi_range(20, 150)
		var r: float = rng.randf()
		if r < 0.7:
			Painter.px(sky, sx, sy, Color("#1e2846"))
		elif r < 0.94:
			Painter.px(sky, sx, sy, Color("#3a4670"))
		else:
			Painter.px(sky, sx, sy, Color("#7080b0"))
			Painter.px(sky, sx - 1, sy, Color("#242c4a"))
			Painter.px(sky, sx + 1, sy, Color("#242c4a"))
	return sky


# The station's far superstructure: a long truss with modules, spokes, masts and a docking ring.
static func _paint_ring(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 80
	var img: Image = Painter.new_img(w, h)
	var lights: PackedVector2Array = PackedVector2Array()
	var dark: Color = Color("#0b1222")
	var mid: Color = Color("#111a2e")
	var lit: Color = Color("#1d2a44")
	Painter.rect(img, 0, 46, w, 3, mid)
	Painter.span(img, 0, w - 1, 46, lit)
	for tx: int in range(0, w, 6):
		Painter.line(img, tx, 49, tx + 3, 52, dark)
		Painter.line(img, tx + 3, 52, tx + 6, 49, dark)
	Painter.span(img, 0, w - 1, 52, dark)
	var x: int = 10
	while x < w - 20:
		var kind: int = rng.randi_range(0, 4)
		match kind:
			0:  # cylinder module
				var cw: int = rng.randi_range(30, 56)
				var ch: int = rng.randi_range(10, 16)
				var cy: int = 47 - ch / 2
				Painter.rect(img, x, cy, cw, ch, mid)
				Painter.span(img, x, x + cw - 1, cy, lit)
				Painter.ellipse(img, float(x), float(cy) + float(ch) * 0.5, 3.0, float(ch) * 0.5, dark)
				for wx: int in range(x + 4, x + cw - 3, 5):
					if rng.randf() < 0.5:
						Painter.px(img, wx, cy + ch / 2, Color("#2a2a2c"))
				x += cw + rng.randi_range(8, 22)
			1:  # sphere tank
				var r: float = rng.randf_range(6.0, 10.0)
				Painter.disc(img, float(x) + r, 47.0 - r * 0.4, r, mid)
				Painter.disc(img, float(x) + r - 2.0, 45.0 - r * 0.4, r * 0.6, lit)
				Painter.disc(img, float(x) + r - 1.0, 46.0 - r * 0.4, r * 0.45, mid)
				x += int(r * 2.0) + rng.randi_range(8, 20)
			2:  # spoke tower with a mast light
				var th: int = rng.randi_range(18, 40)
				Painter.rect(img, x, 46 - th, 3, th, mid)
				Painter.vline(img, x, 46 - th, 46, lit)
				Painter.rect(img, x - 3, 46 - th, 9, 3, mid)
				lights.append(Vector2(float(x + 1), float(45 - th)))
				x += rng.randi_range(14, 30)
			3:  # docking ring seen edge-on
				var rr: float = rng.randf_range(12.0, 18.0)
				for a: int in range(48):
					var ang: float = TAU * float(a) / 48.0
					Painter.px(img, x + int(rr + cos(ang) * rr * 0.35), int(47.0 + sin(ang) * rr), lit if sin(ang) < 0.0 else mid)
				lights.append(Vector2(float(x) + rr, 47.0 - rr))
				x += int(rr) + rng.randi_range(16, 30)
			_:  # antenna cluster
				for m: int in range(3):
					var mh: int = rng.randi_range(6, 20)
					Painter.vline(img, x + m * 3, 46 - mh, 46, mid)
				x += rng.randi_range(12, 22)
	out["ring"] = img
	out["ring_lights"] = lights


# The planet surface as a tileable strip whose top row is the horizon: ocean, continents and
# horizontally stretched cloud bands, squashed toward the horizon, hazy near it. Painted in its
# lit colours; the night overlay darkens the right side.
static func _paint_planet(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = PLANET_H
	var img: Image = Painter.new_img(w, h)
	var land: PackedByteArray = Painter.fast_field(w, h, 70.0, 4, 2525)
	var cloud: PackedByteArray = Painter.fast_field(w, h * 2, 46.0, 4, 2526)
	var cities: PackedVector2Array = PackedVector2Array()
	var ocean_a: Color = Color("#040d1c")
	var ocean_b: Color = Color("#06152a")
	var land_a: Color = Color("#09150f")
	var land_b: Color = Color("#0e1d14")
	var desert: Color = Color("#181710")
	var cl_a: Color = Color("#111d2e")
	var cl_b: Color = Color("#19283c")
	var haze: Color = Color("#0d2836")
	for y: int in range(h):
		var t: float = float(y) / float(h - 1)
		var sy: int = int(pow(t, 1.5) * float(h - 1))
		var sy2: int = mini(h * 2 - 1, sy * 2)
		var hz: float = clampf(1.0 - float(y) / 14.0, 0.0, 1.0)
		for x: int in range(w):
			var lv: float = float(land[sy * w + x]) / 255.0
			var cv: float = float(cloud[sy2 * w + x]) / 255.0
			var c: Color = ocean_a if Painter.bayer(x, y) > lv * 1.2 else ocean_b
			if lv > 0.58:
				c = land_b if lv > 0.66 else land_a
				if lv > 0.74 and Painter.bayer(x, y) < 0.6:
					c = desert
			if cv > 0.6:
				c = cl_b if cv > 0.68 else cl_a
			elif cv > 0.55 and Painter.bayer(x, y) < (cv - 0.55) * 14.0:
				c = cl_a
			if hz > 0.0 and Painter.bayer(x, y) < hz:
				c = haze
			img.set_pixel(x, y, c)
	for i: int in range(90):
		var cx: int = rng.randi_range(0, w - 1)
		var cy: int = rng.randi_range(10, h - 40)
		var csy: int = int(pow(float(cy) / float(h - 1), 1.5) * float(h - 1))
		if float(land[csy * w + cx]) / 255.0 > 0.6:
			cities.append(Vector2(float(cx), float(cy)))
	out["planet"] = img
	out["cities"] = cities


# Screen-fixed overlay over the planet's top corners: the sky above the curved horizon (copied
# from the sky so stars line up), a soft atmosphere glow and a thin bright limb, brighter on the
# day side, warm where the terminator meets it.
static func _paint_limb(out: Dictionary, sky: Image) -> void:
	var img: Image = Painter.new_img(480, 44)
	for x: int in range(480):
		var hy: float = horizon_y(float(x))
		var day: float = clampf((300.0 - float(x)) / 240.0, 0.0, 1.0)
		var dusk: float = clampf(1.0 - absf(float(x) - terminator_x(hy)) / 30.0, 0.0, 1.0)
		for ly: int in range(44):
			var y: float = LIMB_Y + float(ly)
			if y < hy - 4.0:
				img.set_pixel(x, ly, sky.get_pixel(x, int(y)))
			elif y < hy - 1.0:
				var base: Color = sky.get_pixel(x, int(y))
				var g: Color = Color("#0c2a3a").lerp(Color("#164a5c"), day)
				img.set_pixel(x, ly, g if Painter.bayer(x, int(y)) < 0.25 + 0.5 * (y - hy + 4.0) / 3.0 else base)
			elif y < hy + 1.0:
				var rim: Color = Color("#1a4a5a").lerp(Color("#3a8c9c"), day)
				if dusk > 0.0:
					rim = rim.lerp(Color("#8a5a3a"), dusk * 0.8)
				img.set_pixel(x, ly, rim)
	out["limb"] = img


# Screen-fixed night-side shading: dithered across the slanted terminator, solid beyond it.
static func _paint_night(out: Dictionary) -> void:
	var img: Image = Painter.new_img(480, PLANET_H)
	var dark: Color = Color(0.008, 0.016, 0.04, 0.78)
	for y: int in range(PLANET_H):
		var tx: float = terminator_x(PLANET_Y + float(y))
		var x0: int = maxi(0, int(tx - 34.0))
		for x: int in range(x0, 480):
			var k: float = (float(x) - (tx - 34.0)) / 68.0
			if k >= 1.0 or Painter.bayer(x, y) < k:
				img.set_pixel(x, y, dark)
	out["night"] = img


# A farther row of the station's masts and panel wings, silhouetted against the planet.
static func _paint_far(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 96
	var img: Image = Painter.new_img(w, h)
	var lights: PackedVector2Array = PackedVector2Array()
	var sil: Color = Color("#080d18")
	var edge: Color = Color("#111a2a")
	var cellc: Color = Color("#0a1426")
	var x: int = 8
	while x < w - 30:
		var top: int = rng.randi_range(6, 50)
		Painter.rect(img, x, top, 2, h - top, sil)
		Painter.vline(img, x, top, h - 1, edge)
		lights.append(Vector2(float(x), float(top - 1)))
		var levels: int = rng.randi_range(1, 3)
		for lv: int in range(levels):
			var py: int = top + 4 + lv * 15
			if py + 9 > h - 6:
				break
			var pw: int = rng.randi_range(16, 30)
			for side: int in [-1, 1]:
				var px0: int = x - pw - 1 if side < 0 else x + 3
				Painter.rect(img, px0, py, pw, 8, sil)
				Painter.rect(img, px0 + 1, py + 1, pw - 2, 6, cellc)
				Painter.span(img, px0, px0 + pw - 1, py, edge)
		if rng.randf() < 0.35:
			var bw: int = rng.randi_range(24, 44)
			Painter.rect(img, x + 8, h - 18, bw, 18, sil)
			Painter.span(img, x + 8, x + 7 + bw, h - 18, edge)
		x += rng.randi_range(46, 80)
	out["far"] = img
	out["far_lights"] = lights


# Solar array towers with paired panel wings, docking arms ending in collars, radiators and
# habitat blocks, all rising from below the hull.
static func _paint_arrays(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = int(ARR_W)
	var h: int = 150
	var img: Image = Painter.new_img(w, h)
	var panels: PackedVector4Array = PackedVector4Array()
	var beacons: PackedVector2Array = PackedVector2Array()
	var mast: Color = Color("#111926")
	var mast_hi: Color = Color("#1e2a3c")
	var frame: Color = Color("#22304a")
	var cell: Color = Color("#0a1830")
	var grid: Color = Color("#122648")
	var x: int = 20
	var n: int = 0
	while x < w - 60:
		var kind: int = n % 3 if rng.randf() < 0.8 else 2
		n += 1
		if kind == 0 or kind == 1:
			# truss mast
			var top: int = rng.randi_range(8, 46)
			Painter.rect(img, x, top, 4, h - top, mast)
			Painter.vline(img, x, top, h - 1, mast_hi)
			for by: int in range(top + 2, h, 6):
				Painter.line(img, x, by, x + 3, by + 3, Color("#0a1018"))
			Painter.rect(img, x - 2, top - 3, 8, 3, mast_hi)
			if kind == 0:
				# solar wings at two or three heights
				var levels: int = rng.randi_range(2, 3)
				for lv: int in range(levels):
					var py: int = top + 6 + lv * 26
					if py + 18 > h - 20:
						break
					var pw: int = rng.randi_range(36, 64)
					var ph: int = rng.randi_range(13, 18)
					for side: int in [-1, 1]:
						var px0: int = x - pw - 3 if side < 0 else x + 7
						Painter.rect(img, px0, py, pw, ph, frame)
						Painter.rect(img, px0 + 1, py + 1, pw - 2, ph - 2, cell)
						for gx: int in range(px0 + 4, px0 + pw - 1, 5):
							Painter.vline(img, gx, py + 1, py + ph - 2, grid)
						Painter.span(img, px0 + 1, px0 + pw - 2, py + ph / 2, grid)
						Painter.span(img, px0, px0 + pw - 1, py, Color("#2e4468"))
						Painter.span(img, px0 + (pw if side < 0 else -4), px0 + (pw + 3 if side < 0 else -1), py + ph / 2, mast_hi)
						panels.append(Vector4(float(px0), float(py), float(pw), float(ph)))
				x += 96 + rng.randi_range(0, 34)
			else:
				# docking arm: a braced girder reaching left to a collar ring
				var ay: int = top + rng.randi_range(10, 30)
				var alen: int = rng.randi_range(56, 90)
				Painter.rect(img, x - alen, ay, alen, 2, mast_hi)
				Painter.rect(img, x - alen, ay + 7, alen, 2, mast)
				for gx2: int in range(x - alen, x, 6):
					Painter.line(img, gx2, ay + 2, gx2 + 3, ay + 6, mast)
					Painter.line(img, gx2 + 3, ay + 6, gx2 + 6, ay + 2, mast)
				var cx: int = x - alen - 6
				Painter.ellipse(img, float(cx), float(ay) + 4.5, 5.0, 10.0, mast_hi)
				Painter.ellipse(img, float(cx), float(ay) + 4.5, 3.0, 7.0, Color("#060a12"))
				Painter.ellipse(img, float(cx) + 1.0, float(ay) + 4.5, 1.5, 5.0, Color("#0e1828"))
				beacons.append(Vector2(float(cx), float(ay) - 6.0))
				beacons.append(Vector2(float(cx), float(ay) + 15.0))
				# a radiator panel hanging off the mast
				for rp: int in range(3):
					Painter.rect(img, x + 6, ay + 20 + rp * 9, 26, 7, Color("#141c28"))
					Painter.span(img, x + 6, x + 31, ay + 20 + rp * 9, Color("#202a3a"))
				x += 84 + rng.randi_range(0, 30)
		else:
			# habitat block with lit ports
			var bw: int = rng.randi_range(40, 70)
			var bh: int = rng.randi_range(24, 44)
			var btop: int = h - bh
			Painter.rect(img, x, btop, bw, bh, Color("#0e1420"))
			Painter.span(img, x, x + bw - 1, btop, mast_hi)
			for wy: int in range(btop + 5, h - 4, 6):
				for wx: int in range(x + 3, x + bw - 3, 5):
					var r: float = rng.randf()
					if r < 0.18:
						Painter.rect(img, wx, wy, 2, 2, Color("#4a3a1c"))
					elif r < 0.5:
						Painter.rect(img, wx, wy, 2, 2, Color("#141c2a"))
			Painter.disc(img, float(x + bw / 2), float(btop) - 3.0, 4.0, Color("#141c28"))
			Painter.span(img, x + bw / 2 - 3, x + bw / 2 + 3, btop - 6, mast_hi)
			x += bw + rng.randi_range(10, 30)
	out["arrays"] = img
	out["panels"] = panels
	out["beacons"] = beacons


# The station hull we skim: plating with seams and rivets, a sunlit top edge, vents, pipes,
# domes and ports, hazard-striped hatches and three turret battery bases (barrels are live).
static func _paint_hull(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 42
	var img: Image = Painter.new_img(w, h)
	var turrets: PackedVector2Array = PackedVector2Array()
	var ports: PackedVector2Array = PackedVector2Array()
	var edge: int = 18
	Painter.rect(img, 0, edge, w, h - edge, Color("#111823"))
	Painter.span(img, 0, w - 1, edge, Color("#3a4a60"))
	Painter.span(img, 0, w - 1, edge + 1, Color("#222e40"))
	Painter.span(img, 0, w - 1, 31, Color("#0a0f18"))
	Painter.span(img, 0, w - 1, 32, Color("#182232"))
	for px0: int in range(0, w, 32):
		Painter.vline(img, px0, edge + 2, h - 1, Color("#0a0f18"))
		Painter.vline(img, px0 + 1, edge + 2, h - 1, Color("#1a2434"))
		Painter.px(img, px0 + 4, edge + 4, Color("#26324a"))
		Painter.px(img, px0 + 27, edge + 4, Color("#26324a"))
		Painter.px(img, px0 + 4, 36, Color("#26324a"))
		Painter.px(img, px0 + 27, 36, Color("#26324a"))
		if rng.randf() < 0.22:
			# hazard-striped hatch
			for hx: int in range(px0 + 6, px0 + 26, 4):
				Painter.rect(img, hx, 24, 2, 5, Color("#5a3c12"))
				Painter.rect(img, hx + 2, 24, 2, 5, Color("#141008"))
		elif rng.randf() < 0.3:
			for wx: int in range(px0 + 6, px0 + 26, 4):
				ports.append(Vector2(float(wx), 26.0))
				Painter.rect(img, wx, 25, 2, 3, Color("#1a2232"))
	# superstructure along the top edge
	var x: int = 0
	while x < w:
		var kind: int = rng.randi_range(0, 4)
		match kind:
			0:  # vent block
				var vw: int = rng.randi_range(10, 18)
				Painter.rect(img, x, edge - 5, vw, 5, Color("#151d2a"))
				Painter.span(img, x, x + vw - 1, edge - 5, Color("#2e3c52"))
				for vx: int in range(x + 2, x + vw - 1, 2):
					Painter.vline(img, vx, edge - 3, edge - 1, Color("#0a0f18"))
				x += vw + rng.randi_range(4, 14)
			1:  # dome
				var r: float = rng.randf_range(3.0, 6.0)
				Painter.ellipse(img, float(x) + r, float(edge), r, r * 0.8, Color("#182030"))
				Painter.ellipse(img, float(x) + r - 1.0, float(edge) - 1.0, r * 0.5, r * 0.4, Color("#2e3c52"))
				x += int(r * 2.0) + rng.randi_range(6, 16)
			2:  # pipe run
				var pl: int = rng.randi_range(20, 40)
				Painter.rect(img, x, edge - 3, pl, 2, Color("#1c2636"))
				Painter.span(img, x, x + pl - 1, edge - 3, Color("#34445c"))
				x += pl + rng.randi_range(2, 10)
			3:  # antenna mast
				var mh: int = rng.randi_range(6, 16)
				Painter.vline(img, x, edge - mh, edge, Color("#1e2838"))
				Painter.span(img, x - 2, x + 2, edge - mh + 2, Color("#1e2838"))
				x += rng.randi_range(8, 18)
			_:
				x += rng.randi_range(6, 20)
	# turret battery bases
	for tb: int in range(3):
		var tx: int = 60 + tb * 256
		Painter.rect(img, tx - 10, edge - 6, 20, 7, Color("#182232"))
		Painter.span(img, tx - 10, tx + 9, edge - 6, Color("#3a4a60"))
		Painter.ellipse(img, float(tx), float(edge - 7), 7.0, 4.0, Color("#202c3e"))
		Painter.ellipse(img, float(tx) - 2.0, float(edge - 8), 3.0, 1.5, Color("#3e5068"))
		for hx2: int in range(tx - 9, tx + 9, 4):
			Painter.rect(img, hx2, edge - 2, 2, 2, Color("#5a3c12"))
		turrets.append(Vector2(float(tx), float(edge - 8)))
	out["hull"] = img
	out["turrets"] = turrets
	out["ports"] = ports


static func _paint_shuttle(out: Dictionary) -> void:
	var img: Image = Painter.new_img(30, 12)
	Painter.poly(img, PackedVector2Array([Vector2(0, 6), Vector2(6, 3), Vector2(24, 3), Vector2(28, 5), Vector2(28, 8), Vector2(24, 10), Vector2(6, 9)]), Color("#2a3446"))
	Painter.span(img, 6, 23, 3, Color("#4a586e"))
	Painter.poly(img, PackedVector2Array([Vector2(14, 3), Vector2(20, 0), Vector2(24, 0), Vector2(22, 3)]), Color("#222a3a"))
	Painter.poly(img, PackedVector2Array([Vector2(14, 9), Vector2(22, 9), Vector2(24, 12), Vector2(20, 12)]), Color("#222a3a"))
	Painter.rect(img, 3, 5, 3, 1, Color("#3a5a80"))
	Painter.rect(img, 8, 5, 12, 1, Color("#1a2232"))
	Painter.rect(img, 28, 5, 2, 3, Color("#141a26"))
	out["shuttle"] = img


# --- animation ----------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 30.0
	drift_a.y1 = 250.0
	drift_a.setup(26, rng, -7.0, -2.0, -1.5, 1.5)
	drift_a.par = 0.18
	drift_a.cols = PackedColorArray([Color(0.4, 0.5, 0.7, 0.3), Color(0.55, 0.65, 0.85, 0.22)])
	_ev_wait_a = rng.randf_range(6.0, 12.0)
	_ev_wait_b = rng.randf_range(4.0, 9.0)
	_ev_wait_c = rng.randf_range(9.0, 15.0)
	_shuttle_t = -1.0
	_search_t = -1.0
	_gun_t = -1.0
	_puffs = PackedVector3Array()
	_turret_cd = PackedFloat32Array([1.0, 2.4, 3.6])
	_flash = PackedFloat32Array([0.0, 0.0, 0.0])


func update() -> void:
	if _shuttle_t < 0.0:
		_ev_wait_a -= dl
		if _ev_wait_a <= 0.0:
			_shuttle_t = 0.0
			_shuttle_y0 = rng.randf_range(52.0, 84.0)
			_shuttle_y1 = _shuttle_y0 + rng.randf_range(10.0, 40.0)
	else:
		_shuttle_t += dl
		if _shuttle_t > SHUTTLE_TIME:
			_shuttle_t = -1.0
			_ev_wait_a = rng.randf_range(18.0, 28.0)
	if _search_t < 0.0:
		_ev_wait_b -= dl
		if _ev_wait_b <= 0.0:
			_search_t = 0.0
	else:
		_search_t += dl
		if _search_t > SEARCH_TIME:
			_search_t = -1.0
			_ev_wait_b = rng.randf_range(12.0, 20.0)
	if _gun_t < 0.0:
		_ev_wait_c -= dl
		if _ev_wait_c <= 0.0:
			_gun_t = 0.0
			_gun_from = Vector2(rng.randf_range(300.0, 440.0), rng.randf_range(52.0, 66.0))
	else:
		_gun_t += dl
		if _gun_t > GUN_TIME:
			_gun_t = -1.0
			_ev_wait_c = rng.randf_range(14.0, 24.0)
	# hull turrets: track a far-off target and fire flak at it now and then
	var turrets: PackedVector2Array = meta.get("turrets", PackedVector2Array())
	var o_h: float = off(HULL_F, 768.0)
	for i: int in range(mini(turrets.size(), _turret_cd.size())):
		_flash[i] = maxf(0.0, _flash[i] - dl)
		_turret_cd[i] -= dl
		if _turret_cd[i] <= 0.0:
			_turret_cd[i] = rng.randf_range(2.5, 5.0)
			var tx: float = wrap_x(turrets[i].x, o_h, 768.0)
			if tx > 10.0 and tx < 470.0:
				_flash[i] = 0.09
				var d: Vector2 = Vector2.from_angle(_turret_angle(i))
				var p0: Vector2 = Vector2(tx, HULL_Y + turrets[i].y)
				for k: int in range(2):
					var far: Vector2 = p0 + d * rng.randf_range(130.0, 175.0) + Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-8.0, 8.0))
					if far.y > 34.0:
						_puffs.append(Vector3(far.x, far.y, -0.45 - 0.12 * float(k)))
	var keep: PackedVector3Array = PackedVector3Array()
	for p: Vector3 in _puffs:
		var a: float = p.z + dl
		if a < 1.1:
			keep.append(Vector3(p.x - ds * RING_F, p.y, a))
	_puffs = keep


func _turret_angle(i: int) -> float:
	return -PI * 0.5 - 0.35 + sin(life * 0.31 + float(i) * 2.1) * 0.55


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	layer("ring", RING_Y, RING_F)
	var o_r: float = off(RING_F, 768.0)
	var lights: PackedVector2Array = meta.get("ring_lights", PackedVector2Array())
	for i: int in range(lights.size()):
		var lx: float = wrap_x(lights[i].x, o_r, 768.0)
		if lx < 0.0 or lx > 480.0:
			continue
		if fposmod(life * 0.7 + float(i) * 0.41, 1.0) < 0.35:
			bg.draw_rect(Rect2(floorf(lx), RING_Y + lights[i].y, 1.0, 1.0), Color("#ff4a3a") if i % 3 != 0 else Color("#d8e4ff"))
	_draw_gun_event()
	layer_rows("planet", PLANET_Y, 4, PLANET_FT, PLANET_FB)
	bg.draw_texture(tex("night"), Vector2(0.0, PLANET_Y))
	_draw_cities()
	bg.draw_texture(tex("limb"), Vector2(0.0, LIMB_Y))
	_draw_puffs()
	layer("far", FAR_Y, FAR_F)
	var o_f: float = off(FAR_F, 768.0)
	var flights: PackedVector2Array = meta.get("far_lights", PackedVector2Array())
	for fl: int in range(flights.size()):
		var fx: float = wrap_x(flights[fl].x, o_f, 768.0)
		if fx < 0.0 or fx > 480.0:
			continue
		if fposmod(life * 0.55 + float(fl) * 0.29, 1.0) < 0.3:
			bg.draw_rect(Rect2(floorf(fx), FAR_Y + flights[fl].y, 1.0, 1.0), Color(1.0, 0.3, 0.25, 0.7))
	layer("arrays", ARR_Y, ARR_F)
	_draw_array_lights()
	_draw_drones()
	_draw_shuttle()
	_draw_searchlights()
	layer("hull", HULL_Y, HULL_F)
	_draw_hull_live()
	drift_draw(drift_a)


func _draw_cities() -> void:
	var cities: PackedVector2Array = meta.get("cities", PackedVector2Array())
	for i: int in range(cities.size()):
		var cy: float = cities[i].y
		var band_t: float = float((int(cy) / 4) * 4) / float(PLANET_H - 1)
		var f: float = lerpf(PLANET_FT, PLANET_FB, band_t)
		var sx: float = wrap_x(cities[i].x, off(f, 768.0), 768.0)
		var sy: float = PLANET_Y + cy
		if sx < 0.0 or sx > 479.0 or sx < terminator_x(sy) + 8.0 or sy < horizon_y(sx) + 2.0:
			continue
		var tw: float = 0.55 + 0.45 * sin(life * (1.5 + float(i % 5) * 0.4) + float(i))
		bg.draw_rect(Rect2(floorf(sx), sy, 1.0, 1.0), Color(1.0, 0.82, 0.5, 0.35 + 0.35 * tw))
		if i % 4 == 0:
			bg.draw_rect(Rect2(floorf(sx) + 1.0, sy, 1.0, 1.0), Color(1.0, 0.7, 0.4, 0.3 * tw))


func _draw_puffs() -> void:
	for p: Vector3 in _puffs:
		if p.z < 0.0:
			continue
		var k: float = p.z / 1.1
		var r: float = floorf(1.0 + k * 5.0)
		var a: float = 0.32 * (1.0 - k)
		var x: float = floorf(p.x)
		var y: float = floorf(p.y)
		if p.z < 0.07:
			bg.draw_rect(Rect2(x - 1.0, y - 1.0, 2.0, 2.0), Color(1.0, 0.85, 0.55, 0.45))
		bg.draw_rect(Rect2(x - r, y - floorf(r * 0.7), r * 2.0, floorf(r * 1.4) + 1.0), Color(0.36, 0.38, 0.44, a))
		bg.draw_rect(Rect2(x - r + 2.0, y - floorf(r * 0.7) - 1.0, maxf(1.0, r * 2.0 - 4.0), 1.0), Color(0.42, 0.44, 0.5, a * 0.8))


func _draw_array_lights() -> void:
	var o_a: float = off(ARR_F, ARR_W)
	var panels: PackedVector4Array = meta.get("panels", PackedVector4Array())
	var glint_x: float = fposmod(life * 70.0, 760.0) - 140.0
	for i: int in range(panels.size()):
		var pr: Vector4 = panels[i]
		var px0: float = wrap_x(pr.x, o_a, ARR_W)
		if px0 + pr.z < 0.0 or px0 > 480.0:
			continue
		var py: float = ARR_Y + pr.y
		# the sun glint: a slanted band sweeping across the cells
		var gx: float = glint_x - (py - 100.0) * 0.6
		if gx > px0 - 4.0 and gx < px0 + pr.z + 4.0:
			var x0: float = maxf(px0 + 1.0, floorf(gx) - 3.0)
			var x1: float = minf(px0 + pr.z - 1.0, floorf(gx) + 4.0)
			if x1 > x0:
				bg.draw_rect(Rect2(x0, py + 1.0, x1 - x0, pr.w - 2.0), Color(0.45, 0.65, 1.0, 0.12))
			var x2: float = clampf(floorf(gx), px0 + 1.0, px0 + pr.z - 2.0)
			bg.draw_rect(Rect2(x2, py + 1.0, 1.0, pr.w - 2.0), Color(0.75, 0.88, 1.0, 0.32))
	var beacons: PackedVector2Array = meta.get("beacons", PackedVector2Array())
	for j: int in range(beacons.size()):
		var bx: float = wrap_x(beacons[j].x, o_a, ARR_W)
		if bx < 0.0 or bx > 480.0:
			continue
		var on: bool = fposmod(life * 1.1 + float(j / 2) * 0.37 + (0.5 if j % 2 == 1 else 0.0), 1.0) < 0.22
		var col: Color = Color("#ff3a2a") if j % 2 == 0 else Color("#e0ecff")
		bg.draw_rect(Rect2(floorf(bx), ARR_Y + beacons[j].y, 1.0, 1.0), col if on else Color(col.r, col.g, col.b, 0.25))
		if on:
			bg.draw_rect(Rect2(floorf(bx) - 1.0, ARR_Y + beacons[j].y - 1.0, 3.0, 3.0), Color(col.r, col.g, col.b, 0.18))


func _draw_drones() -> void:
	for i: int in range(4):
		var t: float = life * (0.05 + 0.012 * float(i)) + float(i) * 0.31
		var x: float = 500.0 - fposmod(t * 620.0, 560.0)
		var hop: float = floorf(fposmod(life * 0.6 + float(i) * 0.7, 3.0))
		var y: float = 118.0 + float(i) * 22.0 + sin(life * 0.9 + float(i) * 2.0) * 6.0 + hop * 4.0
		bg.draw_rect(Rect2(floorf(x), floorf(y), 3.0, 2.0), Color("#2c3648"))
		bg.draw_rect(Rect2(floorf(x), floorf(y), 3.0, 1.0), Color("#46546a"))
		if fposmod(life * 2.0 + float(i) * 0.5, 1.0) < 0.3:
			bg.draw_rect(Rect2(floorf(x) + 3.0, floorf(y) + 1.0, 1.0, 1.0), Color("#40ff90") if i % 2 == 0 else Color("#ffb040"))


func _draw_shuttle() -> void:
	if _shuttle_t < 0.0:
		return
	var k: float = _shuttle_t / SHUTTLE_TIME
	var x: float = lerpf(500.0, -40.0, k)
	var y: float = lerpf(_shuttle_y0, _shuttle_y1, k * k)
	var p: Vector2 = Vector2(floorf(x), floorf(y))
	bg.draw_texture(tex("shuttle"), p, Color(0.85, 0.85, 0.9, 0.9))
	var fl: float = 0.5 + 0.5 * sin(life * 30.0)
	bg.draw_rect(Rect2(p.x + 30.0, p.y + 5.0, 2.0 + floorf(fl * 2.0), 2.0), Color(0.5, 0.9, 1.0, 0.55))
	if fposmod(life, 1.0) < 0.15:
		bg.draw_rect(Rect2(p.x + 20.0, p.y + 11.0, 1.0, 1.0), Color("#ff3a2a"))
		bg.draw_rect(Rect2(p.x + 20.0, p.y, 1.0, 1.0), Color("#40ff90"))


func _draw_searchlights() -> void:
	if _search_t < 0.0:
		return
	var a: float = sin(_search_t / SEARCH_TIME * PI)
	var turrets: PackedVector2Array = meta.get("turrets", PackedVector2Array())
	var o_h: float = off(HULL_F, 768.0)
	for i: int in range(turrets.size()):
		var tx: float = wrap_x(turrets[i].x, o_h, 768.0)
		if tx < -60.0 or tx > 540.0:
			continue
		var base: Vector2 = Vector2(tx, HULL_Y + turrets[i].y + 2.0)
		var ang: float = -PI * 0.5 + sin(_search_t * 0.8 + float(i) * 1.9) * 0.7
		var d: Vector2 = Vector2.from_angle(ang)
		var nrm: Vector2 = d.orthogonal() * 16.0
		bg.draw_colored_polygon(PackedVector2Array([base, base + d * 200.0 + nrm, base + d * 200.0 - nrm]), Color(0.75, 0.85, 1.0, 0.06 * a))
		bg.draw_colored_polygon(PackedVector2Array([base, base + d * 200.0 + nrm * 0.4, base + d * 200.0 - nrm * 0.4]), Color(0.85, 0.92, 1.0, 0.05 * a))


func _draw_gun_event() -> void:
	if _gun_t < 0.0:
		return
	var to: Vector2 = Vector2(6.0, 24.0)
	if _gun_t < 0.3:
		var k: float = 1.0 - _gun_t / 0.3
		bg.draw_circle(_gun_from, 3.0 + 6.0 * (1.0 - k), Color(0.8, 0.9, 1.0, 0.22 * k))
		bg.draw_line(_gun_from, to, Color(0.6, 0.85, 1.0, 0.4 * k), 1.0)
		bg.draw_line(_gun_from + Vector2(0.0, 1.0), to + Vector2(0.0, 1.0), Color(0.4, 0.6, 1.0, 0.15 * k), 1.0)
	if _gun_t > 0.45:
		var k2: float = clampf((_gun_t - 0.45) / (GUN_TIME - 0.45), 0.0, 1.0)
		bg.draw_circle(to + Vector2(8.0, 6.0), 2.0 + 10.0 * k2, Color(1.0, 0.6, 0.3, 0.2 * (1.0 - k2)))
		bg.draw_circle(to + Vector2(8.0, 6.0), 1.0 + 4.0 * k2, Color(1.0, 0.85, 0.6, 0.25 * (1.0 - k2)))


func _draw_hull_live() -> void:
	var o_h: float = off(HULL_F, 768.0)
	var turrets: PackedVector2Array = meta.get("turrets", PackedVector2Array())
	for i: int in range(turrets.size()):
		var tx: float = wrap_x(turrets[i].x, o_h, 768.0)
		if tx < -20.0 or tx > 500.0:
			continue
		var piv: Vector2 = Vector2(floorf(tx) + 0.5, HULL_Y + turrets[i].y + 0.5)
		var d: Vector2 = Vector2.from_angle(_turret_angle(i))
		bg.draw_line(piv, piv + d * 10.0, Color("#0c121c"), 3.0)
		bg.draw_line(piv, piv + d * 10.0, Color("#4a5a72"), 1.0)
		if i < _flash.size() and _flash[i] > 0.0:
			bg.draw_rect(Rect2(floorf(piv.x + d.x * 12.0) - 1.0, floorf(piv.y + d.y * 12.0) - 1.0, 3.0, 3.0), Color(1.0, 0.85, 0.5, 0.8))
	# running lights chasing along the hull edge
	var chase: int = int(life * 6.0)
	var lx: float = -fposmod(scroll * HULL_F, 24.0)
	var li: int = int(floorf(scroll * HULL_F / 24.0))
	while lx < 480.0:
		var on: bool = posmod(chase - li, 8) == 0
		bg.draw_rect(Rect2(floorf(lx) + 6.0, HULL_Y + 19.0, 2.0, 1.0), Color(1.0, 0.65, 0.2, 0.9 if on else 0.25))
		lx += 24.0
		li += 1
	var ports: PackedVector2Array = meta.get("ports", PackedVector2Array())
	for p: int in range(ports.size()):
		var px0: float = wrap_x(ports[p].x, o_h, 768.0)
		if px0 < 0.0 or px0 > 480.0:
			continue
		var lit: bool = (p * 7 + int(life * 0.25)) % 5 != 0
		if lit:
			bg.draw_rect(Rect2(floorf(px0), HULL_Y + ports[p].y, 2.0, 2.0), Color(0.95, 0.75, 0.4, 0.55))
