extends "res://scripts/bosses/boss_rig.gd"

# STAGE 1 boss: the NEMESIS DREADNOUGHT, a fortress-wall battleship captained by a T-rex.
# Its twin cannon turrets track the player and kick back when they fire; the gun-port column down
# its prow glows before the bullet wall; the reactor core's shutters slide open before the ring
# burst; cracks open up in phase 2 and fires break out in phase 3.
# Muzzles: cannon_top, cannon_bot (pattern 1), core (aimed shot and the ring).

const HULL_POS: Vector2 = Vector2(6.0, 0.0)
const HULL_PIVOT: Vector2 = Vector2(50.0, 88.0)
const BASE: Color = Color("#465c8c")
const DARK: Color = Color("#243254")
const DARKER: Color = Color("#161f38")
const HI: Color = Color("#9eb8e8")

var _hull: Sprite2D
var _turrets: Array[Sprite2D] = []
var _barrels: Array[Sprite2D] = []
var _flashes: Array[Sprite2D] = []
var _charges: Array[Sprite2D] = []
var _core: Sprite2D
var _shutters: Array[Sprite2D] = []
var _ports: Sprite2D
var _engines: Array[Sprite2D] = []
var _beacons: Array[Sprite2D] = []
var _cracks: Sprite2D
var _fires: Array[Sprite2D] = []


func build() -> void:
	for i: int in range(2):
		var e: Sprite2D = part(self, Kit.cached("dread_engine", _paint_engine), Vector2(52.0, -70.0 + 140.0 * float(i)), Vector2(2.0, 11.0), -1)
		e.use_parent_material = false
		_engines.append(e)
	_hull = part(self, Kit.cached("dread_hull", _paint_hull), HULL_POS, HULL_PIVOT, 0)
	_cracks = part(_hull, Kit.cached("dread_cracks", _paint_cracks), Vector2.ZERO, HULL_PIVOT, 1)
	_cracks.visible = false
	_ports = part(_hull, Kit.cached("dread_ports", _paint_ports), Vector2(-45.0, -77.0), Vector2.ZERO, 2)
	_ports.use_parent_material = false
	_ports.modulate.a = 0.0
	for p: Vector2 in [Vector2(-4.0, -66.0), Vector2(18.0, -40.0), Vector2(8.0, 40.0), Vector2(26.0, 66.0)]:
		var b: Sprite2D = part(self, Kit.cached("dread_beacon", _paint_beacon), p, Vector2(3.0, 3.0), 2)
		b.use_parent_material = false
		_beacons.append(b)
	for f: Vector2 in [Vector2(10.0, -54.0), Vector2(30.0, 20.0), Vector2(-6.0, 70.0)]:
		var fire: Sprite2D = part(self, Kit.cached("dread_fire", _paint_fire), f, Vector2(5.0, 13.0), 4)
		fire.use_parent_material = false
		fire.visible = false
		_fires.append(fire)

	# Reactor core with its two shutters.
	_core = part(self, Kit.cached("dread_core", _paint_core), Vector2(-8.0, 8.0), Vector2(17.0, 17.0), 1)
	marker(_core, "core", Vector2(0.0, 0.0))
	marker(_core, "ring", Vector2(0.0, 0.0))
	for i: int in range(2):
		var sh_tex: Texture2D = Kit.cached("dread_shutter_%d" % i, _paint_shutter.bind(i == 1))
		_shutters.append(part(self, sh_tex, Vector2(-8.0, 8.0), Vector2(16.0, 12.0 if i == 0 else 0.0), 2))

	# Cannon turrets (top, bottom).
	for i: int in range(2):
		var y: float = -62.0 if i == 0 else 58.0
		var tur: Sprite2D = part(self, Kit.cached("dread_turret", _paint_turret), Vector2(-30.0, y), Vector2(12.0, 12.0), 3)
		var bar: Sprite2D = part(tur, Kit.cached("dread_barrel", _paint_barrel), Vector2(0.0, 0.0), Vector2(29.0, 6.0), -1)
		marker(bar, "cannon_top" if i == 0 else "cannon_bot", Vector2(-29.0, 0.0))
		var ch: Sprite2D = part(bar, Kit.cached("dread_charge", _paint_charge), Vector2(-29.0, 0.0), Vector2(6.0, 6.0), 1)
		ch.use_parent_material = false
		ch.scale = Vector2.ZERO
		var fl: Sprite2D = part(bar, Kit.cached("dread_flash", _paint_flash), Vector2(-30.0, 0.0), Vector2(12.0, 8.0), 2)
		fl.use_parent_material = false
		fl.visible = false
		_turrets.append(tur)
		_barrels.append(bar)
		_charges.append(ch)
		_flashes.append(fl)

	add_pilot(self, Vector2(-14.0, -32.0), "rex", Vector2i(36, 28), 4)


