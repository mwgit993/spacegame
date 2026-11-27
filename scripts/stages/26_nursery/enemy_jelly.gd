extends "res://scripts/stages/stage_enemy.gd"

# Cosmic jelly: a gas-bell riding one of the nebula's currents, a faint flowing line it
# follows across the screen (jellies of one group share the current: same "phase"). Every
# so often it pulses: PULSE_WARN of squeezing (bell contracts, its heart glows and the ring of
# motes it's about to throw shows faintly: the telegraph), then it throws the ring and surges
# forward on the push. The motes coast out and slow to a stop (OUT_T), hang for a beat
# (HANG_T), then the current takes them: they flow off to the left along the same wavy line,
# a drifting band rather than a ring. From its second pulse on it also spits a quick aimed
# pair from its heart. Variant 1 rides a steeper, faster current.

enum S { DRIFT, PULSE }

const PULSE_WARN: float = 0.55
const RING: int = 7
const PULSES: int = 3
const OUT_T: float = 0.45
const HANG_T: float = 0.5
const RAMP_T: float = 0.5
const MOTE_LIFE: float = 4.5
const THROW: float = 92.0
const FLOW: float = 78.0
const HEART: Vector2 = Vector2(-1.0, -9.0)

var state: S = S.DRIFT
var timer: float = 0.0
var amp: float = 26.0
var k: float = 0.022
var speed: float = 34.0
var surge: float = 0.0
var pulses_left: int = PULSES
var motes: Array[GameBullet] = []
var mote_age: PackedFloat32Array = PackedFloat32Array()
var mote_v0: PackedVector2Array = PackedVector2Array()


func setup() -> void:
	if variant == 1:
		amp = 40.0
		k = 0.03
		speed = 44.0
	fire_timer = 1.1


func _curve_y(x: float) -> float:
	return base_y + amp * sin(k * x + phase)


# The current's flow at x: leftward along the curve.
func _flow(x: float) -> Vector2:
	var slope: float = amp * k * cos(k * x + phase)
	return Vector2(-1.0, -slope).normalized() * FLOW * enemy._shot_mult


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	surge = maxf(0.0, surge - delta * 90.0)
	p.x -= (speed + surge + (40.0 if p.x > 460.0 else 0.0)) * delta
	p.y = clampf(_curve_y(p.x), 36.0, 240.0)
	enemy.global_position = p
	match state:
		S.DRIFT:
			set_texture("nursery_jelly_0")
			fire_timer -= delta
			if fire_timer <= 0.0 and pulses_left > 0 and on_screen(110.0, 450.0):
				pulses_left -= 1
				state = S.PULSE
				timer = PULSE_WARN
				sfx("boss_hp_tick", -17.0, 0.05)
		S.PULSE:
			timer -= delta
			set_texture("nursery_jelly_1" if timer < PULSE_WARN * 0.6 else "nursery_jelly_0")
			if timer <= 0.0:
				_throw(p)
				state = S.DRIFT
				fire_timer = fire_cd(3.0)
				surge = 70.0
	_steer_motes(delta)


func _throw(p: Vector2) -> void:
	var rot: float = randf() * TAU
	for i: int in range(RING):
		var v: Vector2 = Vector2.from_angle(rot + TAU * float(i) / float(RING)) * THROW
		var b: GameBullet = emit_bullet(p + HEART, v, "nursery_mote", false, 2.5)
		if b == null:
			continue
		b.life_left = MOTE_LIFE
		motes.append(b)
		mote_age.append(0.0)
		mote_v0.append(b.velocity)
	if pulses_left < PULSES - 1:
		for s: int in range(2):
			shoot_aimed_from(p + HEART, 150.0, bullet_a(), (float(s) - 0.5) * 0.1)
	sparks(p + HEART, Color("#7af0ea"), 6)
	sfx("bounce", -13.0, 0.08)


# Coast out, hang, then flow with the current.
func _steer_motes(delta: float) -> void:
	var i: int = 0
	while i < motes.size():
		var b: GameBullet = motes[i]
		if not is_instance_valid(b) or b.is_queued_for_deletion():
			motes.remove_at(i)
			mote_age.remove_at(i)
			mote_v0.remove_at(i)
			continue
		var t: float = mote_age[i] + delta
		mote_age[i] = t
		if t < OUT_T:
			b.velocity = mote_v0[i] * pow(1.0 - t / OUT_T, 1.5)
		elif t < OUT_T + HANG_T:
			b.velocity = _flow(b.global_position.x) * 0.06
		elif t < OUT_T + HANG_T + RAMP_T:
			b.velocity = _flow(b.global_position.x) * lerpf(0.06, 1.0, (t - OUT_T - HANG_T) / RAMP_T)
		else:
			b.velocity = _flow(b.global_position.x)
			if t > OUT_T + HANG_T + RAMP_T + 4.0:
				motes.remove_at(i)
				mote_age.remove_at(i)
				mote_v0.remove_at(i)
				continue
		i += 1


func draw() -> void:
	# the current it rides: faint dashes flowing left along the curve
	var p: Vector2 = enemy.global_position
	var segs: PackedVector2Array = PackedVector2Array()
	var x: float = p.x - 170.0 - fposmod(age * FLOW, 10.0)
	while x < p.x + 150.0:
		var y0: float = _curve_y(x) - p.y
		var y1: float = _curve_y(x + 4.0) - p.y
		segs.append(Vector2(floorf(x - p.x) + 0.5, floorf(y0) + 0.5))
		segs.append(Vector2(floorf(x + 4.0 - p.x) + 0.5, floorf(y1) + 0.5))
		x += 10.0
	enemy.draw_multiline(segs, Color(0.5, 1.0, 0.95, 0.13), 1.0)
	if state == S.PULSE:
		var kk: float = 1.0 - clampf(timer / PULSE_WARN, 0.0, 1.0)
		enemy.draw_circle(HEART, 3.0 + 5.0 * kk, Color(1.0, 0.45, 0.85, 0.2 + 0.35 * kk))
		for i: int in range(RING):
			var a: float = TAU * float(i) / float(RING) + age * 2.0
			enemy.draw_rect(Rect2(HEART + Vector2.from_angle(a) * (26.0 - 10.0 * kk) - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(0.6, 1.0, 0.95, 0.25 + 0.4 * kk))
	draw_hp_bar(24.0, -21.0)


# Its last ring (if any is still coasting or hanging) is released to the current at once.
func on_death() -> void:
	for i: int in range(motes.size()):
		var b: GameBullet = motes[i]
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			b.velocity = _flow(b.global_position.x)
	motes.clear()
	sparks(enemy.global_position, Color("#7af0ea"), 10)
	sparks(enemy.global_position, Color("#ff8ad8"), 6)
