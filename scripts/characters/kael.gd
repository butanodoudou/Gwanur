# scripts/characters/kael.gd
# Kael — héritier de la magie elfique, joueur 1 (manette 1 / clavier fallback)
#
#   Skill 1 (X) → Brassards de Sève  : fait pousser des lianes
#   Skill 2 (Y) → Corne d'Appel      : attire les créatures proches
#   Interagir (A) → Carnet des Anciens

class_name Kael
extends CharacterBase

signal lianes_invoquees(position: Vector3)
signal corne_sonnee

# Portée de la Corne d'Appel en mètres
const PORTEE_CORNE: float = 8.0

func _ready() -> void:
	super()  # Appelle CharacterBase._ready() qui fait add_to_group("joueurs")
	add_to_group("kael")
	id_joueur = 1

func _physics_process(delta: float) -> void:
	super(delta)
	_verifier_skills()

func _verifier_skills() -> void:
	if Input.is_action_just_pressed("joueur1_skill1"):
		utiliser_brassards()
	if Input.is_action_just_pressed("joueur1_skill2"):
		utiliser_corne()

# Brassards de Sève — les puzzles écoutent ce signal pour faire pousser des lianes
func utiliser_brassards() -> void:
	lianes_invoquees.emit(global_position)

# Corne d'Appel — les créatures proches écoutent ce signal
# La portée est vérifiée par les créatures elles-mêmes (elles ont la position de Kael via le signal)
func utiliser_corne() -> void:
	corne_sonnee.emit()

# Retourne vrai si la position donnée est dans la portée de la Corne
func dans_portee_corne(pos: Vector3) -> bool:
	return global_position.distance_to(pos) <= PORTEE_CORNE

func interagir() -> void:
	# TODO : ouvrir le Carnet des Anciens ou déclencher le dialogue végétal
	pass
