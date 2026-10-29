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
# Nom de la touche « interagir » de chaque joueur (E / Entrée / A), pour le texte du choix.
const TouchesJoueur = preload("res://scripts/ui/touches_joueur.gd")

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
var _grimoire_annonce: bool = false  # l'indice du grimoire n'est donné qu'une fois
var _grimoire_ouvert: bool = false   # le grimoire ne se lit qu'une fois

# L'indice donné quand les trois puzzles sont résolus (lu aussi par test_parcours_complet).
const INDICE_GRIMOIRE: Array[String] = [
	"Au-delà de la porte du nord, dans la vieille maison de pierre, quelque chose brille.",
	"Une latte du plancher, à peine soulevée. Comme si on l'avait laissée ainsi exprès."
]

func _ready() -> void:
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
	# La boîte reste la collision ; le modèle (tools/gen_props.py) la remplace
	# à l'écran s'il existe. Le décalage ramène l'origine du modèle au sol.
	_habiller_bloc(_mur(Vector3(1.8, 1.5, 1.8), Vector3(7.0, 0.75, 6.0), COULEUR_PIERRE),
		"puits", Vector3(0, -0.75, 0))

	# ── Perchoir de l'oiseau ──────────────────────────────────────────────────
	# Sur le faîtage de la maison voisin (est). Le modèle Blender monte plus
	# haut que l'ancienne boîte : murs 4.57 + toit 2.46 ≈ 7.0 m. Décalé vers le
	# sud du faîtage pour ne pas être caché par la cheminée.
	_habiller_bloc(_mur(Vector3(1.3, 0.45, 1.3), Vector3(22.0, 7.25, -3.2), COULEUR_PERCHOIR),
		"perchoir")

	# ── Palissades : ce qui oblige à passer par les puzzles ───────────────────
	_construire_les_enceintes()

	# ── Les ouvertures de la paroi, côté extérieur ───────────────────────────
	_fermer_les_ouvertures_exterieures()

	# ── Collision du tronc du Rejet (le saule) ───────────────────────────────
	# Le saule de la place est un rejet de l'Aelith (voir l'en-tête). Le modèle
	# GLB n'a pas de collision native — cylindre autour du tronc (scale 6×)
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
	_habiller_bloc(_mur(Vector3(0.5, 3.5, 0.4), Vector3(0.0, 1.75, -44.0), COULEUR_PIERRE),
		"stele", Vector3(0, -1.75, 0))

	# ── Ruisseau (Puzzle 3 — côté ouest) ──────────────────────────────────────
	_construire_le_ruisseau()

# ──────────────────────────────────────────────────────────────────────────────
# LES ENCEINTES — palissades, cour, bief
# ──────────────────────────────────────────────────────────────────────────────
#
# Vu de dessus (nord en haut), ce que les palissades dessinent :
#
#        paroi ─────────────── z=-36 ────[ PORTE ]──── z=-36 ─────────── paroi
#                ┌─ bief ─┐                │ cour │
#                │~~eau~~~│ (pont)         │      │
#                └────────┘                └─[GRILLE]─┘  z=-26
#                                  village (sud)
#
#   - La grande palissade z = -36 coupe la cavité d'un bord à l'autre de la
#     paroi : le NORD (stèle, vieille maison, sortie) ne s'atteint que par la
#     Porte Double (Puzzle 1).
#   - Devant la porte, une COUR fermée (x ∈ [-8, 8], z ∈ [-36, -26]) dont la
#     seule entrée est la Grille (Puzzle 2). Le verrou et les deux poignées de
#     la porte sont dans la cour : on fait donc le Puzzle 2 avant le Puzzle 1.
#   - À l'ouest, le BIEF : une bande de terre entre le ruisseau et la
#     palissade, fermée à ses deux bouts. On n'y entre qu'en traversant le
#     ruisseau — donc par le pont (Puzzle 3).
#
# Pas de saut dans le jeu : 3 m de palissade suffisent à arrêter un joueur.

