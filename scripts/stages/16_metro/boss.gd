extends "res://scripts/stages/stage_boss.gd"

# CORPORATE TITAN APEX-9. Three patterns, switching every 4 attacks:
#  0 SEARCHLIGHT  its visor sweeps a searchlight up and down the screen; each attack fires a
#                 tight fan down the beam (drawn first), then the beam moves on.
#  1 MISSILES     shoulder pods launch warheads that home in for a moment, then fly straight;
#                 the gatling arm sprays a spread in between.
#  2 NEON RAIN    a row of glowing drops falls from the top of the screen with one gap,
#                 while the gatling fires a wall with a gap (two gaps lined up in phase 3).
# Each phase adds missiles, fan shots and drops; rate_mult shortens the cooldowns.

const VISOR: Vector2 = Vector2(-20.0, -61.0)
const GUN: Vector2 = Vector2(-57.0, 4.0)
const PODS: Array[Vector2] = [Vector2(-22.0, -42.0), Vector2(-22.0, 36.0)]

var _beam: float = PI - 0.1
var _beam_dir: float = 1.0
var _rain_gap: int = 3


func setup() -> void:
	_beam = PI - 0.1


func attack(rate_mult: float, spd_bonus: float) -> void:
	match pattern:
		0:
			var o: Vector2 = pos() + VISOR
			var n: int = 2 + phase
			for k: int in range(n):
				var off_a: float = (float(k) - float(n - 1) * 0.5) * 0.07
				emit_bullet(o, Vector2.from_angle(_beam + off_a) * (205.0 + spd_bonus), bullet_b())
			emit_bullet(o, Vector2.from_angle(_beam) * (170.0 + spd_bonus), bullet_a())
			_beam += _beam_dir * 0.2
			if _beam > PI + 0.55:
				_beam_dir = -1.0
			elif _beam < PI - 0.75:
				_beam_dir = 1.0
			RetroSfx.play("laser", -12.0, 0.05)
			wait(0.5 * rate_mult)
		1:
			if substep % 2 == 0:
				var m: int = 2 + phase
				for k2: int in range(m):
					var pod: Vector2 = pos() + PODS[k2 % 2]
					var up: float = -1.0 if k2 % 2 == 0 else 1.0
					var v: Vector2 = Vector2(-60.0 - 25.0 * float(k2 / 2), 150.0 * up).rotated(randf_range(-0.15, 0.15))
					var b: GameBullet = emit_bullet(pod, v, "metro_missile", 3.5)
					if b != null:
						b.home_target = boss.player_ref
						b.home_time = 1.1
						b.home_rate = 2.4
						b.life_left = 5.0
				RetroSfx.play("missile", -9.0, 0.08)
				wait(1.0 * rate_mult)
			else:
				shoot_spread_from(pos() + GUN, 5 + phase, 0.14, 165.0 + spd_bonus, bullet_a())
				wait(0.75 * rate_mult)
		_:
			# drops along the top edge, one gap per row
			var cols: int = 9
			for c: int in range(cols):
				if c == _rain_gap or (phase < 3 and c == _rain_gap + 1):
					continue
				var x: float = 40.0 + float(c) * 44.0 + float(substep % 2) * 22.0
				emit_bullet(Vector2(x, 34.0), Vector2(-24.0, 112.0 + spd_bonus * 0.4), bullet_b())
			_rain_gap = (_rain_gap + 3 + randi() % 3) % (cols - 1)
			if phase >= 2:
				var gap: int = (substep * 2 + 1) % 7
				for lane: int in range(9):
					if lane == gap or lane == gap + 1:
						continue
					emit_bullet(Vector2(pos().x - 50.0, 40.0 + float(lane) * 24.0), Vector2(-(150.0 + spd_bonus), 0.0), bullet_a())
			wait(0.95 * rate_mult)


func draw() -> void:
	# the searchlight: always on, brighter and red while that pattern is running
	var in_sweep: bool = pattern == 0
	var a: Vector2 = Vector2.from_angle(_beam - 0.07) * 470.0
	var b: Vector2 = Vector2.from_angle(_beam + 0.07) * 470.0
	var col: Color = Color(1.0, 0.25, 0.3, 0.13 + 0.05 * float(int(age * 18.0) % 2)) if in_sweep else Color(1.0, 0.95, 0.8, 0.05)
	boss.draw_colored_polygon(PackedVector2Array([VISOR, VISOR + a, VISOR + b]), col)
	boss.draw_circle(VISOR, 2.5, Color(1.0, 0.8, 0.8, 0.9))
	var k: float = 0.5 + 0.5 * sin(age * 4.0)
	boss.draw_circle(GUN + Vector2(-4.0, 0.0), 2.0 + 2.0 * k, Color(1.0, 0.9, 0.4, 0.15 + 0.15 * k))
