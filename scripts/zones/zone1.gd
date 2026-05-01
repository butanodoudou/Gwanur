# scripts/zones/zone1.gd
# Zone 1 — Sylvara, le Village des Lisières
#
# L'Aelith (Nimbus Willow) est au centre (0, 0, 0) — instancié dans zone1.tscn.
# Le village s'étend en radial autour de l'arbre, rayon ~15m.
# Entrée depuis le sud (+Z), sortie vers Zone 2 au nord (-Z).
#
# Responsabilités :
#   1. Géométrie procédurale — maisons, puits, palissade, ruisseau (BoxMesh colorés)
#   2. Coordination des puzzles — signaux et état global
#   3. Grimoire — choix narratif de fin de zone

extends Node3D

const COULEUR_SOL      = Color(0.55, 0.45, 0.30)
const COULEUR_PIERRE   = Color(0.72, 0.63, 0.50)
const COULEUR_BOIS     = Color(0.42, 0.28, 0.18)
const COULEUR_PERCHOIR = Color(0.35, 0.22, 0.12)
const COULEUR_EAU      = Color(0.25, 0.45, 0.60)

@onready var puzzle1     = $Puzzle1PorteDouble
@onready var puzzle2     = $Puzzle2Oiseau
@onready var puzzle3     = $Puzzle3RoueEau
@onready var zone_grimoire: Area3D = $ZoneGrimoire

var _attente_choix: bool = false

func _ready() -> void:
	set_process(false)
	_construire_village()
	_coloriser_puzzles()
	_configurer_echo_liane()
	_connecter_puzzles()

# ──────────────────────────────────────────────────────────────────────────────
# GÉOMÉTRIE PROCÉDURALE
# ──────────────────────────────────────────────────────────────────────────────
#
# Les BoxMesh colorés sont des placeholders en attendant les vrais assets 3D.
# L'Aelith (le vrai modèle) est déjà instancié dans zone1.tscn.

func _construire_village() -> void:
	# ── Sol étendu ────────────────────────────────────────────────────────────
	# Couvre tout le village doublé (rayon ~30m) + la zone nord vers Zone 2.
	_sol(Vector3(80, 0.2, 40), Vector3( 0, -0.1, -20))  # Centre et nord
	_sol(Vector3(80, 0.2, 30), Vector3( 0, -0.1,  20))  # Sud (entrée)

	# ── Maisons ───────────────────────────────────────────────────────────────
	# Maison de Lira (est, en face de l'Aelith)
	_maison(Vector3(8, 4, 8), Vector3( 22, 2.0,  14))

	# Maison voisin (est, côté nord — l'oiseau du Puzzle 2 est sur ce toit)
	_maison(Vector3(8, 4, 8), Vector3( 22, 2.0,  -6))

	# Moulin de Brennan (ouest — plus grand, c'est un moulin)
	_maison(Vector3(10, 6, 10), Vector3(-22, 3.0, -12))

	# Maisons de bruit (camouflent Vaenmor, donnent vie au village)
	_maison(Vector3(7, 4, 7), Vector3(-18, 2.0,  14))
	_maison(Vector3(7, 4, 6), Vector3( -6, 2.0,  22))
	_maison(Vector3(6, 4, 7), Vector3(  8, 2.0,  24))
	_maison(Vector3(6, 3, 6), Vector3( 20, 1.5,  18))  # Maison supplémentaire

	# ── Puits central ─────────────────────────────────────────────────────────
	_mur(Vector3(1.8, 1.5, 1.8), Vector3(7.0, 0.75, 6.0), COULEUR_PIERRE)

	# ── Perchoir de l'oiseau ──────────────────────────────────────────────────
	# Sur le toit de la maison voisin (est, z=-6).
	_mur(Vector3(2.0, 0.6, 2.0), Vector3(23.0, 6.2, -6.0), COULEUR_PERCHOIR)

	# ── Palissade nord ────────────────────────────────────────────────────────
	# Gap au centre pour la Porte du Puzzle 1 (z=-36).
	_mur(Vector3(0.4, 3.0, 20.0), Vector3(-18.0, 1.5, -36.0), COULEUR_BOIS)
	_mur(Vector3(0.4, 3.0, 20.0), Vector3( 18.0, 1.5, -36.0), COULEUR_BOIS)

	# ── Stèle du Pacte d'Aelric ───────────────────────────────────────────────
	_mur(Vector3(0.5, 3.5, 0.4), Vector3(0.0, 1.75, -44.0), COULEUR_PIERRE)

	# ── Ruisseau (Puzzle 3 — côté ouest) ──────────────────────────────────────
	_mur(Vector3(18.0, 0.5, 0.4), Vector3(-22.0, 0.25, -30.0), COULEUR_PIERRE)
	_mur(Vector3(18.0, 0.5, 0.4), Vector3(-22.0, 0.25, -38.0), COULEUR_PIERRE)
	# Fond du ruisseau (eau)
	_mur(Vector3(16.0, 0.1, 7.5), Vector3(-22.0, -0.05, -34.0), COULEUR_EAU)

