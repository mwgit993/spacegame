extends "res://scripts/stages/stage_enemy.gd"

# Billboard drone: a flying ad screen that cycles its ads while it drifts in and bobs. Before
# each attack the screen goes red with a big "!" for WARN_TIME (the telegraph), then it fires
# a "pixel block": variant 0 a tight 3x3 block of shots aimed at the ship, variant 1 a five-
# shot ticker line that sweeps left. Damage makes the screen glitch. Leaves after SHOWS.

enum S { ENTER, SHOW, WARN, LEAVE }

const WARN_TIME: float = 0.8
const SHOWS: int = 4
const GRID: float = 8.0

var state: S = S.ENTER
var timer: float = 0.0
var target_x: float = 410.0
var shows_left: int = SHOWS
var ad: int = 0
var glitch: float = 0.0


func setup() -> void:
	target_x = randf_range(385.0, 430.0)
	ad = randi() % 3
	fire_timer = 1.6


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	glitch = maxf(0.0, glitch - delta)
	match state:
		S.ENTER, S.SHOW:
			p.x = lerpf(p.x, target_x, clampf(1.8 * delta, 0.0, 1.0))
			p.y = base_y + sin(age * 1.1 + phase) * 9.0
			if state == S.ENTER and absf(p.x - target_x) < 16.0:
				state = S.SHOW
			fire_timer -= delta
			if fire_timer <= WARN_TIME and on_screen(110.0, 455.0):
				state = S.WARN
				timer = fire_timer
				sfx("boss_hp_tick", -14.0, 0.0)
		S.WARN:
			timer -= delta
			p.y = base_y + sin(age * 1.1 + phase) * 9.0
			if timer <= 0.0:
				_fire(p)
				shows_left -= 1
				ad = (ad + 1) % 3
				if shows_left <= 0:
					state = S.LEAVE
				else:
					state = S.SHOW
					fire_timer = fire_cd(2.4)
		S.LEAVE:
			p.x += 70.0 * delta
			p.y -= 20.0 * delta
	enemy.global_position = p
	if state == S.WARN:
		set_texture("metro_board_3" if int(age * 10.0) % 3 != 0 else "metro_board_%d" % ad)
	elif glitch > 0.0:
		set_texture("metro_board_%d" % (int(age * 30.0) % 4))
	else:
		set_texture("metro_board_%d" % ad)


func _fire(p: Vector2) -> void:
	var o: Vector2 = p + Vector2(-14.0, -2.0)
	if variant == 0:
		var dir: Vector2 = (player_pos() - o).normalized()
		var side: Vector2 = dir.orthogonal()
		for i: int in range(-1, 2):
			for j: int in range(-1, 2):
				emit_bullet(o + side * float(i) * GRID + dir * float(j) * GRID, dir * 120.0, bullet_b())
	else:
		for k: int in range(-2, 3):
			emit_bullet(o + Vector2(0.0, float(k) * 11.0), Vector2(-128.0, float(k) * 6.0), bullet_b())
	sparks(o, Color("#ff3c9c"), 5)
	sfx("zap", -13.0, 0.1)


func modify_damage(dmg: float) -> float:
	glitch = 0.12
	return dmg


func draw() -> void:
	if state == S.WARN:
		var k: float = 1.0 - clampf(timer / WARN_TIME, 0.0, 1.0)
		var a: float = 0.12 + 0.25 * k * float(int(age * 16.0) % 2)
		enemy.draw_rect(Rect2(-17.0, -14.0, 34.0, 24.0), Color(1.0, 0.2, 0.25, a), false, 1.0)
		enemy.draw_rect(Rect2(-19.0 - 3.0 * k, -16.0 - 3.0 * k, 38.0 + 6.0 * k, 28.0 + 6.0 * k), Color(1.0, 0.2, 0.25, a * 0.6), false, 1.0)
	else:
		# the screen's glow on the night air
		enemy.draw_rect(Rect2(-16.0, -13.0, 32.0, 22.0), Color(1.0, 0.3, 0.7, 0.05 + 0.03 * sin(age * 3.0)))
	draw_hp_bar(26.0, -17.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#30f0e0"), 8)
	sparks(enemy.global_position, Color("#ff3c9c"), 8)
