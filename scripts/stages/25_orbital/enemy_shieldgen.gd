extends "res://scripts/stages/stage_enemy.gd"

# Shield generator: a slow hexagonal drone that parks at the right and projects a hex shield
# over the stage's other enemies within RADIUS (link beams show who is covered, and a covered
# enemy wears a hex bubble). Covered enemies take only COVER_MULT damage until the generator
# dies. Generators never cover each other, so a generator is always the thing to shoot first.
# Every so often its core flares (the telegraph, PULSE_WARN) and it pulses out a slow ring of
# hex rounds; in between, its front emitter glints and snaps an aimed shot at the ship. After
# LIFETIME it drifts away to the left.
#
# The stage's other behaviours ask covers(enemy) in their modify_damage(). Generic enemies have
# no damage hook, so they are never shielded.

const RADIUS: float = 78.0
const COVER_MULT: float = 0.15
const PULSE_WARN: float = 0.55
const LIFETIME: float = 17.0
const SNAP: Vector2 = Vector2(-11.0, 0.0)

static var _live: Array = []

var target_x: float = 400.0
var warn: float = 0.0
var spin: float = 0.0
var covered: Array = []
var scan_t: float = 0.0
var snap_t: float = 1.0


# True if a live generator (other than the enemy itself) covers this enemy.
static func covers(e: GameEnemy) -> bool:
	for v: Variant in _live:
		if not is_instance_valid(v):
			continue
		var g: GameEnemy = v as GameEnemy
		if g == null or g == e or g._dead or g._warn_timer > 0.0 or e.module_kind == "shieldgen":
			continue
		if g.global_position.distance_squared_to(e.global_position) < RADIUS * RADIUS:
			return true
	return false


# Hex bubble drawn by a covered enemy around itself (its own local space).
static func draw_bubble(e: GameEnemy, r: float) -> void:
	var a: float = 0.22 + 0.12 * sin(e._age * 7.0)
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(7):
		pts.append(Vector2.from_angle(PI / 6.0 + TAU * float(i) / 6.0) * r)
	e.draw_polyline(pts, Color(0.45, 0.85, 1.0, a), 1.0)
	e.draw_colored_polygon(pts.slice(0, 6), Color(0.35, 0.7, 1.0, 0.06))


# Blocked-hit feedback for a covered enemy (throttled).
static func blocked(e: GameEnemy) -> void:
	if e.fx != null and e._block_fx_t <= 0.0:
		e._block_fx_t = 0.09
		e.fx.spawn_hit_sparks(e.global_position + Vector2(-8.0, randf_range(-6.0, 6.0)), Color("#8ad8ff"), 2)


static func _prune() -> void:
	var keep: Array = []
	for v: Variant in _live:
		if is_instance_valid(v) and not (v as GameEnemy)._dead:
			keep.append(v)
	_live = keep


func setup() -> void:
	_prune()
	_live.append(enemy)
	target_x = randf_range(372.0, 430.0)
	fire_timer = 1.6
	snap_t = 0.9 + randf() * 0.4
	spin = randf() * TAU


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	if age < LIFETIME:
		p.x = lerpf(p.x, target_x, clampf(1.1 * delta, 0.0, 1.0))
		if absf(p.x - target_x) > 30.0:
			p.x -= 30.0 * delta
	else:
		p.x -= 34.0 * delta
	p.y = base_y + sin(age * 0.9 + phase) * 10.0
	enemy.global_position = p
	spin += delta * 0.8
	# who's covered (for the link beams)
	scan_t -= delta
	if scan_t <= 0.0:
		scan_t = 0.1
		covered.clear()
		for node: Node in enemy.get_tree().get_nodes_in_group("enemies"):
			var ge: GameEnemy = node as GameEnemy
			if ge == null or ge == enemy or ge._dead or ge.enemy_type != GameEnemy.Type.MODULE or ge.module_kind == "shieldgen":
				continue
			if ge.global_position.distance_squared_to(p) < RADIUS * RADIUS:
				covered.append(ge)
	# pulse attack
	if warn > 0.0:
		warn -= delta
		if warn <= 0.0:
			var n: int = 8
			var rot: float = spin
			for i: int in range(n):
				emit_bullet(p, Vector2.from_angle(rot + TAU * float(i) / float(n)) * 74.0, bullet_b())
			sfx("shield_hit", -14.0, 0.1)
			fire_timer = fire_cd(2.9)
	else:
		fire_timer -= delta
		if fire_timer <= 0.0 and on_screen(90.0, 450.0):
			warn = PULSE_WARN
		elif on_screen(90.0, 450.0):
			snap_t -= delta
			if snap_t <= 0.0:
				snap_t = fire_cd(1.8)
				shoot_aimed_from(p + SNAP, 155.0, bullet_a())
				sfx("laser", -17.0, 0.08)
	set_texture("orbital_gen_1" if warn > 0.0 and int(age * 14.0) % 2 == 0 else "orbital_gen_0")


func draw() -> void:
	var p: Vector2 = enemy.global_position
	# coverage boundary: a faint rotating dashed hex
	var pts: Array[Vector2] = []
	for i: int in range(6):
		pts.append(Vector2.from_angle(spin * 0.3 + TAU * float(i) / 6.0) * RADIUS)
	for i2: int in range(6):
		var a: Vector2 = pts[i2]
		var b: Vector2 = pts[(i2 + 1) % 6]
		for s: int in range(4):
			enemy.draw_line(a.lerp(b, float(s) / 4.0), a.lerp(b, (float(s) + 0.5) / 4.0), Color(0.4, 0.8, 1.0, 0.13), 1.0)
	# link beams to every covered enemy
	var flick: float = 0.25 + 0.15 * float(int(age * 20.0) % 2)
	for v: Variant in covered:
		if not is_instance_valid(v):
			continue
		var to: Vector2 = (v as GameEnemy).global_position - p
		if to.length() < 12.0:
			continue
		enemy.draw_line(to.normalized() * 10.0, to - to.normalized() * 9.0, Color(0.5, 0.9, 1.0, flick), 1.0)
	if warn > 0.0:
		var k: float = 1.0 - clampf(warn / PULSE_WARN, 0.0, 1.0)
		enemy.draw_arc(Vector2.ZERO, 8.0 + 14.0 * k, 0.0, TAU, 18, Color(0.55, 0.9, 1.0, 0.25 + 0.4 * k), 1.0)
	else:
		draw_glint(SNAP, snap_t, 0.3, Color(1.0, 0.6, 0.2))
	draw_hp_bar(24.0, -17.0)


func on_death() -> void:
	_prune()
	sparks(enemy.global_position, Color("#70dcff"), 12)
	sparks(enemy.global_position, Color("#f0a030"), 6)
	sfx("shield_hit", -8.0, 0.05)
