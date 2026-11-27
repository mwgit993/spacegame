extends "res://scripts/stages/stage_boss.gd"

# GOD-MACHINE ITZAMAT. Three patterns, switching every 4 attacks:
#  0 SUN DISC          the halo throws out a ring of spokes (pairs of shots) with a two-spoke
#                      gap that turns every volley; the spokes it will fire next light up on the
#                      halo first. Phase 2 adds a counter-turning ring of single shots between
#                      them every other volley, phase 3 every volley.
#  1 EYE OF JUDGEMENT  it fixes its gaze: sight lines from both eyes lock onto where the ship is
#                      (flickering, the telegraph), then on the next attack it pours a stream of
#                      sun-fire down each line. Phase 2 adds tablet fans to the sides, phase 3 a
#                      third stream from its mouth.
#  2 GLYPH TABLETS     its arms lob glowing tablets in arcs; they pulse (with faint guide lines
#                      showing the burst) and on the next attack shatter into crosses, diagonal
#                      crosses from phase 2, six-way stars in phase 3, while the mouth spits a fan.
# rate_mult shortens the cooldowns; spd_bonus is scaled down for the dense patterns.

const EYES: Array[Vector2] = [Vector2(-3.0, -32.0), Vector2(15.0, -32.0)]
const MOUTH: Vector2 = Vector2(6.0, -18.0)
const HALO: Vector2 = Vector2(12.0, -24.0)
const HALO_R: float = 46.0
const STREAM: int = 8  # shots per gaze stream
const TABLETS: Array[Vector2] = [Vector2(-46.0, -29.0), Vector2(-46.0, 35.0), Vector2(51.0, -31.0), Vector2(49.0, 39.0)]

var _aim: Vector2 = Vector2.ZERO
var _locked: bool = false
var _tablets: Array = []
var _next_spin: float = 0.0
var _gap: int = 0


func setup() -> void:
	_next_spin = 0.0


func _spokes() -> int:
	return 10 + 2 * phase


func attack(rate_mult: float, spd_bonus: float) -> void:
	if pattern != 1:
		_locked = false
	if pattern != 2 and not _tablets.is_empty():
		_shatter()
	match pattern:
		0:
			_sun_disc(spd_bonus)
			wait(0.82 * rate_mult)
		1:
			if substep % 2 == 0 or not _locked:
				_aim = player_pos()
				_locked = true
				if phase >= 2:
					for k: int in range(-1, 2):
						shoot_aimed_from(pos() + TABLETS[0], 150.0 + spd_bonus * 0.5, bullet_b(), float(k) * 0.22)
				RetroSfx.play("boss_hp_tick", -9.0, 0.0)
				wait(maxf(0.62, 0.8 * rate_mult))
			else:
				_judgement(spd_bonus)
				_locked = false
				wait(0.92 * rate_mult)
		_:
			if substep % 2 == 0 or _tablets.is_empty():
				_throw_tablets()
				wait(0.85 * rate_mult)
			else:
				_shatter()
				shoot_spread_from(pos() + MOUTH, 3 + phase, 0.18, 150.0 + spd_bonus * 0.6, bullet_a())
				wait(0.76 * rate_mult)


func _sun_disc(spd_bonus: float) -> void:
	var n: int = _spokes()
	var spd: float = 80.0 + spd_bonus * 0.45
	var per: int = 2
	var origin: Vector2 = pos() + HALO
	for i: int in range(n):
		if i == _gap or i == (_gap + 1) % n:
			continue
		var a: float = _next_spin + TAU * float(i) / float(n)
		var d: Vector2 = Vector2.from_angle(a)
		if d.x > 0.35:
			continue
		for k: int in range(per):
			emit_bullet(origin + d * HALO_R, d * spd * (1.0 + 0.24 * float(k)), bullet_b())
	if phase >= 3 or (phase == 2 and substep % 2 == 1):
		for j: int in range(n):
			var a2: float = -_next_spin * 1.3 + TAU * (float(j) + 0.5) / float(n)
			var d2: Vector2 = Vector2.from_angle(a2)
			if d2.x > 0.2:
				continue
			emit_bullet(origin + d2 * (HALO_R - 6.0), d2 * spd * 1.12, bullet_a())
	_next_spin += 0.21
	_gap = (_gap + 3) % n
	RetroSfx.play("zap", -12.0, 0.08)


func _judgement(spd_bonus: float) -> void:
	var origins: Array[Vector2] = [pos() + EYES[0], pos() + EYES[1]]
	if phase >= 3:
		origins.append(pos() + MOUTH)
	var spd: float = 175.0 + spd_bonus * 0.5
	for o: Vector2 in origins:
		var d: Vector2 = (_aim - o).normalized()
		for k: int in range(10):
			var b: GameBullet = emit_bullet(o + d * 6.0, d * spd, "temple_ray")
			if b != null:
				b.slow_timer = 0.045 * float(k)
				b.slow_factor = 0.0
	if phase >= 2:
		shoot_spread_from(pos() + TABLETS[1], 5, 0.2, 140.0 + spd_bonus * 0.5, bullet_a())
	RetroSfx.play("laser", -8.0, 0.04)


