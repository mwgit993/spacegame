extends "res://scripts/stages/stage_enemy.gd"

# Attack drone, built and launched by a drone factory (a child: no Scrap). It shoots out of the
# bay, homes in on the ship for HOME_TIME, then stops dead with its eye flaring (the telegraph:
# AIM_TIME), fires one short fan and flies off in a straight line. No new drones are built
# while CAP of them are about.

enum S { LAUNCH, HOME, AIM, FLEE }

const CAP: int = 8
const LAUNCH_TIME: float = 0.35
const HOME_TIME: float = 1.2
const AIM_TIME: float = 0.4
const SPEED: float = 112.0

var state: S = S.LAUNCH
var timer: float = LAUNCH_TIME


static func count(from: GameEnemy) -> int:
	var n: int = 0
	for node: Node in from.get_tree().get_nodes_in_group("enemies"):
		var ge: GameEnemy = node as GameEnemy
		if ge != null and ge.module_kind == "drone" and not ge._dead:
			n += 1
	return n


func setup() -> void:
	vel = Vector2(-70.0, 0.0)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		S.LAUNCH:
			timer -= delta
			vel = vel.move_toward(vel.normalized() * 60.0, 260.0 * delta)
			if timer <= 0.0:
				state = S.HOME
				timer = HOME_TIME
		S.HOME:
			timer -= delta
			var want: Vector2 = (player_pos() - p).normalized() * SPEED
			vel = vel.lerp(want, clampf(2.6 * delta, 0.0, 1.0))
			if timer <= 0.0 or (p.distance_to(player_pos()) < 70.0 and timer < HOME_TIME - 0.4):
				state = S.AIM
				timer = AIM_TIME
				sfx("boss_hp_tick", -18.0, 0.15)
		S.AIM:
			timer -= delta
			vel = vel.move_toward(Vector2.ZERO, 400.0 * delta)
			if timer <= 0.0:
				for k: int in range(-1, 2):
					shoot_aimed_from(p + Vector2(-5.0, 0.0), 130.0, bullet_b(), float(k) * 0.2)
				state = S.FLEE
				var d: Vector2 = (player_pos() - p).normalized()
				vel = Vector2(minf(-80.0, d.x * 150.0), d.y * 60.0)
		S.FLEE:
			vel = vel.move_toward(vel.normalized() * 190.0, 200.0 * delta)
	p += vel * delta
	p.y = clampf(p.y, 34.0, 246.0)
	enemy.global_position = p
	set_texture("mothership_drone_1" if state == S.AIM and int(age * 16.0) % 2 == 0 else "mothership_drone_0")


func draw() -> void:
	if state == S.AIM:
		var k: float = 1.0 - clampf(timer / AIM_TIME, 0.0, 1.0)
		var d: Vector2 = (player_pos() - enemy.global_position).normalized()
		enemy.draw_line(d * 7.0, d * (16.0 + 26.0 * k), Color(1.0, 0.3, 0.35, 0.25 + 0.45 * k), 1.0)
		draw_glint(Vector2(-3.0, 0.0), timer, AIM_TIME, Color(1.0, 0.25, 0.35))


func on_death() -> void:
	sparks(enemy.global_position, Color("#ff4058"), 5)
