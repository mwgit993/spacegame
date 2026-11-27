extends RefCounted

# STORM OCEAN sprites. build() runs on a worker thread, so it only paints Images. Every key starts
# with the stage id ("ocean_...", "boss_ocean_..."). Enemies face left, toward the player.
# Palette: gunmetal gunboats with a rust waterline and lit portholes, silver-blue flying fish with
# glassy wing-fins, plum-crimson kraken flesh with pale suckers and cyan storm-light spots, and
# bright sea-foam / flare-orange shots that stand out on the dark green-grey sea.

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

# Kraken flesh: outline, dark, mid, light, highlight.
const FLESH: Array[Color] = [Color("#1a0814"), Color("#4a1a36"), Color("#7a2c50"), Color("#a84a6c"), Color("#d8849c")]
const SUCKER: Color = Color("#ecc4c8")
const SUCKER_D: Color = Color("#9a6070")
const GLOW: Color = Color("#5af0e0")
const GLOW_D: Color = Color("#2a9a9a")
const STEEL: Array[Color] = [Color("#1c2228"), Color("#323c46"), Color("#56626e"), Color("#8c98a4")]
const RUST: Color = Color("#9a4426")
const LAMP: Color = Color("#ffd25a")



static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(3):
		out[id + "_gunboat_%d" % f] = Kit.outline(_gunboat(f))
		out[id + "_fish_%d" % f] = Kit.outline(_fish(f))
	for f2: int in range(2):
		out[id + "_tip_%d" % f2] = Kit.outline(_tip(f2))
	out[id + "_shot"] = _shot()
	out[id + "_drop"] = _drop()
	out[id + "_shell_0"] = _shell(0)
	out[id + "_shell_1"] = _shell(1)
	for f3: int in range(3):
		out["boss_%s_%d" % [id, f3]] = _paint_boss(f3)
	return out


# --- Gunboat: a squat armoured patrol boat, bow left. -------------------------------------------
# Frame 0 gun level, 1 gun raised (aiming the mortar), 2 raised with the muzzle flash.

static func _gunboat(frame: int) -> Image:
	var img: Image = Kit.blank(36, 19)
	# Hull: raked bow at the left, flat stern at the right.
	var hull: PackedVector2Array = PackedVector2Array([Vector2(0.0, 10.0), Vector2(35.0, 10.0), Vector2(35.0, 15.0), Vector2(33.0, 17.0), Vector2(7.0, 17.0), Vector2(3.0, 14.0)])
	Painter.poly(img, hull, STEEL[1])
	Painter.poly(img, PackedVector2Array([Vector2(1.0, 10.0), Vector2(35.0, 10.0), Vector2(35.0, 12.0), Vector2(2.0, 12.0)]), STEEL[2])
	Kit.rect(img, 1, 10, 34, 1, STEEL[3])
	# Rust waterline stripe and the dark wet hull below it.
	Kit.rect(img, 4, 14, 31, 1, RUST)
	Kit.rect(img, 6, 15, 28, 2, STEEL[0])
	Kit.put(img, 3, 14, Color("#5a2a18"))
	# Portholes.
	for px: int in [12, 17, 22, 27]:
		Kit.put(img, px, 12, LAMP if (px / 5 + frame) % 3 != 0 else Color("#b08a3a"))
	# Bow foam.
	Kit.put(img, 2, 15, Color("#e8f4f4"))
	Kit.put(img, 1, 16, Color("#a8c8c8"))
	Kit.put(img, 4, 17, Color("#c8e0e0"))
	# Bridge and funnel.
	Kit.rect(img, 15, 5, 11, 5, STEEL[2])
	Kit.rect(img, 15, 5, 11, 1, STEEL[3])
	Kit.rect(img, 17, 3, 7, 2, STEEL[2])
	Kit.rect(img, 17, 3, 7, 1, STEEL[3])
	Kit.rect(img, 16, 7, 9, 1, Color("#1a2a30"))
	for wx: int in [17, 19, 21, 23]:
		Kit.put(img, wx, 7, Color("#ffe8a0") if wx != 21 else LAMP)
	Kit.rect(img, 27, 4, 4, 6, STEEL[1])
	Kit.rect(img, 27, 4, 1, 6, STEEL[2])
	Kit.rect(img, 27, 4, 4, 1, RUST)
	# Mast with a lamp and an aerial.
	Kit.rect(img, 21, 0, 1, 3, STEEL[3])
	Kit.put(img, 20, 1, STEEL[2])
	Kit.put(img, 21, 0, Color("#ff5a4a"))
	# Aft flak gun.
	Kit.rect(img, 31, 8, 3, 2, STEEL[2])
	Kit.put(img, 33, 7, STEEL[3])
	# Deck gun: a domed turret and its barrel.
	var dome: Array[Color] = [STEEL[0], STEEL[1], STEEL[2], STEEL[3]]
	Kit.ball(img, 8.5, 8.5, 3.6, 2.6, dome)
	if frame == 0:
		Kit.line(img, Vector2(6.0, 7.0), Vector2(0.0, 7.0), STEEL[3])
		Kit.line(img, Vector2(6.0, 8.0), Vector2(1.0, 8.0), STEEL[1])
	else:
		Kit.line(img, Vector2(7.0, 7.0), Vector2(3.0, 3.0), STEEL[3])
		Kit.line(img, Vector2(7.0, 8.0), Vector2(3.0, 4.0), STEEL[1])
		Kit.put(img, 3, 3, STEEL[3])
		if frame == 2:
			Kit.put(img, 2, 2, Color.WHITE)
			Kit.put(img, 1, 1, Color("#ffe27a"))
			Kit.put(img, 2, 1, Color("#ffb040"))
			Kit.put(img, 1, 2, Color("#ffb040"))
			Kit.put(img, 0, 0, Color("#ff8a30"))
	return img


