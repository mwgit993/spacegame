extends RefCounted

# ORE MINES sprites. build() runs on a worker thread, so it only paints Images. Every key starts
# with the stage id ("mines_...", "boss_mines_..."). Enemies face left, toward the player.
# Palette: hazard yellow and scuffed steel machines, cyan ore crystals, sodium-orange lamps.

const Kit = preload("res://scripts/stages/art_kit.gd")

const K: Color = Color("#1a1410")
const STEEL: Array[Color] = [Color("#2c2f37"), Color("#555b68"), Color("#8d95a3"), Color("#d4dae2")]
const HAZ: Color = Color("#f2b630")
const HAZ_D: Color = Color("#a8701c")
const HAZ_L: Color = Color("#ffe07a")
const STRIPE: Color = Color("#2a2018")
const ORE: Array[Color] = [Color("#0e5a6a"), Color("#1fb4c8"), Color("#7ef4ff"), Color("#ffffff")]
const ROCK: Array[Color] = [Color("#2a221c"), Color("#4a3e34"), Color("#6e5e50"), Color("#968470")]
const RED: Color = Color("#ff3c3c")
const AMBER: Color = Color("#ff9a2a")


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(2):
		out[id + "_drill_%d" % f] = Kit.outline(_drillbot(f))
		out[id + "_hauler_%d" % f] = Kit.outline(_hauler(f))
		out[id + "_surveyor_%d" % f] = Kit.outline(_surveyor(f))
	out[id + "_ore"] = Kit.outline(_ore_shot())
	out[id + "_bolt"] = _bolt_shot()
	for f2: int in range(3):
		out["boss_%s_%d" % [id, f2]] = _paint_boss(f2)
	return out


# --- Drill bot: a stubby hazard-yellow burrower with a spinning steel drill -----------------------

static func _drillbot(frame: int) -> Image:
	var img: Image = Kit.blank(21, 13)
	# Body (x 8..18): armoured shell, hazard stripes along the top, red sensor eye.
	Kit.rect(img, 8, 2, 10, 9, HAZ)
	Kit.rect(img, 9, 1, 8, 1, HAZ_L)
	Kit.rect(img, 8, 2, 10, 1, HAZ_L)
	Kit.rect(img, 8, 9, 10, 2, HAZ_D)
	Kit.rect(img, 18, 3, 1, 7, HAZ_D)
	for sx: int in range(9, 18, 3):
		Kit.put(img, sx, 3, STRIPE)
		Kit.put(img, sx + 1, 4, STRIPE)
	Kit.rect(img, 10, 5, 4, 3, STEEL[0])
	Kit.put(img, 11, 6, RED)
	Kit.put(img, 12, 6, Color("#ffb0a0"))
	Kit.rect(img, 15, 6, 2, 3, STEEL[1])
	# Tread skids underneath and a hot exhaust at the back.
	Kit.rect(img, 9, 11, 9, 1, STEEL[0])
	for tx: int in range(9, 18, 2):
		Kit.put(img, tx + (frame % 2), 11, STEEL[2])
	Kit.rect(img, 19, 5, 1, 3, AMBER)
	Kit.put(img, 20, 6, HAZ_L if frame == 1 else AMBER)
	# Drill cone (x 0..7): spiral grooves shift between frames so it spins.
	for x: int in range(8):
		var half: int = int(round(float(x) * 0.68))
		for y: int in range(6 - half, 6 + half + 1):
			var shade: int = 2
			if y < 6 - half + 1:
				shade = 3
			elif y > 6 + half - 2:
				shade = 1
			if (x + y + frame * 2) % 4 == 0:
				shade = 0
			Kit.put(img, x, y, STEEL[shade])
	Kit.put(img, 0, 6, Color.WHITE)
	Kit.rect(img, 7, 1, 1, 11, STEEL[0])
	return img


# --- Ore hauler: a boxy freighter with a hopper full of glowing ore --------------------------------

