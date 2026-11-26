extends RefCounted

# Pre-renders the static layers of every stage background into Images, once per stage.
# StarfieldBg turns them into textures and scrolls them; only the animated parts are drawn
# per frame. Everything here is pure (no scene access, no shared state).
#
# Horizontal strips are tileable: every primitive wraps x around the image width, so a layer
# can scroll forever. Colors are picked from small per-stage ramps and blended with a 4x4
# Bayer dither instead of smooth gradients, to keep the 16-bit look.
#
# Each build_*() returns a Dictionary of Images ("sky", "far", ...) plus metadata arrays
# (positions of lights, vents, glints...) in that layer's texture coordinates.

const BAYER: PackedFloat32Array = [
	0.03125, 0.53125, 0.15625, 0.65625,
	0.78125, 0.28125, 0.90625, 0.40625,
	0.21875, 0.71875, 0.09375, 0.59375,
	0.96875, 0.46875, 0.84375, 0.34375,
]

const CLEAR: Color = Color(0.0, 0.0, 0.0, 0.0)


static func build(theme: String) -> Dictionary:
	match theme:
		"space":
			return build_space()
		"starcruiser":
			return build_starcruiser()
		"planet_base":
			return build_cloud()
		"forest":
			return build_forest()
		"ice":
			return build_ice()
		"volcano":
			return build_volcano()
		"abyss":
			return build_abyss()
		"cyber":
			return build_cyber()
	return build_space()


# ---------------------------------------------------------------------------------------------
# Primitives
# ---------------------------------------------------------------------------------------------

static func bayer(x: int, y: int) -> float:
	return BAYER[(y & 3) * 4 + (x & 3)]


static func new_img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


# Horizontal run x0..x1 (inclusive) on row y, wrapping around the image width.
static func span(img: Image, x0: int, x1: int, y: int, c: Color) -> void:
	if y < 0 or y >= img.get_height() or x1 < x0:
		return
	var w: int = img.get_width()
	var n: int = x1 - x0 + 1
	if n >= w:
		img.fill_rect(Rect2i(0, y, w, 1), c)
		return
	var a: int = posmod(x0, w)
	if a + n <= w:
		img.fill_rect(Rect2i(a, y, n, 1), c)
	else:
		img.fill_rect(Rect2i(a, y, w - a, 1), c)
		img.fill_rect(Rect2i(0, y, n - (w - a), 1), c)


static func rect(img: Image, x: int, y: int, rw: int, rh: int, c: Color) -> void:
	var y0: int = maxi(0, y)
	var y1: int = mini(img.get_height(), y + rh)
	if y1 <= y0 or rw <= 0:
		return
	var w: int = img.get_width()
	if rw >= w:
		img.fill_rect(Rect2i(0, y0, w, y1 - y0), c)
		return
	var a: int = posmod(x, w)
	if a + rw <= w:
		img.fill_rect(Rect2i(a, y0, rw, y1 - y0), c)
	else:
		img.fill_rect(Rect2i(a, y0, w - a, y1 - y0), c)
		img.fill_rect(Rect2i(0, y0, rw - (w - a), y1 - y0), c)


static func px(img: Image, x: int, y: int, c: Color) -> void:
	if y >= 0 and y < img.get_height():
		img.set_pixel(posmod(x, img.get_width()), y, c)


static func get_px(img: Image, x: int, y: int) -> Color:
	if y < 0 or y >= img.get_height():
		return CLEAR
	return img.get_pixel(posmod(x, img.get_width()), y)


# Opaque blend of c over the existing pixel (amount a), result stays opaque if dst was.
static func blend_px(img: Image, x: int, y: int, c: Color, a: float) -> void:
	if y < 0 or y >= img.get_height():
		return
	var xx: int = posmod(x, img.get_width())
	var d: Color = img.get_pixel(xx, y)
	if d.a <= 0.0:
		img.set_pixel(xx, y, Color(c.r, c.g, c.b, a))
		return
	var o: Color = d.lerp(c, a)
	o.a = d.a
	img.set_pixel(xx, y, o)


static func vline(img: Image, x: int, y0: int, y1: int, c: Color) -> void:
	rect(img, x, mini(y0, y1), 1, absi(y1 - y0) + 1, c)


static func line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	var x: int = x0
	var y: int = y0
	for _guard: int in range(4096):
		px(img, x, y, c)
		if x == x1 and y == y1:
			return
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy


static func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	for y: int in range(floori(cy - ry), ceili(cy + ry) + 1):
		var dy: float = (float(y) + 0.5 - cy) / ry
		if absf(dy) > 1.0:
			continue
		var hw: float = rx * sqrt(1.0 - dy * dy)
		span(img, ceili(cx - hw - 0.5), floori(cx + hw - 0.5), y, c)


static func disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	ellipse(img, cx, cy, r, r, c)


# Scanline polygon fill (even-odd), wrapping x.
static func poly(img: Image, pts: PackedVector2Array, c: Color) -> void:
	var n: int = pts.size()
	if n < 3:
		return
	var ymin: float = pts[0].y
	var ymax: float = pts[0].y
	for p: Vector2 in pts:
		ymin = minf(ymin, p.y)
		ymax = maxf(ymax, p.y)
	var xs: PackedFloat32Array = PackedFloat32Array()
	for y: int in range(floori(ymin), ceili(ymax) + 1):
		var sy: float = float(y) + 0.5
		xs.clear()
		for i: int in range(n):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % n]
			if (a.y <= sy and b.y > sy) or (b.y <= sy and a.y > sy):
				xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k: int = 0
		while k + 1 < xs.size():
			span(img, ceili(xs[k] - 0.5), floori(xs[k + 1] - 0.5), y, c)
			k += 2


# Banded vertical gradient between palette colors. Each band is solid and only its last
# `soft` fraction dithers into the next color.
static func vgrad(img: Image, y0: int, y1: int, cols: PackedColorArray, soft: float = 0.4) -> void:
	var w: int = img.get_width()
	var n: int = cols.size()
	var rows: int = maxi(1, y1 - y0 - 1)
	for y: int in range(maxi(0, y0), mini(img.get_height(), y1)):
		var t: float = float(y - y0) / float(rows) * float(n - 1)
		var i: int = clampi(floori(t), 0, n - 2)
		var g: float = clampf((t - float(i) - (1.0 - soft)) / soft, 0.0, 1.0)
		if g <= 0.0:
			img.fill_rect(Rect2i(0, y, w, 1), cols[i])
		elif g >= 1.0:
			img.fill_rect(Rect2i(0, y, w, 1), cols[i + 1])
		else:
			for x: int in range(w):
				img.set_pixel(x, y, cols[i + 1] if bayer(x, y) < g else cols[i])


# Dithered pick from a ramp: v in 0..1 maps onto ramp indices with ordered dithering.
static func ramp_pick(ramp: PackedColorArray, v: float, x: int, y: int) -> Color:
	var n: int = ramp.size()
	var idx: int = clampi(floori(clampf(v, 0.0, 1.0) * float(n - 1) + bayer(x, y)), 0, n - 1)
	return ramp[idx]


# Tileable (horizontally, period w) fractal value noise, values roughly 0..1.
static func noise_field(w: int, h: int, cell: int, octaves: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(w * h)
	var amp: float = 1.0
	var total: float = 0.0
	var c: int = cell
	for _o: int in range(octaves):
		var gw: int = maxi(1, w / c)
		var gh: int = h / c + 2
		var lat: PackedFloat32Array = PackedFloat32Array()
		lat.resize(gw * gh)
		for i: int in range(lat.size()):
			lat[i] = rng.randf()
		var inv: float = 1.0 / float(c)
		for y: int in range(h):
			var fy: float = float(y) * inv
			var yi: int = int(fy)
			var ty: float = fy - float(yi)
			ty = ty * ty * (3.0 - 2.0 * ty)
			var r0: int = yi * gw
			var r1: int = r0 + gw
			var row: int = y * w
			for x: int in range(w):
				var fx: float = float(x) * inv
				var xi: int = int(fx)
				var tx: float = fx - float(xi)
				tx = tx * tx * (3.0 - 2.0 * tx)
				var xa: int = xi % gw
				var xb: int = (xi + 1) % gw
				var top: float = lerpf(lat[r0 + xa], lat[r0 + xb], tx)
				var bot: float = lerpf(lat[r1 + xa], lat[r1 + xb], tx)
				out[row + x] += lerpf(top, bot, ty) * amp
		total += amp
		amp *= 0.5
		c = maxi(1, c / 2)
	var inv_total: float = 1.0 / total
	for i: int in range(out.size()):
		out[i] *= inv_total
	return out


# Native tileable fractal noise (FastNoiseLite), normalized to 0..1, as one byte per pixel
# (read as byte / 255.0). Much faster than noise_field() for big layers.
static func fast_field(w: int, h: int, period: float, octaves: int, seed_v: int) -> PackedByteArray:
	var n: FastNoiseLite = FastNoiseLite.new()
	n.seed = seed_v
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 1.0 / period
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = octaves
	var img: Image = n.get_seamless_image(w, h)
	if img.get_format() != Image.FORMAT_L8:
		img.convert(Image.FORMAT_L8)
	return img.get_data()


# A dithered light wedge radiating from `origin` (sun rays, god rays). Only pixels inside the
# wedge are visited.
static func ray_wedge(img: Image, origin: Vector2, ang: float, half_w: float, length: float, c: Color, density: float) -> void:
	var d0: Vector2 = Vector2(cos(ang - half_w), sin(ang - half_w)) * length
	var d1: Vector2 = Vector2(cos(ang + half_w), sin(ang + half_w)) * length
	var pts: PackedVector2Array = PackedVector2Array([origin, origin + d0, origin + d1])
	var ymin: int = maxi(0, floori(minf(origin.y, minf(origin.y + d0.y, origin.y + d1.y))))
	var ymax: int = mini(img.get_height() - 1, ceili(maxf(origin.y, maxf(origin.y + d0.y, origin.y + d1.y))))
	var w: int = img.get_width()
	var axis: Vector2 = Vector2(cos(ang), sin(ang))
	var xs: PackedFloat32Array = PackedFloat32Array()
	for y: int in range(ymin, ymax + 1):
		var sy: float = float(y) + 0.5
		xs.clear()
		for i: int in range(3):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % 3]
			if (a.y <= sy and b.y > sy) or (b.y <= sy and a.y > sy):
				xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
		if xs.size() < 2:
			continue
		xs.sort()
		for x: int in range(maxi(0, ceili(xs[0] - 0.5)), mini(w - 1, floori(xs[1] - 0.5)) + 1):
			var v: Vector2 = Vector2(float(x) + 0.5, sy) - origin
			var along: float = v.dot(axis)
			if along <= 12.0:
				continue
			var across: float = absf(v.cross(axis)) / (along * tan(half_w))
			var e: float = (1.0 - across * 0.6) * clampf(1.0 - along / length, 0.0, 1.0)
			if bayer(x, y) < e * density:
				img.set_pixel(x, y, c)


# Periodic 1-D profile over width w (sum of integer-frequency sines), for tileable skylines.
static func profile(w: int, rng: RandomNumberGenerator, terms: int, base_freq: int, rough: float) -> PackedFloat32Array:
	var amps: PackedFloat32Array = PackedFloat32Array()
	var freqs: PackedInt32Array = PackedInt32Array()
	var phases: PackedFloat32Array = PackedFloat32Array()
	var a: float = 1.0
	var f: int = base_freq
	for _i: int in range(terms):
		amps.append(a * rng.randf_range(0.6, 1.0))
		freqs.append(f + rng.randi_range(0, 1))
		phases.append(rng.randf_range(0.0, TAU))
		a *= rough
		f *= 2
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(w)
	var norm: float = 0.0
	for k: int in range(terms):
		norm += amps[k]
	for x: int in range(w):
		var v: float = 0.0
		for k: int in range(terms):
			v += amps[k] * sin(TAU * float(freqs[k]) * float(x) / float(w) + phases[k])
		out[x] = 0.5 + 0.5 * v / norm
	return out


# Mask helpers (PackedByteArray w*h, wrapping x) used for clouds and leaf clusters.
static func mask_disc(mask: PackedByteArray, w: int, h: int, cx: float, cy: float, r: float, y_cut: float) -> void:
	for y: int in range(maxi(0, floori(cy - r)), mini(h, ceili(cy + r) + 1)):
		if float(y) > y_cut:
			continue
		var dy: float = float(y) + 0.5 - cy
		if absf(dy) > r:
			continue
		var hw: float = sqrt(r * r - dy * dy)
		for x: int in range(ceili(cx - hw - 0.5), floori(cx + hw - 0.5) + 1):
			mask[y * w + posmod(x, w)] = 1


static func mask_at(mask: PackedByteArray, w: int, h: int, x: int, y: int) -> bool:
	if y < 0 or y >= h:
		return false
	return mask[y * w + posmod(x, w)] != 0


