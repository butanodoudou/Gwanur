# tools/mesure_fps.gd
# Outil de dev : mesure les FPS du VRAI jeu (scenes/main.tscn, écran splitté,
# donc deux rendus 3D par image), sans limite d'images ni synchro verticale.
#
# Lancer (dans une fenêtre, pas en --headless : il faut un vrai rendu) :
#   godot --path . res://tools/mesure_fps.tscn --resolution 1920x1080
#
# Trois prises de 6 secondes chacune, après 2 secondes de chauffe :
#   - « depart »  : les héros à leur point de départ, sur la place ;
#   - « prairie » : au milieu de l'herbe la plus dense, caméras tournées vers
#                   le champ (le pire cas pour l'herbe) ;
#   - « nord »    : face au rempart et à la canopée.
# Pour chacune : FPS moyen, pire image, et temps GPU de CHAQUE vue (mesuré
# par le moteur sur chaque SubViewport — c'est ce chiffre qu'on compare au
# budget de ~8 ms par vue pour tenir 60 fps à deux).
#
# main.tscn est glissé SOUS ce noeud : main.gd ne joue alors pas l'intro
# (voir main.gd, _ready) et l'on mesure directement le jeu.
extends Node

const DUREE_CHAUFFE := 2.0
const DUREE_PRISE := 6.0

const PRISES := [
	{ "nom": "depart",  "kael": Vector3(-1, 1, 5),    "mira": Vector3(1, 1, 5),    "angle": 0.0 },
	{ "nom": "prairie", "kael": Vector3(-30, 1, 12),  "mira": Vector3(34, 1, 2),  "angle": 2.2 },
	{ "nom": "nord",    "kael": Vector3(-3, 1, -18),  "mira": Vector3(3, 1, -18),  "angle": PI },
]

var _vues: Array[SubViewport] = []

func _ready() -> void:
	# Pas de plafond : on veut voir la marge au-dessus de 60.
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	var jeu: Node = load("res://scenes/main.tscn").instantiate()
	add_child(jeu)
	for chemin in ["SplitScreen/Conteneur/VueKael/SubViewport", "SplitScreen/Conteneur/VueMira/SubViewport"]:
		var vue := jeu.get_node(chemin) as SubViewport
		RenderingServer.viewport_set_measure_render_time(vue.get_viewport_rid(), true)
		_vues.append(vue)

	var kael := jeu.get_node("Monde/Kael") as Node3D
	var mira := jeu.get_node("Monde/Mira") as Node3D
	var cameras := [
		jeu.get_node("SplitScreen/Conteneur/VueKael/SubViewport/CameraKael"),
		jeu.get_node("SplitScreen/Conteneur/VueMira/SubViewport/CameraMira"),
	]

	print("mesure_fps : ", DisplayServer.window_get_size(), " — ",
		RenderingServer.get_video_adapter_name())
	for prise in PRISES:
		kael.global_position = prise["kael"]
		mira.global_position = prise["mira"]
		for cam in cameras:
			if "_angle_h" in cam:
				cam._angle_h = prise["angle"]
		await _attendre(DUREE_CHAUFFE)
		await _mesurer(prise["nom"])
	get_tree().quit()

func _attendre(secondes: float) -> void:
	var fin := Time.get_ticks_msec() + int(secondes * 1000.0)
	while Time.get_ticks_msec() < fin:
		await get_tree().process_frame

func _mesurer(nom: String) -> void:
	var images := 0
	var pire := 0.0
	var gpu := [0.0, 0.0]
	var debut := Time.get_ticks_usec()
	var precedent := debut
	while Time.get_ticks_usec() - debut < int(DUREE_PRISE * 1e6):
		await get_tree().process_frame
		var maintenant := Time.get_ticks_usec()
		pire = maxf(pire, float(maintenant - precedent) / 1000.0)
		precedent = maintenant
		images += 1
		for i in _vues.size():
			gpu[i] += RenderingServer.viewport_get_measured_render_time_gpu(_vues[i].get_viewport_rid())
	var duree := float(Time.get_ticks_usec() - debut) / 1e6
	print("mesure_fps [%s] : %.1f fps moyens, pire image %.1f ms, GPU vue Kael %.2f ms, vue Mira %.2f ms" % [
		nom, images / duree, pire, gpu[0] / images, gpu[1] / images])
