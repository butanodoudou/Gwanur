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
#   Oiseau               (Node3D)         — l'oiseau, positionné sur son perchoir au départ
#   PlateformePoids      (Area3D)         — détecte quand l'oiseau est dessus
#   Grille               (AnimatableBody3D) — la grille qui bloque le chemin
#   ZoneVerrou           (Area3D)         — là où Mira active le verrou

extends Node3D

signal puzzle_resolu

# Durée d'ouverture de la grille avant refermeture (si Mira n'a pas verrouillé)
const DUREE_OUVERTURE: float = 12.0

@onready var oiseau: Node3D = $Oiseau
@onready var plateforme_poids: Area3D = $PlateformePoids
@onready var grille: AnimatableBody3D = $Grille
@onready var zone_verrou: Area3D = $ZoneVerrou

var position_perchoir: Vector3
var position_plateforme: Vector3

var oiseau_attire: bool = false
var oiseau_en_place: bool = false
var grille_ouverte: bool = false
var verrou_active: bool = false
var resolu: bool = false
var _minuterie_fermeture: float = 0.0
var _mira_au_verrou: bool = false

func _ready() -> void:
	position_perchoir = oiseau.global_position
	position_plateforme = plateforme_poids.global_position

	# Connecte le signal de Kael dès que les personnages sont dans la scène
	call_deferred("_connecter_kael")

	plateforme_poids.body_entered.connect(func(b):
		# L'oiseau est représenté par un Node3D qui n'est pas un corps physique —
		# on vérifie la proximité dans _process à la place
		pass
	)

	zone_verrou.body_entered.connect(func(b): if b.is_in_group("mira"): _mira_au_verrou = true)
	zone_verrou.body_exited.connect(func(b): if b.is_in_group("mira"): _mira_au_verrou = false)

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
		if _minuterie_fermeture <= 0.0:
			_fermer_grille()

	# Mira active le verrou pendant que la grille est ouverte
	if _mira_au_verrou and grille_ouverte and not verrou_active:
		if Input.is_action_just_pressed("joueur2_interagir"):
			_activer_verrou()

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
	DialogueManager.afficher("", ["Le poids ouvre le passage ! Mira, dépêche-toi !"])
	var tween = create_tween()
	tween.tween_property(grille, "position", grille.position + Vector3(0, 3.5, 0), 1.0)

func _fermer_grille() -> void:
	grille_ouverte = false
	oiseau_attire = false
	oiseau_en_place = false
	# L'oiseau retourne sur son perchoir
	oiseau.global_position = position_perchoir
	DialogueManager.afficher("", ["L'oiseau s'est envolé. Recommencez."])
	var tween = create_tween()
	tween.tween_property(grille, "position", grille.position - Vector3(0, 3.5, 0), 1.0)

func _activer_verrou() -> void:
	verrou_active = true
	resolu = true
	GameManager.puzzle2_resolu = true
	DialogueManager.afficher("", ["Mira verrouille le passage. Kael peut passer."])
	puzzle_resolu.emit()
