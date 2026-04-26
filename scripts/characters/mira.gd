# scripts/characters/mira.gd
# Mira — héritière de la robustesse humaine, joueur 2 (manette 2)
#
#   Skill 1 (X) → Grappin de Cuivre   : accroche et interagit à distance
#   Skill 2 (Y) → Lanterne à Mémoire  : révèle les échos du passé
#   Interagir (A) → Sac d'Alchimiste

class_name Mira
extends CharacterBase

signal grappin_active(active: bool)
signal lanterne_activee(active: bool)

var lanterne_allumee: bool = false
var grappin_en_cours: bool = false

func _ready() -> void:
	super()
	add_to_group("mira")
	id_joueur = 2

func _physics_process(delta: float) -> void:
	super(delta)
	_verifier_skills()

func _verifier_skills() -> void:
	if Input.is_action_just_pressed("joueur2_skill1"):
		utiliser_grappin()
	if Input.is_action_just_pressed("joueur2_skill2"):
		basculer_lanterne()

# Grappin de Cuivre — accroche ou décroche
# Les zones de grappin (GrappinPoint) écoutent ce signal pour réagir
func utiliser_grappin() -> void:
	grappin_en_cours = not grappin_en_cours
	grappin_active.emit(grappin_en_cours)

# Lanterne à Mémoire — allume ou éteint
# Les nœuds d'écho dans la scène écoutent ce signal pour devenir visibles
func basculer_lanterne() -> void:
	lanterne_allumee = not lanterne_allumee
	lanterne_activee.emit(lanterne_allumee)

func interagir() -> void:
	# TODO : ouvrir le Sac d'Alchimiste ou examiner un mécanisme
	pass
