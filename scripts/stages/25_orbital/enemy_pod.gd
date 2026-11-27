extends "res://scripts/stages/stage_enemy.gd"

# Turret pod: flies in (from the right, or dropping from above on variant 1), clamps onto the
# station hull and unfolds into a flak battery that rides along with the hull. It never shoots
# straight at the ship: it paints a reticle where the ship is heading (RETICLE_TIME, shrinking
# and blinking), then lobs a flak shell at that point which bursts into a flower of rounds
# when it gets there. Shoot the pod while the shell is in the air and the shell is a dud.
# The boss launches these too (children, capped by CAP).

const Shield = preload("enemy_shieldgen.gd")

enum S { FLY, DEPLOY, IDLE, AIM, FLIGHT }

const HULL_Y: float = 228.0
const SCROLL: float = 44.0
const DEPLOY_TIME: float = 0.55
const RETICLE_TIME: float = 0.8
const LEAD: float = 0.5
const SHELL_SPEED: float = 150.0
const RING: int = 9
const PIVOT: Vector2 = Vector2(-1.0, -1.0)
const BARREL: float = 9.0
const CAP: int = 5

var state: S = S.FLY
var timer: float = 0.0
var land_x: float = 400.0
var aim: float = -PI * 0.75
var target: Vector2 = Vector2.ZERO
var shell: GameBullet = null
var shell_t: float = 0.0
var last_pp: Vector2 = Vector2.ZERO
var pvel: Vector2 = Vector2.ZERO


static func count(from: GameEnemy) -> int:
	var n: int = 0
	for node: Node in from.get_tree().get_nodes_in_group("enemies"):
		var ge: GameEnemy = node as GameEnemy
		if ge != null and ge.module_kind == "pod" and not ge._dead:
			n += 1
	return n


func setup() -> void:
	if gen > 0:
		land_x = randf_range(250.0, 360.0)
	elif variant == 1:
		land_x = clampf(enemy.global_position.x, 240.0, 440.0)
	else:
		land_x = randf_range(300.0, 430.0)
	fire_timer = 0.6
	last_pp = player_pos()


func _muzzle() -> Vector2:
	return enemy.global_position + PIVOT + Vector2.from_angle(aim) * BARREL


func _aim_toward(to: Vector2, rate: float, delta: float) -> void:
	var want: float = (to - enemy.global_position - PIVOT).angle()
	want = clampf(wrapf(want, -PI * 1.5, PI * 0.5), -PI + 0.12, -0.12)
	aim = lerp_angle(aim, want, clampf(rate * delta, 0.0, 1.0))


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	var pp: Vector2 = player_pos()
	pvel = pvel.lerp((pp - last_pp) / maxf(delta, 0.001), clampf(5.0 * delta, 0.0, 1.0))
	last_pp = pp
	if state != S.FLY:
		p.x -= SCROLL * delta
	match state:
		S.FLY:
			land_x -= SCROLL * delta
			var tgt: Vector2 = Vector2(land_x, HULL_Y)
			var d: float = p.distance_to(tgt)
			p = p.move_toward(tgt, clampf(d * 2.6, 70.0, 260.0) * delta)
			if d < 2.0:
				p = tgt
				state = S.DEPLOY
				timer = DEPLOY_TIME
				sparks(p + Vector2(-8.0, 8.0), Color("#c8d4e4"), 3)
				sparks(p + Vector2(8.0, 8.0), Color("#c8d4e4"), 3)
				sfx("boss_hp_tick", -14.0, 0.1)
		S.DEPLOY:
			timer -= delta
			set_texture("orbital_pod_1" if timer > DEPLOY_TIME * 0.5 else "orbital_pod_2")
			if timer <= 0.0:
				state = S.IDLE
				fire_timer = 0.3
		S.IDLE:
			enemy.global_position = p
			_aim_toward(pp, 3.0, delta)
			fire_timer -= delta
			if fire_timer <= 0.0 and on_screen(60.0, 450.0):
				target = pp + pvel * LEAD
				target.x = clampf(target.x, 30.0, 440.0)
				target.y = clampf(target.y, 40.0, 214.0)
				state = S.AIM
				timer = RETICLE_TIME
				sfx("boss_hp_tick", -16.0, 0.05)
		S.AIM:
			enemy.global_position = p
			_aim_toward(target, 10.0, delta)
			timer -= delta
			if timer <= 0.0:
				var from: Vector2 = _muzzle()
				var dir: Vector2 = (target - from).normalized()
				shell = emit_bullet(from, dir * SHELL_SPEED, "orbital_flak", false, 3.5)
				if shell != null:
					shell_t = from.distance_to(target) / maxf(1.0, shell.velocity.length())
					shell.life_left = shell_t + 0.7
				state = S.FLIGHT
				sfx("missile", -15.0, 0.1)
				sparks(from, Color("#ffd060"), 3)
		S.FLIGHT:
			shell_t -= delta
			if shell_t <= 0.0:
				if is_instance_valid(shell):
					_burst(shell.global_position)
					shell.queue_free()
				shell = null
				state = S.IDLE
				fire_timer = fire_cd(2.6)
	enemy.global_position = p
	if state == S.IDLE or state == S.FLIGHT:
		set_texture("orbital_pod_2")
	elif state == S.AIM:
		set_texture("orbital_pod_3" if int(age * 12.0) % 2 == 0 else "orbital_pod_2")


