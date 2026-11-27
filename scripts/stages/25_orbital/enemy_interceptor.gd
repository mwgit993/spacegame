extends "res://scripts/stages/stage_enemy.gd"

# Interceptor: flies in tight formation with its squadron (variant 0 a V behind the leader,
# variant 1 an echelon), the whole formation drifting toward the ship's height. When the
# formation reaches BREAK_X the leader (red markings) flashes its break signal and every
# fighter shows the heading it is about to take (SIGNAL_TIME), then they all break at once:
# the leader dives at the ship with an aimed 3-way burst, the wingmen peel off and strafe a
# short burst down their new headings, so the squadron bursts open like a flower.
# Shoot the leader before the signal and the wingmen lose their orders: they scatter, fire
# one wild shot and leave.
#
# The squadron is the wave director's squad (enemy.squad_id); "phase" is the slot (0 = leader).

const Shield = preload("enemy_shieldgen.gd")

enum S { FORM, SIGNAL, BREAK, CONFUSED }

const SPEED: float = 150.0
const SIGNAL_TIME: float = 0.5
const BREAK_X: float = 335.0
const STRAFE_SHOTS: int = 4
const STRAFE_GAP: float = 0.09

static var _leaders: Dictionary = {}

var state: S = S.FORM
var slot: int = 0
var rank: int = 0
var side: float = 0.0
var offset: Vector2 = Vector2.ZERO
var anchor: Vector2 = Vector2.ZERO
var heading: float = PI
var timer: float = 0.0
var shots_left: int = 0
var shot_t: float = 0.0
var drift: Vector2 = Vector2.ZERO
var wild_t: float = 0.5


func setup() -> void:
	var solo: bool = gen > 0 or enemy.squad_id < 0
	slot = 0 if solo else int(phase)
	rank = (slot + 1) / 2
	side = 0.0 if slot == 0 else (-1.0 if slot % 2 == 1 else 1.0)
	anchor = enemy.global_position
	var toward_mid: float = 1.0 if anchor.y < 135.0 else -1.0
	if variant == 1:
		offset = Vector2(float(slot) * 12.0, float(slot) * 10.0 * toward_mid)
	else:
		offset = Vector2(float(rank) * 14.0, side * float(rank) * 12.0)
	enemy.global_position = anchor + offset
	if slot == 0 and not solo:
		for key: Variant in _leaders.keys():
			if not is_instance_valid(_leaders[key]):
				_leaders.erase(key)
		_leaders[enemy.squad_id] = enemy


func _leader_lost() -> bool:
	if slot == 0 or not _leaders.has(enemy.squad_id):
		return false
	var v: Variant = _leaders[enemy.squad_id]
	return not is_instance_valid(v) or (v as GameEnemy)._dead


func _pick_heading(pp: Vector2) -> void:
	var p: Vector2 = enemy.global_position
	if slot == 0:
		heading = PI + clampf(angle_difference(PI, (pp - p).angle()), -1.1, 1.1)
	elif variant == 1:
		var toward_mid: float = 1.0 if anchor.y < 135.0 else -1.0
		heading = PI - toward_mid * (0.22 + 0.16 * float(slot))
	else:
		heading = PI + side * (0.3 + 0.24 * float(rank))


