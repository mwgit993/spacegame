extends "res://scripts/stages/stage_enemy.gd"

# STORM MANTA: glides through the storm in big slow swoops, flapping. Before each volley its
# wingtips crackle with lightning (telegraph, plus the charged sprite), then each wingtip
# releases a fan: the upper wing sprays up-left, the lower wing down-left, leaving a lane
# straight ahead. variant 1 swoops the other way round.

const CHARGE: float = 0.6
const SPEED: float = 52.0
const SWOOP: float = 46.0
const FAN: int = 3

var swoop_dir: float = 1.0


func setup() -> void:
	swoop_dir = -1.0 if variant == 1 else 1.0
	fire_timer = 1.3


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= SPEED * delta
	p.y = clampf(base_y + sin(age * 1.5 + phase) * SWOOP * swoop_dir, 44.0, 232.0)
	enemy.global_position = p
	fire_timer -= delta
	if not on_screen(70.0, 452.0):
		fire_timer = maxf(fire_timer, CHARGE)
	var charging: bool = fire_timer < CHARGE
	if charging:
		set_texture("storm_manta_2")
	else:
		set_texture("storm_manta_%d" % (int(age * 4.0) % 2))
	if fire_timer <= 0.0 and on_screen(70.0, 452.0):
		fire_timer = fire_cd(2.3)
		for side: float in [-1.0, 1.0]:
			var tip: Vector2 = p + Vector2(-4.0, side * 15.0)
			for k: int in range(FAN):
				var ang: float = PI - side * (0.18 + 0.2 * float(k))
				emit_bullet(tip, Vector2.from_angle(ang) * (128.0 + 10.0 * float(k)), bullet_b())
		sfx("zap", -13.0, 0.08)


# Lightning crackling between the wingtips and the body while it charges.
func draw() -> void:
	if fire_timer > 0.0 and fire_timer < CHARGE:
		var k: float = 1.0 - fire_timer / CHARGE
		for side: float in [-1.0, 1.0]:
			var tip: Vector2 = Vector2(-4.0, side * 15.0)
			var a: float = 0.35 + 0.55 * k
			var prev: Vector2 = tip
			for s: int in range(3):
				var jit: float = sin(age * 70.0 + float(s) * 2.3 + side) * 3.0
				var nxt: Vector2 = tip + Vector2(-3.0 - float(s) * 3.0 * k, side * (2.0 + float(s) * 2.0) * k + jit)
				enemy.draw_line(prev, nxt, Color(1.0, 0.95, 0.5, a), 1.0)
				prev = nxt
			draw_glint(tip, fire_timer, CHARGE, Color(0.4, 0.95, 1.0))
	draw_hp_bar(22.0, -20.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#5af0ff"), 9)
