# Pistol Stargate

Isometric bullet hell looter shooter set in space. DMET 909 final team project.

Team: Yaseen Gadalla, Mohamed Ashraf, Moataz Hegazi

## Getting started

1. Install **Godot 4.7** (standard or .NET build both work, since the project is GDScript only).
2. Clone the repo, open Godot, choose **Import**, and pick `project.godot`.
3. Press **F5** to run. The game starts at the main menu.

### VS Code (godot-tools extension)

- Install the recommended extension `geequlim.godot-tools` (VS Code prompts you to).
- Create `.vscode/settings.json` (it's gitignored, because each teammate's path differs):
  ```json
  { "godotTools.editorPath.godot4": "C:\\path\\to\\Godot_v4.7.2-stable_mono_win64.exe" }
  ```
- In Godot: **Editor > Editor Settings > Text Editor > External**: turn on *Use External Editor*, set
  *Exec Path* to `Code.exe`, and set *Exec Flags* to `{project} --goto {file}:{line}:{col}`.
- Keep the Godot editor open while coding. godot-tools talks to its language server for autocomplete.
- Run and debug from VS Code with the **Launch Pistol Stargate** configuration.

## Controls

| Action | Input |
|---|---|
| Move | WASD / arrow keys |
| Aim | Mouse |
| Jump | Space |
| Dash | Shift |
| Slide | Ctrl / C |
| Grapple | Right mouse |
| Shoot (semi-auto: click, automatic: hold) | Left mouse |
| Swap weapon | Q / mouse wheel |
| Select weapon slot | 1 / 2 / 3 |
| Talk to NPCs / next dialogue line | E |
| Pick up weapon | E |
| Answer a dialogue question | Click, or 1 / 2 |
| Pause | Esc |
| Debug cheats (debug builds only) | F1 hurt, F2 heal, F3 add currency, **F4 weapon test menu**, F5 random weapon, F6 training dummy, F7 give/charge Infinite Pistol, F8 refill ammo |

## Weapons and loot

- Weapons are `WeaponData` resources in `resources/weapons/`, listed in `scripts/weapons/weapon_library.gd`.
  To add one: import the model, make a `.tres` (copy an existing one), and add it to `WeaponLibrary.ALL`.
- Rarity tiers (Borderlands colours): Common (white), Uncommon (green), Rare (blue), Epic (purple),
  Legendary (orange), plus the special Infinite tier. Weapons on the floor glow with a beam in their rarity
  colour, and walking up to one shows an item card (silhouette, rank, damage, stats vs your gun, effect).
- The player holds 2 weapons plus the **Infinite Pistol**. It one-shots any normal enemy, which then drops
  2-3 weapons, ammo and cash. It recharges after 7 kills with other guns, and a missed shot returns to the chamber.
- **F4 opens the weapon test menu** (debug builds): equip any weapon or spawn it on the floor, spawn a
  training dummy, the chicken or the boss, refill ammo, charge the pistol, drop a jackpot, Infinite Health (take no damage).

## Story flow so far

Title screen (press any button) → Play → hub (no weapon) → talk to Pickle-yo (the alien) → he teleports you to the **Proving Grounds**
(`scenes/levels/proving_grounds.tscn`) → he gives you the Infinite Pistol → shoot the chicken → grab its
weapons → fight THE FIRST DESCENDANT among spike traps and low walls → portal back to the hub.
Dying in the boss fight restarts at the boss.

## Project structure

```
assets/        art, audio, fonts (raw files only, no scripts)
  textures/    every texture, one folder per asset (metal_044a/, railgun/, chicken/, ui/ ...)
  materials/   Godot materials built from those textures
  models/      characters/, environment/, weapons/
resources/     data files: weapons/ (one WeaponData .tres per gun)
shaders/       rarity beam and ring shaders for weapons on the floor
scenes/        .tscn files (Godot's equivalent of Unity prefabs)
  levels/      hub, proving_grounds, props/ (spike trap)
  player/  enemies/  pickups/  ui/  systems/
scripts/       .gd files, mirroring scenes/
  player/  enemies/  weapons/  pickups/  ui/  systems/  levels/
docs/          MCP journal, test cases, bug log
```

Autoloads (global singletons): `GameState` (currencies, the player's weapons between scenes, tutorial progress),
`DebugCheats` (cheat keys and the F4 menu) and `Transition` (screen fades between scenes).

Physics layers: 1 world, 2 player, 3 enemies, 4 player projectiles, 5 enemy projectiles, 6 pickups.

## Conventions

- Files and folders use `snake_case` (`camera_rig.gd`). Nodes and `class_name` use `PascalCase`.
- Distances from the GDD are in **grid units**. Convert them with `Grid.to_world()`
  (1 grid unit = 2 m, set in `scripts/systems/grid.gd`).
- Reusable pieces are their own scene and script (for example `Health` goes on the player and every enemy).
- Mark GDD values that aren't final as `placeholder` in comments.

## Git workflow

- Don't commit `.godot/`. Do commit `.import` and `.uid` files, because Godot needs them to keep references intact.
- Work on a branch per feature (`feature/weapon-switching`) and merge to `main` through a PR.
- Two people editing the same `.tscn` at once causes painful merges, so say who owns which scene.
