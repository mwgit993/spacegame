extends "res://scripts/stages/stage_boss.gd"

# GRAND CHAMPION AUREUS: the arena's reigning champion, a towering gladiator mech with a tower
# shield, a cyan-pronged trident and a hologram crest. Three patterns, switching every 4
# attacks; each phase adds shots and rate_mult shortens the cooldowns.
#   0 TRIDENT THRUST  the prongs flare (glow at the tips), then each prong fires at the ship:
#                     1 shot per prong, 2 in phase 2, 3 in phase 3 (plus a wide pair)
#   1 NET CAST        a ring of net knots is thrown at the ship (the net's mesh is drawn between
#                     them), it stops and hangs while the mesh tightens and brightens, then
#                     snaps: every knot flies outward. Phase 3 throws a second, smaller net.
#   2 SHIELD BASH     the shield blazes and a dotted column with gold brackets marks the next
#                     barrier and its gap; then a wall of bars sweeps out of the shield, its gap
#                     following the ship. Phase 2 adds trident shots; phase 3 ends the pattern
#                     with a charge: a red lane marks it, then the champion lunges forward and
#                     its shield bursts into a ring.

const PRONGS: Array[Vector2] = [Vector2(-53.0, -41.0), Vector2(-56.0, -33.0), Vector2(-53.0, -25.0)]
const SHIELD: Vector2 = Vector2(-37.0, 25.0)
const SHIELD_FACE_X: float = -56.0
const NET_FLY: float = 0.6
const NET_HANG: float = 0.55
const GAP: float = 50.0
const WALL_STEP: float = 12.0
const TELL: float = 0.45
const CHARGE_X: float = 300.0

var net: Array[GameBullet] = []
var net_dir: Vector2 = Vector2.LEFT
var net_hanging: bool = false
var next_gap: float = 140.0
var home_x: float = 404.0
var charging: bool = false


func setup() -> void:
	home_x = boss._target_x


func attack(rate_mult: float, spd_bonus: float) -> void:
	if charging:
		charging = false
		boss._target_x = home_x
	match pattern:
		0:
			_thrust(spd_bonus)
			wait(0.48 * rate_mult)
		1:
			match substep:
				0:
					_throw_net(spd_bonus, 12 + phase * 2, 16.0)
					wait(NET_FLY)
				1:
					_hang_net()
					wait(NET_HANG)
				2:
					_snap_net(spd_bonus)
					if phase >= 2:
						_thrust(spd_bonus)
					wait(0.6 * rate_mult)
				_:
					if phase >= 3:
						_throw_net(spd_bonus, 8, 10.0)
						wait(NET_FLY)
					else:
						_thrust(spd_bonus)
						wait(0.62 * rate_mult)
		_:
			if substep == 3 and phase >= 3:
				_charge(spd_bonus)
				wait(0.9 * rate_mult)
			else:
				_wall(spd_bonus)
				for p: int in range(3):
					shoot_aimed_from(pos() + PRONGS[p], 170.0 + spd_bonus, bullet_a(), 0.0)
					if phase >= 2:
						shoot_aimed_from(pos() + PRONGS[p], 160.0 + spd_bonus, bullet_a(), 0.12 * float(p - 1) + 0.06)
				wait(0.76 * rate_mult)
	# Pick the next barrier's gap now, so the telegraph can show it during the wait.
	next_gap = clampf(player_pos().y + randf_range(-26.0, 26.0), 62.0, 216.0)


func _upcoming_pattern() -> int:
	return pattern if substep < 3 else (pattern + 1) % 3


func _upcoming_substep() -> int:
	return substep + 1 if substep < 3 else 0


# Each prong fires at the ship; later phases fire tighter bursts and a wide pair.
func _thrust(spd_bonus: float) -> void:
	var per: int = mini(phase + 1, 3)
	for p: int in range(3):
		var origin: Vector2 = pos() + PRONGS[p]
		var base_off: float = float(p - 1) * 0.07
		for k: int in range(per):
			var off: float = base_off + (float(k) - float(per - 1) * 0.5) * 0.05
			shoot_aimed_from(origin, 172.0 + spd_bonus + float(k) * 8.0, bullet_b(), off)
	if phase >= 3:
		shoot_aimed_from(pos() + PRONGS[1], 150.0 + spd_bonus, bullet_a(), 0.42)
		shoot_aimed_from(pos() + PRONGS[1], 150.0 + spd_bonus, bullet_a(), -0.42)
	RetroSfx.play("laser", -11.0, 0.05)


func _throw_net(spd_bonus: float, n: int, radius: float) -> void:
	_clean_net()
	var origin: Vector2 = pos() + PRONGS[1] + Vector2(-radius - 4.0, 0.0)
	net_dir = (player_pos() - origin).normalized()
	var fly: float = 165.0 + spd_bonus * 0.5
	var rot: float = randf() * TAU
	for i: int in range(n):
		var a: float = rot + TAU * float(i) / float(n)
		var radial: Vector2 = Vector2.from_angle(a)
		var b: GameBullet = emit_bullet(origin + radial * radius, net_dir * fly + radial * 34.0, "arena_knot", 3.5)
		if b != null:
			net.append(b)
	net_hanging = false
	RetroSfx.play("missile", -12.0, 0.05)


func _net_center() -> Vector2:
	var c: Vector2 = Vector2.ZERO
	var n: int = 0
	for b: GameBullet in net:
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			c += b.global_position
			n += 1
	return c / float(n) if n > 0 else pos()


func _hang_net() -> void:
	_clean_net()
	var c: Vector2 = _net_center()
	for b: GameBullet in net:
		var radial: Vector2 = (b.global_position - c).normalized()
		b.velocity = net_dir * 10.0 + radial * 12.0
	net_hanging = true


