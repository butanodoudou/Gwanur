# scripts/zones/zone1.gd
# Zone 1 — Le Village des Lisières
#
# Deux responsabilités :
#   1. Géométrie procédurale — crée le village (sol, murs, maisons, décor)
#      en code pour éviter les .tscn trop lourds pendant le prototype.
#   2. Coordination — connecte les puzzles, déclenche le grimoire, gère le choix final.
#
# Pourquoi la géométrie en code ?
#   Les vrais modèles 3D (Meshy → Blender) remplaceront ces blocs plus tard.
#   En attendant, des boîtes colorées suffisent pour tester les mécaniques.

extends Node3D

# ── Palette de couleurs du village ────────────────────────────────────────
const COULEUR_SOL    = Color(0.55, 0.45, 0.30)  # Terre battue
const COULEUR_PIERRE = Color(0.72, 0.63, 0.50)  # Mur en pierre
const COULEUR_BOIS   = Color(0.42, 0.28, 0.18)  # Maison en bois
const COULEUR_PERCHOIR = Color(0.35, 0.22, 0.12)

# ── Références aux nœuds de gameplay ─────────────────────────────────────
@onready var puzzle1 = $Puzzle1PorteDouble
@onready var puzzle2 = $Puzzle2Oiseau
@onready var puzzle3 = $Puzzle3RoueEau
@onready var zone_grimoire: Area3D = $ZoneGrimoire

# ── État du grimoire ───────────────────────────────────────────────────────
var _attente_choix: bool = false

func _ready() -> void:
	set_process(false)
	_construire_village()
	_configurer_echo_liane()
	_connecter_puzzles()

# ──────────────────────────────────────────────────────────────────────────
# GÉOMÉTRIE PROCÉDURALE
# ──────────────────────────────────────────────────────────────────────────

func _construire_village() -> void:
	# Sol en deux sections (séparées par le fossé du Puzzle 3)
	_sol(Vector3(12, 0.2, 46), Vector3(0, -0.1, -23))   # z=0 à z=-46
	_sol(Vector3(12, 0.2,  8), Vector3(0, -0.1, -54))   # z=-50 à z=-58

	# Murs latéraux (toute la longueur)
	_mur(Vector3(0.5, 4, 60), Vector3(-6, 2, -28))
	_mur(Vector3(0.5, 4, 60), Vector3( 6, 2, -28))

	# Fond de zone
	_mur(Vector3(12, 5, 0.5), Vector3(0, 2.5, -58))

	# Maisons du village (décor)
	_maison(Vector3(4, 3, 5), Vector3(-4, 1.5, -5))   # Maison de Lira
	_maison(Vector3(4, 3, 5), Vector3( 4, 1.5, -5))   # Maison voisin

	# Moulin de Brennan (plus grand, à gauche)
	_maison(Vector3(5, 4, 6), Vector3(-4.5, 2, -19))

	# Murs qui rétrécissent le couloir autour de la Grille (Puzzle 2)
	# → force les joueurs à passer par la grille
	_mur(Vector3(3, 4, 0.5), Vector3(-4, 2, -24))
	_mur(Vector3(3, 4, 0.5), Vector3( 4, 2, -24))

	# Perchoir de l'oiseau (petite plateforme en hauteur à droite)
	_mur(Vector3(1.5, 0.5, 1.5), Vector3(5.25, 3.1, -24), COULEUR_PERCHOIR)

	# Rebord du fossé (Puzzle 3) — bords visibles
	_mur(Vector3(12, 0.5, 0.3), Vector3(0, 0.25, -46))  # Bord proche
	_mur(Vector3(12, 0.5, 0.3), Vector3(0, 0.25, -50))  # Bord loin

# ── Matériau de l'écho (semi-transparent, bleu fantôme) ───────────────────
func _configurer_echo_liane() -> void:
	var echo: MeshInstance3D = $Puzzle3RoueEau/EchoLiane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.9, 0.6, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	echo.set_surface_override_material(0, mat)

# ──────────────────────────────────────────────────────────────────────────
# COORDINATION DES PUZZLES
# ──────────────────────────────────────────────────────────────────────────

