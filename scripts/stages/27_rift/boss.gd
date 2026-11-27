extends "res://scripts/stages/stage_boss.gd"

# THE PARADOX ENGINE. An hourglass held in an impossible triangle; it fights with time itself.
# Three patterns, switching every 4 attacks (each runs its own little sequence across attacks):
#  0 REWIND       it marks where the ship is with an amber clock; next attack a ring of cyan
#                 shots bursts out of that spot; then time runs backwards for them: they stall,
#                 turn amber and fly back through the spot and out the other side (phase 2+: the
#                 rewind slips, knocking them off their old lines), and an amber aftershock
#                 rings out of the aperture. In phase 3 a TIME STOP comes instead: a closing
#                 clock warns, then every shot on screen freezes for STOP seconds while a fan
#                 is aimed through the frozen field.
#  1 TIME ECHO    it fires a volley (an aimed fan or a curtain) and its future self appears, an
#                 amber ghost of the engine above or below it with a clock filling; next attack
#                 the ghost fires the very same volley from where it floats (phase 2+: a ghost
#                 on each side; phase 3: the echoes are mirrored, crossing the original lines).
#  2 PROBABILITY  three candidate patterns spread round it as faint dotted rays and drop out one
#    STORM        by one; next attack the survivor fires exactly as shown (phase 2+: two survive).
# rate_mult shortens the cooldowns; spd_bonus is only partly applied (the patterns are dense).

enum K { GAP_RING, STREAMS, WALL, HELIX, SCATTER }

const APERTURE: Vector2 = Vector2(-12.0, 0.0)
const STOP: float = 1.15
const TINTS: Array[Color] = [Color(0.35, 0.9, 1.0), Color(1.0, 0.72, 0.28), Color(0.78, 0.62, 1.0)]

var _last_pattern: int = -1

# REWIND
var _rw_step: int = 0
var _mark: Vector2 = Vector2.ZERO
var _mark_t: float = -10.0
var _mark_until: float = -10.0
var _ring: Array[GameBullet] = []
var _rw_twist: float = 0.32
var _stop_warn_t: float = -10.0
var _stop_warn_dur: float = 1.0
var _stop_t: float = -10.0
var _stop_armed: bool = false
var _frozen: Array[GameBullet] = []

# TIME ECHO
var _ec_step: int = 0
var _ec_count: int = 0
var _ec_off: PackedVector2Array = PackedVector2Array()
var _ec_vel: PackedVector2Array = PackedVector2Array()
var _ghosts: PackedVector2Array = PackedVector2Array()
var _ghost_t0: float = -10.0
var _ghost_dur: float = 1.0
var _ghost_fire_t: float = -10.0

# PROBABILITY STORM
var _pb_step: int = 0
var _cand_off: Array[PackedVector2Array] = []
var _cand_vel: Array[PackedVector2Array] = []
var _keep: Array[int] = []
var _drop: Array[int] = []
var _pb_t0: float = -10.0
var _pb_dur: float = 1.0


func attack(rate_mult: float, spd_bonus: float) -> void:
	if not _frozen.is_empty() and age - _stop_t >= STOP:
		for fb: GameBullet in _frozen:
			if is_instance_valid(fb):
				fb.modulate = Color.WHITE
		_frozen.clear()
	if pattern != _last_pattern:
		_last_pattern = pattern
		_rw_step = 0
		_ring.clear()
		_stop_armed = false
		_ec_step = 0
		_ghosts.clear()
		_pb_step = 0
		_cand_off.clear()
		_cand_vel.clear()
	match pattern:
		0:
			_rewind(rate_mult, spd_bonus)
		1:
			_echo(rate_mult, spd_bonus)
		_:
			_storm(rate_mult, spd_bonus)


# --- 0 REWIND --------------------------------------------------------------------------------------