# Colors a cloud mask, lit from the upper left: bright rim on top, a lit band below it that
# fades into the body with dithering, darker right-hand edges and a shadowed flat base.
static func paint_cloud_mask(img: Image, mask: PackedByteArray, w: int, h: int, y_off: int, ramp: PackedColorArray) -> void:
	# Rows past the bottom count as cloud, so a layer's cut-off base is not shaded.
	var nr: int = ramp.size() - 1
	for x: int in range(w):
		var xl: int = posmod(x - 1, w)
		var xr: int = (x + 1) % w
		var xr2: int = (x + 2) % w
		var depth: int = 0
		for y: int in range(h):
			var row: int = y * w
			if mask[row + x] == 0:
				depth = 0
				continue
			var lit: float = 0.5
			if depth == 0:
				lit = 1.0
			elif depth <= 2:
				lit = 0.82
			elif depth <= 8:
				lit = 0.72 - 0.044 * float(depth - 3)
			if mask[row + xr] == 0 or (y > 0 and mask[row - w + xr2] == 0):
				lit -= 0.22
			elif depth > 0 and mask[row + xl] == 0:
				lit += 0.15
			if y + 1 < h and mask[row + w + x] == 0:
				lit = minf(lit, 0.05)
			elif y + 3 < h and mask[row + 3 * w + x] == 0:
				lit = minf(lit, 0.28)
			elif y + 6 < h and mask[row + 6 * w + x] == 0:
				lit = minf(lit, 0.42)
			var idx: int = clampi(floori(clampf(lit, 0.0, 1.0) * float(nr) + BAYER[(y & 3) * 4 + (x & 3)]), 0, nr)
			img.set_pixel(x, y + y_off, ramp[idx])
			depth += 1


# A puffy cumulus: discs along its width, bottoms cut flat at base_y.
static func cloud_puff(mask: PackedByteArray, w: int, h: int, cx: float, base_y: float, width: float, height: float, rng: RandomNumberGenerator, flat_base: bool = true) -> void:
	var y_cut: float = base_y if flat_base else 9999.0
	var n: int = maxi(2, int(width / 9.0))
	for i: int in range(n):
		var t: float = (float(i) + 0.5) / float(n)
		var hump: float = sin(t * PI)
		var r: float = height * (0.45 + 0.55 * hump) * rng.randf_range(0.75, 1.05)
		var x: float = cx - width * 0.5 + t * width + rng.randf_range(-3.0, 3.0)
		mask_disc(mask, w, h, x, base_y - r * 0.55, r, y_cut)
	mask_disc(mask, w, h, cx + rng.randf_range(-width * 0.15, width * 0.15), base_y - height * 0.95, height * 0.55, y_cut)


# Shaded faceted shape helpers ------------------------------------------------------------------

static func crystal(img: Image, bx: float, by: float, ang: float, length: float, width: float, ramp: PackedColorArray) -> Vector2:
	# Elongated hexagonal prism pointing along `ang` (0 = straight up). Returns the tip.
	var dir: Vector2 = Vector2(sin(ang), -cos(ang))
	var nrm: Vector2 = Vector2(dir.y * -1.0, dir.x)
	var base: Vector2 = Vector2(bx, by)
	var hw: float = width * 0.5
	var shoulder: Vector2 = base + dir * (length - width * 0.9)
	var tip: Vector2 = base + dir * length
	var l0: Vector2 = base - nrm * hw
	var l1: Vector2 = shoulder - nrm * hw
	var r0: Vector2 = base + nrm * hw
	var r1: Vector2 = shoulder + nrm * hw
	var m0: Vector2 = base - nrm * (hw * 0.15)
	var m1: Vector2 = shoulder - nrm * (hw * 0.15)
	# dark outline body
	poly(img, PackedVector2Array([l0 - nrm, l1 - nrm, tip - dir * -1.0, r1 + nrm, r0 + nrm]), ramp[0])
	# right (shadow) face, center face, left (lit) face
	poly(img, PackedVector2Array([m0, m1, tip, r1, r0]), ramp[1])
	poly(img, PackedVector2Array([l0, l1, tip, m1, m0]), ramp[2])
	poly(img, PackedVector2Array([l0, l1, l1 + nrm * (hw * 0.35), l0 + nrm * (hw * 0.35)]), ramp[3])
	# edge highlight along the lit ridge and tip
	line(img, roundi(l1.x + nrm.x), roundi(l1.y), roundi(tip.x), roundi(tip.y), ramp[4])
	line(img, roundi(m1.x), roundi(m1.y), roundi(m0.x), roundi(m0.y), ramp[3])
	return tip


static func rock_blob(img: Image, cx: float, cy: float, r: float, ramp: PackedColorArray, rng: RandomNumberGenerator, light: Vector2) -> void:
	# Lumpy shaded boulder (used for asteroids, rocks, rubble).
	var a2: float = rng.randf_range(0.05, 0.16)
	var a3: float = rng.randf_range(0.04, 0.14)
	var a5: float = rng.randf_range(0.02, 0.08)
	var p2: float = rng.randf_range(0.0, TAU)
	var p3: float = rng.randf_range(0.0, TAU)
	var p5: float = rng.randf_range(0.0, TAU)
	var lz: float = 0.62
	var ld: Vector3 = Vector3(light.x, light.y, lz).normalized()
	for y: int in range(floori(cy - r * 1.3), ceili(cy + r * 1.3) + 1):
		for x: int in range(floori(cx - r * 1.3), ceili(cx + r * 1.3) + 1):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			var d: float = sqrt(dx * dx + dy * dy)
			var th: float = atan2(dy, dx)
			var rr: float = r * (1.0 + a2 * sin(2.0 * th + p2) + a3 * sin(3.0 * th + p3) + a5 * sin(5.0 * th + p5))
			if d > rr:
				continue
			var q: float = d / rr
			var nz: float = sqrt(maxf(0.0, 1.0 - q * q))
			var lam: float = maxf(0.0, Vector3(dx / rr, dy / rr, nz).dot(ld))
			if d > rr - 1.0:
				lam *= 0.35
			px(img, x, y, ramp_pick(ramp, lam * 0.95, x, y))


# ---------------------------------------------------------------------------------------------
# 1) OUTER ORBIT
# ---------------------------------------------------------------------------------------------

static func build_space() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1101
	var out: Dictionary = {}

	var sky: Image = new_img(480, 270)
	sky.fill(Color("#04050f"))
	vgrad(sky, 18, 258, PackedColorArray([Color("#04050f"), Color("#060818"), Color("#080b21"), Color("#0a0f2b"), Color("#0d1434")]), 0.45)
	out["sky"] = sky

	# Nebula: two-tone dithered clouds, faint enough to sit behind bullets.
	var nw: int = 768
	var nh: int = 210
	var neb: Image = new_img(nw, nh)
	var f1: PackedByteArray = fast_field(nw, nh, 90.0, 4, 11)
	var f2: PackedByteArray = fast_field(nw, nh, 200.0, 2, 12)
	var vio: PackedColorArray = PackedColorArray([Color("#0f0a24"), Color("#170e34"), Color("#211344"), Color("#2c1952"), Color("#3a2064")])
	var teal: PackedColorArray = PackedColorArray([Color("#08121f"), Color("#0b1a2c"), Color("#0f2438"), Color("#142f46"), Color("#1a3b54")])
	for y: int in range(nh):
		var ey: float = sin(PI * (float(y) + 0.5) / float(nh))
		# keep the middle band (where most fighting happens) thinner
		var band: float = 1.0 - 0.45 * exp(-pow((float(y) - 105.0) / 38.0, 2.0))
		for x: int in range(nw):
			var v: float = float(f1[y * nw + x]) / 255.0
			var m: float = clampf((v - 0.5) / 0.34, 0.0, 1.0) * ey * band
			if m <= 0.02:
				continue
			var lv: int = mini(5, floori(m * 5.0 + bayer(x, y)))
			if lv <= 0:
				continue
			var use_teal: bool = (float(f2[y * nw + x]) / 255.0 - 0.52) * 10.0 + bayer(x + 1, y + 2) > 0.5
			neb.set_pixel(x, y, teal[lv - 1] if use_teal else vio[lv - 1])
	out["nebula"] = neb

	var stars_far: Image = new_img(512, 236)
	var far_cols: PackedColorArray = PackedColorArray([Color("#1a2142"), Color("#232d58"), Color("#2f3c70"), Color("#46548e"), Color("#5f6ea8")])
	for _i: int in range(330):
		var r: float = rng.randf()
		var ci: int = 0
		if r > 0.45:
			ci = 1
		if r > 0.75:
			ci = 2
		if r > 0.92:
			ci = 3
		if r > 0.985:
			ci = 4
		px(stars_far, rng.randi_range(0, 511), rng.randi_range(0, 235), far_cols[ci])
	out["stars_far"] = stars_far

	var stars_mid: Image = new_img(512, 236)
	for _i: int in range(70):
		px(stars_mid, rng.randi_range(0, 511), rng.randi_range(0, 235), Color("#4a5c98") if rng.randf() < 0.6 else Color("#6878b4"))
	for _i: int in range(11):
		var sx: int = rng.randi_range(0, 511)
		var sy: int = rng.randi_range(4, 231)
		px(stars_mid, sx, sy, Color("#a4b4dc"))
		px(stars_mid, sx - 1, sy, Color("#46588e"))
		px(stars_mid, sx + 1, sy, Color("#46588e"))
		px(stars_mid, sx, sy - 1, Color("#46588e"))
		px(stars_mid, sx, sy + 1, Color("#46588e"))
	out["stars_mid"] = stars_mid

	# Distant ringed gas giant (ring back half, banded body, ring front half).
	var gw: int = 132
	var gh: int = 72
	var giant: Image = new_img(gw, gh)
	var gcx: float = 66.0
	var gcy: float = 36.0
	var gr: float = 17.0
	var rx: float = 50.0
	var ry: float = 10.0
	var shear: float = -0.17
	# desaturated ochre/slate so it never reads like an enemy
	var body_ramp: PackedColorArray = PackedColorArray([Color("#09080c"), Color("#131116"), Color("#1e1a20"), Color("#2b252a"), Color("#3a3234"), Color("#4c4240"), Color("#62564e")])
	var ring_cols: PackedColorArray = PackedColorArray([Color("#1c1a22"), Color("#302c34"), Color("#46404a"), Color("#3a3540")])
	var ld: Vector3 = Vector3(-0.62, -0.42, 0.66).normalized()
	for pass_i: int in range(3):
		for y: int in range(gh):
			for x: int in range(gw):
				var dx: float = float(x) + 0.5 - gcx
				var dy: float = float(y) + 0.5 - gcy
				var in_body: bool = dx * dx + dy * dy <= gr * gr
				if pass_i == 1:
					if not in_body:
						continue
					var nx: float = dx / gr
					var ny: float = dy / gr
					var nz: float = sqrt(maxf(0.0, 1.0 - nx * nx - ny * ny))
					var lam: float = maxf(0.0, Vector3(nx, ny, nz).dot(ld))
					var band_v: float = sin(ny * 9.0 + sin(nx * 3.0) * 0.6) * 0.09
					# ring shadow band across the body
					var rdy: float = dy - dx * shear
					if rdy > 2.0 and rdy < 5.0:
						lam *= 0.55
					giant.set_pixel(x, y, ramp_pick(body_ramp, lam * 0.92 + band_v, x, y))
					continue
				var rdy2: float = dy - dx * shear
				var q: float = sqrt(pow(dx / rx, 2.0) + pow(rdy2 / ry, 2.0))
				if q < 0.52 or q > 1.0:
					continue
				var front: bool = rdy2 > 0.0
				if pass_i == 0 and front:
					continue
				if pass_i == 2 and not front:
					continue
				if pass_i == 0 and in_body:
					continue
				var c: Color = ring_cols[1]
				if q < 0.6:
					c = ring_cols[0]
				elif q < 0.74:
					c = ring_cols[2]
				elif q < 0.79:
					continue
				elif q < 0.93:
					c = ring_cols[3]
				else:
					c = ring_cols[0]
				# night side of the ring is darker
				if dx > gr * 0.6 and not front:
					c = c.darkened(0.35)
				giant.set_pixel(x, y, c)
	out["giant"] = giant
	out["giant_ring"] = Vector4(rx, ry, shear, gr)

	# Planet surface strip (scrolls under the curved horizon) + static rim/shade overlay.
	var pw: int = 512
	var ph: int = 44
	var surf: Image = new_img(pw, ph)
	var land_n: PackedByteArray = fast_field(pw, ph, 30.0, 4, 13)
	var cloud_n: PackedByteArray = fast_field(pw, ph, 14.0, 3, 14)
	var ocean: PackedColorArray = PackedColorArray([Color("#081430"), Color("#0b1a3c"), Color("#0e2148")])
	var land: PackedColorArray = PackedColorArray([Color("#0d2426"), Color("#123028"), Color("#183a2c")])
	var clouds: PackedColorArray = PackedColorArray([Color("#1e2e52"), Color("#2a3e66"), Color("#36507a")])
	var haze: Color = Color("#16336a")
	for y: int in range(ph):
		var hz: float = clampf(1.0 - float(y) / 16.0, 0.0, 1.0)
		for x: int in range(pw):
			var ln: float = float(land_n[y * pw + x]) / 255.0
			var cn: float = float(cloud_n[y * pw + x]) / 255.0
			var c: Color
			if cn > 0.64 + bayer(x, y) * 0.06:
				c = ramp_pick(clouds, (cn - 0.64) * 3.5, x, y)
			elif ln > 0.56:
				c = ramp_pick(land, (ln - 0.56) * 3.5, x, y)
			else:
				c = ramp_pick(ocean, ln * 1.6, x, y)
			if hz > 0.0 and bayer(x, y) < hz * 0.85:
				c = haze
			surf.set_pixel(x, y, c)
	out["surface"] = surf

	var over: Image = new_img(480, 50)
	var pcx: float = 240.0
	var pr: float = 740.0
	var pcy: float = 218.0 + pr
	var rim: PackedColorArray = PackedColorArray([Color("#2f84ba"), Color("#2270ae"), Color("#1a5596"), Color("#153f7c"), Color("#112e62"), Color("#0e2452")])
	for x: int in range(480):
		var dxp: float = float(x) + 0.5 - pcx
		var arc_y: float = pcy - sqrt(pr * pr - dxp * dxp)
		var night: float = clampf((float(x) - 300.0) / 150.0, 0.0, 1.0)
		for k: int in range(9):
			var yy: int = floori(arc_y) - k - 210
			if yy < 0 or yy >= 50:
				continue
			var idx: int = mini(5, k)
			var dens: float = 1.0 - float(k) / 9.0
			if k <= 1 or bayer(x, yy) < dens:
				var c2: Color = rim[idx]
				if night > 0.0:
					c2 = c2.lerp(Color("#0a1430"), night * 0.85)
				over.set_pixel(x, yy, c2)
		# night-side shade over the surface below the arc
		if night > 0.0:
			for yy2: int in range(maxi(0, floori(arc_y) - 209), 50):
				if bayer(x, yy2) < night * 0.9:
					over.set_pixel(x, yy2, Color(0.01, 0.015, 0.04, 0.78))
	# city lights on the night side
	for _i: int in range(60):
		var lx: int = rng.randi_range(330, 479)
		var dxl: float = float(lx) + 0.5 - pcx
		var top: int = floori(pcy - sqrt(pr * pr - dxl * dxl)) - 210 + 2
		var ly: int = rng.randi_range(top, 49)
		if ly < 50 and ly >= 0:
			over.set_pixel(lx, ly, Color("#a07a3a") if rng.randf() < 0.7 else Color("#d0a050"))
	out["planet_over"] = over
	out["planet_arc"] = Vector3(pcx, pcy, pr)

	# Asteroids: 6 shapes x 8 rotation frames in 24px cells.
	var atl: Image = new_img(144, 192)
	var rock_ramp: PackedColorArray = PackedColorArray([Color("#0e1018"), Color("#191c28"), Color("#252a3a"), Color("#33394e"), Color("#454c64")])
	var lvec: Vector3 = Vector3(-0.6, -0.55, 0.58).normalized()
	for s: int in range(6):
		var base_r: float = rng.randf_range(4.5, 10.0)
		var amp: PackedFloat32Array = PackedFloat32Array([rng.randf_range(0.06, 0.18), rng.randf_range(0.04, 0.14), rng.randf_range(0.02, 0.08)])
		var phs: PackedFloat32Array = PackedFloat32Array([rng.randf_range(0.0, TAU), rng.randf_range(0.0, TAU), rng.randf_range(0.0, TAU)])
		var craters: Array[Vector3] = []
		for _c: int in range(rng.randi_range(1, 3)):
			craters.append(Vector3(rng.randf_range(0.0, TAU), rng.randf_range(0.2, 0.6), rng.randf_range(1.2, 2.6)))
		for rot: int in range(8):
			var ang: float = float(rot) * TAU / 8.0
			for y: int in range(24):
				for x: int in range(24):
					var dx: float = float(x) + 0.5 - 12.0
					var dy: float = float(y) + 0.5 - 12.0
					var d: float = sqrt(dx * dx + dy * dy)
					var th: float = atan2(dy, dx) - ang
					var rr: float = base_r * (1.0 + amp[0] * sin(2.0 * th + phs[0]) + amp[1] * sin(3.0 * th + phs[1]) + amp[2] * sin(5.0 * th + phs[2]))
					if d > rr:
						continue
					var q: float = d / rr
					var nz: float = sqrt(maxf(0.0, 1.0 - q * q))
					var lam: float = maxf(0.0, Vector3(dx / rr, dy / rr, nz).dot(lvec))
					for cr: Vector3 in craters:
						var cc: Vector2 = Vector2(cos(cr.x + ang), sin(cr.x + ang)) * cr.y * base_r
						var cd: float = Vector2(dx, dy).distance_to(cc)
						if cd < cr.z:
							lam *= 0.5
						elif cd < cr.z + 1.0 and dx - cc.x + dy - cc.y > 0.0:
							lam = minf(1.0, lam * 1.25)
					if d > rr - 1.0:
						lam *= 0.45
					atl.set_pixel(s * 24 + x, rot * 24 + y, ramp_pick(rock_ramp, lam * 0.95, x, y))
	out["asteroids"] = atl

	# Big near rocks (foreground silhouettes with a cold rim light).
	var near: Image = new_img(144, 44)
	var near_ramp: PackedColorArray = PackedColorArray([Color("#05060b"), Color("#090b13"), Color("#0f121d"), Color("#171c2b"), Color("#232b40")])
	for s2: int in range(3):
		rock_blob(near, 24.0 + float(s2) * 48.0, 24.0, rng.randf_range(14.0, 19.0), near_ramp, rng, Vector2(-0.7, -0.6))
	out["near_rocks"] = near

	# Far asteroid belt bands (tiny rocks).
	var belt: Image = new_img(640, 30)
	var belt_cols: PackedColorArray = PackedColorArray([Color("#161a28"), Color("#1e2334"), Color("#283044"), Color("#343d54")])
	for _i: int in range(240):
		var bx: int = rng.randi_range(0, 639)
		var by: int = clampi(int(15.0 + rng.randfn(0.0, 6.0)), 0, 29)
		var sz: int = 1
		var rr2: float = rng.randf()
		if rr2 > 0.8:
			sz = 2
		if rr2 > 0.97:
			sz = 3
		var bc: Color = belt_cols[rng.randi_range(0, 3)]
		rect(belt, bx, by, sz, sz, bc)
		if sz >= 2:
			px(belt, bx, by, bc.lightened(0.18))
			px(belt, bx + sz - 1, by + sz - 1, bc.darkened(0.4))
	out["belt"] = belt

	# Capital ship silhouettes for the distant battle.
	var ships: Image = new_img(34, 26)
	_space_ship(ships, 1, 2, 30, Color("#141b32"), Color("#222c4c"), Color("#3a5aa0"))
	_space_ship(ships, 1, 12, 22, Color("#121830"), Color("#1e2846"), Color("#3a5aa0"))
	_space_ship(ships, 1, 20, 15, Color("#10162a"), Color("#1c2440"), Color("#3a5aa0"))
	out["ships"] = ships
	return out


