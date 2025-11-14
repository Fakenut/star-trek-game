# scripts/systems/WeaponManager.gd
extends Node2D
class_name WeaponManager

# EXPORT VARIABLEN
@export var weapon_configs: Array[WeaponConfig] = []
@export var phaser_beam_scene: PackedScene
@export var charge_effect_scene: PackedScene

# ENERGY / RECHARGE SETTINGS
@export var unlimited_energy: bool = true
@export var use_ship_energy: bool = false
@export var continuous_energy_cost: float = 20.0            # cost per "beam update" call (you can tune)
@export var max_energy: float = 100.0
@export var energy_recharge_per_second: float = 10.0        # wieviel Energie / Sekunde geladen wird (wenn unlimited_energy = false)

# MISSILE / AMMO SETTINGS
@export var missile_max_ammo: int = 3
@export var missile_recharge_tick: float = 5.0              # Sekunden pro 1 Rakete Wiederaufladung

# NORMALE VARIABLEN
var weapons: Array = []
var fire_timers: Dictionary = {}
var current_weapon_index: int = 0

# PERSISTENT PHASER SYSTEM
var active_phaser: Node2D = null
var is_firing: bool = false

# CHARGE SYSTEM
var active_charge_effects: Dictionary = {}
var current_phaser_position: String = "forward"

# LOKALE ENERGIE-POOL (sofern use_ship_energy == false)
var energy_pool: float = max_energy

class WeaponInstance:
	var config: WeaponConfig
	var is_charging: bool = false
	var is_ready: bool = true
	var charge_timer: float = 0.0
	# Ammo fields (nur relevant für missiles)
	var ammo: int = 0
	var max_ammo: int = 0
	var ammo_recharge_acc: float = 0.0   # Akkumulator für Wiederaufladung

	func _init(weapon_config: WeaponConfig) -> void:
		config = weapon_config

func _ready() -> void:
	# setze initial energy pool
	energy_pool = max_energy
	setup_weapons()

func setup_weapons() -> void:
	# Alte Timer cleanup
	for timer in fire_timers.values():
		if is_instance_valid(timer):
			timer.queue_free()
	fire_timers.clear()
	weapons.clear()

	print("🔧 WeaponManager Setup mit ", weapon_configs.size(), " Waffen")

	for i in range(weapon_configs.size()):
		var config: WeaponConfig = weapon_configs[i]
		print("  💣 Waffe ", i, ": ", config.weapon_name, " (", config.weapon_type, ")")

		var weapon = WeaponInstance.new(config)

		# Initialisiere Ammo für missiles
		if config.weapon_type == "missile":
			weapon.max_ammo = missile_max_ammo
			weapon.ammo = weapon.max_ammo
			weapon.ammo_recharge_acc = 0.0
		else:
			weapon.max_ammo = 0
			weapon.ammo = 0
			weapon.ammo_recharge_acc = 0.0

		weapons.append(weapon)

		# Timer für Feuerrate
		var timer = Timer.new()
		timer.wait_time = config.fire_rate
		timer.one_shot = true
		# Saubere Verbindung mit Callable + bind(index)
		timer.timeout.connect(Callable(self, "_on_weapon_ready").bind(i))
		add_child(timer)
		fire_timers[i] = timer

	print("✅ WeaponManager Setup abgeschlossen")

# Dauerfeuer starten
func start_continuous_fire(weapon_index: int, start_position: Vector2, target_position: Vector2) -> void:
	if weapon_index >= weapons.size():
		print("❌ Waffe nicht verfügbar für Dauerfeuer")
		return

	var weapon: WeaponInstance = weapons[weapon_index]

	if not weapon.is_ready:
		print("⏳ Waffe nicht bereit für Dauerfeuer")
		return

	# BESTIMME PHASER-POSITION BASIEREND AUF ZIEL
	var ship = get_parent()
	if ship and ship.has_method("get_phaser_position"):
		var target_angle = (target_position - ship.global_position).angle()
		current_phaser_position = ship.get_phaser_position(target_angle)
		print("🎯 Phaser Position: ", current_phaser_position)

	# STARTE CHARGE-EFFEKT
	start_charge_effect(current_phaser_position)

	is_firing = true

	# Erstelle persistenten Phaser falls nicht existiert
	if not active_phaser:
		if phaser_beam_scene:
			active_phaser = phaser_beam_scene.instantiate()
			# Phaser wird dem Schiff als Kind hinzugefügt, damit er dem Schiff folgt
			get_parent().add_child(active_phaser)

			if active_phaser.has_method("setup"):
				active_phaser.setup(weapon.config)

	# Sofort mit Dauerfeuer starten (kein await)
	start_continuous_beam(start_position, target_position)


