# Main.gd
extends Node2D

#@export var player_ship_type: String = "Warbird"
@export var player_ship_type: String = "GalaxyClass"
@export var player_start_position: Vector2 = Vector2(400, 300)

func _ready():
	print("🚀 Starting Alpha Quadrant...")
	_setup_starfield()
	_setup_player()
	print("✅ Ready to fly!")

func _setup_player():
	# Player Template laden - STELLE SICHER DASS DAS DIE RICHTIGE SCENE IST!
	var player_scene = preload("res://player/Player.tscn")
	var player_instance = player_scene.instantiate()
	
	# Prüfe ob es wirklich unser Player-Template ist
	if player_instance.has_method("set_current_ship"):
		player_instance.global_position = player_start_position
		add_child(player_instance)
		
		# Schiff basierend auf Typ hinzufügen
		var ship_scene
		match player_ship_type:
			"GalaxyClass":
				ship_scene = preload("res://ships/GalaxyClass.tscn")
			"Warbird":
				ship_scene = preload("res://ships/Warbird.tscn")
			_:
				push_error("Unknown ship type: " + player_ship_type)
				return
		
		# Schiff zum Player hinzufügen
		player_instance.set_current_ship(ship_scene, player_start_position)
		print("🎮 Player with ship created")
	else:
		push_error("❌ Loaded scene is not a Player template! It's a: ", player_instance.get_class())

func _setup_starfield():
	var starfield_scene = preload("res://universe/Starfield.tscn")
	var starfield_instance = starfield_scene.instantiate()
	add_child(starfield_instance)
	print("🌟 Starfield loaded")