static func _space_ship(img: Image, x: int, y: int, length: int, body: Color, top: Color, engine: Color) -> void:
	# Wedge hull pointing right, with a superstructure and a glowing engine block.
	for i: int in range(length):
		var t: float = float(i) / float(length)
		var hh: int = int(round(lerpf(3.0, 1.0, maxf(0.0, t - 0.55) / 0.45)))
		vline(img, x + i, y + 3 - hh, y + 3 + hh, body)
		px(img, x + i, y + 3 - hh, top)
	var tower: int = x + length / 3
	rect(img, tower, y, 3, 2, top)
	px(img, tower + 1, y - 1, top)
	vline(img, x, y + 2, y + 4, engine)


# ---------------------------------------------------------------------------------------------
# 2) STARCRUISER - reactor corridor
# ---------------------------------------------------------------------------------------------

static func build_starcruiser() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2202
	var out: Dictionary = {}

	var sky: Image = new_img(480, 270)
	sky.fill(Color("#080b12"))
	vgrad(sky, 28, 258, PackedColorArray([Color("#080b12"), Color("#0a0e17"), Color("#0c111c"), Color("#0a0e17")]), 0.5)
	out["sky"] = sky

	# Far reactor hall seen through the windows (y 64..214 on screen).
	var hw: int = 640
	var hh: int = 150
	var hall: Image = new_img(hw, hh)
	vgrad(hall, 0, hh, PackedColorArray([Color("#0b0f19"), Color("#0d121e"), Color("#0f1522"), Color("#0c111c")]), 0.5)
	# background lattice
	for gx: int in range(0, hw, 40):
		rect(hall, gx, 0, 2, hh, Color("#0e1320"))
		for gy: int in range(0, hh, 20):
			line(hall, gx, gy, gx + 20, gy + 20, Color("#0d121e"))
	var cores: PackedVector2Array = PackedVector2Array()
	var cyl: PackedColorArray = PackedColorArray([Color("#10161f"), Color("#151d2b"), Color("#1c2638"), Color("#243046"), Color("#2a3850"), Color("#243046"), Color("#1c2638"), Color("#151d2b"), Color("#10161f")])
	for k: int in range(4):
		var cx: int = 44 + k * 160
		var cw: int = 46
		for i: int in range(cw):
			var t: float = float(i) / float(cw - 1)
			var ci: int = clampi(int(round(t * 8.0)), 0, 8)
			rect(hall, cx - cw / 2 + i, 0, 1, hh, cyl[ci])
		for ry: int in range(6, hh, 18):
			rect(hall, cx - cw / 2, ry, cw, 1, Color("#33425c"))
			rect(hall, cx - cw / 2, ry + 1, cw, 1, Color("#0c111a"))
			for bolt: int in range(-cw / 2 + 3, cw / 2 - 2, 6):
				px(hall, cx + bolt, ry + 3, Color("#2a3650"))
		# glowing core slit
		rect(hall, cx - 4, 0, 8, hh, Color("#1a0f0c"))
		rect(hall, cx - 3, 0, 6, hh, Color("#4a2410"))
		rect(hall, cx - 1, 0, 2, hh, Color("#7a3c14"))
		cores.append(Vector2(float(cx), 0.0))
	# catwalk trusses across the hall
	var lights: PackedVector3Array = PackedVector3Array()
	for cy: int in [38, 116]:
		rect(hall, 0, cy, hw, 1, Color("#222c40"))
		rect(hall, 0, cy + 1, hw, 1, Color("#151c2a"))
		rect(hall, 0, cy + 6, hw, 1, Color("#1a2232"))
		for tx: int in range(0, hw, 8):
			line(hall, tx, cy + 2, tx + 4, cy + 5, Color("#141b28"))
			line(hall, tx + 4, cy + 5, tx + 8, cy + 2, Color("#141b28"))
		for lx: int in range(12, hw, 32):
			lights.append(Vector3(float(lx), float(cy - 1), float(rng.randi_range(0, 2))))
	# piston housings between reactors
	var pistons: PackedVector2Array = PackedVector2Array()
	for k2: int in range(4):
		var px0: int = 124 + k2 * 160
		rect(hall, px0 - 9, 124, 18, 26, Color("#141b28"))
		rect(hall, px0 - 9, 124, 18, 1, Color("#2a3448"))
		rect(hall, px0 - 7, 128, 14, 2, Color("#5a4418"))
		pistons.append(Vector2(float(px0), 124.0))
	out["hall"] = hall
	out["cores"] = cores
	out["hall_lights"] = lights
	out["pistons"] = pistons

	# Mid wall: opaque panels top and bottom, window bays between pillars (y 46..236 on screen).
	var ww: int = 512
	var wh: int = 190
	var wall: Image = new_img(ww, wh)
	var panel: Color = Color("#182030")
	var seam_d: Color = Color("#0c1018")
	var seam_l: Color = Color("#263046")
	rect(wall, 0, 0, ww, 24, panel)
	rect(wall, 0, 154, ww, 36, panel)
	for sx: int in range(0, ww, 32):
		vline(wall, sx, 0, 23, seam_d)
		vline(wall, sx + 1, 0, 23, seam_l)
		vline(wall, sx, 154, 189, seam_d)
		vline(wall, sx + 1, 154, 189, seam_l)
		for ry2: int in [3, 20, 158, 186]:
			px(wall, sx + 4, ry2, Color("#2c3850"))
			px(wall, sx + 28, ry2, Color("#2c3850"))
	rect(wall, 0, 10, ww, 1, seam_d)
	rect(wall, 0, 11, ww, 1, seam_l)
	# amber light strip along the top band
	rect(wall, 0, 16, ww, 3, Color("#141822"))
	for lx2: int in range(4, ww, 8):
		rect(wall, lx2, 17, 4, 1, Color("#4a3416"))
	# hazard stripes at the bottom of the wall
	for hx: int in range(ww):
		for hy: int in range(184, 190):
			var stripe: bool = posmod(hx + hy, 10) < 5
			px(wall, hx, hy, Color("#5a4816") if stripe else Color("#16150f"))
	var wall_lights: PackedVector3Array = PackedVector3Array()
	for k3: int in range(4):
		var bx: int = k3 * 128
		# window bay frame (between pillars)
		var wx0: int = bx + 28
		var wx1: int = bx + 126
		rect(wall, wx0, 24, wx1 - wx0, 130, Color(0.02, 0.05, 0.11, 0.30))
		rect(wall, wx0, 24, wx1 - wx0, 3, Color("#34425c"))
		rect(wall, wx0, 27, wx1 - wx0, 1, Color("#1e283a"))
		rect(wall, wx0, 151, wx1 - wx0, 3, Color("#0c1018"))
		rect(wall, wx0, 24, 3, 130, Color("#2a3650"))
		rect(wall, wx1 - 3, 24, 3, 130, Color("#0e1320"))
		# mullion
		rect(wall, (wx0 + wx1) / 2 - 1, 27, 3, 124, Color("#141b28"))
		px(wall, (wx0 + wx1) / 2 - 1, 27, Color("#2a3650"))
		# glass reflections
		for rk: int in range(2):
			var rx0: int = wx0 + 10 + rk * 52
			for ry3: int in range(28, 150):
				var off: int = (150 - ry3) / 3
				for wdt: int in range(3):
					blend_px(wall, rx0 + off + wdt, ry3, Color("#9ec8ff"), 0.05)
		# pillar
		var pl: PackedColorArray = PackedColorArray([Color("#0c1018"), Color("#141c2a"), Color("#1e283a"), Color("#283448"), Color("#1e283a"), Color("#141c2a")])
		for i2: int in range(28):
			var pci: int = clampi(int(float(i2) / 27.0 * 5.0 + 0.5), 0, 5)
			rect(wall, bx + i2, 24, 1, 130, pl[pci])
		rect(wall, bx + 9, 24, 4, 130, Color("#202a3c"))
		rect(wall, bx + 10, 24, 1, 130, Color("#34425c"))
		for py2: int in range(30, 150, 22):
			rect(wall, bx + 8, py2, 6, 3, Color("#2c3850"))
		# warning lamp on each pillar
		wall_lights.append(Vector3(float(bx + 20), 40.0, 0.0))
		# console in the lower band
		var cx2: int = bx + 64
		rect(wall, cx2 - 17, 158, 34, 22, Color("#0e131e"))
		rect(wall, cx2 - 16, 159, 32, 20, Color("#222c3e"))
		rect(wall, cx2 - 12, 161, 24, 10, Color("#081c24"))
		for ln: int in range(4):
			var ll: int = rng.randi_range(6, 20)
			rect(wall, cx2 - 11, 162 + ln * 2, ll, 1, Color("#16505c"))
		for b: int in range(5):
			wall_lights.append(Vector3(float(cx2 - 11 + b * 5), 174.0, float(rng.randi_range(1, 3))))
		# vent grille
		for gy2: int in range(0, 8, 2):
			rect(wall, bx + 104, 160 + gy2, 16, 1, Color("#0c1018"))
	out["wall"] = wall
	out["wall_lights"] = wall_lights

	# Near ceiling pipe bundle (screen y 28..46).
	var pt: Image = new_img(512, 18)
	_pipe(pt, 0, 7, PackedColorArray([Color("#1a2130"), Color("#2a3446"), Color("#3a4660"), Color("#2a3446"), Color("#1a2030"), Color("#10141e"), Color("#0a0d14")]))
	_pipe(pt, 7, 6, PackedColorArray([Color("#202838"), Color("#34405a"), Color("#28324a"), Color("#1a2030"), Color("#10141e"), Color("#0a0d14")]))
	rect(pt, 0, 13, 512, 5, Color("#0c1018"))
	rect(pt, 0, 13, 512, 1, Color("#1e2636"))
	var vents_top: PackedVector2Array = PackedVector2Array()
	for fx: int in range(0, 512, 64):
		rect(pt, fx, 0, 4, 13, Color("#3a4660"))
		rect(pt, fx + 3, 0, 1, 13, Color("#141a26"))
	for vx: int in [40, 200, 330, 460]:
		rect(pt, vx - 4, 13, 9, 4, Color("#05070b"))
		for gx2: int in range(vx - 4, vx + 5, 2):
			vline(pt, gx2, 13, 16, Color("#1e2636"))
		vents_top.append(Vector2(float(vx), 17.0))
	# valve wheels
	for vw: int in [120, 380]:
		disc(pt, float(vw), 6.0, 5.0, Color("#6a2a1a"))
		disc(pt, float(vw), 6.0, 3.0, Color("#0c1018"))
		disc(pt, float(vw), 6.0, 1.0, Color("#8a3a22"))
	out["pipes_top"] = pt
	out["vents_top"] = vents_top

	# Near floor: conveyor belt + pipe bundle (screen y 226..258).
	var pb: Image = new_img(512, 32)
	rect(pb, 0, 0, 512, 2, Color("#2a3446"))
	rect(pb, 0, 2, 512, 4, Color("#141a24"))
	for rx3: int in range(0, 512, 8):
		disc(pb, float(rx3) + 4.0, 7.0, 2.0, Color("#222a38"))
		px(pb, rx3 + 3, 6, Color("#3a4660"))
	rect(pb, 0, 9, 512, 1, Color("#0a0d14"))
	_pipe(pb, 10, 7, PackedColorArray([Color("#1a2130"), Color("#2a3446"), Color("#3a4660"), Color("#46546e"), Color("#2a3446"), Color("#1a2030"), Color("#0e121a")]))
	_pipe(pb, 17, 6, PackedColorArray([Color("#3a2410"), Color("#5a3818"), Color("#6a4420"), Color("#4a2e14"), Color("#2a1a0c"), Color("#160e08")]))
	_pipe(pb, 23, 9, PackedColorArray([Color("#141a26"), Color("#222a3a"), Color("#2e384c"), Color("#38445c"), Color("#2e384c"), Color("#222a3a"), Color("#181e2a"), Color("#10141c"), Color("#0a0d12")]))
	var vents_bot: PackedVector2Array = PackedVector2Array()
	for fx2: int in range(32, 512, 64):
		rect(pb, fx2, 10, 3, 22, Color("#3a4660"))
		rect(pb, fx2 + 2, 10, 1, 22, Color("#10141c"))
	for vx2: int in [90, 290, 430]:
		rect(pb, vx2 - 3, 9, 7, 2, Color("#05070b"))
		vents_bot.append(Vector2(float(vx2), 9.0))
	out["pipes_bot"] = pb
	out["vents_bot"] = vents_bot

	# Crates riding the conveyor (two sprites side by side).
	var crate: Image = new_img(26, 10)
	rect(crate, 0, 1, 13, 9, Color("#3a2a14"))
	rect(crate, 1, 2, 11, 7, Color("#5a4220"))
	rect(crate, 1, 2, 11, 1, Color("#7a5a2c"))
	line(crate, 1, 2, 11, 8, Color("#3a2a14"))
	rect(crate, 14, 0, 12, 10, Color("#1e2a3c"))
	rect(crate, 15, 1, 10, 8, Color("#2c3c54"))
	rect(crate, 15, 1, 10, 1, Color("#40546e"))
	rect(crate, 17, 4, 6, 2, Color("#6a5418"))
	out["crates"] = crate

	# Foreground bulkhead post with hazard-striped brackets (screen y 28..258).
	var bk: Image = new_img(44, 230)
	var post: PackedColorArray = PackedColorArray([Color("#06080c"), Color("#0b0e15"), Color("#10141d"), Color("#161b26"), Color("#10141d"), Color("#0b0e15")])
	for i3: int in range(14):
		rect(bk, 15 + i3, 0, 1, 230, post[clampi(int(float(i3) / 13.0 * 5.0 + 0.5), 0, 5)])
	for by2: int in [0, 214]:
		rect(bk, 0, by2, 44, 16, Color("#0a0d14"))
		rect(bk, 1, by2 + 1, 42, 14, Color("#141a24"))
		for hx2: int in range(2, 42):
			for hy2: int in range(by2 + 4, by2 + 12):
				if posmod(hx2 + hy2, 8) < 4:
					px(bk, hx2, hy2, Color("#4a3c14"))
		rect(bk, 1, by2 + 1, 42, 1, Color("#222a38"))
	out["bulkhead"] = bk
	return out


