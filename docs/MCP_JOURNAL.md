# MCP / AI-Assisted Development Journal

Course requirement (brief §13): at least 4 documented AI-assisted tasks spread across development.
Copy the template for each new task. The sections marked *(team)* must be written by us, not the AI.

---

## Task 1: Project setup and foundation

- **Date:** 2026-11-02
- **Type:** Project understanding + script development
- **Tool:** Claude Code (AI coding assistant in VS Code)
- **Team member:** Mohamed Ashraf

**Task description**
Set up the Godot 4.7 project for Pistol Stargate from the GDD: folder structure, input map,
isometric camera, a player movement foundation, basic UI screens and repo housekeeping.

**Prompt / instruction used**
Gave the assistant the GDD (v0.1) and the course brief, and asked it to set up the Godot project
for the empty GitHub repo.

**Relevant output**
- `project.godot` with an input map for every action in GDD §13.1 and named physics layers.
- Folder structure following the course's suggested layout (§12).
- Player controller: camera-relative movement, jump, a 2-grid-unit dash in any direction (on ground or in air), mouse aim.
- Reusable `Health` component, `GameState` autoload (two currencies), `Portal`, isometric `CameraRig`.
- Main menu, HUD, pause menu, and a greybox hub with a jump/dash course.
- Headless smoke test checking camera angle, camera-relative movement and dash distance.

**Errors or incorrect suggestions**
- The first dash implementation ended the dash *before* `move_and_slide()` on its last frame, so every
  dash fell slightly short of 2 grid units. It was caught while writing the smoke test and fixed by
  ending the dash after the move.
- The smoke test first read the camera from the viewport, but headless mode has no current camera.
  This was a problem in the test only, not in the game.

**Testing performed**
Headless Godot run: the camera is pitched 35.26° on a 45° diagonal, W moves the player up-screen,
the dash covers 4.00 m (2 grid units × 2 m), and the dash charge comes back after the cooldown.
*(team)* Playtest in the editor and record the results in `docs/TESTING.md`.

**Student modifications** *(team)*

**Final implementation** *(team, after review)*

**What was learned** *(team)*

**Why suggestions were accepted / modified / rejected** *(team)*

---

## Task 2: Hub textures, NPC and dialogue system

- **Date:** 2026-11-02
- **Type:** Script development + debugging
- **Tool:** Claude Code (AI coding assistant in VS Code)
- **Team member:** Mohamed Ashraf

**Task description**
Put the Metal044A texture on the hub walls, add the Alien Orange Trooper model as an NPC, and add
talking to him with a dialogue box at the bottom of the screen.

**Prompt / instruction used**
"Add in the walls in the hub the texture I added to the folder and also add the alien orange trooper to
the scene and introduce talking to him where it shows a box in the bottom where he talks."

**Relevant output**
- Wall material `metal_044a.tres` (world-space tiling) on all four walls.
- Trooper imported from FBX with its PBR material assigned in the import settings, so a re-import keeps it.
- Reusable `NPC` script (talk range, "[F] Talk" prompt, faces the player, freezes player input while talking).
- Reusable `DialogueBox` UI (bottom panel, speaker name, typewriter text, F to skip/advance/close).

**Errors or incorrect suggestions**
- First wall render came out black (bug B02). Fixed with a reflection-only sky.
- The NPC played the FBX's first animation, which was a T-pose (bug B03). Found by rendering close-ups of each animation.
- The first test run failed with "Could not find type NPC": new `class_name` scripts aren't registered until Godot rescans the project. Fixed by running an import pass first.

**Testing performed**
Automated windowed run that sends real F key events: out of range does nothing; in range shows the
prompt; F opens the box and disables player input; F skips the typing; repeated F steps through all lines
and closes; input is re-enabled; trooper turns to face the player. Screenshots checked for the box layout,
walls and animation.

**Student modifications** *(team)*

**Final implementation** *(team, after review)*

**What was learned** *(team)*

**Why suggestions were accepted / modified / rejected** *(team)*

---

## Task 3: Wall fix, platform textures, gun, portal frame, poster

- **Date:** 2026-11-02
- **Type:** Debugging + project organization
- **Tool:** Claude Code (AI coding assistant in VS Code), Blender 5.2 command line
- **Team member:** Mohamed Ashraf

**Task description**
The walls didn't look like the chosen texture. Add the new platform textures, the poster, the gun, and put every
texture in `assets/textures/` so the whole team can find them in Godot. Change the trooper's opening lines.

**Relevant output**
- Root cause for the walls: Metal044A is a near-mirror silver, and the reflection sky added in Task 2 was purple,
  so the walls showed up lavender. The sky is now neutral steel grey, and the walls render silver.
- Metal062C on the steps, Metal049A on the landing pad.
- Gun converted from .blend to .glb with Blender on the command line (auto-run scripts disabled), textures downscaled, 3 materials linked.
- Portal frame imported and textured, not placed yet.
- Poster used as the main-menu title. All textures moved under `assets/textures/<asset>/`.
- Trooper now opens with alien gibberish, then "*BEEP* ...I forgot to turn on my English translator."

**Errors or incorrect suggestions**
- The Task 2 wall fix (purple sky) was incomplete: it removed the black but hid the texture's real colour. That's why the team flagged it.

**Testing performed**
Rendered the main menu, the full hub, close-ups of the walls, steps and gun, and the first dialogue line. Checked the import settings link every model material.

**Student modifications** *(team)*

**What was learned** *(team)*

**Why suggestions were accepted / modified / rejected** *(team)*

---

## Task 4: Pistol in hand, shooting, portal frame, NPC idle

- **Date:** 2026-11-02
- **Type:** Script development + debugging
- **Tool:** Claude Code (AI coding assistant in VS Code)
- **Team member:** Mohamed Ashraf

