extends RefCounted

# DESERT WORLD sprites. build() runs on a worker thread, so it only paints Images. Every key starts
# with the stage id ("desert_...", "boss_desert_..."). Enemies face left, toward the player.
# Palette: sun-baked sandstone and bronze, temple gold and lapis blue, turquoise glyph glow.

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const SAND: Array[Color] = [Color("#3a2416"), Color("#7a5030"), Color("#b08050"), Color("#e0b878")]
const STONE: Array[Color] = [Color("#4a3020"), Color("#8a6038"), Color("#b88a50"), Color("#ecc488")]
const GOLD: Array[Color] = [Color("#5a3a10"), Color("#a8741c"), Color("#e0b040"), Color("#fff0a0")]
const LAPIS: Array[Color] = [Color("#0e1c58"), Color("#1e3aa0"), Color("#4a78e8"), Color("#a8c4ff")]
const TURQ: Color = Color("#28f0d4")
const TURQ_D: Color = Color("#0e7a78")
const MAW: Color = Color("#4a1018")
const THROAT: Color = Color("#ff6a3a")
const TOOTH: Color = Color("#f0e8d0")

# The sandworm column: the head's centre is this far from the image's top-left (outline included),
# so the behaviour can pin the head to the enemy's position and crop the body at the ground.
const WORM_W: int = 20
const WORM_H: int = 100
const WORM_HEAD: Vector2 = Vector2(11.0, 11.0)


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(2):
		out[id + "_worm_%d" % f] = Kit.outline(_worm(f))
		out[id + "_scarab_%d" % f] = Kit.outline(_scarab(f))
		out[id + "_orb_%d" % f] = _orb(f)
		out[id + "_devil_%d" % f] = Kit.outline(_obelisk(f))
	out[id + "_glyph"] = Kit.outline(_glyph())
	out[id + "_sand"] = Kit.outline(_sand())
	for f2: int in range(3):
		out["boss_%s_%d" % [id, f2]] = _paint_boss(f2)
	return out


# --- Sandworm: an armoured ringed column with a round, toothed maw ------------------------------

static func _worm(frame: int) -> Image:
	var img: Image = Kit.blank(WORM_W, WORM_H)
	# Body rings below the head.
	for y: int in range(17, WORM_H):
		var r: int = (y - 17) % 8
		var half: int = 6 if r != 0 else 5
		for x: int in range(10 - half, 10 + half):
			var shade: int = 2
			if x < 7:
				shade = 3 if x > 10 - half else 2
			elif x > 13:
				shade = 0 if x == 10 + half - 1 else 1
			if r == 0:
				shade = 0
			elif r == 1 and shade >= 2:
				shade = 3
			Kit.put(img, x, y, SAND[shade])
		# a spine on every ring's back edge
		if r == 3:
			Kit.put(img, 10 + half, y, SAND[1])
			Kit.put(img, 10 + half + 1, y - 1, SAND[0])
	# Head: a rounded armoured cap.
	Kit.ball(img, 10.0, 9.5, 9.5, 10.0, [SAND[0], SAND[1], SAND[2], SAND[3]])
	for py: int in [5, 10, 15]:
		for px: int in range(9, 19):
			if img.get_pixel(px, py).a > 0.0:
				Kit.put(img, px, py, SAND[1] if px < 16 else SAND[0])
	Kit.put(img, 14, 5, TURQ)
	Kit.put(img, 16, 8, TURQ_D)
	if frame == 1:
		# Open maw: a ring of teeth around a glowing throat.
		Kit.disc(img, 5.0, 9.5, 5.2, MAW)
		Kit.disc(img, 5.0, 9.5, 3.0, Color("#c83a24"))
		Kit.disc(img, 5.0, 9.5, 1.8, THROAT)
		Kit.put(img, 5, 9, Color("#ffd27a"))
		for t: int in range(9):
			var a: float = TAU * float(t) / 9.0
			Kit.put(img, int(round(5.0 + cos(a) * 4.4)), int(round(9.5 + sin(a) * 4.4)), TOOTH)
	else:
		# Closed: a beak-like slit with a few teeth showing.
		Kit.line(img, Vector2(1, 9), Vector2(8, 10), MAW)
		Kit.line(img, Vector2(1, 10), Vector2(7, 11), SAND[0])
		Kit.put(img, 3, 9, TOOTH)
		Kit.put(img, 6, 10, TOOTH)
	return img


# --- Scarab drone: gold and lapis shell; frame 1 lifts the wing cases ---------------------------