func _connecter_puzzles() -> void:
	puzzle1.puzzle_resolu.connect(_sur_puzzle1_resolu)
	puzzle2.puzzle_resolu.connect(_sur_puzzle2_resolu)
	puzzle3.puzzle_resolu.connect(_sur_puzzle3_resolu)
	zone_grimoire.body_entered.connect(_sur_entree_grimoire)
	zone_grimoire.monitoring = false

func _sur_puzzle1_resolu() -> void:
	DialogueManager.afficher("", ["La porte grince... le passage est libre."])

func _sur_puzzle2_resolu() -> void:
	DialogueManager.afficher("", ["Le chemin vers le vieux moulin est ouvert."])

func _sur_puzzle3_resolu() -> void:
	if not GameManager.zone1_terminee():
		return
	# Attend 3s puis guide les joueurs vers le grimoire
	await get_tree().create_timer(3.0).timeout
	DialogueManager.afficher("", [
		"Quelque chose brille dans la vieille maison...",
		"Une lame du plancher, légèrement soulevée."
	])
	zone_grimoire.monitoring = true

func _sur_entree_grimoire(body: Node3D) -> void:
	if not body.is_in_group("joueurs"):
		return
	zone_grimoire.monitoring = false
	_declencher_grimoire()

# ──────────────────────────────────────────────────────────────────────────
# GRIMOIRE + CHOIX DE FIN DE ZONE
# ──────────────────────────────────────────────────────────────────────────

func _declencher_grimoire() -> void:
	DialogueManager.afficher("Grimoire d'Aelindra", [
		"Un vieux grimoire, couvert de son écriture.",
		"\"L'équilibre que je maintiens... le titre que je ne peux plus porter.\"",
		"Vous le gardez secret entre vous ?"
	])
	await get_tree().create_timer(11.0).timeout
	DialogueManager.afficher("", [
		"Manette 1 (A) → Garder le secret",
		"Manette 2 (A) → Le partager avec les villageois"
	])
	_attente_choix = true
	set_process(true)

func _process(_delta: float) -> void:
	if not _attente_choix:
		return
	if Input.is_action_just_pressed("joueur1_interagir"):
		_appliquer_choix("secret")
	elif Input.is_action_just_pressed("joueur2_interagir"):
		_appliquer_choix("partager")

func _appliquer_choix(choix: String) -> void:
	_attente_choix = false
	set_process(false)
	GameManager.choix_grimoire = choix

	if choix == "secret":
		GameManager.modifier_moralite_kael(-10)
		GameManager.modifier_moralite_mira(-10)
		DialogueManager.afficher("", [
			"Vous refermez le grimoire. C'est entre vous.",
			"Kael débloque : Résonance",
			"Mira débloque : Ancrage"
		])
	else:
		GameManager.modifier_moralite_kael(10)
		GameManager.modifier_moralite_mira(10)
		DialogueManager.afficher("", [
			"Vous partagez la nouvelle avec les villageois.",
			"Kael débloque : Mémoire des Anciens",
			"Mira débloque : Lecture"
		])

# ──────────────────────────────────────────────────────────────────────────
# HELPERS — CRÉATION DE GÉOMÉTRIE
# ──────────────────────────────────────────────────────────────────────────

func _sol(taille: Vector3, pos: Vector3) -> void:
	_bloc(taille, pos, COULEUR_SOL)

func _mur(taille: Vector3, pos: Vector3, couleur: Color = COULEUR_PIERRE) -> void:
	_bloc(taille, pos, couleur)

func _maison(taille: Vector3, pos: Vector3) -> void:
	_bloc(taille, pos, COULEUR_BOIS)

func _bloc(taille: Vector3, pos: Vector3, couleur: Color) -> void:
	var sb := StaticBody3D.new()
	sb.position = pos

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = taille
	cs.shape = shape
	sb.add_child(cs)

	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = taille
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mesh.surface_set_material(0, mat)
	mi.mesh = mesh
	sb.add_child(mi)

	add_child(sb)