func stop_continuous_fire() -> void:
	is_firing = false
	print("🔫 Stoppe Dauerfeuer")

	# Stoppe alle Charge-Effekte
	stop_all_charge_effects()

	if active_phaser and active_phaser.has_method("hide"):
		active_phaser.hide()


func start_continuous_beam(start_position: Vector2, target_position: Vector2) -> void:
	if not is_firing or not active_phaser:
		return

	# Wenn unlimited_energy aktiv -> kein Verbrauch
	if unlimited_energy:
		if active_phaser.has_method("fire_beam"):
			active_phaser.fire_beam(start_position, target_position)
		return

	# Versuch zuerst die Schiffsmethode zu nutzen (wenn gesetztes Flag)
	var ship = get_parent()
	if use_ship_energy and ship and ship.has_method("use_energy"):
		if ship.use_energy(continuous_energy_cost):
			if active_phaser.has_method("fire_beam"):
				active_phaser.fire_beam(start_position, target_position)
		else:
			print("🔋 Keine Energie mehr (Ship) - stoppe Dauerfeuer")
			stop_continuous_fire()
		return

	# Sonst nutze lokalen Energy-Pool
	if energy_pool >= continuous_energy_cost:
		energy_pool -= continuous_energy_cost
		if active_phaser.has_method("fire_beam"):
			active_phaser.fire_beam(start_position, target_position)
	else:
		print("🔋 Keine Energie mehr (Manager) - stoppe Dauerfeuer")
		stop_continuous_fire()


func stop_all_charge_effects() -> void:
	for position_name in active_charge_effects.keys():
		var effect = active_charge_effects[position_name]
		if is_instance_valid(effect) and effect.has_method("stop_charge"):
			effect.stop_charge()
	active_charge_effects.clear()


func _process(delta: float) -> void:
	# ----------------------------
	# Recharge: Energy Pool
	# ----------------------------
	if not unlimited_energy:
		energy_pool = min(max_energy, energy_pool + energy_recharge_per_second * delta)

	# ----------------------------
	# Recharge: Ammo (Missiles)
	# ----------------------------
	for weapon in weapons:
		if weapon.max_ammo > 0 and weapon.ammo < weapon.max_ammo:
			weapon.ammo_recharge_acc += delta
			# Wenn genug Zeit gesammelt wurde, lade 1 Torpedo und reduziere Acc
			if weapon.ammo_recharge_acc >= missile_recharge_tick:
				var to_add = int(floor(weapon.ammo_recharge_acc / missile_recharge_tick))
				weapon.ammo = min(weapon.max_ammo, weapon.ammo + to_add)
				weapon.ammo_recharge_acc -= to_add * missile_recharge_tick

	# Update Charge-Effekte
	for position_name in active_charge_effects.keys():
		var effect = active_charge_effects[position_name]
		if is_instance_valid(effect) and effect.has_method("update_charge"):
			effect.update_charge(delta)
		else:
			# Ungültigen Effekt entfernen
			active_charge_effects.erase(position_name)

	# Dauerfeuer -> aktualisiere Beam (position/target) jede Process-Iteration
	if is_firing and active_phaser:
		var ship = get_parent()
		if ship:
			var start_pos: Vector2 = ship.global_position
			if ship.has_method("get_phaser_global_position"):
				start_pos = ship.get_phaser_global_position(current_phaser_position)

			var target_pos: Vector2 = get_global_mouse_position()

			# Update Phaser-Position falls nötig
			var target_angle = (target_pos - ship.global_position).angle()
			var new_position = current_phaser_position
			if ship.has_method("get_phaser_position"):
				new_position = ship.get_phaser_position(target_angle)

			if new_position != current_phaser_position:
				print("🔄 Wechsle Phaser Position: ", current_phaser_position, " -> ", new_position)
				current_phaser_position = new_position
				start_charge_effect(current_phaser_position)

			start_continuous_beam(start_pos, target_pos)


