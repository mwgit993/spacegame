extends "res://scripts/stages/stage_boss.gd"

# BASTION MAIN BATTERY. Three patterns, switching every 4 attacks:
#  0 RAILGUN       the rail cannon locks on: a red charging line runs from the muzzle across
#                  the screen (thickening, flashing white just before it fires), then a solid
#                  lance of rail bolts tears down it with a spray off each side. Phase 2 locks
#                  two lines and the flak turret fires an aimed pair during the charge; phase
#                  3 locks three.
#  1 FLAK BARRAGE  the flak turret lobs shells at reticles on and around the ship (2, 3, then
#                  4 of them); each bursts into a flower of rounds on arrival (a second ring
#                  from phase 2), and the rail muzzle fans shots in between volleys.
#  2 SALVO / ARC   the missile block fires warheads that home in for a moment, then fly
#                  straight; between salvos the gatling sweeps an arc of rounds with one safe
#                  lane (shown beforehand as a dotted arc with a gap), two arcs from phase 2.
#                  In phase 3 the salvo also launches turret pods onto the hull (children,
#                  capped).
# rate_mult shortens the cooldowns in later phases; spd_bonus is scaled down for the dense
# patterns.

const Pod = preload("enemy_pod.gd")

const RAIL: Vector2 = Vector2(-63.0, 2.0)
const FLAK: Vector2 = Vector2(-32.0, -67.0)
const GATLING: Vector2 = Vector2(-53.0, 26.0)
const TUBES: Array[Vector2] = [Vector2(-11.0, 57.0), Vector2(4.0, 69.0), Vector2(19.0, 57.0), Vector2(-11.0, 69.0), Vector2(4.0, 57.0), Vector2(19.0, 69.0)]
const FLAK_TIME: float = 1.05
const ARC_HALF: float = 0.78
const ARC_SHOTS: int = 21

var _rail_dirs: PackedFloat32Array = PackedFloat32Array()
var _charge_total: float = 1.0
var _charging: bool = false
var _shells: Array = []
var _reticles: PackedVector2Array = PackedVector2Array()
var _arc_gap: float = PI
var _arc_ready: bool = false
var _side: float = 1.0


func attack(rate_mult: float, spd_bonus: float) -> void:
	_burst_shells(spd_bonus)
	if _charging:
		_fire_rail(spd_bonus)
		_charging = false
		wait(0.6 * rate_mult)
		return
	match pattern:
		0:
			_start_rail(spd_bonus)
		1:
			_flak(rate_mult, spd_bonus)
		_:
			_salvo_or_arc(rate_mult, spd_bonus)


func _start_rail(spd_bonus: float) -> void:
	var m: Vector2 = pos() + RAIL
	var a0: float = PI + clampf(angle_difference(PI, (player_pos() - m).angle()), -0.62, 0.62)
	_side = -_side
	_rail_dirs = PackedFloat32Array([a0])
	if phase >= 2:
		_rail_dirs.append(a0 + 0.24 * _side)
	if phase >= 3:
		_rail_dirs.append(a0 - 0.24 * _side)
	_charge_total = 1.0 - 0.1 * float(phase - 1)
	_charging = true
	if phase >= 2:
		for k: int in [-1, 1]:
			shoot_aimed_from(pos() + FLAK, 150.0 + spd_bonus * 0.5, bullet_a(), float(k) * 0.14)
	RetroSfx.play("boss_beam", -12.0, 0.02)
	wait(_charge_total)


func _fire_rail(spd_bonus: float) -> void:
	var m: Vector2 = pos() + RAIL
	for a: float in _rail_dirs:
		var d: Vector2 = Vector2.from_angle(a)
		for k: int in range(8):
			var b: GameBullet = emit_bullet(m + d * (float(k) * 9.0), d * (300.0 + spd_bonus * 0.6), "orbital_rail", 3.0)
			if b != null:
				b.rotation = a
		for s: float in [-1.0, 1.0]:
			for j: int in range(3):
				emit_bullet(m, Vector2.from_angle(a + s * (0.3 + 0.15 * float(j))) * (140.0 + spd_bonus * 0.4), bullet_b())
	RetroSfx.play("laser", -6.0, 0.02)
	if boss.fx != null:
		boss.fx.add_shake(2.5)
		boss.fx.spawn_hit_sparks(m, Color("#9ae8ff"), 10)


