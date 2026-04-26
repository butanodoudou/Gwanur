# scripts/puzzles/puzzle_roue_eau.gd
# Puzzle 3 — La Roue d'Eau
#
# Mécanique :
#   Prérequis : Brennan doit avoir été interrogé (GameManager.brennan_parle = true)
#
#   1. Mira entre dans la ZoneLanterne et allume sa Lanterne (Y)
#      → l'écho de la liane devient visible (EchoLiane)
#   2. Mira doit rester dans la ZoneLanterne avec la lanterne allumée
#   3. Kael entre dans la ZoneLianes et utilise ses Brassards (X)
#      → la liane pousse si Mira est en position
#   4. La liane active la roue → le pont s'étend → chemin ouvert
#
# Nœuds attendus :
#   ZoneLanterne    (Area3D)          — où Mira doit se tenir
#   ZoneLianes      (Area3D)          — où Kael invoque la liane
#   EchoLiane       (MeshInstance3D)  — fantôme semi-transparent de la liane
#   Lianes          (AnimatableBody3D) — la vraie liane qui pousse
#   RoueEau         (AnimatableBody3D) — la roue qui tourne
#   Pont            (AnimatableBody3D) — le pont qui s'étend

extends Node3D

signal puzzle_resolu

@onready var zone_lanterne: Area3D = $ZoneLanterne
@onready var zone_lianes: Area3D = $ZoneLianes
@onready var echo_liane: MeshInstance3D = $EchoLiane
@onready var lianes: AnimatableBody3D = $Lianes
@onready var roue_eau: AnimatableBody3D = $RoueEau
@onready var pont: AnimatableBody3D = $Pont

var mira_en_position: bool = false
var kael_en_zone_lianes: bool = false
var resolu: bool = false

func _ready() -> void:
	# L'écho est invisible au départ
	echo_liane.visible = false

	zone_lanterne.body_entered.connect(func(b): if b.is_in_group("mira"): mira_en_position = true)
	zone_lanterne.body_exited.connect(func(b): if b.is_in_group("mira"): mira_en_position = false)

	zone_lianes.body_entered.connect(func(b): if b.is_in_group("kael"): kael_en_zone_lianes = true)
	zone_lianes.body_exited.connect(func(b): if b.is_in_group("kael"): kael_en_zone_lianes = false)

	call_deferred("_connecter_personnages")

func _connecter_personnages() -> void:
	var mira = get_tree().get_first_node_in_group("mira")
	if mira:
		mira.lanterne_activee.connect(_sur_lanterne_changee)

	var kael = get_tree().get_first_node_in_group("kael")
	if kael:
		kael.lianes_invoquees.connect(_sur_lianes_invoquees)

func _process(_delta: float) -> void:
	if resolu:
		return

	# Vérifie si le prérequis (parler à Brennan) est rempli
	if not GameManager.brennan_parle:
		return

	# Kael essaie d'invoquer les lianes
	if kael_en_zone_lianes and Input.is_action_just_pressed("joueur1_skill1"):
		if mira_en_position:
			var mira = get_tree().get_first_node_in_group("mira")
			if mira and mira.lanterne_allumee:
				_faire_pousser_lianes()
			else:
				DialogueManager.afficher("", ["Kael sent l'endroit... mais quelque chose manque."])
		else:
			DialogueManager.afficher("", ["Kael sent l'endroit... Mira, viens voir avec ta Lanterne !"])

func _sur_lanterne_changee(allumee: bool) -> void:
	if not GameManager.brennan_parle:
		return
	# L'écho apparaît seulement si Mira est dans la zone ET la lanterne est allumée
	if allumee and mira_en_position:
		echo_liane.visible = true
		DialogueManager.afficher("", [
			"Mira voit l'écho : une vieille liane enroulée autour de l'engrenage...",
			"Kael ! Il faut faire pousser une liane là — sur l'engrenage !"
		])
	else:
		echo_liane.visible = false

func _sur_lianes_invoquees(_pos: Vector3) -> void:
	# Ce signal est géré dans _process pour vérifier les conditions
	pass

func _faire_pousser_lianes() -> void:
	resolu = true
	GameManager.puzzle3_resolu = true
	echo_liane.visible = false

	DialogueManager.afficher("", [
		"La liane s'enroule autour de l'engrenage...",
		"La roue tourne ! Le pont s'avance !"
	])

	# Liane pousse (monte en place)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(lianes, "scale", Vector3(1, 1, 1), 1.0).from(Vector3(1, 0, 1))
	# Roue tourne (rotation sur Z)
	tween.tween_property(roue_eau, "rotation", Vector3(0, 0, TAU), 2.0).as_relative()
	# Pont s'étend après 1.5s
	var tween2 = create_tween()
	tween2.tween_interval(1.5)
	tween2.tween_property(pont, "position", pont.position + Vector3(0, 0, -4.0), 1.5)

	puzzle_resolu.emit()
