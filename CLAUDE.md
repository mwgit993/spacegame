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

- There is no unit-test framework or linter. The smoke test is the only automated check. It is `_run_smoke_test()` in `scripts/main.gd`, and it drives every menu, ship, upgrade, stage and boss by calling private methods directly. It mostly checks for crashes and script errors, not behavior; the skill-tree checks (save migration refund, locked draft cards, every node buyable, draft-card perk effects) the speed-up checks (`_smoke_check_speed_up`: hold, toggle, drop to 1x on every way out of flight, setting saved and loaded) and the stage-enemy checks (`_smoke_check_themed_enemies`: every sprite exists, every type runs its pattern, a kill pays out once, child spawns are capped and give no Scrap, the golem shield, frost/bomb/spore shots, the difficulty table only gets harder) instead push an error and exit 1 without printing the PASSED line. If you rename a method it calls, update it there. If you add a ship, upgrade or stage, add it to the smoke test (stage enemies are picked up from `GameEnemy.THEMED` automatically).
- **The smoke test overwrites the real save file.** It buys skill-tree nodes and finally calls `MetaSave.reset_save()`, all against `user://star_viper_save.json`, the same file normal play uses. Back that file up before running the test on a machine where someone has progress.
- `build_releases.bat` (Windows only) copies the Godot editor binary next to an exported `.pck`. It has the original author's Godot install paths hardcoded. `export_presets.cfg` has `Windows` and `SteamDeck` (Linux) presets.

## Code conventions

- Use explicit static types everywhere. Don't use `:=` when the right-hand side is a `Variant`, such as a `Dictionary` lookup or an element of an untyped `Array`. Cast instead, for example `String(d["id"])` or `int(d.get("x", 0))`. The codebase does this consistently.
- Nearly the whole scene tree is built in code. `scenes/main.tscn` contains a single `Node2D` with `main.gd`, and all UI is laid out with literal pixel coordinates. Don't go looking for `.tscn` files or a theme resource.
- Input is polled directly with `Input.is_physical_key_pressed(KEY_*)` and joypad button and axis checks, in `player.gd` and in `main.gd` (`_unhandled_input`, `_poll_controller_menu_stick`, and `_update_speed_up` for the speed-up button: `F` or the right trigger, which is not a fire button). The project defines no InputMap actions. Touch and mouse-drag flight is handled in `player.gd`.
- On-screen button prompts follow the last device used. `InputPrompts` switches between keyboard/mouse and gamepad on each real press (stick drift and small mouse nudges are ignored) and draws key caps or Xbox button glyphs. Never write key names into UI text. Use `InputPrompts.bind_button(btn, action)` for a button, or a `PromptBar` (`scripts/prompt_bar.gd`) for a line of text with glyphs. Actions are listed in `InputPrompts.ACTIONS`. If you change a binding in `_unhandled_input` or `player.gd`, update its entry there too.
- Menu focus: the Options panel sets explicit focus neighbours with `_link_focus_grid(rows)`, because Godot's automatic search picks wide neighbouring rows over the button beside you. Use it for any new grid of buttons. The left stick is removed from the `ui_left/right/up/down` actions in `main._ready`, so `_poll_controller_menu_stick` is the only stick handler and one push moves focus once. RESET SAVE needs two presses within 3 s.
- Text uses the FF6-style bitmap font at `font_size = 10`, or an integer multiple of it. Texture filtering is nearest-neighbor and antialiasing is off.

## Screen layout (480×270 native, integer-scaled)

- `y 0–19`: top status bar, drawn by `main._draw_hud` on `hud_bar`. `y 19–23`: XP bar. `y 24–33`: boss HP gauge with 28 pips (only shown during a boss fight); at `x 436–476` on the same row, the speed-up `>> x2` badge while 2x is on.
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

**The speed-up button uses `Engine.time_scale`.** `main._set_speed_up` sets it to 2 and doubles `Engine.physics_ticks_per_second`, but only in `PLAYING` and `HYPERSPACE`. The `state` property's setter calls `_on_state_changed`, which drops back to 1x on any other state, so always change state through `state = ...`. Everything driven by `delta` speeds up; audio doesn't (music renders by buffer space, SFX keep their pitch). Because movement happens in `_process`, a 2x frame moves things twice as far between overlap checks: `GameBullet._update_sweep` adds a capsule along each shot's path while `time_scale > 1`, and `GamePickup` uses `move_toward` so a pull can't overshoot the ship. Anything new that moves fast or tests distance once per frame needs the same care. Cooldowns that reset to their interval (rather than carrying the remainder) fire up to one frame late each time, so at 2x the player fires about 7–16% fewer shots per game second than at 1x.

