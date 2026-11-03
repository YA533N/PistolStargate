class_name Rarity
## Weapon rarity tiers, colour-coded like Borderlands. The rank shown on item cards is the tier number + 1.

enum Tier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, INFINITE }

const NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Infinite"]
const COLORS := [
	Color(0.92, 0.92, 0.92),
	Color(0.3, 0.95, 0.35),
	Color(0.25, 0.6, 1.0),
	Color(0.72, 0.35, 1.0),
	Color(1.0, 0.55, 0.1),
	Color(0.45, 1.0, 0.95),
]
## Relative chance of each tier in a random drop. The Infinite Pistol is never dropped.
const DROP_WEIGHTS := [40.0, 30.0, 18.0, 9.0, 3.0, 0.0]


static func color(tier: int) -> Color:
	return COLORS[clampi(tier, 0, COLORS.size() - 1)]


static func display_name(tier: int) -> String:
	return NAMES[clampi(tier, 0, NAMES.size() - 1)]


## "1" to "5", or "∞" for the Infinite tier.
static func rank_text(tier: int) -> String:
	return "∞" if tier == Tier.INFINITE else str(tier + 1)