# --- Flying fish: silver-blue torpedo with long glassy wing-fins, nose left. ------------------------
# Frame 0 fins spread (gliding), 1 fins half-folded (flapping), 2 fins tucked (diving).

static func _fish(frame: int) -> Image:
	var img: Image = Kit.blank(22, 15)
	var cy: float = 7.0
	var fin_a: Color = Color(0.62, 0.9, 1.0, 0.8)
	var fin_b: Color = Color(0.4, 0.7, 0.9, 0.85)
	var rib: Color = Color("#2a5c84")
	# Big rounded pectoral "wings" behind the head (dragonfly-like, not swept like a jet's).
	if frame < 2:
		var reach: float = 6.4 if frame == 0 else 4.2
		var back_x: float = 13.0 if frame == 0 else 14.5
		for side: float in [-1.0, 1.0]:
			var pts: PackedVector2Array = PackedVector2Array()
			var root: Vector2 = Vector2(7.0, cy + side * 1.0)
			for k: int in range(9):
				var a: float = float(k) / 8.0 * PI
				var ex: Vector2 = Vector2(lerpf(7.5, back_x, (1.0 - cos(a)) * 0.5), cy + side * (1.0 + sin(a) * reach))
				pts.append(ex)
			pts.append(Vector2(back_x - 1.0, cy + side * 1.0))
			Painter.poly(img, pts, fin_a if side < 0.0 else fin_b)
			for r: int in range(4):
				var a2: float = (0.2 + float(r) * 0.22) * PI
				var tip: Vector2 = Vector2(lerpf(7.5, back_x, (1.0 - cos(a2)) * 0.5), cy + side * (1.0 + sin(a2) * reach))
				Kit.line(img, root, tip, rib)
	else:
		Kit.line(img, Vector2(8.0, cy - 2.0), Vector2(15.0, cy - 3.0), fin_b)
		Kit.line(img, Vector2(8.0, cy + 2.0), Vector2(15.0, cy + 3.0), fin_b)
	# Forked tail, the lower lobe longer.
	Painter.poly(img, PackedVector2Array([Vector2(16.0, cy - 0.5), Vector2(20.0, cy - 4.0), Vector2(18.5, cy), Vector2(21.5, cy + 5.0), Vector2(16.0, cy + 1.0)]), Color("#3a78a8"))
	Kit.put(img, 20, int(cy) - 3, Color("#7ab8d8"))
	# Body: dark teal-blue back, silver flank with a lateral line, white belly.
	var scales: Array[Color] = [Color("#1a3a5a"), Color("#3a74a0"), Color("#98c8e0"), Color("#eef8ff")]
	Kit.ball(img, 9.5, cy, 8.0, 2.8, scales)
	Kit.rect(img, 3, int(cy) + 1, 11, 1, Color("#dcf0fa"))
	Kit.rect(img, 4, int(cy) - 2, 10, 1, Color("#22486e"))
	for sx: int in range(6, 15, 2):
		Kit.put(img, sx, int(cy), Color("#6a9cc0"))
	# Small pelvic fin.
	Kit.put(img, 12, int(cy) + 3, fin_b)
	Kit.put(img, 13, int(cy) + 3, fin_b)
	# Big round eye with a glint, and the mouth.
	Kit.rect(img, 3, int(cy) - 1, 2, 2, Color("#0c1218"))
	Kit.put(img, 3, int(cy) - 1, Color("#ffffff"))
	Kit.put(img, 1, int(cy) + 1, Color("#16304c"))
	Kit.put(img, 2, int(cy) + 1, Color("#16304c"))
	return img


