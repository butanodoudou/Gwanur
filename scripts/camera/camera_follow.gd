# scripts/camera/camera_follow.gd
# Caméra orbitale qui suit un personnage.
# Trouve sa cible automatiquement via les groupes "kael" / "mira" au démarrage.
# Chaque joueur pivote avec le stick droit de SA manette, via les actions
# joueurN_camera_haut/bas/gauche/droite de project.godot :
#   Joueur 1 (Kael) : manette 0 — et en plus clic droit + souris (fallback dev)
#   Joueur 2 (Mira) : manette 1 — et en plus le pavé numérique 8/2/4/6
#
# La caméra tourne sur DEUX axes :
#   - horizontal (`_angle_h`) : elle fait le tour du personnage ;
#   - vertical   (`_angle_v`) : elle monte pour regarder le sol, descend pour
#     regarder le ciel — comme elle vise toujours le personnage, plus elle est
#     basse, plus la vue pointe vers le haut.
#
# LE PIVOT — c'est la clé du ressenti
# La caméra ne se déplace pas « vers » sa position idéale. Elle est accrochée
# RIGIDEMENT à un point invisible, le pivot, et c'est le PIVOT qui suit le
# personnage en douceur.
#   - tourner la caméra → réponse immédiate, l'orbite est rigide ;
#   - marcher           → la caméra traîne légèrement, ce qui donne du poids.
# Amortir la caméra elle-même (ce qu'on faisait avant) amortit aussi la
# rotation : le stick pousse, l'image suit un dixième de seconde plus tard, et
# ça donne cette impression de caméra « molle », accrochée par un élastique.

extends Camera3D

@export var distance: float = 9.0
@export var hauteur: float = 6.0
# Vitesse à laquelle le pivot rattrape le personnage, en « par seconde ».
# Plus c'est haut, plus la caméra colle. 12 ≈ 1/12 s de retard.
@export var vitesse_suivi: float = 12.0
@export var sensibilite_souris: float = 0.004
@export var sensibilite_stick: float = 2.5
@export var id_joueur: int = 1

# Bornes de l'angle vertical.
# En bas : un peu SOUS le personnage, pour dégager le ciel et la canopée de
# l'Aelith. En haut : presque à la verticale — on ne va pas jusqu'à 90°, car
# `look_at()` ne sait pas orienter une caméra pile au-dessus de sa cible
# (la direction du regard serait parallèle au vecteur « haut »).
const ANGLE_V_MIN := -0.50   # ≈ -29°
const ANGLE_V_MAX :=  1.36   # ≈  78°

# Le sol de la Zone 1 est plat (y = 0). On empêche la caméra de passer dessous
# quand le joueur regarde vers le haut. À revoir le jour où il y a du relief.
const HAUTEUR_MIN := 0.8

# Le pivot est placé au-dessus de l'origine du personnage, à hauteur de tête.
# Viser les pieds tasse l'horizon en haut de l'écran et donne l'impression de
# regarder le sol en permanence.
const HAUTEUR_REGARD := 1.0

# Manette : en dessous, on ignore (le stick ne revient jamais pile au centre).
const ZONE_MORTE := 0.15

var cible: Node3D = null
var _angle_h: float = 0.0
var _angle_v: float = 0.0

# Le point que la caméra regarde. Il suit le personnage avec du retard.
var _pivot: Vector3 = Vector3.ZERO
var _pivot_initialise: bool = false

# Distance réelle entre la caméra et le personnage. `distance` et `hauteur`
# décrivent la position de départ ; une fois la caméra sur une orbite, c'est le
# rayon de cette orbite qui compte, et il ne change plus quand on pivote.
var _rayon: float = 0.0

func _ready() -> void:
	make_current()
	# On convertit la position de départ (distance + hauteur) en coordonnées
	# d'orbite : un rayon et un angle vertical. Avec 9 m et 6 m, ça donne un
	# rayon de 10,8 m et un angle de 34° — exactement le cadrage d'avant.
	_rayon   = sqrt(distance * distance + hauteur * hauteur)
	_angle_v = atan2(hauteur, distance)
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
		# Souris vers le haut → relative.y négatif → la caméra descend → on
		# regarde vers le ciel. C'est la convention non inversée.
		_angle_v = clamp(_angle_v + event.relative.y * sensibilite_souris,
						 ANGLE_V_MIN, ANGLE_V_MAX)

