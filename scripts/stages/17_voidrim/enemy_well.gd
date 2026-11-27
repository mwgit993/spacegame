extends "res://scripts/stages/stage_enemy.gd"

# Gravity-well mine: drifts in and parks. It charges for CHARGE_TIME (rings contracting into
# its core: the telegraph), then for ACTIVE_TIME its field (a swirl of rings, radius FIELD_R)
# bends every shot that passes through it: your shots curve in toward it, enemy shots are
# slung round it. The field collapses with a ring of shots. After CYCLES it drifts away.

enum S { ENTER, IDLE, CHARGE, ACTIVE, LEAVE }

const CHARGE_TIME: float = 0.9
const ACTIVE_TIME: float = 2.6
const FIELD_R: float = 82.0
const TURN_PLAYER: float = 5.5    # rad/s at the centre for your shots
const TURN_ENEMY: float = 1.4     # rad/s at the centre for enemy shots
const CYCLES: int = 2
const RING: int = 10

var state: S = S.ENTER
var timer: float = 0.0
var target_x: float = 380.0
var cycles_left: int = CYCLES
var spin: float = 0.0


func setup() -> void:
	target_x = randf_range(300.0, 410.0)
	timer = 1.0


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	spin += delta * (6.0 if state == S.ACTIVE else 1.5)
	sprite().rotation = spin
	match state:
		S.ENTER, S.IDLE:
			p.x = lerpf(p.x, target_x, clampf(1.5 * delta, 0.0, 1.0))
			p.y = base_y + sin(age * 0.9 + phase) * 6.0
			if state == S.ENTER and absf(p.x - target_x) < 12.0:
				state = S.IDLE
				timer = 0.8
			elif state == S.IDLE:
				timer -= delta
				if timer <= 0.0 and on_screen(110.0, 450.0):
					state = S.CHARGE
					timer = CHARGE_TIME
					sfx("boss_hp_tick", -15.0, 0.0)
			set_texture("voidrim_well_0")
		S.CHARGE:
			timer -= delta
			set_texture("voidrim_well_1")
			if timer <= 0.0:
				state = S.ACTIVE
				timer = ACTIVE_TIME
				sfx("zap", -12.0, 0.0)
		S.ACTIVE:
			timer -= delta
			set_texture("voidrim_well_2")
			_bend(p, delta)
			if timer <= 0.0:
				var rot: float = randf() * TAU
				for i: int in range(RING):
					emit_bullet(p, Vector2.from_angle(rot + TAU * float(i) / float(RING)) * 88.0, bullet_b())
				sfx("explode", -13.0, 0.05)
				cycles_left -= 1
				if cycles_left <= 0:
					state = S.LEAVE
				else:
					state = S.IDLE
					timer = fire_cd(1.6)
		S.LEAVE:
			p.x -= 60.0 * delta
			set_texture("voidrim_well_0")
	enemy.global_position = p


# Turns each shot inside the field toward the well (keeping its speed), harder near the core.
func _bend(p: Vector2, delta: float) -> void:
	if enemy.bullet_container == null:
		return
	var r2: float = FIELD_R * FIELD_R
	for node: Node in enemy.bullet_container.get_children():
		var b: GameBullet = node as GameBullet
		if b == null:
			continue
		var d: Vector2 = p - b.global_position
		var dd: float = d.length_squared()
		if dd > r2 or dd < 9.0:
			continue
		var k: float = 1.0 - sqrt(dd) / FIELD_R
		var rate: float = (TURN_PLAYER if b.is_player_bullet else TURN_ENEMY) * k * delta
		var turn: float = clampf(angle_difference(b.velocity.angle(), d.angle()), -rate, rate)
		b.velocity = b.velocity.rotated(turn)
		if b.is_player_bullet and not b.keep_upright:
			b.rotation = b.velocity.angle()


func draw() -> void:
	match state:
		S.CHARGE:
			var k: float = 1.0 - clampf(timer / CHARGE_TIME, 0.0, 1.0)
			for i: int in range(3):
				var r: float = fposmod(FIELD_R * (1.0 - k) - float(i) * 22.0, FIELD_R) + 6.0
				enemy.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(0.7, 0.45, 1.0, 0.12 + 0.25 * k), 1.0)
		S.ACTIVE:
			enemy.draw_arc(Vector2.ZERO, FIELD_R, 0.0, TAU, 40, Color(0.7, 0.45, 1.0, 0.22), 1.0)
			for i2: int in range(4):
				var a0: float = -spin * 0.5 + float(i2) * PI * 0.5
				var r2: float = fposmod(age * 40.0 + float(i2) * 20.0, FIELD_R - 8.0) + 8.0
				enemy.draw_arc(Vector2.ZERO, FIELD_R - r2 + 8.0, a0, a0 + 1.4, 10, Color(0.75, 0.55, 1.0, 0.1 + 0.2 * (r2 / FIELD_R)), 1.0)
			enemy.draw_circle(Vector2.ZERO, 9.0, Color(0.6, 0.35, 1.0, 0.12 + 0.08 * sin(age * 20.0)))
	draw_hp_bar(16.0, -12.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#b070ff"), 10)
