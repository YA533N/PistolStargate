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
| T08 | Main menu | Launch, then click Play | Hub loads with the HUD shown | | |
| T09 | Health / HUD | Press F1 (debug) | HP bar and label drop by 10 | | |
| T10 | Death | Press F1 ten times | Scene restarts with full HP | | |
| T11 | Portal (locked) | Walk into the ARENA portal | "The arena isn't built yet." message appears | | |
| T12 | Out of bounds | Fall below y = -20 | Player respawns at the start | | |
| T13 | NPC prompt | Walk within 3 m of the Orange Trooper | "[F] Talk" appears above him; disappears when walking away | | |
| T14 | Dialogue open | Press F near the trooper | Box opens at the bottom, text types out, player can't move, trooper turns to face the player | | |
| T15 | Dialogue advance | Press F while text is typing, then again | First press shows the whole line; second goes to the next line; last line says "[F] close" | | |
| T16 | Dialogue close | Press F on the last line | Box closes and the player can move again | | |
| T17 | Dialogue out of range | Press F far from the trooper | Nothing happens | | |
| T18 | Shooting | Hold left mouse | Pistol fires 6 bullets per second toward the cursor | | |
| T19 | Bullet impact | Shoot a wall or crate | Bullet disappears on contact, never passes through | | |
| T20 | Bullet damage | Shoot something with a Health component | Loses 10 HP per hit | | |
| T21 | No shooting while talking | Hold left mouse during dialogue | No bullets fire | | |
| T22 | NPC idle | Load the hub, then talk to the trooper | Stands still in his stance; animates only while the box is open; still again after | | |

## Bugs

| ID | Description | Severity | Cause | Fix | Verification | AI-assisted? |
|---|---|---|---|---|---|---|
| B01 | Dash fell slightly short of 2 grid units | Low | `_end_dash()` overwrote the velocity before `move_and_slide()` on the dash's last frame | End the dash after the move | Headless test: dash = 4.00 m | Yes (Task 1) |
| B02 | Metal walls rendered pure black | Medium | Fully metallic materials mostly show reflections, and the hub environment was a flat dark colour with nothing to reflect | Added a dim procedural sky used only for reflections (`reflected_light_source = Sky`); background stays the dark colour. Brightened the sky's ground half because vertical faces seen from above reflect downward | Screenshot render: walls no longer black, but tinted lavender by the purple sky. Revised in Task 3: sky changed to neutral steel grey so the walls show Metal044A's real silver | Yes (Tasks 2, 3) |
| B03 | Orange Trooper stood in a T-pose | Medium | The FBX has two animations; the NPC played the first one, `Take 001`, which is just the bind pose | Set the NPC's `idle_animation` to `mixamo_com` (the fist-fight loop) | Close-up renders at 0.5 s / 1.6 s / 2.8 s show the fighting stance moving | Yes (Task 2) |
| B04 | Bullets flew through walls and crates | High | Godot 4.7 uses Jolt physics, where an `Area3D` doesn't detect static bodies unless a project setting is on; the first bullets were `Area3D`s | Bullets now ray-cast along each frame's movement (`PhysicsRayQueryParameters3D`), which also stops fast bullets skipping through thin objects | Test: 0.5 s of fire on a dummy = 3 hits, 30 damage; a wall shot 21 m away is removed after 0.65 s (expected 0.7 s at 30 m/s) | Yes (Task 4) |
| B05 | Portal frame rendered as a solid white glow | Medium | `StandardMaterial3D.emission_operator` defaults to Add, so white emission colour + an almost-black emission texture = white everywhere | Set `emission_operator = Multiply` so only the texture's glowing parts emit | Renders with emission off / on compared; stone arch and inlays now visible | Yes (Task 4) |
