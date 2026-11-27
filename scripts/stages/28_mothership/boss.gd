extends "res://scripts/stages/stage_boss.gd"

# THE OVERMIND, the armada's mind and the last boss. On top of the three shared phases (66% and
# 33%, which speed everything up) the fight runs in five ACTS by HP (80/60/40/20%). Each act
# change is announced (a line from the Overmind, a shockwave, a pause) and sets off the hangar
# behind it (background.gd: reactor surges, then red alert). Every act nods to earlier bosses:
#  I   BROADSIDE      stage 1's Nemesis wall: a wall of shots with a two-lane gap that moves
#                     every volley, between aimed crossfire from both cannon arms.
#  II  RAIL LANCE     the defence grid's rail cannon: the eye locks a line on the ship (drawn,
#                     then flickering), and a solid lance of slugs fires down it (three lances
#                     from phase 2) with a backblast ring; between lances the idol's sun spokes
#                     wheel out of the eye.
#  III MEDUSA NOVA    stage 8's neon spiral arms (one more arm per phase), and the protostar's
#                     nova: a ring closes in on the eye (the telegraph) before two rings of
#                     orbs burst out (three in phase 3).
#  IV  REWIND         the paradox entity's trick: a fan of shots freezes, flies back the way it
#                     came, freezes again and re-aims at the ship; the scorpion tail sweeps
#                     between rewinds.
#  V   ALL FLEETS     everything at once (always three lances): the shell's lenses join in,
#                     and drones launch from the shell (children, capped).
# Between the set pieces the cannon arms and the eye keep up quick aimed volleys (also while a
# lance or nova charges, and while a rewind fan is turning around), so there's no dead time.

const BG = preload("background.gd")
const DroneScript = preload("enemy_drone.gd")

const EYE: Vector2 = Vector2(-38.0, 0.0)
const GUN_HI: Vector2 = Vector2(-74.0, -55.0)
const GUN_LO: Vector2 = Vector2(-74.0, 55.0)
const LENSES: Array[Vector2] = [Vector2(44.0, -62.0), Vector2(58.0, -28.0), Vector2(58.0, 28.0), Vector2(44.0, 62.0)]
const ACT_THRESH: Array[float] = [0.8, 0.6, 0.4, 0.2]
const ACT_LINES: Array[String] = ["", "THE OVERMIND AWAKENS", "ALL BATTERIES: FIRE!", "THE CORE IS EXPOSED!", "TIME ITSELF OBEYS ME!", "THE ARMADA WILL NOT FALL!"]
const ACT_NAMES: Array[String] = ["", "I", "II", "III", "IV", "V"]
const LANCE_CHARGE: float = 0.8
const NOVA_CHARGE: float = 0.9

var _act: int = 0
var _k: int = 0
var _gap: int = 4
var _pending: String = ""
var _lance_dir: float = PI
var _lance_at: float = -10.0
var _nova_at: float = -10.0
var _rewind: Array[GameBullet] = []
var _rewind_speed: float = 120.0
var _tail: float = PI
var _tail_dir: float = 1.0
var _act_t: float = -10.0


func setup() -> void:
	BG.alert = 1


