# scripts/characters/kael.gd
# Kael — héritier de la magie elfique, joueur 1 (clavier ZQSD)
#
# Équipements :
#   Skill 1 (A) → Brassards de Sève  : fait pousser des lianes
#   Skill 2 (R) → Corne d'Appel      : attire les créatures
#   Interagir (E) → Carnet des Anciens : lit, note, parle aux plantes

class_name Kael
extends CharacterBase

# Signaux émis vers les autres systèmes (puzzles, environnement)
signal lianes_invoquees(position: Vector3)
signal corne_sonnee

func _ready() -> void:
	# Kael est toujours le joueur 1 — clavier ZQSD
	id_joueur = 1

func _physics_process(delta: float) -> void:
	# Appelle la logique de base : gravité, déplacement, interaction
	super(delta)
	_verifier_skills()

# Vérifie les touches de skill à chaque frame
func _verifier_skills() -> void:
	if Input.is_action_just_pressed("joueur1_skill1"):
		utiliser_brassards()
	if Input.is_action_just_pressed("joueur1_skill2"):
		utiliser_corne()

# Skill 1 — Brassards de Sève
# Fait pousser une liane depuis la position de Kael
# Les puzzles écoutent le signal "lianes_invoquees" pour réagir
func utiliser_brassards() -> void:
	emit_signal("lianes_invoquees", global_position)
	# TODO : déclencher l'animation des brassards + effet de particules végétales

# Skill 2 — Corne d'Appel
# Souffle dans la corne pour attirer les animaux proches
# Les créatures écoutent le signal "corne_sonnee" pour se déplacer
func utiliser_corne() -> void:
	emit_signal("corne_sonnee")
	# TODO : jouer le son de la corne + rayon de détection des animaux

# Interaction de Kael — lit le Carnet, parle aux plantes, inspecte
func interagir() -> void:
	# TODO : ouvrir le Carnet des Anciens ou déclencher le dialogue végétal
	print("Kael interagit")
