extends "res://scripts/stages/stage_enemy.gd"

# Drone factory: a hulking assembly pod riding the floor (variant 0) or ceiling (variant 1)
# rails with the hangar. It builds attack drones in its nose bay: the conveyor lights along its
# hull chase faster and faster and welding sparks fly in the bay for ASSEMBLE_TIME (the
# telegraph), then the bay opens and a drone shoots out (a child: no Scrap), DRONES times at
# most and never while the drone cap is reached. Between builds its roof turret tracks the ship
# and fires short bursts (charge glint first).

const DroneScript = preload("enemy_drone.gd")

enum S { IDLE, ASSEMBLE, OPEN }

const ASSEMBLE_TIME: float = 1.3
const OPEN_TIME: float = 0.35
const DRONES: int = 3
const SCROLL: float = 38.0
const FLOOR_Y: float = 243.0
const CEIL_Y: float = 43.0
const BAY: Vector2 = Vector2(-13.0, 3.0)
const TURRET: Vector2 = Vector2(4.0, -12.0)

var state: S = S.IDLE
var timer: float = 0.0
var ceiling: bool = false
var drones_left: int = DRONES
var build_t: float = 1.0
var aim: float = PI
var burst_left: int = 0
var burst_t: float = 0.0
var spark_t: float = 0.0


func setup() -> void:
	ceiling = variant == 1
	enemy.global_position.y = CEIL_Y if ceiling else FLOOR_Y
	base_y = enemy.global_position.y
	sprite().flip_v = ceiling
	build_t = 0.8 + randf() * 0.4
	fire_timer = 1.6
	aim = PI * 0.8 if ceiling else -PI * 0.8


func _local(v: Vector2) -> Vector2:
	return Vector2(v.x, -v.y) if ceiling else v


func _clamp_aim(a: float) -> float:
	if ceiling:
		return clampf(wrapf(a, -PI * 0.5, PI * 1.5), 0.2, PI - 0.2)
	return clampf(wrapf(a, -PI * 1.5, PI * 0.5), -PI + 0.2, -0.2)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= SCROLL * delta
	enemy.global_position = p
	var on: bool = on_screen(60.0, 452.0)
	var tur: Vector2 = p + _local(TURRET)
	match state:
		S.IDLE:
			if drones_left > 0 and on:
				build_t -= delta
				if build_t <= 0.0 and DroneScript.count(enemy) < DroneScript.CAP:
					state = S.ASSEMBLE
					timer = ASSEMBLE_TIME
					sfx("boss_hp_tick", -17.0, 0.1)
		S.ASSEMBLE:
			timer -= delta
			spark_t -= delta
			if spark_t <= 0.0:
				spark_t = 0.12
				sparks(p + _local(BAY) + Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0)), Color("#ffd060"), 2)
			if timer <= 0.0:
				state = S.OPEN
				timer = OPEN_TIME
				drones_left -= 1
				var out_v: Vector2 = Vector2(randf_range(-90.0, -50.0), 110.0 if ceiling else -110.0)
				spawn_child("drone", p + _local(BAY) + Vector2(-6.0, 0.0), out_v)
				sparks(p + _local(BAY), Color("#ff8a30"), 6)
				sfx("missile", -14.0, 0.1)
		S.OPEN:
			timer -= delta
			if timer <= 0.0:
				state = S.IDLE
				build_t = fire_cd(2.4)
	# the roof turret
	if burst_left == 0:
		aim = lerp_angle(aim, _clamp_aim((player_pos() - tur).angle()), clampf(3.0 * delta, 0.0, 1.0))
		fire_timer -= delta
		if fire_timer <= 0.0 and on and state != S.ASSEMBLE:
			burst_left = 2
			burst_t = 0.0
	else:
		burst_t -= delta
		if burst_t <= 0.0:
			burst_t = 0.1
			burst_left -= 1
			emit_bullet(tur + Vector2.from_angle(aim) * 9.0, Vector2.from_angle(aim) * 140.0, bullet_a())
			if burst_left == 0:
				fire_timer = fire_cd(2.4)
	set_texture("mothership_factory_1" if state == S.OPEN else "mothership_factory_0")


func draw() -> void:
	var tur: Vector2 = _local(TURRET)
	var d: Vector2 = Vector2.from_angle(aim)
	# conveyor lights chasing along the hull (faster while a drone is being built)
	var speed: float = 6.0
	if state == S.ASSEMBLE:
		speed = lerpf(10.0, 34.0, 1.0 - timer / ASSEMBLE_TIME)
	var chase: int = int(age * speed)
	for i: int in range(8):
		var lx: float = 18.0 - float(i) * 4.0
		var on: bool = posmod(chase - i, 4) == 0
		var c: Color = Color(1.0, 0.55, 0.15, 0.9) if on else Color(0.5, 0.2, 0.1, 0.5)
		if state == S.ASSEMBLE and on:
			c = Color(1.0, 0.85, 0.4, 1.0)
		enemy.draw_rect(Rect2(_local(Vector2(lx, 6.0)) - Vector2(1.0, 0.5), Vector2(2.0, 1.0)), c)
	if state == S.ASSEMBLE:
		var k: float = 1.0 - clampf(timer / ASSEMBLE_TIME, 0.0, 1.0)
		var bay: Vector2 = _local(BAY)
		enemy.draw_circle(bay, 3.0 + 4.0 * k, Color(1.0, 0.6, 0.2, 0.12 + 0.25 * k))
		# the drone taking shape in the bay
		enemy.draw_rect(Rect2(bay - Vector2(3.0, 2.0) * k, Vector2(6.0, 4.0) * k), Color(0.6, 0.65, 0.75, 0.8))
		if int(age * 20.0) % 2 == 0:
			enemy.draw_rect(Rect2(bay + Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 2.0)), Vector2(1.0, 1.0)), Color(1.0, 1.0, 0.8))
	# the roof turret
	enemy.draw_circle(tur, 3.5, Color("#262a36"))
	enemy.draw_line(tur, tur + d * 9.0, Color("#0e1016"), 4.0)
	enemy.draw_line(tur, tur + d * 9.0, Color("#7c869c"), 2.0)
	if burst_left == 0:
		draw_glint(tur + d * 10.0, fire_timer, 0.35, Color(0.3, 0.9, 1.0))
	draw_hp_bar(30.0, 16.0 if ceiling else -18.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#ff8a30"), 10)
	sparks(enemy.global_position, Color("#ff4058"), 8)