static func _pipe(img: Image, y: int, h: int, ramp: PackedColorArray) -> void:
	for i: int in range(h):
		var t: float = float(i) / float(maxi(1, h - 1))
		rect(img, 0, y + i, img.get_width(), 1, ramp[clampi(int(t * float(ramp.size() - 1) + 0.5), 0, ramp.size() - 1)])


# ---------------------------------------------------------------------------------------------
# 3) CLOUD BASE - planetary descent
# ---------------------------------------------------------------------------------------------

static func build_cloud() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3303
	var out: Dictionary = {}

	var sky: Image = new_img(480, 270)
	sky.fill(Color("#0a1636"))
	var sky_cols: PackedColorArray = PackedColorArray([Color("#0a1636"), Color("#0e1f47"), Color("#132a58"), Color("#183668"), Color("#1f4378"), Color("#285288"), Color("#326296"), Color("#3c70a2")])
	vgrad(sky, 18, 258, sky_cols, 0.4)
	# sun with a dithered halo, kept small and high (near the HUD) so bullets stay readable
	var sun: Vector2 = Vector2(420.0, 46.0)
	for y: int in range(18, 100):
		for x: int in range(360, 480):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(sun)
			if d < 6.5:
				sky.set_pixel(x, y, Color("#f2e2b8"))
			elif d < 8.0:
				sky.set_pixel(x, y, Color("#dcc08a"))
			elif d < 34.0:
				var k: float = pow(1.0 - (d - 8.0) / 26.0, 2.0) * 0.5
				var lv: int = floori(k * 4.0 + bayer(x, y))
				if lv > 0:
					var base: Color = sky.get_pixel(x, y)
					sky.set_pixel(x, y, base.lerp(Color("#c8a880"), float(lv) * 0.16))
	# high cirrus streaks
	for _i: int in range(14):
		var cx: int = rng.randi_range(0, 479)
		var cy: int = rng.randi_range(36, 120)
		var cw: int = rng.randi_range(18, 60)
		for i: int in range(cw):
			var t: float = float(i) / float(cw)
			if bayer(cx + i, cy) < sin(t * PI) * 0.9:
				blend_px(sky, cx + i, cy, Color("#5a86b8"), 0.35)
			if t > 0.2 and t < 0.8 and bayer(cx + i, cy + 1) < 0.4:
				blend_px(sky, cx + i + 3, cy + 1, Color("#5a86b8"), 0.25)
	out["sky"] = sky

	# Two sun-ray textures that crossfade.
	for k: int in range(2):
		var rays: Image = new_img(480, 230)
		for _r: int in range(5):
			ray_wedge(rays, sun - Vector2(0.0, 28.0), rng.randf_range(1.9, 2.75), rng.randf_range(0.025, 0.06), 420.0, Color(1.0, 0.9, 0.7, 0.07), 0.9)
		out["rays_%d" % k] = rays

	# Distant mountains on the horizon (screen y 178..242).
	var mw: int = 640
	var mh: int = 64
	var mtn: Image = new_img(mw, mh)
	var prof: PackedFloat32Array = profile(mw, rng, 5, 3, 0.55)
	var prof2: PackedFloat32Array = profile(mw, rng, 4, 5, 0.5)
	for x: int in range(mw):
		var top_far: int = int(10.0 + (1.0 - prof2[x]) * 30.0)
		for y: int in range(top_far, mh):
			mtn.set_pixel(x, y, Color("#2e5c8c") if bayer(x, y) < 0.5 + float(y - top_far) / 40.0 else Color("#336494"))
		var top: int = int(18.0 + (1.0 - prof[x]) * 36.0)
		var lit: bool = prof[x] > prof[posmod(x - 2, mw)]
		for y2: int in range(top, mh):
			var c: Color = Color("#27527f")
			if lit:
				c = Color("#2f5d8b")
			if y2 - top < 3 and top < 30:
				c = Color("#6a96c2") if lit else Color("#4c7aa8")
			mtn.set_pixel(x, y2, c)
		# haze toward the bottom
		for y3: int in range(mh - 20, mh):
			if bayer(x, y3) < float(y3 - (mh - 20)) / 22.0:
				mtn.set_pixel(x, y3, Color("#3a6ea0"))
	out["mountains"] = mtn

	# Floating islands with tiny spires (screen y ~96..176).
	var iw: int = 768
	var ih: int = 80
	var isl: Image = new_img(iw, ih)
	for k2: int in range(2):
		var icx: float = 170.0 + float(k2) * 390.0
		var iy: float = 26.0 + float(k2) * 10.0
		var half: float = 46.0 - float(k2) * 10.0
		var pts: PackedVector2Array = PackedVector2Array()
		pts.append(Vector2(icx - half, iy))
		for s: int in range(1, 12):
			var t2: float = float(s) / 12.0
			var depth: float = sin(t2 * PI) * (half * 0.9) * rng.randf_range(0.8, 1.15)
			pts.append(Vector2(icx - half + t2 * half * 2.0, iy + depth))
		pts.append(Vector2(icx + half, iy))
		poly(isl, pts, Color("#24507c"))
		for s2: int in range(int(half * 2.0)):
			var xx: int = int(icx - half) + s2
			for yy: int in range(int(iy), int(iy) + 40):
				if get_px(isl, xx, yy).a > 0.0 and posmod(xx * 7 + yy * 3, 11) == 0:
					px(isl, xx, yy, Color("#1e466e"))
		rect(isl, int(icx - half), int(iy) - 2, int(half * 2.0), 3, Color("#2f6488"))
		rect(isl, int(icx - half), int(iy) - 2, int(half * 2.0), 1, Color("#3c7898"))
		# spires
		for sp: int in range(4):
			var sx: int = int(icx - half * 0.6) + sp * int(half * 0.4)
			var sh: int = rng.randi_range(8, 22)
			rect(isl, sx, int(iy) - 2 - sh, 3, sh, Color("#1e4670"))
			px(isl, sx + 1, int(iy) - 3 - sh, Color("#1e4670"))
			px(isl, sx + 1, int(iy) - 2 - sh + 3, Color("#7ab8d8"))
		# waterfall off the edge
		var wf: int = int(icx + half * 0.7)
		for wy: int in range(int(iy), int(iy) + 34):
			if bayer(wf, wy) < 1.0 - float(wy - int(iy)) / 34.0:
				px(isl, wf, wy, Color("#5a90bc"))
				px(isl, wf + 1, wy, Color("#4a80b0"))
	out["islands"] = isl

	var cloud_far_ramp: PackedColorArray = PackedColorArray([Color("#1f3e70"), Color("#24467a"), Color("#2a4f84"), Color("#32598e"), Color("#3c6498")])
	var cloud_mid_ramp: PackedColorArray = PackedColorArray([Color("#2b5286"), Color("#335d92"), Color("#3c689e"), Color("#4a78ac"), Color("#5a88ba")])
	var sea_far_ramp: PackedColorArray = PackedColorArray([Color("#30598a"), Color("#366296"), Color("#3d6b9f"), Color("#4776a8"), Color("#5482b2")])
	var cloud_sea_ramp: PackedColorArray = PackedColorArray([Color("#3a6698"), Color("#4672a4"), Color("#5682b2"), Color("#6c96c2"), Color("#88acd2")])
	var sea_near_ramp: PackedColorArray = PackedColorArray([Color("#4a76a8"), Color("#5a86b6"), Color("#7098c4"), Color("#8cb0d6"), Color("#b0cbe6")])
	out["clouds_far"] = _cloud_layer(768, 56, 7, 22.0, 60.0, 7.0, 12.0, cloud_far_ramp, rng, false)
	out["clouds_mid"] = _cloud_layer(768, 74, 5, 36.0, 96.0, 11.0, 18.0, cloud_mid_ramp, rng, false)
	out["sea_far"] = _cloud_layer(640, 44, 12, 34.0, 80.0, 9.0, 16.0, sea_far_ramp, rng, true)
	out["cloud_sea"] = _cloud_layer(640, 52, 9, 50.0, 110.0, 13.0, 22.0, cloud_sea_ramp, rng, true)
	out["sea_near"] = _cloud_layer(512, 34, 6, 60.0, 130.0, 12.0, 20.0, sea_near_ramp, rng, true)

	# Sky platform sprite (64x36) and airship (2 frames 72x24).
	var plat: Image = new_img(64, 36)
	ellipse(plat, 32.0, 24.0, 30.0, 5.0, Color("#16243c"))
	ellipse(plat, 32.0, 22.0, 29.0, 3.0, Color("#2a4064"))
	rect(plat, 4, 22, 56, 1, Color("#3a5480"))
	rect(plat, 24, 8, 16, 14, Color("#1c2c48"))
	rect(plat, 25, 9, 6, 13, Color("#2a4064"))
	ellipse(plat, 32.0, 8.0, 7.0, 4.0, Color("#2a4064"))
	ellipse(plat, 30.0, 7.0, 3.0, 2.0, Color("#4a6a98"))
	vline(plat, 32, 0, 4, Color("#2a4064"))
	rect(plat, 26, 13, 12, 1, Color("#7ce8ff"))
	ellipse(plat, 32.0, 29.0, 9.0, 3.0, Color("#101a2c"))
	out["platform"] = plat

	var ship: Image = new_img(72, 48)
	for f: int in range(2):
		var oy: int = f * 24
		ellipse(ship, 34.0, float(oy) + 9.0, 28.0, 7.0, Color("#223a62"))
		ellipse(ship, 33.0, float(oy) + 7.0, 25.0, 4.0, Color("#2c4a76"))
		rect(ship, 12, oy + 5, 44, 1, Color("#3a5c8a"))
		for rb: int in range(12, 60, 8):
			vline(ship, rb, oy + 4, oy + 14, Color("#1c3254"))
		poly(ship, PackedVector2Array([Vector2(60.0, float(oy) + 9.0), Vector2(70.0, float(oy) + 2.0), Vector2(71.0, float(oy) + 9.0)]), Color("#1c3254"))
		poly(ship, PackedVector2Array([Vector2(60.0, float(oy) + 10.0), Vector2(71.0, float(oy) + 17.0), Vector2(70.0, float(oy) + 10.0)]), Color("#1c3254"))
		rect(ship, 26, oy + 15, 14, 4, Color("#1a2c4a"))
		rect(ship, 28, oy + 16, 10, 1, Color("#6ac0e0"))
		if f == 0:
			vline(ship, 72 - 1, oy + 6, oy + 12, Color("#5a7aa0"))
		else:
			rect(ship, 69, oy + 9, 3, 1, Color("#5a7aa0"))
	out["airship"] = ship
	return out


