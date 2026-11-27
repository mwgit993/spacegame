extends RefCounted

# STAGE 26 sprites (worker thread: Images only). Creatures of the nebula: luminous teal and
# magenta gas, gold starlight, soft dust. Every key starts with the stage id (or "boss_<id>").

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const TEAL: Array[Color] = [Color("#0a2a36"), Color("#16606e"), Color("#3cc0c8"), Color("#c8fff6")]
const MAG: Array[Color] = [Color("#2a0a30"), Color("#6a1a6a"), Color("#c84aa8"), Color("#ffc8f0")]
const GOLD: Array[Color] = [Color("#4a2408"), Color("#a8620e"), Color("#ffb43c"), Color("#fff0c0")]
const DUST: Array[Color] = [Color("#2a1e42"), Color("#54447a"), Color("#9080b8"), Color("#dcd0f4")]
const BELL: Array[Color] = [Color("#0e3a4a"), Color("#1e7488"), Color("#52c8d4"), Color("#d8fffa")]


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(2):
		out[id + "_seed_%d" % f] = Kit.outline(_seed(f))
		out[id + "_young_%d" % f] = Kit.outline(_young(f))
		out[id + "_flare_%d" % f] = Kit.outline(_flare(f))
		out[id + "_jelly_%d" % f] = Kit.outline(_jelly(f))
		out[id + "_wraith_%d" % f] = Kit.outline(_wraith(f))

	# Shots: the stage's own gold star mote (bullet_b), the jellies' teal motes, wraith dust.
	var shot: Image = Kit.blank(9, 9)
	Kit.disc(shot, 4.5, 4.5, 3.6, Color(1.0, 0.7, 0.25, 0.4))
	Kit.line(shot, Vector2(4, 0), Vector2(4, 8), Color(1.0, 0.85, 0.5, 0.85))
	Kit.line(shot, Vector2(0, 4), Vector2(8, 4), Color(1.0, 0.85, 0.5, 0.85))
	Kit.disc(shot, 4.5, 4.5, 2.4, GOLD[2])
	Kit.disc(shot, 4.5, 4.5, 1.4, GOLD[3])
	Kit.put(shot, 4, 4, Color.WHITE)
	out[id + "_shot"] = shot
	var mote: Image = Kit.blank(8, 8)
	Kit.disc(mote, 4.0, 4.0, 4.0, Color(0.25, 0.95, 0.9, 0.38))
	Kit.disc(mote, 4.0, 4.0, 2.8, Color("#7af0ea"))
	Kit.disc(mote, 3.6, 3.6, 1.5, Color("#e8fffc"))
	out[id + "_mote"] = mote
	var dust: Image = Kit.blank(7, 7)
	Kit.disc(dust, 3.5, 3.5, 3.5, Color(0.75, 0.55, 1.0, 0.38))
	Kit.disc(dust, 3.5, 3.5, 2.4, Color("#c8a8ff"))
	Kit.disc(dust, 3.2, 3.2, 1.2, Color("#f8f0ff"))
	out[id + "_dust"] = dust

	out[id + "_scout"] = Kit.outline(_g_scout())
	out[id + "_swooper"] = Kit.outline(_g_swooper())
	out[id + "_sniper"] = Kit.outline(_g_sniper())
	out[id + "_cruiser"] = Kit.outline(_g_cruiser())
	for f2: int in range(3):
		out["boss_%s_%d" % [id, f2]] = Kit.outline(_protostar(f2))
	return out


