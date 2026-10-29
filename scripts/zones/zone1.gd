# scripts/zones/zone1.gd
# Zone 1 — Sylvara, le Village des Lisières
#
# LE VILLAGE EST DANS LE TRONC DE L'AELITH.
# L'arbre est si vieux que son tronc s'est creusé ; Sylvara s'est installée
# dans la cavité. La paroi de bois qui ceinture la zone est son rempart
# naturel, avec deux ouvertures seulement : l'entrée sud et la sortie nord.
#
# Le centre (0, 0, 0) n'est donc PAS un tronc mais la place du village. Le
# petit saule qui y pousse est un rejet de l'Aelith — l'arbre-enfant au coeur
# de l'arbre-parent (instancié dans zone1.tscn).
# Entrée depuis le sud (+Z), sortie vers Zone 2 au nord (-Z).
#
# Responsabilités :
#   1. Géométrie procédurale — maisons, puits, palissade, ruisseau (BoxMesh colorés)
#   2. Coordination des puzzles — signaux et état global
#   3. Grimoire — choix narratif de fin de zone

extends Node3D

const COULEUR_SOL      = Color(0.36, 0.48, 0.28)  # prairie — la terre battue est posée par le décor
const COULEUR_PIERRE   = Color(0.72, 0.63, 0.50)
const COULEUR_BOIS     = Color(0.42, 0.28, 0.18)
const COULEUR_PERCHOIR = Color(0.35, 0.22, 0.12)
const COULEUR_EAU      = Color(0.25, 0.45, 0.60)

# Le décor (toits, arbres, props…) vit dans son propre fichier.
const DecorVillage = preload("res://scripts/zones/decor_village.gd")

# ── Les bâtiments ─────────────────────────────────────────────────────────────
#
# Les maisons sont des modèles Blender (voir `tools/gen_maison.py`).
# RÉPARTITION DU TRAVAIL :
#   - `zone1.gd` pose la COLLISION (une boîte invisible autour des murs) ;
#   - `DecorVillage` pose le MODÈLE VISIBLE par-dessus.
# Le joueur se cogne donc à la boîte, jamais au modèle : la collision reste
# simple et prévisible, quelle que soit la complexité de l'asset.
#
# `taille` = l'emprise des MURS seulement (largeur, hauteur, profondeur), sans
# le toit ni la cheminée — on ne veut pas d'un mur invisible au-dessus du toit.
# Ces valeurs viennent des paramètres passés à `maison()` dans gen_maison.py :
# hauteur des murs + 0.55 m de soubassement.
const MODELES := {
	"maison_a": Vector3(7.0, 4.15, 6.5),
	"maison_b": Vector3(5.5, 3.75, 5.0),
	"moulin":   Vector3(7.5, 5.95, 7.0),
}

# `pos` est posée AU SOL (y = 0), pas au centre du volume.
# `rot` en radians : la façade (porte + fenêtres) regarde le sud avant rotation.
# `echelle` donne la variété — trois modèles suffisent pour sept maisons.
const MAISONS := [
	{ "modele": "maison_a", "pos": Vector3( 22, 0,  14), "rot":  0.00, "echelle": 1.15 },  # Lira
	{ "modele": "maison_a", "pos": Vector3( 22, 0,  -6), "rot":  0.00, "echelle": 1.10 },  # voisin — NE PAS tourner : le perchoir est calé sur son faîtage
	{ "modele": "moulin",   "pos": Vector3(-22, 0, -12), "rot":  0.25, "echelle": 1.10 },  # moulin de Brennan
	{ "modele": "maison_b", "pos": Vector3(-18, 0,  14), "rot": -0.25, "echelle": 1.15 },  # maisons de bruit
	{ "modele": "maison_a", "pos": Vector3( -6, 0,  22), "rot":  0.15, "echelle": 0.95 },
	{ "modele": "maison_b", "pos": Vector3(  8, 0,  24), "rot": -0.12, "echelle": 1.05 },
	{ "modele": "maison_b", "pos": Vector3( 20, 0,  18), "rot":  0.45, "echelle": 0.90 },
]

