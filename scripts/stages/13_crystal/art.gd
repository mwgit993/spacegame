extends RefCounted

# CRYSTAL CAVE sprites. build() runs on a worker thread, so it only paints Images (Kit and the
# pure stage_bg_painter primitives are safe). Every key starts with the stage id ("crystal_...",
# "boss_crystal_..."). Enemies face left, toward the player.
# Palette: amethyst and magenta geode crystal, emerald and gold accents, white-gold light.

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

# Crystal ramps for Painter.crystal(): outline, shadow face, centre face, lit face, ridge.
const AMETHYST: PackedColorArray = [Color("#12081f"), Color("#3a1868"), Color("#6a30a8"), Color("#a870e8"), Color("#f0dcff")]
const ROSE: PackedColorArray = [Color("#1c0614"), Color("#6a1048"), Color("#b02878"), Color("#f070b8"), Color("#ffe0f4")]
const EMERALD: PackedColorArray = [Color("#04140e"), Color("#0e5a3a"), Color("#1ca068"), Color("#5ae8a8"), Color("#e0fff0")]
const GOLD: PackedColorArray = [Color("#1a1004"), Color("#7a5410"), Color("#c8901c"), Color("#ffd25a"), Color("#fffae0")]
const BRIGHT: PackedColorArray = [Color("#1a0b2e"), Color("#5a2aa0"), Color("#9050e0"), Color("#c898ff"), Color("#ffffff")]
const LIT: PackedColorArray = [Color("#2a1a08"), Color("#ffa840"), Color("#ffd878"), Color("#fff2c0"), Color("#ffffff")]
const ROCK: Array[Color] = [Color("#140e1c"), Color("#221a2e"), Color("#342842"), Color("#4a3c5a")]


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(4):
		out[id + "_prism_%d" % f] = Kit.outline(_prism_turret(f))
	for f2: int in range(3):
		out[id + "_bat_%d" % f2] = Kit.outline(_bat(f2))
	for f3: int in range(2):
		out[id + "_golem_%d" % f3] = Kit.outline(_golem(f3))
	out[id + "_shot"] = Kit.outline(_prism_shot())
	var shard_cols: Array[Array] = [
		[Color("#ff3c5a"), Color("#ff9aa8")],   # rose-red
		[Color("#22d070"), Color("#a8ffc8")],   # emerald
		[Color("#ffc020"), Color("#fff2a0")],   # gold
	]
	for k: int in range(3):
		out[id + "_shard_%d" % k] = Kit.outline(_shard(shard_cols[k][0], shard_cols[k][1]))
	for f4: int in range(2):
		out[id + "_orb_%d" % f4] = Kit.outline(_orb(f4))
	for f5: int in range(3):
		out["boss_%s_%d" % [id, f5]] = _paint_boss(f5)
	return out


# --- Prism turret: a cluster of three crystals on a rock base; frame k lights k facets -----------

static func _prism_turret(lit: int) -> Image:
	var img: Image = Kit.blank(22, 20)
	# Rock base (floor-mounted; the ceiling variant flips the sprite).
	Kit.ball(img, 11.0, 17.5, 10.0, 3.5, ROCK)
	Kit.rect(img, 2, 17, 18, 3, ROCK[1])
	Kit.rect(img, 3, 17, 16, 1, ROCK[2])
	# Three crystals, fired off in order: left-small, right-medium, centre-tall.
	var specs: Array[Vector4] = [
		Vector4(6.0, 17.0, -0.55, 8.0),
		Vector4(15.0, 17.0, 0.4, 10.0),
		Vector4(10.5, 17.0, -0.12, 15.0),
	]
	for i: int in range(3):
		var s: Vector4 = specs[i]
		Painter.crystal(img, s.x, s.y, s.z, s.w, 5.0 if i == 2 else 4.0, LIT if i < lit else BRIGHT)
	if lit >= 3:
		Kit.put(img, 9, 2, Color.WHITE)
		Kit.put(img, 10, 3, Color.WHITE)
	# Emerald seed gems in the rock.
	Kit.put(img, 4, 18, Color("#2ad08a"))
	Kit.put(img, 17, 18, Color("#2ad08a"))
	return img


# --- Crystal bat: wings 0 up / 1 down / 2 shriek (spread flat, mouth open, eyes blazing) ---------

