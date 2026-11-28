extends Node

# Device-aware button prompts.
#
# Tracks whether the player last touched a gamepad or the keyboard/mouse and hands out
# 16-bit prompt glyphs for that device only: Xbox buttons for gamepads, key caps for the
# keyboard. Glyphs are built in code (11 px tall, so they sit inline with the FF6 font at
# size 10) and cached.
#
# Showing a prompt:
# - On a Button: `InputPrompts.bind_button(btn, "back")`. The glyph is drawn right after the
#   label and swaps by itself when the device changes. Pass "" to remove it.
# - In a line of text: a `PromptBar` with segments like ["PAUSE ", {"act": "pause"}].
# - Anywhere else: `InputPrompts.strip_for(action)` and listen to `device_changed`.
#
# Every action below must match what main.gd / player.gd actually accept for that device.

signal device_changed(is_gamepad: bool)

# Stick/trigger travel needed before the gamepad counts as "in use" (ignores drift).
const AXIS_DEADZONE: float = 0.5
# Mouse travel (viewport px, accumulated) needed to switch back to keyboard/mouse prompts.
const MOUSE_SWITCH_DIST: float = 6.0
const GLYPH_H: int = 11
const STRIP_GAP: int = 2
const BUTTON_GLYPH_GAP: int = 4
const BUTTON_STYLE_STATES: Array[String] = ["normal", "hover", "focus", "pressed", "disabled"]

# action -> glyph ids per device. "kbm" ids starting with "key_" become key caps.
const ACTIONS: Dictionary = {
	"confirm": {"kbm": ["key_ENTER"], "pad": ["pad_a"]},
	"back": {"kbm": ["key_ESC"], "pad": ["pad_b"]},
	"buy": {"kbm": ["key_SPACE"], "pad": ["pad_a"]},
	"swap_menu": {"kbm": ["key_TAB"], "pad": ["pad_x"]},
	"launch": {"kbm": [], "pad": ["pad_menu"]},
	"resume": {"kbm": ["key_ESC"], "pad": ["pad_b"]},
	"pause": {"kbm": ["key_ESC"], "pad": ["pad_menu"]},
	"reroll": {"kbm": ["key_R"], "pad": ["pad_y"]},
	"draft_pick": {"kbm": ["key_1", "key_2", "key_3"], "pad": ["pad_dpad", "pad_a"]},
	"move": {"kbm": ["key_WASD"], "pad": ["pad_ls"]},
	"fire": {"kbm": ["key_SPACE"], "pad": ["pad_a"]},
	"focus": {"kbm": ["key_SHIFT"], "pad": ["pad_lb"]},
	"autofire": {"kbm": ["key_C"], "pad": ["pad_y"]},
	"speed": {"kbm": ["key_F"], "pad": ["pad_rt"]},
	"swap_weapon": {"kbm": ["key_E"], "pad": ["pad_b"]},
}

# 3x5 pixel font for key caps and small button labels (M, N and W are wider).
const FONT_3X5: Dictionary = {
	"A": [".X.", "X.X", "XXX", "X.X", "X.X"],
	"B": ["XX.", "X.X", "XX.", "X.X", "XX."],
	"C": [".XX", "X..", "X..", "X..", ".XX"],
	"D": ["XX.", "X.X", "X.X", "X.X", "XX."],
	"E": ["XXX", "X..", "XX.", "X..", "XXX"],
	"F": ["XXX", "X..", "XX.", "X..", "X.."],
	"G": [".XX", "X..", "X.X", "X.X", ".XX"],
	"H": ["X.X", "X.X", "XXX", "X.X", "X.X"],
	"I": ["XXX", ".X.", ".X.", ".X.", "XXX"],
	"J": ["..X", "..X", "..X", "X.X", ".X."],
	"K": ["X.X", "X.X", "XX.", "X.X", "X.X"],
	"L": ["X..", "X..", "X..", "X..", "XXX"],
	"M": ["X...X", "XX.XX", "X.X.X", "X...X", "X...X"],
	"N": ["X..X", "XX.X", "X.XX", "X..X", "X..X"],
	"O": [".X.", "X.X", "X.X", "X.X", ".X."],
	"P": ["XX.", "X.X", "XX.", "X..", "X.."],
	"Q": [".X.", "X.X", "X.X", "XX.", ".XX"],
	"R": ["XX.", "X.X", "XX.", "X.X", "X.X"],
	"S": [".XX", "X..", ".X.", "..X", "XX."],
	"T": ["XXX", ".X.", ".X.", ".X.", ".X."],
	"U": ["X.X", "X.X", "X.X", "X.X", "XXX"],
	"V": ["X.X", "X.X", "X.X", "X.X", ".X."],
	"W": ["X...X", "X...X", "X.X.X", "XX.XX", "X...X"],
	"X": ["X.X", "X.X", ".X.", "X.X", "X.X"],
	"Y": ["X.X", "X.X", ".X.", ".X.", ".X."],
	"Z": ["XXX", "..X", ".X.", "X..", "XXX"],
	"0": ["XXX", "X.X", "X.X", "X.X", "XXX"],
	"1": [".X.", "XX.", ".X.", ".X.", "XXX"],
	"2": ["XX.", "..X", ".X.", "X..", "XXX"],
	"3": ["XX.", "..X", ".X.", "..X", "XX."],
	"4": ["X.X", "X.X", "XXX", "..X", "..X"],
	"5": ["XXX", "X..", "XX.", "..X", "XX."],
	"6": [".XX", "X..", "XXX", "X.X", "XXX"],
	"7": ["XXX", "..X", ".X.", ".X.", ".X."],
	"8": ["XXX", "X.X", "XXX", "X.X", "XXX"],
	"9": ["XXX", "X.X", "XXX", "..X", "XX."],
}