# ── L'Aelith ──────────────────────────────────────────────────────────────────
#
# Ces valeurs DOIVENT rester identiques à celles de `tools/gen_aelith_v2.py`,
# sinon la collision ne tombe pas sur la paroi visible.
const AELITH_CENTRE   := Vector3(0, 0, -10)
const AELITH_RAYON    := 56.0   # rayon intérieur de la cavité
const AELITH_EPAISSEUR := 11.0
const AELITH_HAUTEUR  := 64.0   # hauteur du mur de collision

# Les ouvertures : (angle en radians, demi-largeur). 0 = sud, π = nord.
const AELITH_OUVERTURES := [
	[ 0.0,      0.085],   # entrée sud
	[ PI,       0.075],   # sortie nord, derrière la Porte Double
	[ PI * 0.5, 0.045],   # brèche est
	[-PI * 0.5, 0.045],   # brèche ouest
]

# Emprise au sol d'une maison, échelle comprise. Utilisée par la collision et
# par le décor (pour ne pas planter un arbre dans un mur).
static func emprise(entree: Dictionary) -> Vector3:
	return MODELES[entree["modele"]] * float(entree["echelle"])

@onready var puzzle1       = $Puzzle1PorteDouble
@onready var puzzle2       = $Puzzle2Oiseau
@onready var puzzle3       = $Puzzle3RoueEau
@onready var zone_grimoire: Area3D = $ZoneGrimoire
@onready var zone_stele:    Area3D = $ZoneStele

var _attente_choix: bool  = false
var _stele_lue: bool      = false
var _choix_affiche: bool  = false

func _ready() -> void:
	set_process(false)
	_construire_village()
	_habiller_le_village()
	_coloriser_puzzles()
	_configurer_echo_liane()
	_connecter_puzzles()

# ──────────────────────────────────────────────────────────────────────────────
# GÉOMÉTRIE PROCÉDURALE
# ──────────────────────────────────────────────────────────────────────────────
#
# Les BoxMesh colorés sont des placeholders en attendant les vrais assets 3D.
# L'Aelith (le vrai modèle) est déjà instancié dans zone1.tscn.

func _construire_village() -> void:
	# ── Sol ───────────────────────────────────────────────────────────────────
	# La dalle doit dépasser la paroi de l'Aelith (rayon 56 + épaisseur),
	# sinon on verrait le vide sous le rempart.
	_sol(Vector3(260, 0.2, 260), AELITH_CENTRE + Vector3(0, -0.1, 0))

	# ── La paroi de l'Aelith : le mur de collision ───────────────────────────
	_ceinture_aelith()

	# ── Maisons : la collision seulement, le modèle vient avec le décor ───────
	for maison in MAISONS:
		_collision_maison(maison)

	# ── Puits central ─────────────────────────────────────────────────────────
	_mur(Vector3(1.8, 1.5, 1.8), Vector3(7.0, 0.75, 6.0), COULEUR_PIERRE)

	# ── Perchoir de l'oiseau ──────────────────────────────────────────────────
	# Sur le faîtage de la maison voisin (est). Le modèle Blender monte plus
	# haut que l'ancienne boîte : murs 4.57 + toit 2.46 ≈ 7.0 m. Décalé vers le
	# sud du faîtage pour ne pas être caché par la cheminée.
	_mur(Vector3(1.3, 0.45, 1.3), Vector3(22.0, 7.25, -3.2), COULEUR_PERCHOIR)

	# ── Palissade nord ────────────────────────────────────────────────────────
	# Gap au centre pour la Porte du Puzzle 1 (z=-36).
	_mur(Vector3(0.4, 3.0, 20.0), Vector3(-18.0, 1.5, -36.0), COULEUR_BOIS)
	_mur(Vector3(0.4, 3.0, 20.0), Vector3( 18.0, 1.5, -36.0), COULEUR_BOIS)

	# ── Collision du tronc de l'Aelith ───────────────────────────────────────
	# Le modèle GLB n'a pas de collision native — cylindre autour du tronc (scale 6×)
	var sb_aelith := StaticBody3D.new()
	var cs_aelith := CollisionShape3D.new()
	var shape_aelith := CylinderShape3D.new()
	shape_aelith.radius = 2.0
	shape_aelith.height = 8.0
	cs_aelith.shape = shape_aelith
	cs_aelith.position = Vector3(0, 4.0, 0)
	sb_aelith.add_child(cs_aelith)
	add_child(sb_aelith)

	# ── Stèle du Pacte d'Aelric ───────────────────────────────────────────────
	_mur(Vector3(0.5, 3.5, 0.4), Vector3(0.0, 1.75, -44.0), COULEUR_PIERRE)

	# ── Ruisseau (Puzzle 3 — côté ouest) ──────────────────────────────────────
	_mur(Vector3(18.0, 0.5, 0.4), Vector3(-22.0, 0.25, -30.0), COULEUR_PIERRE)
	_mur(Vector3(18.0, 0.5, 0.4), Vector3(-22.0, 0.25, -38.0), COULEUR_PIERRE)
	# Fond du ruisseau (eau)
	_mur(Vector3(16.0, 0.1, 7.5), Vector3(-22.0, -0.05, -34.0), COULEUR_EAU)

