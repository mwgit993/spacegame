# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Star Viper is a Godot 4.7 (GDScript) horizontal roguelite shoot-'em-up. Nearly every asset is generated in code at startup: sprites, bosses, SFX and music. The only binary asset is the bitmap font in `assets/fonts/`. Gameplay and controls are described in `README.md`. `PROJECT_CONTEXT.md` and `AGENTS.md` repeat this material for other agents (Antigravity).

## Commands

`godot` below means the Godot 4.7.x editor binary. On macOS that is `/Applications/Godot.app/Contents/MacOS/Godot`.

```bash
godot --headless --path . --import                         # run once on a fresh clone, or after adding a class_name script
godot --headless --path . --quit-after 30 -- --smoke-test  # must print STAR_VIPER_SMOKE_TEST_PASSED with zero script errors
godot --path .                                             # play the game
```

- There is no unit-test framework or linter. The smoke test is the only automated check. It is `_run_smoke_test()` in `scripts/main.gd`, and it drives every menu, ship, upgrade, stage and boss by calling private methods directly. It checks for crashes and script errors, not behavior. If you rename a method it calls, update it there. If you add a ship, upgrade or stage, add it to the smoke test.
- **The smoke test overwrites the real save file.** It buys skill-tree nodes and finally calls `MetaSave.reset_save()`, all against `user://star_viper_save.json`, the same file normal play uses. Back that file up before running the test on a machine where someone has progress.
- `build_releases.bat` (Windows only) copies the Godot editor binary next to an exported `.pck`. It has the original author's Godot install paths hardcoded. `export_presets.cfg` has `Windows` and `SteamDeck` (Linux) presets.

## Code conventions

- Use explicit static types everywhere. Don't use `:=` when the right-hand side is a `Variant`, such as a `Dictionary` lookup or an element of an untyped `Array`. Cast instead, for example `String(d["id"])` or `int(d.get("x", 0))`. The codebase does this consistently.
- Nearly the whole scene tree is built in code. `scenes/main.tscn` contains a single `Node2D` with `main.gd`, and all UI is laid out with literal pixel coordinates. Don't go looking for `.tscn` files or a theme resource.
- Input is polled directly with `Input.is_physical_key_pressed(KEY_*)` and joypad button and axis checks, in `player.gd` and in `main.gd` (`_unhandled_input`, `_poll_controller_menu_stick`). The project defines no InputMap actions. Touch and mouse-drag flight is handled in `player.gd`.
- On-screen button prompts follow the last device used. `InputPrompts` switches between keyboard/mouse and gamepad on each real press (stick drift and small mouse nudges are ignored) and draws key caps or Xbox button glyphs. Never write key names into UI text. Use `InputPrompts.bind_button(btn, action)` for a button, or a `PromptBar` (`scripts/prompt_bar.gd`) for a line of text with glyphs. Actions are listed in `InputPrompts.ACTIONS`. If you change a binding in `_unhandled_input` or `player.gd`, update its entry there too.
- Text uses the FF6-style bitmap font at `font_size = 10`, or an integer multiple of it. Texture filtering is nearest-neighbor and antialiasing is off.

## Screen layout (480×270 native, integer-scaled)

- `y 0–19`: top status bar, drawn by `main._draw_hud` on `hud_bar`. `y 19–23`: XP bar. `y 24–33`: boss HP gauge with 28 pips (only shown during a boss fight).
- `y 30–249`: playfield. The player is clamped to `PlayerShip.MIN_Y`/`MAX_Y`, and bouncing bullets reflect at roughly `y 27` and `y 254`.
- `y 258–270`: scrolling floor deck, drawn by `StarfieldBg`. There is no bottom HUD.

## Architecture

**Autoloads**, in load order:

| Autoload | Role |
| --- | --- |
| `MetaSave` | Persistent progression and settings. |
| `StageData` | Stage table: 8 stages × `WAVES_PER_STAGE = 4`. Wave 4 of each stage is the boss. |
| `PixelArt` | Texture cache. |
| `RetroSfx` | Pool of synthesized `AudioStreamWAV` effects. |
| `GenesisMusic` | Real-time synth that feeds an `AudioStreamGenerator`. |
| `InputPrompts` | Tracks the last-used input device and builds the button-prompt glyphs. |

`SkillTreeData` is a `class_name` with const data only (`SHIPS`, `NODES`). It is not an autoload.

**`main.gd` is the hub** (about 2,750 lines). It owns the `State` enum state machine, builds every menu panel, runs the wave director (`_begin_next_wave` queues timed spawns into `_spawn_queue`, and `_update_wave_director` releases them), handles XP and level-up drafts, and draws the HUD, skill tree and pause screen. It does the drawing through `Control.draw.connect(...)` callbacks.

