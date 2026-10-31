# scripts/zones/decor_village.gd
# Décor de Sylvara — tout ce qui habille le village sans changer le gameplay.
#
# POURQUOI UN FICHIER SÉPARÉ
# `zone1.gd` a déjà trois responsabilités (géométrie de base, puzzles, grimoire).
# Le décor est purement visuel : il mérite son propre fichier, qu'on peut lire,
# modifier ou désactiver sans toucher à la logique de la zone.
#
# RÈGLE IMPORTANTE — LE DÉCOR NE BLOQUE PAS LE JOUEUR
# Presque tout ici est un simple `MeshInstance3D` : un objet qu'on voit mais qui
# n'a AUCUNE collision. On traverse les fleurs, les caisses, les tonneaux.
# Seuls les troncs d'arbres ont une collision (sinon marcher à travers un arbre
# est trop bizarre). La liberté de déplacement reste intacte.
#
# UTILISATION (depuis zone1.gd) :
#     var decor := DecorVillage.new()
#     add_child(decor)
#     decor.construire(MAISONS)

class_name DecorVillage
extends Node3D

# ──────────────────────────────────────────────────────────────────────────────
# PALETTE — tirée de docs/ART_DIRECTION.md
# ──────────────────────────────────────────────────────────────────────────────

const C_TUILE      = Color(0.55, 0.25, 0.16)  # rouille — toits
const C_TUILE_2    = Color(0.48, 0.30, 0.20)  # variante de toit, plus brune
const C_BOIS       = Color(0.42, 0.28, 0.18)
const C_BOIS_CLAIR = Color(0.58, 0.42, 0.26)
const C_PIERRE     = Color(0.72, 0.63, 0.50)
const C_PIERRE_2   = Color(0.58, 0.55, 0.50)  # rochers, plus gris
const C_FEUILLE    = Color(0.29, 0.49, 0.35)  # vert mousse
const C_FEUILLE_2  = Color(0.36, 0.56, 0.38)
const C_HERBE      = Color(0.33, 0.52, 0.30)
const C_FOIN       = Color(0.83, 0.71, 0.42)  # beige doré
const C_LUMIERE    = Color(1.00, 0.80, 0.45)  # doré miel — lanternes
const C_TERRE      = Color(0.34, 0.24, 0.16)  # terre retournée du potager
const C_SOL_USE    = Color(0.52, 0.43, 0.29)  # terre battue — l'herbe usée du village
const C_METAL      = Color(0.45, 0.40, 0.34)

const C_TISSU = [
	Color(0.71, 0.29, 0.20),  # auburn
	Color(0.83, 0.66, 0.26),  # doré miel
	Color(0.35, 0.45, 0.60),  # bleu crépuscule adouci
	Color(0.85, 0.80, 0.72),  # lin écru
]

const C_FLEUR = [
	Color(0.90, 0.85, 0.35),
	Color(0.85, 0.45, 0.55),
	Color(0.70, 0.75, 0.95),
	Color(0.95, 0.65, 0.30),
]

# Graine fixe : le village est décoré exactement pareil à chaque lancement.
# Sans ça, les arbres changeraient de place à chaque partie — intestable.
const GRAINE := 20260919

var _rng := RandomNumberGenerator.new()
var _maisons: Array = []            # rempli par construire()
var _materiaux: Dictionary = {}     # cache : une couleur = un seul matériau

# ──────────────────────────────────────────────────────────────────────────────
# POINT D'ENTRÉE
# ──────────────────────────────────────────────────────────────────────────────

# `maisons` est la liste préparée par zone1.gd, sous la forme
# [ { "modele": String, "pos": Vector3, "rot": float, "echelle": float,
#     "taille": Vector3 }, ... ].
# `taille` est l'emprise des murs, échelle comprise : elle sert à poser la
# terre battue devant la porte et à ne jamais planter un arbre dans un mur.
func construire(maisons: Array) -> void:
	_rng.seed = GRAINE
	_maisons  = maisons

	_poser_l_aelith()
	_poser_les_maisons()
	_battre_la_terre()
	_tracer_les_chemins()
	_planter_la_foret()
	_semer_herbe_et_fleurs()
	_poser_les_rochers()
	_verser_les_multimesh()       # toute la végétation d'un coup, en MultiMesh
	_habiller_le_puits()
	_remplir_le_village()
	_allumer_les_lanternes()
	_batir_la_vieille_maison()
	preload("res://scripts/zones/herbe.gd").semer(self, _maisons)  # l'herbe au vent (en dernier : elle évite le décor)

# ──────────────────────────────────────────────────────────────────────────────
# L'AELITH
# ──────────────────────────────────────────────────────────────────────────────
#
# Deux modèles : la paroi (le tronc creux qui ceinture la zone) et la canopée
# (les branches en voûte, très haut). Ils sont séparés parce qu'on retouche
# beaucoup plus souvent l'un que l'autre — et parce qu'un seul .glb de 21 000
# faces serait pénible à recharger à chaque essai.
#
# La collision du rempart est posée par `zone1.gd`, comme pour les maisons.

const AELITH_CENTRE := Vector3(0, 0, -10)

func _poser_l_aelith() -> void:
	for nom in ["aelith_paroi", "aelith_canopee"]:
		var modele: PackedScene = load(DOSSIER_MODELES + nom + ".glb")
		if modele == null:
			push_warning("Modèle manquant : " + nom + " — lance tools/gen_aelith_v2.py")
			continue
		var noeud: Node3D = modele.instantiate()
		noeud.position = AELITH_CENTRE
		add_child(noeud)

# ──────────────────────────────────────────────────────────────────────────────
# LES MAISONS
# ──────────────────────────────────────────────────────────────────────────────
#
# Les modèles sont générés par `tools/gen_maison.py` (Blender, en ligne de
# commande) et exportés en .glb. Ici on se contente de les instancier :
# la collision, elle, est posée par `zone1.gd` — voir le commentaire de MAISONS.
#
# `instantiate()` fabrique une copie indépendante du modèle. Trois fichiers
# suffisent donc pour les sept maisons : c'est la rotation et l'échelle qui
# font la variété.

const DOSSIER_MODELES := "res://assets/models/environnement/"

func _poser_les_maisons() -> void:
	for maison in _maisons:
		var chemin: String = DOSSIER_MODELES + str(maison["modele"]) + ".glb"
		var modele: PackedScene = load(chemin)
		if modele == null:
			push_warning("Modèle introuvable : " + chemin + " — lance tools/gen_maison.py")
			continue
		var noeud: Node3D = modele.instantiate()
		noeud.position   = maison["pos"]
		noeud.rotation.y = maison["rot"]
		noeud.scale      = Vector3.ONE * float(maison["echelle"])
		add_child(noeud)

# ──────────────────────────────────────────────────────────────────────────────
# TERRE BATTUE
# ──────────────────────────────────────────────────────────────────────────────
#
# Le sol de la zone est une prairie verte. Là où le village vit — la place, le
# devant des maisons — l'herbe est usée : on pose de grandes plaques de terre
# au ras du sol (y = 0.015, juste sous les dalles des chemins pour éviter que
# les deux surfaces ne clignotent l'une à travers l'autre).

