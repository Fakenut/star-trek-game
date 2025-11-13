# PhaserBeam.gd
extends Node2D

@onready var main_beam: Line2D = $Line2D
@onready var background_beam: Line2D = $Line2D2
@onready var glow_effect: Node2D = $GlowEffect
@onready var glow_sprite: Sprite2D = $GlowEffect/Sprite2D
@onready var timer: Timer = $Timer

var weapon_config: WeaponConfig

func setup(config: WeaponConfig):
	weapon_config = config
	setup_beam_properties()

func setup_beam_properties():
	# Hauptbeam
	main_beam.width = weapon_config.beam_width
	main_beam.default_color = Color.WHITE
	
	# Hintergrundbeam mit WeaponConfig-Farbe
	background_beam.width = weapon_config.background_width
	background_beam.default_color = weapon_config.beam_color
	
	# Glow-Effekt
	glow_sprite.modulate = weapon_config.beam_color
	glow_sprite.modulate.a = weapon_config.glow_intensity
	
	# Timer einstellen
	timer.wait_time = weapon_config.beam_duration

func fire_beam(start_pos: Vector2, target_pos: Vector2, is_charged: bool = false):
	if is_charged and weapon_config.with_charge:
		main_beam.width = weapon_config.charged_beam_width
		background_beam.default_color = weapon_config.charged_color
		glow_sprite.modulate = weapon_config.charged_color
	
	global_position = start_pos
	var local_target = to_local(target_pos)
	
	# Beams zeichnen
	main_beam.clear_points()
	background_beam.clear_points()
	main_beam.add_point(Vector2.ZERO)
	main_beam.add_point(local_target)
	background_beam.add_point(Vector2.ZERO)
	background_beam.add_point(local_target)
	
	# Glow-Effekt
	setup_glow_effect(local_target)
	
	show()
	timer.start()

func setup_glow_effect(local_target: Vector2):
	var beam_length = local_target.length()
	var beam_angle = local_target.angle()
	
	glow_effect.position = local_target * 0.5
	glow_effect.rotation = beam_angle
	glow_sprite.scale.x = beam_length / glow_sprite.texture.get_width()
	glow_sprite.scale.y = background_beam.width / glow_sprite.texture.get_height()

func _on_timer_timeout():
	hide()
	# Optional: Signal emitieren dass Beam fertig ist für Pooling
