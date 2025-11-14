# scripts/systems/WeaponManager.gd
extends Node2D
class_name WeaponManagerSystem

# EXPORT VARIABLEN
@export var weapon_configs: Array[WeaponConfig] = []
@export var phaser_beam_scene: PackedScene
@export var charge_effect_scene: PackedScene

# ENERGIE & TICK
@export var unlimited_energy: bool = false
@export var energy_pool_max: float = 100.0
var energy_pool: float = energy_pool_max
@export var energy_tick_rate: float = 10.0  # Energie pro Sekunde wieder aufladen

# TORPEDO / PROJEKTILE
@export var missile_tick_rate: float = 1.0  # Wiederaufladung pro Sekunde
var missile_ammo: Dictionary = {}
var missile_max_ammo: Dictionary = {}

# NORMALE VARIABLEN
var weapons: Array = []
var fire_timers: Dictionary = {}
var current_weapon_index: int = 0

# PERSISTENT PHASER SYSTEM
var active_phaser: Node2D = null
var is_firing: bool = false
var current_phaser_position: String = "forward"

# CHARGE SYSTEM
var active_charge_effects: Dictionary = {}

# ---------------- WeaponInstance ----------------
class WeaponInstance:
	var config: WeaponConfig
	var is_charging: bool = false
	var is_ready: bool = true
	var charge_timer: float = 0.0

	func _init(weapon_config: WeaponConfig) -> void:
		config = weapon_config

# ---------------- READY ----------------
func _ready() -> void:
	setup_weapons()

# ---------------- SETUP ----------------
func setup_weapons() -> void:
	# Alte Timer cleanup
	for timer in fire_timers.values():
		if is_instance_valid(timer):
			timer.queue_free()
	fire_timers.clear()
	weapons.clear()
	missile_ammo.clear()
	missile_max_ammo.clear()

	print("🔧 WeaponManager Setup mit ", weapon_configs.size(), " Waffen")

	for i in range(weapon_configs.size()):
		var config: WeaponConfig = weapon_configs[i]
		print("  💣 Waffe ", i, ": ", config.weapon_name, " (", config.weapon_type, ")")

		var weapon = WeaponInstance.new(config)
		weapons.append(weapon)

		# Timer für Feuerrate
		var timer = Timer.new()
		timer.wait_time = config.fire_rate
		timer.one_shot = true
		timer.timeout.connect(Callable(self, "_on_weapon_ready").bind(i))
		add_child(timer)
		fire_timers[i] = timer

		# Für Missile/Projectile Ammo
		if config.weapon_type in ["missile", "projectile"]:
			missile_max_ammo[i] = 5  # max Anzahl pro Waffe
			missile_ammo[i] = missile_max_ammo[i]

	print("✅ WeaponManager Setup abgeschlossen")

# ---------------- CONTINUOUS FIRE ----------------
func start_continuous_fire(weapon_index: int, start_position: Vector2, target_position: Vector2) -> void:
	if weapon_index >= weapons.size(): return
	var weapon: WeaponInstance = weapons[weapon_index]
	if not weapon.is_ready: return

	# Phaser Position bestimmen
	var ship = get_parent()
	if ship and ship.has_method("get_phaser_position"):
		var target_angle = (target_position - ship.global_position).angle()
		current_phaser_position = ship.get_phaser_position(target_angle)

	start_charge_effect(current_phaser_position)
	is_firing = true

	if not active_phaser and phaser_beam_scene:
		active_phaser = phaser_beam_scene.instantiate()
		get_parent().add_child(active_phaser)
		if active_phaser.has_method("setup"):
			active_phaser.setup(weapon.config)

	# Sofort starten
	start_continuous_beam(start_position, target_position)

func stop_continuous_fire() -> void:
	is_firing = false
	stop_all_charge_effects()
	if active_phaser and active_phaser.has_method("hide"):
		active_phaser.hide()

# ---------------- BEAM ----------------
func start_continuous_beam(start_position: Vector2, target_position: Vector2) -> void:
	if not is_firing or not active_phaser: return

	var ship = get_parent()
	if ship and active_phaser.has_method("fire_beam"):
		if unlimited_energy or (energy_pool >= 0):
			active_phaser.fire_beam(start_position, target_position)
			if not unlimited_energy:
				energy_pool -= weapons[current_weapon_index].config.energy_cost * get_process_delta_time()

