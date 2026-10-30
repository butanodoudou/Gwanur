# tools/tests/test_cour_oiseau.gd
# Vérifie que la grille du Puzzle 2 ne se referme JAMAIS sur un joueur.
#
# Derrière la grille, il n'y a que la cour (la porte nord est fermée tant que
# le Puzzle 1 n'est pas fait). Si la grille retombait sur Kael, il serait trop
# loin de l'oiseau pour le rappeler : la partie serait bloquée.
#
#   1. Les bornes de la cour (zone1.gd → derriere_la_grille) : cour, nord de
#      la palissade, sous la grille → dedans ; village, bief → dehors
#   2. Grille ouverte, Kael dans la cour, le délai expire → la grille reste
#      ouverte, et l'état coop explique pourquoi
#   3. Kael sort, Mira entre → toujours ouverte (elle peut verrouiller ou sortir)
#   4. La cour se vide → la grille se referme
#
# Pour ne pas attendre 12 s, on raccourcit la minuterie du puzzle à la main.
#
# Lancer :
#   godot --headless --path . res://tools/tests/test_cour_oiseau.tscn --quit-after 3000

extends Node

const Zone1 = preload("res://scripts/zones/zone1.gd")

var _echecs: int = 0
var _zone: Node3D
var _kael: CharacterBody3D
var _mira: CharacterBody3D
var _puzzle: Node3D
# Chaque émission de grille_changee, dans l'ordre (true = levée, false = retombée)
var _changements: Array = []

func _ready() -> void:
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(scene)
	for i in 10:
		await get_tree().physics_frame
	await get_tree().process_frame

	print("--- Test Puzzle 2 : la grille ne se referme pas sur un joueur ---")

	_zone = scene.get_node("Monde/Zone1")
	_kael = scene.get_node("Monde/Kael")
	_mira = scene.get_node("Monde/Mira")
	_puzzle = _zone.get_node("Puzzle2Oiseau")
	_puzzle.grille_changee.connect(func(ouverte): _changements.append(ouverte))

	# ── 1. Les bornes de la cour ─────────────────────────────────────────────
	var marge: float = _puzzle.MARGE_SOUS_GRILLE
	_verifier("Milieu de la cour : dedans",
		str(Zone1.derriere_la_grille(Vector3(0, 0, -30), marge)), "true")
	_verifier("Au nord de la grande palissade : dedans",
		str(Zone1.derriere_la_grille(Vector3(20, 0, -40), marge)), "true")
	_verifier("Debout sous la grille levee : dedans",
		str(Zone1.derriere_la_grille(Vector3(0, 0, Zone1.Z_GRILLE + marge * 0.5), marge)), "true")
	_verifier("Place du village : dehors",
		str(Zone1.derriere_la_grille(Vector3(0, 0, -14), marge)), "false")
	_verifier("Bief du ruisseau (a cote de la cour) : dehors",
		str(Zone1.derriere_la_grille(Vector3(-20, 0, -33), marge)), "false")

	# ── 2. Kael dans la cour quand le délai expire ──────────────────────────
	await _placer(_mira, Vector3(3, 0, -18))     # Mira sur la place
	_puzzle._ouvrir_grille()                      # comme si l'oiseau s'était posé
	_verifier("La grille s'ouvre", str(_puzzle.grille_ouverte), "true")
	await _attendre(1.2)                          # la grille finit de monter
	await _placer(_kael, Vector3(0, 0, -30))      # Kael passe dans la cour
	_verifier("Kael est compte derriere la grille",
		str(_puzzle.joueurs_derriere_la_grille().has(_kael)), "true")

	_puzzle._minuterie_fermeture = 0.3            # on raccourcit les 12 s
	await _attendre(1.0)
	_verifier("Delai expire, Kael dans la cour : la grille reste ouverte",
		str(_puzzle.grille_ouverte), "true")
	_verifier("Aucune fermeture annoncee", str(_changements.has(false)), "false")
	_verifier("L'etat coop dit a Kael de ressortir",
		str(GameManager.etat_coop.contains("Kael")), "true")
	_verifier("Le verrou reste propose a Mira", str(_puzzle.zone_verrou._disponible), "true")

	# ── 3. Kael sort, Mira entre ─────────────────────────────────────────────
	await _placer(_mira, Vector3(2, 0, -30))
	await _placer(_kael, Vector3(-3, 0, -14))
	await _attendre(0.5)
	_verifier("Mira dans la cour : la grille reste ouverte", str(_puzzle.grille_ouverte), "true")
	_verifier("L'etat coop appelle Mira au verrou",
		str(GameManager.etat_coop.contains("Mira")), "true")

	# ── 4. La cour se vide ───────────────────────────────────────────────────
	await _placer(_mira, Vector3(3, 0, -18))
	await _attendre(0.3)
	_verifier("Cour vide : la grille se referme", str(_puzzle.grille_ouverte), "false")
	_verifier("La fermeture est annoncee (grille_changee(false))", str(_changements.back()), "false")
	_verifier("L'etat coop est efface", GameManager.etat_coop, "")
	_verifier("Le verrou n'est plus propose", str(_puzzle.zone_verrou._disponible), "false")

	_conclure()

# Téléporte un personnage (position LOCALE de la zone, au sol) et laisse la
# physique se poser.
func _placer(perso: CharacterBody3D, local: Vector3) -> void:
	perso.velocity = Vector3.ZERO
	perso.global_position = _zone.to_global(local) + Vector3(0, 0.05, 0)
	for i in 6:
		await get_tree().physics_frame
	await get_tree().process_frame

func _attendre(secondes: float) -> void:
	await get_tree().create_timer(secondes).timeout

func _conclure() -> void:
	if _echecs == 0:
		print("--- RESULTAT : tout est OK ---")
	else:
		print("--- RESULTAT : %d ECHEC(S) ---" % _echecs)
	get_tree().quit()

func _verifier(quoi: String, obtenu: String, attendu: String) -> void:
	if obtenu == attendu:
		print("  OK   : %s" % quoi)
	else:
		_echecs += 1
		print("  ECHEC: %s  (attendu '%s', obtenu '%s')" % [quoi, attendu, obtenu])
