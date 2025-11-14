# Warbird.gd
extends CharacterBody2D

# Warbird spezifische Werte (schneller, wendiger)
@export_group("Warbird Specific")
@export var cloaking_available: bool = true
@export var plasma_torpedo_charge_time: float = 3.0
@export var cloak_energy_cost: float = 50.0

@export var impulse_speed: float = 350.0  # Schneller als Galaxy
@export var warp_speed: float = 1200.0    # Schnellerer Warp
@export var rotation_speed: float = 3.0   # Wendiger
@export var accel: float = 1000.0         # Schnellere Beschleunigung
@export var deaccel: float = 400.0        # Anderes Bremsverhalten

# ShipBase Properties
@export_group("Ship Identity")
@export var ship_faction: int = 2  # FactionManager.FACTION.ROMULAN
@export var ship_class: String = "battle_cruiser"
@export var ship_name: String = "Unnamed Ship"
@export var is_destroyable: bool = true
@export var is_targetable: bool = true

@export_group("Ship Stats")
@export var max_health: float = 400.0
@export var max_speed: float = 180.0


var health: float = 400.0
var current_speed: float = 0.0
var is_cloaked: bool = false
var plasma_torpedo_charge: float = 0.0
var last_decloak_time: float = 0.0

# Weapon System
@onready var weapon_system = $WeaponSystem

# Signals
signal ship_destroyed(ship: Node)
signal ship_damaged(ship: Node, damage: float, source: Node)
signal ship_targeted(ship: Node)
signal cloak_status_changed(is_cloaked: bool)
signal plasma_charge_changed(charge: float)

func _ready():
	_initialize_ship()
	print("👻 Warbird initialized: ", ship_name)

func _initialize_ship():
	health = max_health
	
	if ship_name == "Unnamed Ship":
		ship_name = _generate_ship_name()
	
	_update_faction_visuals()

func _update_faction_visuals():
	if has_node("Sprite2D"):
		$Sprite2D.modulate = FactionManager.get_faction_color(ship_faction)

func _physics_process(delta):
	# AI Bewegung
	if current_speed > 0:
		var motion = transform.x * current_speed * delta
		var collision = move_and_collide(motion)
		
		if collision:
			_handle_collision(collision)
	
	# Plasma Torpedo aufladen (nur wenn nicht getarnt)
	if not is_cloaked:
		_charge_plasma_torpedo(delta)

# NEU: Phaser-Schießen mit Leertaste
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Leertaste
		var mouse_pos = get_global_mouse_position()
		if weapon_system and weapon_system.fire_phaser(mouse_pos):
			print("🔫 Warbird: Grüner Phaser abgefeuert auf ", mouse_pos)
		else:
			print("⚡ Warbird: Nicht genug Energie!")

func _handle_collision(collision: KinematicCollision2D):
	print("💥 Collision detected with: ", collision.get_collider().name)
	take_damage(15)  # Warbirds nehmen mehr Kollisionsschaden

func _charge_plasma_torpedo(delta: float):
	var old_charge = plasma_torpedo_charge
	plasma_torpedo_charge = min(plasma_torpedo_charge + delta / plasma_torpedo_charge_time, 1.0)
	
	if plasma_torpedo_charge != old_charge:
		plasma_charge_changed.emit(plasma_torpedo_charge)
		
		if plasma_torpedo_charge >= 1.0:
			print("⚡ Plasma torpedo fully charged!")

# ShipBase kompatible Methoden
func take_damage(amount: float, damage_source: Node = null):
	if not is_destroyable:
		return
	
	# Zusätzlicher Schaden wenn getarnt
	if is_cloaked:
		amount *= 2.0
		print("🚨 CRITICAL: Taking damage while cloaked!")
	
	health -= amount
	ship_damaged.emit(self, amount, damage_source)
	
	print("💥 ", ship_name, " took ", amount, " damage. Health: ", health, "/", max_health)
	
	if health <= 0:
		_destroy_ship(damage_source)

func _destroy_ship(destroyer: Node = null):
	print("💀 ", ship_name, " destroyed!")
	ship_destroyed.emit(self)
	_create_destruction_effect()
	queue_free()

func _create_destruction_effect():
	# Größere Explosion für Warbird
	var explosion = ColorRect.new()
	explosion.size = Vector2(40, 40)
	explosion.color = Color.DARK_GREEN
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	
	var timer = get_tree().create_timer(0.5)
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

func is_hostile_to(other_ship: Node) -> bool:
	if other_ship.has_method("get_ship_faction"):
		return not FactionManager.are_factions_allied(ship_faction, other_ship.get_ship_faction())
	return true

# Warbird spezifische Methoden
func toggle_cloak() -> bool:
	if cloaking_available:
		if not is_cloaked:
			return _activate_cloak()
		else:
			return _deactivate_cloak()
	return false

func _activate_cloak() -> bool:
	if not is_cloaked:
		print("👻 Cloaking device activated")
		is_cloaked = true
		
		# Visuelle Effekte
		modulate.a = 0.3
		
		# Geschwindigkeit erhöht im Tarnmodus
		max_speed *= 1.2
		
		cloak_status_changed.emit(true)
		return true
	return false

func _deactivate_cloak() -> bool:
	if is_cloaked:
		print("👻 Decloaking...")
		is_cloaked = false
		last_decloak_time = Time.get_unix_time_from_system()
		
		# Visuelle Effekte zurücksetzen
		modulate.a = 1.0
		
		# Geschwindigkeit zurücksetzen
		max_speed = 180.0
		
		cloak_status_changed.emit(false)
		return true
	return false

func fire_plasma_torpedo(target: Node2D) -> bool:
	if plasma_torpedo_charge >= 1.0:
		print("⚡ PLASMA TORPEDO FIRED!")
		plasma_torpedo_charge = 0.0
		plasma_charge_changed.emit(0.0)
		
		# Angriffsbonus nach Decloak
		var attack_bonus = 1.0
		if Time.get_unix_time_from_system() - last_decloak_time < 5.0:
			attack_bonus = 1.5
			print("   🎯 Decloak attack bonus active!")
		
		# Schaden verursachen
		if target and target.has_method("take_damage"):
			var damage = 80.0 * attack_bonus
			target.take_damage(damage, self)
		
		return true
	
	print("❌ Plasma torpedo not fully charged: ", plasma_torpedo_charge)
	return false

# Bewegung-Methoden für AI
func set_current_speed(speed: float):
	current_speed = speed

func rotate_ship(direction: float):
	rotation += direction * rotation_speed * get_process_delta_time()

func move_forward():
	set_current_speed(max_speed)

func stop():
	set_current_speed(0)

func get_ship_status() -> Dictionary:
	return {
		"name": ship_name,
		"class": ship_class,
		"health": health,
		"cloaked": is_cloaked,
		"plasma_charge": plasma_torpedo_charge,
		"speed": current_speed
	}

func _generate_ship_name() -> String:
	var prefixes = ["IRW", "RIS"]
	var names = ["Vengeance", "Shadow", "D'deridex", "Valdore", "Scimitar", "Tero", "Kazhon", "Vorta"]
	return prefixes[randi() % prefixes.size()] + " " + names[randi() % names.size()]
