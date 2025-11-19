# res://Scripts/ShipData.gd
extends Resource
class_name ShipData

@export var ship_name : String = "Galaxy Class"

# Das ist das Wichtigste: die eigentliche Schiff-Szene (Sprite + Partikel + etc.)
@export var ship_scene : PackedScene

@export_group("Bewegung")
@export var max_speed : float = 450.0
@export var rotation_speed : float = 3.8
@export var acceleration : float = 800.0
@export var deceleration : float = 400.0
@export var drift_factor : float = 0.94      # 0.90 = sehr drifty, 0.98 = fast arcade

@export_group("Visuell & Effekte")
@export var thrust_color : Color = Color("00a6ffba")
@export var icon : Texture2D
