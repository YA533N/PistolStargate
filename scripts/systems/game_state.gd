extends Node
## Autoload "GameState": run-wide state that survives scene changes.
## Holds the two currencies from the GDD (weapon currency and relic currency), the player's weapons
## between scenes, and tutorial progress.

signal currency_changed(weapon_currency: int, relic_currency: int)
## Every enemy death. The Infinite Pistol charges from these. Emitted by Enemy, not here.
@warning_ignore("unused_signal")
signal enemy_killed(enemy: Node)

var weapon_currency := 0
var relic_currency := 0
## The player's weapons, written by Arsenal whenever they change. Empty at the start of a run.
var loadout := {}
## The Proving Grounds (tutorial) has been beaten at least once this run.
var proving_grounds_done := false
## Where the Proving Grounds restarts after the player dies: "" (the beginning) or "boss".
var proving_grounds_checkpoint := ""


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


## A new run: no money, no weapons, tutorial not done.
func reset_run() -> void:
	weapon_currency = 0
	relic_currency = 0
	loadout = {}
	proving_grounds_done = false
	proving_grounds_checkpoint = ""
	currency_changed.emit(weapon_currency, relic_currency)
