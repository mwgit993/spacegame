extends "res://scripts/stages/stage_enemy.gd"

# ORE HAULER: a slow, tough freighter crossing the cavern. Before each dump its hazard lamps
# flash and the drop zone lights up (telegraph); then it empties its hopper. High up (y < 150)
# the ore falls as a curtain of rocks below it; low down it flings the ore up in a fountain that
# arcs over and rains back down. After MAX_DUMPS it speeds away. Shot down, it spills one last
# fountain of ore.

const DUMP_WARN: float = 0.7
const MAX_DUMPS: int = 5
const ROCKS: int = 7
const SPEED: float = 30.0

var dumps_left: int = MAX_DUMPS
var high: bool = true


func setup() -> void:
	high = base_y < 150.0
	fire_timer = 1.2


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	var leaving: bool = dumps_left <= 0 or age > 16.0
	p.x -= (SPEED * 2.4 if leaving else SPEED) * delta
	p.y = clampf(base_y + sin(age * 0.9 + phase) * 7.0, 44.0, 232.0)
	enemy.global_position = p
	fire_timer -= delta
	if not on_screen(70.0, 450.0):
		fire_timer = maxf(fire_timer, DUMP_WARN)   # the full telegraph always plays on screen
	var warning: bool = dumps_left > 0 and fire_timer < DUMP_WARN
	set_texture("mines_hauler_1" if warning and int(age * 10.0) % 2 == 0 else "mines_hauler_0")
	if dumps_left > 0 and fire_timer <= 0.0 and on_screen(70.0, 450.0):
		fire_timer = fire_cd(2.3)
		dumps_left -= 1
		_dump(false)
		sfx("explode", -15.0, 0.15)


func _dump(dying: bool) -> void:
	var origin: Vector2 = enemy.global_position + Vector2(4.0, -6.0)
	for i: int in range(ROCKS):
		var t: float = (float(i) + 0.5) / float(ROCKS)
		var v: Vector2
		var g: float
		if high and not dying:
			v = Vector2(lerpf(-60.0, 26.0, t), 18.0 + 22.0 * absf(t - 0.5))
			g = 150.0
		else:
			v = Vector2(lerpf(-78.0, 22.0, t), -(160.0 + 40.0 * sin(t * PI)))
			g = 175.0
		var b: GameBullet = emit_bullet(origin + Vector2(lerpf(-10.0, 10.0, t), 0.0), v, "mines_ore", dying, 3.0)
		if b != null:
			b.gravity_pull = g


func draw() -> void:
	draw_hp_bar(36.0, -17.0)
	if dumps_left > 0 and fire_timer > 0.0 and fire_timer < DUMP_WARN:
		var k: float = 1.0 - fire_timer / DUMP_WARN
		var a: float = (0.06 + 0.1 * k) * (0.6 + 0.4 * sin(age * 30.0))
		var col: Color = Color(1.0, 0.72, 0.2, a)
		if high:
			# The curtain's footprint: a widening column under the hopper.
			var floor_dy: float = 256.0 - enemy.global_position.y
			enemy.draw_colored_polygon(PackedVector2Array([Vector2(-8.0, 8.0), Vector2(12.0, 8.0), Vector2(26.0, floor_dy), Vector2(-62.0, floor_dy)]), col)
		else:
			enemy.draw_colored_polygon(PackedVector2Array([Vector2(-8.0, -10.0), Vector2(12.0, -10.0), Vector2(-20.0, 34.0 - enemy.global_position.y), Vector2(-90.0, 34.0 - enemy.global_position.y)]), col)
		draw_glint(Vector2(-6.0, -4.0), fire_timer, DUMP_WARN, Color(1.0, 0.75, 0.2))
		draw_glint(Vector2(14.0, -4.0), fire_timer, DUMP_WARN, Color(1.0, 0.75, 0.2))


func on_death() -> void:
	high = false
	_dump(true)
	sparks(enemy.global_position, Color("#7ef4ff"), 10)
