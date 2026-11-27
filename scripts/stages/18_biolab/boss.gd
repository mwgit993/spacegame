extends "res://scripts/stages/stage_boss.gd"

# SUBJECT ZERO: CHIMERA. Three patterns, switching every 4 attacks:
#  0 TOXIC GEYSER   ooze globs heaved high that burst into sprays where they hit the floor,
#                   and every other volley a spit fan from the maw.
#  1 MUTAGEN HOSE   a sweeping hose of shots from the maw, swinging up and down (a second,
#                   counter-swinging hose from phase 2).
#  2 CELL DIVISION  a ring of paired shots that hangs round it for a moment and then bursts
#                   outward; between rings it spawns ooze blobs (children, capped by the blob
#                   cap).
# Each phase adds globs, hose shots and ring cells; rate_mult shortens the cooldowns.

const Blob = preload("enemy_blob.gd")

const MAW: Vector2 = Vector2(-22.0, 13.0)

var _hose: float = 0.0


func attack(rate_mult: float, spd_bonus: float) -> void:
	var maw: Vector2 = pos() + MAW
	match pattern:
		0:
			var n: int = 2 + phase
			for i: int in range(n):
				var v: Vector2 = Vector2(-(58.0 + 46.0 * float(i) + randf_range(-10.0, 10.0)), -(160.0 + randf_range(0.0, 50.0)))
				var b: GameBullet = emit_bullet(pos() + Vector2(-6.0, -30.0), v, "biolab_glob", 3.5)
				if b != null:
					b.gravity_pull = 170.0
					b.floor_burst = 4
					b.burst_tex = bullet_b()
					b.burst_speed = 95.0
			if substep % 2 == 1:
				for k: int in range(-1, 2):
					shoot_aimed_from(maw, 165.0 + spd_bonus, bullet_a(), float(k) * 0.15)
			wait(1.1 * rate_mult)
		1:
			var hoses: int = 1 if phase < 2 else 2
			for h: int in range(hoses):
				var sgn: float = 1.0 if h == 0 else -1.0
				for k2: int in range(3 + phase):
					var a: float = PI + sgn * sin(_hose + float(k2) * 0.12) * 0.75
					emit_bullet(maw, Vector2.from_angle(a) * (150.0 + spd_bonus + 8.0 * float(k2)), bullet_b() if h == 0 else bullet_a())
			_hose += 0.55
			RetroSfx.play("laser", -13.0, 0.08)
			wait(0.42 * rate_mult)
		_:
			if substep % 2 == 0 and Blob.count(boss) < Blob.CAP - 2:
				for k3: int in range(2):
					boss._request_child(GameEnemy.Type.MODULE, pos() + Vector2(-20.0, -10.0 + 30.0 * float(k3)), Vector2(-70.0 - 30.0 * float(k3), -150.0), 1, "blob")
			var cells: int = 8 + phase * 2
			for c: int in range(cells):
				var a2: float = spin + TAU * float(c) / float(cells)
				for pair: float in [-0.06, 0.06]:
					var b2: GameBullet = emit_bullet(pos() + Vector2.from_angle(a2) * 34.0, Vector2.from_angle(a2 + pair) * (125.0 + spd_bonus), bullet_b())
					if b2 != null:
						b2.slow_timer = 0.6
						b2.slow_factor = 0.06
			spin += 0.21
			RetroSfx.play("explode", -12.0, 0.1)
			wait(1.05 * rate_mult)


func draw() -> void:
	var k: float = 0.5 + 0.5 * sin(age * 6.0)
	boss.draw_circle(MAW + Vector2(-10.0, 0.0), 3.0 + 3.0 * k, Color(0.5, 1.0, 0.2, 0.12 + 0.15 * k))
	if pattern == 1:
		# the hose's aim for the next volley
		var a: float = PI + sin(_hose) * 0.75
		boss.draw_line(MAW + Vector2.from_angle(a) * 16.0, MAW + Vector2.from_angle(a) * 60.0, Color(0.7, 1.0, 0.3, 0.35), 1.0)