func _rewind(rate_mult: float, spd_bonus: float) -> void:
	var ap: Vector2 = pos() + APERTURE
	match _rw_step:
		0:
			_mark = player_pos()
			_mark_t = age
			_mark_until = age + 4.0
			for k: int in range(-3, 4):
				shoot_aimed_from(ap, 150.0 + spd_bonus * 0.4, bullet_a(), float(k) * 0.11)
			RetroSfx.play("boss_hp_tick", -9.0, 0.0)
			_rw_step = 1
			wait(0.8 * rate_mult)
		1:
			var rot: float = randf() * TAU
			var spd: float = 82.0 + spd_bonus * 0.12
			_ring.clear()
			# phase 2+: a second, slower ring inside the first, offset half a step
			var rings: int = 1 if phase < 2 else 2
			for r: int in range(rings):
				var n: int = (20 if r == 0 else 14) + phase * 2
				for i: int in range(n):
					var a: float = rot + TAU * (float(i) + 0.5 * float(r)) / float(n)
					var b: GameBullet = emit_bullet(_mark + Vector2.from_angle(a) * 6.0, Vector2.from_angle(a) * spd * (1.0 if r == 0 else 0.6), bullet_a())
					if b != null:
						_ring.append(b)
			shoot_spread_from(ap, 7, 0.15, 140.0 + spd_bonus * 0.4, bullet_a())
			RetroSfx.play("zap", -10.0, 0.06)
			_rw_step = 2
			wait(0.9 * rate_mult)
		2:
			_rw_twist = -_rw_twist
			var twist: float = _rw_twist if phase >= 2 else 0.0
			for b2: GameBullet in _ring:
				if is_instance_valid(b2):
					b2.velocity = -b2.velocity.rotated(twist) * 1.08
					b2.slow_timer = 0.32
					b2.slow_factor = 0.06
					b2.anim_tex_a = bullet_b()
					b2.anim_tex_b = bullet_b()
			_ring.clear()
			_mark_until = age + 1.2
			for k2: int in range(6):
				var s: GameBullet = emit_bullet(ap, (player_pos() - ap).normalized() * (175.0 + spd_bonus * 0.5), bullet_a())
				if s != null:
					s.slow_timer = 0.07 * float(k2)
					s.slow_factor = 0.0
			RetroSfx.play("laser", -9.0, 0.04)
			_rw_step = 3
			_stop_armed = phase >= 3
			if _stop_armed:
				_stop_warn_t = age
				_stop_warn_dur = 0.95 * rate_mult
				wait(_stop_warn_dur)
			else:
				wait(0.85 * rate_mult)
		_:
			_rw_step = 0
			if not _stop_armed:
				# AFTERSHOCK: the echo of the rewind rings out of the aperture
				shoot_ring(16 + phase * 2, 118.0 + spd_bonus * 0.35, bullet_b(), randf() * TAU)
				_snipe(ap, spd_bonus, 5)
				RetroSfx.play("zap", -11.0, 0.05)
				wait(0.72 * rate_mult)
				return
			_stop_armed = false
			_stop_t = age
			if boss.bullet_container != null:
				for node: Node in boss.bullet_container.get_children():
					var gb: GameBullet = node as GameBullet
					if gb != null and not gb.is_player_bullet:
						gb.slow_timer = STOP
						gb.slow_factor = 0.0
						gb.modulate = Color(0.7, 0.8, 1.0, 0.85)
						_frozen.append(gb)
			var aim: float = (player_pos() - ap).angle()
			for k3: int in range(7):
				emit_bullet(ap, Vector2.from_angle(aim + (float(k3) - 3.0) * 0.12) * (120.0 + spd_bonus * 0.3), bullet_b())
			RetroSfx.play("shield_hit", -6.0, 0.0)
			if boss.fx != null:
				boss.fx.add_shake(3.0)
			wait(STOP * rate_mult + 0.2)


# --- 1 TIME ECHO -----------------------------------------------------------------------------------

