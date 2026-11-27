extends "res://scripts/stages/stage_enemy.gd"

# CRYSTAL BAT: flits in erratic swarms. When it picks its moment its eyes blaze and it spreads
# its wings with a shriek (SHRIEK seconds of expanding sound rings: the telegraph), then it
# dives at where the player was, spitting a 3-way spread, and flutters off. The wave director's
# "phase" staggers a swarm so they don't all dive at once.

enum Phase { FLIT, SHRIEK, DIVE, LEAVE }

const SHRIEK: float = 0.45
const DIVE_SPEED: float = 190.0

var state: Phase = Phase.FLIT
var timer: float = 0.0
var wob: float = 0.0
var dive_t: float = 0.0


func setup() -> void:
	wob = randf() * TAU
	timer = randf_range(0.9, 1.6) + phase * 0.35


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		Phase.FLIT:
			p.x -= (46.0 + sin(age * 5.0 + wob) * 26.0) * delta
			p.y = clampf(base_y + sin(age * 3.1 + wob) * 22.0 + sin(age * 7.3 + wob * 2.0) * 6.0, 40.0, 238.0)
			set_texture("crystal_bat_%d" % (int(age * 10.0 + wob) % 2))
			timer -= delta
			if timer <= 0.0 and on_screen(110.0, 450.0):
				state = Phase.SHRIEK
				timer = SHRIEK
				sfx("boss_hp_tick", -14.0, 0.2)
		Phase.SHRIEK:
			set_texture("crystal_bat_2")
			p += Vector2(sin(age * 60.0), cos(age * 53.0)) * 0.4
			timer -= delta
			if timer <= 0.0:
				var dir: Vector2 = (player_pos() - p).normalized()
				if dir.x > -0.3:
					dir = Vector2(-0.3, signf(dir.y) if dir.y != 0.0 else 1.0).normalized()
				vel = dir * DIVE_SPEED
				for k: int in [-1, 0, 1]:
					shoot_aimed_from(p + Vector2(-5.0, 1.0), 140.0, bullet_a(), float(k) * 0.24)
				state = Phase.DIVE
				dive_t = 0.0
				sfx("missile", -15.0, 0.1)
		Phase.DIVE:
			set_texture("crystal_bat_%d" % (int(age * 18.0) % 2))
			p += vel * delta
			dive_t += delta
			if dive_t > 0.85:
				state = Phase.LEAVE
		Phase.LEAVE:
			set_texture("crystal_bat_%d" % (int(age * 12.0) % 2))
			vel = vel.lerp(Vector2(-150.0, -40.0 if p.y > 135.0 else 40.0), clampf(delta * 2.0, 0.0, 1.0))
			p += vel * delta
	enemy.global_position = p


func draw() -> void:
	if state == Phase.SHRIEK:
		var k: float = 1.0 - timer / SHRIEK
		for r: int in range(2):
			var rr: float = fposmod(k * 2.0 + float(r) * 0.5, 1.0)
			enemy.draw_arc(Vector2(-6.0, 0.0), 4.0 + rr * 12.0, PI * 0.6, PI * 1.4, 10, Color(1.0, 0.85, 1.0, 0.55 * (1.0 - rr)), 1.0)
		draw_glint(Vector2(-6.0, -1.0), timer, SHRIEK, Color(1.0, 0.8, 0.3))


func on_death() -> void:
	sparks(enemy.global_position, Color("#b07ae8"), 5)
