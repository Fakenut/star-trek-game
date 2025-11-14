# scripts/ships/GalaxyClass.gd
extends ShipTemplate



# PHASER START PUNKTE - Relative Positionen zum Schiff
var phaser_positions = {
	"forward": Vector2(0, -50),    # Vorne auf dem Ring
	"left": Vector2(-40, -30),     # Links auf dem Ring  
	"right": Vector2(40, -30)      # Rechts auf dem Ring
}

# PHASER NODES - werden im _ready() gesetzt
var phaser_nodes = {}


func _ready():
	# ZUERST Basis-Klasse initialisieren lassen
	super._ready()
	
	# DANACH Galaxy Class spezifische Werte setzen
	ship_name = "Enterprise"
	max_health = 200.0
	max_speed = 600.0
	rotation_speed = 4.0
	acceleration = 300.0
	deceleration = 150.0
	drift_factor = 0.92
	
	print("🛸 Galaxy Class initialized - Majestätisch und kampfstark!")
	print("📊 Stats - Health: ", max_health, " Speed: ", max_speed, " Rotation: ", rotation_speed)

 # Phaser Startpunkte erstellen
	setup_phaser_positions()
	
	print("🛸 Galaxy Class initialized - Majestätisch und kampfstark!")
	print("🎯 Phaser Positions: ", phaser_positions)
	
func setup_phaser_positions():
	# Erstelle Node2D für jede Phaser-Position
	for position_name in phaser_positions.keys():
		var node = Node2D.new()
		node.name = "PhaserPosition_" + position_name
		node.position = phaser_positions[position_name]
		add_child(node)
		phaser_nodes[position_name] = node
		print("✅ Phaser Position created: ", position_name, " at ", phaser_positions[position_name])

# BESTIMME PHASER-POSITION BASIEREND AUF ZIELRICHTUNG
func get_phaser_position(target_angle: float) -> String:
	# Winkel relativ zum Schiff (0° = vorne, 90° = rechts, -90° = links)
	var relative_angle = fmod(target_angle - global_rotation + PI, 2 * PI) - PI
	
	if abs(relative_angle) < PI/4:  # ±45° vorne
		return "forward"
	elif relative_angle > 0:        # Rechts
		return "right"
	else:                           # Links
		return "left"

func get_phaser_global_position(position_name: String) -> Vector2:
	if position_name in phaser_nodes:
		return phaser_nodes[position_name].global_position
	return global_position  # Fallback


# Weapon API - können überschrieben werden falls benötigt
func fire_weapon(weapon_index: int, start_position: Vector2, target_position: Vector2) -> bool:
	print("🔄 Galaxy Class firing weapon: ", weapon_index)
	return super.fire_weapon(weapon_index, start_position, target_position)

# Movement API - können überschrieben werden falls benötigt
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

# Damage System - können überschrieben werden
func take_damage(amount: float):
	print("🛡️ Galaxy Class taking damage: ", amount)
	super.take_damage(amount)

# Galaxy Class spezifische Funktionen
func activate_deflector_shield():
	print("🛡️ Deflector Shield activated! Energy field stabilizing...")

func activate_saucer_separation():
	print("🚀 Saucer Separation initiated! Primary hull detaching...")

func emergency_evacuation():
	print("🚨 Emergency evacuation procedures activated! All hands to escape pods!")

# Override der destroy Methode für spezielles Verhalten
func destroy():
	print("💥 CRITICAL DAMAGE! Galaxy Class destruction imminent!")
	print("🚨 Activating emergency protocols...")
	print("🛟 Escape pods launching...")
	print("📡 Distress beacon activated...")
	
	# Spezielle Zerstörungs-Logik für Galaxy Class
	super.destroy()

# Spezielle Galaxy Class Fähigkeiten
func long_range_scan():
	print("📡 Long range scan initiated...")

func tractor_beam(target_position: Vector2):
	print("🧲 Tractor beam engaged on target: ", target_position)

# Debug Funktionen
func _input(event):
	if event.is_action_pressed("debug_shield"):
		activate_deflector_shield()
	
	if event.is_action_pressed("debug_separation"):
		activate_saucer_separation()
	
	if event.is_action_pressed("debug_scan"):
		long_range_scan()
