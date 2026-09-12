# tools/tests/test_interaction.gd
# Vérifie que le bouton d'interaction n'est consommé que par un seul système
# à la fois.
#
# Scénario : un joueur à portée d'un PNJ ouvre un dialogue, puis appuie sur A
# pour avancer. Avant correction (2026-09-12), le PNJ lisait l'input lui-même
# et relançait le dialogue depuis la première ligne dans la même frame — le
# texte restait bloqué sur la ligne 1.
#
# Lancer :
#   godot --headless --path . res://tools/tests/test_interaction.tscn --quit-after 900
#
# Contrôle négatif (doit échouer — reproduit l'ancien comportement) :
#   godot --headless --path . res://tools/tests/test_interaction.tscn --quit-after 900 -- --bug

extends Node

class FauxPnj extends Node3D:
	var appels: int = 0
	# Mis a true pour reproduire l'ANCIEN comportement bugue (le PNJ lisait
	# l'input lui-meme). Sert de controle negatif : le test doit alors echouer.
	var lire_input_soi_meme: bool = false

	func obtenir_verbe() -> String:
		return "Tester"

	func _process(_delta: float) -> void:
		if lire_input_soi_meme and Input.is_action_just_pressed("joueur1_interagir"):
			declencher(1)

	func declencher(_id_joueur: int) -> void:
		appels += 1
		DialogueManager.afficher("Faux PNJ", ["ligne1", "ligne2", "ligne3"])

var _pnj: FauxPnj
var _echecs: int = 0

func _ready() -> void:
	var joueur := Node3D.new()
	joueur.add_to_group("kael")
	joueur.add_to_group("joueurs")
	add_child(joueur)

	_pnj = FauxPnj.new()
	# Lancer avec --  --bug pour reproduire l'ancien comportement (controle negatif)
	_pnj.lire_input_soi_meme = OS.get_cmdline_user_args().has("--bug")
	add_child(_pnj)
	InteractionManager.enregistrer(1, _pnj)

	await get_tree().process_frame
	_lancer()

func _lancer() -> void:
	print("--- Test interaction / dialogue ---")

	await _appuyer()
	_verifier("Appui 1 ouvre le dialogue", _ligne(), "ligne1")
	_verifier("Appui 1 declenche le PNJ une fois", str(_pnj.appels), "1")

	await _attendre(0.8)
	await _appuyer()
	_verifier("Appui 2 avance a la ligne 2", _ligne(), "ligne2")
	_verifier("Appui 2 ne relance PAS le PNJ", str(_pnj.appels), "1")

	await _attendre(0.8)
	await _appuyer()
	_verifier("Appui 3 avance a la ligne 3", _ligne(), "ligne3")
	_verifier("Appui 3 ne relance PAS le PNJ", str(_pnj.appels), "1")

	await _attendre(0.8)
	await _appuyer()
	_verifier("Appui 4 ferme le dialogue", str(DialogueManager.est_actif()), "false")
	_verifier("La fermeture ne relance PAS le PNJ", str(_pnj.appels), "1")

	# Apres fermeture, une nouvelle interaction doit redevenir possible
	await _attendre(0.5)
	await _appuyer()
	_verifier("Nouvel appui rouvre le dialogue", str(_pnj.appels), "2")

	if _echecs == 0:
		print("--- RESULTAT : tout est OK ---")
	else:
		print("--- RESULTAT : %d ECHEC(S) ---" % _echecs)
	get_tree().quit()

func _ligne() -> String:
	return DialogueManager._label_texte.text

func _appuyer() -> void:
	# On se resynchronise sur un DEBUT de frame avant de presser : le signal
	# process_frame est emis juste avant les _process(), alors qu'un timer rend
	# la main apres. Sans ca, l'appui simule arrive trop tard pour etre vu.
	await get_tree().process_frame
	Input.action_press("joueur1_interagir")
	await get_tree().process_frame
	Input.action_release("joueur1_interagir")
	await get_tree().process_frame

func _attendre(secondes: float) -> void:
	await get_tree().create_timer(secondes).timeout

func _verifier(quoi: String, obtenu: String, attendu: String) -> void:
	if obtenu == attendu:
		print("  OK   : %s" % quoi)
	else:
		_echecs += 1
		print("  ECHEC: %s  (attendu '%s', obtenu '%s')" % [quoi, attendu, obtenu])
