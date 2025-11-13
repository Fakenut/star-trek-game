# GalaxyClass.gd
extends CharacterBody2D
class_name GalaxyClass

# --- GalaxyClass spezifische Werte ---
@export_group("Galaxy Class Specific")
@export var science_probes: int = 10
@export var max_energy: float = 1200.0
@export var impulse_speed: float = 300.0
@export var warp_capable: bool = true
@export var warp_speed: float = 1000.0
@export var rotation_speed: float = 2.0
@export var accel: float = 800.0
@export var deaccel: float = 500.0

# --- Ship Identity ---
@export_group("Ship Identity")
@export var ship_faction: int = 0
@export var ship_class: String = "explorer"
@export var ship_name: String = "Unnamed Ship"
@export var is_destroyable: bool = true
@export var is_targetable: bool = true

# --- Ship Stats ---
@export_group("Ship Stats")
@export var max_health: float = 300.0
var health: float = 300.0
var current_energy: float = 1200.0
var current_speed: float = 0.0
var is_at_warp: bool = false

# --- Weapon System ---
@export var weapon_configs: Array[WeaponConfig]

# --- Signale ---
signal ship_destroyed(ship: Node)
signal ship_damaged(ship: Node, damage: float, source: Node)
signal ship_targeted(ship: Node)
signal warp_status_changed(is_warp: bool)

# --- Ready ---
func _ready():
	_initialize_ship()
	print("🛸 Galaxy-Class initialized: ", ship_name)
	print("Drücke SPACE zum Phaser-Test!")

func _initialize_ship():
	health = max_health
	current_energy = max_energy
	if ship_name == "Unnamed Ship":
		ship_name = _generate_ship_name()
	_update_faction_visuals()

func _update_faction_visuals():
	if has_node("Sprite2D"):
		$Sprite2D.modulate = FactionManager.get_faction_color(ship_faction)

# --- Physics / Bewegung ---
func _physics_process(delta):
	if current_speed != 0:
		var motion = transform.x * current_speed * delta
		var collision = move_and_collide(motion)
		if collision:
			_handle_collision(collision)

func setup_player(player: Node):
	var weapon_system = player.get_node("WeaponSystem")
	weapon_system.weapon_configs = weapon_configs
	weapon_system.setup_weapons()

func _handle_collision(collision: KinematicCollision2D):
	print("💥 Collision detected with: ", collision.get_collider().name)
	take_damage(10)

# --- Schaden / Zerstörung ---
func take_damage(amount: float, damage_source: Node = null):
	if not is_destroyable:
		return
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
	var explosion = ColorRect.new()
	explosion.size = Vector2(30, 30)
	explosion.color = Color.ORANGE_RED
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(explosion.queue_free)

# --- Statusabfragen ---
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

# --- Spezialfähigkeiten ---
func activate_warp_drive() -> bool:
	if warp_capable and current_energy > 200 and not is_at_warp:
		print("✨ Warp drive engaged!")
		is_at_warp = true
		current_energy -= 100
		warp_status_changed.emit(true)
		return true
	return false

func deactivate_warp_drive() -> bool:
	if is_at_warp:
		print("✨ Warp drive disengaged")
		is_at_warp = false
		warp_status_changed.emit(false)
		return true
	return false

func launch_science_probe() -> bool:
	if science_probes > 0:
		science_probes -= 1
		print("📡 Science probe launched! Probes remaining: ", science_probes)
		return true
	print("❌ No science probes remaining")
	return false

# --- Bewegung AI / Steuerung ---
func set_current_speed(speed: float):
	current_speed = speed

func rotate_ship(direction: float):
	rotation += direction * rotation_speed * get_process_delta_time()

func move_forward():
	set_current_speed(impulse_speed)

func stop():
	set_current_speed(0)

func get_ship_status() -> Dictionary:
	return {
		"name": ship_name,
		"class": ship_class,
		"health": health,
		"energy": current_energy,
		"warp_engaged": is_at_warp,
		"probes_remaining": science_probes,
		"speed": current_speed
	}

func _generate_ship_name() -> String:
	var prefixes = ["USS", "NCC"]
	var names = ["Enterprise", "Voyager", "Defiant", "Reliant", "Excelsior", "Constellation", "Galaxy", "Yamato"]
	return prefixes[randi() % prefixes.size()] + " " + names[randi() % names.size()]
