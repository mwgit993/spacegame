extends RefCounted

# HOLO ARENA sprites. build() runs on a worker thread, so it only paints Images. Every key
# starts with the stage id ("arena_...", "boss_arena_..."). Enemies face left, toward the player.
# Palette: navy-gunmetal armour with gold trim, hot magenta and cyan hologram light, red visors.

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const ARM: Array[Color] = [Color("#161a36"), Color("#2c3768"), Color("#4e66aa"), Color("#a0b6ee")]
const GOLD: Array[Color] = [Color("#5a3a10"), Color("#a8701c"), Color("#f0b838"), Color("#fff2a8")]
const MAG: Color = Color("#ff3cc8")
const MAG_L: Color = Color("#ffa6ee")
const MAG_D: Color = Color("#8a1a74")
const CY: Color = Color("#38e8ff")
const CY_L: Color = Color("#c4faff")
const CY_D: Color = Color("#1a7a9a")
const VISOR: Color = Color("#ff3048")
const DARK: Color = Color("#0a0c1a")


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(3):
		out[id + "_gladiator_%d" % f] = Kit.outline(_gladiator(f))
		out[id + "_bot_%d" % f] = Kit.outline(_bot(f))
	for f2: int in range(4):
		out[id + "_turret_%d" % f2] = Kit.outline(_turret(f2))
	out[id + "_shot"] = _shot()
	out[id + "_wall"] = _wall_node()
	out[id + "_knot"] = _knot()
	for f3: int in range(3):
		out["boss_%s_%d" % [id, f3]] = _paint_boss(f3)
	return out


# --- Gladiator drone: round shield in front, energy blade, crested helmet --------------------------
# Frame 0 guard (shield up, blade raised behind), 1 lunge (blade thrust forward, shield swung
# back), 2 aiming (guard pose, visor and blade blazing: the telegraph).

static func _gladiator(f: int) -> Image:
	var img: Image = Kit.blank(28, 26)
	var lunge: bool = f == 1
	# Back thruster.
	var fl: int = 4 if lunge else 2
	Kit.rect(img, 23, 13, fl, 3, CY_D)
	Kit.rect(img, 23, 14, fl, 1, CY)
	Kit.put(img, 22 + fl, 14, CY_L)
	if lunge:
		_shield(img, 20.0, 19.0, 5.0)
	else:
		# Blade held up behind the shoulder.
		Kit.line(img, Vector2(21.0, 13.0), Vector2(25.0, 1.0), CY_D)
		Kit.line(img, Vector2(22.0, 13.0), Vector2(26.0, 1.0), CY_L if f == 2 else CY)
		if f == 2:
			Kit.put(img, 26, 0, Color.WHITE)
			Kit.put(img, 27, 1, CY_L)
		Kit.rect(img, 20, 12, 3, 2, GOLD[2])
	# Torso, belt and tasset plates.
	Kit.ball(img, 16.0, 15.0, 6.5, 6.8, ARM)
	Kit.rect(img, 10, 18, 13, 1, GOLD[1])
	Kit.put(img, 12, 18, GOLD[3])
	Kit.put(img, 16, 18, GOLD[2])
	for tx: int in [12, 15, 18]:
		Kit.rect(img, tx, 19, 3, 3, ARM[1])
		Kit.put(img, tx, 19, ARM[2])
		Kit.put(img, tx + 1, 21, GOLD[1])
	Kit.rect(img, 14, 22, 5, 1, CY_D)
	Kit.put(img, 16, 23, CY)
	# Helmet with cheek guard and T-visor.
	Kit.ball(img, 15.0, 8.0, 4.6, 4.3, ARM)
	Kit.rect(img, 11, 9, 2, 3, GOLD[1])
	Kit.put(img, 11, 9, GOLD[3])
	var vc: Color = Color.WHITE if f == 2 else VISOR
	Kit.rect(img, 10, 7, 4, 1, vc)
	Kit.put(img, 11, 8, vc)
	if f == 2:
		Kit.put(img, 9, 7, VISOR)
	# Crest: a magenta hologram plume arcing from the brow over to the back.
	for i: int in range(12):
		var t: float = float(i) / 11.0
		var x: int = int(11.0 + t * 11.0)
		var y: int = int(roundf(4.6 - sin(t * PI) * 4.0))
		Kit.put(img, x, y, MAG)
		Kit.put(img, x, y + 1, MAG_D)
		if i % 3 == 1:
			Kit.put(img, x, y - 1, MAG_L)
	if lunge:
		# Blade thrust forward from the fist.
		Kit.line(img, Vector2(9.0, 15.0), Vector2(0.0, 15.0), CY)
		Kit.line(img, Vector2(9.0, 16.0), Vector2(1.0, 16.0), CY_D)
		Kit.line(img, Vector2(7.0, 15.0), Vector2(2.0, 15.0), CY_L)
		Kit.put(img, 0, 15, Color.WHITE)
		Kit.rect(img, 9, 14, 3, 3, GOLD[2])
		Kit.put(img, 9, 14, GOLD[3])
	else:
		_shield(img, 7.0, 15.0, 6.6)
	return img


