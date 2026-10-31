# scripts/characters/kael.gd
# Kael — héritier de la magie elfique, joueur 1 (première manette, device 0 — clavier ZQSD en fallback)
#
#   Skill 1 (X) → Brassards de Sève  : fait pousser des lianes
#   Skill 2 (Y) → Corne d'Appel      : attire les créatures proches
#
# Le bouton A (interagir) n'est pas géré ici : l'InteractionManager le lit et
# appelle directement l'objet visé (PNJ, poignée, verrou).
# Le Carnet des Anciens n'est pas implémenté — hors scope Zone 1.

class_name Kael
extends CharacterBase

signal lianes_invoquees(position: Vector3)
signal corne_sonnee

func _ready() -> void:
	super()  # Appelle CharacterBase._ready() qui fait add_to_group("joueurs")
	add_to_group("kael")
	id_joueur = 1

func _physics_process(delta: float) -> void:
	super(delta)
	_verifier_skills()

func _verifier_skills() -> void:
	# Pendant l'intro et la fin, les joueurs ne contrôlent rien.
	if not controles_actifs:
		return
	if Input.is_action_just_pressed("joueur1_skill1"):
		utiliser_brassards()
	if Input.is_action_just_pressed("joueur1_skill2"):
		utiliser_corne()

# Brassards de Sève — les puzzles écoutent ce signal pour faire pousser des lianes
func utiliser_brassards() -> void:
	jouer_geste("skill1")  # il lève les deux bras (visuel seulement)
	lianes_invoquees.emit(global_position)

# Corne d'Appel — les créatures écoutent ce signal (sans argument).
# C'est la créature qui décide si elle est à portée : elle cherche Kael dans
# le groupe "kael" et mesure la distance elle-même. La portée de l'oiseau est
# PORTEE_CORNE dans puzzle_oiseau.gd.
func utiliser_corne() -> void:
	jouer_geste("skill2")  # il porte la corne à ses lèvres (visuel seulement)
	corne_sonnee.emit()
