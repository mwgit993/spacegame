extends RefCounted

# TOXIC SWAMP sprites. build() runs on a worker thread, so it only paints Images. Every key
# starts with the stage id ("swamp_...", "boss_swamp_..."). Enemies face left, toward the player.
# Palette: sickly yellow-green gas sacs with purple veins, rotten purple-brown carapace with acid
# spots, a dark carnivorous pod with pale teeth, magenta fungus, and a mud-and-moss behemoth.

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const SAC: Array[Color] = [Color("#34440f"), Color("#64841c"), Color("#a2c436"), Color("#e2f088")]
const SAC_HOT: Array[Color] = [Color("#4e6e14"), Color("#8cbc24"), Color("#d2ee5c"), Color("#fcffcc")]
const VEIN: Color = Color("#6a2c64")
const VEIN_HOT: Color = Color("#e04aa8")
const SHELL: Array[Color] = [Color("#1c1222"), Color("#3a2a40"), Color("#5e4866"), Color("#8c7494")]
const ACID: PackedColorArray = [Color("#1c3a08"), Color("#468a10"), Color("#86d41c"), Color("#d2ff58"), Color("#f6ffd0")]
const POD: Array[Color] = [Color("#1e2e10"), Color("#3a5a1a"), Color("#5e8a26"), Color("#94bc44")]
const ROT: Array[Color] = [Color("#2a1a0e"), Color("#4a3018"), Color("#6e4a24"), Color("#9a7040")]
const BONE: Color = Color("#d0c890")
const BONE_D: Color = Color("#7e7448")
const FUNGUS: PackedColorArray = [Color("#3a0a2a"), Color("#7a1a5a"), Color("#c23c8e"), Color("#ff84cc")]
const MUD: PackedColorArray = [Color("#0e0a06"), Color("#1e160d"), Color("#322616"), Color("#4a3a22"), Color("#645034"), Color("#7e6a46")]
const MOSS: PackedColorArray = [Color("#10180a"), Color("#1e2c0e"), Color("#324614"), Color("#4c621c"), Color("#70862c")]
const WOOD: PackedColorArray = [Color("#0e0b12"), Color("#1e1826"), Color("#342a3e"), Color("#4e4258"), Color("#6e6278")]


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(3):
		out[id + "_bloater_%d" % f] = Kit.outline(_bloater(f))
		out[id + "_crawler_%d" % f] = Kit.outline(_crawler(f))
		out[id + "_spitter_%d" % f] = Kit.outline(_spitter(f))
	out[id + "_acid"] = Kit.outline(_glob(7, false))
	out[id + "_glob"] = Kit.outline(_glob(9, true))
	out[id + "_drop"] = _drop()
	out[id + "_seed"] = Kit.outline(_seed())
	out[id + "_pollen"] = _pollen()
	out[id + "_pod"] = Kit.outline(_pod())
	for g: int in range(2):
		out[id + "_gas_%d" % g] = _gas(g)
	var base: Image = _paint_boss_base()
	for f2: int in range(3):
		out["boss_%s_%d" % [id, f2]] = _paint_boss(base, f2)
	return out


# --- Gas bloater: a floating sac with a puckered vent and dangling tendrils ------------------------
# Frame 0 resting, 1 swelling, 2 fully swollen and glowing (the telegraph).

