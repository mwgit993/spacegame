extends "res://scripts/stages/stage_enemy.gd"

# Strike marshal: a command ship that calls in air strikes. It takes position at the right edge,
# then marks a strip of the screen at the ship's height: a red band with chevrons racing along
# it and warning arrows blinking at the left edge (MARK_TIME, the telegraph). Then a flight of
# FLIGHT strike fighters screams in from behind along the strip, strafing as they go (children,
# no Scrap, capped). Between strikes it fires an aimed spread. After STRIKES strikes it leaves.

const StrikerScript = preload("enemy_striker.gd")

enum S { ENTER, MARK, CALL, REST, LEAVE }

const MARK_TIME: float = 1.15
const STRIKES: int = 2
const FLIGHT: int = 3
const STRIP_H: float = 22.0
const GUN: Vector2 = Vector2(-17.0, 3.0)

var state: S = S.ENTER
var timer: float = 0.0
var target_x: float = 420.0
var strip_y: float = 135.0
var strikes_left: int = STRIKES
var calls_left: int = 0
var call_t: float = 0.0
var shot_done: bool = false


func setup() -> void:
	target_x = randf_range(405.0, 435.0)
	fire_timer = 0.8


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		S.ENTER, S.REST:
			p.x = lerpf(p.x, target_x, clampf(2.4 * delta, 0.0, 1.0))
			p.y = base_y + sin(age * 1.4 + phase) * 10.0
			fire_timer -= delta
			if state == S.REST and not shot_done and fire_timer < 0.9 and on_screen(120.0, 455.0):
				shot_done = true
				shoot_spread_from(p + GUN, 3, 0.18, 135.0, bullet_a())
				sfx("laser", -15.0, 0.05)
			if fire_timer <= 0.0 and absf(p.x - target_x) < 24.0 and on_screen(120.0, 455.0):
				if strikes_left <= 0:
					state = S.LEAVE
				else:
					state = S.MARK
					timer = MARK_TIME
					strip_y = clampf(player_pos().y, 46.0, 230.0)
					sfx("boss_siren", -17.0, 0.0)
		S.MARK:
			timer -= delta
			p.y = base_y + sin(age * 1.4 + phase) * 10.0
			if timer <= 0.0:
				state = S.CALL
				calls_left = FLIGHT
				call_t = 0.0
		S.CALL:
			call_t -= delta
			if call_t <= 0.0 and calls_left > 0:
				call_t = 0.13
				if StrikerScript.count(enemy) < StrikerScript.CAP:
					var k: int = FLIGHT - calls_left
					var dy: float = 0.0 if k == 0 else (-6.0 if k == 1 else 6.0)
					spawn_child("striker", Vector2(-24.0 - float(k) * 10.0, strip_y + dy), Vector2(340.0, 0.0))
				calls_left -= 1
				if calls_left == 0:
					strikes_left -= 1
					state = S.REST
					shot_done = false
					fire_timer = fire_cd(2.6)
					sfx("missile", -12.0, 0.05)
		S.LEAVE:
			p += Vector2(70.0, -60.0 if base_y < 135.0 else 60.0) * delta
	enemy.global_position = p
	set_texture("mothership_marshal_1" if state == S.MARK or state == S.CALL else "mothership_marshal_0")


func draw() -> void:
	if state == S.MARK or state == S.CALL:
		var gp: Vector2 = enemy.global_position
		var k: float = 1.0 - clampf(timer / MARK_TIME, 0.0, 1.0) if state == S.MARK else 1.0
		var top: float = strip_y - STRIP_H * 0.5 - gp.y
		var left: float = -gp.x
		var flick: float = float(int(age * 14.0) % 2)
		enemy.draw_rect(Rect2(left, top, 480.0, STRIP_H), Color(1.0, 0.15, 0.25, 0.05 + 0.07 * k))
		enemy.draw_rect(Rect2(left, top, 480.0, 1.0), Color(1.0, 0.25, 0.35, 0.25 + 0.3 * k))
		enemy.draw_rect(Rect2(left, top + STRIP_H - 1.0, 480.0, 1.0), Color(1.0, 0.25, 0.35, 0.25 + 0.3 * k))
		# chevrons racing left to right along the strip: where the fighters will fly
		var cy: float = top + STRIP_H * 0.5
		var x0: float = fposmod(age * 260.0, 40.0)
		var cx: float = left + x0
		while cx < left + 480.0:
			var c: Color = Color(1.0, 0.35, 0.4, 0.18 + 0.2 * k)
			enemy.draw_line(Vector2(cx, cy - 4.0), Vector2(cx + 4.0, cy), c, 1.0)
			enemy.draw_line(Vector2(cx + 4.0, cy), Vector2(cx, cy + 4.0), c, 1.0)
			cx += 40.0
		# warning arrows on the left edge
		if flick > 0.0:
			var lx: float = left + 4.0
			enemy.draw_colored_polygon(PackedVector2Array([Vector2(lx, cy - 6.0), Vector2(lx + 7.0, cy), Vector2(lx, cy + 6.0)]), Color("#ff4c68"))
			enemy.draw_colored_polygon(PackedVector2Array([Vector2(lx + 7.0, cy - 6.0), Vector2(lx + 14.0, cy), Vector2(lx + 7.0, cy + 6.0)]), Color(1.0, 0.85, 0.35))
		# the beacon on the dish
		enemy.draw_circle(Vector2(-4.0, -6.0), 3.0 + 2.0 * flick, Color(1.0, 0.25, 0.3, 0.35))
	elif state == S.REST and not shot_done:
		draw_glint(GUN, fire_timer - 0.9, 0.35, Color(0.3, 0.9, 1.0))
	draw_hp_bar(28.0, -16.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#ff4058"), 10)
	sparks(enemy.global_position, Color("#40e8ff"), 5)
