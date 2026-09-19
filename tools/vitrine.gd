# tools/vitrine.gd
# Banc d'essai : aligne des modèles .glb côte à côte, sous la lumière du jeu,
# avec une silhouette de 1,80 m comme repère d'échelle. Sans lancer le jeu.
#
# Lancer :
#   godot --path . res://tools/vitrine.tscn --resolution 1400x720 -- arbre_chene arbre_pin
#
# Tout ce qui suit le `--` est une liste de noms de modèles (sans .glb). Ils
# sont cherchés dans assets/models/environnement/ puis personnages/.
# Sortie : tools/captures/vitrine.png
#
# ⚠ Après avoir regénéré un .glb, il FAUT réimporter avant de capturer :
#     godot --headless --path . --import
#   sinon Godot ressert la version en cache et la capture ne bouge pas.
extends Node3D

const SORTIE := "res://tools/captures/"
const DOSSIERS := [
	"res://assets/models/environnement/",
	"res://assets/models/personnages/",
]

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SORTIE)
	_decor()

	var noms := OS.get_cmdline_user_args()
	if noms.is_empty():
		noms = ["arbre_chene"]

	# On aligne les modèles sur l'axe X, chacun espacé selon sa propre largeur.
	var x := 0.0
	var hauteur_max := 2.0
	for nom in noms:
		var noeud := _charger(nom)
		if noeud == null:
			continue
		add_child(noeud)
		var boite := _emprise(noeud)
		var largeur: float = max(boite.size.x, 2.5)
		x += largeur * 0.5 + 1.0
		noeud.position = Vector3(x, 0, 0)
		x += largeur * 0.5
		hauteur_max = max(hauteur_max, boite.size.y)
		print("  %s : %.1f m de haut, %.1f m de large" % [nom, boite.size.y, boite.size.x])

	_reglet(Vector3(-1.5, 0, 0))

	# La caméra recule juste ce qu'il faut pour tout voir.
	# Attention : `fov` est le champ VERTICAL. Le champ horizontal s'en déduit
	# par le rapport d'aspect de la fenêtre — sans ça on recule beaucoup trop
	# et les modèles finissent minuscules au milieu de l'image.
	var cam := Camera3D.new()
	cam.current = true
	add_child(cam)

	var taille_ecran := get_viewport().get_visible_rect().size
	var aspect := taille_ecran.x / taille_ecran.y
	var demi_v := deg_to_rad(cam.fov) * 0.5
	var demi_h := atan(tan(demi_v) * aspect)

	var centre := Vector3(x * 0.5, hauteur_max * 0.45, 0)
	var recul: float = max(
		(x * 0.5) / tan(demi_h),
		(hauteur_max * 0.6) / tan(demi_v)
	) * 1.15
	cam.position = centre + Vector3(0, hauteur_max * 0.18, recul)
	cam.look_at(centre, Vector3.UP)

	for i in 10:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SORTIE + "vitrine.png")
	print("capture: vitrine.png")
	get_tree().quit()

func _charger(nom: String) -> Node3D:
	for dossier in DOSSIERS:
		var chemin: String = str(dossier) + nom + ".glb"
		if ResourceLoader.exists(chemin):
			var scene: PackedScene = load(chemin)
			if scene != null:
				return scene.instantiate()
	push_error("Modèle introuvable : " + nom)
	return null

# Fait le tour des MeshInstance3D d'un modèle pour connaître son encombrement.
func _emprise(noeud: Node) -> AABB:
	var total := AABB()
	var premier := true
	for enfant in _tous_les_noeuds(noeud):
		if enfant is MeshInstance3D and enfant.mesh != null:
			var b: AABB = enfant.mesh.get_aabb()
			if premier:
				total = b
				premier = false
			else:
				total = total.merge(b)
	return total

func _tous_les_noeuds(racine: Node) -> Array:
	var liste := [racine]
	for enfant in racine.get_children():
		liste.append_array(_tous_les_noeuds(enfant))
	return liste

func _decor() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var ciel := Sky.new()
	ciel.sky_material = ProceduralSkyMaterial.new()
	e.sky = ciel
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.85
	env.environment = e
	add_child(env)

	var soleil := DirectionalLight3D.new()
	soleil.transform = Transform3D(
		Basis(Vector3(0.3, 1.0, 0.4).normalized(), deg_to_rad(35.0)) *
		Basis(Vector3(1, 0, 0), deg_to_rad(-55.0)),
		Vector3(0, 10, 0)
	)
	soleil.light_color = Color(1, 0.952941, 0.8)
	soleil.light_energy = 1.2
	soleil.shadow_enabled = true
	soleil.shadow_normal_bias = 3.0
	soleil.directional_shadow_max_distance = 180.0
	add_child(soleil)

	var sol := MeshInstance3D.new()
	var plan := BoxMesh.new()
	plan.size = Vector3(400, 0.2, 400)
	sol.mesh = plan
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.48, 0.28)
	mat.roughness = 0.9
	sol.material_override = mat
	sol.position = Vector3(0, -0.1, 0)
	add_child(sol)

# Un bonhomme de 1,80 m : sans repère d'échelle, impossible de juger un modèle.
func _reglet(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var corps := CapsuleMesh.new()
	corps.radius = 0.3
	corps.height = 1.8
	mi.mesh = corps
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.25, 0.35)
	mi.material_override = mat
	mi.position = pos + Vector3(0, 0.9, 0)
	add_child(mi)