func _battre_la_terre() -> void:
	# La place centrale, autour de l'Aelith et du puits.
	for donnees in [
		[Vector3(  2, 0,   8), Vector2(24, 20)],
		[Vector3( -2, 0,  -8), Vector2(20, 16)],
		[Vector3(  0, 0,  20), Vector2(16, 14)],
	]:
		_plaque_de_terre(donnees[0], donnees[1])

	# Devant chaque maison — le passage des habitants.
	for maison in _maisons:
		var taille: Vector3 = maison["taille"]
		var pos:    Vector3 = maison["pos"]
		_plaque_de_terre(
			Vector3(pos.x, 0, pos.z + taille.z * 0.5 + 1.8),
			Vector2(taille.x + 2.0, 5.0)
		)

func _plaque_de_terre(centre: Vector3, taille: Vector2) -> void:
	# Une plaque = quelques rectangles superposés et décalés : le bord devient
	# irrégulier, au lieu d'un carré net qui trahirait la géométrie.
	for i in 4:
		var plaque := BoxMesh.new()
		plaque.size = Vector3(
			taille.x * _rng.randf_range(0.6, 1.0),
			0.05,
			taille.y * _rng.randf_range(0.6, 1.0)
		)
		_prop(
			plaque,
			centre + Vector3(
				_rng.randf_range(-taille.x * 0.2, taille.x * 0.2),
				0.015,
				_rng.randf_range(-taille.y * 0.2, taille.y * 0.2)
			),
			C_SOL_USE,
			_rng.randf_range(0.0, TAU)
		)

# ──────────────────────────────────────────────────────────────────────────────
# CHEMINS
# ──────────────────────────────────────────────────────────────────────────────
#
# Des dalles plates posées au ras du sol (y = 0.03). Elles guident l'œil du
# joueur depuis l'entrée sud jusqu'à l'Aelith, puis jusqu'à la porte nord.

func _tracer_les_chemins() -> void:
	_dalles_entre(Vector3( 0, 0,  33), Vector3(  0, 0,   6), 3.2, 26)  # entrée → Aelith
	_dalles_entre(Vector3( 0, 0,  -6), Vector3(  0, 0, -34), 2.8, 24)  # Aelith → porte nord
	_dalles_entre(Vector3( 4, 0,   2), Vector3( 18, 0,  12), 2.0, 12)  # vers chez Lira
	_dalles_entre(Vector3(-4, 0,  -2), Vector3(-19, 0, -11), 2.0, 14)  # vers le moulin

func _dalles_entre(depart: Vector3, arrivee: Vector3, largeur: float, nombre: int) -> void:
	for i in nombre:
		# lerp() = interpolation : t va de 0 (départ) à 1 (arrivée).
		var t   := float(i) / float(nombre - 1)
		var pos := depart.lerp(arrivee, t)
		# Petit décalage : un chemin de village n'est jamais une ligne droite.
		pos.x += _rng.randf_range(-0.5, 0.5)
		pos.z += _rng.randf_range(-0.4, 0.4)
		pos.y  = 0.03

		var dalle := BoxMesh.new()
		dalle.size = Vector3(
			largeur * _rng.randf_range(0.75, 1.10),
			0.06,
			largeur * _rng.randf_range(0.50, 0.80)
		)
		var teinte := C_PIERRE.lerp(C_PIERRE_2, _rng.randf())
		_prop(dalle, pos, teinte, _rng.randf_range(-0.25, 0.25))

# ──────────────────────────────────────────────────────────────────────────────
# VÉGÉTATION : ARBRES, SOUS-BOIS, FLEURS, ROCHERS
# ──────────────────────────────────────────────────────────────────────────────
#
# Les modèles viennent du pack CC0 « Ultimate Nature Pack » de Quaternius,
# recolorés à la palette du jeu par `tools/recolor_cc0.py` (provenance et
# licence : assets/models/vegetation/LICENCES.md). Ils sont affichés en
# MULTIMESH.
#
# POURQUOI UN MULTIMESH
# Un MeshInstance3D par plante = un ordre de dessin par plante. Avec des
# centaines de plantes et l'écran splitté (la scène est rendue DEUX fois par
# image), c'est intenable. Un `MultiMeshInstance3D` dessine TOUTES les copies
# d'un même modèle en un seul ordre (un par matériau du modèle).
# Le prix à payer : toutes les copies partagent le même maillage, donc la
# variété vient de la rotation, de l'échelle… et du nombre de modèles.
#
# LA COMPOSITION (ce qui fait « Breath of the Wild » plutôt que « semis »)
#   - des BOSQUETS d'une même famille d'arbres (chênaie, boulaie, pinède), avec
#     leur sous-bois de fougères et de buissons, et des CLAIRIÈRES entre eux ;
#   - des LISIÈRES de buissons le long des maisons, des clôtures et de la
#     palissade nord — c'est là que la végétation pousse dans un vrai village ;
#   - des fleurs en TOUFFES d'une même couleur, jamais semées une par une ;
#   - des rochers moussus en petits GROUPES (un gros, deux ou trois petits).

const DOSSIER_VEGETATION := "res://assets/models/vegetation/quaternius/"

# Les modèles utilisés, et ce que le décor doit savoir de chacun :
#   hauteur      — hauteur du modèle à l'échelle 1, en mètres (pour la collision)
#   rayon_tronc  — rayon de la collision cylindre ; 0 = on traverse (buissons…)
#                  Valeurs affichées par tools/recolor_cc0.py (« rayon_tronc »).
#   portee       — distance au-delà de laquelle on ne dessine plus (0 = toujours).
#                  Une fleur à 40 m fait un pixel : autant ne pas la dessiner.
#   ombre        — false pour les petites plantes : leur ombre ne se voit pas,
#                  mais elle coûte un second passage de dessin.
const VEGETATION := {
	# Arbres
	"feuillu_large_1": { "hauteur": 11.0, "rayon_tronc": 0.38 },  # grands chênes
	"feuillu_large_2": { "hauteur": 12.5, "rayon_tronc": 0.43 },
	"feuillu_haut":    { "hauteur":  9.5, "rayon_tronc": 0.25 },
	"feuillu_rond":    { "hauteur":  7.5, "rayon_tronc": 0.26 },
	"feuillu_jeune":   { "hauteur":  7.0, "rayon_tronc": 0.30 },
	"feuillu_dore":    { "hauteur": 10.0, "rayon_tronc": 0.35 },  # rappel de l'Aelith
	"bouleau_1":       { "hauteur":  9.0, "rayon_tronc": 0.22 },
	"bouleau_2":       { "hauteur": 11.0, "rayon_tronc": 0.19 },
	"pin_1":           { "hauteur": 11.0, "rayon_tronc": 0.45 },
	"pin_2":           { "hauteur":  9.5, "rayon_tronc": 0.45 },
	"pin_3":           { "hauteur": 10.5, "rayon_tronc": 0.50 },
	"saule":           { "hauteur":  8.5, "rayon_tronc": 0.70 },
	# Sous-bois — traversables
	"buisson_1":       { "portee": 70.0 },
	"buisson_2":       { "portee": 70.0 },
	"buisson_baies":   { "portee": 55.0 },
	"fougere_basse":   { "portee": 35.0, "ombre": false },
	"fougere":         { "portee": 35.0, "ombre": false },
	"fougere_large":   { "portee": 40.0, "ombre": false },
	"fleurs_touffe":   { "portee": 30.0, "ombre": false },
	"fleurs_hautes":   { "portee": 30.0, "ombre": false },
	# Minéral et bois mort — traversables, comme les anciens rochers
	"rocher_1":        { "portee": 60.0 },
	"rocher_2":        {},
	"rocher_moussu_1": { "portee": 50.0 },
	"rocher_moussu_2": { "portee": 50.0 },
	"rocher_moussu_3": { "portee": 50.0 },
	"rocher_moussu_4": {},
	"rocher_moussu_5": {},
	"souche":          { "portee": 50.0 },
	"tronc_couche":    { "portee": 60.0 },
}

