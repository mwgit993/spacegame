extends Node2D

# An angry space dinosaur at a boss's controls (Matt: "all bosses should be piloted by angry space
# dinosaurs"). The rig puts one in a glass canopy on its boss: the canopy's back panel, the dino,
# then the glass. Its face follows the fight: angry (blinking now and then), a roar on every attack
# and phase change, a wince when hit, panic once the boss is down to phase 3, and when the boss
# blows up it bails out in an escape pod (eject()), shaking its fist.
#
# The dinos face left (towards the player). Each species is painted from the same face layout
# (snout left, eye, brow, jaw, a scarf, a tiny arm on the stick) plus its own features.

const Kit = preload("res://scripts/bosses/boss_kit.gd")
const PilotPod = preload("res://scripts/bosses/pilot_pod.gd")

const W: int = 30
const H: int = 24
const EXPRESSIONS: Array[String] = ["angry", "blink", "roar", "hurt", "panic"]

## Every boss is flown by the same pilot (Matthew's call): the angry T-rex.
const BOSS_PILOT: String = "rex"

# skin, belly, stripe/accent, scarf
const SPECIES: Dictionary = {
	"rex": {"skin": Color("#5cb84a"), "belly": Color("#e6d27a"), "accent": Color("#2f7a2c"), "scarf": Color("#e8344a")},
	"raptor": {"skin": Color("#e08a2e"), "belly": Color("#f6e0a8"), "accent": Color("#8e4510"), "scarf": Color("#3c8cff")},
	"ptero": {"skin": Color("#9378dc"), "belly": Color("#ddd0f8"), "accent": Color("#e8344a"), "scarf": Color("#ffe854")},
	"trike": {"skin": Color("#4a8fd8"), "belly": Color("#d4e8ff"), "accent": Color("#ff9624"), "scarf": Color("#e8344a")},
	"stego": {"skin": Color("#7fb8d8"), "belly": Color("#eef8ff"), "accent": Color("#ff8a4c"), "scarf": Color("#e8344a")},
	"spino": {"skin": Color("#d8453a"), "belly": Color("#f4c890"), "accent": Color("#ff9624"), "scarf": Color("#2c2c3c")},
	"plesio": {"skin": Color("#3cb8b0"), "belly": Color("#c8f4e8"), "accent": Color("#ffe854"), "scarf": Color("#ff6a9a")},
	"dilo": {"skin": Color("#2fa86a"), "belly": Color("#d8f8c8"), "accent": Color("#ff4cd4"), "scarf": Color("#3cf4ff")},
}

var species: String = "rex"
var low_hp: bool = false        # the boss is in phase 3: panic instead of anger
var _face: Sprite2D
var _expr: String = "angry"
var _hold: float = 0.0          # how long a roar / wince still shows
var _hold_expr: String = ""
var _blink_t: float = 2.0
var _t: float = 0.0
var _shake: float = 0.0
var _canopy_size: Vector2i = Vector2i(36, 28)


# canopy: the glass dome's size in px; the dino sits centred in it.
func setup(species_id: String, canopy: Vector2i = Vector2i(36, 28)) -> void:
	species = species_id if SPECIES.has(species_id) else "rex"
	_canopy_size = canopy
	var back: Sprite2D = Sprite2D.new()
	back.texture = Kit.cached("canopy_back_%dx%d" % [canopy.x, canopy.y], _paint_canopy_back.bind(canopy))
	back.use_parent_material = true
	add_child(back)
	_face = Sprite2D.new()
	_face.texture = face_texture(species, "angry")
	_face.position = Vector2(1.0, 1.0)
	_face.use_parent_material = true
	add_child(_face)
	var glass: Sprite2D = Sprite2D.new()
	glass.texture = Kit.cached("canopy_glass_%dx%d" % [canopy.x, canopy.y], _paint_canopy_glass.bind(canopy))
	add_child(glass)


func roar(time: float = 0.34) -> void:
	_set_hold("roar", time)
	_shake = maxf(_shake, time)


func hurt() -> void:
	if _hold_expr != "roar":
		_set_hold("hurt", 0.13)


