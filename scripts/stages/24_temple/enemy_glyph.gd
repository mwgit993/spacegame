extends "res://scripts/stages/stage_enemy.gd"

# Glyph sentinel: rune stones that arrive as a group (one wave-director squad) and take up the
# slots of a sigil round a shared centre: a triangle, a diamond or a five-stone ring (the spawn's
# "variant"; its "phase" is the stone's slot). The sigil turns slowly. Once every stone is in
# place it charges for CHARGE seconds: the links between neighbouring stones brighten and their
# glyphs burn, and for the last AIM_SHOW seconds dotted marks show where it will be thrown.
# Then the sigil's whole outline (its stones plus shots along each link) is hurled at
# the ship as one rigid shape, each stone snapping a fast aimed shot after it. Killing a stone breaks its two links, so a damaged sigil throws
# a broken outline; a lone stone just fires a small aimed fan. After VOLLEYS throws the stones
# scatter. One stone of each group (the first one alive) drives the shared state.

enum G { FORM, CHARGE, REST, SCATTER }

const CENTER_X: float = 344.0
const CHARGE: float = 1.15
const AIM_SHOW: float = 0.4
const REST: float = 1.0
const VOLLEYS: int = 2
const EDGE_PTS: Array[int] = [4, 4, 3]  # per shape: shots per link (one sits on the stone)
const THROW_SPEED: float = 92.0
const SNAP_SPEED: float = 150.0
const SIZES: Array[int] = [3, 4, 5]
const RADII: Array[float] = [27.0, 29.0, 31.0]

# group key -> shared state (members, shape, centre, turn, timers)
static var _groups: Dictionary = {}

var key: int = 0
var slot: int = 0
var g: Dictionary = {}
var settled: bool = false


static func shape_size(shape: int) -> int:
	return SIZES[clampi(shape, 0, SIZES.size() - 1)]


static func _alive(e: Variant) -> bool:
	return e != null and is_instance_valid(e) and not (e as GameEnemy)._dead


func setup() -> void:
	# forget groups whose stones are all gone
	for k: Variant in _groups.keys():
		var any: bool = false
		for m: Variant in (_groups[k] as Dictionary)["members"]:
			if _alive(m):
				any = true
				break
		if not any:
			_groups.erase(k)
	key = enemy.squad_id if enemy.squad_id >= 0 else -enemy.get_instance_id()
	var shape: int = clampi(variant, 0, SIZES.size() - 1)
	slot = int(phase) % SIZES[shape]
	if not _groups.has(key):
		_groups[key] = {
			"members": [], "shape": shape, "center": Vector2(CENTER_X, base_y), "base_y": base_y,
			"turn": 0.0, "t": 0.0, "state": G.FORM, "timer": 0.0, "volleys": 0, "aim": Vector2.LEFT,
		}
	g = _groups[key]
	(g["members"] as Array).append(enemy)
	set_texture("temple_glyph_%d" % (slot % 3))
	fire_timer = 99.0


func _driver() -> GameEnemy:
	for m: Variant in g["members"]:
		if _alive(m):
			return m as GameEnemy
	return null


func _slot_pos(s: int) -> Vector2:
	var shape: int = int(g["shape"])
	var n: int = SIZES[shape]
	var a: float = PI + float(g["turn"]) + TAU * float(s) / float(n)
	var off: Vector2 = Vector2.from_angle(a) * RADII[shape]
	if shape == 1:
		off.y *= 0.9
	return Vector2(g["center"]) + off


# Living stones by slot.
func _stones() -> Dictionary:
	var out: Dictionary = {}
	for m: Variant in g["members"]:
		if _alive(m):
			var b: RefCounted = (m as GameEnemy)._behaviour
			out[int(b.get("slot"))] = m
	return out


func tick(delta: float) -> void:
	if _driver() == enemy:
		_drive(delta)
	var p: Vector2 = enemy.global_position
	var st: int = int(g["state"])
	if st == G.SCATTER:
		p += Vector2(-70.0, (p.y - Vector2(g["center"]).y) * 1.6 - 10.0) * delta
	else:
		var want: Vector2 = _slot_pos(slot)
		if settled:
			p = p.lerp(want, clampf(10.0 * delta, 0.0, 1.0))
		else:
			p = p.move_toward(want, 230.0 * delta)
			if p.distance_to(want) < 3.0:
				settled = true
	enemy.global_position = p
	var lit: bool = st == G.CHARGE
	set_texture(("temple_glyph_lit_%d" if lit else "temple_glyph_%d") % (slot % 3))
	sprite().position.y = sin(age * 3.0 + float(slot)) * 1.0