func _burst(at: Vector2) -> void:
	var rot: float = randf() * TAU
	for i: int in range(RING):
		emit_bullet(at, Vector2.from_angle(rot + TAU * float(i) / float(RING)) * 72.0, bullet_b())
	for j: int in range(4):
		emit_bullet(at, Vector2.from_angle(rot + TAU * (float(j) + 0.5) / 4.0) * 48.0, bullet_a())
	sfx("explode", -15.0, 0.1)


func draw() -> void:
	if state == S.FLY:
		var fl: float = float(int(age * 24.0) % 2)
		enemy.draw_rect(Rect2(11.0, -1.0, 2.0 + fl * 2.0, 2.0), Color(0.5, 0.95, 1.0, 0.7))
		if variant == 1 or gen > 0:
			enemy.draw_rect(Rect2(-1.0, 7.0, 2.0, 2.0 + fl * 2.0), Color(0.5, 0.95, 1.0, 0.6))
	elif state != S.DEPLOY:
		var d: Vector2 = Vector2.from_angle(aim)
		enemy.draw_line(PIVOT, PIVOT + d * BARREL, Color("#0c121c"), 4.0)
		enemy.draw_line(PIVOT, PIVOT + d * BARREL, Color("#8a98ac"), 2.0)
		enemy.draw_line(PIVOT + d * (BARREL - 2.0), PIVOT + d * BARREL, Color("#f0a030"), 2.0)
	var me: Vector2 = enemy.global_position
	if state == S.AIM:
		var k: float = 1.0 - clampf(timer / RETICLE_TIME, 0.0, 1.0)
		var lt: Vector2 = target - me
		var r: float = lerpf(16.0, 6.0, k)
		var blink: bool = timer < 0.25 and int(age * 20.0) % 2 == 0
		var col: Color = Color(1.0, 0.25, 0.2, 0.85) if blink else Color(1.0, 0.65, 0.2, 0.35 + 0.4 * k)
		enemy.draw_arc(lt, r, 0.0, TAU, 20, col, 1.0)
		for q: int in range(4):
			var qd: Vector2 = Vector2.from_angle(age * 3.0 + float(q) * PI * 0.5)
			enemy.draw_line(lt + qd * (r + 1.0), lt + qd * (r + 5.0), col, 1.0)
		# dotted trajectory
		var from: Vector2 = PIVOT + Vector2.from_angle(aim) * BARREL
		for s: int in range(1, 12):
			if s % 2 == 0:
				continue
			var t: float = float(s) / 12.0
			enemy.draw_rect(Rect2(from.lerp(lt, t), Vector2(1.0, 1.0)), Color(1.0, 0.7, 0.3, 0.25 * k))
	elif state == S.FLIGHT:
		var lt2: Vector2 = target - me
		var c2: Color = Color(1.0, 0.3, 0.2, 0.55 if int(age * 16.0) % 2 == 0 else 0.3)
		enemy.draw_line(lt2 + Vector2(-5.0, 0.0), lt2 + Vector2(5.0, 0.0), c2, 1.0)
		enemy.draw_line(lt2 + Vector2(0.0, -5.0), lt2 + Vector2(0.0, 5.0), c2, 1.0)
		enemy.draw_arc(lt2, 4.0, 0.0, TAU, 12, c2, 1.0)
	if Shield.covers(enemy):
		Shield.draw_bubble(enemy, 13.0)
	draw_hp_bar(20.0, -14.0)


func modify_damage(dmg: float) -> float:
	if Shield.covers(enemy):
		Shield.blocked(enemy)
		return dmg * Shield.COVER_MULT
	return dmg


func on_death() -> void:
	sparks(enemy.global_position, Color("#f0a030"), 8)
	sparks(enemy.global_position, Color("#c8d4e4"), 6)
	if is_instance_valid(shell):
		shell.life_left = minf(shell.life_left, 0.5)