# 5x7 letters for the round Xbox face buttons.
const FONT_5X7: Dictionary = {
	"A": ["..X..", ".X.X.", "X...X", "X...X", "XXXXX", "X...X", "X...X"],
	"B": ["XXXX.", "X...X", "X...X", "XXXX.", "X...X", "X...X", "XXXX."],
	"X": ["X...X", "X...X", ".X.X.", "..X..", ".X.X.", "X...X", "X...X"],
	"Y": ["X...X", "X...X", ".X.X.", "..X..", "..X..", "..X..", "..X.."],
}

const COL_OUTLINE: Color = Color("#141c3a")
const COL_KEY_FACE: Color = Color("#dce8ff")
const COL_KEY_BEVEL: Color = Color("#8ca6d8")
const COL_KEY_TEXT: Color = Color("#1d294a")
const COL_PAD_DARK: Color = Color("#3a4566")
const COL_PAD_MID: Color = Color("#6f7fa6")
const COL_PAD_TEXT: Color = Color("#f4f7ff")

var is_gamepad: bool = false

var _glyph_images: Dictionary = {}
var _strip_cache: Dictionary = {}
var _glyph_cache: Dictionary = {}
var _bound_buttons: Dictionary = {}
var _mouse_travel: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_gamepad = not Input.get_connected_joypads().is_empty()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	var kind: int = classify_event(event)
	if kind == 1:
		_mouse_travel = 0.0
		set_gamepad(true)
	elif kind == 0:
		set_gamepad(false)


# 1 = gamepad, 0 = keyboard/mouse/touch, -1 = not a deliberate input (release, drift, jitter).
func classify_event(event: InputEvent) -> int:
	if event is InputEventJoypadButton:
		return 1 if (event as InputEventJoypadButton).pressed else -1
	if event is InputEventJoypadMotion:
		return 1 if absf((event as InputEventJoypadMotion).axis_value) >= AXIS_DEADZONE else -1
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		return 0 if ke.pressed and not ke.echo else -1
	if event is InputEventMouseButton:
		return 0 if (event as InputEventMouseButton).pressed else -1
	if event is InputEventScreenTouch:
		return 0 if (event as InputEventScreenTouch).pressed else -1
	if event is InputEventMouseMotion:
		if not is_gamepad:
			return -1
		# A bumped desk or a resting hand shouldn't flip the prompts, so wait for real travel.
		_mouse_travel += (event as InputEventMouseMotion).relative.length()
		if _mouse_travel >= MOUSE_SWITCH_DIST:
			_mouse_travel = 0.0
			return 0
	return -1


func set_gamepad(on: bool) -> void:
	if on == is_gamepad:
		return
	is_gamepad = on
	_mouse_travel = 0.0
	_refresh_bound_buttons()
	device_changed.emit(is_gamepad)


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if connected:
		set_gamepad(true)
	elif Input.get_connected_joypads().is_empty():
		set_gamepad(false)


# Glyph ids for an action on the current device (empty if that device has no binding).
func glyph_ids_for(action: String) -> Array[String]:
	var out: Array[String] = []
	var spec: Dictionary = ACTIONS.get(action, {})
	var ids: Array = spec.get("pad" if is_gamepad else "kbm", [])
	for id: Variant in ids:
		out.append(String(id))
	return out