static func _scarab(frame: int) -> Image:
	var img: Image = Kit.blank(18, 14)
	if frame == 1:
		# Membrane wings fanned up and back.
		for i: int in range(6):
			Kit.line(img, Vector2(9, 5), Vector2(17 - i, float(i) * 0.6), Color(1.0, 0.82, 0.45, 0.85))
		Kit.line(img, Vector2(9, 5), Vector2(17, 0), Color("#fff0c0"))
	# Legs.
	for lx: int in [6, 9, 12]:
		Kit.line(img, Vector2(lx, 9), Vector2(lx - 2, 13), SAND[0])
	# Shell dome with a lapis band and gold rim.
	var yo: int = -1 if frame == 1 else 0
	Kit.ball(img, 10.0, 7.0 + float(yo), 6.5, 4.8, GOLD)
	Kit.rect(img, 6, 6 + yo, 9, 2, LAPIS[1])
	Kit.rect(img, 7, 6 + yo, 7, 1, LAPIS[2])
	Kit.line(img, Vector2(10, 3 + yo), Vector2(10, 11 + yo), GOLD[0])
	# Head and horn mandibles.
	Kit.ball(img, 3.5, 8.0, 2.6, 2.4, [SAND[0], Color("#5a3a20"), Color("#8a5a30"), Color("#c89058")])
	Kit.put(img, 0, 6, GOLD[2])
	Kit.put(img, 1, 7, GOLD[1])
	Kit.put(img, 0, 9, GOLD[1])
	Kit.put(img, 2, 7, TURQ)
	return img


static func _orb(frame: int) -> Image:
	var img: Image = Kit.blank(11, 11)
	var cols: Array[Color] = [Color("#4a1068"), Color("#9a2cc8"), Color("#e070ff"), Color("#ffffff")]
	if frame == 1:
		cols = [Color("#8a24b8"), Color("#d850ff"), Color("#ffb8ff"), Color("#ffffff")]
		Kit.disc(img, 5.5, 5.5, 5.5, Color(1.0, 0.5, 1.0, 0.35))
	Kit.ball(img, 5.5, 5.5, 4.0, 4.0, cols)
	Kit.put(img, 5, 5, Color.WHITE)
	return img


# --- Dust-devil obelisk: a sandstone needle with a gold cap and an eye glyph ----------------------

static func _obelisk(frame: int) -> Image:
	var img: Image = Kit.blank(14, 32)
	for y: int in range(4, 28):
		var half: float = lerpf(3.0, 5.0, float(y - 4) / 23.0)
		for x: int in range(int(7.0 - half), int(7.0 + half) + 1):
			var shade: int = 2
			if x <= int(7.0 - half) + 1:
				shade = 3
			elif x >= int(7.0 + half) - 1:
				shade = 1
			Kit.put(img, x, y, STONE[shade])
	# Pyramidion cap.
	for y2: int in range(0, 5):
		Kit.rect(img, 7 - y2 / 2 - 1, y2, y2 + 2, 1, GOLD[2] if y2 < 3 else GOLD[1])
	Kit.put(img, 6, 0, GOLD[3])
	# Plinth.
	Kit.rect(img, 1, 28, 12, 4, STONE[1])
	Kit.rect(img, 1, 28, 12, 1, STONE[3])
	Kit.rect(img, 1, 31, 12, 1, STONE[0])
	# Carved glyphs down the shaft.
	for gy: int in range(14, 27, 4):
		Kit.put(img, 6, gy, STONE[0])
		Kit.put(img, 7 + (gy % 3) - 1, gy + 1, STONE[0])
		Kit.put(img, 5, gy + 2, STONE[0])
	# The eye of the devil: dark until it spins up.
	var eye: Color = TURQ if frame == 1 else TURQ_D
	Kit.rect(img, 5, 8, 4, 2, Color("#2a1810"))
	Kit.put(img, 6, 8, eye)
	Kit.put(img, 7, 8, eye)
	Kit.put(img, 5, 10, Color("#2a1810"))
	if frame == 1:
		Kit.put(img, 6, 9, Color.WHITE)
	return img


# --- Shots -----------------------------------------------------------------------------------

# A gold-rimmed turquoise glyph diamond (orb shards, devil spirals, boss rings).
static func _glyph() -> Image:
	var img: Image = Kit.blank(7, 7)
	for y: int in range(7):
		var half: int = 3 - absi(y - 3)
		Kit.rect(img, 3 - half, y, half * 2 + 1, 1, GOLD[2])
	for y2: int in range(1, 6):
		var h2: int = 2 - absi(y2 - 3)
		if h2 >= 0:
			Kit.rect(img, 3 - h2, y2, h2 * 2 + 1, 1, TURQ)
	Kit.put(img, 3, 3, Color.WHITE)
	return img


# A clot of hot sand spat by the worms (cream core, burnt rim).
static func _sand() -> Image:
	var img: Image = Kit.blank(6, 6)
	Kit.disc(img, 3.0, 3.0, 3.0, Color("#c8642a"))
	Kit.disc(img, 3.0, 3.0, 2.0, Color("#ffd890"))
	Kit.put(img, 2, 2, Color.WHITE)
	Kit.put(img, 3, 2, Color("#fff4d8"))
	return img