const HAUTEUR_PALISSADE := 3.0
const MODULE_PALISSADE  := 4.0   # longueur du modèle palissade.glb
const Z_PALISSADE_NORD  := -36.0
const Z_GRILLE          := -26.0
const X_COUR            := 8.0   # demi-largeur de la cour devant la porte
const DEMI_PORTE        := 4.0   # la porte et la grille font 8 m de large

# Le ruisseau : un lit de 4 m le long de X. Le pont (5 × 4 m, voir zone1.tscn)
# part replié sur la rive sud et s'avance de 4 m vers le nord
# (puzzle_roue_eau.gd) : déployé, il couvre exactement le lit.
const RUISSEAU_Z        := -30.0  # axe du lit
const RUISSEAU_LARGEUR  := 4.0
const RUISSEAU_X_MIN    := -30.7  # bout ouest (palissade du bief)
const RUISSEAU_X_MAX    := -12.8  # bout est (palissade du bief)
const PONT_X_MAX        := -25.5  # le pont couvre x ∈ [-30.5, -25.5]
const MODULE_BERGE      := 6.0    # longueur du modèle berge.glb

# L'obstacle invisible sous le pont, retiré quand le pont est déployé.
var _gue_ferme: StaticBody3D = null

func _construire_les_enceintes() -> void:
	# On enfonce les bouts de 2 m dans la paroi : pas de fente au raccord.
	var x_paroi := _x_de_la_paroi(Z_PALISSADE_NORD) + 2.0

	# La grande palissade nord, de part et d'autre de la Porte Double
	_palissade(Vector3( DEMI_PORTE, 0, Z_PALISSADE_NORD), Vector3( x_paroi, 0, Z_PALISSADE_NORD))
	_palissade(Vector3(-DEMI_PORTE, 0, Z_PALISSADE_NORD), Vector3(-x_paroi, 0, Z_PALISSADE_NORD))

	# La cour : deux bouts de palissade de part et d'autre de la Grille…
	_palissade(Vector3( DEMI_PORTE, 0, Z_GRILLE), Vector3( X_COUR + 0.2, 0, Z_GRILLE))
	_palissade(Vector3(-DEMI_PORTE, 0, Z_GRILLE), Vector3(-X_COUR - 0.2, 0, Z_GRILLE))
	# …et ses deux flancs, jusqu'à la grande palissade
	_palissade(Vector3( X_COUR, 0, Z_GRILLE), Vector3( X_COUR, 0, Z_PALISSADE_NORD))
	_palissade(Vector3(-X_COUR, 0, Z_GRILLE), Vector3(-X_COUR, 0, Z_PALISSADE_NORD))

	# Le bief : ses deux bouts descendent jusqu'à la rive sud du ruisseau.
	var z_rive_sud := RUISSEAU_Z + RUISSEAU_LARGEUR * 0.5 + 0.2
	_palissade(Vector3(RUISSEAU_X_MIN, 0, Z_PALISSADE_NORD), Vector3(RUISSEAU_X_MIN, 0, z_rive_sud))
	_palissade(Vector3(RUISSEAU_X_MAX, 0, Z_PALISSADE_NORD), Vector3(RUISSEAU_X_MAX, 0, z_rive_sud))

# x de la face intérieure de la paroi de l'Aelith, à une profondeur z donnée.
func _x_de_la_paroi(z: float) -> float:
	var dz := z - AELITH_CENTRE.z
	return sqrt(maxf(AELITH_RAYON * AELITH_RAYON - dz * dz, 0.0))

