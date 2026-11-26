# PROJECT_CONTEXT.md — Star Viper: 16-Bit Galactic Roguelite

> **Purpose:** Complete session handoff & collaboration guide for `https://github.com/mwgit993/spacegame` across **Work PC**, **Home PC**, and collaborating with **Jay (`justgetjay`)** using **Godot 4.7.2**, **Antigravity**, or **Claude**.

---

## 1. High-Level Concept & Core Loop
- **Genre:** Horizontal 16-bit Widescreen Action-Roguelite Space Shooter (*Gradius* / *R-Type* / *Mega Man* meets *BALL x PIT* XP gem leveling and *Rogue Legacy* branching skill-tree progression).
- **Engine:** **Godot Engine v4.7.2** (Standard GDScript with strict static typing, Forward+ / D3D12 on Windows, compatible with Linux/Steam Deck).
- **Zero-Fragility Procedural Pipeline:** All 16-bit ship/enemy sprites, 3-frame animated giant bosses, exotic projectiles, upgrade diagrams, 16-bit PCM SFX, and the real-time 44.1 kHz multi-instrument soundtrack are generated procedurally in GDScript (paired with a custom *Final Fantasy VI*-inspired bitmap font in `assets/fonts/`).
- **Core Roguelite Loop:**
  - **Automatic Scrap + Magnetized XP Gems (*BALL x PIT* Style):** Blowing up enemies automatically banks **Scrap** to your counter (zero coin clutter!) while bursting into tiered cyan/violet/gold **XP Gems** and occasional **Hull Heals**.
  - **Mid-Combat Level-Up Drafts:** Waves flow seamlessly without end-of-wave interruptions. Whenever your full-width glowing **XP Bar** fills up, combat briefly freezes for a **1-of-3 Powerup Draft** (`[BEAM]`, `[ADDON]`, or `[CORE]`, with optional **Rerolls**).
  - **30-Node *Rogue Legacy* Skill Tree & 7 Unlockable Ships:** Between runs, spend Scrap in the pannable **Starforge Skill Tree** to unlock permanent stat boosts, pre-installed starter addons, keystones (like *Lazarus Supernova Revive*), and **6 secret Starships** selectable in the **Fleet Ship Loadout Bay**!

---

## 2. Playable Ships, Beams & Ship Addons
### 7 Playable Starships (`SkillTreeData.SHIPS`)
1. **Star Viper Mk-I** *(Starter)* — Twin Pulse Vulcan; modular nose directly adopts any drafted Tech Beam Core.
2. **Scarab Bio-Cruiser** *(North Wing)* — Living xeno-beetle firing weaving, piercing **Corrosive Bio-Waves** (`+2 Hull` & post-boss nanite regen).
3. **Chrono Phantom** *(East Wing)* — High-speed stealth needle-wing firing **Hyper-Phase Railgun** slugs (`+20% Crit`, skewers 3 targets).
4. **Titan Gunship** *(East Wing)* — Heavy twin-prow corvette firing AoE **Cluster Flak Mortars** + built-in Flank Blasters.
5. **Cosmic Saucer X-99** *(West Wing)* — Spinning alien UFO firing wall-bouncing **Psychic Mind-Rings** + starts with **Orbital Sawblades**.
6. **Ocularis Void-Spawn** *(West Wing)* — Floating cosmic eyeball w/ writhing tentacles firing homing **Eldritch Gaze Eyeballs** that chain void lightning (`+18% XP`).
7. **S.S. Meow-zer** *(West Wing)* — Cat-eared starfighter with wagging thruster tail and **Yarn-Ball Option Orbs** that shoots leaping, meowing **Flying Space Cats** bouncing from foe to foe!
*(Note: Exotic ships NEVER lose their signature weapon when drafting Tech Beams mid-run; drafted Tech Beams mount as a co-axial bonus barrel!)*

### 5 Tech Beam Cores & 7 Visible Hull Addons
- **Beams (`[BEAM]`):** *Pierce Laser*, *Sonic Wave Beam* (double-helix), *Ricochet Prism* (wall & enemy bounce), *Tesla Arc Beam* (chain lightning), *Solar Plasma* (explosive AoE fireballs).
- **Ship Addons (`[ADDON]` — visibly rendered on/around your hull):** *Option Drone* (`x1..4`), *Orbital Blades* (`2..5` spinning saws that slice enemies & enemy bullets), *360° Roof Auto-Turret*, *Homing Wing Pods*, *Tail & Flank Guns*, *Belly Gravity Bombs*, and *Wing Nova Shock Coils*.
- **Core Systems (`[CORE]`):** *Blaster Overclock*, *Spread Matrix*, *Rapid Coil*, *Force Shield*, *Afterburner*, *Hull Overclock*.

---

