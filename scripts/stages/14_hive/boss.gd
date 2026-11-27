extends "res://scripts/stages/stage_boss.gd"

# BROOD QUEEN VESPERA. Three patterns, switching every 4 attacks:
#  0 ACID RAIN    globs lobbed high from the egg sac rain down and burst where they hit the
#                 floor; every other volley she also spits a fan from her jaws.
#  1 BROOD        she births drones (children, capped at BROOD_CAP) that swirl and dive, and
#                 between births breathes out pheromone rings (two counter-offset rings later).
#  2 STINGER LANCE a line of fast stingers along a sight line she draws first (the line locks
#                 onto the ship during the wind-up, so moving off it dodges the lance).
# Each phase adds globs, drones and stingers; rate_mult shortens the cooldowns.

const BROOD_CAP: int = 6
const JAW: Vector2 = Vector2(-52.0, -2.0)
const SAC: Vector2 = Vector2(18.0, 0.0)

var _aim: float = PI
var _lance_ready: bool = false


func attack(rate_mult: float, spd_bonus: float) -> void:
	var jaw: Vector2 = pos() + JAW
	match pattern:
		0:
			var n: int = 2 + phase
			for i: int in range(n):
				var v: Vector2 = Vector2(-(64.0 + 44.0 * float(i) + randf_range(-10.0, 10.0)), -(150.0 + randf_range(0.0, 55.0)))
				var b: GameBullet = emit_bullet(pos() + SAC + Vector2(-6.0, -22.0), v, "hive_glob", 3.5)
				if b != null:
					b.gravity_pull = 175.0
					b.floor_burst = 3 if phase < 3 else 4
					b.burst_tex = bullet_b()
					b.burst_speed = 92.0
			if substep % 2 == 1:
				for k: int in range(-1 - phase / 3, 2 + phase / 3):
					shoot_aimed_from(jaw, 160.0 + spd_bonus, bullet_b(), float(k) * 0.16)
			wait(1.15 * rate_mult)
		1:
			if substep % 2 == 0 and _drone_count() < BROOD_CAP:
				var births: int = 2 if phase < 3 else 3
				for k2: int in range(births):
					boss._request_child(GameEnemy.Type.MODULE, pos() + SAC + Vector2(-10.0, -16.0 + 16.0 * float(k2)), Vector2(-70.0 - 25.0 * float(k2), -60.0 + 60.0 * float(k2)), 1, "drone")
				if boss.fx != null:
					boss.fx.spawn_hit_sparks(pos() + SAC, Color("#a8f040"), 10)
				RetroSfx.play("explode", -12.0, 0.1)
				wait(0.85 * rate_mult)
			else:
				shoot_ring(12 + phase * 2, 118.0 + spd_bonus, bullet_a(), spin)
				if phase >= 2:
					shoot_ring(12 + phase * 2, 92.0 + spd_bonus, bullet_b(), spin + PI / float(12 + phase * 2))
				spin += 0.23
				wait(0.95 * rate_mult)
		_:
			var dir: float = _aim if _lance_ready else (player_pos() - jaw).angle()
			var count: int = 3 + phase
			for k3: int in range(count):
				emit_bullet(jaw, Vector2.from_angle(dir) * (205.0 + spd_bonus + 16.0 * float(k3)), bullet_a())
			if phase >= 2:
				for side: float in [-0.3, 0.3]:
					emit_bullet(jaw, Vector2.from_angle(dir + side) * (175.0 + spd_bonus), bullet_b())
			RetroSfx.play("laser", -11.0, 0.05)
			wait(0.85 * rate_mult)
	# Lock the next lance's sight line now, so it shows during the wind-up.
	var next_pattern: int = pattern if substep < 3 else (pattern + 1) % 3
	_lance_ready = next_pattern == 2
	if _lance_ready:
		_aim = (player_pos() - jaw).angle()


func _drone_count() -> int:
	var n: int = 0
	for node: Node in boss.get_tree().get_nodes_in_group("enemies"):
		var ge: GameEnemy = node as GameEnemy
		if ge != null and ge.module_kind == "drone" and not ge._dead:
			n += 1
	return n


func draw() -> void:
	# Pulsing glow round the jaws.
	var k: float = 0.5 + 0.5 * sin(age * 5.0)
	boss.draw_circle(JAW + Vector2(-4.0, 0.0), 3.0 + 2.0 * k, Color(0.6, 1.0, 0.25, 0.18 + 0.15 * k))
	if _lance_ready:
		var t: float = clampf(1.0 - boss._fire_timer / 0.85, 0.0, 1.0)
		var flick: float = 0.12 + 0.3 * t + 0.1 * float(int(age * 24.0) % 2)
		var d: Vector2 = Vector2.from_angle(_aim)
		boss.draw_line(JAW + d * 6.0, JAW + d * 520.0, Color(1.0, 0.35, 0.25, flick), 1.0)
		boss.draw_circle(JAW + d * 6.0, 2.0 + 2.0 * t, Color(1.0, 0.85, 0.4, 0.5 + 0.4 * t))
