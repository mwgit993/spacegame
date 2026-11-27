extends RefCounted

# STAGE 25 sprites (worker thread: Images only). Station hardware in cold white and gunmetal
# with amber hazard paint, blue solar-cell glass and cyan energy. Every key starts with the
# stage id (or "boss_<id>").

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

const HULL: Array[Color] = [Color("#161e2c"), Color("#323e52"), Color("#5e6e86"), Color("#a8b8cc")]
const WHITE: Array[Color] = [Color("#46546a"), Color("#8896ac"), Color("#c4d0de"), Color("#f2f7ff")]
const BLUE: Array[Color] = [Color("#0a2450"), Color("#1c56a8"), Color("#46a0f0"), Color("#b0e4ff")]
const CORE: Array[Color] = [Color("#0e3a66"), Color("#2a8ad0"), Color("#70dcff"), Color("#e4fbff")]
const AMBER: Color = Color("#f0a030")
const AMBER_D: Color = Color("#7a4810")
const RED: Color = Color("#ff3a3a")
const DARK: Color = Color("#0a0e18")
const CYAN: Color = Color("#60e8ff")


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	out[id + "_pod_0"] = Kit.outline(_pod_flying())
	out[id + "_pod_1"] = Kit.outline(_pod_opening())
	out[id + "_pod_2"] = Kit.outline(_pod_deployed(false))
	out[id + "_pod_3"] = Kit.outline(_pod_deployed(true))
	out[id + "_icpt_0"] = Kit.outline(_interceptor(0))
	out[id + "_icpt_lead"] = Kit.outline(_interceptor(1))
	out[id + "_icpt_flash"] = Kit.outline(_interceptor(2))
	out[id + "_gen_0"] = Kit.outline(_generator(0))
	out[id + "_gen_1"] = Kit.outline(_generator(1))

	# bullet_b: a pale-blue plasma round with a dark rim (reads on the navy sky and white hull).
	var shot: Image = Kit.blank(7, 7)
	Kit.disc(shot, 3.5, 3.5, 3.5, Color("#0a1a3a"))
	Kit.disc(shot, 3.5, 3.5, 2.6, Color("#78d8ff"))
	Kit.disc(shot, 3.0, 3.0, 1.3, Color.WHITE)
	out[id + "_shot"] = shot
	# Flak shell: a fat amber round with a dark driving band; it bursts at its reticle.
	var flak: Image = Kit.blank(10, 10)
	Kit.disc(flak, 5.0, 5.0, 5.0, Color("#2a1404"))
	Kit.ball(flak, 5.0, 5.0, 4.0, 4.0, [AMBER_D, Color("#c87a20"), AMBER, Color("#ffe8a8")])
	Kit.rect(flak, 4, 1, 2, 8, Color("#3a2008"))
	Kit.put(flak, 3, 3, Color.WHITE)
	out[id + "_flak"] = flak
	# Rail lance bolt (rotated to its heading when fired).
	var rail: Image = Kit.blank(13, 5)
	Kit.rect(rail, 0, 0, 13, 5, Color("#0a1a3a"))
	Kit.rect(rail, 1, 1, 11, 3, Color("#48c8ff"))
	Kit.rect(rail, 2, 2, 10, 1, Color.WHITE)
	Kit.put(rail, 0, 0, Color(0, 0, 0, 0))
	Kit.put(rail, 0, 4, Color(0, 0, 0, 0))
	Kit.put(rail, 12, 0, Color(0, 0, 0, 0))
	Kit.put(rail, 12, 4, Color(0, 0, 0, 0))
	out[id + "_rail"] = rail
	# Homing warhead: round enough that it doesn't need to turn with its course.
	var missile: Image = Kit.blank(9, 9)
	Kit.disc(missile, 4.5, 4.5, 4.5, Color("#200808"))
	Kit.ball(missile, 4.5, 4.5, 3.5, 3.5, [Color("#7a1010"), Color("#d02828"), Color("#ff6a4a"), Color("#ffd0b0")])
	Kit.rect(missile, 3, 2, 3, 5, WHITE[2])
	Kit.rect(missile, 4, 3, 1, 3, Color("#ffe060"))
	out[id + "_missile"] = missile

	out[id + "_scout"] = Kit.outline(_g_scout())
	out[id + "_swooper"] = Kit.outline(_g_swooper())
	out[id + "_sniper"] = Kit.outline(_g_sniper())
	out[id + "_cruiser"] = Kit.outline(_g_cruiser())
	for f: int in range(3):
		out["boss_%s_%d" % [id, f]] = Kit.outline(_battery(f), Color("#05070e"))
	return out