# Les familles de bosquets : un bosquet tire ses arbres dans UNE liste. C'est ce
# qui donne des taches lisibles (le bois de bouleaux, le coin des pins) au lieu
# d'un mélange uniforme.
const BOSQUETS := {
	"chenaie": ["feuillu_large_1", "feuillu_large_2", "feuillu_large_1", "feuillu_rond"],
	"boulaie": ["bouleau_1", "bouleau_2", "bouleau_2", "feuillu_jeune"],
	"pinede":  ["pin_1", "pin_2", "pin_3"],
	"mixte":   ["feuillu_haut", "feuillu_rond", "feuillu_jeune", "bouleau_1", "pin_2"],
}

# Taille des « cases » qui découpent les petits éléments (fleurs, fougères…)
# en plusieurs MultiMesh. Voir `_verser_les_multimesh()`.
const CASE_VEGETATION := 20.0

# Les plantations en attente, rangées par modèle, avant d'être versées dans les
# MultiMesh : { "pin_1": [Transform3D, ...], ... }
var _plantations: Dictionary = {}
# Le pied de chaque arbre déjà planté (x, z, rayon d'encombrement) : deux
# arbres ne poussent pas l'un dans l'autre.
var _arbres: Array = []
# Ce que la végétation ne doit JAMAIS cacher : les PNJ et les pièces des puzzles.
# Rempli par `_reperer_les_points_importants()`.
var _points_importants: Array = []

func _planter_la_foret() -> void:
	_reperer_les_points_importants()

	# ── 1. Les bosquets de la couronne ────────────────────────────────────────
	# Le village se sent « niché dans la forêt », et on ne voit plus le bord du
	# sol. Les trous entre les bosquets font les clairières.
	# L'anneau est centré sur l'Aelith (pas sur la place) : c'est sa paroi qui
	# borne la forêt, à 56 m de son centre.
	for i in 42:
		var angle := _rng.randf_range(0.0, TAU)
		var rayon := _rng.randf_range(30.0, 44.0)
		var centre := AELITH_CENTRE + Vector3(sin(angle) * rayon, 0.0, cos(angle) * rayon)
		var famille: String = ["chenaie", "chenaie", "boulaie", "pinede", "mixte"][_rng.randi() % 5]
		_bosquet(centre, famille, _rng.randi_range(3, 6), 6.5)

	# Quelques arbres isolés entre les bosquets, pour que la couronne reste
	# dense vue de loin.
	for i in 140:
		var angle := _rng.randf_range(0.0, TAU)
		var rayon := _rng.randf_range(26.0, 47.0)
		var pos := AELITH_CENTRE + Vector3(sin(angle) * rayon, 0.0, cos(angle) * rayon)
		var famille: String = BOSQUETS.keys()[_rng.randi() % BOSQUETS.size()]
		_planter_arbre(pos, _au_hasard(BOSQUETS[famille]), _rng.randf_range(0.8, 1.1))

	# ── 2. Derrière la palissade nord ─────────────────────────────────────────
	# C'est la forêt qui commence, la sortie de la zone. Surtout des pins : la
	# silhouette verticale ferme mieux l'horizon.
	for i in 26:
		var centre := Vector3(_rng.randf_range(-42.0, 42.0), 0.0, _rng.randf_range(-56.0, -42.0))
		_bosquet(centre, "pinede" if _rng.randf() < 0.6 else "mixte", _rng.randi_range(3, 5), 5.0)

	# ── 3. Les arbres du village ──────────────────────────────────────────────
	# Ombre et verticalité sur la place. Les grands chênes sont gardés pour les
	# endroits dégagés ; près des maisons, des arbres plus étroits.
	for donnees in [
		[Vector3( -9, 0,  18), "feuillu_large_2", 0.75],
		[Vector3( 15, 0,   8), "feuillu_rond",    0.95],  # était à (13, -2) : devant l'oiseau
		[Vector3(-16, 0,   4), "feuillu_dore",    0.85],  # le doré : l'Aelith en petit
		[Vector3( 11, 0,  16), "feuillu_haut",    0.90],
		[Vector3( 16, 0,  26), "feuillu_large_1", 0.85],
	]:
		_planter_arbre(donnees[0], donnees[1], donnees[2], true)

	# ── 4. Le saule, au bout du ruisseau ──────────────────────────────────────
	# Hors de la zone du Puzzle 3 (il ne cache ni la roue ni les lianes).
	_planter_arbre(Vector3(-42, 0, -24), "saule", 1.1, true)
	# Et deux arbres dorés en lisière, qui répondent à la couleur de l'Aelith.
	_planter_arbre(Vector3(-41, 0, -6), "feuillu_dore", 0.95, true)
	_planter_arbre(Vector3(38, 0, -24), "feuillu_dore", 1.0, true)

	# ── 5. Les lisières ───────────────────────────────────────────────────────
	_border_les_maisons()
	_border_les_palissades()

# Un bosquet : quelques arbres d'une même famille autour d'un centre, puis leur
# sous-bois (fougères au pied, buissons sur le pourtour).
func _bosquet(centre: Vector3, famille: String, nombre: int, etendue: float) -> void:
	var plantes := 0
	for i in nombre * 2:          # deux fois plus d'essais : certains sont refusés
		if plantes >= nombre:
			break
		var angle := _rng.randf_range(0.0, TAU)
		var dist := _rng.randf_range(0.0, etendue)
		var pos := centre + Vector3(sin(angle) * dist, 0.0, cos(angle) * dist)
		if _planter_arbre(pos, _au_hasard(BOSQUETS[famille]), _rng.randf_range(0.8, 1.15)):
			plantes += 1
	if plantes == 0:
		return

	# Sous-bois : les fougères au pied, à l'ombre.
	for i in _rng.randi_range(3, 6):
		var pos := centre + _decalage(etendue * 0.9)
		_planter_petit(pos, _au_hasard(["fougere", "fougere_large", "fougere_basse"]),
			_rng.randf_range(1.0, 1.6))
	# Les buissons sur le pourtour, côté lumière.
	for i in _rng.randi_range(1, 3):
		var angle := _rng.randf_range(0.0, TAU)
		var pos := centre + Vector3(sin(angle), 0.0, cos(angle)) * (etendue + 1.5)
		_planter_petit(pos, _au_hasard(["buisson_1", "buisson_2", "buisson_baies"]),
			_rng.randf_range(0.8, 1.3))
	# Parfois du bois mort : une souche ou un tronc couché.
	if _rng.randf() < 0.35:
		_planter_petit(centre + _decalage(etendue), _au_hasard(["souche", "tronc_couche"]),
			_rng.randf_range(1.0, 1.4))

