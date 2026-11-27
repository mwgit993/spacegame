extends "res://scripts/stages/stage_background.gd"

# STAGE 16 background: a megacity at midnight, in the rain. Storm clouds lit pink from below
# and a moon breaking through; megatowers on the horizon with blinking aircraft lights; closer
# towers carrying giant animated billboards and neon signs; sky-lanes of flying traffic
# (white headlights one way, red taillights the other); wet rooftops with water towers and
# neon below; rain over everything. Rare events: lightning, an advertising blimp with a
# scrolling ticker, and searchlights sweeping the clouds.
#
# Layers: "sky" 480x270; "far" 768x130 at y 96 (0.05); "mid" 896x180 at y 66 (0.2);
# "near" 768x64 at y 206 (0.75); "ads" 4 ads x 2 frames of 38x24; "blimp" 124x36.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const FAR_Y: float = 96.0
const FAR_F: float = 0.05
const MID_Y: float = 66.0
const MID_F: float = 0.2
const NEAR_Y: float = 206.0
const NEAR_F: float = 0.75
const RAIN_N: int = 70
const AD_W: float = 38.0
const AD_H: float = 24.0

const NEON: Array[Color] = [Color("#ff3c9c"), Color("#30f0e0"), Color("#ffb040"), Color("#b060ff")]

var _bolt: PackedVector2Array = PackedVector2Array()
var _flash_t: float = -1.0
var _flash_wait: float = 6.0
var _blimp_x: float = -999.0
var _blimp_wait: float = 5.0
var _sl_t: float = -1.0
var _sl_wait: float = 3.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1616
	var out: Dictionary = {}

	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#06051a"))
	Painter.vgrad(sky, 22, 230, PackedColorArray([Color("#06051a"), Color("#090722"), Color("#0e0a2a"), Color("#160c32"), Color("#221038"), Color("#32143e"), Color("#46183e")]), 0.55)
	# a moon breaking through the clouds
	var moon: Vector2 = Vector2(92.0, 50.0)
	for y: int in range(24, 82):
		for x: int in range(56, 130):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(moon)
			if d < 10.0:
				sky.set_pixel(x, y, Color("#d8d0ee") if d < 8.5 or Painter.bayer(x, y) < 0.5 else Color("#9890b8"))
			elif d < 26.0 and Painter.bayer(x, y) < (1.0 - (d - 10.0) / 16.0) * 0.45:
				sky.set_pixel(x, y, Color("#2a2450"))
	Painter.px(sky, 89, 47, Color("#b0a8d0"))
	Painter.px(sky, 95, 53, Color("#b0a8d0"))
	# storm clouds, lit pink-orange from the city underneath
	var n: PackedByteArray = Painter.fast_field(480, 120, 110.0, 3, 1616)
	for y2: int in range(22, 140):
		var fade: float = 1.0 - absf(float(y2) - 70.0) / 70.0
		for x2: int in range(480):
			var v: float = float(n[(y2 - 22) * 480 + x2]) / 255.0 * (0.6 + 0.4 * fade)
			if v < 0.36:
				continue
			var b2: float = float(n[mini(119, y2 - 22 + 2) * 480 + x2]) / 255.0 * (0.6 + 0.4 * fade)
			var b5: float = float(n[mini(119, y2 - 22 + 5) * 480 + x2]) / 255.0 * (0.6 + 0.4 * fade)
			var c: Color = Color("#120a26")
			if b2 < 0.36:
				c = Color("#44183e") if Painter.bayer(x2, y2) < 0.7 else Color("#2c1240")
			elif b5 < 0.36:
				c = Color("#26103a") if Painter.bayer(x2, y2) < 0.5 else Color("#1a0c30")
			elif v > 0.5:
				c = Color("#0c0720")
			sky.set_pixel(x2, y2, c)
	out["sky"] = sky

	_paint_far(out, rng)
	_paint_mid(out, rng)
	_paint_near(out, rng)
	_paint_ads(out)
	_paint_blimp(out)
	return out