# Zone morte + réponse au carré. Une réponse linéaire rend les petits
# ajustements impossibles : au quart du stick on tourne déjà au quart de la
# vitesse max. Au carré, le début de course est lent et précis, et la vitesse
# maximale est inchangée en bout de course.
func _axe(valeur: float) -> float:
	if absf(valeur) < ZONE_MORTE:
		return 0.0
	# absf() plutôt que abs() : abs() renvoie un Variant, et GDScript refuse
	# alors d'inférer le type de `utile`.
	var utile := (absf(valeur) - ZONE_MORTE) / (1.0 - ZONE_MORTE)
	return signf(valeur) * utile * utile

# Position du stick droit de ce joueur, de -1 à +1 sur chaque axe.
# get_action_raw_strength() renvoie la valeur BRUTE du stick (sans la zone
# morte de l'action) : c'est _axe() qui applique la nôtre, avec sa courbe.
# Une touche du clavier renvoie simplement 1.0 quand elle est enfoncée.
func _lire_stick() -> Vector2:
	var prefixe := "joueur%d_camera_" % id_joueur
	return Vector2(
		Input.get_action_raw_strength(prefixe + "droite") - Input.get_action_raw_strength(prefixe + "gauche"),
		Input.get_action_raw_strength(prefixe + "bas") - Input.get_action_raw_strength(prefixe + "haut"))

func _process(delta: float) -> void:
	if not cible:
		return

	# Stick droit (ou pavé numérique pour J2). La souris de J1 passe par
	# _unhandled_input. On ne lit PAS la manette directement par son numéro :
	# c'est project.godot qui dit quelle manette appartient à quel joueur.
	var stick := _lire_stick()
	_angle_h -= _axe(stick.x) * sensibilite_stick * delta
	# Stick vers le haut → valeur négative → la caméra descend → on regarde
	# vers le ciel. Même convention que la souris.
	_angle_v = clamp(
		_angle_v + _axe(stick.y) * sensibilite_stick * delta,
		ANGLE_V_MIN, ANGLE_V_MAX)

	# ── Le pivot rattrape le personnage ──────────────────────────────────────
	var vise_pivot := cible.global_position + Vector3.UP * HAUTEUR_REGARD
	if not _pivot_initialise:
		# Première frame : pas de glissade depuis l'origine du monde.
		_pivot = vise_pivot
		_pivot_initialise = true
	else:
		# 1 - exp(-v * delta) : un amortissement qui ne dépend PAS du nombre
		# d'images par seconde. Avec un simple `lerp(x, 0.08)`, la caméra est
		# deux fois plus vive à 120 fps qu'à 60 — le réglage ne veut rien dire.
		_pivot = _pivot.lerp(vise_pivot, 1.0 - exp(-vitesse_suivi * delta))

	# Position sur la sphère : l'angle vertical écrase le cercle horizontal
	# (cos) et donne la hauteur (sin). À _angle_v = 0 la caméra est à hauteur
	# d'épaules et la vue est horizontale.
	var offset := Vector3(
		sin(_angle_h) * cos(_angle_v) * _rayon,
		sin(_angle_v) * _rayon,
		cos(_angle_h) * cos(_angle_v) * _rayon
	)
	var pos := _pivot + offset

	# Le sol bloque la descente : sous HAUTEUR_MIN, la caméra ne peut plus
	# reculer vers le bas. Ce qu'elle ne peut pas faire en descendant, elle le
	# fait en VISANT PLUS HAUT — on regarde alors au-dessus du personnage, et
	# le ciel entre dans le cadre. Sans cette compensation, l'angle bas ne
	# servirait à rien : la vue resterait horizontale.
	var compensation: float = max(0.0, HAUTEUR_MIN - pos.y)
	pos.y = max(pos.y, HAUTEUR_MIN)

	# Aucun amortissement ici : la caméra est soudée à son orbite, donc la
	# rotation répond à l'image près.
	global_position = pos

	var point_vise := _pivot + Vector3.UP * compensation
	if global_position.distance_to(point_vise) > 0.1:
		look_at(point_vise, Vector3.UP)
