extends "res://scripts/stages/stage_boss.gd"

# BOG BEHEMOTH: a hulking mud-and-moss mound with dead trees on its back and a gaping toxic maw.
# Three patterns, switching every 4 attacks; each phase adds shots and rate_mult shortens the
# cooldowns.
#   0 ACID STREAM  acid gathers in the maw (a glowing ball) while a dotted arc in front of it
#                  shows the sweep; then a stream of acid sprays out along that arc, sweeping the
#                  other way every time. Phase 2 adds a second, crossing stream of seeds; phase 3
#                  a third, faster one through the middle.
#   1 GAS BELCH    the throat swells (rings tighten on the maw), then it belches a fan of slow,
#                  lingering gas clouds; from phase 2 a ring of acid drops follows each belch
#   2 ROT RAIN     the dead trees on its back shake and fling rotten pods high over the bog; a
#                  marker on the bog shows where each will land (one under the player), and each
#                  pod splashes into a fan of droplets there
#
# Timed sprays use the bullets' slow_timer: a shot with slow_factor 0 waits at the maw until its
# timer runs out, so one attack() can release a stream over time.

const MAW: Vector2 = Vector2(-34.0, 23.0)
const TREES: Array[Vector2] = [Vector2(-3.0, -68.0), Vector2(29.0, -72.0), Vector2(55.0, -49.0)]
const GATHER: float = 0.45
const SWEEP: float = 0.62
const FLOOR: float = 247.0
const POD_G: float = 230.0

var sweep_from: float = PI
var sweep_to: float = PI
var sweep_at: float = -9.0
var sweep_dir: float = 1.0
var belch_at: float = -9.0
var marks: PackedVector3Array = PackedVector3Array()   # x, land time (age), unused


func attack(rate_mult: float, spd_bonus: float) -> void:
	match pattern:
		0:
			_acid_stream(spd_bonus)
			wait(1.2 * rate_mult)
		1:
			_belch(spd_bonus)
			wait(1.0 * rate_mult)
		_:
			_rot_rain()
			wait(1.0 * rate_mult)


func _held(origin: Vector2, vel: Vector2, tex: String, hold: float, r: float = 2.5) -> GameBullet:
	var b: GameBullet = emit_bullet(origin, vel, tex, r)
	if b != null and hold > 0.0:
		b.slow_timer = hold
		b.slow_factor = 0.0
	return b


func _acid_stream(spd_bonus: float) -> void:
	var origin: Vector2 = pos() + MAW
	var centre: float = (player_pos() - origin).angle()
	sweep_dir = -sweep_dir
	sweep_from = centre - SWEEP * sweep_dir
	sweep_to = centre + SWEEP * sweep_dir
	sweep_at = age
	var n: int = 10 + phase * 2
	var spd: float = 118.0 + spd_bonus * 0.75
	for i: int in range(n):
		var u: float = float(i) / float(n - 1)
		var a: float = lerpf(sweep_from, sweep_to, u)
		_held(origin, Vector2.from_angle(a) * spd, bullet_b(), GATHER + u * 0.55, 3.0)
	if phase >= 2:
		# A crossing stream of seeds, sweeping the opposite way a little later.
		for j: int in range(n - 3):
			var u2: float = float(j) / float(n - 4)
			var a2: float = lerpf(sweep_to, sweep_from, u2)
			_held(origin + Vector2(2.0, 3.0), Vector2.from_angle(a2) * (spd * 0.9), "swamp_seed", GATHER + 0.2 + u2 * 0.55)
	if phase >= 3:
		for k: int in range(5):
			_held(origin, Vector2.from_angle(centre + (float(k) - 2.0) * 0.07) * (spd + 40.0), bullet_a(), GATHER + 0.3 + float(k) * 0.06)
	RetroSfx.play("boss_hp_tick", -11.0, 0.1)


func _belch(spd_bonus: float) -> void:
	var origin: Vector2 = pos() + MAW
	var centre: float = (player_pos() - origin).angle()
	var n: int = 4 + phase
	for i: int in range(n):
		var a: float = centre + (float(i) - float(n - 1) * 0.5) * (0.95 / float(n - 1)) + randf_range(-0.05, 0.05)
		var sp: float = randf_range(46.0, 66.0) + spd_bonus * 0.2
		var b: GameBullet = emit_bullet(origin, Vector2.from_angle(a) * sp, "swamp_gas_0", 5.0)
		if b != null:
			b.life_left = randf_range(3.0, 3.6)
			b.anim_tex_b = "swamp_gas_1"
	if phase >= 2:
		var ring: int = 8 + phase * 2
		var rot: float = randf() * TAU
		for k: int in range(ring):
			var v: Vector2 = Vector2.from_angle(rot + TAU * float(k) / float(ring)) * (96.0 + spd_bonus * 0.6)
			if v.x < 30.0:
				_held(origin, v, "swamp_drop", 0.25)
	belch_at = age
	RetroSfx.play("explode", -13.0, 0.12)