func _snap_net(spd_bonus: float) -> void:
	_clean_net()
	var c: Vector2 = _net_center()
	for b: GameBullet in net:
		var radial: Vector2 = (b.global_position - c).normalized()
		b.velocity = radial * (118.0 + spd_bonus * 0.55)
	if not net.is_empty():
		RetroSfx.play("shield_hit", -10.0, 0.08)
	net.clear()
	net_hanging = false


func _clean_net() -> void:
	var keep: Array[GameBullet] = []
	for b: GameBullet in net:
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			keep.append(b)
	net = keep


# A barrier of bars from the shield with one gap (chosen during the previous wait).
func _wall(spd_bonus: float) -> void:
	var x: float = pos().x + SHIELD_FACE_X
	var spd: float = 104.0 + spd_bonus * 0.55
	var y: float = 34.0
	while y <= 250.0:
		if absf(y - next_gap) > GAP * 0.5:
			emit_bullet(Vector2(x, y), Vector2(-spd, 0.0), "arena_wall", 3.5)
		y += WALL_STEP
	RetroSfx.play("shield_hit", -9.0, 0.04)


# Phase 3: lunge forward along the marked lane and burst a ring out of the shield.
func _charge(spd_bonus: float) -> void:
	charging = true
	boss._target_x = CHARGE_X
	var n: int = 18
	var rot: float = randf() * TAU
	for i: int in range(n):
		var v: Vector2 = Vector2.from_angle(rot + TAU * float(i) / float(n)) * (130.0 + spd_bonus * 0.6)
		if v.x < 40.0:
			shoot_from(pos() + SHIELD, v, bullet_b())
	RetroSfx.play("explode", -9.0, 0.05)


func draw() -> void:
	var up_p: int = _upcoming_pattern()
	var up_s: int = _upcoming_substep()
	var tleft: float = boss._fire_timer
	# Net mesh: a ring between the knots and spokes to its centre, brightening while it hangs.
	_clean_net()
	if net.size() >= 3:
		var c: Vector2 = _net_center() - pos()
		var k: float = clampf(1.0 - tleft / NET_HANG, 0.0, 1.0) if net_hanging else 0.0
		var col: Color = Color(0.3, 0.92, 1.0, 0.22 + 0.4 * k)
		for i: int in range(net.size()):
			var a: Vector2 = net[i].global_position - pos()
			var b: Vector2 = net[(i + 1) % net.size()].global_position - pos()
			boss.draw_line(a, b, col, 1.0)
			if i % 2 == 0:
				boss.draw_line(a, c, Color(col.r, col.g, col.b, col.a * 0.6), 1.0)
		if net_hanging and k > 0.5:
			boss.draw_circle(c, 2.0 + 3.0 * k, Color(1.0, 1.0, 1.0, 0.25 * k))
	if tleft <= 0.0 or tleft >= TELL:
		return
	var u: float = 1.0 - tleft / TELL
	match up_p:
		0:
			# Prong flare.
			for p: int in range(3):
				var tip: Vector2 = PRONGS[p] + Vector2(-3.0, 0.0)
				boss.draw_circle(tip, 1.5 + 3.0 * u, Color(0.3, 0.95, 1.0, 0.45))
				boss.draw_circle(tip, 0.8 + 1.5 * u, Color(0.9, 1.0, 1.0, 0.9))
		1:
			if up_s == 0 or (up_s == 3 and phase >= 3):
				var tip2: Vector2 = PRONGS[1] + Vector2(-8.0, 0.0)
				boss.draw_arc(tip2, 4.0 + 10.0 * (1.0 - u), 0.0, TAU, 16, Color(0.3, 0.95, 1.0, 0.3 + 0.4 * u), 1.0)
		_:
			if up_s == 3 and phase >= 3:
				# The charge lane.
				var a2: float = 0.25 + 0.35 * u + 0.2 * sin(age * 40.0)
				var d: float = 0.0
				var reach: float = pos().x - CHARGE_X + 70.0
				while d < reach:
					boss.draw_line(Vector2(SHIELD_FACE_X - 6.0 - d, SHIELD.y - 30.0), Vector2(SHIELD_FACE_X - 12.0 - d, SHIELD.y - 30.0), Color(1.0, 0.25, 0.3, a2), 1.0)
					boss.draw_line(Vector2(SHIELD_FACE_X - 6.0 - d, SHIELD.y + 30.0), Vector2(SHIELD_FACE_X - 12.0 - d, SHIELD.y + 30.0), Color(1.0, 0.25, 0.3, a2), 1.0)
					d += 11.0
			else:
				# The next barrier: a dotted column with gold brackets around its gap.
				var x: float = SHIELD_FACE_X - 6.0
				var on: bool = fposmod(age * 12.0, 1.0) < 0.6
				var a3: float = (0.18 + 0.32 * u) * (1.0 if on else 0.5)
				var g: float = next_gap - pos().y
				var y: float = 34.0 - pos().y
				while y <= 250.0 - pos().y:
					if absf(y - g) > GAP * 0.5:
						boss.draw_rect(Rect2(x, floorf(y), 2.0, 2.0), Color(1.0, 0.3, 0.82, a3))
					y += 6.0
				var gc: Color = Color(1.0, 0.82, 0.3, 0.45 + 0.45 * u)
				for s: float in [-1.0, 1.0]:
					var ey: float = floorf(g + s * GAP * 0.5)
					boss.draw_rect(Rect2(x - 5.0, ey, 11.0, 1.0), gc)
					boss.draw_rect(Rect2(x - 5.0, ey - s * 2.0, 1.0, 2.0), gc)
				boss.draw_circle(SHIELD + Vector2(-20.0, 0.0), 2.0 + 3.0 * u, Color(1.0, 0.35, 0.85, 0.35))
