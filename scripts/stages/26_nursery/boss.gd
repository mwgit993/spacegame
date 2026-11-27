extends "res://scripts/stages/stage_boss.gd"

# PROTOSTAR GUARDIAN SOLENNE. Three patterns, switching every 4 attacks:
#  0 STELLAR WIND   rings of star motes pulsed from the core, each with a three-shot gap that
#                   turns a little every volley, and every other volley a fast aimed pair; from
#                   phase 2 a slower second ring with its gap on the other side. In phase 3 the third volley is a NOVA FLARE instead: rings
#                   of light close in on the star for NOVA_CHARGE (the telegraph), then it
#                   bursts in a dense double ring.
#  1 BIPOLAR JETS   the fans its jets are about to sweep are drawn faintly from both poles (the
#                   telegraph); then each pole streams a sweep of shots, top and bottom
#                   scissoring across the screen, and the next fans light up. Phase 2 adds an
#                   aimed five-shot burst from the core, phase 3 a shorter stream sweeping back.
#  2 ACCRETION      it marks points along the top and bottom edges (pulsing markers), then gas
#                   falls inward from them, curving toward the star across the field, with an
#                   aimed seven-shot spread from the core; phase 3 adds a ring.
# Each phase adds shots and rate_mult shortens the cooldowns. Speeds use only part of
# spd_bonus (about 71 here in phase 1): the patterns are dense, not fast.

const CORE: Vector2 = Vector2(-2.0, 0.0)
const POLE_T: Vector2 = Vector2(0.0, -46.0)
const POLE_B: Vector2 = Vector2(0.0, 46.0)
const NOVA_CHARGE: float = 1.15
const JET_ARM: float = 0.75
const STAGGER: float = 0.032

var _gap: int = 0
var _nova: bool = false
var _jets_armed: bool = false
var _jet_from: float = 0.05
var _jet_to: float = 0.8
var _marks: PackedVector2Array = PackedVector2Array()
var _mark_center: Vector2 = Vector2.ZERO


func attack(rate_mult: float, spd_bonus: float) -> void:
	if pattern != 1:
		_jets_armed = false
	if pattern != 2:
		_marks.clear()
	if pattern != 0:
		_nova = false
	match pattern:
		0:
			_stellar_wind(rate_mult, spd_bonus)
		1:
			_bipolar_jets(rate_mult, spd_bonus)
		_:
			_accretion(rate_mult, spd_bonus)


func _ring_with_gap(n: int, speed: float, rot: float, gap_at: int, tex: String) -> void:
	var core: Vector2 = pos() + CORE
	for i: int in range(n):
		var d: int = posmod(i - gap_at, n)
		if d <= 1 or d == n - 1:
			continue
		var v: Vector2 = Vector2.from_angle(rot + TAU * float(i) / float(n)) * speed
		if v.x > 30.0:
			continue
		emit_bullet(core, v, tex)


