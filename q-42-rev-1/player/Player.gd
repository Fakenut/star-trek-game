# scripts/player/Player.gd
extends Node2D

@export var current_ship: PackedScene
@export var move_speed: float = 300.0

@onready var ship_container: Node2D = $ShipContainer

# VARIABLEN - jetzt als Node2D für maximale Flexibilität
var ship_instance: Node2D
var velocity: Vector2 = Vector2.ZERO
var current_speed: float = 0.0
var target_rotation: float = 0.0

# GESCHWINDIGKEITS-HOLD SYSTEM
var is_speed_locked: bool = false
var locked_velocity: Vector2 = Vector2.ZERO
var was_forward_pressed: bool = false
var was_backward_pressed: bool = false

# STANDARDWERTE FÜR SCHIFFE OHNE METHODEN
var default_max_speed: float = 300.0
var default_rotation_speed: float = 2.0
var default_acceleration: float = 200.0
var default_deceleration: float = 100.0
var default_drift_factor: float = 0.95

func _ready():
	print("Player initialisiert")
	
	if ship_container:
		ship_container.position = Vector2.ZERO
		print("🎯 ShipContainer reset to zero position")
	
	setup_camera()
	spawn_ship()

func _process(delta):
	handle_input(delta)
	handle_weapon_input()
	move_ship(delta)

# HELPER METHODS FÜR DYNAMISCHE KOMPOSITION
func get_ship_max_speed() -> float:
	if ship_instance and ship_instance.has_method("get_max_speed"):
		return ship_instance.get_max_speed()
	return default_max_speed

func get_ship_rotation_speed() -> float:
	if ship_instance and ship_instance.has_method("get_rotation_speed"):
		return ship_instance.get_rotation_speed()
	return default_rotation_speed

func get_ship_acceleration() -> float:
	if ship_instance and ship_instance.has_method("get_acceleration"):
		return ship_instance.get_acceleration()
	return default_acceleration

func get_ship_deceleration() -> float:
	if ship_instance and ship_instance.has_method("get_deceleration"):
		return ship_instance.get_deceleration()
	return default_deceleration

func get_ship_drift_factor() -> float:
	if ship_instance and ship_instance.has_method("get_drift_factor"):
		return ship_instance.get_drift_factor()
	return default_drift_factor

func get_ship_name() -> String:
	if ship_instance and ship_instance.has_method("get_ship_name"):
		return ship_instance.get_ship_name()
	elif ship_instance and "ship_name" in ship_instance:
		return ship_instance.ship_name
	return "Unbekanntes Schiff"

func can_ship_fire(weapon_index: int) -> bool:
	if ship_instance and ship_instance.has_method("can_fire"):
		return ship_instance.can_fire(weapon_index)
	return false

func fire_ship_weapon(weapon_index: int, start_pos: Vector2, target_pos: Vector2) -> bool:
	if ship_instance and ship_instance.has_method("fire_weapon"):
		return ship_instance.fire_weapon(weapon_index, start_pos, target_pos)
	return false

func handle_input(delta):
	if not ship_instance:
		return
		
	var rotation_input = 0.0
	var thrust_input = 0.0
	
	# Input sammeln
	if Input.is_action_pressed("move_left"):
		rotation_input -= 1.0
	if Input.is_action_pressed("move_right"):
		rotation_input += 1.0
		
	# Geschwindigkeits-Hold mit Input Map
	if Input.is_action_just_pressed("speed_hold"):
		toggle_speed_hold()
	
	# Vorwärts/Rückwärts Input - nur wenn nicht gesperrt
	if not is_speed_locked:
		if Input.is_action_pressed("move_forward"):
			thrust_input = 1.0
		if Input.is_action_pressed("move_backward"):
			thrust_input = -0.5
	else:
		# HOLD-BREAK: Bei JEDEM Vorwärts/Rückwärts Input
		var is_forward_pressed = Input.is_action_pressed("move_forward")
		var is_backward_pressed = Input.is_action_pressed("move_backward")
		
		if (is_forward_pressed and !was_forward_pressed) or (is_backward_pressed and !was_backward_pressed):
			toggle_speed_hold()
			if is_forward_pressed:
				thrust_input = 1.0
			if is_backward_pressed:
				thrust_input = -0.5
		
		was_forward_pressed = is_forward_pressed
		was_backward_pressed = is_backward_pressed

	# ROTATION (immer möglich)
	var previous_rotation = global_rotation
	if rotation_input != 0:
		var rotation_speed = get_ship_rotation_speed()
		global_rotation += rotation_input * rotation_speed * delta

	# BEWEGUNGS-LOGIK
	if is_speed_locked:
		# Locked Velocity mit Rotation aktualisieren
		if rotation_input != 0:
			var rotation_delta = global_rotation - previous_rotation
			locked_velocity = locked_velocity.rotated(rotation_delta)
		
		velocity = locked_velocity
	else:
		# Normale Bewegung
		if thrust_input != 0:
			var acceleration_rate = get_ship_acceleration()
			var max_speed_val = get_ship_max_speed()
			
			if thrust_input > 0:
				current_speed = move_toward(current_speed, max_speed_val, acceleration_rate * delta)
			else:
				current_speed = move_toward(current_speed, -max_speed_val * 0.5, acceleration_rate * delta * 0.7)
		else:
			var deceleration_rate = get_ship_deceleration()
			current_speed = move_toward(current_speed, 0, deceleration_rate * delta)
		
		# Velocity berechnen
		var forward_vector = Vector2.UP.rotated(global_rotation) * current_speed
		var drift_factor = get_ship_drift_factor()
		velocity = velocity.lerp(forward_vector, 1.0 - drift_factor * delta)
		
		# Reset der Hold-Break States
		was_forward_pressed = false
		was_backward_pressed = false