# Le rempart : une suite de pans droits qui approchent le cercle. Une boîte
# par secteur, invisible — le modèle visible est posé par le décor.
# On saute les ouvertures : c'est par là qu'on entre et qu'on sort.
func _ceinture_aelith() -> void:
	var secteurs := 64
	var rayon := AELITH_RAYON + AELITH_EPAISSEUR * 0.5
	for i in secteurs:
		var angle := float(i) * TAU / float(secteurs)
		if _dans_une_ouverture(angle):
			continue

		# Largeur du pan : la corde du secteur, un peu élargie pour que deux
		# pans voisins se recouvrent et ne laissent pas de fente.
		var corde := 2.0 * rayon * sin(PI / float(secteurs)) * 1.25

		var sb := StaticBody3D.new()
		sb.position = AELITH_CENTRE + Vector3(
			sin(angle) * rayon, AELITH_HAUTEUR * 0.5, cos(angle) * rayon)
		sb.rotation.y = angle

		var cs    := CollisionShape3D.new()
		var forme := BoxShape3D.new()
		forme.size = Vector3(corde, AELITH_HAUTEUR, AELITH_EPAISSEUR)
		cs.shape   = forme
		sb.add_child(cs)
		add_child(sb)

func _dans_une_ouverture(angle: float) -> bool:
	for ouverture in AELITH_OUVERTURES:
		# On mesure l'écart d'angle par un atan2 pour gérer le passage par ±π.
		var d: float = angle - float(ouverture[0])
		if absf(atan2(sin(d), cos(d))) < float(ouverture[1]):
			return true
	return false

# Le décor est ajouté APRÈS la géométrie de base, donc par-dessus : les toits
# se posent sur des maisons qui existent déjà.
func _habiller_le_village() -> void:
	# On ajoute l'emprise calculée à chaque maison avant de passer la liste :
	# le décor a besoin de la taille (pour la terre battue et pour ne pas
	# planter d'arbre dans un mur) mais n'a pas à connaître la table MODELES.
	var liste: Array = []
	for maison in MAISONS:
		var entree: Dictionary = maison.duplicate()
		entree["taille"] = emprise(maison)
		liste.append(entree)

	var decor := DecorVillage.new()
	decor.name = "Decor"
	add_child(decor)
	decor.construire(liste)

func _configurer_echo_liane() -> void:
	var echo: MeshInstance3D = $Puzzle3RoueEau/EchoLiane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.9, 0.6, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode    = BaseMaterial3D.CULL_DISABLED
	echo.set_surface_override_material(0, mat)