static func _bat(frame: int) -> Image:
	var img: Image = Kit.blank(22, 14)
	var wing_dark: Color = Color("#6a1048")
	var wing: Color = Color("#c03890")
	var wing_hi: Color = Color("#ff9ad8")
	var tip_y: float = 1.0 if frame == 0 else (12.0 if frame == 1 else 4.0)
	var spread: float = 0.0 if frame != 2 else 2.0
	# Wings: faceted membranes from the shoulders out to crystal tips.
	for side: int in [-1, 1]:
		var sx: float = 11.0 + float(side) * 2.0
		var tx: float = 11.0 + float(side) * (9.0 + spread)
		Painter.poly(img, PackedVector2Array([Vector2(sx, 5.0), Vector2(tx, tip_y), Vector2(tx - float(side) * 2.0, 7.5), Vector2(sx, 8.5)]), wing_dark)
		Painter.poly(img, PackedVector2Array([Vector2(sx, 5.0), Vector2(tx, tip_y), Vector2(sx + float(side) * 3.0, 7.0)]), wing)
		Kit.line(img, Vector2(sx, 5.0), Vector2(tx, tip_y), wing_hi)
		Kit.put(img, int(tx), int(tip_y), Color.WHITE)
	# Body and head (head on the left).
	var body: Array[Color] = [Color("#2e1452"), Color("#7a3cc0"), Color("#b07ae8"), Color("#e8d0ff")]
	Kit.ball(img, 11.5, 7.5, 3.5, 3.0, body)
	Kit.ball(img, 7.0, 7.0, 2.6, 2.4, body)
	# Crystal ears and a ridge of spikes on the back.
	Kit.put(img, 6, 4, Color("#f070b8"))
	Kit.put(img, 8, 4, Color("#f070b8"))
	Kit.put(img, 12, 4, Color("#e8d0ff"))
	Kit.put(img, 14, 5, Color("#e8d0ff"))
	var eye: Color = Color("#ffd050") if frame != 2 else Color.WHITE
	Kit.put(img, 6, 6, eye)
	if frame == 2:
		Kit.put(img, 5, 6, Color("#ffd050"))
		Kit.rect(img, 4, 8, 3, 2, Color("#ff3c5a"))
		Kit.put(img, 4, 8, Color.WHITE)
	else:
		Kit.put(img, 5, 8, Color("#f0dcff"))
	return img


# --- Gem golem: a hulking crystal brute; frame 1 is cracked open with the emerald core -----------

static func _golem(frame: int) -> Image:
	var img: Image = Kit.blank(34, 36)
	var open: bool = frame == 1
	# Legs.
	Kit.rect(img, 11, 27, 5, 8, ROCK[1])
	Kit.rect(img, 19, 27, 5, 8, ROCK[1])
	Kit.rect(img, 11, 27, 1, 8, ROCK[2])
	Kit.rect(img, 19, 27, 1, 8, ROCK[2])
	Kit.rect(img, 9, 34, 8, 2, ROCK[0])
	Kit.rect(img, 18, 34, 8, 2, ROCK[0])
	# Torso: a faceted gem block (two halves that part when it opens).
	var gap: int = 3 if open else 0
	Painter.poly(img, PackedVector2Array([Vector2(8 - gap, 10), Vector2(17 - gap, 7), Vector2(17 - gap, 29), Vector2(10 - gap, 28), Vector2(7 - gap, 18)]), Color("#5a2aa0"))
	Painter.poly(img, PackedVector2Array([Vector2(8 - gap, 10), Vector2(17 - gap, 7), Vector2(17 - gap, 15), Vector2(9 - gap, 16)]), Color("#c898ff"))
	Painter.poly(img, PackedVector2Array([Vector2(17 + gap, 7), Vector2(27 + gap, 10), Vector2(28 + gap, 18), Vector2(25 + gap, 28), Vector2(17 + gap, 29)]), Color("#3e1a78"))
	Painter.poly(img, PackedVector2Array([Vector2(17 + gap, 7), Vector2(27 + gap, 10), Vector2(26 + gap, 16), Vector2(17 + gap, 15)]), Color("#8a50d0"))
	Kit.line(img, Vector2(8 - gap, 10), Vector2(17 - gap, 7), Color("#f0dcff"))
	if open:
		Kit.rect(img, 15, 9, 5, 19, Color("#04140e"))
		Kit.ball(img, 17.5, 18.0, 3.0, 5.5, [Color("#0e5a3a"), Color("#1ca068"), Color("#5ae8a8"), Color("#e0fff0")])
		Kit.put(img, 17, 16, Color.WHITE)
	else:
		Kit.line(img, Vector2(17, 8), Vector2(17, 28), Color("#12081f"))
		Kit.put(img, 17, 18, Color("#2ad08a"))
	# Shoulders: crystal spires.
	Painter.crystal(img, 7.0, 12.0, -0.5, 10.0, 5.0, ROSE)
	Painter.crystal(img, 28.0, 12.0, 0.45, 11.0, 5.0, ROSE)
	Painter.crystal(img, 22.0, 9.0, 0.15, 7.0, 4.0, AMETHYST)
	# Arms hanging to big crystal fists (the left fist is forward).
	Kit.rect(img, 3 - gap, 14, 4, 10, ROCK[2])
	Kit.ball(img, 4.5 - float(gap), 26.0, 3.5, 3.5, [Color("#3a1868"), Color("#6a30a8"), Color("#a870e8"), Color("#f0dcff")])
	Kit.rect(img, 28 + gap, 14, 4, 10, ROCK[1])
	Kit.ball(img, 30.0 + float(gap), 25.0, 3.0, 3.5, [Color("#2a1048"), Color("#4a2080"), Color("#7a3cc0"), Color("#b07ae8")])
	# Head: a small gem with gold eyes.
	Kit.ball(img, 14.5, 6.0, 4.5, 4.0, [Color("#1a0b2e"), Color("#4a2080"), Color("#7a3cc0"), Color("#b07ae8")])
	Kit.put(img, 12, 6, Color("#ffd050") if not open else Color.WHITE)
	Kit.put(img, 15, 6, Color("#ffd050") if not open else Color.WHITE)
	Painter.crystal(img, 15.0, 3.0, -0.1, 5.0, 3.0, GOLD)
	return img