func _rot_rain() -> void:
	var n: int = 2 + phase
	var targets: PackedFloat32Array = PackedFloat32Array()
	targets.append(clampf(player_pos().x + randf_range(-10.0, 10.0), 24.0, 340.0))
	var lane: float = 310.0 / float(n)
	for i: int in range(n - 1):
		var x: float = 26.0 + lane * (float(i) + randf_range(0.15, 0.85))
		if absf(x - targets[0]) < 22.0:
			x += 30.0
		targets.append(x)
	for t: int in range(targets.size()):
		var top: Vector2 = pos() + TREES[t % TREES.size()]
		var hold: float = float(t) * 0.12
		var flight: float = randf_range(1.35, 1.7)
		var dx: float = targets[t] - top.x
		var dy: float = FLOOR - top.y
		var v: Vector2 = Vector2(dx / flight, (dy - 0.5 * POD_G * flight * flight) / flight)
		var b: GameBullet = _held(top, v, "swamp_pod", hold, 3.5)
		if b != null:
			b.gravity_pull = POD_G
			b.floor_burst = 3 + (1 if phase >= 3 else 0)
			b.burst_tex = "swamp_drop"
			b.burst_speed = 96.0
		marks.append(Vector3(targets[t], age + hold + flight, 0.0))
	RetroSfx.play("missile", -12.0, 0.1)


func draw() -> void:
	var maw: Vector2 = MAW
	# Acid stream: the sweep arc and the acid gathering in the maw.
	var since: float = age - sweep_at
	if since >= 0.0 and since < GATHER + 0.6:
		var k: float = clampf(since / GATHER, 0.0, 1.0)
		if since < GATHER + 0.2:
			var segs: int = 14
			for i: int in range(segs + 1):
				var u: float = float(i) / float(segs)
				var a: float = lerpf(sweep_from, sweep_to, u)
				var r: float = 30.0 + 10.0 * u
				var q: Vector2 = maw + Vector2.from_angle(a) * r
				var al: float = (0.2 + 0.45 * k) * (0.5 + 0.5 * u)
				boss.draw_rect(Rect2(q.floor(), Vector2(2.0, 2.0) if i == segs else Vector2.ONE), Color(0.8, 1.0, 0.35, al))
		var pulse: float = 0.5 + 0.5 * sin(age * 30.0)
		boss.draw_circle(maw + Vector2(-4.0, 0.0), 3.0 + 4.0 * k, Color(0.6, 1.0, 0.25, 0.18 + 0.2 * pulse))
	# Gas belch: rings tightening on the maw before the next belch.
	if pattern == 1 and boss._fire_timer > 0.0 and boss._fire_timer < 0.5:
		var k2: float = 1.0 - boss._fire_timer / 0.5
		boss.draw_arc(maw, lerpf(22.0, 8.0, k2), 0.0, TAU, 18, Color(0.75, 1.0, 0.35, 0.2 + 0.4 * k2), 1.0)
		boss.draw_arc(maw, lerpf(30.0, 14.0, k2), 0.0, TAU, 18, Color(0.75, 1.0, 0.35, 0.1 + 0.25 * k2), 1.0)
	# Rot rain: the trees shake before they throw (dust motes off the tops), landing markers.
	if pattern == 2 and boss._fire_timer > 0.0 and boss._fire_timer < 0.45:
		for tr: Vector2 in TREES:
			var j: float = sin(age * 50.0 + tr.x) * 2.0
			boss.draw_rect(Rect2(tr + Vector2(j - 1.0, -6.0), Vector2(2.0, 2.0)), Color(0.75, 1.0, 0.35, 0.55))
			boss.draw_rect(Rect2(tr + Vector2(-j + 2.0, -10.0 - absf(j)), Vector2(1.0, 1.0)), Color(0.85, 1.0, 0.5, 0.45))
	if not marks.is_empty():
		var keep: PackedVector3Array = PackedVector3Array()
		for m: Vector3 in marks:
			var left: float = m.y - age
			if left < -0.1:
				continue
			keep.append(m)
			var l: Vector2 = Vector2(m.x, FLOOR + 2.0) - pos()
			var u2: float = clampf(1.0 - left / 1.7, 0.0, 1.0)
			var w: float = lerpf(12.0, 4.0, u2)
			var c: Color = Color(1.0, 0.5, 0.85, 0.3 + 0.5 * u2)
			boss.draw_line(l + Vector2(-w, -w * 0.4), l + Vector2(w, w * 0.4), c, 1.0)
			boss.draw_line(l + Vector2(-w, w * 0.4), l + Vector2(w, -w * 0.4), c, 1.0)
			boss.draw_rect(Rect2(l.floor() - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(1.0, 0.9, 0.95, 0.4 + 0.5 * u2))
		marks = keep
