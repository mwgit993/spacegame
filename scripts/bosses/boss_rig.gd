extends Node2D

# Base of the animated stage 1-8 bosses (Matt: the old ones "should be redone to give them more
# life, animations, and excitement"). Instead of three painted frames, a boss is a rig of parts
# (hull, turrets, claws, jaws, wings...) that move in code, with a dino pilot in a canopy.
#
# GameEnemy adds the rig under its sprite (so the teleport-in squash, the recoil, the sway and the
# white hit flash still apply to every part), stops drawing the old frames, and reports the fight:
#   on_attack(pattern)  each attack        on_hurt()   each hit that does damage
#   on_phase(p)         phase 2 and 3      on_pose()   the intro's power pose
#   on_die()            death begins       eject(layer, fx)  the pilot bails out as it explodes
# and asks muzzle(name) where to fire from, so shots leave the moving cannons, claws and jaws.
#
# A subclass paints and assembles its parts in build() and moves them in animate(delta), using:
#   t       seconds alive               windup  0 -> 1 over the WINDUP s before each attack
#   kick    1 on an attack, decays      hurt_k  1 on a hit, decays fast
#   rage    1 on a phase change, decays slowly   pattern  the attack pattern (0-2) coming up
#   phase() 1-3                         aim()   unit vector from the boss towards the player
# Add a part with part(), a muzzle point with marker(), the pilot with add_pilot(). Their `z` is
# the draw order: for parts on the rig itself, a layer from -4 (back) to 4 (front); for parts on
# another part, negative means behind that part. Never use z_index (see _layers).

const Kit = preload("res://scripts/bosses/boss_kit.gd")
const DinoPilot = preload("res://scripts/bosses/dino_pilot.gd")
const WINDUP: float = 0.42

var boss: GameEnemy = null
var t: float = 0.0
var windup: float = 0.0
var kick: float = 0.0
var hurt_k: float = 0.0
var rage: float = 0.0
var pattern: int = 0
var dying: bool = false
var debug_phase: int = 0    # tools only: force phase() / next_pattern() without a GameEnemy
var debug_next: int = -1
var pilot: DinoPilot = null
var _markers: Dictionary = {}
# Draw layers for the top-level parts (z -4..4). Everything stays at z_index 0, so the boss keeps
# drawing under bullets and explosions and over the background; order comes from these layer
# nodes and, inside a part, from show_behind_parent.
const LAYERS: int = 9
var _layers: Array[Node2D] = []


func setup(b: GameEnemy) -> void:
	boss = b
	use_parent_material = true
	for i: int in range(LAYERS):
		var layer: Node2D = Node2D.new()
		layer.use_parent_material = true
		add_child(layer)
		_layers.append(layer)
	build()


# The node a part with draw order `z` goes under: a layer for top-level parts, else the parent
# (a negative z then draws it behind that parent).
func _host(parent: Node2D, z: int, item: CanvasItem) -> Node2D:
	if parent == self and not _layers.is_empty():
		return _layers[clampi(z + LAYERS / 2, 0, LAYERS - 1)]
	item.show_behind_parent = z < 0
	return parent


# Override: paint (Kit.cached) and assemble the parts.
func build() -> void:
	pass


# Override: move the parts. Called every frame after the shared timers update.
func animate(_delta: float) -> void:
	pass


func phase() -> int:
	if debug_phase > 0:
		return debug_phase
	return boss.boss_phase if boss != null else 1


# The pattern the coming attack will use (what the windup should show).
func next_pattern() -> int:
	if debug_next >= 0:
		return debug_next
	return boss.next_boss_pattern() if boss != null else 0


func aim() -> Vector2:
	if boss == null:
		return Vector2.LEFT
	return (boss._player_pos() - global_position).normalized()


# A sprite part under `parent`. `joint` is where it sits in the parent's space; `pivot` is the
# point of its texture that sits on the joint (and that it rotates around).
func part(parent: Node2D, tex: Texture2D, joint: Vector2, pivot: Vector2, z: int = 0) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = -pivot
	s.position = joint
	s.use_parent_material = true
	_host(parent, z, s).add_child(s)
	return s


# An empty pivot node (to group parts that move together).
func joint(parent: Node2D, pos: Vector2, z: int = 0) -> Node2D:
	var n: Node2D = Node2D.new()
	n.position = pos
	n.use_parent_material = true
	_host(parent, z, n).add_child(n)
	return n


# A named muzzle point that moves with `parent`.
func marker(parent: Node2D, marker_name: String, pos: Vector2) -> void:
	var m: Node2D = Node2D.new()
	m.position = pos
	parent.add_child(m)
	_markers[marker_name] = m


func has_muzzle(marker_name: String) -> bool:
	return _markers.has(marker_name)


func muzzle(marker_name: String) -> Vector2:
	var m: Node2D = _markers.get(marker_name, null)
	return m.global_position if m != null else global_position


func add_pilot(parent: Node2D, pos: Vector2, species: String, canopy: Vector2i = Vector2i(36, 28), z: int = 3) -> DinoPilot:
	pilot = DinoPilot.new()
	pilot.position = pos
	pilot.use_parent_material = true
	_host(parent, z, pilot).add_child(pilot)
	pilot.setup(species, canopy)
	return pilot


func _process(delta: float) -> void:
	t += delta
	kick = move_toward(kick, 0.0, delta * 3.2)
	hurt_k = move_toward(hurt_k, 0.0, delta * 9.0)
	rage = move_toward(rage, 0.0, delta * 0.8)
	if boss != null and not dying and not boss.boss_intro_active:
		windup = clampf(1.0 - boss._fire_timer / WINDUP, 0.0, 1.0)
	else:
		windup = 0.0
	if pilot != null and boss != null:
		pilot.low_hp = boss.boss_phase >= 3 or dying
	animate(delta)


func on_attack(p: int) -> void:
	pattern = p
	kick = 1.0
	if pilot != null:
		pilot.roar(0.3)


func on_hurt() -> void:
	hurt_k = 1.0
	if pilot != null:
		pilot.hurt()


func on_phase(_p: int) -> void:
	rage = 1.0
	if pilot != null:
		pilot.roar(0.95)


func on_pose() -> void:
	rage = 0.7
	if pilot != null:
		pilot.roar(0.6)


func on_die() -> void:
	dying = true


# The pilot bails out (call just before the boss is freed).
func eject(layer: Node, fx: Node) -> void:
	if pilot != null and pilot.visible:
		pilot.eject(layer, fx)


# Smoothly approaches 1 at the start and 0 at the end of a pulse: handy for one-shot motions.
static func ease_pulse(k: float) -> float:
	return sin(clampf(k, 0.0, 1.0) * PI)
