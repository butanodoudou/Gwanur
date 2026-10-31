# scripts/zones/herbe.gd
# L'herbe de la prairie, façon Breath of the Wild : des dizaines de milliers
# de touffes qui ondulent au vent, s'écartent sous les pieds des héros et se
# fondent dans le sol au loin.
#
# UTILISATION (une seule ligne, à la FIN de DecorVillage.construire()) :
#     preload("res://scripts/zones/herbe.gd").semer(self, _maisons)
# À la fin, parce que l'herbe doit éviter la terre battue et les dalles des
# chemins posées par le décor : elle les lit dans l'arbre de scène.
#
# COMMENT ÇA MARCHE
# 1. Un MASQUE : une grille de cases de 50 cm sur toute la cavité, qui dit
#    pour chaque case « combien d'herbe ici » (0 = aucune, 1 = pleine). On y
#    creuse les chemins, la terre battue, les maisons, le ruisseau et les
#    repères des puzzles — avec un bord adouci : l'herbe s'éclaircit et
#    rapetisse en approchant d'un chemin, au lieu de s'arrêter net.
# 2. UNE TOUFFE : un petit maillage de 9 brins, construit ici en code.
# 3. DES PARCELLES : la cavité est découpée en carrés de 8 m. Chaque parcelle
#    est un MultiMeshInstance3D qui dessine toutes ses touffes en UN ordre de
#    dessin. Pourquoi pas un seul MultiMesh pour tout ? Parce que Godot ne
#    peut écarter (« culling ») qu'un noeud entier : avec des parcelles, celles
#    qui sont derrière la caméra ou trop loin ne sont pas dessinées du tout.
#    C'est ce qui tient le budget en écran splitté (DEUX rendus par image).
#
# Le shader (vent, couleurs, disparition au loin) est shaders/herbe.gdshader.

extends Node3D

const SHADER_HERBE := preload("res://shaders/herbe.gdshader")

# ── Réglages ──────────────────────────────────────────────────────────────────
const ACTIVE := true
const DENSITE := 9.0           # touffes par m² là où le masque vaut 1
const BRINS_PAR_TOUFFE := 9
const TAILLE_PARCELLE := 8.0   # côté d'une parcelle, en mètres
const CASE := 0.5              # résolution du masque, en mètres
const BORD := 1.2              # largeur du bord adouci autour des exclusions
# L'herbe disparaît entre ces deux distances (doit suivre herbe.gdshader).
const FONDU_DEBUT := 26.0
const FONDU_FIN := 38.0

# La cavité de l'Aelith (mêmes valeurs que zone1.gd / decor_village.gd).
const CENTRE := Vector3(0, 0, -10)
const RAYON := 54.0

const GRAINE := 777

var _rng := RandomNumberGenerator.new()
var _bruit := FastNoiseLite.new()
var _materiau: ShaderMaterial

# Le masque : une case = un float, rangé ligne par ligne.
var _masque := PackedFloat32Array()
var _cases := 0              # nombre de cases par côté
var _origine := Vector2.ZERO # coin (x min, z min) de la grille

# Nombre total de touffes posées (lu par les outils de mesure).
var nombre_touffes := 0

# ──────────────────────────────────────────────────────────────────────────────
# POINT D'ENTRÉE
# ──────────────────────────────────────────────────────────────────────────────

# Crée l'herbe sous `decor` (le noeud DecorVillage) et la renvoie.
static func semer(decor: Node3D, maisons: Array) -> Node3D:
	var herbe = load("res://scripts/zones/herbe.gd").new()
	herbe.name = "Herbe"
	decor.add_child(herbe)
	if ACTIVE:
		herbe._construire(decor, maisons)
	return herbe

func _construire(decor: Node3D, maisons: Array) -> void:
	_rng.seed = GRAINE
	_bruit.seed = GRAINE
	_bruit.frequency = 0.045

	_materiau = ShaderMaterial.new()
	_materiau.shader = SHADER_HERBE
	_materiau.set_shader_parameter("fondu_debut", FONDU_DEBUT)
	_materiau.set_shader_parameter("fondu_fin", FONDU_FIN)

	_preparer_le_masque()
	_creuser_le_decor(decor)
	_creuser_les_maisons(maisons)
	_creuser_la_zone(decor.get_parent())
	_planter(_construire_touffe())

