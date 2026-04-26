# scripts/camera/camera_follow.gd
# Caméra orbitale qui suit un personnage.
# Joueur 1 : clic droit + souris pour pivoter horizontalement.
# Joueur 2 : stick droit de la manette pour pivoter.

extends Camera3D

@export var distance: float = 9.0
@export var hauteur: float = 6.0
@export var lissage: float = 0.08
@export var sensibilite_souris: float = 0.004
@export var sensibilite_stick: float = 2.5
@export var id_joueur: int = 1

var cible: Node3D = null
var _angle_h: float = 0.0

# Utilisé par les personnages pour calculer le mouvement relatif à la caméra
func get_angle_h() -> float:
	return _angle_h

func _unhandled_input(event: InputEvent) -> void:
	if id_joueur != 1:
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_angle_h -= event.relative.x * sensibilite_souris

func _process(delta: float) -> void:
	if not cible:
		return

	if id_joueur == 2:
		var stick_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		if abs(stick_x) > 0.15:
			_angle_h -= stick_x * sensibilite_stick * delta

	var offset = Vector3(sin(_angle_h) * distance, hauteur, cos(_angle_h) * distance)
	var cible_pos = cible.global_position + offset
	global_position = global_position.lerp(cible_pos, lissage)

	if global_position.distance_to(cible.global_position) > 0.1:
		look_at(cible.global_position, Vector3.UP)
