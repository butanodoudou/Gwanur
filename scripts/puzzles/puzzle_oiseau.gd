# scripts/puzzles/puzzle_oiseau.gd
# Puzzle 2 — L'Oiseau et le Passage
#
# Mécanique :
#   0. Prérequis (désactivable, voir EXIGER_LIRA) : avoir parlé à Lira
#   1. Kael utilise la Corne près de l'oiseau (à 12 m, mesurés au sol) → l'oiseau vole vers la plateforme de poids
#   2. Quand l'oiseau atteint la plateforme → la grille s'ouvre (12 secondes)
#      Tout ce qui est minuté passe par l'état coop (HUD), JAMAIS par un
#      dialogue : un dialogue ouvert bloque l'InteractionManager, et le premier
#      appui de Mira au verrou ne ferait que fermer le texte.
#   3. Mira doit passer et interagir avec le verrou avant la fermeture
#   4. Verrou activé → grille reste ouverte définitivement
#
# Nœuds attendus :
#   Oiseau               (Node3D)           — l'oiseau, posé sur son perchoir au départ
#   PlateformePoids      (Area3D)           — repère de la position d'arrivée de l'oiseau
#   Grille               (AnimatableBody3D) — la grille qui bloque le chemin
#   ZoneVerrou           (PointInteraction) — là où Mira active le verrou

extends Node3D

signal puzzle_resolu

# Durée d'ouverture de la grille avant refermeture (si Mira n'a pas verrouillé)
const DUREE_OUVERTURE: float = 12.0

# PRÉREQUIS DE LIRA (GAME_DESIGN, Puzzle 2) — pas encore tranché définitivement.
# true  : l'oiseau ne descend que si les joueurs ont parlé à Lira ; sinon un
#         message doux les envoie vers elle.
# false : la corne marche tout de suite.
const EXIGER_LIRA: bool = true

# Portée de la corne, mesurée À L'HORIZONTALE (on ignore la hauteur) : l'oiseau
# est perché à ~7,8 m sur un toit, une distance 3D de 8 m ne laissait qu'un
# mouchoir de poche au pied du mur.
const PORTEE_CORNE: float = 12.0
# Au-delà de la portée mais en deçà de cette distance, Kael est « près du
# puzzle » : on lui dit de s'approcher au lieu de ne rien dire.
const DISTANCE_INDICE: float = 25.0

# Vitesse du vol de l'oiseau. Le vol suit `1 - exp(-VITESSE_VOL * delta)` :
# la même trajectoire à 30, 60 ou 144 images par seconde.
const VITESSE_VOL: float = 1.8
# Combien de temps on affiche « la grille se lève » avant le compte à rebours
const DUREE_ANNONCE_OUVERTURE: float = 2.0

@onready var oiseau: Node3D = $Oiseau
@onready var plateforme_poids: Area3D = $PlateformePoids
@onready var grille: AnimatableBody3D = $Grille
@onready var zone_verrou: PointInteraction = $ZoneVerrou

var position_perchoir: Vector3
var position_plateforme: Vector3

var oiseau_attire: bool = false
var oiseau_en_place: bool = false
var grille_ouverte: bool = false
var verrou_active: bool = false
var resolu: bool = false
var _minuterie_fermeture: float = 0.0

func _ready() -> void:
	position_perchoir = oiseau.global_position
	position_plateforme = plateforme_poids.global_position

	# Connecte le signal de Kael dès que les personnages sont dans la scène
	call_deferred("_connecter_kael")

	# Le verrou ne devient utilisable que lorsque la grille est ouverte —
	# sinon Mira verrait "(A) Verrouiller le passage" sans que ça ait un sens.
	zone_verrou.definir_disponible(false)
	zone_verrou.active.connect(func(_id): _activer_verrou())

func _connecter_kael() -> void:
	var kael = get_tree().get_first_node_in_group("kael")
	if kael:
		kael.corne_sonnee.connect(_sur_corne_sonnee)