static func _poly(img: Image, pts: Array[Vector2], col: Color) -> void:
	Painter.poly(img, PackedVector2Array(pts), col)


# Clipped fill_rect (fast for big painted rectangles).
static func _fill(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	var r: Rect2i = Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, col)


static func _hazard(img: Image, x: int, y: int, w: int, h: int) -> void:
	for hx: int in range(x, x + w, 4):
		_fill(img, hx, y, mini(2, x + w - hx), h, AMBER)
		_fill(img, hx + 2, y, mini(2, maxi(0, x + w - hx - 2)), h, Color("#1a1408"))


# --- turret pod --------------------------------------------------------------------------------

# Flying: a white capsule with a hazard band, a red sensor slit in front and a thruster behind.
static func _pod_flying() -> Image:
	var img: Image = Kit.blank(20, 12)
	Kit.rect(img, 15, 4, 3, 4, HULL[1])
	Kit.rect(img, 15, 4, 3, 1, HULL[2])
	Kit.put(img, 18, 5, CYAN)
	Kit.put(img, 18, 6, CYAN)
	Kit.put(img, 19, 5, Color("#c8f8ff"))
	Kit.ball(img, 8.5, 6.0, 7.5, 4.6, WHITE)
	Kit.rect(img, 9, 2, 2, 8, AMBER)
	Kit.rect(img, 10, 2, 1, 8, AMBER_D)
	Kit.rect(img, 2, 5, 4, 2, DARK)
	Kit.put(img, 3, 5, RED)
	Kit.put(img, 4, 6, Color("#ff9a9a"))
	Kit.line(img, Vector2(5, 3), Vector2(13, 3), WHITE[3])
	return img


# Unfolding: clamp legs swing down, the top hatch opens with a glow.
static func _pod_opening() -> Image:
	var img: Image = Kit.blank(20, 15)
	Kit.line(img, Vector2(6, 8), Vector2(2, 13), HULL[2])
	Kit.line(img, Vector2(7, 8), Vector2(3, 13), HULL[1])
	Kit.line(img, Vector2(13, 8), Vector2(17, 13), HULL[2])
	Kit.line(img, Vector2(12, 8), Vector2(16, 13), HULL[1])
	Kit.rect(img, 1, 13, 4, 2, HULL[2])
	Kit.rect(img, 15, 13, 4, 2, HULL[2])
	Kit.ball(img, 9.5, 7.0, 7.5, 4.4, WHITE)
	Kit.rect(img, 4, 3, 12, 1, DARK)
	Kit.rect(img, 6, 2, 8, 1, AMBER)
	Kit.rect(img, 9, 4, 2, 7, AMBER)
	Kit.rect(img, 2, 6, 3, 2, DARK)
	Kit.put(img, 3, 6, RED)
	return img


# Deployed flak battery: clamps on the hull, a hazard-striped base and a turret dome with a
# radar fin (the barrel is drawn live so it can aim). Lit: the breech glows before a shot.
static func _pod_deployed(lit: bool) -> Image:
	var img: Image = Kit.blank(22, 16)
	Kit.rect(img, 0, 13, 5, 3, HULL[1])
	Kit.rect(img, 17, 13, 5, 3, HULL[1])
	Kit.rect(img, 0, 13, 5, 1, HULL[3])
	Kit.rect(img, 17, 13, 5, 1, HULL[3])
	Kit.rect(img, 2, 10, 18, 4, HULL[1])
	Kit.rect(img, 2, 10, 18, 1, HULL[2])
	_hazard(img, 3, 12, 16, 2)
	Kit.rect(img, 16, 1, 2, 9, HULL[2])
	Kit.rect(img, 17, 1, 1, 9, HULL[1])
	Kit.put(img, 16, 1, RED)
	Kit.ball(img, 10.0, 8.0, 7.0, 5.0, WHITE)
	Kit.rect(img, 4, 7, 5, 2, DARK)
	Kit.put(img, 5, 7, AMBER if lit else RED)
	Kit.put(img, 6, 7, AMBER if lit else Color("#801818"))
	Kit.line(img, Vector2(6, 4), Vector2(13, 4), WHITE[3])
	if lit:
		Kit.disc(img, 8.0, 8.0, 1.6, Color("#ffe080"))
	return img


