# scripts/camera/camera_follow.gd
# Caméra orbitale qui suit un personnage.
# Trouve sa cible automatiquement via les groupes "kael" / "mira" au démarrage.
# Joueur 1 : clic droit + souris pour pivoter.
# Joueur 1 et 2 : stick droit manette (device = id_joueur - 1).

extends Camera3D

@export var distance: float = 9.0
@export var hauteur: float = 6.0
@export var lissage: float = 0.08
@export var sensibilite_souris: float = 0.004
@export var sensibilite_stick: float = 2.5
@export var id_joueur: int = 1

var cible: Node3D = null
var _angle_h: float = 0.0

func _ready() -> void:
	make_current()
	# Kael et Mira s'ajoutent eux-mêmes à leurs groupes dans leur _ready().
	# Comme Monde est traité avant SplitScreen dans l'arbre, les groupes existent déjà ici.
	var groupe = "kael" if id_joueur == 1 else "mira"
	var noeuds = get_tree().get_nodes_in_group(groupe)
	if noeuds.size() > 0:
		cible = noeuds[0] as Node3D

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

	# Kael (J1) : souris uniquement (voir _unhandled_input)
	# Mira (J2) : stick droit device 0 — joueur2_* est mappé sur device 0 dans project.godot
	if id_joueur == 2:
		var stick_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		if abs(stick_x) > 0.15:
			_angle_h -= stick_x * sensibilite_stick * delta

	var offset = Vector3(sin(_angle_h) * distance, hauteur, cos(_angle_h) * distance)
	global_position = global_position.lerp(cible.global_position + offset, lissage)

	if global_position.distance_to(cible.global_position) > 0.1:
		look_at(cible.global_position, Vector3.UP)
