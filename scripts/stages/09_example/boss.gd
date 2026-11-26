extends "res://scripts/stages/stage_boss.gd"

# TEMPORARY EXAMPLE BOSS: "TEMPLATE CORE". Three patterns, switching every 4 attacks (pattern
# 0, 1, 2, 0, ...); each phase adds bullets and rate_mult shortens the cooldowns. GameEnemy
# handles the intro, movement, frames, phases, escorts and death (see stage_boss.gd).

func attack(rate_mult: float, spd_bonus: float) -> void:
	var muzzle: Vector2 = pos() + Vector2(-34.0, 0.0)
	match pattern:
		0:  # An aimed fan from the lens, one shot wider per phase.
			for k: int in range(-phase, phase + 1):
				shoot_aimed_from(muzzle, 160.0 + spd_bonus, bullet_a(), float(k) * 0.12)
			wait(0.8 * rate_mult)
		1:  # A rotating ring of the stage's own shots.
			shoot_ring(10 + phase * 2, 140.0 + spd_bonus, bullet_b(), spin)
			spin += 0.3
			wait(0.75 * rate_mult)
		_:  # A wall from both arms with a two-lane gap that moves every volley.
			var gap: int = (substep * 2 + 1) % 7
			for lane: int in range(9):
				if lane == gap or lane == gap + 1:
					continue
				shoot_from(Vector2(pos().x - 40.0, 40.0 + float(lane) * 24.0), Vector2(-(150.0 + spd_bonus), 0.0), bullet_a())
			wait(1.0 * rate_mult)


# A pulsing ring in front of the lens. Boss drawing sits behind the boss sprite (like the
# built-in charge glint), so keep it outside the silhouette.
func draw() -> void:
	var k: float = 0.5 + 0.5 * sin(age * 6.0)
	boss.draw_arc(Vector2(-54.0, 0.0), 5.0 + 3.0 * k, 0.0, TAU, 16, Color(0.66, 0.6, 1.0, 0.35 + 0.3 * k), 1.0)