# --- Tentacle tip: the hooked, sucker-lined end of a kraken arm, curling over at the end. It is
# drawn pointing up; its root joins the drawn body. Frame 1: suckers lit for the slam (telegraph).

static func _tip(frame: int) -> Image:
	var img: Image = Kit.blank(16, 24)
	var pts: PackedVector2Array = PackedVector2Array([Vector2(8.0, 23.0), Vector2(8.0, 17.0), Vector2(7.0, 12.0), Vector2(5.0, 8.0), Vector2(3.8, 4.5), Vector2(5.5, 1.8), Vector2(9.0, 1.4), Vector2(11.6, 3.6), Vector2(11.0, 6.6), Vector2(8.8, 7.4)])
	_tube(img, pts, 3.6, 0.7, FLESH, SUCKER if frame == 0 else Color("#ffe27a"), 1.0, false)
	if frame == 1:
		Kit.put(img, 10, 3, Color.WHITE)
		Kit.put(img, 5, 12, Color("#fff4b0"))
		Kit.put(img, 4, 8, Color("#fff4b0"))
	return img


# --- Shots -------------------------------------------------------------------------------------

# Sea-foam orb (StageData "bullet_b"): pale aqua ring, white core.
static func _shot() -> Image:
	var img: Image = Kit.blank(7, 7)
	Kit.disc(img, 3.5, 3.5, 3.5, Color(0.35, 0.9, 1.0, 0.5))
	Kit.disc(img, 3.5, 3.5, 2.5, Color("#8ef0ff"))
	Kit.disc(img, 3.5, 3.5, 1.4, Color.WHITE)
	return img


# A water droplet pointing right (the bullet rotates it to its flight direction).
static func _drop() -> Image:
	var img: Image = Kit.blank(9, 5)
	Kit.disc(img, 6.0, 2.5, 2.5, Color("#8ef0ff"))
	Kit.line(img, Vector2(0.0, 2.0), Vector2(5.0, 2.0), Color(0.55, 0.95, 1.0, 0.6))
	Kit.line(img, Vector2(2.0, 1.0), Vector2(5.0, 1.0), Color(0.55, 0.95, 1.0, 0.45))
	Kit.line(img, Vector2(2.0, 3.0), Vector2(5.0, 3.0), Color(0.55, 0.95, 1.0, 0.45))
	Kit.disc(img, 6.5, 2.5, 1.3, Color.WHITE)
	return img


# The gunboat's mortar shell: an orange-hot incendiary with a sputtering fuse (2 frames).
static func _shell(frame: int) -> Image:
	var img: Image = Kit.blank(9, 9)
	Kit.disc(img, 4.5, 4.5, 4.4, Color(1.0, 0.45, 0.15, 0.45))
	Kit.disc(img, 4.5, 4.5, 3.2, Color("#ff8a30"))
	Kit.disc(img, 4.0, 4.0, 2.0, Color("#ffd25a"))
	Kit.disc(img, 3.6, 3.6, 0.9, Color.WHITE)
	if frame == 1:
		Kit.put(img, 7, 1, Color("#fff4b0"))
		Kit.put(img, 8, 0, Color("#ffd25a"))
	else:
		Kit.put(img, 1, 7, Color("#fff4b0"))
		Kit.put(img, 0, 8, Color("#ff8a30"))
	return img


# --- Shared painting helpers ---------------------------------------------------------------------

