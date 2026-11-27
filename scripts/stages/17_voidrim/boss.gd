extends "res://scripts/stages/stage_boss.gd"

# EVENT HORIZON: THE DEVOURER. Three patterns, switching every 4 attacks:
#  0 SPIRAL ARMS     curved arms of shots that leave slowly and then speed up, turning a little
#                    further each volley, so the four volleys draw a spiral galaxy.
#  1 GRAVITY LENS    it marks an arc of points round where the ship is (pulsing markers: the
#                    telegraph), and on the next attack shots converge from them on that spot.
#  2 ACCRETION RAIN  shots flung high off the top of its ring arc over and rain down across
#                    the screen; in phase 3 a fast jet also streams from the eye.
# Phase 2+ adds arms, lens points and rain; rate_mult shortens the cooldowns.

const EYE: Vector2 = Vector2(-20.0, 0.0)
const LENS_R: float = 125.0

var _lens: PackedVector2Array = PackedVector2Array()
var _lens_center: Vector2 = Vector2.ZERO


func attack(rate_mult: float, spd_bonus: float) -> void:
	if pattern != 1:
		_lens.clear()
	match pattern:
		0:
			var arms: int = 2 + (1 if phase >= 2 else 0)
			for arm: int in range(arms):
				var base: float = spin + TAU * float(arm) / float(arms)
				for k: int in range(3 + phase):
					var a: float = base + float(k) * 0.16
					var b: GameBullet = emit_bullet(pos() + Vector2.from_angle(a) * 26.0, Vector2.from_angle(a) * (150.0 + spd_bonus + 10.0 * float(k)), bullet_b())
					if b != null:
						b.slow_timer = 0.55
						b.slow_factor = 0.22
			spin += 0.42
			RetroSfx.play("zap", -13.0, 0.08)
			wait(0.85 * rate_mult)
		1:
			if _lens.is_empty():
				# mark an arc of points round the ship (the ones off the playfield are dropped)
				_lens_center = player_pos()
				var n: int = 7 + phase * 2
				for i: int in range(n):
					var a2: float = lerpf(-1.75, 1.75, float(i) / float(n - 1))
					var p: Vector2 = _lens_center + Vector2.from_angle(a2) * LENS_R
					if p.x > 20.0 and p.x < 470.0 and p.y > 34.0 and p.y < 248.0:
						_lens.append(p)
				shoot_aimed_from(pos() + EYE, 160.0 + spd_bonus, bullet_a())
				RetroSfx.play("boss_hp_tick", -10.0, 0.0)
				wait(0.85 * rate_mult)
			else:
				for p2: Vector2 in _lens:
					emit_bullet(p2, (_lens_center - p2).normalized() * (118.0 + spd_bonus * 0.5), bullet_b())
				_lens.clear()
				shoot_ring(10 + phase * 2, 120.0 + spd_bonus, bullet_a(), spin)
				spin += 0.3
				RetroSfx.play("laser", -10.0, 0.05)
				wait(0.9 * rate_mult)
		_:
			var drops: int = 4 + phase * 2
			for d: int in range(drops):
				var v: Vector2 = Vector2(-(40.0 + 34.0 * float(d) + randf_range(-8.0, 8.0)), -(150.0 + randf_range(0.0, 40.0)))
				var b2: GameBullet = emit_bullet(pos() + Vector2(-8.0, -42.0), v, bullet_b())
				if b2 != null:
					b2.gravity_pull = 140.0
			if phase >= 3:
				for k2: int in range(5):
					var b3: GameBullet = emit_bullet(pos() + EYE, Vector2.from_angle((player_pos() - pos() - EYE).angle()) * (230.0 + spd_bonus), bullet_a())
					if b3 != null:
						b3.slow_timer = 0.06 * float(k2)
						b3.slow_factor = 0.0
			elif substep % 2 == 1:
				shoot_spread_from(pos() + EYE, 5, 0.16, 160.0 + spd_bonus, bullet_a())
			wait(1.0 * rate_mult)


func draw() -> void:
	# lens markers: pulsing crosshairs where shots will converge from
	if not _lens.is_empty():
		var t: float = 0.5 + 0.5 * sin(age * 16.0)
		for p: Vector2 in _lens:
			var l: Vector2 = p - pos()
			boss.draw_arc(l, 4.0 + 2.0 * t, 0.0, TAU, 10, Color(0.8, 0.5, 1.0, 0.45 + 0.3 * t), 1.0)
			boss.draw_line(l + Vector2(-2.0, 0.0), l + Vector2(2.0, 0.0), Color(1.0, 0.85, 1.0, 0.7), 1.0)
		boss.draw_arc(_lens_center - pos(), 6.0, 0.0, TAU, 12, Color(1.0, 0.4, 0.5, 0.25 + 0.2 * t), 1.0)
	var k: float = 0.5 + 0.5 * sin(age * 2.0)
	boss.draw_arc(Vector2.ZERO, 62.0 + 3.0 * k, 0.0, TAU, 40, Color(1.0, 0.6, 0.25, 0.06 + 0.06 * k), 2.0)