# Une palissade droite de `a` à `b` (au sol) : UNE boîte de collision, et le
# modèle de 4 m répété tout du long (étiré d'un poil pour tomber juste).
func _palissade(a: Vector3, b: Vector3) -> void:
	var delta := b - a
	var longueur := Vector2(delta.x, delta.z).length()

	var sb := StaticBody3D.new()
	sb.position   = Vector3((a.x + b.x) * 0.5, 0.0, (a.z + b.z) * 0.5)
	# atan2(x, z) : la rotation autour de Y qui aligne l'axe Z local sur a → b
	sb.rotation.y = atan2(delta.x, delta.z)

	var cs    := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size  = Vector3(0.4, HAUTEUR_PALISSADE, longueur)
	cs.shape    = forme
	cs.position = Vector3(0, HAUTEUR_PALISSADE * 0.5, 0)
	sb.add_child(cs)
	add_child(sb)

	var nombre := maxi(1, ceili(longueur / MODULE_PALISSADE))
	var pas := longueur / float(nombre)
	for i in nombre:
		var module := _instancier_prop("palissade")
		if module == null:
			# Pas encore de modèle : la boîte de bois d'avant.
			_boite_visible(sb, Vector3(0.4, HAUTEUR_PALISSADE, longueur),
				Vector3(0, HAUTEUR_PALISSADE * 0.5, 0), COULEUR_BOIS)
			return
		module.position = Vector3(0, 0, -longueur * 0.5 + (float(i) + 0.5) * pas)
		module.scale    = Vector3(1, 1, pas / MODULE_PALISSADE)
		sb.add_child(module)

# Les ouvertures sud, est et ouest de la paroi mènent HORS de la cavité. Par
# l'extérieur, on pourrait faire le tour du rempart et rentrer par la sortie
# nord — derrière la Porte Double, sans résoudre aucun puzzle. On les ferme
# donc côté extérieur, d'un mur invisible : on peut s'avancer dans le passage
# et regarder dehors, mais pas sortir. Le nord reste ouvert : c'est la sortie.
func _fermer_les_ouvertures_exterieures() -> void:
	var rayon := AELITH_RAYON + AELITH_EPAISSEUR - 0.5
	for ouverture in AELITH_OUVERTURES:
		var angle: float = float(ouverture[0])
		if absf(angle - PI) < 0.01:
			continue
		_obstacle_invisible(
			AELITH_CENTRE + Vector3(sin(angle) * rayon, AELITH_HAUTEUR * 0.5, cos(angle) * rayon),
			Vector3(10.0, AELITH_HAUTEUR, 1.0),
			angle)

# Le ruisseau : de l'eau qui ondule (shader), des rives de galets, et une
# barrière invisible sur toute sa longueur — l'eau n'a pas de vrai creux
# (le sol est une dalle plate), c'est donc cette barrière qui empêche de
# traverser à pied. Le morceau sous le pont est retiré quand le pont se pose.
func _construire_le_ruisseau() -> void:
	var longueur := RUISSEAU_X_MAX - RUISSEAU_X_MIN
	var centre_x := (RUISSEAU_X_MIN + RUISSEAU_X_MAX) * 0.5

	# ── L'eau ─────────────────────────────────────────────────────────────────
	var eau := MeshInstance3D.new()
	eau.name = "Eau"
	var plan := PlaneMesh.new()
	plan.size = Vector2(longueur, RUISSEAU_LARGEUR)
	# Des subdivisions pour que le shader puisse faire onduler la surface
	plan.subdivide_width = 36
	plan.subdivide_depth = 8
	eau.mesh = plan
	var shader := Shader.new()
	shader.code = SHADER_EAU
	var mat_eau := ShaderMaterial.new()
	mat_eau.shader = shader
	eau.material_override = mat_eau
	# 4 cm au-dessus du sol : sinon l'eau et l'herbe clignotent l'une à travers l'autre
	eau.position = Vector3(centre_x, 0.04, RUISSEAU_Z)
	add_child(eau)

	# ── La barrière invisible ─────────────────────────────────────────────────
	var x_est := PONT_X_MAX
	_obstacle_invisible(
		Vector3((x_est + RUISSEAU_X_MAX) * 0.5, 1.5, RUISSEAU_Z),
		Vector3(RUISSEAU_X_MAX - x_est, 3.0, RUISSEAU_LARGEUR))
	_gue_ferme = _obstacle_invisible(
		Vector3((RUISSEAU_X_MIN + x_est) * 0.5, 1.5, RUISSEAU_Z),
		Vector3(x_est - RUISSEAU_X_MIN, 3.0, RUISSEAU_LARGEUR))
	puzzle3.puzzle_resolu.connect(_sur_pont_deploye)

	# ── Les rives ─────────────────────────────────────────────────────────────
	var nombre := maxi(1, roundi(longueur / MODULE_BERGE))
	var pas := longueur / float(nombre)
	for rive in [-1.0, 1.0]:
		var z: float = RUISSEAU_Z + float(rive) * RUISSEAU_LARGEUR * 0.5
		for i in nombre:
			var x_debut := RUISSEAU_X_MIN + float(i) * pas
			# Pas de galets là où le pont se pose, sur aucune des deux rives
			if x_debut < PONT_X_MAX:
				continue
			var module := _instancier_prop("berge")
			if module == null:
				var galets := MeshInstance3D.new()
				var boite := BoxMesh.new()
				boite.size = Vector3(pas, 0.3, 0.4)
				galets.mesh = boite
				galets.material_override = _materiau_simple(COULEUR_PIERRE)
				galets.position = Vector3(x_debut + pas * 0.5, 0.15, z)
				add_child(galets)
				continue
			module.position = Vector3(x_debut + pas * 0.5, 0, z)
			module.scale    = Vector3(pas / MODULE_BERGE, 1, 1)
			add_child(module)

