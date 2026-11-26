extends RefCounted

# Base class of a stage-module background animator. The module's create_background() returns
# a new one each time the stage's background becomes active; StarfieldBg calls reset() once,
# then update() and draw() every frame. A background script starts with:
#
#     extends "res://scripts/stages/stage_background.gd"
#
# The still layers are painted once, on a worker thread, by the module's paint_background()
# (usually a static paint() in the same script, using scripts/stage_bg_painter.gd). They arrive
# here as textures: tex("far"), layer("far", y, factor)... Metadata values from the painter are
# in `meta`.
#
# StarfieldBg advances the scroll and the ambient clock, moves drift_a/drift_b (configure them
# in reset(), draw them with drift_draw()), ages the shared effect particles (fx_spawn() /
# fx_draw()), draws the floor and ceiling decks over your layers, and the hyperspace tunnel on
# top. Readability rule: keep the playfield (y 30-249) dark and low in contrast; put bright or
# busy detail at the edges, in far layers, or in short bursts.

var bg: StarfieldBg

var scroll: float:   # accumulated scroll in px at parallax factor 1.0
	get:
		return bg._scroll
var life: float:     # ambient animation clock (slows down on pause instead of stopping)
	get:
		return bg._life
var ds: float:       # this frame's scroll step
	get:
		return bg._ds
var dl: float:       # this frame's ambient step
	get:
		return bg._dl
var rng: RandomNumberGenerator:
	get:
		return bg._rng
var meta: Dictionary:
	get:
		return bg._meta
var drift_a: StarfieldBg.Drift:
	get:
		return bg._drift_a
var drift_b: StarfieldBg.Drift:
	get:
		return bg._drift_b


# The background just became active: set up particles and any state of your own.
func reset() -> void:
	pass


# Every frame, after the scroll and particles moved.
func update() -> void:
	pass


# Every frame, inside StarfieldBg._draw(): draw the sky first, then far to near.
func draw() -> void:
	pass


# --- Helpers (thin wrappers over StarfieldBg) ---------------------------------------------------

# Layer names tex()/layer() couldn't find, as "<stage id>/<name>" (the smoke test fails if this
# isn't empty). StarfieldBg itself would just skip a missing layer.
static var missing_layers: Dictionary = {}
static var _blank: ImageTexture = null


# A painted layer's texture. A missing name is reported once and gives a blank 1x1 texture.
func tex(key: String) -> Texture2D:
	if _has_layer(key):
		return bg._t(key)
	if _blank == null:
		_blank = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	return _blank


# A tileable layer scrolled at `factor` of the base speed.
func layer(key: String, y: float, factor: float, mod: Color = Color.WHITE, extra: float = 0.0) -> void:
	if _has_layer(key):
		bg._layer(key, y, factor, mod, extra)


# A line-scrolled layer whose speed goes from f_top (top row) to f_bot (bottom row).
func layer_rows(key: String, y: float, band_h: int, f_top: float, f_bot: float, mod: Color = Color.WHITE) -> void:
	if _has_layer(key):
		bg._layer_rows(key, y, band_h, f_top, f_bot, mod)


# A layer with a per-band sine wobble (heat shimmer, water).
func layer_wobble(key: String, y: float, factor: float, band_h: int, amp: float, freq: float, speed: float, from_row: int = 0) -> void:
	if _has_layer(key):
		bg._layer_wobble(key, y, factor, band_h, amp, freq, speed, from_row)


func _has_layer(key: String) -> bool:
	if bg._t(key) != null:
		return true
	var tag: String = "%s/%s" % [bg._theme, key]
	if not missing_layers.has(tag):
		missing_layers[tag] = true
		push_error("Stage background has no layer '%s'" % tag)
	return false


# Integer scroll offset of a layer of width w.
func off(factor: float, w: float) -> float:
	return bg._off(factor, w)


# Screen x of a texture-space x on a layer scrolled by `o` (may be off screen).
func wrap_x(tex_x: float, o: float, w: float) -> float:
	return bg._wrap_x(tex_x, o, w)


func drift_draw(p: StarfieldBg.Drift, streak: float = 1.0) -> void:
	bg._drift_draw(p, streak)


# Kinds are StarfieldBg.Fx (STEAM, SPARK, BOMB, SMOKE, BUBBLE_POP, DROPLET).
func fx_spawn(kind: int, x: float, y: float, vx: float, vy: float, seconds: float, par: float) -> void:
	bg._fx_spawn(kind, x, y, vx, vy, seconds, par)


func fx_draw() -> void:
	bg._fx_draw()