# A shaded fleshy tube along a polyline whose radius goes r0 -> r1: dark outline, body, a lit
# upper-left ridge, and sucker dots along one side (side_sign picks which). Used for the tentacle
# tip and the boss's arms.
static func _tube(img: Image, pts: PackedVector2Array, r0: float, r1: float, ramp: Array[Color], suck: Color, side_sign: float, outline: bool = true) -> void:
	var samples: PackedVector3Array = PackedVector3Array()   # x, y, radius
	var tangents: PackedVector2Array = PackedVector2Array()
	var total: float = 0.0
	for i: int in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	var run: float = 0.0
	for i2: int in range(pts.size() - 1):
		var a: Vector2 = pts[i2]
		var b: Vector2 = pts[i2 + 1]
		var seg: float = a.distance_to(b)
		var steps: int = maxi(1, int(seg * 1.6))
		for s: int in range(steps):
			var t: float = float(s) / float(steps)
			var p: Vector2 = a.lerp(b, t)
			var u: float = (run + seg * t) / maxf(0.001, total)
			samples.append(Vector3(p.x, p.y, lerpf(r0, r1, u)))
			tangents.append((b - a).normalized())
		run += seg
	samples.append(Vector3(pts[pts.size() - 1].x, pts[pts.size() - 1].y, r1))
	tangents.append(tangents[tangents.size() - 1] if tangents.size() > 0 else Vector2.UP)
	if outline:
		for q: Vector3 in samples:
			Kit.disc(img, q.x, q.y, q.z + 1.0, ramp[0])
	for q2: Vector3 in samples:
		Kit.disc(img, q2.x, q2.y, q2.z, ramp[1])
	for q3: Vector3 in samples:
		if q3.z >= 1.6:
			Kit.disc(img, q3.x - q3.z * 0.3, q3.y - q3.z * 0.32, q3.z * 0.6, ramp[2])
	for q4: Vector3 in samples:
		if q4.z >= 2.4:
			Kit.disc(img, q4.x - q4.z * 0.45, q4.y - q4.z * 0.5, maxf(0.6, q4.z * 0.22), ramp[3])
	# Suckers on the inner side, spaced by size.
	var next_at: float = 0.0
	var acc: float = 0.0
	for k: int in range(samples.size()):
		if k > 0:
			acc += Vector2(samples[k].x, samples[k].y).distance_to(Vector2(samples[k - 1].x, samples[k - 1].y))
		var r: float = samples[k].z
		if acc < next_at or r < 1.5:
			continue
		next_at = acc + maxf(2.5, r * 1.3)
		var n: Vector2 = Vector2(-tangents[k].y, tangents[k].x) * side_sign
		var c: Vector2 = Vector2(samples[k].x, samples[k].y) + n * (r * 0.62)
		Kit.put(img, int(round(c.x)), int(round(c.y)), suck)
		if r >= 3.0:
			Kit.put(img, int(round(c.x + n.x)), int(round(c.y + n.y)), SUCKER_D)


# --- Boss: MAELSTROM KRAKEN ---------------------------------------------------------------------
# A storm-scarred giant squid: a long plum mantle swept back to the upper right with two fins, a
# great amber eye with a slit pupil, a bone beak in a ring of arms, two long club tentacles
# reaching forward, barnacle crusts, cyan storm-light spots, a broken ship's mast and torn sail
# caught in its arms, and sea water streaming off it. Frames 0/1 idle (arms writhe), 2 attacking
# (arms flared, eye blazing, beak open).

const BOSS_W: int = 120
const BOSS_H: int = 158


