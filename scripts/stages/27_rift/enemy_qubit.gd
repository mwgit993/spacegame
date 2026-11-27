extends "res://scripts/stages/stage_enemy.gd"

# Superposition drone: in two places at once. It glides in uncertain: two translucent copies, A
# and B (one above the other, or on a slant for variant 1), joined by a flickering dotted line.
# Its body really flickers between them (SWAP), so a shot lands on whichever copy is real at
# that instant. It collapses the moment it is hit (where it was hit), or when the ship lines up
# level with one copy for OBSERVE_TIME (looked at, a bracket closing round that copy shows it);
# left alone for DECOHERE seconds it collapses by itself, at random, flashing out a ring of
# shots (the copies shiver for the last DECOHERE_WARN seconds). Only a collapsed drone shoots:
# aimed three-shot fans after a charge glint. After FIGHT_TIME it slips away.

enum S { SUPER, COLLAPSE, FIGHT, LEAVE }

const SPLIT: float = 24.0
const SWAP: float = 0.08
const OBSERVE_TIME: float = 0.32
const OBSERVE_BAND: float = 9.0
const DECOHERE: float = 3.4
const DECOHERE_WARN: float = 0.8
const COLLAPSE_TIME: float = 0.32
const FIGHT_TIME: float = 6.2

var state: S = S.SUPER
var timer: float = 0.0
var hold_x: float = 380.0
var center: Vector2 = Vector2.ZERO
var axis: Vector2 = Vector2.DOWN
var on_b: bool = false
var swap_t: float = 0.0
var observe: float = 0.0
var obs_side: int = -1
var hit_side: int = -1
var lost: Vector2 = Vector2.ZERO
var super_t: float = 0.0
var anchor: Vector2 = Vector2.ZERO
var self_collapse: bool = false


func setup() -> void:
	center = enemy.global_position
	hold_x = randf_range(300.0, 420.0)
	axis = Vector2.DOWN if variant == 0 else Vector2(0.55, 0.84).normalized()
	center.y = clampf(center.y, 40.0 + SPLIT, 240.0 - SPLIT)
	fire_timer = 0.9
	sprite().modulate = Color(0.75, 0.95, 1.0, 0.55)


func _copy(side: int) -> Vector2:
	return center + axis * SPLIT * (1.0 if side == 1 else -1.0)


func tick(delta: float) -> void:
	match state:
		S.SUPER:
			if center.x > hold_x:
				center.x = maxf(hold_x, center.x - 120.0 * delta)
			else:
				center.x -= 6.0 * delta
			center.y += sin(age * 1.7 + phase) * 9.0 * delta
			center.y = clampf(center.y, 40.0 + SPLIT, 240.0 - SPLIT)
			swap_t -= delta
			if swap_t <= 0.0:
				swap_t = SWAP
				on_b = not on_b
			enemy.global_position = _copy(1 if on_b else 0)
			var s: Sprite2D = sprite()
			s.modulate.a = 0.45 + 0.2 * float(int(age * 30.0) % 2)
			if on_screen(80.0, 455.0):
				super_t += delta
				# observed: the ship sits level with one copy (and is to its left)
				var pp: Vector2 = player_pos()
				var seen: int = -1
				for side: int in range(2):
					var cp: Vector2 = _copy(side)
					if absf(pp.y - cp.y) < OBSERVE_BAND and pp.x < cp.x:
						seen = side
				if seen >= 0 and seen == obs_side:
					observe += delta
				elif seen >= 0:
					obs_side = seen
					observe = delta
				else:
					observe = maxf(0.0, observe - delta * 2.0)
				if hit_side >= 0:
					_collapse(hit_side, false)
				elif observe >= OBSERVE_TIME:
					_collapse(obs_side, false)
				elif super_t >= DECOHERE:
					_collapse(randi() % 2, true)
			elif hit_side >= 0:
				_collapse(hit_side, false)
		S.COLLAPSE:
			timer -= delta
			enemy.global_position = anchor
			if timer <= 0.0:
				state = S.FIGHT
				timer = FIGHT_TIME
				fire_timer = maxf(fire_timer, 0.55)
				set_texture("rift_qubit_1")
		S.FIGHT:
			timer -= delta
			var p: Vector2 = anchor + Vector2(sin(age * 1.3) * 6.0, sin(age * 2.1 + phase) * 10.0)
			enemy.global_position = p
			anchor.x -= 8.0 * delta
			fire_timer -= delta
			if fire_timer < 0.3 and fire_timer > 0.0:
				set_texture("rift_qubit_2")
			if fire_timer <= 0.0 and on_screen(80.0, 455.0):
				fire_timer = fire_cd(1.75)
				for k: int in range(-1, 2):
					shoot_aimed(132.0, bullet_a(), float(k) * 0.15)
				set_texture("rift_qubit_1")
				sfx("laser", -16.0, 0.08)
			if timer <= 0.0:
				state = S.LEAVE
		S.LEAVE:
			var p2: Vector2 = enemy.global_position
			p2.x -= 120.0 * delta
			p2.y += sin(age * 2.0) * 20.0 * delta
			enemy.global_position = p2


