extends "res://scripts/stages/stage_enemy.gd"

# MIRROR WARDEN ("reflector"): a chrome core behind a big mirror pane that rocks up and down.
# The pane obeys real mirror optics: your shots fly right, so a hit on the pane bounces back at
# the mirrored angle, 180 - 2 x tilt. Facing straight at you (flat, the face blazes white) the
# echo comes straight back down your own line; tilted, it glances off up or down. A dotted line
# from the pane always shows where the next echo will go. While shielded it takes 25% damage.
# Every few seconds it swings the pane up out of the way (the core's eye charges: the telegraph)
# and fires a mirrored fan from the exposed core, taking 130% damage until the pane drops back.
# Unlike the gem golem, it never stops reflecting while shielded and the echoes are aimed by
# the pane's angle, not at you: rock with the pane, or shoot when it swings open.

enum Phase { ENTER, SHIELD, OPENING, OPEN, CLOSING, LEAVE }

const TILT_MAX: float = 24.0
const SHIELD_TIME: float = 2.7
const OPEN_TELL: float = 0.55
const OPEN_TIME: float = 1.25
const CLOSE_TIME: float = 0.3
const REFLECT_GAP: float = 0.2
const CYCLES: int = 3

var state: Phase = Phase.ENTER
var timer: float = 0.0
var reflect_cd: float = 0.0
var cycles_left: int = CYCLES
var target_x: float = 400.0
var rock: float = 0.0
var tilt: float = 0.0       # degrees, + tips the pane's face downward
var fired: int = 0


func setup() -> void:
	target_x = randf_range(372.0, 424.0)
	rock = randf() * TAU + (PI if variant == 1 else 0.0)


func _tilt_frame() -> int:
	return clampi(int(roundf(tilt / TILT_MAX * 2.0)) + 2, 0, 4)


# Direction an echo leaves the pane in: the reflection of (1, 0) off a mirror whose normal is
# (-cos t, sin t), which is (-cos 2t, sin 2t).
func _echo_dir() -> Vector2:
	var t: float = deg_to_rad(float(_tilt_frame() - 2) * TILT_MAX * 0.5)
	return Vector2(-cos(2.0 * t), sin(2.0 * t))


func _shielded() -> bool:
	return state == Phase.ENTER or state == Phase.SHIELD or state == Phase.CLOSING or (state == Phase.OPENING and timer > OPEN_TELL - 0.15)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	reflect_cd -= delta
	if state != Phase.OPENING and state != Phase.OPEN:
		rock += delta * 1.25
		tilt = sin(rock) * TILT_MAX
	match state:
		Phase.ENTER:
			p.x = lerpf(p.x, target_x, clampf(1.6 * delta, 0.0, 1.0))
			if p.x < target_x + 12.0:
				state = Phase.SHIELD
				timer = SHIELD_TIME * 0.6
		Phase.SHIELD:
			timer -= delta
			if timer <= 0.0 and on_screen(80.0, 450.0):
				state = Phase.OPENING
				timer = OPEN_TELL
				sfx("shield_hit", -14.0, 0.15)
		Phase.OPENING:
			timer -= delta
			if timer <= 0.0:
				state = Phase.OPEN
				timer = OPEN_TIME
				fired = 0
		Phase.OPEN:
			timer -= delta
			if fired == 0 or (fired == 1 and timer < OPEN_TIME * 0.45):
				_fan(fired == 1)
				fired += 1
			if timer <= 0.0:
				state = Phase.CLOSING
				timer = CLOSE_TIME
		Phase.CLOSING:
			timer -= delta
			if timer <= 0.0:
				cycles_left -= 1
				if cycles_left <= 0 or age > 17.0:
					state = Phase.LEAVE
				else:
					state = Phase.SHIELD
					timer = fire_cd(SHIELD_TIME * 1.4)
		Phase.LEAVE:
			p.x -= 60.0 * delta
	if state != Phase.ENTER:
		p.y = clampf(base_y + sin(age * 0.9 + phase) * 10.0, 44.0, 235.0)
	enemy.global_position = p
	if state == Phase.OPENING or state == Phase.OPEN:
		set_texture("mirror_reflector_5")
	else:
		set_texture("mirror_reflector_%d" % _tilt_frame())


# A fan mirrored about the horizontal: pairs at +-a around a shot straight at you.
func _fan(second: bool) -> void:
	var origin: Vector2 = enemy.global_position + Vector2(-4.0, 0.0)
	shoot_aimed_from(origin, 128.0, bullet_b())
	var base: Vector2 = Vector2(-1.0, 0.0)
	var spread: Array[float] = [0.34, 0.6]
	if not second:
		spread = [0.22, 0.46, 0.72]
	for a: float in spread:
		emit_bullet(origin, base.rotated(a) * 120.0, bullet_a())
		emit_bullet(origin, base.rotated(-a) * 120.0, bullet_a())
	sfx("missile", -14.0, 0.08)


func modify_damage(dmg: float) -> float:
	if state == Phase.OPEN or (state == Phase.OPENING and timer <= OPEN_TELL - 0.15):
		return dmg * 1.3
	if state == Phase.LEAVE:
		return dmg
	if reflect_cd <= 0.0 and on_screen(60.0, 460.0):
		reflect_cd = REFLECT_GAP
		var d: Vector2 = _echo_dir()
		var from: Vector2 = enemy.global_position + Vector2(-11.0, randf_range(-8.0, 8.0))
		emit_bullet(from, d * 125.0, "mirror_echo", true, 2.5)
		sparks(from, Color("#e8f6ff"), 2)
	return dmg * 0.25


func draw() -> void:
	draw_hp_bar(24.0, -21.0)
	if _shielded() and state != Phase.LEAVE:
		# Where the next echo goes: a dotted line from the pane along the reflected angle,
		# brighter when the pane faces you squarely (the echo comes straight back at you).
		var d: Vector2 = _echo_dir()
		var flat: bool = _tilt_frame() == 2
		var a: float = 0.32 if flat else 0.16
		var o: Vector2 = Vector2(-11.0, 0.0)
		var dist: float = 6.0
		while dist < 90.0:
			var q: Vector2 = o + d * dist
			enemy.draw_rect(Rect2(q.floor(), Vector2.ONE), Color(0.85, 0.97, 1.0, a * (1.0 - dist / 110.0)))
			dist += 5.0
		if flat:
			var k: float = 0.5 + 0.5 * sin(age * 18.0)
			enemy.draw_rect(Rect2(-13.0, -12.0, 1.0, 24.0), Color(1.0, 1.0, 1.0, 0.25 + 0.25 * k))
		if reflect_cd > REFLECT_GAP - 0.07:
			enemy.draw_circle(o, 4.0, Color(1.0, 1.0, 1.0, 0.4))
	elif state == Phase.OPENING:
		draw_glint(Vector2(-3.0, 0.0), timer, OPEN_TELL, Color(1.0, 0.45, 0.3))


func on_death() -> void:
	var origin: Vector2 = enemy.global_position
	for i: int in range(3):
		var a: float = 0.3 + 0.35 * float(i)
		emit_bullet(origin, Vector2(-1.0, 0.0).rotated(a) * 95.0, "mirror_echo", true)
		emit_bullet(origin, Vector2(-1.0, 0.0).rotated(-a) * 95.0, "mirror_echo", true)
	sparks(origin, Color("#e8f6ff"), 8)
	sparks(origin, Color("#ff7ae8"), 4)