# Des buissons et des fougères contre les murs des maisons — sur les côtés et
# derrière, jamais devant la porte (la terre battue du passage).
func _border_les_maisons() -> void:
	for maison in _maisons:
		var taille: Vector3 = maison["taille"]
		var centre: Vector3 = maison["pos"]
		var rot: float = maison["rot"]
		var demi_x := taille.x * 0.5 + 0.9
		var demi_z := taille.z * 0.5 + 0.9
		# Points du pourtour, dans le repère de la maison (z+ = la porte).
		var points: Array = []
		for t in [-0.8, -0.3, 0.3, 0.8]:
			points.append(Vector3(t * demi_x, 0, -demi_z))      # derrière
		for t in [-0.6, 0.0, 0.6]:
			points.append(Vector3(-demi_x, 0, t * demi_z))      # côté gauche
			points.append(Vector3( demi_x, 0, t * demi_z))      # côté droit
		for local in points:
			if _rng.randf() < 0.3:
				continue                    # des trous : une haie trop régulière fait jardin à la française
			var pos: Vector3 = centre + local.rotated(Vector3.UP, rot) + _decalage(0.4)
			if not _lisiere_libre(pos):
				continue
			if _rng.randf() < 0.65:
				_planter(pos, _au_hasard(["buisson_1", "buisson_2", "buisson_baies"]),
					_rng.randf_range(0.7, 1.1))
			else:
				_planter(pos, _au_hasard(["fougere", "fougere_large"]), _rng.randf_range(1.0, 1.4))

# Une lisière de buissons le long de la palissade nord et de la cour de la
# grille, côté village (côté ouest, c'est le Puzzle 3 : on n'y touche pas). La végétation pousse là où on ne fauche pas.
func _border_les_palissades() -> void:
	var lignes := [
		[Vector3( 10, 0, -34.6), Vector3( 44, 0, -34.6)],   # palissade nord, côté est
		[Vector3( 8.9, 0, -27), Vector3( 8.9, 0, -35)],     # la cour de la grille, côté est
	]
	for ligne in lignes:
		var a: Vector3 = ligne[0]
		var b: Vector3 = ligne[1]
		var nb := int(a.distance_to(b) / 2.2)
		for i in nb:
			var pos := a.lerp(b, (float(i) + _rng.randf_range(0.2, 0.8)) / float(nb))
			if not _lisiere_libre(pos):
				continue
			var tirage := _rng.randf()
			if tirage < 0.55:
				_planter(pos, _au_hasard(["buisson_1", "buisson_2", "buisson_baies"]),
					_rng.randf_range(0.8, 1.2))
			elif tirage < 0.85:
				_planter(pos, _au_hasard(["fougere", "fougere_large"]), _rng.randf_range(1.1, 1.5))
			else:
				_planter(pos, "fleurs_hautes", _rng.randf_range(1.2, 1.6))

# Plante un arbre si la place est libre. Renvoie true s'il a été planté.
# `force` : les arbres du village sont placés à la main, on ne vérifie que
# l'écart avec les points importants.
func _planter_arbre(pos: Vector3, nom: String, echelle: float, force: bool = false) -> bool:
	var infos: Dictionary = VEGETATION[nom]
	# L'encombrement au sol d'un arbre : un peu moins que le rayon de sa
	# couronne. Deux couronnes peuvent se mêler, pas deux troncs se toucher.
	var encombrement: float = float(infos["hauteur"]) * echelle * 0.16
	if not force:
		if not _emplacement_libre(pos, 2.5):
			return false
		for arbre in _arbres:
			if Vector2(pos.x - arbre.x, pos.z - arbre.z).length() < encombrement + arbre.y:
				return false
	if _cache_un_point_important(pos, 4.0):
		return false
	# On range (x, encombrement, z) dans un Vector3 : pas besoin d'une classe.
	_arbres.append(Vector3(pos.x, encombrement, pos.z))
	_planter(pos, nom, echelle)
	return true

# Plante un petit élément (fougère, buisson, fleurs, rocher) si la place est libre.
# `marge` : à agrandir pour les gros rochers, qui débordent largement de leur point.
func _planter_petit(pos: Vector3, nom: String, echelle: float, ecrasement: float = 1.0,
		marge: float = 0.6) -> void:
	if not _emplacement_libre(pos, marge):
		return
	if _cache_un_point_important(pos, 1.4 + marge):
		return
	_planter(pos, nom, echelle, ecrasement)

# Enregistre une plante. Rien n'est affiché avant `_verser_les_multimesh()`.
# `ecrasement` < 1 aplatit le modèle (rochers) : une seule forme en donne deux.
func _planter(pos: Vector3, nom: String, echelle: float, ecrasement: float = 1.0) -> void:
	var t := Transform3D()
	# Rotation au hasard autour de la verticale : c'est elle qui empêche de
	# reconnaître le même modèle répété.
	t = t.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
	t = t.scaled(Vector3(echelle, echelle * ecrasement, echelle))
	t.origin = pos

	if not _plantations.has(nom):
		_plantations[nom] = []
	_plantations[nom].append(t)

	# La collision reste un cylindre par tronc — invisible, et beaucoup moins
	# cher qu'une collision sur le maillage. Les modèles recolorés ont le pied
	# du tronc sur leur origine (tools/recolor_cc0.py) : le cylindre tombe pile
	# dedans. Buissons, fleurs et rochers n'en ont pas : on les traverse.
	var infos: Dictionary = VEGETATION.get(nom, {})
	if float(infos.get("rayon_tronc", 0.0)) > 0.0:
		var hauteur: float = float(infos["hauteur"]) * echelle
		_collision_cylindre(
			pos + Vector3(0, hauteur * 0.5, 0),
			float(infos["rayon_tronc"]) * echelle,
			hauteur
		)

# Verse les plantations dans des MultiMeshInstance3D.
#
# LES ARBRES : un seul MultiMesh par modèle, pour tout le village.
#
# LES PETITS ÉLÉMENTS (ceux qui ont une `portee`) : un MultiMesh par modèle ET
# par case de 20 × 20 m. Pourquoi ? `visibility_range_end` se mesure depuis la
# caméra jusqu'au CENTRE de la boîte englobante du noeud. Un MultiMesh qui
# couvre tout le village a son centre au milieu de la place : la portée
# n'aurait aucun sens (tout ou rien). En cases, seules celles proches de la
# caméra sont dessinées — et le frustum culling écarte aussi celles de derrière.
func _verser_les_multimesh() -> void:
	for nom in _plantations:
		var infos: Dictionary = VEGETATION.get(nom, {})
		var portee: float = float(infos.get("portee", 0.0))
		var groupes: Dictionary = {}
		for t: Transform3D in _plantations[nom]:
			var cle := Vector2i.ZERO
			if portee > 0.0:
				cle = Vector2i(floori(t.origin.x / CASE_VEGETATION), floori(t.origin.z / CASE_VEGETATION))
			if not groupes.has(cle):
				groupes[cle] = []
			groupes[cle].append(t)

		var modele := _maillage_du_modele(_chemin_du_modele(str(nom)))
		if modele.is_empty():
			continue
		for cle in groupes:
			var transformations: Array = groupes[cle]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh             = modele["maillage"]
			mm.instance_count   = transformations.size()
			# On recompose avec la transformation interne du modèle. Sans elle,
			# tous les arbres sont couchés : Godot range le maillage d'un .glb
			# sous un noeud qui porte la conversion d'axes Blender (Z haut) →
			# Godot (Y haut), et un MultiMesh n'utilise que le maillage.
			var correction: Transform3D = modele["transformation"]
			for i in transformations.size():
				mm.set_instance_transform(i, transformations[i] * correction)

			var noeud := MultiMeshInstance3D.new()
			noeud.name      = "Vegetation_%s_%d_%d" % [nom, cle.x, cle.y]
			noeud.multimesh = mm
			if portee > 0.0:
				# La portée vise le centre de la case : on ajoute sa demi-diagonale
				# pour qu'un élément au bord ne disparaisse pas trop tôt.
				noeud.visibility_range_end = portee + CASE_VEGETATION * 0.7
			if not bool(infos.get("ombre", true)):
				noeud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(noeud)