# --- Shots ---------------------------------------------------------------------------------------

# The prism bolt (bullet_b): a white-gold diamond.
static func _prism_shot() -> Image:
	return Kit.rows(PackedStringArray([
		"...G...",
		"..GYG..",
		".GYWYG.",
		"GYWWWYG",
		".GYWYG.",
		"..GYG..",
		"...G...",
	]), {"G": Color("#c8901c"), "Y": Color("#ffd878"), "W": Color("#ffffff")})


static func _shard(col: Color, hi: Color) -> Image:
	var img: Image = Kit.blank(6, 6)
	Kit.disc(img, 3.0, 3.0, 2.9, col)
	Kit.rect(img, 2, 1, 2, 4, hi)
	Kit.rect(img, 1, 2, 4, 2, hi)
	Kit.put(img, 2, 2, Color.WHITE)
	Kit.put(img, 3, 3, Color.WHITE)
	return img


# A slow splitting orb: a prismatic ball that blinks between frames before it bursts.
static func _orb(frame: int) -> Image:
	var img: Image = Kit.blank(12, 12)
	var cols: Array[Color] = [Color("#4a2080"), Color("#b02878"), Color("#f070b8"), Color("#ffe0f4")]
	if frame == 1:
		cols = [Color("#b02878"), Color("#f070b8"), Color("#ffe0f4"), Color.WHITE]
	Kit.ball(img, 6.0, 6.0, 5.5, 5.5, cols)
	Kit.put(img, 3, 6, Color("#ffd25a"))
	Kit.put(img, 8, 4, Color("#5ae8a8"))
	Kit.put(img, 7, 8, Color("#ffd25a") if frame == 1 else Color("#a870e8"))
	return img


# --- Boss: PRISM HYDRA "SPECTRA" -------------------------------------------------------------------
# A geode body split open around a glowing core, crusted with crystals, with three crystalline
# heads on segmented necks: rose (top), emerald (middle) and gold (bottom). The heads rise and
# dip between the idle frames; on the attack frame the jaws open and the core flares.

const BW: int = 126
const BH: int = 152
# Head joints (where each neck meets the back of its head) per frame, top/mid/bottom.
const HEADS: Array[Array] = [
	[Vector2(34.0, 30.0), Vector2(26.0, 76.0), Vector2(34.0, 122.0)],
	[Vector2(35.0, 26.0), Vector2(24.0, 77.0), Vector2(35.0, 126.0)],
	[Vector2(30.0, 28.0), Vector2(22.0, 76.0), Vector2(30.0, 124.0)],
]


