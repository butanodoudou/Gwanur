# scripts/main.gd
# Assigne la référence caméra à chaque personnage pour le mouvement relatif.
# Les caméras trouvent leur cible elles-mêmes (voir camera_follow.gd).

extends Node3D

func _ready() -> void:
	var kael     = $Monde/Kael
	var mira     = $Monde/Mira
	var cam_kael = $SplitScreen/Conteneur/VueKael/SubViewport/CameraKael
	var cam_mira = $SplitScreen/Conteneur/VueMira/SubViewport/CameraMira

	# camera_ref permet aux personnages de se déplacer relatif à leur caméra
	if cam_kael:
		kael.camera_ref = cam_kael
	if cam_mira:
		mira.camera_ref = cam_mira
