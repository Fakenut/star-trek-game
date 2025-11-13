# WeaponSystem.gd
extends Node2D

@export var weapon_configs: Array[WeaponConfig]
@export var phaser_beam_scene: PackedScene

var weapons: Array[WeaponInstance] = []
var fire_timers: Array[Timer] = []
var charge_timers: Array[Timer] = []

class WeaponInstance:
	var config: WeaponConfig
	var is_charging: bool = false
	var is_ready: bool = true
	
	func _init(weapon_config: WeaponConfig):
		config = weapon_config

func _ready():
	setup_weapons()

func setup_weapons():
	for config in weapon_configs:
		var weapon = WeaponInstance.new(config)
		weapons.append(weapon)
		
		# Timer für Feuerrate
		var fire_timer = Timer.new()
		fire_timer.wait_time = config.fire_rate
		fire_timer.one_shot = true
		add_child(fire_timer)
		fire_timers.append(fire_timer)
		
		# Timer für Charging
		var charge_timer = Timer.new()
		charge_timer.wait_time = config.charge_time
		charge_timer.one_shot = true
		add_child(charge_timer)
		charge_timers.append(charge_timer)

func start_charging_weapon(weapon_index: int):
	if weapon_index >= weapons.size(): return
	
	var weapon = weapons[weapon_index]
	if weapon.config.with_charge and weapon.is_ready:
		weapon.is_charging = true
		charge_timers[weapon_index].start()

func fire_weapon(weapon_index: int, target_position: Vector2):
	if weapon_index >= weapons.size(): return
	
	var weapon = weapons[weapon_index]
	if not weapon.is_ready: return
	
	var is_charged = weapon.is_charging and weapon.config.with_charge
	
	# PhaserBeam instanziieren und konfigurieren
	var phaser_beam = phaser_beam_scene.instantiate()
	get_parent().add_child(phaser_beam)
	phaser_beam.setup(weapon.config)
	phaser_beam.fire_beam(global_position, target_position, is_charged)
	
	# Reset state
	weapon.is_charging = false
	weapon.is_ready = false
	fire_timers[weapon_index].start()

func _on_fire_timer_timeout(weapon_index: int):
	weapons[weapon_index].is_ready = true