static func _hauler(frame: int) -> Image:
	var img: Image = Kit.blank(40, 24)
	# Hull.
	Kit.rect(img, 4, 10, 32, 9, STEEL[1])
	Kit.rect(img, 4, 10, 32, 1, STEEL[2])
	Kit.rect(img, 4, 17, 32, 2, STEEL[0])
	# Cockpit nose at the front (left), with a lit window.
	for i: int in range(5):
		Kit.rect(img, i, 13 - i / 2, 1, 4 + i, STEEL[1] if i > 1 else STEEL[0])
	Kit.rect(img, 5, 11, 7, 4, STEEL[2])
	Kit.rect(img, 6, 12, 5, 2, Color("#ffd27a"))
	Kit.put(img, 6, 12, Color.WHITE)
	# Hazard band along the hull.
	for sx: int in range(13, 35):
		var on: bool = ((sx / 2) % 2) == 0
		Kit.put(img, sx, 15, HAZ if on else STRIPE)
		Kit.put(img, sx, 16, HAZ_D if on else STRIPE)
	# Hopper: a trapezoid bin on top, heaped with ore; frame 1 tips it forward.
	var tip: int = 1 if frame == 1 else 0
	for row: int in range(7):
		var x0: int = 14 + (6 - row) / 2 - tip * (row % 2)
		var x1: int = 34 - (6 - row) / 2
		Kit.rect(img, x0, 3 + row + tip, x1 - x0, 1, HAZ_D if row < 6 else STEEL[0])
	Kit.rect(img, 14 - tip, 3 + tip, 21, 1, HAZ)
	for i: int in range(14):
		var ox: int = 16 + (i * 7) % 17
		var oy: int = 1 + (i * 5) % 3 + tip
		var c: Color = ORE[1 + (i % 3)] if i % 3 != 0 else ROCK[2]
		Kit.disc(img, float(ox) + 0.5, float(oy) + 1.5, 1.5, c)
	Kit.put(img, 22, 1 + tip, ORE[3])
	Kit.put(img, 29, 2 + tip, ORE[3])
	# Engine pod at the back with exhaust.
	Kit.rect(img, 35, 9, 4, 10, STEEL[0])
	Kit.rect(img, 36, 10, 2, 8, STEEL[1])
	Kit.rect(img, 39, 12, 1, 4, AMBER)
	# Landing struts and hazard lamps (lit on frame 1).
	Kit.rect(img, 9, 19, 2, 3, STEEL[0])
	Kit.rect(img, 28, 19, 2, 3, STEEL[0])
	Kit.rect(img, 7, 22, 6, 1, STEEL[1])
	Kit.rect(img, 26, 22, 6, 1, STEEL[1])
	var lamp: Color = HAZ_L if frame == 1 else Color("#7a4a10")
	Kit.put(img, 14, 9, lamp)
	Kit.put(img, 34, 9, lamp)
	return img


# --- Laser surveyor: a hovering tripod drone with a big lens -------------------------------------

static func _surveyor(frame: int) -> Image:
	var img: Image = Kit.blank(20, 18)
	# Folded tripod legs below.
	Kit.line(img, Vector2(9, 11), Vector2(5, 17), STEEL[1])
	Kit.line(img, Vector2(11, 11), Vector2(11, 17), STEEL[1])
	Kit.line(img, Vector2(13, 11), Vector2(17, 17), STEEL[1])
	Kit.put(img, 5, 17, HAZ)
	Kit.put(img, 11, 17, HAZ)
	Kit.put(img, 17, 17, HAZ)
	# Body: a rounded steel housing with a hazard collar.
	Kit.ball(img, 12.0, 7.5, 7.0, 5.5, STEEL)
	Kit.rect(img, 6, 11, 12, 1, HAZ)
	Kit.rect(img, 6, 11, 2, 1, STRIPE)
	Kit.rect(img, 12, 11, 2, 1, STRIPE)
	# Antenna mast with a beacon.
	Kit.rect(img, 14, 0, 1, 3, STEEL[2])
	Kit.put(img, 14, 0, RED if frame == 1 else Color("#7a1c1c"))
	# The survey lens on the front (left): glows on frame 1.
	Kit.disc(img, 5.5, 7.5, 4.0, STEEL[0])
	var lens: Array[Color] = [Color("#7a0c2a"), Color("#ff3c5a"), Color("#ffb0c0"), Color.WHITE]
	if frame == 0:
		lens = [Color("#3a0814"), Color("#8a1c34"), Color("#d04860"), Color("#ffb0c0")]
	Kit.ball(img, 5.0, 7.5, 2.8, 2.8, lens)
	return img


# --- Shots ---------------------------------------------------------------------------------------

# A lump of rock with a glowing cyan ore crystal (falls with gravity, so it may rotate).
static func _ore_shot() -> Image:
	var img: Image = Kit.blank(7, 7)
	Kit.disc(img, 3.5, 3.5, 3.4, ROCK[1])
	Kit.put(img, 1, 2, ROCK[2])
	Kit.put(img, 2, 1, ROCK[3])
	Kit.disc(img, 3.8, 3.8, 2.0, ORE[1])
	Kit.put(img, 3, 3, ORE[2])
	Kit.put(img, 4, 3, ORE[3])
	Kit.put(img, 3, 4, ORE[2])
	return img


# A hot pink-white mining-laser bolt (always fired straight left, so it's drawn horizontal).
static func _bolt_shot() -> Image:
	var img: Image = Kit.blank(10, 5)
	Kit.rect(img, 1, 1, 8, 3, Color(1.0, 0.25, 0.5, 0.55))
	Kit.rect(img, 0, 2, 10, 1, Color(1.0, 0.3, 0.55, 0.7))
	Kit.rect(img, 2, 2, 6, 1, Color.WHITE)
	Kit.rect(img, 1, 1, 1, 3, Color("#ff5c8a"))
	Kit.put(img, 0, 2, Color("#ffd0e0"))
	return img


