extends "res://scripts/stages/stage_enemy.gd"

# DRILL BOT: burrows out of the floor (variant 0) or the ceiling (variant 1). For WARN seconds
# the spot cracks, glows and spits grit (the entrance telegraph, hidden and unhittable); then it
# bursts out drill-first, throwing a small fan of rock, brakes to a hover, and aims: a dashed
# lane line and a glint on the drill tip show where it will go. It fires a 3-way spread and
# dashes along the lane.

enum Phase { BURST, AIM, DASH }

const WARN: float = 0.95
const FLOOR_Y: float = 252.0
const CEIL_Y: float = 31.0
const AIM_TIME: float = 0.75
const DASH_SPEED: float = 235.0
const DEBRIS: int = 4

var state: Phase = Phase.BURST
var timer: float = 0.0
var dir: float = -1.0           # -1 burrows up out of the floor, +1 down out of the ceiling
var dash_dir: Vector2 = Vector2.LEFT


func setup() -> void:
	dir = 1.0 if variant == 1 else -1.0
	enemy.global_position.y = CEIL_Y if variant == 1 else FLOOR_Y
	base_y = enemy.global_position.y
	warn_timer = WARN
	_face(Vector2(0.0, dir))


func on_wake() -> void:
	vel = Vector2(-28.0, dir * 255.0)
	sfx("explode", -13.0, 0.1)
	sparks(enemy.global_position, Color("#c8a070"), 8)
	# Rock thrown out of the burrow (the cracks were the telegraph): a small fan that falls back.
	for i: int in range(DEBRIS):
		var t: float = (float(i) + 0.5) / float(DEBRIS) - 0.5
		var b: GameBullet = emit_bullet(enemy.global_position + Vector2(0.0, dir * 4.0), Vector2(-30.0 + t * 150.0, dir * (120.0 - absf(t) * 60.0)), bullet_b(), false, 3.0)
		if b != null:
			b.gravity_pull = 170.0 if dir < 0.0 else 40.0


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	set_texture("mines_drill_%d" % (int(age * (24.0 if state != Phase.BURST else 14.0)) % 2))
	match state:
		Phase.BURST:
			p += vel * delta
			vel *= exp(-3.0 * delta)
			if absf(vel.y) < 26.0:
				state = Phase.AIM
				timer = AIM_TIME
				dash_dir = (player_pos() - p).normalized()
				if dash_dir.x > -0.35:
					dash_dir = Vector2(-0.35, signf(dash_dir.y) if dash_dir.y != 0.0 else 1.0).normalized()
				_face(dash_dir)
				sfx("boss_hp_tick", -15.0, 0.1)
		Phase.AIM:
			p.y += sin(age * 9.0) * 6.0 * delta
			p.x -= 6.0 * delta
			timer -= delta
			if timer <= 0.0:
				state = Phase.DASH
				for k: int in [-1, 0, 1]:
					shoot_aimed_from(p + dash_dir * 10.0, 150.0, bullet_a(), float(k) * 0.2)
				vel = dash_dir * DASH_SPEED
				sfx("missile", -12.0)
		Phase.DASH:
			p += vel * delta
	enemy.global_position = p


# The sprite faces left; rotate it in 45-degree steps toward a direction.
func _face(d: Vector2) -> void:
	var ang: float = d.angle() - PI
	sprite().rotation = roundf(ang / (PI * 0.25)) * PI * 0.25


func draw() -> void:
	if state == Phase.AIM:
		var k: float = 1.0 - timer / AIM_TIME
		var a: float = 0.25 + 0.35 * k * (0.5 + 0.5 * sin(age * 40.0))
		var col: Color = Color(1.0, 0.75, 0.2, a)
		var step: float = 9.0
		var dist: float = 12.0 + fposmod(age * 60.0, step)
		while dist < 420.0:
			var q: Vector2 = dash_dir * dist
			var g: Vector2 = enemy.global_position + q
			if g.x < 0.0 or g.y < 28.0 or g.y > 258.0:
				break
			enemy.draw_line(q, q + dash_dir * 4.0, col, 1.0)
			dist += step
		draw_glint(dash_dir * 10.0, timer, AIM_TIME, Color(1.0, 0.7, 0.2))


# Cracks spreading from the burrow point, a pulsing glow and grit spitting out.
func draw_warning() -> void:
	var k: float = clampf(1.0 - warn_timer / WARN, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(age * 28.0)
	var out: float = dir   # grit flies away from the wall
	enemy.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	enemy.draw_circle(Vector2.ZERO, lerpf(4.0, 11.0, k), Color(1.0, 0.6, 0.15, 0.22 + 0.25 * pulse))
	enemy.draw_circle(Vector2.ZERO, lerpf(1.5, 5.0, k), Color(1.0, 0.9, 0.5, 0.75))
	enemy.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var crack_col: Color = Color(1.0, 0.7, 0.25, 0.5 + 0.4 * k)
	for c: int in range(5):
		var ang: float = float(c) * 0.62 - 1.24
		var len: float = (4.0 + float(c % 3) * 3.0) * k
		var a0: Vector2 = Vector2(sin(ang) * 2.0, 0.0)
		var a1: Vector2 = Vector2(sin(ang) * (2.0 + len), -out * absf(cos(ang)) * len * 0.3)
		enemy.draw_line(a0, a1, crack_col, 1.0)
	for i: int in range(4):
		var t: float = fposmod(age * 2.6 + float(i) * 0.27, 1.0)
		var gx: float = (float(i) - 1.5) * 4.0 + sin(float(i) * 2.1) * 3.0
		var gy: float = out * (t * 18.0 - t * t * 14.0) * (0.5 + k)
		enemy.draw_rect(Rect2(gx, gy, 1.0, 1.0), Color(0.8, 0.65, 0.45, 0.9 * (1.0 - t)))


func on_death() -> void:
	sparks(enemy.global_position, Color("#f2b630"), 8)
