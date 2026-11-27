extends "res://scripts/stages/stage_enemy.gd"

# Void eye: loops a slow figure-eight near the right edge, its iris following the ship. To
# attack it charges (rim lights up) and after LOCK_AT locks a sight line, drawn as a thin beam;
# then it stares a stream of STREAM shots straight down that line and blinks. Its lid is
# armour: while closed it takes a quarter damage. After STARES it sinks away.

enum S { WATCH, CHARGE, STARE, BLINK, LEAVE }

const CHARGE_TIME: float = 0.75
const LOCK_AT: float = 0.4        # seconds before the stare when the line locks
const STREAM: int = 7
const BLINK_TIME: float = 0.8
const STARES: int = 4

var state: S = S.WATCH
var timer: float = 0.0
var anchor: Vector2 = Vector2.ZERO
var aim: float = PI
var locked: bool = false
var stream_left: int = 0
var stream_t: float = 0.0
var stares_left: int = STARES


func setup() -> void:
	anchor = Vector2(randf_range(370.0, 430.0), clampf(enemy.global_position.y, 56.0, 214.0))
	timer = 1.3


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	var want: Vector2 = anchor + Vector2(sin(age * 0.8 + phase) * 22.0, sin(age * 1.6 + phase) * 16.0)
	if state == S.LEAVE:
		p += Vector2(-50.0, 30.0 if anchor.y < 135.0 else -30.0) * delta
	else:
		p = p.lerp(want, clampf((2.2 if state == S.WATCH else 0.6) * delta, 0.0, 1.0))
	var to_ship: float = (player_pos() - p).angle()
	match state:
		S.WATCH:
			set_texture("voidrim_eye_0")
			aim = lerp_angle(aim, to_ship, clampf(6.0 * delta, 0.0, 1.0))
			timer -= delta
			if timer <= 0.0 and on_screen(120.0, 455.0):
				state = S.CHARGE
				timer = CHARGE_TIME
				locked = false
		S.CHARGE:
			set_texture("voidrim_eye_1")
			timer -= delta
			if not locked:
				aim = lerp_angle(aim, to_ship, clampf(8.0 * delta, 0.0, 1.0))
				if timer <= LOCK_AT:
					locked = true
					sfx("boss_hp_tick", -15.0, 0.0)
			if timer <= 0.0:
				state = S.STARE
				stream_left = STREAM
				stream_t = 0.0
		S.STARE:
			stream_t -= delta
			if stream_t <= 0.0:
				stream_t = 0.055
				stream_left -= 1
				emit_bullet(p + Vector2.from_angle(aim) * 7.0, Vector2.from_angle(aim) * 170.0, bullet_b())
				if stream_left <= 0:
					state = S.BLINK
					timer = BLINK_TIME
					stares_left -= 1
					sfx("laser", -14.0, 0.05)
		S.BLINK:
			set_texture("voidrim_eye_2")
			timer -= delta
			if timer <= 0.0:
				if stares_left <= 0:
					state = S.LEAVE
				else:
					state = S.WATCH
					timer = fire_cd(1.2)
		S.LEAVE:
			set_texture("voidrim_eye_2" if int(age * 2.0) % 3 == 0 else "voidrim_eye_0")
	enemy.global_position = p


func modify_damage(dmg: float) -> float:
	return dmg * 0.25 if state == S.BLINK else dmg


func draw() -> void:
	if state != S.BLINK and state != S.LEAVE:
		var d: Vector2 = Vector2.from_angle(aim)
		var iris: Vector2 = d * 2.6
		enemy.draw_circle(iris, 3.4, Color("#b070ff") if state == S.WATCH else Color("#ffd8ff"))
		enemy.draw_circle(iris, 1.8, Color("#08020e"))
		enemy.draw_rect(Rect2(iris + Vector2(-1.0, -1.5), Vector2(1.0, 1.0)), Color(1.0, 1.0, 1.0, 0.9))
	if state == S.CHARGE and locked:
		var d2: Vector2 = Vector2.from_angle(aim)
		var flick: float = 0.2 + 0.3 * float(int(age * 24.0) % 2)
		enemy.draw_line(d2 * 9.0, d2 * 500.0, Color(0.8, 0.5, 1.0, flick), 1.0)
	elif state == S.CHARGE:
		var k: float = 1.0 - clampf(timer / CHARGE_TIME, 0.0, 1.0)
		enemy.draw_arc(Vector2.ZERO, 12.0 - 3.0 * k, 0.0, TAU, 16, Color(0.8, 0.5, 1.0, 0.2 + 0.3 * k), 1.0)
	draw_hp_bar(18.0, -12.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#b070ff"), 8)
	sparks(enemy.global_position, Color("#ffffff"), 4)