# --- Boss: MEGA EXCAVATOR "MAWGRINDER" -------------------------------------------------------------
# A towering bucket-wheel excavator: the wheel turns between frames, the stacks smoke, and on the
# attack frame the buckets glow white-hot and the crusher jaw opens.

const BW: int = 128
const BH: int = 158
const WHEEL_C: Vector2 = Vector2(36.0, 46.0)
const WHEEL_R: float = 30.0


static func _paint_boss(frame: int) -> Image:
	var img: Image = BossPainter._new_img(BW, BH)
	var base: Color = Color("#c8901e")
	var hi: Color = Color("#ffd25a")
	var sh: Color = Color("#6a4410")
	var steel: Color = Color("#5a606c")
	var steel_hi: Color = Color("#aab2bf")
	var steel_sh: Color = Color("#2a2d35")
	var hot: bool = frame == 2

	# Caterpillar tracks along the bottom.
	BossPainter._armor_plate(img, 34, 132, 90, 22, steel_sh, steel, Color("#15171c"), false)
	for i: int in range(11):
		var tx: int = 38 + i * 8 + (frame * 3) % 8
		if tx < 120:
			BossPainter._rect(img, tx, 134, 3, 18, steel_hi if i % 2 == 0 else steel)
	for wx: int in [46, 66, 86, 106]:
		BossPainter._circle(img, wx, 143, 6, steel_sh)
		BossPainter._circle(img, wx, 143, 4, steel)
		BossPainter._circle(img, wx - 1, 142, 1, steel_hi)

	# Main house: a stacked machine body with hazard bands and a lit control cab.
	BossPainter._armor_plate(img, 58, 44, 64, 90, sh, base, Color("#3a2408"))
	BossPainter._armor_plate(img, 66, 54, 52, 70, base, hi, sh)
	# Grime creeping up from the bottom of the house.
	for gy: int in range(96, 124):
		for gx: int in range(67, 117):
			var gk: float = float(gy - 96) / 28.0
			if float(((gx * 7 + gy * 13) % 17)) / 17.0 < gk * 0.55:
				BossPainter._px(img, gx, gy, Color("#9a6a14"))
	# Panel seams with rivets.
	for sx0: int in [82, 100]:
		BossPainter._rect(img, sx0, 56, 1, 66, sh)
		BossPainter._rect(img, sx0 + 1, 56, 1, 66, hi)
		for ry: int in range(60, 120, 8):
			BossPainter._px(img, sx0 - 2, ry, sh)
			BossPainter._px(img, sx0 + 3, ry, sh)
	# Diagonal hazard bands.
	for row_y: int in [62, 112]:
		for sy: int in range(row_y, row_y + 5):
			for sx: int in range(68, 116):
				var on: bool = ((sx + sy) / 3) % 2 == 0
				BossPainter._px(img, sx, sy, Color("#f2b630") if on else Color("#2a2018"))
	# Smelter furnace window glowing through a grille (white-hot on the attack frame).
	BossPainter._armor_plate(img, 70, 76, 26, 26, steel_sh, steel, Color("#15171c"), false)
	var glow_a: Color = Color("#ff8a1a") if not hot else Color("#ffe07a")
	var glow_b: Color = Color("#c84a10") if not hot else Color("#ff9a2a")
	BossPainter._rect(img, 73, 79, 20, 20, glow_b)
	BossPainter._rect(img, 75, 83 - frame, 16, 14 + frame, glow_a)
	BossPainter._rect(img, 78, 88, 10, 6, Color("#fff2c0") if hot else Color("#ffd27a"))
	for bx: int in range(74, 93, 4):
		BossPainter._rect(img, bx, 79, 1, 20, Color("#2a1408"))
	# Vent slats.
	for vy: int in range(78, 100, 4):
		BossPainter._rect(img, 102, vy, 13, 2, Color("#3a2408"))
		BossPainter._rect(img, 102, vy + 2, 13, 1, hi)
	# A fat pipe running down the left edge of the house into the boom.
	BossPainter._thick_line(img, Vector2(62.0, 50.0), Vector2(62.0, 126.0), 2, steel, steel_hi)
	for py: int in [60, 84, 108]:
		BossPainter._rect(img, 59, py, 7, 2, steel_sh)
	# Control cab with windows (the operators' lights).
	BossPainter._armor_plate(img, 70, 24, 36, 24, steel, steel_hi, steel_sh)
	for wi: int in range(3):
		var wc: Color = Color("#ffd27a") if (wi + frame) % 3 != 0 else Color("#ff9a2a")
		BossPainter._rect(img, 74 + wi * 10, 30, 7, 8, Color("#1a1410"))
		BossPainter._rect(img, 75 + wi * 10, 31, 5, 6, wc)
		BossPainter._px(img, 75 + wi * 10, 31, Color.WHITE)
	# Smokestacks; frame-dependent exhaust puffs.
	for sx2: int in [100, 112]:
		BossPainter._armor_plate(img, sx2, 8, 8, 40, steel_sh, steel, Color("#15171c"), false)
		BossPainter._rect(img, sx2 + 1, 8, 6, 2, Color("#ff9a2a") if hot else Color("#3a2408"))
	var puff_y: int = 4 - frame * 2
	for pk: int in range(3):
		var pr: int = 3 + pk + (1 if hot else 0)
		BossPainter._circle(img, 104 + pk * 4, puff_y + 2 - pk * 2, pr, Color(0.25, 0.22, 0.2, 0.55 - 0.12 * float(pk)))

	# Lattice boom from the wheel hub into the house.
	var hub: Vector2 = WHEEL_C
	BossPainter._thick_line(img, hub, Vector2(74.0, 64.0), 3, steel, steel_hi)
	BossPainter._thick_line(img, hub + Vector2(0.0, 6.0), Vector2(70.0, 96.0), 2, steel, steel_hi)
	for k: int in range(1, 5):
		var a: Vector2 = hub.lerp(Vector2(74.0, 64.0), float(k) / 5.0)
		var b: Vector2 = (hub + Vector2(0.0, 6.0)).lerp(Vector2(70.0, 96.0), float(k) / 5.0)
		BossPainter._thick_line(img, a, b, 1, steel_sh, steel)

	# Bucket wheel: rim, spokes and 8 buckets; it turns 15 degrees per frame.
	var rot: float = deg_to_rad(15.0 * float(frame))
	BossPainter._circle(img, int(hub.x), int(hub.y), int(WHEEL_R) + 1, steel_sh)
	BossPainter._circle(img, int(hub.x), int(hub.y), int(WHEEL_R) - 1, steel)
	BossPainter._circle(img, int(hub.x), int(hub.y), int(WHEEL_R) - 5, Color("#2a2018"))
	for s: int in range(8):
		var a2: float = rot + TAU * float(s) / 8.0 + 0.2
		var tip2: Vector2 = hub + Vector2.from_angle(a2) * (WHEEL_R - 5.0)
		BossPainter._thick_line(img, hub, tip2, 1, steel, steel_hi)
	for s2: int in range(8):
		var a3: float = rot + TAU * float(s2) / 8.0
		var bc: Vector2 = hub + Vector2.from_angle(a3) * WHEEL_R
		var bcol: Color = Color("#ffe07a") if hot else base
		BossPainter._circle(img, int(bc.x), int(bc.y), 6, Color("#3a2408"))
		BossPainter._circle(img, int(bc.x), int(bc.y), 5, bcol)
		var tooth: Vector2 = hub + Vector2.from_angle(a3 - 0.18) * (WHEEL_R + 6.0)
		BossPainter._thick_line(img, bc, tooth, 1, steel_sh, Color.WHITE if hot else steel_hi)
		# ore heaped in the bucket
		BossPainter._px(img, int(bc.x), int(bc.y) - 1, Color("#7ef4ff"))
	BossPainter._glow_orb(img, int(hub.x), int(hub.y), 6, Color("#6a4410"), Color("#ffb22e") if not hot else Color("#ffe07a"), Color.WHITE)

	# Crusher jaw at the lower front: opens on the attack frame.
	var jaw: int = 7 if hot else (2 if frame == 1 else 0)
	BossPainter._armor_plate(img, 18, 100 - jaw, 46, 14, steel, steel_hi, steel_sh)
	BossPainter._armor_plate(img, 18, 116 + jaw, 46, 14, steel, steel_hi, steel_sh)
	for tx2: int in range(20, 62, 5):
		BossPainter._rect(img, tx2, 113 - jaw, 3, 3, Color("#d4dae2"))
		BossPainter._rect(img, tx2 + 2, 115 + jaw, 3, 3, Color("#d4dae2"))
	if hot:
		BossPainter._rect(img, 20, 110 - jaw + 6, 40, jaw * 2 - 4, Color("#ff6a1a"))
		BossPainter._rect(img, 24, 112, 30, 2, Color("#ffe07a"))
	# Warning beacons on the house corners.
	for bxy: Vector2i in [Vector2i(62, 48), Vector2i(118, 48), Vector2i(62, 128)]:
		var on2: bool = (frame + bxy.x) % 2 == 0
		BossPainter._glow_orb(img, bxy.x, bxy.y, 2, Color("#6e1024"), Color("#ff3854") if on2 else Color("#ff9624"), Color.WHITE)
	return img
