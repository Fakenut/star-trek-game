# FactionTypes.gd
extends Node
class_name FactionTypes

enum FACTION { 
	FEDERATION = 0,
	KLINGON = 1, 
	ROMULAN = 2,
	BORG = 3,
	CIVILIAN = 4
}

static func get_faction_name(faction: int) -> String:
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

static func get_faction_color(faction: int) -> Color:
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