static func _bloater(frame: int) -> Image:
	var img: Image = Kit.blank(26, 30)
	var r: float = float([7.0, 8.6, 10.2][frame])
	var cx: float = 13.0
	var cy: float = 12.0
	var ramp: Array[Color] = SAC_HOT if frame == 2 else SAC
	# Tendrils first (behind the sac).
	for k: int in range(4):
		var tx: float = cx - 5.0 + float(k) * 3.4
		var len_t: float = 9.0 + float((k * 5) % 3) * 2.0 - float(frame)
		var prev: Vector2 = Vector2(tx, cy + r * 0.7)
		for s: int in range(1, 5):
			var p: Vector2 = Vector2(tx + sin(float(s) * 1.3 + float(k)) * 1.2, cy + r * 0.7 + len_t * float(s) / 4.0)
			Kit.line(img, prev, p, Color("#3a2034") if s < 3 else Color("#5a3450"))
			prev = p
		Kit.put(img, int(prev.x), int(prev.y), Color("#c070a8") if frame < 2 else VEIN_HOT)
	Kit.ball(img, cx, cy, r, r * 0.92, ramp)
	# Veins across the sac.
	var vein: Color = VEIN_HOT if frame == 2 else VEIN
	for v: int in range(3):
		var a0: float = -1.2 + float(v) * 1.1
		var p0: Vector2 = Vector2(cx + cos(a0) * r * 0.25, cy + sin(a0) * r * 0.25)
		var p1: Vector2 = Vector2(cx + cos(a0 + 0.4) * r * 0.85, cy + sin(a0 + 0.4) * r * 0.8)
		Kit.line(img, p0, p1, vein)
	# Pale blotches (thin skin).
	Kit.put(img, int(cx + r * 0.35), int(cy - r * 0.5), ramp[3])
	Kit.put(img, int(cx + r * 0.15), int(cy + r * 0.35), ramp[2])
	# Puckered vent on the left, with magenta lips.
	var vx: int = int(cx - r + 1.0)
	Kit.rect(img, vx - 1, int(cy) - 1, 3, 3, FUNGUS[1])
	Kit.put(img, vx, int(cy), Color("#0c0808") if frame < 2 else ACID[4])
	Kit.put(img, vx - 1, int(cy) - 1, FUNGUS[2])
	Kit.put(img, vx - 1, int(cy) + 1, FUNGUS[2])
	# A small mean eye above the vent.
	Kit.put(img, vx + 3, int(cy) - 3, Color("#140808"))
	Kit.put(img, vx + 4, int(cy) - 3, Color("#ff5a20") if frame == 2 else Color("#c0401a"))
	return img


# --- Bog crawler: a segmented leech-beetle, low on the bog; frame 2 reared up -------------------

