# PlayerController.gd
extends Node
class_name PlayerController

# --- Bewegungswerte ---
var impulse_speed: float = 0.0
var warp_speed: float = 0.0
var rotation_speed: float = 0.0
var accel: float = 0.0

# --- Zustandsvariablen ---
var current_speed: float = 0.0
var is_using_warp: bool = false

# --- Input ---
var thrust_direction: float = 0.0
var rotation_direction: float = 0.0

# --- Referenzen ---
var ship: CharacterBody2D

func _ready():
	ship = get_parent() as CharacterBody2D
	if ship:
		_load_ship_stats()
		switch_to_impulse()
		print("🎮 PlayerController ready for: ", _get_ship_name())
	else:
		push_error("❌ PlayerController needs a CharacterBody2D parent!")

func _load_ship_stats():
	impulse_speed = ship.impulse_speed if ship.get("impulse_speed") != null else 300.0
	warp_speed = ship.warp_speed if ship.get("warp_speed") != null else 1000.0
	rotation_speed = ship.rotation_speed if ship.get("rotation_speed") != null else 2.0
	accel = ship.accel if ship.get("accel") != null else 800.0

func _input(event):
	if Input.is_action_just_pressed("warp_drive"):
		if is_using_warp:
			deactivate_warp_drive()
		else:
			activate_warp_drive()

	if Input.is_action_just_pressed("special_ability") and ship.has_method("launch_science_probe"):
		ship.launch_science_probe()

func _physics_process(delta):
	if ship:
		handle_input()
		apply_movement(delta)

func handle_input() -> void:
	rotation_direction = 0.0
	if Input.is_action_pressed("move_left"):
		rotation_direction -= 1.0
	if Input.is_action_pressed("move_right"):
		rotation_direction += 1.0

	thrust_direction = 0.0
	if Input.is_action_pressed("move_forward"):
		thrust_direction += 1.0
	if Input.is_action_pressed("move_backward"):
		thrust_direction -= 1.0

func apply_movement(delta: float) -> void:
	ship.rotation += rotation_direction * rotation_speed * delta
	var forward: Vector2 = Vector2.UP.rotated(ship.rotation)
	
	if thrust_direction != 0.0:
		var target_velocity = forward * thrust_direction * current_speed
		ship.velocity = ship.velocity.move_toward(target_velocity, accel * delta)
	else:
		ship.velocity = ship.velocity.rotated(rotation_direction * rotation_speed * delta)

	ship.move_and_slide()

# --- Warp / Impulse ---
func switch_to_impulse() -> void:
	is_using_warp = false
	current_speed = impulse_speed

func switch_to_warp() -> void:
	is_using_warp = true
	current_speed = warp_speed

func activate_warp_drive() -> void:
	switch_to_warp()
	print("🌠 Warp drive engaged!")

func deactivate_warp_drive() -> void:
	switch_to_impulse()
	print("🌠 Warp drive disengaged")

func _get_ship_name() -> String:
	return ship.get_ship_name() if ship.has_method("get_ship_name") else "Unknown Ship"