func animate(delta: float) -> void:
	var nxt: int = next_pattern()
	var w_wall: float = windup if nxt == 0 else 0.0
	var w_guns: float = windup if nxt == 1 else 0.0
	var w_ring: float = windup if nxt == 2 else 0.0

	# Hit jolt and phase-change shudder.
	var shud: float = rage * (1.0 if int(t * 40.0) % 2 == 0 else -1.0) * 1.5
	position = Vector2(hurt_k * 1.5 + shud, 0.0)

	# Turrets track the player; barrels kick back along their axis.
	var a: Vector2 = aim()
	var rot: float = clampf(wrapf(a.angle() - PI, -PI, PI), -0.5, 0.5)
	for i: int in range(2):
		var bar: Sprite2D = _barrels[i]
		bar.rotation = lerp_angle(bar.rotation, rot, clampf(delta * 5.0, 0.0, 1.0))
		var recoil: float = 7.0 * kick * kick if pattern == 1 else 2.0 * kick
		bar.position = Vector2(recoil, 0.0).rotated(bar.rotation)
		var c: float = w_guns
		_charges[i].scale = Vector2(c, c) * (1.0 + 0.2 * sin(t * 40.0))
		_flashes[i].visible = pattern == 1 and kick > 0.72
		_flashes[i].scale = Vector2.ONE * (0.8 + randf() * 0.5)

	# Reactor: pulses; brightens and opens its shutters before the ring.
	var pulse: float = 1.0 + 0.05 * sin(t * (5.0 + float(phase()) * 2.0)) + 0.22 * w_ring + 0.15 * (kick if pattern == 2 else 0.0)
	_core.scale = Vector2(pulse, pulse)
	var open: float = 3.0 + 1.0 * sin(t * 2.0) + 9.0 * maxf(w_ring, kick if pattern == 2 else 0.0)
	_shutters[0].position = Vector2(-8.0, 8.0 - open)
	_shutters[1].position = Vector2(-8.0, 8.0 + open)

	# Gun ports light up before the wall of bullets.
	_ports.modulate.a = clampf(maxf(w_wall, kick if pattern == 0 else 0.0) * (0.75 + 0.25 * sin(t * 50.0)), 0.0, 1.0)

	# Engines flicker; beacons blink (fast and red in a rage / late phases).
	for e: Sprite2D in _engines:
		e.scale = Vector2(randf_range(0.85, 1.15), 1.0)
	var blink_rate: float = 3.0 + float(phase()) * 2.0 + rage * 10.0
	for i: int in range(_beacons.size()):
		_beacons[i].visible = int(t * blink_rate + float(i) * 0.5) % 2 == 0
		_beacons[i].modulate = Color(1.0, 0.25, 0.25) if (phase() >= 2 or rage > 0.0) else Color.WHITE

	# Battle damage.
	_cracks.visible = phase() >= 2 or dying
	for i: int in range(_fires.size()):
		var f: Sprite2D = _fires[i]
		f.visible = phase() >= 3 or dying
		f.scale = Vector2(randf_range(0.8, 1.15), randf_range(0.8, 1.3))


