# scripts/characters/character_base.gd
# Classe de base commune à Kael et Mira.
# Gère le mouvement 3D, la gravité, et le système d'interaction.
# Le mouvement est relatif à la caméra si camera_ref est assigné.

class_name CharacterBase
extends CharacterBody3D

@export var vitesse: float = 5.0
@export var id_joueur: int = 1

const GRAVITE: float = 9.8

signal interaction_declenchee

var _peut_interagir: bool = false
var camera_ref = null

func _ready() -> void:
	add_to_group("joueurs")

func _physics_process(delta: float) -> void:
	_appliquer_gravite(delta)
	_deplacer()
	_verifier_interaction()
	move_and_slide()

func _appliquer_gravite(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITE * delta

func _deplacer() -> void:
	var direction = _obtenir_direction()
	if direction.length() > 0.0:
		velocity.x = direction.x * vitesse
		velocity.z = direction.z * vitesse
		_orienter_personnage(direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, vitesse)
		velocity.z = move_toward(velocity.z, 0.0, vitesse)

func _obtenir_direction() -> Vector3:
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

func _orienter_personnage(direction: Vector3) -> void:
	var angle_cible = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, angle_cible, 0.15)

func _verifier_interaction() -> void:
	var prefixe = "joueur" + str(id_joueur) + "_"
	if Input.is_action_just_pressed(prefixe + "interagir") and _peut_interagir:
		interagir()
		interaction_declenchee.emit()

func interagir() -> void:
	pass

func entrer_zone_interaction() -> void:
	_peut_interagir = true

func quitter_zone_interaction() -> void:
	_peut_interagir = false
