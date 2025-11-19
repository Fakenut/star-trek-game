# res://Scripts/Modules/MovementModule.gd
class_name MovementModule
extends Node

# Exportierte Bewegungswerte
@export var max_speed : float = 450.0
@export var rotation_speed : float = 3.8
@export var acceleration : float = 800.0
@export var deceleration : float = 400.0
@export var drift_factor : float = 0.94

# Referenzen
var player: Node2D

# Bewegungswerte
var velocity : Vector2 = Vector2.ZERO
var current_speed : float = 0.0
var is_speed_locked : bool = false
var locked_velocity : Vector2 = Vector2.ZERO
var was_forward_pressed : bool = false
var was_backward_pressed : bool = false

func initialize(player_ref: Node2D) -> void:
	player = player_ref

func process_movement(delta: float, rotation_input: float, thrust_input: float) -> void:
	if not player: return
	
	# Rotation
	if rotation_input != 0:
		var prev_rot = player.global_rotation
		player.global_rotation += rotation_input * rotation_speed * delta
		if is_speed_locked:
			var delta_rot = player.global_rotation - prev_rot
			locked_velocity = locked_velocity.rotated(delta_rot)

	# Speed Hold handling
	if is_speed_locked:
		velocity = locked_velocity
		return

	# Geschwindigkeit berechnen
	if thrust_input != 0:
		if thrust_input > 0:
			current_speed = move_toward(current_speed, max_speed, acceleration * delta)
		else:
			current_speed = move_toward(current_speed, -max_speed * 0.5, acceleration * delta * 0.7)
	else:
		current_speed = move_toward(current_speed, 0, deceleration * delta)

	# Velocity anwenden
	var desired = Vector2.UP.rotated(player.global_rotation) * current_speed
	velocity = velocity.lerp(desired, 1.0 - drift_factor * delta)

	# Reset input flags wenn nicht locked
	if not is_speed_locked:
		was_forward_pressed = false
		was_backward_pressed = false

func toggle_speed_hold() -> void:
	is_speed_locked = !is_speed_locked
	if is_speed_locked:
		locked_velocity = velocity
		print("LOCKED →", int(velocity.length()))
	else:
		locked_velocity = Vector2.ZERO
		was_forward_pressed = false
		was_backward_pressed = false
		print("UNLOCKED")

func get_velocity() -> Vector2:
	return velocity

func set_velocity(new_velocity: Vector2) -> void:
	velocity = new_velocity

func get_current_speed() -> float:
	return current_speed
