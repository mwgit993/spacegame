extends "res://scripts/stages/stage_enemy.gd"

# Salvage drone: holds a scrap plate in front of itself as a shield. While it has the plate,
# hits mostly dent the plate (the drone takes 15%); the plate cracks, then breaks off and
# tumbles away. Left without one for a while, the drone reels in a new piece of debris with a
# green tractor beam (1 s, clearly visible, and it can't shoot meanwhile): REGRABS times at
# most. It fires paired shots past the plate's edges (charge glint first), then leaves.

enum S { HOLD, TRACTOR, LEAVE }

const PLATE_OFFSET: Vector2 = Vector2(-11.0, 0.0)
const TRACTOR_TIME: float = 1.0
const REGRABS: int = 1
const LIFETIME: float = 15.0

var state: S = S.HOLD
var timer: float = 0.0
var target_x: float = 400.0
var shield_max: float = 1.0
var shield: float = 1.0
var bare_time: float = 0.0
var regrabs_left: int = REGRABS
var plate: Sprite2D = null
var falling: Sprite2D = null
var fall_v: Vector2 = Vector2.ZERO
var chunk_from: Vector2 = Vector2.ZERO


func setup() -> void:
	target_x = randf_range(360.0, 432.0)
	shield_max = enemy.max_hp * 0.9
	fire_timer = 1.2 + 0.3 * float(variant)
	_attach_plate()


func _attach_plate() -> void:
	shield = shield_max
	plate = Sprite2D.new()
	plate.texture = PixelArt.tex("wreck_plate_0")
	plate.material = enemy._mat
	plate.show_behind_parent = true
	plate.position = PLATE_OFFSET
	enemy.add_child(plate)


func _drop_plate() -> void:
	if plate == null:
		return
	falling = plate
	plate = null
	falling.material = null
	fall_v = Vector2(-30.0, -40.0)
	bare_time = 0.0
	sparks(enemy.global_position + PLATE_OFFSET, Color("#d09456"), 8)
	sfx("explode", -14.0, 0.1)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	if falling != null:
		fall_v.y += 260.0 * delta
		falling.position += fall_v * delta
		falling.rotation += 3.0 * delta
		if falling.position.y > 300.0:
			falling.queue_free()
			falling = null
	match state:
		S.HOLD:
			p.x = lerpf(p.x, target_x, clampf(2.0 * delta, 0.0, 1.0))
			var want_y: float = clampf(player_pos().y, 50.0, 220.0)
			p.y = lerpf(p.y, want_y, clampf(0.7 * delta, 0.0, 1.0)) + sin(age * 2.6) * 8.0 * delta
			fire_timer -= delta
			if fire_timer <= 0.0 and on_screen(90.0, 455.0):
				fire_timer = fire_cd(1.8)
				shoot_aimed_from(p + Vector2(-8.0, -12.0), 140.0, bullet_a(), 0.06)
				shoot_aimed_from(p + Vector2(-8.0, 12.0), 140.0, bullet_a(), -0.06)
				sfx("laser", -15.0, 0.1)
			if plate == null:
				bare_time += delta
				if bare_time > 2.2 and regrabs_left > 0 and on_screen(120.0, 455.0):
					state = S.TRACTOR
					timer = TRACTOR_TIME
					regrabs_left -= 1
					chunk_from = Vector2(randf_range(-30.0, 40.0), -p.y + 20.0)
					sfx("boss_hp_tick", -14.0, 0.0)
			if age > LIFETIME:
				state = S.LEAVE
		S.TRACTOR:
			timer -= delta
			p.y += sin(age * 6.0) * 6.0 * delta
			if timer <= 0.0:
				_attach_plate()
				shield = shield_max * 0.7
				state = S.HOLD
				fire_timer = maxf(fire_timer, 0.8)
				sparks(p + PLATE_OFFSET, Color("#7cffc8"), 6)
		S.LEAVE:
			p.x += 120.0 * delta
			p.y -= 30.0 * delta
	enemy.global_position = p
	set_texture("wreck_salvager_1" if state == S.TRACTOR and int(age * 12.0) % 2 == 0 else "wreck_salvager_0")
	if plate != null:
		plate.texture = PixelArt.tex("wreck_plate_1" if shield < shield_max * 0.5 else "wreck_plate_0")


func modify_damage(dmg: float) -> float:
	if plate == null:
		return dmg
	shield -= dmg * 0.85
	if enemy.fx != null and randf() < 0.3:
		enemy.fx.spawn_hit_sparks(enemy.global_position + PLATE_OFFSET + Vector2(-3.0, randf_range(-8.0, 8.0)), Color("#d09456"), 2)
	if shield <= 0.0:
		_drop_plate()
	return dmg * 0.15


func draw() -> void:
	if state == S.HOLD:
		draw_glint(Vector2(-8.0, -12.0), fire_timer, 0.35, Color(1.0, 0.4, 0.75))
		draw_glint(Vector2(-8.0, 12.0), fire_timer, 0.35, Color(1.0, 0.4, 0.75))
	elif state == S.TRACTOR:
		var k: float = 1.0 - clampf(timer / TRACTOR_TIME, 0.0, 1.0)
		var chunk: Vector2 = chunk_from.lerp(PLATE_OFFSET, k * k)
		var a: float = 0.25 + 0.2 * sin(age * 30.0)
		enemy.draw_line(Vector2(-4.0, -4.0), chunk, Color(0.5, 1.0, 0.75, a), 3.0)
		enemy.draw_line(Vector2(-4.0, -4.0), chunk, Color(0.85, 1.0, 0.95, a + 0.2), 1.0)
		var t: Texture2D = PixelArt.tex("wreck_chunk_%d" % (int(age * 3.0) % 2))
		enemy.draw_texture(t, (chunk - t.get_size() * 0.5).round())
	draw_hp_bar(16.0, -12.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#e8c030"), 8)