# ──────────────────────────────────────────────────────────────────────────────
# COORDINATION DES PUZZLES
# ──────────────────────────────────────────────────────────────────────────────

func _connecter_puzzles() -> void:
	puzzle1.puzzle_resolu.connect(_sur_puzzle1_resolu)
	puzzle2.puzzle_resolu.connect(_sur_puzzle2_resolu)
	puzzle3.puzzle_resolu.connect(_sur_puzzle3_resolu)
	zone_grimoire.body_entered.connect(_sur_entree_grimoire)
	zone_grimoire.monitoring = false
	zone_stele.body_entered.connect(_sur_entree_stele)

func _sur_puzzle1_resolu() -> void:
	DialogueManager.afficher("", ["Les gonds de Caeryn gémissent. Pour la première fois depuis l'hiver, la porte s'ouvre."])

func _sur_puzzle2_resolu() -> void:
	DialogueManager.afficher("", ["La grille tient bon. L'oiseau blanc vous regarde, comme s'il attendait la suite."])

func _sur_puzzle3_resolu() -> void:
	if not GameManager.zone1_terminee():
		return
	await get_tree().create_timer(3.0).timeout
	DialogueManager.afficher("", [
		"Au-delà de la porte du nord, dans la vieille maison de pierre, quelque chose brille.",
		"Une latte du plancher, à peine soulevée. Comme si on l'avait laissée ainsi exprès."
	])
	zone_grimoire.monitoring = true

func _sur_entree_grimoire(body: Node3D) -> void:
	if not body.is_in_group("joueurs"):
		return
	zone_grimoire.monitoring = false
	_declencher_grimoire()

# ──────────────────────────────────────────────────────────────────────────────
# GRIMOIRE + CHOIX DE FIN DE ZONE
# ──────────────────────────────────────────────────────────────────────────────

func _declencher_grimoire() -> void:
	DialogueManager.afficher("Grimoire d'Aelindra", [
		"Sous la latte, un grimoire enveloppé de lin. L'écriture penchée de votre mère.",
		"« Pour Kael et Mira, si un jour ces pages vous trouvent. »",
		"« Avant d'être votre mère, j'étais la Tisserande : celle qui tient les fils des peuples.",
		"« Ce fil-là, je l'ai lâché pour vous. J'ai cru que le monde tiendrait sans moi.",
		"« Il ne tient pas. La lisière s'efface — et vous êtes nés sur la lisière.",
		"« Votre père savait tout. Il disait que vous seriez plus forts que nous, parce que deux.",
		"« Je pars recoudre ce que j'ai défait. Ne me cherchez pas trop vite.",
		"« Ce que vous ferez de ce secret, décidez-le ensemble. C'est le seul conseil que j'aie. »"
	])
	# Attend la fin de la lecture (le joueur clique à travers toutes les lignes)
	await DialogueManager.dialogue_fini
	# Petit délai pour que le bouton soit relâché (évite le double-input)
	await get_tree().create_timer(0.4).timeout
	_attente_choix = true
	set_process(true)

func _process(_delta: float) -> void:
	if not _attente_choix:
		return
	# Lire l'input en priorité (avant de re-afficher pour éviter les conflits)
	if Input.is_action_just_pressed("joueur1_interagir"):
		_appliquer_choix("secret")
		return
	if Input.is_action_just_pressed("joueur2_interagir"):
		_appliquer_choix("partager")
		return
	# Re-afficher le choix dès que le panneau est fermé (loop jusqu'au choix)
	if not DialogueManager._panneau.visible:
		DialogueManager.afficher("", [
			"Garder le grimoire entre vous : Kael (A)   ·   Le confier au village : Mira (A)",
			"Parlez-en d'abord. Garder le secret : Kael (A)   ·   Le partager : Mira (A)"
		])

