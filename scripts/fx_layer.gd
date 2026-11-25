class_name FxLayer
extends Node2D

var _particles: Array[Dictionary] = []
var _popups: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var shake_strength: float = 0.0


func add_shake(amount: float) -> void:
	if not MetaSave.screen_shake_enabled:
		return
	shake_strength = maxf(shake_strength, amount)


func spawn_hit_sparks(pos: Vector2, col: Color = Color("#ffe854"), count: int = 5) -> void:
	for i: int in range(count):
		var ang: float = randf_range(0.0, TAU)
		var spd: float = randf_range(35.0, 115.0)
		_particles.append({
			"pos": pos,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"life": randf_range(0.10, 0.22),
			"max_life": 0.22,
			"size": 2.0 if i % 2 == 0 else 1.0,
			"col_a": Color.WHITE,
			"col_b": col,
		})


func spawn_explosion(pos: Vector2, big: bool = false) -> void:
	var count: int = 28 if big else 12
	var max_spd: float = 165.0 if big else 95.0
	for i: int in range(count):
		var ang: float = randf_range(0.0, TAU)
		var spd: float = randf_range(18.0, max_spd)
		var max_l: float = randf_range(0.22, 0.55 if big else 0.36)
		_particles.append({
			"pos": pos + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"life": max_l,
			"max_life": max_l,
			"size": 3.0 if (big and i % 3 == 0) else 2.0,
			"col_a": Color("#ffffaa"),
			"col_b": Color("#ff5522") if i % 2 == 0 else Color("#ff9922"),
		})
	_rings.append({
		"pos": pos,
		"radius": 3.0,
		"max_radius": 34.0 if big else 16.0,
		"life": 0.26 if big else 0.16,
		"max_life": 0.26 if big else 0.16,
		"color": Color("#ffe866"),
	})


func spawn_popup(pos: Vector2, text: String, col: Color = Color("#ffe854")) -> void:
	_popups.append({
		"pos": pos,
		"text": text,
		"col": col,
		"life": 0.85,
		"max_life": 0.85,
	})


func clear_all() -> void:
	_particles.clear()
	_popups.clear()
	_rings.clear()
	shake_strength = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if shake_strength > 0.0:
		shake_strength = maxf(0.0, shake_strength - delta * 22.0)

	var i: int = _particles.size() - 1
	while i >= 0:
		var p: Dictionary = _particles[i]
		var life: float = float(p["life"]) - delta
		if life <= 0.0:
			_particles.remove_at(i)
		else:
			p["life"] = life
			var vel: Vector2 = p["vel"]
			p["pos"] = Vector2(p["pos"]) + vel * delta
			p["vel"] = vel * (1.0 - 3.0 * delta)
		i -= 1

	i = _rings.size() - 1
	while i >= 0:
		var r: Dictionary = _rings[i]
		var life: float = float(r["life"]) - delta
		if life <= 0.0:
			_rings.remove_at(i)
		else:
			r["life"] = life
			var t: float = 1.0 - life / float(r["max_life"])
			r["radius"] = lerpf(3.0, float(r["max_radius"]), t)
		i -= 1

	i = _popups.size() - 1
	while i >= 0:
		var pop: Dictionary = _popups[i]
		var life: float = float(pop["life"]) - delta
		if life <= 0.0:
			_popups.remove_at(i)
		else:
			pop["life"] = life
			pop["pos"] = Vector2(pop["pos"]) + Vector2(0.0, -18.0 * delta)
		i -= 1

	queue_redraw()


func _draw() -> void:
	for r: Dictionary in _rings:
		var alpha: float = clampf(float(r["life"]) / float(r["max_life"]), 0.0, 1.0)
		var col: Color = r["color"]
		draw_arc(Vector2(r["pos"]), float(r["radius"]), 0.0, TAU, 20, Color(col.r, col.g, col.b, alpha), 1.0)

	for p: Dictionary in _particles:
		var ratio: float = clampf(float(p["life"]) / float(p["max_life"]), 0.0, 1.0)
		var ca: Color = p["col_a"]
		var cb: Color = p["col_b"]
		var c: Color = cb.lerp(ca, ratio)
		c.a = clampf(ratio * 1.35, 0.0, 1.0)
		var pos: Vector2 = Vector2(p["pos"]).floor()
		var sz: float = float(p["size"])
		draw_rect(Rect2(pos.x, pos.y, sz, sz), c)

	var font: Font = PixelArt.ui_font if PixelArt.ui_font != null else ThemeDB.fallback_font
	for pop: Dictionary in _popups:
		var alpha: float = clampf(float(pop["life"]) / float(pop["max_life"]) * 1.4, 0.0, 1.0)
		var col: Color = pop["col"]
		var pos: Vector2 = Vector2(pop["pos"]).floor()
		var txt: String = String(pop["text"])
		draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(col.r, col.g, col.b, alpha))
