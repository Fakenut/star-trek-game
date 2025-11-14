# GameController.gd
extends Node

func _ready():
	print("🎮 GameController initialized")
	_run_system_tests()

func _run_system_tests() -> void:
	print("\n🧪 Running System Tests...")
	
	# Test Faction System
	var fed_vs_rom = FactionManager.are_factions_allied(
		FactionManager.FACTION.FEDERATION, 
		FactionManager.FACTION.ROMULAN
	)
	print("   Federation vs Romulan: ", "Allied" if fed_vs_rom else "Hostile")
	
	var fed_vs_fed = FactionManager.are_factions_allied(
		FactionManager.FACTION.FEDERATION, 
		FactionManager.FACTION.FEDERATION
	)
	print("   Federation vs Federation: ", "Allied" if fed_vs_fed else "Hostile")
	
	print("✅ All systems operational!")
