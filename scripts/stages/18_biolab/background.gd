extends "res://scripts/stages/stage_background.gd"

# STAGE 18 background: a bio-lab after the containment breach. A panelled back wall with
# vents and hazard signs; a row of specimen tanks bubbling with green fluid and dark shapes
# (two smashed open and empty); ceiling machinery with turning red warning beacons and vines
# hanging and swaying; consoles, ooze puddles and broken glass on the floor. Rare events: a
# lab-wide alarm, a specimen slamming against its glass, and sparks showering from a conduit.
#
# Layers: "sky" 480x270; "wall" 640x190 at y 36 (0.12); "tanks" 768x170 at y 62 (0.3);
# "ceil" 768x44 at y 28 (0.6); "floor" 768x52 at y 208 (0.8).

const Painter = preload("res://scripts/stage_bg_painter.gd")

const WALL_Y: float = 36.0
const WALL_F: float = 0.12
const TANK_Y: float = 62.0
const TANK_F: float = 0.3
const CEIL_Y: float = 28.0
const CEIL_F: float = 0.6
const FLOOR_Y: float = 208.0
const FLOOR_F: float = 0.8

var _alarm_t: float = -1.0
var _alarm_wait: float = 8.0
var _thump_t: float = -1.0
var _thump_i: int = 0
var _thump_wait: float = 4.0
var _spark_wait: float = 3.0
var _pop_t: float = 0.2


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1818
	var out: Dictionary = {}
	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#050a0b"))
	Painter.vgrad(sky, 22, 258, PackedColorArray([Color("#050a0b"), Color("#071012"), Color("#091416"), Color("#071012"), Color("#050a0b")]), 0.5)
	out["sky"] = sky
	_paint_wall(out, rng)
	_paint_tanks(out, rng)
	_paint_ceil(out, rng)
	_paint_floor(out, rng)
	return out


