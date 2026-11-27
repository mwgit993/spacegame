extends "res://scripts/stages/stage_enemy.gd"

# Ooze blob: bounces along toward the ship. Before each hop it squashes down (the telegraph);
# big and medium blobs splash three droplets up when they land. Shot down, a blob of gen 0 or 1
# splits into two smaller ones (children: no Scrap; small ones don't split), so one big blob
# makes at most 7, and never while CAP blobs are about. After LIFETIME it oozes off left.

const CAP: int = 12
const GRAVITY: float = 260.0
const SQUASH_TIME: float = 0.35
const LIFETIME: float = 13.0
const RADIUS: Array[float] = [7.0, 5.0, 3.6]

var size: int = 0
var on_floor: bool = false
var squash_t: float = 0.0
var sized: bool = false


static func count(from: GameEnemy) -> int:
	var n: int = 0
	for node: Node in from.get_tree().get_nodes_in_group("enemies"):
		var ge: GameEnemy = node as GameEnemy
		if ge != null and ge.module_kind == "blob" and not ge._dead:
			n += 1
	return n


func setup() -> void:
	size = mini(gen, 2)
	if size > 0:
		enemy.max_hp *= pow(0.55, float(size))
	set_texture("biolab_blob_%d" % size)


func tick(delta: float) -> void:
	if not sized:
		# the hit circle shrinks with the blob (the shape is added after setup)
		sized = true
		for c: Node in enemy.get_children():
			var cs: CollisionShape2D = c as CollisionShape2D
			if cs != null and cs.shape is CircleShape2D:
				(cs.shape as CircleShape2D).radius = RADIUS[size] - 0.5
	var p: Vector2 = enemy.global_position
	var r: float = RADIUS[size]
	var floor_y: float = 249.0 - r
	var s: Sprite2D = sprite()
	if on_floor:
		squash_t -= delta
		var k: float = 1.0 - clampf(squash_t / SQUASH_TIME, 0.0, 1.0)
		s.scale = Vector2(1.0 + 0.3 * k, 1.0 - 0.3 * k)
		s.position.y = r * 0.3 * k
		if squash_t <= 0.0:
			on_floor = false
			s.scale = Vector2.ONE
			s.position.y = 0.0
			var toward: float = signf(player_pos().x - p.x)
			var vx: float = toward * 45.0 - 25.0
			if age > LIFETIME:
				vx = -70.0
			vel = Vector2(vx, -randf_range(150.0, 195.0) * (1.0 - 0.12 * float(size)))
	else:
		vel.y += GRAVITY * delta
		p += vel * delta
		if p.y < 36.0 + r and vel.y < 0.0:
			p.y = 36.0 + r
			vel.y = absf(vel.y) * 0.4
		if p.y >= floor_y and vel.y > 0.0:
			p.y = floor_y
			on_floor = true
			squash_t = SQUASH_TIME
			if size < 2 and on_screen(60.0, 460.0):
				for side: float in [-1.0, 0.0, 1.0]:
					emit_bullet(p + Vector2(0.0, -r), Vector2(side * 45.0 - 20.0, -95.0), bullet_b())
	enemy.global_position = p


func draw() -> void:
	if on_floor:
		var k: float = 1.0 - clampf(squash_t / SQUASH_TIME, 0.0, 1.0)
		var r: float = RADIUS[size]
		enemy.draw_rect(Rect2(-r - 2.0, r - 1.0, r * 2.0 + 4.0, 1.0), Color(0.5, 1.0, 0.2, 0.2 + 0.3 * k))


func on_death() -> void:
	sparks(enemy.global_position, Color("#7ad830"), 6)
	if size >= 2 or count(enemy) >= CAP:
		return
	for side: float in [-1.0, 1.0]:
		spawn_child("blob", enemy.global_position + Vector2(side * 4.0, -2.0), Vector2(side * 55.0 - 15.0, -130.0))
