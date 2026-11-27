extends "res://scripts/stages/stage_background.gd"

# STAGE 24 background: jungle ruins of jade and gold at dusk. A teal-green sky with a pale jade
# moon and a small gold one; stepped pyramids on the horizon; colossal seated statues whose eye
# slits smoulder, a stepped temple between them with waterfalls pouring off its terraces into
# misty pools; a colonnade of carved pillars whose glyph panels pulse in a slow wave; a dark
# jungle canopy overhead trailing swaying vines; a rubble floor with flickering braziers.
# Fireflies drift through it all. Rare events: a colossus awakening (its eyes flare and two
# beams of light sweep the sky), a glyph wave racing through every panel, and a flock of
# golden birds crossing the sky.
#
# Layers: "sky" 480x270; "horizon" 512x70 at y 148 (0.025); "far" 640x140 at y 104 (0.06);
# "mid" 768x156 at y 92 (0.26); "canopy" 768x46 at y 22 (0.5); "near" 768x58 at y 200 (0.85).

const Painter = preload("res://scripts/stage_bg_painter.gd")

const HOR_Y: float = 148.0
const HOR_F: float = 0.025
const FAR_Y: float = 104.0
const FAR_F: float = 0.06
const MID_Y: float = 92.0
const MID_F: float = 0.26
const CAN_Y: float = 22.0
const CAN_F: float = 0.5
const NEAR_Y: float = 200.0
const NEAR_F: float = 0.85

const STATUES: Array[float] = [118.0, 446.0]
const EYE_TIME: float = 2.8
const WAVE_TIME: float = 1.7
const BIRD_COUNT: int = 7

# rare events (the batch harness forces them by zeroing these countdowns)
var _ev_wait_a: float = 9.0
var _ev_wait_b: float = 5.0
var _ev_wait_c: float = 13.0
var _eye_t: float = -1.0
var _eye_i: int = 0
var _wave_t: float = -1.0
var _birds_x: float = -1.0
var _birds_y: float = 60.0
var _mist_t: float = 0.2
var _ember_t: float = 0.3


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2424
	var out: Dictionary = {}
	_paint_sky(out, rng)
	_paint_horizon(out, rng)
	_paint_far(out, rng)
	_paint_mid(out, rng)
	_paint_canopy(out, rng)
	_paint_near(out, rng)
	return out


# --- painting ------------------------------------------------------------------------------------