static func _cloud_layer(w: int, h: int, count: int, min_w: float, max_w: float, min_h: float, max_h: float, ramp: PackedColorArray, rng: RandomNumberGenerator, sea: bool) -> Image:
	var mask: PackedByteArray = PackedByteArray()
	mask.resize(w * h)
	if sea:
		# continuous cloud sea: puffs packed edge to edge, solid underneath
		var solid: int = int(float(h) * 0.4)
		for y: int in range(h - solid, h):
			for x: int in range(w):
				mask[y * w + x] = 1
		var room: float = float(h - solid)
		var x0: float = 0.0
		while x0 < float(w) - min_w * 0.4:
			var cw: float = rng.randf_range(min_w, max_w)
			var ph: float = minf(rng.randf_range(min_h, max_h), room * 0.62)
			cloud_puff(mask, w, h, x0 + cw * 0.5, room + rng.randf_range(0.0, 4.0), cw, ph, rng, false)
			x0 += cw * rng.randf_range(0.5, 0.75)
	else:
		for i: int in range(count):
			var cw2: float = rng.randf_range(min_w, max_w)
			var cx: float = (float(i) + rng.randf_range(0.1, 0.9)) * float(w) / float(count)
			var base: float = rng.randf_range(max_h + 2.0, float(h) - 3.0)
			cloud_puff(mask, w, h, cx, base, cw2, rng.randf_range(min_h, max_h), rng)
	var img: Image = new_img(w, h)
	paint_cloud_mask(img, mask, w, h, 0, ramp)
	return img


# ---------------------------------------------------------------------------------------------
# 4) XENO FOREST
# ---------------------------------------------------------------------------------------------

static func build_forest() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4404
	var out: Dictionary = {}

	var sky: Image = new_img(480, 270)
	sky.fill(Color("#030c09"))
	vgrad(sky, 28, 258, PackedColorArray([Color("#030c09"), Color("#05120d"), Color("#071a12"), Color("#0a2117"), Color("#0c281b"), Color("#0e2c1d")]), 0.45)
	# distant glow haze patches
	for _i: int in range(5):
		var hx: float = rng.randf_range(0.0, 480.0)
		var hy: float = rng.randf_range(140.0, 230.0)
		for y: int in range(int(hy) - 30, int(hy) + 30):
			for x: int in range(int(hx) - 60, int(hx) + 60):
				var d: float = Vector2((float(x) - hx) / 60.0, (float(y) - hy) / 30.0).length()
				if d < 1.0 and bayer(x, y) < (1.0 - d) * 0.6 and x >= 0 and x < 480 and y >= 0 and y < 258:
					sky.set_pixel(x, y, Color("#113524"))
	out["sky"] = sky

	# Far trunks (screen y 28..258).
	var fw: int = 640
	var fh: int = 230
	var far: Image = new_img(fw, fh)
	var x: float = 0.0
	while x < float(fw):
		var tw: int = rng.randi_range(6, 13)
		var tx: int = int(x)
		var lean: float = rng.randf_range(-0.04, 0.04)
		for y: int in range(fh):
			var ox: int = int(float(y - fh) * lean)
			var wdt: int = tw + int(float(y) / float(fh) * 4.0)
			rect(far, tx + ox, y, wdt, 1, Color("#0a221c"))
			px(far, tx + ox, y, Color("#0d2a24"))
		for _b: int in range(rng.randi_range(1, 3)):
			var by: int = rng.randi_range(30, 150)
			var dir: int = 1 if rng.randf() < 0.5 else -1
			var bl: int = rng.randi_range(10, 24)
			line(far, tx + tw / 2, by, tx + tw / 2 + dir * bl, by - bl / 2, Color("#0a2219"))
			line(far, tx + tw / 2, by + 1, tx + tw / 2 + dir * bl, by - bl / 2 + 1, Color("#0a2219"))
			disc(far, float(tx + tw / 2 + dir * bl), float(by - bl / 2), rng.randf_range(4.0, 7.0), Color("#0a2419"))
		# faint glow fungus dots on the trunk
		for _g: int in range(3):
			px(far, tx + rng.randi_range(1, tw - 1), rng.randi_range(40, 200), Color("#1a4a3a"))
		x += float(tw) + rng.randf_range(18.0, 46.0)
	for xx: int in range(fw):
		var ch: int = int(10.0 + 8.0 * sin(float(xx) * TAU * 9.0 / float(fw)) + 5.0 * sin(float(xx) * TAU * 23.0 / float(fw) + 1.0))
		vline(far, xx, 0, maxi(0, ch), Color("#09201a"))
		var gh: int = int(16.0 + 6.0 * sin(float(xx) * TAU * 13.0 / float(fw) + 2.0) + 4.0 * sin(float(xx) * TAU * 31.0 / float(fw)))
		vline(far, xx, fh - gh, fh - 1, Color("#0b261b"))
	out["far"] = far

	# Light shafts through canopy gaps (static, pulsed by modulate).
	var shafts: Image = new_img(480, 230)
	for k: int in range(4):
		var sx: float = 70.0 + float(k) * 112.0 + rng.randf_range(-20.0, 20.0)
		var swid: float = rng.randf_range(10.0, 22.0)
		for y: int in range(230):
			var cx: float = sx + float(y) * 0.32
			var fade: float = 1.0 - float(y) / 230.0
			for xx2: int in range(int(cx - swid), int(cx + swid)):
				var e: float = 1.0 - absf(float(xx2) - cx) / swid
				if xx2 >= 0 and xx2 < 480 and bayer(xx2, y) < e * fade * 1.1:
					shafts.set_pixel(xx2, y, Color(0.55, 1.0, 0.8, 0.055))
	out["shafts"] = shafts

	# Mid giant trunks + mushrooms (screen y 28..258).
	var mw: int = 768
	var mh: int = 230
	var mid: Image = new_img(mw, mh)
	var bark: PackedColorArray = PackedColorArray([Color("#040d08"), Color("#0b1c12"), Color("#13301e"), Color("#1c4128"), Color("#245032"), Color("#163824"), Color("#0c2014"), Color("#061209")])
	var glows: PackedVector3Array = PackedVector3Array()
	var trunk_x: PackedFloat32Array = PackedFloat32Array([40.0, 230.0, 430.0, 610.0])
	for k2: int in range(trunk_x.size()):
		var tx2: int = int(trunk_x[k2] + rng.randf_range(-20.0, 20.0))
		var tw2: int = rng.randi_range(24, 36)
		for y: int in range(mh):
			var flare: int = 0
			if y > mh - 30:
				flare = int(pow(float(y - (mh - 30)) / 30.0, 2.0) * 16.0)
			var w2: int = tw2 + flare * 2
			for i: int in range(w2):
				var t: float = float(i) / float(maxi(1, w2 - 1))
				# cylindrical shading lit from the left, dithered between ramp steps
				var shade: float = clampf(1.0 - absf(t - 0.32) * 2.1, 0.0, 1.0)
				if t < 0.06 or t > 0.94:
					shade = 0.0
				var ci: int = clampi(floori(shade * 4.0 + bayer(tx2 + i, y) * 0.9), 0, 4)
				if t > 0.6 and ci > 1:
					ci = 6 if t > 0.85 else 5
				px(mid, tx2 - flare + i, y, bark[ci])
		# bark grooves
		for _g2: int in range(7):
			var gx: int = tx2 + rng.randi_range(3, tw2 - 3)
			var gy: int = rng.randi_range(0, 120)
			for y2: int in range(gy, mini(mh - 10, gy + rng.randi_range(30, 100))):
				if posmod(y2, 9) == 0:
					gx += rng.randi_range(-1, 1)
				px(mid, gx, y2, Color("#040d09"))
		# moss on the lit side
		for _m: int in range(10):
			var my: int = rng.randi_range(10, mh - 30)
			var mx: int = tx2 + rng.randi_range(2, tw2 / 2)
			for j: int in range(rng.randi_range(4, 9)):
				px(mid, mx + rng.randi_range(-2, 2), my + j, Color("#1c4a2c") if rng.randf() < 0.6 else Color("#245834"))
		# bracket fungi with glowing rims
		for f: int in range(3):
			var fy: int = 40 + f * 52 + rng.randi_range(-10, 10)
			var left: bool = (f + k2) % 2 == 0
			# a shelf growing out of the trunk edge: quarter-dome, lit top, glowing gills below
			var edge_x: int = tx2 + 1 if left else tx2 + tw2 - 2
			var dir: int = -1 if left else 1
			var shelf_w: int = rng.randi_range(6, 9)
			for i: int in range(-3, shelf_w + 1):
				var t: float = clampf(float(i) / float(shelf_w), 0.0, 1.0)
				var hgt: int = int(round(4.0 * sqrt(maxf(0.0, 1.0 - t * t))))
				var xx: int = edge_x + dir * i
				vline(mid, xx, fy - hgt, fy, Color("#3a1e4c"))
				px(mid, xx, fy - hgt, Color("#5a3078"))
				px(mid, xx, fy, Color("#22142e"))
				if i >= 0 and i < shelf_w and i % 2 == 0:
					px(mid, xx, fy + 1, Color("#1f9a86"))
					glows.append(Vector3(float(xx), float(fy + 1), 0.0))
			for i2: int in range(1, 5):
				px(mid, edge_x - dir * i2, fy + 1, Color("#040d08"))
	# giant mushrooms at the floor between trunks
	var spots: PackedVector3Array = PackedVector3Array()
	for k3: int in range(3):
		var mx2: float = 130.0 + float(k3) * 250.0 + rng.randf_range(-20.0, 20.0)
		var cap_y: float = rng.randf_range(176.0, 196.0)
		var rx: float = rng.randf_range(18.0, 26.0)
		rect(mid, int(mx2) - 3, int(cap_y), 7, mh - int(cap_y), Color("#2a2640"))
		rect(mid, int(mx2) - 3, int(cap_y), 2, mh - int(cap_y), Color("#3a3656"))
		rect(mid, int(mx2) + 2, int(cap_y), 2, mh - int(cap_y), Color("#1c1a2c"))
		ellipse(mid, mx2, cap_y, rx, 9.0, Color("#1c0c2a"))
		ellipse(mid, mx2, cap_y - 1.0, rx - 1.0, 8.0, Color("#331548"))
		ellipse(mid, mx2 - rx * 0.25, cap_y - 3.0, rx * 0.6, 4.5, Color("#47205e"))
		rect(mid, int(mx2 - rx + 2.0), int(cap_y) + 1, int(rx * 2.0) - 4, 1, Color("#14081e"))
		for s: int in range(7):
			var sx2: float = mx2 + rng.randf_range(-rx * 0.8, rx * 0.8)
			var sy2: float = cap_y - rng.randf_range(1.0, 7.0)
			px(mid, int(sx2), int(sy2), Color("#8a3cc0"))
			spots.append(Vector3(sx2, sy2, float(s % 3)))
	out["mid"] = mid
	out["glows"] = glows
	out["spots"] = spots

	# Canopy fringe (screen y 28..74) with vine anchor points.
	var cw: int = 640
	var chh: int = 46
	var canopy: Image = new_img(cw, chh)
	var leaf: PackedColorArray = PackedColorArray([Color("#04120a"), Color("#081d10"), Color("#0d2a17"), Color("#13381f"), Color("#1b4a2a")])
	var lmask: PackedByteArray = PackedByteArray()
	lmask.resize(cw * chh)
	for xx3: int in range(cw):
		var depth: int = int(14.0 + 7.0 * sin(float(xx3) * TAU * 7.0 / float(cw)) + 5.0 * sin(float(xx3) * TAU * 19.0 / float(cw) + 0.7))
		for y3: int in range(maxi(0, depth)):
			lmask[y3 * cw + xx3] = 1
	for _l: int in range(140):
		var lx: float = rng.randf_range(0.0, float(cw))
		var ly: float = rng.randf_range(6.0, 30.0)
		mask_disc(lmask, cw, chh, lx, ly, rng.randf_range(3.0, 7.0), 999.0)
	for y4: int in range(chh):
		for x4: int in range(cw):
			if lmask[y4 * cw + x4] == 0:
				continue
			var c: Color = leaf[2]
			if not mask_at(lmask, cw, chh, x4, y4 + 1):
				c = leaf[0]
			elif not mask_at(lmask, cw, chh, x4, y4 + 3):
				c = leaf[1]
			elif not mask_at(lmask, cw, chh, x4 - 1, y4 - 2) or not mask_at(lmask, cw, chh, x4, y4 - 2):
				c = leaf[4] if bayer(x4, y4) < 0.6 else leaf[3]
			elif bayer(x4 * 3, y4) < 0.25:
				c = leaf[3]
			canopy.set_pixel(x4, y4, c)
	# hanging moss strands
	var vines: PackedVector2Array = PackedVector2Array()
	for _s: int in range(40):
		var sx3: int = rng.randi_range(0, cw - 1)
		var top: int = 0
		while top < chh - 1 and mask_at(lmask, cw, chh, sx3, top + 1):
			top += 1
		var ln: int = rng.randi_range(3, 12)
		for j2: int in range(ln):
			if top + j2 < chh:
				px(canopy, sx3, top + j2, Color("#0b2614"))
	for k4: int in range(9):
		var vx: int = int((float(k4) + rng.randf_range(0.2, 0.8)) * float(cw) / 9.0)
		var vtop: int = 0
		while vtop < chh - 1 and mask_at(lmask, cw, chh, vx, vtop + 1):
			vtop += 1
		vines.append(Vector2(float(vx), float(vtop)))
	out["canopy"] = canopy
	out["vines"] = vines

	# Undergrowth (screen y 222..258) with glow-plant anchors.
	var uw: int = 640
	var uh: int = 36
	var under: Image = new_img(uw, uh)
	var fern: PackedColorArray = PackedColorArray([Color("#05150c"), Color("#092012"), Color("#0e2c18"), Color("#153a20"), Color("#1d4a2a")])
	for xx5: int in range(uw):
		var gh2: int = int(12.0 + 4.0 * sin(float(xx5) * TAU * 11.0 / float(uw)) + 3.0 * sin(float(xx5) * TAU * 29.0 / float(uw) + 1.3))
		vline(under, xx5, uh - gh2, uh - 1, fern[0])
	for _f: int in range(70):
		var fx2: int = rng.randi_range(0, uw - 1)
		var fh2: int = rng.randi_range(8, 24)
		var dir2: int = 1 if rng.randf() < 0.5 else -1
		for j3: int in range(fh2):
			var t3: float = float(j3) / float(fh2)
			var bx: int = fx2 + int(dir2 * t3 * t3 * 6.0)
			var by: int = uh - 1 - j3
			px(under, bx, by, fern[2] if t3 < 0.7 else fern[3])
			if j3 % 3 == 1:
				px(under, bx - 1, by, fern[1])
				px(under, bx + 1, by + 1, fern[1])
				px(under, bx + dir2 * 2, by + 1, fern[2])
	for _b2: int in range(24):
		var bx2: int = rng.randi_range(0, uw - 1)
		var by2: int = rng.randi_range(uh - 12, uh - 4)
		disc(under, float(bx2), float(by2), rng.randf_range(2.0, 3.5), fern[1])
		px(under, bx2 - 1, by2 - 1, fern[3])
	var plants: PackedVector3Array = PackedVector3Array()
	for k5: int in range(10):
		plants.append(Vector3((float(k5) + rng.randf_range(0.1, 0.9)) * float(uw) / 10.0, rng.randf_range(10.0, 22.0), float(k5 % 3)))
	out["under"] = under
	out["plants"] = plants

	# Giant moth (2 frames, 22x14 each).
	var moth: Image = new_img(44, 14)
	for f2: int in range(2):
		var ox: int = f2 * 22
		var wy: float = 4.0 if f2 == 0 else 8.0
		ellipse(moth, float(ox) + 6.0, wy, 6.0, 4.0, Color("#1e1430"))
		ellipse(moth, float(ox) + 16.0, wy, 6.0, 4.0, Color("#1e1430"))
		px(moth, ox + 5, int(wy), Color("#7a4aa0"))
		px(moth, ox + 16, int(wy), Color("#7a4aa0"))
		rect(moth, ox + 10, 5, 2, 7, Color("#140c20"))
		px(moth, ox + 9, 4, Color("#140c20"))
		px(moth, ox + 12, 4, Color("#140c20"))
	out["moth"] = moth
	return out