# Le pont commence à s'avancer 1,5 s après la résolution et met 1,5 s
# (puzzle_roue_eau.gd) : on ouvre le gué quand il est posé.
func _sur_pont_deploye() -> void:
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(_gue_ferme):
		_gue_ferme.queue_free()
		_gue_ferme = null

func _obstacle_invisible(centre: Vector3, taille: Vector3, rot_y: float = 0.0) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.position   = centre
	sb.rotation.y = rot_y
	var cs    := CollisionShape3D.new()
	var forme := BoxShape3D.new()
	forme.size = taille
	cs.shape   = forme
	sb.add_child(cs)
	add_child(sb)
	return sb

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

# L'écho de la liane, que révèle la Lanterne de Mira : un fantôme vert qui
# luit et palpite doucement (shader SHADER_ECHO). Il prend la forme de la
# vraie liane si son modèle existe — l'écho annonce exactement ce qui va pousser.
func _configurer_echo_liane() -> void:
	var echo: MeshInstance3D = $Puzzle3RoueEau/EchoLiane
	var shader := Shader.new()
	shader.code = SHADER_ECHO
	var mat := ShaderMaterial.new()
	mat.shader = shader

	var modele := _instancier_prop("liane")
	if modele == null:
		echo.set_surface_override_material(0, mat)
		return
	# Le modèle devient enfant de l'écho : le puzzle n'a qu'à montrer ou
	# cacher EchoLiane, comme avant. On retire la boîte d'origine.
	echo.mesh = null
	echo.add_child(modele)
	for mi in _maillages(modele):
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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

# Le message de résolution de chaque puzzle est affiché par le script du
# puzzle lui-même. (DialogueManager met les messages en file d'attente : un
# second message ici ne l'écraserait plus, mais il ferait doublon.)
func _sur_puzzle1_resolu() -> void:
	_verifier_fin_de_zone()

func _sur_puzzle2_resolu() -> void:
	_verifier_fin_de_zone()

func _sur_puzzle3_resolu() -> void:
	_verifier_fin_de_zone()

# Appelée après CHAQUE puzzle : les trois peuvent être résolus dans n'importe
# quel ordre, c'est le dernier — quel qu'il soit — qui révèle le grimoire.
func _verifier_fin_de_zone() -> void:
	if not GameManager.zone1_terminee() or _grimoire_annonce:
		return
	_grimoire_annonce = true
	# On laisse retomber l'émotion du dernier puzzle…
	# (2e argument false : la minuterie S'ARRÊTE pendant la pause du jeu.)
	await get_tree().create_timer(3.0, false).timeout
	# … puis l'indice. S'il reste un message du puzzle à l'écran, celui-ci
	# attend son tour dans la file du DialogueManager.
	DialogueManager.afficher("", INDICE_GRIMOIRE)
	zone_grimoire.monitoring = true

