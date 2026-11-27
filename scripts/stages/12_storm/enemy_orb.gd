extends "res://scripts/stages/stage_enemy.gd"

# LIGHTNING ORB: comes in squads strung out in a line (the wave director gives each orb its
# index in the squad as its "phase"). Each orb links to the next one in its squad: a faint
# flickering line telegraphs the link for LINK_WARN seconds, then it becomes a short-lived
# electric fence, a row of stationary sparks along the segment that drifts with the orbs.
# An orb whose partner is gone (or that came alone) fires an aimed spark instead.

const LINK_WARN: float = 0.8
const FENCE_LIFE: float = 1.15
const FENCE_GAP: float = 11.0
const SPEED: float = 34.0

var partner: GameEnemy = null
var _look_t: float = 0.0


func setup() -> void:
	fire_timer = 1.0 + phase * 0.12


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= SPEED * delta
	p.y = clampf(base_y + sin(age * 1.8 + phase * 0.9) * 6.0, 40.0, 238.0)
	enemy.global_position = p
	set_texture("storm_orb_%d" % (int(age * 9.0) % 2))
	# Squadmates spawn staggered, so keep looking for the partner until it turns up.
	_look_t -= delta
	if not _partner_ok() and _look_t <= 0.0:
		_look_t = 0.4
		_find_partner()
	fire_timer -= delta
	if not on_screen(60.0, 456.0):
		fire_timer = maxf(fire_timer, LINK_WARN)
	if fire_timer <= 0.0 and on_screen(60.0, 456.0):
		fire_timer = fire_cd(2.8)
		if partner != null and _partner_ok() and partner.global_position.x < 460.0:
			_fence()
		else:
			shoot_aimed(140.0, bullet_b())
		sfx("zap", -15.0, 0.1)


func _partner_ok() -> bool:
	return partner != null and is_instance_valid(partner) and not partner._dead and not partner.is_queued_for_deletion()


# The next orb in the same squad (index + 1).
func _find_partner() -> void:
	partner = null
	if enemy.squad_id < 0 or not enemy.is_inside_tree():
		return
	for node: Node in enemy.get_tree().get_nodes_in_group("enemies"):
		var ge: GameEnemy = node as GameEnemy
		if ge == null or ge == enemy or ge.module_kind != "orb" or ge.squad_id != enemy.squad_id:
			continue
		if absf(ge._phase_offset - (phase + 1.0)) < 0.01 and not ge._dead:
			partner = ge
			return


func _fence() -> void:
	var a: Vector2 = enemy.global_position
	var b: Vector2 = partner.global_position
	var d: float = a.distance_to(b)
	var n: int = maxi(1, int(d / FENCE_GAP))
	for i: int in range(1, n):
		var q: Vector2 = a.lerp(b, float(i) / float(n))
		var s: GameBullet = emit_bullet(q, Vector2(-SPEED / maxf(0.1, enemy._shot_mult), 0.0), bullet_b())
		if s != null:
			s.life_left = FENCE_LIFE


func draw() -> void:
	var linking: bool = fire_timer > 0.0 and fire_timer < LINK_WARN and _partner_ok()
	if linking:
		var k: float = 1.0 - fire_timer / LINK_WARN
		var to: Vector2 = partner.global_position - enemy.global_position
		var flick: float = 0.15 + 0.45 * k * float(int(age * 24.0) % 2)
		# A jittery dashed line: it firms up as the link charges.
		var steps: int = maxi(2, int(to.length() / 6.0))
		var prev: Vector2 = Vector2.ZERO
		for i: int in range(1, steps + 1):
			var t: float = float(i) / float(steps)
			var jit: Vector2 = to.orthogonal().normalized() * sin(age * 60.0 + float(i) * 1.7) * 2.0 * (1.0 - k)
			var q: Vector2 = to * t + (jit if i < steps else Vector2.ZERO)
			if i % 2 == 0 or k > 0.6:
				enemy.draw_line(prev, q, Color(1.0, 0.95, 0.5, flick), 1.0)
			prev = q
		draw_glint(Vector2.ZERO, fire_timer, LINK_WARN, Color(1.0, 0.95, 0.4))
	elif not _partner_ok():
		draw_glint(Vector2(-6.0, 0.0), fire_timer, 0.35, Color(1.0, 0.95, 0.4))


func on_death() -> void:
	sparks(enemy.global_position, Color("#a8e4ff"), 7)