static func _over(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.3:
		img.set_pixel(x, y, col)


# Diffraction spike: bright at the root, fading to the tip.
static func _spike(img: Image, c: Vector2, d: Vector2, length: float, root: Color, tip: Color) -> void:
	var steps: int = int(length)
	for i: int in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector2 = c + d * float(i)
		Kit.put(img, int(floorf(p.x)), int(floorf(p.y)), root.lerp(tip, t))


# --- star seed: three growth forms -----------------------------------------------------------------

# Form 0: a gold ember in a dim shell; frame 1 the core swells and sparks flick round it.
static func _seed(frame: int) -> Image:
	var img: Image = Kit.blank(11, 11)
	var c: Vector2 = Vector2(5.5, 5.5)
	Kit.disc(img, c.x, c.y, 4.4, GOLD[1])
	Kit.disc(img, c.x, c.y, 3.4, GOLD[2])
	Kit.disc(img, c.x - 0.6, c.y - 0.6, 1.7 + 0.5 * float(frame), GOLD[3])
	Kit.put(img, 4, 4, Color.WHITE)
	if frame == 0:
		Kit.put(img, 0, 5, GOLD[2])
		Kit.put(img, 10, 5, GOLD[2])
	else:
		Kit.put(img, 5, 0, GOLD[3])
		Kit.put(img, 5, 10, GOLD[3])
	return img


# Form 1: a young blue-white star with four diffraction spikes (they twinkle between frames).
static func _young(frame: int) -> Image:
	var img: Image = Kit.blank(17, 17)
	var c: Vector2 = Vector2(8.5, 8.5)
	var dirs: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	for d: Vector2 in dirs:
		_spike(img, c, d, 8.0 if frame == 0 else 6.0, TEAL[3], TEAL[1])
	if frame == 1:
		for d2: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			_spike(img, c, d2, 4.0, TEAL[3], TEAL[1])
	Kit.disc(img, c.x, c.y, 4.6, TEAL[1])
	Kit.disc(img, c.x, c.y, 3.6, TEAL[2])
	Kit.disc(img, c.x - 0.6, c.y - 0.6, 2.2, TEAL[3])
	Kit.put(img, 7, 7, Color.WHITE)
	Kit.put(img, 8, 8, Color.WHITE)
	return img


# Form 2: a flare star: white-hot core in a magenta corona with looping prominences and
# eight spikes; frame 1 the corona and prominences shift.
static func _flare(frame: int) -> Image:
	var img: Image = Kit.blank(23, 23)
	var c: Vector2 = Vector2(11.5, 11.5)
	for y: int in range(23):
		for x: int in range(23):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c)
			var cr: float = 8.6 if frame == 0 else 8.0
			if d < cr and d > 5.0 and Painter.bayer(x + frame, y) < (cr - d) / 3.2:
				img.set_pixel(x, y, MAG[1] if d > 7.0 else MAG[2])
	for p: int in range(3):
		var a: float = float(p) * TAU / 3.0 + (0.6 if frame == 1 else 0.0)
		for s: int in range(7):
			var t: float = float(s) / 6.0
			var q: Vector2 = c + Vector2.from_angle(a - 0.35 + t * 0.7) * (6.5 + sin(t * PI) * 3.0)
			Kit.put(img, int(q.x), int(q.y), MAG[3])
	for k: int in range(8):
		var d2: Vector2 = Vector2.from_angle(float(k) * PI * 0.25)
		var long: bool = (k % 2 == 0) == (frame == 0)
		_spike(img, c, Vector2(signf(d2.x) if absf(d2.x) > 0.3 else 0.0, signf(d2.y) if absf(d2.y) > 0.3 else 0.0), 10.0 if long else 6.0, Color("#fff0fa"), MAG[1])
	Kit.disc(img, c.x, c.y, 5.0, MAG[2])
	Kit.disc(img, c.x, c.y, 4.0, Color("#ffd8f4"))
	Kit.disc(img, c.x - 0.5, c.y - 0.5, 2.6, Color.WHITE)
	return img


# --- cosmic jelly -----------------------------------------------------------------------------------