func _flak(rate_mult: float, spd_bonus: float) -> void:
	if substep % 2 == 0:
		var n: int = 1 + phase
		var pp: Vector2 = player_pos()
		_shells.clear()
		_reticles.clear()
		for i: int in range(n):
			var tgt: Vector2 = pp
			if i > 0:
				var ang: float = TAU * float(i) / float(n - 1) + randf() * 0.8
				tgt = pp + Vector2.from_angle(ang) * randf_range(46.0, 70.0)
			tgt.x = clampf(tgt.x, 26.0, 360.0)
			tgt.y = clampf(tgt.y, 40.0, 238.0)
			var from: Vector2 = pos() + FLAK
			var b: GameBullet = emit_bullet(from, (tgt - from) / FLAK_TIME, "orbital_flak", 3.5)
			if b != null:
				b.life_left = FLAK_TIME + 0.6
				_shells.append(b)
			_reticles.append(tgt)
		RetroSfx.play("missile", -9.0, 0.05)
		wait(FLAK_TIME)
	else:
		shoot_spread_from(pos() + RAIL, 3 + phase, 0.16, 160.0 + spd_bonus * 0.5, bullet_a())
		wait(0.85 * rate_mult)


func _burst_shells(spd_bonus: float) -> void:
	if _shells.is_empty():
		return
	var ring: int = 10
	for v: Variant in _shells:
		if not is_instance_valid(v):
			continue
		var sh: GameBullet = v as GameBullet
		var at: Vector2 = sh.global_position
		var rot: float = randf() * TAU
		for i: int in range(ring):
			emit_bullet(at, Vector2.from_angle(rot + TAU * float(i) / float(ring)) * (72.0 + spd_bonus * 0.3), bullet_b())
		if phase >= 2:
			for j: int in range(4):
				emit_bullet(at, Vector2.from_angle(rot + TAU * (float(j) + 0.5) / 4.0) * 60.0, bullet_a())
		sh.queue_free()
		if boss.fx != null:
			boss.fx.spawn_hit_sparks(at, Color("#ffd060"), 6)
	_shells.clear()
	_reticles.clear()
	RetroSfx.play("explode", -11.0, 0.08)


func _salvo_or_arc(rate_mult: float, spd_bonus: float) -> void:
	if substep % 2 == 0:
		var m: int = 2 + phase
		for k: int in range(m):
			var tube: Vector2 = TUBES[k % TUBES.size()]
			var up: float = -1.0 if k % 2 == 0 else 1.0
			var v: Vector2 = Vector2(-70.0 - 22.0 * float(k / 2), 115.0 * up).rotated(randf_range(-0.2, 0.2))
			var b: GameBullet = emit_bullet(pos() + tube, v, "orbital_missile", 3.5)
			if b != null:
				b.home_target = boss.player_ref
				b.home_time = 1.15
				b.home_rate = 2.3
				b.life_left = 5.0
		if phase >= 3 and substep == 0 and Pod.count(boss) < Pod.CAP - 1:
			for k2: int in range(2):
				boss._request_child(GameEnemy.Type.MODULE, pos() + Vector2(-6.0 + 14.0 * float(k2), 62.0), Vector2(-90.0, 40.0), 1, "pod")
		RetroSfx.play("missile", -8.0, 0.08)
		# pick the next arc's safe lane now, so it can be shown during the wait
		var g: Vector2 = pos() + GATLING
		_arc_gap = PI + clampf(angle_difference(PI, (player_pos() - g).angle()) + randf_range(-0.3, 0.3), -ARC_HALF + 0.15, ARC_HALF - 0.15)
		_arc_ready = true
		wait(0.95 * rate_mult)
	else:
		var g2: Vector2 = pos() + GATLING
		var rows: int = 1 if phase < 2 else 2
		for r: int in range(rows):
			var gap: float = _arc_gap + (0.0 if r == 0 else 0.3 * _side)
			for i: int in range(ARC_SHOTS):
				var a: float = PI - ARC_HALF + 2.0 * ARC_HALF * float(i) / float(ARC_SHOTS - 1)
				if absf(angle_difference(a, gap)) < 0.11:
					continue
				emit_bullet(g2, Vector2.from_angle(a) * (135.0 + spd_bonus * 0.4 - 32.0 * float(r)), bullet_a() if r == 0 else bullet_b())
		_arc_ready = false
		RetroSfx.play("laser", -11.0, 0.08)
		wait(0.8 * rate_mult)