# --- Boss: SPHINX ENGINE "ANKHERA" ----------------------------------------------------------------
# A mechanical sphinx: nemes headdress in gold and lapis, a bronze face with glowing eyes, a lion
# body with an ankh reactor in the chest. Frame 1 brightens the eyes and core; frame 2 (attack)
# opens the mouth, turns the eyes white-hot and unsheathes the claws.

const BW: int = 128
const BH: int = 144


static func _paint_boss(frame: int) -> Image:
	var img: Image = BossPainter._new_img(BW, BH)
	var hot: bool = frame == 2
	var st_sh: Color = Color("#5a3a22")
	var st: Color = Color("#a87a48")
	var st_hi: Color = Color("#d8b078")
	var g_sh: Color = Color("#7a5414")
	var g: Color = Color("#d8a030")
	var g_hi: Color = Color("#ffe07a")

	# Lion body: a rounded torso and haunch shaded like stone lit from the upper left, ribs, and a
	# tail curling up behind.
	var st_cols: Array[Color] = [st_sh, st, st_hi, Color("#f0d098")]
	BossPainter._thick_line(img, Vector2(122.0, 122.0), Vector2(125.0, 92.0), 2, st, st_hi)
	BossPainter._thick_line(img, Vector2(125.0, 92.0), Vector2(118.0, 80.0), 2, st, st_hi)
	BossPainter._glow_orb(img, 117, 78, 3, g_sh, g, g_hi)
	BossPainter._circle(img, 104, 102, 25, st_sh.darkened(0.45))
	EnemyArt._ball(img, 104.0, 102.0, 23.0, 24.0, st_cols)
	BossPainter._circle(img, 80, 100, 27, st_sh.darkened(0.45))
	EnemyArt._ball(img, 80.0, 100.0, 36.0, 25.0, st_cols)
	for rib: int in range(4):
		var rx0: int = 74 + rib * 7
		for ry: int in range(84, 112):
			var bend: int = int(round(sin(float(ry - 84) / 28.0 * PI) * 3.0))
			BossPainter._px(img, rx0 + bend, ry, st_sh)
			BossPainter._px(img, rx0 + bend + 1, ry, st_hi)
	# Gold saddle cloth with a lapis border on the back.
	BossPainter._rect(img, 78, 76, 30, 6, g)
	BossPainter._rect(img, 78, 76, 30, 1, g_hi)
	BossPainter._rect(img, 78, 81, 30, 2, Color("#1e3aa0"))

	# Forelegs stretched forward along the bottom, the far one darker, with rounded paws.
	BossPainter._armor_plate(img, 18, 112, 50, 14, st_sh, st, st_sh.darkened(0.3), false)
	EnemyArt._ball(img, 20.0, 119.0, 8.0, 7.0, [st_sh.darkened(0.3), st_sh, st, st_hi])
	BossPainter._armor_plate(img, 12, 124, 58, 16, st, st_hi, st_sh, false)
	EnemyArt._ball(img, 14.0, 132.0, 10.0, 8.0, st_cols)
	for tx: int in [8, 12, 16]:
		BossPainter._rect(img, tx, 129, 1, 9, st_sh)
	var claw: int = 5 if hot else 1
	for cy: int in [128, 132, 136]:
		BossPainter._rect(img, 5 - claw, cy, claw + 1, 2, Color("#f0e8d0"))
	for cy2: int in [116, 121]:
		BossPainter._rect(img, 13 - claw, cy2, claw + 1, 2, Color("#c8c0a8"))
	# Gold bracelet bands on the forelegs.
	BossPainter._rect(img, 44, 124, 6, 16, g)
	BossPainter._rect(img, 44, 124, 6, 2, g_hi)
	BossPainter._rect(img, 46, 128, 2, 8, Color("#1e3aa0"))

	# Chest armour with the ankh reactor.
	BossPainter._armor_plate(img, 50, 72, 32, 46, g_sh, g, Color("#4a3008"))
	var ank: Color = Color("#28f0d4") if frame == 0 else (Color("#7afff0") if frame == 1 else Color.WHITE)
	var ank_d: Color = Color("#0e7a78") if not hot else Color("#28f0d4")
	BossPainter._circle(img, 66, 86, 6, ank_d)
	BossPainter._circle(img, 66, 86, 4, Color("#2a1408"))
	BossPainter._circle(img, 66, 86, 2, ank)
	BossPainter._rect(img, 64, 92, 5, 20, ank_d)
	BossPainter._rect(img, 65, 93, 3, 18, ank)
	BossPainter._rect(img, 57, 95, 19, 4, ank_d)
	BossPainter._rect(img, 58, 96, 17, 2, ank)
	if hot:
		for gi: int in range(24):
			var ga: float = TAU * float(gi) / 24.0
			BossPainter._px(img, 66 + int(round(cos(ga) * 8.0)), 86 + int(round(sin(ga) * 8.0)), Color("#7afff0"))

	# Nemes headdress: a striped hood flaring from the crown into two lappets on the chest.
	var hood: PackedVector2Array = PackedVector2Array([
		Vector2(30, 7), Vector2(60, 7), Vector2(72, 30), Vector2(74, 82), Vector2(60, 82),
		Vector2(58, 40), Vector2(32, 40), Vector2(30, 82), Vector2(14, 82), Vector2(16, 30),
	])
	Painter.poly(img, hood, Color("#0e1c58"))
	for y: int in range(8, 82):
		var band: bool = ((y + (1 if frame == 1 else 0)) / 4) % 2 == 0
		var c: Color = g if band else Color("#1e3aa0")
		var c_edge: Color = g_hi if band else Color("#4a78e8")
		for x: int in range(12, 78):
			if img.get_pixel(x, y).a > 0.0 and img.get_pixel(x, y).is_equal_approx(Color("#0e1c58")):
				var shade: Color = c
				if img.get_pixel(x - 1, y).a == 0.0 or x < 20:
					shade = c_edge
				elif x > 68:
					shade = c.darkened(0.3)
				img.set_pixel(x, y, shade)
	# Crown band.
	BossPainter._armor_plate(img, 28, 6, 34, 8, g_sh, g, Color("#4a3008"), false)
	BossPainter._rect(img, 30, 7, 30, 1, g_hi)

	# Bronze face.
	var f_sh: Color = Color("#6a3a1a")
	var f: Color = Color("#b8783a")
	var f_hi: Color = Color("#e8b070")
	BossPainter._rect(img, 31, 14, 28, 50, f_sh)
	BossPainter._rect(img, 32, 14, 26, 48, f)
	BossPainter._rect(img, 33, 15, 9, 44, f_hi)
	BossPainter._rect(img, 33, 58, 24, 6, f_sh)
	# Brow, nose and cheek planes.
	BossPainter._rect(img, 33, 29, 24, 2, f_sh)
	BossPainter._rect(img, 44, 32, 3, 14, f_hi)
	BossPainter._rect(img, 47, 33, 1, 13, f_sh)
	BossPainter._rect(img, 42, 45, 8, 2, f_sh)
	# Eyes: kohl-lined almonds with glowing turquoise irises.
	var iris: Color = Color("#28f0d4") if frame == 0 else Color("#7afff0")
	if hot:
		iris = Color.WHITE
	for ex: int in [34, 48]:
		BossPainter._rect(img, ex - 1, 33, 10, 5, Color("#0e1c58"))
		BossPainter._rect(img, ex, 34, 8, 3, Color("#f0e8d0"))
		BossPainter._rect(img, ex + 2, 34, 4, 3, iris)
		BossPainter._rect(img, ex + 7, 37, 4, 1, Color("#0e1c58"))
		if hot:
			BossPainter._rect(img, ex - 2, 35, 1, 1, Color("#7afff0"))
			BossPainter._rect(img, ex + 9, 35, 1, 1, Color("#7afff0"))
			BossPainter._rect(img, ex + 1, 32, 6, 1, Color("#7afff0"))
	# Mouth: a closed line, or open and glowing on the attack frame.
	if hot:
		BossPainter._rect(img, 37, 50, 15, 7, Color("#2a0a08"))
		BossPainter._rect(img, 39, 51, 11, 5, Color("#ff6a1a"))
		BossPainter._rect(img, 41, 52, 7, 3, Color("#ffe07a"))
	else:
		BossPainter._rect(img, 38, 52, 13, 1, f_sh)
		BossPainter._rect(img, 39, 53, 11, 1, Color("#8a4a24"))
	# False beard.
	for by: int in range(62, 80):
		var bc: Color = g if (by / 3) % 2 == 0 else Color("#1e3aa0")
		BossPainter._rect(img, 41, by, 8, 1, bc)
	BossPainter._rect(img, 40, 79, 10, 2, g_hi)
	# Uraeus cobra on the brow.
	BossPainter._rect(img, 44, 4, 3, 8, g)
	BossPainter._circle(img, 45, 4, 2, g_hi)
	BossPainter._px(img, 44, 4, Color("#ff2a3a"))
	# Gold collar where the lappets meet the chest.
	BossPainter._rect(img, 30, 80, 46, 3, g_hi)
	for cx: int in range(31, 76, 3):
		BossPainter._px(img, cx, 83, Color("#28f0d4") if (cx + frame) % 2 == 0 else Color("#1e3aa0"))
	return img
