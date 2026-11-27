extends "res://scripts/stages/stage_enemy.gd"

# SPITTER: a carnivorous pod on a vine, rooted in the bog (variant 0) or hanging from the dead
# canopy (variant 1), riding the scroll. The vine grows out first, then the head sways and turns
# to track the player. Before it attacks its jaws open and tremble and its throat glows (OPEN
# seconds; a short dotted aim line in the last moment): then it spits an aimed stream of acid
# seeds, and a moment later a wide fan of slow pollen. No homing.

enum Phase { GROW, IDLE, STREAM, FAN }

const SCROLL: float = 56.0
const OPEN: float = 0.8
const GROW_TIME: float = 0.7
const STREAM_N: int = 3
const FAN_N: int = 6

var state: Phase = Phase.GROW
var timer: float = 0.0
var anchor: Vector2 = Vector2.ZERO
var head_y: float = 120.0
var aim: Vector2 = Vector2.LEFT
var shots_left: int = 0


func setup() -> void:
	var hang: bool = variant == 1
	anchor = Vector2(enemy.global_position.x, 22.0 if hang else 258.0)
	head_y = randf_range(64.0, 104.0) if hang else randf_range(172.0, 208.0)
	enemy.global_position.y = anchor.y + (8.0 if hang else -8.0)
	base_y = head_y
	timer = GROW_TIME
	fire_timer = randf_range(0.9, 1.4) + phase * 0.3


func tick(delta: float) -> void:
	anchor.x -= SCROLL * delta
	var p: Vector2 = enemy.global_position
	var sway: Vector2 = Vector2(sin(age * 1.4 + phase) * 4.0, sin(age * 1.9 + phase) * 6.0)
	if state == Phase.GROW:
		timer -= delta
		var u: float = 1.0 - clampf(timer / GROW_TIME, 0.0, 1.0)
		var start_y: float = anchor.y + (8.0 if variant == 1 else -8.0)
		p = Vector2(anchor.x, lerpf(start_y, head_y, u * u * (3.0 - 2.0 * u)))
		if timer <= 0.0:
			state = Phase.IDLE
	else:
		p = Vector2(anchor.x, head_y) + sway
	# Track the player (turned in steps, so the pixel art stays clean).
	var want: Vector2 = (player_pos() - p).normalized()
	if want.x > -0.2:
		want = Vector2(-0.2, signf(want.y) if want.y != 0.0 else 1.0).normalized()
	aim = aim.slerp(want, clampf(delta * 3.0, 0.0, 1.0))
	var rot: float = clampf(angle_difference(PI, aim.angle()), -1.2, 1.2)
	sprite().rotation = roundf(rot / (PI / 12.0)) * (PI / 12.0)
	var jitter: Vector2 = Vector2.ZERO
	match state:
		Phase.IDLE:
			fire_timer -= delta
			var frame: int = 0
			if fire_timer < OPEN:
				frame = 1 if fire_timer > OPEN * 0.5 else 2
				jitter = Vector2(sin(age * 57.0), cos(age * 49.0)) * 0.6
			set_texture("swamp_spitter_%d" % frame)
			if fire_timer <= 0.0:
				if on_screen(70.0, 455.0):
					state = Phase.STREAM
					shots_left = STREAM_N
					timer = 0.0
				else:
					fire_timer = OPEN
		Phase.STREAM:
			set_texture("swamp_spitter_2")
			timer -= delta
			if timer <= 0.0:
				shoot_aimed_from(_mouth(p), 150.0, "swamp_seed", 0.0)
				shots_left -= 1
				timer = 0.09
				if shots_left <= 0:
					state = Phase.FAN
					timer = 0.38
				sfx("laser", -18.0, 0.15)
		Phase.FAN:
			set_texture("swamp_spitter_2")
			timer -= delta
			if timer <= 0.0:
				var base_a: float = aim.angle()
				for k: int in range(FAN_N):
					var a: float = base_a + (float(k) - float(FAN_N - 1) * 0.5) * 0.24
					emit_bullet(_mouth(p), Vector2.from_angle(a) * 74.0, "swamp_pollen", false, 2.5)
				state = Phase.IDLE
				fire_timer = fire_cd(3.7)
				sfx("missile", -17.0, 0.1)
	enemy.global_position = p + jitter


func _mouth(p: Vector2) -> Vector2:
	return p + aim * 8.0


func draw() -> void:
	# The vine, from the back of the head to its root, with a couple of leaves.
	var back: Vector2 = -aim * 7.0
	var root: Vector2 = anchor - enemy.global_position
	var prev: Vector2 = back
	var n: int = 5
	for i: int in range(1, n + 1):
		var u: float = float(i) / float(n)
		var q: Vector2 = back.lerp(root, u)
		q.x += sin(u * PI) * (6.0 + 2.0 * sin(age * 1.3 + phase)) * (1.0 if variant == 0 else -1.0)
		enemy.draw_line(prev, q, Color("#16200c"), 3.0)
		enemy.draw_line(prev, q, Color("#2a3c16"), 1.0)
		if i == 2 or i == 4:
			var side: float = -1.0 if i == 2 else 1.0
			enemy.draw_rect(Rect2(q + Vector2(side * 2.0 - 1.0, -1.0), Vector2(3.0, 2.0)), Color("#2e4418"))
		prev = q
	if state == Phase.IDLE and fire_timer < OPEN:
		var m: Vector2 = aim * 8.0
		draw_glint(m, fire_timer, OPEN, Color(0.75, 1.0, 0.3))
		if fire_timer < 0.3:
			var a: float = 0.15 + 0.3 * (1.0 - fire_timer / 0.3)
			var d: float = 12.0
			while d < 110.0:
				var q2: Vector2 = aim * d
				enemy.draw_rect(Rect2(q2.floor(), Vector2.ONE), Color(1.0, 0.55, 0.85, a))
				d += 6.0


func on_death() -> void:
	sparks(enemy.global_position, Color("#c23c8e"), 6)
	sparks(enemy.global_position, Color("#86d41c"), 4)
