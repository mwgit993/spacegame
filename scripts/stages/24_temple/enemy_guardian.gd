extends "res://scripts/stages/stage_enemy.gd"

# Guardian: a colossal carved head, broken off its statue, that floats in and hangs there. With its eyes shut it's solid
# stone (shots chip it for ARMOUR of their damage). To attack it opens its eyes: they kindle
# for CHARGE_TIME (growing glints, two thin sight lines tracking the ship, which lock and turn
# solid for the last LOCK_TIME), then pour twin beams of sun-fire down the locked lines. While
# its eyes are open (charging, firing, cooling) it takes OPEN_MULT damage, so the time to hit it
# is right when it's most dangerous. After CYCLES volleys (or LIFETIME) it sinks away.

enum S { ENTER, IDLE, CHARGE, FIRE, COOL, LEAVE }

const CHARGE_TIME: float = 0.85
const LOCK_TIME: float = 0.32
const FIRE_TIME: float = 0.54
const PELLET_GAP: float = 0.06
const COOL_TIME: float = 0.55
const CYCLES: int = 3
const LIFETIME: float = 13.0
const ARMOUR: float = 0.25
const OPEN_MULT: float = 1.35
const BEAM_SPEED: float = 200.0
const EYES: Array[Vector2] = [Vector2(-6.5, 0.0), Vector2(5.5, 0.0)]

var state: S = S.ENTER
var timer: float = 0.0
var target_x: float = 400.0
var aim: Vector2 = Vector2(60.0, 135.0)
var pellet_t: float = 0.0
var cycles_left: int = CYCLES
var chip_t: float = 0.0
var hold_y: float = 0.0
var leave_dir: float = 1.0


func setup() -> void:
	target_x = randf_range(385.0, 428.0) - 18.0 * float(variant)
	fire_timer = 1.1 + 0.3 * float(variant)


func _eyes_open() -> bool:
	return state == S.CHARGE or state == S.FIRE or state == S.COOL


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	chip_t -= delta
	match state:
		S.ENTER:
			p.x = lerpf(p.x, target_x, 2.4 * delta)
			p.y = base_y + sin(age * 1.3 + phase) * 9.0
			if p.x < target_x + 6.0:
				state = S.IDLE
		S.IDLE:
			p.x = lerpf(p.x, target_x, 2.0 * delta)
			p.y = base_y + sin(age * 1.3 + phase) * 9.0
			fire_timer -= delta
			if age > LIFETIME or cycles_left <= 0:
				state = S.LEAVE
				leave_dir = -1.0 if p.y < 135.0 else 1.0
			elif fire_timer <= 0.0 and on_screen(90.0, 450.0):
				state = S.CHARGE
				timer = CHARGE_TIME
				hold_y = p.y
				aim = player_pos()
				set_texture("temple_guard_1")
				sfx("boss_hp_tick", -14.0, 0.05)
		S.CHARGE:
			p.y = lerpf(p.y, hold_y, 6.0 * delta)
			timer -= delta
			if timer > LOCK_TIME:
				aim = aim.lerp(player_pos(), clampf(9.0 * delta, 0.0, 1.0))
			if timer <= 0.0:
				state = S.FIRE
				timer = FIRE_TIME
				pellet_t = 0.0
				sfx("laser", -11.0, 0.05)
		S.FIRE:
			timer -= delta
			pellet_t -= delta
			if pellet_t <= 0.0:
				pellet_t = PELLET_GAP
				for e: Vector2 in EYES:
					var from: Vector2 = p + e
					var dir: Vector2 = (aim - from).normalized()
					emit_bullet(from + dir * 4.0, dir * BEAM_SPEED, "temple_ray", false, 2.5)
			if timer <= 0.0:
				state = S.COOL
				timer = COOL_TIME
				cycles_left -= 1
		S.COOL:
			timer -= delta
			if timer <= 0.0:
				state = S.IDLE
				fire_timer = fire_cd(1.6)
				base_y = p.y - sin(age * 1.3 + phase) * 9.0
				set_texture("temple_guard_0")
		S.LEAVE:
			set_texture("temple_guard_0")
			p.x -= 28.0 * delta
			p.y += leave_dir * 70.0 * delta
	enemy.global_position = p


func modify_damage(dmg: float) -> float:
	if _eyes_open():
		return dmg * OPEN_MULT
	if chip_t <= 0.0:
		chip_t = 0.1
		sparks(enemy.global_position + Vector2(-10.0, randf_range(-8.0, 8.0)), Color("#92a294"), 2)
	return dmg * ARMOUR


func draw() -> void:
	match state:
		S.CHARGE:
			var locked: bool = timer <= LOCK_TIME
			var k: float = 1.0 - clampf(timer / CHARGE_TIME, 0.0, 1.0)
			for e: Vector2 in EYES:
				var to: Vector2 = aim - enemy.global_position
				var dir: Vector2 = (to - e).normalized()
				var a: float = 0.1 + 0.1 * k
				if locked:
					a = 0.32 + 0.25 * float(int(age * 26.0) % 2)
				enemy.draw_line(e + dir * 5.0, e + dir * 520.0, Color(1.0, 0.82, 0.3, a), 1.0)
				var r: float = lerpf(1.0, 4.0, k)
				enemy.draw_circle(e, r + 1.5, Color(1.0, 0.7, 0.2, 0.35))
				enemy.draw_circle(e, r * 0.55, Color(1.0, 0.97, 0.8, 0.95))
		S.FIRE:
			for e2: Vector2 in EYES:
				var to2: Vector2 = aim - enemy.global_position
				var dir2: Vector2 = (to2 - e2).normalized()
				enemy.draw_line(e2 + dir2 * 5.0, e2 + dir2 * 520.0, Color(1.0, 0.85, 0.4, 0.18), 3.0)
				enemy.draw_circle(e2, 4.5, Color(1.0, 0.85, 0.3, 0.5))
				enemy.draw_circle(e2, 2.2, Color(1.0, 1.0, 0.9, 1.0))
		S.COOL:
			var k2: float = clampf(timer / COOL_TIME, 0.0, 1.0)
			for e3: Vector2 in EYES:
				enemy.draw_circle(e3, 2.5 * k2 + 0.5, Color(1.0, 0.75, 0.3, 0.6 * k2))
	draw_hp_bar(28.0, -21.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#92a294"), 10)
	sparks(enemy.global_position, Color("#e0b040"), 8)
