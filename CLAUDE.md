# CLAUDE.md — Star Viper Architecture & Collaboration Guide

Welcome! This repository is a self-contained **Godot 4.7** (`GDScript`) 16-bit horizontal roguelite space shooter. Almost all art, bitmap fonts, SFX, and multi-instrument music are generated procedurally in GDScript so there are no external binary asset dependencies to break across machines.

## Core Viewport & Rendering Conventions
- **Native Resolution:** `480x270` (`16:9` widescreen pixel art), scaled `3x` (`1440x810`) windowed or integer-scaled fullscreen (`project.godot`).
- **Playfield Vertical Bounds:**
  - Top HUD bar: `y = 0..19`
  - Active flight corridor: `y = 28..234` (Stage floor deck renders at `y = 242..250`)
  - Bottom Pictorial Ship Upgrades Dock: `y = 250..270`
- **Typography:** Custom SNES *Final Fantasy VI*-inspired serif bitmap font at `res://assets/fonts/ff6_font.fnt` (`ff6_font.png`). Always render text at `font_size = 10` (or integer multiples like `20`) for crisp 1:1 pixel alignment.

## Project Structure & Autoloads
Autoload singletons (configured in `project.godot` in load order):
1. `MetaSave` (`scripts/autoload/meta_save.gd`) — Persists permanent Hangar upgrades, banked Scrap, pilot stats, and audio/display/touch settings to `user://star_viper_save.json`.
2. `StageData` (`scripts/autoload/stage_data.gd`) — Defines the 8 campaign stages (`Outer Orbit`, `Starcruiser`, `Cloud Base`, `Xeno Forest`, `Cryo Glacier`, `Magma Core`, `Abyssal Trench`, `Cyber Nexus`), 4 waves per stage (`Wave 4` = Stage Boss).
3. `PixelArt` (`scripts/autoload/pixel_art.gd` + `scripts/boss_painter.gd`) — Builds and caches all 16-bit `ImageTexture` sprites, `28x18` upgrade card diagrams, `11x11` bottom HUD module icons, and the 8 giant native-pixel bosses (`BossPainter`).
4. `RetroSfx` (`scripts/autoload/retro_sfx.gd`) — Synthesizes 16-bit PCM `AudioStreamWAV` sound effects at startup with a 12-voice `AudioStreamPlayer` pool.
5. `GenesisMusic` (`scripts/autoload/genesis_music.gd`) — Real-time `44.1 kHz` stereo `AudioStreamGenerator` synthesizer using pure diatonic scale-degree indexing (zero out-of-key accidentals), featuring 8 distinct stage instrument ensembles + 1 universal dark-synthwave Boss theme.

Gameplay & Scene Scripts:
- `scenes/main.tscn` + `scripts/main.gd` — State machine (`TITLE`, `STATS`, `OPTIONS`, `HANGAR`, `INTRO_WARP`, `PLAYING`, `PAUSED`, `DRAFT`, `HYPERSPACE`, `GAME_OVER_DELAY`), wave director, FF6-styled menus, controller/touch UI, and HUD.
- `scripts/starfield.gd` (`StarfieldBg`) — Multi-biome parallax stage renderer and Hyperspace Warp tunnel.
- `scripts/player.gd` (`PlayerShip`) — Keyboard, full Gamepad, and multi-touch drag flight, Focus slow-dodge (`3px` core hurtbox), *Gradius* trailing Option drones, and weapon emitters.
- `scripts/enemy.gd` (`GameEnemy`) — 4 regular enemy archetypes + 8 giant 3-phase stage bosses with adaptive burst-DPS plating.
- `scripts/bullet.gd` (`GameBullet`), `scripts/pickup.gd` (`GamePickup`), `scripts/fx_layer.gd` (`FxLayer`).

## Verification & Headless Smoke Testing
GDScript 4 strict typing is used throughout (avoid `:=` type inference on `Variant` / untyped `Array` lookups; use explicit types).

To run the automated headless smoke test (exercises menus, pause flow, all 8 stages, music synthesis, all 40 enemy/boss variants, draft cards, and hyperspace transitions, then exits with `STAR_VIPER_SMOKE_TEST_PASSED`):
```bash
godot --headless --path . --quit-after 30 -- --smoke-test
```