func _process(delta: float) -> void:
	if resolu:
		return

	# Déplace l'oiseau vers sa cible quand il est attiré
	if oiseau_attire and not oiseau_en_place:
		# Fraction du chemin restant parcourue pendant CETTE image (indépendant du framerate)
		var fraction: float = 1.0 - exp(-VITESSE_VOL * delta)
		oiseau.global_position = oiseau.global_position.lerp(position_plateforme, fraction)
		# Vérifie si l'oiseau est arrivé sur la plateforme
		if oiseau.global_position.distance_to(position_plateforme) < 0.5:
			oiseau_en_place = true
			_ouvrir_grille()

	# Minuterie de fermeture automatique
	if grille_ouverte and not verrou_active:
		_minuterie_fermeture -= delta
		_annoncer_compte_a_rebours()
		if _minuterie_fermeture <= 0.0:
			_fermer_grille()

# Les deux joueurs voient le temps qu'il reste à Mira pour atteindre le verrou.
func _annoncer_compte_a_rebours() -> void:
	# Les deux premières secondes : on raconte ce qui se passe.
	if _minuterie_fermeture > DUREE_OUVERTURE - DUREE_ANNONCE_OUVERTURE:
		GameManager.definir_etat_coop("Sous le poids de l'oiseau, la grille se lève. Mira, cours bloquer le verrou !")
		return
	var secondes: int = max(int(ceil(_minuterie_fermeture)), 0)
	GameManager.definir_etat_coop("La grille retombe dans %d s — Mira, cours au verrou !" % secondes)

func _sur_corne_sonnee() -> void:
	if oiseau_attire or resolu:
		return
	var kael = get_tree().get_first_node_in_group("kael")
	if kael == null:
		return
	var distance: float = _distance_au_sol(kael.global_position, oiseau.global_position)

	# Trop loin pour être entendu. Tout près du puzzle, on le dit doucement ;
	# ailleurs dans le village, la corne sonne pour le plaisir, sans message.
	if distance > PORTEE_CORNE:
		if distance <= DISTANCE_INDICE:
			DialogueManager.afficher("", ["L'oiseau blanc ne t'entend pas d'ici… Kael, approche-toi de la maison."])
		return

	# Prérequis : Lira connaît cet oiseau (voir EXIGER_LIRA en haut du fichier).
	if EXIGER_LIRA and not GameManager.lira_parlee:
		DialogueManager.afficher("", ["L'oiseau blanc t'observe sans bouger. Lira, la voisine, saurait peut-être…"])
		return

	oiseau_attire = true
	# État coop et pas dialogue : la suite est minutée (voir l'en-tête).
	GameManager.definir_etat_coop("L'oiseau blanc dresse la tête vers la corne... puis se laisse glisser du toit.")

# Distance entre deux points en ignorant la hauteur (comme vue d'au-dessus).
func _distance_au_sol(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _ouvrir_grille() -> void:
	grille_ouverte = true
	_minuterie_fermeture = DUREE_OUVERTURE
	zone_verrou.definir_disponible(true)
	# Le message passe par l'état coop (voir _annoncer_compte_a_rebours) : un
	# dialogue ici « avalerait » le premier appui de Mira au verrou.
	_annoncer_compte_a_rebours()
	var tween = create_tween()
	tween.tween_property(grille, "position", grille.position + Vector3(0, 3.5, 0), 1.0)

func _fermer_grille() -> void:
	grille_ouverte = false
	oiseau_attire = false
	oiseau_en_place = false
	zone_verrou.definir_disponible(false)
	GameManager.definir_etat_coop("")
	# L'oiseau retourne sur son perchoir
	oiseau.global_position = position_perchoir
	DialogueManager.afficher("", ["L'oiseau prend peur et regagne son toit. La grille retombe. Kael, rappelle-le !"])
	var tween = create_tween()
	tween.tween_property(grille, "position", grille.position - Vector3(0, 3.5, 0), 1.0)

func _activer_verrou() -> void:
	if verrou_active or not grille_ouverte:
		return
	verrou_active = true
	resolu = true
	GameManager.puzzle2_resolu = true
	zone_verrou.definir_disponible(false)
	GameManager.definir_etat_coop("")
	DialogueManager.afficher("", ["Mira bloque le verrou d'un coup sec. La grille ne retombera plus."])
	puzzle_resolu.emit()