func _sur_entree_grimoire(body: Node3D) -> void:
	if not body.is_in_group("joueurs"):
		return
	# Garde-fou : Godot refuse qu'on change `monitoring` PENDANT le signal
	# body_entered (l'ancien code échouait, et le grimoire se relançait à
	# chaque entrée). On le coupe donc « en différé », à la fin de l'image,
	# et le booléen empêche toute seconde lecture d'ici là.
	if _grimoire_ouvert:
		return
	_grimoire_ouvert = true
	zone_grimoire.set_deferred("monitoring", false)
	_declencher_grimoire()

# ──────────────────────────────────────────────────────────────────────────────
# GRIMOIRE + CHOIX DE FIN DE ZONE
# ──────────────────────────────────────────────────────────────────────────────

func _declencher_grimoire() -> void:
	var numero := DialogueManager.afficher("Grimoire d'Aelindra", [
		"Sous la latte, un grimoire enveloppé de lin. L'écriture penchée de votre mère.",
		"« Pour Kael et Mira, si un jour ces pages vous trouvent. »",
		"« Avant d'être votre mère, j'étais la Tisserande : celle qui tient les fils des peuples.",
		"« Ce fil-là, je l'ai lâché pour vous. J'ai cru que le monde tiendrait sans moi.",
		"« Il ne tient pas. La lisière s'efface — et vous êtes nés sur la lisière.",
		"« Votre père savait tout. Il disait que vous seriez plus forts que nous, parce que deux.",
		"« Je pars recoudre ce que j'ai défait. Ne me cherchez pas trop vite.",
		"« Ce que vous ferez de ce secret, décidez-le ensemble. C'est le seul conseil que j'aie. »"
	])
	# Attend la fin de CETTE lecture (le joueur clique à travers toutes les lignes).
	await DialogueManager.attendre_fin(numero)

	# Le choix : les deux options sont affichées ENSEMBLE, et c'est le
	# DialogueManager qui lit le bouton (règle d'or : aucun autre script ne lit
	# « interagir »). Il ignore les appuis pendant ses premières 0,8 s, pour
	# qu'un joueur qui tapote A pour lire ne choisisse pas sans le vouloir.
	_attente_choix = true
	DialogueManager.proposer_choix("Grimoire d'Aelindra",
		"Parlez-en d'abord.\nGarder le grimoire entre vous : Kael (%s)   ·   Le confier au village : Mira (%s)"
		% [TouchesJoueur.interagir(1), TouchesJoueur.interagir(2)])
	var id_joueur: int = await DialogueManager.choix_fait
	_appliquer_choix("secret" if id_joueur == 1 else "partager")

# Kael (joueur 1) = garder le secret, Mira (joueur 2) = partager.
# Appelée aussi directement par test_fin_zone.gd.
func _appliquer_choix(choix: String) -> void:
	if GameManager.choix_grimoire != "":
		return   # le choix est irréversible
	_attente_choix = false
	GameManager.choix_grimoire = choix

	var numero := 0
	if choix == "secret":
		GameManager.modifier_moralite_kael(-10)
		GameManager.modifier_moralite_mira(-10)
		numero = DialogueManager.afficher("", [
			"Vous refermez le grimoire. Il ne quittera plus votre sac.",
			"Kael s'éveille à la Résonance.",
			"Mira apprend l'Ancrage."
		])
	else:
		GameManager.modifier_moralite_kael(10)
		GameManager.modifier_moralite_mira(10)
		numero = DialogueManager.afficher("", [
			"Vous emportez le grimoire jusqu'à la place. Sylvara se tait, puis se souvient.",
			"Kael s'éveille à la Mémoire des Anciens.",
			"Mira apprend la Lecture."
		])

	# Quand ce dernier dialogue est lu, la zone est finie : main.gd prend le
	# relais (fondu au noir, texte de fin, crédits, retour au menu).
	await DialogueManager.attendre_fin(numero)
	GameManager.annoncer_fin_zone1()

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