# Où trouver un modèle : la végétation CC0 d'abord, sinon les anciens modèles
# générés par tools/gen_arbres.py (arbre_chene, buisson…).
func _chemin_du_modele(nom: String) -> String:
	var chemin := DOSSIER_VEGETATION + nom + ".glb"
	if ResourceLoader.exists(chemin):
		return chemin
	return DOSSIER_MODELES + nom + ".glb"

# Sort d'un .glb son maillage ET la transformation qui va avec.
# Les modèles sont fusionnés en un seul objet à l'export (voir `exporter()`
# dans tools/blender_commun.py et `traiter()` dans tools/recolor_cc0.py), il
# n'y a donc qu'un MeshInstance3D à trouver.
# Renvoie { "maillage": Mesh, "transformation": Transform3D }, ou {} si raté.
func _maillage_du_modele(chemin: String) -> Dictionary:
	var scene: PackedScene = load(chemin)
	if scene == null:
		push_warning("Modèle introuvable : " + chemin + " — lance tools/recolor_cc0.py")
		return {}

	var racine := scene.instantiate()
	for noeud in _tous_les_enfants(racine):
		if noeud is MeshInstance3D and noeud.mesh != null:
			# On remonte jusqu'à la racine du modèle en accumulant les
			# transformations de chaque parent.
			var t := Transform3D.IDENTITY
			var courant: Node = noeud
			while courant != null and courant != racine.get_parent():
				if courant is Node3D:
					t = courant.transform * t
				courant = courant.get_parent()
			var resultat := { "maillage": noeud.mesh, "transformation": t }
			racine.queue_free()
			return resultat

	racine.queue_free()
	return {}

func _tous_les_enfants(racine: Node) -> Array:
	var liste: Array = [racine]
	for enfant in racine.get_children():
		liste.append_array(_tous_les_enfants(enfant))
	return liste

func _au_hasard(liste: Array) -> String:
	return str(liste[_rng.randi() % liste.size()])

# Un petit décalage horizontal au hasard, dans un disque de rayon `rayon`.
func _decalage(rayon: float) -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var r := sqrt(_rng.randf()) * rayon   # sqrt : répartition uniforme dans le disque
	return Vector3(sin(angle) * r, 0.0, cos(angle) * r)

# ──────────────────────────────────────────────────────────────────────────────
# CE QUE LA VÉGÉTATION NE DOIT PAS CACHER
# ──────────────────────────────────────────────────────────────────────────────
#
# Un arbre planté devant l'oiseau, un buisson sur un levier : le joueur cherche
# une pièce de puzzle qu'il ne peut pas voir. On relève donc, dans la scène de
# la zone (le parent du décor), la position de chaque PNJ et de chaque zone
# d'interaction ou pièce mobile des puzzles. Rien ne pousse près d'eux.
#
# L'oiseau est perché sur un toit : on garde en plus des « couloirs de vue »
# dégagés entre lui et les endroits d'où les joueurs le cherchent.

const COULOIRS_DE_VUE := [
	# [depuis, vers] — au sol, en x/z
	[Vector3(4, 0, 3.5),  Vector3(22, 0, -3.2)],   # Vaenmor (la place) → l'oiseau
	[Vector3(6, 0, -14),  Vector3(22, 0, -3.2)],   # la plateforme → l'oiseau
	[Vector3(0, 0, 10),   Vector3(22, 0, -3.2)],   # la rue principale → l'oiseau
	[Vector3(-2, 0, -6),  Vector3(-16, 0, -28)],   # la place → les lianes et la roue
]

func _reperer_les_points_importants() -> void:
	_points_importants.clear()
	# Le décor est enfant de la zone (zone1.gd). Hors de la zone (outil de
	# mesure), il n'y a rien à protéger.
	var zone := get_parent() as Node3D
	if zone == null:
		return
	for nom in ["PNJ", "Puzzle1PorteDouble", "Puzzle2Oiseau", "Puzzle3RoueEau",
			"ZoneGrimoire", "ZoneStele"]:
		var noeud := zone.get_node_or_null(nom)
		if noeud == null:
			continue
		# Chaque noeud 3D du groupe (le PNJ, une zone d'interaction, la grille…)
		# sauf les formes de collision et les maillages, qui sont à la même
		# place que leur parent. Les positions sont ramenées dans le repère
		# de la zone, au sol.
		for enfant in _tous_les_enfants(noeud):
			if enfant is Node3D and not (enfant is CollisionShape3D or enfant is MeshInstance3D):
				var local: Vector3 = zone.to_local(enfant.global_position)
				_points_importants.append(Vector3(local.x, 0.0, local.z))

# true si `pos` est à moins de `rayon` d'un PNJ ou d'une pièce de puzzle, ou
# dans un couloir de vue de l'oiseau.
func _cache_un_point_important(pos: Vector3, rayon: float) -> bool:
	var sol := Vector3(pos.x, 0.0, pos.z)
	for point in _points_importants:
		if sol.distance_to(point) < rayon:
			return true
	for couloir in COULOIRS_DE_VUE:
		var proche := Geometry3D.get_closest_point_to_segment(sol, couloir[0], couloir[1])
		if sol.distance_to(proche) < rayon:
			return true
	return false

# Une lisière (contre un mur, une clôture) n'a pas à respecter la marge des
# maisons de `_emplacement_libre()` — c'est tout son intérêt. On vérifie le
# reste : le chemin, les puzzles, la cavité, les PNJ.
func _lisiere_libre(pos: Vector3) -> bool:
	if pos.distance_to(AELITH_CENTRE) > 48.0:
		return false
	if abs(pos.x) < 3.6 or _sur_un_chemin(pos, 1.5):          # les chemins
		return false
	if pos.x > -40.0 and pos.x < -8.0 and pos.z > -42.0 and pos.z < -14.0:   # Puzzle 3
		return false
	if abs(pos.x) < 8.0 and pos.z < -22.0:                    # grille, porte, stèle
		return false
	return not _cache_un_point_important(pos, 2.2)

# ──────────────────────────────────────────────────────────────────────────────
# FLEURS ET ROCHERS
# ──────────────────────────────────────────────────────────────────────────────
#
# L'herbe au sol n'est plus ici : elle est dessinée par un shader dédié
# (scripts/zones/herbe.gd). Les anciennes touffes en lamelles (420 petits
# objets, 420 ordres de dessin) sont retirées.