# ---------------------------------------------------------------------------------------------
# 5) CRYO GLACIER
# ---------------------------------------------------------------------------------------------

static func build_ice() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5505
	var out: Dictionary = {}

	var sky: Image = new_img(480, 270)
	sky.fill(Color("#040a18"))
	vgrad(sky, 28, 258, PackedColorArray([Color("#040a18"), Color("#060e22"), Color("#08142d"), Color("#0b1b3b"), Color("#10264b"), Color("#16325c"), Color("#1c3e6c")]), 0.45)
	for _i: int in range(70):
		var r: float = rng.randf()
		var c: Color = Color("#22305a")
		if r > 0.6:
			c = Color("#34467a")
		if r > 0.92:
			c = Color("#5a6ca0")
		px(sky, rng.randi_range(0, 479), rng.randi_range(30, 150), c)
	out["sky"] = sky

	# Aurora curtain (tileable 512 wide); runtime draws it in waving vertical slices.
	var aw: int = 512
	var ah: int = 70
	var aur: Image = new_img(aw, ah)
	var streak: PackedFloat32Array = noise_field(aw, 1, 8, 3, rng)
	var tops: PackedFloat32Array = profile(aw, rng, 3, 2, 0.5)
	var lens: PackedFloat32Array = profile(aw, rng, 3, 3, 0.6)
	for xx: int in range(aw):
		var top: int = int(4.0 + tops[xx] * 16.0)
		var ln: int = int(24.0 + lens[xx] * 28.0)
		# curtain folds (slow) times fine vertical rays (fast)
		var fold: float = clampf(pow(streak[xx], 1.4) * 1.6, 0.12, 1.0)
		var ray: float = 0.5 + 0.5 * sin(float(xx) * TAU * 61.0 / float(aw) + 3.0 * sin(float(xx) * TAU * 5.0 / float(aw)))
		var s: float = fold * (0.45 + 0.55 * ray)
		for j: int in range(ln):
			var y: int = top + j
			if y >= ah:
				break
			var t: float = float(j) / float(ln)
			# bright hem along the bottom edge, rays fading upward into a violet fringe
			var inten: float = pow(t, 1.5) * s
			if j >= ln - 2:
				inten = 0.55 + 0.45 * fold
			var lv: int = mini(4, floori(inten * 4.0 + bayer(xx, y)))
			if lv <= 0:
				continue
			var c2: Color
			if t > 0.65:
				c2 = Color(0.22, 1.0, 0.62, 0.1 * float(lv))
			elif t > 0.3:
				c2 = Color(0.16, 0.82, 0.78, 0.08 * float(lv))
			else:
				c2 = Color(0.5, 0.34, 0.95, 0.06 * float(lv))
			aur.set_pixel(xx, y, c2)
	out["aurora"] = aur

	# Distant mountains + frozen citadel (screen y 146..244).
	var mw: int = 768
	var mh: int = 98
	var mtn: Image = new_img(mw, mh)
	var p1: PackedFloat32Array = profile(mw, rng, 5, 4, 0.55)
	var p2: PackedFloat32Array = profile(mw, rng, 5, 3, 0.55)
	for x: int in range(mw):
		var t1: int = int(8.0 + (1.0 - p1[x]) * 44.0)
		var lit1: bool = p1[x] >= p1[posmod(x - 1, mw)]
		for y: int in range(t1, mh):
			var c3: Color = Color("#1a3a64") if lit1 else Color("#15325a")
			if y - t1 < 4:
				c3 = Color("#4a78aa") if lit1 else Color("#2e5888")
			mtn.set_pixel(x, y, c3)
		var t2: int = int(34.0 + (1.0 - p2[x]) * 46.0)
		var lit2: bool = p2[x] >= p2[posmod(x - 1, mw)]
		for y2: int in range(t2, mh):
			var c4: Color = Color("#12284a") if lit2 else Color("#0e2242")
			if y2 - t2 < 3:
				c4 = Color("#3a6a9c") if lit2 else Color("#244c7c")
			mtn.set_pixel(x, y2, c4)
	# citadel on a near peak
	var best_x: int = 0
	var best_top: int = 999
	for x2: int in range(200, 560):
		var t3: int = int(34.0 + (1.0 - p2[x2]) * 46.0)
		if t3 < best_top:
			best_top = t3
			best_x = x2
	var windows: PackedVector2Array = PackedVector2Array()
	for s2: int in range(5):
		var sx: int = best_x - 14 + s2 * 7
		var sh: int = rng.randi_range(14, 30) - absi(s2 - 2) * 4
		rect(mtn, sx, best_top - sh, 4, sh + 4, Color("#0c1e3a"))
		px(mtn, sx + 1, best_top - sh - 1, Color("#0c1e3a"))
		px(mtn, sx + 2, best_top - sh - 1, Color("#0c1e3a"))
		px(mtn, sx + 1, best_top - sh - 2, Color("#0c1e3a"))
		px(mtn, sx, best_top - sh, Color("#2e5888"))
		for wy: int in range(best_top - sh + 4, best_top, 5):
			px(mtn, sx + 2, wy, Color("#3a7ab8"))
			windows.append(Vector2(float(sx + 2), float(wy)))
	out["mountains"] = mtn
	out["citadel_windows"] = windows

	# Mid ice: icicles from the ceiling, crystal clusters on the floor (screen y 28..258).
	var iw: int = 768
	var ih: int = 230
	var ice: Image = new_img(iw, ih)
	var glints: PackedVector2Array = PackedVector2Array()
	rect(ice, 0, 0, iw, 5, Color("#1f4a78"))
	rect(ice, 0, 5, iw, 1, Color("#3f7fb5"))
	var ix: float = 0.0
	while ix < float(iw):
		var icw: float = rng.randf_range(4.0, 12.0)
		var icl: float = rng.randf_range(8.0, 44.0)
		if rng.randf() < 0.3:
			icl *= 0.4
		var l: float = ix
		var r2: float = ix + icw
		var tipx: float = ix + icw * rng.randf_range(0.4, 0.6)
		poly(ice, PackedVector2Array([Vector2(l - 1.0, 4.0), Vector2(r2 + 1.0, 4.0), Vector2(tipx, 6.0 + icl + 1.0)]), Color("#12305a"))
		poly(ice, PackedVector2Array([Vector2(l, 4.0), Vector2(tipx, 4.0), Vector2(tipx, 6.0 + icl)]), Color("#3a78ae"))
		poly(ice, PackedVector2Array([Vector2(tipx, 4.0), Vector2(r2, 4.0), Vector2(tipx, 6.0 + icl)]), Color("#24528a"))
		line(ice, int(l + 1.0), 6, int(tipx), int(5.0 + icl), Color("#7cc4ec"))
		if icl > 20.0:
			glints.append(Vector2(tipx, 5.0 + icl))
		ix += icw + rng.randf_range(-1.0, 6.0)
	var cr_ramp: PackedColorArray = PackedColorArray([Color("#0e2648"), Color("#1c4676"), Color("#2c6298"), Color("#4a8cc0"), Color("#8ad0f0")])
	var cx: float = 20.0
	while cx < float(iw):
		var n: int = rng.randi_range(3, 6)
		for k: int in range(n):
			var ang: float = rng.randf_range(-0.55, 0.55)
			var ln2: float = rng.randf_range(18.0, 58.0)
			if k == n / 2:
				ln2 *= 1.3
			var wd: float = rng.randf_range(6.0, 13.0)
			var tip: Vector2 = crystal(ice, cx + rng.randf_range(-14.0, 14.0), float(ih) - 6.0, ang, ln2, wd, cr_ramp)
			glints.append(tip)
		cx += rng.randf_range(80.0, 150.0)
	# snow drifts along the floor
	var drift: PackedFloat32Array = profile(iw, rng, 4, 6, 0.5)
	for x3: int in range(iw):
		var dtop: int = ih - 4 - int(drift[x3] * 10.0)
		for y3: int in range(dtop, ih):
			var c5: Color = Color("#3c64a0")
			if y3 == dtop:
				c5 = Color("#7aa6d6")
			elif y3 < dtop + 3:
				c5 = Color("#5a86bc")
			ice.set_pixel(x3, y3, c5)
	out["ice"] = ice
	out["glints"] = glints

	# Near dark ice chunks (screen y 236..266).
	var nw: int = 512
	var nh: int = 30
	var near: Image = new_img(nw, nh)
	var np: PackedFloat32Array = profile(nw, rng, 4, 5, 0.6)
	for x4: int in range(nw):
		var top2: int = int(4.0 + (1.0 - np[x4]) * 26.0)
		if top2 >= nh:
			continue
		vline(near, x4, top2, nh - 1, Color("#081628"))
		px(near, x4, top2, Color("#24507e"))
		if np[x4] > np[posmod(x4 - 1, nw)]:
			px(near, x4, top2 + 1, Color("#163a64"))
	out["near"] = near
	return out


