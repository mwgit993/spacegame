extends "res://scripts/stages/stage_enemy.gd"

# Strike fighter, called in by a strike marshal (a child: no Scrap). It screams in from behind
# along the marked strip and out past the right edge, strafing as it goes: every STRAFE_GAP it
# drops a pair of shots that drift up and down out of the strip, so the band itself is the
# danger and the shots fan out of it slowly. No more are called while CAP of them are about.

const CAP: int = 9
const STRAFE_GAP: float = 0.38

var strafe_t: float = 0.2


static func count(from: GameEnemy) -> int:
	var n: int = 0
	for node: Node in from.get_tree().get_nodes_in_group("enemies"):
		var ge: GameEnemy = node as GameEnemy
		if ge != null and ge.module_kind == "striker" and not ge._dead:
			n += 1
	return n


func setup() -> void:
	vel = Vector2(340.0, 0.0)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	if vel.x < 200.0:
		vel = Vector2(340.0, 0.0)
	p += vel * delta
	p.y += sin(age * 9.0 + phase) * 6.0 * delta
	enemy.global_position = p
	if p.x > 50.0 and p.x < 410.0:
		strafe_t -= delta
		if strafe_t <= 0.0:
			strafe_t = STRAFE_GAP
			emit_bullet(p + Vector2(-4.0, -3.0), Vector2(-34.0, -58.0), bullet_b())
			emit_bullet(p + Vector2(-4.0, 3.0), Vector2(-34.0, 58.0), bullet_b())
	set_texture("mothership_striker_1" if int(age * 14.0) % 2 == 0 else "mothership_striker_0")


func on_death() -> void:
	sparks(enemy.global_position, Color("#ff9a30"), 5)
