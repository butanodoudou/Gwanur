# tools/capture_zone1.gd
# Outil de dev : photographie la Zone 1 sous plusieurs angles, sans lancer le
# jeu ni bouger un personnage. Pratique pour juger le décor d'un coup d'oeil.
#
# Lancer :
#   godot --path . res://tools/capture_zone1.tscn --resolution 1280x720
#
# Les images arrivent dans tools/captures/ (dossier ignoré par git).
# Pour ajouter un point de vue, ajoute une ligne dans VUES : "pos" est la
# position de la caméra, "cible" le point qu'elle regarde.
extends Node3D

const SORTIE := "res://tools/captures/"

const VUES := [
	{ "nom": "aerien",  "pos": Vector3(0, 120, 130),  "cible": Vector3(0, 20, -10) },
	{ "nom": "cavite",  "pos": Vector3(0, 22, 40),    "cible": Vector3(0, 30, -30) },
	{ "nom": "rempart", "pos": Vector3(6, 4, 14),     "cible": Vector3(-20, 30, -40) },
	{ "nom": "sud",    "pos": Vector3(0, 14, 46),    "cible": Vector3(0, 3, 0) },
	{ "nom": "place",  "pos": Vector3(4, 5, 22),     "cible": Vector3(2, 2, 4) },
	{ "nom": "dessus", "pos": Vector3(0, 55, 30),    "cible": Vector3(0, 0, -10) },
	{ "nom": "nord",   "pos": Vector3(0, 9, -12),    "cible": Vector3(0, 2, -38) },
	{ "nom": "oiseau", "pos": Vector3(14, 9.5, 4),   "cible": Vector3(22, 7.3, -4) },
	{ "nom": "moulin", "pos": Vector3(-10, 8, -4),   "cible": Vector3(-22, 3, -12) },
	{ "nom": "ruine",  "pos": Vector3(18, 7, -32),   "cible": Vector3(6, 1, -42) },
	{ "nom": "ruisseau", "pos": Vector3(-8, 8, -18), "cible": Vector3(-22, 1, -32) },
]

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var ciel := Sky.new()
	ciel.sky_material = ProceduralSkyMaterial.new()
	e.sky = ciel
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.85
	e.fog_enabled = true
	e.fog_light_color = Color(0.807843, 0.85098, 0.878431)
	e.fog_density = 0.0008
	e.fog_sky_affect = 0.2
	env.environment = e
	add_child(env)

	var soleil := DirectionalLight3D.new()
	soleil.transform = Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(-68.0)), Vector3(0, 10, 0))
	soleil.light_color = Color(1, 0.952941, 0.8)
	soleil.light_energy = 1.2
	soleil.shadow_enabled = true
	soleil.shadow_normal_bias = 3.0
	soleil.directional_shadow_max_distance = 180.0
	add_child(soleil)

	add_child(load("res://scenes/zones/zone1.tscn").instantiate())

	DirAccess.make_dir_recursive_absolute(SORTIE)

	var cam := Camera3D.new()
	cam.current = true
	add_child(cam)

	for vue in VUES:
		cam.position = vue["pos"]
		cam.look_at(vue["cible"], Vector3.UP)
		for i in 5:
			await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(SORTIE + "zone1_" + str(vue["nom"]) + ".png")
		print("capture: ", vue["nom"])

	get_tree().quit()