# --- Painting -----------------------------------------------------------------------------------

static func _paint_hull() -> Image:
	var img: Image = Kit.blank(100, 176)
	Kit.poly(img, PackedVector2Array([Vector2(16, 2), Vector2(78, 0), Vector2(99, 10), Vector2(99, 166), Vector2(78, 176), Vector2(16, 174), Vector2(3, 146), Vector2(3, 30)]), BASE)
	Kit.poly(img, PackedVector2Array([Vector2(70, 3), Vector2(99, 12), Vector2(99, 164), Vector2(70, 173)]), DARK)
	for pl: Rect2i in [Rect2i(18, 6, 50, 14), Rect2i(18, 156, 50, 14), Rect2i(46, 28, 22, 18), Rect2i(46, 130, 22, 18), Rect2i(54, 66, 14, 44)]:
		Kit.plate(img, pl.position.x, pl.position.y, pl.size.x, pl.size.y, BASE.lightened(0.05), true)
	for pl2: Rect2i in [Rect2i(74, 20, 20, 30), Rect2i(74, 126, 20, 30), Rect2i(74, 70, 20, 36)]:
		Kit.plate(img, pl2.position.x, pl2.position.y, pl2.size.x, pl2.size.y, DARK.lightened(0.08), true)
	for ry: int in [22, 48, 128, 154]:
		Kit.rect(img, 14, ry, 80, 2, DARKER)
		Kit.rect(img, 14, ry + 2, 80, 1, HI)
	# Hazard stripes along the top and bottom of the prow.
	for band_y: int in [3, 169]:
		for x: int in range(18, 66):
			for y: int in range(band_y, band_y + 4):
				Kit.put(img, x, y, Color("#ffd23c") if ((x + y) / 3) % 2 == 0 else Color("#1a1a22"))
	# Gun-port column down the prow.
	Kit.rect(img, 5, 12, 8, 154, DARKER)
	for k: int in range(9):
		var py: int = 12 + 19 * k
		Kit.rect(img, 6, py, 6, 5, Color("#090c18"))
		Kit.put(img, 8, py + 2, Color("#6e2a10"))
		Kit.put(img, 9, py + 2, Color("#6e2a10"))
	# Sockets the core, canopy and turrets sit in.
	Kit.ellipse(img, 36.0, 96.0, 20.0, 20.0, DARKER)
	Kit.ellipse(img, 36.0, 96.0, 17.0, 17.0, Color("#0b1124"))
	Kit.ellipse(img, 30.0, 56.0, 21.0, 15.0, DARKER)
	Kit.ellipse(img, 14.0, 26.0, 13.0, 13.0, DARK)
	Kit.ellipse(img, 14.0, 146.0, 13.0, 13.0, DARK)
	# Rear windows.
	for wy: int in range(30, 150, 12):
		Kit.rect(img, 88, wy, 4, 2, Color("#9ad8ff"))
	return Kit.finish(img)


static func _paint_cracks() -> Image:
	var img: Image = Kit.blank(102, 178)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4401
	for start: Vector2 in [Vector2(60, 40), Vector2(80, 110), Vector2(30, 150), Vector2(50, 20)]:
		var p: Vector2 = start
		for s: int in range(7):
			var q: Vector2 = p + Vector2(rng.randf_range(-7.0, 7.0), rng.randf_range(-7.0, 7.0))
			Kit.line(img, p, q, Color("#0a0c16"))
			if s % 3 == 1:
				Kit.put(img, int(q.x), int(q.y), Color("#ff9624"))
			p = q
	return img


static func _paint_ports() -> Image:
	var img: Image = Kit.blank(10, 160)
	for k: int in range(9):
		Kit.glow(img, 5.0, 2.0 + 19.0 * float(k) + 2.0, 3.0, Color(1.0, 0.4, 0.1, 0.6), Color("#ff9624"), Color("#fff2a0"))
	return img


