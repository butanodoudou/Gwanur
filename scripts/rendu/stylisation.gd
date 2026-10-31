# scripts/rendu/stylisation.gd
# Convertit TOUT le décor au rendu « Breath of the Wild » (cel-shading doux).
#
# LE PROBLÈME
# Les modèles .glb et les boîtes construites en code arrivent avec des
# StandardMaterial3D : l'éclairage réaliste par défaut de Godot. Sur des
# formes simples, ça donne l'aspect « pâte à modeler » (chaque facette a sa
# propre nuance de gris, les ombres sont noires et sales).
#
# LA SOLUTION
# Plutôt que de retoucher chaque modèle à la main, ce script parcourt l'arbre
# de scène et remplace chaque StandardMaterial3D par un ShaderMaterial « toon »
# (shaders/toon*.gdshader) qui reprend sa couleur, sa texture, sa transparence
# et son émission. Un nouveau modèle ajouté au décor est donc stylisé tout seul.
#
# UTILISATION (fonctions STATIQUES : pas besoin de créer d'objet) :
#     const Stylisation = preload("res://scripts/rendu/stylisation.gd")
#     Stylisation.styliser(un_noeud)          # convertit ce noeud et ses enfants
#     Stylisation.suivre(get_tree())          # + tout ce qui apparaîtra ensuite
#
# CE QUI N'EST PAS TOUCHÉ
#   - les ShaderMaterial (l'eau, l'écho de la liane, l'herbe) : déjà stylisés ;
#   - les matériaux « unshaded » (ils ne reçoivent pas de lumière de toute façon) ;
#   - Label3D, Sprite3D, particules.
#
# LE CACHE
# Un matériau d'origine = UN ShaderMaterial toon, partagé par tous les objets
# qui l'utilisaient. Les sept maisons partagent ainsi les mêmes six matériaux,
# comme avant la conversion : pas de matériau en plus à dessiner. La recoloration
# des PNJ (pnj.gd) fabrique une COPIE du matériau `tunique_pnj` par villageois :
# chaque copie est un matériau d'origine différent, chacun garde donc sa couleur.
#
# LE SOL ET LA TERRE BATTUE
# Les plaques de terre battue de DecorVillage (reconnues à leur couleur,
# DecorVillage.C_SOL_USE) reçoivent shaders/terre.gdshader : bord rongé qui
# s'effiloche dans l'herbe. La grande dalle posée par zone1.gd (_sol) est reconnue à sa taille (plus de
# 100 m de côté) et reçoit shaders/sol.gdshader, dont la teinte varie comme
# celle de l'herbe (shaders/prairie.gdshaderinc).

extends RefCounted

# Mettre à false pour comparer avec le rendu Godot par défaut. On peut aussi
# lancer le jeu avec `-- --sans-toon` sans rien modifier.
const ACTIVE := true

const SHADER_TOON        := preload("res://shaders/toon.gdshader")
const SHADER_DOUBLE      := preload("res://shaders/toon_double.gdshader")
const SHADER_FEUILLAGE   := preload("res://shaders/toon_feuillage.gdshader")
const SHADER_FEUILLES    := preload("res://shaders/toon_feuillage_scissor.gdshader")
const SHADER_TRANSPARENT := preload("res://shaders/toon_transparent.gdshader")
const SHADER_SOL         := preload("res://shaders/sol.gdshader")
const SHADER_TERRE       := preload("res://shaders/terre.gdshader")

# Un matériau dont le nom contient l'un de ces mots est du feuillage.
const MOTS_FEUILLAGE := ["feuill", "leaf", "leaves", "foliage", "aiguille", "needle", "canopy"]

# Au-delà de cette taille (m), un feuillage n'est plus « une boule » : la
# canopée de l'Aelith fait 110 m de large, des normales sphériques centrées
# sur elle n'auraient aucun sens.
const TAILLE_MAX_VOLUME := 16.0

# Matériau d'origine (ou clé texte pour le feuillage) → ShaderMaterial toon.
static var _cache: Dictionary = {}
static var _suivi_branche: bool = false

static func est_active() -> bool:
	return ACTIVE and not OS.get_cmdline_user_args().has("--sans-toon")

# ──────────────────────────────────────────────────────────────────────────────
# POINTS D'ENTRÉE
# ──────────────────────────────────────────────────────────────────────────────

# Convertit `racine` et tout ce qu'il y a dessous.
static func styliser(racine: Node) -> void:
	if not est_active() or racine == null:
		return
	var a_voir: Array[Node] = [racine]
	while not a_voir.is_empty():
		var noeud: Node = a_voir.pop_back()
		a_voir.append_array(noeud.get_children())
		if noeud is MeshInstance3D:
			_convertir_mesh_instance(noeud as MeshInstance3D)
		elif noeud is MultiMeshInstance3D:
			_convertir_multimesh(noeud as MultiMeshInstance3D)