**Entities are created with `.new()` and set up through a `setup(...)` call.** The player, enemies and bullets are `Area2D` subclasses; `GamePickup` is a plain `Node2D`. They talk to `main` through signals: `GameEnemy.destroyed(enemy, killed_by_player)`, `boss_phase_broken`, `spawn_requested` (child enemies), `GamePickup.collected`, `PlayerShip.hp_changed` and `player_died`.

- Collision layers: `1` player, `2` player bullets, `4` enemies, `8` enemy bullets. Pickups don't use physics: they are collected within 13 px of the player and pulled in from `MetaSave.get_magnet_radius()`.
- Enemies join the `"enemies"` group. Homing, chain and AoE effects iterate that group. A stage enemy that is still telegraphing its entrance (`_warn_timer > 0`: a lava blob bubbling, a jet's warning arrow) stays out of the group and has no collision until it appears.
- An enemy that leaves the screen emits `destroyed(self, false)`, and so does a space mine that bursts on its own. Only `true` awards score, Scrap or XP; an enemy with `scrap_drop` 0 gives no Scrap.
- Pickups spawned from kill handlers go through `call_deferred` (`_spawn_pickup_deferred`), because the kill happens inside a physics callback.

**Two progression layers:**

1. **Meta (between runs).** Skill-tree nodes live in `SkillTreeData.NODES`. Each node has an `id`, a `parent` (a node is revealed once its parent has level 1 or more), `max_level`, `base_cost` plus `cost_step`, a tree `pos`, `unlocks_ship` and `unlocks_upgrade`. `MetaSave.tree_levels[id]` stores the rank. **The tree deliberately gives no combat bonuses at run start** (Matthew's design call): nodes only add starting hull and shields, Lazarus revive, ships, economy perks (magnet, Scrap, XP, boss bounty, rerolls), and "DRAFT CARD" nodes whose `unlocks_upgrade` adds a `RUN_UPGRADE_POOL` id to the level-up drafts. Effects are applied only through `MetaSave.get_*()` getters, such as `get_starting_max_hp()`, read by `PlayerShip.reset_for_new_run()` and `main._start_run()`. Ship perks are hardcoded by ship id inside the getters, for example `selected_ship == "phantom"` adds +20% crit.
   - **Saves:** `MetaSave.migrate_tree_levels()` runs on every load. It refunds Scrap for levels in nodes that no longer exist (priced from `LEGACY_NODE_COSTS`) and for levels above a node's current `max_level`, then drops unknown keys. If you remove or shrink a node, add its old price to `LEGACY_NODE_COSTS` so players get their Scrap back. `TREE_VERSION` is written to the save.
2. **Run (in-run drafts).** `main.RUN_UPGRADE_POOL` defines draft cards (`id`, `cat`, `max_rank`, `icon`). The base cards (BEAM, ADDON, CORE) are always offered. The 18 DRAFT CARD entries (cat MOD, GUARD, TECH or LOOT, plus `short` and `badge` for the pause screen) are skipped by `_roll_draft_choices` until `MetaSave.is_run_upgrade_unlocked(id)`. Choosing a card increments `main.run_ranks[id]` and calls `player.apply_run_upgrade(id)`. That function's `match` has **its own hardcoded rank caps**, which must stay in sync with `max_rank`. Once a non-vulcan ship drafts a beam, it is mounted as `aux_beam` while the signature weapon stays. On the vulcan ship (`viper`) the beam replaces `active_beam`. Either way, `_roll_draft_choices` then only offers that one beam.
   - DRAFT CARD effects live in `player.gd` (`_update_run_perks` for timed/aura effects, `_spawn_player_bullet` / `_spawn_mode_shot` for per-shot flags, `on_enemy_killed` and `on_stage_cleared` hooks called from `main`), `bullet.gd` (`_apply_hit_modifiers`, shrapnel fragments, mine lifetime, chrono slow) and `enemy.gd` (`apply_chill`, `apply_burn`). Anything that adds an `Area2D` from inside a collision callback goes through `call_deferred`.

**Enemies and difficulty.**

- Four generic types (`SCOUT_SINE`, `SWOOPER`, `SNIPER`, `CRUISER`) appear in every stage, re-skinned through `StageData.STAGES[i]["scout_tex"]` etc. Each stage also has its own enemies (the rest of `GameEnemy.Type`), with base stats in `GameEnemy.THEMED` (home `stage`, `hp`, `score`, `scrap`, `xp`, hit `r` or `box`, `tex`). Their behaviour is one `_tick_<name>` per type, dispatched from `_process_themed`; per-type setup is in `_setup_themed`; telegraphs (charge glints, lock-on lines, warning markers, the glitch's ghost) and HP bars are drawn in `_draw_themed`, on top of the sprite (`show_behind_parent`). By stage: 1 asteroids (split into `ROCK_CHUNK`s) and mine layers (drop `SPACE_MINE`s); 2 floor/ceiling turrets and security drones; 3 bomber blimps and jet formations (some from behind); 4 spore pods and charging beetles; 5 ice crystals (shatter into shards) and snow drones (frost puffs slow the ship via `PlayerShip.apply_frost`); 6 leaping lava blobs and shielded rock golems; 7 jellyfish, eels (solid body segments) and anglerfish; 8 replicating viruses, teleporting glitches and firewall columns.
- **Difficulty curve:** `StageData.DIFFICULTY` has one row per stage: `hp`, `shot_speed`, `fire_rate`, `groups`, `pace`, `themed`. Stage 1 is all 1.0. `get_difficulty()` wraps it for loops (HP x`LOOP_HP_STEP`, plus a little more speed). Regular enemies' bullet speeds and cooldowns in `enemy.gd` are written as stage-1 values: `_shoot_from` / `_emit_bullet` scale speed by `shot_speed`, and `_fire_cd()` divides cooldowns by `fire_rate`. Bosses ignore the table.
- **Wave director:** in a regular wave, `_begin_next_wave` builds `groups` (+1 per later wave) groups, a `themed` share of them from `_queue_themed_group` (per-stage recipes; recipe C from the stage's second wave, an extra unit in the third) and the rest from the six generic patterns in `_queue_generic_group`. Each group's time gap is multiplied by `pace`.
- **Child enemies** (rock chunks, mines, virus copies) are requested with `spawn_requested`; `main._on_enemy_spawn_requested` puts them in `_spawn_queue` so they spawn next frame (never inside a physics callback) with signals connected, and the wave can't end while they're pending. Children (`gen > 0`) give no Scrap and at most 1 XP, and every source is capped: `ROCK_CHUNKS` per asteroid, `MINES_PER_LAYER`, `VIRUS_MAX_GEN` and `VIRUS_CAP`. Shots fired while dying (ice crystal shards) use `_emit_bullet(..., deferred = true)`.
- Enemy shot extras in `GameBullet`: `home_target`/`home_time`/`home_rate` (spores), `floor_burst` (blimp bombs), `make_frost()` (harmless puffs that slow the ship, never count as grazes), and any enemy shot with `life_left` fades out over its last 0.5 s.

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
  - an icon texture (`upg_<id>`; DRAFT CARD art is built from the badge in `PixelArt._build_draft_card_icons`)
  - for base cards, the badge list in `main._collect_installed_modules`, which feeds the pause screen (DRAFT CARD entries are listed automatically from `short`/`badge`)
  - for a tree-unlocked card, a `NODES` entry with `unlocks_upgrade` set to the card id
- **Stage enemy:**
  - a value appended to `GameEnemy.Type` (append, so queued spawns keep their meaning) and a `THEMED` entry
  - setup in `_setup_themed`, a `_tick_<name>` dispatched from `_process_themed`, telegraphs in `_draw_themed`, and any death effect in `_on_themed_death`
  - sprites in `EnemyArt` (`scripts/enemy_art.gd`), listed in `EnemyArt.KEYS`
  - a recipe in `main._queue_themed_group`
  - if it spawns children, a cap, and `gen > 0` rewards (see `_apply_child_rewards`)
- **Stage:** the stage count is hardcoded as 8 in several places (`posmod(..., 8)` in `enemy.gd`, `starfield.gd` and `main._queue_themed_group`). A stage needs:
  - a `StageData.STAGES` entry
  - `GameEnemy.STAGE_BOSS_HP`
  - a boss pattern in `GameEnemy._boss_attack` (`match stage_idx`)
  - boss frames in `BossPainter.build_all_bosses`
  - a biome in `StarfieldBg`
  - a song in `GenesisMusic.STAGE_SONGS`, plus a `"stage_N"` slot with 5 alternatives in `music_candidates.gd` (the smoke test expects 5 per slot)
  - a `StageData.DIFFICULTY` row, its own enemies (see **Stage enemy**) and their recipes in `main._queue_themed_group`

  After stage 8, play loops with harder enemies; nothing ends the game.

**Asset generation:**

- `PixelArt` sprites are arrays of strings, one character per pixel, mapped through `PALETTE` or an optional custom palette passed to `_make_tex`. `BossPainter` draws bosses into `Image`s and registers three animation frames per boss, `boss_<theme>_0`, `_1` and `_2`.
- `EnemyArt` (`scripts/enemy_art.gd`, a `class_name` called from `PixelArt._build_all`) builds the stage enemies and their special shots, partly from strings and partly painted (`_ball`, `_disc`, `_line`), and adds a 1-px dark outline in `_finish()` so they read against busy backgrounds. Keys start with `en_`.
- **Lookups fail silently.** `PixelArt.tex("typo")` returns the `scout_space` sprite. `RetroSfx.play("typo")` does nothing. A wrong key won't produce an error, so look at the result on screen.
- `GenesisMusic._process` synthesizes every sample in GDScript on the main thread, with a buffer of only 0.14 s. Keep the per-sample path (`_synth_*_frame`, `_tick_*`) cheap. Any work added there runs 44,100 times per second.
- **Soundtrack slots and alternatives.** Music plays in 11 slots (`GenesisMusic.SLOT_KEYS`: `title`, `stage_1`–`stage_8`, `boss`, `hyperspace`). Each slot has its original track plus 5 alternatives in `scripts/music_candidates.gd`, picked in **Options → SOUNDTRACK** (`main._build_soundtrack_ui`, state `SOUNDTRACK`) and saved as `MetaSave.music_picks` (slot → index, 0 = original). `GenesisMusic.DEFAULT_PICKS` sets the shipped choice for players who haven't picked. `_resolve_song` picks the song for each slot; `preview()` / `resume_after_preview()` are for the picker.
  - An alternative is a song dictionary like `STAGE_SONGS`, with a few extras. `"style"` is the groove: 0–8 are the original stage grooves, and 9–17 add chiptune, drum & bass, outrun, orchestral, ambient, lo-fi, bossa nova, industrial and 6/8. `"bass"`, `"pad"`, `"arp"` and `"lead"` borrow any instrument voice; voices 9+ are extra instruments. `"kit"` sets the drum tuning. The voice list is at the top of `music_candidates.gd`.
  - Melodies are composed at load time from `"seed"` by `GenesisMusic.compose_melody`, unless the entry spells out `"mel_a"`/`"mel_b"`. Change the seed to get a different tune with the same arrangement.
  - Hyperspace alternatives (`"hyper"`) are 2.6 s jingles made of per-16th-step lists (`h_arp`, `h_lead`, `h_kick`, ...).
  - Every song, originals included, also gets the arrangement layers from `GenesisMusic._trigger_layers`. Those are crash cymbals at section changes, claps on the groove's backbeat, ghost 16th hats in the gaps, a snare roll into the chorus, a chorus countermelody, plus a sub-octave under the bass, extra bass gain and a punchier kick. How busy they get depends on `energy` (0 calm, 1 normal, 2 intense; defaults per groove in `GROOVE_ENERGY`). `bass_gain`, `sub_mix`, `kick_gain` and `counter` tune them per song.
  - Changing the shared voice, kit or layer code changes every track. To check a refactor is sound-neutral, render the songs before and after (fresh `GenesisMusic` with a fixed `_rng.seed`) and compare the bytes.
