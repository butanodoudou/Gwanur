# scripts/puzzles/puzzle_porte_double.gd
# Puzzle 1 — La Porte à Deux Poignées
#
# Mécanique : Kael et Mira doivent chacun se placer devant une poignée
# et appuyer sur A. Le premier qui appuie attend l'autre (sans limite de temps).
# Quand les deux ont appuyé, la porte monte.
#
# Le puzzle ne lit PAS l'input : chaque poignée est un PointInteraction qui
# affiche son prompt dans le HUD et émet `active` quand le joueur appuie.
#
# Nœuds attendus dans la scène :
#   ZoneInteractionKael  (PointInteraction) — poignée gauche, réservée à Kael
#   ZoneInteractionMira  (PointInteraction) — poignée droite, réservée à Mira
#   Porte                (AnimatableBody3D) — la porte qui monte

extends Node3D

signal puzzle_resolu

@onready var zone_kael: PointInteraction = $ZoneInteractionKael
@onready var zone_mira: PointInteraction = $ZoneInteractionMira
@onready var porte: AnimatableBody3D = $Porte

var kael_pret: bool = false
var mira_prete: bool = false
var resolu: bool = false

func _ready() -> void:
	zone_kael.active.connect(func(_id): _prendre_poignee(1))
	zone_mira.active.connect(func(_id): _prendre_poignee(2))

	# Si un joueur lâche sa poignée en s'éloignant, il n'est plus prêt —
	# sauf si l'autre est déjà en place (on ne punit pas celui qui attend).
	zone_kael.body_exited.connect(func(b):
		if b.is_in_group("kael") and not mira_prete:
			_lacher_poignee(1)
	)
	zone_mira.body_exited.connect(func(b):
		if b.is_in_group("mira") and not kael_pret:
			_lacher_poignee(2)
	)

func _prendre_poignee(id_joueur: int) -> void:
	if resolu:
		return

	if id_joueur == 1:
		if kael_pret:
			return
		kael_pret = true
		zone_kael.definir_disponible(false)
	else:
		if mira_prete:
			return
		mira_prete = true
		zone_mira.definir_disponible(false)

	if kael_pret and mira_prete:
		_ouvrir_porte()
	else:
		_annoncer_attente()

func _lacher_poignee(id_joueur: int) -> void:
	if resolu:
		return

	if id_joueur == 1:
		if not kael_pret:
			return
		kael_pret = false
		zone_kael.definir_disponible(true)
	else:
		if not mira_prete:
			return
		mira_prete = false
		zone_mira.definir_disponible(true)

	_annoncer_attente()

# Message persistant en haut des DEUX vues : chacun doit savoir que l'autre
# l'attend. Un dialogue ne suffirait pas — il disparaît au bout de quelques
# secondes, et le joueur qui arrive après ne le verrait jamais.
func _annoncer_attente() -> void:
	if kael_pret and not mira_prete:
		GameManager.definir_etat_coop("Kael tient sa poignée — Mira, prends l'autre !")
	elif mira_prete and not kael_pret:
		GameManager.definir_etat_coop("Mira tient sa poignée — Kael, prends l'autre !")
	else:
		GameManager.definir_etat_coop("")

func _ouvrir_porte() -> void:
	resolu = true
	GameManager.puzzle1_resolu = true
	GameManager.definir_etat_coop("")
	zone_kael.definir_disponible(false)
	zone_mira.definir_disponible(false)

	DialogueManager.afficher("", ["Deux mains, deux poignées, un seul souffle. La porte grince et se lève lentement..."])
	# La porte monte de 3.5m en 1.5 secondes
	var tween = create_tween()
	tween.tween_property(porte, "position", porte.position + Vector3(0, 3.5, 0), 1.5)
	puzzle_resolu.emit()
