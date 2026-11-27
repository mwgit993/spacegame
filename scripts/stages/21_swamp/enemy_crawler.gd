extends "res://scripts/stages/stage_enemy.gd"

# BOG CRAWLER: a segmented leech-beetle that crawls along the bog at the bottom of the screen.
# When it picks its moment it stops and rears up, mandibles glowing; a dotted arc shows where its
# middle glob will fly (REAR seconds: the telegraph). Then it lobs three acid globs on short,
# true and long arcs through the player's position; each one splashes into droplets where it hits
# the bog. variant 1 crawls faster and rears sooner.

const FLOOR_Y: float = 242.0
const REAR: float = 0.7
const GRAV: float = 240.0
const MOUTH: Vector2 = Vector2(-16.0, -5.0)

var speed: float = 50.0


func setup() -> void:
	enemy.global_position.y = FLOOR_Y
	base_y = FLOOR_Y
	speed = 50.0 if variant == 0 else 64.0
	fire_timer = randf_range(1.0, 1.5) - (0.35 if variant == 1 else 0.0) + phase * 0.3


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	fire_timer -= delta
	if fire_timer < REAR and fire_timer > 0.0:
		set_texture("swamp_crawler_2")
		p.x -= 20.0 * delta
	else:
		set_texture("swamp_crawler_%d" % (int(age * 8.0) % 2))
		p.x -= speed * delta
	p.y = FLOOR_Y
	enemy.global_position = p
	if fire_timer <= 0.0:
		if on_screen(60.0, 455.0):
			var flight: float = _flight_time()
			for m: float in [0.8, 1.0, 1.22]:
				var v: Vector2 = _launch(flight * m)
				var b: GameBullet = emit_bullet(p + MOUTH, v / enemy._shot_mult, "swamp_glob", false, 3.5)
				if b != null:
					b.gravity_pull = GRAV
					b.floor_burst = 2
					b.burst_tex = "swamp_drop"
					b.burst_speed = 84.0
			sfx("missile", -15.0, 0.15)
			fire_timer = fire_cd(3.9)
		else:
			fire_timer = REAR


func _flight_time() -> float:
	var dx: float = absf(player_pos().x - (enemy.global_position.x + MOUTH.x))
	return clampf(dx / 150.0, 0.75, 1.45)


# Launch velocity for a lob that passes through the player's position after `t` seconds.
func _launch(t: float) -> Vector2:
	var o: Vector2 = enemy.global_position + MOUTH
	var tg: Vector2 = player_pos()
	return Vector2((tg.x - o.x) / t, (tg.y - o.y - 0.5 * GRAV * t * t) / t)


func draw() -> void:
	if fire_timer < REAR and fire_timer > 0.0:
		draw_glint(MOUTH, fire_timer, REAR, Color(0.75, 1.0, 0.3))
		# The dotted arc of the middle glob.
		var k: float = 1.0 - fire_timer / REAR
		var v: Vector2 = _launch(_flight_time())
		var a: float = 0.12 + 0.3 * k
		var t: float = 0.08
		while t < 2.0:
			var q: Vector2 = MOUTH + v * t + Vector2(0.0, 0.5 * GRAV * t * t)
			if enemy.global_position.y + q.y > 250.0 or enemy.global_position.x + q.x < 0.0:
				break
			enemy.draw_rect(Rect2(q.floor(), Vector2.ONE), Color(0.8, 1.0, 0.4, a))
			t += 0.07


func on_death() -> void:
	sparks(enemy.global_position, Color("#8c7494"), 6)
	sparks(enemy.global_position + Vector2(0.0, -3.0), Color("#b4ea48"), 4)