# A gas-bell drifting on the currents: a teal dome with a little magenta star for a heart,
# frilled rim and trailing tendrils. Frame 0 relaxed (wide bell), frame 1 the pulse (bell
# squeezed tall, tendrils flared out).
static func _jelly(frame: int) -> Image:
	var img: Image = Kit.blank(28, 30)
	var cx: float = 14.0
	var rx: float = 11.0 if frame == 0 else 8.5
	var ry: float = 9.0 if frame == 0 else 10.5
	var rim: int = 12 if frame == 0 else 13
	# the dome: the top half of a lit ball
	Kit.ball(img, cx, float(rim) - 1.0, rx, ry, BELL)
	img.fill_rect(Rect2i(0, rim, 28, 30 - rim), Color(0, 0, 0, 0))
	# tendrils trailing under it
	for i: int in range(6):
		var x0: float = cx - rx * 0.8 + float(i) * (rx * 1.6 / 5.0)
		var spread: float = (x0 - cx) * (0.12 if frame == 0 else 0.45)
		for y: int in range(rim, 30):
			var t: float = float(y - rim) / float(30 - rim)
			var x: float = x0 + spread * t * 2.0 + sin(float(y) * 0.55 + float(i) * 1.7) * 1.2 * t
			if t > 0.6 and (y + i) % 2 == 0:
				continue
			var col: Color = MAG[2] if i % 2 == 0 else TEAL[2]
			if t > 0.5:
				col = col.darkened(0.25)
			Kit.put(img, int(x), y, col)
	# inner ribs and the frilled rim
	for r: int in range(3):
		var bx: float = cx + float(r - 1) * rx * 0.55
		Kit.line(img, Vector2(cx, float(rim) - ry + 2.0), Vector2(bx, float(rim) - 1.0), BELL[1])
	for x3: int in range(int(cx - rx) + 1, int(cx + rx)):
		Kit.put(img, x3, rim - 1, MAG[3] if x3 % 2 == 0 else BELL[2])
		if x3 % 3 == 0:
			Kit.put(img, x3, rim, MAG[2])
	# the heart: a tiny magenta star
	var hy: float = float(rim) - ry * 0.45
	Kit.disc(img, cx, hy, 2.8, MAG[2])
	Kit.disc(img, cx - 0.3, hy - 0.3, 1.4, MAG[3])
	Kit.put(img, int(cx), int(hy), Color.WHITE)
	Kit.put(img, int(cx) - 4, int(float(rim) - ry * 0.7), BELL[3])
	return img


# --- dust wraith ------------------------------------------------------------------------------------

# A hooded phantom of dark dust with two gold eyes, its ragged tail streaming behind (right).
# Frame 1 is the lunge: stretched long and low, eyes white-hot, the tail streaming further.
static func _wraith(frame: int) -> Image:
	var w: int = 28 if frame == 0 else 34
	var img: Image = Kit.blank(w, 18)
	var hx: float = 8.0
	var hy: float = 8.0
	# tail of loose dust
	var tail_len: float = float(w) - hx - 1.0
	for i: int in range(90):
		var t: float = fposmod(float(i) * 0.618, 1.0)
		var along: float = hx + 3.0 + t * tail_len
		var half: float = 2.0 + t * (5.0 if frame == 0 else 3.5)
		var off: float = sin(float(i) * 2.399) * half
		var a: float = 1.0 - t * 0.7
		var col: Color = DUST[2] if i % 3 == 0 else DUST[1]
		Kit.put(img, int(along), int(hy + 1.0 + off), Color(col.r, col.g, col.b, a))
	# cloak and hood
	Painter.poly(img, PackedVector2Array([Vector2(hx - 4.0, hy + 3.0), Vector2(hx + 8.0, hy - 3.0), Vector2(hx + 13.0, hy + 4.0), Vector2(hx + 9.0, hy + 9.0), Vector2(hx - 2.0, hy + 8.0)]), DUST[1])
	if frame == 0:
		Kit.ball(img, hx, hy, 6.0, 6.5, DUST)
	else:
		Kit.ball(img, hx, hy + 1.0, 7.0, 5.0, DUST)
	Kit.line(img, Vector2(hx - 2.0, hy - 6.0), Vector2(hx + 5.0, hy - 5.0), DUST[3])
	# the face hollow and eyes
	Kit.disc(img, hx - 1.5, hy + 0.5, 3.4, Color("#06040c"))
	var eye: Color = Color("#ffd860") if frame == 0 else Color("#fff8e0")
	Kit.put(img, int(hx) - 4, int(hy), eye)
	Kit.put(img, int(hx) - 1, int(hy), eye)
	if frame == 1:
		Kit.put(img, int(hx) - 3, int(hy), Color("#ffb040"))
		Kit.put(img, int(hx), int(hy), Color("#ffb040"))
	return img


