# EditableRing.gd
extends Node2D

# Exportierte Variablen für Inspector
@export var particle_travel_time: float = 0.2  # Zeit in Sekunden bis zum Treffpunkt
@export var particle_color: Color = Color(1.0, 0.8, 0.3)  # Orange/Gelb
@export var particle_size: float = 8.0
@export var debug_mode: bool = true  # Zeigt Debug-Visualisierung

# Referenzen zu Child-Nodes
@onready var curve_points: Node2D = $CurvePoints
@onready var line_2d: Line2D = $Line2D
@onready var path_2d: Path2D = $Path2D
@onready var path_follow_1: PathFollow2D = $Path2D/PathFollow2D
@onready var path_follow_2: PathFollow2D = $Path2D/PathFollow2D2
@onready var sprite_1: Sprite2D = $Path2D/PathFollow2D/Sprite2D
@onready var sprite_2: Sprite2D = $Path2D/PathFollow2D2/Sprite2D

# Phaser Beam Szene (wird später geladen)
var phaser_beam_scene: PackedScene

# Bewegungsvariablen
var is_moving: bool = false
var elapsed_time: float = 0.0
var meeting_point_progress: float = 0.0  # 0.0 bis 1.0 auf dem Path
var distance_1: float = 0.0  # Distanz von Start zu Treffpunkt
var distance_2: float = 0.0  # Distanz von Ende zu Treffpunkt

# Debug-Variablen
var debug_start_point: Vector2
var debug_end_point: Vector2
var debug_meeting_point: Vector2
var debug_particle1_start: Vector2
var debug_particle2_start: Vector2
var debug_enemy_position: Vector2

func _ready():
	# Curve aus Path2D in Line2D übertragen
	_update_line_from_path()
	
	# Partikel-Sprites konfigurieren
	_setup_particle_sprites()
	
	# WICHTIG: Sprites müssen exakt auf PathFollow2D Position sein
	sprite_1.position = Vector2.ZERO
	sprite_2.position = Vector2.ZERO
	
	# PathFollow2D Einstellungen sicherstellen
	path_follow_1.rotates = false
	path_follow_2.rotates = false
	path_follow_1.loop = false
	path_follow_2.loop = false
	
	# Sprites initial verstecken
	sprite_1.visible = false
	sprite_2.visible = false
	
	# Phaser Beam Szene laden - versuche verschiedene Pfade
	_load_phaser_beam_scene()

func _load_phaser_beam_scene():
	"""Lädt die PhaserBeam Szene mit Fehlerbehandlung"""
	print("\n🔍 === LADE PHASER BEAM SZENE ===")
	
	# Mögliche Pfade (angepasst für dein Projekt)
	var possible_paths = [
		"res://Scenes/Weapons/PhaserBeam.tscn",  # Dein Pfad
		"res://scenes/weapons/PhaserBeam.tscn",  # Kleinbuchstaben
		"res://Scenes/Weapons/phaser_beam.tscn",
		"res://PhaserBeam.tscn",
		"res://scenes/PhaserBeam.tscn",
		"res://weapons/PhaserBeam.tscn"
	]
	
	for path in possible_paths:
		if FileAccess.file_exists(path):
			phaser_beam_scene = load(path)
			if phaser_beam_scene:
				print("✅ PhaserBeam.tscn erfolgreich geladen von: ", path)
				return
	
	# Wenn nichts gefunden wurde
	push_error("❌ FEHLER: PhaserBeam.tscn nicht gefunden!")
	print("❌ Gesucht in folgenden Pfaden:")
	for path in possible_paths:
		print("   - ", path)
	print("\n💡 LÖSUNG:")
	print("1. Stelle sicher, dass PhaserBeam.tscn existiert")
	print("2. Speichere sie in: res://Scenes/Weapons/")
	print("3. Oder passe den Pfad im Code an")
	print("====================================\n")

func _process(delta):
	# Curve kontinuierlich aktualisieren (für Editor-Änderungen)
	if Engine.is_editor_hint():
		_update_line_from_path()
	
	# Debug-Visualisierung
	if debug_mode:
		queue_redraw()
	
	# Partikel-Bewegung
	if is_moving:
		elapsed_time += delta
		var progress = clamp(elapsed_time / particle_travel_time, 0.0, 1.0)
		
		var curve = path_2d.curve
		var total_length = curve.get_baked_length()
		var meeting_point_offset = meeting_point_progress * total_length
		
		# Partikel 1: fährt von Offset 0 zu meeting_point_offset (VORWÄRTS)
		var new_position_1 = progress * distance_1
		path_follow_1.progress = new_position_1
		
		# Partikel 2: fährt von total_length zu meeting_point_offset (RÜCKWÄRTS)
		var new_position_2 = total_length - (progress * distance_2)
		path_follow_2.progress = new_position_2
		
		# Debug output jedes Frame
		if debug_mode and int(elapsed_time * 10) % 5 == 0:  # Alle 0.5 Sekunden
			print("Progress: %.2f | P1: %.1f | P2: %.1f | Target: %.1f" % [progress, new_position_1, new_position_2, meeting_point_offset])
		
		# Wenn angekommen
		if progress >= 1.0:
			is_moving = false
			# Finale Positionen exakt setzen
			path_follow_1.progress = meeting_point_offset
			path_follow_2.progress = meeting_point_offset
			_on_particles_arrived()

