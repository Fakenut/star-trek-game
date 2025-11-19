# res://Scripts/Modules/WeaponModule.gd
class_name WeaponModule
extends Node

@export var phaser_charge_scene: PackedScene
@export var phaser_beam_scene: PackedScene

@export_group("Ship-specific Ring Settings")
@export var ring_width: float = 200.0
@export var ring_height: float = 120.0
@export var ring_opening_start: float = -30.0
@export var ring_opening_end: float = 330.0

var player: Node2D
var current_target: Node2D

func initialize(player_ref: Node2D) -> void:
	player = player_ref

func set_target(target: Node2D) -> void:
	current_target = target

func fire_phaser() -> void:
	if not current_target:
		push_warning("Kein Target für Phaser!")
		return
	
	# Charge Effect erstellen
	var charge_effect = phaser_charge_scene.instantiate()
	player.get_parent().add_child(charge_effect)
	charge_effect.global_position = player.global_position
	
	# Schiffsspezifische Ring-Konfiguration anwenden
	charge_effect.set_ring_size(ring_width, ring_height)
	charge_effect.set_ring_opening(ring_opening_start, ring_opening_end)
	
	# Charge einrichten
	charge_effect.setup_charge(current_target.global_position)
	charge_effect.charge_completed.connect(_on_charge_completed.bind(charge_effect))

func _on_charge_completed(beam_start_point: Vector2, charge_effect: PhaserChargeEffect):
	# Phaser Beam erstellen
	var phaser_beam = phaser_beam_scene.instantiate()
	player.get_parent().add_child(phaser_beam)
	phaser_beam.global_position = beam_start_point
	phaser_beam.fire_beam(beam_start_point, current_target.global_position)
	
	# Charge Effect entfernen
	charge_effect.queue_free()

# Methode zum Wechseln der Schiffskonfiguration
func update_ship_config(ship_data: ShipData) -> void:
	if ship_data.has_method("get_phaser_ring_config"):
		# Hier könntest du ship-spezifische Konfiguration laden
		ring_width = ship_data.phaser_ring_width
		ring_height = ship_data.phaser_ring_height
		# etc.
