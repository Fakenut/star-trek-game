# StarMap.gd
extends Node2D
class_name StarMap

@export var current_sector: String = "Sector_001"
var systems: Dictionary = {}  # system_name: SolarSystem

func _ready():
	load_sector(current_sector)

func load_sector(sector_name: String):
	# Alte Systeme entfernen
	for child in get_children():
		if child is SolarSystem:
			child.queue_free()
	
	# Neue Systeme laden basierend auf Sektor
	match sector_name:
		"Sector_001":
			spawn_system("SolSystem", Vector2(0, 0), FactionManager.FACTION.FEDERATION)
			spawn_system("VulcanSystem", Vector2(300, 200), FactionManager.FACTION.FEDERATION)
			spawn_system("AndoriaSystem", Vector2(-200, 300), FactionManager.FACTION.FEDERATION)
		"Sector_002":
			spawn_system("RomulusSystem", Vector2(0, 0), FactionManager.FACTION.ROMULAN)
			spawn_system("RemusSystem", Vector2(150, -150), FactionManager.FACTION.ROMULAN)

func spawn_system(system_name: String, position: Vector2, faction: FactionManager.FACTION):
	var system_scene = preload("res://systems/SolarSystem.tscn").instantiate()
	system_scene.system_name = system_name
	system_scene.global_position = position
	system_scene.system_faction = faction
	add_child(system_scene)
	
	systems[system_name] = system_scene

func travel_to_system(system_name: String):
	if system_name in systems:
		GameManager.enter_solar_system(system_name)
		systems[system_name].enter_system(GameManager.player_ship)