# All of an action's glyphs for the current device in one texture, or null if it has none.
func strip_for(action: String) -> Texture2D:
	var ids: Array[String] = glyph_ids_for(action)
	if ids.is_empty():
		return null
	var key: String = ",".join(PackedStringArray(ids))
	if _strip_cache.has(key):
		return _strip_cache[key]
	var imgs: Array[Image] = []
	var total_w: int = 0
	for id: String in ids:
		var g: Image = _glyph_image(id)
		imgs.append(g)
		total_w += g.get_width()
	total_w += STRIP_GAP * (imgs.size() - 1)
	var strip: Image = Image.create(total_w, GLYPH_H, false, Image.FORMAT_RGBA8)
	var x: int = 0
	for g: Image in imgs:
		strip.blit_rect(g, Rect2i(0, 0, g.get_width(), g.get_height()), Vector2i(x, 0))
		x += g.get_width() + STRIP_GAP
	var tex: ImageTexture = ImageTexture.create_from_image(strip)
	_strip_cache[key] = tex
	return tex


# A single glyph by id, e.g. "pad_a" or "key_ESC".
func glyph(id: String) -> Texture2D:
	if not _glyph_cache.has(id):
		_glyph_cache[id] = ImageTexture.create_from_image(_glyph_image(id))
	return _glyph_cache[id]


# Draws the action's glyph just right of the button's label (the pair stays centred) and keeps
# it in sync with the device. Pass "" to clear it. The button's text can keep changing freely.
# Call after the button's styleboxes are set: the glyph's room is reserved in their right margin.
func bind_button(btn: Button, action: String) -> void:
	var key: int = btn.get_instance_id()
	if not _bound_buttons.has(key):
		var base_margins: Dictionary = {}
		for state: String in BUTTON_STYLE_STATES:
			if not btn.has_theme_stylebox_override(state):
				var own: StyleBox = btn.get_theme_stylebox(state).duplicate() as StyleBox
				btn.add_theme_stylebox_override(state, own)
			base_margins[state] = btn.get_theme_stylebox(state).content_margin_right
		_bound_buttons[key] = {"btn": btn, "act": "", "base_margins": base_margins}
		btn.draw.connect(_draw_button_glyph.bind(btn))
	_bound_buttons[key]["act"] = action
	_fit_button_margin(btn)


func _refresh_bound_buttons() -> void:
	for key: int in _bound_buttons.keys():
		var entry: Dictionary = _bound_buttons[key]
		if not is_instance_valid(entry["btn"]):
			_bound_buttons.erase(key)
			continue
		_fit_button_margin(entry["btn"] as Button)


# Widens the right content margin by the glyph's width so Godot centres the label in the space
# left of the glyph, which keeps "LABEL [glyph]" centred as a pair.
func _fit_button_margin(btn: Button) -> void:
	var entry: Dictionary = _bound_buttons[btn.get_instance_id()]
	var tex: Texture2D = strip_for(String(entry["act"]))
	var extra: float = 0.0 if tex == null else float(tex.get_width() + BUTTON_GLYPH_GAP)
	var base_margins: Dictionary = entry["base_margins"]
	for state: String in BUTTON_STYLE_STATES:
		btn.get_theme_stylebox(state).content_margin_right = float(base_margins[state]) + extra
	btn.queue_redraw()


func _draw_button_glyph(btn: Button) -> void:
	var entry: Dictionary = _bound_buttons.get(btn.get_instance_id(), {})
	if entry.is_empty():
		return
	var tex: Texture2D = strip_for(String(entry["act"]))
	if tex == null:
		return
	var font: Font = btn.get_theme_font("font")
	var font_size: int = btn.get_theme_font_size("font_size")
	var text_w: float = 0.0
	if btn.text != "":
		text_w = font.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var sb: StyleBox = btn.get_theme_stylebox("normal")
	var left: float = sb.get_margin(SIDE_LEFT)
	var avail: float = btn.size.x - left - sb.get_margin(SIDE_RIGHT)
	var gx: float = floorf(left + (avail - text_w) * 0.5 + text_w) + float(BUTTON_GLYPH_GAP)
	# The FF6 font sits about a pixel above the button's centre line, so match it.
	var gy: float = floorf((btn.size.y - float(GLYPH_H)) * 0.5) - 1.0
	var tint: Color = Color(1.0, 1.0, 1.0, 0.45) if btn.disabled else Color.WHITE
	btn.draw_texture(tex, Vector2(gx, gy), tint)


