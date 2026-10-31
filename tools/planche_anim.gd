# tools/planche_anim.gd
# Planche d'animation : fige un personnage à plusieurs instants de ses
# animations et les photographie côte à côte. Sert à juger un cycle de marche
# sans lancer le jeu (on lit les PNG : jambes qui alternent, genou qui plie,
# bras opposés, pieds posés au sol).
#
# Lancer :
#   godot --path . res://tools/planche_anim.tscn --resolution 1600x500 -- kael mira
#
# Tout ce qui suit le `--` est une liste de personnages (kael, mira, pnj_ancien…).
# Sortie, pour chaque personnage, dans tools/captures/ :
#   planche_<perso>_marche.png   6 poses du cycle de marche, de profil
#   planche_<perso>_course.png   6 poses du cycle de course, de profil
#   planche_<perso>_idle.png     4 instants de l'idle, de trois quarts
#   planche_<perso>_gestes.png   interagir et les skills, au sommet du geste
#
# ⚠ Après avoir regénéré un .glb : godot --headless --path . --import
extends Node3D

const SORTIE := "res://tools/captures/"
const DOSSIER := "res://assets/models/personnages/"
const ECART := 1.15   # distance entre deux poses, en mètres

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SORTIE)
	_decor()
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.current = true
	add_child(cam)

	var noms := OS.get_cmdline_user_args()
	if noms.is_empty():
		noms = ["kael"]
	for nom in noms:
		var scene: PackedScene = load(DOSSIER + nom + ".glb")
		if scene == null:
			push_error("Modèle introuvable : " + nom)
			continue
		var planches := {
			# nom de la planche : [animation, instants (en fraction de la durée), vue]
			"marche": [["marche", [0.0, 1.0 / 6, 2.0 / 6, 3.0 / 6, 4.0 / 6, 5.0 / 6]], "profil"],
			"course": [["course", [0.0, 1.0 / 6, 2.0 / 6, 3.0 / 6, 4.0 / 6, 5.0 / 6]], "profil"],
			"idle": [["idle", [0.0, 0.25, 0.5, 0.75]], "trois_quarts"],
		}
		for nom_planche in planches:
			var reglage: Array = planches[nom_planche]
			var poses := []
			for f in reglage[0][1]:
				poses.append([reglage[0][0], f])
			await _photographier(scene, poses, reglage[1], cam, "planche_%s_%s.png" % [nom, nom_planche])
		# Les gestes : au sommet (≈ 40 % de la durée), plus une pose de repos.
		var gestes := [["idle", 0.0]]
		for g in ["interagir", "skill1", "skill2"]:
			gestes.append([g, 0.4])
		await _photographier(scene, gestes, "trois_quarts", cam, "planche_%s_gestes.png" % nom)
	get_tree().quit()

# Pose une instance du modèle par pose demandée, les fige, prend la photo,
# puis les retire.
func _photographier(scene: PackedScene, poses: Array, vue: String, cam: Camera3D, fichier: String) -> void:
	var instances: Array[Node3D] = []
	for i in poses.size():
		var anim: String = poses[i][0]
		var fraction: float = poses[i][1]
		var modele: Node3D = scene.instantiate()
		add_child(modele)
		modele.position = Vector3(i * ECART, 0, 0)
		# Profil : il regarde +X (vers la droite de l'image).
		# Trois quarts : il regarde entre la caméra et la droite.
		modele.rotation.y = PI * 0.5 if vue == "profil" else PI * 0.2
		var lecteur := modele.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if lecteur != null and lecteur.has_animation(anim):
			lecteur.play(anim)
			lecteur.seek(lecteur.get_animation(anim).length * fraction, true)
			lecteur.pause()
		elif lecteur == null:
			push_warning("Pas d'AnimationPlayer dans le modèle")
		else:
			push_warning("Animation absente : " + anim)
		instances.append(modele)

	var largeur := (poses.size() - 1) * ECART
	cam.size = 2.4   # hauteur visible, en mètres
	cam.position = Vector3(largeur * 0.5, 1.0, 10.0)
	cam.look_at(Vector3(largeur * 0.5, 1.0, 0.0), Vector3.UP)
	get_window().size = Vector2i(int((largeur + 1.4) / 2.4 * 500.0), 500)

	for i in 8:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SORTIE + fichier)
	print("capture: " + fichier)
	for m in instances:
		m.queue_free()
	await get_tree().process_frame

func _decor() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.82, 0.86, 0.9)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.9, 0.9, 0.95)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)

	var soleil := DirectionalLight3D.new()
	soleil.rotation = Vector3(deg_to_rad(-45.0), deg_to_rad(30.0), 0.0)
	soleil.light_color = Color(1, 0.95, 0.8)
	soleil.light_energy = 1.1
	soleil.shadow_enabled = true
	add_child(soleil)

	# Un sol vert, pour voir où les pieds se posent.
	var sol := MeshInstance3D.new()
	var plan := BoxMesh.new()
	plan.size = Vector3(60, 0.02, 4)
	sol.mesh = plan
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.5, 0.32)
	sol.material_override = mat
	sol.position = Vector3(10, -0.01, 0)
	add_child(sol)