# Stylise aussi tout objet 3D ajouté PLUS TARD à l'arbre (un prop qui
# apparaît pendant un puzzle, le grimoire…). Le travail est différé à la fin
# de l'image : le code qui crée l'objet a le temps de lui donner ses
# matériaux avant qu'on les convertisse.
static func suivre(arbre: SceneTree) -> void:
	if not est_active() or _suivi_branche:
		return
	_suivi_branche = true
	arbre.node_added.connect(_sur_noeud_ajoute)

static func _sur_noeud_ajoute(noeud: Node) -> void:
	if noeud is MeshInstance3D or noeud is MultiMeshInstance3D:
		_styliser_si_present.call_deferred(noeud)

static func _styliser_si_present(noeud: Node) -> void:
	if is_instance_valid(noeud) and noeud.is_inside_tree():
		styliser(noeud)

# ──────────────────────────────────────────────────────────────────────────────
# PARCOURS DES MAILLAGES
# ──────────────────────────────────────────────────────────────────────────────

static func _convertir_mesh_instance(mi: MeshInstance3D) -> void:
	var mesh := mi.mesh
	if mesh == null:
		return

	# Le sol de la zone : une boîte géante et plate.
	if mesh is BoxMesh:
		var taille := (mesh as BoxMesh).size
		if taille.x >= 100.0 and taille.z >= 100.0 and taille.y < 1.0:
			if not mi.material_override is ShaderMaterial:
				mi.material_override = _materiau_sol()
			return

	# La terre battue du village : bord rongé (shaders/terre.gdshader).
	if mesh is BoxMesh and mi.material_override is BaseMaterial3D 			and (mi.material_override as BaseMaterial3D).albedo_color == DecorVillage.C_SOL_USE:
		mi.material_override = _materiau_terre(mi.material_override as BaseMaterial3D)
		mi.set_instance_shader_parameter("demi_taille", (mesh as BoxMesh).size * 0.5)
		return

	# 1. material_override remplace TOUTES les surfaces.
	if mi.material_override is BaseMaterial3D:
		var feuillage := _bornes_si_feuillage(mi.material_override, mesh, -1)
		var conv := _convertir(mi.material_override as BaseMaterial3D, feuillage)
		if conv != null:
			mi.material_override = conv
		return
	if mi.material_override != null:
		return  # déjà un ShaderMaterial

	# 2. Surface par surface : d'abord la surcharge de CETTE instance (c'est là
	#    que pnj.gd met la tunique recolorée), sinon le matériau du maillage.
	#    On écrit toujours dans la surcharge de l'instance : le maillage, qui
	#    peut être partagé par d'autres noeuds, n'est pas modifié.
	for i in mesh.get_surface_count():
		var mat := mi.get_surface_override_material(i)
		if mat == null:
			mat = mesh.surface_get_material(i)
		if not mat is BaseMaterial3D:
			continue
		var conv := _convertir(mat as BaseMaterial3D, _bornes_si_feuillage(mat, mesh, i))
		if conv != null:
			mi.set_surface_override_material(i, conv)

# Un MultiMesh n'a pas de surcharge par surface : on modifie le maillage
# lui-même (il n'est partagé qu'entre les instances de la même essence).
static func _convertir_multimesh(mmi: MultiMeshInstance3D) -> void:
	if mmi.material_override is BaseMaterial3D:
		var conv := _convertir(mmi.material_override as BaseMaterial3D, {})
		if conv != null:
			mmi.material_override = conv
		return
	if mmi.material_override != null or mmi.multimesh == null:
		return
	var mesh := mmi.multimesh.mesh
	if mesh == null:
		return
	if mesh is PrimitiveMesh:
		var prim := mesh as PrimitiveMesh
		if prim.material is BaseMaterial3D:
			var conv := _convertir(prim.material as BaseMaterial3D, _bornes_si_feuillage(prim.material, mesh, 0))
			if conv != null:
				prim.material = conv
		return
	if not mesh is ArrayMesh:
		return
	var am := mesh as ArrayMesh
	for i in am.get_surface_count():
		var mat := am.surface_get_material(i)
		if not mat is BaseMaterial3D:
			continue
		var conv := _convertir(mat as BaseMaterial3D, _bornes_si_feuillage(mat, am, i))
		if conv != null:
			am.surface_set_material(i, conv)

# ──────────────────────────────────────────────────────────────────────────────
# LE FEUILLAGE
# ──────────────────────────────────────────────────────────────────────────────

static func est_feuillage(mat: Material) -> bool:
	var nom := mat.resource_name.to_lower()
	for mot in MOTS_FEUILLAGE:
		if nom.contains(mot):
			return true
	# Une carte de feuilles importée (texture découpée par l'alpha) sans nom
	# parlant, comme le saule du centre : c'est presque toujours du feuillage.
	if mat is BaseMaterial3D:
		var b := mat as BaseMaterial3D
		if b.albedo_texture != null and b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			return true
	return false

