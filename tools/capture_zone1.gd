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
	# Vues à hauteur de joueur (la caméra du jeu est à ~9 m derrière le héros)
	{ "nom": "vaenmor", "pos": Vector3(8, 3.2, 11),  "cible": Vector3(3, 1.2, 2.5) },
	{ "nom": "porte",   "pos": Vector3(3, 4, -20),   "cible": Vector3(0, 2, -36) },
	{ "nom": "roue",    "pos": Vector3(-12, 4, -22), "cible": Vector3(-20, 1, -32) },
	{ "nom": "foule",   "pos": Vector3(11, 2.6, 13),  "cible": Vector3(16, 1, 20) },
	{ "nom": "villageoises", "pos": Vector3(-6, 3, 17), "cible": Vector3(-10, 1, 10) },
	{ "nom": "pnj_proche", "pos": Vector3(6.5, 1.9, 7.5), "cible": Vector3(4, 1.0, 3.5) },
	# Kael et Mira dans l'herbe, cadrés comme par la caméra du jeu (~9 m derrière)
	{ "nom": "heros", "pos": Vector3(1.5, 4.5, 38), "cible": Vector3(0, 1.2, 28) },
	{ "nom": "heros_proche", "pos": Vector3(2.6, 1.7, 31.5), "cible": Vector3(0, 1.0, 28) },
	# La prairie en grand, vue d'à peine plus haut qu'un héros
	{ "nom": "prairie", "pos": Vector3(0, 3.2, 40), "cible": Vector3(-10, 1.0, 22) },
	{ "nom": "prairie_haut", "pos": Vector3(0, 22, 46), "cible": Vector3(0, 0, 14) },
]

# Où poser les héros pour les vues « heros » (sur le chemin de l'entrée sud,
# entre deux prairies), tournés vers la caméra.
const HEROS := {
	"kael": [Vector3(-0.8, 0, 28), 0.35],
	"mira": [Vector3(0.7, 0, 28.4), -0.25],
}

func _ready() -> void:
	# La lumière et le ciel sont ceux du JEU : on les emprunte à main.tscn.
	# (Avant, l'outil avait sa propre copie de l'Environment — elle dérivait,
	# et on jugeait une ambiance qui n'était pas celle du jeu.)
	# instantiate() ne lance aucun _ready() : rien du jeu ne démarre ici.
	var principale: Node = load("res://scenes/main.tscn").instantiate()
	for chemin in ["Monde/Environnement", "Monde/LumiereDirectionnelle"]:
		var noeud: Node = principale.get_node(chemin)
		noeud.get_parent().remove_child(noeud)
		noeud.owner = null
		add_child(noeud)
	principale.free()

	var zone: Node3D = load("res://scenes/zones/zone1.tscn").instantiate()
	add_child(zone)
	# Comme main.gd : les rayons de soleil du Trou de Ciel.
	preload("res://scripts/rendu/rayons_oculus.gd").poser(zone, $LumiereDirectionnelle)

	# Les héros, immobiles (PROCESS_MODE_DISABLED : ni gravité ni commandes),
	# stylisés comme le fait main.gd en jeu.
	for nom in HEROS:
		var heros: Node3D = load("res://scenes/characters/" + nom + ".tscn").instantiate()
		heros.process_mode = Node.PROCESS_MODE_DISABLED
		heros.position = HEROS[nom][0]
		heros.rotation.y = HEROS[nom][1]
		add_child(heros)
		preload("res://scripts/rendu/stylisation.gd").styliser(heros)

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
