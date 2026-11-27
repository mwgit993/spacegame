extends "res://scripts/stages/stage_enemy.gd"

# Haywire security turret on the floor (variant 0) or ceiling (variant 1), riding the scroll
# and spitting sparks. Its barrel twitches about at random, a faint sight line showing where it
# points. To attack it locks on (the sight turns solid red for LOCK_TIME, aimed near the ship
# but not quite true) and fires a burst down the line. Every third attack it goes berserk
# instead: its alarm light flashes (SPIN_WARN) and it sprays shots while spinning its barrel.

enum S { TWITCH, LOCK, BURST, ALARM, SPIN }

const LOCK_TIME: float = 0.45
const SPIN_WARN: float = 0.6
const SCROLL: float = 40.0
const FLOOR_Y: float = 250.0
const CEIL_Y: float = 36.0
const BARREL: float = 11.0

var state: S = S.TWITCH
var timer: float = 0.0
var ceiling: bool = false
var aim: float = -PI * 0.75
var twitch_t: float = 0.2
var attacks: int = 0
var shots_left: int = 0
var spark_t: float = 0.3


func setup() -> void:
	ceiling = variant == 1
	enemy.global_position.y = CEIL_Y if ceiling else FLOOR_Y
	base_y = enemy.global_position.y
	sprite().flip_v = ceiling
	aim = PI * 0.75 if ceiling else -PI * 0.75
	fire_timer = 1.4


func _pivot() -> Vector2:
	return Vector2(0.0, 2.0 if ceiling else -2.0)


func _clamp_aim(a: float) -> float:
	# floor turrets aim into the upper half-plane, ceiling turrets into the lower one
	if ceiling:
		return clampf(wrapf(a, -PI * 0.5, PI * 1.5), 0.15, PI - 0.15)
	return clampf(wrapf(a, -PI * 1.5, PI * 0.5), -PI + 0.15, -0.15)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= SCROLL * delta
	enemy.global_position = p
	var muzzle: Vector2 = p + _pivot() + Vector2.from_angle(aim) * BARREL
	match state:
		S.TWITCH:
			twitch_t -= delta
			if twitch_t <= 0.0:
				twitch_t = randf_range(0.12, 0.35)
				aim = _clamp_aim(aim + randf_range(-0.9, 0.9))
			fire_timer -= delta
			if fire_timer <= 0.0 and on_screen(70.0, 450.0):
				attacks += 1
				if attacks % 3 == 0:
					state = S.ALARM
					timer = SPIN_WARN
					sfx("boss_siren", -18.0, 0.0)
				else:
					state = S.LOCK
					timer = LOCK_TIME
					aim = _clamp_aim((player_pos() - p - _pivot()).angle() + randf_range(-0.22, 0.22))
					sfx("boss_hp_tick", -15.0, 0.1)
		S.LOCK:
			timer -= delta
			if timer <= 0.0:
				state = S.BURST
				shots_left = 4
				timer = 0.0
		S.BURST:
			timer -= delta
			if timer <= 0.0:
				timer = 0.08
				shots_left -= 1
				emit_bullet(muzzle, Vector2.from_angle(aim) * 150.0, bullet_a())
				if shots_left <= 0:
					state = S.TWITCH
					fire_timer = fire_cd(1.4)
		S.ALARM:
			timer -= delta
			if timer <= 0.0:
				state = S.SPIN
				shots_left = 8
				timer = 0.0
				aim = PI * 0.1 if ceiling else -PI * 0.1
		S.SPIN:
			timer -= delta
			if timer <= 0.0:
				timer = 0.07
				shots_left -= 1
				aim = _clamp_aim(aim + (0.36 if ceiling else -0.36))
				emit_bullet(p + _pivot() + Vector2.from_angle(aim) * BARREL, Vector2.from_angle(aim) * 120.0, bullet_b())
				if shots_left <= 0:
					state = S.TWITCH
					fire_timer = fire_cd(1.9)
	set_texture("biolab_turret_1" if state == S.ALARM and int(age * 12.0) % 2 == 0 else "biolab_turret_0")
	spark_t -= delta
	if spark_t <= 0.0:
		spark_t = randf_range(0.2, 0.6)
		sparks(p + Vector2(randf_range(-6.0, 6.0), 0.0), Color("#ffe060"), 2)


func draw() -> void:
	var pv: Vector2 = _pivot()
	var d: Vector2 = Vector2.from_angle(aim)
	match state:
		S.TWITCH:
			enemy.draw_line(pv + d * BARREL, pv + d * 160.0, Color(1.0, 0.3, 0.3, 0.1), 1.0)
		S.LOCK, S.BURST:
			var flick: float = 0.35 + 0.25 * float(int(age * 24.0) % 2)
			enemy.draw_line(pv + d * BARREL, pv + d * 480.0, Color(1.0, 0.25, 0.25, flick), 1.0)
		S.ALARM:
			var a: float = 0.2 + 0.3 * float(int(age * 12.0) % 2)
			enemy.draw_circle(Vector2(4.0, -5.0 if not ceiling else 5.0), 6.0, Color(1.0, 0.2, 0.2, a))
	# the barrel
	enemy.draw_line(pv, pv + d * BARREL, Color("#26383e"), 4.0)
	enemy.draw_line(pv, pv + d * BARREL, Color("#9ab4bc"), 2.0)
	enemy.draw_rect(Rect2(pv + d * BARREL - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color("#101c20"))
	draw_hp_bar(18.0, 10.0 if ceiling else -14.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#ffe060"), 10)