# --- interceptor -------------------------------------------------------------------------------

# A white dart with swept wings and a blue canopy. Kind 1: the squadron leader (red stripe and
# wingtips). Kind 2: the leader's break signal flash.
static func _interceptor(kind: int) -> Image:
	var img: Image = Kit.blank(18, 11)
	var wing: Color = HULL[2]
	var wing_hi: Color = HULL[3]
	var body: Array[Color] = WHITE
	var stripe: Color = AMBER
	if kind == 1:
		stripe = RED
	elif kind == 2:
		wing = Color("#fff4c0")
		wing_hi = Color.WHITE
		body = [Color("#ffe8a0"), Color("#fff2c8"), Color("#fffbe8"), Color.WHITE]
		stripe = Color("#ffe060")
	_poly(img, [Vector2(8, 4), Vector2(12, 0), Vector2(16, 0), Vector2(14, 4)], wing)
	_poly(img, [Vector2(8, 7), Vector2(14, 7), Vector2(16, 11), Vector2(12, 11)], wing)
	Kit.line(img, Vector2(12, 0), Vector2(15, 0), wing_hi)
	_poly(img, [Vector2(0, 5.5), Vector2(6, 3), Vector2(15, 3.5), Vector2(17, 4.5), Vector2(17, 6.5), Vector2(15, 7.5), Vector2(6, 8)], body[2])
	Kit.line(img, Vector2(6, 3), Vector2(14, 3), body[3])
	Kit.line(img, Vector2(6, 7), Vector2(15, 7), body[1])
	Kit.rect(img, 11, 3, 1, 5, stripe)
	if kind == 1:
		Kit.put(img, 15, 0, RED)
		Kit.put(img, 15, 10, RED)
		Kit.put(img, 14, 0, RED)
		Kit.put(img, 14, 10, RED)
	if kind != 2:
		Kit.rect(img, 4, 4, 4, 2, BLUE[1])
		Kit.put(img, 5, 4, BLUE[3])
		Kit.put(img, 4, 5, BLUE[2])
		Kit.rect(img, 16, 4, 2, 3, CYAN)
		Kit.put(img, 17, 5, Color.WHITE)
	return img


# --- shield generator --------------------------------------------------------------------------

static func _hex(cx: float, cy: float, r: float, rot: float) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for i: int in range(6):
		pts.append(Vector2(cx, cy) + Vector2.from_angle(rot + TAU * float(i) / 6.0) * r)
	return pts


# A hexagonal drone: armoured hex frame, three emitter prongs with amber tips and a cyan core.
# Frame 1: the core flares (it is about to pulse).
static func _generator(frame: int) -> Image:
	var img: Image = Kit.blank(28, 28)
	var c: Vector2 = Vector2(14.0, 14.0)
	for k: int in range(3):
		var a: float = -PI * 0.5 + TAU * float(k) / 3.0 + PI / 3.0
		var tip: Vector2 = c + Vector2.from_angle(a) * 13.0
		Kit.line(img, c + Vector2.from_angle(a) * 8.0, tip, HULL[2])
		Kit.line(img, c + Vector2.from_angle(a) * 8.0 + Vector2(1, 0), tip + Vector2(1, 0), HULL[1])
		Kit.disc(img, tip.x, tip.y, 1.6, AMBER)
	_poly(img, _hex(c.x, c.y, 10.5, PI / 6.0), HULL[1])
	_poly(img, _hex(c.x - 0.5, c.y - 0.5, 9.0, PI / 6.0), HULL[2])
	_poly(img, _hex(c.x, c.y, 7.5, PI / 6.0), HULL[0])
	var top: Array[Vector2] = _hex(c.x, c.y, 10.5, PI / 6.0)
	Kit.line(img, top[3], top[4], HULL[3])
	Kit.line(img, top[4], top[5], HULL[3])
	if frame == 0:
		Kit.ball(img, c.x, c.y, 5.0, 5.0, CORE)
	else:
		Kit.ball(img, c.x, c.y, 5.6, 5.6, [CORE[1], CORE[2], CORE[3], Color.WHITE])
	Kit.disc(img, c.x - 1.5, c.y - 1.5, 1.2, Color.WHITE)
	for b: int in range(6):
		var p: Vector2 = c + Vector2.from_angle(TAU * float(b) / 6.0) * 8.5
		Kit.put(img, int(p.x), int(p.y), Color("#9ad8ff") if frame == 1 else Color("#3a6a90"))
	return img


