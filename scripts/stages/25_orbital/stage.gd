extends "res://scripts/stages/stage_module.gd"

# STAGE 25: DEFENSE GRID. Skimming the hull of a colossal orbital battle station: solar arrays
# and docking arms rise behind the hull, turret batteries track far-off targets, and the
# planet turns slowly below, its night side glittering with cities. The station's defence grid
# is fully awake.
#
# Files in this folder:
#   stage.gd               stage table entry, difficulty, enemies, wave recipes, song
#   art.gd                 every sprite (enemies, shots, generic re-skins, the battery's frames)
#   background.gd          the painted station/planet layers plus the per-frame animation
#   enemy_pod.gd           turret pods that clamp onto the hull and lob flak at a marked point
#   enemy_interceptor.gd   interceptor squadrons that fly in formation and break on the leader
#   enemy_shieldgen.gd     shield generators that cover nearby stage enemies with a hex shield
#   boss.gd                BASTION MAIN BATTERY's attack patterns

const Art = preload("art.gd")
const Background = preload("background.gd")
const Boss = preload("boss.gd")
const Pod = preload("enemy_pod.gd")
const Interceptor = preload("enemy_interceptor.gd")
const ShieldGen = preload("enemy_shieldgen.gd")
const Music = preload("res://scripts/music_candidates.gd")

const ID: String = "orbital"


func get_stage_def() -> Dictionary:
	return {
		"id": ID,
		"name": "DEFENSE GRID",
		"subtitle": "ORBITAL STATION EXTERIOR",
		"boss_name": "BASTION MAIN BATTERY",
		"sky_top": Color("#03061a"),
		"sky_mid": Color("#071029"),
		"sky_bot": Color("#0b1a36"),
		"deck_fill": Color("#161e2a"),
		"deck_line": Color("#e8a030"),
		"accent": Color("#78d0ff"),
		"has_ceiling": false,
		"scout_tex": ID + "_scout",
		"swooper_tex": ID + "_swooper",
		"sniper_tex": ID + "_sniper",
		"cruiser_tex": ID + "_cruiser",
		"boss_tex": "boss_" + ID,
		"bullet_a": "bullet_enemy_orange",
		"bullet_b": ID + "_shot",
		"boss_box": Vector2(100.0, 150.0),
		"boss_x": 398.0,
	}


# Stage 25 on the shared curve (k = 17). "hp" is StageData.stage_hp_growth(24): 1.34^7 x 1.12^17.
func get_difficulty_row() -> Dictionary:
	return {"hp": 53.26, "shot_speed": 1.424, "fire_rate": 1.69, "groups": 18, "pace": 0.647, "themed": 0.836}


func get_boss_hp() -> float:
	return 42500.0


func build_art() -> Dictionary:
	return Art.build(ID)


func get_enemy_defs() -> Dictionary:
	return {
		"pod": {"hp": 16.0, "score": 460, "scrap": 3, "xp": 9, "r": 8.5, "tex": ID + "_pod_0", "behaviour": Pod},
		"interceptor": {"hp": 6.0, "score": 210, "scrap": 1, "xp": 4, "r": 6.5, "tex": ID + "_icpt_0", "behaviour": Interceptor, "exit_left": -50.0},
		"shieldgen": {"hp": 22.0, "score": 620, "scrap": 4, "xp": 12, "r": 10.5, "tex": ID + "_gen_0", "behaviour": ShieldGen, "big": true},
	}


# A: an interceptor squadron in a V, with a turret pod dropping onto the hull. B: a fortified
# position - a shield generator covering two pods (plus a squadron in the third wave). C: a
# generator escorting an echelon squadron and a pod.
func queue_themed_group(w: RefCounted) -> float:
	match w.recipe:
		0:
			var n: int = 3 + w.extra
			var sq: int = w.new_squad(n)
			var lane: float = randf_range(70.0, 190.0)
			for k: int in range(n):
				w.spawn("interceptor", w.t, Vector2(512.0, lane), float(k), sq, 0)
			w.spawn("pod", w.t + 0.6, Vector2(randf_range(300.0, 420.0), 14.0), 0.0, -1, 1)
			return 2.6
		1:
			var gy: float = randf_range(120.0, 170.0)
			w.spawn("shieldgen", w.t, Vector2(512.0, gy), 0.0, -1, 0)
			w.spawn("pod", w.t + 0.3, Vector2(512.0, 200.0), 0.0, -1, 0)
			w.spawn("pod", w.t + 0.9, Vector2(randf_range(380.0, 440.0), 14.0), 1.0, -1, 1)
			if w.extra > 0:
				var sq2: int = w.new_squad(3)
				var lane2: float = 70.0 if w.top else 200.0
				for k2: int in range(3):
					w.spawn("interceptor", w.t + 1.4, Vector2(512.0, lane2), float(k2), sq2, 1)
			return 3.1
		_:
			var n3: int = 4 + w.extra
			var sq3: int = w.new_squad(n3)
			var lane3: float = 80.0 if w.top else 185.0
			w.spawn("shieldgen", w.t, Vector2(512.0, 270.0 - lane3), 0.0, -1, 1)
			for k3: int in range(n3):
				w.spawn("interceptor", w.t + 0.8, Vector2(512.0, lane3), float(k3), sq3, 1)
			w.spawn("pod", w.t + 1.3, Vector2(512.0, 190.0), 0.0, -1, 0)
			return 3.4


func create_boss() -> RefCounted:
	return Boss.new()


func paint_background() -> Dictionary:
	return Background.paint()


func create_background() -> RefCounted:
	return Background.new()


# Station-defence march in C minor at 126 BPM: an orchestral march groove (snare-led, on the
# march variant, not stage 11's taiko), low-string ostinato, brass chords, pulse plucks keeping
# the radar-blip pulse, and a heroic brass lead.
func get_song() -> Dictionary:
	return {
		"seed": 2525, "style": 12, "gv": 0, "root": 36, "bpm": 126.0, "scale": Music.MINOR,
		"bass": 12, "pad": 0, "arp": 8, "lead": 11, "kit": "orch",
		"energy": 2, "bass_gain": 1.4, "kick_gain": 1.4, "sub_mix": 0.35,
		"lead_attack": 45.0, "lead_decay": 1.3, "vib": 0.005, "density": 1,
		"mel_lo": 2, "mel_hi": 10, "lift": 2, "harm_int": -3,
		"delay_beats": 0.75, "delay_fb": 0.28, "delay_wet": 0.22,
		"prog_a": [0, 0, -2, -2, -4, -4, -3, -1],
		"prog_b": [3, 3, 0, 0, -2, -3, -1, -1],
	}


# The same fight on outrun synths, for the soundtrack picker in Options.
func get_song_alternatives() -> Array:
	return [
		{"name": "PERIMETER ALERT", "info": "OUTRUN  132 BPM  G DORIAN", "seed": 2526,
			"style": 11, "gv": 0, "root": 43, "bpm": 132.0, "scale": Music.DORIAN,
			"bass": 7, "pad": 7, "arp": 8, "lead": 10, "kit": "hard",
			"energy": 2, "bass_gain": 1.6, "lead_decay": 1.6, "mel_lo": 0, "mel_hi": 8, "delay_wet": 0.26,
			"prog_a": [0, 0, 3, 3, -2, -2, 4, 4], "prog_b": [3, 4, 0, -2, 3, 4, 1, 4]},
	]
