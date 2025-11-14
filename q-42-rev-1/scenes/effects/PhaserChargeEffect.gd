# scripts/effects/PhaserChargeEffect.gd
extends Node2D

@onready var particles: CPUParticles2D = $ChargeParticles
@onready var sprite: Sprite2D = $ChargeSprite

var charge_time: float = 0.2
var current_charge: float = 0.0
var is_charging: bool = false

func _ready():
	hide()
	particles.emitting = false

func start_charge():
	is_charging = true
	current_charge = 0.0
	show()
	particles.emitting = true
	# Skaliere basierend auf Ladung
	sprite.scale = Vector2(0.1, 0.1)
	
func update_charge(delta: float):
	if not is_charging:
		return
		
	current_charge += delta
	var charge_ratio = current_charge / charge_time
	
	# Skaliere Sprite mit Ladung
	sprite.scale = Vector2(charge_ratio * 0.5, charge_ratio * 0.5)
	
	# Ändere Farbe mit Ladung (blau -> weiß)
	sprite.modulate = Color(1 - charge_ratio, 1 - charge_ratio, 1.0, 1.0)
	
	if current_charge >= charge_time:
		complete_charge()

func complete_charge():
	is_charging = false
	particles.emitting = false
	# Kleiner Blitz-Effekt bevor es verschwindet
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2(0.8, 0.8)
	
	# Nach kurzer Zeit ausblenden
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.1)
	tween.tween_callback(hide)

func stop_charge():
	is_charging = false
	hide()
	particles.emitting = false
