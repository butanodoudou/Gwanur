# tools/tests/test_puzzle_porte.gd
# Vérifie le Puzzle 1 (La Porte à Deux Poignées) après son passage aux
# PointInteraction :
#   - chaque poignée affiche son prompt dans le HUD du bon joueur uniquement
#   - prendre une poignée pose un message d'état visible par les DEUX joueurs
#   - la poignée prise n'affiche plus de prompt
#   - quand les deux tiennent, la porte monte et l'état s'efface
#
# Lancer :
#   godot --headless --path . res://tools/tests/test_puzzle_porte.tscn --quit-after 900

extends Node

# Le prompt affiche (E)/(Entrée) au clavier, (A) à la manette (voir le fichier).
const TouchesJoueur = preload("res://scripts/ui/touches_joueur.gd")

var _echecs: int = 0
var _kael: Node3D
var _mira: Node3D
var _puzzle: Node3D
var _hud_kael
var _hud_mira

func _ready() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	print("--- Test Puzzle 1 : la porte a deux poignees ---")

	_kael = scene.get_node("Monde/Kael")
	_mira = scene.get_node("Monde/Mira")
	_puzzle = scene.get_node("Monde/Zone1/Puzzle1PorteDouble")
	_hud_kael = scene.get_node("SplitScreen/Conteneur/VueKael/SubViewport/HudKael")
	_hud_mira = scene.get_node("SplitScreen/Conteneur/VueMira/SubViewport/HudMira")

	var poignee_kael = _puzzle.get_node("ZoneInteractionKael")
	var poignee_mira = _puzzle.get_node("ZoneInteractionMira")

	_verifier("Poignee de Kael est un PointInteraction",
		str(poignee_kael is PointInteraction), "true")
	_verifier("Poignee de Mira est un PointInteraction",
		str(poignee_mira is PointInteraction), "true")

	# ── Kael s'approche de sa poignee ───────────────────────────────────────
	await _placer(_kael, poignee_kael.global_position)

	_verifier("Prompt de Kael sur sa poignee",
		_hud_kael._label_prompt.text, "(%s)  Tirer la poignée gauche" % TouchesJoueur.interagir(1))
	_verifier("Mira ne voit pas le prompt de Kael",
		str(_hud_mira._label_prompt.visible), "false")

	# ── Kael prend sa poignee ───────────────────────────────────────────────
	await _appuyer("joueur1_interagir")

	_verifier("Kael tient sa poignee", str(_puzzle.kael_pret), "true")
	_verifier("La porte n'est pas encore ouverte", str(_puzzle.resolu), "false")
	_verifier("Un etat coop est affiche",
		GameManager.etat_coop, "Kael tient sa poignée — Mira, prends l'autre !")
	_verifier("L'etat coop est visible chez Kael",
		str(_hud_kael._label_etat.visible), "true")
	_verifier("L'etat coop est AUSSI visible chez Mira",
		str(_hud_mira._label_etat.visible), "true")
	_verifier("La poignee prise n'affiche plus de prompt",
		str(_hud_kael._label_prompt.visible), "false")

	# ── Mira rejoint et prend la sienne ─────────────────────────────────────
	await _placer(_mira, poignee_mira.global_position)
	_verifier("Prompt de Mira sur sa poignee",
		_hud_mira._label_prompt.text, "(%s)  Tirer la poignée droite" % TouchesJoueur.interagir(2))

	var hauteur_avant: float = _puzzle.get_node("Porte").position.y
	await _appuyer("joueur2_interagir")

	_verifier("Le puzzle est resolu", str(_puzzle.resolu), "true")
	_verifier("GameManager enregistre la resolution", str(GameManager.puzzle1_resolu), "true")
	_verifier("L'etat coop est efface", GameManager.etat_coop, "")

	# La porte monte via un tween de 1.5 s
	await get_tree().create_timer(2.0).timeout
	_verifier("La porte est montee",
		str(_puzzle.get_node("Porte").position.y > hauteur_avant + 3.0), "true")

	_conclure()

# Teleporte un personnage et laisse la physique detecter l'entree dans l'Area3D
func _placer(perso: Node3D, cible: Vector3) -> void:
	perso.global_position = cible + Vector3(0.0, 0.5, 0.0)
	for i in 20:
		await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame

func _appuyer(action: String) -> void:
	# Resynchronisation sur un debut de frame : process_frame est emis juste
	# avant les _process(), alors qu'un timer rend la main apres.
	await get_tree().process_frame
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)
	await get_tree().process_frame

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