static func _shield(img: Image, cx: float, cy: float, r: float) -> void:
	Kit.disc(img, cx, cy, r, GOLD[1])
	Kit.disc(img, cx - 0.4, cy - 0.4, r - 0.8, GOLD[2])
	Kit.disc(img, cx, cy, r - 1.6, ARM[1])
	Kit.disc(img, cx - 0.7, cy - 0.7, r - 2.6, ARM[2])
	var c: Vector2i = Vector2i(int(cx), int(cy))
	Kit.put(img, c.x, c.y, CY_L)
	Kit.put(img, c.x - 1, c.y, CY)
	Kit.put(img, c.x + 1, c.y, CY)
	Kit.put(img, c.x, c.y - 1, CY)
	Kit.put(img, c.x, c.y + 1, CY)


# --- Combat bot: boxy chassis, visor band, arm cannon ------------------------------------------
# Frame 0 visor dim, 1 visor lit (the beat flash), 2 firing (muzzle flash).

const STEEL: Array[Color] = [Color("#2a3048"), Color("#5a6684"), Color("#94a2c0"), Color("#d8e0f2")]


static func _bot(f: int) -> Image:
	var img: Image = Kit.blank(19, 21)
	# Antenna with a beacon.
	Kit.rect(img, 11, 0, 1, 3, STEEL[2])
	Kit.put(img, 11, 0, MAG if f > 0 else MAG_D)
	# Head: steel dome with a wide visor band.
	BossPainter._armor_plate(img, 4, 2, 13, 8, STEEL[1], STEEL[3], STEEL[0], false)
	Kit.rect(img, 5, 4, 11, 4, DARK)
	var vis: Color = Color("#6a1040")
	if f == 1:
		vis = MAG
	elif f == 2:
		vis = MAG_L
	Kit.rect(img, 5, 5, 10, 2, vis)
	Kit.rect(img, 5, 5, 3, 1, vis.lightened(0.4))
	if f > 0:
		Kit.put(img, 6, 5, Color.WHITE)
		Kit.put(img, 7, 6, Color.WHITE)
	# Torso: steel with a gold collar, a number plate and a core light.
	BossPainter._armor_plate(img, 3, 10, 15, 7, STEEL[1], STEEL[2], STEEL[0], false)
	Kit.rect(img, 4, 10, 13, 1, GOLD[2])
	Kit.put(img, 5, 10, GOLD[3])
	Kit.rect(img, 7, 12, 6, 3, Color("#1a1430"))
	Kit.rect(img, 8, 13, 4, 1, MAG_D if f == 0 else MAG)
	Kit.put(img, 9, 13, MAG_L if f > 0 else MAG)
	# Arm cannon (front) and back arm.
	Kit.rect(img, 0, 12, 6, 3, STEEL[2])
	Kit.rect(img, 0, 14, 6, 1, STEEL[0])
	Kit.rect(img, 0, 12, 6, 1, STEEL[3])
	Kit.rect(img, 16, 12, 3, 4, STEEL[1])
	Kit.put(img, 16, 12, STEEL[2])
	if f == 2:
		Kit.put(img, 0, 13, Color("#fff27a"))
		Kit.put(img, 1, 13, Color.WHITE)
	# Hover jets.
	Kit.rect(img, 5, 17, 3, 2, STEEL[0])
	Kit.rect(img, 12, 17, 3, 2, STEEL[0])
	Kit.rect(img, 6, 19, 1, 2, CY)
	Kit.rect(img, 13, 19, 1, 2, CY)
	Kit.put(img, 6, 20, CY_L)
	Kit.put(img, 13, 20, CY_L)
	return img