static func _paint_boss(frame: int) -> Image:
	var img: Image = BossPainter._new_img(BOSS_W, BOSS_H)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2020
	var wob: float = 0.0 if frame == 0 else (1.0 if frame == 1 else 0.0)
	var flare: bool = frame == 2

	# The broken mast and torn sail, behind everything.
	var mast_a: Vector2 = Vector2(108.0, 6.0)
	var mast_b: Vector2 = Vector2(74.0, 120.0)
	BossPainter._thick_line(img, mast_a, mast_b, 2, Color("#5a3e2a"), Color("#8a6444"))
	Kit.line(img, Vector2(100.0, 24.0), Vector2(118.0, 30.0), Color("#3a2618"))
	Kit.line(img, Vector2(100.0, 25.0), Vector2(117.0, 31.0), Color("#6a4a30"))
	var sail: PackedVector2Array = PackedVector2Array([Vector2(103.0, 27.0), Vector2(117.0, 32.0), Vector2(116.0, 52.0 + wob), Vector2(110.0, 47.0), Vector2(106.0, 56.0), Vector2(101.0, 44.0)])
	Painter.poly(img, sail, Color("#3e4048"))
	Painter.poly(img, PackedVector2Array([Vector2(104.0, 28.0), Vector2(116.0, 33.0), Vector2(115.0, 42.0), Vector2(105.0, 38.0)]), Color("#5a5c64"))
	Kit.line(img, Vector2(108.0, 6.0), Vector2(118.0, 40.0), Color("#2a2420"))   # rigging rope

	# Back arms hanging down into the sea (behind the head).
	var back_arms: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(66.0, 108.0), Vector2(74.0, 126.0), Vector2(70.0, 142.0), Vector2(78.0, 154.0 - wob)]),
		PackedVector2Array([Vector2(58.0, 110.0), Vector2(60.0, 130.0), Vector2(52.0, 146.0 + wob), Vector2(58.0, 156.0)]),
	]
	var back_ramp: Array[Color] = [FLESH[0], FLESH[1], FLESH[2], FLESH[3]]
	for arm: PackedVector2Array in back_arms:
		_tube(img, arm, 6.0, 2.0, back_ramp, SUCKER_D, 1.0)

	# Mantle: a long tapered body swept up-right, shaded from the upper left, with dithering.
	var axis_a: Vector2 = Vector2(56.0, 98.0)   # base (at the head)
	var axis_b: Vector2 = Vector2(100.0, 14.0)  # tip
	var axis: Vector2 = (axis_b - axis_a)
	var alen: float = axis.length()
	var ad: Vector2 = axis / alen
	var an: Vector2 = Vector2(-ad.y, ad.x)
	var ramp: PackedColorArray = PackedColorArray([FLESH[1], FLESH[2], FLESH[3], FLESH[4]])
	for y: int in range(0, 112):
		for x: int in range(30, BOSS_W):
			var p: Vector2 = Vector2(float(x) + 0.5, float(y) + 0.5) - axis_a
			var along: float = p.dot(ad) / alen
			if along < -0.08 or along > 1.0:
				continue
			var half: float = 25.0 * sqrt(maxf(0.0, 1.0 - pow(maxf(0.0, along - 0.1) / 0.9, 2.2))) * (1.0 if along > 0.0 else (1.0 + along * 3.0))
			var across: float = p.dot(an)
			if absf(across) > half:
				continue
			var q: float = across / maxf(1.0, half)
			var nz: float = sqrt(maxf(0.0, 1.0 - q * q))
			var lam: float = clampf(0.35 + 0.55 * (-q * 0.75 + nz * 0.5) - along * 0.15, 0.0, 1.0)
			# Mottled skin.
			lam += 0.08 * sin(float(x) * 0.7 + float(y) * 0.31) * sin(float(y) * 0.5 - float(x) * 0.2)
			var c: Color = Painter.ramp_pick(ramp, lam, x, y)
			if absf(across) > half - 1.2:
				c = FLESH[0]
			img.set_pixel(x, y, c)
	# Fins at the mantle tip.
	for side: float in [-1.0, 1.0]:
		var root: Vector2 = axis_a + axis * 0.78 + an * side * 15.0
		var tipf: Vector2 = axis_a + axis * 0.98 + an * side * 30.0
		var back: Vector2 = axis_a + axis * 0.99
		Painter.poly(img, PackedVector2Array([root, tipf, back]), FLESH[0])
		Painter.poly(img, PackedVector2Array([root + an * side * 1.0, tipf - ad * 1.5, back - ad * 2.0]), FLESH[2] if side < 0.0 else FLESH[1])
		Kit.line(img, root, tipf, FLESH[3] if side < 0.0 else FLESH[2])
	# Ribs of muscle across the mantle.
	for r: int in range(4):
		var u: float = 0.3 + float(r) * 0.15
		var c0: Vector2 = axis_a + axis * u
		Kit.line(img, c0 - an * 14.0 + ad * 2.0, c0 + an * 4.0, FLESH[1])
	# Scars: pale slashes from old battles.
	Kit.line(img, Vector2(70.0, 44.0), Vector2(80.0, 58.0), FLESH[4])
	Kit.line(img, Vector2(71.0, 44.0), Vector2(81.0, 58.0), FLESH[1])
	Kit.line(img, Vector2(86.0, 30.0), Vector2(90.0, 40.0), FLESH[4])
	# Barnacle crusts.
	for b: int in range(26):
		var u2: float = rng.randf_range(0.15, 0.85)
		var v2: float = rng.randf_range(0.2, 0.95) * (1.0 if rng.randf() < 0.75 else -0.6)
		var bc: Vector2 = axis_a + axis * u2 + an * v2 * 20.0
		var br: float = rng.randf_range(0.8, 2.2)
		Kit.disc(img, bc.x, bc.y, br + 0.6, Color("#3a3a36"))
		Kit.disc(img, bc.x, bc.y, br, Color("#9a9c90"))
		Kit.put(img, int(bc.x), int(bc.y), Color("#262624"))
		Kit.put(img, int(bc.x) - 1, int(bc.y) - 1, Color("#d4d6c8"))
	# Storm-light spots: two curved rows of cyan photophores (brighter when attacking).
	for s: int in range(9):
		for row: int in range(2):
			var u3: float = 0.2 + float(s) * 0.075
			var off: float = -10.0 + float(row) * 14.0 + sin(float(s) * 0.9) * 2.0
			var sc: Vector2 = axis_a + axis * u3 + an * off
			var lit: Color = Color.WHITE if flare else GLOW
			Kit.put(img, int(sc.x), int(sc.y), lit if (s + row) % 2 == 0 else GLOW)
			Kit.put(img, int(sc.x) + 1, int(sc.y), GLOW_D)

	# Head below the mantle.
	var head_ramp: Array[Color] = [FLESH[1], FLESH[2], FLESH[3], FLESH[4]]
	Kit.ball(img, 54.0, 96.0, 22.0, 16.0, head_ramp)
	# The great eye: gold rim, amber iris, slit pupil; it blazes when attacking.
	var eye: Vector2 = Vector2(46.0, 92.0)
	Kit.disc(img, eye.x, eye.y, 10.5, FLESH[0])
	Kit.disc(img, eye.x, eye.y, 9.5, Color("#6a4a1a"))
	Kit.disc(img, eye.x, eye.y, 8.4, Color("#ffb030") if not flare else Color("#ffd25a"))
	Kit.disc(img, eye.x - 1.5, eye.y - 1.5, 5.2, Color("#ffd25a") if not flare else Color("#fff4b0"))
	var slit_w: int = 9 if not flare else 5
	Kit.rect(img, int(eye.x) - slit_w / 2, int(eye.y) - 1, slit_w, 3, Color("#140608"))
	Kit.rect(img, int(eye.x) - slit_w / 2 + 1, int(eye.y) - 2, slit_w - 2, 1, Color("#140608"))
	Kit.rect(img, int(eye.x) - slit_w / 2 + 1, int(eye.y) + 2, slit_w - 2, 1, Color("#140608"))
	Kit.put(img, int(eye.x) - 4, int(eye.y) - 5, Color.WHITE)
	Kit.put(img, int(eye.x) - 3, int(eye.y) - 5, Color.WHITE)
	# Heavy brow ridge.
	for bx: int in range(int(eye.x) - 10, int(eye.x) + 9):
		var by: int = int(eye.y) - 10 - int(2.0 * sin(float(bx - int(eye.x) + 10) / 19.0 * PI))
		Kit.put(img, bx, by, FLESH[0])
		Kit.put(img, bx, by - 1, FLESH[3])

	# Front arms in a ring around the beak, curling (they writhe between frames).
	var curl: float = 4.0 if frame == 1 else (-3.0 if frame == 0 else 0.0)
	var spread: float = 1.0 if not flare else 1.35
	var arms: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(44.0, 106.0), Vector2(30.0, 118.0 + curl), Vector2(22.0, 136.0), Vector2(30.0, 148.0 - curl), Vector2(38.0, 144.0)]),
		PackedVector2Array([Vector2(52.0, 110.0), Vector2(46.0, 128.0), Vector2(44.0, 144.0 + curl), Vector2(50.0, 156.0)]),
		PackedVector2Array([Vector2(40.0, 102.0), Vector2(24.0, 106.0 - curl * spread), Vector2(12.0, 116.0), Vector2(8.0, 128.0), Vector2(14.0, 132.0)]),
		PackedVector2Array([Vector2(38.0, 98.0), Vector2(22.0, 88.0 + curl), Vector2(14.0, 74.0), Vector2(20.0, 64.0 - curl), Vector2(26.0, 68.0)]),
	]
	for i: int in range(arms.size()):
		_tube(img, arms[i], 6.0, 1.6, FLESH, SUCKER, -1.0 if i == 3 else 1.0)
	# Two long club tentacles reaching forward, up and down.
	var club_up: PackedVector2Array = PackedVector2Array([Vector2(42.0, 100.0), Vector2(26.0, 84.0 - curl * 0.5), Vector2(14.0, 50.0 * (1.0 if not flare else 0.9)), Vector2(6.0, 36.0 - (6.0 if flare else 0.0)), Vector2(10.0, 26.0 - (6.0 if flare else 0.0))])
	var club_dn: PackedVector2Array = PackedVector2Array([Vector2(46.0, 108.0), Vector2(30.0, 126.0 + curl * 0.5), Vector2(16.0, 140.0 + (4.0 if flare else 0.0)), Vector2(5.0, 146.0 + (6.0 if flare else 0.0)), Vector2(4.0, 138.0 + (6.0 if flare else 0.0))])
	_tube(img, club_up, 4.0, 1.8, FLESH, SUCKER, -1.0)
	_tube(img, club_dn, 4.0, 1.8, FLESH, SUCKER, 1.0)
	for club: Vector2 in [club_up[club_up.size() - 2], club_dn[club_dn.size() - 2]]:
		Kit.disc(img, club.x, club.y, 4.6, FLESH[0])
		Kit.disc(img, club.x, club.y, 3.6, FLESH[2])
		Kit.disc(img, club.x - 1.0, club.y - 1.0, 1.8, FLESH[3])
		for k: int in range(5):
			var a: float = TAU * float(k) / 5.0
			Kit.put(img, int(club.x + cos(a) * 2.4), int(club.y + sin(a) * 2.4), SUCKER if not flare else Color("#ffe27a"))
	# The beak: a dark maw with two hooked bone halves, gaping when it attacks.
	var beak: Vector2 = Vector2(36.0, 108.0)
	var gape: float = 2.0 if not flare else 5.0
	Kit.disc(img, beak.x, beak.y, 6.5, FLESH[0])
	Kit.disc(img, beak.x, beak.y, 5.0, Color("#0c0408"))
	Painter.poly(img, PackedVector2Array([Vector2(beak.x + 4.0, beak.y - 1.0), Vector2(beak.x - 6.0, beak.y - gape), Vector2(beak.x - 2.0, beak.y - gape - 4.0), Vector2(beak.x + 3.0, beak.y - 5.0)]), Color("#e8d8b0"))
	Painter.poly(img, PackedVector2Array([Vector2(beak.x + 4.0, beak.y + 1.0), Vector2(beak.x - 5.0, beak.y + gape), Vector2(beak.x - 1.0, beak.y + gape + 3.0), Vector2(beak.x + 3.0, beak.y + 4.0)]), Color("#b8a47a"))
	Kit.put(img, int(beak.x) - 6, int(beak.y - gape), Color("#fff8e0"))
	if flare:
		Kit.disc(img, beak.x - 1.0, beak.y, 1.6, GLOW)
		Kit.put(img, int(beak.x) - 1, int(beak.y), Color.WHITE)

	# Sea water streaming off the arms and mantle.
	for d: int in range(18):
		var dx: int = rng.randi_range(6, 100)
		var dy: int = rng.randi_range(100, 152)
		if img.get_pixel(dx, dy).a > 0.5 and dy + 3 < BOSS_H:
			var ln: int = rng.randi_range(2, 5)
			for j: int in range(ln):
				var yy: int = dy + 1 + j + (int(wob) if d % 2 == 0 else 0)
				if yy < BOSS_H and img.get_pixel(dx, yy).a < 0.5:
					img.set_pixel(dx, yy, Color(0.62, 0.94, 1.0, 0.9 - 0.15 * float(j)))
	return img
