extends "res://scripts/stages/stage_boss.gd"

# The attacks of a checkpoint's giant dino robot (see checkpoint_bosses.gd). Each robot in the
# lineup knows the previous ones' moves plus new ones (Matthew: "bosses get more difficult after
# every 4 levels, have vertical beams, waves, stuff coming from behind"):
#   checkpoint 1  VOLLEY aimed bursts from the jaw, FAN needle spreads from the arm
#   2             + WAVE   a snaking stream of shots sweeping up and down
#   3             + BEAMS  warning lines flicker, then vertical laser columns erupt
#   4             + BEHIND warning arrows on the left edge, then shots fly in from behind you
#   5             + RING   bursts from the core
#   6+            + RAIN   shots falling from the top across the screen
#   final         everything, faster, and in phase 3 two attacks at once
# Telegraphs are drawn in draw(); a move that needs a warning first spans two attack() calls.

const BEAM_WARN: float = 0.8
const BEAM_LIFE: float = 0.75
const BEHIND_WARN: float = 0.9

var tier: int = 0
var final_boss: bool = false
var used: Dictionary = {}          # moves performed (the smoke test reads it)

var _moves: Array[String] = []
var _mi: int = 0
var _pending: String = ""          # a move waiting out its warning
var _beams: Array[float] = []      # x of each warned beam column
var _behind: Array[float] = []     # y of each warned shot from behind
var _warn_t: float = -1.0          # boss age when the warning started
var _wave_n: int = 0


func setup() -> void:
	var level: int = 99 if final_boss else tier
	_moves = ["volley", "fan"]
	if level >= 1:
		_moves.insert(1, "wave")
	if level >= 2:
		_moves.append("beams")
	if level >= 3:
		_moves.insert(2, "behind")
	if level >= 4:
		_moves.append("ring")
	if level >= 5:
		_moves.insert(3, "rain")


func _speed(spd_bonus: float) -> float:
	return 118.0 + spd_bonus * 0.6 + float(tier) * 8.0 + (20.0 if final_boss else 0.0)


func _rate(rate_mult: float) -> float:
	return rate_mult * (0.82 if final_boss else 1.0) * maxf(0.7, 1.0 - 0.04 * float(tier))


func _mouth() -> Vector2:
	return boss._bm("mouth", Vector2(-60.0, -14.0))


func attack(rate_mult: float, spd_bonus: float) -> void:
	var r: float = _rate(rate_mult)
	var spd: float = _speed(spd_bonus)
	if _pending != "":
		_fire_pending(spd)
		wait(0.7 * r)
		return
	if _wave_n > 0:
		_wave_step(spd)
		wait(0.055)
		return
	var move: String = _moves[_mi % _moves.size()]
	_mi += 1
	_start(move, spd, r)
	# The final boss doubles up in its last phase.
	if final_boss and phase >= 3 and _pending == "" and _wave_n == 0:
		var extra: String = _moves[(_mi + 2) % _moves.size()]
		if extra != "beams" and extra != "behind" and extra != "wave":
			_start(extra, spd, r)


func _start(move: String, spd: float, r: float) -> void:
	used[move] = true
	match move:
		"volley":
			var n: int = 3 + mini(tier, 4) + (2 if phase >= 3 else 0)
			for k: int in range(n):
				shoot_aimed_from(_mouth(), spd * 1.1, "bullet_enemy_orange", (float(k) - float(n - 1) * 0.5) * 0.07)
			wait(0.95 * r)
		"fan":
			var count: int = 7 + mini(tier, 6)
			shoot_spread_from(boss._bm("arm", _mouth()), count, 0.17, spd, "bullet_enemy_cyan")
			wait(1.0 * r)
		"wave":
			_wave_n = 14 + tier * 2
			wait(0.3 * r)
		"beams":
			_beams.clear()
			var cols: int = 2 + mini(tier, 4) / 2 + (1 if phase >= 2 else 0)
			_beams.append(clampf(player_pos().x, 30.0, 330.0))
			for c: int in range(cols - 1):
				_beams.append(randf_range(30.0, 330.0))
			_pending = "beams"
			_warn_t = age
			wait(BEAM_WARN)
		"behind":
			_behind.clear()
			var rows: int = 3 + (1 if phase >= 2 else 0)
			_behind.append(clampf(player_pos().y, 40.0, 240.0))
			for c: int in range(rows - 1):
				_behind.append(randf_range(40.0, 240.0))
			_pending = "behind"
			_warn_t = age
			wait(BEHIND_WARN)
		"ring":
			spin += 0.31
			shoot_ring(16 + tier * 2, spd * 0.85, "bullet_enemy_orange", spin)
			wait(1.0 * r)
		"rain":
			for k: int in range(10 + tier):
				emit_bullet(Vector2(randf_range(20.0, 340.0), 14.0 - randf() * 30.0), Vector2(randf_range(-20.0, 0.0), spd * 0.9), "bullet_enemy_lime")
			wait(0.9 * r)


func _fire_pending(spd: float) -> void:
	match _pending:
		"beams":
			# A beam is a column of shots that hang in place and fade (GameBullet.life_left).
			for x: float in _beams:
				var y: float = 32.0
				while y < 250.0:
					var b: GameBullet = emit_bullet(Vector2(x, y), Vector2.ZERO, "bullet_enemy_pink", 3.0)
					if b != null:
						b.life_left = BEAM_LIFE
					y += 7.0
			RetroSfx.play("boss_beam", -6.0, 0.05)
		"behind":
			for y: float in _behind:
				for k: int in range(3):
					emit_bullet(Vector2(-12.0 - float(k) * 14.0, y), Vector2(spd * 1.15, (float(k) - 1.0) * 12.0), "bullet_enemy_pink")
	_pending = ""
	_warn_t = -1.0


func _wave_step(spd: float) -> void:
	_wave_n -= 1
	var base: float = (player_pos() - _mouth()).angle()
	var a: float = base + sin(float(_wave_n) * 0.55) * 0.55
	shoot_from(_mouth(), Vector2.from_angle(a) * spd, "bullet_enemy_lime")


func draw() -> void:
	if _pending == "" or _warn_t < 0.0:
		return
	var origin: Vector2 = boss.global_position
	var blink: bool = int(age * 18.0) % 2 == 0
	var col: Color = Color(1.0, 0.35, 0.55, 1.0 if blink else 0.55)
	match _pending:
		"beams":
			for x: float in _beams:
				boss.draw_line(Vector2(x, 32.0) - origin, Vector2(x, 248.0) - origin, col, 1.0)
		"behind":
			for y: float in _behind:
				for k: int in range(2):
					var tip: Vector2 = Vector2(18.0 + float(k) * 8.0, y) - origin
					boss.draw_polyline(PackedVector2Array([tip + Vector2(-5.0, -5.0), tip, tip + Vector2(-5.0, 5.0)]), col, 2.0)