# --- Arena turret: a floor slot whose emitter pops up (variant 1 is flipped onto the ceiling) -----
# Frame 0 hatch closed, 1 rising, 2 up, 3 up and charging (lens blazing).

static func _turret(f: int) -> Image:
	var img: Image = Kit.blank(22, 18)
	# Emitter column and head (drawn first; the housing sits over its foot).
	if f >= 1:
		var rise: int = 4 if f == 1 else 10
		Kit.rect(img, 8, 14 - rise, 6, rise, ARM[1])
		Kit.rect(img, 8, 14 - rise, 2, rise, ARM[2])
		Kit.rect(img, 13, 14 - rise, 1, rise, ARM[0])
		Kit.rect(img, 8, 14 - rise + 2, 6, 1, GOLD[1])
		if f >= 2:
			Kit.ball(img, 11.0, 5.5, 5.5, 3.2, ARM)
			# The emitter fork with a lens between the prongs.
			Kit.rect(img, 6, 1, 2, 4, GOLD[1])
			Kit.rect(img, 14, 1, 2, 4, GOLD[1])
			Kit.put(img, 6, 1, GOLD[3])
			Kit.put(img, 14, 1, GOLD[3])
			var lens: Color = MAG if f == 2 else MAG_L
			Kit.disc(img, 11.0, 3.0, 2.3, MAG_D)
			Kit.disc(img, 11.0, 3.0, 1.6, lens)
			if f == 3:
				Kit.put(img, 10, 2, Color.WHITE)
				Kit.put(img, 11, 2, Color.WHITE)
				Kit.put(img, 7, 0, MAG_L)
				Kit.put(img, 15, 0, MAG_L)
		else:
			Kit.rect(img, 7, 9, 8, 2, GOLD[1])
	# Housing in the deck with hazard stripes.
	BossPainter._armor_plate(img, 1, 13, 20, 5, ARM[0], ARM[1], Color("#080a16"), false)
	for x: int in range(3, 19, 4):
		Kit.rect(img, x, 15, 2, 1, GOLD[2])
	if f == 0:
		Kit.rect(img, 6, 12, 10, 2, ARM[1])
		Kit.rect(img, 6, 12, 10, 1, ARM[2])
		Kit.put(img, 11, 12, GOLD[2])
		Kit.put(img, 7, 12, MAG_D)
		Kit.put(img, 14, 12, MAG_D)
	return img


# --- Shots --------------------------------------------------------------------------------------

# The stage's own shot ("bullet_b"): a gold diamond with a white core.
static func _shot() -> Image:
	var img: Image = Kit.blank(9, 9)
	Painter.poly(img, PackedVector2Array([Vector2(4.5, 0.0), Vector2(9.0, 4.5), Vector2(4.5, 9.0), Vector2(0.0, 4.5)]), Color(1.0, 0.72, 0.2, 0.5))
	Painter.poly(img, PackedVector2Array([Vector2(4.5, 1.5), Vector2(7.5, 4.5), Vector2(4.5, 7.5), Vector2(1.5, 4.5)]), GOLD[2])
	Kit.rect(img, 3, 4, 3, 1, GOLD[3])
	Kit.rect(img, 4, 3, 1, 3, GOLD[3])
	Kit.put(img, 4, 4, Color.WHITE)
	return img


# A node of a laser barrier: an upright magenta bar with a white-hot core.
static func _wall_node() -> Image:
	var img: Image = Kit.blank(5, 9)
	Kit.rect(img, 1, 0, 3, 9, Color(1.0, 0.24, 0.78, 0.45))
	Kit.rect(img, 0, 2, 5, 5, Color(1.0, 0.24, 0.78, 0.35))
	Kit.rect(img, 1, 1, 3, 7, MAG)
	Kit.rect(img, 2, 1, 1, 7, MAG_L)
	Kit.rect(img, 2, 3, 1, 3, Color.WHITE)
	return img