func _draw():
	"""Debug-Visualisierung"""
	if not debug_mode:
		return
	
	var curve = path_2d.curve
	if not curve:
		return
	
	# Start-Punkt (GRÜN)
	debug_start_point = curve.sample_baked(0.0)
	draw_circle(debug_start_point, 12, Color.GREEN)
	draw_circle(debug_start_point, 10, Color.BLACK)
	_draw_label(debug_start_point + Vector2(0, -20), "START", Color.GREEN)
	
	# End-Punkt (ROT)
	debug_end_point = curve.sample_baked(curve.get_baked_length())
	draw_circle(debug_end_point, 12, Color.RED)
	draw_circle(debug_end_point, 10, Color.BLACK)
	_draw_label(debug_end_point + Vector2(0, -20), "END", Color.RED)
	
	# Treffpunkt (GELB)
	if is_moving or meeting_point_progress > 0.0:
		debug_meeting_point = curve.sample_baked(meeting_point_progress * curve.get_baked_length())
		draw_circle(debug_meeting_point, 15, Color.YELLOW)
		draw_circle(debug_meeting_point, 12, Color.BLACK)
		_draw_label(debug_meeting_point + Vector2(0, -25), "MEETING", Color.YELLOW)
	
	# Gegner-Position (MAGENTA)
	if debug_enemy_position != Vector2.ZERO:
		var local_enemy = to_local(debug_enemy_position)
		draw_circle(local_enemy, 10, Color.MAGENTA)
		draw_line(debug_meeting_point, local_enemy, Color.MAGENTA, 2.0)
		_draw_label(local_enemy + Vector2(0, -20), "ENEMY", Color.MAGENTA)
	
	# AKTUELLE Partikel-Positionen (LIVE während Bewegung)
	if is_moving:
		# Partikel 1 aktuelle Position (HELLBLAU) - kleiner Marker
		var p1_pos = curve.sample_baked(path_follow_1.progress)
		draw_circle(p1_pos, 5, Color(0.3, 0.7, 1.0, 0.5))
		_draw_label(p1_pos + Vector2(20, 0), "P1: %.0f" % path_follow_1.progress, Color.CYAN)
		
		# Partikel 2 aktuelle Position (PINK) - kleiner Marker
		var p2_pos = curve.sample_baked(path_follow_2.progress)
		draw_circle(p2_pos, 5, Color(1.0, 0.0, 1.0, 0.5))
		_draw_label(p2_pos + Vector2(20, 0), "P2: %.0f" % path_follow_2.progress, Color(1.0, 0.0, 1.0))
		
		# Distanz-Linien zu den Startpunkten
		draw_line(debug_start_point, debug_meeting_point, Color.CYAN, 1.0, true)
		draw_line(debug_end_point, debug_meeting_point, Color(1.0, 0.0, 1.0), 1.0, true)
		
		# Distanz-Text an den Startpunkten
		_draw_label(debug_start_point + Vector2(0, 15), "D1: %.0f" % distance_1, Color.CYAN)
		_draw_label(debug_end_point + Vector2(0, 15), "D2: %.0f" % distance_2, Color(1.0, 0.0, 1.0))