static func _crawler(frame: int) -> Image:
	var img: Image = Kit.blank(38, 24)
	var reared: bool = frame == 2
	# Segments from tail (right) to head (left).
	var segs: Array[Vector3] = []
	for i: int in range(5):
		var sx: float = 32.0 - float(i) * 5.4
		var sy: float = 16.0
		if reared:
			sy = 16.0 - maxf(0.0, float(i) - 1.5) * 3.2
		var sr: float = 4.2 + (1.0 if i == 2 or i == 3 else 0.0) - (0.8 if i == 0 else 0.0)
		segs.append(Vector3(sx, sy, sr))
	# Legs (alternate per frame).
	for i2: int in range(1, 5):
		var s: Vector3 = segs[i2]
		var kick: float = 1.5 if (i2 + frame) % 2 == 0 else -1.5
		if reared and i2 >= 3:
			kick = -2.0
		Kit.line(img, Vector2(s.x, s.y + 2.0), Vector2(s.x + kick, 22.0), Color("#2a1e30"))
		Kit.put(img, int(s.x + kick), 22, Color("#5a4862"))
	# Tail stinger.
	Kit.line(img, Vector2(34.0, 16.0), Vector2(37.0, 13.0), SHELL[1])
	Kit.put(img, 37, 12, ACID[3])
	for i3: int in range(segs.size()):
		var sg: Vector3 = segs[i3]
		Kit.ball(img, sg.x, sg.y, sg.z, sg.z * 0.82, SHELL)
		# Dorsal spine and a glowing acid spot on each segment.
		Kit.put(img, int(sg.x), int(sg.y - sg.z * 0.82), SHELL[3])
		Kit.put(img, int(sg.x) + 1, int(sg.y - sg.z * 0.82) - 1, SHELL[2])
		if i3 < 4:
			Kit.put(img, int(sg.x) - 1, int(sg.y - sg.z * 0.3), ACID[3] if reared else ACID[2])
			Kit.put(img, int(sg.x) - 1, int(sg.y - sg.z * 0.3) + 1, ACID[1])
		# Segment seam.
		Kit.line(img, Vector2(sg.x + sg.z * 0.7, sg.y - sg.z * 0.5), Vector2(sg.x + sg.z * 0.7, sg.y + sg.z * 0.5), SHELL[0])
	# Head with long mandibles.
	var head: Vector3 = segs[4]
	var hx: float = head.x - 3.5
	var hy: float = head.y + (-1.0 if reared else 0.5)
	Kit.ball(img, hx, hy, 4.0, 3.4, SHELL)
	var open: float = 3.0 if reared else 1.0
	Kit.line(img, Vector2(hx - 2.0, hy - 1.0), Vector2(hx - 6.0, hy - 1.5 - open), BONE_D)
	Kit.line(img, Vector2(hx - 6.0, hy - 1.5 - open), Vector2(hx - 7.0, hy - open), BONE)
	Kit.line(img, Vector2(hx - 2.0, hy + 1.0), Vector2(hx - 6.0, hy + 1.5 + open), BONE_D)
	Kit.line(img, Vector2(hx - 6.0, hy + 1.5 + open), Vector2(hx - 7.0, hy + open), BONE)
	if reared:
		Kit.rect(img, int(hx - 5.0), int(hy) - 1, 3, 3, ACID[3])
		Kit.put(img, int(hx - 5.0), int(hy), ACID[4])
	Kit.put(img, int(hx - 1.0), int(hy - 2.0), Color("#ff4a1a"))
	Kit.put(img, int(hx + 1.0), int(hy - 2.0), Color("#ff4a1a"))
	Kit.put(img, int(hx), int(hy - 3.0), Color("#7a1a0a"))
	return img


# --- Spitter: a carnivorous flower-pod, mouth to the left; 0 closed, 1 opening, 2 wide open -------

static func _spitter(frame: int) -> Image:
	var img: Image = Kit.blank(28, 28)
	var cx: float = 14.0
	var cy: float = 14.0
	var open: float = float([0.0, 0.34, 0.66][frame])
	# A collar of magenta-tipped petals behind the head.
	for k: int in range(7):
		var a: float = -PI * 0.75 + float(k) * (PI * 1.5 / 6.0)
		var dir: Vector2 = Vector2.from_angle(a)
		var root: Vector2 = Vector2(cx + 3.0, cy) + dir * 3.0
		var tip: Vector2 = Vector2(cx + 3.0, cy) + dir * (11.5 if k % 2 == 0 else 9.5)
		var side: Vector2 = Vector2(-dir.y, dir.x) * 2.2
		Painter.poly(img, PackedVector2Array([root - side, tip, root + side]), POD[1])
		Kit.line(img, root, tip, POD[2])
		Kit.put(img, int(tip.x), int(tip.y), FUNGUS[2] if frame < 2 else FUNGUS[3])
	Kit.ball(img, cx + 1.0, cy, 7.4, 6.8, POD)
	# Purple veins on the pod.
	Kit.line(img, Vector2(cx + 5.0, cy - 4.0), Vector2(cx + 1.0, cy - 2.0), Color("#3a2240"))
	Kit.line(img, Vector2(cx + 5.0, cy + 4.0), Vector2(cx + 1.0, cy + 3.0), Color("#3a2240"))
	if open > 0.0:
		var hinge: Vector2 = Vector2(cx + 3.0, cy)
		for s2: float in [-1.0, 1.0]:
			var a2: float = PI + s2 * open
			var tip2: Vector2 = hinge + Vector2.from_angle(a2) * 11.0
			var mid: Vector2 = hinge + Vector2.from_angle(a2 + s2 * 0.35) * 8.0
			Painter.poly(img, PackedVector2Array([hinge, mid, tip2, hinge + Vector2.from_angle(a2 - s2 * 0.25) * 7.0]), POD[2])
			# Red-magenta lip along the inner edge, white teeth.
			Kit.line(img, hinge + Vector2.from_angle(a2 - s2 * 0.18) * 3.0, tip2, FUNGUS[1])
			for t: int in range(4):
				var q: Vector2 = hinge + Vector2.from_angle(a2 - s2 * 0.16) * (4.0 + float(t) * 2.0)
				Kit.put(img, int(q.x), int(q.y - s2), BONE)
			var sp: Vector2 = hinge + Vector2.from_angle(a2 + s2 * 0.22) * 6.5
			Kit.put(img, int(sp.x), int(sp.y), FUNGUS[3] if frame == 2 else FUNGUS[2])
		var glow_r: float = 2.2 if frame == 1 else 3.4
		Kit.disc(img, cx - 2.0, cy, glow_r, ACID[2] if frame == 1 else ACID[3])
		Kit.disc(img, cx - 2.5, cy, glow_r * 0.5, ACID[4])
	else:
		# Closed: a red seam with interlocking teeth.
		Kit.line(img, Vector2(cx - 6.0, cy), Vector2(cx + 2.0, cy), FUNGUS[0])
		Kit.line(img, Vector2(cx - 6.0, cy - 1.0), Vector2(cx - 1.0, cy - 1.0), FUNGUS[1])
		for t2: int in range(4):
			Kit.put(img, int(cx - 6.0) + t2 * 2, int(cy) - 1 + (t2 % 2) * 2, BONE)
		Kit.put(img, int(cx) + 1, int(cy) - 4, FUNGUS[2])
		Kit.put(img, int(cx), int(cy) + 4, FUNGUS[2])
	return img