static func _paint_boss(frame: int) -> Image:
	var img: Image = BossPainter._new_img(BW, BH)
	var hot: bool = frame == 2
	var body_c: Vector2 = Vector2(88.0, 76.0)

	# Crystals jutting from the back of the geode (behind the shell).
	var back: Array[Vector4] = [
		Vector4(98.0, 34.0, 0.5, 24.0), Vector4(110.0, 52.0, 1.0, 16.0), Vector4(112.0, 96.0, 2.1, 16.0),
		Vector4(100.0, 118.0, 2.6, 22.0), Vector4(84.0, 30.0, -0.1, 20.0), Vector4(86.0, 124.0, 3.1, 18.0),
	]
	for i: int in range(back.size()):
		var b: Vector4 = back[i]
		Painter.crystal(img, b.x, b.y, b.z, b.w, 7.0, AMETHYST if i % 2 == 0 else ROSE)

	# Rock shell of the geode.
	_ellipse(img, body_c, 37.0, 50.0, Color("#0e0a16"))
	_ellipse(img, body_c, 35.0, 48.0, ROCK[1])
	for y: int in range(int(body_c.y) - 48, int(body_c.y) + 48):
		for x: int in range(int(body_c.x) - 35, int(body_c.x) + 35):
			var n: Vector2 = Vector2((float(x) - body_c.x) / 35.0, (float(y) - body_c.y) / 48.0)
			if n.length_squared() > 1.0:
				continue
			var lit: float = -n.x * 0.5 - n.y * 0.7
			if lit > 0.45:
				BossPainter._px(img, x, y, ROCK[3])
			elif lit > 0.15:
				BossPainter._px(img, x, y, ROCK[2])
			elif lit < -0.55:
				BossPainter._px(img, x, y, ROCK[0])
	# Pock marks and gold veins in the shell.
	for k: int in range(30):
		var a: float = float(k) * 2.39
		var r: float = 0.55 + 0.4 * fposmod(float(k) * 0.618, 1.0)
		var p: Vector2 = body_c + Vector2(cos(a) * 33.0 * r, sin(a) * 46.0 * r)
		BossPainter._px(img, int(p.x), int(p.y), ROCK[0] if k % 3 else Color("#c8901c"))

	# The cavity on the front face, packed with amethyst points around the core.
	var cav: Vector2 = Vector2(76.0, 76.0)
	_ellipse(img, cav, 24.0, 36.0, Color("#0a0512"))
	_ellipse(img, cav, 22.0, 34.0, Color("#1a0b2e"))
	for j: int in range(16):
		var a2: float = TAU * float(j) / 16.0
		var rim: Vector2 = cav + Vector2(cos(a2) * 20.0, sin(a2) * 31.0)
		var inward: float = atan2(cav.x - rim.x, -(cav.y - rim.y))
		Painter.crystal(img, rim.x, rim.y, inward, 12.0 + float(j % 3) * 3.0, 5.0, AMETHYST if j % 3 != 1 else ROSE)
	var core_r: int = 11 if not hot else 14
	BossPainter._glow_orb(img, int(cav.x), int(cav.y), core_r, Color("#b02878"), Color("#f070b8") if not hot else Color("#ffd0f0"), Color.WHITE)
	BossPainter._circle(img, int(cav.x) - 3, int(cav.y) - 4, 2, Color.WHITE)

	# Necks and heads, back to front: bottom, top, middle.
	var heads: Array = HEADS[frame]
	var joints: Array[Vector2] = [Vector2(64.0, 48.0), Vector2(56.0, 76.0), Vector2(64.0, 104.0)]
	var ramps: Array[PackedColorArray] = [ROSE, EMERALD, GOLD]
	for idx: int in [2, 0, 1]:
		var h: Vector2 = heads[idx]
		var j0: Vector2 = joints[idx]
		var ctrl: Vector2 = Vector2((j0.x + h.x) * 0.5 + 4.0, (j0.y + h.y) * 0.5 + (8.0 if idx == 0 else (-8.0 if idx == 2 else 0.0)) * (1.0 if frame != 1 else 1.6))
		_neck(img, j0, ctrl, h, ramps[idx])
		_head(img, h, ramps[idx], hot)
	return img


static func _ellipse(img: Image, c: Vector2, rx: float, ry: float, col: Color) -> void:
	for y: int in range(int(c.y - ry), int(c.y + ry) + 1):
		var dy: float = (float(y) + 0.5 - c.y) / ry
		if absf(dy) > 1.0:
			continue
		var hw: float = rx * sqrt(1.0 - dy * dy)
		for x: int in range(int(c.x - hw), int(c.x + hw) + 1):
			BossPainter._px(img, x, y, col)


