# scripts/puzzles/puzzle_porte_double.gd
# Puzzle 1 — La Porte à Deux Poignées
#
# Mécanique : Kael et Mira doivent chacun se placer devant une poignée
# et appuyer sur A. Le premier qui appuie attend l'autre (sans limite de temps).
# Quand les deux ont appuyé, la porte monte.
#
# Nœuds attendus dans la scène :
#   ZoneInteractionKael  (Area3D) — zone devant la poignée de Kael
#   ZoneInteractionMira  (Area3D) — zone devant la poignée de Mira
#   Porte                (AnimatableBody3D) — la porte qui monte

extends Node3D

signal puzzle_resolu

@onready var zone_kael: Area3D = $ZoneInteractionKael
@onready var zone_mira: Area3D = $ZoneInteractionMira
@onready var porte: AnimatableBody3D = $Porte

var kael_en_zone: bool = false
var mira_en_zone: bool = false
var kael_pret: bool = false
var mira_prete: bool = false
var resolu: bool = false

func _ready() -> void:
	zone_kael.body_entered.connect(func(b): if b.is_in_group("kael"): kael_en_zone = true)
	zone_kael.body_exited.connect(func(b):
		if b.is_in_group("kael"):
			kael_en_zone = false
			# Si Kael s'en va avant que Mira soit prête, il n'est plus prêt non plus
			if not mira_prete:
				kael_pret = false
	)
	zone_mira.body_entered.connect(func(b): if b.is_in_group("mira"): mira_en_zone = true)
	zone_mira.body_exited.connect(func(b):
		if b.is_in_group("mira"):
			mira_en_zone = false
			if not kael_pret:
				mira_prete = false
	)

func _process(_delta: float) -> void:
	if resolu:
		return

	if kael_en_zone and not kael_pret and Input.is_action_just_pressed("joueur1_interagir"):
		kael_pret = true
		DialogueManager.afficher("", ["Kael s'arc-boute contre la poignée... en attente de Mira."])

	if mira_en_zone and not mira_prete and Input.is_action_just_pressed("joueur2_interagir"):
		mira_prete = true
		DialogueManager.afficher("", ["Mira empoigne le grappin... en attente de Kael."])

	if kael_pret and mira_prete:
		_ouvrir_porte()

func _ouvrir_porte() -> void:
	resolu = true
	GameManager.puzzle1_resolu = true
	DialogueManager.afficher("", ["La porte grince et s'ouvre lentement..."])
	# La porte monte de 3.5m en 1.5 secondes
	var tween = create_tween()
	tween.tween_property(porte, "position", porte.position + Vector3(0, 3.5, 0), 1.5)
	puzzle_resolu.emit()