# A knot of the champion's net: a cyan ring with a white centre.
static func _knot() -> Image:
	var img: Image = Kit.blank(9, 9)
	Kit.disc(img, 4.5, 4.5, 4.5, Color(0.2, 0.9, 1.0, 0.4))
	Kit.disc(img, 4.5, 4.5, 3.4, CY)
	Kit.disc(img, 4.5, 4.5, 2.2, CY_D)
	Kit.disc(img, 4.5, 4.5, 1.3, CY_L)
	Kit.put(img, 4, 4, Color.WHITE)
	return img


# --- The boss: GRAND CHAMPION, an armoured gladiator mech -------------------------------------
# A gold crested helmet with a red T-visor, a navy breastplate with a magenta core, a tower
# shield with a laurel emblem held in front, a long trident with cyan energy prongs, a crimson
# cape. Frame 2 (attacking): prongs blazing and longer, the shield emblem and core lit.

static func _paint_boss(frame: int) -> Image:
	var img: Image = BossPainter._new_img(118, 154)
	var navy: Color = Color("#28305c")
	var navy_hi: Color = Color("#5a6cb0")
	var navy_sh: Color = Color("#151a36")
	var gold: Color = Color("#c8901c")
	var gold_hi: Color = Color("#ffe07a")
	var gold_sh: Color = Color("#6a4410")
	var atk: bool = frame == 2
	var hem: float = 0.0 if frame == 0 else (4.0 if frame == 1 else -3.0)

	# Cape behind, flowing back to the right.
	var cape: PackedVector2Array = PackedVector2Array([Vector2(68.0, 40.0), Vector2(98.0, 42.0), Vector2(110.0, 80.0 + hem * 0.5), Vector2(117.0, 132.0 + hem), Vector2(104.0, 140.0 - hem), Vector2(92.0, 146.0), Vector2(84.0, 118.0), Vector2(74.0, 70.0)])
	Painter.poly(img, cape, Color("#3a0a2e"))
	var cape_in: PackedVector2Array = PackedVector2Array([Vector2(72.0, 44.0), Vector2(96.0, 46.0), Vector2(107.0, 82.0 + hem * 0.5), Vector2(113.0, 130.0 + hem), Vector2(103.0, 136.0 - hem), Vector2(93.0, 141.0), Vector2(86.0, 116.0), Vector2(77.0, 70.0)])
	Painter.poly(img, cape_in, Color("#7a1858"))
	for k: int in range(3):
		var x0: float = 84.0 + float(k) * 8.0
		BossPainter._thick_line(img, Vector2(x0, 50.0), Vector2(x0 + 8.0 + hem * 0.3, 136.0), 0, Color("#a8287a"), Color("#a8287a"))
		Painter.line(img, int(x0 + 3.0), 52, int(x0 + 12.0 + hem * 0.3), 134, Color("#4a0e3a"))

	# Back pauldron.
	BossPainter._armor_plate(img, 66, 34, 32, 20, gold, gold_hi, gold_sh)
	BossPainter._armor_plate(img, 70, 40, 24, 10, navy, navy_hi, navy_sh, false)

	# Hover skirt: hanging tasset plates and the thruster glow under them.
	for t: int in range(5):
		var tx: int = 44 + t * 10
		var th: int = 26 - absi(t - 2) * 3
		BossPainter._armor_plate(img, tx, 108, 11, th, navy, navy_hi, navy_sh, false)
		BossPainter._rect(img, tx + 1, 108 + th - 3, 9, 2, gold)
		BossPainter._px(img, tx + 2, 108 + th - 3, gold_hi)
	for j: int in range(4):
		var jx: int = 52 + j * 10
		BossPainter._rect(img, jx, 138, 5, 3, navy_sh)
		var flame: int = 5 if atk else 3
		BossPainter._rect(img, jx + 1, 141, 3, flame, CY_D)
		BossPainter._rect(img, jx + 2, 141, 1, flame + 1, CY)
		BossPainter._px(img, jx + 2, 141, CY_L)

	# Breastplate, abdomen bands and the magenta core.
	BossPainter._armor_plate(img, 42, 50, 50, 60, navy, navy_hi, navy_sh)
	for b: int in range(3):
		BossPainter._rect(img, 46, 94 + b * 5, 42, 1, navy_sh)
		BossPainter._rect(img, 46, 95 + b * 5, 42, 1, navy_hi)
	BossPainter._rect(img, 44, 50, 46, 3, gold)
	BossPainter._rect(img, 44, 50, 46, 1, gold_hi)
	BossPainter._armor_plate(img, 56, 66, 26, 24, gold, gold_hi, gold_sh, false)
	BossPainter._glow_orb(img, 68, 78, 9 if atk else 7, MAG_D, MAG, MAG_L if not atk else Color.WHITE)
	# Laurel ribs either side of the core.
	for r: int in range(4):
		BossPainter._px(img, 58 + r, 70 + r * 4, gold_hi)
		BossPainter._px(img, 78 - r, 70 + r * 4, gold_hi)

	# Helmet: a domed gold galea with a flared neck guard, a navy face plate and a red T-visor.
	var gold_ramp: Array[Color] = [gold_sh, gold, Color("#e8b440"), gold_hi]
	BossPainter._rect(img, 62, 36, 22, 8, gold_sh.darkened(0.4))
	BossPainter._rect(img, 63, 37, 20, 6, gold)
	BossPainter._rect(img, 63, 37, 20, 1, gold_hi)
	Kit.ball(img, 63.0, 31.0, 15.5, 14.5, gold_ramp)
	for a: int in range(40):
		var ang: float = PI + PI * float(a) / 39.0
		BossPainter._px(img, int(63.0 + cos(ang) * 15.5), int(31.0 + sin(ang) * 14.5), gold_sh.darkened(0.4))
	BossPainter._rect(img, 54, 42, 20, 2, gold_sh)
	BossPainter._armor_plate(img, 44, 24, 17, 19, navy, navy_hi, navy_sh, false)
	BossPainter._rect(img, 60, 26, 2, 15, gold)
	var vc: Color = Color.WHITE if atk else VISOR
	BossPainter._rect(img, 44, 29, 13, 2, vc)
	BossPainter._rect(img, 48, 31, 3, 8, vc)
	BossPainter._px(img, 43, 29, VISOR)
	BossPainter._px(img, 43, 30, Color(1.0, 0.2, 0.3, 0.6))
	# The crest: a gold ridge along the dome carrying a tall magenta hologram plume (a brush of
	# bristles from the ridge up to the plume's rounded top).
	for bx: int in range(50, 83):
		var u0: float = (float(bx) - 49.0) / 34.0
		var top_y: int = int(14.0 - sin(u0 * PI) * 11.0)
		var ridge_y: int = int(31.0 - sqrt(maxf(0.0, 1.0 - pow((float(bx) - 63.0) / 15.5, 2.0))) * 14.5)
		BossPainter._rect(img, bx, top_y, 1, maxi(0, ridge_y - top_y), MAG_D if bx % 2 == 0 else Color("#c02a9a"))
	for i: int in range(40):
		var u: float = float(i) / 39.0
		var cx: float = 49.0 + u * 34.0
		var cy: float = 14.0 - sin(u * PI) * 11.0
		BossPainter._circle(img, int(cx), int(cy), 3, MAG_D)
	for i2: int in range(40):
		var u2: float = float(i2) / 39.0
		var cx2: float = 49.0 + u2 * 34.0
		var cy2: float = 13.0 - sin(u2 * PI) * 11.0
		BossPainter._circle(img, int(cx2), int(cy2), 2, MAG)
		if i2 % 5 == 0:
			BossPainter._px(img, int(cx2), int(cy2) - 3, MAG_L)
			BossPainter._px(img, int(cx2) + 1, int(cy2) - 2, MAG_L)
	for i3: int in range(30):
		var u3: float = float(i3) / 29.0
		var gx: int = int(50.0 + u3 * 30.0)
		var gy: int = int(31.0 - sqrt(maxf(0.0, 1.0 - pow((float(gx) - 63.0) / 15.5, 2.0))) * 14.5)
		BossPainter._rect(img, gx, gy - 1, 1, 2, gold_hi)
		BossPainter._px(img, gx, gy + 1, gold_sh)

	# Front pauldron.
	BossPainter._armor_plate(img, 30, 46, 28, 18, gold, gold_hi, gold_sh)
	BossPainter._rect(img, 33, 56, 22, 2, navy)

	# Trident: shaft from the back gauntlet forward, three cyan energy prongs.
	BossPainter._thick_line(img, Vector2(114.0, 64.0), Vector2(20.0, 44.0), 1, Color("#8a6420"), gold_hi)
	for ring: int in [36, 62, 92]:
		var ry: int = int(44.0 + (float(ring) - 20.0) * 20.0 / 94.0)
		BossPainter._rect(img, ring, ry - 2, 3, 5, gold)
		BossPainter._px(img, ring, ry - 2, gold_hi)
	BossPainter._armor_plate(img, 84, 52, 12, 12, gold, gold_hi, gold_sh, false)
	BossPainter._rect(img, 16, 34, 6, 20, gold)
	BossPainter._rect(img, 16, 34, 2, 20, gold_hi)
	BossPainter._rect(img, 21, 34, 1, 20, gold_sh)
	var plen: int = 2 if atk else 0
	var prong: Color = CY_L if atk else CY
	for p: int in range(3):
		var py: int = 36 + p * 8
		var tip_x: int = (3 if p == 1 else 6) - plen
		BossPainter._rect(img, tip_x, py - 1, 16 - tip_x, 3, CY_D)
		BossPainter._rect(img, tip_x, py, 16 - tip_x, 1, prong)
		# barbs
		BossPainter._px(img, tip_x + 3, py - 2, CY)
		BossPainter._px(img, tip_x + 3, py + 2, CY)
		BossPainter._px(img, tip_x, py, Color.WHITE if atk else CY_L)
		if atk:
			BossPainter._px(img, tip_x - 1, py, CY_L)

	# Shield arm gauntlet, then the tower shield in front.
	BossPainter._armor_plate(img, 34, 84, 14, 12, navy, navy_hi, navy_sh, false)
	# A curved scutum: rounded top and bottom edges over a straight body.
	Painter.ellipse(img, 22.0, 64.0, 19.0, 6.0, gold_sh.darkened(0.5))
	Painter.ellipse(img, 22.0, 142.0, 19.0, 6.0, gold_sh.darkened(0.5))
	BossPainter._armor_plate(img, 3, 64, 38, 78, gold, gold_hi, gold_sh)
	Painter.ellipse(img, 22.0, 64.0, 18.0, 5.0, gold)
	Painter.ellipse(img, 22.0, 63.0, 15.0, 3.0, gold_hi)
	Painter.ellipse(img, 22.0, 142.0, 18.0, 5.0, gold_sh)
	Painter.ellipse(img, 22.0, 66.5, 14.0, 4.0, navy)
	BossPainter._rect(img, 8, 66, 28, 75, navy)
	BossPainter._rect(img, 8, 66, 2, 75, navy_hi)
	BossPainter._rect(img, 34, 66, 2, 75, navy_sh)
	Painter.ellipse(img, 22.0, 140.5, 14.0, 3.0, navy_sh)
	BossPainter._rect(img, 8, 72, 28, 2, gold)
	BossPainter._rect(img, 8, 132, 28, 2, gold)
	BossPainter._rect(img, 8, 72, 28, 1, gold_hi)
	# Laurel emblem: a gold wreath ring around a magenta star.
	BossPainter._circle(img, 22, 102, 11, gold_sh)
	BossPainter._circle(img, 22, 102, 10, gold)
	BossPainter._circle(img, 22, 102, 8, navy_sh)
	for lf: int in range(12):
		var la: float = TAU * float(lf) / 12.0
		BossPainter._px(img, int(22.0 + cos(la) * 9.5), int(102.0 + sin(la) * 9.5), gold_hi)
	var star: Color = MAG_L if atk else MAG
	if atk:
		BossPainter._glow_orb(img, 22, 102, 6, MAG_D, MAG, Color.WHITE)
	for s: int in range(5):
		var sa: float = -PI * 0.5 + TAU * float(s) / 5.0
		BossPainter._thick_line(img, Vector2(22.0, 102.0), Vector2(22.0 + cos(sa) * 6.0, 102.0 + sin(sa) * 6.0), 0, star, star)
	BossPainter._px(img, 22, 102, Color.WHITE)
	# Rivets down the shield rim.
	for rv: int in range(6):
		BossPainter._px(img, 6, 76 + rv * 11, gold_hi)
		BossPainter._px(img, 37, 76 + rv * 11, gold_sh)
	return img