func attack(rate_mult: float, spd_bonus: float) -> void:
	var ratio: float = boss.hp / maxf(1.0, boss.max_hp)
	var act: int = 1
	for th: float in ACT_THRESH:
		if ratio <= th:
			act += 1
	if act > _act:
		var first: bool = _act == 0
		_act = act
		_k = 0
		_pending = ""
		_rewind.clear()
		_lance_at = -10.0
		_nova_at = -10.0
		BG.alert = act
		_announce()
		if not first:
			wait(0.95)
			return
	if _pending != "":
		_resolve(rate_mult, spd_bonus)
		return
	match _act:
		1:
			if _k % 2 == 0:
				_wall(spd_bonus)
				wait(0.95 * rate_mult)
			else:
				_crossfire(spd_bonus, true)
				wait(0.7 * rate_mult)
		2:
			if _k % 4 == 0:
				_charge_lance()
				_crossfire(spd_bonus, false)
			else:
				_spokes(spd_bonus)
				if _k % 2 == 1:
					_crossfire(spd_bonus, false)
				else:
					_eye_fan(spd_bonus, 3)
				wait(0.44 * rate_mult)
		3:
			if _k % 4 == 3:
				_charge_nova()
				_eye_fan(spd_bonus, 5)
			else:
				_spiral(spd_bonus)
				_eye_fan(spd_bonus, 3 if _k % 2 == 0 else 2)
				wait(0.27 * rate_mult)
		4:
			if _k % 4 == 0:
				_rewind_fire(spd_bonus)
			else:
				_tail_sweep(spd_bonus)
				wait(0.24 * rate_mult)
		_:
			match _k % 6:
				0:
					_wall(spd_bonus)
					_spiral(spd_bonus)
					_eye_fan(spd_bonus, 3)
					wait(0.6 * rate_mult)
				1:
					_charge_lance()
					_crossfire(spd_bonus, false)
				2:
					_spokes(spd_bonus)
					_lenses(spd_bonus)
					wait(0.4 * rate_mult)
				3:
					_rewind_fire(spd_bonus)
					_lenses(spd_bonus)
				4:
					_tail_sweep(spd_bonus)
					_crossfire(spd_bonus, false)
					wait(0.42 * rate_mult)
				_:
					_launch_drones()
					_spiral(spd_bonus)
					_lenses(spd_bonus)
					wait(0.42 * rate_mult)
	_k += 1


func _announce() -> void:
	var fx: FxLayer = boss.fx
	RetroSfx.play("boss_siren", -6.0, 0.0)
	if fx == null:
		return
	fx.add_shake(8.0)
	fx.spawn_ring_blast(pos() + EYE, 110.0, Color("#ff4058"))
	fx.spawn_hit_sparks(pos() + EYE, Color("#40e8ff"), 16)
	fx.spawn_popup(pos() + Vector2(-150.0, -78.0), "ACT %s: %s" % [ACT_NAMES[_act], ACT_LINES[_act]], Color("#ff4058") if _act >= 4 else Color("#ffe854"))
	_act_t = age
	BG.surge_req += 1