func draw() -> void:
	var k: float = 0.5 + 0.5 * sin(age * 5.0)
	boss.draw_circle(RAIL + Vector2(-4.0, 0.0), 2.0 + 2.0 * k, Color(0.4, 0.85, 1.0, 0.18 + 0.15 * k))
	if _charging:
		var t: float = 1.0 - clampf(boss._fire_timer / maxf(0.01, _charge_total), 0.0, 1.0)
		var hot: bool = boss._fire_timer < 0.22
		for a: float in _rail_dirs:
			var d: Vector2 = Vector2.from_angle(a)
			var col: Color = Color(1.0, 0.95, 0.85, 0.8) if hot and int(age * 24.0) % 2 == 0 else Color(1.0, 0.3, 0.25, 0.2 + 0.45 * t)
			boss.draw_line(RAIL + d * 6.0, RAIL + d * 540.0, col, 1.0 + 2.0 * t)
			boss.draw_circle(RAIL + d * 3.0, 2.0 + 5.0 * t, Color(0.6, 0.95, 1.0, 0.3 + 0.4 * t))
	if not _reticles.is_empty():
		var kk: float = clampf(boss._fire_timer / FLAK_TIME, 0.0, 1.0)
		var me: Vector2 = boss.global_position
		for tg: Vector2 in _reticles:
			var lt: Vector2 = tg - me
			var r: float = 5.0 + 12.0 * kk
			var blink: bool = kk < 0.25 and int(age * 20.0) % 2 == 0
			var col2: Color = Color(1.0, 0.25, 0.2, 0.85) if blink else Color(1.0, 0.65, 0.2, 0.3 + 0.45 * (1.0 - kk))
			boss.draw_arc(lt, r, 0.0, TAU, 20, col2, 1.0)
			for q: int in range(4):
				var qd: Vector2 = Vector2.from_angle(float(q) * PI * 0.5 + PI * 0.25)
				boss.draw_line(lt + qd * (r + 1.0), lt + qd * (r + 5.0), col2, 1.0)
	if _arc_ready and pattern == 2:
		# the coming arc, with its safe lane
		var near: float = clampf(1.0 - boss._fire_timer / 0.6, 0.0, 1.0)
		for i: int in range(ARC_SHOTS):
			var a2: float = PI - ARC_HALF + 2.0 * ARC_HALF * float(i) / float(ARC_SHOTS - 1)
			if absf(angle_difference(a2, _arc_gap)) < 0.11:
				continue
			boss.draw_rect(Rect2(GATLING + Vector2.from_angle(a2) * 30.0 - Vector2(0.5, 0.5), Vector2(1.5, 1.5)), Color(1.0, 0.7, 0.3, 0.2 + 0.5 * near))
		var gd: Vector2 = Vector2.from_angle(_arc_gap)
		boss.draw_line(GATLING + gd * 22.0, GATLING + gd * 44.0, Color(0.6, 1.0, 0.7, 0.25 + 0.4 * near), 1.0)
