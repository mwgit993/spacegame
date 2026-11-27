extends "res://scripts/stages/stage_enemy.gd"

# The amber echo of a time-echo ship (a child: no Scrap, capped by Echo.ECHO_CAP). It replays the
# original's recorded flight a moment late: the same path and the very same shots (amber,
# aimed where the ship was), with afterimages trailing it. Ahead of it runs the rest of its
# timeline, a faint amber dotted line, and a ring tightens on each spot where a shot will
# repeat (the telegraph). If the original was destroyed, the echo fades out where its timeline
# ends. Spawned without a recording (or straight from the wave director) it drifts in and fires
# aimed amber pairs on its own.

const Echo = preload("enemy_echo.gd")

const LOOKAHEAD: float = 1.3
const SHOT_WARN: float = 0.55
const FADE: float = 0.45

var rec: RefCounted = null
var started: bool = false
var t: float = 0.0
var next_shot: int = 0
var end_v: Vector2 = Vector2(-120.0, 0.0)
var fading: float = -1.0
var trail: PackedVector2Array = PackedVector2Array()
var trail_t: float = 0.0


func setup() -> void:
	sprite().modulate = Color(1.0, 1.0, 1.0, 0.8)
	fire_timer = 1.0


func tick(delta: float) -> void:
	if not started:
		started = true
		if gen > 0:
			var token: int = int(roundf(vel.x))
			if Echo.pending.has(token):
				rec = Echo.pending[token]
				Echo.pending.erase(token)
		vel = Vector2.ZERO
	var p: Vector2 = enemy.global_position
	if rec != null:
		_replay(delta)
	else:
		p.x -= (130.0 if p.x > 400.0 else 60.0) * delta
		p.y = base_y + sin(age * 2.2 + phase) * 22.0
		enemy.global_position = p
		fire_timer -= delta
		if fire_timer <= 0.0 and on_screen(110.0, 450.0):
			fire_timer = fire_cd(1.5)
			for k: float in [-0.08, 0.08]:
				shoot_aimed(Echo.SHOT_SPEED, bullet_b(), k)
	if fading >= 0.0:
		fading += delta
		sprite().modulate.a = 0.8 * (1.0 - fading / FADE)
		if fading >= FADE:
			sparks(enemy.global_position, Color("#ffb030"), 4)
			leave()
			return
	else:
		sprite().modulate.a = 0.62 + 0.18 * float(int(age * 20.0) % 2)
	set_texture("rift_ghost_1" if int(age * 8.0) % 2 == 0 else "rift_ghost_0")
	trail_t -= delta
	if trail_t <= 0.0:
		trail_t = 0.07
		trail.insert(0, enemy.global_position)
		if trail.size() > 3:
			trail.resize(3)


func _replay(delta: float) -> void:
	t += delta
	var r: Echo.Record = rec as Echo.Record
	var n: int = r.times.size()
	var last_t: float = r.times[n - 1]
	if t <= last_t:
		var p: Vector2 = r.sample(t)
		if n >= 2:
			end_v = (r.pts[n - 1] - r.pts[maxi(0, n - 3)]) / maxf(0.01, r.times[n - 1] - r.times[maxi(0, n - 3)])
		enemy.global_position = p
	else:
		enemy.global_position += end_v * delta
		if not r.open and fading < 0.0:
			fading = 0.0
	while next_shot < r.shot_t.size() and r.shot_t[next_shot] <= t:
		if fading < 0.0:
			emit_bullet(r.shot_pos[next_shot], r.shot_vel[next_shot], bullet_b())
		next_shot += 1
		sfx("laser", -19.0, 0.08)


func draw() -> void:
	var here: Vector2 = enemy.global_position
	var tx: Texture2D = PixelArt.tex("rift_ghost_0")
	var half: Vector2 = (tx.get_size() * 0.5).round()
	for i: int in range(trail.size()):
		enemy.draw_texture(tx, trail[i] - here - half, Color(1.0, 0.9, 0.6, 0.14 - 0.04 * float(i)))
	if rec == null or fading >= 0.0:
		return
	var r: Echo.Record = rec as Echo.Record
	# the rest of its timeline, ahead of it
	var segs: PackedVector2Array = PackedVector2Array()
	var steps: int = 12
	var prev: Vector2 = Vector2.ZERO
	for s: int in range(1, steps + 1):
		var tt: float = t + LOOKAHEAD * float(s) / float(steps)
		if tt > r.times[r.times.size() - 1]:
			break
		var q: Vector2 = (r.sample(tt) - here).floor() + Vector2(0.5, 0.5)
		if (s + int(age * 10.0)) % 2 == 0:
			segs.append(prev)
			segs.append(q)
		prev = q
	if not segs.is_empty():
		enemy.draw_multiline(segs, Color(1.0, 0.7, 0.25, 0.3), 1.0)
	# rings tightening on the spots where shots are about to repeat
	for j: int in range(next_shot, r.shot_t.size(), 2):
		var dt: float = r.shot_t[j] - t
		if dt > SHOT_WARN:
			break
		var k: float = 1.0 - clampf(dt / SHOT_WARN, 0.0, 1.0)
		var sp: Vector2 = r.shot_pos[j] - here
		enemy.draw_arc(sp, 7.0 - 4.5 * k, 0.0, TAU, 10, Color(1.0, 0.75, 0.3, 0.3 + 0.5 * k), 1.0)
		var dir: Vector2 = r.shot_vel[j].normalized()
		enemy.draw_line(sp, sp + dir * (10.0 + 14.0 * k), Color(1.0, 0.75, 0.3, 0.25 + 0.3 * k), 1.0)
	draw_hp_bar(18.0, -12.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#ffb030"), 8)