## 3. Viewport, HUD & Boss Presentation (`480 × 270`)
- `y = 0..19`: **Top FF6 Status Bar** (`HP`, `Shields`, `LV`, `Stage`, `Scrap`, `Score`, `II` Pause).
- `y = 19..23`: **Full-Width Glowing XP Progress Bar**.
- `y = 24..33`: **Mega Man-Style 28-Pip Segmented Boss HP Gauge** (appears during boss fights).
- `y = 30..249`: **Clean Full-Height Flight Corridor** (`y = 258..270` scrolling stage floor deck; no bottom HUD bar!).
- **Enemy Bullet Readability:** All enemy projectiles render at `z_index = 6` with a pulsing scarlet/crimson danger glow and dark-crimson contrast rim so they pop against every background and explosion.
- **Mega Man Boss Intros & 3-Frame Animations:** All 8 giant bosses arrive via a vertical cyan-white teleport beam, strike an animated signature taunt pose, fill their 28-pip HP bar tick-by-tick (`boss_hp_tick`), animate across 3 custom pixel-art frames (`_0`, `_1`, `_2`) with weapon recoil & charge glints, and detonate in a 1.15s chain-explosion meltdown (cancelling enemy bullets on kill).
- **Split-Screen Tactical Pause Menu (`Esc` / `Start`):** Left column has compact FF6 pause buttons + active ship card; Right panel shows live **Current Ship Stats** and a 2-column pictorial grid of **Installed Weapons & Upgrades**.

---

## 4. Main File Map
| File | Role |
| :--- | :--- |
| `project.godot` | Godot 4.7 config, `480×270` integer scaling, FF6 global font, 5 autoloads |
| `scripts/skill_tree_data.gd` | 7 Playable Ship definitions + 30-node *Rogue Legacy* Starforge Skill Tree |
| `scripts/main.gd` | State machine (`TITLE`, `STATS`, `OPTIONS`, `HANGAR`, `LOADOUT`, `INTRO_WARP`, `PLAYING`, `PAUSED`, `DRAFT`, `HYPERSPACE`, `GAME_OVER_DELAY`), XP leveling, Skill Tree & Loadout UIs, split Pause menu, `--smoke-test` |
| `scripts/player.gd` | Multi-controller + Keyboard + Touch flight, 7 ship blasters, 5 Tech Beams, 7 visible Hull Addons, crits, Lazarus Revive |
| `scripts/enemy.gd` | 4 regular enemy types + 8 animated 3-phase Stage Bosses (Mega Man intro, 28-pip HP fill, adaptive plating, death meltdown) |
| `scripts/boss_painter.gd` | Procedural 3-frame native-pixel painter for all 8 giant bosses (`_0`, `_1`, `_2`) |
| `scripts/bullet.gd` | Enemy danger-glow bullets + player piercing, wave-helix, wall-ricochet, chain-lightning, AoE, and animated pouncing Space Cats |
| `scripts/pickup.gd` / `fx_layer.gd` | Magnetized tiered XP Gems & Hull Heals, lightning arcs, blast rings, screen shake, popups |
| `scripts/starfield.gd` | 8 biome parallax worlds + Hyperspace Warp tunnel |
| `scripts/autoload/meta_save.gd` | JSON save/load (`user://star_viper_save.json`) for Skill Tree ranks, unlocked ships, Scrap, stats, and options |
| `scripts/autoload/pixel_art.gd` | Caches all ship, enemy, bullet, XP gem, upgrade diagram, and badge pixel textures |
| `scripts/autoload/retro_sfx.gd` | Synthesizes 16-bit WAV SFX (`shoot`, `laser`, `zap`, `bounce`, `meow`, `xp`, `level_up`, `boss_beam`, `boss_pose`, `boss_hp_tick`, etc.) |
| `scripts/autoload/genesis_music.gd` | Real-time 44.1 kHz stereo diatonic music synthesizer (8 stage ensembles + universal Boss darksynth anthem) |

---

## 5. Collaboration Workflow (Home PC, Work PC & Jay)
1. **First-time clone on a new PC:**
   ```bash
   git clone https://github.com/mwgit993/spacegame.git
   ```
   Open Godot v4.7.2 -> **Import** -> select `spacegame/project.godot` -> press **`F5`**.
2. **Pulling latest updates before working:**
   ```bash
   git pull
   ```
3. **Running the automated headless smoke test:**
   ```bash
   godot --headless --path . --import
   godot --headless --path . --quit-after 30 -- --smoke-test
   ```
   *(Prints `STAR_VIPER_SMOKE_TEST_PASSED` with zero errors.)*
4. **Building standalone `StarViper.exe`:**
   Double-click `build_releases.bat` to package `builds/windows/StarViper.exe` + `StarViper.pck`.
