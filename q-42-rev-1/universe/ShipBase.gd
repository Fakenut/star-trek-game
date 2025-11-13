# ShipBase.gd
extends CharacterBody2D
class_name ShipBase

@export_group("Ship Identity")
@export var ship_faction: int = 0  # FactionManager.FACTION.FEDERATION
@export var ship_class: String = "explorer"
@export var ship_name: String = "Unnamed Ship"
@export var is_destroyable: bool = true
@export var is_targetable: bool = true

@export_group("Ship Stats")
@export var max_health: float = 100.0
@export var max_speed: float = 200.0
@export var rotation_speed: float = 1.5

var health: float = 100.0
var current_speed: float = 0.0

# Signals
signal ship_destroyed(ship: ShipBase)
signal ship_damaged(ship: ShipBase, damage: float, source: Node)
signal ship_targeted(ship: ShipBase)
signal faction_changed(old_faction: int, new_faction: int)

func _ready():
	_initialize_ship()
	add_to_group("ships")
	print("🚀 Ship spawned: ", ship_name, " (", FactionManager.get_faction_name(ship_faction), ")")

func _initialize_ship() -> void:
	health = max_health
	
	if ship_name == "Unnamed Ship":
		ship_name = _generate_ship_name()
	
	_update_faction_visuals()

func _update_faction_visuals() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.modulate = FactionManager.get_faction_color(ship_faction)

func take_damage(amount: float, damage_source: Node = null) -> void:
	if not is_destroyable:
		return
	
	health -= amount
	ship_damaged.emit(self, amount, damage_source)
	
	print("💥 ", ship_name, " took ", amount, " damage. Health: ", health, "/", max_health)
	
	if health <= 0:
		_destroy_ship(damage_source)

func _destroy_ship(destroyer: Node = null) -> void:
	print("💀 ", ship_name, " destroyed!")
	ship_destroyed.emit(self)
	_create_destruction_effect()
	queue_free()

func _create_destruction_effect() -> void:
	var explosion = ColorRect.new()
	explosion.size = Vector2(20, 20)
	explosion.color = Color.ORANGE_RED
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	
	var timer = get_tree().create_timer(0.3)
	timer.timeout.connect(explosion.queue_free)

func get_target_type() -> String:
	return ship_class

func get_ship_faction() -> int:
	return ship_faction

func get_ship_name() -> String:
	return ship_name

func get_health() -> float:
	return health

func get_health_ratio() -> float:
	return health / max_health

func is_hostile_to(other_ship: ShipBase) -> bool:
	return not FactionManager.are_factions_allied(ship_faction, other_ship.get_ship_faction())

func set_ship_faction(new_faction: int) -> void:
	var old_faction = ship_faction
	ship_faction = new_faction
	_update_faction_visuals()
	faction_changed.emit(old_faction, new_faction)
	print("🔄 ", ship_name, " changed faction to: ", FactionManager.get_faction_name(new_faction))

func _generate_ship_name() -> String:
	var prefixes: Array[String] = []
	var names: Array[String] = []
	
	match ship_faction:
		FactionManager.FACTION.FEDERATION:
			prefixes = ["USS", "NCC"]
			names = ["Enterprise", "Voyager", "Defiant", "Reliant", "Excelsior", "Constellation"]
		FactionManager.FACTION.ROMULAN:
			prefixes = ["IRW", "RIS"]
			names = ["Vengeance", "Shadow", "D'deridex", "Valdore", "Scimitar", "Tero"]
		FactionManager.FACTION.KLINGON:
			prefixes = ["IKS", "IKV"]
			names = ["Bortas", "Gorkon", "Martok", "K'Vort", "Rotarran", "Negh'Var"]
		FactionManager.FACTION.CIVILIAN:
			prefixes = ["CS", "FV"]
			names = ["Trader", "Merchant", "Explorer", "Pioneer", "Voyager", "Wanderer"]
		_:
			prefixes = ["UNS"]
			names = ["Unknown"]
	
	return prefixes[randi() % prefixes.size()] + " " + names[randi() % names.size()]

# Movement methods
func set_speed(speed: float) -> void:
	current_speed = clamp(speed, 0, max_speed)

func rotate_ship(direction: float) -> void:
	rotation += direction * rotation_speed * get_process_delta_time()

func move_forward() -> void:
	set_speed(max_speed)

func stop() -> void:
	set_speed(0)