# Habille les pièces des puzzles avec les modèles de tools/gen_props.py.
# Chaque modèle devient l'ENFANT du noeud animé par le puzzle (la porte qui
# monte, la roue qui tourne…) : il bouge avec, sans que le script du puzzle
# le sache. La boîte d'origine est seulement cachée — la collision ne change pas.
# Sans modèle (pas encore généré), on garde les boîtes colorées d'avant.
func _coloriser_puzzles() -> void:
	_appliquer_couleur($Puzzle1PorteDouble/Porte/MeshInstance3D,    Color(0.30, 0.15, 0.08))
	_appliquer_couleur($Puzzle2Oiseau/Grille/MeshInstance3D,        Color(0.50, 0.50, 0.55))
	_appliquer_couleur($Puzzle3RoueEau/RoueEau/MeshInstance3D,      Color(0.35, 0.22, 0.12))
	_appliquer_couleur($Puzzle3RoueEau/Pont/MeshInstance3D,         Color(0.45, 0.32, 0.18))

	_remplacer_visuel($Puzzle1PorteDouble/Porte/MeshInstance3D, "porte_double")
	_remplacer_visuel($Puzzle2Oiseau/Grille/MeshInstance3D,     "grille")
	_remplacer_visuel($Puzzle2Oiseau/Oiseau/MeshInstance3D,     "oiseau")
	_remplacer_visuel($Puzzle3RoueEau/RoueEau/MeshInstance3D,   "roue_eau")
	_remplacer_visuel($Puzzle3RoueEau/Pont/MeshInstance3D,      "pont")
	_remplacer_visuel($Puzzle3RoueEau/Lianes/MeshInstance3D,    "liane")

	# Les chevalets de la roue : immobiles, donc posés à côté de la roue et
	# pas dedans (sinon ils tourneraient avec elle).
	var roue: Node3D = $Puzzle3RoueEau/RoueEau
	var support := _instancier_prop("roue_support")
	if support != null:
		support.position = roue.position - Vector3(0, 2.0, 0)
		$Puzzle3RoueEau.add_child(support)

	# Les repères au sol : là où il faut se tenir. Sans eux, ces zones sont
	# invisibles et un joueur qui n'a pas l'habitude ne les trouve pas.
	# (PlateformePoids est à y = 0.2 : on redescend le modèle au sol.)
	_poser_repere($Puzzle2Oiseau/PlateformePoids, "plateforme", Vector3(0, -0.2, 0),
		Vector3(2.4, 0.12, 2.4), COULEUR_PIERRE)
	_poser_repere($Puzzle2Oiseau/ZoneVerrou, "verrou", Vector3.ZERO,
		Vector3(0.3, 1.5, 0.3), COULEUR_BOIS)
	_poser_repere($Puzzle3RoueEau/ZoneLanterne, "cercle_lanterne", Vector3.ZERO,
		Vector3(1.4, 0.06, 1.4), Color(1.0, 0.85, 0.55))