func _throw_tablets() -> void:
	_tablets.clear()
	var count: int = 3 if phase < 2 else 4
	for i: int in range(count):
		var from: Vector2 = pos() + TABLETS[i]
		var v: Vector2 = Vector2(-(150.0 + 45.0 * float(i % 2) + randf_range(0.0, 30.0)), -(140.0 if i % 2 == 0 else 40.0) + randf_range(-20.0, 20.0))
		if i >= 2:
			v.x -= 40.0
		var b: GameBullet = emit_bullet(from, v, "temple_tablet", 5.0)
		if b != null:
			b.gravity_pull = 150.0
			_tablets.append(b)
	RetroSfx.play("missile", -10.0, 0.08)


func _shatter() -> void:
	var spd: float = 95.0 + 18.0 * float(phase - 1)
	for i: int in range(_tablets.size()):
		var tv: Variant = _tablets[i]
		if not is_instance_valid(tv):
			continue
		var t: GameBullet = tv as GameBullet
		var at: Vector2 = t.global_position
		t.queue_free()
		if at.x < 8.0 or at.y < 30.0 or at.y > 250.0:
			continue
		var dirs: int = 4 if phase < 3 else 6
		var rot: float = 0.0 if (phase < 2 or i % 2 == 0) else PI * 0.25
		for k: int in range(dirs):
			var d: Vector2 = Vector2.from_angle(rot + TAU * float(k) / float(dirs))
			emit_bullet(at, d * spd, bullet_b())
			if phase < 3:
				emit_bullet(at, d * spd * 0.62, bullet_b())
		if boss.fx != null:
			boss.fx.spawn_hit_sparks(at, Color("#3cc890"), 8)
	_tablets.clear()
	RetroSfx.play("explode", -12.0, 0.1)


func draw() -> void:
	var t: float = boss._fire_timer
	# a slow shimmer round the halo
	var sh: float = 0.5 + 0.5 * sin(age * 2.4)
	boss.draw_arc(HALO, 64.0 + 2.0 * sh, 0.0, TAU, 40, Color(1.0, 0.8, 0.3, 0.05 + 0.05 * sh), 2.0)
	match pattern:
		0:
			# the spokes about to fire light up on the halo
			var n: int = _spokes()
			var k: float = clampf(1.0 - t / 0.6, 0.0, 1.0)
			for i: int in range(n):
				if i == _gap or i == (_gap + 1) % n:
					continue
				var d: Vector2 = Vector2.from_angle(_next_spin + TAU * float(i) / float(n))
				if d.x > 0.35:
					continue
				boss.draw_line(HALO + d * 58.0, HALO + d * (64.0 + 10.0 * k), Color(1.0, 0.85, 0.35, 0.2 + 0.5 * k), 2.0)
		1:
			if _locked:
				var flick: float = 0.3 + 0.3 * float(int(age * 22.0) % 2)
				var origins: Array[Vector2] = [EYES[0], EYES[1]]
				if phase >= 3:
					origins.append(MOUTH)
				for o: Vector2 in origins:
					var d2: Vector2 = (_aim - pos() - o).normalized()
					boss.draw_line(o + d2 * 8.0, o + d2 * 560.0, Color(1.0, 0.8, 0.3, flick), 1.0)
				boss.draw_arc(_aim - pos(), 7.0, 0.0, TAU, 14, Color(1.0, 0.6, 0.2, flick), 1.0)
		_:
			var k3: float = clampf(1.0 - t / 0.5, 0.0, 1.0)
			for ti: int in range(_tablets.size()):
				var tbv: Variant = _tablets[ti]
				if not is_instance_valid(tbv):
					continue
				var l: Vector2 = (tbv as GameBullet).global_position - pos()
				var pulse: float = 0.5 + 0.5 * sin(age * 18.0)
				boss.draw_arc(l, 9.0 + 3.0 * pulse, 0.0, TAU, 14, Color(0.35, 1.0, 0.7, 0.25 + 0.4 * k3), 1.0)
				if k3 > 0.0:
					var dirs: int = 4 if phase < 3 else 6
					var rot: float = 0.0 if (phase < 2 or ti % 2 == 0) else PI * 0.25
					for j: int in range(dirs):
						var d3: Vector2 = Vector2.from_angle(rot + TAU * float(j) / float(dirs))
						boss.draw_line(l + d3 * 10.0, l + d3 * (10.0 + 14.0 * k3), Color(0.35, 1.0, 0.7, 0.3 * k3), 1.0)