# Back wall: big panels with bevels, vents, a hazard sign here and there, a pipe run.
static func _paint_wall(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 640
	var h: int = 190
	var img: Image = Painter.new_img(w, h)
	img.fill(Color("#08100f"))
	for py: int in range(0, h, 38):
		for px: int in range(0, w, 64):
			var shade: Color = Color("#0a1414") if (px / 64 + py / 38) % 2 == 0 else Color("#091211")
			Painter.rect(img, px + 1, py + 1, 62, 36, shade)
			Painter.span(img, px + 1, px + 62, py + 1, Color("#122020"))
			Painter.vline(img, px + 1, py + 1, py + 36, Color("#101c1c"))
			Painter.span(img, px, px + 63, py + 37, Color("#040808"))
			if rng.randf() < 0.25:
				# a vent grille
				for vy: int in range(py + 10, py + 28, 3):
					Painter.span(img, px + 18, px + 44, vy, Color("#050a0a"))
			elif rng.randf() < 0.15:
				# a faded hazard triangle
				var cx: float = float(px + 32)
				var cy: float = float(py + 20)
				Painter.poly(img, PackedVector2Array([Vector2(cx, cy - 8.0), Vector2(cx + 9.0, cy + 7.0), Vector2(cx - 9.0, cy + 7.0)]), Color("#3a3010"))
				Painter.poly(img, PackedVector2Array([Vector2(cx, cy - 5.0), Vector2(cx + 6.0, cy + 5.0), Vector2(cx - 6.0, cy + 5.0)]), Color("#0a1414"))
				Painter.vline(img, int(cx), int(cy) - 2, int(cy) + 1, Color("#3a3010"))
	# pipe run
	for pr: int in range(2):
		var y: int = 128 + pr * 6
		Painter.rect(img, 0, y, w, 4, Color("#14201f"))
		Painter.span(img, 0, w - 1, y, Color("#22302e"))
		for jx: int in range(20, w, 80):
			Painter.rect(img, jx, y - 1, 4, 6, Color("#1c2a28"))
	# hazard band along the base of the wall
	for hx: int in range(0, w, 8):
		Painter.rect(img, hx, h - 10, 4, 4, Color("#3a3010"))
		Painter.rect(img, hx + 4, h - 10, 4, 4, Color("#0a0a08"))
	out["wall"] = img


# Specimen tanks: glass cylinders of green fluid with dark shapes inside; two are smashed.
static func _paint_tanks(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 170
	var img: Image = Painter.new_img(w, h)
	var tanks: PackedVector4Array = PackedVector4Array()
	var broken_at: Array[int] = [2, 5]
	for t: int in range(6):
		var tx: int = t * 128 + 34 + rng.randi_range(-10, 10)
		var tw: int = rng.randi_range(28, 34)
		var top: int = 16
		var bot: int = 152
		var broken: bool = broken_at.has(t)
		# caps with bolts
		Painter.rect(img, tx - 3, top - 10, tw + 6, 10, Color("#1a2628"))
		Painter.span(img, tx - 3, tx + tw + 2, top - 10, Color("#3a4e52"))
		Painter.rect(img, tx - 4, bot, tw + 8, 14, Color("#1a2628"))
		Painter.span(img, tx - 4, tx + tw + 3, bot, Color("#3a4e52"))
		for b: int in range(4):
			Painter.px(img, tx + 2 + b * (tw / 3), top - 5, Color("#4e6468"))
			Painter.px(img, tx + 1 + b * (tw / 3), bot + 6, Color("#4e6468"))
		Painter.rect(img, tx + tw / 2 - 2, 0, 4, top - 10, Color("#121c1e"))
		if broken:
			# smashed: dark and empty, jagged glass teeth, a puddle at the bottom
			Painter.rect(img, tx, top, tw, bot - top, Color("#060c0c"))
			for g: int in range(tw):
				var tooth_top: int = top + int(absf(sin(float(g) * 1.7)) * 10.0)
				var tooth_bot: int = bot - int(absf(sin(float(g) * 2.3 + 1.0)) * 14.0)
				Painter.vline(img, tx + g, top, tooth_top, Color(0.45, 0.6, 0.58, 0.55))
				Painter.vline(img, tx + g, tooth_bot, bot - 1, Color(0.45, 0.6, 0.58, 0.45))
			Painter.rect(img, tx + 2, bot - 3, tw - 4, 3, Color("#0e2e14"))
			Painter.span(img, tx + 3, tx + tw - 4, bot - 3, Color("#1e5a22"))
		else:
			var level: int = top + rng.randi_range(14, 34)
			Painter.rect(img, tx, top, tw, level - top, Color("#081210"))
			for y: int in range(level, bot):
				var k: float = float(y - level) / float(bot - level)
				var c: Color = Color("#0b2210") if Painter.bayer(tx, y) > k else Color("#08180c")
				Painter.span(img, tx, tx + tw - 1, y, c)
			Painter.span(img, tx, tx + tw - 1, level, Color("#2a6a28"))
			# the specimen inside
			var sx: float = float(tx) + float(tw) * 0.5
			var sy: float = float(level + bot) * 0.5 + 6.0
			match t % 3:
				0:  # curled creature
					Painter.ellipse(img, sx, sy, 9.0, 14.0, Color("#061a0c"))
					Painter.ellipse(img, sx - 3.0, sy - 12.0, 6.0, 6.0, Color("#061a0c"))
					Painter.px(img, int(sx) - 5, int(sy) - 13, Color("#4a8a20"))
				1:  # brain with dangling nerves
					Painter.ellipse(img, sx, sy - 14.0, 10.0, 8.0, Color("#061a0c"))
					for n: int in range(4):
						Painter.line(img, int(sx) - 4 + n * 3, int(sy) - 7, int(sx) - 6 + n * 4, int(sy) + 14, Color("#061a0c"))
				_:  # tentacled thing
					Painter.ellipse(img, sx, sy - 6.0, 8.0, 10.0, Color("#061a0c"))
					for n2: int in range(5):
						Painter.line(img, int(sx), int(sy), int(sx) - 10 + n2 * 5, int(sy) + 26, Color("#061a0c"))
			tanks.append(Vector4(float(tx), float(level), float(tw), float(bot)))
			# glass highlights
			Painter.vline(img, tx + 2, top, bot - 1, Color(0.6, 0.85, 0.8, 0.35))
			Painter.vline(img, tx + tw - 4, top + 8, bot - 10, Color(0.6, 0.85, 0.8, 0.2))
		Painter.vline(img, tx - 1, top, bot - 1, Color("#1a2628"))
		Painter.vline(img, tx + tw, top, bot - 1, Color("#101a1c"))
		# vines climbing the tank
		var vx: int = tx + (0 if t % 2 == 0 else tw - 1)
		for vy2: int in range(bot + 12, rng.randi_range(40, 110), -1):
			var wob: int = int(sin(float(vy2) * 0.3 + float(t)) * 2.0)
			Painter.px(img, vx + wob, vy2, Color("#0e2a12"))
			if vy2 % 7 == 0:
				Painter.px(img, vx + wob + (1 if wob >= 0 else -1), vy2 - 1, Color("#18401a"))
	out["tanks"] = img
	out["tank_meta"] = tanks


# Ceiling machinery: pipes, vents, beacons, hanging vines (their tips sway live).
static func _paint_ceil(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 44
	var img: Image = Painter.new_img(w, h)
	var beacons: PackedVector2Array = PackedVector2Array()
	var vines: PackedVector3Array = PackedVector3Array()
	var conduits: PackedVector2Array = PackedVector2Array()
	Painter.rect(img, 0, 0, w, 8, Color("#0c1415"))
	Painter.span(img, 0, w - 1, 7, Color("#1e2c2e"))
	for p: int in range(2):
		var y: int = 9 + p * 5
		Painter.rect(img, 0, y, w, 3, Color("#121c1d"))
		Painter.span(img, 0, w - 1, y, Color("#26383a"))
	for x: int in range(0, w, 96):
		var bx: int = x + rng.randi_range(10, 80)
		Painter.rect(img, bx - 3, 16, 7, 4, Color("#1a2426"))
		Painter.rect(img, bx - 2, 20, 5, 3, Color("#3a0a0a"))
		beacons.append(Vector2(float(bx), 21.0))
		var cx: int = x + rng.randi_range(0, 90)
		Painter.rect(img, cx, 16, 10, 6, Color("#101a1b"))
		Painter.span(img, cx, cx + 9, 21, Color("#2a1a10"))
		conduits.append(Vector2(float(cx + 5), 22.0))
	for v: int in range(16):
		var vx: int = rng.randi_range(0, w - 1)
		var vl: int = rng.randi_range(8, 26)
		for vy: int in range(16, 16 + vl):
			Painter.px(img, vx + int(sin(float(vy) * 0.4 + float(v)) * 1.5), vy, Color("#0c240e"))
		vines.append(Vector3(float(vx), float(16 + vl), rng.randf_range(14.0, 36.0)))
	out["ceil"] = img
	out["beacons"] = beacons
	out["vines"] = vines
	out["conduits"] = conduits


# Floor: consoles with screens, crates, ooze puddles, broken glass.
static func _paint_floor(out: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = 768
	var h: int = 52
	var img: Image = Painter.new_img(w, h)
	var screens: PackedVector3Array = PackedVector3Array()
	var puddles: PackedVector3Array = PackedVector3Array()
	var glints: PackedVector2Array = PackedVector2Array()
	Painter.rect(img, 0, 40, w, 12, Color("#0c1415"))
	Painter.span(img, 0, w - 1, 40, Color("#26383a"))
	var x: int = 0
	while x < w:
		var kind: int = rng.randi_range(0, 3)
		if kind <= 1:
			var cw: int = rng.randi_range(26, 40)
			var ch: int = rng.randi_range(16, 26)
			Painter.rect(img, x, 40 - ch, cw, ch, Color("#101a1c"))
			Painter.span(img, x, x + cw - 1, 40 - ch, Color("#2e4246"))
			Painter.vline(img, x, 40 - ch, 39, Color("#1e2c2e"))
			Painter.rect(img, x + 4, 40 - ch + 4, cw - 8, 7, Color("#040a0a"))
			screens.append(Vector3(float(x + 5), float(40 - ch + 5), float(cw - 10)))
			for hx: int in range(x, x + cw, 6):
				Painter.rect(img, hx, 36, 3, 2, Color("#3a3010"))
			x += cw + rng.randi_range(4, 20)
		elif kind == 2:
			var s: int = rng.randi_range(10, 16)
			Painter.rect(img, x, 40 - s, s, s, Color("#14140e"))
			Painter.span(img, x, x + s - 1, 40 - s, Color("#2e2e1e"))
			Painter.line(img, x, 40 - s, x + s - 1, 39, Color("#0a0a06"))
			x += s + rng.randi_range(6, 24)
		else:
			var pw: int = rng.randi_range(18, 34)
			Painter.ellipse(img, float(x) + float(pw) * 0.5, 42.0, float(pw) * 0.5, 2.5, Color("#0e2e14"))
			Painter.span(img, x + 3, x + pw - 4, 41, Color("#1e5a22"))
			puddles.append(Vector3(float(x), 41.0, float(pw)))
			for g: int in range(3):
				glints.append(Vector2(float(x + rng.randi_range(0, pw)), float(rng.randi_range(44, 50))))
			x += pw + rng.randi_range(6, 20)
	out["floor"] = img
	out["screens"] = screens
	out["puddles"] = puddles
	out["glints"] = glints


# --- animation ----------------------------------------------------------------------------------

func reset() -> void:
	drift_a.y0 = 32.0
	drift_a.y1 = 250.0
	drift_a.setup(24, rng, -8.0, 4.0, -6.0, 2.0)
	drift_a.par = 0.45
	drift_a.sway = 2.0
	drift_a.sway_hz = 1.0
	drift_a.cols = PackedColorArray([Color(0.5, 1.0, 0.3, 0.35), Color(0.4, 0.8, 0.3, 0.25), Color(0.8, 0.9, 0.85, 0.2)])
	_alarm_t = -1.0
	_alarm_wait = rng.randf_range(6.0, 12.0)
	_thump_t = -1.0
	_thump_wait = rng.randf_range(3.0, 6.0)
	_spark_wait = rng.randf_range(2.0, 4.0)


func update() -> void:
	if _alarm_t < 0.0:
		_alarm_wait -= dl
		if _alarm_wait <= 0.0:
			_alarm_t = 0.0
	else:
		_alarm_t += dl
		if _alarm_t > 3.2:
			_alarm_t = -1.0
			_alarm_wait = rng.randf_range(16.0, 24.0)
	if _thump_t < 0.0:
		_thump_wait -= dl
		if _thump_wait <= 0.0:
			var tanks: PackedVector4Array = meta.get("tank_meta", PackedVector4Array())
			if not tanks.is_empty():
				_thump_t = 0.0
				_thump_i = rng.randi_range(0, tanks.size() - 1)
	else:
		_thump_t += dl
		if _thump_t > 1.2:
			_thump_t = -1.0
			_thump_wait = rng.randf_range(6.0, 11.0)
	_spark_wait -= dl
	if _spark_wait <= 0.0:
		_spark_wait = rng.randf_range(3.5, 7.0)
		var cons: PackedVector2Array = meta.get("conduits", PackedVector2Array())
		if not cons.is_empty():
			var c: Vector2 = cons[rng.randi_range(0, cons.size() - 1)]
			var cx: float = wrap_x(c.x, off(CEIL_F, 768.0), 768.0)
			if cx > 0.0 and cx < 480.0:
				for s: int in range(10):
					fx_spawn(StarfieldBg.Fx.SPARK, cx, CEIL_Y + c.y, rng.randf_range(-50.0, 50.0), rng.randf_range(-20.0, 30.0), rng.randf_range(0.5, 1.0), CEIL_F)


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	layer("wall", WALL_Y, WALL_F)
	layer("tanks", TANK_Y, TANK_F)
	var o_t: float = off(TANK_F, 768.0)
	var tanks: PackedVector4Array = meta.get("tank_meta", PackedVector4Array())
	for i: int in range(tanks.size()):
		var tm: Vector4 = tanks[i]
		var tx: float = wrap_x(tm.x, o_t, 768.0)
		if tx < -40.0 or tx > 480.0:
			continue
		var top: float = TANK_Y + tm.y
		var bot: float = TANK_Y + tm.w
		var glow: float = 0.5 + 0.5 * sin(life * 0.9 + float(i) * 1.7)
		bg.draw_rect(Rect2(floorf(tx), top + 1.0, tm.z, bot - top - 1.0), Color(0.3, 0.9, 0.3, 0.02 + 0.03 * glow))
		for b: int in range(4):
			var span: float = bot - top - 4.0
			var by: float = bot - 2.0 - fposmod(life * (14.0 + float(b) * 5.0) + float(b * 37 + i * 11), span)
			var bx: float = floorf(tx) + 4.0 + fposmod(float(b * 7 + i * 3), tm.z - 8.0) + floorf(sin(life * 2.0 + float(b)) * 1.5)
			bg.draw_rect(Rect2(bx, floorf(by), 1.0 if b % 2 == 0 else 2.0, 1.0 if b % 2 == 0 else 2.0), Color(0.6, 1.0, 0.5, 0.5))
		if _thump_t >= 0.0 and i == _thump_i:
			var k: float = _thump_t / 1.2
			var hit: float = 1.0 if fposmod(_thump_t, 0.4) < 0.08 else 0.0
			var cx: float = floorf(tx) + tm.z * 0.5
			var cy: float = (top + bot) * 0.5
			bg.draw_rect(Rect2(floorf(tx), top, tm.z, bot - top), Color(0.6, 1.0, 0.6, 0.12 * hit))
			var cc: Color = Color(0.85, 1.0, 0.95, 0.5 * (1.0 - k))
			bg.draw_line(Vector2(cx, cy), Vector2(cx - 7.0, cy - 9.0), cc, 1.0)
			bg.draw_line(Vector2(cx, cy), Vector2(cx + 6.0, cy - 5.0), cc, 1.0)
			bg.draw_line(Vector2(cx, cy), Vector2(cx + 2.0, cy + 10.0), cc, 1.0)
	# warning beacons: a turning red light raking the back wall
	var o_c: float = off(CEIL_F, 768.0)
	var beacons: PackedVector2Array = meta.get("beacons", PackedVector2Array())
	var alarm: bool = _alarm_t >= 0.0
	for j: int in range(beacons.size()):
		var bx2: float = wrap_x(beacons[j].x, o_c, 768.0)
		if bx2 < -60.0 or bx2 > 540.0:
			continue
		var by2: float = CEIL_Y + beacons[j].y
		var ang: float = life * (5.0 if alarm else 2.2) + float(j) * 1.3
		var dx: float = cos(ang)
		var a: float = (0.07 if alarm else 0.04) * (0.4 + 0.6 * absf(dx))
		var tip: Vector2 = Vector2(bx2 + dx * 70.0, by2 + 120.0)
		bg.draw_colored_polygon(PackedVector2Array([Vector2(bx2, by2), tip + Vector2(-12.0, 0.0), tip + Vector2(12.0, 0.0)]), Color(1.0, 0.15, 0.1, a))
	drift_draw(drift_b)
	layer("ceil", CEIL_Y, CEIL_F)
	for j2: int in range(beacons.size()):
		var bx3: float = wrap_x(beacons[j2].x, o_c, 768.0)
		if bx3 < 0.0 or bx3 > 480.0:
			continue
		var on: bool = sin(life * (10.0 if alarm else 4.4) + float(j2)) > 0.0
		bg.draw_rect(Rect2(floorf(bx3) - 2.0, CEIL_Y + beacons[j2].y - 1.0, 5.0, 3.0), Color(1.0, 0.2, 0.15, 0.95 if on else 0.35))
		if on:
			bg.draw_rect(Rect2(floorf(bx3) - 5.0, CEIL_Y + beacons[j2].y - 3.0, 11.0, 7.0), Color(1.0, 0.2, 0.15, 0.12))
	# vines hanging from the ceiling, their tips swaying (batched into one draw)
	var vines: PackedVector3Array = meta.get("vines", PackedVector3Array())
	var segs: PackedVector2Array = PackedVector2Array()
	for v: int in range(vines.size()):
		var vx: float = wrap_x(vines[v].x, o_c, 768.0)
		if vx < -20.0 or vx > 500.0:
			continue
		var y0: float = CEIL_Y + vines[v].y
		var length: float = vines[v].z
		var prev: Vector2 = Vector2(floorf(vx) + 0.5, y0 + 0.5)
		for s: int in range(1, 5):
			var t: float = float(s) / 4.0
			var sw: float = sin(life * 1.1 + float(v) * 1.7 + t * 2.0) * t * 5.0
			var p: Vector2 = Vector2(floorf(vx + sw) + 0.5, floorf(y0 + t * length) + 0.5)
			segs.append(prev)
			segs.append(p)
			prev = p
	if not segs.is_empty():
		bg.draw_multiline(segs, Color("#123a16"), 1.0)
	layer("floor", FLOOR_Y, FLOOR_F)
	var o_f: float = off(FLOOR_F, 768.0)
	var screens: PackedVector3Array = meta.get("screens", PackedVector3Array())
	for sc: int in range(screens.size()):
		var sx: float = wrap_x(screens[sc].x, o_f, 768.0)
		if sx < -40.0 or sx > 480.0:
			continue
		var sy: float = FLOOR_Y + screens[sc].y
		var sw2: float = screens[sc].z
		var red: bool = alarm and int(life * 4.0) % 2 == 0
		var col: Color = Color(1.0, 0.25, 0.2, 0.7) if red else Color(0.3, 1.0, 0.6, 0.45)
		var bar: float = fposmod(life * 18.0 + float(sc) * 13.0, sw2)
		bg.draw_rect(Rect2(floorf(sx), sy + 2.0, floorf(bar), 1.0), col)
		bg.draw_rect(Rect2(floorf(sx), sy + 4.0, floorf(sw2 * (0.3 + 0.3 * sin(life * 1.3 + float(sc)) + 0.3)), 1.0), col * Color(1.0, 1.0, 1.0, 0.6))
	var puddles: PackedVector3Array = meta.get("puddles", PackedVector3Array())
	for pd: int in range(puddles.size()):
		var px: float = wrap_x(puddles[pd].x, o_f, 768.0)
		if px < -40.0 or px > 480.0:
			continue
		var ph: float = fposmod(life * 0.8 + float(pd) * 0.37, 1.0)
		if ph < 0.25:
			var bxp: float = floorf(px) + 4.0 + fposmod(float(pd) * 13.0 + floorf(life * 0.8) * 7.0, maxf(1.0, puddles[pd].z - 8.0))
			var r: float = 1.0 + floorf(ph * 8.0)
			bg.draw_rect(Rect2(bxp - r, FLOOR_Y + puddles[pd].y - r, r * 2.0 + 1.0, r), Color(0.5, 1.0, 0.3, 0.6 - ph * 2.0))
	var glints: PackedVector2Array = meta.get("glints", PackedVector2Array())
	for g: int in range(glints.size()):
		if fposmod(life * 0.6 + float(g) * 0.29, 1.0) < 0.08:
			var gx: float = wrap_x(glints[g].x, o_f, 768.0)
			if gx > 0.0 and gx < 480.0:
				bg.draw_rect(Rect2(floorf(gx), FLOOR_Y + glints[g].y, 1.0, 1.0), Color(0.9, 1.0, 1.0, 0.9))
	fx_draw()
	drift_draw(drift_a)
	if alarm:
		var pulse: float = maxf(0.0, sin(_alarm_t * 10.0))
		bg.draw_rect(Rect2(0.0, 28.0, 480.0, 230.0), Color(1.0, 0.1, 0.05, 0.05 * pulse))