World layering is `world_root` → `pickup_layer`, `enemy_layer`, `player`, `bullet_layer`, `fx_layer`. UI lives on a separate `CanvasLayer`.

**Pausing and drafts don't use `get_tree().paused`.** They set `world_root.process_mode = PROCESS_MODE_DISABLED` and slow `starfield.speed_scale`. `GenesisMusic` runs with `PROCESS_MODE_ALWAYS` and is only ducked. Anything new that should freeze during pause must live under `world_root`.

**Entities are created with `.new()` and set up through a `setup(...)` call.** The player, enemies and bullets are `Area2D` subclasses; `GamePickup` is a plain `Node2D`. They talk to `main` through signals: `GameEnemy.destroyed(enemy, killed_by_player)`, `boss_phase_broken`, `GamePickup.collected`, `PlayerShip.hp_changed` and `player_died`.

- Collision layers: `1` player, `2` player bullets, `4` enemies, `8` enemy bullets. Pickups don't use physics: they are collected within 13 px of the player and pulled in from `MetaSave.get_magnet_radius()`.
- Enemies join the `"enemies"` group. Homing, chain and AoE effects iterate that group.
- An enemy that leaves the screen emits `destroyed(self, false)`. Only `true` awards score, Scrap or XP.
- Pickups spawned from kill handlers go through `call_deferred` (`_spawn_pickup_deferred`), because the kill happens inside a physics callback.

**Two progression layers:**

1. **Meta (between runs).** Skill-tree nodes live in `SkillTreeData.NODES`. Each node has an `id`, a `parent` (a node is revealed once its parent has level 1 or more), `max_level`, `base_cost` plus `cost_step`, a tree `pos`, and optionally `unlocks_ship`. `MetaSave.tree_levels[id]` stores the rank. Effects are applied only through `MetaSave.get_*()` getters, such as `get_starting_max_hp()` or `get_crit_chance()`. `PlayerShip.reset_for_new_run()` and `main._start_run()` read those getters. Some ship perks are hardcoded by ship id inside the getters, for example `selected_ship == "phantom"` adds +20% crit. Save loading only copies keys that exist in `NODES`, so adding or removing a node doesn't break old saves.
2. **Run (in-run drafts).** `main.RUN_UPGRADE_POOL` defines draft cards (`id`, `cat` set to BEAM, ADDON or CORE, `max_rank`, `icon`). Choosing a card increments `main.run_ranks[id]` and calls `player.apply_run_upgrade(id)`. That function's `match` has **its own hardcoded rank caps**, which must stay in sync with `max_rank`. Once a non-vulcan ship drafts a beam, it is mounted as `aux_beam` while the signature weapon stays. On the vulcan ship (`viper`) the beam replaces `active_beam`. Either way, `_roll_draft_choices` then only offers that one beam.

**Content touchpoints.** Adding content means editing several files:

- **Ship:**
  - an entry in `SkillTreeData.SHIPS`
  - a `NODES` entry with `unlocks_ship`
  - sprites `<sprite_0>` and `<sprite_1>` in `PixelArt._build_all`
  - a weapon branch in `player._get_mode_params`, `_fire_primary` and `_spawn_mode_shot`
  - any perk inside a `MetaSave` getter
- **Draft upgrade:**
  - `RUN_UPGRADE_POOL`
  - `player.apply_run_upgrade`
  - an icon texture
  - the badge list in `main._collect_installed_modules`, which feeds the pause screen
- **Stage:** the stage count is hardcoded as 8 in several places (`posmod(..., 8)` in `enemy.gd` and `starfield.gd`). A stage needs:
  - a `StageData.STAGES` entry
  - `GameEnemy.STAGE_BOSS_HP`
  - a boss pattern in `GameEnemy._boss_attack` (`match stage_idx`)
  - boss frames in `BossPainter.build_all_bosses`
  - a biome in `StarfieldBg`
  - a song in `GenesisMusic.STAGE_SONGS`

  After stage 8, play loops with harder enemies; nothing ends the game.

**Asset generation:**

- `PixelArt` sprites are arrays of strings, one character per pixel, mapped through `PALETTE` or an optional custom palette passed to `_make_tex`. `BossPainter` draws bosses into `Image`s and registers three animation frames per boss, `boss_<theme>_0`, `_1` and `_2`.
- **Lookups fail silently.** `PixelArt.tex("typo")` returns the `scout_space` sprite. `RetroSfx.play("typo")` does nothing. A wrong key won't produce an error, so look at the result on screen.
- `GenesisMusic._process` synthesizes every sample in GDScript on the main thread, with a buffer of only 0.14 s. Keep the per-sample path (`_synth_*_frame`, `_tick_*`) cheap. Any work added there runs 44,100 times per second.
