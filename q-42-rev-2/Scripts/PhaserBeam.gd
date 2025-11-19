# PhaserBeam.gd VERSION 2.0 - MIT TRACKING
extends Node2D

@export var beam_duration: float = 0.5  # Wie lange der Strahl sichtbar bleibt
@export var beam_fade_out: bool = true  # Soll der Strahl ausblenden?
@export var debug_mode: bool = true  # Debug-Visualisierung (zum Testen)
@export var track_target: bool = true  # Soll der Beam dem Ziel folgen?

@onready var background_beam: Line2D = $BackgroundBeam
@onready var main_beam: Line2D = $MainBeam
@onready var glow_effect: Sprite2D = $GlowEffect
@onready var timer: Timer = $Timer

var fade_time: float = 0.0
var is_fading: bool = false
var beam_start: Vector2
var beam_end: Vector2

# Tracking-Variablen
var start_node: Node2D  # Das Schiff / der Ring
var target_node: Node2D  # Der Gegner (optional)
var start_offset: Vector2  # Lokaler Offset zum Startpunkt
var use_global_end: bool = true  # Nutze fixe globale End-Position

func _ready():
	print("\n🚀 === PHASER BEAM READY ===")
	print("Beam Node: ", name)
	print("Global Position: ", global_position)
	
	# Node-Checks
	if not background_beam:
		push_error("❌ BackgroundBeam Node fehlt!")
	else:
		print("✅ BackgroundBeam gefunden")
	
	if not main_beam:
		push_error("❌ MainBeam Node fehlt!")
	else:
		print("✅ MainBeam gefunden")
	
	if not glow_effect:
		push_warning("⚠️ GlowEffect Node fehlt (optional)")
	else:
		print("✅ GlowEffect gefunden")
	
	if not timer:
		push_error("❌ Timer Node fehlt!")
	else:
		print("✅ Timer gefunden")
		timer.wait_time = beam_duration
		timer.one_shot = true
		timer.timeout.connect(_on_timer_timeout)
	
	# Add-Blend Material für Glow-Effekt erstellen
	_setup_blend_materials()
	
	# Falls kein Glow-Sprite vorhanden, erstelle eins
	if glow_effect and not glow_effect.texture:
		glow_effect.texture = _create_glow_texture()
		glow_effect.modulate = Color(1.0, 0.6, 0.2, 0.8)  # Orange Glow
	
	print("=========================\n")

func _process(delta):
	# Beam-Position kontinuierlich aktualisieren
	if track_target and not is_fading:
		_update_beam_position()
	
	if debug_mode:
		queue_redraw()
	
	if is_fading and beam_fade_out:
		fade_time += delta
		var alpha = 1.0 - (fade_time / 0.2)  # 0.2 Sekunden Fade-Out
		
		if main_beam:
			main_beam.modulate.a = alpha
		if background_beam:
			background_beam.modulate.a = alpha
		if glow_effect:
			glow_effect.modulate.a = alpha * 0.8
		
		if alpha <= 0.0:
			queue_free()

	# Beam aktualisieren
func _update_beam_position():
   # """Aktualisiert die Beam-Position kontinuierlich"""
	if not start_node or not is_instance_valid(start_node):
		return
	
	# Startpunkt korrekt berechnen (relativ zum Schiff)
	var current_start = start_node.global_position + start_offset.rotated(start_node.global_rotation)
	
	# Endpunkt: entweder fixer Punkt oder Target-Node
	var current_end = beam_end  # Default: fixe Position
	
	if target_node and is_instance_valid(target_node):
		# WICHTIG: Target verfolgen
		current_end = target_node.global_position
	else:
		# WENN KEIN TARGET NODE: Endpunkt relativ zum Schiff transformieren
		# Das bedeutet: Der Endpunkt "dreht sich mit" dem Schiff
		if use_global_end:
			# Berechne den ursprünglichen Offset vom Schiff zum Endpunkt
			var original_end_offset = beam_end - start_node.global_position
			# Wende die aktuelle Rotation des Schiffs an
			current_end = start_node.global_position + original_end_offset.rotated(start_node.global_rotation)
	
	# Debug alle 10 Frames
	if Engine.get_process_frames() % 10 == 0 and debug_mode:
		print("🔄 Beam Update:")
		print("   Ship pos: ", start_node.global_position)
		print("   Ship rot: ", rad_to_deg(start_node.global_rotation), "°")
		print("   Current start: ", current_start)
		print("   Current end: ", current_end)
		print("   Distance: ", current_start.distance_to(current_end))
		if target_node:
			print("   Tracking target: ", target_node.name)
		else:
			print("   Using fixed end point")
	
	# Beam aktualisieren
	_set_beam_line_points(current_start, current_end)
	
func _draw():
	"""Debug-Visualisierung"""
	if not debug_mode:
		return
	
	# Zeige Beam-Punkte
	if beam_start != Vector2.ZERO or beam_end != Vector2.ZERO:
		var local_start = to_local(beam_start)
		var local_end = to_local(beam_end)
		
		# Start-Punkt (GRÜN)
		draw_circle(local_start, 15, Color.GREEN)
		draw_circle(local_start, 12, Color.BLACK)
		
		# End-Punkt (ROT)
		draw_circle(local_end, 15, Color.RED)
		draw_circle(local_end, 12, Color.BLACK)
		
		# Verbindungslinie (MAGENTA)
		draw_line(local_start, local_end, Color.MAGENTA, 3.0)

