extends "res://scripts/stages/stage_enemy.gd"

# Police cruiser: hovers at the right edge with its siren flashing and sweeps a searchlight
# cone up and down. If the ship is caught in the cone the beam turns red and locks on (the
# telegraph: LOCK_TIME), then it fires a burst down the beam. If it can't find you for a while
# it fires a warning burst down the beam anyway. After BURSTS bursts it peels away.

enum S { ENTER, SWEEP, LOCK, LEAVE }

const LAMP: Vector2 = Vector2(-14.0, 2.0)
const CONE_LEN: float = 430.0
const CONE_HALF: float = 0.1
const LOCK_TIME: float = 0.5
const BURSTS: int = 4
const SHOTS: int = 5

var state: S = S.ENTER
var timer: float = 0.0
var target_x: float = 410.0
var beam: float = PI
var sweep_dir: float = 1.0
var lock_angle: float = PI
var bursts_left: int = BURSTS
var burst_left: int = 0
var burst_t: float = 0.0
var no_find: float = 0.0


func setup() -> void:
	target_x = randf_range(380.0, 430.0)
	beam = PI - 0.45 if variant == 0 else PI + 0.45
	sweep_dir = 1.0 if variant == 0 else -1.0


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		S.ENTER, S.SWEEP:
			p.x = lerpf(p.x, target_x, clampf(2.0 * delta, 0.0, 1.0))
			p.y = base_y + sin(age * 1.3 + phase) * 12.0
			if state == S.ENTER and absf(p.x - target_x) < 20.0:
				state = S.SWEEP
			# sweep the beam between straight-ish up-left and down-left
			beam += sweep_dir * 0.75 * delta
			if beam > PI + 0.62:
				sweep_dir = -1.0
			elif beam < PI - 0.62:
				sweep_dir = 1.0
			if state == S.SWEEP:
				no_find += delta
				var to: Vector2 = player_pos() - (p + LAMP)
				var caught: bool = to.length() < CONE_LEN and absf(angle_difference(beam, to.angle())) < CONE_HALF
				if (caught or no_find > 2.4) and on_screen(120.0, 450.0):
					state = S.LOCK
					timer = LOCK_TIME
					lock_angle = to.angle() if caught else beam
					no_find = 0.0
					sfx("boss_siren", -18.0, 0.05)
		S.LOCK:
			timer -= delta
			beam = lerp_angle(beam, lock_angle, clampf(10.0 * delta, 0.0, 1.0))
			if timer <= 0.0 and burst_left == 0:
				burst_left = SHOTS
				burst_t = 0.0
		S.LEAVE:
			p += Vector2(90.0, -70.0 if base_y < 135.0 else 70.0) * delta
	if burst_left > 0:
		burst_t -= delta
		if burst_t <= 0.0:
			burst_t = 0.09
			burst_left -= 1
			emit_bullet(p + LAMP, Vector2.from_angle(lock_angle + randf_range(-0.05, 0.05)) * 165.0, bullet_b())
			sfx("laser", -16.0, 0.05)
			if burst_left == 0:
				bursts_left -= 1
				state = S.LEAVE if bursts_left <= 0 else S.SWEEP
	enemy.global_position = p
	set_texture("metro_police_0" if int(age * 6.0) % 2 == 0 else "metro_police_1")


func _cone_color() -> Color:
	if state == S.LOCK or burst_left > 0:
		return Color(1.0, 0.2, 0.25, 0.09 + 0.07 * float(int(age * 20.0) % 2))
	return Color(1.0, 0.95, 0.75, 0.07)


func draw() -> void:
	if state != S.ENTER and state != S.LEAVE:
		var a: Vector2 = Vector2.from_angle(beam - CONE_HALF) * CONE_LEN
		var b: Vector2 = Vector2.from_angle(beam + CONE_HALF) * CONE_LEN
		enemy.draw_colored_polygon(PackedVector2Array([LAMP, LAMP + a, LAMP + b]), _cone_color())
		enemy.draw_line(LAMP, LAMP + Vector2.from_angle(beam) * CONE_LEN, Color(1.0, 1.0, 0.9, 0.08), 1.0)
	enemy.draw_circle(LAMP, 1.5, Color(1.0, 1.0, 0.85, 0.9))
	# the light bar: red and blue taking turns
	var red_on: bool = int(age * 8.0) % 2 == 0
	enemy.draw_rect(Rect2(-1.0, -7.0, 2.0, 1.0), Color(1.0, 0.2, 0.2, 1.0 if red_on else 0.3))
	enemy.draw_rect(Rect2(1.0, -7.0, 2.0, 1.0), Color(0.25, 0.45, 1.0, 0.3 if red_on else 1.0))
	if red_on:
		enemy.draw_circle(Vector2(0.0, -7.0), 4.0, Color(1.0, 0.2, 0.2, 0.18))
	else:
		enemy.draw_circle(Vector2(2.0, -7.0), 4.0, Color(0.25, 0.45, 1.0, 0.18))
	draw_hp_bar(22.0, -12.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#3c78ff"), 6)
	sparks(enemy.global_position, Color("#ff3030"), 6)