# ---------------- PROCESS ----------------
func _process(delta: float) -> void:
	# Charge Effekte updaten
	for position_name in active_charge_effects.keys():
		var effect = active_charge_effects[position_name]
		if is_instance_valid(effect) and effect.has_method("update_charge"):
			effect.update_charge(delta)
		else:
			active_charge_effects.erase(position_name)

	# Dauerfeuer Beam
	if is_firing and active_phaser:
		var ship = get_parent()
		if ship:
			var start_pos = ship.global_position
			if ship.has_method("get_phaser_global_position"):
				start_pos = ship.get_phaser_global_position(current_phaser_position)
			var target_pos = get_global_mouse_position()
			start_continuous_beam(start_pos, target_pos)

	# Energie wieder aufladen
	if not unlimited_energy:
		energy_pool += energy_tick_rate * delta
		energy_pool = min(energy_pool, energy_pool_max)

	# Missile/Projectile Ammo wieder aufladen
	for key in missile_ammo.keys():
		if missile_ammo[key] < missile_max_ammo[key]:
			missile_ammo[key] += missile_tick_rate * delta
			missile_ammo[key] = min(missile_ammo[key], missile_max_ammo[key])

# ---------------- SINGLE FIRE ----------------
func fire_weapon(weapon_index: int, start_position: Vector2, target_position: Vector2) -> bool:
	if weapon_index >= weapons.size(): return false
	var weapon: WeaponInstance = weapons[weapon_index]
	if not weapon.is_ready: return false

	# Missile/Projectile Check
	if weapon.config.weapon_type in ["missile", "projectile"]:
		if missile_ammo.get(weapon_index, 0) < 1:
			print("❌ Keine Munition mehr!")
			return false
		missile_ammo[weapon_index] -= 1

	var is_charged = weapon.is_charging and weapon.config.with_charge

	match weapon.config.weapon_type:
		"beam":
			fire_beam_weapon(weapon.config, start_position, target_position, is_charged)
		"projectile":
			fire_projectile_weapon(weapon.config, start_position, target_position)
		"missile":
			fire_missile_weapon(weapon.config, start_position, target_position)

	weapon.is_ready = false
	weapon.is_charging = false
	if fire_timers.has(weapon_index):
		fire_timers[weapon_index].start()

	return true

func fire_beam_weapon(config: WeaponConfig, start_pos: Vector2, target_pos: Vector2, is_charged: bool) -> void:
	if not phaser_beam_scene: return
	var phaser_beam = phaser_beam_scene.instantiate()
	get_tree().current_scene.add_child(phaser_beam)
	if phaser_beam.has_method("setup"): phaser_beam.setup(config)
	if phaser_beam.has_method("fire_beam"): phaser_beam.fire_beam(start_pos, target_pos, is_charged)

func fire_projectile_weapon(config: WeaponConfig, start_pos: Vector2, target_pos: Vector2) -> void:
	print("🚀 Projectile: ", config.weapon_name)

func fire_missile_weapon(config: WeaponConfig, start_pos: Vector2, target_pos: Vector2) -> void:
	print("🎯 Missile: ", config.weapon_name)

# ---------------- WEAPON READY ----------------
func _on_weapon_ready(weapon_index: int) -> void:
	if weapon_index < weapons.size():
		weapons[weapon_index].is_ready = true

# ---------------- CHARGE EFFECT ----------------
func start_charge_effect(position_name: String) -> void:
	if not charge_effect_scene: return
	stop_all_charge_effects()
	var charge_effect = charge_effect_scene.instantiate()
	var ship = get_parent()
	if ship and ship.has_method("get_phaser_global_position"):
		charge_effect.global_position = ship.get_phaser_global_position(position_name)
	else:
		charge_effect.global_position = ship.global_position if ship else Vector2.ZERO
	get_tree().current_scene.add_child(charge_effect)
	active_charge_effects[position_name] = charge_effect
	if charge_effect.has_method("start_charge"):
		charge_effect.start_charge()

func stop_all_charge_effects() -> void:
	for position_name in active_charge_effects.keys():
		var effect = active_charge_effects[position_name]
		if is_instance_valid(effect) and effect.has_method("stop_charge"):
			effect.stop_charge()
	active_charge_effects.clear()
