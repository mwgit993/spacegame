# PROJECT_CONTEXT.md — Star Viper: 16-Bit Galactic Roguelite

> **Purpose:** Complete session handoff document so you can clone `https://github.com/mwgit993/spacegame` on your **Home PC** (in **Antigravity** + **Godot 4.7+**) or collaborate with your brother using **Claude**, and pick up right where we left off without losing any context.

---

## 1. High-Level Concept & Design Pillars
- **Genre:** Horizontal 16-bit Widescreen Roguelite Space Shooter (*Gradius* / *R-Type* / *Thunder Force* meets modern run-based roguelite progression).
- **Engine:** **Godot Engine v4.7.2** (Standard GDScript, Forward+ / D3D12 on Windows, compatible with Linux/Steam Deck).
- **Zero-Fragility Procedural Pipeline:** All 16-bit sprites, giant boss pixel paintings, upgrade diagrams, 16-bit PCM sound effects, and the real-time 44.1 kHz multi-instrument soundtrack are generated procedurally in GDScript (paired with a custom imported *Final Fantasy VI*-style bitmap font in `assets/fonts/`). Any procedural texture or SFX can later be swapped one-by-one for hand-crafted `.png` / `.wav` files if desired.
- **Core Roguelite Loop:**
  - **In-Run Temporary Modules (lost on death):** Clear a wave to draft **1-of-3 concise visual upgrade cards** (*Option Orb* trailing shadow drones up to 4, *Spread Shot* up to 5-way, *Pierce Laser*, *Homing Pods*, *Force Shield*, *Rapid Coil*, *Afterburner*, *Hull Patch*).
  - **Permanent Meta-Progression (kept on death):** Enemies and squad-wipes drop magnetized **Scrap** banked to `user://star_viper_save.json` (`MetaSave`), spent in the **Ship Hangar** on permanent *Reinforced Hull*, *Cycler Capacitor*, *Plasma Core*, *Tractor Array*, and *Aegis Generator* ranks.

---

## 2. Viewport, Coordinate Layout & Typography
- **Native Pixel Viewport:** `480 × 270` (`16:9`), integer-scaled (`1440 × 810` default 3× window, nearest-neighbor canvas texture filter).
- **Screen Zones (`480 × 270`):**
  - `y = 0..19`: **Top FF6 Status Bar** (Hull pips, Shield pips, `Stage X-Y Name`, `Scrap`, `Score`, and clickable/tappable `II` Pause button; segmented 3-phase Boss HP bar renders at `y = 22..30` during boss fights).
  - `y = 28..234`: **Active Flight Corridor** (`PlayerShip` clamped to `x = 18..462, y = 28..234`).
  - `y = 242..250`: **Scrolling Stage Floor Deck** (plus `y = 19..26` ceiling bulkhead on enclosed stages).
  - `y = 250..270`: **Pictorial Bottom Ship Upgrades Dock** (framed visual pills with `11×11` pixel icons and full English names like `Option x2`, `Spread Lv2`, `Laser Lv1`—no cryptic abbreviations).
- **Font:** Custom SNES *Final Fantasy VI*-style variable-width serif pixel bitmap font (`res://assets/fonts/ff6_font.fnt` + `ff6_font.png`) with silver-white shading and 1px black drop-shadow. Set globally in `project.godot`; always use `font_size = 10` (or `20` for 2× titles).

---

## 3. Runtime Scene Tree Architecture
When the game runs (`res://scenes/main.tscn`), the live scene tree is structured as follows:

```text
root (Window)
 ├── MetaSave          [Autoload: scripts/autoload/meta_save.gd]
 ├── StageData         [Autoload: scripts/autoload/stage_data.gd]
 ├── PixelArt          [Autoload: scripts/autoload/pixel_art.gd]
 ├── RetroSfx          [Autoload: scripts/autoload/retro_sfx.gd]
 │    └── AudioStreamPlayer × 12 (16-bit PCM SFX pool)
 ├── GenesisMusic      [Autoload: scripts/autoload/genesis_music.gd] (PROCESS_MODE_ALWAYS)
 │    └── AudioStreamPlayer (44.1 kHz stereo AudioStreamGenerator)
 └── Main (Node2D)     [scenes/main.tscn -> scripts/main.gd]
      ├── StarfieldBg (Node2D)        [scripts/starfield.gd] — 8-biome parallax + Hyperspace warp tunnel
      ├── world_root (Node2D)         — Screen-shake root; disabled during State.PAUSED
      │    ├── pickup_layer (Node2D)  — Active GamePickup nodes (Scrap crystals & Hull heals)
      │    ├── enemy_layer (Node2D)   — Active GameEnemy & Boss nodes (group: "enemies")
      │    ├── PlayerShip (Area2D)    [scripts/player.gd] + 4 top-level Option Orb Sprite2Ds
      │    ├── bullet_layer (Node2D)  — Active player & enemy GameBullet Area2Ds
      │    └── FxLayer (Node2D)       [scripts/fx_layer.gd] — Pixel explosions, shockwaves, popups
      └── ui_layer (CanvasLayer)
           ├── hud_bar (Control)      — Custom-drawn top status bar, Boss HP bar, & bottom module dock
           ├── pause_hud_btn (Button) — Top-right "II" mouse/touch pause button
           ├── touch_focus_btn        — Bottom-right "FOCUS" hold pad for phone/tablet touch mode
           ├── banner_label (Label)   — Stage/Boss/Hyperspace announcements
           ├── title_panel (Control)  — Start Run, Ship Hangar, Stats, Options, Quit Game
           ├── stats_panel (Control)  — Pilot service record
           ├── options_panel (Control)— Music/SFX vol, Autofire, Shake, Touch mode, Fullscreen, Reset
           ├── hangar_panel (Control) — Permanent between-run Scrap upgrades
           ├── draft_panel (Control)  — Between-wave 3-card visual module selector
           └── pause_panel (Control)  — Resume, Options, Retire to Hangar, Quit to Title
```