func _appliquer_couleur(mi: MeshInstance3D, couleur: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mi.set_surface_override_material(0, mat)

# Cache la boîte `mi` et pose le modèle `nom` à sa place, sous le même parent.
func _remplacer_visuel(mi: MeshInstance3D, nom: String) -> void:
	var modele := _instancier_prop(nom)
	if modele == null:
		return
	mi.visible = false
	modele.name = "Modele"
	modele.transform = mi.transform
	mi.get_parent().add_child(modele)

# Un repère au sol, enfant d'une Area3D. Sans modèle : une simple dalle.
func _poser_repere(zone: Node3D, nom: String, decalage: Vector3,
		taille_secours: Vector3, couleur_secours: Color) -> void:
	var modele := _instancier_prop(nom)
	if modele != null:
		modele.position = decalage
		zone.add_child(modele)
		return
	_boite_visible(zone, taille_secours,
		decalage + Vector3(0, taille_secours.y * 0.5, 0), couleur_secours)

# Pose le modèle `nom` dans un bloc créé par _mur() et cache la boîte.
# `decalage` ramène l'origine du modèle (au sol) depuis le centre du bloc.
func _habiller_bloc(sb: StaticBody3D, nom: String, decalage: Vector3 = Vector3.ZERO) -> void:
	var modele := _instancier_prop(nom)
	if modele == null:
		return
	for enfant in sb.get_children():
		if enfant is MeshInstance3D:
			(enfant as MeshInstance3D).visible = false
	modele.position = decalage
	sb.add_child(modele)

# ──────────────────────────────────────────────────────────────────────────────
# HELPERS — MODÈLES ET MATÉRIAUX
# ──────────────────────────────────────────────────────────────────────────────

const DOSSIER_PROPS := "res://assets/models/props/"

# Instancie un modèle de tools/gen_props.py, ou renvoie null s'il n'existe
# pas encore (pas généré, ou pas importé par Godot).
func _instancier_prop(nom: String) -> Node3D:
	var chemin := DOSSIER_PROPS + nom + ".glb"
	if not ResourceLoader.exists(chemin):
		return null
	var scene := load(chemin) as PackedScene
	if scene == null:
		return null
	return scene.instantiate() as Node3D

# Tous les MeshInstance3D sous `racine` (racine comprise).
func _maillages(racine: Node) -> Array[MeshInstance3D]:
	var resultat: Array[MeshInstance3D] = []
	var a_voir: Array[Node] = [racine]
	while not a_voir.is_empty():
		var noeud: Node = a_voir.pop_back()
		a_voir.append_array(noeud.get_children())
		if noeud is MeshInstance3D:
			resultat.append(noeud as MeshInstance3D)
	return resultat

func _materiau_simple(couleur: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mat.roughness = 0.9
	return mat

# Une boîte visible SANS collision, enfant de `parent`.
func _boite_visible(parent: Node3D, taille: Vector3, pos: Vector3, couleur: Color) -> void:
	var mi := MeshInstance3D.new()
	var boite := BoxMesh.new()
	boite.size = taille
	mi.mesh = boite
	mi.material_override = _materiau_simple(couleur)
	mi.position = pos
	parent.add_child(mi)

# L'eau du ruisseau. Deux familles de vagues qui se croisent font onduler la
# surface (vertex) ; des rides plus fines font varier la couleur (fragment).
# Le bord est plus opaque que le centre (effet Fresnel), comme une vraie eau.
const SHADER_EAU := """
shader_type spatial;
render_mode cull_disabled;

uniform vec3 couleur_fond : source_color = vec3(0.13, 0.33, 0.38);
uniform vec3 couleur_surface : source_color = vec3(0.42, 0.66, 0.66);
uniform float vitesse = 0.6;

varying float vague;

void vertex() {
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vague = sin(p.x * 1.3 - TIME * vitesse * 2.0) * 0.5
		  + sin(p.z * 2.1 + p.x * 0.7 + TIME * vitesse * 1.3) * 0.5;
	VERTEX.y += vague * 0.03;
}

void fragment() {
	vec3 p = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float rides = sin(p.x * 4.0 - TIME * vitesse * 3.0 + sin(p.z * 3.0) * 1.5) * 0.5 + 0.5;
	ALBEDO = mix(couleur_fond, couleur_surface, rides * 0.45 + vague * 0.2 + 0.25);
	ROUGHNESS = 0.12;
	SPECULAR = 0.6;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALPHA = mix(0.78, 0.96, fresnel);
}
"""

# L'écho de la liane : un fantôme lumineux (non éclairé, donc visible même à
# l'ombre), plus dense sur ses contours, qui palpite comme un souffle.
# ALBEDO dépasse 1 exprès : le glow de l'Environment le fait rayonner.
const SHADER_ECHO := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec3 teinte : source_color = vec3(0.45, 1.0, 0.7);

void fragment() {
	float contour = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 1.5);
	float pouls = 0.65 + 0.35 * sin(TIME * 2.2);
	ALBEDO = teinte * 1.6;
	ALPHA = clamp((0.18 + contour * 0.7) * pouls, 0.0, 1.0);
}
"""

# ──────────────────────────────────────────────────────────────────────────────
# HELPERS — CRÉATION DE GÉOMÉTRIE
# ──────────────────────────────────────────────────────────────────────────────

func _sol(taille: Vector3, pos: Vector3) -> void:
	_bloc(taille, pos, COULEUR_SOL)

func _mur(taille: Vector3, pos: Vector3, couleur: Color) -> StaticBody3D:
	return _bloc(taille, pos, couleur)

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

func _bloc(taille: Vector3, pos: Vector3, couleur: Color) -> StaticBody3D:
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
	return sb