func _semer_herbe_et_fleurs() -> void:
	# Des touffes de fleurs : 4 à 9 fleurs d'une même sorte, serrées. Une
	# prairie de BotW, ce sont des taches de couleur, pas des points isolés.
	for i in 34:
		var centre := _position_au_hasard(7.0, 40.0)
		if centre == Vector3.INF:
			continue
		var sorte := "fleurs_touffe" if _rng.randf() < 0.65 else "fleurs_hautes"
		var nb := _rng.randi_range(4, 9) if sorte == "fleurs_touffe" else _rng.randi_range(2, 4)
		for j in nb:
			_planter_petit(centre + _decalage(1.3), sorte, _rng.randf_range(1.1, 1.6))
		# Une fougère ou deux au bord de la touffe, de temps en temps.
		if _rng.randf() < 0.4:
			_planter_petit(centre + _decalage(2.0), "fougere_basse", _rng.randf_range(1.0, 1.4))


func _poser_les_rochers() -> void:
	# Des groupes : un gros rocher moussu, deux ou trois petits autour. Ils
	# donnent au village un relief que le sol plat n'a pas.
	for i in 16:
		var centre := _position_au_hasard(14.0, 44.0)
		if centre == Vector3.INF:
			continue
		_planter_petit(centre, _au_hasard(["rocher_moussu_4", "rocher_moussu_5", "rocher_2"]),
			_rng.randf_range(1.6, 2.6), _rng.randf_range(0.7, 1.0), 2.5)
		for j in _rng.randi_range(1, 3):
			_planter_petit(centre + _decalage(2.2),
				_au_hasard(["rocher_moussu_1", "rocher_moussu_2", "rocher_moussu_3", "rocher_1"]),
				_rng.randf_range(0.9, 1.6), _rng.randf_range(0.6, 1.0))
		if _rng.randf() < 0.5:
			_planter_petit(centre + _decalage(2.5), "fougere", _rng.randf_range(1.0, 1.3))

	# Au pied du rempart, de gros blocs tombés de la paroi.
	for i in 10:
		var angle := _rng.randf_range(0.0, TAU)
		var pos := AELITH_CENTRE + Vector3(sin(angle), 0.0, cos(angle)) * _rng.randf_range(45.0, 47.5)
		_planter_petit(pos, _au_hasard(["rocher_2", "rocher_moussu_4", "rocher_moussu_5"]),
			_rng.randf_range(2.4, 3.6), _rng.randf_range(0.7, 1.0), 3.0)


# ──────────────────────────────────────────────────────────────────────────────
# LE PUITS
# ──────────────────────────────────────────────────────────────────────────────
#
# Le puits existe déjà dans zone1.gd (une simple boîte de pierre à 7, 6).
# On lui ajoute la margelle, les deux montants, le petit toit et le seau.

func _habiller_le_puits() -> void:
	var p := Vector3(7.0, 0.0, 6.0)

	# Le puits modélisé (tools/gen_props.py) est posé par zone1.gd sur sa
	# boîte de collision : s'il existe, l'habillage en primitives est inutile.
	if ResourceLoader.exists("res://assets/models/props/puits.glb"):
		return

	var margelle := TorusMesh.new()
	margelle.inner_radius = 0.85
	margelle.outer_radius = 1.15
	_prop(margelle, p + Vector3(0, 1.5, 0), C_PIERRE)

	var montant := BoxMesh.new()
	montant.size = Vector3(0.16, 2.2, 0.16)
	_prop(montant, p + Vector3(-0.8, 2.6, 0), C_BOIS)
	_prop(montant, p + Vector3( 0.8, 2.6, 0), C_BOIS)

	var toit := PrismMesh.new()
	toit.size = Vector3(2.4, 0.7, 2.0)
	_prop(toit, p + Vector3(0, 4.0, 0), C_TUILE)

	# Le treuil : un cylindre couché à l'horizontale entre les deux montants.
	var axe := CylinderMesh.new()
	axe.top_radius    = 0.09
	axe.bottom_radius = 0.09
	axe.height        = 1.8
	var mi_axe := _prop(axe, p + Vector3(0, 3.4, 0), C_BOIS_CLAIR)
	mi_axe.rotation.z = PI * 0.5

	var seau := CylinderMesh.new()
	seau.top_radius    = 0.22
	seau.bottom_radius = 0.18
	seau.height        = 0.35
	_prop(seau, p + Vector3(0, 2.4, 0), C_BOIS)

# ──────────────────────────────────────────────────────────────────────────────
# LA VIE DU VILLAGE
# ──────────────────────────────────────────────────────────────────────────────

func _remplir_le_village() -> void:
	# ── Tonneaux et caisses contre les maisons ────────────────────────────────
	for pos in [
		Vector3( 17.5, 0,  11.0), Vector3( 18.2, 0, 12.0), Vector3(-17.0, 0, -8.0),
		Vector3(-13.5, 0,  17.0), Vector3(  4.0, 0, 20.0), Vector3( -2.5, 0, 19.0),
	]:
		_tonneau(pos)

	for pos in [
		Vector3( 18.0, 0, 16.5), Vector3(-16.5, 0, 16.0), Vector3(6.0, 0, 21.0),
		Vector3(-17.8, 0, -9.5), Vector3( 16.5, 0, -2.0),
	]:
		_caisse(pos)

	# ── Bottes de foin près du moulin de Brennan ──────────────────────────────
	for pos in [Vector3(-16.0, 0, -16.0), Vector3(-14.6, 0, -17.2), Vector3(-15.4, 0, -14.6)]:
		var botte := CylinderMesh.new()
		botte.top_radius      = 0.7
		botte.bottom_radius   = 0.7
		botte.height          = 1.1
		botte.radial_segments = 10
		var mi := _prop(botte, pos + Vector3(0, 0.7, 0), C_FOIN, _rng.randf_range(0.0, TAU))
		mi.rotation.x = PI * 0.5   # couchée sur le flanc

	_charrette(Vector3(-5.0, 0, 12.0), 0.6)          # sur la place
	_etal(Vector3(6.5, 0, 16.0))                     # l'étal du marché
	_corde_a_linge(Vector3(13.0, 0, 20.0), Vector3(19.0, 0, 21.0))
	_potager(Vector3(27.0, 0, 16.0))                 # derrière chez Lira

	_cloture(Vector3( 26.0, 0, 11.0), Vector3(26.0, 0, 21.0))
	_cloture(Vector3(-11.0, 0, 21.0), Vector3(-2.0, 0, 21.0))

func _tonneau(pos: Vector3) -> void:
	var corps := CylinderMesh.new()
	corps.top_radius      = 0.32
	corps.bottom_radius   = 0.32
	corps.height          = 0.90
	corps.radial_segments = 10
	_prop(corps, pos + Vector3(0, 0.45, 0), C_BOIS)

	for h in [0.25, 0.65]:
		var cercle := TorusMesh.new()
		cercle.inner_radius = 0.32
		cercle.outer_radius = 0.37
		_prop(cercle, pos + Vector3(0, h, 0), C_METAL)

func _caisse(pos: Vector3) -> void:
	var t := _rng.randf_range(0.5, 0.8)
	var c := BoxMesh.new()
	c.size = Vector3(t, t, t)
	_prop(c, pos + Vector3(0, t * 0.5, 0), C_BOIS_CLAIR, _rng.randf_range(0.0, TAU))