# --- Shots --------------------------------------------------------------------------------------

static func _glob(d: int, big: bool) -> Image:
	var img: Image = Kit.blank(d, d)
	var c: float = float(d) * 0.5
	Kit.disc(img, c, c, c, ACID[1])
	Kit.disc(img, c - 0.4, c - 0.4, c - 1.2, ACID[2])
	Kit.disc(img, c - 0.8, c - 0.8, c * 0.45, ACID[3])
	Kit.put(img, int(c - 1.0), int(c - 1.0), ACID[4])
	if big:
		Kit.put(img, int(c + 1.5), int(c + 1.0), ACID[3])
	return img


static func _drop() -> Image:
	var img: Image = Kit.blank(5, 5)
	Kit.disc(img, 2.5, 2.5, 2.4, ACID[1])
	Kit.disc(img, 2.2, 2.2, 1.4, ACID[3])
	Kit.put(img, 2, 2, ACID[4])
	return img


static func _seed() -> Image:
	var img: Image = Kit.blank(6, 6)
	Kit.disc(img, 3.0, 3.0, 3.0, FUNGUS[1])
	Kit.disc(img, 2.6, 2.6, 2.0, FUNGUS[2])
	Kit.put(img, 2, 2, FUNGUS[3])
	Kit.put(img, 3, 2, Color("#ffd8f0"))
	return img


static func _pollen() -> Image:
	var img: Image = Kit.blank(7, 7)
	Kit.disc(img, 3.5, 3.5, 3.5, Color(0.9, 0.85, 0.3, 0.45))
	Kit.disc(img, 3.5, 3.5, 2.3, Color("#e8d850"))
	Kit.disc(img, 3.2, 3.2, 1.2, Color("#fffbd0"))
	for k: int in range(4):
		var a: float = TAU * float(k) / 4.0 + 0.4
		Kit.put(img, int(3.5 + cos(a) * 3.0), int(3.5 + sin(a) * 3.0), Color("#c8b030"))
	return img


