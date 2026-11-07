# Testing and Bug Log

Course requirement (brief §14): at least 10 test cases and at least 3 bugs (at least one investigated with AI/MCP help).

## Test cases

| ID | Feature | Action / Input | Expected result | Actual result | Status |
|---|---|---|---|---|---|
| T01 | Player movement | Hold W in the hub | Player moves up-screen at about 8 m/s | | |
| T02 | Jump | Press Space on the floor | Player jumps about 1.3 m and lands on the 1 m step | | |
| T03 | Dash | Press Shift while moving | Player dashes exactly 2 grid units (4 m) | | |
| T04 | Dash cooldown | Press Shift twice quickly | Second dash only happens after the 0.6 s recharge; HUD bar refills | | |
| T05 | Air dash | Jump, then dash across the gap | Player clears the 7 m gap that a jump alone can't | | |
| T06 | Aim | Move the mouse around the player | Player and gun turn toward the cursor | | |
| T07 | Pause menu | Press Esc | Game freezes and the pause menu appears; Esc or Resume continues | | |
| T08 | Main menu | Launch, then click Play | Hub loads with the HUD shown and no weapon in hand (weapon panel says UNARMED) | | |
| T09 | Health / HUD | Press F1 (debug) | The health bar drains by 10 (see T44) | | |
| T10 | Death | Press F1 ten times | Scene restarts with full HP | | |
| T11 | Portal (locked) | Walk into the ARENA portal | "The arena isn't built yet." message appears | | |
| T12 | Out of bounds | Fall below y = -20 | Player respawns at the start | | |
| T13 | NPC prompt | Walk within 3 m of Pickle-yo (the alien) | "[E] Talk" appears above him; disappears when walking away | | |
| T14 | Dialogue open | Press E near the trooper | Box opens at the bottom, text types out, player can't move, trooper turns to face the player | | |
| T15 | Dialogue advance | Press E while text is typing, then again | First press shows the whole line; second goes to the next line; last line says "[E] close" | | |
| T16 | Dialogue close | Press E on the last line | Box closes and the player can move again | | |
| T17 | Dialogue out of range | Press E far from the trooper | Nothing happens | | |
| T18 | Shooting | Equip the PX-9 (F4 menu) and hold left mouse | Fires 7 bullets per second toward the cursor; ammo counts down | | |
| T19 | Bullet impact | Shoot a wall or crate | Bullet disappears on contact, never passes through | | |
| T20 | Bullet damage | Spawn a training dummy (F6) and shoot it | Damage numbers pop up; it heals 3 s after the last hit | | |
| T21 | No shooting while talking | Hold left mouse during dialogue | No bullets fire | | |
| T22 | NPC idle | Load the hub, then talk to the trooper | Stands still in his stance; animates only while the box is open; still again after | | |
| T23 | Rarity beams | F4 -> Spawn ALL weapons around me | Each weapon floats in a beam + ring of its rarity colour (white, green, blue, purple, orange, cyan) | | |
| T24 | Item card | Walk next to a weapon on the floor | Card shows its silhouette, rarity + RANK number, damage, stats with up/down arrows vs your gun, effect and flavour text | | |
| T25 | Pick up / swap | With 2 weapons held, press E on a third | It replaces the active gun; the old one drops on the floor with its ammo | | |
| T26 | Weapon switching | Press Q, scroll the wheel, press 1/2/3 | Active weapon changes; HUD panel and gun model update | | |
| T27 | Out of ammo | Empty a gun, then click | "out of ammo" message; walking over an ammo pickup refills 35% | | |
| T28 | Weapon effects | Try each gun on 2 dummies (F4) | Poison ticks green, Orbit Seeker homes, Plasma/Toy explode, sniper and railgun pierce, Collector/Toy ricochet, Arc Charger chains, Ares spins up | | |
| T29 | Infinite Pistol instakill | Shoot a dummy or chicken with a loaded Infinite Pistol | INSTAKILL; it drops 2-3 weapons, ammo, cash and health ("JACKPOT!") | | |
| T30 | Infinite Pistol miss | Fire the loaded pistol at nothing | "Missed! The bullet returns to the chamber" and it's loaded again | | |
| T31 | Infinite Pistol recharge | With the pistol empty, kill 7 enemies with another gun | Each kill fills the next coin (top right) with gold; on the 7th all coins spin like a slot machine and stop on gold, "INFINITE PISTOL CHARGED!" | | |
| T32 | Teleport | Finish talking to Pickle-yo in the hub | Orange flash, the Proving Grounds loads | | |
| T33 | Question | Answer "No" to "Do you understand?" | "Wrong answer" and he asks again; "Yes" continues | | |
| T34 | Chicken | Shoot the chicken with the Infinite Pistol | It dies and spills Neon Hornet, Plasma Popper and Longshot X-80 | | |
| T35 | Boss | Grab the guns and fight THE FIRST DESCENDANT | Drops from the sky, red "!" wind-up, then sweeping sprays and aimed bursts; crates and low walls block his bullets; boss bar at the top | | |
| T36 | Spike trap | Stand on a spike plate | Red flash, spikes come up ~0.5 s later: 15 damage and a pop upwards; moving off in time avoids it | | |
| T37 | Low walls | Jump over a grey low wall | Clears it; the orange crates are too tall to jump | | |
| T38 | Boss checkpoint | Die during the boss fight | Restart at the boss with an empty pistol and the chicken's 3 weapons on the floor | | |
| T39 | Exit portal | Kill the boss | Trooper returns, portal opens, it leads back to the hub | | |
| T40 | Cheat menu | Press F4, click Equip / Spawn | Game pauses; weapon goes into your hands / onto the floor; F4 or Esc closes | | |
| T41 | Title screen | Start the game, press any key / click / pad button | Title art with a pulsing PRESS ANY BUTTON; the press brings up PLAY and QUIT at the bottom right | | |
| T42 | Menu rows | Hover or use up/down, then click or press Enter | The selected row gets a full-width cyan bar with dark text; the option runs straight away | | |
| T43 | Pause menu | Press Esc in a level | Title art with PAUSED and RESUME / RESTART / MAIN MENU / QUIT in the same style; opens on RESUME; Esc closes | | |
| T44 | Health bar | Take damage (e.g. a spike trap), then heal (F2) | No HP number: three red segments, each a third of max health, drain from the right; the part just lost stays pale for a moment, then drains | | |
| T45 | Dash bar | Dash | The green block empties, then fills back up from the bottom like water (waves and a light foam line), and flashes when the dash is ready | | |
| T46 | Aim lines up | On flat ground, point the crosshair at something and shoot | The bullet flies flat at gun height and passes right under the centre of the crosshair | | |
| T47 | Shoot down | Swing on a grapple point (or jump) and shoot at an enemy or dummy below (F6 spawns one) | The shot angles down from the gun to the spot under the crosshair and hits the target; on the floor, shots stay flat | | |