func _set_hold(e: String, time: float) -> void:
	_hold_expr = e
	_hold = time


func _process(delta: float) -> void:
	_t += delta
	_hold = maxf(0.0, _hold - delta)
	_shake = maxf(0.0, _shake - delta)
	_blink_t -= delta
	var e: String = "panic" if low_hp else "angry"
	if _hold > 0.0:
		e = _hold_expr
	elif not low_hp and _blink_t < 0.11:
		e = "blink"
		if _blink_t < 0.0:
			_blink_t = randf_range(1.8, 3.6)
	if e != _expr:
		_expr = e
		_face.texture = face_texture(species, e)
	# A little head bob; a rattle while roaring; a nervous jitter when panicking.
	var bob: float = sin(_t * 3.1) * 0.6
	var jx: float = 0.0
	if _shake > 0.0:
		jx = 1.0 if int(_t * 30.0) % 2 == 0 else -1.0
	elif low_hp:
		jx = 0.5 if int(_t * 18.0) % 2 == 0 else -0.5
	_face.position = Vector2(1.0 + jx, 1.0 + bob)


# Bails out: an escape pod (under `layer`, so it outlives the boss) launches from here.
func eject(layer: Node, fx: Node) -> void:
	if layer == null:
		return
	var pod: Node2D = PilotPod.new()
	layer.add_child(pod)
	pod.global_position = global_position
	pod.call("setup", face_texture(species, "angry"), fx)
	visible = false


static func face_texture(sp: String, expr: String) -> Texture2D:
	return Kit.cached("dino_%s_%s" % [sp, expr], paint_face.bind(sp, expr))


# --- Painting ---------------------------------------------------------------------------------

