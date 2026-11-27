extends "res://scripts/stages/stage_enemy.gd"

# Drone: flies in a flock. The wave director spawns a whole flock at the same moment, each
# drone with its own slot (the spawn "phase"), so they all follow one shared centre path and
# swirl around it. Each drone takes potshots (charge glint first); then, one after another,
# they flash red with a line pointing at the ship (the telegraph) and dive at where it was.
# Drones the queen gives birth to (gen > 0) swirl round their birth point, then dive.

enum S { FLOCK, WARN, DIVE }

const WARN_TIME: float = 0.55
const DIVE_SPEED: float = 205.0

var state: S = S.FLOCK
var timer: float = 0.0
var slot: int = 0
var center: Vector2 = Vector2.ZERO
var dive_dir: Vector2 = Vector2.LEFT
var dive_at: float = 3.0
var swirl: float = 0.0
var mirror: float = 1.0


func setup() -> void:
	slot = int(phase) % 8
	mirror = -1.0 if variant == 1 else 1.0
	center = enemy.global_position
	swirl = float(slot) * 2.39996  # the golden angle spreads a flock evenly round its centre
	if gen > 0:
		dive_at = randf_range(1.1, 1.7)
		fire_timer = 99.0
	else:
		dive_at = 3.4 + float(slot) * 0.55
		fire_timer = 0.9 + float(slot) * 0.3


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		S.FLOCK:
			if gen == 0:
				center.x = lerpf(center.x, 352.0, clampf(0.75 * delta, 0.0, 1.0))
				var want_y: float = clampf(player_pos().y, 64.0, 206.0)
				base_y = move_toward(base_y, want_y, 22.0 * delta)
				center.y = clampf(base_y + sin(age * 1.4) * 34.0 * mirror, 46.0, 224.0)
			else:
				vel = vel.lerp(Vector2(-24.0, 0.0), clampf(2.0 * delta, 0.0, 1.0))
				center += vel * delta
				center.y = clampf(center.y, 46.0, 224.0)
			var r: float = (12.0 + 4.0 * float(slot % 3)) if gen == 0 else 8.0
			var a: float = swirl + age * 2.6
			p = center + Vector2(cos(a), sin(a) * 0.8) * r + Vector2(0.0, sin(age * 7.0 + float(slot)) * 1.5)
			set_texture("hive_drone_0" if int(age * 16.0) % 2 == 0 else "hive_drone_1")
			fire_timer -= delta
			if fire_timer <= 0.0 and on_screen(80.0, 455.0):
				fire_timer = fire_cd(1.8)
				shoot_aimed(118.0, bullet_b())
			if age >= dive_at and on_screen(60.0, 470.0):
				state = S.WARN
				timer = WARN_TIME
				sfx("boss_hp_tick", -16.0, 0.2)
		S.WARN:
			timer -= delta
			p += Vector2(randf_range(-0.7, 0.7), randf_range(-0.7, 0.7))
			set_texture("hive_drone_2" if int(age * 14.0) % 2 == 0 else "hive_drone_0")
			if timer <= 0.0:
				state = S.DIVE
				dive_dir = (player_pos() - p).normalized()
				if dive_dir.x > 0.3:
					dive_dir = Vector2(0.3, signf(dive_dir.y) * 0.95).normalized()
				sprite().rotation = dive_dir.angle() - PI
				set_texture("hive_drone_2")
				sfx("missile", -15.0, 0.1)
				if gen == 0 and on_screen(80.0, 455.0):
					# a parting pair as it dives
					shoot_aimed(125.0, bullet_b(), 0.14)
					shoot_aimed(125.0, bullet_b(), -0.14)
		S.DIVE:
			p += dive_dir * DIVE_SPEED * delta
	enemy.global_position = p


func draw() -> void:
	match state:
		S.FLOCK:
			draw_glint(Vector2(-7.0, 0.0), fire_timer, 0.3, Color(0.7, 1.0, 0.3))
		S.WARN:
			var k: float = 1.0 - timer / WARN_TIME
			var flick: float = 0.3 + 0.3 * float(int(age * 20.0) % 2)
			enemy.draw_arc(Vector2.ZERO, 9.0 - 3.0 * k, 0.0, TAU, 12, Color(1.0, 0.25, 0.2, flick), 1.0)
			var to_ship: Vector2 = (player_pos() - enemy.global_position).normalized()
			enemy.draw_line(to_ship * 8.0, to_ship * (20.0 + 26.0 * k), Color(1.0, 0.3, 0.25, 0.25 + 0.3 * k), 1.0)
		S.DIVE:
			enemy.draw_rect(Rect2(-dive_dir * 9.0 - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(1.0, 0.7, 0.3, 0.45))
			enemy.draw_rect(Rect2(-dive_dir * 15.0 - Vector2(0.5, 0.5), Vector2(1.0, 1.0)), Color(1.0, 0.5, 0.2, 0.3))


func on_death() -> void:
	sparks(enemy.global_position, Color("#e8a028"), 5)
