# tools/tests/test_fin_zone.gd
# Vérifie le flux complet d'une partie, de l'intro au retour au menu :
#
#   1. Intro : écran noir + textes, joueurs figés, et le bouton « interagir »
#      (qui fait passer les lignes) ne déclenche PAS de PNJ en même temps.
#   2. Choix du grimoire → dialogue de résultat → fondu au noir → texte de fin
#      qui correspond au choix → texte commun → crédits → menu principal.
#   3. Au menu : « Commencer » a le focus (manette), et le relancer remet
#      GameManager à zéro — sinon la 2e partie démarrerait « terminée ».
#
# Le jeu tourne en accéléré (Engine.time_scale) pour que le test reste court.
#
# Lancer :
#   godot --headless --path . res://tools/tests/test_fin_zone.tscn --quit-after 20000

extends Node

const SCENE_MAIN := "res://scenes/main.tscn"
const ACCELERATION := 4.0

# Un faux PNJ « collé » à Kael : s'il est déclenché pendant une narration,
# c'est que deux systèmes ont réagi au même appui.
class FauxPnj extends Node3D:
	var appels: int = 0
	func obtenir_verbe() -> String:
		return "Tester"
	func declencher(_id_joueur: int) -> void:
		appels += 1

var _echecs: int = 0
var _main: Node = null

