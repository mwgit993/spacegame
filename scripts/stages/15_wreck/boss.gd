extends "res://scripts/stages/stage_boss.gd"

# PHANTOM FLAGSHIP REQUIEM. Three patterns, switching every 4 attacks:
#  0 BROADSIDE        its six gun ports fire a fanned volley; two ports stay dark each time
#                     (the gaps), and the ports about to fire glow first.
#  1 PHANTOM TORPEDO  wailing ghost skulls that home in on the ship for a moment, then fly
#                     straight and fade; a pink spread between launches.
#  2 DEAD MAN'S RING  a ring of spirit shots that hangs round the hull, frozen, then all
#                     launch at once; an aimed volley from the figurehead follows in phase 2+.
# rate_mult shortens the cooldowns; each phase adds ports, torpedoes and ring shots.

const PORTS: Array[Vector2] = [Vector2(-36.0, -12.0), Vector2(-22.0, -28.0), Vector2(-8.0, -43.0), Vector2(-36.0, 12.0), Vector2(-22.0, 28.0), Vector2(-8.0, 43.0)]
const PORT_ANGLE: Array[float] = [0.08, 0.2, 0.33, -0.08, -0.2, -0.33]
const PROW: Vector2 = Vector2(-46.0, 0.0)

var _quiet: Array[int] = [0, 3]
var _next_broadside: bool = false


func attack(rate_mult: float, spd_bonus: float) -> void:
	match pattern:
		0:
			for i: int in range(PORTS.size()):
				if _quiet.has(i):
					continue
				var o: Vector2 = pos() + PORTS[i]
				var ang: float = PI - PORT_ANGLE[i] + randf_range(-0.03, 0.03)
				emit_bullet(o, Vector2.from_angle(ang) * (150.0 + spd_bonus), bullet_a())
				if phase >= 2:
					emit_bullet(o, Vector2.from_angle(ang + 0.07) * (118.0 + spd_bonus), bullet_b())
				if phase >= 3:
					emit_bullet(o, Vector2.from_angle(ang - 0.07) * (118.0 + spd_bonus), bullet_b())
			RetroSfx.play("explode", -13.0, 0.08)
			wait(0.78 * rate_mult)
		1:
			if substep % 2 == 0:
				var n: int = 1 + phase
				for k: int in range(n):
					var o2: Vector2 = pos() + (Vector2(-10.0, -54.0) if k % 2 == 0 else Vector2(-10.0, 54.0))
					var dir: Vector2 = Vector2(-0.6, -0.8 if k % 2 == 0 else 0.8).normalized().rotated(randf_range(-0.2, 0.2))
					var b: GameBullet = emit_bullet(o2, dir * (95.0 + spd_bonus * 0.5 + 12.0 * float(k)), "wreck_wisp", 4.0)
					if b != null:
						b.home_target = boss.player_ref
						b.home_time = 1.6
						b.home_rate = 1.7
						b.life_left = 6.0
				RetroSfx.play("zap", -11.0, 0.1)
				wait(1.1 * rate_mult)
			else:
				shoot_spread_from(pos() + PROW, 5 + phase, 0.15, 150.0 + spd_bonus, bullet_a())
				wait(0.8 * rate_mult)
		_:
			var count: int = 12 + phase * 2
			for i2: int in range(count):
				var a: float = spin + TAU * float(i2) / float(count)
				var b2: GameBullet = emit_bullet(pos() + Vector2.from_angle(a) * 30.0, Vector2.from_angle(a) * (132.0 + spd_bonus), bullet_b())
				if b2 != null:
					b2.slow_timer = 0.75
					b2.slow_factor = 0.04
			spin += 0.19
			if phase >= 2 and substep % 2 == 1:
				for k2: int in range(-1, 2):
					shoot_aimed_from(pos() + PROW, 175.0 + spd_bonus, bullet_a(), float(k2) * 0.12)
			wait(1.0 * rate_mult)
	# Pick which ports stay quiet next time, so the glow can show which ones will fire.
	var next_pattern: int = pattern if substep < 3 else (pattern + 1) % 3
	_next_broadside = next_pattern == 0
	if _next_broadside:
		var g: int = randi() % 3
		_quiet.clear()
		_quiet.append(g)
		if phase < 3:
			_quiet.append(3 + (g + 1 + randi() % 2) % 3)


func draw() -> void:
	if _next_broadside:
		var t: float = clampf(1.0 - boss._fire_timer / 0.6, 0.0, 1.0)
		for i: int in range(PORTS.size()):
			if _quiet.has(i):
				continue
			var flick: float = 0.2 + 0.5 * t + 0.15 * float(int(age * 22.0 + float(i)) % 2)
			boss.draw_circle(PORTS[i] + Vector2(-8.0, 0.0), 2.0 + 3.0 * t, Color(1.0, 0.35, 0.8, flick))
	var k: float = 0.5 + 0.5 * sin(age * 3.0)
	boss.draw_circle(PROW + Vector2(-4.0, -2.0), 3.0 + 2.0 * k, Color(0.5, 1.0, 0.8, 0.12 + 0.12 * k))
