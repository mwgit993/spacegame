extends "res://scripts/stages/stage_enemy.gd"

# TEMPORARY EXAMPLE ENEMY 2: "lancer". Slides in to the right edge tracking the player's height,
# locks on (a laser sight across the screen is the telegraph), fires a 3-way spread and dashes
# across the screen. Armoured while dashing (half damage), and bursts into a ring of shots when
# destroyed. variant 1 waits a little longer before locking on.
#
# Shows: a small state machine, a telegraph line in draw(), modify_damage(), and a death effect
# (shots fired while dying must be deferred).

enum Phase { ENTER, AIM, DASH }

const AIM_TIME: float = 0.7

var state: Phase = Phase.ENTER
var timer: float = 0.0
var target_x: float = 410.0


func setup() -> void:
	target_x = randf_range(390.0, 432.0)
	timer = 1.2 if variant == 0 else 1.8


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		Phase.ENTER:
			p.x = lerpf(p.x, target_x, clampf(2.5 * delta, 0.0, 1.0))
			p.y = lerpf(p.y, clampf(player_pos().y, 40.0, 238.0), clampf(1.6 * delta, 0.0, 1.0))
			timer -= delta
			if timer <= 0.0 and absf(p.x - target_x) < 12.0:
				state = Phase.AIM
				timer = AIM_TIME
				sfx("boss_hp_tick", -14.0, 0.0)
		Phase.AIM:
			timer -= delta
			if timer <= 0.0:
				state = Phase.DASH
				shoot_spread_from(p + Vector2(-10.0, 0.0), 3, 0.18, 150.0, bullet_a())
				set_texture("example_lancer_1")
				sfx("missile", -11.0)
		Phase.DASH:
			p.x -= 280.0 * delta
	enemy.global_position = p


func draw() -> void:
	if state == Phase.AIM:
		# The laser sight: from the nose to the left edge of the screen, flickering faster near
		# the end of the lock-on.
		var a: float = 0.25 + 0.25 * sin(age * (30.0 + 40.0 * (1.0 - timer / AIM_TIME)))
		enemy.draw_line(Vector2(-11.0, 0.0), Vector2(-enemy.global_position.x, 0.0), Color(1.0, 0.3, 0.4, a), 1.0)
		enemy.draw_circle(Vector2(-11.0, 0.0), 2.0, Color(1.0, 0.85, 0.4, 0.9))


func modify_damage(dmg: float) -> float:
	return dmg * 0.5 if state == Phase.DASH else dmg


func on_death() -> void:
	var rot: float = randf() * TAU
	for i: int in range(6):
		emit_bullet(enemy.global_position, Vector2.from_angle(rot + TAU * float(i) / 6.0) * 90.0, bullet_b(), true)
	sparks(enemy.global_position, Color("#28e8ff"), 8)