static func _pod() -> Image:
	var img: Image = Kit.blank(10, 11)
	Kit.ball(img, 5.0, 5.5, 4.2, 4.8, ROT)
	# Glowing rot cracks.
	Kit.line(img, Vector2(3.0, 3.0), Vector2(5.0, 6.0), ACID[3])
	Kit.line(img, Vector2(5.0, 6.0), Vector2(7.0, 5.0), ACID[2])
	Kit.put(img, 4, 8, ACID[3])
	Kit.put(img, 5, 1, Color("#1a2a0c"))
	Kit.put(img, 5, 0, Color("#3a5a16"))
	return img


# A drifting gas puff: dithered translucent edges around a denser core (two "boil" frames).
static func _gas(frame: int) -> Image:
	var img: Image = Kit.blank(15, 15)
	var lobes: Array[Vector3] = [Vector3(7.5, 7.5, 5.2), Vector3(5.0, 6.0, 3.6), Vector3(10.0, 8.5, 3.8), Vector3(7.5, 4.5, 3.4)]
	if frame == 1:
		lobes = [Vector3(7.5, 7.5, 5.4), Vector3(4.6, 8.4, 3.6), Vector3(10.4, 6.2, 3.6), Vector3(7.8, 10.6, 3.2)]
	for y: int in range(15):
		for x: int in range(15):
			var best: float = 0.0
			for l: Vector3 in lobes:
				var d: float = Vector2(float(x) + 0.5 - l.x, float(y) + 0.5 - l.y).length() / l.z
				best = maxf(best, 1.0 - d)
			if best <= 0.0:
				continue
			var b: float = Painter.bayer(x, y)
			if best < 0.22:
				if b < best * 3.2:
					img.set_pixel(x, y, Color(0.62, 0.78, 0.22, 0.5))
			elif best < 0.5:
				img.set_pixel(x, y, Color(0.66, 0.84, 0.24, 0.78) if b < 0.7 else Color(0.5, 0.66, 0.16, 0.7))
			else:
				img.set_pixel(x, y, Color(0.84, 0.96, 0.42, 0.92) if b < (best - 0.5) * 2.5 else Color(0.7, 0.88, 0.28, 0.88))
	Kit.put(img, 6, 6, Color(0.98, 1.0, 0.8, 1.0))
	Kit.put(img, 7, 6, Color(0.98, 1.0, 0.8, 0.9))
	return img


# --- BOG BEHEMOTH ---------------------------------------------------------------------------------
# A hulking mud-and-moss mound risen out of the bog: dead trees on its back draped with moss, a
# forward-hunched head with a gaping toxic maw, small burning eyes, acid boils and magenta fungus,
# mud tendrils dripping beneath. The body is painted once; frames add the maw, eyes and glow:
# 0 and 1 breathe (maw ajar), 2 attacks (maw wide, throat and eyes blazing).

const BW: int = 124
const BH: int = 152
const MAW: Vector2 = Vector2(30.0, 98.0)
const EYES: Array[Vector2] = [Vector2(22.0, 78.0), Vector2(37.0, 74.0)]
const LOBES: Array[Vector4] = [
	Vector4(72.0, 88.0, 46.0, 44.0),   # main mound
	Vector4(36.0, 90.0, 28.0, 25.0),   # hunched head
	Vector4(80.0, 56.0, 34.0, 22.0),   # shoulder hump (the trees grow here)
	Vector4(58.0, 112.0, 40.0, 20.0),  # belly sagging into the drips
]


static func _lobe_field(x: float, y: float) -> Vector3:
	# Returns (strength, lobe index, lumpiness-adjusted d) of the strongest lobe.
	var best: float = -9.0
	var bi: int = 0
	for i: int in range(LOBES.size()):
		var l: Vector4 = LOBES[i]
		var dx: float = (x - l.x) / l.z
		var dy: float = (y - l.y) / l.w
		var ang: float = atan2(dy, dx)
		var lump: float = 1.0 + 0.07 * sin(ang * 5.0 + float(i) * 1.7) + 0.05 * sin(ang * 9.0 + float(i))
		var f: float = 1.0 - sqrt(dx * dx + dy * dy) / lump
		if f > best:
			best = f
			bi = i
	return Vector3(best, float(bi), 0.0)