static func _paint_core() -> Image:
	var img: Image = Kit.blank(34, 34)
	Kit.glow(img, 17.0, 17.0, 16.0, Color("#0a78c0"), Color("#28e8ff"), Color.WHITE)
	for k: int in range(8):
		var a: float = TAU * float(k) / 8.0
		Kit.put(img, int(17.0 + cos(a) * 12.0), int(17.0 + sin(a) * 12.0), Color("#dcfaff"))
	return img


static func _paint_shutter(bottom: bool) -> Image:
	var img: Image = Kit.blank(32, 12)
	Kit.poly(img, PackedVector2Array([Vector2(0, 0), Vector2(32, 0), Vector2(28, 11), Vector2(4, 11)]), Color("#596e9c"))
	for x: int in range(5, 27):
		Kit.put(img, x, 9, Color("#ffd23c") if (x / 2) % 2 == 0 else Color("#1a1a22"))
	var out: Image = Kit.finish(img)
	return Kit.flip_v(out) if bottom else out


static func _paint_turret() -> Image:
	var img: Image = Kit.blank(22, 22)
	Kit.ball(img, 11.0, 11.0, 10.5, 10.5, Color("#596e9c"))
	Kit.ellipse(img, 11.0, 11.0, 5.0, 5.0, Color("#243254"))
	Kit.ellipse(img, 10.0, 10.0, 2.0, 2.0, Color("#c8dcff"))
	return Kit.outline(img)


static func _paint_barrel() -> Image:
	var img: Image = Kit.blank(30, 11)
	for by: int in [1, 6]:
		Kit.rect(img, 3, by, 25, 4, Color("#c8dcff"))
		Kit.rect(img, 3, by, 25, 1, Color.WHITE)
		Kit.rect(img, 3, by + 3, 25, 1, Color("#7f93bd"))
		Kit.rect(img, 0, by, 4, 4, Color("#ff9624"))
	Kit.rect(img, 22, 0, 8, 11, Color("#596e9c"))
	return Kit.outline(img)


static func _paint_charge() -> Image:
	var img: Image = Kit.blank(12, 12)
	Kit.glow(img, 6.0, 6.0, 6.0, Color(1.0, 0.45, 0.1, 0.7), Color("#ffe854"), Color.WHITE)
	return img


static func _paint_flash() -> Image:
	var img: Image = Kit.blank(14, 16)
	Kit.poly(img, PackedVector2Array([Vector2(13, 8), Vector2(0, 2), Vector2(5, 8), Vector2(0, 14)]), Color("#ff9624"))
	Kit.poly(img, PackedVector2Array([Vector2(13, 8), Vector2(4, 5), Vector2(7, 8), Vector2(4, 11)]), Color("#ffe854"))
	Kit.ellipse(img, 11.0, 8.0, 2.5, 2.5, Color.WHITE)
	return img


static func _paint_engine() -> Image:
	var img: Image = Kit.blank(14, 22)
	Kit.ellipse(img, 4.0, 11.0, 4.0, 10.0, Color(0.2, 0.6, 1.0, 0.55))
	Kit.ellipse(img, 4.0, 11.0, 2.5, 7.0, Color("#9ad8ff"))
	Kit.ellipse(img, 3.0, 11.0, 1.2, 4.0, Color.WHITE)
	return img


static func _paint_beacon() -> Image:
	var img: Image = Kit.blank(6, 6)
	Kit.glow(img, 3.0, 3.0, 3.0, Color(1.0, 0.3, 0.2, 0.6), Color("#ff9624"), Color.WHITE)
	return img


static func _paint_fire() -> Image:
	var img: Image = Kit.blank(10, 14)
	Kit.poly(img, PackedVector2Array([Vector2(5, 0), Vector2(10, 9), Vector2(7, 14), Vector2(3, 14), Vector2(0, 9)]), Color("#ff6820"))
	Kit.poly(img, PackedVector2Array([Vector2(5, 5), Vector2(7, 10), Vector2(5, 13), Vector2(3, 10)]), Color("#ffe854"))
	return img
