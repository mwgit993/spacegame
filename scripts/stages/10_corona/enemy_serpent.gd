extends "res://scripts/stages/stage_enemy.gd"

# FLARE SERPENT: lurks under the star's surface. For WARN seconds the spot boils (a swelling glow
# and a dotted preview of its leap arc: the entrance telegraph, hidden and unhittable), then it
# leaps out in a parabola, its molten body trailing behind. Every segment is solid (touching any
# of them hurts) and shootable. It drips fire as it flies, bites an aimed 3-way spread at the top
# of the arc (its jaw opens and glints first), and dives back into the surface.
# variant 1 leaps higher and shorter.

const WARN: float = 1.0
const SURFACE_Y: float = 256.0
const GRAVITY: float = 255.0
const SEGMENTS: int = 6
const SPACING: float = 7.0
const DRIP_GAP: float = 0.45
const BITE_WARN: float = 0.35

var segs: Array[Sprite2D] = []
var shapes: Array[CollisionShape2D] = []
var trail: Array[Vector2] = []
var launch: Vector2 = Vector2(-92.0, -315.0)
var drip_t: float = 0.3
var bitten: bool = false
var flying: bool = false


func setup() -> void:
	launch = Vector2(-92.0, -315.0) if variant == 0 else Vector2(-62.0, -335.0)
	enemy.global_position.y = SURFACE_Y
	base_y = SURFACE_Y
	warn_timer = WARN
	for i: int in range(SEGMENTS):
		var s: Sprite2D = Sprite2D.new()
		var key: String = "corona_serpent_tail" if i == SEGMENTS - 1 else "corona_serpent_body"
		_check_key(key)
		s.texture = PixelArt.tex(key)
		s.material = enemy._mat
		s.show_behind_parent = true
		s.visible = false
		enemy.add_child(s)
		enemy.move_child(s, 0)   # each segment draws under the one in front of it
		segs.append(s)
		var cs: CollisionShape2D = CollisionShape2D.new()
		var c: CircleShape2D = CircleShape2D.new()
		c.radius = 3.0 if i == SEGMENTS - 1 else 4.0
		cs.shape = c
		enemy.add_child(cs)
		shapes.append(cs)
	trail.clear()
	trail.append(enemy.global_position)
	_place_body()


func _check_key(key: String) -> void:
	if not PixelArt._cache.has(key) and not missing_sprites.has(key):
		missing_sprites[key] = true
		push_error("Stage enemy '%s' has no sprite '%s'" % [enemy.module_kind, key])


func on_wake() -> void:
	vel = launch
	flying = true
	for s: Sprite2D in segs:
		s.visible = true
	trail.clear()
	trail.append(enemy.global_position)
	sfx("explode", -13.0, 0.1)
	sparks(enemy.global_position, Color("#ffd060"), 10)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	vel.y += GRAVITY * delta
	p += vel * delta
	enemy.global_position = p
	trail.insert(0, p)
	if trail.size() > 90:
		trail.resize(90)
	_place_body()
	# Head follows its flight direction in 45-degree steps (the sprite faces left).
	var ang: float = vel.angle() - PI
	sprite().rotation = roundf(ang / (PI * 0.25)) * PI * 0.25
	# The bite: the jaw opens as it nears the top of the arc, then fires.
	var to_apex: float = -vel.y / GRAVITY
	var opening: bool = not bitten and to_apex < BITE_WARN
	set_texture("corona_serpent_bite" if opening or (bitten and to_apex > -0.25) else "corona_serpent_head")
	if not bitten and to_apex <= 0.0:
		bitten = true
		if on_screen(40.0, 465.0):
			for k: int in [-1, 0, 1]:
				shoot_aimed_from(p + Vector2(-8.0, 0.0), 150.0, bullet_a(), float(k) * 0.2)
			sfx("missile", -13.0, 0.05)
	# Fire drips falling from the body.
	drip_t -= delta
	if drip_t <= 0.0 and on_screen(30.0, 466.0) and p.y < 236.0:
		drip_t = fire_cd(DRIP_GAP)
		var b: GameBullet = emit_bullet(p + Vector2(4.0, 3.0), Vector2(vel.x * 0.25, 20.0), bullet_b(), false, 2.5)
		if b != null:
			b.gravity_pull = 110.0
	# Gone once the whole body has sunk back under the surface.
	if vel.y > 0.0 and _tail().y > SURFACE_Y + 10.0:
		leave()


func _tail() -> Vector2:
	return enemy.global_position + segs[SEGMENTS - 1].position


func _place_body() -> void:
	var head: Vector2 = enemy.global_position
	var placed: int = 0
	var acc: float = 0.0
	var prev: Vector2 = head
	for i: int in range(1, trail.size()):
		var q: Vector2 = trail[i]
		acc += prev.distance_to(q)
		prev = q
		while placed < SEGMENTS and acc >= SPACING * float(placed + 1):
			segs[placed].position = q - head
			shapes[placed].position = q - head
			placed += 1
		if placed >= SEGMENTS:
			break
	while placed < SEGMENTS:
		# Not enough path yet: stack the rest just behind (below the surface at the start).
		var rest: Vector2 = prev + Vector2(0.0, SPACING * float(placed + 1) - acc)
		segs[placed].position = rest - head
		shapes[placed].position = rest - head
		placed += 1


func draw() -> void:
	if flying and not bitten:
		var to_apex: float = -vel.y / GRAVITY
		draw_glint(Vector2(-9.0, 0.0).rotated(sprite().rotation), to_apex, BITE_WARN, Color(1.0, 0.75, 0.3))


# The surface boils where it will leap, and a dotted arc previews the leap.
func draw_warning() -> void:
	var k: float = clampf(1.0 - warn_timer / WARN, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(age * 30.0)
	enemy.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	enemy.draw_circle(Vector2.ZERO, lerpf(5.0, 14.0, k), Color(1.0, 0.95, 0.7, 0.3 + 0.3 * pulse))
	enemy.draw_circle(Vector2.ZERO, lerpf(2.0, 7.0, k), Color(1.0, 1.0, 0.95, 0.9))
	enemy.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Glow column rising off the spot.
	enemy.draw_rect(Rect2(-3.0, -40.0 * k, 6.0, 40.0 * k), Color(1.0, 0.6, 0.2, 0.12 + 0.1 * pulse))
	# Dotted preview of the arc (same physics as the leap), drawn more of it as the warning ends.
	var v: Vector2 = launch
	var t: float = 0.08
	var shown: float = 0.4 + 2.2 * k
	while t < shown:
		var q: Vector2 = v * t + Vector2(0.0, 0.5 * GRAVITY * t * t)
		if q.y > 0.0:
			break
		var a: float = 0.25 + 0.35 * k * (1.0 - t / shown)
		enemy.draw_rect(Rect2(floorf(q.x), floorf(q.y), 1.0, 1.0), Color(1.0, 0.8, 0.4, a))
		t += 0.07


func on_death() -> void:
	sparks(enemy.global_position, Color("#ffb040"), 10)
	for s: Sprite2D in segs:
		if is_instance_valid(s):
			sparks(enemy.global_position + s.position, Color("#ff7a20"), 2)