func _echo(rate_mult: float, spd_bonus: float) -> void:
	if _ec_step == 0:
		_ec_off.clear()
		_ec_vel.clear()
		var ap: Vector2 = APERTURE
		if _ec_count % 2 == 0:
			var aim: float = (player_pos() - pos() - ap).angle()
			var n: int = 11 + phase
			for i: int in range(n):
				_ec_off.append(ap)
				_ec_vel.append(Vector2.from_angle(aim + (float(i) - float(n - 1) * 0.5) * 0.095) * (138.0 + spd_bonus * 0.35))
		else:
			var lean: float = clampf((player_pos().y - pos().y) / 400.0, -0.25, 0.25)
			var cols: int = 1 if phase < 2 else 2
			for col: int in range(cols):
				var rows: int = 11 if cols == 1 else 9
				for j: int in range(rows):
					_ec_off.append(Vector2(-24.0 + 16.0 * float(col), -60.0 + 120.0 * float(j) / float(rows - 1) + 7.0 * float(col)))
					_ec_vel.append(Vector2.from_angle(PI - lean) * (138.0 + spd_bonus * 0.35))
		_ec_count += 1
		for s: int in range(_ec_off.size()):
			emit_bullet(pos() + _ec_off[s], _ec_vel[s], bullet_a())
		_ghosts.clear()
		var up: Vector2 = Vector2(-46.0, -88.0)
		var down: Vector2 = Vector2(-46.0, 88.0)
		if phase >= 2:
			_ghosts.append(up)
			_ghosts.append(down)
		else:
			_ghosts.append(up if pos().y > 134.0 else down)
		_ghost_t0 = age
		_ghost_dur = 1.0 * rate_mult
		RetroSfx.play("zap", -11.0, 0.05)
		_ec_step = 1
		wait(_ghost_dur)
	else:
		for g: Vector2 in _ghosts:
			for s2: int in range(_ec_off.size()):
				var v: Vector2 = _ec_vel[s2]
				if phase >= 3:
					v.y = -v.y
				emit_bullet(pos() + g + _ec_off[s2], v, bullet_b())
		_ghost_fire_t = age
		_snipe(pos() + APERTURE, spd_bonus, 5)
		RetroSfx.play("laser", -9.0, 0.03)
		_ec_step = 0
		wait(0.75 * rate_mult)


# --- 2 PROBABILITY STORM ---------------------------------------------------------------------------

func _storm(rate_mult: float, spd_bonus: float) -> void:
	if _pb_step == 0:
		var kinds: Array[int] = [K.GAP_RING, K.STREAMS, K.WALL, K.HELIX, K.SCATTER]
		kinds.shuffle()
		_cand_off.clear()
		_cand_vel.clear()
		for c: int in range(3):
			var built: Array = _build(kinds[c], spd_bonus)
			_cand_off.append(built[0] as PackedVector2Array)
			_cand_vel.append(built[1] as PackedVector2Array)
		var slots: Array[int] = [0, 1, 2]
		slots.shuffle()
		var keep_n: int = 1 if phase < 2 else 2
		_keep.clear()
		_drop.clear()
		for i: int in range(3):
			if i < 3 - keep_n:
				_drop.append(slots[i])
			else:
				_keep.append(slots[i])
		_pb_t0 = age
		_pb_dur = 1.2 * rate_mult
		_snipe(pos() + APERTURE, spd_bonus, 5)
		RetroSfx.play("boss_hp_tick", -9.0, 0.0)
		_pb_step = 1
		wait(_pb_dur)
	else:
		for c2: int in _keep:
			if c2 >= _cand_off.size():
				continue
			var offs2: PackedVector2Array = _cand_off[c2]
			var vels2: PackedVector2Array = _cand_vel[c2]
			for s: int in range(offs2.size()):
				emit_bullet(pos() + offs2[s], vels2[s], "rift_qshot", 3.0)
		_cand_off.clear()
		_cand_vel.clear()
		RetroSfx.play("explode", -11.0, 0.08)
		_pb_step = 0
		wait(0.8 * rate_mult)


# A short aimed stream from the aperture between the set pieces (the shots leave one by one).
func _snipe(from: Vector2, spd_bonus: float, n: int) -> void:
	var dir: Vector2 = (player_pos() - from).normalized()
	for k: int in range(n):
		var b: GameBullet = emit_bullet(from, dir * (185.0 + spd_bonus * 0.5), bullet_a())
		if b != null:
			b.slow_timer = 0.07 * float(k)
			b.slow_factor = 0.0


