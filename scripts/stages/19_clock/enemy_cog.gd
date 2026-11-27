extends "res://scripts/stages/stage_enemy.gd"

# COG DRONE: a spiked brass cog with a teal lens in its hub, rolling along the floor (variant 0)
# or the ceiling (variant 1). When it picks its moment it brakes and spins up, glowing hot and
# throwing sparks off the deck (SPIN seconds: the telegraph), then hops off the deck toward the
# player's height and, at the top of the hop, fires a ring of rivets. It lands, rolls on and
# hops again, HOPS times in all.

enum Phase { ROLL, SPIN, HOP }

const FLOOR_Y: float = 249.0
const CEIL_Y: float = 37.0
const ROLL_SPEED: float = 64.0
const SPIN: float = 0.55
const GRAVITY: float = 430.0
const HOPS: int = 2
const RING: int = 6
const FRAME_DIST: float = 3.5   # px rolled per frame step (22.5 degrees at r 9)

var state: Phase = Phase.ROLL
var timer: float = 0.0
var dist: float = 0.0
var side: float = 1.0           # +1 floor (falls down), -1 ceiling (falls up)
var deck_y: float = FLOOR_Y
var hops_left: int = HOPS
var fired: bool = false
var spark_t: float = 0.0


func setup() -> void:
	side = -1.0 if variant == 1 else 1.0
	deck_y = CEIL_Y if variant == 1 else FLOOR_Y
	enemy.global_position.y = deck_y
	base_y = deck_y
	timer = randf_range(0.5, 1.0) + phase * 0.3
	dist = randf() * 20.0


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		Phase.ROLL:
			p.x -= ROLL_SPEED * delta
			dist += ROLL_SPEED * delta
			timer -= delta
			if timer <= 0.0 and hops_left > 0 and on_screen(130.0, 440.0):
				state = Phase.SPIN
				timer = SPIN
				sfx("boss_hp_tick", -15.0, 0.25)
		Phase.SPIN:
			p.x -= 14.0 * delta
			dist += 300.0 * delta
			timer -= delta
			spark_t -= delta
			if spark_t <= 0.0:
				spark_t = 0.07
				sparks(p + Vector2(randf_range(-4.0, 4.0), 8.0 * side), Color("#ffd070"), 1)
			if timer <= 0.0:
				state = Phase.HOP
				fired = false
				var rise: float = clampf(absf(player_pos().y - deck_y), 60.0, 150.0)
				vel = Vector2(-48.0, -side * sqrt(2.0 * GRAVITY * rise))
				sfx("missile", -16.0, 0.15)
		Phase.HOP:
			vel = Vector2(vel.x, vel.y + GRAVITY * side * delta)
			p += vel * delta
			dist += 160.0 * delta
			if not fired and vel.y * side >= 0.0:
				fired = true
				_ring(p)
			if fired and (p.y - deck_y) * side >= 0.0:
				p.y = deck_y
				state = Phase.ROLL
				hops_left -= 1
				timer = fire_cd(1.5)
				sparks(p + Vector2(0.0, 8.0 * side), Color("#ffd070"), 4)
	enemy.global_position = p
	var step: int = int(dist / FRAME_DIST) % 4
	if side > 0.0:
		step = 3 - step   # rolling left on the floor turns counter-clockwise
	var hot: bool = state == Phase.SPIN or (state == Phase.HOP and not fired)
	set_texture("clock_cog_%d" % (step + (4 if hot else 0)))


func _ring(p: Vector2) -> void:
	var rot: float = randf() * TAU
	for i: int in range(RING):
		emit_bullet(p, Vector2.from_angle(rot + TAU * float(i) / float(RING)) * 82.0, "clock_rivet", false, 2.5)
	if hops_left == HOPS:
		shoot_aimed(120.0, bullet_b())
	sfx("laser", -15.0, 0.1)


func draw() -> void:
	if state == Phase.SPIN:
		var k: float = 1.0 - timer / SPIN
		# Speed arcs whirling around the cog and the hub lens charging.
		var a0: float = -age * 24.0 * side
		for i: int in range(2):
			enemy.draw_arc(Vector2.ZERO, 11.0 + k * 2.0, a0 + PI * float(i), a0 + PI * float(i) + 1.1, 6, Color(1.0, 0.85, 0.45, 0.35 + 0.4 * k), 1.0)
		draw_glint(Vector2.ZERO, timer, SPIN, Color(0.4, 1.0, 0.85))


func on_death() -> void:
	sparks(enemy.global_position, Color("#e8c060"), 7)