# ──────────────────────────────────────────────────────────────────────────────
# LE MASQUE
# ──────────────────────────────────────────────────────────────────────────────

func _preparer_le_masque() -> void:
	_cases = int(ceil(RAYON * 2.0 / CASE))
	_origine = Vector2(CENTRE.x - RAYON, CENTRE.z - RAYON)
	_masque.resize(_cases * _cases)
	for j in _cases:
		for i in _cases:
			var p := _centre_case(i, j)
			var d := p.distance_to(Vector2(CENTRE.x, CENTRE.z))
			# l'herbe s'éclaircit au pied du rempart (ombre, racines)
			_masque[j * _cases + i] = 1.0 - smoothstep(RAYON - 4.0, RAYON, d)

func _centre_case(i: int, j: int) -> Vector2:
	return _origine + Vector2((float(i) + 0.5) * CASE, (float(j) + 0.5) * CASE)

func _valeur(p: Vector2) -> float:
	var i := int((p.x - _origine.x) / CASE)
	var j := int((p.y - _origine.y) / CASE)
	if i < 0 or j < 0 or i >= _cases or j >= _cases:
		return 0.0
	return _masque[j * _cases + i]

# Retire l'herbe d'un rectangle tourné (centre, demi-tailles, angle autour
# de Y), avec un bord adouci de `bord` mètres.
func _creuser_rectangle(centre: Vector2, demi: Vector2, angle: float, bord: float) -> void:
	var rayon_englobant := demi.length() + bord
	var cos_a := cos(angle)
	var sin_a := sin(angle)
	for j in _plage(centre.y, rayon_englobant, _origine.y):
		for i in _plage(centre.x, rayon_englobant, _origine.x):
			var p := _centre_case(i, j) - centre
			# On ramène le point dans le repère du rectangle (rotation inverse).
			# Godot tourne autour de Y : x' = x cos + z sin, z' = -x sin + z cos.
			var local := Vector2(p.x * cos_a - p.y * sin_a, p.x * sin_a + p.y * cos_a)
			var dehors := Vector2(maxf(absf(local.x) - demi.x, 0.0), maxf(absf(local.y) - demi.y, 0.0))
			_abaisser(i, j, smoothstep(0.0, bord, dehors.length()))

func _creuser_disque(centre: Vector2, rayon: float, bord: float) -> void:
	for j in _plage(centre.y, rayon + bord, _origine.y):
		for i in _plage(centre.x, rayon + bord, _origine.x):
			var d := _centre_case(i, j).distance_to(centre)
			_abaisser(i, j, smoothstep(rayon, rayon + bord, d))

# Les indices de cases couverts par [centre - r, centre + r] sur un axe.
func _plage(centre: float, r: float, origine: float) -> Array:
	var debut := clampi(int((centre - r - origine) / CASE), 0, _cases - 1)
	var fin := clampi(int((centre + r - origine) / CASE) + 1, 0, _cases)
	return range(debut, fin)

func _abaisser(i: int, j: int, valeur: float) -> void:
	var k := j * _cases + i
	_masque[k] = minf(_masque[k], valeur)

# Les dalles des chemins, la terre battue et le potager : ce sont les boîtes
# plates posées au ras du sol par DecorVillage. On les retrouve dans l'arbre
# de scène plutôt que de recopier leurs positions : si le décor change,
# l'herbe suit toute seule.
func _creuser_le_decor(decor: Node3D) -> void:
	for noeud in decor.get_children():
		if not noeud is MeshInstance3D:
			continue
		var mi := noeud as MeshInstance3D
		if not mi.mesh is BoxMesh:
			continue
		var taille: Vector3 = (mi.mesh as BoxMesh).size
		if taille.y > 0.15 or mi.position.y > 0.12:
			continue
		var demi := Vector2(taille.x, taille.z) * 0.5 * Vector2(mi.scale.x, mi.scale.z)
		# La terre battue a un bord rongé (shaders/terre.gdshader) qui recule
		# jusqu'à ~1,5 m à l'intérieur de la plaque : l'herbe l'y rejoint.
		var mat := mi.material_override as BaseMaterial3D
		if mat != null and mat.albedo_color == DecorVillage.C_SOL_USE:
			demi = (demi - Vector2(1.1, 1.1)).max(Vector2(0.3, 0.3))
		_creuser_rectangle(Vector2(mi.position.x, mi.position.z), demi, mi.rotation.y, BORD)

