extends RefCounted

# A tiny 3x5 pixel font for the arena's scoreboard and the bots' "ROUND" call, drawn with
# rects on any CanvasItem (the bitmap UI font is for the HUD). Each glyph is 5 rows of 3 bits,
# top row first, high bit on the left. Unknown characters draw as a space.

const GLYPHS: Dictionary = {
	"0": [7, 5, 5, 5, 7], "1": [2, 6, 2, 2, 7], "2": [7, 1, 7, 4, 7], "3": [7, 1, 3, 1, 7],
	"4": [5, 5, 7, 1, 1], "5": [7, 4, 7, 1, 7], "6": [7, 4, 7, 5, 7], "7": [7, 1, 2, 2, 2],
	"8": [7, 5, 7, 5, 7], "9": [7, 5, 7, 1, 7], ":": [0, 2, 0, 2, 0], "!": [2, 2, 2, 0, 2],
	"-": [0, 0, 7, 0, 0], "A": [2, 5, 7, 5, 5], "C": [7, 4, 4, 4, 7], "D": [6, 5, 5, 5, 6],
	"E": [7, 4, 6, 4, 7], "F": [7, 4, 6, 4, 4], "G": [7, 4, 5, 5, 7], "H": [5, 5, 7, 5, 5],
	"I": [7, 2, 2, 2, 7], "K": [5, 5, 6, 5, 5], "L": [4, 4, 4, 4, 7], "M": [5, 7, 7, 5, 5],
	"N": [6, 5, 5, 5, 5], "O": [7, 5, 5, 5, 7], "P": [7, 5, 7, 4, 4], "R": [6, 5, 6, 5, 5],
	"S": [7, 4, 7, 1, 7], "T": [7, 2, 2, 2, 2], "U": [5, 5, 5, 5, 7], "V": [5, 5, 5, 5, 2],
	"W": [5, 5, 7, 7, 5], "Y": [5, 5, 2, 2, 2],
}


# Width in pixels of `text` at scale s (4 px per glyph including the gap, minus the last gap).
static func width(text: String, s: float) -> float:
	return maxf(0.0, float(text.length()) * 4.0 * s - s)


# Draws `text` with its top-left corner at pos. Runs of lit pixels in a row are merged into one
# rect, so a glyph costs at most 5-10 draw calls.
static func draw_text(ci: CanvasItem, text: String, pos: Vector2, s: float, col: Color) -> void:
	var x: float = pos.x
	for i: int in range(text.length()):
		var ch: String = text.substr(i, 1)
		if GLYPHS.has(ch):
			var rows: Array = GLYPHS[ch]
			for r: int in range(5):
				var bits: int = int(rows[r])
				var c: int = 0
				while c < 3:
					if bits & (4 >> c):
						var run: int = 1
						while c + run < 3 and (bits & (4 >> (c + run))):
							run += 1
						ci.draw_rect(Rect2(x + float(c) * s, pos.y + float(r) * s, float(run) * s, s), col)
						c += run
					else:
						c += 1
		x += 4.0 * s


static func draw_centered(ci: CanvasItem, text: String, center: Vector2, s: float, col: Color) -> void:
	draw_text(ci, text, Vector2(floorf(center.x - width(text, s) * 0.5), floorf(center.y - 2.5 * s)), s, col)
