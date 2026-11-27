extends "res://scripts/stages/stage_enemy.gd"

# ARENA TURRET: a hazard emitter in a floor slot (variant 0) or a ceiling slot (variant 1),
# riding the deck scroll. It sits armoured in its hatch until it's well on screen, pops up, and
# projects laser barriers: a flashing dotted line from its emitter to the edge of the gap marks
# the next barrier (gold brackets mark the gap), then the barrier fires as a column of bars that
# sweeps left. A floor and a ceiling turret spawned together share the gap ("phase" carries its
# centre), so between them they raise a full wall with one opening; the gap shifts for each of
# the WALLS barriers. Shooting one down leaves its half of the wall open. Armoured while
# retracted (in the hatch, rising, sinking).

enum Phase { SLOT, RISE, ARMED, SINK, GONE }

const FLOOR_Y: float = 249.0
const CEIL_Y: float = 37.0
const SCROLL: float = 40.0
const RISE_TIME: float = 0.4
const TELL: float = 0.8
const PAUSE: float = 0.6
const WALLS: int = 4
const GAP: float = 46.0
const SPACING: float = 12.0
const WALL_SPEED: float = 88.0
const GAP_SHIFT: Array[float] = [0.0, 36.0, -36.0, 0.0]
const ARMOUR: float = 0.15

var state: Phase = Phase.SLOT
var timer: float = 0.3
var up: float = -1.0     # -1 on the floor (emits upward), +1 on the ceiling (downward)
var gap0: float = 140.0
var wall_i: int = 0
var block_cd: float = 0.0


func setup() -> void:
	up = 1.0 if variant == 1 else -1.0
	enemy.global_position.y = CEIL_Y if variant == 1 else FLOOR_Y
	base_y = enemy.global_position.y
	sprite().flip_v = variant == 1
	gap0 = clampf(phase, 70.0, 210.0) if phase > 1.0 else 140.0
	timer = 0.3


func _gap() -> float:
	return clampf(gap0 + GAP_SHIFT[wall_i % GAP_SHIFT.size()], 66.0, 214.0)


func _tip() -> Vector2:
	return enemy.global_position + Vector2(0.0, up * 7.0)


# The barrier runs from the emitter to the near edge of the gap.
func _wall_end() -> float:
	return _gap() + GAP * 0.5 if up < 0.0 else _gap() - GAP * 0.5


func tick(delta: float) -> void:
	enemy.global_position.x -= SCROLL * delta
	block_cd -= delta
	match state:
		Phase.SLOT:
			set_texture("arena_turret_0")
			if on_screen(80.0, 446.0):
				timer -= delta
				if timer <= 0.0:
					state = Phase.RISE
					timer = RISE_TIME
					sfx("shield_hit", -16.0, 0.1)
		Phase.RISE:
			timer -= delta
			set_texture("arena_turret_1" if timer > RISE_TIME * 0.5 else "arena_turret_2")
			if timer <= 0.0:
				state = Phase.ARMED
				timer = TELL
		Phase.ARMED:
			timer -= delta
			set_texture("arena_turret_3" if timer < TELL else "arena_turret_2")
			if timer <= 0.0:
				if on_screen(50.0, 470.0):
					_fire_wall()
				wall_i += 1
				if wall_i >= WALLS or enemy.global_position.x < 70.0:
					state = Phase.SINK
					timer = RISE_TIME
				else:
					timer = TELL + PAUSE
		Phase.SINK:
			timer -= delta
			set_texture("arena_turret_2" if timer > RISE_TIME * 0.5 else "arena_turret_1")
			if timer <= 0.0:
				state = Phase.GONE
		Phase.GONE:
			set_texture("arena_turret_0")


func _fire_wall() -> void:
	var y0: float = _tip().y
	var y1: float = _wall_end()
	var span: float = (y1 - y0) * up
	if span < 0.0:
		return
	var n: int = int(span / SPACING) + 1
	var x: float = enemy.global_position.x
	for i: int in range(n):
		var y: float = y0 + up * float(i) * SPACING
		emit_bullet(Vector2(x, y), Vector2(-WALL_SPEED, 0.0), "arena_wall", false, 3.5)
	sparks(_tip(), Color("#ff3cc8"), 4)
	sfx("laser", -13.0, 0.06)


func _retracted() -> bool:
	return state == Phase.SLOT or state == Phase.RISE or state == Phase.SINK or state == Phase.GONE


func modify_damage(dmg: float) -> float:
	if _retracted():
		if block_cd <= 0.0:
			block_cd = 0.12
			sparks(enemy.global_position, Color("#c8d0e8"), 2)
		return dmg * ARMOUR
	return dmg


func draw() -> void:
	draw_hp_bar(16.0, -17.0 if up < 0.0 else 14.0)
	if state != Phase.ARMED or timer >= TELL:
		return
	# Telegraph: a flashing dotted line from the emitter to the gap edge, gold gap brackets.
	var u: float = 1.0 - timer / TELL
	var on: bool = fposmod(age * (8.0 + 14.0 * u), 1.0) < 0.6
	var a: float = (0.25 + 0.45 * u) * (1.0 if on else 0.45)
	var tip_l: float = up * 7.0
	var end_l: float = _wall_end() - enemy.global_position.y
	var y: float = tip_l
	var guard: int = 0
	while (end_l - y) * up > 0.0 and guard < 80:
		enemy.draw_rect(Rect2(-1.0, floorf(y), 2.0, 2.0), Color(1.0, 0.3, 0.82, a))
		y += up * 5.0
		guard += 1
	var gc: Color = Color(1.0, 0.82, 0.3, 0.4 + 0.5 * u)
	enemy.draw_rect(Rect2(-5.0, floorf(end_l), 11.0, 1.0), gc)
	enemy.draw_rect(Rect2(-5.0, floorf(end_l) - up * 2.0, 1.0, 2.0), gc)
	enemy.draw_rect(Rect2(5.0, floorf(end_l) - up * 2.0, 1.0, 2.0), gc)
	draw_glint(Vector2(0.0, up * 8.0), timer, TELL, Color(1.0, 0.3, 0.82))


func on_death() -> void:
	sparks(enemy.global_position + Vector2(0.0, up * 4.0), Color("#ff3cc8"), 7)