func _charrette(pos: Vector3, rot: float) -> void:
	var plateau := BoxMesh.new()
	plateau.size = Vector3(2.6, 0.18, 1.4)
	_prop(plateau, pos + Vector3(0, 0.75, 0), C_BOIS_CLAIR, rot)

	# `lat` = le vecteur "côté" de la charrette, une fois tournée de `rot`.
	# On s'en sert pour placer les ridelles et les roues des deux bords.
	var lat := Vector3(sin(rot + PI * 0.5), 0, cos(rot + PI * 0.5)) * 0.65

	var ridelle := BoxMesh.new()
	ridelle.size = Vector3(2.6, 0.5, 0.1)
	_prop(ridelle, pos + Vector3(0, 1.05, 0) + lat, C_BOIS, rot)
	_prop(ridelle, pos + Vector3(0, 1.05, 0) - lat, C_BOIS, rot)

	for cote in [-1.0, 1.0]:
		var roue := TorusMesh.new()
		roue.inner_radius = 0.38
		roue.outer_radius = 0.52
		var mi := _prop(roue, pos + Vector3(0, 0.52, 0) + lat * cote * 1.15, C_BOIS)
		mi.rotation = Vector3(PI * 0.5, rot, 0)

	# Les brancards, posés en oblique dans l'herbe.
	var brancard := BoxMesh.new()
	brancard.size = Vector3(1.6, 0.12, 0.12)
	var avant := Vector3(sin(rot), 0, cos(rot)) * 1.9
	var mi_b := _prop(brancard, pos + avant + Vector3(0, 0.45, 0), C_BOIS_CLAIR, rot)
	mi_b.rotation.z = -0.25

func _etal(pos: Vector3) -> void:
	var table := BoxMesh.new()
	table.size = Vector3(3.0, 0.14, 1.4)
	_prop(table, pos + Vector3(0, 0.95, 0), C_BOIS_CLAIR)

	var pied := BoxMesh.new()
	pied.size = Vector3(0.14, 1.9, 0.14)
	for dx in [-1.35, 1.35]:
		for dz in [-0.6, 0.6]:
			_prop(pied, pos + Vector3(dx, 0.95, dz), C_BOIS)

	# Auvent en tissu, légèrement incliné.
	var auvent := BoxMesh.new()
	auvent.size = Vector3(3.4, 0.08, 1.8)
	var mi := _prop(auvent, pos + Vector3(0, 2.05, 0), C_TISSU[0])
	mi.rotation.x = 0.12

	# Marchandises : quelques boules colorées posées sur la table.
	for i in 6:
		var fruit := SphereMesh.new()
		fruit.radius          = 0.13
		fruit.height          = 0.26
		fruit.radial_segments = 6
		fruit.rings           = 4
		_prop(
			fruit,
			pos + Vector3(_rng.randf_range(-1.2, 1.2), 1.13, _rng.randf_range(-0.4, 0.4)),
			C_FLEUR[_rng.randi() % C_FLEUR.size()]
		)

func _corde_a_linge(a: Vector3, b: Vector3) -> void:
	var poteau := BoxMesh.new()
	poteau.size = Vector3(0.12, 2.6, 0.12)
	_prop(poteau, a + Vector3(0, 1.3, 0), C_BOIS)
	_prop(poteau, b + Vector3(0, 1.3, 0), C_BOIS)

	var longueur := a.distance_to(b)
	var milieu   := a.lerp(b, 0.5)
	# atan2(x, z) donne l'angle de rotation autour de Y pour aligner un objet
	# sur la direction a → b.
	var angle    := atan2(b.x - a.x, b.z - a.z)

	var corde := BoxMesh.new()
	corde.size = Vector3(0.04, 0.04, longueur)
	_prop(corde, milieu + Vector3(0, 2.4, 0), Color(0.75, 0.70, 0.60), angle)

	# Les draps qui pendent — c'est eux qui font vivre la scène.
	for i in 4:
		var t := 0.2 + i * 0.2
		var drap := BoxMesh.new()
		drap.size = Vector3(0.05, 1.0, 0.7)
		_prop(drap, a.lerp(b, t) + Vector3(0, 1.85, 0), C_TISSU[i % C_TISSU.size()], angle)

func _potager(pos: Vector3) -> void:
	var terre := BoxMesh.new()
	terre.size = Vector3(5.0, 0.12, 4.0)
	_prop(terre, pos + Vector3(0, 0.06, 0), C_TERRE)

	for rang in 4:
		for plant in 6:
			var feuille := SphereMesh.new()
			feuille.radius          = 0.17
			feuille.height          = 0.24
			feuille.radial_segments = 6
			feuille.rings           = 3
			_prop(feuille, pos + Vector3(-2.0 + plant * 0.8, 0.20, -1.4 + rang * 0.95), C_FEUILLE_2)

func _cloture(a: Vector3, b: Vector3) -> void:
	var longueur := a.distance_to(b)
	var angle    := atan2(b.x - a.x, b.z - a.z)
	var nb       := int(longueur / 1.2) + 1

	var piquet := BoxMesh.new()
	piquet.size = Vector3(0.12, 1.0, 0.12)
	for i in nb:
		_prop(piquet, a.lerp(b, float(i) / float(nb - 1)) + Vector3(0, 0.5, 0), C_BOIS)

	var lisse := BoxMesh.new()
	lisse.size = Vector3(0.06, 0.1, longueur)
	_prop(lisse, a.lerp(b, 0.5) + Vector3(0, 0.75, 0), C_BOIS_CLAIR, angle)
	_prop(lisse, a.lerp(b, 0.5) + Vector3(0, 0.35, 0), C_BOIS_CLAIR, angle)

# ──────────────────────────────────────────────────────────────────────────────
# LANTERNES
# ──────────────────────────────────────────────────────────────────────────────
#
# Une `OmniLight3D` éclaire dans toutes les directions autour d'elle, comme une
# ampoule. On en met peu (6) et sans ombres portées : les ombres dynamiques
# coûtent cher, et en écran splitté la scène est rendue DEUX fois par image.

func _allumer_les_lanternes() -> void:
	for pos in [
		Vector3( 3.5, 0,  14.0), Vector3(-3.5, 0,   8.0), Vector3(9.0, 0,  3.0),
		Vector3(-8.0, 0,  -6.0), Vector3( 2.0, 0, -20.0), Vector3(-3.0, 0, 26.0),
	]:
		var mat := BoxMesh.new()
		mat.size = Vector3(0.14, 2.8, 0.14)
		_prop(mat, pos + Vector3(0, 1.4, 0), C_BOIS)

		var bras := BoxMesh.new()
		bras.size = Vector3(0.5, 0.1, 0.1)
		_prop(bras, pos + Vector3(0.2, 2.75, 0), C_BOIS)

		var verre := BoxMesh.new()
		verre.size = Vector3(0.3, 0.4, 0.3)
		var mi := _prop(verre, pos + Vector3(0.4, 2.45, 0), C_LUMIERE)

		# `emission` = le matériau émet sa propre lumière : le verre a l'air
		# allumé même dans l'ombre. On lui donne un matériau à lui pour ne pas
		# faire briller tout ce qui partage la couleur dorée (les fenêtres).
		var mat_verre := StandardMaterial3D.new()
		mat_verre.albedo_color     = C_LUMIERE
		mat_verre.emission_enabled = true
		mat_verre.emission         = C_LUMIERE
		mat_verre.emission_energy_multiplier = 1.6
		mi.material_override = mat_verre

		var lampe := OmniLight3D.new()
		lampe.position       = pos + Vector3(0.4, 2.45, 0)
		lampe.light_color    = C_LUMIERE
		lampe.light_energy   = 1.1
		lampe.omni_range     = 9.0
		lampe.shadow_enabled = false
		add_child(lampe)