**Physics Collision Layers (`Area2D`):**
- Bit 1 (`1`): `PlayerShip` (`3.0 px` fair core hurtbox; revealed when holding Focus)
- Bit 2 (`2`): Player `GameBullet` (`mask = 4`)
- Bit 3 (`4`): `GameEnemy` (`monitorable = true`)
- Bit 4 (`8`): Enemy `GameBullet` (`mask = 1`)
*(Pickups use fast distance + Tractor Magnet pull in `pickup.gd` rather than physics shapes so the player's 3px hurtbox stays strictly for dodging.)*

---

## 4. Main Scripts & File Map
| File | Role |
| :--- | :--- |
| `project.godot` | Godot 4.7 config, `480×270` integer scaling, FF6 global theme font, 5 autoloads |
| `scripts/main.gd` | Master state machine (`TITLE`, `STATS`, `OPTIONS`, `HANGAR`, `INTRO_WARP`, `PLAYING`, `PAUSED`, `DRAFT`, `HYPERSPACE`, `GAME_OVER_DELAY`), 10–14 formation wave director, UI/HUD, controller/touch menu nav, `--smoke-test` runner |
| `scripts/player.gd` | Keyboard + Gamepad + Multi-Touch drag flight, Focus slow-dodge, *Gradius* movement-history ring buffer for up to 4 Option drones, Vulcan/Spread/Pierce-Laser/Homing-Missile emitters |
| `scripts/enemy.gd` | 4 regular enemy archetypes + 8 giant 3-phase Stage Bosses (`STAGE_BOSS_HP` exponential curve, adaptive anti-melt burst plating, 66%/33% phase shields, phase escort summons, themed boss bullet patterns) |
| `scripts/boss_painter.gd` | Procedural 1:1 native-pixel painter for all 8 towering right-side bosses (`Nemesis Dreadnought Wall`, `Mecha Scorpion`, `Sky Wyvern`, `Emperor Stag-Mantis Bug`, `Frost Seraph`, `Inferno Skull Balrog`, `Abyssal Kraken`, `Neon Medusa Overmind`) |
| `scripts/starfield.gd` | Renders all 8 themed parallax environments (`Outer Orbit`, `Starcruiser Interior`, `Cloud Base`, `Xeno Forest`, `Cryo Glacier`, `Magma Core`, `Abyssal Trench`, `Cyber Nexus`) + Hyperspace Warp tunnel |
| `scripts/autoload/genesis_music.gd` | Real-time 44.1 kHz stereo music engine locked to pure diatonic scale degrees (zero out-of-key sharps), with **8 distinct stage instrument ensembles** + **1 universal "Neon Medusa" C-minor darksynth Boss theme** |
| `scripts/autoload/pixel_art.gd` | Caches player/enemy/projectile sprites, `28×18` upgrade demonstration scenes, and `11×11` bottom HUD module icons |
| `scripts/autoload/retro_sfx.gd` | Synthesizes 16-bit arcade WAV SFX (`shoot`, `laser`, `missile`, `hit`, `explode`, `big_explode`, `shield_hit`, `scrap`, `powerup`, `ui`) |
| `scripts/autoload/stage_data.gd` | Palette, enemy texture keys, boss names, and wave-per-stage (`4` waves per stage) helpers |
| `scripts/autoload/meta_save.gd` | JSON save/load (`user://star_viper_save.json`) for Scrap, permanent upgrades, stats, and options |
| `scripts/bullet.gd` / `pickup.gd` / `fx_layer.gd` | Homing/piercing projectiles, magnetized Scrap/Heal drops, screen shake, pixel explosions, floating popups |
| `export_presets.cfg` & `build_releases.bat` | One-click Windows `.exe` + Steam Deck Proton/Linux export setup |
| `CLAUDE.md` & `AGENTS.md` | Quick-reference context files read automatically by Claude and Antigravity |

---

## 5. Summary of Recent Changes Completed
1. **8 Unique Stage Ensembles + Universal Boss Theme:** Rebuilt `genesis_music.gd` on pure diatonic scales so each world uses its own instruments (Midnight Synthwave -> Slap-FM Funk -> Sky Flute-Fusion -> Tribal Marimba/Congas -> Ice-Bell Celesta/Choir -> Volcanic Guitar/Taiko -> Underwater Tremolo Rhodes/Sonar -> 142 BPM Cyber-Trance) while all bosses share the heavy C-minor *"Neon Medusa"* darksynth anthem.
2. **8 Giant Screen-Filling Bosses & 3-Phase Anti-Melt System:** Built `BossPainter` (`110×190 px` right-side bosses with tall rectangular hurtboxes), exponential stage HP (`360` -> `17,500`), adaptive burst-DPS plating, and 3 escalating phases (`66%` Overdrive & `33%` Berserk with phase-shift shields and escort spawns).
3. **Longer Waves & Stage 1 Opening Warp-In:** Expanded stage waves to 10–14 multi-formation encounters (~32–42s per wave) and added a cinematic Hyperspace Warp-In arrival at the start of Stage 1 (plus inter-stage Hyperspace jumps after every boss).
4. **FF6 Pixel Font, Pictorial HUD, Pause, Controller & Touch:** Custom *Final Fantasy VI* serif bitmap font, clear bottom module chips with `11×11` icons and full English names, full Pause menu, Xbox/PS/Steam Deck controller support, and phone/tablet touch-drag + `FOCUS` pad.
5. **Standalone `StarViper.exe` Export:** Verified standalone `.exe` + `.pck` packaging via `build_releases.bat` for PC and Steam Deck (Proton).

---

## 6. How to Resume on Your Home PC (or Brother's PC)
1. **Clone the repository:**
   ```bash
   git clone https://github.com/mwgit993/spacegame.git
   ```
2. **Open in Antigravity (Home PC):**
   - Set the cloned `spacegame` folder as your **Active Workspace** in Antigravity.
   - Start a new chat and say: *"Read `PROJECT_CONTEXT.md` and let's continue working on Star Viper."*
3. **Open in Godot 4.7+:**
   - Open Godot v4.7+ -> **Import** -> select `spacegame/project.godot` -> press **`F5`** to run.
4. **Run Headless Verification Anytime:**
   ```bash
   godot --headless --path . --quit-after 30 -- --smoke-test
   ```
   *(Should print `STAR_VIPER_SMOKE_TEST_PASSED` with zero errors.)*
5. **Build Standalone `.exe` for PC / Steam Deck:**
   - Edit the `GODOT=` path at the top of `build_releases.bat` if Godot is installed in a different folder on your Home PC, then double-click `build_releases.bat` to generate `builds/windows/StarViper.exe` + `StarViper.pck`.

---

## 7. Suggested Next Steps Backlog
When you sit down at your Home PC (or team up with your brother), here are great next areas to tackle:
1. **Playtesting & Tuning Pass:** Test Stage 1–8 wave pacing, boss TTK (time-to-kill) across different upgrade synergies, and bullet visibility against brighter backgrounds (like Cloud Base and Magma Core).
2. **Distinct Stage-Specific Enemy Mechanics:** Give biome enemies unique behaviors beyond visual/stat variants (e.g., Starcruiser ceiling/floor rail-turrets, Forest splitting spore-pods, Ice shattering frost-mines, Volcano rising lava geysers, Cyber teleporting bit-drones).
3. **More Roguelite Build Synergies & Ship Frames:** Add unlockable starter ships in the Hangar (e.g., Twin-Laser Interceptor, Heavy Missile Gunship, Drone Carrier) and rare Gold "Boss Relic" cards dropped specifically after defeating a Stage Boss.
4. **Visual Polish & CRT/Scanline Toggle:** Optional subtle 16-bit CRT scanline/phosphor shader toggle in `OPTIONS`, boss destruction chain-explosion slow-mo, and custom `.png` sprite overrides if you or your brother want to hand-draw art in Aseprite.
5. **Steam Deck Native Linux Export:** Download Godot 4.7.2 Export Templates (`Editor -> Manage Export Templates`) to test one-click single-binary `StarViper.x86_64` builds alongside the Proton `.exe` build.
