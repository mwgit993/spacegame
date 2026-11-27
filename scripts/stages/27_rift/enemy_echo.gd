extends "res://scripts/stages/stage_enemy.gd"

# Time-echo ship: dives in, swings toward the ship's row and fires aimed pairs, and every moment
# of it is recorded. ECHO_DELAY seconds after it appears (variant 1: twice, a beat apart) an
# amber echo of it (a capped child, enemy_ghost.gd) starts replaying the recording: the same
# path and the very same shots, aimed where the ship WAS. Until its echo exists the ship trails
# a faint amber line, its timeline, with a tick wherever a shot was fired: exactly where the
# echo will fly and fire. Shoot the ship down before its echo appears and the echo never
# happens; after that the past can't be undone.

const ECHO_DELAY: float = 1.0
const SAMPLE: float = 0.05
const SHOT_SPEED: float = 142.0
const ECHO_CAP: int = 8


# One recorded flight, shared with the echo(es) replaying it.
class Record extends RefCounted:
	var times: PackedFloat32Array = PackedFloat32Array()
	var pts: PackedVector2Array = PackedVector2Array()
	var shot_t: PackedFloat32Array = PackedFloat32Array()
	var shot_pos: PackedVector2Array = PackedVector2Array()
	var shot_vel: PackedVector2Array = PackedVector2Array()
	var open: bool = true   # the original is still alive and recording

	func sample(t: float) -> Vector2:
		var n: int = times.size()
		if n == 0:
			return Vector2.ZERO
		if t <= times[0]:
			return pts[0]
		if t >= times[n - 1]:
			return pts[n - 1]
		var lo: int = 0
		var hi: int = n - 1
		while hi - lo > 1:
			var mid: int = (lo + hi) / 2
			if times[mid] <= t:
				lo = mid
			else:
				hi = mid
		var k: float = (t - times[lo]) / maxf(0.0001, times[hi] - times[lo])
		return pts[lo].lerp(pts[hi], k)


# Echo children pick up their recording by token (it rides in the spawn's launch velocity).
static var pending: Dictionary = {}
static var _next_token: int = 1

var rec: Record = Record.new()
var sample_t: float = 0.0
var echoes_left: int = 1
var next_echo: float = ECHO_DELAY
var swing: bool = false
var flame: float = 0.0


static func count_ghosts(from: GameEnemy) -> int:
	var n: int = 0
	for node: Node in from.get_tree().get_nodes_in_group("enemies"):
		var ge: GameEnemy = node as GameEnemy
		if ge != null and ge.module_kind == "ghost" and not ge._dead:
			n += 1
	return n


func setup() -> void:
	echoes_left = 2 if variant == 1 else 1
	fire_timer = 0.75
	rec.times.append(0.0)
	rec.pts.append(enemy.global_position)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	if age < 5.6:
		if p.x > 410.0 and not swing:
			p.x -= 170.0 * delta
		else:
			swing = true
			p.x -= 62.0 * delta
			var want: float = clampf(player_pos().y, 44.0, 226.0)
			p.y = move_toward(p.y, want, 58.0 * delta)
		p.y += sin(age * 3.1 + phase) * 14.0 * delta
	else:
		p.x -= 175.0 * delta
		p.y += (8.0 if p.y < 135.0 else -8.0) * delta
	enemy.global_position = p
	flame -= delta
	set_texture("rift_echo_1" if flame > 0.0 or p.x > 410.0 else "rift_echo_0")

	fire_timer -= delta
	if fire_timer <= 0.0 and on_screen(110.0, 450.0) and age < 5.6:
		fire_timer = fire_cd(1.06)
		var aim: float = (player_pos() - p).angle()
		for k: float in [-0.08, 0.08]:
			var v: Vector2 = Vector2.from_angle(aim + k) * SHOT_SPEED
			emit_bullet(p + Vector2(-10.0, 0.0), v, bullet_a())
			rec.shot_t.append(age)
			rec.shot_pos.append(p + Vector2(-10.0, 0.0))
			rec.shot_vel.append(v)
		flame = 0.15
		sfx("laser", -17.0, 0.08)

	sample_t -= delta
	if sample_t <= 0.0:
		sample_t = SAMPLE
		rec.times.append(age)
		rec.pts.append(p)

	if echoes_left > 0 and age >= next_echo:
		echoes_left -= 1
		next_echo += 0.9
		if count_ghosts(enemy) < ECHO_CAP:
			if pending.size() > 32:
				pending.clear()
			var token: int = _next_token
			_next_token += 1
			pending[token] = rec
			spawn_child("ghost", rec.pts[0], Vector2(float(token), 0.0))
			sfx("boss_hp_tick", -15.0, 0.0)


func draw() -> void:
	if echoes_left <= 0 and age > next_echo - 0.9 + 0.3:
		return
	# the timeline being recorded: where the echo will fly, with ticks where it will fire
	var here: Vector2 = enemy.global_position
	var n: int = rec.pts.size()
	var segs: PackedVector2Array = PackedVector2Array()
	var step: int = 2
	var i: int = n - 1
	while i - step >= 0:
		if rec.times[i] < age - 2.2:
			break
		if (i / step + int(age * 10.0)) % 2 == 0:
			segs.append((rec.pts[i] - here).floor() + Vector2(0.5, 0.5))
			segs.append((rec.pts[i - step] - here).floor() + Vector2(0.5, 0.5))
		i -= step
	if not segs.is_empty():
		enemy.draw_multiline(segs, Color(1.0, 0.7, 0.25, 0.32), 1.0)
	for s: int in range(0, rec.shot_t.size(), 2):
		if rec.shot_t[s] < age - 2.4:
			continue
		var sp: Vector2 = rec.shot_pos[s] - here
		enemy.draw_arc(sp, 2.5, 0.0, TAU, 8, Color(1.0, 0.72, 0.3, 0.5), 1.0)
	draw_glint(Vector2(-11.0, 0.0), fire_timer, 0.3, Color(0.3, 0.9, 1.0))
	draw_hp_bar(20.0, -12.0)


func on_death() -> void:
	rec.open = false
	sparks(enemy.global_position, Color("#3ce8ff"), 8)
	sparks(enemy.global_position, Color("#ffb030"), 4)
