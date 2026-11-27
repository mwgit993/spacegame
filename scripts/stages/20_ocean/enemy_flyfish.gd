extends "res://scripts/stages/stage_enemy.gd"

# FLYING FISH: schools burst out of the swell. First a splash ring spreads on the water where
# each fish will leap (the entrance telegraph; hidden and unhittable meanwhile, staggered by the
# wave director's "phase"); then it leaps in a parabolic arc toward the player's height, glides
# with its wing-fins spread, and just before the top of the arc its eye flashes and it spits a
# pair of droplets at the player. It dives back in with a splash (no reward). variant 1 skips off the
# water once and makes a second, lower leap.

const WATER_Y: float = 238.0
const GRAVITY: float = 210.0
const WARN: float = 0.75
const GLINT: float = 0.22

var leaps_left: int = 1
var spat: bool = false
var splash_t: float = -1.0


func setup() -> void:
	enemy.global_position.y = WATER_Y + 4.0
	warn_timer = WARN + phase * 0.13
	leaps_left = 2 if variant == 1 else 1


func on_wake() -> void:
	_leap(1.0)
	sfx("bounce", -16.0, 0.2)


# Launch toward an apex near the player's height (higher for the first leap).
func _leap(scale: float) -> void:
	var p: Vector2 = enemy.global_position
	var apex_y: float = clampf(player_pos().y + randf_range(-26.0, 10.0), 70.0, 196.0)
	apex_y = lerpf(WATER_Y - 30.0, apex_y, scale)
	var h: float = maxf(24.0, p.y - apex_y)
	var vy: float = -sqrt(2.0 * GRAVITY * h)
	var t_up: float = -vy / GRAVITY
	# Cover a good stretch of screen during the leap, a bit faster for low hops.
	var vx: float = -clampf(150.0 / maxf(0.5, t_up), 85.0, 150.0)
	vel = Vector2(vx, vy)
	spat = false
	splash_t = 0.25
	leaps_left -= 1


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	vel.y += GRAVITY * delta
	p += vel * delta
	splash_t -= delta
	# Spit at the player just before the apex (the eye flashes for GLINT seconds first).
	if not spat and vel.y > -GRAVITY * 0.05 and on_screen(40.0, 470.0):
		spat = true
		shoot_aimed_from(p + Vector2(-6.0, 0.0), 140.0, "ocean_drop", -0.1)
		shoot_aimed_from(p + Vector2(-6.0, 0.0), 140.0, "ocean_drop", 0.1)
	# Fins: spread while gliding near the top, flapping on the way up, tucked when diving.
	var f: int = 0
	if vel.y < -110.0:
		f = 1 if int(age * 14.0) % 2 == 0 else 0
	elif vel.y > 120.0:
		f = 2
	set_texture("ocean_fish_%d" % f)
	sprite().rotation = clampf(atan2(vel.y, -vel.x) * -1.0, -0.9, 0.9)
	if p.y > WATER_Y + 3.0 and vel.y > 0.0:
		if leaps_left > 0:
			p.y = WATER_Y + 3.0
			enemy.global_position = p
			_leap(0.45)
			sfx("bounce", -18.0, 0.2)
			return
		sparks(Vector2(p.x, WATER_Y), Color("#c8f4ff"), 4)
		enemy.global_position = p
		leave()
		return
	enemy.global_position = p


func draw() -> void:
	# Eye flash just before it spits (time to the apex is -vel.y / GRAVITY).
	if not spat:
		var t_apex: float = -vel.y / GRAVITY
		if t_apex > 0.0 and t_apex < GLINT:
			draw_glint(Vector2(-6.0, -1.0).rotated(sprite().rotation), t_apex, GLINT, Color(0.55, 0.95, 1.0))
	# Spray trailing it out of the water.
	if splash_t > 0.0:
		var wy: float = WATER_Y - enemy.global_position.y
		for i: int in range(4):
			var u: float = 1.0 - splash_t / 0.25
			enemy.draw_rect(Rect2(float(i * 3 - 4), wy - u * 10.0 - float(i % 2) * 3.0, 1.0, 2.0), Color(0.8, 0.95, 1.0, 0.7 * (1.0 - u)))


# A splash ring spreading on the water where it will leap out, with spray jumping up.
func draw_warning() -> void:
	var total: float = WARN + phase * 0.13
	var k: float = clampf(1.0 - warn_timer / maxf(0.01, total), 0.0, 1.0)
	var wy: float = WATER_Y - enemy.global_position.y
	enemy.draw_set_transform(Vector2(0.0, wy), 0.0, Vector2(1.0, 0.28))
	for i: int in range(2):
		var r: float = fposmod(age * 14.0 + float(i) * 6.0, 12.0) * (0.5 + 0.7 * k)
		enemy.draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 16, Color(0.75, 0.95, 1.0, 0.55 * (1.0 - r / 16.0)), 1.0)
	enemy.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if k > 0.5:
		for j: int in range(3):
			var t: float = fposmod(age * 3.4 + float(j) * 0.3, 1.0)
			enemy.draw_rect(Rect2(float(j * 3 - 3), wy - (t * 9.0 - t * t * 7.0), 1.0, 1.0), Color(0.85, 0.97, 1.0, 0.85 * (1.0 - t)))


func on_death() -> void:
	sparks(enemy.global_position, Color("#9ccce8"), 5)
