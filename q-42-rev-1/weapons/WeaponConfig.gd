# scripts/resources/WeaponConfig.gd
extends Resource
class_name WeaponConfig

@export_group("Basic Settings")
@export var weapon_name: String = "Phaser"
@export var weapon_type: String = "beam"  # "beam", "projectile", "missile"
@export var fire_rate: float = 0.5
@export var damage: float = 55.0
@export var energy_cost: float = 10.0

@export_group("Visual Settings") 
@export var beam_color: Color = Color(1, 0.5, 0)
@export var beam_width: float = 3.0
@export var background_width: float = 6.0
@export var beam_duration: float = 0.2
@export var glow_intensity: float = 0.6

@export_group("Charging System")
@export var with_charge: bool = false
@export var charge_time: float = 0.6
@export var charged_color: Color = Color(1, 0.2, 0)
@export var charged_beam_width: float = 6.0

@export_group("Projectile Settings")
@export var projectile_speed: float = 300.0
@export var projectile_lifetime: float = 3.0

@export_group("Audio")
@export var fire_sound: AudioStream
@export var charge_sound: AudioStream

# Funktion um Kopien für verschiedene Waffen zu erstellen
func duplicate_config() -> WeaponConfig:
	var new_config = WeaponConfig.new()
	new_config.weapon_name = weapon_name
	new_config.weapon_type = weapon_type
	new_config.fire_rate = fire_rate
	new_config.damage = damage
	new_config.energy_cost = energy_cost
	new_config.beam_color = beam_color
	new_config.beam_width = beam_width
	new_config.background_width = background_width
	new_config.beam_duration = beam_duration
	new_config.glow_intensity = glow_intensity
	new_config.with_charge = with_charge
	new_config.charge_time = charge_time
	new_config.charged_color = charged_color
	new_config.charged_beam_width = charged_beam_width
	new_config.projectile_speed = projectile_speed
	new_config.projectile_lifetime = projectile_lifetime
	new_config.fire_sound = fire_sound
	new_config.charge_sound = charge_sound
	return new_config
