# scripts/main.gd
# Script de la scène principale — point d'entrée du jeu.
# Responsabilité : connecter les caméras aux personnages au démarrage.
#
# Pourquoi ici et pas dans les scènes .tscn ?
#   Les caméras sont dans les SubViewports (UI) et les personnages dans le Monde (3D).
#   Godot ne permet pas de référencer des nœuds d'arbres différents depuis l'éditeur,
#   donc on fait la connexion par code dans _ready().

extends Node3D

func _ready() -> void:
	# Récupère les deux personnages depuis la branche Monde
	var kael: Node3D = $Monde/Kael
	var mira: Node3D = $Monde/Mira

	# Récupère les deux caméras depuis les SubViewports
	var camera_kael = $UI/SplitScreen/ViewportGauche/SubViewportKael/CameraKael
	var camera_mira = $UI/SplitScreen/ViewportDroit/SubViewportMira/CameraMira

	# Assigne la cible à chaque caméra — elles suivront leurs personnages dès maintenant
	camera_kael.cible = kael
	camera_mira.cible = mira