# Every glyph id used by ACTIONS (for the smoke test).
func all_glyph_ids() -> Array[String]:
	var out: Array[String] = []
	for action: String in ACTIONS.keys():
		var spec: Dictionary = ACTIONS[action]
		for dev: String in ["kbm", "pad"]:
			for id: Variant in spec[dev]:
				if not out.has(String(id)):
					out.append(String(id))
	return out


# =================================================================================
# GLYPH PAINTING
# =================================================================================
func _glyph_image(id: String) -> Image:
	if not _glyph_images.has(id):
		_glyph_images[id] = _paint_glyph(id)
	return _glyph_images[id]


func _paint_glyph(id: String) -> Image:
	if id.begins_with("key_"):
		return _paint_keycap(id.substr(4))
	match id:
		"pad_a":
			return _paint_face_button("A", Color("#2fb350"), Color("#14612a"), COL_PAD_TEXT)
		"pad_b":
			return _paint_face_button("B", Color("#e3404b"), Color("#7e1820"), COL_PAD_TEXT)
		"pad_x":
			return _paint_face_button("X", Color("#3b78f5"), Color("#18398f"), COL_PAD_TEXT)
		"pad_y":
			return _paint_face_button("Y", Color("#ffcf2e"), Color("#946f00"), Color("#3a2c00"))
		"pad_lb":
			return _paint_shoulder("LB", false)
		"pad_rb":
			return _paint_shoulder("RB", false)
		"pad_lt":
			return _paint_shoulder("LT", true)
		"pad_rt":
			return _paint_shoulder("RT", true)
		"pad_menu":
			return _paint_menu_button()
		"pad_view":
			return _paint_view_button()
		"pad_dpad":
			return _paint_dpad()
		"pad_ls":
			return _paint_stick("L")
		"pad_rs":
			return _paint_stick("R")
	return _paint_keycap("?")


func _text_width_3x5(txt: String) -> int:
	var w: int = 0
	for i: int in range(txt.length()):
		var rows: Array = FONT_3X5.get(txt.substr(i, 1), ["XXX"])
		w += String(rows[0]).length()
		if i < txt.length() - 1:
			w += 1
	return w


func _blit_rows(img: Image, rows: Array, x0: int, y0: int, col: Color) -> void:
	for ry: int in range(rows.size()):
		var row: String = String(rows[ry])
		for rx: int in range(row.length()):
			if row.substr(rx, 1) == "X":
				img.set_pixel(x0 + rx, y0 + ry, col)


func _blit_text_3x5(img: Image, txt: String, x0: int, y0: int, col: Color) -> void:
	var x: int = x0
	for i: int in range(txt.length()):
		var rows: Array = FONT_3X5.get(txt.substr(i, 1), [])
		if rows.is_empty():
			x += 4
			continue
		_blit_rows(img, rows, x, y0, col)
		x += String(rows[0]).length() + 1


func _disc_dist(x: int, y: int) -> float:
	return Vector2(float(x) - 5.0, float(y) - 5.0).length()


# Keyboard key cap: light face, darker bottom bevel, dark outline with clipped corners.
func _paint_keycap(label: String) -> Image:
	var tw: int = _text_width_3x5(label)
	var w: int = maxi(GLYPH_H, tw + 6)
	var img: Image = Image.create(w, GLYPH_H, false, Image.FORMAT_RGBA8)
	for y: int in range(GLYPH_H):
		for x: int in range(w):
			var edge_x: bool = x == 0 or x == w - 1
			var edge_y: bool = y == 0 or y == GLYPH_H - 1
			if edge_x and edge_y:
				continue
			var col: Color = COL_KEY_FACE
			if edge_x or edge_y:
				col = COL_OUTLINE
			elif y >= GLYPH_H - 3:
				col = COL_KEY_BEVEL
			img.set_pixel(x, y, col)
	_blit_text_3x5(img, label, floori(float(w - tw) * 0.5), 2, COL_KEY_TEXT)
	return img


# Round Xbox face button: coloured disc, darker rim, small highlight, big letter.
func _paint_face_button(letter: String, fill: Color, rim: Color, text_col: Color) -> Image:
	var img: Image = Image.create(GLYPH_H, GLYPH_H, false, Image.FORMAT_RGBA8)
	var hi: Color = fill.lightened(0.38)
	for y: int in range(GLYPH_H):
		for x: int in range(GLYPH_H):
			var d: float = _disc_dist(x, y)
			if d > 5.45:
				continue
			var col: Color = fill
			if d > 4.4:
				col = rim
			elif d > 3.4 and x < 5 and y < 5:
				col = hi
			img.set_pixel(x, y, col)
	_blit_rows(img, FONT_5X7[letter], 3, 2, text_col)
	return img