**Task description**
Put the Laugo Alien Pistol in the player's hand and make it shoot; replace the placeholder portal ring
with the portal frame model; stop the Orange Trooper animating until he's talked to.

**Relevant output**
- Reusable `Weapon` (fire rate 6/s, damage 10, bullet speed 30 m/s, Muzzle marker) and `Projectile` (ray-cast bullets that damage any `Health`).
- Pistol scene in the player's hand; hold left mouse to fire toward the cursor; disabled during dialogue.
- NPC option `animate_only_while_talking`: holds the first frame of the animation, plays during dialogue.
- Portal frame placed in the hub's ArenaPortal, keeping the existing trigger.

**Errors or incorrect suggestions**
- First bullet version used `Area3D`, which doesn't detect walls under Jolt physics (bug B04).
- The portal's emission setup made it pure white (bug B05).
- Several test-script mistakes along the way: moving the mouse in window coordinates instead of viewport coordinates, and counting render frames instead of physics frames. None of these were in the game itself.

**Testing performed**
Windowed tests: trooper still at start, animating while talking, still after; held fire on a dummy with
`Health` = 3 hits / 30 damage in 0.5 s; bullets removed on wall impact; screenshots of the gun in hand and the portal.

**Student modifications** *(team)*

**What was learned** *(team)*

**Why suggestions were accepted / modified / rejected** *(team)*

---

## Task 5: Weapons, rarity loot, Infinite Pistol, Proving Grounds tutorial and boss

- **Date:** 2026-11-02
- **Type:** Script development + asset pipeline + debugging + testing
- **Tool:** Claude Code (AI coding assistant in VS Code), Blender 5.2 command line, Python (Pillow)
- **Team member:** Mohamed Ashraf

**Task description**
Import the 12 weapons from the `weapons` folder with varying rarity; weapons on the floor shine a beam in their
rarity colour; an item card with the weapon's silhouette, rarity rank and what it does; a cheat to spawn/equip
any weapon to test it. The existing pistol becomes the Infinite Pistol: it one-shots normal enemies, which then
drop 2-3 weapons, ammo and cash, and it only recharges after kills. New start: no weapon; the Orange Trooper
teleports the player to a tutorial area, hands over the pistol, makes them shoot a chicken ("you have to be
merciless... do you understand?"), then THE FIRST DESCENDANT boss with a machine gun, in a big arena with
hide-spike traps and obstacles to jump.

**Prompt / instruction used**
The team's full feature description (weapons first, then the tutorial flow, then the arena hazards).

**Relevant output**
- Asset pipeline: Blender CLI script that bakes each gun (FBX/OBJ/glTF/.blend, some rigged) into one static mesh,
  turns the barrel to -Z, scales it to a hand-held length, decimates the heavy ones and exports a texture-less GLB;
  Python script that downscales every texture to 1K into `assets/textures/<gun>/` and writes one material per slot.
- `WeaponData` resource per gun (`resources/weapons/`), `WeaponLibrary`, `Rarity` (5 tiers + Infinite).
  Specials: poison, homing, explosions, pierce, ricochet, railgun beam, chain lightning, spin-up, shotgun spread.
- `Arsenal` on the player: 2 slots + the Infinite Pistol, ammo, Q/wheel/1-2-3 swapping, F pickup/swap,
  pistol kill-charge and miss refund, saved in `GameState` between scenes.
- `WeaponPickup` (rarity beam + ring shaders, spinning model), `LootPickup` (ammo/cash/health), `Loot` (drops,
  jackpot), HUD `WeaponCard` (silhouette rendered in a SubViewport) and `WeaponPanel`, boss health bar.
- `Enemy` base, `Chicken` (code-animated), `FirstDescendant` boss (sweep and burst attacks with wind-up),
  `TrainingDummy`, `SpikeTrap`, dialogue questions with answer buttons, `Transition` fades, F4 cheat menu.
- `proving_grounds.tscn` with the scripted tutorial and a boss checkpoint.

**Errors or incorrect suggestions**
- Five guns rendered pure white: the material generator repeated bug B05 (emission operator Add). See B07.
- The chicken and spike-trap FBX imports silently failed because new FBX files defaulted to the FBX2glTF importer (B08).
- The chicken couldn't be hit: bullets fly at hand height, above its 0.9 m model (B06). Found by the end-to-end test.
- The item card stretched to the bottom of the screen (B09). Found in a screenshot.
- Test-harness mistakes (not game bugs): compiling the test before the autoloads existed; setting the trigger
  flag directly instead of simulating the mouse button; a loop counted render frames instead of physics frames.

**Testing performed**
Two headless suites, both passing with 0 failures:
- Weapons test (30 checks): every gun damages a dummy, poison, spin-up 5 -> 18/s, chain lightning, pistol
  instakill + jackpot + miss refund + 3-kill recharge, pickup focus/swap/drop, ammo refill, spike trap damage,
  loadout saving.
- End-to-end test (21 checks): hub talk -> teleport -> pistol -> "No" re-asks -> chicken -> 3 weapons -> boss lands
  and fires -> boss killed with the dropped guns -> portal opens -> checkpoint restart.

Windowed screenshots were also checked for the beams, item card, HUD, boss, spike traps and cheat menu.

**Student modifications** *(team)*

**What was learned** *(team)*

**Why suggestions were accepted / modified / rejected** *(team)*

---

## Task template

- **Date / Type / Tool / Team member:**

**Task description**

**Prompt / instruction used**

**Relevant output**

**Student modifications**

**Testing performed**

**Errors or incorrect suggestions**

**Final implementation**

**What was learned**

**Why suggestions were accepted / modified / rejected**
