# Player.gd
extends Node2D
class_name Player

@export_group("Player Configuration")
@export var camera_zoom: float = 1.0
@export var camera_smoothing: float = 5.0

@onready var camera: Camera2D = $Camera2D
@onready var phaser_beam_scene = preload("res://weapons/PhaserBeam.tscn")

var current_ship: Node2D = null
var weapon_config: WeaponConfig = null

func _ready() -> void:
	setup_camera()
	print("🎮 Player template initialized")

func setup_camera() -> void:
	if not camera:
		push_error("Camera2D fehlt!")
		return
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = camera_smoothing
	camera.make_current()

# --- Waffenfeuer ---
func fire_weapon() -> void:
	if not current_ship or not weapon_config:
		return
	var ws = current_ship.get_node_or_null("WeaponSystem") as WeaponSystem
	if ws:
		ws.fire(get_global_mouse_position())  # Signal löst Beam aus

func _on_ws_weapon_fired(start_pos: Vector2, target_pos: Vector2) -> void:
	var beam = phaser_beam_scene.instantiate()
	get_tree().root.call_deferred("add_child", beam)
	if weapon_config:
		beam.beam_color = weapon_config.beam_color
		beam.with_charge = weapon_config.with_charge
	beam.fire(start_pos, target_pos)
	beam.beam_finished.connect(Callable(self, "_on_beam_finished"))

func _on_beam_finished() -> void:
	if weapon_config:
		print("Weapon fired: ", weapon_config.weapon_name)
	else:
		print("Weapon fired (no config)")

# --- Hilfsfunktion Emitter-Position ---
func _get_emitter_position() -> Vector2:
	if not current_ship:
		return global_position
	var ws = current_ship.get_node_or_null("WeaponSystem") as WeaponSystem
	if ws:
		return ws.get_emitter_global_position()
	return current_ship.global_position + Vector2(60, 0).rotated(current_ship.global_rotation)

# --- Schiff laden / wechseln ---
func set_current_ship(new_ship_scene: PackedScene, position: Vector2 = Vector2.ZERO) -> void:
	if current_ship:
		if camera.get_parent() == current_ship:
			current_ship.remove_child(camera)
			add_child(camera)
		remove_child(current_ship)
		current_ship.queue_free()

	current_ship = new_ship_scene.instantiate() as Node2D
	if not current_ship:
		push_error("set_current_ship: Instantiation failed or result is not Node2D")
		return
	current_ship.global_position = position if position != Vector2.ZERO else global_position
	add_child(current_ship)

	if camera.get_parent() == self:
		remove_child(camera)
		current_ship.add_child(camera)
		camera.position = Vector2.ZERO

	# PlayerController hinzufügen
	var controller = preload("res://player/PlayerController.gd").new()
	current_ship.add_child(controller)

	print("Ship loaded: ", current_ship.name, " | Weapon: ", weapon_config.weapon_name if weapon_config else "None")

func switch_ship(new_ship_scene: PackedScene, position: Vector2 = Vector2.ZERO) -> void:
	set_current_ship(new_ship_scene, position)

# --- Input-Handling über Actions ---
func _process(_delta):
	# Phaser feuern
	if Input.is_action_just_pressed("fire_phaser"):
		fire_weapon()

	# Spezialfähigkeit
	if Input.is_action_just_pressed("special_ability"):
		if current_ship and current_ship.has_method("launch_science_probe"):
			current_ship.launch_science_probe()
