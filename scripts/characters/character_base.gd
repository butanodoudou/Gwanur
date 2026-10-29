# scripts/characters/character_base.gd
# Classe de base commune à Kael et Mira.
# Gère le mouvement 3D, la gravité, et une démarche procédurale du modèle.
# Le mouvement est relatif à la caméra si camera_ref est assigné.
#
# LA DÉMARCHE SANS SQUELETTE
# Les modèles .glb de Kael et Mira n'ont pas d'os : ils ne peuvent pas jouer
# d'animation de marche. Pour qu'ils ne glissent pas comme des pions, on fait
# rebondir et balancer légèrement le MODÈLE (le nœud enfant « Modele ») quand
# le personnage avance. On ne touche jamais au CharacterBody3D lui-même : sa
# capsule de collision bougerait avec, et le personnage se cognerait au sol.
#
# Les interactions ne passent PAS par ici : c'est l'InteractionManager qui lit
# le bouton et appelle l'objet visé. Voir scripts/globals/interaction_manager.gd.

class_name CharacterBase
extends CharacterBody3D

@export var vitesse: float = 5.0
@export var id_joueur: int = 1

const GRAVITE: float = 9.8

# Vitesse à laquelle le personnage se tourne vers sa direction, « par seconde ».
# 10 ≈ l'ancien lerp_angle(..., 0.15) à 60 fps, mais identique à 30 ou 144 fps.
const VITESSE_ROTATION: float = 10.0

# ── Réglages de la démarche ──────────────────────────────────────────────────
const PAS_PAR_SECONDE: float = 2.2      # nombre de pas à pleine vitesse
const AMPLITUDE_REBOND: float = 0.05    # hauteur du rebond, en mètres
const AMPLITUDE_BALANCEMENT: float = 0.05  # roulis gauche/droite, en radians (≈ 3°)
const INCLINAISON_AVANT: float = 0.04   # le buste penche un peu en marchant (≈ 2°)
# Vitesse à laquelle la démarche apparaît / s'efface (retour doux au repos).
const VITESSE_TRANSITION: float = 8.0

var camera_ref = null

# Mis à false pendant l'intro et la fin (voir main.gd) : le personnage ne lit
# plus ses touches, mais la gravité continue de s'appliquer.
var controles_actifs: bool = true

# Le modèle visuel animé par la démarche (null si la scène n'en a pas).
var _modele: Node3D = null
var _position_repos: Vector3 = Vector3.ZERO
var _rotation_repos: Vector3 = Vector3.ZERO
# Où on en est dans le cycle de pas (avance avec le temps quand on marche).
var _phase_pas: float = 0.0
# 0 = immobile, 1 = pleine vitesse. Lissé pour que la démarche s'efface en douceur.
var _intensite_marche: float = 0.0

func _ready() -> void:
	add_to_group("joueurs")
	# Le nom « Modele » vient de kael.tscn / mira.tscn.
	_modele = get_node_or_null("Modele") as Node3D
	if _modele:
		_position_repos = _modele.position
		_rotation_repos = _modele.rotation

func _physics_process(delta: float) -> void:
	_appliquer_gravite(delta)
	_deplacer(delta)
	move_and_slide()
	_animer_demarche(delta)

func _appliquer_gravite(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITE * delta

func _deplacer(delta: float) -> void:
	var direction = _obtenir_direction()
	if direction.length() > 0.0:
		velocity.x = direction.x * vitesse
		velocity.z = direction.z * vitesse
		_orienter_personnage(direction, delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, vitesse)
		velocity.z = move_toward(velocity.z, 0.0, vitesse)

func _obtenir_direction() -> Vector3:
	if not controles_actifs:
		return Vector3.ZERO
	var prefixe = "joueur" + str(id_joueur) + "_"
	var dir_2d = Input.get_vector(
		prefixe + "gauche",
		prefixe + "droite",
		prefixe + "haut",
		prefixe + "bas"
	)
	if dir_2d.length() < 0.1:
		return Vector3.ZERO

	if camera_ref:
		var h = camera_ref.get_angle_h()
		var avant = Vector3(-sin(h), 0.0, -cos(h))
		var droite = Vector3(cos(h), 0.0, -sin(h))
		return (droite * dir_2d.x + avant * -dir_2d.y).normalized()

	return Vector3(dir_2d.x, 0.0, dir_2d.y).normalized()

func _orienter_personnage(direction: Vector3, delta: float) -> void:
	var angle_cible = atan2(direction.x, direction.z)
	# 1 - exp(-k * delta) : la même formule que la caméra (camera_follow.gd).
	# Un lerp_angle(..., 0.15) par frame tournerait deux fois plus vite à 120 fps.
	rotation.y = lerp_angle(rotation.y, angle_cible, 1.0 - exp(-VITESSE_ROTATION * delta))

# Petit rebond + balancement du modèle, proportionnels à la vitesse.
func _animer_demarche(delta: float) -> void:
	if _modele == null:
		return

	# Vitesse horizontale seulement : tomber ne doit pas faire « marcher ».
	var vitesse_sol := Vector2(velocity.x, velocity.z).length()
	var cible: float = 0.0
	if vitesse > 0.0:
		cible = clampf(vitesse_sol / vitesse, 0.0, 1.0)
	_intensite_marche = lerpf(_intensite_marche, cible, 1.0 - exp(-VITESSE_TRANSITION * delta))

	# Un cycle complet de sin() = deux pas (pied gauche, pied droit).
	# Le cycle ralentit quand on marche doucement (stick à moitié).
	_phase_pas += delta * PAS_PAR_SECONDE * PI * cible

	# abs(sin) donne une bosse par pas : le corps monte à chaque appui.
	var rebond := absf(sin(_phase_pas)) * AMPLITUDE_REBOND * _intensite_marche
	# sin sans abs : penche à gauche sur un pas, à droite sur le suivant.
	var roulis := sin(_phase_pas) * AMPLITUDE_BALANCEMENT * _intensite_marche

	_modele.position = _position_repos + Vector3(0.0, rebond, 0.0)
	_modele.rotation = _rotation_repos + Vector3(INCLINAISON_AVANT * _intensite_marche, 0.0, roulis)