func _configurer_echo_liane() -> void:
	var echo: MeshInstance3D = $Puzzle3RoueEau/EchoLiane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.9, 0.6, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode    = BaseMaterial3D.CULL_DISABLED
	echo.set_surface_override_material(0, mat)

# ──────────────────────────────────────────────────────────────────────────────
# COORDINATION DES PUZZLES
# ──────────────────────────────────────────────────────────────────────────────

func _connecter_puzzles() -> void:
	puzzle1.puzzle_resolu.connect(_sur_puzzle1_resolu)
	puzzle2.puzzle_resolu.connect(_sur_puzzle2_resolu)
	puzzle3.puzzle_resolu.connect(_sur_puzzle3_resolu)
	zone_grimoire.body_entered.connect(_sur_entree_grimoire)
	zone_grimoire.monitoring = false

func _sur_puzzle1_resolu() -> void:
	DialogueManager.afficher("", ["La porte grince... le passage est libre."])

func _sur_puzzle2_resolu() -> void:
	DialogueManager.afficher("", ["L'oiseau s'envole. Le chemin est ouvert."])

func _sur_puzzle3_resolu() -> void:
	if not GameManager.zone1_terminee():
		return
	await get_tree().create_timer(3.0).timeout
	DialogueManager.afficher("", [
		"Quelque chose brille dans la vieille maison au nord...",
		"Une lame du plancher, légèrement soulevée."
	])
	zone_grimoire.monitoring = true

func _sur_entree_grimoire(body: Node3D) -> void:
	if not body.is_in_group("joueurs"):
		return
	zone_grimoire.monitoring = false
	_declencher_grimoire()

# ──────────────────────────────────────────────────────────────────────────────
# GRIMOIRE + CHOIX DE FIN DE ZONE
# ──────────────────────────────────────────────────────────────────────────────

func _declencher_grimoire() -> void:
	DialogueManager.afficher("Grimoire d'Elara", [
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

# ──────────────────────────────────────────────────────────────────────────────
# HELPERS — COULEURS DES PUZZLES
# ──────────────────────────────────────────────────────────────────────────────

func _coloriser_puzzles() -> void:
	_appliquer_couleur($Puzzle1PorteDouble/Porte/MeshInstance3D,    Color(0.30, 0.15, 0.08))
	_appliquer_couleur($Puzzle2Oiseau/Grille/MeshInstance3D,        Color(0.50, 0.50, 0.55))
	_appliquer_couleur($Puzzle3RoueEau/RoueEau/MeshInstance3D,      Color(0.35, 0.22, 0.12))
	_appliquer_couleur($Puzzle3RoueEau/Pont/MeshInstance3D,         Color(0.45, 0.32, 0.18))

func _appliquer_couleur(mi: MeshInstance3D, couleur: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mi.set_surface_override_material(0, mat)

# ──────────────────────────────────────────────────────────────────────────────
# HELPERS — CRÉATION DE GÉOMÉTRIE
# ──────────────────────────────────────────────────────────────────────────────

func _sol(taille: Vector3, pos: Vector3) -> void:
	_bloc(taille, pos, COULEUR_SOL)

func _mur(taille: Vector3, pos: Vector3, couleur: Color) -> void:
	_bloc(taille, pos, couleur)

func _maison(taille: Vector3, pos: Vector3) -> void:
	_bloc(taille, pos, COULEUR_BOIS)

func _bloc(taille: Vector3, pos: Vector3, couleur: Color) -> void:
	var sb := StaticBody3D.new()
	sb.position = pos

	var cs    := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = taille
	cs.shape   = shape
	sb.add_child(cs)

	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = taille
	var mat  := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mesh.surface_set_material(0, mat)
	mi.mesh = mesh
	sb.add_child(mi)

	add_child(sb)