# Second halves of the two-step attacks (the first half drew its telegraph).
func _resolve(rate_mult: float, spd_bonus: float) -> void:
	var p: String = _pending
	_pending = ""
	match p:
		"lance":
			var n: int = _lance_count()
			for l: int in range(n):
				var a: float = _lance_dir + (float(l) - float(n - 1) * 0.5) * 0.24
				var d: Vector2 = Vector2.from_angle(a)
				for i: int in range(14):
					emit_bullet(pos() + EYE + d * (10.0 + float(i) * 7.0), d * (260.0 + spd_bonus * 0.4), "mothership_slug", 3.0)
			# the cannon arms fire down the outer edges of the lances
			for g: Vector2 in [GUN_HI, GUN_LO]:
				shoot_aimed_from(pos() + g, 165.0 + spd_bonus * 0.5, bullet_a())
			# the backblast: a slow ring of sparks off the eye
			for r: int in range(10):
				var ra: float = spin + TAU * float(r) / 10.0
				var rv: Vector2 = Vector2.from_angle(ra) * (70.0 + spd_bonus * 0.25)
				if rv.x < 20.0:
					emit_bullet(pos() + EYE + Vector2.from_angle(ra) * 14.0, rv, bullet_b())
			RetroSfx.play("boss_beam", -7.0, 0.03)
			if boss.fx != null:
				boss.fx.add_shake(3.0)
			wait(0.55 * rate_mult)
			_k += 1
		"nova":
			var rings: int = 2 if boss.boss_phase < 3 else 3
			for ring: int in range(rings):
				var cnt: int = 30
				for i2: int in range(cnt):
					var a2: float = spin + TAU * (float(i2) + 0.5 * float(ring % 2)) / float(cnt)
					var v: Vector2 = Vector2.from_angle(a2) * (92.0 - 22.0 * float(ring) + spd_bonus * 0.3)
					if v.x < 30.0:
						emit_bullet(pos() + EYE + Vector2.from_angle(a2) * 12.0, v, "mothership_orb", 3.2)
			spin += 0.13
			RetroSfx.play("big_explode", -9.0, 0.05)
			if boss.fx != null:
				boss.fx.spawn_ring_blast(pos() + EYE, 70.0, Color("#b080ff"))
			wait(0.8 * rate_mult)
			_k += 1
		"rewind1":
			# freeze, then fly back the way they came
			var live: Array[GameBullet] = []
			for b: GameBullet in _rewind:
				if is_instance_valid(b) and not b.is_queued_for_deletion():
					b.slow_timer = 0.32
					b.slow_factor = 0.0
					b.velocity = -b.velocity * 1.1
					b.modulate = Color(0.55, 1.0, 1.0)
					live.append(b)
			_rewind = live
			_crossfire(spd_bonus, false)
			RetroSfx.play("shield_hit", -9.0, 0.0)
			_pending = "rewind2"
			wait(0.75)
		"rewind2":
			# freeze again and re-aim, each shot at the ship
			for b2: GameBullet in _rewind:
				if is_instance_valid(b2) and not b2.is_queued_for_deletion():
					b2.slow_timer = 0.3
					b2.slow_factor = 0.0
					b2.velocity = (player_pos() - b2.global_position).normalized() * (_rewind_speed * 0.9)
					b2.modulate = Color(1.0, 0.7, 1.0)
			_rewind.clear()
			_eye_fan(spd_bonus, 5)
			RetroSfx.play("shield_hit", -9.0, 0.0)
			wait(0.7 * rate_mult)
			_k += 1


# I: the Nemesis wall. Ten lanes, two of them open; the gap wanders every volley.
func _wall(spd_bonus: float) -> void:
	var lanes: int = 10
	_gap = clampi(_gap + randi_range(-3, 3), 0, lanes - 2)
	var x: float = pos().x - 72.0
	for lane: int in range(lanes):
		if lane == _gap or lane == _gap + 1:
			continue
		var y: float = 40.0 + float(lane) * 22.0
		emit_bullet(Vector2(x, y), Vector2(-(92.0 + spd_bonus * 0.45), 0.0), bullet_b())
		if lane != _gap - 1 and lane != _gap + 2:
			emit_bullet(Vector2(x + 14.0, y + 11.0), Vector2(-(80.0 + spd_bonus * 0.4), 0.0), bullet_b())
	RetroSfx.play("laser", -11.0, 0.05)


# Aimed triples from both cannon arms (plus a five-shot fan from the eye in act I).
func _crossfire(spd_bonus: float, with_eye: bool) -> void:
	for g: Vector2 in [GUN_HI, GUN_LO]:
		for k: int in range(-1, 2):
			shoot_aimed_from(pos() + g, 150.0 + spd_bonus * 0.5, bullet_a(), float(k) * 0.12)
	if with_eye:
		for k2: int in range(-2, 3):
			shoot_aimed_from(pos() + EYE, 120.0 + spd_bonus * 0.4, bullet_b(), float(k2) * 0.16)
	RetroSfx.play("laser", -12.0, 0.05)


# Lances per volley: one in phase 1, three from phase 2 (and always three in act V).
func _lance_count() -> int:
	return 3 if boss.boss_phase >= 2 or _act >= 5 else 1


# A quick aimed fan from the eye, between the set pieces.
func _eye_fan(spd_bonus: float, n: int) -> void:
	for k: int in range(n):
		shoot_aimed_from(pos() + EYE, 150.0 + spd_bonus * 0.5, bullet_b(), (float(k) - float(n - 1) * 0.5) * 0.14)


