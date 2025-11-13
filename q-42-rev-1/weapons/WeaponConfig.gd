# WeaponConfig.gd
extends Resource
class_name WeaponConfig

@export_group("Basic Settings")
@export var weapon_name: String = "Phaser"
@export var weapon_type: String = "beam"  # "beam", "projectile", "missile"
@export var fire_rate: float = 0.5
@export var damage: float = 55.0

@export_group("Visual Settings") 
@export var beam_color: Color = Color(1, 0.5, 0)
@export var beam_width: float = 3.0
@export var background_width: float = 6.0
@export var beam_duration: float = 0.2
@export var glow_intensity: float = 0.6

@export_group("Charging System")
@export var with_charge: bool = true
@export var charge_time: float = 0.6
@export var charged_color: Color = Color(1, 0.2, 0)
@export var charged_beam_width: float = 6.0

@export_group("Projectile Settings")
@export var projectile_speed: float = 300.0
@export var projectile_lifetime: float = 3.0

@export_group("Audio")
@export var fire_sound: AudioStream
@export var charge_sound: AudioStream
