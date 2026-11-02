extends Node
## Autoload "GameState": run-wide state that survives scene changes.
## Holds the two currencies from the GDD (weapon currency and relic currency).

signal currency_changed(weapon_currency: int, relic_currency: int)

var weapon_currency := 0
var relic_currency := 0


func add_currency(weapon: int, relic: int) -> void:
	weapon_currency += weapon
	relic_currency += relic
	currency_changed.emit(weapon_currency, relic_currency)


func can_afford(weapon_cost: int, relic_cost: int) -> bool:
	return weapon_currency >= weapon_cost and relic_currency >= relic_cost


## Returns false and spends nothing if the player can't afford it.
func spend(weapon_cost: int, relic_cost: int) -> bool:
	if not can_afford(weapon_cost, relic_cost):
		return false
	add_currency(-weapon_cost, -relic_cost)
	return true


func reset_run() -> void:
	weapon_currency = 0
	relic_currency = 0
	currency_changed.emit(weapon_currency, relic_currency)