# Einzelschuss-Methoden
func fire_weapon(weapon_index: int, start_position: Vector2, target_position: Vector2) -> bool:
	print("🔫 WEAPONMANAGER: fire_weapon aufgerufen - Index:", weapon_index)

	if weapon_index >= weapons.size():
		print("❌ WEAPONMANAGER: Waffe nicht verfügbar")
		return false

	var weapon: WeaponInstance = weapons[weapon_index]
	if not weapon.is_ready:
		print("⏳ WEAPONMANAGER: Waffe nicht bereit")
		return false

	# Wenn Missile: prüfe Ammo
	if weapon.config.weapon_type == "missile":
		if weapon.ammo <= 0:
			print("❌ Keine Raketen/Torpedos verfügbar für Waffe: ", weapon.config.weapon_name)
			return false
		# Reduziere Ammo sofort
		weapon.ammo -= 1

	print("✅ WEAPONMANAGER: Feuere Waffe:", weapon.config.weapon_name)

	var is_charged: bool = weapon.is_charging and weapon.config.with_charge

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
	if not phaser_beam_scene:
		push_error("❌ PhaserBeam scene not assigned!")
		return

	var phaser_beam = phaser_beam_scene.instantiate()
	# Hier bewusst in current_scene, damit der Einzelschuss unabhängig ist
	get_tree().current_scene.add_child(phaser_beam)
	if phaser_beam.has_method("setup"):
		phaser_beam.setup(config)
	if phaser_beam.has_method("fire_beam"):
		phaser_beam.fire_beam(start_pos, target_pos, is_charged)


func fire_projectile_weapon(config: WeaponConfig, start_pos: Vector2, target_pos: Vector2) -> void:
	print("🚀 Projectile: ", config.weapon_name)
	# Implementiere projectile creation hier, Energie/Kollisionen etc. optional


func fire_missile_weapon(config: WeaponConfig, start_pos: Vector2, target_pos: Vector2) -> void:
	print("🎯 Missile: ", config.weapon_name)
	# Implementiere missile instantiation hier (z.B. missile scene), aktuell nur Platzhalter


func _on_weapon_ready(weapon_index: int) -> void:
	print("🔄 WEAPON READY: Waffe ", weapon_index, " ist wieder bereit")
	if weapon_index < weapons.size():
		weapons[weapon_index].is_ready = true


func can_fire(weapon_index: int = 0) -> bool:
	if weapon_index < weapons.size():
		return weapons[weapon_index].is_ready
	return false


func get_weapon_count() -> int:
	return weapons.size()


# CHARGE EFFECT SYSTEM
func start_charge_effect(position_name: String) -> void:
	if not charge_effect_scene:
		# KEIN FEHLER - einfach ignorieren wenn keine Scene zugewiesen
		print("⚡ CHARGE EFFECT: ", position_name, " (keine Scene zugewiesen)")
		return

	# Stoppe vorherige Effekte
	stop_all_charge_effects()

	# Starte neuen Charge-Effekt
	var charge_effect = charge_effect_scene.instantiate()
	var ship = get_parent()

	if ship and ship.has_method("get_phaser_global_position"):
		charge_effect.global_position = ship.get_phaser_global_position(position_name)
	else:
		if ship:
			charge_effect.global_position = ship.global_position
		else:
			charge_effect.global_position = Vector2.ZERO

	get_tree().current_scene.add_child(charge_effect)
	active_charge_effects[position_name] = charge_effect

	if charge_effect.has_method("start_charge"):
		charge_effect.start_charge()
