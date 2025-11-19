# res://Scripts/Modules/ShipManager.gd
class_name ShipManager
extends Node

# Exportierte Variablen
@export var ship_scene : PackedScene : set = _set_ship_scene
@export var current_ship_data : ShipData : set = _set_ship_data

# Referenzen
var player: Node2D
var ship_container: Node2D

# Intern
var ship: Node2D

func initialize(player_ref: Node2D, container_path: String) -> void:
	player = player_ref
	ship_container = player.get_node(container_path)
	
	if not ship_container:
		push_error("ShipContainer nicht gefunden: " + container_path)

func _set_ship_scene(new_scene: PackedScene) -> void:
	ship_scene = new_scene
	if ship_scene and not current_ship_data:
		# Erstelle automatisch eine basic ShipData
		current_ship_data = ShipData.new()
		current_ship_data.ship_scene = ship_scene
		current_ship_data.ship_name = ship_scene.resource_path.get_file()
		apply_ship_data()
	
	if ship_container and not Engine.is_editor_hint():
		spawn_ship()

func _set_ship_data(data: ShipData) -> void:
	current_ship_data = data
	if current_ship_data and ship_container and not Engine.is_editor_hint():
		apply_ship_data()
		spawn_ship()

func apply_ship_data() -> void:
	if not current_ship_data: 
		return
	
	# Werte an Player weitergeben
	if player.has_method("update_movement_stats"):
		player.update_movement_stats(
			current_ship_data.max_speed,
			current_ship_data.rotation_speed,
			current_ship_data.acceleration,
			current_ship_data.deceleration,
			current_ship_data.drift_factor
		)
	
	print("SHIP DATA APPLIED → ", current_ship_data.ship_name)

func spawn_ship() -> void:
	if not ship_container:
		push_error("ShipContainer ist null! Kann Schiff nicht spawnen.")
		return
	
	# Altes Schiff entfernen
	if ship:
		ship.queue_free()
		ship = null
	
	var scene_to_spawn = null
	if current_ship_data and current_ship_data.ship_scene:
		scene_to_spawn = current_ship_data.ship_scene
	elif ship_scene:
		scene_to_spawn = ship_scene
	
	if scene_to_spawn:
		ship = scene_to_spawn.instantiate()
		ship_container.add_child(ship)
		ship.position = Vector2.ZERO
		print("Schiff gespawnt: ", scene_to_spawn.resource_path.get_file())
	else:
		_create_placeholder_ship()

func _create_placeholder_ship() -> void:
	if not ship_container:
		return
		
	var p = Node2D.new()
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(0,-25), Vector2(-15,15), Vector2(0,8), Vector2(15,15)])
	poly.color = Color.CYAN
	p.add_child(poly)
	ship_container.add_child(p)
	ship = p
	print("Placeholder Schiff erstellt")

func change_ship(new_data: ShipData) -> void:
	current_ship_data = new_data
	apply_ship_data()
	spawn_ship()

func get_current_ship() -> Node2D:
	return ship
