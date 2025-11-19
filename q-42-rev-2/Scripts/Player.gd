# res://Scripts/Player.gd
extends Node2D
class_name Player

# Module
var movement_module: MovementModule
var input_handler: InputHandler
var ship_manager: ShipManager
var camera_manager: CameraManager

# Export für Inspector
@export var ship_scene : PackedScene : set = set_ship_scene
@export var current_ship_data : ShipData : set = set_ship_data

func _ready() -> void:
	initialize_modules()
	setup_camera()

func initialize_modules() -> void:
	# Movement Module
	movement_module = MovementModule.new()
	add_child(movement_module)
	movement_module.initialize(self)
	
	# Input Handler
	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.initialize(movement_module)
	
	# Ship Manager
	ship_manager = ShipManager.new()
	add_child(ship_manager)
	ship_manager.initialize(self, "ShipContainer")
	
	# Apply exported values after module initialization
	if ship_scene:
		ship_manager.ship_scene = ship_scene
	if current_ship_data:
		ship_manager.current_ship_data = current_ship_data

func setup_camera() -> void:
	camera_manager = CameraManager.new()
	add_child(camera_manager)
	camera_manager.initialize(self)

func _process(delta: float) -> void:
	if not ship_manager.get_current_ship(): 
		return
	
	# Input verarbeiten
	input_handler.process_input()
	
	# Bewegung verarbeiten
	movement_module.process_movement(
		delta,
		input_handler.get_rotation_input(),
		input_handler.get_thrust_input()
	)
	
	# Position aktualisieren
	global_position += movement_module.get_velocity() * delta

# Public Methoden für externe Zugriffe
func update_movement_stats(max_s: float, rot_s: float, accel: float, decel: float, drift: float) -> void:
	if movement_module:
		movement_module.max_speed = max_s
		movement_module.rotation_speed = rot_s
		movement_module.acceleration = accel
		movement_module.deceleration = decel
		movement_module.drift_factor = drift

func change_ship(new_ship_data: ShipData, keep_velocity: bool = true) -> void:
	if keep_velocity:
		var current_vel = movement_module.get_velocity()
		var current_locked = movement_module.is_speed_locked
		var current_locked_vel = movement_module.locked_velocity
		
		ship_manager.change_ship(new_ship_data)
		
		movement_module.set_velocity(current_vel)
		movement_module.is_speed_locked = current_locked
		movement_module.locked_velocity = current_locked_vel
	else:
		ship_manager.change_ship(new_ship_data)

# Setter für Export Variablen
func set_ship_scene(scene: PackedScene) -> void:
	ship_scene = scene
	if ship_manager:
		ship_manager.ship_scene = scene

func set_ship_data(data: ShipData) -> void:
	current_ship_data = data
	if ship_manager:
		ship_manager.current_ship_data = data

# Getter für andere Systeme
func get_movement_module() -> MovementModule:
	return movement_module

func get_ship_manager() -> ShipManager:
	return ship_manager