func _creuser_les_maisons(maisons: Array) -> void:
	for maison in maisons:
		var taille: Vector3 = maison["taille"]
		var pos: Vector3 = maison["pos"]
		_creuser_rectangle(Vector2(pos.x, pos.z), Vector2(taille.x, taille.z) * 0.5 + Vector2(0.2, 0.2),
			float(maison["rot"]), 0.6)

# Ce que zone1.gd pose : le ruisseau, le puits, le tronc du Rejet, la stèle
# et les repères des puzzles (une plaque à moitié cachée par l'herbe, c'est
# un puzzle qu'on ne trouve plus).
func _creuser_la_zone(zone: Node) -> void:
	var c := {}
	if zone != null and zone.get_script() != null:
		c = (zone.get_script() as Script).get_script_constant_map()
	if c.has("RUISSEAU_X_MIN"):
		var x_min: float = c["RUISSEAU_X_MIN"]
		var x_max: float = c["RUISSEAU_X_MAX"]
		var demi_z: float = float(c["RUISSEAU_LARGEUR"]) * 0.5
		_creuser_rectangle(Vector2((x_min + x_max) * 0.5, c["RUISSEAU_Z"]),
			Vector2((x_max - x_min) * 0.5, demi_z + 0.1), 0.0, 0.5)

	_creuser_disque(Vector2(0, 0), 2.4, 0.8)       # tronc du Rejet (le saule)
	_creuser_disque(Vector2(7, 6), 1.3, 0.6)       # le puits
	_creuser_disque(Vector2(0, -44), 1.0, 0.6)     # la stèle

	if zone == null:
		return
	for donnees in [
		["Puzzle2Oiseau/PlateformePoids", 1.7],
		["Puzzle2Oiseau/ZoneVerrou", 0.8],
		["Puzzle3RoueEau/ZoneLanterne", 1.3],
		["Puzzle3RoueEau/Pont", 3.2],
		["Puzzle1PorteDouble/ZoneInteractionKael", 0.8],
		["Puzzle1PorteDouble/ZoneInteractionMira", 0.8],
	]:
		var n := zone.get_node_or_null(donnees[0]) as Node3D
		if n != null:
			var p := (zone as Node3D).to_local(n.global_position) if zone is Node3D else n.position
			_creuser_disque(Vector2(p.x, p.z), donnees[1], 0.7)

# ──────────────────────────────────────────────────────────────────────────────
# LA TOUFFE
# ──────────────────────────────────────────────────────────────────────────────
#
# Un brin = une lame effilée en 3 segments (7 sommets), légèrement courbée.
# UV.y va de 0 (pied) à 1 (pointe) : le shader s'en sert pour le dégradé et
# pour savoir quelle partie du brin le vent doit plier.
# COLOR.r = un hasard propre au brin (nuance, phase du vent).

func _construire_touffe() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var segments := 3
	for b in BRINS_PAR_TOUFFE:
		var angle := rng.randf_range(0.0, TAU)
		var r := sqrt(rng.randf()) * 0.24
		var base := Vector3(cos(angle) * r, 0.0, sin(angle) * r)
		var hauteur := rng.randf_range(0.32, 0.62)
		var largeur := rng.randf_range(0.07, 0.11)
		var orientation := rng.randf_range(0.0, TAU)
		var cote := Vector3(cos(orientation), 0, sin(orientation))
		var avant := Vector3(-cote.z, 0, cote.x)
		var penche := rng.randf_range(0.08, 0.28)
		var hasard := rng.randf()
		var couleur := Color(hasard, 0, 0)

		var depart := b * (segments * 2 + 1)
		for s in segments:
			var t := float(s) / float(segments)
			var centre := base + Vector3(0, t * hauteur, 0) + avant * penche * hauteur * t * t
			var demi := largeur * 0.5 * (1.0 - t * 0.85)
			for k in [-1.0, 1.0]:
				st.set_color(couleur)
				st.set_uv(Vector2(0.5 + k * 0.5, t))
				st.set_normal(Vector3.UP)
				st.add_vertex(centre + cote * demi * k)
		# la pointe
		st.set_color(couleur)
		st.set_uv(Vector2(0.5, 1.0))
		st.set_normal(Vector3.UP)
		st.add_vertex(base + Vector3(0, hauteur, 0) + avant * penche * hauteur)

		for s in segments - 1:
			var a := depart + s * 2
			st.add_index(a);     st.add_index(a + 1); st.add_index(a + 2)
			st.add_index(a + 1); st.add_index(a + 3); st.add_index(a + 2)
		var dernier := depart + (segments - 1) * 2
		st.add_index(dernier); st.add_index(dernier + 1); st.add_index(dernier + 2)
	return st.commit()