# --- generic re-skins ----------------------------------------------------------------------------

# Patrol drone: a white pod with a red eye and twin antennae.
static func _g_scout() -> Image:
	var img: Image = Kit.blank(15, 11)
	Kit.line(img, Vector2(9, 3), Vector2(12, 0), HULL[2])
	Kit.line(img, Vector2(9, 7), Vector2(12, 10), HULL[2])
	Kit.ball(img, 7.0, 5.5, 6.0, 4.5, WHITE)
	Kit.rect(img, 12, 4, 2, 3, CYAN)
	Kit.disc(img, 4.0, 5.0, 2.0, DARK)
	Kit.put(img, 3, 5, RED)
	Kit.rect(img, 7, 8, 4, 1, AMBER)
	return img


# Gunmetal strike fighter with forward-swept wings and a blue stripe.
static func _g_swooper() -> Image:
	var img: Image = Kit.blank(19, 13)
	_poly(img, [Vector2(6, 6), Vector2(4, 0), Vector2(9, 0), Vector2(13, 5)], HULL[2])
	_poly(img, [Vector2(6, 7), Vector2(13, 8), Vector2(9, 13), Vector2(4, 13)], HULL[2])
	_poly(img, [Vector2(0, 6.5), Vector2(5, 4), Vector2(16, 4.5), Vector2(18, 6.5), Vector2(16, 8.5), Vector2(5, 9)], HULL[1])
	Kit.line(img, Vector2(5, 4), Vector2(15, 4), HULL[3])
	Kit.line(img, Vector2(6, 6), Vector2(15, 6), BLUE[2])
	Kit.rect(img, 3, 5, 3, 2, BLUE[3])
	Kit.rect(img, 17, 5, 2, 3, CYAN)
	return img


# Sensor satellite: a lens body between two solar panels.
static func _g_sniper() -> Image:
	var img: Image = Kit.blank(17, 17)
	for py: int in [1, 12]:
		Kit.rect(img, 5, py, 10, 4, BLUE[0])
		for gx: int in range(5, 15, 3):
			Kit.rect(img, gx, py, 2, 4, BLUE[1])
		Kit.rect(img, 5, py, 10, 1, BLUE[2])
	Kit.rect(img, 9, 5, 2, 7, HULL[2])
	Kit.ball(img, 9.0, 8.5, 6.0, 4.5, WHITE)
	Kit.disc(img, 5.0, 8.5, 3.0, DARK)
	Kit.disc(img, 5.0, 8.5, 2.0, Color("#801818"))
	Kit.put(img, 4, 8, RED)
	Kit.put(img, 5, 7, Color("#ffb0b0"))
	return img


# Station gunboat: a long armoured hull with a bridge tower, prow cannon and hazard trim.
static func _g_cruiser() -> Image:
	var img: Image = Kit.blank(32, 19)
	_poly(img, [Vector2(2, 9), Vector2(8, 5), Vector2(29, 5), Vector2(31, 8), Vector2(31, 13), Vector2(28, 15), Vector2(8, 15)], WHITE[1])
	_poly(img, [Vector2(4, 9), Vector2(9, 6), Vector2(28, 6), Vector2(30, 9), Vector2(30, 10), Vector2(4, 10)], WHITE[2])
	Kit.line(img, Vector2(9, 5), Vector2(28, 5), WHITE[3])
	Kit.rect(img, 16, 1, 9, 5, HULL[1])
	Kit.rect(img, 16, 1, 9, 1, HULL[3])
	Kit.rect(img, 17, 3, 6, 1, BLUE[2])
	Kit.rect(img, 0, 10, 8, 2, HULL[1])
	Kit.rect(img, 0, 10, 8, 1, HULL[3])
	_hazard(img, 10, 13, 16, 2)
	Kit.rect(img, 29, 7, 2, 5, CYAN)
	Kit.put(img, 12, 8, RED)
	return img


