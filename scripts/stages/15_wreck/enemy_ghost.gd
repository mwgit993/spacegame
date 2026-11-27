extends "res://scripts/stages/stage_enemy.gd"

# Ghost frigate: phases in and out of reality. It glides in solid, fires a fan (charge glint
# first), then fades out: while faded it is intangible (no collision, out of the "enemies"
# group, immune) and slides to a new spot. Re-forming is telegraphed: its outline flickers
# and firms up over FORM_TIME before it can be hit (or hit you) again. After CYCLES it leaves.

enum S { ENTER, SOLID, FADE, PHASED, FORM, LEAVE }

const FADE_TIME: float = 0.4
const PHASED_TIME: float = 1.3
const FORM_TIME: float = 0.55
const CYCLES: int = 3

var state: S = S.ENTER
var timer: float = 0.0
var target: Vector2 = Vector2.ZERO
var cycles_left: int = CYCLES
var intangible: bool = false
var shot_ready: bool = true
var alpha: float = 1.0  # drawn by draw() while fading (the sprite's flash shader ignores modulate)


func setup() -> void:
	target = Vector2(randf_range(330.0, 430.0), clampf(enemy.global_position.y, 50.0, 220.0))
	fire_timer = 0.9


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	var s: Sprite2D = sprite()
	match state:
		S.ENTER, S.SOLID:
			p = p.lerp(target, clampf(2.4 * delta, 0.0, 1.0))
			p.y += sin(age * 2.0) * 5.0 * delta
			if state == S.ENTER and p.distance_to(target) < 14.0:
				state = S.SOLID
				timer = 1.7
				shot_ready = true
				fire_timer = maxf(fire_timer, 0.45)
			if state == S.SOLID:
				timer -= delta
				fire_timer -= delta
				if shot_ready and fire_timer <= 0.0 and on_screen(80.0, 455.0):
					shot_ready = false
					var n: int = 4 if variant == 0 else 5
					var step: float = 0.17 if variant == 0 else 0.15
					for k: int in range(n):
						shoot_aimed(132.0 if variant == 0 else 118.0, bullet_b(), (float(k) - float(n - 1) * 0.5) * step)
					sfx("laser", -14.0, 0.1)
				if timer <= 0.0:
					cycles_left -= 1
					if cycles_left <= 0:
						state = S.LEAVE
					else:
						state = S.FADE
						timer = FADE_TIME
			alpha = 1.0
		S.FADE:
			timer -= delta
			var a: float = clampf(timer / FADE_TIME, 0.0, 1.0)
			alpha = 0.2 + 0.8 * a
			if a < 0.5 and not intangible:
				_set_intangible(true)
			if timer <= 0.0:
				state = S.PHASED
				timer = PHASED_TIME
				target = _pick_spot(p)
				sfx("zap", -17.0, 0.2)
		S.PHASED:
			timer -= delta
			p = p.lerp(target, clampf(3.0 * delta, 0.0, 1.0))
			alpha = 0.14 + 0.06 * sin(age * 9.0)
			if timer <= 0.0:
				state = S.FORM
				timer = FORM_TIME
		S.FORM:
			timer -= delta
			var k2: float = 1.0 - clampf(timer / FORM_TIME, 0.0, 1.0)
			var flick: float = 0.25 + 0.5 * k2 + 0.2 * float(int(age * 24.0) % 2)
			alpha = clampf(flick, 0.0, 1.0)
			if timer <= 0.0:
				_set_intangible(false)
				state = S.SOLID
				timer = 1.6
				shot_ready = true
				fire_timer = 0.45
				sparks(p, Color("#7cffc8"), 6)
		S.LEAVE:
			p.x -= 95.0 * delta
			alpha = 1.0
	s.visible = alpha >= 1.0
	set_texture("wreck_ghost_1" if int(age * 5.0) % 4 == 0 else "wreck_ghost_0")
	enemy.global_position = p


func _pick_spot(from: Vector2) -> Vector2:
	var pp: Vector2 = player_pos()
	var c: Vector2 = from
	for i: int in range(8):
		c = Vector2(randf_range(290.0, 435.0), clampf(pp.y + randf_range(-70.0, 70.0), 48.0, 222.0))
		if c.distance_to(from) > 60.0 and c.distance_to(pp) > 120.0:
			break
	return c


func _set_intangible(on: bool) -> void:
	intangible = on
	if on:
		enemy.collision_layer = 0
		enemy.remove_from_group("enemies")
	else:
		enemy.collision_layer = 4
		enemy.add_to_group("enemies")


func modify_damage(dmg: float) -> float:
	return 0.0 if intangible else dmg


func draw() -> void:
	if alpha < 1.0:
		var t: Texture2D = PixelArt.tex("wreck_ghost_0")
		enemy.draw_texture(t, (-t.get_size() * 0.5).round(), Color(0.55, 1.0, 0.82, alpha))
	match state:
		S.SOLID:
			if shot_ready:
				draw_glint(Vector2(-14.0, 1.0), fire_timer, 0.4, Color(0.9, 0.4, 1.0))
		S.PHASED:
			# a faint shimmer trail where it slides
			var to: Vector2 = target - enemy.global_position
			enemy.draw_line(Vector2.ZERO, to * 0.3, Color(0.5, 1.0, 0.8, 0.12), 1.0)
		S.FORM:
			var k: float = 1.0 - clampf(timer / FORM_TIME, 0.0, 1.0)
			var a: float = 0.25 + 0.5 * k
			var r: Rect2 = Rect2(Vector2(-16.0, -10.0) * (1.6 - 0.6 * k), Vector2(32.0, 20.0) * (1.6 - 0.6 * k))
			enemy.draw_rect(r, Color(0.5, 1.0, 0.8, a * (0.5 + 0.5 * float(int(age * 20.0) % 2))), false, 1.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#7cffc8"), 10)