func _stellar_wind(rate_mult: float, spd_bonus: float) -> void:
	if _nova:
		# the charged nova: a dense double ring
		_nova = false
		var core: Vector2 = pos() + CORE
		for i: int in range(40):
			var a: float = spin + TAU * float(i) / 40.0
			var v: Vector2 = Vector2.from_angle(a) * (112.0 + spd_bonus * 0.5)
			if v.x < 40.0:
				emit_bullet(core, v, bullet_b())
			var v2: Vector2 = Vector2.from_angle(a + TAU / 80.0) * (82.0 + spd_bonus * 0.4)
			if v2.x < 40.0:
				emit_bullet(core, v2, bullet_a())
		spin += 0.2
		RetroSfx.play("big_explode", -8.0, 0.05)
		if boss.fx != null:
			boss.fx.add_shake(4.0)
		wait(1.2 * rate_mult)
		return
	if phase >= 3 and substep == 2:
		# start charging the nova; a light ring meanwhile
		_nova = true
		_ring_with_gap(12, 100.0 + spd_bonus * 0.45, spin, _gap, bullet_b())
		RetroSfx.play("boss_siren", -10.0, 0.0)
		wait(NOVA_CHARGE)
		return
	var n: int = 20 + 2 * phase
	_ring_with_gap(n, 105.0 + spd_bonus * 0.55, spin, _gap, bullet_b())
	if phase >= 2:
		_ring_with_gap(n - 4, 88.0 + spd_bonus * 0.45, spin + PI / float(n), _gap + (n - 4) / 2, bullet_a())
	if substep % 2 == 1:
		for k: int in range(2):
			shoot_aimed_from(pos() + CORE, 175.0 + spd_bonus * 0.5, bullet_a(), (float(k) - 0.5) * 0.12)
	_gap = posmod(_gap + (1 if substep % 2 == 0 else 2), n)
	spin += 0.17
	RetroSfx.play("zap", -12.0, 0.08)
	wait(0.82 * rate_mult)


# One pole's sweep: shots leave one after another while the angle swings from `a0` to `a1`
# (they wait at the pole until their turn, so the stream fans out like a turning jet).
func _sweep(origin: Vector2, a0: float, a1: float, count: int, speed: float, tex: String, delay0: float) -> void:
	for k: int in range(count):
		var t: float = float(k) / float(maxi(1, count - 1))
		var a: float = lerpf(a0, a1, t)
		var b: GameBullet = emit_bullet(origin, Vector2.from_angle(a) * speed, tex)
		if b != null:
			b.slow_timer = delay0 + STAGGER * float(k)
			b.slow_factor = 0.0


func _bipolar_jets(rate_mult: float, spd_bonus: float) -> void:
	if not _jets_armed:
		_jets_armed = true
		_jet_from = 0.05
		_jet_to = 0.85
		RetroSfx.play("boss_hp_tick", -10.0, 0.0)
		wait(JET_ARM * rate_mult)
		return
	var count: int = 10 + phase
	var speed: float = 150.0 + spd_bonus * 0.5
	# top pole sweeps from level-left down toward the middle; the bottom one mirrors it
	_sweep(pos() + POLE_T, PI - _jet_from, PI - _jet_to, count, speed, bullet_b(), 0.0)
	_sweep(pos() + POLE_B, PI + _jet_from, PI + _jet_to, count, speed, bullet_b(), 0.0)
	if phase >= 3:
		var back: float = STAGGER * float(count) + 0.05
		_sweep(pos() + POLE_T, PI - _jet_to, PI - _jet_from, count - 5, speed * 0.95, bullet_a(), back)
		_sweep(pos() + POLE_B, PI + _jet_to, PI + _jet_from, count - 5, speed * 0.95, bullet_a(), back)
	if phase >= 2:
		for k: int in range(-2, 3):
			shoot_aimed_from(pos() + CORE, 170.0 + spd_bonus * 0.5, bullet_a(), float(k) * 0.09)
	RetroSfx.play("laser", -10.0, 0.05)
	# next sweep: a different slice of the field
	var opts: Array[Vector2] = [Vector2(0.05, 0.85), Vector2(0.35, 1.1), Vector2(-0.1, 0.6), Vector2(0.2, 1.0)]
	var nxt: Vector2 = opts[(substep + 1) % opts.size()]
	_jet_from = nxt.x
	_jet_to = nxt.y
	wait(0.95 * rate_mult)


