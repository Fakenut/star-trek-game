# res://Scripts/Modules/InputHandler.gd
class_name InputHandler
extends Node

# Input Actions
const MOVE_LEFT := "move_left"
const MOVE_RIGHT := "move_right"
const MOVE_FORWARD := "move_forward"
const MOVE_BACKWARD := "move_backward"
const SPEED_HOLD := "speed_hold"

# Referenzen
var movement_module: MovementModule

# Input State
var rotation_input := 0.0
var thrust_input := 0.0
var speed_hold_just_pressed := false

func initialize(movement_ref: MovementModule) -> void:
	movement_module = movement_ref

func process_input() -> void:
	# Reset inputs
	rotation_input = 0.0
	thrust_input = 0.0
	speed_hold_just_pressed = false

	# Rotation Input
	if Input.is_action_pressed(MOVE_LEFT):  rotation_input -= 1.0
	if Input.is_action_pressed(MOVE_RIGHT): rotation_input += 1.0

	# Speed Hold Toggle
	if Input.is_action_just_pressed(SPEED_HOLD):
		speed_hold_just_pressed = true
		movement_module.toggle_speed_hold()

	# Thrust Input (abhängig von Speed Hold State)
	if not movement_module.is_speed_locked:
		if Input.is_action_pressed(MOVE_FORWARD):   thrust_input = 1.0
		if Input.is_action_pressed(MOVE_BACKWARD):  thrust_input = -0.5
	else:
		# Special handling für Speed Hold Mode
		var fwd = Input.is_action_pressed(MOVE_FORWARD)
		var back = Input.is_action_pressed(MOVE_BACKWARD)
		
		if (fwd and not movement_module.was_forward_pressed) or (back and not movement_module.was_backward_pressed):
			movement_module.toggle_speed_hold()
			if fwd:  thrust_input = 1.0
			if back: thrust_input = -0.5
		
		movement_module.was_forward_pressed = fwd
		movement_module.was_backward_pressed = back

func get_rotation_input() -> float:
	return rotation_input

func get_thrust_input() -> float:
	return thrust_input

func is_speed_hold_just_pressed() -> bool:
	return speed_hold_just_pressed
