extends "res://scripts/stages/stage_enemy.gd"

# GLADIATOR DRONE: a shield-and-blade duelist. Gladiators come in pairs and take turns: while
# one squares up behind its shield (an energy arc in front; hits barely scratch it, and it jabs
# back with a 3-shot fan), the other attacks. An attack is a lunge: a red dashed line marks
# the path for AIM_TIME (it tracks the ship, then locks), then it dashes along it slashing out a
# crescent of shots, and a smaller backhand crescent at the end of the dash. Out of guard it
# takes extra damage. variant 1 starts one turn later than variant 0, so a pair alternates.

enum Phase { ENTER, GUARD, AIM, DASH, RECOVER, LEAVE }

const GUARD_TIME: float = 2.0
const AIM_TIME: float = 0.65
const LOCK_AT: float = 0.25     # the aim stops tracking this long before the dash
const DASH_TIME: float = 0.42
const DASH_SPEED: float = 270.0
const RECOVER_TIME: float = 0.9
const CYCLES: int = 3
const CRESCENT: int = 9
const SHIELD_CUT: float = 0.3

var state: Phase = Phase.ENTER
var timer: float = 0.0
var home: Vector2 = Vector2(400.0, 135.0)
var dash_dir: Vector2 = Vector2.LEFT
var cycles_left: int = CYCLES
var block_cd: float = 0.0


func setup() -> void:
	home = Vector2(randf_range(376.0, 420.0), clampf(base_y, 56.0, 214.0))
	timer = GUARD_TIME * (0.55 if variant == 0 else 1.6)
	fire_timer = fire_cd(1.1) + randf() * 0.4


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	block_cd -= delta
	match state:
		Phase.ENTER:
			p = p.lerp(home, clampf(2.4 * delta, 0.0, 1.0))
			set_texture("arena_gladiator_0")
			if p.x < home.x + 10.0:
				state = Phase.GUARD
		Phase.GUARD:
			# Square up: drift toward the ship's height behind the shield, jab now and then.
			# (partners keep to either side of the ship's line so they don't stack up)
			var side: float = -26.0 if variant == 0 else 26.0
			home.y = lerpf(home.y, clampf(player_pos().y + side, 52.0, 218.0), clampf(0.5 * delta, 0.0, 1.0))
			p.x = lerpf(p.x, home.x, clampf(2.0 * delta, 0.0, 1.0))
			p.y = lerpf(p.y, home.y + sin(age * 1.6 + phase) * 8.0, clampf(2.5 * delta, 0.0, 1.0))
			set_texture("arena_gladiator_0")
			fire_timer -= delta
			if fire_timer <= 0.0 and on_screen(110.0, 455.0):
				fire_timer = fire_cd(1.25)
				for k: int in [-1, 0, 1]:
					shoot_aimed_from(p + Vector2(-9.0, 1.0), 120.0 + (8.0 if k == 0 else 0.0), bullet_b(), float(k) * 0.13)
			timer -= delta
			if timer <= 0.0 and on_screen(120.0, 450.0):
				state = Phase.AIM
				timer = AIM_TIME
				_aim(p)
				sfx("boss_hp_tick", -13.0, 0.05)
		Phase.AIM:
			set_texture("arena_gladiator_2")
			p += Vector2(sin(age * 50.0), cos(age * 43.0)) * 0.3
			if timer > LOCK_AT:
				_aim(p)
			timer -= delta
			if timer <= 0.0:
				state = Phase.DASH
				timer = DASH_TIME
				set_texture("arena_gladiator_1")
				_crescent(p, CRESCENT, 132.0, 0.7)
				sfx("missile", -11.0, 0.08)
		Phase.DASH:
			p += dash_dir * DASH_SPEED * delta
			timer -= delta
			if timer <= 0.0:
				_crescent(p, 5, 118.0, 0.5)
				state = Phase.RECOVER
				timer = RECOVER_TIME
				cycles_left -= 1
		Phase.RECOVER:
			p = p.lerp(home, clampf(2.4 * delta, 0.0, 1.0))
			set_texture("arena_gladiator_0")
			timer -= delta
			if timer <= 0.0:
				if cycles_left <= 0 or age > 22.0:
					state = Phase.LEAVE
					vel = Vector2(-40.0, 0.0)
				else:
					# Back on guard for the partner's turn.
					state = Phase.GUARD
					timer = GUARD_TIME + AIM_TIME + DASH_TIME + RECOVER_TIME * 0.5
		Phase.LEAVE:
			vel = vel.lerp(Vector2(-210.0, 0.0), clampf(delta * 1.2, 0.0, 1.0))
			p += vel * delta
			set_texture("arena_gladiator_1")
	p.y = clampf(p.y, 40.0, 238.0)
	enemy.global_position = p


