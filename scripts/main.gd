# scripts/main.gd
# Point d'entrée du jeu — connecte les caméras aux personnages.

extends Node3D

func _ready() -> void:
	var kael = $Monde/Kael
	var mira = $Monde/Mira

	var camera_kael = $UI/SplitScreen/ViewportGauche/SubViewportKael/CameraKael
	var camera_mira = $UI/SplitScreen/ViewportDroit/SubViewportMira/CameraMira

	camera_kael.cible = kael
	camera_kael.id_joueur = 1
	camera_mira.cible = mira
	camera_mira.id_joueur = 2

	kael.camera_ref = camera_kael
	mira.camera_ref = camera_mira
