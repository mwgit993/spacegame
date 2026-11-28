extends "res://scripts/bosses/boss_rig.gd"

# STAGE 8 boss: the NEON MEDUSA OVERMIND, a chrome cyber-gorgon with a dilophosaurus in its crown.
# Its snake-cable hair writhes; the cables fan out wide before the ring burst and the snake heads
# hiss open when it fires; a scan line sweeps the visor, racing and flaring before the laser wall.
# Muzzles: ring (visor).

const CHROME: Color = Color("#9aa8c8")
const CHROME_D: Color = Color("#4a5470")
const NEON_P: Color = Color("#ff4cd4")
const NEON_C: Color = Color("#3cf4ff")
const SEGS: int = 5
# Cable roots on the head and their resting angle (from straight up, clockwise).
const ROOTS: Array[Vector3] = [
	Vector3(10.0, -30.0, 0.5), Vector3(20.0, -22.0, 0.95), Vector3(24.0, -8.0, 1.4), Vector3(22.0, 6.0, 1.85),
	Vector3(-16.0, -28.0, -0.45), Vector3(-6.0, -34.0, -0.1), Vector3(-22.0, -18.0, -0.85), Vector3(2.0, -36.0, 0.2),
]

var _cables: Array = []      # Array of Array[Sprite2D]
var _heads: Array[Sprite2D] = []
var _scan: Sprite2D
var _visor_glow: Sprite2D


func build() -> void:
	for k: int in range(4):
		_cables.append(_build_cable(k, -2))
	part(self, Kit.cached("medusa_collar", _paint_collar), Vector2(6.0, 34.0), Vector2(36.0, 6.0), -1)
	var face: Sprite2D = part(self, Kit.cached("medusa_face", _paint_face), Vector2(0.0, 0.0), Vector2(31.0, 37.0), 0)
	_visor_glow = part(face, Kit.cached("medusa_visor", _paint_visor), Vector2(-26.0, -10.0), Vector2.ZERO, 1)
	_visor_glow.use_parent_material = false
	_scan = part(face, Kit.cached("medusa_scan", _paint_scan), Vector2(-26.0, -10.0), Vector2(1.0, 0.0), 2)
	_scan.use_parent_material = false
	marker(face, "ring", Vector2(-12.0, -6.0))
	for k2: int in range(4, 8):
		_cables.append(_build_cable(k2, 2))
	add_pilot(self, Vector2(2.0, -30.0), "dilo", Vector2i(36, 28), 3)


func _build_cable(k: int, z: int) -> Array[Sprite2D]:
	var segs: Array[Sprite2D] = []
	var parent: Node2D = self
	var root: Vector3 = ROOTS[k]
	var at: Vector2 = Vector2(root.x, root.y)
	for i: int in range(SEGS):
		var s: Sprite2D = part(parent, Kit.cached("medusa_cable", _paint_cable), at, Vector2(3.0, 10.0), z if i == 0 else 0)
		segs.append(s)
		parent = s
		at = Vector2(0.0, -8.0)
	var head: Sprite2D = part(parent, Kit.cached("medusa_snake", _paint_snake.bind(false)), at, Vector2(5.0, 9.0), 1)
	_heads.append(head)
	return segs