static func paint_face(sp: String, expr: String) -> Image:
	var d: Dictionary = SPECIES[sp]
	var skin: Color = d["skin"]
	var belly: Color = d["belly"]
	var accent: Color = d["accent"]
	var scarf: Color = d["scarf"]
	var jaw_col: Color = skin.darkened(0.18)
	var img: Image = Kit.blank(W, H)
	var roaring: bool = expr == "roar"

	# Behind the head: the triceratops frill, the pterodactyl crest.
	if sp == "trike":
		Kit.ellipse(img, 22.0, 9.5, 7.5, 9.0, skin.darkened(0.3))
		for k: int in range(7):
			var a: float = -1.9 + float(k) * 0.55
			Kit.ellipse(img, 22.0 + cos(a) * 7.0, 9.5 + sin(a) * 8.4, 1.3, 1.3, accent)
	elif sp == "ptero":
		Kit.poly(img, PackedVector2Array([Vector2(15, 4), Vector2(29, 0), Vector2(22, 7)]), accent)
	elif sp == "spino":
		Kit.poly(img, PackedVector2Array([Vector2(14, 7), Vector2(17, 0), Vector2(29, 0), Vector2(29, 13), Vector2(22, 12)]), accent)
		for sx: int in [19, 23, 27]:
			Kit.line(img, Vector2(float(sx), 1), Vector2(float(sx) - 2.0, 11), accent.darkened(0.35))
	elif sp == "stego":
		for pl: Vector3 in [Vector3(21, 3, 4), Vector3(25, 8, 4), Vector3(27, 13, 3)]:
			Kit.poly(img, PackedVector2Array([Vector2(pl.x - pl.z, pl.y + 3.0), Vector2(pl.x, pl.y - pl.z), Vector2(pl.x + pl.z, pl.y + 3.0), Vector2(pl.x, pl.y + 6.0)]), accent)
	elif sp == "dilo":
		Kit.ellipse(img, 21.0, 11.0, 7.0, 8.5, accent)
		for k2: int in range(6):
			var a2: float = -1.7 + float(k2) * 0.62
			Kit.ellipse(img, 21.0 + cos(a2) * 6.0, 11.0 + sin(a2) * 7.4, 1.1, 1.1, Color("#3cf4ff"))

	# Shoulders, scarf, neck, skull.
	Kit.ball(img, 21.0, 21.5, 7.5, 5.5, skin)
	Kit.ellipse(img, 17.5, 22.0, 3.0, 3.0, belly)
	Kit.ellipse(img, 20.0, 14.0, 4.5, 5.0, skin)
	Kit.ball(img, 18.0, 9.0, 7.0, 6.0, skin)

	# Snout (upper jaw), per species.
	var snout: PackedVector2Array
	match sp:
		"raptor":
			snout = PackedVector2Array([Vector2(2, 9), Vector2(12, 6), Vector2(17, 7.5), Vector2(17, 11.5), Vector2(3, 11.5)])
		"ptero":
			snout = PackedVector2Array([Vector2(0, 10.5), Vector2(13, 6.5), Vector2(17, 8), Vector2(17, 11.5), Vector2(3, 11.5)])
		"trike":
			snout = PackedVector2Array([Vector2(3, 11), Vector2(8, 6.5), Vector2(16, 6), Vector2(16, 12), Vector2(5, 12)])
		"spino":
			snout = PackedVector2Array([Vector2(0, 10), Vector2(10, 7.5), Vector2(17, 7.5), Vector2(17, 11.5), Vector2(1, 11.5)])
		"stego", "plesio":
			snout = PackedVector2Array([Vector2(7, 10), Vector2(11, 6.5), Vector2(17, 7), Vector2(17, 12), Vector2(7, 12)])
		"dilo":
			snout = PackedVector2Array([Vector2(3, 9), Vector2(12, 6), Vector2(17, 7.5), Vector2(17, 11.5), Vector2(4, 11.5)])
		_:
			snout = PackedVector2Array([Vector2(5, 8), Vector2(12, 5), Vector2(17, 7), Vector2(17, 12), Vector2(5, 12)])
	var beak: bool = sp == "ptero" or sp == "trike" or sp == "stego"
	Kit.poly(img, snout, skin)
	if sp == "ptero":
		Kit.poly(img, PackedVector2Array([Vector2(0, 10.5), Vector2(9, 7.5), Vector2(10, 11.5), Vector2(3, 11.5)]), Color("#f0b44a"))
	elif sp == "trike":
		Kit.poly(img, PackedVector2Array([Vector2(3, 11), Vector2(6, 8), Vector2(8, 12), Vector2(5, 12)]), Color("#e8dcb4"))

	# Lower jaw and mouth.
	var front: float = snout[0].x + 1.0
	if roaring:
		Kit.poly(img, PackedVector2Array([Vector2(front + 1.0, 12), Vector2(16, 12), Vector2(16, 13.5), Vector2(front + 3.0, 17)]), Color("#5a1020"))
		Kit.ellipse(img, front + 5.0, 14.6, 3.0, 1.2, Color("#e05a7a"))
		Kit.poly(img, PackedVector2Array([Vector2(front + 3.0, 17), Vector2(16, 13.5), Vector2(16, 15.5), Vector2(front + 4.0, 18.5)]), jaw_col)
		if not beak:
			for x: int in range(int(front) + 2, 15, 2):
				Kit.put(img, x, 12, Color.WHITE)
			Kit.put(img, int(front) + 4, 16, Color.WHITE)
			Kit.put(img, int(front) + 7, 15, Color.WHITE)
	else:
		var jaw_drop: float = 1.0 if expr == "panic" else 0.0
		Kit.poly(img, PackedVector2Array([Vector2(front + 1.0, 12 + jaw_drop), Vector2(16, 12), Vector2(16, 14.5), Vector2(front + 3.0, 14.5 + jaw_drop)]), jaw_col)
		if expr == "panic":
			Kit.rect(img, int(front) + 2, 12, 5, 1, Color("#5a1020"))
		elif expr == "hurt" and not beak:
			Kit.rect(img, int(front) + 1, 12, 15 - int(front), 1, Color.WHITE)
			for x: int in range(int(front) + 3, 15, 3):
				Kit.put(img, x, 12, Kit.INK)
		elif not beak:
			# A snarl: a row of teeth and two long fangs over the lower lip.
			for x: int in range(int(front) + 1, 16, 2):
				Kit.put(img, x, 12, Color.WHITE)
			Kit.put(img, int(front) + 2, 13, Color.WHITE)
			Kit.put(img, int(front) + 7, 13, Color.WHITE)
	# Nostril.
	Kit.put(img, int(snout[0].x) + 2, int(snout[0].y) - (1 if sp == "rex" else 0), Kit.INK)

	# Species features in front: stripes, crest feathers, horns.
	match sp:
		"rex":
			Kit.line(img, Vector2(21, 5), Vector2(22, 8), accent)
			Kit.line(img, Vector2(23.5, 7), Vector2(24, 10), accent)
			Kit.put(img, 17, 3, skin.lightened(0.35))
			Kit.put(img, 18, 3, skin.lightened(0.35))
		"raptor":
			Kit.line(img, Vector2(21, 6), Vector2(23, 10), accent)
			Kit.line(img, Vector2(18, 15), Vector2(21, 17), accent)
			for f: Vector3 in [Vector3(16, 3, 0), Vector3(19, 2.5, 1), Vector3(22, 3.5, 2)]:
				Kit.poly(img, PackedVector2Array([Vector2(f.x - 1.5, f.y + 1.5), Vector2(f.x + 2.5 + f.z, f.y - 3.0), Vector2(f.x + 1.5, f.y + 2.0)]), Color("#e8344a"))
		"dilo":
			Kit.line(img, Vector2(12, 5), Vector2(19, 0), Color("#ff4c68"), 1.0)
			Kit.line(img, Vector2(14, 6), Vector2(21, 1), Color("#ff4c68"), 1.0)
		"plesio":
			for sp2: Vector2i in [Vector2i(20, 6), Vector2i(23, 9), Vector2i(19, 15), Vector2i(22, 18)]:
				Kit.put(img, sp2.x, sp2.y, accent)
		"spino":
			Kit.line(img, Vector2(20, 8), Vector2(22, 12), skin.darkened(0.3))
		"trike":
			var horn: Color = Color("#f4ead0")
			Kit.line(img, Vector2(15, 5), Vector2(10, 0), horn, 2.0)
			Kit.line(img, Vector2(17, 4), Vector2(13, -1), horn.darkened(0.15), 1.0)
			Kit.line(img, Vector2(6.5, 7.5), Vector2(5, 4), horn, 1.0)

	# Scarf round the neck, its end flapping back.
	Kit.ellipse(img, 20.0, 16.5, 5.5, 1.6, scarf)
	Kit.poly(img, PackedVector2Array([Vector2(24, 16), Vector2(29, 15), Vector2(28, 18), Vector2(24, 18)]), scarf.darkened(0.2))

	# Tiny arm gripping the stick.
	Kit.line(img, Vector2(17, 18), Vector2(12, 19), skin.darkened(0.1), 2.0)
	Kit.ellipse(img, 11.5, 19.0, 1.6, 1.6, skin.lightened(0.1))

	# Eye and brow.
	var eye_w: Color = Color("#fff4c0")
	var pupil: Color = Color("#c81828")
	if roaring:
		Kit.rect(img, 13, 7, 3, 2, eye_w)
		Kit.put(img, 13, 8, pupil)
		for bp2: Vector2i in [Vector2i(12, 7), Vector2i(13, 6), Vector2i(14, 6), Vector2i(15, 5), Vector2i(16, 5), Vector2i(17, 4), Vector2i(14, 5), Vector2i(16, 4)]:
			Kit.put(img, bp2.x, bp2.y, Kit.INK)
	match expr:
		"roar":
			pass
		"blink":
			Kit.rect(img, 13, 8, 3, 1, Kit.INK)
			Kit.line(img, Vector2(12, 6), Vector2(17, 4), Kit.INK, 1.0)
		"hurt":
			Kit.put(img, 15, 6, Kit.INK)
			Kit.put(img, 14, 7, Kit.INK)
			Kit.put(img, 13, 7, Kit.INK)
			Kit.put(img, 15, 8, Kit.INK)
			Kit.line(img, Vector2(12, 6), Vector2(17, 5), Kit.INK, 1.0)
		"panic":
			Kit.rect(img, 13, 6, 3, 3, eye_w)
			Kit.put(img, 14, 7, Kit.INK)
			Kit.line(img, Vector2(12, 4), Vector2(17, 5), Kit.INK, 1.0)
			# Sweat drop.
			Kit.put(img, 21, 2, Color("#9ae4ff"))
			Kit.rect(img, 20, 3, 3, 2, Color("#9ae4ff"))
			Kit.put(img, 21, 3, Color.WHITE)
		_:
			Kit.rect(img, 13, 7, 3, 2, eye_w)
			Kit.put(img, 13, 8, pupil)
			Kit.put(img, 14, 8, pupil)
			# Angry brow: a heavy ridge slanting down towards the snout, cutting into the eye.
			for bp: Vector2i in [Vector2i(12, 7), Vector2i(13, 7), Vector2i(13, 6), Vector2i(14, 6), Vector2i(15, 6), Vector2i(15, 5), Vector2i(16, 5), Vector2i(17, 5), Vector2i(16, 4), Vector2i(17, 4), Vector2i(14, 5)]:
				Kit.put(img, bp.x, bp.y, Kit.INK)
	# The cartoon anger vein, when it's angry or roaring.
	if expr == "angry" or expr == "roar" or expr == "blink":
		var vein: Color = Color("#ff3048")
		for vp: Vector2i in [Vector2i(24, 2), Vector2i(26, 2), Vector2i(23, 3), Vector2i(27, 3), Vector2i(23, 5), Vector2i(27, 5), Vector2i(24, 6), Vector2i(26, 6)]:
			Kit.put(img, vp.x, vp.y, vein)
	if sp == "plesio" and not roaring:
		Kit.line(img, Vector2(9, 12), Vector2(9, 3), Color("#ffe854"), 1.0)
		Kit.rect(img, 8, 2, 3, 1, Color("#ff9624"))
		Kit.rect(img, 7, 12, 4, 1, Color("#ff9624"))
	Kit.shade(img, 0.2, 0.25, 0.9)
	return Kit.outline(img)


