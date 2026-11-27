extends "res://scripts/stages/stage_enemy.gd"

# DUST DEVIL: a sandstone obelisk planted in the dunes, wrapped in a whirling dust devil, riding
# the scrolling ground. Before each attack the whirl tightens and speeds up and the eye glyph
# lights (SPINUP seconds of telegraph); then it sprays a two-arm spiral of glyph shards over the
# upper arc for SPIRAL seconds. CYCLES spirals, then it just rides away.

enum Phase { IDLE, SPIN, FIRE, DONE }

const FLOOR_Y: float = 241.0
const GROUND_SCROLL: float = 40.0
const SPINUP: float = 0.8
const SPIRAL: float = 1.85
const SHOT_GAP: float = 0.13
const CYCLES: int = 2
const EYE: Vector2 = Vector2(0.0, -8.0)

var state: Phase = Phase.IDLE
var timer: float = 0.0
var shot_t: float = 0.0
var ang: float = 0.0
var turn: float = 1.0
var cycles_left: int = CYCLES
var whirl: float = 0.0          # swirl angle
var power: float = 0.35         # swirl intensity 0..1


func setup() -> void:
	enemy.global_position.y = FLOOR_Y
	base_y = FLOOR_Y
	fire_timer = 0.9
	turn = 1.0 if variant == 0 else -1.0
	whirl = randf() * TAU


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= GROUND_SCROLL * delta
	p.y = FLOOR_Y
	enemy.global_position = p
	var target_power: float = 0.35
	match state:
		Phase.IDLE, Phase.DONE:
			fire_timer -= delta
			if state == Phase.IDLE and fire_timer <= 0.0 and on_screen(60.0, 450.0):
				state = Phase.SPIN
				timer = SPINUP
				sfx("boss_hp_tick", -15.0, 0.1)
		Phase.SPIN:
			target_power = 1.0
			timer -= delta
			if timer <= 0.0:
				state = Phase.FIRE
				timer = SPIRAL
				shot_t = 0.0
				ang = PI * 1.5 + randf_range(-0.5, 0.5)
				sfx("laser", -14.0, 0.05)
		Phase.FIRE:
			target_power = 1.0
			timer -= delta
			shot_t -= delta
			while shot_t <= 0.0:
				shot_t += SHOT_GAP
				for arm: int in range(2):
					var d: Vector2 = Vector2.from_angle(ang + float(arm) * PI)
					if d.y < 0.15:
						emit_bullet(p + EYE + d * 4.0, d * 92.0, bullet_b())
				ang += 0.36 * turn
			if timer <= 0.0:
				cycles_left -= 1
				if cycles_left > 0:
					state = Phase.IDLE
					fire_timer = fire_cd(1.8)
				else:
					state = Phase.DONE
	power = move_toward(power, target_power, delta * 1.6)
	whirl += delta * (3.0 + 9.0 * power) * turn
	set_texture("desert_devil_1" if (state == Phase.FIRE or (state == Phase.SPIN and int(age * 14.0) % 2 == 0)) else "desert_devil_0")


func draw() -> void:
	# The dust devil: rings of grit whirling around the obelisk, a funnel widening upward. Grit in
	# front of the obelisk is brighter than grit behind it.
	for i: int in range(7):
		var h: float = float(i) / 6.0
		var ry: float = 16.0 - h * 44.0
		var r: float = 5.0 + h * (8.0 + 8.0 * power)
		for j: int in range(6):
			var a: float = whirl * (1.0 + h * 0.4) + float(j) * TAU / 6.0 + float(i) * 0.7
			var front: bool = sin(a) > 0.0
			var x: float = cos(a) * r
			var y: float = ry + sin(a) * r * 0.22
			var alpha: float = (0.3 + 0.5 * power) * (1.0 if front else 0.45) * (1.0 - h * 0.35)
			enemy.draw_rect(Rect2(floorf(x), floorf(y), 2.0 if front else 1.0, 1.0), Color(0.88, 0.65, 0.42, alpha))
	if state == Phase.SPIN:
		draw_glint(EYE, timer, SPINUP, Color(0.2, 1.0, 0.85))
	draw_hp_bar(14.0, -22.0)


func on_death() -> void:
	sparks(enemy.global_position + EYE, Color("#28f0d4"), 6)
	sparks(enemy.global_position, Color("#e0b878"), 10)