# One candidate's shots, as origins relative to the boss and velocities.
func _build(kind: int, spd_bonus: float) -> Array:
	var offs: PackedVector2Array = PackedVector2Array()
	var vels: PackedVector2Array = PackedVector2Array()
	var ap: Vector2 = APERTURE
	var aim: float = (player_pos() - pos() - ap).angle()
	match kind:
		K.GAP_RING:
			var n: int = 30
			var gap_a: float = aim + (0.5 if randf() < 0.5 else -0.5)
			for i: int in range(n):
				var a: float = gap_a + TAU * float(i) / float(n)
				if i < 2 or i > n - 2:
					continue
				offs.append(ap)
				vels.append(Vector2.from_angle(a) * (112.0 + spd_bonus * 0.3))
		K.STREAMS:
			for st: int in range(3):
				for k: int in range(6):
					offs.append(ap)
					vels.append(Vector2.from_angle(aim + float(st - 1) * 0.42) * (115.0 + 20.0 * float(k) + spd_bonus * 0.3))
		K.WALL:
			var gap: int = randi_range(2, 9)
			for row: int in range(13):
				if row >= gap and row <= gap + 2:
					continue
				var wy: float = 44.0 + 15.5 * float(row)
				offs.append(Vector2(-40.0, wy - pos().y))
				vels.append(Vector2(-(104.0 + spd_bonus * 0.3), 0.0))
		K.HELIX:
			for arm: int in range(2):
				var sgn: float = 1.0 if arm == 0 else -1.0
				for k2: int in range(10):
					offs.append(ap)
					vels.append(Vector2.from_angle(aim + sgn * (0.12 + 0.11 * float(k2))) * (82.0 + 11.0 * float(k2) + spd_bonus * 0.3))
		_:
			for k3: int in range(20):
				offs.append(ap)
				vels.append(Vector2.from_angle(PI + randf_range(-1.2, 1.2)) * (randf_range(92.0, 165.0) + spd_bonus * 0.2))
	return [offs, vels]


# --- telegraphs ------------------------------------------------------------------------------------