# ──────────────────────────────────────────────────────────────────────────────
# LES PARCELLES
# ──────────────────────────────────────────────────────────────────────────────

func _planter(touffe: ArrayMesh) -> void:
	var nb_parcelles := int(ceil(RAYON * 2.0 / TAILLE_PARCELLE))
	var par_parcelle := int(TAILLE_PARCELLE * TAILLE_PARCELLE * DENSITE)
	for pj in nb_parcelles:
		for pi in nb_parcelles:
			var coin := _origine + Vector2(pi, pj) * TAILLE_PARCELLE
			var centre := coin + Vector2.ONE * TAILLE_PARCELLE * 0.5
			# parcelle entièrement hors de la cavité : on passe
			if centre.distance_to(Vector2(CENTRE.x, CENTRE.z)) > RAYON + TAILLE_PARCELLE:
				continue
			var transformations: Array[Transform3D] = []
			for n in par_parcelle:
				var p := coin + Vector2(_rng.randf(), _rng.randf()) * TAILLE_PARCELLE
				var m := _valeur(p)
				if m <= 0.02 or _rng.randf() > m:
					continue
				# De grandes taches d'herbe plus haute, comme les hautes herbes de BotW.
				var haute := smoothstep(-0.1, 0.5, _bruit.get_noise_2d(p.x, p.y))
				var echelle := lerpf(0.55, 1.0, m) * lerpf(0.8, 1.45, haute) * _rng.randf_range(0.8, 1.15)
				var t := Transform3D(Basis(Vector3.UP, _rng.randf_range(0.0, TAU)).scaled(
					Vector3(_rng.randf_range(0.9, 1.2), echelle, _rng.randf_range(0.9, 1.2))),
					Vector3(p.x - centre.x, 0.0, p.y - centre.y))
				transformations.append(t)
			if transformations.is_empty():
				continue
			_creer_parcelle(touffe, centre, transformations)

func _creer_parcelle(touffe: ArrayMesh, centre: Vector2, transformations: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = touffe
	mm.instance_count = transformations.size()
	for i in transformations.size():
		mm.set_instance_transform(i, transformations[i])

	var parcelle := MultiMeshInstance3D.new()
	parcelle.multimesh = mm
	parcelle.material_override = _materiau
	parcelle.position = Vector3(centre.x, 0.0, centre.y)
	# L'herbe reçoit les ombres mais n'en projette pas : des dizaines de
	# milliers de brins dans la carte d'ombre coûteraient plus que tout le reste.
	parcelle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parcelle.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# Le vent déplace les pointes hors de la boîte englobante calculée.
	parcelle.extra_cull_margin = 0.8
	# Au-delà, le shader a déjà fait disparaître l'herbe : inutile de dessiner.
	parcelle.visibility_range_end = FONDU_FIN + TAILLE_PARCELLE * 0.75
	add_child(parcelle)
	nombre_touffes += transformations.size()

# ──────────────────────────────────────────────────────────────────────────────
# LES HÉROS ÉCARTENT L'HERBE
# ──────────────────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if _materiau == null:
		return
	var joueurs := get_tree().get_nodes_in_group("joueurs")
	for i in mini(joueurs.size(), 2):
		var j := joueurs[i] as Node3D
		if j != null:
			_materiau.set_shader_parameter("joueur_" + str(i + 1), j.global_position)