static func _paint_sky(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#040c0b"))
	Painter.vgrad(sky, 20, 236, PackedColorArray([Color("#040c0b"), Color("#061210"), Color("#091a16"), Color("#0e231c"), Color("#142c21"), Color("#1c3424")]), 0.5)
	# a dusky gold-green glow low on the horizon
	Painter.vgrad(sky, 196, 250, PackedColorArray([Color("#1c3424"), Color("#24382a"), Color("#283c2a")]), 0.6)
	for i: int in range(80):
		var c: Color = Color("#3c5c52") if i % 4 != 0 else Color("#7a9e90")
		Painter.px(sky, rng.randi_range(0, 479), rng.randi_range(24, 130), c)
	# pale jade moon with thin cloud bands across it
	Painter.disc(sky, 372.0, 66.0, 23.0, Color("#1e3a30"))
	Painter.disc(sky, 374.0, 65.0, 21.0, Color("#284a3e"))
	Painter.disc(sky, 378.0, 63.0, 16.0, Color("#30584a"))
	Painter.disc(sky, 383.0, 60.0, 9.0, Color("#3a6656"))
	for cr: Vector3 in [Vector3(366.0, 70.0, 4.0), Vector3(380.0, 74.0, 3.0), Vector3(372.0, 56.0, 2.5)]:
		Painter.disc(sky, cr.x, cr.y, cr.z, Color("#24443a"))
	for band: Vector2i in [Vector2i(58, 3), Vector2i(71, 2), Vector2i(80, 4)]:
		for y: int in range(band.x, band.x + band.y):
			for x: int in range(332, 420):
				if Painter.bayer(x, y) < 0.7:
					Painter.px(sky, x, y, Color("#0c1c17"))
	# a small gold moon
	Painter.disc(sky, 104.0, 44.0, 6.0, Color("#4a4226"))
	Painter.disc(sky, 105.0, 43.0, 4.5, Color("#5e5430"))
	Painter.disc(sky, 106.0, 42.0, 2.0, Color("#786a3c"))
	out["sky"] = sky


static func _paint_horizon(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 512
	var h: int = 70
	var img: Image = Painter.new_img(w, h)
	# rolling jungle hills
	var prof: PackedFloat32Array = Painter.profile(w, rng, 4, 3, 0.5)
	for x: int in range(w):
		var top: int = int(40.0 + prof[x] * 16.0)
		Painter.vline(img, x, top, h - 1, Color("#0d1d17"))
	# distant stepped pyramids with a faint lit shrine on top
	var shrines: PackedVector2Array = PackedVector2Array()
	for pyr: Vector2i in [Vector2i(60, 5), Vector2i(230, 7), Vector2i(390, 6)]:
		var px0: int = pyr.x
		var base: int = 58
		var tiers: int = pyr.y
		for t: int in range(tiers):
			var half: int = 34 - t * 6
			var ty: int = base - (t + 1) * 6
			Painter.rect(img, px0 - half, ty, half * 2, 6, Color("#0f211a"))
			Painter.span(img, px0 - half, px0 + half - 1, ty, Color("#16291f"))
		var top_y: int = base - tiers * 6
		Painter.rect(img, px0 - 4, top_y - 6, 8, 6, Color("#13261d"))
		Painter.px(img, px0, top_y - 4, Color("#4a4a28"))
		shrines.append(Vector2(float(px0), float(top_y - 4)))
		# the great stair
		Painter.rect(img, px0 - 3, top_y, 6, base - top_y, Color("#122419"))
	out["horizon"] = img
	out["shrines"] = shrines


# Far: jungle crowns, two colossi and a stepped temple whose terraces spill waterfalls.
static func _paint_far(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 640
	var h: int = 140
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 6, 0.55)
	for x: int in range(w):
		var top: int = int(58.0 + prof[x] * 40.0)
		Painter.vline(img, x, top, h - 1, Color("#09150f"))
		Painter.px(img, x, top, Color("#0f2117"))
		if (x + top) % 7 == 0:
			Painter.px(img, x, top + 1, Color("#0f2117"))
	var falls: PackedVector4Array = PackedVector4Array()
	# the stepped temple between the colossi
	var tx: int = 282
	for t: int in range(4):
		var half: int = 62 - t * 12
		var ty: int = 112 - t * 24
		Painter.rect(img, tx - half, ty, half * 2, h - ty, Color("#0c1a14"))
		Painter.span(img, tx - half, tx + half - 1, ty, Color("#1a2c22"))
		Painter.span(img, tx - half, tx + half - 1, ty + 1, Color("#12221a"))
		for b: int in range(tx - half + 4, tx + half - 4, 9):
			Painter.rect(img, b, ty + 6, 5, 6, Color("#08120e"))
	Painter.rect(img, tx - 9, 24, 18, 16, Color("#0e1d16"))
	Painter.rect(img, tx - 4, 30, 8, 10, Color("#060e0a"))
	Painter.span(img, tx - 11, tx + 10, 24, Color("#3a3418"))
	# waterfalls: one wide one off the top terrace, two thin ones off the cliffs
	for fdef: Vector4 in [Vector4(float(tx - 8), 40.0, 132.0, 16.0), Vector4(176.0, 70.0, 132.0, 5.0), Vector4(598.0, 62.0, 132.0, 6.0)]:
		var fx: int = int(fdef.x)
		var fw: int = int(fdef.w)
		for y: int in range(int(fdef.y), int(fdef.z)):
			for x2: int in range(fx, fx + fw):
				var c: Color = Color("#163a32")
				if (x2 - fx) % 3 == 1 and Painter.bayer(x2, y) < 0.6:
					c = Color("#22524a")
				elif x2 == fx or x2 == fx + fw - 1:
					c = Color("#10302a")
				Painter.px(img, x2, y, c)
		Painter.ellipse(img, float(fx) + float(fw) * 0.5, fdef.z + 2.0, float(fw) * 0.5 + 8.0, 3.0, Color("#183c32"))
		falls.append(fdef)
	# the colossi
	var eyes: PackedVector2Array = PackedVector2Array()
	for sx: float in STATUES:
		var stat: Image = _statue(rng)
		img.blend_rect(stat, Rect2i(0, 0, stat.get_width(), stat.get_height()), Vector2i(int(sx) - 50, 0))
		eyes.append(Vector2(sx - 6.0, 27.0))
		eyes.append(Vector2(sx + 5.0, 27.0))
	# mist over the pools at the foot of it all
	for y2: int in range(124, h):
		var k: float = float(y2 - 124) / float(h - 124)
		for x3: int in range(w):
			if Painter.bayer(x3, y2) < 0.25 * k + 0.08:
				Painter.px(img, x3, y2, Color("#183028"))
	out["far"] = img
	out["eyes"] = eyes
	out["falls"] = falls


# One seated colossus (100x140, centred at x 50): a crowned head, a gold collar, hands on its
# knees, a stepped pedestal; rim-lit on the right, mossy and cracked.
static func _statue(rng: RandomNumberGenerator) -> Image:
	var img: Image = Painter.new_img(100, 140)
	var base: Color = Color("#0b1914")
	var c: float = 50.0
	Painter.rect(img, 6, 124, 88, 16, base)
	Painter.rect(img, 12, 116, 76, 8, base)
	Painter.rect(img, 16, 92, 68, 24, base)
	Painter.ellipse(img, c - 18.0, 93.0, 17.0, 6.0, base)
	Painter.ellipse(img, c + 18.0, 93.0, 17.0, 6.0, base)
	Painter.rect(img, 13, 110, 31, 6, base)
	Painter.rect(img, 56, 110, 31, 6, base)
	Painter.poly(img, PackedVector2Array([Vector2(c - 25.0, 93.0), Vector2(c - 19.0, 44.0), Vector2(c + 19.0, 44.0), Vector2(c + 25.0, 93.0)]), base)
	Painter.ellipse(img, c - 25.0, 52.0, 8.0, 6.0, base)
	Painter.ellipse(img, c + 25.0, 52.0, 8.0, 6.0, base)
	Painter.rect(img, 17, 52, 9, 44, base)
	Painter.rect(img, 74, 52, 9, 44, base)
	Painter.ellipse(img, c - 27.0, 96.0, 7.0, 4.0, base)
	Painter.ellipse(img, c + 27.0, 96.0, 7.0, 4.0, base)
	Painter.rect(img, 39, 18, 22, 27, base)
	Painter.poly(img, PackedVector2Array([Vector2(c - 21.0, 19.0), Vector2(c - 17.0, 2.0), Vector2(c - 7.0, 9.0), Vector2(c, 0.0), Vector2(c + 7.0, 9.0), Vector2(c + 17.0, 2.0), Vector2(c + 21.0, 19.0)]), base)
	Painter.disc(img, c - 13.0, 31.0, 3.0, base)
	Painter.disc(img, c + 13.0, 31.0, 3.0, base)
	# rim light on right-facing edges, a darker left edge
	var rim: Image = img.duplicate() as Image
	for y: int in range(140):
		for x: int in range(1, 99):
			if img.get_pixel(x, y).a <= 0.0:
				continue
			if img.get_pixel(x + 1, y).a <= 0.0:
				rim.set_pixel(x, y, Color("#1c3328"))
			elif img.get_pixel(x - 1, y).a <= 0.0:
				rim.set_pixel(x, y, Color("#081210"))
			elif y > 0 and img.get_pixel(x, y - 1).a <= 0.0:
				rim.set_pixel(x, y, Color("#16291f"))
	img = rim
	# weathered gold trim: crown band, collar, bracers, pedestal edge
	var gold: Color = Color("#463c1a")
	var gold_hi: Color = Color("#6a5824")
	Painter.rect(img, 36, 15, 28, 3, gold)
	Painter.span(img, 36, 63, 15, gold_hi)
	Painter.rect(img, 31, 44, 38, 5, gold)
	Painter.span(img, 31, 68, 44, gold_hi)
	for s: int in range(5):
		Painter.rect(img, 34 + s * 7, 46, 2, 2, Color("#1c4a36"))
	Painter.rect(img, 17, 82, 9, 3, gold)
	Painter.rect(img, 74, 82, 9, 3, gold)
	Painter.span(img, 12, 87, 116, gold)
	Painter.px(img, 50, 5, Color("#1c4a36"))
	# face: brow, eye slits (lit live), nose, mouth
	Painter.span(img, 41, 58, 24, Color("#060e0b"))
	Painter.rect(img, 41, 26, 6, 3, Color("#040806"))
	Painter.rect(img, 52, 26, 6, 3, Color("#040806"))
	Painter.rect(img, 48, 29, 3, 6, Color("#14251d"))
	Painter.span(img, 45, 54, 38, Color("#040806"))
	# cracks and moss runs
	Painter.line(img, 66, 58, 70, 78, Color("#060e0b"))
	Painter.line(img, 70, 78, 67, 90, Color("#060e0b"))
	Painter.line(img, 30, 100, 36, 112, Color("#060e0b"))
	for m: int in range(9):
		var mx: int = rng.randi_range(14, 86)
		var my: int = rng.randi_range(46, 112)
		if img.get_pixel(mx, my).a > 0.0:
			Painter.vline(img, mx, my, my + rng.randi_range(3, 9), Color("#0f2a18"))
	return img


# Mid: a colonnade of carved pillars under a fret-carved lintel (broken in two places), glyph
# panels on every pillar, vines climbing them, a platform edge along the foot.
static func _paint_mid(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 156
	var img: Image = Painter.new_img(w, h)
	var panels: PackedVector2Array = PackedVector2Array()
	var stone: Color = Color("#0e1915")
	var hi: Color = Color("#19291f")
	var sh: Color = Color("#08100d")
	var broken: Array[int] = [2, 6]
	for i: int in range(8):
		var px0: int = i * 96 + 30
		var top: int = 12
		if broken.has(i):
			top = 50 + rng.randi_range(0, 30)
		# shaft with fluting
		Painter.rect(img, px0, top, 20, 140 - top, stone)
		Painter.vline(img, px0, top, 139, hi)
		Painter.vline(img, px0 + 19, top, 139, sh)
		for fl: int in [5, 10, 15]:
			Painter.vline(img, px0 + fl, top + 8, 132, Color("#0b1411"))
		if broken.has(i):
			# a jagged broken top with fallen chunks at its foot
			for jx: int in range(20):
				var jag: int = int(absf(sin(float(jx) * 1.9 + float(i))) * 7.0)
				Painter.vline(img, px0 + jx, top - jag, top, stone)
				Painter.px(img, px0 + jx, top - jag, hi)
		else:
			Painter.rect(img, px0 - 4, 12, 28, 7, stone)
			Painter.span(img, px0 - 4, px0 + 23, 12, hi)
			Painter.span(img, px0 - 4, px0 + 23, 16, Color("#3a3218"))
			Painter.span(img, px0 - 4, px0 + 23, 18, sh)
		Painter.rect(img, px0 - 4, 133, 28, 7, stone)
		Painter.span(img, px0 - 4, px0 + 23, 133, hi)
		Painter.span(img, px0 - 4, px0 + 23, 135, Color("#3a3218"))
		Painter.span(img, px0, px0 + 19, 70, Color("#2e2914"))
		# glyph panels
		for py: int in [42, 92]:
			if py < top + 6:
				continue
			Painter.rect(img, px0 + 4, py, 12, 14, Color("#070e0b"))
			Painter.span(img, px0 + 4, px0 + 15, py + 13, hi)
			_carve(img, px0 + 6, py + 3, (i + py) % 3, Color("#123426"))
			panels.append(Vector2(float(px0 + 4), float(py)))
		# vines up the shaft
		var vx: int = px0 + (2 if i % 2 == 0 else 17)
		var vtop: int = maxi(top, 140 - rng.randi_range(40, 110))
		for vy: int in range(vtop, 140):
			var wob: int = int(sin(float(vy) * 0.25 + float(i)) * 2.0)
			Painter.px(img, vx + wob, vy, Color("#0e2614"))
			if vy % 6 == 0:
				Painter.px(img, vx + wob + 1, vy, Color("#163a1c"))
				Painter.px(img, vx + wob - 1, vy - 1, Color("#163a1c"))
	# the lintel: spans between unbroken neighbours, carved with a step-fret
	for i2: int in range(8):
		if broken.has(i2) or broken.has((i2 + 1) % 8):
			continue
		var x0: int = i2 * 96 + 26
		var x1: int = x0 + 96 + 28
		Painter.rect(img, x0, 0, x1 - x0, 12, stone)
		Painter.span(img, x0, x1 - 1, 0, hi)
		Painter.span(img, x0, x1 - 1, 1, Color("#3a3218"))
		Painter.span(img, x0, x1 - 1, 11, sh)
		for fx: int in range(x0 + 2, x1 - 8, 8):
			Painter.span(img, fx, fx + 5, 4, Color("#08110d"))
			Painter.vline(img, fx + 5, 4, 8, Color("#08110d"))
			Painter.span(img, fx + 2, fx + 5, 8, Color("#08110d"))
			Painter.px(img, fx + 1, 5, Color("#1a2c22"))
			if (fx / 8) % 4 == 0:
				Painter.px(img, fx + 3, 6, Color("#1c4a34"))
	# platform edge at the foot
	Painter.rect(img, 0, 140, w, 16, Color("#0b1411"))
	Painter.span(img, 0, w - 1, 140, Color("#1a2a21"))
	for bx: int in range(0, w, 24):
		Painter.vline(img, bx + (bx / 24) % 3 * 3, 141, 155, Color("#070d0a"))
	out["mid"] = img
	out["panels"] = panels


static func _carve(img: Image, x: int, y: int, sym: int, c: Color) -> void:
	match sym:
		0:
			Painter.rect(img, x, y, 8, 1, c)
			Painter.rect(img, x, y + 7, 8, 1, c)
			Painter.vline(img, x, y, y + 7, c)
			Painter.vline(img, x + 7, y, y + 7, c)
			Painter.rect(img, x + 3, y + 3, 2, 2, c)
		1:
			Painter.vline(img, x + 3, y, y + 7, c)
			Painter.span(img, x, x + 7, y + 3, c)
			Painter.px(img, x + 1, y + 1, c)
			Painter.px(img, x + 6, y + 1, c)
			Painter.px(img, x + 1, y + 6, c)
			Painter.px(img, x + 6, y + 6, c)
		_:
			Painter.span(img, x, x + 5, y, c)
			Painter.vline(img, x + 5, y, y + 3, c)
			Painter.span(img, x + 1, x + 5, y + 3, c)
			Painter.vline(img, x + 1, y + 3, y + 6, c)
			Painter.span(img, x + 1, x + 7, y + 6, c)


# Canopy: jungle leaves overhanging the top of the screen, roots and the anchors of the vines.
static func _paint_canopy(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 46
	var img: Image = Painter.new_img(w, h)
	var prof: PackedFloat32Array = Painter.profile(w, rng, 5, 5, 0.6)
	for x: int in range(w):
		var bot: int = int(5.0 + prof[x] * 15.0)
		Painter.vline(img, x, 0, bot, Color("#07120c"))
	# leaf clumps along the edge
	for l: int in range(150):
		var lx: float = rng.randf_range(0.0, float(w))
		var ly: float = 6.0 + prof[int(lx) % w] * 15.0 + rng.randf_range(-3.0, 4.0)
		var lw: float = rng.randf_range(2.5, 5.0)
		Painter.ellipse(img, lx, ly, lw, lw * 0.55, Color("#0a1a10"))
		Painter.span(img, int(lx - lw * 0.6), int(lx + lw * 0.3), int(ly - lw * 0.3), Color("#11281a"))
	var vines: PackedVector3Array = PackedVector3Array()
	for v: int in range(22):
		var vx: int = rng.randi_range(0, w - 1)
		var vy: int = int(6.0 + prof[vx] * 15.0)
		var vl: int = rng.randi_range(14, 52)
		vines.append(Vector3(float(vx), float(vy), float(vl)))
		Painter.ellipse(img, float(vx), float(vy), 3.0, 2.0, Color("#0c1f12"))
	# hanging roots (static, short)
	for r: int in range(26):
		var rx: int = rng.randi_range(0, w - 1)
		var ry: int = int(6.0 + prof[rx] * 15.0)
		for yy: int in range(ry, mini(h - 1, ry + rng.randi_range(4, 12))):
			Painter.px(img, rx + int(sin(float(yy) * 0.5 + float(r)) * 1.2), yy, Color("#0a160e"))
	out["canopy"] = img
	out["vines"] = vines


# Near: a rubble floor of carved blocks, broken pillar stumps, a fallen stone head, ferns and
# braziers (their flames are drawn live).
static func _paint_near(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 58
	var img: Image = Painter.new_img(w, h)
	var fires: PackedVector2Array = PackedVector2Array()
	Painter.rect(img, 0, 46, w, 12, Color("#0c140f"))
	Painter.span(img, 0, w - 1, 46, Color("#1e2c24"))
	for bx: int in range(0, w, 18):
		Painter.vline(img, bx + rng.randi_range(0, 4), 47, 57, Color("#070c09"))
		if (bx / 18) % 3 == 1:
			Painter.rect(img, bx + 8, 51, 2, 2, Color("#1c4632"))
		elif (bx / 18) % 5 == 3:
			Painter.span(img, bx + 5, bx + 11, 49, Color("#36301a"))
	var heads: Array[int] = [190, 570]
	var last_fire: int = -200
	var x: int = 6
	while x < w - 40:
		if heads.size() > 0 and x >= heads[0] - 10:
			_fallen_head(img, heads[0])
			x = heads[0] + 44
			heads.remove_at(0)
			continue
		var kind: int = rng.randi_range(0, 3)
		if kind == 1 and x - last_fire < 150:
			kind = 2 if rng.randf() < 0.5 else 3
		match kind:
			0:  # broken pillar stump
				var sh: int = rng.randi_range(14, 30)
				Painter.rect(img, x, 46 - sh, 16, sh, Color("#101b15"))
				Painter.vline(img, x, 46 - sh, 45, Color("#1c2c22"))
				Painter.vline(img, x + 15, 46 - sh, 45, Color("#08100c"))
				for jx: int in range(16):
					var jag: int = int(absf(sin(float(jx + x) * 1.3)) * 4.0)
					Painter.vline(img, x + jx, 46 - sh - jag, 46 - sh, Color("#101b15"))
					Painter.px(img, x + jx, 46 - sh - jag, Color("#1c2c22"))
				x += 16 + rng.randi_range(10, 30)
			1:  # brazier: a stone bowl on a stepped foot
				Painter.rect(img, x + 4, 34, 8, 12, Color("#111c16"))
				Painter.rect(img, x + 1, 42, 14, 4, Color("#141f18"))
				Painter.rect(img, x - 1, 28, 18, 6, Color("#16221a"))
				Painter.span(img, x - 1, x + 16, 28, Color("#3a3418"))
				Painter.span(img, x, x + 15, 33, Color("#0a120e"))
				fires.append(Vector2(float(x + 8), 27.0))
				last_fire = x
				x += 18 + rng.randi_range(30, 60)
			2:  # fern clump
				var fc: float = float(x + 10)
				for f: int in range(7):
					var a: float = -PI * 0.5 + (float(f) - 3.0) * 0.36
					var ln: float = rng.randf_range(10.0, 18.0)
					var tip: Vector2 = Vector2(fc, 46.0) + Vector2.from_angle(a) * ln
					Painter.line(img, int(fc), 46, int(tip.x), int(tip.y), Color("#0d2414"))
					Painter.px(img, int(tip.x), int(tip.y), Color("#16381e"))
					var mid: Vector2 = Vector2(fc, 46.0).lerp(tip, 0.6)
					Painter.px(img, int(mid.x) - 1, int(mid.y), Color("#12301a"))
					Painter.px(img, int(mid.x) + 1, int(mid.y), Color("#12301a"))
				x += 20 + rng.randi_range(6, 24)
			_:  # tumbled carved blocks
				var bw: int = rng.randi_range(12, 20)
				var bh: int = rng.randi_range(8, 12)
				Painter.rect(img, x, 46 - bh, bw, bh, Color("#121d17"))
				Painter.span(img, x, x + bw - 1, 46 - bh, Color("#1e2e24"))
				Painter.rect(img, x + 3, 46 - bh + 3, bw - 6, 2, Color("#0a120e"))
				if rng.randf() < 0.5:
					Painter.rect(img, x + bw - 4, 46 - bh - 7, 10, 7, Color("#111b15"))
					Painter.span(img, x + bw - 4, x + bw + 5, 46 - bh - 7, Color("#1e2e24"))
				x += bw + rng.randi_range(8, 26)
	out["near"] = img
	out["fires"] = fires


# A colossal stone head toppled onto its side, half sunk into the floor: helmet band, shut eyes,
# broad nose and lips, moss over the top.
static func _fallen_head(img: Image, x: int) -> void:
	var cx: float = float(x + 18)
	Painter.ellipse(img, cx, 36.0, 18.0, 15.0, Color("#121d17"))
	Painter.ellipse(img, cx - 3.0, 32.0, 13.0, 9.0, Color("#16231c"))
	Painter.rect(img, x, 40, 37, 6, Color("#121d17"))
	# helmet band across the brow (the head lies tilted back)
	Painter.line(img, x + 3, 27, x + 33, 23, Color("#463c1a"))
	Painter.line(img, x + 3, 28, x + 33, 24, Color("#2e2812"))
	Painter.px(img, x + 10, 26, Color("#1c4a34"))
	Painter.px(img, x + 20, 25, Color("#1c4a34"))
	# shut eyes, nose, lips
	Painter.span(img, x + 8, x + 13, 31, Color("#070c09"))
	Painter.span(img, x + 21, x + 26, 30, Color("#070c09"))
	Painter.rect(img, x + 15, 32, 4, 5, Color("#1e2c24"))
	Painter.span(img, x + 11, x + 24, 39, Color("#070c09"))
	Painter.span(img, x + 12, x + 23, 40, Color("#1a2820"))
	# cracks and moss
	Painter.line(img, x + 30, 30, x + 27, 41, Color("#070c09"))
	for m: int in range(10):
		Painter.px(img, x + 6 + m * 3, 22 + (m % 3), Color("#123018"))
	Painter.px(img, x + 4, 25, Color("#123018"))


# --- animation ----------------------------------------------------------------------------------

func reset() -> void:
	# fireflies: blinking yellow-green motes drifting in the foreground
	drift_a.y0 = 40.0
	drift_a.y1 = 246.0
	drift_a.setup(22, rng, -10.0, 6.0, -5.0, 5.0)
	drift_a.par = 0.4
	drift_a.sway = 4.0
	drift_a.sway_hz = 0.9
	drift_a.blink = 0.45
	drift_a.duty = 0.55
	drift_a.cols = PackedColorArray([Color(0.8, 1.0, 0.45, 0.75), Color(1.0, 0.9, 0.45, 0.6), Color(0.6, 1.0, 0.6, 0.5)])
	# pollen and spray drifting further back
	drift_b.y0 = 60.0
	drift_b.y1 = 240.0
	drift_b.setup(26, rng, -6.0, 2.0, -3.0, 3.0)
	drift_b.par = 0.18
	drift_b.sway = 2.0
	drift_b.sway_hz = 0.5
	drift_b.cols = PackedColorArray([Color(0.55, 0.8, 0.7, 0.22), Color(0.7, 0.75, 0.5, 0.18)])
	_eye_t = -1.0
	_wave_t = -1.0
	_birds_x = -1.0
	_ev_wait_a = rng.randf_range(8.0, 14.0)
	_ev_wait_b = rng.randf_range(4.0, 8.0)
	_ev_wait_c = rng.randf_range(12.0, 18.0)


func _nearest_statue() -> int:
	var best: int = 0
	var best_d: float = 1.0e9
	var o: float = off(FAR_F, 640.0)
	for i: int in range(STATUES.size()):
		var sx: float = wrap_x(STATUES[i], o, 640.0)
		var d: float = absf(sx - 300.0)
		if d < best_d:
			best_d = d
			best = i
	return best


func update() -> void:
	# a: a colossus wakes
	if _eye_t < 0.0:
		_ev_wait_a -= dl
		if _ev_wait_a <= 0.0:
			_eye_t = 0.0
			_eye_i = _nearest_statue()
	else:
		_eye_t += dl
		if _eye_t > EYE_TIME:
			_eye_t = -1.0
			_ev_wait_a = rng.randf_range(18.0, 26.0)
	# b: a glyph wave sweeps the colonnade
	if _wave_t < 0.0:
		_ev_wait_b -= dl
		if _ev_wait_b <= 0.0:
			_wave_t = 0.0
	else:
		_wave_t += dl
		if _wave_t > WAVE_TIME:
			_wave_t = -1.0
			_ev_wait_b = rng.randf_range(11.0, 17.0)
	# c: golden birds cross the sky
	if _birds_x < 0.0:
		_ev_wait_c -= dl
		if _ev_wait_c <= 0.0:
			_birds_x = 520.0
			_birds_y = rng.randf_range(44.0, 84.0)
	else:
		_birds_x -= 64.0 * dl
		if _birds_x < -120.0:
			_birds_x = -1.0
			_ev_wait_c = rng.randf_range(20.0, 30.0)
	# mist rising off the waterfall pools
	_mist_t -= dl
	if _mist_t <= 0.0:
		_mist_t = rng.randf_range(0.25, 0.5)
		var falls: PackedVector4Array = meta.get("falls", PackedVector4Array())
		if not falls.is_empty():
			var f: Vector4 = falls[rng.randi_range(0, falls.size() - 1)]
			var fx: float = wrap_x(f.x + f.w * 0.5, off(FAR_F, 640.0), 640.0)
			if fx > -10.0 and fx < 490.0:
				fx_spawn(StarfieldBg.Fx.STEAM, fx + rng.randf_range(-6.0, 6.0), FAR_Y + f.z, rng.randf_range(-6.0, 6.0), rng.randf_range(-9.0, -4.0), rng.randf_range(1.6, 2.6), FAR_F)
	# embers off the braziers
	_ember_t -= dl
	if _ember_t <= 0.0:
		_ember_t = rng.randf_range(0.15, 0.35)
		var fires: PackedVector2Array = meta.get("fires", PackedVector2Array())
		if not fires.is_empty():
			var fp: Vector2 = fires[rng.randi_range(0, fires.size() - 1)]
			var ex: float = wrap_x(fp.x, off(NEAR_F, 768.0), 768.0)
			if ex > 0.0 and ex < 480.0:
				fx_spawn(StarfieldBg.Fx.SPARK, ex + rng.randf_range(-3.0, 3.0), NEAR_Y + fp.y - 4.0, rng.randf_range(-8.0, 8.0), rng.randf_range(-36.0, -18.0), rng.randf_range(0.6, 1.1), NEAR_F)


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	# a few stars twinkle
	for i: int in range(14):
		var tw: float = sin(life * (1.1 + float(i % 4) * 0.37) + float(i) * 2.3)
		if tw > 0.7:
			bg.draw_rect(Rect2(fposmod(float(i) * 131.7 + 17.0, 480.0), 26.0 + fposmod(float(i) * 47.3, 96.0), 1.0, 1.0), Color(0.6, 0.85, 0.75, 0.7))
	layer("horizon", HOR_Y, HOR_F)
	var o_h: float = off(HOR_F, 512.0)
	var shrines: PackedVector2Array = meta.get("shrines", PackedVector2Array())
	for s: int in range(shrines.size()):
		var shx: float = wrap_x(shrines[s].x, o_h, 512.0)
		if shx > 0.0 and shx < 480.0:
			var fl: float = 0.35 + 0.25 * sin(life * 3.0 + float(s) * 2.0)
			bg.draw_rect(Rect2(floorf(shx) - 1.0, HOR_Y + shrines[s].y, 3.0, 2.0), Color(1.0, 0.7, 0.3, fl))
	if _birds_x >= 0.0:
		_draw_birds()
	layer("far", FAR_Y, FAR_F)
	_draw_falls()
	_draw_eyes()
	drift_draw(drift_b)
	layer("mid", MID_Y, MID_F)
	_draw_panels()
	layer("canopy", CAN_Y, CAN_F)
	_draw_vines()
	layer("near", NEAR_Y, NEAR_F)
	_draw_fires()
	fx_draw()
	drift_draw(drift_a)


func _draw_falls() -> void:
	var o: float = off(FAR_F, 640.0)
	var falls: PackedVector4Array = meta.get("falls", PackedVector4Array())
	for i: int in range(falls.size()):
		var f: Vector4 = falls[i]
		var fx: float = wrap_x(f.x, o, 640.0)
		if fx < -16.0 or fx > 480.0:
			continue
		var top: float = FAR_Y + f.y
		var length: float = f.z - f.y
		var n: int = int(f.w) * 2
		for s: int in range(n):
			var sx: float = floorf(fx) + float(s % int(f.w))
			var sy: float = fposmod(life * (46.0 + float(s % 3) * 9.0) + float(s * 23), length)
			bg.draw_rect(Rect2(sx, floorf(top + sy), 1.0, 3.0 + float(s % 3)), Color(0.6, 0.9, 0.82, 0.34))
		# white water at the foot
		var foam: float = 0.5 + 0.5 * sin(life * 7.0 + float(i))
		bg.draw_rect(Rect2(floorf(fx) - 2.0, FAR_Y + f.z - 1.0, f.w + 4.0, 2.0), Color(0.7, 0.9, 0.85, 0.12 + 0.1 * foam))


func _draw_eyes() -> void:
	var o: float = off(FAR_F, 640.0)
	var eyes: PackedVector2Array = meta.get("eyes", PackedVector2Array())
	for i: int in range(eyes.size()):
		var ex: float = wrap_x(eyes[i].x, o, 640.0)
		if ex < -100.0 or ex > 580.0:
			continue
		var y: float = FAR_Y + eyes[i].y
		var awake: bool = _eye_t >= 0.0 and i / 2 == _eye_i
		var glow: float = 0.3 + 0.12 * sin(life * 1.4 + float(i / 2) * 2.0)
		if awake:
			var k: float = clampf(_eye_t / 0.5, 0.0, 1.0) * clampf((EYE_TIME - _eye_t) / 0.6, 0.0, 1.0)
			glow = lerpf(glow, 1.0, k)
			if i % 2 == 0:
				# twin beams sweeping across the sky
				var sweep: float = lerpf(-0.55, 0.25, clampf(_eye_t / EYE_TIME, 0.0, 1.0))
				var origin: Vector2 = Vector2(ex + 5.0, y + 1.0)
				for b: int in range(2):
					var a: float = PI + sweep + float(b) * 0.08
					var tip: Vector2 = origin + Vector2.from_angle(a) * 520.0
					var side: Vector2 = Vector2.from_angle(a + PI * 0.5) * (18.0 + 10.0 * float(b))
					bg.draw_colored_polygon(PackedVector2Array([origin, tip + side, tip - side]), Color(1.0, 0.82, 0.4, 0.045 * k))
			if ex > 0.0 and ex < 480.0:
				bg.draw_rect(Rect2(floorf(ex) - 3.0, y - 2.0, 7.0, 5.0), Color(1.0, 0.8, 0.35, 0.25 * k))
		if ex > 0.0 and ex < 480.0:
			bg.draw_rect(Rect2(floorf(ex) - 1.0, y, 4.0, 2.0), Color(1.0, 0.78, 0.32, glow))


func _draw_panels() -> void:
	var o: float = off(MID_F, 768.0)
	var panels: PackedVector2Array = meta.get("panels", PackedVector2Array())
	var wave_x: float = -1000.0
	if _wave_t >= 0.0:
		wave_x = lerpf(-60.0, 540.0, _wave_t / WAVE_TIME)
	for i: int in range(panels.size()):
		var px: float = wrap_x(panels[i].x, o, 768.0)
		if px < -12.0 or px > 480.0:
			continue
		var py: float = MID_Y + panels[i].y
		var a: float = 0.04 + 0.13 * maxf(0.0, sin(life * 1.5 - px * 0.018))
		var dw: float = absf(px - wave_x)
		if dw < 46.0:
			a = maxf(a, 0.55 * (1.0 - dw / 46.0))
		if a > 0.06:
			bg.draw_rect(Rect2(floorf(px) + 2.0, py + 3.0, 8.0, 8.0), Color(0.24, 1.0, 0.62, a))
			bg.draw_rect(Rect2(floorf(px) + 4.0, py + 5.0, 4.0, 4.0), Color(0.7, 1.0, 0.85, a * 0.8))
	if _wave_t >= 0.0:
		var k: float = sin(_wave_t / WAVE_TIME * PI)
		bg.draw_rect(Rect2(floorf(wave_x) - 30.0, MID_Y, 60.0, 140.0), Color(0.24, 1.0, 0.62, 0.035 * k))


func _draw_vines() -> void:
	var o: float = off(CAN_F, 768.0)
	var vines: PackedVector3Array = meta.get("vines", PackedVector3Array())
	var segs: PackedVector2Array = PackedVector2Array()
	var leaves: PackedVector2Array = PackedVector2Array()
	for v: int in range(vines.size()):
		var vx: float = wrap_x(vines[v].x, o, 768.0)
		if vx < -20.0 or vx > 500.0:
			continue
		var y0: float = CAN_Y + vines[v].y
		var length: float = vines[v].z
		var prev: Vector2 = Vector2(floorf(vx) + 0.5, y0 + 0.5)
		for s: int in range(1, 6):
			var t: float = float(s) / 5.0
			var sw: float = sin(life * 0.9 + float(v) * 1.3 + t * 2.2) * t * 6.0
			var p: Vector2 = Vector2(floorf(vx + sw) + 0.5, floorf(y0 + t * length) + 0.5)
			segs.append(prev)
			segs.append(p)
			if s % 2 == 0:
				leaves.append(p)
			prev = p
	if not segs.is_empty():
		bg.draw_multiline(segs, Color("#10301a"), 1.0)
	for lf: Vector2 in leaves:
		bg.draw_rect(Rect2(lf.x - 1.5, lf.y - 0.5, 2.0, 1.0), Color("#16401f"))


func _draw_fires() -> void:
	var o: float = off(NEAR_F, 768.0)
	var fires: PackedVector2Array = meta.get("fires", PackedVector2Array())
	for i: int in range(fires.size()):
		var fx: float = wrap_x(fires[i].x, o, 768.0)
		if fx < -20.0 or fx > 500.0:
			continue
		var base: Vector2 = Vector2(floorf(fx), NEAR_Y + fires[i].y)
		var fl: float = sin(life * 13.0 + float(i) * 1.7) * 0.5 + sin(life * 21.0 + float(i)) * 0.5
		var hgt: float = 7.0 + 2.0 * fl
		bg.draw_rect(Rect2(base.x - 9.0, base.y - 10.0, 18.0, 12.0), Color(1.0, 0.55, 0.15, 0.06 + 0.02 * fl))
		bg.draw_colored_polygon(PackedVector2Array([base + Vector2(-6.0, 0.0), base + Vector2(fl, -hgt - 3.0), base + Vector2(6.0, 0.0)]), Color(1.0, 0.45, 0.12, 0.85))
		bg.draw_colored_polygon(PackedVector2Array([base + Vector2(-3.0, 0.0), base + Vector2(-fl * 0.5, -hgt), base + Vector2(3.0, 0.0)]), Color(1.0, 0.85, 0.35, 0.95))
		bg.draw_rect(Rect2(base.x - 1.0, base.y - 2.0, 2.0, 2.0), Color(1.0, 1.0, 0.85, 1.0))


func _draw_birds() -> void:
	var segs: PackedVector2Array = PackedVector2Array()
	for b: int in range(BIRD_COUNT):
		var row: int = (b + 1) / 2
		var side: float = -1.0 if b % 2 == 1 else 1.0
		var x: float = floorf(_birds_x + float(row) * 11.0)
		var y: float = floorf(_birds_y + side * float(row) * 6.0 + sin(life * 2.0 + float(b)) * 1.5)
		var flap: bool = int(life * 6.0 + float(b) * 0.7) % 2 == 0
		var wy: float = -2.0 if flap else 1.0
		segs.append(Vector2(x - 3.0, y + wy))
		segs.append(Vector2(x, y))
		segs.append(Vector2(x, y))
		segs.append(Vector2(x + 3.0, y + wy))
	bg.draw_multiline(segs, Color(0.95, 0.75, 0.3, 0.7), 1.0)