# LB/RB bumper (pill) or LT/RT trigger (taller, rounded top).
func _paint_shoulder(label: String, trigger: bool) -> Image:
	var tw: int = _text_width_3x5(label)
	var w: int = tw + 6
	var img: Image = Image.create(w, GLYPH_H, false, Image.FORMAT_RGBA8)
	var top: int = 0 if trigger else 1
	var bot: int = GLYPH_H - 1 if trigger else GLYPH_H - 2
	for y: int in range(top, bot + 1):
		for x: int in range(w):
			var edge_x: bool = x == 0 or x == w - 1
			var edge_y: bool = y == top or y == bot
			if edge_x and edge_y:
				continue
			# Trigger: round off the top corners a little more.
			if trigger and y == top and (x <= 1 or x >= w - 2):
				continue
			if trigger and y == top + 1 and (x == 0 or x == w - 1):
				continue
			var col: Color = COL_PAD_DARK
			if edge_x or edge_y or (trigger and y == top + 1 and (x == 1 or x == w - 2)):
				col = COL_OUTLINE
			img.set_pixel(x, y, col)
	_blit_text_3x5(img, label, 3, bot - 6, COL_PAD_TEXT)
	return img


func _paint_dark_disc() -> Image:
	var img: Image = Image.create(GLYPH_H, GLYPH_H, false, Image.FORMAT_RGBA8)
	for y: int in range(GLYPH_H):
		for x: int in range(GLYPH_H):
			var d: float = _disc_dist(x, y)
			if d <= 5.45:
				img.set_pixel(x, y, COL_OUTLINE if d > 4.4 else COL_PAD_DARK)
	return img


# Menu (start) button: dark disc with three lines.
func _paint_menu_button() -> Image:
	var img: Image = _paint_dark_disc()
	for line_y: int in [3, 5, 7]:
		for x: int in range(3, 8):
			img.set_pixel(x, line_y, COL_PAD_TEXT)
	return img


# View (back/select) button: dark disc with two overlapping windows.
func _paint_view_button() -> Image:
	var img: Image = _paint_dark_disc()
	for i: int in range(5):
		img.set_pixel(4 + i, 2, COL_PAD_TEXT)
		img.set_pixel(8, 2 + i, COL_PAD_TEXT)
	for y: int in range(4, 9):
		for x: int in range(2, 7):
			var edge: bool = x == 2 or x == 6 or y == 4 or y == 8
			img.set_pixel(x, y, COL_PAD_TEXT if edge else COL_PAD_DARK)
	return img


# D-pad: grey cross with darker centre and light arrow tips.
func _paint_dpad() -> Image:
	var rows: Array[String] = [
		"...kkkkk...",
		"...kSWSk...",
		"...kSSSk...",
		"kkkkSSSkkkk",
		"kSSSSSSSSSk",
		"kWSSSDSSSWk",
		"kSSSSSSSSSk",
		"kkkkSSSkkkk",
		"...kSSSk...",
		"...kSWSk...",
		"...kkkkk...",
	]
	var pal: Dictionary = {"k": COL_OUTLINE, "S": COL_PAD_MID, "W": COL_PAD_TEXT, "D": COL_PAD_DARK}
	var img: Image = Image.create(GLYPH_H, GLYPH_H, false, Image.FORMAT_RGBA8)
	for y: int in range(GLYPH_H):
		for x: int in range(GLYPH_H):
			var ch: String = rows[y].substr(x, 1)
			if pal.has(ch):
				img.set_pixel(x, y, pal[ch])
	return img


# Analog stick: grey ring around a dark cap with the stick's letter.
func _paint_stick(letter: String) -> Image:
	var img: Image = Image.create(GLYPH_H, GLYPH_H, false, Image.FORMAT_RGBA8)
	for y: int in range(GLYPH_H):
		for x: int in range(GLYPH_H):
			var d: float = _disc_dist(x, y)
			if d > 5.45:
				continue
			var col: Color = COL_PAD_DARK
			if d > 4.4:
				col = COL_OUTLINE
			elif d > 3.4:
				col = COL_PAD_MID
			img.set_pixel(x, y, col)
	_blit_text_3x5(img, letter, 4, 3, COL_PAD_TEXT)
	return img