# ──────────────────────────────────────────────────────────────────────────────
# LA VIEILLE MAISON DU NORD
# ──────────────────────────────────────────────────────────────────────────────
#
# Le dialogue du grimoire dit « quelque chose brille dans la vieille maison au
# nord » — mais il n'y avait aucune maison là-bas. La voici : en ruine, sans
# toit, pour qu'on comprenne au premier coup d'œil qu'elle est abandonnée.
# Elle entoure la ZoneGrimoire, qui se trouve à (8, 0, -40).

func _batir_la_vieille_maison() -> void:
	var p := Vector3(8.0, 0, -40.0)

	var mur_long := BoxMesh.new()
	mur_long.size = Vector3(6.0, 2.6, 0.4)
	_prop(mur_long, p + Vector3(0, 1.3, -3.0), C_PIERRE_2)

	var mur_lat := BoxMesh.new()
	mur_lat.size = Vector3(0.4, 2.6, 6.0)
	_prop(mur_lat, p + Vector3(-3.0, 1.3, 0), C_PIERRE_2)

	# Mur effondré : deux moignons, avec le trou au milieu (l'entrée).
	var moignon := BoxMesh.new()
	moignon.size = Vector3(0.4, 1.2, 2.0)
	_prop(moignon, p + Vector3(3.0, 0.6, -2.0), C_PIERRE_2)
	_prop(moignon, p + Vector3(3.0, 0.9,  2.2), C_PIERRE_2)

	# Reste de charpente, en travers.
	var poutre := BoxMesh.new()
	poutre.size = Vector3(6.5, 0.22, 0.22)
	var mi := _prop(poutre, p + Vector3(0, 1.6, -1.0), C_BOIS)
	mi.rotation.z = -0.35

	# Gravats
	for i in 8:
		var t := _rng.randf_range(0.25, 0.6)
		var bloc := BoxMesh.new()
		bloc.size = Vector3(t, t * 0.6, t)
		_prop(
			bloc,
			p + Vector3(_rng.randf_range(-3.5, 3.5), t * 0.3, _rng.randf_range(-3.5, 3.5)),
			C_PIERRE_2,
			_rng.randf_range(0.0, TAU)
		)

# ──────────────────────────────────────────────────────────────────────────────
# OUTILS INTERNES
# ──────────────────────────────────────────────────────────────────────────────

# Crée un objet visible, SANS collision, et le renvoie pour un réglage éventuel
# (rotation sur un autre axe, mise à l'échelle…).
func _prop(mesh: Mesh, pos: Vector3, couleur: Color, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh              = mesh
	mi.material_override = _materiau(couleur)
	mi.position          = pos
	mi.rotation.y        = rot_y
	add_child(mi)
	return mi

# Deux objets de la même couleur partagent le même matériau, au lieu d'en créer
# des centaines d'identiques. C'est plus léger pour la mémoire et le rendu.
func _materiau(couleur: Color) -> StandardMaterial3D:
	var cle := couleur.to_rgba32()
	if not _materiaux.has(cle):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = couleur
		# Un peu de rugosité : pas de reflet plastique, on reste sur du mat.
		mat.roughness = 0.9
		_materiaux[cle] = mat
	return _materiaux[cle]

func _collision_cylindre(pos: Vector3, rayon: float, hauteur: float) -> void:
	var sb    := StaticBody3D.new()
	var cs    := CollisionShape3D.new()
	var forme := CylinderShape3D.new()
	forme.radius = rayon
	forme.height = hauteur
	cs.shape     = forme
	sb.position  = pos
	sb.add_child(cs)
	add_child(sb)

# Tire une position au hasard dans un anneau autour de l'Aelith, en rejetant
# les endroits occupés. Renvoie Vector3.INF si rien n'est libre après 12 essais —
# l'appelant fait alors simplement l'impasse sur cet objet.
func _position_au_hasard(rayon_min: float, rayon_max: float) -> Vector3:
	for essai in 12:
		var angle := _rng.randf_range(0.0, TAU)
		var r     := _rng.randf_range(rayon_min, rayon_max)
		var pos   := Vector3(sin(angle) * r, 0.0, cos(angle) * r)
		if _emplacement_libre(pos, 1.0):
			return pos
	return Vector3.INF

# Un emplacement est libre s'il ne tombe ni dans une maison, ni sur un chemin,
# ni dans le ruisseau, ni sur une zone de puzzle.
func _emplacement_libre(pos: Vector3, marge: float) -> bool:
	# Rester DANS la cavité de l'Aelith : le rempart est à 56 m du centre de
	# l'anneau, on garde 8 m de marge pour ne pas planter d'arbre dans le mur.
	if pos.distance_to(AELITH_CENTRE) > 48.0:
		return false
	# Laisser le passage libre derrière la porte nord (la sortie de la zone)
	if abs(pos.x) < 7.0 and pos.z < -36.0:
		return false
	# Ne pas planter d'arbre au travers de la palissade nord (z = -36)
	if abs(pos.z + 36.0) < 3.5:
		return false
	# Le pied de l'Aelith
	if Vector2(pos.x, pos.z).length() < 8.0:
		return false
	# La rue principale nord-sud, et les deux chemins de traverse
	if abs(pos.x) < 3.0 + marge or _sur_un_chemin(pos, 1.0 + marge):
		return false
	# Tout le Puzzle 3 — le ruisseau, la roue à eau, les lianes et la lanterne.
	# Large exprès : un arbre planté devant cacherait une pièce du puzzle.
	if pos.x > -40.0 and pos.x < -8.0 and pos.z > -42.0 and pos.z < -14.0:
		return false
	# Devant la grille (Puzzle 2), la porte (Puzzle 1) et la stèle
	if abs(pos.x) < 8.0 and pos.z < -22.0:
		return false
	# La vieille maison du nord
	if pos.distance_to(Vector3(8, 0, -40)) < 6.0:
		return false
	# Les maisons, avant-toit compris
	for maison in _maisons:
		var taille: Vector3 = maison["taille"]
		var centre: Vector3 = maison["pos"]
		var demi: float = max(taille.x, taille.z) * 0.5 + 1.5 + marge
		if Vector2(pos.x - centre.x, pos.z - centre.z).length() < demi:
			return false
	return true

# Les deux chemins de traverse dallés (voir `_tracer_les_chemins()`).
const CHEMINS := [
	[Vector3( 4, 0,  2), Vector3( 18, 0,  12)],   # vers chez Lira
	[Vector3(-4, 0, -2), Vector3(-19, 0, -11)],   # vers le moulin
]

func _sur_un_chemin(pos: Vector3, marge: float) -> bool:
	var sol := Vector3(pos.x, 0.0, pos.z)
	for chemin in CHEMINS:
		var proche := Geometry3D.get_closest_point_to_segment(sol, chemin[0], chemin[1])
		if sol.distance_to(proche) < marge:
			return true
	return false
