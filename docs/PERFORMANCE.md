# Performance and Optimization

Course requirement (brief §15): at least 3 performance considerations and at least 2 optimization actions.

## Considerations

| Area | Why it matters for Pistol Stargate |
|---|---|
| Textures / materials | Every model ships 4K PBR maps, but the isometric camera shows most objects at a few dozen pixels. |
| Active GameObjects / projectiles | A bullet hell puts hundreds of bullets and enemies on screen at once. |
| AI update frequency | Swarms of enemies each running pathfinding every frame will cost more than rendering. |
| Polygon count | Store-bought weapon models range up to 339k triangles, but a gun is ~40 px long on screen, and several lie on the floor at once. |

## Optimization actions

| # | Action | Before | After | Date |
|---|---|---|---|---|
| O1 | Downscaled oversized texture maps before import (Laugo Alien Pistol 4K → 1K, Portal Frame 4K → 2K)  | ~100 MB of source PNGs for the gun and portal | ~22 MB | 2026-11-02 |
| O1b | Same downscale for the 12 new weapons, chicken and boss (all maps to 1K, JPG where no alpha is needed) | ~880 MB of source textures | ~25 MB in the project | 2026-11-02 |
| O2 | Decimated the heaviest weapon models in Blender before import (Ares LMG, PX rifle, Capper, plasma gun) | 339k / 130k / 31k / 29k triangles | 27k / 16k / 12k / 15k | 2026-11-02 |
| O3 | Bullets are plain nodes that ray-cast each frame (no physics bodies) and share one cached material per colour, so hundreds of bullets don't create hundreds of materials | one material + one physics area per bullet (first version) | one ray query per bullet per frame; ~1 material per gun colour | 2026-11-02 |