# Pour un feuillage : { "centre", "etendue", "spherique" } calculés sur les
# sommets de la surface (`surface` = -1 : tout le maillage). {} sinon.
static func _bornes_si_feuillage(mat: Material, mesh: Mesh, surface: int) -> Dictionary:
	if not est_feuillage(mat):
		return {}
	var boite := mesh.get_aabb()
	if surface >= 0 and mesh is ArrayMesh:
		var tableaux := (mesh as ArrayMesh).surface_get_arrays(surface)
		var sommets: PackedVector3Array = tableaux[Mesh.ARRAY_VERTEX]
		if sommets.size() > 0:
			boite = AABB(sommets[0], Vector3.ZERO)
			for s in sommets:
				boite = boite.expand(s)
	var etendue := boite.size * 0.5
	var spherique := 0.0
	if boite.size.length() < TAILLE_MAX_VOLUME:
		# Les normales tirées vers l'ellipsoïde englobant : la boule à
		# facettes s'éclaire comme un seul volume doux.
		spherique = 0.9
	return {
		"centre": boite.get_center(),
		"etendue": etendue,
		"spherique": spherique,
		# (un .glb peut être encore en Z haut dans son maillage, cf. decor_village)
		"hauteur": maxf(maxf(boite.end.y, boite.end.z), 2.0),
	}

# ──────────────────────────────────────────────────────────────────────────────
# LA CONVERSION
# ──────────────────────────────────────────────────────────────────────────────

# Renvoie le ShaderMaterial toon équivalent à `mat`, ou null s'il ne faut pas
# y toucher.
static func _convertir(mat: BaseMaterial3D, feuillage: Dictionary) -> ShaderMaterial:
	if mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		return null

	var cle: Variant = mat
	if not feuillage.is_empty():
		cle = "%d|%s|%s" % [mat.get_instance_id(), feuillage["centre"], feuillage["etendue"]]
	if _cache.has(cle):
		return _cache[cle]

	var transparent := mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
	var decoupe := mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR \
		or mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
	var shader: Shader
	if not feuillage.is_empty():
		# Les feuilles transparentes deviennent découpées (alpha scissor) :
		# pas de tri, pas de scintillement, et c'est l'aspect net de BotW.
		shader = SHADER_FEUILLES if transparent else SHADER_FEUILLAGE
	elif decoupe:
		shader = SHADER_FEUILLES
	elif transparent:
		shader = SHADER_TRANSPARENT
	elif mat.cull_mode == BaseMaterial3D.CULL_BACK:
		shader = SHADER_TOON
	else:
		shader = SHADER_DOUBLE

	var sm := ShaderMaterial.new()
	sm.shader = shader
	sm.resource_name = mat.resource_name + "_toon"
	sm.render_priority = mat.render_priority

	sm.set_shader_parameter("albedo", mat.albedo_color)
	if mat.albedo_texture != null:
		sm.set_shader_parameter("texture_albedo", mat.albedo_texture)
		sm.set_shader_parameter("utiliser_texture", true)
	sm.set_shader_parameter("utiliser_couleur_sommet", mat.vertex_color_use_as_albedo)
	sm.set_shader_parameter("uv1_echelle", mat.uv1_scale)
	sm.set_shader_parameter("uv1_decalage", mat.uv1_offset)
	sm.set_shader_parameter("seuil_alpha", mat.alpha_scissor_threshold)

	if mat.emission_enabled:
		sm.set_shader_parameter("emission", mat.emission)
		sm.set_shader_parameter("energie_emission", mat.emission_energy_multiplier)
		if mat.emission_texture != null:
			sm.set_shader_parameter("texture_emission", mat.emission_texture)
			sm.set_shader_parameter("utiliser_texture_emission", true)

	if not feuillage.is_empty():
		sm.set_shader_parameter("centre_feuillage", feuillage["centre"])
		sm.set_shader_parameter("etendue_feuillage", feuillage["etendue"])
		sm.set_shader_parameter("force_normales_spheriques", feuillage["spherique"])
		sm.set_shader_parameter("hauteur_vent", feuillage["hauteur"])
		# Les textures de feuilles importées sont souvent très saturées.
		if mat.albedo_texture != null:
			sm.set_shader_parameter("saturation", 0.7)

	_cache[cle] = sm
	return sm

static func _materiau_terre(mat: BaseMaterial3D) -> ShaderMaterial:
	if _cache.has(mat):
		return _cache[mat]
	var sm := ShaderMaterial.new()
	sm.shader = SHADER_TERRE
	sm.resource_name = "terre_battue_toon"
	sm.set_shader_parameter("albedo", mat.albedo_color)
	_cache[mat] = sm
	return sm

static func _materiau_sol() -> ShaderMaterial:
	if _cache.has("sol"):
		return _cache["sol"]
	var sm := ShaderMaterial.new()
	sm.shader = SHADER_SOL
	sm.resource_name = "sol_toon"
	_cache["sol"] = sm
	return sm
