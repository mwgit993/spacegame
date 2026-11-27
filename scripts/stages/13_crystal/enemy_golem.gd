extends "res://scripts/stages/stage_enemy.gd"

# GEM GOLEM: a hulking crystal brute that wades in and holds the right side. While its facets
# shimmer with rainbow light (MIRROR) it shrugs off most damage and throws hits back: a hit
# sends a slow shard back at the player from where it struck (at most one per REFLECT_GAP s).
# Then the shimmer dies, its chest cracks open (a glint is the telegraph) and it bursts a ring
# of crystal spikes; while open it takes extra damage. After CYCLES cycles it lumbers off.
# Unlike the magma golem's rock shield, holding fire during the shimmer is what keeps you safe.

enum Phase { ENTER, MIRROR, OPEN, LEAVE }

const MIRROR_TIME: float = 2.4
const OPEN_TELL: float = 0.55
const OPEN_TIME: float = 1.4
const REFLECT_GAP: float = 0.22
const SPIKES: int = 12
const CYCLES: int = 3

var state: Phase = Phase.ENTER
var timer: float = 0.0
var reflect_cd: float = 0.0
var cycles_left: int = CYCLES
var fired: bool = false
var target_x: float = 400.0
var spin: float = 0.0


func setup() -> void:
	target_x = randf_range(372.0, 420.0)
	spin = randf() * TAU


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	reflect_cd -= delta
	match state:
		Phase.ENTER:
			p.x = lerpf(p.x, target_x, clampf(1.5 * delta, 0.0, 1.0))
			if p.x < target_x + 10.0:
				state = Phase.MIRROR
				timer = MIRROR_TIME
		Phase.MIRROR:
			timer -= delta
			if timer <= 0.0:
				state = Phase.OPEN
				timer = OPEN_TELL + OPEN_TIME
				fired = false
				set_texture("crystal_golem_1")
				sfx("shield_hit", -12.0, 0.1)
		Phase.OPEN:
			timer -= delta
			if not fired and timer <= OPEN_TIME:
				fired = true
				_burst(false)
			if timer <= 0.0:
				set_texture("crystal_golem_0")
				cycles_left -= 1
				if cycles_left <= 0 or age > 18.0:
					state = Phase.LEAVE
				else:
					state = Phase.MIRROR
					timer = fire_cd(MIRROR_TIME * 1.35)
		Phase.LEAVE:
			p.x -= 52.0 * delta
	if state != Phase.ENTER:
		p.y = clampf(base_y + sin(age * 1.1 + phase) * 8.0, 46.0, 226.0)
	enemy.global_position = p


func _burst(deferred: bool) -> void:
	var origin: Vector2 = enemy.global_position + Vector2(0.0, -1.0)
	for i: int in range(SPIKES):
		var a: float = spin + TAU * float(i) / float(SPIKES)
		emit_bullet(origin, Vector2.from_angle(a) * 96.0, "crystal_shard_%d" % (i % 3), deferred, 2.5)
	spin += 0.31
	sparks(origin, Color("#5ae8a8"), 8)
	sfx("explode", -12.0, 0.1)


func _mirroring() -> bool:
	return state == Phase.ENTER or state == Phase.MIRROR or (state == Phase.OPEN and timer > OPEN_TIME + 0.2)


func modify_damage(dmg: float) -> float:
	if state == Phase.OPEN and timer <= OPEN_TIME + 0.2:
		return dmg * 1.4
	if state == Phase.LEAVE:
		return dmg
	if reflect_cd <= 0.0 and on_screen(60.0, 460.0):
		reflect_cd = REFLECT_GAP
		var from: Vector2 = enemy.global_position + Vector2(-12.0, randf_range(-9.0, 9.0))
		var dir: Vector2 = (player_pos() - from).normalized()
		emit_bullet(from, dir * 100.0, "crystal_shard_%d" % (randi() % 3), true, 2.5)
	return dmg * 0.3


func draw() -> void:
	draw_hp_bar(30.0, -21.0)
	if _mirroring():
		# A rainbow glare sweeping across the facets.
		var u: float = fposmod(age * 0.9, 1.0)
		var x0: float = lerpf(-16.0, 16.0, u)
		var cols: Array[Color] = [Color(1.0, 0.35, 0.45, 0.55), Color(1.0, 0.9, 0.35, 0.55), Color(0.35, 1.0, 0.6, 0.55), Color(0.5, 0.6, 1.0, 0.55)]
		for c: int in range(cols.size()):
			var xx: float = x0 + float(c)
			if absf(xx) < 13.0:
				enemy.draw_line(Vector2(xx - 3.0, -11.0), Vector2(xx + 3.0, 9.0), cols[c], 1.0)
		if reflect_cd > REFLECT_GAP - 0.08:
			enemy.draw_circle(Vector2(-13.0, 0.0), 5.0, Color(1.0, 1.0, 1.0, 0.35))
	elif state == Phase.OPEN:
		var core: Vector2 = Vector2(0.0, 1.0)
		draw_glint(core, timer - OPEN_TIME, OPEN_TELL, Color(0.4, 1.0, 0.65))
		if timer <= OPEN_TIME:
			var pulse: float = 0.5 + 0.5 * sin(age * 22.0)
			enemy.draw_circle(core, 4.0 + pulse * 2.0, Color(0.4, 1.0, 0.65, 0.3))


func on_death() -> void:
	_burst(true)
	sparks(enemy.global_position, Color("#f070b8"), 10)