func _draw_label(pos: Vector2, text: String, color: Color):
	"""Hilfsfunktion zum Zeichnen von Text"""
	# Hintergrund (schwarz, halbtransparent)
	var font = ThemeDB.fallback_font
	var font_size = 14
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var rect = Rect2(pos - Vector2(text_size.x / 2, text_size.y), text_size + Vector2(4, 2))
	draw_rect(rect, Color(0, 0, 0, 0.7))
	
	# Text
	draw_string(font, pos - Vector2(text_size.x / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _update_line_from_path():
	"""Synchronisiert Line2D mit Path2D Curve"""
	if not path_2d or not line_2d:
		return
	
	var curve = path_2d.curve
	if not curve:
		return
	
	# Line2D Punkte löschen und neu setzen
	line_2d.clear_points()
	
	# Kurve in kleine Segmente unterteilen für glatte Darstellung
	var point_count = 64
	for i in range(point_count + 1):
		var progress = float(i) / float(point_count)
		var point = curve.sample_baked(progress * curve.get_baked_length())
		line_2d.add_point(point)

func _setup_particle_sprites():
	"""Erstellt einfache Partikel-Sprites (Kreise)"""
	# Sprite 1
	var texture1 = _create_circle_texture(particle_size, particle_color)
	sprite_1.texture = texture1
	sprite_1.centered = true
	sprite_1.position = Vector2.ZERO  # WICHTIG: Keine lokale Offset-Position
	
	# Sprite 2
	var texture2 = _create_circle_texture(particle_size, particle_color)
	sprite_2.texture = texture2
	sprite_2.centered = true
	sprite_2.position = Vector2.ZERO  # WICHTIG: Keine lokale Offset-Position
	
	# Debug-Info
	print("\n=== SPRITE SETUP ===")
	print("Sprite 1 local position: ", sprite_1.position)
	print("Sprite 2 local position: ", sprite_2.position)
	print("PathFollow1 rotates: ", path_follow_1.rotates)
	print("PathFollow2 rotates: ", path_follow_2.rotates)
	print("PathFollow1 loop: ", path_follow_1.loop)
	print("PathFollow2 loop: ", path_follow_2.loop)
	print("==================\n")

func _create_circle_texture(size: float, color: Color) -> ImageTexture:
	"""Erstellt eine kreisförmige Textur mit Glow"""
	var img_size = int(size * 2)
	var image = Image.create(img_size, img_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(img_size / 2.0, img_size / 2.0)
	var radius = size
	
	for x in range(img_size):
		for y in range(img_size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= radius:
				# Glow-Effekt: Alpha nimmt zum Rand hin ab
				var alpha = 1.0 - (dist / radius)
				alpha = pow(alpha, 0.5)  # Sanfterer Glow
				var pixel_color = Color(color.r, color.g, color.b, alpha)
				image.set_pixel(x, y, pixel_color)
	
	return ImageTexture.create_from_image(image)

func start_particle_animation(enemy_position: Vector2):
	"""Startet die Partikel-Animation zum Phaser-Startpunkt"""
	# Speichere Gegner-Position für Debug
	debug_enemy_position = enemy_position
	
	# Finde den Punkt auf dem Path, der am nächsten zum Gegner ist
	meeting_point_progress = _find_closest_point_on_path(enemy_position)
	
	# Berechne Distanzen in ABSOLUTEN OFFSET-WERTEN
	var curve = path_2d.curve
	var total_length = curve.get_baked_length()
	
	# Treffpunkt in absoluter Offset-Position
	var meeting_offset = meeting_point_progress * total_length
	
	# KORREKTUR: Partikel sollen von entgegengesetzten Seiten kommen
	# aber auf dem PATH bleiben (nicht "durch die Luft")
	
	# Partikel 1: Startet am Anfang (0) und fährt vorwärts zum Treffpunkt
	distance_1 = meeting_offset
	
	# Partikel 2: Startet am Ende (total_length) und fährt RÜCKWÄRTS zum Treffpunkt
	distance_2 = total_length - meeting_offset
	
	# Debug-Ausgabe (Console)
	print("\n=== PHASER DEBUG ===")
	print("Meeting point progress: ", meeting_point_progress)
	print("Total length: ", total_length)
	print("Meeting offset: ", meeting_offset)
	print("Distance 1 (Start->Meeting, vorwärts): ", distance_1)
	print("Distance 2 (End->Meeting, rückwärts): ", distance_2)
	print("Enemy position (global): ", enemy_position)
	
	var start_point = curve.sample_baked(0.0)
	var end_point = curve.sample_baked(total_length)
	var meeting_point = curve.sample_baked(meeting_offset)
	
	print("Start point (local): ", start_point)
	print("End point (local): ", end_point)
	print("Meeting point (local): ", meeting_point)
	
	# Zeige wo die Partikel TATSÄCHLICH starten werden
	print("\n--- PARTIKEL START-POSITIONEN ---")
	print("Partikel 1 startet bei Offset 0.0 = ", start_point)
	print("Partikel 2 startet bei Offset ", total_length, " = ", end_point)
	print("Beide treffen sich bei Offset ", meeting_offset, " = ", meeting_point)
	print("==================\n")
	
	# WICHTIG: Deaktiviere Loop für korrekte Bewegung bei offenen Pfaden
	path_follow_1.loop = false
	path_follow_2.loop = false
	
	# Setze Startpositionen
	path_follow_1.progress = 0.0
	path_follow_2.progress = total_length
	
	# Starte Animation
	elapsed_time = 0.0
	is_moving = true
	
	# Sprites sichtbar machen
	sprite_1.visible = true
	sprite_2.visible = true
	
	# Force redraw für Debug
	queue_redraw()
	
func _find_closest_point_on_path(target_position: Vector2) -> float:
 # """Findet den Punkt auf dem Path2D, der am nächsten zum Ziel ist"""
	var curve = path_2d.curve
	if not curve:
		return 0.5
	
	var closest_progress = 0.0
	var min_distance = INF
	var samples = 128  # Genauigkeit der Suche
	
	for i in range(samples + 1):
		var progress = float(i) / float(samples)
		var point_on_curve = curve.sample_baked(progress * curve.get_baked_length())
		
		# WICHTIG KORREKTUR: In globale Koordinaten umwandeln!
		var global_point = to_global(point_on_curve)  # ÄNDERUNG: to_global statt path_2d.to_global
		
		var dist = global_point.distance_to(target_position)
		
		if dist < min_distance:
			min_distance = dist
			closest_progress = progress
	
	# Debug: Zeige den gefundenen Punkt
	if debug_mode:
		var found_point = curve.sample_baked(closest_progress * curve.get_baked_length())
		var found_global = to_global(found_point)  # ÄNDERUNG: to_global
		print("🎯 Nächster Punkt gefunden:")
		print("   Local: ", found_point)
		print("   Global: ", found_global)
		print("   Target: ", target_position)
		print("   Distance: ", found_global.distance_to(target_position))
		print("   Ship Rotation: ", rad_to_deg(global_rotation), "°")  # Debug Rotation
	
	return closest_progress

func _on_particles_arrived():
	"""Wird aufgerufen, wenn beide Partikel angekommen sind"""
	# Partikel verstecken
	sprite_1.visible = false
	sprite_2.visible = false
	
	# Phaser-Startpunkt ermitteln (in globalen Koordinaten)
	var phaser_start = path_2d.to_global(
		path_2d.curve.sample_baked(meeting_point_progress * path_2d.curve.get_baked_length())
	)
	
	print("Partikel angekommen bei: ", phaser_start)
	print("Gegner Position: ", debug_enemy_position)
	
	# Phaser-Strahl spawnen
	_spawn_phaser_beam(phaser_start, debug_enemy_position)

func _spawn_phaser_beam(start_pos: Vector2, end_pos: Vector2):
  #  """Spawnt den Phaser-Strahl"""
	print("\n🔫 === SPAWN_PHASER_BEAM AUFGERUFEN ===")
	
	if not phaser_beam_scene:
		push_error("❌ FEHLER: phaser_beam_scene ist NULL!")
		return
	
	var beam = phaser_beam_scene.instantiate()
	var ship = get_parent()
	
	if ship:
		ship.add_child(beam)
		print("✅ Beam zu Schiff hinzugefügt: ", ship.name)
	else:
		get_tree().root.add_child(beam)
		print("⚠️ Beam zu Root hinzugefügt")
		ship = null
	
	# WICHTIG: Finde den echten Enemy-Node für Tracking
	var enemy_node = _find_enemy_at_position(end_pos)
	
	# Beam-Punkte setzen MIT Target-Node für Tracking
	beam.set_beam_points(start_pos, end_pos, ship, enemy_node)
	
	print("🎯 Phaser Beam mit Enemy-Tracking gespawnt!")
	print("==============================\n")

func _find_enemy_at_position(position: Vector2) -> Node2D:
 #   """Findet den Enemy-Node an der gegebenen Position"""
	# Hier musst du deine eigene Logik implementieren, um den
	# tatsächlichen Enemy-Node an der Position zu finden
	
	# Beispiel: Durchsuche alle Nodes in der "enemies" Gruppe
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_distance = 50.0  # Maximaler Abstand um als "selber Enemy" zu gelten
	
	for enemy in enemies:
		var dist = enemy.global_position.distance_to(position)
		if dist < closest_distance:
			closest_distance = dist
			closest_enemy = enemy
	
	if closest_enemy:
		print("🎯 Enemy gefunden: ", closest_enemy.name, " bei Distanz: ", closest_distance)
	else:
		print("⚠️ Kein Enemy an Position gefunden")
	
	return closest_enemy

# Für Tests: Startet Animation beim Drücken der Leertaste oder Mausklick
func _input(event):
	# Test mit Leertaste (zufällige Position)
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		var test_enemy_pos = global_position + Vector2(
			randf_range(-200, 200),
			randf_range(-200, 200)
		)
		start_particle_animation(test_enemy_pos)
	
	# Test mit Mausklick (klicke auf Gegner-Position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		start_particle_animation(get_global_mouse_position())
