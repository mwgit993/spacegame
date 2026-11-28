class_name Scenery
extends RefCounted

## 16-bit dressing for the menus (Matthew: "make the title screen and skill tree look more 16-bit
## than 8-bit, give them a lot more life and personality, show planets in the background of the
## skill tree"): gradient windows with bevelled borders, dithered planets and the painted
## STAR VIPER logo. Everything is painted into Images on first use and cached.

const INK: Color = Color("#070a1c")
## 4x4 ordered-dither thresholds: the shading steps of the planets mix through this pattern,
## like SNES-era art.
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
## Planets: radius, shading ramp (dark to light), and extras.
const PLANETS: Dictionary = {
	"gas": {"r": 30, "ramp": ["#2a120c", "#6a3018", "#b05e26", "#e09a4c", "#ffd690"], "bands": true, "spot": true},
	"ringed": {"r": 18, "ramp": ["#0c2232", "#1a5062", "#2a8e84", "#62d0ac", "#c4fbe8"], "ring": "#e0cc9c"},
	"lava": {"r": 13, "ramp": ["#260810", "#601220", "#b02828", "#ec6a2e", "#ffd060"], "craters": 6},
	"ice": {"r": 10, "ramp": ["#16244a", "#344f8e", "#7096d0", "#b4d4ff", "#ffffff"], "craters": 3},
	"moon": {"r": 5, "ramp": ["#1a1a26", "#3a3a4e", "#686880", "#9c9cb4", "#dcdcec"], "craters": 2},
}
## The logo's letters, 8 rows tall ("#" is solid).
const GLYPHS: Dictionary = {
	"S": [".######.", "##....##", "##......", ".######.", "......##", "......##", "##....##", ".######."],
	"T": ["########", "########", "...##...", "...##...", "...##...", "...##...", "...##...", "...##..."],
	"A": ["..####..", ".##..##.", "##....##", "##....##", "########", "##....##", "##....##", "##....##"],
	"R": ["#######.", "##....##", "##....##", "#######.", "##..##..", "##...##.", "##....##", "##....##"],
	"V": ["##....##", "##....##", "##....##", ".##..##.", ".##..##.", "..####..", "..####..", "...##..."],
	"I": ["####", ".##.", ".##.", ".##.", ".##.", ".##.", ".##.", "####"],
	"P": ["#######.", "##....##", "##....##", "#######.", "##......", "##......", "##......", "##......"],
	"E": ["########", "##......", "##......", "######..", "##......", "##......", "##......", "########"],
}

static var _cache: Dictionary = {}
static var _logo_img: Image = null


## A SNES-style window: a vertical gradient with a bevelled border (light along the top and
## left, dark along the bottom and right) inside a dark outline. Drop-in for a flat box of the
## same colours.
static func window_box(bg: Color, border: Color, border_w: int, margin: float) -> StyleBoxTexture:
	var bw: int = maxi(1, border_w)
	var key: String = "win_%s_%s_%d" % [bg.to_html(), border.to_html(), bw]
	if not _cache.has(key):
		var m: int = bw + 1
		var w: int = m * 2 + 4
		var h: int = 32
		var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		var top_c: Color = Color(bg.lightened(0.2), bg.a)
		var bot_c: Color = Color(bg.darkened(0.35), bg.a)
		var hi: Color = border.lightened(0.35)
		var lo: Color = border.darkened(0.3)
		for y: int in range(h):
			for x: int in range(w):
				if (x == 0 or x == w - 1) and (y == 0 or y == h - 1):
					continue
				var edge: int = mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
				var c: Color
				if edge == 0:
					c = INK
				elif edge <= bw:
					c = hi if (y <= bw and x < w - 1 - bw) or (x <= bw and y < h - 1 - bw) else lo
				else:
					c = top_c.lerp(bot_c, float(y) / float(h - 1))
				img.set_pixel(x, y, c)
		_cache[key] = ImageTexture.create_from_image(img)
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = _cache[key]
	sb.set_texture_margin_all(float(bw + 1))
	sb.set_content_margin_all(margin)
	return sb


## A dithered planet lit from the upper left. Ringed planets come with their ring.
static func planet(kind: String) -> Texture2D:
	var key: String = "planet_" + kind
	if _cache.has(key):
		return _cache[key]
	var spec: Dictionary = PLANETS[kind]
	var r: float = float(spec["r"])
	var ramp: Array[Color] = []
	for hex: Variant in spec["ramp"]:
		ramp.append(Color(String(hex)))
	var ringed: bool = spec.has("ring")
	var w: int = int(ceilf(r * (3.9 if ringed else 2.0))) + 4
	var h: int = int(ceilf(r * 2.0)) + 4
	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var cx: float = float(w) * 0.5
	var cy: float = float(h) * 0.5
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = kind.hash()
	var craters: Array[Vector3] = []
	for i: int in range(int(spec.get("craters", 0))):
		craters.append(Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6), rng.randf_range(0.12, 0.26)))
	if ringed:
		_paint_ring(img, cx, cy, r, Color(String(spec["ring"])), true)
	var light: Vector3 = Vector3(-0.55, -0.45, 0.7).normalized()
	for y: int in range(h):
		for x: int in range(w):
			var nx: float = (float(x) + 0.5 - cx) / r
			var ny: float = (float(y) + 0.5 - cy) / r
			var d2: float = nx * nx + ny * ny
			if d2 > 1.0:
				continue
			var nz: float = sqrt(1.0 - d2)
			var lum: float = clampf(Vector3(nx, ny, nz).dot(light), 0.0, 1.0)
			var v: float = 0.1 + lum * 0.95
			if bool(spec.get("bands", false)):
				v += 0.13 * sin(ny * 13.0 + sin(nx * 4.0 + ny * 2.0) * 0.8)
			if bool(spec.get("spot", false)):
				var sx: float = (nx - 0.22) / 0.22
				var sy: float = (ny - 0.32) / 0.11
				if sx * sx + sy * sy < 1.0:
					v -= 0.25
			for c: Vector3 in craters:
				var dx: float = nx - c.x
				var dy: float = ny - c.y
				var cd: float = sqrt(dx * dx + dy * dy)
				if cd < c.z:
					v -= 0.2 if cd < c.z * 0.75 else -0.1 * signf(-dx - dy)
			if d2 > 0.84 and lum > 0.35:
				v += 0.35                               # bright atmosphere rim on the lit side
			img.set_pixel(x, y, _dither(ramp, v, x, y))
	if ringed:
		_paint_ring(img, cx, cy, r, Color(String(spec["ring"])), false)
	_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


