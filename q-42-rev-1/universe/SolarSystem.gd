# SolarSystem.gd
extends Node2D
class_name SolarSystem

@export_group("System Identity")
@export var system_name: String = "Unbenanntes System"
@export var system_faction: int = 4  # FactionManager.FACTION.CIVILIAN
@export var is_accessible: bool = true

@export_group("Visuals")
@export var background_texture: Texture2D
@export var background_color: Color = Color.DARK_BLUE

var ships_in_system: Array[ShipBase] = []

func _ready():
	_initialize_system()
	print("🌌 SolarSystem created: ", system_name, " (", FactionManager.get_faction_name(system_faction), ")")

func _initialize_system() -> void:
	add_to_group("solar_systems")
	_setup_background()
	_spawn_initial_content()

func _setup_background() -> void:
	#var background = ColorRect.new()
	#background.size = Vector2(2000, 2000)
	#background.color = background_color
	#background.position = Vector2(-1000, -1000)
	#add_child(background)
	#
	#var label = Label.new()
	#label.text = system_name
	#label.position = Vector2(-50, -300)
	#label.add_theme_color_override("font_color", Color.WHITE)
	#add_child(label)
	pass


func _spawn_initial_content() -> void:
	match system_faction:
		FactionManager.FACTION.FEDERATION:
			_spawn_federation_assets()
		FactionManager.FACTION.ROMULAN:
			_spawn_romulan_assets()
		FactionManager.FACTION.CIVILIAN:
			_spawn_civilian_assets()
		_:
			_spawn_neutral_assets()

func _spawn_federation_assets() -> void:
	print("   Creating Federation assets...")
	_spawn_ship("GalaxyClass", Vector2(200, 150), FactionManager.FACTION.FEDERATION)

func _spawn_romulan_assets() -> void:
	print("   Creating Romulan assets...")
	_spawn_ship("Warbird", Vector2(-200, -150), FactionManager.FACTION.ROMULAN)

func _spawn_civilian_assets() -> void:
	print("   Creating Civilian assets...")
	_spawn_ship("CivilianFreighter", Vector2(100, -100), FactionManager.FACTION.CIVILIAN)
	_spawn_ship("CivilianFreighter", Vector2(-150, 200), FactionManager.FACTION.CIVILIAN)

func _spawn_neutral_assets() -> void:
	print("   Creating Neutral assets...")
	if randf() > 0.5:
		_spawn_ship("GalaxyClass", Vector2(200, 0), FactionManager.FACTION.FEDERATION)
	else:
		_spawn_ship("Warbird", Vector2(-200, 0), FactionManager.FACTION.ROMULAN)

# In SolarSystem.gd - _spawn_ship Funktion aktualisieren:
func _spawn_ship(ship_type: String, position: Vector2, faction: int) -> void:
	var ship: Node
	
	match ship_type:
		"GalaxyClass":
			var scene = preload("res://ships/GalaxyClass.tscn")
			ship = scene.instantiate()
			ship.ship_faction = faction
		"Warbird":
			var scene = preload("res://ships/Warbird.tscn")
			ship = scene.instantiate() 
			ship.ship_faction = faction
		"CivilianFreighter":
			ship = _create_placeholder_ship(ship_type, position, faction)
		_:
			ship = _create_placeholder_ship(ship_type, position, faction)
	
	ship.global_position = position
	add_child(ship)
	ships_in_system.append(ship)
	
	print("   🚀 Spawned: ", ship.ship_name, " (", FactionManager.get_faction_name(faction), ") at ", position)
	

func _create_placeholder_ship(ship_type: String, position: Vector2, faction: int) -> ShipBase:
	var ship = ShipBase.new()
	ship.ship_name = ship_type + "_" + str(randi() % 1000)
	ship.ship_class = ship_type.to_lower()
	ship.ship_faction = faction
	ship.global_position = position
	
	var sprite = Sprite2D.new()
	var texture = _create_ship_texture(ship_type, faction)
	sprite.texture = texture
	sprite.scale = Vector2(0.5, 0.5)
	ship.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	ship.add_child(collision)
	
	return ship

func _create_ship_texture(ship_type: String, faction: int) -> Texture2D:
	var image = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	var color = FactionManager.get_faction_color(faction)
	
	match ship_type:
		"GalaxyClass":
			_draw_circle_on_image(image, Vector2(20, 20), 15, color)
		"Warbird":
			_draw_triangle_on_image(image, Vector2(20, 20), 18, color)
		_:
			_draw_circle_on_image(image, Vector2(20, 20), 12, color)
	
	return ImageTexture.create_from_image(image)

func _draw_circle_on_image(image: Image, center: Vector2, radius: int, color: Color) -> void:
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			if Vector2(x, y).distance_to(center) <= radius:
				image.set_pixel(x, y, color)

func _draw_triangle_on_image(image: Image, center: Vector2, size: int, color: Color) -> void:
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var rel_x = x - center.x
			var rel_y = y - center.y
			if abs(rel_x) <= size - abs(rel_y) * 0.7 and abs(rel_y) <= size:
				image.set_pixel(x, y, color)