# --- generic re-skins -------------------------------------------------------------------------------

# Scout: a little comet sprite, teal head and a magenta tail.
static func _g_scout() -> Image:
	var img: Image = Kit.blank(16, 11)
	for i: int in range(9):
		var x: int = 7 + i
		var half: int = 1 + i / 4
		for y: int in range(5 - half, 6 + half):
			if (x + y) % 2 == 0 or i < 3:
				Kit.put(img, x, y, MAG[2] if i < 5 else MAG[1])
	Kit.ball(img, 5.5, 5.5, 4.5, 4.5, TEAL)
	Kit.disc(img, 4.0, 5.5, 1.5, GOLD[3])
	return img


# Swooper: a sail moth, two translucent magenta sails on a slim teal body.
static func _g_swooper() -> Image:
	var img: Image = Kit.blank(22, 16)
	Painter.poly(img, PackedVector2Array([Vector2(6, 7), Vector2(14, 0), Vector2(20, 2), Vector2(15, 7)]), MAG[1])
	Painter.poly(img, PackedVector2Array([Vector2(6, 8), Vector2(15, 8), Vector2(20, 14), Vector2(14, 16)]), MAG[1])
	Kit.line(img, Vector2(6, 7), Vector2(14, 0), MAG[3])
	Kit.line(img, Vector2(14, 0), Vector2(20, 2), MAG[2])
	Kit.line(img, Vector2(6, 8), Vector2(14, 15), MAG[2])
	Kit.line(img, Vector2(10, 4), Vector2(17, 2), MAG[2])
	Kit.line(img, Vector2(10, 11), Vector2(17, 13), MAG[2])
	Kit.ball(img, 7.0, 7.5, 6.0, 2.5, TEAL)
	Kit.put(img, 2, 7, GOLD[3])
	return img


# Sniper: a crystal eye-star, a faceted teal gem round a gold pupil.
static func _g_sniper() -> Image:
	var img: Image = Kit.blank(17, 17)
	var c: Vector2 = Vector2(8.5, 8.5)
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in range(8):
		pts.append(c + Vector2.from_angle(float(k) * PI * 0.25 + PI / 8.0) * 8.0)
	Painter.poly(img, pts, TEAL[1])
	var inner: PackedVector2Array = PackedVector2Array()
	for k2: int in range(8):
		inner.append(c + Vector2.from_angle(float(k2) * PI * 0.25 + PI / 8.0) * 5.5)
	Painter.poly(img, inner, TEAL[2])
	Kit.line(img, pts[4], pts[5], TEAL[3])
	Kit.line(img, pts[5], pts[6], TEAL[3])
	Kit.disc(img, 6.5, 8.5, 2.6, Color("#20081c"))
	Kit.disc(img, 6.5, 8.5, 1.6, GOLD[2])
	Kit.put(img, 6, 8, GOLD[3])
	return img


# Cruiser: a nebula carrier, a long magenta hull with a teal sail fin and glowing ports.
static func _g_cruiser() -> Image:
	var img: Image = Kit.blank(32, 22)
	Painter.poly(img, PackedVector2Array([Vector2(0, 12), Vector2(8, 6), Vector2(28, 6), Vector2(32, 12), Vector2(28, 18), Vector2(8, 18)]), MAG[1])
	Painter.poly(img, PackedVector2Array([Vector2(3, 11), Vector2(9, 7), Vector2(27, 7), Vector2(29, 11)]), MAG[2])
	Kit.line(img, Vector2(8, 6), Vector2(28, 6), MAG[3])
	Painter.poly(img, PackedVector2Array([Vector2(14, 6), Vector2(22, 0), Vector2(27, 0), Vector2(24, 6)]), TEAL[1])
	Kit.line(img, Vector2(14, 6), Vector2(22, 0), TEAL[2])
	for p: int in range(4):
		Kit.rect(img, 10 + p * 5, 13, 2, 2, TEAL[3] if p % 2 == 0 else TEAL[2])
	Kit.disc(img, 4.0, 12.0, 2.0, GOLD[2])
	Kit.put(img, 3, 11, GOLD[3])
	return img


