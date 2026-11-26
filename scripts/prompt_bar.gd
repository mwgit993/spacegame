class_name PromptBar
extends Control

# One line of FF6 text mixed with button-prompt glyphs. Each segment is either a String
# (drawn as text) or {"act": "<action>"} (drawn as that action's glyphs from InputPrompts for
# the device the player last used). Redraws itself when the device changes, so it never shows
# keyboard and gamepad prompts at the same time.

const FONT_SZ: int = 10
const GLYPH_GAP: float = 2.0

var segments: Array = []
var text_color: Color = Color.WHITE
var align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	InputPrompts.device_changed.connect(_on_device_changed)


func set_segments(new_segments: Array) -> void:
	segments = new_segments
	queue_redraw()


func _on_device_changed(_is_gamepad: bool) -> void:
	queue_redraw()


func _draw() -> void:
	var font: Font = PixelArt.ui_font if PixelArt.ui_font != null else ThemeDB.fallback_font
	# Lay out first so the whole line can be centred or right-aligned.
	var items: Array = []
	var total_w: float = 0.0
	var prev_was_glyph: bool = false
	for seg: Variant in segments:
		if seg is Dictionary:
			var tex: Texture2D = InputPrompts.strip_for(String((seg as Dictionary).get("act", "")))
			if tex == null:
				continue
			if not items.is_empty():
				total_w += GLYPH_GAP
			items.append(tex)
			total_w += float(tex.get_width())
			prev_was_glyph = true
		else:
			var txt: String = str(seg)
			if txt == "":
				continue
			if prev_was_glyph:
				total_w += GLYPH_GAP
			items.append(txt)
			total_w += font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ).x
			prev_was_glyph = false

	var x: float = 0.0
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x = floorf((size.x - total_w) * 0.5)
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x = floorf(size.x - total_w)
	var glyph_y: float = floorf((size.y - float(InputPrompts.GLYPH_H)) * 0.5)
	var baseline: float = glyph_y + 9.0

	prev_was_glyph = false
	for i: int in range(items.size()):
		var item: Variant = items[i]
		if item is Texture2D:
			var tex: Texture2D = item as Texture2D
			if i > 0:
				x += GLYPH_GAP
			draw_texture(tex, Vector2(x, glyph_y))
			x += float(tex.get_width())
			prev_was_glyph = true
		else:
			var txt: String = String(item)
			if prev_was_glyph:
				x += GLYPH_GAP
			draw_string(font, Vector2(x, baseline), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ, text_color)
			x += font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SZ).x
			prev_was_glyph = false
