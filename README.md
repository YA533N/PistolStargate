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
| Grapple | E / right mouse |
| Shoot (hold for auto-fire) | Left mouse |
| Swap weapon *(not built)* | Q / mouse wheel |
| Interact / talk / next dialogue line | F |
| Pause | Esc |
| Debug cheats (debug builds only) | F1 hurt, F2 heal, F3 add currency |

## Project structure

```
assets/        art, audio, fonts (raw files only, no scripts)
  textures/    every texture, one folder per asset (metal_044a/, laugo_alien_pistol/, ui/ ...)
  materials/   Godot materials built from those textures
  models/      characters/, environment/, weapons/
scenes/        .tscn files (Godot's equivalent of Unity prefabs)
  levels/      hub, arena
  player/  enemies/  weapons/  ui/  systems/
scripts/       .gd files, mirroring scenes/
  player/  enemies/  weapons/  ui/  systems/  levels/
docs/          MCP journal, test cases, bug log
```

Autoloads (global singletons): `GameState` (currencies and run state) and `DebugCheats`.

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
