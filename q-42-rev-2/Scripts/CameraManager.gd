# res://Scripts/Modules/CameraManager.gd
class_name CameraManager
extends Node

@export var zoom_level : Vector2 = Vector2(0.8, 0.8)
@export var smoothing_enabled : bool = true
@export var smoothing_speed : float = 6.0

var camera: Camera2D
var player: Node2D

func initialize(player_ref: Node2D) -> void:
	player = player_ref
	setup_camera()

func setup_camera() -> void:
	if not player.has_node("Camera2D"):
		camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.zoom = zoom_level
		camera.position_smoothing_enabled = smoothing_enabled
		camera.position_smoothing_speed = smoothing_speed
		player.add_child(camera)
		camera.make_current()
	else:
		camera = player.get_node("Camera2D")

func set_zoom(new_zoom: Vector2) -> void:
	if camera:
		camera.zoom = new_zoom

func set_smoothing_speed(speed: float) -> void:
	if camera:
		camera.position_smoothing_speed = speed
