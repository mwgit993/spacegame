# CLAUDE.md — Star Viper Architecture & Collaboration Guide

Welcome! This repository is a self-contained **Godot 4.7** (`GDScript`) 16-bit horizontal roguelite space shooter built for easy collaboration across PCs (Antigravity + Claude + Godot 4.7.2). Almost all sprites, giant 3-frame bosses, upgrade diagrams, SFX, and multi-instrument music are generated procedurally in GDScript so there are no fragile binary asset dependencies.

## Core Viewport & Rendering Conventions
- **Native Resolution:** `480x270` (`16:9` widescreen pixel art), scaled `3x` (`1440x810`) windowed or integer-scaled fullscreen (`project.godot`).
- **Playfield Vertical Bounds:**
  - Top FF6 Status Bar: `y = 0..19` (`HP`, `Shields`, `LV`, `Stage`, `Scrap`, `Score`, `II` Pause)
  - Full-Width Glowing XP Bar: `y = 19..23` (Mega Man 28-pip Boss HP Bar renders below it at `y = 24..33`)
  - Active Flight Corridor: `y = 30..249` (Scrolling stage floor deck renders flush at `y = 258..270`; no bottom HUD bar!)
  - Tactical Split-Screen Pause Menu: Left column shows compact FF6 option boxes; Right panel displays Current Ship Stats & a 2-column pictorial grid of Installed Weapons & Upgrades.
- **Typography:** Custom SNES *Final Fantasy VI*-inspired serif bitmap font at `res://assets/fonts/ff6_font.fnt` (`ff6_font.png`). Always render text at `font_size = 10` (or integer multiples like `20`).

## Project Structure, Autoloads & Gameplay Systems
Autoload singletons (configured in `project.godot` in load order):
1. `MetaSave` (`scripts/autoload/meta_save.gd`) — Persists the 30-node Starforge Skill Tree (`tree_levels`), `selected_ship`, banked Scrap, pilot stats, and settings to `user://star_viper_save.json`.
2. `StageData` (`scripts/autoload/stage_data.gd`) — Defines the 8 campaign stages (`Outer Orbit`, `Starcruiser`, `Cloud Base`, `Xeno Forest`, `Cryo Glacier`, `Magma Core`, `Abyssal Trench`, `Cyber Nexus`), 4 waves per stage (`Wave 4` = Stage Boss).
3. `PixelArt` (`scripts/autoload/pixel_art.gd` + `scripts/boss_painter.gd`) — Builds and caches all 16-bit `ImageTexture` sprites, 7 playable 2-frame starships, exotic projectiles (including animated Flying Space Cats!), red enemy-bullet danger halos, `28x18` upgrade diagrams, `11x11` badges, and 3-frame animated bosses (`BossPainter`).
4. `RetroSfx` (`scripts/autoload/retro_sfx.gd`) — Synthesizes 16-bit PCM `AudioStreamWAV` sound effects at startup (including Mega Man boss intro beam/pose/HP-tick, XP chimes, level-up fanfare, electric zaps, prism bounces, and space-cat meows).
5. `GenesisMusic` (`scripts/autoload/genesis_music.gd`) — Real-time `44.1 kHz` stereo `AudioStreamGenerator` synthesizer locked to pure diatonic scales, with 8 stage ensembles + 1 universal darksynth Boss theme.

Gameplay & Data Scripts:
- `scripts/skill_tree_data.gd` (`SkillTreeData`) — Defines all **7 Playable Ships** (`viper`, `beetle`, `phantom`, `dread`, `saucer`, `eyeball`, `neko`) and the **30-Node Branching Skill Tree**.
- `scenes/main.tscn` + `scripts/main.gd` — Master state machine (`TITLE`, `STATS`, `OPTIONS`, `HANGAR` [Skill Tree], `LOADOUT` [Ship Fleet Bay], `INTRO_WARP`, `PLAYING`, `PAUSED`, `DRAFT`, `HYPERSPACE`, `GAME_OVER_DELAY`), seamless wave director, *BALL x PIT*-style XP gem leveling & auto-Scrap banking, and UI.
- `scripts/player.gd` (`PlayerShip`) — Multi-controller + Keyboard + Touch flight, 7 ship hulls & signature blasters, 5 Tech Beam cores (co-axial on exotic ships), 7 visible hull-mounted/orbiting Ship Addons, crits, and Lazarus Revive.
- `scripts/enemy.gd` (`GameEnemy`) — 4 regular enemy archetypes + 8 giant 3-phase animated bosses with Mega Man teleport intros, signature taunt poses, 28-pip HP bar fills, and chain-explosion deaths.
- `scripts/bullet.gd` (`GameBullet`), `scripts/pickup.gd` (`GamePickup`), `scripts/fx_layer.gd` (`FxLayer`), `scripts/starfield.gd` (`StarfieldBg`).

## Verification & Headless Smoke Testing
GDScript 4 strict typing is used throughout (avoid `:=` type inference on `Variant` / untyped `Array` lookups; use explicit types). When adding new `class_name` scripts on a fresh clone, run `--headless --import` once before `--smoke-test`:
```bash
godot --headless --path . --import
godot --headless --path . --quit-after 30 -- --smoke-test
```
*(Must print `STAR_VIPER_SMOKE_TEST_PASSED` with zero script errors.)*