func _setup_blend_materials():
	"""Erstellt Add-Blend Materials für Glow-Effekt"""
	print("\n🎨 Setting up Blend Materials...")
	
	# Material für Background Beam (Orange)
	if background_beam:
		var bg_material = CanvasItemMaterial.new()
		bg_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		bg_material.light_mode = CanvasItemMaterial.LIGHT_MODE_NORMAL
		background_beam.material = bg_material
		print("✅ BackgroundBeam Material: ADD Blend")
	
	# Material für Main Beam (Weiß)
	if main_beam:
		var main_material = CanvasItemMaterial.new()
		main_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		main_material.light_mode = CanvasItemMaterial.LIGHT_MODE_NORMAL
		main_beam.material = main_material
		print("✅ MainBeam Material: ADD Blend")
	
	# Material für Glow Effect
	if glow_effect:
		var glow_material = CanvasItemMaterial.new()
		glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED  # Heller
		glow_effect.material = glow_material
		print("✅ GlowEffect Material: ADD Blend")

func set_beam_points(start_point: Vector2, end_point: Vector2, ship_node: Node2D = null, enemy_node: Node2D = null):
   # """Setzt Start- und Endpunkt des Phaser-Strahls"""
	print("\n⚡ === SET_BEAM_POINTS AUFGERUFEN ===")
	print("Start Point (global): ", start_point)
	print("End Point (global): ", end_point)
	
	beam_start = start_point
	beam_end = end_point
	start_node = ship_node
	target_node = enemy_node  # WICHTIG: Target Node setzen für Tracking!
	
	# Berechne lokalen Offset vom Schiff zum Startpunkt
	if start_node:
		var relative_position = start_point - start_node.global_position
		start_offset = relative_position.rotated(-start_node.global_rotation)
		
		print("✅ Start Node gesetzt: ", start_node.name)
		print("   Target Node: ", target_node.name if target_node else "NONE")
	else:
		start_offset = Vector2.ZERO
		print("⚠️ Kein Start Node - Beam wird nicht mit Schiff mitbewegt")
	
	# Initiale Position setzen
	_set_beam_line_points(start_point, end_point)
	
	# Timer starten
	if timer:
		timer.start()
	
	print("=========================\n")

func _set_beam_line_points(start_point: Vector2, end_point: Vector2):
   # """Interne Funktion zum Setzen der Line2D Punkte"""
	# WICHTIG: Wenn Beam Child eines Schiffs ist, müssen wir die Position anders handhaben
	if get_parent() and get_parent() != get_tree().root:
		# Beam ist Child eines Schiffs → setze globale Position
		global_position = start_point  # ÄNDERUNG: globale Position setzen
	else:
		# Beam ist im Root → nutze globale Koordinaten
		global_position = start_point
	
	# In lokale Koordinaten umrechnen (relativ zum Beam selbst)
	var local_start = Vector2.ZERO  # Beam ist JA am Startpunkt
	var local_end = to_local(end_point)  # ÄNDERUNG: to_local verwenden für Endpunkt
	
	if debug_mode and Engine.get_process_frames() % 30 == 0:
		print("📍 _set_beam_line_points:")
		print("   Beam parent: ", get_parent().name if get_parent() else "ROOT")
		print("   Beam global_position: ", global_position)
		print("   Start (global): ", start_point)
		print("   End (global): ", end_point)
		print("   Local start: ", local_start)
		print("   Local end: ", local_end)
		print("   Distance: ", start_point.distance_to(end_point))
	
	# Hauptstrahl (weiß, dünn)
	if main_beam:
		main_beam.clear_points()
		main_beam.add_point(local_start)
		main_beam.add_point(local_end)
		main_beam.visible = true
	
	# Hintergrundstrahl (orange, dick)
	if background_beam:
		background_beam.clear_points()
		background_beam.add_point(local_start)
		background_beam.add_point(local_end)
		background_beam.visible = true
	
	# Glow-Effekt positionieren und skalieren
	if glow_effect:
		glow_effect.position = local_start
		glow_effect.visible = true
		
		# Kleinere, konstante Größe für den Glow
		var glow_scale = 0.3
		glow_effect.scale = Vector2(glow_scale, glow_scale)
		
		# Rotation zum Ziel
		if local_end != Vector2.ZERO:
			var angle = atan2(local_end.y, local_end.x)
			glow_effect.rotation = angle + PI/2

func _create_glow_texture() -> ImageTexture:
	"""Erstellt eine Glow-Textur falls keine vorhanden"""
	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var max_radius = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= max_radius:
				# Radialer Gradient
				var alpha = 1.0 - (dist / max_radius)
				alpha = pow(alpha, 2.0)  # Stärkerer Glow in der Mitte
				var pixel_color = Color(1.0, 1.0, 1.0, alpha)
				image.set_pixel(x, y, pixel_color)
	
	print("✅ Glow Texture erstellt (", size, "x", size, ")")
	return ImageTexture.create_from_image(image)

func _on_timer_timeout():
	print("⏱️ Timer abgelaufen - Beam wird", " ausgeblendet" if beam_fade_out else " gelöscht")
	
	if beam_fade_out:
		is_fading = true
		fade_time = 0.0
	else:
		queue_free()