# ---------------------------------------------------------------------------------------------
# 6) MAGMA CORE
# ---------------------------------------------------------------------------------------------

static func build_volcano() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6606
	var out: Dictionary = {}

	var sky: Image = new_img(480, 270)
	sky.fill(Color("#0e0305"))
	vgrad(sky, 28, 236, PackedColorArray([Color("#0e0305"), Color("#140406"), Color("#1a0608"), Color("#22080a"), Color("#2c0b0c"), Color("#3a0f0e"), Color("#4a1610")]), 0.45)
	vgrad(sky, 236, 270, PackedColorArray([Color("#4a1610"), Color("#5a1e10")]), 0.5)
	out["sky"] = sky

	# Distant volcanoes with lava rivers (screen y 128..236).
	var vw: int = 768
	var vh: int = 108
	var vol: Image = new_img(vw, vh)
	var craters: PackedVector2Array = PackedVector2Array()
	var base_prof: PackedFloat32Array = profile(vw, rng, 4, 4, 0.5)
	for x: int in range(vw):
		var top: int = int(70.0 + (1.0 - base_prof[x]) * 26.0)
		vline(vol, x, top, vh - 1, Color("#1a0607"))
	for k: int in range(3):
		var cx: float = 120.0 + float(k) * 256.0 + rng.randf_range(-30.0, 30.0)
		var peak: float = rng.randf_range(10.0, 30.0)
		var half: float = rng.randf_range(70.0, 110.0)
		var pts: PackedVector2Array = PackedVector2Array([
			Vector2(cx - half, float(vh)), Vector2(cx - 7.0, peak), Vector2(cx - 3.0, peak + 3.0),
			Vector2(cx + 3.0, peak + 3.0), Vector2(cx + 7.0, peak), Vector2(cx + half, float(vh)),
		])
		poly(vol, pts, Color("#1e0708"))
		# lit left flank
		poly(vol, PackedVector2Array([Vector2(cx - half, float(vh)), Vector2(cx - 7.0, peak), Vector2(cx - 3.0, peak + 3.0), Vector2(cx - half * 0.55, float(vh))]), Color("#260a0a"))
		rect(vol, int(cx) - 4, int(peak) + 1, 8, 2, Color("#b8441a"))
		rect(vol, int(cx) - 2, int(peak), 4, 1, Color("#ff8a30"))
		craters.append(Vector2(cx, peak))
		# lava rivers wandering down
		for _r: int in range(rng.randi_range(2, 3)):
			var rx: float = cx + rng.randf_range(-3.0, 3.0)
			var ry: float = peak + 3.0
			var drift: float = rng.randf_range(-0.6, 0.6)
			while ry < float(vh):
				px(vol, int(rx), int(ry), Color("#7a200c") if rng.randf() < 0.8 else Color("#b8401a"))
				ry += 1.0
				rx += drift + rng.randf_range(-0.7, 0.7)
	out["volcanoes"] = vol
	out["craters"] = craters

	# Cavern cliffs with lava falls (screen y 34..234).
	var cw: int = 640
	var ch: int = 200
	var cliffs: Image = new_img(cw, ch)
	var tp: PackedFloat32Array = profile(cw, rng, 5, 5, 0.55)
	var bp: PackedFloat32Array = profile(cw, rng, 5, 4, 0.55)
	for x2: int in range(cw):
		# cavern walls, rim-lit from below by the lava
		var t2: int = int(6.0 + tp[x2] * 34.0)
		vline(cliffs, x2, 0, t2, Color("#210808"))
		px(cliffs, x2, t2, Color("#5a1a0e"))
		px(cliffs, x2, t2 - 1, Color("#38100b"))
		var b2: int = ch - int(10.0 + bp[x2] * 40.0)
		vline(cliffs, x2, b2, ch - 1, Color("#210808"))
		px(cliffs, x2, b2, Color("#6a2210"))
		px(cliffs, x2, b2 + 1, Color("#3e120c"))
		if bp[x2] > bp[posmod(x2 - 1, cw)]:
			px(cliffs, x2, b2 + 2, Color("#30100a"))
	for _sp: int in range(500):
		var sx: int = rng.randi_range(0, cw - 1)
		var sy: int = rng.randi_range(0, ch - 1)
		if get_px(cliffs, sx, sy).a > 0.0 and get_px(cliffs, sx, sy - 2).a > 0.0 and get_px(cliffs, sx, sy + 2).a > 0.0:
			px(cliffs, sx, sy, Color("#2c0c0a"))
	var falls: PackedVector3Array = PackedVector3Array()
	for k2: int in range(3):
		var fx: int = 60 + k2 * 210 + rng.randi_range(-30, 30)
		var ftop: int = int(6.0 + tp[fx] * 34.0)
		var fbot: int = ch - int(10.0 + bp[fx] * 40.0)
		rect(cliffs, fx - 4, ftop, 9, fbot - ftop, Color("#3a0e08"))
		ellipse(cliffs, float(fx), float(fbot) + 2.0, 12.0, 3.0, Color("#6a1c0a"))
		ellipse(cliffs, float(fx), float(fbot) + 1.0, 7.0, 1.5, Color("#9a3010"))
		falls.append(Vector3(float(fx), float(ftop), float(fbot)))
	out["cliffs"] = cliffs
	out["falls"] = falls

	# Lava fall flow texture (8 x 64, tiles vertically).
	var flow: Image = new_img(8, 64)
	for y: int in range(64):
		for x3: int in range(8):
			var v: float = 0.5 + 0.5 * sin(float(y) * TAU / 64.0 * 3.0 + float(x3) * 1.7) * sin(float(y) * TAU / 64.0 + float(x3))
			var c: Color
			if x3 == 0 or x3 == 7:
				c = Color("#3e1006")
			elif x3 == 1 or x3 == 6:
				c = Color("#661c08") if v < 0.7 else Color("#80280a")
			else:
				c = Color("#8a2a0c")
				if v > 0.5:
					c = Color("#a8380e")
				if v > 0.78:
					c = Color("#c44c14")
				if v > 0.95:
					c = Color("#e0681e")
			flow.set_pixel(x3, y, c)
	out["flow"] = flow

	# Mid basalt: stalactites + stalagmites with glowing cracks (screen y 28..258).
	var rw: int = 768
	var rh: int = 230
	var rocks: Image = new_img(rw, rh)
	var basalt: PackedColorArray = PackedColorArray([Color("#0c0303"), Color("#150505"), Color("#1e0807"), Color("#2c0e0a")])
	var x4: float = 0.0
	while x4 < float(rw):
		var w4: float = rng.randf_range(14.0, 34.0)
		var l4: float = rng.randf_range(14.0, 52.0)
		var tip: float = x4 + w4 * rng.randf_range(0.35, 0.65)
		poly(rocks, PackedVector2Array([Vector2(x4, 0.0), Vector2(x4 + w4, 0.0), Vector2(tip + 2.0, l4 * 0.7), Vector2(tip, l4), Vector2(tip - 2.0, l4 * 0.75)]), basalt[1])
		poly(rocks, PackedVector2Array([Vector2(x4, 0.0), Vector2(tip - 1.0, 0.0), Vector2(tip - 1.0, l4 * 0.9), Vector2(tip - 2.0, l4 * 0.75)]), basalt[2])
		line(rocks, int(x4), 0, int(tip - 2.0), int(l4 * 0.75), basalt[3])
		if rng.randf() < 0.6:
			var cy: float = 2.0
			var crx: float = x4 + w4 * 0.5
			while cy < l4 * 0.6:
				px(rocks, int(crx), int(cy), Color("#8a2a0c"))
				if rng.randf() < 0.4:
					px(rocks, int(crx) + 1, int(cy), Color("#5a1808"))
				cy += 1.0
				crx += rng.randf_range(-0.8, 0.8)
		x4 += w4 * rng.randf_range(0.7, 1.4)
	var x5: float = 10.0
	while x5 < float(rw):
		var w5: float = rng.randf_range(18.0, 40.0)
		var h5: float = rng.randf_range(12.0, 44.0)
		var tip2: float = x5 + w5 * rng.randf_range(0.35, 0.65)
		poly(rocks, PackedVector2Array([Vector2(x5, float(rh)), Vector2(tip2 - 3.0, float(rh) - h5 * 0.8), Vector2(tip2, float(rh) - h5), Vector2(tip2 + 3.0, float(rh) - h5 * 0.85), Vector2(x5 + w5, float(rh))]), basalt[1])
		poly(rocks, PackedVector2Array([Vector2(x5, float(rh)), Vector2(tip2 - 3.0, float(rh) - h5 * 0.8), Vector2(tip2, float(rh) - h5), Vector2(tip2 - 1.0, float(rh))]), basalt[2])
		line(rocks, int(tip2 - 3.0), int(float(rh) - h5 * 0.8), int(tip2), int(float(rh) - h5), basalt[3])
		var cy2: float = float(rh) - 2.0
		var crx2: float = tip2 + rng.randf_range(-3.0, 3.0)
		while cy2 > float(rh) - h5 * 0.7:
			px(rocks, int(crx2), int(cy2), Color("#a8380e") if rng.randf() < 0.7 else Color("#6a1e0a"))
			cy2 -= 1.0
			crx2 += rng.randf_range(-0.8, 0.8)
		x5 += w5 * rng.randf_range(1.2, 2.4)
	out["rocks"] = rocks

	# Lava lake surface (screen y 234..260), line-scrolled at runtime.
	var lw: int = 512
	var lh: int = 26
	var lava: Image = new_img(lw, lh)
	# noise is generated 4x narrower and stretched, so crust plates are long and flat
	# (the lake is seen at a grazing angle and line-scrolled)
	var nw4: int = lw / 4
	var ln_a: PackedFloat32Array = noise_field(nw4, lh, 8, 2, rng)
	var ln_b: PackedFloat32Array = noise_field(nw4, lh, 8, 2, rng)
	var hot: PackedColorArray = PackedColorArray([Color("#b0360c"), Color("#d65014"), Color("#f0721e"), Color("#ff9c38")])
	for y5: int in range(lh):
		for x6: int in range(lw):
			var fx6: float = float(x6) / 4.0
			var i0: int = int(fx6) % nw4
			var i1: int = (i0 + 1) % nw4
			var ft: float = fx6 - floorf(fx6)
			var a: float = lerpf(ln_a[y5 * nw4 + i0], ln_a[y5 * nw4 + i1], ft)
			var b: float = lerpf(ln_b[y5 * nw4 + i0], ln_b[y5 * nw4 + i1], ft)
			var c6: Color
			if a > 0.6:
				c6 = Color("#2a0806") if a > 0.66 else Color("#4a1006")
			elif a > 0.585:
				c6 = Color("#ff8a2c")
			else:
				# mostly solid bands of heat; dithering only right at the band edges
				var v6: float = clampf((0.585 - a) * 4.0 + (b - 0.5) * 0.8, 0.0, 0.999) * 4.0
				var i6: int = clampi(floori(v6 + (bayer(x6, y5) - 0.5) * 0.5), 0, 3)
				c6 = hot[i6]
			if absf(b - 0.5) < 0.012 and a < 0.5:
				c6 = Color("#ffcc4c")
			lava.set_pixel(x6, y5, c6)
	rect(lava, 0, 0, lw, 1, Color("#ffb040"))
	rect(lava, 0, 1, lw, 1, Color("#f07020"))
	out["lava"] = lava
	return out


# ---------------------------------------------------------------------------------------------
# 7) ABYSSAL TRENCH - sunken megalopolis
# ---------------------------------------------------------------------------------------------

