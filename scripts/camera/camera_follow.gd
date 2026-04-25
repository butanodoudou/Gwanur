# scripts/camera/camera_follow.gd
# Caméra qui suit un personnage depuis un angle légèrement au-dessus et derrière.
# Une instance est utilisée dans chaque moitié du split-screen.
#
# Comment ça marche :
#   - La caméra se déplace vers (position du personnage + offset) chaque frame.
#   - Le "lissage" rend le mouvement doux — plus il est bas, plus c'est fluide.
#   - look_at() fait pointer la caméra vers le personnage automatiquement.

extends Camera3D

# Décalage de la caméra par rapport au personnage (haut et derrière)
# x=0 : centré horizontalement / y=6 : 6m au-dessus / z=9 : 9m derrière
@export var offset: Vector3 = Vector3(0.0, 6.0, 9.0)

# Vitesse de lissage du suivi — entre 0.0 (immobile) et 1.0 (instantané)
# 0.08 donne un suivi doux, agréable à l'œil
@export var lissage: float = 0.08

# Le personnage à suivre — assigné depuis main.gd au démarrage
var cible: Node3D = null

func _process(_delta: float) -> void:
	if not cible:
		return

	# Calcule la position cible et se rapproche doucement (interpolation linéaire)
	var position_cible = cible.global_position + offset
	global_position = global_position.lerp(position_cible, lissage)

	# Regarde toujours vers le personnage (sécurité : vérifie qu'on n'est pas au même endroit)
	if global_position.distance_to(cible.global_position) > 0.1:
		look_at(cible.global_position, Vector3.UP)
