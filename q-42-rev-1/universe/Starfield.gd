# Starfield.gd
extends Node2D

@export_group("Starfield Settings") 
@export var star_count: int = 500
@export var area_size: Vector2 = Vector2(4000, 4000)
@export var min_star_size: float = 0.5
@export var max_star_size: float = 2.5

var stars = []
var player_ship: Node2D


func _ready():
	z_index = -10  # Sterne kommen hinter alle anderen Nodes
	generate_stars()
	print("🌟 Starfield: Generated ", stars.size(), " stars (Z-Index: ", z_index, ")")
	set_process(true)


func generate_stars():
	stars.clear()
	for i in range(star_count):
		stars.append({
			"position": Vector2(
				randf_range(-area_size.x/2, area_size.x/2),
				randf_range(-area_size.y/2, area_size.y/2)
			),
			"size": randf_range(min_star_size, max_star_size),
			"brightness": randf_range(0.4, 1.0)
		})

func _process(delta):
	# Immer nach Player suchen bis wir ihn finden
	if not player_ship or not is_instance_valid(player_ship):
		find_player()
	
	queue_redraw()

func find_player():
	# Einfache Suche: Nimm das erste Schiff mit Camera2D
	var nodes = get_tree().get_nodes_in_group("ships")
	for node in nodes:
		if node.has_node("Camera2D"):
			player_ship = node
			print("🎯 Starfield: Found player: ", player_ship.name)
			return
	
	# Alternative: Suche nach CharacterBody2D mit Camera2D
	for node in get_tree().get_nodes_in_group("ships"):
		if node is CharacterBody2D and node.has_node("Camera2D"):
			player_ship = node
			print("🎯 Starfield: Found CharacterBody2D player: ", player_ship.name)
			return

func _draw():
	if not player_ship or not is_instance_valid(player_ship):
		# Zeichne Sterne an festen Positionen (Fallback)
		for star in stars:
			var color = Color(star.brightness, star.brightness, star.brightness)
			draw_rect(Rect2(star.position, Vector2(star.size, star.size)), color)
		return
	
	# Hole die Camera vom Player
	var camera = player_ship.get_node("Camera2D")
	if not camera:
		return
		
	var camera_pos = camera.global_position
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Zeichne Sterne relativ zur Camera
	for star in stars:
		var screen_pos = star.position - camera_pos + viewport_size / 2
		
		# Prüfe ob Stern im erweiterten Sichtbereich ist
		if (screen_pos.x >= -200 && screen_pos.x <= viewport_size.x + 200 && 
			screen_pos.y >= -200 && screen_pos.y <= viewport_size.y + 200):
			
			var color = Color(star.brightness, star.brightness, star.brightness)
			var size = star.size
			draw_rect(Rect2(screen_pos - Vector2(size/2, size/2), Vector2(size, size)), color)

# Debug-Funktion
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		print("🌟 Starfield Debug:")
		print("  Stars: ", stars.size())
		print("  Player: ", player_ship.name if player_ship else "None")
		print("  Camera: ", player_ship.get_node("Camera2D").name if player_ship and player_ship.has_node("Camera2D") else "None")