static func build_abyss() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7707
	var out: Dictionary = {}

	var sky: Image = new_img(480, 270)
	sky.fill(Color("#0d3654"))
	vgrad(sky, 22, 258, PackedColorArray([Color("#0d3452"), Color("#0b2d49"), Color("#09263f"), Color("#071f35"), Color("#06192b"), Color("#041322"), Color("#030e1a")]), 0.45)
	out["sky"] = sky

	# Caustic shimmer near the top (tileable, drawn twice crossing).
	var cw: int = 512
	var ch: int = 22
	var caus: Image = new_img(cw, ch)
	for y: int in range(ch):
		for x: int in range(cw):
			var fx: float = float(x) * TAU / float(cw)
			var v: float = sin(fx * 9.0 + sin(float(y) * 0.45 + fx * 4.0) * 1.6) + sin(fx * 14.0 - float(y) * 0.3 + cos(fx * 6.0) * 1.2)
			var fade: float = 1.0 - float(y) / float(ch)
			if absf(v) < 0.16 and bayer(x, y) < fade * 1.05:
				caus.set_pixel(x, y, Color(0.35, 0.85, 0.95, 0.20 + 0.15 * fade))
	out["caustics"] = caus

	for k: int in range(2):
		var rays: Image = new_img(480, 232)
		for _r: int in range(5):
			var top_x: float = rng.randf_range(-40.0, 480.0)
			var slant: float = rng.randf_range(0.18, 0.34)
			var wid: float = rng.randf_range(8.0, 22.0)
			for y2: int in range(232):
				var cx: float = top_x + float(y2) * slant
				var w2: float = wid + float(y2) * 0.05
				var fade2: float = pow(1.0 - float(y2) / 232.0, 1.3)
				for x2: int in range(int(cx - w2), int(cx + w2) + 1):
					if x2 < 0 or x2 >= 480:
						continue
					var e: float = 1.0 - absf(float(x2) - cx) / w2
					if bayer(x2, y2) < e * fade2 * 1.2:
						rays.set_pixel(x2, y2, Color(0.4, 0.85, 0.92, 0.06))
		out["rays_%d" % k] = rays

	# Sunken megalopolis skyline (screen y 106..258).
	var mw: int = 768
	var mh: int = 152
	var city: Image = new_img(mw, mh)
	var windows: PackedVector2Array = PackedVector2Array()
	var body: Color = Color("#061724")
	var edge: Color = Color("#0a2130")
	var x3: int = 0
	while x3 < mw:
		var tw: int = rng.randi_range(10, 34)
		var th: int = rng.randi_range(40, 140)
		var lean: float = rng.randf_range(-0.06, 0.06)
		var top: int = mh - th
		for y3: int in range(top, mh):
			var ox: int = int(float(mh - y3) * lean)
			span(city, x3 + ox, x3 + ox + tw - 1, y3, body)
			px(city, x3 + ox, y3, edge)
		# broken / jagged top
		var kind: int = rng.randi_range(0, 2)
		if kind == 0:
			for j: int in range(tw):
				var bite: int = rng.randi_range(0, 6)
				vline(city, x3 + int(float(th) * lean) + j, top, top + bite, CLEAR)
		elif kind == 1:
			ellipse(city, float(x3) + float(tw) * 0.5 + float(th) * lean, float(top), float(tw) * 0.5, float(tw) * 0.35, body)
		else:
			var sx: int = x3 + tw / 2 + int(float(th) * lean)
			vline(city, sx, top - rng.randi_range(8, 20), top, edge)
		# window grid
		for wy: int in range(top + 6, mh - 4, 6):
			var ox2: int = int(float(mh - wy) * lean)
			for wx: int in range(x3 + 3, x3 + tw - 3, 4):
				if rng.randf() < 0.55:
					rect(city, wx + ox2, wy, 2, 2, Color("#0b2a3a"))
					if rng.randf() < 0.07:
						windows.append(Vector2(float(wx + ox2), float(wy)))
		# hanging seaweed silhouettes
		for _s: int in range(rng.randi_range(0, 3)):
			var sx2: int = x3 + rng.randi_range(0, tw)
			var sy: int = top + rng.randi_range(0, 20)
			for j2: int in range(rng.randi_range(4, 12)):
				px(city, sx2 + int(sin(float(j2) * 0.8) * 1.2), sy + j2, Color("#0a2422"))
		x3 += tw + rng.randi_range(2, 22)
	# domes and arches in front
	for _d: int in range(4):
		var dx: float = rng.randf_range(0.0, float(mw))
		var dr: float = rng.randf_range(14.0, 26.0)
		ellipse(city, dx, float(mh), dr, dr * 0.8, Color("#051420"))
		ellipse(city, dx - dr * 0.3, float(mh) - dr * 0.5, dr * 0.25, dr * 0.12, Color("#0a2130"))
	out["city"] = city
	out["windows"] = windows

	# Seabed rocks, coral and rubble (screen y 204..270).
	var sw: int = 768
	var sh: int = 66
	var bed: Image = new_img(sw, sh)
	var bp: PackedFloat32Array = profile(sw, rng, 5, 5, 0.55)
	var rock: PackedColorArray = PackedColorArray([Color("#040e16"), Color("#071722"), Color("#0b2030"), Color("#10293a")])
	for x4: int in range(sw):
		var t4: int = int(24.0 + (1.0 - bp[x4]) * 30.0)
		var lit: bool = bp[x4] > bp[posmod(x4 - 2, sw)]
		for y4: int in range(t4, sh):
			var c: Color = rock[1]
			if y4 - t4 < 2:
				c = rock[3] if lit else rock[2]
			elif bayer(x4, y4) < 0.2:
				c = rock[0]
			bed.set_pixel(x4, y4, c)
	var kelp: PackedVector3Array = PackedVector3Array()
	var anemones: PackedVector3Array = PackedVector3Array()
	for k2: int in range(14):
		var kx: float = (float(k2) + rng.randf_range(0.1, 0.9)) * float(sw) / 14.0
		var ktop: float = 24.0 + (1.0 - bp[int(kx)]) * 30.0
		kelp.append(Vector3(kx, ktop, rng.randf_range(44.0, 96.0)))
	for _a: int in range(10):
		var ax: int = rng.randi_range(0, sw - 1)
		var atop: int = int(24.0 + (1.0 - bp[ax]) * 30.0)
		anemones.append(Vector3(float(ax), float(atop), float(rng.randi_range(0, 1))))
		for t5: int in range(5):
			line(bed, ax, atop, ax - 2 + t5, atop - 3 - (t5 % 2), Color("#14403c"))
	# branching coral fans
	for _c: int in range(9):
		var cxx: int = rng.randi_range(0, sw - 1)
		var cyy: int = int(24.0 + (1.0 - bp[cxx]) * 30.0)
		var col: Color = Color("#24183a") if rng.randf() < 0.5 else Color("#123634")
		_coral(bed, cxx, cyy, rng.randf_range(-0.3, 0.3), 9.0, 3, col, rng)
	out["seabed"] = bed
	out["kelp"] = kelp
	out["anemones"] = anemones

	# Leviathan silhouette (2 frames 128x40).
	var whale: Image = new_img(128, 80)
	for f: int in range(2):
		var oy: float = float(f) * 40.0
		ellipse(whale, 56.0, oy + 20.0, 46.0, 12.0, Color("#041320"))
		ellipse(whale, 24.0, oy + 19.0, 18.0, 10.0, Color("#041320"))
		ellipse(whale, 60.0, oy + 26.0, 36.0, 4.0, Color("#071c2b"))
		var tail_dy: float = -6.0 if f == 0 else 5.0
		poly(whale, PackedVector2Array([Vector2(98.0, oy + 17.0), Vector2(112.0, oy + 19.0 + tail_dy * 0.4), Vector2(98.0, oy + 24.0)]), Color("#041320"))
		poly(whale, PackedVector2Array([Vector2(110.0, oy + 19.0 + tail_dy * 0.4), Vector2(126.0, oy + 12.0 + tail_dy), Vector2(122.0, oy + 20.0 + tail_dy * 0.5), Vector2(126.0, oy + 28.0 + tail_dy)]), Color("#041320"))
		poly(whale, PackedVector2Array([Vector2(40.0, oy + 28.0), Vector2(50.0, oy + 38.0 - absf(tail_dy) * 0.3), Vector2(54.0, oy + 28.0)]), Color("#03101b"))
		px(whale, 14, int(oy) + 18, Color("#1a6a7a"))
		for s2: int in range(8):
			px(whale, 30 + s2 * 8, int(oy) + 22 + (s2 % 2), Color("#0d3c48"))
	out["whale"] = whale

	# Jellyfish (2 frames 12x18).
	var jelly: Image = new_img(24, 18)
	for f2: int in range(2):
		var ox: int = f2 * 12
		var bw: float = 5.0 if f2 == 0 else 4.0
		var bh: float = 3.5 if f2 == 0 else 4.5
		ellipse(jelly, float(ox) + 6.0, 5.0, bw, bh, Color("#2a2456"))
		rect(jelly, ox + 1, 5, 10, 4, CLEAR)
		ellipse(jelly, float(ox) + 6.0, 4.5, bw - 1.5, bh - 1.5, Color("#3c3274"))
		rect(jelly, ox + int(6.0 - bw), 5, int(bw * 2.0), 1, Color("#4a3c8a"))
		for t6: int in range(4):
			var tx: int = ox + 3 + t6 * 2
			for j3: int in range(rng.randi_range(5, 11)):
				px(jelly, tx + int(sin(float(j3) * 0.9 + float(t6 + f2)) * 0.8), 6 + j3, Color("#221e48"))
	out["jelly"] = jelly
	return out


static func _coral(img: Image, x: int, y: int, ang: float, length: float, depth: int, col: Color, rng: RandomNumberGenerator) -> void:
	var ex: int = x + int(sin(ang) * length)
	var ey: int = y - int(cos(ang) * length)
	line(img, x, y, ex, ey, col)
	if depth > 0:
		_coral(img, ex, ey, ang - rng.randf_range(0.3, 0.6), length * 0.7, depth - 1, col, rng)
		_coral(img, ex, ey, ang + rng.randf_range(0.3, 0.6), length * 0.7, depth - 1, col, rng)


# ---------------------------------------------------------------------------------------------
# 8) CYBER NEXUS
# ---------------------------------------------------------------------------------------------

static func build_cyber() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8808
	var out: Dictionary = {}

	var sky: Image = new_img(480, 270)
	sky.fill(Color("#06020d"))
	vgrad(sky, 28, 206, PackedColorArray([Color("#06020d"), Color("#090314"), Color("#0d041d"), Color("#120627"), Color("#170831"), Color("#1d0a3b")]), 0.45)
	# synthwave sun, dim, striped, setting behind the grid horizon
	var sun: Vector2 = Vector2(312.0, 176.0)
	var sun_cols: PackedColorArray = PackedColorArray([Color("#3a0f46"), Color("#4a1450"), Color("#5a1a56"), Color("#6a2058"), Color("#782854")])
	for y: int in range(130, 206):
		for x: int in range(260, 366):
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(sun)
			if d > 44.0:
				continue
			var rel: float = (float(y) - (sun.y - 44.0)) / 88.0
			if y > int(sun.y) - 10:
				var period: int = 8
				var gap: int = clampi(int(float(y - (int(sun.y) - 10)) / 9.0) + 1, 1, 6)
				if posmod(y, period) < gap:
					continue
			sky.set_pixel(x, y, ramp_pick(sun_cols, rel, x, y))
	# scanlines over the upper sky
	for y2: int in range(30, 206, 3):
		for x2: int in range(480):
			var c: Color = sky.get_pixel(x2, y2)
			sky.set_pixel(x2, y2, c.darkened(0.18))
	# grid floor and ceiling plane bases
	vgrad(sky, 206, 258, PackedColorArray([Color("#1a0a34"), Color("#12062a"), Color("#0c041e")]), 0.5)
	out["sky"] = sky

	# Holographic city (screen y 90..206).
	var cw: int = 768
	var chh: int = 116
	var city: Image = new_img(cw, chh)
	var blinks: PackedVector2Array = PackedVector2Array()
	var holo: PackedVector4Array = PackedVector4Array()
	var x3: int = 0
	while x3 < cw:
		var tw: int = rng.randi_range(14, 40)
		var th: int = rng.randi_range(30, 110)
		var top: int = chh - th
		var is_holo: bool = rng.randf() < 0.3
		if is_holo:
			for y3: int in range(top, chh):
				for xx: int in range(x3, x3 + tw):
					if posmod(xx + y3, 4) == 0:
						px(city, xx, y3, Color(0.12, 0.35, 0.6, 0.55))
			rect(city, x3, top, tw, 1, Color("#2a6aa0"))
			vline(city, x3, top, chh - 1, Color("#1e4a7a"))
			vline(city, x3 + tw - 1, top, chh - 1, Color("#1e4a7a"))
			holo.append(Vector4(float(x3), float(top), float(tw), float(th)))
		else:
			rect(city, x3, top, tw, th, Color("#0d0420"))
			rect(city, x3, top, tw, 1, Color("#4a2280"))
			vline(city, x3, top, chh - 1, Color("#2c1458"))
			vline(city, x3 + tw - 1, top, chh - 1, Color("#1c0c3c"))
			for wy: int in range(top + 4, chh - 2, 4):
				for wx: int in range(x3 + 3, x3 + tw - 3, 3):
					if rng.randf() < 0.45:
						px(city, wx, wy, Color("#3a1a6a") if rng.randf() < 0.85 else Color("#6a3aa0"))
		if rng.randf() < 0.6:
			var ax: int = x3 + tw / 2
			var al: int = rng.randi_range(6, 16)
			vline(city, ax, top - al, top, Color("#2c1458"))
			blinks.append(Vector2(float(ax), float(top - al)))
		x3 += tw + rng.randi_range(1, 14)
	out["city"] = city
	out["blinks"] = blinks
	out["holo"] = holo

	# Falling glyph column (8 x 256, tiles vertically).
	var gl: Image = new_img(8, 256)
	var gy: int = 0
	while gy < 250:
		var bright: bool = rng.randf() < 0.18
		for yy: int in range(5):
			for xx2: int in range(1, 6):
				if rng.randf() < 0.5:
					px(gl, xx2, gy + yy, Color("#38c8a0") if bright else Color("#1a6a5a"))
		gy += 7
	out["glyphs"] = gl
	return out
