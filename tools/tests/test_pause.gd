# tools/tests/test_pause.gd
# Vérifie le menu pause :
#   - l'action "pause" (Échap / Start) fige tout le jeu, et le menu, lui, tourne ;
#   - « Reprendre » a le focus, la croix / le stick (ui_down, ui_up) le déplacent ;
#   - pendant la pause, interagir ne déclenche rien ;
#   - valider « Reprendre » avec A ne déclenche PAS le PNJ le plus proche
#     (A = ui_accept ET joueur1_interagir : c'est le bug historique du projet) ;
#   - « Menu principal » lève la pause et revient au menu.
#
# Lancer :
#   godot --headless --path . res://tools/tests/test_pause.tscn --quit-after 20000

extends Node

const SCENE_MAIN := "res://scenes/main.tscn"

class FauxPnj extends Node3D:
	var appels: int = 0
	func obtenir_verbe() -> String:
		return "Tester"
	func declencher(_id_joueur: int) -> void:
		appels += 1

var _echecs: int = 0
var _main: Node = null

func _ready() -> void:
	print("--- Test pause ---")
	# Ce nœud doit continuer de tourner pendant la pause pour observer.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 4.0
	_main = load(SCENE_MAIN).instantiate()
	get_tree().root.add_child.call_deferred(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = _main
	_lancer()

func _lancer() -> void:
	var kael: Node3D = _main.get_node("Monde/Kael")
	var menu = _main.menu_pause

	# On passe l'intro pour être en jeu.
	await _passer_intro()
	Engine.time_scale = 1.0
	_verifier("En jeu apres l'intro", str(_main.ecran_narration == null), "true")

	# ── Ouvrir ───────────────────────────────────────────────────────────────
	await _appuyer("pause")
	_verifier("L'action pause fige l'arbre", str(get_tree().paused), "true")
	_verifier("Le menu pause est visible", str(menu.est_ouvert()), "true")
	_verifier("Le menu tourne pendant la pause",
		str(menu.can_process()), "true")
	_verifier("« Reprendre » a le focus", _focus(), "Reprendre")

	# ── Le jeu est vraiment figé ─────────────────────────────────────────────
	var x_depart := kael.global_position.x
	Input.action_press("joueur1_droite")
	await _attendre(0.5)
	Input.action_release("joueur1_droite")
	_verifier("Kael ne bouge pas en pause",
		"%.2f" % (kael.global_position.x - x_depart), "0.00")

	var pnj := FauxPnj.new()
	kael.add_child(pnj)
	InteractionManager.enregistrer(1, pnj)
	await _appuyer("joueur1_interagir")
	_verifier("Interagir en pause ne declenche rien", str(pnj.appels), "0")

	# ── Navigation manette ───────────────────────────────────────────────────
	_envoyer_ui("ui_down")
	await get_tree().process_frame
	_verifier("ui_down descend sur « Menu principal »", _focus(), "Menu principal")
	_envoyer_ui("ui_up")
	await get_tree().process_frame
	_verifier("ui_up remonte sur « Reprendre »", _focus(), "Reprendre")

	# ── Reprendre avec A ─────────────────────────────────────────────────────
	# Le pire cas : l'appui de A est vu comme joueur1_interagir dans la MÊME
	# frame que celle où « Reprendre » est validé.
	await get_tree().process_frame
	Input.action_press("joueur1_interagir")
	menu._sur_reprendre()
	await get_tree().process_frame
	Input.action_release("joueur1_interagir")
	await get_tree().process_frame
	await get_tree().process_frame
	_verifier("Reprendre leve la pause", str(get_tree().paused), "false")
	_verifier("Reprendre cache le menu", str(menu.est_ouvert()), "false")
	_verifier("Le A de « Reprendre » ne declenche pas le PNJ", str(pnj.appels), "0")

	# Contrôle : hors pause, le même appui déclenche bien le PNJ.
	await _appuyer("joueur1_interagir")
	_verifier("Hors pause, interagir declenche le PNJ", str(pnj.appels), "1")
	InteractionManager.retirer(1, pnj)
	await _attendre(0.2)
	# Ferme le dialogue éventuel ouvert par un vrai PNJ voisin.
	if DialogueManager.est_actif():
		DialogueManager.masquer()

	# Hors pause, Kael marche de nouveau.
	x_depart = kael.global_position.x
	Input.action_press("joueur1_droite")
	await _attendre(0.5)
	Input.action_release("joueur1_droite")
	_verifier("Kael remarche apres la pause",
		str(absf(kael.global_position.x - x_depart) > 0.5), "true")

	# ── Start re-ferme le menu (bascule) ─────────────────────────────────────
	await _appuyer("pause")
	await _appuyer("pause")
	await get_tree().process_frame
	_verifier("Deux appuis sur pause : ouvert puis ferme", str(get_tree().paused), "false")

	# ── Menu principal ───────────────────────────────────────────────────────
	await _appuyer("pause")
	_envoyer_ui("ui_down")
	await get_tree().process_frame
	_envoyer_ui("ui_accept")
	var scene: Node = await _attendre_scene("MenuPrincipal", 5.0)
	_verifier("« Menu principal » revient au menu", str(scene != null), "true")
	_verifier("La pause est levee au menu", str(get_tree().paused), "false")

	_conclure()

# ──────────────────────────────────────────────────────────────────────────────
# OUTILS
# ──────────────────────────────────────────────────────────────────────────────

func _passer_intro() -> void:
	var ecoule := 0.0
	while _main.ecran_narration != null and ecoule < 40.0:
		await _appuyer("joueur1_interagir")
		await _attendre(0.8)
		ecoule += 0.8

func _focus() -> String:
	var focus := get_viewport().gui_get_focus_owner()
	return (focus as Button).text if focus is Button else "aucun"

func _appuyer(action: String) -> void:
	await get_tree().process_frame
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)
	await get_tree().process_frame

func _envoyer_ui(action: String) -> void:
	for presse in [true, false]:
		var evenement := InputEventAction.new()
		evenement.action = action
		evenement.pressed = presse
		get_viewport().push_input(evenement)

func _attendre_scene(nom: String, delai_max: float) -> Node:
	var ecoule := 0.0
	while ecoule < delai_max:
		var scene := get_tree().current_scene
		if scene != null and scene.name == nom:
			return scene
		await _attendre(0.2)
		ecoule += 0.2
	return null

# create_timer() tourne même en pause (process_always vaut true par défaut).
func _attendre(secondes: float) -> void:
	await get_tree().create_timer(secondes).timeout

func _conclure() -> void:
	Engine.time_scale = 1.0
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
