# scripts/ships/ShipTemplate.gd
extends Node2D
class_name ShipTemplate

# BASIS EXPORT VARIABLEN - werden von allen Schiffen geerbt
@export var ship_name: String = "Unknown Ship"
@export var max_health: float = 100.0
@export var weapon_configs: Array[WeaponConfig]

# MOVEMENT SETTINGS - Standardwerte
@export_group("Movement Settings")
@export var max_speed: float = 300.0
@export var rotation_speed: float = 2.0
@export var acceleration: float = 200.0
@export var deceleration: float = 100.0
@export var drift_factor: float = 0.95

# In ShipTemplate.gd - ENERGY SYSTEM HINZUFÜGEN
@export_group("Energy Systems")
@export var max_energy: float = 1000.0
@export var energy_regen_rate: float = 50.0  # Energie/Sekunde
@export var phaser_energy_cost: float = 20.0  # Energie/Schuss

# NODE REFERENZEN
@onready var weapon_manager: WeaponManagerSystem = $WeaponManager


# SHIP STATUS
var current_health: float
var is_destroyed: bool = false
var current_speed: float = 0.0

var current_energy: float

func _ready():
	current_health = max_health
	current_energy = max_energy  # ← NEU
	setup_weapons()
	print("🚀 Ship ready: ", ship_name, " with ", weapon_configs.size(), " weapons")
	
func _process(delta):
	# Energie regenerieren
	current_energy = min(current_energy + energy_regen_rate * delta, max_energy)

# ENERGY API
func can_use_energy(amount: float) -> bool:
	return current_energy >= amount

# CONTINUOUS FIRE API - NEUE METHODEN FÜR PLAYER
func start_continuous_fire(weapon_index: int, start_position: Vector2, target_position: Vector2):
	if weapon_manager:
		weapon_manager.start_continuous_fire(weapon_index, start_position, target_position)
	else:
		push_error("❌ WeaponManager nicht verfügbar für Dauerfeuer")
		
func stop_continuous_fire():
	if weapon_manager:
		weapon_manager.stop_continuous_fire()
	else:
		push_error("❌ WeaponManager nicht verfügbar für Dauerfeuer-Stopp")

func use_energy(amount: float) -> bool:
	if can_use_energy(amount):
		current_energy -= amount
		return true
	return false

func get_energy_percent() -> float:
	return current_energy / max_energy

func setup_weapons():
	if weapon_manager:
		print("🎯 Configuring WeaponManager with ", weapon_configs.size(), " weapons")
		weapon_manager.weapon_configs = weapon_configs
		weapon_manager.setup_weapons()
	else:
		push_error("❌ WeaponManager not found in: " + ship_name)

# WEAPON API FÜR PLAYER
func fire_weapon(weapon_index: int, start_position: Vector2, target_position: Vector2) -> bool:
	if weapon_manager and not is_destroyed:
		return weapon_manager.fire_weapon(weapon_index, start_position, target_position)
	return false

func can_fire(weapon_index: int = 0) -> bool:
	if weapon_manager and not is_destroyed:
		return weapon_manager.can_fire(weapon_index)
	return false

func get_weapon_count() -> int:
	if weapon_manager:
		return weapon_manager.get_weapon_count()
	return 0

# MOVEMENT API
func get_max_speed() -> float:
	return max_speed

func get_rotation_speed() -> float:
	return rotation_speed

func get_acceleration() -> float:
	return acceleration

func get_deceleration() -> float:
	return deceleration

func get_drift_factor() -> float:
	return drift_factor

# DAMAGE SYSTEM
func take_damage(amount: float):
	if is_destroyed:
		return
		
	current_health -= amount
	print(ship_name + " took " + str(amount) + " damage. Health: " + str(current_health))
	
	if current_health <= 0:
		destroy()

func destroy():
	if is_destroyed:
		return
		
	is_destroyed = true
	print("💥 " + ship_name + " destroyed!")
	queue_free()
