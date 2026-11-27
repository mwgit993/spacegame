extends "res://scripts/stages/stage_boss.gd"

# DARK VIPER "REFLECTION": a giant negative of your own ship that turns your weapons back on you
# and aims at your reflection as well as at you. Three patterns, switching every 4 attacks; each
# phase adds shots and rate_mult shortens cooldowns.
#   0 VULCAN MIRROR  the wing guns fire speed-staggered streams (a vulcan burst): one at you, the
#                    other at your reflection across the centre line, so the streams close in as
#                    you near the line. Aim lines and glowing muzzles telegraph each burst.
#                    Phase 2+: the nose cannon adds a fan; phase 3: longer streams.
#   1 MIRROR LASER   flickering guide lines lock onto you and your reflection (phase 2 adds a
#                    pair either side, phase 3 the centre line), then each becomes a laser of
#                    silver slivers.
#   2 REFLECTION     the wing guns spin mirrored spirals (the lower one the reflection of the
#                    upper one). Phase 2+: the guns also fire lances that converge on the centre
#                    line; when they reach it the mirror plane flashes and duplicates every
#                    lance as its reflection, so each one splits into an X.
# GameEnemy moves the boss body itself (a stage module can't), so the reflection lives in the aim.

const AXIS: float = 139.5
const NOSE: Vector2 = Vector2(-62.0, -1.0)
const GUN_T: Vector2 = Vector2(-14.0, -30.0)
const GUN_B: Vector2 = Vector2(-14.0, 29.0)
const LASER_TELL: float = 0.72
const LANCE_SPEED: float = 185.0
const LANCE_ANGLES: Array[float] = [0.42, 0.7, 1.0]

var laser_dirs: PackedFloat32Array = PackedFloat32Array()
var laser_pending: bool = false
var lances: Array[GameBullet] = []
var lance_time: float = 0.6


func _reflect(p: Vector2) -> Vector2:
	return Vector2(p.x, 2.0 * AXIS - p.y)


func attack(rate_mult: float, spd_bonus: float) -> void:
	if pattern != 1:
		laser_pending = false
	if pattern != 2 and not lances.is_empty():
		_mirror_lances()
	match pattern:
		0:
			_vulcan(spd_bonus)
			wait(0.46 * rate_mult)
		1:
			if not laser_pending:
				_lock_lasers()
				wait(LASER_TELL)
			else:
				_fire_lasers(spd_bonus)
				wait(0.36 * rate_mult)
		_:
			_reflection(spd_bonus)
			if phase >= 2 and lances.is_empty() and substep % 2 == 0:
				if _fire_lances(spd_bonus):
					wait(lance_time)
					return
			if not lances.is_empty():
				_mirror_lances()
			wait(0.44 * rate_mult)


# --- 0: vulcan streams at you and your reflection ---------------------------------------------

func _vulcan(spd_bonus: float) -> void:
	var pp: Vector2 = player_pos()
	var rp: Vector2 = _reflect(pp)
	var upper: Vector2 = pp if pp.y <= rp.y else rp
	var lower: Vector2 = rp if pp.y <= rp.y else pp
	var n: int = 3 + (1 if phase >= 3 else 0)
	for g: int in range(2):
		var origin: Vector2 = pos() + (GUN_T if g == 0 else GUN_B)
		var dir: Vector2 = ((upper if g == 0 else lower) - origin).normalized()
		for i: int in range(n):
			var b: GameBullet = emit_bullet(origin, dir * (118.0 + spd_bonus + 16.0 * float(i)), "mirror_sliver")
			if b != null:
				b.rotation = dir.angle()
	if phase >= 2:
		shoot_spread_from(pos() + NOSE, 3, 0.2, 128.0 + spd_bonus, bullet_b())
	RetroSfx.play("laser", -12.0, 0.06)


# --- 1: mirror lasers -------------------------------------------------------------------------

func _lock_lasers() -> void:
	laser_dirs.clear()
	var o: Vector2 = pos() + NOSE
	var a0: float = (player_pos() - o).angle()
	var a1: float = (_reflect(player_pos()) - o).angle()
	laser_dirs.append(a0)
	if absf(angle_difference(a0, a1)) > 0.06:
		laser_dirs.append(a1)
	if phase >= 2:
		laser_dirs.append(a0 + 0.3)
		laser_dirs.append(a0 - 0.3)
	if phase >= 3:
		laser_dirs.append((Vector2(pos().x - 300.0, AXIS) - o).angle())
	laser_pending = true
	RetroSfx.play("boss_hp_tick", -10.0, 0.0)


func _fire_lasers(spd_bonus: float) -> void:
	var o: Vector2 = pos() + NOSE
	var count: int = 7 + phase
	for a: float in laser_dirs:
		var d: Vector2 = Vector2.from_angle(a)
		for i: int in range(count):
			var b: GameBullet = emit_bullet(o, d * (150.0 + spd_bonus * 0.5 + 22.0 * float(i)), "mirror_sliver")
			if b != null:
				b.rotation = a
	laser_pending = false
	RetroSfx.play("boss_beam", -12.0, 0.04)


# --- 2: reflection --------------------------------------------------------------------------