## Bugs

| ID | Description | Severity | Cause | Fix | Verification | AI-assisted? |
|---|---|---|---|---|---|---|
| B01 | Dash fell slightly short of 2 grid units | Low | `_end_dash()` overwrote the velocity before `move_and_slide()` on the dash's last frame | End the dash after the move | Headless test: dash = 4.00 m | Yes (Task 1) |
| B02 | Metal walls rendered pure black | Medium | Fully metallic materials mostly show reflections, and the hub environment was a flat dark colour with nothing to reflect | Added a dim procedural sky used only for reflections (`reflected_light_source = Sky`); background stays the dark colour. Brightened the sky's ground half because vertical faces seen from above reflect downward | Screenshot render: walls no longer black, but tinted lavender by the purple sky. Revised in Task 3: sky changed to neutral steel grey so the walls show Metal044A's real silver | Yes (Tasks 2, 3) |
| B03 | Orange Trooper stood in a T-pose | Medium | The FBX has two animations; the NPC played the first one, `Take 001`, which is just the bind pose | Set the NPC's `idle_animation` to `mixamo_com` (the fist-fight loop) | Close-up renders at 0.5 s / 1.6 s / 2.8 s show the fighting stance moving | Yes (Task 2) |
| B04 | Bullets flew through walls and crates | High | Godot 4.7 uses Jolt physics, where an `Area3D` doesn't detect static bodies unless a project setting is on; the first bullets were `Area3D`s | Bullets now ray-cast along each frame's movement (`PhysicsRayQueryParameters3D`), which also stops fast bullets skipping through thin objects | Test: 0.5 s of fire on a dummy = 3 hits, 30 damage; a wall shot 21 m away is removed after 0.65 s (expected 0.7 s at 30 m/s) | Yes (Task 4) |
| B05 | Portal frame rendered as a solid white glow | Medium | `StandardMaterial3D.emission_operator` defaults to Add, so white emission colour + an almost-black emission texture = white everywhere | Set `emission_operator = Multiply` so only the texture's glowing parts emit | Renders with emission off / on compared; stone arch and inlays now visible | Yes (Task 4) |
| B06 | The tutorial chicken couldn't be shot | High | Bullets fly level at hand height (~1.2 m); the chicken model is only 0.9 m tall, so every shot passed over it | Chicken hitbox made 1.7 m tall (bigger than the model, as is common in top-down shooters) | End-to-end test: Infinite Pistol kills the chicken, which drops 3 weapons | Yes (Task 5, found by the automated test) |
| B07 | Five imported guns rendered solid white | Medium | The script that generated the weapon materials repeated B05: emission texture with the default Add operator | Generator and materials set `emission_operator = Multiply` | Contact-sheet render of all 13 guns | Yes (Task 5) |
| B08 | Chicken and spike trap models failed to load | High | New FBX files defaulted to the FBX2glTF importer, which isn't installed; the import was marked invalid with no visible error | Set `fbx/importer=0` (Godot's built-in ufbx) in their import settings | Both load; render shows the chicken and the spike animation | Yes (Task 5) |
| B09 | Weapon item card stretched to the bottom of the screen | Low | Word-wrapped labels inside the card were measured at zero width, which made them very tall | Gave the wrapped labels a fixed width and shrink the card after each update | Screenshot: card fits its text | Yes (Task 5) |
| B10 | The First Descendant's bullets flew over the low walls | Medium | His bullets flew level at 1.0 m; the low walls are 0.8 m, so they gave no cover | Bullets now leave the gun's muzzle and dip at 45° to 0.5 m, then fly level: low walls and crates block them, and a jump still clears them | Test with the boss pinned in place, two attack cycles per case: 0 hits behind low wall 1, low wall 3 and a crate; screenshot shows bullets stopping at the wall | Yes (reported by a team member) |
| B11 | The First Descendant's aimed bursts mostly missed a player standing still | Medium | He aimed from the centre of his body, but his gun is held 0.6 m to the side, so bullets flew parallel past the player's shoulder | Aim from the muzzle (from the body if the player is closer than the gun's tip) | Same test, player in the open: 12 hits in 44 bullets, up from 4 in 43 | Yes (found while testing B10) |
| B12 | Closing the F4 cheat menu with Esc left the game looking frozen | High | The level's pause menu also listens for Esc and received it first: it unpaused the game but left the cheat menu on screen, and the next Esc opened the pause menu hidden behind the cheat panel | The cheat menu now takes Esc before the pause menu does (`_input`), and F4 won't open it over the pause menu | Test in the hub and Proving Grounds: open, toggle Infinite Health (was "God mode"), Esc closes and unpauses, next Esc opens the pause menu, F4 does nothing while paused; every cheat button pressed with no errors | Yes (reported by a team member) |