static func _paint_canopy_back(sz: Vector2i) -> Image:
	var img: Image = Kit.blank(sz.x, sz.y)
	var cx: float = float(sz.x) * 0.5
	Kit.ellipse(img, cx, float(sz.y) * 0.62, cx - 1.0, float(sz.y) * 0.6, Color("#141a2e"))
	Kit.rect(img, 2, sz.y - 7, sz.x - 4, 6, Color("#1f2a48"))
	# Console lights and the control stick.
	for i: int in range(4):
		Kit.put(img, 5 + i * 3, sz.y - 5, [Color("#ff4c68"), Color("#3ce878"), Color("#ffe854"), Color("#28e8ff")][i])
	Kit.line(img, Vector2(cx - 5.0, float(sz.y) - 6.0), Vector2(cx - 5.0, float(sz.y) - 11.0), Color("#5a6a8c"))
	return img


static func _paint_canopy_glass(sz: Vector2i) -> Image:
	var img: Image = Kit.blank(sz.x, sz.y)
	var cx: float = float(sz.x) * 0.5
	var cy: float = float(sz.y) * 0.62
	var rx: float = cx - 1.0
	var ry: float = float(sz.y) * 0.6
	Kit.ellipse(img, cx, cy, rx, ry, Color(0.55, 0.9, 1.0, 0.16))
	# Glass edge and a bright reflection arc up top-left.
	for k: int in range(160):
		var a: float = TAU * float(k) / 160.0
		Kit.put(img, int(roundf(cx + cos(a) * rx - 0.5)), int(roundf(cy + sin(a) * ry - 0.5)), Color(0.75, 0.95, 1.0, 0.55))
	for k: int in range(9):
		var a2: float = PI + 0.35 + float(k) * 0.13
		Kit.put(img, int(cx + cos(a2) * (rx - 3.0)), int(cy + sin(a2) * (ry - 3.0)), Color(1, 1, 1, 0.85))
	Kit.put(img, int(cx - rx * 0.35), int(cy - ry * 0.45), Color(1, 1, 1, 0.9))
	# Metal rim along the bottom.
	Kit.plate(img, 1, sz.y - 4, sz.x - 2, 4, Color("#8ca6d8"), true)
	return img
