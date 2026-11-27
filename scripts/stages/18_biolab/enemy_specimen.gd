extends "res://scripts/stages/stage_enemy.gd"

# Escaped specimen: mutates as it's hurt. At 70% and 35% HP it convulses (MUTATE_TIME, the
# telegraph: it flashes and swells) and comes out a worse form:
#   form 0  a one-eyed blob that creeps toward the ship and spits single shots
#   form 1  sprouts bone spikes, moves faster, spits 3-way fans
#   form 2  an armoured horror (takes 0.75x damage): shakes, then lunges at the ship and
#           sprays a ring as it goes
# Hit it hard and finish it, or it gets nastier. Leaves after LIFETIME.

enum S { CREEP, MUTATE, WIND, LUNGE }

const MUTATE_TIME: float = 0.45
const WIND_TIME: float = 0.55
const LIFETIME: float = 16.0

var state: S = S.CREEP
var timer: float = 0.0
var form: int = 0
var pending: bool = false
var lunge_dir: Vector2 = Vector2.LEFT


func setup() -> void:
	fire_timer = 1.3


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	if pending and state == S.CREEP:
		pending = false
		state = S.MUTATE
		timer = MUTATE_TIME
		sfx("shield_hit", -12.0, 0.1)
	var s: Sprite2D = sprite()
	match state:
		S.CREEP:
			var target: Vector2 = Vector2(maxf(player_pos().x + 170.0, 300.0 - float(form) * 40.0), player_pos().y)
			if age > LIFETIME:
				target = Vector2(-80.0, p.y)
			var spd: float = 34.0 + float(form) * 22.0
			p = p.move_toward(target, spd * delta)
			if p.x > 440.0:
				p.x -= 60.0 * delta
			p.y += sin(age * 3.0 + phase) * 10.0 * delta
			var squish: float = sin(age * 6.0) * 0.06
			s.scale = Vector2(1.0 + squish, 1.0 - squish)
			fire_timer -= delta
			if fire_timer <= 0.0 and on_screen(90.0, 455.0):
				match form:
					0:
						fire_timer = fire_cd(2.0)
						shoot_aimed(130.0, bullet_b())
					1:
						fire_timer = fire_cd(1.5)
						for k: int in [-1, 0, 1]:
							shoot_aimed(135.0, bullet_b(), float(k) * 0.18)
					_:
						state = S.WIND
						timer = WIND_TIME
						fire_timer = fire_cd(2.6)
		S.MUTATE:
			timer -= delta
			var k2: float = 1.0 - clampf(timer / MUTATE_TIME, 0.0, 1.0)
			s.scale = Vector2.ONE * (1.0 + 0.25 * sin(k2 * PI * 3.0))
			p += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
			if timer <= 0.0:
				form = mini(2, form + 1)
				set_texture("biolab_spec_%d" % form)
				s.scale = Vector2.ONE
				state = S.CREEP
				fire_timer = 0.6
				sparks(p, Color("#c05a84"), 10)
				sfx("explode", -13.0, 0.1)
		S.WIND:
			timer -= delta
			p += Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
			if timer <= 0.0:
				state = S.LUNGE
				timer = 0.7
				lunge_dir = (player_pos() - p).normalized()
				var rot: float = randf() * TAU
				for i: int in range(6):
					emit_bullet(p, Vector2.from_angle(rot + TAU * float(i) / 6.0) * 95.0, bullet_a())
				sfx("missile", -12.0, 0.1)
		S.LUNGE:
			timer -= delta
			p += lunge_dir * 210.0 * delta
			p.y = clampf(p.y, 36.0, 244.0)
			if timer <= 0.0:
				state = S.CREEP
	enemy.global_position = p


func modify_damage(dmg: float) -> float:
	var out: float = dmg * (0.75 if form >= 2 else 1.0)
	var after: float = enemy.hp - out
	if form == 0 and after < enemy.max_hp * 0.7 and after > 0.0:
		pending = true
	elif form == 1 and after < enemy.max_hp * 0.35 and after > 0.0:
		pending = true
	return out


func draw() -> void:
	match state:
		S.CREEP:
			if form < 2:
				draw_glint(Vector2(-6.0 - float(form) * 2.0, 0.0), fire_timer, 0.35, Color(0.7, 1.0, 0.3))
		S.MUTATE:
			var k: float = 1.0 - clampf(timer / MUTATE_TIME, 0.0, 1.0)
			enemy.draw_circle(Vector2.ZERO, 8.0 + 8.0 * k, Color(0.9, 0.35, 0.6, 0.25 * (1.0 - k) + 0.1))
		S.WIND:
			var k2: float = 1.0 - clampf(timer / WIND_TIME, 0.0, 1.0)
			var d: Vector2 = (player_pos() - enemy.global_position).normalized()
			enemy.draw_line(d * 14.0, d * (30.0 + 40.0 * k2), Color(1.0, 0.3, 0.3, 0.3 + 0.4 * k2), 2.0)
			enemy.draw_arc(Vector2.ZERO, 16.0 - 4.0 * k2, 0.0, TAU, 16, Color(1.0, 0.3, 0.4, 0.3 + 0.3 * k2), 1.0)
	draw_hp_bar(20.0 + float(form) * 6.0, -12.0 - float(form) * 3.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#7ad830"), 8)
	sparks(enemy.global_position, Color("#c05a84"), 8)