# II: lock the rail lance on the ship (the line is drawn while it charges).
func _charge_lance() -> void:
	_lance_dir = (player_pos() - (pos() + EYE)).angle()
	_lance_at = age + LANCE_CHARGE
	_pending = "lance"
	RetroSfx.play("boss_hp_tick", -8.0, 0.0)
	wait(LANCE_CHARGE)


# II: sun spokes wheeling out of the eye.
func _spokes(spd_bonus: float) -> void:
	var n: int = 12 + 2 * boss.boss_phase
	for i: int in range(n):
		var a: float = spin + TAU * float(i) / float(n)
		var d: Vector2 = Vector2.from_angle(a)
		if d.x > 0.3:
			continue
		for j: int in range(2):
			emit_bullet(pos() + EYE + d * 14.0, d * (84.0 + 20.0 * float(j) + spd_bonus * 0.35), bullet_b() if j == 0 else bullet_a())
	spin += 0.19
	RetroSfx.play("laser", -13.0, 0.08)


# III: medusa spiral arms (two in phase 1, one more per phase).
func _spiral(spd_bonus: float) -> void:
	var arms: int = 1 + boss.boss_phase
	for arm: int in range(arms):
		for j: int in range(3):
			var a: float = spin + TAU * float(arm) / float(arms) + float(j) * 0.08
			var d: Vector2 = Vector2.from_angle(a)
			if d.x > 0.45:
				continue
			emit_bullet(pos() + EYE + d * 12.0, d * (78.0 + 13.0 * float(j) + spd_bonus * 0.35), "mothership_orb" if j == 2 else bullet_b(), 3.0)
	spin += 0.37


# III: the nova (a closing ring is drawn while it charges).
func _charge_nova() -> void:
	_nova_at = age + NOVA_CHARGE
	_pending = "nova"
	RetroSfx.play("boss_hp_tick", -8.0, 0.0)
	wait(NOVA_CHARGE)


# IV: a fan that will rewind and re-aim.
func _rewind_fire(spd_bonus: float) -> void:
	_rewind.clear()
	_rewind_speed = 118.0 + spd_bonus * 0.3
	var base: float = (player_pos() - (pos() + EYE)).angle()
	var n: int = 17 + 2 * boss.boss_phase
	for i: int in range(n):
		var a: float = base + (float(i) - float(n - 1) * 0.5) * 0.12
		var b: GameBullet = emit_bullet(pos() + EYE, Vector2.from_angle(a) * _rewind_speed, bullet_a())
		if b != null:
			_rewind.append(b)
	RetroSfx.play("laser", -10.0, 0.04)
	_pending = "rewind1"
	wait(0.85)


# IV: the scorpion tail: a fan sweeping up and down from the lower arm.
func _tail_sweep(spd_bonus: float) -> void:
	var g: Vector2 = pos() + (GUN_LO if _k % 2 == 0 else GUN_HI)
	for i: int in range(5):
		emit_bullet(g, Vector2.from_angle(_tail + float(i) * 0.05) * (148.0 + spd_bonus * 0.45 + float(i) * 6.0), bullet_b())
	_tail += _tail_dir * 0.2
	if _tail > PI + 0.7:
		_tail_dir = -1.0
	elif _tail < PI - 0.7:
		_tail_dir = 1.0
	RetroSfx.play("laser", -14.0, 0.06)


# V: every lens on the shell blazes an aimed shot.
func _lenses(spd_bonus: float) -> void:
	for ln: Vector2 in LENSES:
		shoot_aimed_from(pos() + ln, 140.0 + spd_bonus * 0.45, bullet_a())
	if boss.fx != null:
		for ln2: Vector2 in LENSES:
			boss.fx.spawn_hit_sparks(pos() + ln2, Color("#ff4058"), 3)


