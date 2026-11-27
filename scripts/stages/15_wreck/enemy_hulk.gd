extends "res://scripts/stages/stage_enemy.gd"

# Mine-laying hulk: a broken hull section drifting slowly across, sparking. Its belly hatch
# glows open (the telegraph) and drops a mine, MINES times at most (the mines are children: no
# Scrap); its broken turret also takes the odd aimed potshot. Tough, with an HP bar.

const MINES: int = 3
const HATCH: Vector2 = Vector2(2.0, 12.0)
const OPEN_TIME: float = 0.5
const TURRET: Vector2 = Vector2(6.0, -12.0)

var mines_left: int = MINES
var drop_timer: float = 1.4
var spark_t: float = 0.5


func setup() -> void:
	fire_timer = 2.0
	drop_timer = 1.2 + 0.4 * randf()


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= 27.0 * delta
	p.y = base_y + sin(age * 0.7 + phase) * 10.0
	enemy.global_position = p
	sprite().rotation = sin(age * 0.9) * 0.05
	var on: bool = on_screen(110.0, 450.0)
	if mines_left > 0 and on:
		drop_timer -= delta
		if drop_timer <= 0.0:
			mines_left -= 1
			drop_timer = fire_cd(1.9)
			var down: float = 1.0 if p.y < 150.0 else -1.0
			spawn_child("mine", p + HATCH * Vector2(1.0, down), Vector2(-14.0, 55.0 * down))
			sfx("missile", -15.0, 0.1)
	set_texture("wreck_hulk_1" if mines_left > 0 and drop_timer < OPEN_TIME and on else "wreck_hulk_0")
	fire_timer -= delta
	if fire_timer <= 0.0 and on_screen(100.0, 455.0):
		fire_timer = fire_cd(2.7)
		shoot_aimed_from(p + TURRET, 125.0, bullet_a())
	spark_t -= delta
	if spark_t <= 0.0:
		spark_t = randf_range(0.25, 0.7)
		sparks(p + Vector2(randf_range(-20.0, 20.0), randf_range(-8.0, 8.0)), Color("#ffb060"), 2)


func draw() -> void:
	if mines_left > 0 and drop_timer < OPEN_TIME:
		var k: float = 1.0 - clampf(drop_timer / OPEN_TIME, 0.0, 1.0)
		var down: float = 1.0 if enemy.global_position.y < 150.0 else -1.0
		enemy.draw_circle(HATCH * Vector2(1.0, down), 2.0 + 4.0 * k, Color(1.0, 0.3, 0.3, 0.15 + 0.3 * k))
	draw_glint(TURRET, fire_timer, 0.35, Color(1.0, 0.4, 0.75))
	draw_hp_bar(40.0, -17.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#7cffc8"), 10)
	sparks(enemy.global_position + Vector2(-12.0, 0.0), Color("#ffb060"), 8)