func _aim(p: Vector2) -> void:
	var d: Vector2 = (player_pos() - p).normalized()
	if d.x > -0.45:
		var sy: float = signf(d.y) if d.y != 0.0 else 1.0
		d = Vector2(-0.45, sy * 0.9).normalized()
	dash_dir = d


# A crescent of shots: the middle ones lead, the tips trail, so the arc bows toward the ship.
func _crescent(p: Vector2, n: int, speed: float, spread: float) -> void:
	var origin: Vector2 = p + dash_dir * 10.0
	for i: int in range(n):
		var u: float = (float(i) / float(n - 1)) * 2.0 - 1.0
		var spd: float = speed * (1.0 - 0.16 * absf(u))
		emit_bullet(origin + dash_dir.orthogonal() * u * 6.0, dash_dir.rotated(u * spread) * spd, bullet_a())
	sparks(origin, Color("#38e8ff"), 4)


func modify_damage(dmg: float) -> float:
	if state == Phase.ENTER or state == Phase.GUARD:
		if block_cd <= 0.0:
			block_cd = 0.1
			sparks(enemy.global_position + Vector2(-10.0, randf_range(-6.0, 6.0)), Color("#ffe07a"), 2)
		return dmg * SHIELD_CUT
	if state == Phase.DASH or state == Phase.RECOVER:
		return dmg * 1.25
	return dmg


func draw() -> void:
	draw_hp_bar(22.0, -18.0)
	if state == Phase.GUARD or state == Phase.ENTER:
		# The energy shield arc in front.
		var k: float = 0.5 + 0.5 * sin(age * 7.0 + phase)
		enemy.draw_arc(Vector2(-4.0, 1.0), 13.0, PI * 0.62, PI * 1.38, 14, Color(0.25, 0.9, 1.0, 0.25 + 0.2 * k), 1.0)
		enemy.draw_arc(Vector2(-4.0, 1.0), 14.0, PI * 0.72, PI * 1.28, 10, Color(0.75, 1.0, 1.0, 0.12 + 0.12 * k), 1.0)
		draw_glint(Vector2(-11.0, 1.0), fire_timer, 0.3, Color(1.0, 0.8, 0.3))
	elif state == Phase.AIM:
		# The lunge line: red dashes along the dash path, flickering faster as it locks.
		var u: float = 1.0 - timer / AIM_TIME
		var a: float = 0.3 + 0.35 * u + 0.2 * sin(age * (26.0 + 40.0 * u))
		var reach: float = DASH_SPEED * DASH_TIME + 60.0
		var d: float = 10.0
		var march: float = fposmod(age * 90.0, 10.0)
		while d < reach:
			var q0: Vector2 = dash_dir * (d + march)
			var q1: Vector2 = dash_dir * minf(d + march + 5.0, reach)
			enemy.draw_line(q0, q1, Color(1.0, 0.22, 0.3, a), 1.0)
			d += 10.0
		enemy.draw_circle(dash_dir * reach, 2.0 + 2.0 * u, Color(1.0, 0.3, 0.35, 0.35 * u))
		draw_glint(Vector2(-6.0, -7.0), timer, AIM_TIME, Color(1.0, 0.25, 0.3))


func on_death() -> void:
	sparks(enemy.global_position, Color("#ffe07a"), 8)
	sparks(enemy.global_position, Color("#ff3cc8"), 5)