static func _paint_boss_base() -> Image:
	var img: Image = BossPainter._new_img(BW, BH)
	var noise: PackedByteArray = Painter.fast_field(BW, BH, 9.0, 3, 2121)
	var moss_n: PackedByteArray = Painter.fast_field(BW, BH, 14.0, 2, 2122)
	var ld: Vector3 = Vector3(-0.55, -0.7, 0.55).normalized()
	var mask: PackedByteArray = PackedByteArray()
	mask.resize(BW * BH)
	for y: int in range(BH):
		for x: int in range(BW):
			var fx: float = float(x) + 0.5
			var fy: float = float(y) + 0.5
			var fl: Vector3 = _lobe_field(fx, fy)
			var inside: bool = fl.x > 0.0
			# Below y 120 the body breaks up into dripping mud tendrils.
			var bottom: float = 124.0 + 5.0 * sin(fx * 0.37) + 3.0 * sin(fx * 0.91 + 1.0)
			if fy > bottom:
				var drip_len: float = 0.0
				var col_k: int = (x * 7 + 3) % 11
				if col_k == 0 or col_k == 1:
					drip_len = 10.0 + float((x * 13) % 17)
				elif col_k == 5:
					drip_len = 5.0 + float((x * 5) % 7)
				inside = inside and fy < bottom + drip_len
			if not inside:
				continue
			mask[y * BW + x] = 1
			var l: Vector4 = LOBES[int(fl.y)]
			var nx: float = (fx - l.x) / l.z
			var ny: float = (fy - l.y) / l.w
			var nz: float = sqrt(maxf(0.04, 1.0 - minf(1.0, nx * nx + ny * ny)))
			var n: Vector3 = Vector3(nx, ny, nz).normalized()
			var lam: float = maxf(0.0, n.dot(ld))
			var nv: float = float(noise[y * BW + x]) / 255.0
			var v: float = 0.12 + lam * 0.78 + (nv - 0.5) * 0.34
			if fy > bottom - 2.0:
				v *= 0.55
			var mv: float = float(moss_n[y * BW + x]) / 255.0
			var col: Color
			if mv > 0.5 and n.y < 0.15 and fy < 118.0:
				col = Painter.ramp_pick(MOSS, v * 0.95 + (mv - 0.5) * 0.4, x, y)
			else:
				col = Painter.ramp_pick(MUD, v, x, y)
			img.set_pixel(x, y, col)
	# Dark rim.
	for y2: int in range(BH):
		for x2: int in range(BW):
			if mask[y2 * BW + x2] == 0:
				continue
			var edge: bool = x2 == 0 or y2 == 0 or x2 == BW - 1 or y2 == BH - 1
			if not edge:
				edge = mask[y2 * BW + x2 - 1] == 0 or mask[y2 * BW + x2 + 1] == 0 or mask[(y2 - 1) * BW + x2] == 0 or mask[(y2 + 1) * BW + x2] == 0
			if edge:
				img.set_pixel(x2, y2, Color("#080604"))
	# Dead trees growing out of the shoulder hump, with moss hanging off the branches.
	var trees: Array[Vector4] = [Vector4(66.0, 46.0, -0.18, 40.0), Vector4(88.0, 40.0, 0.08, 38.0), Vector4(108.0, 54.0, 0.32, 30.0)]
	for t: int in range(trees.size()):
		var tr: Vector4 = trees[t]
		var base_p: Vector2 = Vector2(tr.x, tr.y)
		var dir: Vector2 = Vector2(sin(tr.z), -cos(tr.z))
		var top: Vector2 = base_p + dir * tr.w
		_trunk(img, base_p, top, 3.0, 1.0)
		for b: int in range(3):
			var at: float = 0.4 + float(b) * 0.22
			var bp: Vector2 = base_p.lerp(top, at)
			var side: float = -1.0 if (b + t) % 2 == 0 else 1.0
			var bdir: Vector2 = dir.rotated(side * (0.9 + 0.2 * float(b)))
			var bend: Vector2 = bp + bdir * (13.0 - float(b) * 3.0)
			_trunk(img, bp, bend, 1.4, 0.6)
			var twig: Vector2 = bend + bdir.rotated(-side * 0.7) * 5.0
			Kit.line(img, bend, twig, WOOD[2])
			# Moss strands hanging down from the branch.
			for m: int in range(3):
				var mp: Vector2 = bp.lerp(bend, 0.35 + float(m) * 0.25)
				var mlen: int = 4 + (m * 7 + t * 3 + b) % 7
				for k: int in range(mlen):
					var c: Color = MOSS[3] if k < 2 else (MOSS[2] if k < mlen - 2 else MOSS[1])
					BossPainter._px(img, int(mp.x) + (1 if k > 3 and m % 2 == 0 else 0), int(mp.y) + 1 + k, c)
	# Mud tendrils' glistening tips and roots dangling below the belly.
	for r: int in range(7):
		var rx: float = 34.0 + float(r) * 11.0
		var ry: float = 118.0 + float((r * 5) % 4) * 2.0
		var rend: Vector2 = Vector2(rx + float(r % 3) - 1.0, ry + 12.0 + float((r * 7) % 9))
		Kit.line(img, Vector2(rx, ry), rend, Color("#1a120a"))
		BossPainter._px(img, int(rend.x), int(rend.y), Color("#3a2a18"))
	# Acid boils on the hide.
	var boils: Array[Vector3] = [Vector3(60.0, 74.0, 3.0), Vector3(92.0, 80.0, 2.0), Vector3(78.0, 102.0, 3.0), Vector3(50.0, 60.0, 2.0), Vector3(104.0, 98.0, 2.0)]
	for bo: Vector3 in boils:
		BossPainter._glow_orb(img, int(bo.x), int(bo.y), int(bo.z), ACID[1], ACID[3], ACID[4])
	# Magenta fungus shelves on the flank.
	var caps: Array[Vector2] = [Vector2(110.0, 72.0), Vector2(114.0, 80.0), Vector2(106.0, 86.0), Vector2(46.0, 116.0)]
	for cp: Vector2 in caps:
		Painter.ellipse(img, cp.x, cp.y, 4.0, 2.0, FUNGUS[0])
		Painter.ellipse(img, cp.x, cp.y - 0.5, 3.4, 1.4, FUNGUS[2])
		BossPainter._px(img, int(cp.x) - 1, int(cp.y) - 1, FUNGUS[3])
	# Brow ridge over the eyes.
	for i: int in range(18):
		var bx: float = 16.0 + float(i)
		var by: float = 73.0 - float(i) * 0.3 + (1.0 if i % 4 == 0 else 0.0)
		BossPainter._px(img, int(bx), int(by), Color("#0e0a06"))
		BossPainter._px(img, int(bx), int(by) - 1, MUD[4])
	return img