# --- BASTION MAIN BATTERY ------------------------------------------------------------------------
# The station's main defence battery on its mounting pylon: a long twin-rail cannon with glowing
# capacitor rings, a twin-barrel flak turret on top, a six-tube missile block below, a gatling
# point-defence mount, radiator fins and a tracking dish. Frames 0/1: the capacitors pulse and
# the dish turns; frame 2: the rails run white-hot and the missile hatches are open.

static func _battery(frame: int) -> Image:
	var img: Image = BossPainter._new_img(128, 160)
	var hot: bool = frame == 2
	var st: Color = HULL[1]
	var st_hi: Color = HULL[3]
	var st_sh: Color = HULL[0]
	var wh: Color = WHITE[1]
	var wh_hi: Color = WHITE[3]
	var wh_sh: Color = WHITE[0]
	# mounting pylon and lattice girder running off to the station (right edge)
	BossPainter._armor_plate(img, 104, 46, 24, 70, st, HULL[2], st_sh)
	for gy: int in [52, 108]:
		_fill(img, 112, gy, 16, 3, HULL[2])
	for gx: int in range(108, 128, 8):
		Kit.line(img, Vector2(gx, 55), Vector2(gx + 8, 107), HULL[0])
	# radiator fins and tracking dish
	for fx: int in range(90, 114, 6):
		_fill(img, fx, 12, 4, 24, HULL[2])
		_fill(img, fx, 12, 1, 24, HULL[3])
		_fill(img, fx + 3, 12, 1, 24, HULL[0])
		_fill(img, fx + 1, 14 + (frame * 3 + fx) % 8, 2, 2, Color("#3a2414") if not hot else Color("#c85a20"))
	BossPainter._thick_line(img, Vector2(112, 34), Vector2(116, 12), 1, HULL[1], HULL[2])
	var dish_rx: float = 9.0 if frame != 1 else 6.0
	Painter.ellipse(img, 114.0, 9.0, dish_rx, 4.5, WHITE[2])
	Painter.ellipse(img, 114.0 + (1.0 if frame == 1 else 0.0), 9.0, dish_rx - 2.0, 3.0, WHITE[1])
	Kit.put(img, 114, 9, RED if frame != 1 else Color("#ffd0d0"))
	# main housing
	BossPainter._armor_plate(img, 44, 32, 66, 98, wh, wh_hi, wh_sh)
	BossPainter._armor_plate(img, 50, 38, 26, 26, WHITE[2], wh_hi, WHITE[1])
	BossPainter._armor_plate(img, 78, 38, 26, 26, WHITE[2], wh_hi, WHITE[1])
	BossPainter._armor_plate(img, 54, 100, 52, 22, st, HULL[2], st_sh)
	# panel seams, a vent grille and soot from the rail breech on the white plating
	for sy: int in [66, 82]:
		_fill(img, 46, sy, 62, 1, WHITE[0])
		_fill(img, 46, sy + 1, 62, 1, WHITE[2])
	for gy: int in range(70, 96, 3):
		_fill(img, 78, gy, 14, 1, Color("#2a3446"))
		_fill(img, 78, gy + 1, 14, 1, WHITE[2])
	var grime: RandomNumberGenerator = RandomNumberGenerator.new()
	grime.seed = 25250
	for g: int in range(160):
		var gx2: int = grime.randi_range(45, 76)
		var gy2: int = grime.randi_range(62, 99)
		if img.get_pixel(gx2, gy2).v > 0.5 and grime.randf() < 1.0 - float(gx2 - 45) / 32.0:
			img.set_pixel(gx2, gy2, img.get_pixel(gx2, gy2).darkened(0.35))
	for b2: int in range(8):
		var lit2: bool = (b2 + frame * 3) % 4 == 0 or hot
		_fill(img, 60 + b2 * 5, 110, 3, 2, Color("#50ff90") if lit2 else Color("#16402a"))
	# station insignia: a blue chevron on the left plate
	for i: int in range(5):
		_fill(img, 56 + i, 44 + i, 2, 1, BLUE[2])
		_fill(img, 66 - i, 44 + i, 2, 1, BLUE[2])
		_fill(img, 56 + i, 50 + i, 2, 1, BLUE[1])
		_fill(img, 66 - i, 50 + i, 2, 1, BLUE[1])
	# a row of lit ports on the right plate
	for wx: int in range(82, 102, 4):
		_fill(img, wx, 46, 2, 3, Color("#e8c060") if (wx / 4 + frame) % 3 != 0 else Color("#4a3a20"))
	_hazard(img, 46, 125, 62, 3)
	# warning lights along the housing
	for li: int in range(3):
		var on: bool = (li + frame) % 2 == 0 or hot
		BossPainter._circle(img, 98, 72 + li * 10, 2, RED if on else Color("#501414"))
	# flak turret on top
	BossPainter._armor_plate(img, 46, 22, 32, 12, st, HULL[2], st_sh)
	Kit.ball(img, 62.0, 22.0, 13.0, 9.0, [WHITE[0], WHITE[1], WHITE[2], WHITE[3]])
	_fill(img, 52, 20, 9, 2, DARK)
	_fill(img, 54, 20, 2, 2, AMBER if hot else RED)
	BossPainter._thick_line(img, Vector2(54, 18), Vector2(32, 10), 1, HULL[1], HULL[2])
	BossPainter._thick_line(img, Vector2(55, 25), Vector2(34, 17), 1, HULL[1], HULL[2])
	_fill(img, 30, 8, 4, 4, HULL[0])
	_fill(img, 32, 15, 4, 4, HULL[0])
	if hot:
		Kit.disc(img, 31.0, 9.5, 2.0, Color("#ffd060"))
		Kit.disc(img, 33.0, 16.5, 2.0, Color("#ffd060"))
	# rail cannon: breech, twin rails, capacitor rings and the energy channel between the rails
	BossPainter._armor_plate(img, 38, 62, 32, 40, st, HULL[2], st_sh)
	_fill(img, 4, 77, 44, 10, DARK)
	for x: int in range(5, 48):
		var e: float = 0.5 + 0.5 * sin(float(x) * 0.6 - float(frame) * 2.0)
		var col: Color = Color("#1a4a8a").lerp(Color("#48c8ff"), e * 0.6)
		if hot:
			col = Color("#9ae8ff").lerp(Color.WHITE, e)
		_fill(img, x, 81, 1, 2, col)
		if hot or e > 0.8:
			_fill(img, x, 80, 1, 1, col.darkened(0.3))
			_fill(img, x, 83, 1, 1, col.darkened(0.3))
	for ry: int in [72, 87]:
		_fill(img, 2, ry, 46, 5, HULL[2])
		_fill(img, 2, ry, 46, 1, HULL[3])
		_fill(img, 2, ry + 4, 46, 1, HULL[0])
		_fill(img, 0, ry - 1, 4, 7, HULL[1])
	for cx: int in [12, 24, 36]:
		BossPainter._armor_plate(img, cx, 66, 6, 32, st, HULL[2], st_sh, false)
		var lit: bool = hot or (cx / 12 + frame) % 2 == 0
		_fill(img, cx + 2, 69, 2, 2, CYAN if lit else Color("#1a4a6a"))
		_fill(img, cx + 2, 93, 2, 2, CYAN if lit else Color("#1a4a6a"))
	# gatling point-defence mount under the rails
	BossPainter._armor_plate(img, 26, 100, 16, 12, st, HULL[2], st_sh, false)
	for b: int in range(3):
		_fill(img, 12, 103 + b * 3, 15, 2, HULL[2])
		_fill(img, 12, 103 + b * 3, 15, 1, HULL[3])
	_fill(img, 10, 102, 3, 9, HULL[0])
	# missile block: six tubes, hatches closed (amber chevrons) or open (red warheads)
	BossPainter._armor_plate(img, 42, 128, 54, 30, st, HULL[2], st_sh)
	for r: int in range(2):
		for c: int in range(3):
			var tx: int = 47 + c * 15
			var ty: int = 133 + r * 12
			_fill(img, tx, ty, 11, 8, DARK)
			if hot:
				Kit.disc(img, float(tx) + 5.5, float(ty) + 4.0, 3.0, Color("#d02828"))
				Kit.put(img, tx + 4, ty + 2, Color("#ffb0a0"))
			else:
				_fill(img, tx + 1, ty + 1, 9, 6, HULL[2])
				_fill(img, tx + 1, ty + 1, 9, 1, HULL[3])
				_fill(img, tx + 3, ty + 3, 5, 2, AMBER)
	return img