func _reflection(spd_bonus: float) -> void:
	var arms: int = 3 + phase
	for k: int in range(arms):
		var a: float = spin + TAU * float(k) / float(arms)
		var v: Vector2 = Vector2.from_angle(a) * (112.0 + spd_bonus * 0.6)
		if v.x > 20.0:
			continue
		shoot_from(pos() + GUN_T, v, bullet_b())
		shoot_from(pos() + GUN_B, Vector2(v.x, -v.y), bullet_b())
	spin += 0.29


# Lances from both guns aimed at the centre line, timed to reach it together after lance_time
# (long enough that the fastest lance stays under LANCE_SPEED).
func _fire_lances(_spd_bonus: float) -> bool:
	var fired: bool = false
	var per_gun: int = 2 if phase < 3 else 3
	var far_dy: float = maxf(absf(AXIS - (pos() + GUN_T).y), absf(AXIS - (pos() + GUN_B).y))
	lance_time = clampf(far_dy / sin(LANCE_ANGLES[0]) / LANCE_SPEED, 0.45, 1.0)
	for g: int in range(2):
		var origin: Vector2 = pos() + (GUN_T if g == 0 else GUN_B)
		var dy: float = AXIS - origin.y
		if absf(dy) < 16.0:
			continue
		for i: int in range(per_gun):
			var ang: float = LANCE_ANGLES[i]
			var dist: float = absf(dy) / sin(ang)
			var speed: float = dist / lance_time
			var v: Vector2 = Vector2(-cos(ang), signf(dy) * sin(ang)) * speed
			var b: GameBullet = emit_bullet(origin, v, "mirror_sliver")
			if b != null:
				b.rotation = v.angle()
				lances.append(b)
				fired = true
	if fired:
		RetroSfx.play("missile", -12.0, 0.05)
	return fired


# The lances have reached the mirror plane: each gets a reflected twin.
func _mirror_lances() -> void:
	for b: GameBullet in lances:
		if not is_instance_valid(b) or b.is_queued_for_deletion():
			continue
		var p: Vector2 = b.global_position
		var v: Vector2 = Vector2(b.velocity.x, -b.velocity.y)
		var tw: GameBullet = emit_bullet(_reflect(p), v, "mirror_sliver")
		if tw != null:
			tw.rotation = v.angle()
		if boss.fx != null:
			boss.fx.spawn_hit_sparks(p, Color("#e8f6ff"), 2)
	lances.clear()
	RetroSfx.play("shield_hit", -14.0, 0.1)


# --- Telegraphs (boss-local space, drawn behind the sprite) -----------------------------------

func draw() -> void:
	var t: float = boss._fire_timer
	var plane_y: float = AXIS - pos().y
	# The mirror plane while lances are in flight: it brightens as they arrive.
	if not lances.is_empty():
		var k: float = clampf(1.0 - t / lance_time, 0.0, 1.0)
		boss.draw_line(Vector2(-pos().x, plane_y), Vector2(480.0 - pos().x, plane_y), Color(0.85, 0.97, 1.0, 0.08 + 0.22 * k), 1.0)
		for b: GameBullet in lances:
			if is_instance_valid(b) and not b.is_queued_for_deletion():
				var hit_x: float = b.global_position.x + b.velocity.x * maxf(0.0, t) - pos().x
				var r: float = 2.0 + 4.0 * (1.0 - k)
				boss.draw_rect(Rect2(hit_x - r, plane_y - 0.5, r * 2.0, 1.0), Color(1.0, 0.5, 0.9, 0.5))
	match pattern:
		0:
			if t > 0.0 and t < 0.32:
				var u: float = 1.0 - t / 0.32
				var pp: Vector2 = player_pos()
				var rp: Vector2 = _reflect(pp)
				for g: int in range(2):
					var gl: Vector2 = GUN_T if g == 0 else GUN_B
					var target: Vector2 = (pp if (pp.y <= rp.y) == (g == 0) else rp) - pos()
					boss.draw_circle(gl + Vector2(-2.0, 0.0), 1.5 + 3.0 * u, Color(1.0, 0.55, 0.92, 0.6))
					var d: Vector2 = (target - gl).normalized()
					var dist: float = 14.0
					while dist < 170.0:
						var q: Vector2 = gl + d * dist
						boss.draw_rect(Rect2(q.floor(), Vector2.ONE), Color(1.0, 0.6, 0.95, 0.15 + 0.25 * u))
						dist += 6.0
		1:
			if laser_pending:
				var u2: float = clampf(1.0 - t / LASER_TELL, 0.0, 1.0)
				var flick: float = 0.5 + 0.5 * sin(age * (26.0 + 40.0 * u2))
				for a: float in laser_dirs:
					var d2: Vector2 = Vector2.from_angle(a)
					boss.draw_line(NOSE, NOSE + d2 * 520.0, Color(0.6, 0.95, 1.0, (0.1 + 0.3 * u2) * (0.6 + 0.4 * flick)), 1.0)
				boss.draw_circle(NOSE, 2.0 + 4.0 * u2, Color(0.75, 0.98, 1.0, 0.65))


func setup() -> void:
	laser_dirs.clear()
	lances.clear()