func tick(delta: float) -> void:
	var pp: Vector2 = player_pos()
	var p: Vector2 = enemy.global_position
	var s: Sprite2D = sprite()
	match state:
		S.FORM:
			anchor.x -= SPEED * delta
			anchor.y = clampf(anchor.y + clampf(pp.y - anchor.y, -1.0, 1.0) * 26.0 * delta, 50.0, 220.0)
			p = anchor + offset + Vector2(0.0, sin(age * 3.0 + float(slot)) * 1.0)
			if _leader_lost():
				_confuse()
			elif anchor.x < BREAK_X or age > 4.0:
				state = S.SIGNAL
				timer = SIGNAL_TIME
				_pick_heading(pp)
				if slot == 0:
					sfx("boss_hp_tick", -12.0, 0.0)
		S.SIGNAL:
			anchor.x -= SPEED * 0.55 * delta
			p = anchor + offset
			timer -= delta
			if _leader_lost():
				_confuse()
			elif timer <= 0.0:
				state = S.BREAK
				shots_left = STRAFE_SHOTS
				shot_t = 0.04
				if slot == 0:
					_pick_heading(pp)
		S.BREAK:
			var d: Vector2 = Vector2.from_angle(heading)
			p += d * 205.0 * delta
			s.rotation = lerp_angle(s.rotation, heading - PI, clampf(12.0 * delta, 0.0, 1.0))
			shot_t -= delta
			if shots_left > 0 and shot_t <= 0.0:
				shot_t = STRAFE_GAP
				shots_left -= 1
				if slot == 0 and shots_left == STRAFE_SHOTS - 1:
					for k: int in [-1, 0, 1]:
						shoot_aimed_from(p + d * 7.0, 160.0, bullet_b(), float(k) * 0.2)
				elif slot != 0 or shots_left == 0:
					emit_bullet(p + d * 7.0, d * 175.0, bullet_a())
		S.CONFUSED:
			p += drift * delta
			drift.y += sin(age * 9.0 + float(slot)) * 60.0 * delta
			s.rotation = sin(age * 14.0) * 0.4
			wild_t -= delta
			if wild_t <= 0.0 and wild_t > -1.0:
				wild_t = -5.0
				if on_screen(40.0, 470.0):
					emit_bullet(p, Vector2.from_angle(PI + randf_range(-0.7, 0.7)) * 110.0, bullet_b())
	enemy.global_position = p
	if slot == 0:
		set_texture("orbital_icpt_flash" if state == S.SIGNAL and int(age * 16.0) % 2 == 0 else "orbital_icpt_lead")
	else:
		set_texture("orbital_icpt_0")


func _confuse() -> void:
	state = S.CONFUSED
	drift = Vector2(-randf_range(70.0, 110.0), randf_range(-70.0, 70.0))
	wild_t = randf_range(0.3, 0.7)
	sparks(enemy.global_position, Color("#ffe060"), 2)


func draw() -> void:
	if state == S.SIGNAL:
		# every fighter shows its break heading
		var k: float = 1.0 - clampf(timer / SIGNAL_TIME, 0.0, 1.0)
		var d: Vector2 = Vector2.from_angle(heading)
		var col: Color = Color(1.0, 0.35, 0.3, 0.3 + 0.4 * k) if slot == 0 else Color(1.0, 0.75, 0.3, 0.2 + 0.35 * k)
		for seg: int in range(5):
			var a: float = 9.0 + float(seg) * 10.0
			enemy.draw_line(d * a, d * (a + 5.0), col, 1.0)
		if slot == 0:
			enemy.draw_arc(Vector2.ZERO, 9.0 + 4.0 * k, 0.0, TAU, 16, Color(1.0, 0.9, 0.5, 0.5 * (1.0 - k)), 1.0)
	elif state == S.FORM and slot == 0:
		# the leader's beacon
		if int(age * 3.0) % 2 == 0:
			enemy.draw_rect(Rect2(7.0, -1.0, 1.0, 1.0), Color(1.0, 0.3, 0.3, 0.9))
	if Shield.covers(enemy):
		Shield.draw_bubble(enemy, 11.0)


func modify_damage(dmg: float) -> float:
	if Shield.covers(enemy):
		Shield.blocked(enemy)
		return dmg * Shield.COVER_MULT
	return dmg


func on_death() -> void:
	sparks(enemy.global_position, Color("#f2f7ff"), 6)
	sparks(enemy.global_position, Color("#f0a030") if slot != 0 else Color("#ff3a3a"), 4)