func _accretion(rate_mult: float, spd_bonus: float) -> void:
	if _marks.is_empty():
		_mark_center = pos()
		var n: int = 8 + 2 * phase
		for i: int in range(n):
			var t: float = (float(i) + 0.5) / float(n)
			var x: float = lerpf(120.0, pos().x - 50.0, t)
			var y: float = 36.0 if i % 2 == 0 else 244.0
			_marks.append(Vector2(x, y))
		shoot_aimed_from(pos() + CORE, 150.0 + spd_bonus * 0.5, bullet_a())
		RetroSfx.play("boss_hp_tick", -10.0, 0.0)
		wait(0.8 * rate_mult)
		return
	var speed: float = 108.0 + spd_bonus * 0.4
	for m: Vector2 in _marks:
		var inward: Vector2 = (_mark_center - m).normalized()
		# start heading off to the left of the star, then curve in toward it
		var turn: float = 0.95 if m.y < 135.0 else -0.95
		var b: GameBullet = emit_bullet(m, inward.rotated(turn) * speed, bullet_b())
		if b != null:
			b.home_target = boss
			b.home_time = 1.7
			b.home_rate = 1.05
			b.life_left = 3.0
	_marks.clear()
	shoot_spread_from(pos() + CORE, 7, 0.13, 160.0 + spd_bonus * 0.5, bullet_a())
	if phase >= 3:
		shoot_ring(14, 100.0 + spd_bonus * 0.45, bullet_b(), spin)
		spin += 0.3
	RetroSfx.play("laser", -11.0, 0.05)
	wait(0.9 * rate_mult)


func draw() -> void:
	var k: float = 0.5 + 0.5 * sin(age * 2.4)
	boss.draw_arc(Vector2.ZERO, 66.0 + 3.0 * k, 0.0, TAU, 48, Color(1.0, 0.55, 0.85, 0.06 + 0.06 * k), 2.0)
	if _nova:
		var c: float = 1.0 - clampf(boss._fire_timer / NOVA_CHARGE, 0.0, 1.0)
		var flick: float = 0.6 + 0.4 * float(int(age * 18.0) % 2)
		boss.draw_arc(CORE, lerpf(130.0, 60.0, c), 0.0, TAU, 56, Color(1.0, 0.5, 0.85, (0.25 + 0.5 * c) * flick), 2.0)
		boss.draw_arc(CORE, lerpf(160.0, 72.0, c), 0.0, TAU, 56, Color(1.0, 0.95, 1.0, (0.1 + 0.35 * c) * flick), 1.0)
		for r: int in range(12):
			var a: float = TAU * float(r) / 12.0 + age
			var d: Vector2 = Vector2.from_angle(a)
			boss.draw_line(CORE + d * 62.0, CORE + d * (66.0 + 14.0 * c), Color(1.0, 0.85, 0.95, 0.3 + 0.4 * c), 1.0)
	if _jets_armed:
		var pulse: float = 0.5 + 0.5 * sin(age * 14.0)
		for pole: int in range(2):
			var o: Vector2 = POLE_T if pole == 0 else POLE_B
			var sgn: float = -1.0 if pole == 0 else 1.0
			for r2: int in range(5):
				var a2: float = PI + sgn * lerpf(_jet_from, _jet_to, float(r2) / 4.0)
				var d2: Vector2 = Vector2.from_angle(a2)
				boss.draw_line(o + d2 * 14.0, o + d2 * 240.0, Color(0.55, 1.0, 1.0, 0.07 + 0.08 * pulse), 1.0)
			boss.draw_circle(o + Vector2(-4.0, 0.0), 3.0 + 2.0 * pulse, Color(0.6, 1.0, 1.0, 0.35))
	if not _marks.is_empty():
		var t: float = 0.5 + 0.5 * sin(age * 16.0)
		for m: Vector2 in _marks:
			var l: Vector2 = m - pos()
			boss.draw_arc(l, 4.0 + 2.0 * t, 0.0, TAU, 10, Color(1.0, 0.75, 0.4, 0.45 + 0.3 * t), 1.0)
			var inward: Vector2 = (_mark_center - m).normalized().rotated(0.95 if m.y < 135.0 else -0.95)
			boss.draw_line(l, l + inward * 12.0, Color(1.0, 0.9, 0.6, 0.6), 1.0)