# --- PROTOSTAR GUARDIAN SOLENNE --------------------------------------------------------------------
# A newborn star still wrapped in its cradle: an edge-on dust disk crosses it as a dark lane,
# two glowing nebula lobes bloom above and below, bipolar jets shoot from its poles with
# bright knots riding out along them, and shards of a broken dusty shell orbit round it.
# Frames 0/1: the knots ride outward and the lobes shimmer; frame 2: it flares (lobes and jets
# brighten, the lane splits open on a white-hot slit).

static func _protostar(frame: int) -> Image:
	var w: int = 120
	var h: int = 156
	var img: Image = BossPainter._new_img(w, h)
	var c: Vector2 = Vector2(60.0, 78.0)
	var hot: bool = frame == 2
	# bipolar jets (behind everything)
	var jw: float = 2.5 if not hot else 3.5
	for y: int in range(2, h - 2):
		var d: float = absf(float(y) - c.y)
		if d < 6.0:
			continue
		var fade: float = 1.0 - d / 80.0
		for x: int in range(int(c.x - 5.0), int(c.x + 6.0)):
			var ax: float = absf(float(x) + 0.5 - c.x)
			if ax < jw * 0.5 + 0.2:
				img.set_pixel(x, y, Color(0.85, 1.0, 1.0, 0.75 + 0.25 * fade) if hot else Color(0.6, 0.95, 1.0, 0.55 + 0.35 * fade))
			elif ax < jw + 2.5 and Painter.bayer(x, y) < 0.45 * fade + (0.2 if hot else 0.0):
				img.set_pixel(x, y, Color(0.25, 0.75, 0.85, 0.55))
	# knots riding out along the jets
	for k: int in range(3):
		var dk: float = 24.0 + float(k) * 19.0 + float(frame % 2) * 7.0
		for sgn: float in [-1.0, 1.0]:
			var ky: float = c.y + sgn * dk
			Kit.disc(img, c.x, ky, 2.6 if hot else 2.0, TEAL[2])
			Kit.disc(img, c.x, ky, 1.2, TEAL[3])
	# nebula lobes above and below: cups opening away from the star
	var lobe_ramp: PackedColorArray = PackedColorArray([MAG[0], MAG[1], MAG[2], Color("#ff9ad8"), GOLD[2], GOLD[3]])
	for y2: int in range(h):
		var dy: float = float(y2) + 0.5 - c.y
		var d2: float = absf(dy)
		if d2 < 5.0 or d2 > 54.0:
			continue
		var half_w: float = 7.0 + d2 * 0.62 - pow(maxf(0.0, d2 - 36.0), 1.5) * 0.35
		var lump: float = sin(d2 * 0.45 + (0.0 if dy < 0.0 else 2.0)) * 2.2
		half_w += lump
		for x2: int in range(int(c.x - half_w) - 1, int(c.x + half_w) + 2):
			var ax2: float = absf(float(x2) + 0.5 - c.x)
			if ax2 > half_w:
				continue
			var edge: float = ax2 / maxf(1.0, half_w)
			# brightest near the star and along the cup's rim, darker in the hollow
			var v: float = (1.0 - d2 / 54.0) * 0.7 + edge * edge * 0.45 - 0.1
			if hot:
				v += 0.18
			# gassy filaments and knots, drifting a little between frames
			var fx: float = float(x2) + float(frame % 2) * 1.5
			v += 0.11 * sin(fx * 0.85 + float(y2) * 0.33) * sin(float(y2) * 0.41 - fx * 0.21)
			if (x2 * 7 + y2 * 13 + frame) % 23 == 0:
				v += 0.2
			if v < 0.12:
				continue
			var col: Color = Painter.ramp_pick(lobe_ramp, clampf(v, 0.0, 1.0), x2, y2)
			if img.get_pixel(x2, y2).a > 0.6 and v < 0.55:
				continue  # the jet core shows through the dim hollow
			img.set_pixel(x2, y2, col)
	# the star's glow round the middle
	Kit.disc(img, c.x, c.y, 13.0, Color(1.0, 0.75, 0.4, 0.5))
	Kit.disc(img, c.x, c.y, 9.0, GOLD[2])
	Kit.disc(img, c.x, c.y, 6.0, GOLD[3])
	# the edge-on dust disk: a dark lane straight across the star
	var lane_h: float = 7.0 if not hot else 5.0
	for y3: int in range(int(c.y - lane_h) - 1, int(c.y + lane_h) + 2):
		for x3: int in range(int(c.x - 56.0), int(c.x + 57.0)):
			var nx: float = (float(x3) + 0.5 - c.x) / 56.0
			var ny: float = (float(y3) + 0.5 - c.y) / lane_h
			var e: float = nx * nx + ny * ny
			if e > 1.0:
				continue
			var col3: Color = Color("#140a1c")
			if e > 0.82:
				col3 = Color("#3a1e46") if ny < 0.0 else Color("#22122c")
			elif absf(ny) < 0.25 and absf(nx) < 0.5 and Painter.bayer(x3, y3) < 0.3:
				col3 = Color("#2a1636")
			img.set_pixel(x3, y3, col3)
	# the star blazing out above and below the lane
	for side: float in [-1.0, 1.0]:
		var gy: float = c.y + side * (lane_h + 1.5)
		Kit.disc(img, c.x, gy, 4.0 if not hot else 5.0, GOLD[2])
		Kit.disc(img, c.x, gy, 2.4 if not hot else 3.2, GOLD[3])
		Kit.put(img, int(c.x), int(gy), Color.WHITE)
	# lit upper rim of the disk
	for x4: int in range(int(c.x - 54.0), int(c.x + 55.0)):
		var nx4: float = (float(x4) + 0.5 - c.x) / 56.0
		var yy: float = c.y - lane_h * sqrt(maxf(0.0, 1.0 - nx4 * nx4))
		var lit: Color = Color("#ff9ad8") if absf(nx4) < 0.45 else MAG[2]
		Kit.put(img, x4, int(yy), lit)
	if hot:
		for x5: int in range(int(c.x - 30.0), int(c.x + 31.0)):
			var t5: float = 1.0 - absf(float(x5) + 0.5 - c.x) / 30.0
			Kit.put(img, x5, int(c.y), Color(1.0, 1.0, 0.9, 0.4 + 0.6 * t5))
	else:
		Kit.rect(img, int(c.x) - 6, int(c.y), 12, 1, Color("#ffd890"))
	# shards of the broken dust shell orbiting round it
	var shard_ramp: PackedColorArray = PackedColorArray([Color("#0e0816"), Color("#2a1a38"), Color("#4a3260"), Color("#7a5a98"), Color("#ffc8f0")])
	for s: int in range(6):
		var a: float = float(s) * TAU / 6.0 + 0.35 + float(frame % 2) * 0.12
		var r: float = 50.0 + float(s % 2) * 4.0
		var p: Vector2 = c + Vector2(cos(a) * r * 0.95, sin(a) * r * 1.15)
		if p.x < 6.0 or p.x > float(w) - 6.0 or p.y < 6.0 or p.y > float(h) - 6.0:
			continue
		Painter.crystal(img, p.x, p.y, a + PI * 0.5, 9.0 + float(s % 3) * 2.0, 5.0, shard_ramp)
	return img
