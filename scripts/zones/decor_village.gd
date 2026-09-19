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
	_habiller_le_puits()
	_remplir_le_village()
	_allumer_les_lanternes()
	_batir_la_vieille_maison()

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
# FORÊT
# ──────────────────────────────────────────────────────────────────────────────
#
# Les arbres sont des modèles Blender (`tools/gen_arbres.py`), affichés en
# MULTIMESH.
#
# POURQUOI UN MULTIMESH
# Un MeshInstance3D par arbre = un ordre de dessin par arbre. Avec ~190 arbres
# et l'écran splitté (la scène est rendue DEUX fois par image), ça fait 380
# ordres de dessin rien que pour la forêt. Un `MultiMeshInstance3D` dessine
# TOUS les arbres d'une même essence en un seul ordre : on passe à 4.
# Le prix à payer : tous les arbres d'une essence partagent le même maillage,
# donc la variété doit venir de la rotation et de l'échelle.

const ESSENCES := {
	"arbre_chene":   { "hauteur": 10.5, "rayon_tronc": 0.50 },
	"arbre_erable":  { "hauteur":  7.5, "rayon_tronc": 0.36 },
	"arbre_pin":     { "hauteur":  8.2, "rayon_tronc": 0.40 },
	"arbre_bouleau": { "hauteur":  8.1, "rayon_tronc": 0.28 },
}

# Les plantations en attente, rangées par essence, avant d'être versées dans
# les MultiMesh : { "arbre_chene": [Transform3D, ...], ... }
var _plantations: Dictionary = {}

func _planter_la_foret() -> void:
	# Une couronne d'arbres autour du village : on ne voit plus le bord du sol,
	# et le village se sent « niché dans la forêt ».
	for i in 130:
		var angle := _rng.randf_range(0.0, TAU)
		var rayon := _rng.randf_range(27.0, 46.0)
		var pos   := Vector3(sin(angle) * rayon, 0.0, cos(angle) * rayon)
		if not _emplacement_libre(pos, 3.0):
			continue
		_planter(pos, _essence_au_hasard(), _rng.randf_range(0.75, 1.15))

	# Derrière la palissade nord : c'est la forêt qui commence, la sortie de la
	# zone. Sans ça, tout le fond de la carte derrière la porte est vide.
	# Plus de conifères ici : la silhouette verticale ferme mieux l'horizon.
	for i in 60:
		var pos := Vector3(_rng.randf_range(-44.0, 44.0), 0.0, _rng.randf_range(-58.0, -42.0))
		if not _emplacement_libre(pos, 2.0):
			continue
		var essence := "arbre_pin" if _rng.randf() < 0.55 else _essence_au_hasard()
		_planter(pos, essence, _rng.randf_range(0.85, 1.3))

	# Quelques arbres isolés dans le village lui-même (ombre, verticalité).
	for pos in [
		Vector3( -9, 0,  18), Vector3( 13, 0,  -2), Vector3(-16, 0,   4),
		Vector3( 11, 0,  16), Vector3(-10, 0, -18), Vector3( 16, 0,  26),
	]:
		_planter(pos, "arbre_chene" if _rng.randf() < 0.5 else "arbre_erable",
				 _rng.randf_range(0.7, 0.95))

	# Des buissons en lisière et autour des maisons.
	for i in 60:
		var pos := _position_au_hasard(10.0, 40.0)
		if pos == Vector3.INF:
			continue
		_planter(pos, "buisson", _rng.randf_range(0.7, 1.4))

	_verser_les_multimesh()

func _essence_au_hasard() -> String:
	var tirage := _rng.randf()
	if tirage < 0.35:
		return "arbre_chene"
	if tirage < 0.65:
		return "arbre_erable"
	if tirage < 0.85:
		return "arbre_bouleau"
	return "arbre_pin"

# Enregistre un arbre. Rien n'est affiché avant `_verser_les_multimesh()`.
func _planter(pos: Vector3, essence: String, echelle: float) -> void:
	var t := Transform3D()
	# Rotation au hasard autour de la verticale : c'est elle qui empêche de
	# reconnaître le même modèle répété.
	t = t.rotated(Vector3.UP, _rng.randf_range(0.0, TAU))
	t = t.scaled(Vector3.ONE * echelle)
	t.origin = pos

	if not _plantations.has(essence):
		_plantations[essence] = []
	_plantations[essence].append(t)

	# La collision reste un cylindre par arbre — invisible, et beaucoup moins
	# cher qu'une collision sur le maillage. Les buissons n'en ont pas : on
	# doit pouvoir les traverser.
	if ESSENCES.has(essence):
		var infos: Dictionary = ESSENCES[essence]
		var hauteur: float = float(infos["hauteur"]) * echelle
		_collision_cylindre(
			pos + Vector3(0, hauteur * 0.5, 0),
			float(infos["rayon_tronc"]) * echelle,
			hauteur
		)