func _appliquer_choix(choix: String) -> void:
	_attente_choix = false
	set_process(false)
	GameManager.choix_grimoire = choix

	if choix == "secret":
		GameManager.modifier_moralite_kael(-10)
		GameManager.modifier_moralite_mira(-10)
		DialogueManager.afficher("", [
			"Vous refermez le grimoire. C'est entre vous.",
			"Kael débloque : Résonance",
			"Mira débloque : Ancrage"
		])
	else:
		GameManager.modifier_moralite_kael(10)
		GameManager.modifier_moralite_mira(10)
		DialogueManager.afficher("", [
			"Vous partagez la nouvelle avec les villageois.",
			"Kael débloque : Mémoire des Anciens",
			"Mira débloque : Lecture"
		])

# ──────────────────────────────────────────────────────────────────────────────
# STÈLE DU PACTE D'AELRIC
# ──────────────────────────────────────────────────────────────────────────────

func _sur_entree_stele(body: Node3D) -> void:
	if not body.is_in_group("joueurs"):
		return
	if _stele_lue:
		return
	_stele_lue = true
	DialogueManager.afficher("Stèle du Pacte d'Aelric", [
		"Le même texte, gravé trois fois : en elfique, en langue d'Arathos, et en signes inconnus.",
		"« Ici commence la terre neutre, gardée par les Lisières et le Pacte d'Aelric. »",
		"« Scellé en l'an de la trêve par la Tisserande et Aldric, émissaire d'Arathos. »",
		"« Que nul ne porte les armes au-delà de cette pierre. »",
		"« Que ceux qui passent ce seuil marchent sur les pas d'une promesse. »"
	])

# ──────────────────────────────────────────────────────────────────────────────
# HELPERS — COULEURS DES PUZZLES
# ──────────────────────────────────────────────────────────────────────────────

func _coloriser_puzzles() -> void:
	_appliquer_couleur($Puzzle1PorteDouble/Porte/MeshInstance3D,    Color(0.30, 0.15, 0.08))
	_appliquer_couleur($Puzzle2Oiseau/Grille/MeshInstance3D,        Color(0.50, 0.50, 0.55))
	_appliquer_couleur($Puzzle3RoueEau/RoueEau/MeshInstance3D,      Color(0.35, 0.22, 0.12))
	_appliquer_couleur($Puzzle3RoueEau/Pont/MeshInstance3D,         Color(0.45, 0.32, 0.18))

func _appliquer_couleur(mi: MeshInstance3D, couleur: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mi.set_surface_override_material(0, mat)

# ──────────────────────────────────────────────────────────────────────────────
# HELPERS — CRÉATION DE GÉOMÉTRIE
# ──────────────────────────────────────────────────────────────────────────────

func _sol(taille: Vector3, pos: Vector3) -> void:
	_bloc(taille, pos, COULEUR_SOL)

func _mur(taille: Vector3, pos: Vector3, couleur: Color) -> void:
	_bloc(taille, pos, couleur)

# Boîte de collision d'une maison : invisible, tournée comme le modèle, et
# calée sur les murs uniquement (le joueur passe donc sous l'avant-toit).
func _collision_maison(entree: Dictionary) -> void:
	var taille: Vector3 = emprise(entree)
	var pos:    Vector3 = entree["pos"]

	var sb := StaticBody3D.new()
	sb.position   = pos + Vector3(0, taille.y * 0.5, 0)
	sb.rotation.y = entree["rot"]

	var cs    := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = taille
	cs.shape   = forme
	sb.add_child(cs)
	add_child(sb)

func _bloc(taille: Vector3, pos: Vector3, couleur: Color) -> void:
	var sb := StaticBody3D.new()
	sb.position = pos

	var cs    := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = taille
	cs.shape   = shape
	sb.add_child(cs)

	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = taille
	var mat  := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mesh.surface_set_material(0, mat)
	mi.mesh = mesh
	sb.add_child(mi)

	add_child(sb)
