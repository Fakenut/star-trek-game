# Main.gd
extends Node2D

@export var player_ship_type: String = "GalaxyClass"
@export var player_start_position: Vector2 = Vector2(400, 300)

func _ready():
	print("🚀 Starting Alpha Quadrant...")
	_setup_starfield()
	_setup_player()
	print("✅ Ready to fly!")

func _setup_player():
	var player_scene = preload("res://player/Player.tscn")
	var player_instance = player_scene.instantiate()
	
	# Prüfe auf die neue Architektur
	if player_instance.has_method("change_ship"):
		add_child(player_instance)
		player_instance.global_position = player_start_position
		
		# Schiff basierend auf Typ hinzufügen
		var ship_scene = _get_ship_scene(player_ship_type)
		if ship_scene:
			player_instance.change_ship(ship_scene)
			print("🎮 Player with " + player_ship_type + " created at position: " + str(player_start_position))
		else:
			push_error("❌ Failed to load ship scene for type: " + player_ship_type)
	else:
		push_error("❌ Player scene doesn't support modern ship system! Missing: change_ship()")

func _get_ship_scene(ship_type: String) -> PackedScene:
	match ship_type:
		"GalaxyClass":
			return preload("res://ships/GalaxyClass.tscn")
		"Warbird":
			return preload("res://ships/Warbird.tscn")
		_:
			push_error("Unknown ship type: " + ship_type)
			return null

func _setup_starfield():
	var starfield_scene = preload("res://universe/Starfield.tscn")
	var starfield_instance = starfield_scene.instantiate()
	add_child(starfield_instance)
	print("🌟 Starfield loaded")

# Optional: Debug-Funktion um Schiffe zur Laufzeit zu wechseln
func _input(event):
	if event.is_action_pressed("debug_change_ship"):
		_cycle_to_next_ship()

func _cycle_to_next_ship():
	var ship_types = ["GalaxyClass", "IntrepidClass", "Warbird", "Defiant"]
	var current_index = ship_types.find(player_ship_type)
	var next_index = (current_index + 1) % ship_types.size()
	
	player_ship_type = ship_types[next_index]
	print("🔄 Changing to ship: " + player_ship_type)
	
	# Neues Schiff laden
	var player = get_node("Player")  # Annahme: Player heißt "Player"
	if player and player.has_method("change_ship"):
		var ship_scene = _get_ship_scene(player_ship_type)
		if ship_scene:
			player.change_ship(ship_scene)
