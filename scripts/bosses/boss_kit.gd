extends RefCounted

# Pixel painting for the animated bosses (scripts/bosses/). A boss is a rig of parts, and each
# part is painted once into an Image with these helpers: flat shapes in a few tones, then
# shade() adds a light rim along top/left edges and a dark rim along bottom/right ones, and
# outline() the 1-px dark edge every sprite in the game has. Textures are cached by key
# (cached()), built the first time a boss needs them.
#
#     const Kit = preload("res://scripts/bosses/boss_kit.gd")

const INK: Color = Color("#0a0c16")

static var _cache: Dictionary = {}


# The texture under `key`, painted by `build` (-> Image) the first time it's asked for.
static func cached(key: String, build: Callable) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var img: Image = build.call()
	var t: ImageTexture = ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


static func has(key: String) -> bool:
	return _cache.has(key)


static func blank(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


static func put(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var x0: int = maxi(0, x)
	var y0: int = maxi(0, y)
	var x1: int = mini(img.get_width(), x + w)
	var y1: int = mini(img.get_height(), y + h)
	for yy: int in range(y0, y1):
		for xx: int in range(x0, x1):
			img.set_pixel(xx, yy, c)


static func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y: int in range(int(floorf(cy - ry)), int(ceilf(cy + ry)) + 1):
		for x: int in range(int(floorf(cx - rx)), int(ceilf(cx + rx)) + 1):
			var nx: float = (float(x) + 0.5 - cx) / rx
			var ny: float = (float(y) + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				put(img, x, y, c)


# Ellipse shaded like a ball lit from the upper left, in the 4 tones of tones(base).
static func ball(img: Image, cx: float, cy: float, rx: float, ry: float, base: Color) -> void:
	var t: Array[Color] = tones(base)
	for y: int in range(int(floorf(cy - ry)), int(ceilf(cy + ry)) + 1):
		for x: int in range(int(floorf(cx - rx)), int(ceilf(cx + rx)) + 1):
			var nx: float = (float(x) + 0.5 - cx) / rx
			var ny: float = (float(y) + 0.5 - cy) / ry
			var d: float = nx * nx + ny * ny
			if d > 1.0:
				continue
			var v: float = (1.0 - d) * 0.55 + (-nx * 0.45 - ny * 0.65) * 0.55
			var idx: int = 0
			if v > 0.62:
				idx = 3
			elif v > 0.3:
				idx = 2
			elif v > 0.0:
				idx = 1
			put(img, x, y, t[idx])


# Filled polygon (even-odd scanline).
static func poly(img: Image, pts: PackedVector2Array, c: Color) -> void:
	if pts.size() < 3:
		return
	var y_min: float = pts[0].y
	var y_max: float = pts[0].y
	for p: Vector2 in pts:
		y_min = minf(y_min, p.y)
		y_max = maxf(y_max, p.y)
	for y: int in range(int(floorf(y_min)), int(ceilf(y_max)) + 1):
		var sy: float = float(y) + 0.5
		var xs: Array[float] = []
		for i: int in range(pts.size()):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % pts.size()]
			if (a.y <= sy and b.y > sy) or (b.y <= sy and a.y > sy):
				xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k: int = 0
		while k + 1 < xs.size():
			for x: int in range(int(roundf(xs[k])), int(roundf(xs[k + 1]))):
				put(img, x, y, c)
			k += 2


static func line(img: Image, a: Vector2, b: Vector2, c: Color, width: float = 1.0) -> void:
	var steps: int = int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	var r: float = (width - 1.0) * 0.5
	for i: int in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(steps))
		if r <= 0.0:
			put(img, int(floorf(p.x)), int(floorf(p.y)), c)
		else:
			ellipse(img, p.x, p.y, r + 0.5, r + 0.5, c)


# A glowing orb: outer halo, mid ring and hot centre.
static func glow(img: Image, cx: float, cy: float, r: float, outer: Color, mid: Color, inner: Color) -> void:
	ellipse(img, cx, cy, r, r, outer)
	ellipse(img, cx, cy, r * 0.68, r * 0.68, mid)
	ellipse(img, cx, cy, maxf(1.0, r * 0.34), maxf(1.0, r * 0.34), inner)


# An armour plate: base fill, bright top/left bevel, dark bottom/right bevel, optional rivets.
static func plate(img: Image, x: int, y: int, w: int, h: int, base: Color, rivets: bool = false) -> void:
	var t: Array[Color] = tones(base)
	rect(img, x, y, w, h, t[1])
	rect(img, x, y, w, 1, t[2])
	rect(img, x, y, 1, h, t[2])
	rect(img, x, y + h - 1, w, 1, t[0])
	rect(img, x + w - 1, y, 1, h, t[0])
	if rivets and w >= 8 and h >= 6:
		for p: Vector2i in [Vector2i(x + 2, y + 2), Vector2i(x + w - 3, y + 2), Vector2i(x + 2, y + h - 3), Vector2i(x + w - 3, y + h - 3)]:
			put(img, p.x, p.y, t[3])


# Rim light pass: opaque pixels with open space above or to the left get lighter, ones with open
# space below or to the right get darker. Skips pixels brighter than `skip_above` (glows, eyes).
static func shade(img: Image, light: float = 0.22, dark: float = 0.3, skip_above: float = 0.93) -> void:
	var src: Image = img.duplicate() as Image
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y: int in range(h):
		for x: int in range(w):
			var c: Color = src.get_pixel(x, y)
			if c.a < 0.5 or c.v > skip_above:
				continue
			var up: bool = y == 0 or src.get_pixel(x, y - 1).a < 0.5
			var left: bool = x == 0 or src.get_pixel(x - 1, y).a < 0.5
			var down: bool = y == h - 1 or src.get_pixel(x, y + 1).a < 0.5
			var right: bool = x == w - 1 or src.get_pixel(x + 1, y).a < 0.5
			if up or left:
				img.set_pixel(x, y, Color(c.lightened(light), c.a))
			elif down or right:
				img.set_pixel(x, y, Color(c.darkened(dark), c.a))


static func _solid(img: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return false
	return img.get_pixel(x, y).a > 0.5


# The image with a 1-px dark outline round every opaque pixel (2 px larger each way).
static func outline(img: Image, c: Color = INK) -> Image:
	var sw: int = img.get_width()
	var sh: int = img.get_height()
	var out: Image = blank(sw + 2, sh + 2)
	out.blit_rect(img, Rect2i(0, 0, sw, sh), Vector2i(1, 1))
	for y: int in range(sh + 2):
		for x: int in range(sw + 2):
			if _solid(img, x - 1, y - 1):
				continue
			if _solid(img, x - 2, y - 1) or _solid(img, x, y - 1) or _solid(img, x - 1, y - 2) or _solid(img, x - 1, y):
				out.set_pixel(x, y, c)
	return out


# shade() then outline(): the finishing pass for a solid part.
static func finish(img: Image) -> Image:
	shade(img)
	return outline(img)


# [dark, mid, light, highlight] around a base colour.
static func tones(base: Color) -> Array[Color]:
	return [base.darkened(0.42), base, base.lightened(0.28), base.lightened(0.62)]


static func flip_h(img: Image) -> Image:
	var out: Image = img.duplicate() as Image
	out.flip_x()
	return out


static func flip_v(img: Image) -> Image:
	var out: Image = img.duplicate() as Image
	out.flip_y()
	return out
