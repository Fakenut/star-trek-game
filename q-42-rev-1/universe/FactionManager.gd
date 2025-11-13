# FactionManager.gd
extends Node

# Fraktionen Definition (direkt hier, da Autoload)
enum FACTION { 
	FEDERATION = 0,
	KLINGON = 1, 
	ROMULAN = 2,
	BORG = 3,
	CIVILIAN = 4
}

# Beziehungsmatrix
var _faction_relations: Dictionary = {}

func _ready():
	_initialize_relations()
	print("🎯 FactionManager initialized")

func _initialize_relations() -> void:
	_faction_relations = {
		FACTION.FEDERATION: {
			FACTION.FEDERATION: true,
			FACTION.KLINGON: false,
			FACTION.ROMULAN: false,
			FACTION.BORG: false,
			FACTION.CIVILIAN: true
		},
		FACTION.KLINGON: {
			FACTION.FEDERATION: false,
			FACTION.KLINGON: true,
			FACTION.ROMULAN: false,
			FACTION.BORG: false,
			FACTION.CIVILIAN: false
		},
		FACTION.ROMULAN: {
			FACTION.FEDERATION: false,
			FACTION.KLINGON: false,
			FACTION.ROMULAN: true,
			FACTION.BORG: false,
			FACTION.CIVILIAN: false
		},
		FACTION.BORG: {
			FACTION.FEDERATION: false,
			FACTION.KLINGON: false,
			FACTION.ROMULAN: false,
			FACTION.BORG: true,
			FACTION.CIVILIAN: false
		},
		FACTION.CIVILIAN: {
			FACTION.FEDERATION: true,
			FACTION.KLINGON: false,
			FACTION.ROMULAN: false,
			FACTION.BORG: false,
			FACTION.CIVILIAN: true
		}
	}
	print("📊 Faction relations loaded")

# Public API
func are_factions_allied(faction_a: int, faction_b: int) -> bool:
	if faction_a in _faction_relations and faction_b in _faction_relations[faction_a]:
		return _faction_relations[faction_a][faction_b]
	return false

func set_faction_relation(faction_a: int, faction_b: int, allied: bool) -> void:
	if faction_a in _faction_relations:
		_faction_relations[faction_a][faction_b] = allied
	if faction_b in _faction_relations:
		_faction_relations[faction_b][faction_a] = allied
	
	print("🔄 Faction relations updated: ", 
		  get_faction_name(faction_a), " <-> ", 
		  get_faction_name(faction_b), " = ", allied)

# Utility functions
func get_faction_name(faction: int) -> String:
	match faction:
		FACTION.FEDERATION:
			return "FEDERATION"
		FACTION.KLINGON:
			return "KLINGON"
		FACTION.ROMULAN:
			return "ROMULAN"
		FACTION.BORG:
			return "BORG"
		FACTION.CIVILIAN:
			return "CIVILIAN"
		_:
			return "UNKNOWN"

func get_faction_color(faction: int) -> Color:
	match faction:
		FACTION.FEDERATION:
			return Color.STEEL_BLUE
		FACTION.ROMULAN:
			return Color.DARK_GREEN
		FACTION.KLINGON:
			return Color.DARK_RED
		FACTION.BORG:
			return Color.PURPLE
		FACTION.CIVILIAN:
			return Color.LIGHT_GRAY
		_:
			return Color.WHITE