static func _trunk(img: Image, a: Vector2, b: Vector2, r0: float, r1: float) -> void:
	var steps: int = maxi(1, int(a.distance_to(b)))
	var dir: Vector2 = (b - a).normalized()
	var nrm: Vector2 = Vector2(-dir.y, dir.x)
	for i: int in range(steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector2 = a.lerp(b, t)
		var r: float = lerpf(r0, r1, t)
		var ri: int = int(ceilf(r))
		for k: int in range(-ri - 1, ri + 2):
			var q: Vector2 = p + nrm * float(k)
			var c: Color = WOOD[0]
			if absf(float(k)) <= r:
				var s: float = float(k) / maxf(0.5, r)
				c = WOOD[3] if s < -0.4 else (WOOD[2] if s < 0.3 else WOOD[1])
				if (i + k * 3) % 7 == 0:
					c = WOOD[1]
			elif absf(float(k)) > r + 1.0:
				continue
			BossPainter._px(img, int(q.x), int(q.y), c)


static func _paint_boss(base: Image, frame: int) -> Image:
	var img: Image = base.duplicate() as Image
	var ry: float = float([6.0, 8.0, 12.5][frame])
	var rx: float = 15.0 if frame < 2 else 17.0
	# Lips, then the black maw, then the glowing throat.
	Painter.ellipse(img, MAW.x, MAW.y, rx + 2.0, ry + 2.0, Color("#1a1208"))
	Painter.ellipse(img, MAW.x + 0.5, MAW.y, rx, ry, Color("#060803"))
	var glow_cols: Array[Color] = [ACID[1], ACID[2], ACID[3]]
	if frame == 2:
		glow_cols = [ACID[2], ACID[3], ACID[4]]
	Painter.ellipse(img, MAW.x + 4.0, MAW.y + 1.0, rx * 0.62, ry * 0.6, glow_cols[0])
	Painter.ellipse(img, MAW.x + 5.0, MAW.y + 1.0, rx * 0.4, ry * 0.38, glow_cols[1])
	Painter.ellipse(img, MAW.x + 5.5, MAW.y + 1.0, rx * 0.18, ry * 0.18, glow_cols[2])
	# Teeth around the lips, pointing in.
	var n_teeth: int = 9
	for i: int in range(n_teeth):
		var u: float = (float(i) + 0.5) / float(n_teeth)
		var tx: float = MAW.x - rx + u * rx * 2.0
		var edge_dy: float = ry * sqrt(maxf(0.0, 1.0 - pow((tx - MAW.x) / rx, 2.0)))
		var tlen: int = 3 + (1 if i % 3 == 1 else 0) + (1 if frame == 2 else 0)
		for k: int in range(tlen):
			var wdt: int = maxi(0, 1 - k / 2)
			for w: int in range(-wdt, wdt + 1):
				BossPainter._px(img, int(tx) + w, int(MAW.y - edge_dy) + k, BONE if k < tlen - 1 else BONE_D)
				if i % 2 == 0:
					BossPainter._px(img, int(tx) + w + 1, int(MAW.y + edge_dy) - k, BONE if k < tlen - 1 else BONE_D)
	# Acid drool from the lower lip.
	var drools: Array[Vector2] = [Vector2(-8.0, 6.0), Vector2(1.0, 10.0), Vector2(8.0, 4.0)]
	for d: Vector2 in drools:
		var dx: int = int(MAW.x + d.x)
		var dy0: int = int(MAW.y + ry * sqrt(maxf(0.0, 1.0 - pow(d.x / rx, 2.0)))) + 1
		var dlen: int = int(d.y) + frame * 3
		for k2: int in range(dlen):
			BossPainter._px(img, dx, dy0 + k2, ACID[2] if k2 < dlen - 1 else ACID[3])
		BossPainter._px(img, dx, dy0 + dlen, ACID[4])
	# Eyes in dark sockets.
	for e: Vector2 in EYES:
		Painter.ellipse(img, e.x, e.y, 4.0, 3.0, Color("#060403"))
		if frame == 2:
			BossPainter._glow_orb(img, int(e.x), int(e.y), 2, Color("#c02a10"), Color("#ffb030"), Color("#fffbe0"))
		else:
			BossPainter._glow_orb(img, int(e.x), int(e.y), 2, Color("#7a2a0c"), Color("#e07a1c"), Color("#ffd060") if frame == 1 else Color("#ffb040"))
	# Boils pulse with the breathing.
	if frame >= 1:
		for bo: Vector2 in [Vector2(60.0, 74.0), Vector2(78.0, 102.0)]:
			BossPainter._px(img, int(bo.x) - 1, int(bo.y) - 1, Color.WHITE)
	return img