func animate(_delta: float) -> void:
	var nxt: int = next_pattern()
	var w_wall: float = windup if nxt == 0 else 0.0
	var w_ring: float = windup if nxt != 0 else 0.0
	position = Vector2(hurt_k * 1.5, 0.0)
	for k: int in range(_cables.size()):
		var segs: Array[Sprite2D] = _cables[k]
		var root: Vector3 = ROOTS[k]
		var side: float = signf(root.z) if root.z != 0.0 else 1.0
		for i: int in range(segs.size()):
			var wave: float = sin(t * (2.6 + 0.4 * float(phase())) - float(i) * 0.9 + float(k) * 0.8) * 0.22
			var r: float = wave
			if i == 0:
				r += root.z + side * (0.35 * w_ring + 0.3 * rage)
			segs[i].rotation = r
	var hiss: bool = kick > 0.5 or rage > 0.3
	for h: Sprite2D in _heads:
		h.texture = Kit.cached("medusa_snake_open" if hiss else "medusa_snake", _paint_snake.bind(hiss))
	# Visor scan line: sweeps steadily, races and flares before the laser wall.
	var speed: float = 1.2 + 4.0 * w_wall
	_scan.position = Vector2(-26.0 + fmod(t * speed * 20.0, 30.0), -10.0)
	_visor_glow.modulate = Color(1.0, 1.0, 1.0, 0.55 + 0.45 * maxf(w_wall, kick if pattern == 0 else 0.0))


# --- Painting -----------------------------------------------------------------------------------

static func _paint_face() -> Image:
	var img: Image = Kit.blank(62, 74)
	Kit.ball(img, 34.0, 34.0, 26.0, 32.0, CHROME)
	# Face plate jutting forward (left), jaw and grille.
	Kit.poly(img, PackedVector2Array([Vector2(4, 24), Vector2(20, 14), Vector2(34, 20), Vector2(30, 60), Vector2(14, 64), Vector2(6, 50)]), CHROME.lightened(0.1))
	Kit.rect(img, 6, 24, 30, 9, Color("#1a1030"))
	for gy: int in range(46, 58, 3):
		Kit.rect(img, 10, gy, 16, 1, CHROME_D)
	# Circuit lines across the skull.
	Kit.line(img, Vector2(38, 10), Vector2(52, 24), NEON_C)
	Kit.line(img, Vector2(52, 24), Vector2(52, 44), NEON_C)
	Kit.line(img, Vector2(40, 52), Vector2(54, 48), NEON_P)
	return Kit.finish(img)


static func _paint_visor() -> Image:
	var img: Image = Kit.blank(32, 11)
	Kit.rect(img, 0, 1, 31, 9, Color(1.0, 0.3, 0.7, 0.35))
	Kit.rect(img, 0, 4, 31, 3, NEON_P)
	Kit.rect(img, 0, 5, 31, 1, Color("#ffd8f4"))
	return img


static func _paint_scan() -> Image:
	var img: Image = Kit.blank(3, 11)
	Kit.rect(img, 0, 0, 3, 11, Color(1.0, 1.0, 1.0, 0.6))
	Kit.rect(img, 1, 0, 1, 11, Color.WHITE)
	return img


static func _paint_collar() -> Image:
	var img: Image = Kit.blank(72, 30)
	Kit.poly(img, PackedVector2Array([Vector2(10, 0), Vector2(62, 0), Vector2(71, 28), Vector2(0, 28)]), CHROME_D)
	for x: int in range(8, 66, 8):
		Kit.line(img, Vector2(float(x) + 2.0, 2), Vector2(float(x), 26), NEON_C.darkened(0.2))
	Kit.rect(img, 10, 0, 52, 2, NEON_P)
	return Kit.finish(img)


static func _paint_cable() -> Image:
	var img: Image = Kit.blank(6, 11)
	Kit.rect(img, 1, 0, 4, 11, CHROME_D.lightened(0.2))
	Kit.rect(img, 1, 5, 4, 2, NEON_C)
	return Kit.outline(img)


static func _paint_snake(open: bool) -> Image:
	var img: Image = Kit.blank(12, 10)
	Kit.ball(img, 6.0, 6.0, 5.0, 4.0, CHROME)
	if open:
		Kit.poly(img, PackedVector2Array([Vector2(1, 2), Vector2(6, 5), Vector2(1, 8)]), Color("#5a1020"))
		Kit.put(img, 2, 3, Color.WHITE)
		Kit.put(img, 2, 7, Color.WHITE)
	Kit.put(img, 5, 4, NEON_P)
	Kit.put(img, 7, 4, NEON_P)
	return Kit.outline(img)