func _verser_les_multimesh() -> void:
	for essence in _plantations:
		var transformations: Array = _plantations[essence]
		var modele := _maillage_du_modele(DOSSIER_MODELES + str(essence) + ".glb")
		if modele.is_empty():
			continue

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh             = modele["maillage"]
		mm.instance_count   = transformations.size()
		# On recompose avec la transformation interne du modèle. Sans elle,
		# tous les arbres sont couchés : Godot range le maillage d'un .glb sous
		# un noeud qui porte la conversion d'axes Blender (Z haut) → Godot
		# (Y haut), et un MultiMesh n'utilise que le maillage, pas le noeud.
		var correction: Transform3D = modele["transformation"]
		for i in transformations.size():
			mm.set_instance_transform(i, transformations[i] * correction)

		var noeud := MultiMeshInstance3D.new()
		noeud.name      = "Foret_" + str(essence)
		noeud.multimesh = mm
		add_child(noeud)

# Sort d'un .glb son maillage ET la transformation qui va avec.
# Les modèles sont fusionnés en un seul objet à l'export (voir `exporter()`
# dans tools/blender_commun.py), il n'y a donc qu'un MeshInstance3D à trouver.
# Renvoie { "maillage": Mesh, "transformation": Transform3D }, ou {} si raté.
func _maillage_du_modele(chemin: String) -> Dictionary:
	var scene: PackedScene = load(chemin)
	if scene == null:
		push_warning("Modèle introuvable : " + chemin + " — lance tools/gen_arbres.py")
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

# ──────────────────────────────────────────────────────────────────────────────
# HERBE, FLEURS, ROCHERS
# ──────────────────────────────────────────────────────────────────────────────

func _semer_herbe_et_fleurs() -> void:
	for i in 140:
		var pos := _position_au_hasard(6.0, 34.0)
		if pos == Vector3.INF:
			continue
		# Une touffe = 3 lamelles fines, tournées au hasard.
		for j in 3:
			var brin := BoxMesh.new()
			brin.size = Vector3(0.08, _rng.randf_range(0.30, 0.60), 0.08)
			_prop(
				brin,
				pos + Vector3(_rng.randf_range(-0.2, 0.2), 0.2, _rng.randf_range(-0.2, 0.2)),
				C_HERBE.lerp(C_FEUILLE_2, _rng.randf()),
				_rng.randf_range(0.0, TAU)
			)

	for i in 70:
		var pos := _position_au_hasard(7.0, 30.0)
		if pos == Vector3.INF:
			continue
		var tige := BoxMesh.new()
		tige.size = Vector3(0.05, 0.35, 0.05)
		_prop(tige, pos + Vector3(0, 0.17, 0), C_HERBE)

		var petale := SphereMesh.new()
		petale.radius          = 0.09
		petale.height          = 0.14
		petale.radial_segments = 6
		petale.rings           = 3
		_prop(petale, pos + Vector3(0, 0.38, 0), C_FLEUR[_rng.randi() % C_FLEUR.size()])

func _poser_les_rochers() -> void:
	for i in 26:
		var pos := _position_au_hasard(9.0, 36.0)
		if pos == Vector3.INF:
			continue
		var taille := _rng.randf_range(0.4, 1.3)

		var roche := SphereMesh.new()
		roche.radius          = taille
		roche.height          = taille * 1.3
		roche.radial_segments = 6
		roche.rings           = 3
		# Aplatie et tournée : une sphère écrasée lit très bien comme un rocher.
		var mi := _prop(
			roche,
			pos + Vector3(0, taille * 0.25, 0),
			C_PIERRE_2.lerp(C_PIERRE, _rng.randf()),
			_rng.randf_range(0.0, TAU)
		)
		mi.scale = Vector3(1.0, 0.55, _rng.randf_range(0.7, 1.1))

# ──────────────────────────────────────────────────────────────────────────────
# LE PUITS
# ──────────────────────────────────────────────────────────────────────────────
#
# Le puits existe déjà dans zone1.gd (une simple boîte de pierre à 7, 6).
# On lui ajoute la margelle, les deux montants, le petit toit et le seau.

func _habiller_le_puits() -> void:
	var p := Vector3(7.0, 0.0, 6.0)

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
	# La rue principale nord-sud
	if abs(pos.x) < 3.0 + marge:
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
