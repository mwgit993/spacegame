extends "res://scripts/stages/stage_enemy.gd"

# Armada elite: the swooper and the sniper rolled into one pilot. It swoops in on an arc to a
# firing spot, locks on with a laser sight (it tracks the ship for the first part of LOCK_TIME,
# then the line holds still and flickers: that's the moment to move), fires a tight spread
# down the line (later volleys add two flankers), then barrel-rolls out of it to a new
# height and locks again. After CYCLES volleys it peels away to the left.

enum S { SWOOP, LOCK, ROLL, WAIT, EXIT }

const SWOOP_TIME: float = 0.9
const LOCK_TIME: float = 0.6
const TRACK_TIME: float = 0.32
const ROLL_TIME: float = 0.42
const CYCLES: int = 3
const SHOT_SPEED: float = 150.0
const GUN: Vector2 = Vector2(-12.0, 0.0)

var state: S = S.SWOOP
var timer: float = 0.0
var start: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
var aim: float = PI
var cycles_left: int = CYCLES
var roll_from: float = 0.0
var roll_to: float = 0.0
var arc: float = 1.0


func setup() -> void:
	start = enemy.global_position
	target = Vector2(randf_range(330.0, 420.0), clampf(base_y, 44.0, 228.0))
	arc = -1.0 if variant == 0 else 1.0
	timer = SWOOP_TIME


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	var s: Sprite2D = sprite()
	match state:
		S.SWOOP:
			timer -= delta
			var k: float = 1.0 - clampf(timer / SWOOP_TIME, 0.0, 1.0)
			var e: float = 1.0 - pow(1.0 - k, 2.4)
			p.x = lerpf(start.x, target.x, e)
			p.y = lerpf(start.y, target.y, e) + sin(k * PI) * 46.0 * arc
			s.rotation = cos(k * PI) * 0.35 * arc
			if timer <= 0.0:
				s.rotation = 0.0
				_begin_lock()
		S.LOCK:
			timer -= delta
			p.y += sin(age * 5.0 + phase) * 6.0 * delta
			if timer > LOCK_TIME - TRACK_TIME:
				aim = lerp_angle(aim, (player_pos() - (p + GUN)).angle(), clampf(12.0 * delta, 0.0, 1.0))
			if timer <= 0.0:
				for k2: int in range(-1, 2):
					emit_bullet(p + GUN, Vector2.from_angle(aim + float(k2) * 0.07) * SHOT_SPEED, bullet_b())
				if cycles_left < CYCLES:
					# later volleys add two flankers, closing the escape either side
					for side: float in [-1.0, 1.0]:
						emit_bullet(p + GUN, Vector2.from_angle(aim + side * 0.2) * SHOT_SPEED * 0.86, bullet_a())
				sfx("laser", -14.0, 0.06)
				cycles_left -= 1
				state = S.ROLL
				timer = ROLL_TIME
				roll_from = p.y
				# roll across the line, away from where the ship is
				var dir: float = 1.0 if player_pos().y < p.y else -1.0
				if p.y + dir * 50.0 > 226.0 or p.y + dir * 50.0 < 46.0:
					dir = -dir
				roll_to = clampf(p.y + dir * randf_range(38.0, 54.0), 46.0, 226.0)
		S.ROLL:
			timer -= delta
			var k3: float = 1.0 - clampf(timer / ROLL_TIME, 0.0, 1.0)
			p.y = lerpf(roll_from, roll_to, 0.5 - 0.5 * cos(k3 * PI))
			p.x += 22.0 * delta
			s.scale.y = absf(cos(k3 * TAU))
			s.flip_v = k3 > 0.25 and k3 < 0.75
			if timer <= 0.0:
				s.scale.y = 1.0
				s.flip_v = false
				state = S.EXIT if cycles_left <= 0 else S.WAIT
				fire_timer = fire_cd(0.55)
		S.WAIT:
			p.y += sin(age * 5.0 + phase) * 8.0 * delta
			fire_timer -= delta
			if fire_timer <= 0.0 and on_screen(110.0, 450.0):
				_begin_lock()
		S.EXIT:
			vel = vel.move_toward(Vector2(-230.0, 70.0 * arc), 300.0 * delta)
			p += vel * delta
			s.rotation = lerpf(s.rotation, 0.3 * arc, 4.0 * delta)
	enemy.global_position = p
	var frame: String = "mothership_elite_0"
	if state == S.LOCK:
		frame = "mothership_elite_1"
	elif state == S.ROLL and absf(s.scale.y) < 0.55:
		frame = "mothership_elite_2"
	set_texture(frame)


func _begin_lock() -> void:
	state = S.LOCK
	timer = LOCK_TIME
	aim = (player_pos() - (enemy.global_position + GUN)).angle()
	sfx("boss_hp_tick", -16.0, 0.1)


func draw() -> void:
	if state == S.LOCK:
		var d: Vector2 = Vector2.from_angle(aim)
		var held: bool = timer <= LOCK_TIME - TRACK_TIME
		var a: float = 0.16
		if held:
			a = 0.3 + 0.3 * float(int(age * 26.0) % 2)
		enemy.draw_line(GUN + d * 4.0, GUN + d * 520.0, Color(1.0, 0.22, 0.3, a), 1.0)
		draw_glint(GUN, timer, 0.3, Color(1.0, 0.25, 0.35))
	draw_hp_bar(20.0, -12.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#ff4058"), 8)
	sparks(enemy.global_position, Color("#40e8ff"), 4)
