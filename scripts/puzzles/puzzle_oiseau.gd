# scripts/puzzles/puzzle_oiseau.gd
# Puzzle 2 — L'Oiseau et le Passage
#
# Mécanique :
#   1. Kael utilise la Corne près de l'oiseau (dans les 8m) → l'oiseau vole vers la plateforme de poids
#   2. Quand l'oiseau atteint la plateforme → la grille s'ouvre (12 secondes)
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
		oiseau.global_position = oiseau.global_position.lerp(position_plateforme, 0.03)
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
	var secondes: int = max(int(ceil(_minuterie_fermeture)), 0)
	GameManager.definir_etat_coop("Le passage se referme dans %d s — Mira, au verrou !" % secondes)

func _sur_corne_sonnee() -> void:
	if oiseau_attire or resolu:
		return
	# Vérifie que Kael est assez proche de l'oiseau
	var kael = get_tree().get_first_node_in_group("kael")
	if kael and kael.global_position.distance_to(oiseau.global_position) <= 8.0:
		oiseau_attire = true
		DialogueManager.afficher("", ["L'oiseau tourne la tête... il vole vers vous."])

func _ouvrir_grille() -> void:
	grille_ouverte = true
	_minuterie_fermeture = DUREE_OUVERTURE
	zone_verrou.definir_disponible(true)
	DialogueManager.afficher("", ["Le poids ouvre le passage ! Mira, dépêche-toi !"])
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
	DialogueManager.afficher("", ["L'oiseau s'est envolé. Recommencez."])
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
	DialogueManager.afficher("", ["Mira verrouille le passage. Kael peut passer."])
	puzzle_resolu.emit()