func _collapse(side: int, by_itself: bool) -> void:
	state = S.COLLAPSE
	timer = COLLAPSE_TIME
	anchor = _copy(side)
	lost = _copy(1 - side)
	self_collapse = by_itself
	enemy.global_position = anchor
	sprite().modulate = Color.WHITE
	set_texture("rift_qubit_1")
	sparks(anchor, Color("#c8faff"), 6)
	sparks(lost, Color("#ffb030"), 4)
	sfx("shield_hit", -14.0, 0.1)
	if by_itself:
		# decoherence: the wave function snaps and flings out a ring
		var rot: float = randf() * TAU
		for i: int in range(8):
			emit_bullet(anchor, Vector2.from_angle(rot + TAU * float(i) / 8.0) * 92.0, bullet_b())


func modify_damage(dmg: float) -> float:
	if state == S.SUPER and hit_side < 0:
		hit_side = 1 if on_b else 0
	return dmg


func draw() -> void:
	var here: Vector2 = enemy.global_position
	var t: Texture2D = PixelArt.tex("rift_qubit_0")
	var half: Vector2 = (t.get_size() * 0.5).round()
	match state:
		S.SUPER:
			var other: Vector2 = _copy(0 if on_b else 1) - here
			var shiver: Vector2 = Vector2.ZERO
			var warn: float = super_t - (DECOHERE - DECOHERE_WARN)
			if warn > 0.0:
				shiver = Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
			enemy.draw_texture(t, other - half + shiver, Color(1.0, 0.85, 0.6, 0.5 + 0.15 * float(int(age * 30.0 + 1.0) % 2)))
			# entanglement: a dotted line between the copies, cyan and amber dashes trading places
			var n: int = 7
			for i: int in range(1, n):
				var k: float = float(i) / float(n)
				var dp: Vector2 = (other * k).floor()
				var cyan: bool = (i + int(age * 12.0)) % 2 == 0
				enemy.draw_rect(Rect2(dp, Vector2(1.0, 1.0)), Color(0.3, 0.9, 1.0, 0.55) if cyan else Color(1.0, 0.7, 0.2, 0.55))
			# the copy being looked at: a bracket closing in
			if obs_side >= 0 and observe > 0.0:
				var op: Vector2 = _copy(obs_side) - here
				var r: float = lerpf(15.0, 8.0, clampf(observe / OBSERVE_TIME, 0.0, 1.0))
				var col: Color = Color(0.85, 1.0, 1.0, 0.75)
				for corner: int in range(4):
					var sx: float = -1.0 if corner % 2 == 0 else 1.0
					var sy: float = -1.0 if corner < 2 else 1.0
					var cpt: Vector2 = op + Vector2(sx * r, sy * r)
					enemy.draw_line(cpt, cpt - Vector2(sx * 3.0, 0.0), col, 1.0)
					enemy.draw_line(cpt, cpt - Vector2(0.0, sy * 3.0), col, 1.0)
			if warn > 0.0:
				# about to decohere: a ring tightens on both copies
				var kk: float = clampf(warn / DECOHERE_WARN, 0.0, 1.0)
				var wc: Color = Color(1.0, 0.75, 0.3, 0.3 + 0.5 * kk)
				enemy.draw_arc(Vector2.ZERO, 14.0 - 5.0 * kk, 0.0, TAU, 16, wc, 1.0)
				enemy.draw_arc(other, 14.0 - 5.0 * kk, 0.0, TAU, 16, wc, 1.0)
		S.COLLAPSE:
			var k2: float = 1.0 - clampf(timer / COLLAPSE_TIME, 0.0, 1.0)
			enemy.draw_arc(Vector2.ZERO, 5.0 + 16.0 * k2, 0.0, TAU, 20, Color(0.9, 1.0, 1.0, 0.8 * (1.0 - k2)), 1.0)
			var lp: Vector2 = lost - here
			var sc: float = 1.0 - k2
			enemy.draw_texture_rect(t, Rect2(lp - half * sc, half * 2.0 * sc), false, Color(1.0, 0.6, 0.2, 0.5 * sc))
			enemy.draw_line(lp + Vector2(-4.0, -4.0) * sc, lp + Vector2(4.0, 4.0) * sc, Color(1.0, 0.7, 0.3, 0.7 * sc), 1.0)
			enemy.draw_line(lp + Vector2(-4.0, 4.0) * sc, lp + Vector2(4.0, -4.0) * sc, Color(1.0, 0.7, 0.3, 0.7 * sc), 1.0)
		S.FIGHT:
			draw_glint(Vector2(-3.0, 0.0), fire_timer, 0.3, Color(0.3, 0.9, 1.0))
	if state != S.SUPER:
		draw_hp_bar(18.0, -14.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#3ce8ff"), 8)
	sparks(enemy.global_position, Color("#c8a8ff"), 6)