# V: drones out of the shell (children of the boss, capped by the drone cap).
func _launch_drones() -> void:
	if DroneScript.count(boss) >= DroneScript.CAP - 2:
		return
	for s: float in [-1.0, 1.0]:
		boss._request_child(GameEnemy.Type.MODULE, pos() + Vector2(10.0, 70.0 * s), Vector2(-80.0, 90.0 * s), 1, "drone")
	RetroSfx.play("missile", -10.0, 0.05)


func draw() -> void:
	# the eye's glow in front of it
	var k: float = 0.5 + 0.5 * sin(age * 5.0)
	boss.draw_circle(EYE + Vector2(-22.0, 0.0), 2.0 + 2.0 * k, Color(1.0, 0.3, 0.4, 0.25 + 0.2 * k))
	# rail lance: the locked line, flickering in the last moments
	if age < _lance_at:
		var rem: float = _lance_at - age
		var n: int = _lance_count()
		var hot: bool = rem < 0.3
		for l: int in range(n):
			var d: Vector2 = Vector2.from_angle(_lance_dir + (float(l) - float(n - 1) * 0.5) * 0.24)
			var a: float = 0.18 + 0.2 * (1.0 - rem / LANCE_CHARGE)
			if hot:
				a = 0.35 + 0.35 * float(int(age * 30.0) % 2)
			boss.draw_line(EYE + d * 22.0, EYE + d * 560.0, Color(0.6, 0.95, 1.0, a), 2.0 if hot else 1.0)
		# energy gathering into the eye
		for i: int in range(6):
			var ang: float = float(i) * TAU / 6.0 + age * 3.0
			var r: float = 10.0 + 30.0 * fposmod(rem * 2.0 + float(i) * 0.17, 1.0)
			boss.draw_rect(Rect2(EYE + Vector2.from_angle(ang) * r - Vector2(22.0, 1.0), Vector2(2.0, 2.0)), Color(0.6, 0.95, 1.0, 0.8))
	# nova: a ring closing in on the eye
	if age < _nova_at:
		var t: float = 1.0 - (_nova_at - age) / NOVA_CHARGE
		boss.draw_arc(EYE, lerpf(84.0, 24.0, t), 0.0, TAU, 40, Color(0.75, 0.5, 1.0, 0.2 + 0.5 * t), 2.0)
		boss.draw_arc(EYE, lerpf(120.0, 40.0, t), 0.0, TAU, 40, Color(0.75, 0.5, 1.0, 0.1 + 0.25 * t), 1.0)
	# rewind: a clock face in front of the boss, its hand running backwards
	if _pending == "rewind1" or _pending == "rewind2":
		var c: Vector2 = Vector2(-96.0, -74.0)
		boss.draw_arc(c, 9.0, 0.0, TAU, 20, Color(0.55, 1.0, 1.0, 0.6), 1.0)
		var hand: float = -age * 9.0
		boss.draw_line(c, c + Vector2.from_angle(hand) * 7.0, Color(0.8, 1.0, 1.0, 0.9), 1.0)
		boss.draw_line(c, c + Vector2.from_angle(hand * 0.25) * 4.0, Color(0.8, 1.0, 1.0, 0.9), 1.0)
	# the tail's aim for the next sweep
	if _act >= 4:
		var g: Vector2 = GUN_LO if _k % 2 == 0 else GUN_HI
		boss.draw_line(g + Vector2.from_angle(_tail) * 6.0, g + Vector2.from_angle(_tail) * 54.0, Color(1.0, 0.35, 0.4, 0.3), 1.0)
	# act change: a shockwave ring
	if age - _act_t < 0.8:
		var u: float = (age - _act_t) / 0.8
		boss.draw_arc(EYE, 30.0 + 140.0 * u, 0.0, TAU, 48, Color(1.0, 0.3, 0.4, 0.6 * (1.0 - u)), 2.0)
