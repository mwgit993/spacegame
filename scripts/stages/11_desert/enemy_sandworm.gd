extends "res://scripts/stages/stage_enemy.gd"

# SANDWORM: erupts from the floor. For WARN seconds sand ripples spread and spurts jump at the
# spot (the entrance telegraph, hidden and unhittable); then it bursts up to strike height near
# the player's level, rears back while its maw opens on a glowing throat (telegraph), spits two
# fans of hot sand at the player and sinks back into the dunes. It rides the scrolling ground the
# whole time, and only its head can be hit. The body below the sand line is cropped away.

const Art = preload("art.gd")

enum Phase { RISE, REAR, SPIT, SINK }

const WARN: float = 1.05
const FLOOR_Y: float = 257.0
const GROUND_SCROLL: float = 40.0
const REAR_TIME: float = 0.6
const FAN: int = 6
const MAW: Vector2 = Vector2(-5.0, -1.0)

var state: Phase = Phase.RISE
var timer: float = 0.0
var target_y: float = 170.0
var volleys_left: int = 2


func setup() -> void:
	enemy.global_position.y = FLOOR_Y
	base_y = FLOOR_Y
	warn_timer = WARN
	var s: Sprite2D = sprite()
	s.centered = false
	s.offset = -Art.WORM_HEAD
	s.region_enabled = true
	_crop()


func on_wake() -> void:
	target_y = clampf(player_pos().y + randf_range(-18.0, 18.0), 118.0, 196.0)
	state = Phase.RISE
	sfx("explode", -13.0, 0.1)
	sparks(Vector2(enemy.global_position.x, FLOOR_Y), Color("#e0b878"), 10)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= GROUND_SCROLL * delta
	match state:
		Phase.RISE:
			p.y = move_toward(p.y, target_y, 330.0 * delta)
			set_texture("desert_worm_0")
			if absf(p.y - target_y) < 0.5:
				state = Phase.REAR
				timer = REAR_TIME
				sfx("boss_hp_tick", -15.0, 0.1)
		Phase.REAR:
			timer -= delta
			p.y = target_y - sin((1.0 - timer / REAR_TIME) * PI * 0.5) * 6.0
			set_texture("desert_worm_1" if int(age * 14.0) % 3 != 0 else "desert_worm_0")
			if timer <= 0.0:
				state = Phase.SPIT
				timer = 0.0
		Phase.SPIT:
			set_texture("desert_worm_1")
			p.y = move_toward(p.y, target_y, 60.0 * delta)
			timer -= delta
			if timer <= 0.0:
				if volleys_left > 0:
					_spit(p, 0.0 if volleys_left == 2 else 0.065)
					volleys_left -= 1
					timer = 0.38 if volleys_left > 0 else 0.45
				else:
					state = Phase.SINK
		Phase.SINK:
			set_texture("desert_worm_0")
			p.y += 150.0 * delta
			if p.y > FLOOR_Y + 12.0:
				enemy.global_position = p
				leave()
				return
	enemy.global_position = p
	_crop()


func _spit(p: Vector2, off: float) -> void:
	for k: int in range(FAN):
		var a: float = (float(k) - float(FAN - 1) * 0.5) * 0.13 + off
		shoot_aimed_from(p + MAW, 125.0, "desert_sand", a)
	sfx("missile", -13.0, 0.1)


# Only the part of the column above the sand line is drawn.
func _crop() -> void:
	var s: Sprite2D = sprite()
	if s.texture == null:
		return
	var tw: float = float(s.texture.get_width())
	var th: float = float(s.texture.get_height())
	var vis: float = FLOOR_Y + 2.0 - (enemy.global_position.y - Art.WORM_HEAD.y)
	s.region_rect = Rect2(0.0, 0.0, tw, clampf(floorf(vis), 1.0, th))


func draw() -> void:
	# Sand churning where the body leaves the ground.
	var gy: float = FLOOR_Y - enemy.global_position.y + 1.0
	enemy.draw_set_transform(Vector2(0.0, gy), 0.0, Vector2(1.0, 0.35))
	enemy.draw_circle(Vector2.ZERO, 12.0, Color(0.45, 0.28, 0.2, 0.55))
	enemy.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i: int in range(5):
		var t: float = fposmod(age * 2.2 + float(i) * 0.21, 1.0)
		var gx: float = (float(i) - 2.0) * 5.0 + sin(float(i) * 1.7) * 2.0
		enemy.draw_rect(Rect2(gx, gy - t * 14.0 + t * t * 10.0, 1.0, 1.0), Color(0.88, 0.66, 0.44, 0.85 * (1.0 - t)))
	if state == Phase.REAR:
		draw_glint(MAW, timer, REAR_TIME, Color(1.0, 0.5, 0.2))
	draw_hp_bar(16.0, -15.0)


# Ripples spreading through the sand and spurts jumping up where it will burst out.
func draw_warning() -> void:
	var k: float = clampf(1.0 - warn_timer / WARN, 0.0, 1.0)
	enemy.draw_set_transform(Vector2(0.0, 0.0), 0.0, Vector2(1.0, 0.3))
	for i: int in range(3):
		var r: float = fposmod(age * 16.0 + float(i) * 7.0, 21.0) * (0.6 + 0.6 * k)
		enemy.draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 20, Color(0.95, 0.72, 0.45, 0.5 * (1.0 - r / 26.0)), 1.0)
	enemy.draw_circle(Vector2.ZERO, lerpf(2.0, 9.0, k), Color(0.12, 0.06, 0.06, 0.7))
	enemy.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for j: int in range(5):
		var t: float = fposmod(age * 3.0 + float(j) * 0.19, 1.0)
		var sx: float = (float(j) - 2.0) * 3.5
		var sy: float = -(t * 20.0 - t * t * 16.0) * (0.4 + k)
		enemy.draw_rect(Rect2(sx, sy, 1.0, 1.0), Color(0.9, 0.7, 0.45, 0.9 * (1.0 - t)))


func on_death() -> void:
	sparks(enemy.global_position, Color("#e0b878"), 10)
	sparks(enemy.global_position + MAW, Color("#ff6a3a"), 5)