# A segmented crystal neck along a quadratic curve: faceted diamonds shrinking toward the head.
static func _neck(img: Image, a: Vector2, c: Vector2, b: Vector2, ramp: PackedColorArray) -> void:
	var segs: int = 8
	for s: int in range(segs, -1, -1):
		var t: float = float(s) / float(segs)
		var p: Vector2 = a.lerp(c, t).lerp(c.lerp(b, t), t)
		var r: float = lerpf(8.0, 5.5, t)
		var pts: PackedVector2Array = PackedVector2Array([p + Vector2(0.0, -r - 1.0), p + Vector2(r + 1.0, 0.0), p + Vector2(0.0, r + 1.0), p + Vector2(-r - 1.0, 0.0)])
		Painter.poly(img, pts, ramp[0])
		Painter.poly(img, PackedVector2Array([p + Vector2(0.0, -r), p + Vector2(r, 0.0), p + Vector2(0.0, r), p + Vector2(-r, 0.0)]), ramp[1])
		Painter.poly(img, PackedVector2Array([p + Vector2(0.0, -r), p + Vector2(-r, 0.0), p + Vector2(0.0, 0.0)]), ramp[3])
		Painter.poly(img, PackedVector2Array([p + Vector2(0.0, -r), p + Vector2(r, 0.0), p + Vector2(0.0, 0.0)]), ramp[2])
		BossPainter._px(img, int(p.x) - 1, int(p.y - r) + 1, ramp[4])


# A crystalline dragon head facing left, its back at `h`. Open jaws glow on the attack frame.
static func _head(img: Image, h: Vector2, ramp: PackedColorArray, open: bool) -> void:
	# Horns sweeping back.
	Painter.crystal(img, h.x - 2.0, h.y - 6.0, 0.95, 12.0, 4.0, ramp)
	Painter.crystal(img, h.x - 7.0, h.y - 7.0, 0.55, 8.0, 3.0, ramp)
	# Lower jaw (dropped when open), mouth glow.
	if open:
		Painter.poly(img, PackedVector2Array([h + Vector2(1.0, 0.0), h + Vector2(-22.0, -1.0), h + Vector2(-14.0, 6.0), h + Vector2(1.0, 5.0)]), Color("#fff2c0"))
		Painter.poly(img, PackedVector2Array([h + Vector2(1.0, 3.0), h + Vector2(-10.0, 6.0), h + Vector2(-19.0, 12.0), h + Vector2(-8.0, 11.0), h + Vector2(2.0, 8.0)]), ramp[0])
		Painter.poly(img, PackedVector2Array([h + Vector2(0.0, 4.0), h + Vector2(-10.0, 6.0), h + Vector2(-17.0, 11.0), h + Vector2(-8.0, 10.0), h + Vector2(1.0, 7.0)]), ramp[1])
		for t: int in range(3):
			BossPainter._px(img, int(h.x) - 9 - t * 3, int(h.y) + 6 + t, Color.WHITE)
	else:
		Painter.poly(img, PackedVector2Array([h + Vector2(1.0, 1.0), h + Vector2(-12.0, 1.0), h + Vector2(-21.0, 2.0), h + Vector2(-12.0, 7.0), h + Vector2(1.0, 7.0)]), ramp[0])
		Painter.poly(img, PackedVector2Array([h + Vector2(0.0, 2.0), h + Vector2(-12.0, 2.0), h + Vector2(-19.0, 3.0), h + Vector2(-12.0, 6.0), h + Vector2(0.0, 6.0)]), ramp[1])
	# Upper skull: outline, shadow, lit top facet.
	Painter.poly(img, PackedVector2Array([h + Vector2(3.0, -8.0), h + Vector2(-8.0, -9.0), h + Vector2(-21.0, -4.0), h + Vector2(-25.0, 0.0), h + Vector2(-12.0, 2.0), h + Vector2(3.0, 4.0)]), ramp[0])
	Painter.poly(img, PackedVector2Array([h + Vector2(2.0, -7.0), h + Vector2(-8.0, -8.0), h + Vector2(-20.0, -3.0), h + Vector2(-23.0, 0.0), h + Vector2(-12.0, 1.0), h + Vector2(2.0, 3.0)]), ramp[2])
	Painter.poly(img, PackedVector2Array([h + Vector2(2.0, -7.0), h + Vector2(-8.0, -8.0), h + Vector2(-20.0, -3.0), h + Vector2(-8.0, -3.0)]), ramp[3])
	Painter.poly(img, PackedVector2Array([h + Vector2(2.0, 0.0), h + Vector2(-12.0, 1.0), h + Vector2(2.0, 3.0)]), ramp[1])
	BossPainter._px(img, int(h.x) - 8, int(h.y) - 8, ramp[4])
	BossPainter._px(img, int(h.x) - 14, int(h.y) - 6, ramp[4])
	# Teeth along the upper jaw, and a burning eye.
	for t2: int in range(4):
		BossPainter._px(img, int(h.x) - 20 + t2 * 4, int(h.y) + 2, Color.WHITE)
	BossPainter._rect(img, int(h.x) - 11, int(h.y) - 5, 3, 2, Color.WHITE if open else Color("#fff2c0"))
	BossPainter._px(img, int(h.x) - 11, int(h.y) - 5, Color("#ff3c5a"))