static func _paint_far(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 130
	var img: Image = Painter.new_img(w, h)
	var lights: PackedVector2Array = PackedVector2Array()
	var x: int = 0
	while x < w:
		var tw: int = rng.randi_range(12, 32)
		var th: int = rng.randi_range(40, 124)
		var top: int = h - th
		Painter.rect(img, x, top, tw, th, Color("#0c0a1e"))
		Painter.vline(img, x, top, h - 1, Color("#18142e"))
		# setback crown
		if rng.randf() < 0.5:
			Painter.rect(img, x + 3, top - 6, tw - 6, 6, Color("#0c0a1e"))
			Painter.span(img, x + 3, x + tw - 4, top - 6, Color("#1c1838"))
		Painter.span(img, x, x + tw - 1, top, Color("#1c1838"))
		for wy: int in range(top + 3, h - 2, 3):
			for wx: int in range(x + 2, x + tw - 2, 2):
				var r: float = rng.randf()
				if r < 0.3:
					Painter.px(img, wx, wy, Color("#241c46"))
				elif r < 0.36:
					Painter.px(img, wx, wy, Color("#6a4a22"))
				elif r < 0.38:
					Painter.px(img, wx, wy, Color("#1e5250"))
		if rng.randf() < 0.25:
			Painter.vline(img, x + tw / 2, top + 4, h - 1, Color("#4a1640") if rng.randf() < 0.5 else Color("#14484a"))
		if rng.randf() < 0.55:
			var sl: int = rng.randi_range(6, 18)
			Painter.vline(img, x + tw / 2, top - sl, top, Color("#18142e"))
			lights.append(Vector2(float(x + tw / 2), float(top - sl)))
		x += tw + rng.randi_range(0, 6)
	out["far"] = img
	out["far_lights"] = lights


static func _paint_mid(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 896
	var h: int = 180
	var img: Image = Painter.new_img(w, h)
	var boards: PackedVector3Array = PackedVector3Array()
	var signs: PackedVector4Array = PackedVector4Array()
	var xs: Array[int] = [20, 170, 330, 470, 640, 780]
	for i: int in range(xs.size()):
		var tx: int = xs[i] + rng.randi_range(-20, 20)
		var tw: int = rng.randi_range(44, 70)
		var top: int = rng.randi_range(10, 70)
		Painter.rect(img, tx, top, tw, h - top, Color("#08061a"))
		Painter.vline(img, tx, top, h - 1, Color("#221c42"))
		Painter.vline(img, tx + 1, top, h - 1, Color("#140f2c"))
		Painter.span(img, tx, tx + tw - 1, top, Color("#2a2250"))
		for wy: int in range(top + 5, h, 6):
			for wx: int in range(tx + 4, tx + tw - 3, 4):
				var r: float = rng.randf()
				if r < 0.12:
					Painter.rect(img, wx, wy, 2, 2, Color("#5a4020"))
				elif r < 0.3:
					Painter.rect(img, wx, wy, 2, 2, Color("#16122e"))
		# a billboard frame on this tower (the ad is drawn live)
		var bx: int = tx + (tw - 42) / 2
		var by: int = top + rng.randi_range(12, 40)
		Painter.rect(img, bx, by, 42, 28, Color("#1a1830"))
		Painter.span(img, bx, bx + 41, by, Color("#3a3660"))
		Painter.rect(img, bx + 2, by + 2, 38, 24, Color("#04030a"))
		Painter.vline(img, bx + 8, by + 28, by + 40, Color("#141228"))
		Painter.vline(img, bx + 33, by + 28, by + 40, Color("#141228"))
		boards.append(Vector3(float(bx + 2), float(by + 2), float(i % 4)))
		# a vertical neon sign
		if i % 2 == 0:
			var sx: int = tx + tw - 9
			var sy: int = by + 46
			Painter.rect(img, sx, sy, 7, 34, Color("#0e0a1e"))
			signs.append(Vector4(float(sx + 1), float(sy + 1), 5.0, float(i % 4)))
	out["mid"] = img
	out["boards"] = boards
	out["signs"] = signs


static func _paint_near(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 64
	var img: Image = Painter.new_img(w, h)
	var signs: PackedVector4Array = PackedVector4Array()
	var x: int = 0
	while x < w:
		var rw: int = rng.randi_range(40, 90)
		var top: int = rng.randi_range(16, 34)
		Painter.rect(img, x, top, rw, h - top, Color("#07051a"))
		Painter.span(img, x, x + rw - 1, top, Color("#2a2048"))
		Painter.span(img, x, x + rw - 1, top + 1, Color("#151030"))
		# railing
		for rx: int in range(x, x + rw, 3):
			Painter.px(img, rx, top - 2, Color("#1a1430"))
		Painter.span(img, x, x + rw - 1, top - 3, Color("#1a1430"))
		# rooftop clutter: water tower, AC units, antennas
		var kind: int = rng.randi_range(0, 2)
		var cx: int = x + rng.randi_range(8, maxi(9, rw - 20))
		if kind == 0:
			Painter.rect(img, cx, top - 16, 12, 10, Color("#0c0920"))
			Painter.span(img, cx, cx + 11, top - 16, Color("#2a2048"))
			Painter.ellipse(img, float(cx) + 6.0, float(top - 17), 6.0, 2.0, Color("#0c0920"))
			Painter.vline(img, cx + 1, top - 6, top, Color("#151030"))
			Painter.vline(img, cx + 10, top - 6, top, Color("#151030"))
		elif kind == 1:
			Painter.rect(img, cx, top - 5, 9, 5, Color("#0e0b22"))
			Painter.span(img, cx, cx + 8, top - 5, Color("#262044"))
			Painter.rect(img, cx + 12, top - 4, 6, 4, Color("#0e0b22"))
		else:
			Painter.vline(img, cx, top - 18, top, Color("#1a1430"))
			Painter.span(img, cx - 3, cx + 3, top - 14, Color("#1a1430"))
		# a neon sign on the roof edge
		if rng.randf() < 0.6:
			var sw: int = rng.randi_range(14, 26)
			var sx: int = x + rng.randi_range(2, maxi(3, rw - sw - 2))
			Painter.rect(img, sx - 1, top + 4, sw + 2, 7, Color("#0e0a1e"))
			signs.append(Vector4(float(sx), float(top + 5), float(sw), float(rng.randi_range(0, 3))))
		# lit windows on the facade below
		for wy: int in range(top + 14, h, 7):
			for wx: int in range(x + 4, x + rw - 4, 6):
				if rng.randf() < 0.2:
					Painter.rect(img, wx, wy, 3, 3, Color("#4a3418"))
		x += rw + rng.randi_range(0, 10)
	out["near"] = img
	out["near_signs"] = signs


# Four ads, two frames each, 38x24 per frame: ad i frame f sits at (i * 40, f * 24).
static func _paint_ads(out: Dictionary) -> void:
	var img: Image = Painter.new_img(160, 48)
	for i: int in range(4):
		for f: int in range(2):
			var ox: int = i * 40
			var oy: int = f * 24
			Painter.rect(img, ox, oy, 38, 24, Color("#0a0618"))
			match i:
				0:  # noodle bowl with rising steam
					Painter.ellipse(img, float(ox) + 19.0, float(oy) + 16.0, 11.0, 5.0, Color("#ff3c9c"))
					Painter.rect(img, ox + 8, oy + 11, 23, 5, Color("#0a0618"))
					Painter.ellipse(img, float(ox) + 19.0, float(oy) + 12.0, 11.0, 2.0, Color("#ffb040"))
					for s: int in range(3):
						var sx: int = ox + 13 + s * 6
						for sy: int in range(4):
							Painter.px(img, sx + (1 if (sy + f + s) % 2 == 0 else 0), oy + 3 + sy * 2, Color("#c8c0e8"))
				1:  # a face in profile
					Painter.disc(img, float(ox) + 18.0, float(oy) + 12.0, 8.0, Color("#30f0e0") if f == 0 else Color("#20b0a8"))
					Painter.rect(img, ox + 22, oy + 4, 8, 16, Color("#0a0618"))
					Painter.px(img, ox + 14, oy + 10, Color("#0a0618"))
					Painter.rect(img, ox + 26, oy + 6, 8, 2, Color("#ff3c9c"))
					Painter.rect(img, ox + 26, oy + 10, 6, 2, Color("#ff3c9c"))
					Painter.rect(img, ox + 26, oy + 14, 7, 2, Color("#ff3c9c"))
				2:  # glyph columns
					for c: int in range(4):
						for r: int in range(3):
							if (c + r + f) % 3 == 0:
								continue
							Painter.rect(img, ox + 4 + c * 8, oy + 3 + r * 7, 5, 1, Color("#ffb040"))
							Painter.rect(img, ox + 6 + c * 8, oy + 3 + r * 7, 1, 5, Color("#ffb040"))
				_:  # a sports car with speed lines
					Painter.rect(img, ox + 8, oy + 12, 22, 5, Color("#ff3c9c"))
					Painter.rect(img, ox + 13, oy + 8, 11, 4, Color("#ff3c9c"))
					Painter.rect(img, ox + 15, oy + 9, 7, 2, Color("#30f0e0"))
					Painter.disc(img, float(ox) + 12.0, float(oy) + 17.0, 2.0, Color("#c8c0e8"))
					Painter.disc(img, float(ox) + 26.0, float(oy) + 17.0, 2.0, Color("#c8c0e8"))
					for l: int in range(3):
						Painter.span(img, ox + 1 + f * 2, ox + 6 + f * 2, oy + 9 + l * 3, Color("#b060ff"))
			# scanlines
			for y: int in range(oy + 1, oy + 24, 2):
				for x: int in range(ox, ox + 38):
					var col: Color = img.get_pixel(x, y)
					img.set_pixel(x, y, col.darkened(0.3))
	out["ads"] = img


static func _paint_blimp(out: Dictionary) -> void:
	var img: Image = Painter.new_img(124, 36)
	Painter.ellipse(img, 62.0, 16.0, 58.0, 14.0, Color("#16142a"))
	Painter.ellipse(img, 58.0, 12.0, 46.0, 7.0, Color("#22203c"))
	Painter.rect(img, 22, 12, 80, 8, Color("#04030a"))
	Painter.poly(img, PackedVector2Array([Vector2(112, 8), Vector2(124, 2), Vector2(122, 16)]), Color("#16142a"))
	Painter.poly(img, PackedVector2Array([Vector2(112, 22), Vector2(124, 30), Vector2(122, 16)]), Color("#16142a"))
	Painter.rect(img, 54, 29, 16, 5, Color("#100e22"))
	Painter.px(img, 56, 31, Color("#ffb040"))
	Painter.px(img, 60, 31, Color("#ffb040"))
	out["blimp"] = img


# --- animation ----------------------------------------------------------------------------------

func reset() -> void:
	_flash_t = -1.0
	_flash_wait = rng.randf_range(4.0, 8.0)
	_blimp_x = -999.0
	_blimp_wait = rng.randf_range(3.0, 8.0)
	_sl_t = -1.0
	_sl_wait = rng.randf_range(1.0, 4.0)


func update() -> void:
	if _flash_t < 0.0:
		_flash_wait -= dl
		if _flash_wait <= 0.0:
			_flash_t = 0.0
			_bolt.clear()
			var x: float = rng.randf_range(160.0, 460.0)
			var y: float = 24.0
			_bolt.append(Vector2(x, y))
			while y < 110.0:
				y += rng.randf_range(6.0, 12.0)
				x += rng.randf_range(-9.0, 9.0)
				_bolt.append(Vector2(x, y))
	else:
		_flash_t += dl
		if _flash_t > 0.55:
			_flash_t = -1.0
			_flash_wait = rng.randf_range(9.0, 16.0)
	if _blimp_x < -500.0:
		_blimp_wait -= dl
		if _blimp_wait <= 0.0:
			_blimp_x = 490.0
	else:
		_blimp_x -= 12.0 * dl
		if _blimp_x < -130.0:
			_blimp_x = -999.0
			_blimp_wait = rng.randf_range(20.0, 30.0)
	if _sl_t < 0.0:
		_sl_wait -= dl
		if _sl_wait <= 0.0:
			_sl_t = 0.0
	else:
		_sl_t += dl
		if _sl_t > 7.0:
			_sl_t = -1.0
			_sl_wait = rng.randf_range(10.0, 16.0)


func _flicker(i: int, rate: float) -> bool:
	var h: int = (int(life * rate) * 7 + i * 31) % 29
	return h != 3 and h != 11


func _traffic(lane_y: float, count: int, speed: float, size: float, seed_v: float, alpha: float) -> void:
	for i: int in range(count):
		var dir: float = 1.0 if i % 2 == 0 else -1.0
		var x: float = fposmod(float(i) * 97.0 + seed_v + life * speed * dir, 560.0) - 40.0
		var y: float = lane_y + float(i % 3) * 3.0 - (2.0 if dir > 0.0 else -1.0)
		if dir < 0.0:
			bg.draw_rect(Rect2(floorf(x), y, size, 1.0), Color(1.0, 0.97, 0.85, alpha))
			bg.draw_rect(Rect2(floorf(x) + size, y, size * 2.0, 1.0), Color(0.2, 0.18, 0.35, alpha))
		else:
			bg.draw_rect(Rect2(floorf(x), y, size * 2.0, 1.0), Color(0.2, 0.18, 0.35, alpha))
			bg.draw_rect(Rect2(floorf(x) + size * 2.0, y, size, 1.0), Color(1.0, 0.2, 0.25, alpha))


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	if _flash_t >= 0.0:
		var f: float = 1.0 if (_flash_t < 0.08 or (_flash_t > 0.18 and _flash_t < 0.26)) else 0.0
		if f > 0.0:
			bg.draw_rect(Rect2(0.0, 22.0, 480.0, 120.0), Color(0.65, 0.55, 1.0, 0.22))
			bg.draw_polyline(_bolt, Color(0.95, 0.9, 1.0, 0.9), 1.0)
		elif _flash_t < 0.4:
			bg.draw_polyline(_bolt, Color(0.6, 0.5, 1.0, 0.25), 1.0)
	if _sl_t >= 0.0:
		var a: float = sin(_sl_t / 7.0 * PI)
		for s: int in range(2):
			var base: Vector2 = Vector2(150.0 + float(s) * 210.0, 200.0)
			var ang: float = -PI * 0.5 + sin(life * 0.5 + float(s) * 2.0) * 0.5
			var d: Vector2 = Vector2.from_angle(ang)
			var nrm: Vector2 = d.orthogonal() * 14.0
			bg.draw_colored_polygon(PackedVector2Array([base, base + d * 190.0 + nrm, base + d * 190.0 - nrm]), Color(0.75, 0.7, 1.0, 0.07 * a))
	if _blimp_x > -500.0:
		var by: float = 34.0 + floorf(sin(life * 0.5) * 2.0)
		bg.draw_texture(tex("blimp"), Vector2(floorf(_blimp_x), by))
		# scrolling ticker on its side
		for t: int in range(10):
			var tx: float = fposmod(float(t) * 8.0 - life * 22.0, 80.0)
			bg.draw_rect(Rect2(floorf(_blimp_x) + 22.0 + tx, by + 14.0, 5.0, 3.0), NEON[(t + int(life * 0.5)) % 4] * Color(1.0, 1.0, 1.0, 0.8))
	layer("far", FAR_Y, FAR_F)
	var o_far: float = off(FAR_F, 768.0)
	var lights: PackedVector2Array = meta.get("far_lights", PackedVector2Array())
	var blink: bool = fposmod(life, 1.4) < 0.5
	for i: int in range(lights.size()):
		var lx: float = wrap_x(lights[i].x, o_far, 768.0)
		if lx < 0.0 or lx > 480.0 or not blink:
			continue
		bg.draw_rect(Rect2(floorf(lx), FAR_Y + lights[i].y, 1.0, 1.0), Color("#ff3030"))
	_traffic(112.0, 10, 34.0, 1.0, 0.0, 0.55)
	_traffic(132.0, 8, 52.0, 1.0, 211.0, 0.65)
	layer("mid", MID_Y, MID_F)
	var o_mid: float = off(MID_F, 896.0)
	var ads: Texture2D = tex("ads")
	var boards: PackedVector3Array = meta.get("boards", PackedVector3Array())
	for b: int in range(boards.size()):
		var bx: float = wrap_x(boards[b].x, o_mid, 896.0)
		if bx < -40.0 or bx > 480.0:
			continue
		var ad: int = (int(boards[b].z) + int(life / 6.0)) % 4
		var fr: int = int(life * 2.0 + float(b)) % 2
		if _flicker(b, 9.0):
			var r: Rect2 = Rect2(floorf(bx), MID_Y + boards[b].y, AD_W, AD_H)
			bg.draw_texture_rect_region(ads, r, Rect2(float(ad) * 40.0, float(fr) * 24.0, AD_W, AD_H), Color(1.0, 1.0, 1.0, 0.8))
			bg.draw_rect(r.grow(3.0), Color(NEON[ad].r, NEON[ad].g, NEON[ad].b, 0.05))
	var signs: PackedVector4Array = meta.get("signs", PackedVector4Array())
	for s2: int in range(signs.size()):
		var sx: float = wrap_x(signs[s2].x, o_mid, 896.0)
		if sx < -8.0 or sx > 480.0:
			continue
		var c: Color = NEON[int(signs[s2].w)]
		for seg: int in range(5):
			if _flicker(s2 * 5 + seg, 6.0) or seg % 2 == 0:
				bg.draw_rect(Rect2(floorf(sx), MID_Y + signs[s2].y + float(seg) * 6.0 + 1.0, signs[s2].z, 4.0), Color(c.r, c.g, c.b, 0.7))
	_traffic(170.0, 7, 80.0, 2.0, 77.0, 0.85)
	layer("near", NEAR_Y, NEAR_F)
	var o_n: float = off(NEAR_F, 768.0)
	var nsigns: PackedVector4Array = meta.get("near_signs", PackedVector4Array())
	for n2: int in range(nsigns.size()):
		var nx: float = wrap_x(nsigns[n2].x, o_n, 768.0)
		if nx < -30.0 or nx > 480.0:
			continue
		if _flicker(n2 + 40, 7.0):
			var c2: Color = NEON[int(nsigns[n2].w)]
			var ny: float = NEAR_Y + nsigns[n2].y
			bg.draw_rect(Rect2(floorf(nx), ny, nsigns[n2].z, 5.0), Color(c2.r, c2.g, c2.b, 0.75))
			bg.draw_rect(Rect2(floorf(nx) + 2.0, ny + 2.0, nsigns[n2].z - 4.0, 1.0), Color(0.04, 0.02, 0.1, 0.9))
			bg.draw_rect(Rect2(floorf(nx) - 2.0, ny - 2.0, nsigns[n2].z + 4.0, 9.0), Color(c2.r, c2.g, c2.b, 0.07))
	# rain: one batched draw of short diagonal streaks
	var segs: PackedVector2Array = PackedVector2Array()
	segs.resize(RAIN_N * 2)
	for r2: int in range(RAIN_N):
		var rx: float = fposmod(float(r2) * 53.7 - life * 70.0 - scroll * 0.6, 500.0) - 10.0
		var ry: float = fposmod(float(r2) * 97.3 + life * 380.0, 240.0) + 24.0
		segs[r2 * 2] = Vector2(floorf(rx) + 0.5, floorf(ry) + 0.5)
		segs[r2 * 2 + 1] = Vector2(floorf(rx) - 1.5, floorf(ry) + 6.5)
	bg.draw_multiline(segs, Color(0.6, 0.65, 1.0, 0.2), 1.0)
