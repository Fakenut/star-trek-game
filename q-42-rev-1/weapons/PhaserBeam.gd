# scripts/weapons/PhaserBeam.gd
extends Node2D

# Referenzen zu Nodes
@onready var main_beam: Line2D = $MainBeam
@onready var background_beam: Line2D = $BackgroundBeam
@onready var glow_effect: Node2D = $GlowEffect
@onready var glow_sprite: Sprite2D = $GlowEffect/GlowSprite
@onready var timer: Timer = $Timer

# Waffen-Konfiguration
var weapon_config: WeaponConfig

# In PhaserBeam.gd - NEUE METHODEN
var is_persistent: bool = false
var persistent_start_node: Node2D
var persistent_target_node: Node2D


func _ready():
	# Unsichtbar starten
	hide()
	
	# Timer connection
	timer.timeout.connect(_on_timer_timeout)

# Setup mit WeaponConfig
func setup(config: WeaponConfig):
	weapon_config = config
	setup_beam_properties()

func setup_beam_properties():
	if not weapon_config:
		return
		
	# HINTERGRUND Beam (orange) - breit
	background_beam.width = weapon_config.background_width
	background_beam.default_color = weapon_config.beam_color
	background_beam.z_index = 1
	
	# HAUPT Beam (weiß) - schmal
	main_beam.width = weapon_config.beam_width
	main_beam.default_color = Color.WHITE
	main_beam.z_index = 2  # Vor dem Hintergrund
	
	# GLOW Effekt
	glow_sprite.modulate = weapon_config.beam_color
	glow_sprite.modulate.a = weapon_config.glow_intensity
	glow_effect.z_index = 0  # Ganz hinten
	
	# Timer einstellen
	timer.wait_time = weapon_config.beam_duration

# Beam abfeuern
func fire_beam(start_pos: Vector2, target_pos: Vector2, is_charged: bool = false):
	global_position = start_pos
	
	# Bei aufgeladener Waffe stärkeren Beam
	if is_charged and weapon_config.with_charge:
		main_beam.width = weapon_config.charged_beam_width
		background_beam.default_color = weapon_config.charged_color
		glow_sprite.modulate = weapon_config.charged_color
	
	# Beam-Punkte setzen
	var local_target = to_local(target_pos)
	
	main_beam.clear_points()
	background_beam.clear_points()
	
	main_beam.add_point(Vector2.ZERO)
	main_beam.add_point(local_target)
	background_beam.add_point(Vector2.ZERO) 
	background_beam.add_point(local_target)
	
	# Glow-Effekt positionieren
	setup_glow_effect(local_target)
	
	# Anzeigen und Timer starten
	show()
	timer.start()

# Glow-Effekt zwischen Start und Ziel positionieren
func setup_glow_effect(local_target: Vector2):
	var beam_length = local_target.length()
	var beam_angle = local_target.angle()
	
	# Glow in der Mitte des Beams positionieren
	glow_effect.position = local_target * 0.5
	glow_effect.rotation = beam_angle
	
	# Glow skalieren (Länge = Beam-Länge, Breite = Beam-Breite)
	if glow_sprite.texture:
		glow_sprite.scale.x = beam_length / glow_sprite.texture.get_width()
		glow_sprite.scale.y = background_beam.width / glow_sprite.texture.get_height()

func _on_timer_timeout():
	# Beam ausblenden und freigeben
	hide()
	
func _process(delta):
	if is_persistent and persistent_start_node and persistent_target_node:
		# Aktualisiere Positionen kontinuierlich
		var start_pos = persistent_start_node.global_position
		var target_pos = persistent_target_node.global_position
		fire_beam(start_pos, target_pos)