static func _dither(ramp: Array[Color], v: float, x: int, y: int) -> Color:
	var f: float = clampf(v, 0.0, 0.999) * float(ramp.size() - 1)
	var i: int = floori(f)
	var thresh: float = (float(BAYER[(y % 4) * 4 + (x % 4)]) + 0.5) / 16.0
	if f - float(i) > thresh:
		i += 1
	return ramp[clampi(i, 0, ramp.size() - 1)]


## The ring: its far half is painted before the planet, its near half after.
static func _paint_ring(img: Image, cx: float, cy: float, r: float, col: Color, back: bool) -> void:
	var inner: float = r * 1.3
	var outer: float = r * 1.92
	var tilt: float = 0.3
	var ramp: Array[Color] = [col.darkened(0.55), col.darkened(0.25), col, col.lightened(0.35)]
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = (float(y) + 0.5 - cy) / tilt
			var d: float = sqrt(dx * dx + dy * dy)
			if d < inner or d > outer:
				continue
			if (dy < 0.0) != back:
				continue
			var k: float = (d - inner) / (outer - inner)
			if absf(k - 0.38) < 0.06 or absf(k - 0.72) < 0.04:
				continue                                  # the gaps between the bands
			var v: float = 0.75 - absf(k - 0.5) * 0.6 + (0.2 if dx < 0.0 else -0.15)
			img.set_pixel(x, y, _dither(ramp, v, x, y))


## The STAR VIPER logo: chunky italic letters with a chrome gradient (sky over a bright horizon
## line, then sunset purple), bevelled edges, a dark outline and a drop shadow.
static func logo() -> Texture2D:
	if _cache.has("logo"):
		return _cache["logo"]
	var text: String = "STAR VIPER"
	var sc: int = 3
	var gh: int = 8 * sc
	var shear: float = 0.22
	var pad: int = 5
	var cols: int = 0
	for ch: String in text:
		cols += 4 if ch == " " else String((GLYPHS[ch] as Array)[0]).length() + 1
	var w: int = cols * sc + int(float(gh) * shear) + pad * 2 + 4
	var h: int = gh + pad * 2 + 4
	var mask: PackedByteArray = PackedByteArray()
	mask.resize(w * h)
	var ox: int = 0
	for ch: String in text:
		if ch == " ":
			ox += 4
			continue
		var rows: Array = GLYPHS[ch]
		for gy: int in range(rows.size()):
			var row: String = rows[gy]
			for gx: int in range(row.length()):
				if row[gx] != "#":
					continue
				for sy: int in range(sc):
					for sx: int in range(sc):
						var py: int = gy * sc + sy
						var px: int = (ox + gx) * sc + sx + pad + int(float(gh - py) * shear)
						mask[(py + pad) * w + px] = 1
		ox += (rows[0] as String).length() + 1
	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var solid: Callable = func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and mask[y * w + x] == 1
	# Drop shadow, then a 2-px outline.
	for y: int in range(h):
		for x: int in range(w):
			if solid.call(x - 3, y - 4):
				img.set_pixel(x, y, Color(0.11, 0.03, 0.22, 0.9))
	for y: int in range(h):
		for x: int in range(w):
			if solid.call(x, y):
				continue
			var near: bool = false
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					if solid.call(x + dx, y + dy):
						near = true
			if near:
				img.set_pixel(x, y, INK)
	# Chrome fill with bevelled edges.
	for y: int in range(h):
		var t: float = float(y - pad) / float(gh - 1)
		var c: Color
		if t < 0.47:
			c = Color.WHITE.lerp(Color("#62e4ff"), t / 0.47)
		elif t < 0.53:
			c = Color("#fffbe0")
		else:
			c = Color("#2a4ad8").lerp(Color("#d046ff"), (t - 0.53) / 0.47)
		for x: int in range(w):
			if not solid.call(x, y):
				continue
			var p: Color = c
			if not solid.call(x, y - 1):
				p = p.lightened(0.55)
			elif not solid.call(x, y + 1) or not solid.call(x + 1, y):
				p = p.darkened(0.35)
			elif not solid.call(x - 1, y):
				p = p.lightened(0.2)
			img.set_pixel(x, y, p)
	_logo_img = img
	_cache["logo"] = ImageTexture.create_from_image(img)
	return _cache["logo"]


## True if the logo is solid (lettering, not outline or shadow) at this pixel: where the title
## screen puts its twinkles.
static func logo_solid_at(p: Vector2i) -> bool:
	if _logo_img == null:
		logo()
	if p.x < 0 or p.y < 0 or p.x >= _logo_img.get_width() or p.y >= _logo_img.get_height():
		return false
	var c: Color = _logo_img.get_pixelv(p)
	return c.a > 0.95 and c.v > 0.5
