extends "res://scripts/stages/stage_boss.gd"

# SUNFORGE CITADEL: a solar-collector fortress. Three patterns, switching every 4 attacks; each
# phase adds shots and rate_mult shortens the cooldowns.
#   0 FOCUSED BEAM  rays of sunlight converge on the mirror petals and a dashed aim line locks
#                   onto the player for BEAM_WARN s; then the lens fires a dense fast stream along
#                   exactly that line (phase 2+: two flanking streams)
#   1 SOLAR WIND    slow rings of plasma with a 3-shot gap that sweeps up and down the left side
#                   (phase 3 adds an aimed pair)
#   2 FLARE SPIRAL  the top and bottom petals throw curved arms that rotate in opposite directions
#                   (phase 2+: a third arm each)

const LENS: Vector2 = Vector2(-24.0, 0.0)
const TOP_PETAL: Vector2 = Vector2(-36.0, -34.0)
const LOW_PETAL: Vector2 = Vector2(-36.0, 34.0)
const BEAM_WARN: float = 0.8

var armed: bool = false
var aim_target: Vector2 = Vector2.ZERO
var arm_age: float = 0.0


func attack(rate_mult: float, spd_bonus: float) -> void:
	if pattern != 0:
		armed = false
	match pattern:
		0:
			if not armed:
				armed = true
				arm_age = age
				aim_target = player_pos()
				RetroSfx.play("boss_hp_tick", -9.0, 0.0)
				wait(BEAM_WARN)
			else:
				armed = false
				var origin: Vector2 = pos() + LENS
				var dir: Vector2 = (aim_target - origin).normalized()
				var n: int = 8 + phase * 2
				for i: int in range(n):
					emit_bullet(origin + dir * 4.0, dir * (165.0 + float(i) * 15.0 + spd_bonus * 0.5), bullet_b(), 2.8)
				if phase >= 2:
					for side: float in [-0.22, 0.22]:
						var d2: Vector2 = dir.rotated(side)
						for j: int in range(2 + phase):
							emit_bullet(origin, d2 * (150.0 + float(j) * 18.0 + spd_bonus * 0.5), bullet_a())
				RetroSfx.play("laser", -6.0, 0.02)
				wait(0.6 * rate_mult)
		1:
			var count: int = 14 + phase * 3
			var gap_ang: float = PI + sin(spin) * 0.75
			var step: float = TAU / float(count)
			var origin2: Vector2 = pos() + Vector2(-20.0, 0.0)
			for i2: int in range(count):
				var a: float = float(i2) * step + spin * 0.37
				var d: Vector2 = Vector2.from_angle(a)
				if d.x > 0.25:
					continue
				if absf(angle_difference(a, gap_ang)) < step * 1.6:
					continue
				emit_bullet(origin2 + d * 10.0, d * (104.0 + spd_bonus * 0.4), bullet_b(), 2.8)
			spin += 0.9
			if phase >= 3:
				for k: int in [-1, 1]:
					shoot_aimed_from(pos() + LENS, 175.0 + spd_bonus, bullet_a(), float(k) * 0.07)
			wait(1.0 * rate_mult)
		_:
			var arms: int = 3 if phase >= 2 else 2
			for m: int in range(2):
				var from: Vector2 = pos() + (TOP_PETAL if m == 0 else LOW_PETAL)
				var sgn: float = 1.0 if m == 0 else -1.0
				for arm: int in range(arms):
					var base: float = sgn * spin + TAU * float(arm) / float(arms)
					for k2: int in range(3):
						var d3: Vector2 = Vector2.from_angle(base + sgn * float(k2) * 0.16)
						if d3.x > 0.3:
							continue
						emit_bullet(from, d3 * (112.0 + float(k2) * 14.0 + spd_bonus * 0.4), bullet_a())
			spin += 0.55
			wait(0.75 * rate_mult)


# The beam's telegraph: incoming sun rays converging on the petals, a glowing lens and a dashed
# aim line to the locked spot (all outside the sprite's silhouette, which draws over this).
func draw() -> void:
	if not armed:
		return
	var k: float = clampf((age - arm_age) / BEAM_WARN, 0.0, 1.0)
	var fl: float = 0.6 + 0.4 * sin(age * 40.0)
	for i: int in range(6):
		var a: float = PI + (float(i) - 2.5) * 0.48
		var tip: Vector2 = LENS + Vector2.from_angle(a) * 46.0
		var far: Vector2 = tip + Vector2.from_angle(a) * (60.0 * (1.0 - k) + 8.0)
		boss.draw_line(far, tip, Color(1.0, 0.85, 0.4, (0.2 + 0.5 * k) * fl), 1.0)
	boss.draw_circle(LENS + Vector2(-20.0, 0.0), 2.0 + 5.0 * k, Color(1.0, 0.9, 0.6, 0.35 + 0.4 * k))
	var to: Vector2 = aim_target - pos()
	var dir: Vector2 = (to - LENS).normalized()
	var d: float = 22.0 + fposmod(age * 120.0, 10.0)
	var col: Color = Color(1.0, 0.45 + 0.5 * k, 0.4 + 0.5 * k, (0.25 + 0.45 * k) * fl)
	while d < 520.0:
		var q: Vector2 = LENS + dir * d
		var g: Vector2 = pos() + q
		if g.x < 0.0 or g.y < 20.0 or g.y > 260.0:
			break
		boss.draw_line(q, q + dir * 5.0, col, 1.0)
		d += 10.0
	boss.draw_arc(to, 6.0 + 4.0 * (1.0 - k), 0.0, TAU, 16, col, 1.0)
