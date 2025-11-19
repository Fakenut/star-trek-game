# res://TestWorld.gd
extends Node2D

func _ready():
	var player_scene = preload("res://Scenes/Player/Player.tscn")
	var player = player_scene.instantiate()
	
	# Explizite Typumwandlung
	player.current_ship_data = load("res://Resources/ShipData.tres") as ShipData
	
	# Sicherheitsprüfung
	if player.current_ship_data == null:
		push_error("ShipData konnte nicht geladen werden oder hat falschen Typ!")
		return
	
	add_child(player)
	player.position = get_viewport_rect().size / 2