func _ready() -> void:
	print("--- Test fin de zone ---")
	Engine.time_scale = ACCELERATION

	# Une « vieille partie » déjà finie, pour vérifier la remise à zéro.
	GameManager.puzzle1_resolu = true
	GameManager.puzzle2_resolu = true
	GameManager.puzzle3_resolu = true
	GameManager.moralite_kael = 40

	# On lance main comme scène courante, MAIS ce nœud de test reste à côté,
	# sous la racine : quand main changera de scène vers le menu, seul main
	# sera détruit, et le test pourra continuer à observer.
	_main = load(SCENE_MAIN).instantiate()
	get_tree().root.add_child.call_deferred(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = _main
	_lancer()

func _lancer() -> void:
	var kael: Node3D = _main.get_node("Monde/Kael")
	var pnj := FauxPnj.new()
	kael.add_child(pnj)

	# ── 1. INTRO ──────────────────────────────────────────────────────────────
	_verifier("L'intro est lancee", str(_main.ecran_narration != null), "true")
	_verifier("Les joueurs sont figes", str(kael.controles_actifs), "false")
	_verifier("InteractionManager coupe pendant l'intro",
		str(InteractionManager.process_mode == Node.PROCESS_MODE_DISABLED), "true")

	await _attendre_que(func(): return _texte() == TextesNarration.INTRO[0], 5.0)
	_verifier("Premiere ligne de l'intro", _texte(), TextesNarration.INTRO[0])

	# Kael essaie de marcher : il ne doit pas bouger.
	var x_depart := kael.global_position.x
	Input.action_press("joueur1_droite")
	await _attendre(1.5)  # après le fondu d'entrée : on est dans la lecture
	Input.action_release("joueur1_droite")
	_verifier("Kael ne bouge pas pendant l'intro",
		"%.2f" % (kael.global_position.x - x_depart), "0.00")

	# Interagir passe la ligne… et rien d'autre.
	InteractionManager.enregistrer(1, pnj)
	await _appuyer("joueur1_interagir")
	_verifier("Interagir pendant l'intro ne declenche pas le PNJ", str(pnj.appels), "0")
	if TextesNarration.INTRO.size() > 1:
		await _attendre_que(func(): return _texte() == TextesNarration.INTRO[1], 5.0)
		_verifier("Interagir passe a la ligne suivante", _texte(), TextesNarration.INTRO[1])
	InteractionManager.retirer(1, pnj)

	await _passer_jusqua(func(): return _main.ecran_narration == null, 30.0)
	_verifier("L'intro se termine", str(_main.ecran_narration == null), "true")
	_verifier("Les joueurs reprennent la main", str(kael.controles_actifs), "true")
	_verifier("InteractionManager reactive",
		str(InteractionManager.process_mode == Node.PROCESS_MODE_INHERIT), "true")

	# ── 1 bis. ORDRE DES PUZZLES ─────────────────────────────────────────────
	# Le grimoire doit apparaître quel que soit le DERNIER puzzle résolu
	# (avant correction, seul le Puzzle 3 vérifiait la fin de zone).
	var zone1 = _main.get_node("Monde/Zone1")
	var zone_grimoire: Area3D = zone1.get_node("ZoneGrimoire")
	GameManager.puzzle1_resolu = false
	GameManager.puzzle2_resolu = false
	GameManager.puzzle3_resolu = true
	zone1._sur_puzzle3_resolu()   # P3 d'abord : rien ne doit se passer
	GameManager.puzzle1_resolu = true
	zone1._sur_puzzle1_resolu()
	await _attendre(4.0)
	_verifier("Pas de grimoire tant qu'un puzzle manque", str(zone_grimoire.monitoring), "false")
	GameManager.puzzle2_resolu = true
	zone1._sur_puzzle2_resolu()   # P2 en dernier : le grimoire doit apparaître
	zone1._sur_puzzle2_resolu()   # un second signal ne doit rien relancer
	await _attendre_que(func(): return zone_grimoire.monitoring, 10.0)
	_verifier("Grimoire revele quand P2 est resolu en dernier", str(zone_grimoire.monitoring), "true")
	_verifier("L'indice du grimoire s'affiche", str(DialogueManager.est_actif()), "true")
	await _passer_jusqua(func(): return not DialogueManager.est_actif(), 20.0)
	await _attendre(4.0)
	_verifier("L'indice n'est donne qu'une fois", str(DialogueManager.est_actif()), "false")
	zone_grimoire.monitoring = false

	# ── 2. CHOIX DU GRIMOIRE → FIN ───────────────────────────────────────────
	zone1._appliquer_choix("partager")
	_verifier("Le choix est enregistre", GameManager.choix_grimoire, "partager")
	_verifier("Le dialogue de resultat s'affiche", str(DialogueManager.est_actif()), "true")
	_verifier("Pas d'ecran de fin pendant le dialogue", str(_main.ecran_narration == null), "true")

	# On lit le dialogue jusqu'au bout (appui toutes les 0,8 s de jeu).
	await _passer_jusqua(func(): return not DialogueManager.est_actif(), 20.0)
	await get_tree().process_frame
	_verifier("Le dialogue fini lance l'ecran de fin", str(_main.ecran_narration != null), "true")

	# Pendant la fin aussi, interagir ne doit déclencher aucun PNJ.
	InteractionManager.enregistrer(1, pnj)
	await _attendre_que(func(): return _texte() == TextesNarration.FIN_PARTAGE[0], 10.0)
	_verifier("Texte de fin du choix « partager »", _texte(), TextesNarration.FIN_PARTAGE[0])

	await _passer_jusqua(func(): return _texte() == TextesNarration.FIN_COMMUNE[0], 30.0)
	_verifier("Puis le texte commun", _texte(), TextesNarration.FIN_COMMUNE[0])

	await _attendre_que(func(): return _main.ecran_narration._credits.visible, 60.0)
	_verifier("Puis les credits", str(_main.ecran_narration._credits.visible), "true")
	_verifier("Les credits contiennent toutes les lignes",
		str(_main.ecran_narration._credits.get_child_count()), str(TextesNarration.CREDITS.size()))
	_verifier("Interagir pendant la fin ne declenche pas le PNJ", str(pnj.appels), "0")

	# Les crédits finissent tout seuls (on ne les passe pas ici).
	var menu: Node = await _attendre_scene("MenuPrincipal", 120.0)

	# ── 3. RETOUR AU MENU ────────────────────────────────────────────────────
	_verifier("Retour au menu principal", str(menu != null), "true")
	if menu == null:
		_conclure()
		return
	await get_tree().process_frame
	var focus := menu.get_viewport().gui_get_focus_owner()
	_verifier("« Commencer » a le focus (manette)",
		(focus as Button).text if focus is Button else "aucun", "Commencer")
	_verifier("InteractionManager actif au menu",
		str(InteractionManager.process_mode == Node.PROCESS_MODE_INHERIT), "true")

	# A sur la manette = ui_accept : on l'envoie au menu comme un vrai appui.
	_envoyer_ui(menu, "ui_accept")
	var nouvelle_partie: Node = await _attendre_scene("Main", 10.0)
	_verifier("ui_accept sur Commencer relance une partie", str(nouvelle_partie != null), "true")
	_verifier("GameManager : puzzles remis a zero", str(GameManager.zone1_terminee()), "false")
	_verifier("GameManager : choix efface", GameManager.choix_grimoire, "")
	_verifier("GameManager : moralite remise a zero",
		"%d %d" % [GameManager.moralite_kael, GameManager.moralite_mira], "0 0")

	_conclure()

# ──────────────────────────────────────────────────────────────────────────────
# OUTILS
# ──────────────────────────────────────────────────────────────────────────────

func _texte() -> String:
	if _main == null or not is_instance_valid(_main) or _main.ecran_narration == null:
		return ""
	return _main.ecran_narration.texte_affiche()

# Appuie et relâche une action, calé sur le début d'une frame (voir test_interaction.gd).
func _appuyer(action: String) -> void:
	await get_tree().process_frame
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)
	await get_tree().process_frame

# Envoie une action d'interface (ui_accept, ui_down…) au système de focus,
# exactement comme le ferait une manette.
func _envoyer_ui(noeud: Node, action: String) -> void:
	for presse in [true, false]:
		var evenement := InputEventAction.new()
		evenement.action = action
		evenement.pressed = presse
		noeud.get_viewport().push_input(evenement)

# Appuie sur interagir régulièrement jusqu'à ce que la condition soit vraie.
func _passer_jusqua(condition: Callable, delai_max: float) -> void:
	var ecoule := 0.0
	while not condition.call() and ecoule < delai_max:
		await _appuyer("joueur1_interagir")
		await _attendre(0.8)
		ecoule += 0.8

func _attendre_que(condition: Callable, delai_max: float) -> void:
	var ecoule := 0.0
	while not condition.call() and ecoule < delai_max:
		await _attendre(0.1)
		ecoule += 0.1

func _attendre_scene(nom: String, delai_max: float) -> Node:
	var ecoule := 0.0
	while ecoule < delai_max:
		var scene := get_tree().current_scene
		if scene != null and scene.name == nom:
			return scene
		await _attendre(0.2)
		ecoule += 0.2
	return null

# Temps de JEU (accéléré par time_scale).
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