func _drive(delta: float) -> void:
	g["t"] = float(g["t"]) + delta
	var t: float = float(g["t"])
	var c: Vector2 = g["center"]
	c.y = float(g["base_y"]) + sin(t * 0.8) * 10.0
	c.x -= 5.0 * delta
	g["center"] = c
	g["turn"] = float(g["turn"]) + 0.32 * delta
	g["timer"] = float(g["timer"]) - delta
	match int(g["state"]):
		G.FORM:
			var ready: bool = true
			for m: Variant in g["members"]:
				if _alive(m) and not bool((m as GameEnemy)._behaviour.get("settled")):
					ready = false
			if (ready and t > 0.6) or t > 3.2:
				_begin_charge()
		G.CHARGE:
			if float(g["timer"]) <= AIM_SHOW and float(g["timer"]) + delta > AIM_SHOW:
				g["aim"] = (player_pos() - c).normalized()
			if float(g["timer"]) <= 0.0:
				_throw()
				g["volleys"] = int(g["volleys"]) + 1
				if int(g["volleys"]) >= VOLLEYS:
					g["state"] = G.SCATTER
				else:
					g["state"] = G.REST
					g["timer"] = fire_cd(REST)
		G.REST:
			if float(g["timer"]) <= 0.0:
				_begin_charge()
		G.SCATTER:
			pass


func _begin_charge() -> void:
	g["state"] = G.CHARGE
	g["timer"] = CHARGE
	g["aim"] = (player_pos() - Vector2(g["center"])).normalized()
	sfx("boss_hp_tick", -16.0, 0.1)


# The sigil's outline: every living stone plus the points along every unbroken link.
func _outline() -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	var stones: Dictionary = _stones()
	var n: int = SIZES[int(g["shape"])]
	for s: Variant in stones.keys():
		var a: Vector2 = (stones[s] as GameEnemy).global_position
		pts.append(a)
		var nxt: int = (int(s) + 1) % n
		if n > 2 and stones.has(nxt):
			var b: Vector2 = (stones[nxt] as GameEnemy).global_position
			var ep: int = EDGE_PTS[int(g["shape"])]
			for j: int in range(1, ep):
				pts.append(a.lerp(b, float(j) / float(ep)))
	return pts


func _throw() -> void:
	var stones: Dictionary = _stones()
	var c: Vector2 = g["center"]
	if stones.size() <= 1:
		# a lone stone: a small aimed fan
		for k: int in range(-1, 2):
			shoot_aimed_from(enemy.global_position + Vector2(-6.0, 0.0), 120.0, bullet_a(), float(k) * 0.2)
		return
	var v: Vector2 = Vector2(g["aim"]) * THROW_SPEED
	for p: Vector2 in _outline():
		emit_bullet(p, v, bullet_b())
	# and every stone snaps a fast aimed shot as the sigil leaves
	for st: Variant in stones.values():
		shoot_aimed_from((st as GameEnemy).global_position + Vector2(-6.0, 0.0), SNAP_SPEED, bullet_a())
	sparks(c, Color("#3cc890"), 6)
	sfx("zap", -12.0, 0.05)


func draw() -> void:
	if g.is_empty():
		return
	var st: int = int(g["state"])
	var me: Vector2 = enemy.global_position
	if st == G.CHARGE:
		var k: float = 1.0 - clampf(float(g["timer"]) / CHARGE, 0.0, 1.0)
		var n: int = SIZES[int(g["shape"])]
		var stones: Dictionary = _stones()
		var nxt: int = (slot + 1) % n
		if n > 2 and stones.has(nxt):
			var b: Vector2 = (stones[nxt] as GameEnemy).global_position - me
			var flick: float = 0.0 if k < 0.75 else 0.2 * float(int(age * 24.0) % 2)
			enemy.draw_line(Vector2.ZERO, b, Color(0.3, 1.0, 0.65, 0.12 + 0.45 * k + flick), 1.0)
		enemy.draw_circle(Vector2.ZERO, 3.0 + 4.0 * k, Color(0.3, 1.0, 0.6, 0.08 + 0.14 * k))
		# the throw marks (only the first stone alive draws them)
		if float(g["timer"]) <= AIM_SHOW and _driver() == enemy:
			var c: Vector2 = Vector2(g["center"]) - me
			var d: Vector2 = Vector2(g["aim"])
			var blink: float = 0.25 + 0.25 * float(int(age * 16.0) % 2)
			for i: int in range(1, 7):
				var q: Vector2 = c + d * (24.0 + 16.0 * float(i))
				enemy.draw_rect(Rect2(q - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(0.4, 1.0, 0.7, blink))
	draw_hp_bar(12.0, -11.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#3cc890"), 7)
	sparks(enemy.global_position, Color("#5a6a5e"), 5)
