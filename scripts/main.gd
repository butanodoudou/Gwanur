# scripts/main.gd
# Point d'entrée — connecte la caméra orbitale à Kael.

extends Node3D

func _ready() -> void:
	var kael   = $Monde/Kael
	var camera = $Monde/Camera

	camera.cible     = kael
	camera.id_joueur = 1
	kael.camera_ref  = camera
