# Performance and Optimization

Course requirement (brief §15): at least 3 performance considerations and at least 2 optimization actions.

## Considerations

| Area | Why it matters for Pistol Stargate |
|---|---|
| Textures / materials | Every model ships 4K PBR maps, but the isometric camera shows most objects at a few dozen pixels. |
| Active GameObjects / projectiles | A bullet hell puts hundreds of bullets and enemies on screen at once. |
| AI update frequency | Swarms of enemies each running pathfinding every frame will cost more than rendering. |

## Optimization actions

| # | Action | Before | After | Date |
|---|---|---|---|---|
| O1 | Downscaled oversized texture maps before import (Laugo Alien Pistol 4K → 1K, Portal Frame 4K → 2K)  | ~100 MB of source PNGs for the gun and portal | ~22 MB | 2026-11-02 |
| O2 | | | | |
