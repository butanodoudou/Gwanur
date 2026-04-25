# scripts/characters/mira.gd
# Mira — héritière de la robustesse humaine, joueur 2 (manette)
#
# Équipements :
#   Skill 1 (X/Carré) → Grappin de Cuivre   : se propulse vers un point d'accroche
#   Skill 2 (Y/Triangle) → Lanterne à Mémoire : révèle les échos du passé
#   Interagir (A/Croix)  → Sac d'Alchimiste  : craft, inspecte les mécanismes

class_name Mira
extends CharacterBase

# Signaux émis vers les autres systèmes
signal grappin_lance(cible: Vector3)
signal lanterne_activee(active: bool)

# État de la lanterne (allumée ou éteinte)
var lanterne_allumee: bool = false

func _ready() -> void:
	# Mira est toujours le joueur 2 — manette
	id_joueur = 2

func _physics_process(delta: float) -> void:
	# Appelle la logique de base : gravité, déplacement, interaction
	super(delta)
	_verifier_skills()

# Vérifie les boutons de skill de la manette à chaque frame
func _verifier_skills() -> void:
	if Input.is_action_just_pressed("joueur2_skill1"):
		utiliser_grappin()
	if Input.is_action_just_pressed("joueur2_skill2"):
		basculer_lanterne()

# Skill 1 — Grappin de Cuivre
# Lance le grappin vers le point d'accroche le plus proche devant Mira
func utiliser_grappin() -> void:
	# TODO : lancer un rayon (raycast) pour trouver le point d'accroche
	# TODO : animer le grappin + déplacer Mira vers le point
	emit_signal("grappin_lance", global_position)
	print("Mira lance son grappin")

# Skill 2 — Lanterne à Mémoire
# Allume ou éteint la lanterne ; quand allumée, révèle les échos du passé (scènes fantômes)
func basculer_lanterne() -> void:
	lanterne_allumee = not lanterne_allumee
	emit_signal("lanterne_activee", lanterne_allumee)
	# TODO : activer/désactiver le nœud OmniLight3D de la lanterne
	# TODO : activer/désactiver les nœuds d'écho (scènes fantômes du passé)

# Interaction de Mira — craft d'objets, inspection de mécanismes
func interagir() -> void:
	# TODO : ouvrir l'interface du Sac d'Alchimiste ou examiner un mécanisme
	print("Mira interagit")