func toggle_speed_hold():
	if is_speed_locked:
		# Hold deaktivieren
		is_speed_locked = false
		locked_velocity = Vector2.ZERO
		was_forward_pressed = false
		was_backward_pressed = false
		print("🔓 Geschwindigkeits-Hold deaktiviert")
	else:
		# Hold aktivieren
		is_speed_locked = true
		var current_speed_magnitude = velocity.length()
		locked_velocity = velocity
		# Merken ob W/S schon gedrückt sind
		was_forward_pressed = Input.is_action_pressed("move_forward")
		was_backward_pressed = Input.is_action_pressed("move_backward")
		print("🔒 Geschwindigkeit gehalten: " + str(int(current_speed_magnitude)))

func move_ship(delta):
	global_position += velocity * delta


	# In Player.gd - CONTINUOUS FIRE
# scripts/player/Player.gd
func handle_weapon_input():
	if not ship_instance:
		return
		
	var ship_name = get_ship_name()
	
	# CONTINUOUS FIRE SYSTEM - Gedrückt halten
	if Input.is_action_just_pressed("primary_fire"):
		print("🔫 Starte Dauerfeuer")
		var target_pos = get_global_mouse_position()
		
		# Verwende die neue continuous fire Methode
		if ship_instance.has_method("start_continuous_fire"):
			ship_instance.start_continuous_fire(0, global_position, target_pos)
		else:
			print("❌ Schiff unterstützt kein Dauerfeuer")
	
	if Input.is_action_just_released("primary_fire"):
		print("🔫 Stoppe Dauerfeuer")
		if ship_instance.has_method("stop_continuous_fire"):
			ship_instance.stop_continuous_fire()
	
	# EINZELSCHUSS für sekundäre Waffe (bleibt gleich)
	if Input.is_action_just_pressed("secondary_fire"):
		print("🎯 Sekundärfeuer gedrückt")
		var target_pos = get_global_mouse_position()
		if can_ship_fire(1):
			print("✅ Waffe 1 kann feuern")
			var success = fire_ship_weapon(1, global_position, target_pos)
			print("💥 Torpedo-Ergebnis: ", success)
		else:
			print("⏳ Waffe 1 nicht bereit")

func add_screen_shake(intensity: float):
	# Später mit Camera-Shake System integrieren
	print("📳 Screen Shake: ", intensity)

func setup_camera():
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(0.8, 0.8)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)
	camera.make_current()
	print("📷 Camera setup complete")

func spawn_ship():
	if ship_instance:
		ship_instance.queue_free()
		ship_instance = null
	
	if current_ship:
		ship_instance = current_ship.instantiate()
		ship_container.add_child(ship_instance)
		
		# FIX: Ship Position zurücksetzen
		ship_instance.position = Vector2.ZERO
		
		# DEBUG AUSGABEN:
		print("=== SHIP SPAWN DEBUG ===")
		print("📍 Player Global Position: ", global_position)
		print("📍 Ship Instance Position: ", ship_instance.position)
		print("📍 Ship Name: ", get_ship_name())
		print("📍 Can Fire Method: ", ship_instance.has_method("can_fire"))
		print("📍 Fire Weapon Method: ", ship_instance.has_method("fire_weapon"))
		print("=== END DEBUG ===")
		
		print("🚀 Schiff gespawnt: " + get_ship_name())

func change_ship(new_ship_scene: PackedScene):
	if new_ship_scene:
		current_ship = new_ship_scene
		spawn_ship()
		print("🔄 Ship changed to: " + new_ship_scene.resource_path)
	else:
		push_error("❌ Cannot change to null ship scene!")

func set_current_ship(ship_scene: PackedScene, start_position: Vector2):
	current_ship = ship_scene
	global_position = start_position
	spawn_ship()
	print("✅ Ship set via set_current_ship")

# Damage forwarding
func take_damage(amount: float):
	if ship_instance and ship_instance.has_method("take_damage"):
		ship_instance.take_damage(amount)

# Debug Funktion
func _input(event):
	if event.is_action_pressed("debug_damage"):
		take_damage(25.0)
		print("Debug: 25 Schaden erhalten")
	
	if event.is_action_pressed("debug_kill"):
		take_damage(1000.0)
		print("Debug: Schiff zerstört")
	
	if event.is_action_pressed("debug_test_weapon"):
		print("🧪 TEST: Direkter Waffentest")
		if can_ship_fire(0):
			var target_pos = get_global_mouse_position()
			var success = fire_ship_weapon(0, global_position, target_pos)
			print("🧪 TEST Ergebnis: ", success)

# UI Status für spätere Controls-Config
func get_speed_status() -> String:
	if is_speed_locked:
		return "LOCKED: " + str(int(locked_velocity.length()))
	else:
		return "CURRENT: " + str(int(current_speed))

func get_control_config() -> Dictionary:
	return {
		"move_forward": "W",
		"move_backward": "S", 
		"move_left": "A",
		"move_right": "D",
		"primary_fire": "Mouse Left",
		"secondary_fire": "Mouse Right",
		"speed_hold": "C"
	}
