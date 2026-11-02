class_name Grid
## World measurements. The GDD gives distances in grid units; this converts them to metres.

## Metres per grid unit. Changing this one value rescales every grid-based distance.
const UNIT := 2.0


static func to_world(grid_units: float) -> float:
	return grid_units * UNIT