func draw() -> void:
	var here: Vector2 = pos()
	# its own clock: a dim ring of ticks with one hand running forward and one back
	var cr: float = 84.0
	var ticks: PackedVector2Array = PackedVector2Array()
	for i: int in range(12):
		var d: Vector2 = Vector2.from_angle(float(i) * TAU / 12.0)
		ticks.append(d * cr)
		ticks.append(d * (cr - (5.0 if i % 3 == 0 else 2.0)))
	boss.draw_multiline(ticks, Color(0.75, 0.65, 1.0, 0.18), 1.0)
	boss.draw_line(Vector2.ZERO + Vector2.from_angle(age * 2.3) * 64.0, Vector2.from_angle(age * 2.3) * 80.0, Color(0.4, 0.9, 1.0, 0.3), 1.0)
	boss.draw_line(Vector2.from_angle(-age * 0.9) * 66.0, Vector2.from_angle(-age * 0.9) * 78.0, Color(1.0, 0.7, 0.3, 0.3), 1.0)

	# REWIND: the amber clock on the marked spot, its hand turning backwards
	if age < _mark_until:
		var m: Vector2 = _mark - here
		var k: float = clampf((age - _mark_t) / 0.6, 0.0, 1.0)
		var r: float = lerpf(18.0, 9.0, k)
		var pulse: float = 0.5 + 0.5 * sin(age * 14.0)
		boss.draw_arc(m, r, 0.0, TAU, 20, Color(1.0, 0.72, 0.28, 0.45 + 0.3 * pulse), 1.0)
		for q: int in range(4):
			var dq: Vector2 = Vector2.from_angle(float(q) * PI * 0.5)
			boss.draw_line(m + dq * (r + 1.0), m + dq * (r + 4.0), Color(1.0, 0.8, 0.4, 0.6), 1.0)
		boss.draw_line(m, m + Vector2.from_angle(-age * 9.0) * (r - 2.0), Color(1.0, 0.9, 0.6, 0.8), 1.0)
	# TIME STOP: a closing clock while it winds up, then everything holds still
	if _stop_armed and _rw_step == 3 and age - _stop_warn_t < _stop_warn_dur:
		var kw: float = clampf((age - _stop_warn_t) / maxf(0.1, _stop_warn_dur), 0.0, 1.0)
		var wr: float = lerpf(120.0, 40.0, kw)
		boss.draw_arc(APERTURE, wr, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.25 + 0.45 * kw), 2.0)
		boss.draw_arc(APERTURE, wr, -PI * 0.5, -PI * 0.5 + TAU * kw, 32, Color(0.8, 0.95, 1.0, 0.8), 2.0)
	var since_stop: float = age - _stop_t
	if since_stop >= 0.0 and since_stop < STOP:
		var ks: float = 1.0 - since_stop / STOP
		boss.draw_rect(Rect2(-here + Vector2(0.0, 30.0), Vector2(480.0, 220.0)), Color(0.75, 0.7, 1.0, 0.06 * ks))
		# the stopped clock: a white ring with its hands frozen at twelve
		boss.draw_arc(APERTURE, 72.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.6 * ks), 2.0)
		boss.draw_line(APERTURE + Vector2(0.0, -58.0), APERTURE + Vector2(0.0, -72.0), Color(1.0, 1.0, 1.0, 0.9 * ks), 2.0)
		for q2: int in range(12):
			var dq2: Vector2 = Vector2.from_angle(float(q2) * TAU / 12.0)
			boss.draw_line(APERTURE + dq2 * 72.0, APERTURE + dq2 * 78.0, Color(0.85, 0.9, 1.0, 0.6 * ks), 1.0)

	# TIME ECHO: the engine's future self, with a clock filling until it fires
	var g_age: float = age - _ghost_t0
	var show_ghost: bool = _ec_step == 1 or age - _ghost_fire_t < 0.3
	if show_ghost and not _ghosts.is_empty() and g_age >= 0.0:
		var tex: Texture2D = PixelArt.tex("boss_rift_0")
		var sz: Vector2 = tex.get_size() * 0.72
		var kg: float = clampf(g_age / maxf(0.1, _ghost_dur), 0.0, 1.0)
		var fade: float = 1.0
		if _ec_step == 0:
			fade = 1.0 - clampf((age - _ghost_fire_t) / 0.3, 0.0, 1.0)
		for gp: Vector2 in _ghosts:
			var flick: float = 0.22 + 0.12 * float(int(age * 24.0) % 2)
			boss.draw_texture_rect(tex, Rect2(gp - sz * 0.5, sz), false, Color(1.0, 0.72, 0.32, (flick + 0.15 * kg) * fade))
			if _ec_step == 1:
				boss.draw_arc(gp, 30.0, -PI * 0.5, -PI * 0.5 + TAU * kg, 28, Color(1.0, 0.75, 0.3, 0.55), 2.0)
				boss.draw_arc(gp, 30.0, 0.0, TAU, 28, Color(1.0, 0.75, 0.3, 0.15), 1.0)

	# PROBABILITY STORM: the candidate futures as dotted rays, dropping out one by one
	if _pb_step == 1 and not _cand_off.is_empty():
		var kt: float = clampf((age - _pb_t0) / maxf(0.1, _pb_dur), 0.0, 1.0)
		for c: int in range(_cand_off.size()):
			var col: Color = TINTS[c % 3]
			var a: float = 0.18 + 0.05 * sin(age * 9.0 + float(c) * 2.0)
			var reach: float = 0.36
			var di: int = _drop.find(c)
			if di >= 0:
				var at: float = 0.38 + 0.26 * float(di)
				if kt > at:
					var gone: float = (kt - at) * _pb_dur
					if gone > 0.22:
						continue
					a = 0.35 * float(int(age * 30.0) % 2)
			elif kt > 0.7:
				var kl: float = (kt - 0.7) / 0.3
				a = 0.3 + 0.35 * kl
				reach = 0.36 + 0.3 * kl
				col = col.lerp(Color.WHITE, 0.5)
			var segs: PackedVector2Array = PackedVector2Array()
			var offs: PackedVector2Array = _cand_off[c]
			var vels: PackedVector2Array = _cand_vel[c]
			for s: int in range(offs.size()):
				var d2: Vector2 = vels[s].normalized()
				var length: float = vels[s].length() * reach
				var dots: int = maxi(2, int(length / 10.0))
				for j: int in range(dots):
					var p0: Vector2 = (offs[s] + d2 * (6.0 + length * float(j) / float(dots))).floor() + Vector2(0.5, 0.5)
					segs.append(p0)
					segs.append(p0 + d2 * 2.0)
			boss.draw_multiline(segs, Color(col.r, col.g, col.b, a), 1.0)
