# scripts/characters/character_base.gd
# Classe de base commune à Kael et Mira.
# Gère le mouvement 3D, la gravité, et le système d'interaction.
#
# Comment ça marche :
#   - CharacterBody3D est un nœud Godot spécialisé pour les personnages jouables.
#   - move_and_slide() gère les collisions automatiquement.
#   - id_joueur = 1 → lit les inputs joueur1_* (clavier)
#   - id_joueur = 2 → lit les inputs joueur2_* (manette)

class_name CharacterBase
extends CharacterBody3D

# --- Paramètres modifiables depuis l'éditeur Godot ---
@export var vitesse: float = 5.0    # Vitesse de déplacement en mètres/seconde
@export var id_joueur: int = 1      # 1 = Kael (clavier), 2 = Mira (manette)

# --- Constantes physiques ---
const GRAVITE: float = 9.8          # Accélération gravitationnelle (m/s²)

# --- État interne ---
var _peut_interagir: bool = false    # Vrai quand un objet interactif est à portée

# _physics_process est appelé 60 fois par seconde par Godot
# delta = temps écoulé depuis le dernier appel (environ 0.0167s à 60fps)
func _physics_process(delta: float) -> void:
	_appliquer_gravite(delta)
	_deplacer()
	_verifier_interaction()
	move_and_slide()

# Tire le personnage vers le bas quand il est en l'air
func _appliquer_gravite(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITE * delta

# Lit les touches du joueur et déplace le personnage
func _deplacer() -> void:
	var direction = _obtenir_direction()
	if direction.length() > 0.0:
		velocity.x = direction.x * vitesse
		velocity.z = direction.z * vitesse
		_orienter_personnage(direction)
	else:
		# Décélération progressive quand aucune touche n'est pressée
		velocity.x = move_toward(velocity.x, 0.0, vitesse)
		velocity.z = move_toward(velocity.z, 0.0, vitesse)

# Convertit les inputs 2D (haut/bas/gauche/droite) en direction 3D dans le monde
func _obtenir_direction() -> Vector3:
	var prefixe = "joueur" + str(id_joueur) + "_"
	# get_vector retourne un Vector2 normalisé entre -1 et 1 sur chaque axe
	var dir_2d = Input.get_vector(
		prefixe + "gauche",
		prefixe + "droite",
		prefixe + "haut",
		prefixe + "bas"
	)
	# On ignore l'axe Y du monde (le personnage ne vole pas)
	return Vector3(dir_2d.x, 0.0, dir_2d.y).normalized()

# Fait pivoter doucement le personnage dans le sens du déplacement
func _orienter_personnage(direction: Vector3) -> void:
	var angle_cible = atan2(direction.x, direction.z)
	# lerp_angle évite les rotations bizarres quand on passe de 359° à 0°
	rotation.y = lerp_angle(rotation.y, angle_cible, 0.15)

# Vérifie si le joueur appuie sur interagir près d'un objet
func _verifier_interaction() -> void:
	var prefixe = "joueur" + str(id_joueur) + "_"
	if Input.is_action_just_pressed(prefixe + "interagir") and _peut_interagir:
		interagir()

# À surcharger dans kael.gd et mira.gd avec leur logique propre
func interagir() -> void:
	pass

# Appelé par les zones interactives (Area3D) quand le personnage les entre
func entrer_zone_interaction() -> void:
	_peut_interagir = true

# Appelé quand le personnage quitte la zone interactive
func quitter_zone_interaction() -> void:
	_peut_interagir = false
