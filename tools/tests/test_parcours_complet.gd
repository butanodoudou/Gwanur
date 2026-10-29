# tools/tests/test_parcours_complet.gd
# Test de bout en bout de la Zone 1 : charge la VRAIE scène main.tscn et joue
# la zone entière en simulant les deux joueurs.
#
#   0. Démarrage         — nœuds présents, personnages posés au sol
#   1. Contrôles avant les PNJ — Puzzle 3 sans Brennan, Puzzle 2 sans Lira
#   2. PNJ               — Vaenmor, Lira, Brennan (dialogue lu jusqu'au bout)
#   3. Puzzle 1          — porte double : un seul joueur ne l'ouvre pas, lâcher
#                          réinitialise, appui simultané, puis ouverture
#   4. Puzzle 2          — oiseau : Mira trop lente → reset, puis réussite
#   5. Puzzle 3          — roue d'eau : Kael seul / lanterne éteinte échouent,
#                          puis lanterne + lianes → résolu
#   6. Grimoire          — apparaît, se lit jusqu'au bout, choix, GameManager,
#                          puis écran de fin → crédits → retour au menu
#   7. Nouvelle partie   — « Commencer » au menu : GameManager, dialogues et
#                          InteractionManager repartent de zéro
#
# COMMENT ON SIMULE LES JOUEURS
#   - On TÉLÉPORTE Kael et Mira, mais jamais dans un mur : _placer_dans()
#     cherche un endroit où la capsule du personnage tient debout SANS toucher
#     de collision, et qui chevauche la zone visée. S'il n'y en a aucun, c'est
#     que la zone est inaccessible en vrai jeu → ECHEC.
#   - Les appuis passent par Input.action_press/action_release, comme une
#     vraie manette : le bouton "interagir" est lu par InteractionManager, les
#     skills par kael.gd / mira.gd.
#
# TROIS SORTES DE LIGNES
#   OK    : le comportement attendu est là
#   ECHEC : le parcours est cassé (compté dans le résultat)
#   BUG   : défaut connu, rapporté par le testeur, qui ne casse pas le parcours.
#           Non compté par défaut — avec `-- --strict`, chaque BUG compte comme
#           un ECHEC (utile quand les correctifs sont fusionnés).
#
# TEXTES : on ne recopie pas les phrases du scénariste (elles changent). On
# compare aux constantes du code (zone1.INDICE_GRIMOIRE, TextesNarration…) ou
# on vérifie qu'un message nomme le bon jumeau / le bon objet.
#
# Lancer (≈ 2 min 30 : le Puzzle 2 attend deux fois ses 12 secondes, puis la fin) :
#   godot --headless --path . res://tools/tests/test_parcours_complet.tscn --quit-after 200000
# Options :
#   -- --strict            les BUG comptent comme des ECHEC
#   -- --choix=secret      Kael fait le choix du grimoire (par défaut : Mira, "partager")

extends Node

# Nom de la touche « interagir » affiché pour chaque joueur (E / Entrée / A).
const TouchesJoueur = preload("res://scripts/ui/touches_joueur.gd")
const SCENE_MENU := "res://scenes/menu_principal.tscn"
const SCENE_MAIN := "res://scenes/main.tscn"

var _echecs: int = 0
var _bugs: int = 0
var _strict: bool = false
var _choix_voulu: String = "partager"

var _scene: Node
var _zone: Node3D
var _kael: CharacterBody3D
var _mira: CharacterBody3D
var _hud_kael
var _hud_mira
var _p1: Node3D
var _p2: Node3D
var _p3: Node3D

# Compteurs branchés sur les signaux des personnages : prouvent que l'appui
# simulé est bien arrivé jusqu'au skill.
var _cornes: int = 0
var _lianes: int = 0
# Toutes les lignes de dialogue affichées depuis le début (signal ligne_affichee).
# Avec la file d'attente du DialogueManager, un message peut s'afficher un peu
# plus tard que l'action qui l'a provoqué : on vérifie qu'il est PASSÉ à l'écran.
var _lignes_vues: Array[String] = []

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_strict = args.has("--strict")
	if args.has("--choix=secret"):
		_choix_voulu = "secret"

	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	for i in 60:
		await get_tree().physics_frame
	await get_tree().process_frame

	print("=== Test de parcours complet — Zone 1 ===")
	if not _etape_demarrage():
		_conclure()
		return
	await _etape_controles_sans_pnj()
	await _etape_pnj()
	await _etape_puzzle1()
	await _etape_puzzle2()
	await _etape_puzzle3()
	await _etape_grimoire()
	await _etape_nouvelle_partie()
	_conclure()

# ══════════════════════════════════════════════════════════════════════════════
# 0. DÉMARRAGE
# ══════════════════════════════════════════════════════════════════════════════

func _etape_demarrage() -> bool:
	print("--- 0. Demarrage ---")
	var chemins := [
		"Monde/Kael", "Monde/Mira", "Monde/Zone1",
		"Monde/Zone1/Puzzle1PorteDouble", "Monde/Zone1/Puzzle2Oiseau",
		"Monde/Zone1/Puzzle3RoueEau", "Monde/Zone1/ZoneGrimoire", "Monde/Zone1/ZoneStele",
		"Monde/Zone1/PNJ/Vaenmor", "Monde/Zone1/PNJ/Lira", "Monde/Zone1/PNJ/Brennan",
		"SplitScreen/Conteneur/VueKael/SubViewport/HudKael",
		"SplitScreen/Conteneur/VueMira/SubViewport/HudMira",
	]
	var tout_present := true
	for chemin in chemins:
		if _scene.get_node_or_null(chemin) == null:
			tout_present = false
			_verifier("Noeud present : " + chemin, "absent", "present")
	_verifier("Tous les noeuds attendus sont presents", str(tout_present), "true")
	if not tout_present:
		return false

	_zone = _scene.get_node("Monde/Zone1")
	_kael = _scene.get_node("Monde/Kael")
	_mira = _scene.get_node("Monde/Mira")
	_hud_kael = _scene.get_node("SplitScreen/Conteneur/VueKael/SubViewport/HudKael")
	_hud_mira = _scene.get_node("SplitScreen/Conteneur/VueMira/SubViewport/HudMira")
	_p1 = _zone.get_node("Puzzle1PorteDouble")
	_p2 = _zone.get_node("Puzzle2Oiseau")
	_p3 = _zone.get_node("Puzzle3RoueEau")
	_kael.corne_sonnee.connect(func(): _cornes += 1)
	_kael.lianes_invoquees.connect(func(_p): _lianes += 1)
	DialogueManager.ligne_affichee.connect(func(): _lignes_vues.append(DialogueManager._label_texte.text))

	_verifier("GameManager part de zero",
		str([GameManager.puzzle1_resolu, GameManager.puzzle2_resolu, GameManager.puzzle3_resolu,
			GameManager.choix_grimoire]), str([false, false, false, ""]))

	# Les personnages doivent être posés sur le sol du village, pas perchés.
	_constater("Kael demarre au sol (et pas sur le cylindre invisible du saule)",
		_hauteur_sol(_kael) < 0.5,
		"Kael est a %.1f m au-dessus du sol : le spawn (-1,1,5) tombe sur le cylindre de collision du saule central, car Zone1 est decalee dans main.tscn" % _hauteur_sol(_kael))
	_constater("Mira demarre au sol", _hauteur_sol(_mira) < 0.5,
		"Mira est a %.1f m au-dessus du sol" % _hauteur_sol(_mira))

	# La porte et la grille doivent fermer le passage vers le nord, sinon les
	# Puzzles 1 et 2 ne servent à rien. On tire des rayons sud→nord à côté.
	var contournements: Array = []
	for x in [-10.0, -6.0, 6.0, 10.0]:
		if _rayon_libre(Vector3(x, 1.0, -15.0), Vector3(x, 1.0, -50.0)):
			contournements.append(x)
	_constater("La porte (z=-36) et la grille (z=-26) ferment le passage nord",
		contournements.is_empty(),
		"on passe librement de z=-15 a z=-50 aux x=%s : la palissade (zone1.gd:133-134) est orientee nord-sud au lieu d'est-ouest" % str(contournements))
	return true

# ══════════════════════════════════════════════════════════════════════════════
# 1. CONTRÔLES AVANT D'AVOIR PARLÉ AUX PNJ
# ══════════════════════════════════════════════════════════════════════════════

func _etape_controles_sans_pnj() -> void:
	print("--- 1. Controles avant les PNJ (prerequis Lira / Brennan) ---")

	# ── Puzzle 3 sans Brennan ────────────────────────────────────────────────
	await _placer_dans(_mira, _p3.get_node("ZoneLanterne"))
	await _placer_dans(_kael, _p3.get_node("ZoneLianes"))
	await _skill("joueur2_skill2")   # Mira allume sa lanterne
	_verifier("La lanterne de Mira s'allume (appui Y)", str(_mira.lanterne_allumee), "true")
	var dialogue_lanterne := DialogueManager.est_actif()
	await _skill("joueur1_skill1")   # Kael : brassards
	_verifier("Les brassards de Kael repondent (appui X)", str(_lianes), "1")
	_verifier("Sans Brennan, la roue NE tourne PAS", str(_p3.resolu), "false")
	_verifier("Sans Brennan, le joueur recoit un retour (dialogue ou message)",
		str(dialogue_lanterne or DialogueManager.est_actif() or GameManager.etat_coop != ""), "true")
	_verifier("Sans Brennan, le message oriente vers le meunier",
		str(_vu("Brennan")), "true")
	await _skill("joueur2_skill2")   # on éteint
	await _fermer_dialogues()

	# ── Puzzle 2 sans Lira ───────────────────────────────────────────────────
	await _placer_pres_oiseau(_kael)
	await _skill("joueur1_skill2")   # corne
	_verifier("La corne de Kael repond (appui Y)", str(_cornes), "1")
	if _p2.EXIGER_LIRA:
		_verifier("Sans Lira, l'oiseau ne repond pas encore (prerequis du design)",
			str(_p2.oiseau_attire), "false")
		_verifier("Sans Lira, un message oriente vers elle", str(_vu("Lira")), "true")
	else:
		print("  INFO : prerequis de Lira desactive (puzzle_oiseau.gd EXIGER_LIRA = false)")
	if _p2.oiseau_attire:
		# On profite du cycle lancé pour vérifier le reset « Mira trop lente ».
		await _cycle_oiseau_trop_lent()
	await _fermer_dialogues()

# ══════════════════════════════════════════════════════════════════════════════
# 2. PNJ
# ══════════════════════════════════════════════════════════════════════════════

func _etape_pnj() -> void:
	print("--- 2. PNJ ---")
	await _parler_a(_kael, 1, "PNJ/Vaenmor", "vaenmor_parle")
	await _parler_a(_mira, 2, "PNJ/Lira", "lira_parlee")
	await _parler_a(_kael, 1, "PNJ/Brennan", "brennan_parle")

	# ── Deux joueurs appuient en même temps sur le même PNJ ─────────────────
	var lira: Node3D = _zone.get_node("PNJ/Lira")
	await _placer_dans(_kael, lira.get_node("ZoneProximite"))
	await _placer_dans(_mira, lira.get_node("ZoneProximite"))
	await _appuyer_les_deux()
	_verifier("Deux appuis simultanes sur Lira ouvrent UN dialogue a la ligne 1",
		DialogueManager._label_texte.text if DialogueManager.est_actif() else "(aucun dialogue)", lira.lignes[0])
	if DialogueManager._label_nom.text != "Lira" or not DialogueManager.est_actif():
		_diagnostic()
	await _fermer_dialogues()

	# ── La stèle lue pendant un dialogue ─────────────────────────────────────
	# Kael parle à Caeryn, Mira passe devant la stèle au même moment.
	var caeryn: Node3D = _zone.get_node("PNJ/Caeryn")
	await _eloigner(_mira)
	await _placer_dans(_kael, caeryn.get_node("ZoneProximite"))
	await _appuyer("joueur1_interagir")
	_verifier("Caeryn parle", DialogueManager._label_nom.text if DialogueManager.est_actif() else "(aucun dialogue)", "Caeryn")
	if not DialogueManager.est_actif():
		_diagnostic()
	await _placer_dans(_mira, _zone.get_node("ZoneStele"))
	_verifier("La stele n'ecrase pas un dialogue deja ouvert (elle attend son tour)",
		DialogueManager._label_nom.text, "Caeryn")
	await _fermer_dialogues()
	await _eloigner(_kael)
	await _eloigner(_mira)

# Place le joueur près du PNJ, vérifie le prompt, ouvre le dialogue et le lit
# jusqu'au bout en comptant les appuis.
func _parler_a(perso: CharacterBody3D, id: int, chemin: String, flag: String) -> void:
	var pnj: Node3D = _zone.get_node(chemin)
	var hud = _hud_kael if id == 1 else _hud_mira
	var accessible := await _placer_dans(perso, pnj.get_node("ZoneProximite"))
	_verifier("%s est accessible a pied (zone de dialogue atteignable)" % pnj.nom_pnj,
		str(accessible), "true")
	if accessible:
		_verifier("Prompt '(A)  Parler a %s'" % pnj.nom_pnj,
			hud._label_prompt.text if hud._label_prompt.visible else "(aucun prompt)",
			"(A)  Parler à " + pnj.nom_pnj)
		await _appuyer("joueur%d_interagir" % id)
	else:
		# CONTOURNEMENT pour que la suite du parcours reste testable : on
		# déclenche le PNJ comme le ferait l'InteractionManager.
		print("         (contournement : %s.declencher() appele directement)" % pnj.nom_pnj)
		pnj.declencher(id)
	_verifier("Le dialogue de %s s'ouvre" % pnj.nom_pnj, DialogueManager._label_nom.text, pnj.nom_pnj)
	var nb_lignes: int = pnj.lignes.size()
	var appuis := await _lire_jusquau_bout("joueur%d_interagir" % id)
	_verifier("%s : %d lignes lues en %d appuis, sans relance" % [pnj.nom_pnj, nb_lignes, nb_lignes],
		str(appuis), str(nb_lignes))
	_verifier("GameManager.%s" % flag, str(GameManager.get(flag)), "true")
	_verifier("L'indicateur '!' de %s a disparu" % pnj.nom_pnj, str(pnj._label_indicateur.visible), "false")
	await _eloigner(perso)

# ══════════════════════════════════════════════════════════════════════════════
# 3. PUZZLE 1 — LA PORTE À DEUX POIGNÉES
# ══════════════════════════════════════════════════════════════════════════════

func _etape_puzzle1() -> void:
	print("--- 3. Puzzle 1 : la porte a deux poignees ---")
	var poignee_k: Area3D = _p1.get_node("ZoneInteractionKael")
	var poignee_m: Area3D = _p1.get_node("ZoneInteractionMira")
	var porte: Node3D = _p1.get_node("Porte")
	var y_porte: float = porte.position.y

	# Kael seul
	await _placer_dans(_kael, poignee_k)
	_verifier("Prompt de Kael sur sa poignee", _prompt(_hud_kael), "(%s)  Tirer la poignée gauche" % TouchesJoueur.interagir(1))
	await _appuyer("joueur1_interagir")
	_verifier("Kael tient sa poignee", str(_p1.kael_pret), "true")
	await _attendre(2.0)
	_verifier("NEGATIF : Kael seul n'ouvre pas la porte (2 s plus tard)", str(_p1.resolu), "false")
	_verifier("Etat coop : Mira est appelee", GameManager.etat_coop, "Kael tient sa poignée — Mira, prends l'autre !")

	# Kael lâche en s'éloignant → sa moitié est réinitialisée
	await _eloigner(_kael)
	_verifier("Kael s'eloigne : il lache sa poignee", str(_p1.kael_pret), "false")
	_verifier("Etat coop efface quand plus personne ne tient", GameManager.etat_coop, "")

	# Mira seule
	await _placer_dans(_mira, poignee_m)
	await _appuyer("joueur2_interagir")
	_verifier("Mira tient sa poignee", str(_p1.mira_prete), "true")
	_verifier("NEGATIF : Mira seule n'ouvre pas la porte", str(_p1.resolu), "false")
	await _eloigner(_mira)
	_verifier("Mira s'eloigne : elle lache sa poignee", str(_p1.mira_prete), "false")

	# Les deux appuient dans la même frame
	await _placer_dans(_kael, poignee_k)
	await _placer_dans(_mira, poignee_m)
	await _appuyer_les_deux()
	# Une fois les deux prises, la porte s'ouvre aussitôt : `resolu` le prouve.
	_verifier("Appui simultane : les DEUX poignees sont prises (la porte s'ouvre)",
		str(_p1.resolu), "true")
	if not _p1.resolu:
		await _fermer_dialogues()
		if not _p1.kael_pret:
			await _appuyer("joueur1_interagir")
		if not _p1.mira_prete:
			await _appuyer("joueur2_interagir")

	_verifier("Puzzle 1 resolu", str(_p1.resolu), "true")
	_verifier("GameManager.puzzle1_resolu", str(GameManager.puzzle1_resolu), "true")
	_verifier("Etat coop efface", GameManager.etat_coop, "")
	_verifier("Le message du puzzle (la porte qui se leve) reste lisible",
		str(DialogueManager.est_actif() and DialogueManager._label_texte.text.contains("porte")), "true")
	await _attendre(2.0)
	_verifier("La porte est montee de 3.5 m", str(porte.position.y > y_porte + 3.4), "true")
	_verifier("Les poignees n'affichent plus de prompt", str(InteractionManager.cible_pour(1) == poignee_k), "false")
	await _fermer_dialogues()
	await _eloigner(_kael)
	await _eloigner(_mira)

# ══════════════════════════════════════════════════════════════════════════════
# 4. PUZZLE 2 — L'OISEAU ET LE PASSAGE
# ══════════════════════════════════════════════════════════════════════════════

var _reset_oiseau_verifie: bool = false

func _etape_puzzle2() -> void:
	print("--- 4. Puzzle 2 : l'oiseau et le passage ---")
	var verrou: Area3D = _p2.get_node("ZoneVerrou")

	# Le verrou n'est pas proposé tant que la grille est fermée
	await _placer_dans(_mira, verrou)
	_verifier("Grille fermee : pas de prompt sur le verrou",
		str(InteractionManager.cible_pour(2) == verrou), "false")

	# La corne porte à PORTEE_CORNE mètres, mesurés au sol
	_mesurer_zone_corne()
	await _corne_hors_de_portee()

	if not _reset_oiseau_verifie:
		await _placer_pres_oiseau(_kael)
		await _skill("joueur1_skill2")
		_verifier("La corne attire l'oiseau", str(_p2.oiseau_attire), "true")
		await _cycle_oiseau_trop_lent()

	# ── Cycle réussi ─────────────────────────────────────────────────────────
	var grille: Node3D = _p2.get_node("Grille")
	var y_grille: float = grille.position.y
	await _placer_pres_oiseau(_kael)
	await _skill("joueur1_skill2")
	_verifier("La corne attire l'oiseau (2e essai)", str(_p2.oiseau_attire), "true")
	var ouverte := await _attendre_que(func(): return _p2.grille_ouverte, 10.0)
	_verifier("L'oiseau se pose et la grille s'ouvre", str(ouverte), "true")
	if not ouverte:
		return
	# L'état coop (pas un dialogue : il bloquerait le verrou) appelle Mira.
	_verifier("L'ouverture est annoncee aux deux joueurs par l'etat coop, qui appelle Mira",
		str(GameManager.etat_coop.contains("Mira")), "true")
	_verifier("Aucun dialogue ne bloque le verrou pendant les 12 s", str(DialogueManager.est_actif()), "false")

	# Relancer le puzzle pendant le compte à rebours ne doit rien casser
	await _attendre(1.0)
	var minuterie_avant: float = _p2._minuterie_fermeture
	await _skill("joueur1_skill2")
	_verifier("Corne pendant le compte a rebours : la minuterie n'est pas relancee",
		str(_p2._minuterie_fermeture <= minuterie_avant), "true")
	await _attendre(1.2)
	_verifier("Puis le compte a rebours en secondes",
		str(GameManager.etat_coop.contains(" s ")), "true")

	# Mira passe sous la grille levée et rejoint le verrou.
	await _placer_dans(_mira, verrou)
	_verifier("Le prompt du verrou est visible pour Mira",
		_prompt(_hud_mira), "(%s)  Verrouiller le passage" % TouchesJoueur.interagir(2))
	await _appuyer("joueur2_interagir")
	_verifier("Un seul appui de Mira au verrou suffit pendant le compte a rebours",
		str(_p2.verrou_active), "true")
	if not _p2.verrou_active:
		await _fermer_dialogues("joueur2_interagir")
		_verifier("Apres le dialogue, le prompt du verrou est visible pour Mira",
			_prompt(_hud_mira), "(%s)  Verrouiller le passage" % TouchesJoueur.interagir(2))
		await _appuyer("joueur2_interagir")

	_verifier("Puzzle 2 resolu (verrou dans les 12 s)", str(_p2.resolu), "true")
	_verifier("GameManager.puzzle2_resolu", str(GameManager.puzzle2_resolu), "true")
	_verifier("Etat coop efface", GameManager.etat_coop, "")
	await _attendre(13.0)
	_verifier("La grille reste ouverte apres 13 s", str(grille.position.y > y_grille + 3.4), "true")
	await _fermer_dialogues()
	await _eloigner(_kael)
	await _eloigner(_mira)

# Mira ne vient pas : la grille doit se refermer et l'oiseau revenir.
func _cycle_oiseau_trop_lent() -> void:
	var grille: Node3D = _p2.get_node("Grille")
	var oiseau: Node3D = _p2.get_node("Oiseau")
	var y_grille: float = grille.position.y
	var perchoir: Vector3 = _p2.position_perchoir
	await _eloigner(_mira)
	var ouverte := await _attendre_que(func(): return _p2.grille_ouverte, 10.0)
	_verifier("NEGATIF Mira trop lente : la grille s'est d'abord ouverte", str(ouverte), "true")
	var fermee := await _attendre_que(func(): return not _p2.grille_ouverte, 14.0)
	_verifier("NEGATIF Mira trop lente : la grille se referme apres 12 s", str(fermee), "true")
	_verifier("NEGATIF : l'oiseau est revenu sur son perchoir", str(oiseau.global_position.is_equal_approx(perchoir)), "true")
	_verifier("NEGATIF : le puzzle n'est pas resolu", str(GameManager.puzzle2_resolu), "false")
	_verifier("NEGATIF : le verrou n'est plus propose", str(_p2.zone_verrou._disponible), "false")
	_verifier("NEGATIF : le compte a rebours est efface", GameManager.etat_coop, "")
	await _attendre(1.3)
	_verifier("NEGATIF : la grille est revenue a sa hauteur d'origine",
		str(absf(grille.position.y - y_grille) < 0.05), "true")
	_reset_oiseau_verifie = true
	await _fermer_dialogues()

# Combien de sol libre permet à Kael d'atteindre l'oiseau avec sa corne ?
# La portée se mesure à l'horizontale (puzzle_oiseau.gd → _distance_au_sol).
func _mesurer_zone_corne() -> void:
	var oiseau: Vector3 = _p2.get_node("Oiseau").global_position
	var portee: float = _p2.PORTEE_CORNE
	var pas := 0.25
	var n := 0
	var x := -portee
	while x <= portee:
		var z := -portee
		while z <= portee:
			var pied := Vector3(oiseau.x + x, _sol_y(), oiseau.z + z)
			if Vector2(x, z).length() <= portee and _libre(pied):
				n += 1
			z += pas
		x += pas
	var surface: float = n * pas * pas
	_verifier("La corne s'utilise depuis une zone de sol confortable (> 4 m2, %.0f m2 mesures)" % surface,
		str(surface > 4.0), "true")

# Kael sonne trop loin de l'oiseau (mais près du puzzle) : un message le guide.
func _corne_hors_de_portee() -> void:
	var oiseau: Vector3 = _p2.get_node("Oiseau").global_position
	var distance: float = (_p2.PORTEE_CORNE + _p2.DISTANCE_INDICE) * 0.5
	var pied := Vector3.INF
	# On cherche un point libre à `distance` mètres, en tournant autour de l'oiseau.
	for i in 24:
		var angle: float = TAU * i / 24.0
		var essai := Vector3(oiseau.x + sin(angle) * distance, _sol_y(), oiseau.z + cos(angle) * distance)
		if _libre(essai, _kael):
			pied = essai
			break
	if pied == Vector3.INF:
		print("  INFO : aucun point libre a %.0f m de l'oiseau, controle 'hors de portee' saute" % distance)
		return
	await _teleporter(_kael, pied)
	var vues_avant: int = _lignes_vues.size()
	await _skill("joueur1_skill2")
	_verifier("Corne hors de portee : l'oiseau ne bouge pas", str(_p2.oiseau_attire), "false")
	_verifier("Corne hors de portee : un message dit a Kael de s'approcher",
		str(_lignes_vues.slice(vues_avant).any(func(l): return l.contains("approche"))), "true")
	await _fermer_dialogues()

# ══════════════════════════════════════════════════════════════════════════════
# 5. PUZZLE 3 — LA ROUE D'EAU
# ══════════════════════════════════════════════════════════════════════════════

func _etape_puzzle3() -> void:
	print("--- 5. Puzzle 3 : la roue d'eau ---")
	var zone_lanterne: Area3D = _p3.get_node("ZoneLanterne")
	var zone_lianes: Area3D = _p3.get_node("ZoneLianes")
	var echo: Node3D = _p3.get_node("EchoLiane")

	# Kael seul, Mira loin
	await _eloigner(_mira)
	await _placer_dans(_kael, zone_lianes)
	await _skill("joueur1_skill1")
	_verifier("NEGATIF : Kael seul (Mira absente) ne fait pas tourner la roue", str(_p3.resolu), "false")
	_verifier("Kael seul : un indice appelle Mira et sa Lanterne",
		str(DialogueManager._label_texte.text.contains("Mira") and DialogueManager._label_texte.text.contains("Lanterne")), "true")
	await _fermer_dialogues()

	# Mira dans la zone mais lanterne éteinte
	await _placer_dans(_mira, zone_lanterne)
	await _skill("joueur1_skill1")
	_verifier("NEGATIF : lanterne eteinte, la roue ne tourne pas", str(_p3.resolu), "false")
	_verifier("Lanterne eteinte : l'indice reclame la Lanterne",
		str(DialogueManager._label_texte.text.contains("Lanterne")), "true")
	await _fermer_dialogues()

	# Lanterne allumée AVANT d'entrer dans la zone, puis Mira entre
	await _eloigner(_mira)
	await _skill("joueur2_skill2")
	await _placer_dans(_mira, zone_lanterne)
	_verifier("Mira entre dans la zone lanterne deja allumee : l'echo apparait",
		str(echo.visible), "true")
	await _skill("joueur2_skill2")   # éteint
	await _fermer_dialogues()

	# Le bon geste : Mira allume dans la zone, Kael fait pousser
	await _skill("joueur2_skill2")
	_verifier("Lanterne allumee dans la zone : l'echo de la liane apparait", str(echo.visible), "true")
	_verifier("Mira recoit l'indice de l'echo (la liane fantome)",
		str(DialogueManager._label_texte.text.contains("liane")), "true")
	await _fermer_dialogues()
	await _skill("joueur1_skill1")
	_verifier("Puzzle 3 resolu", str(_p3.resolu), "true")
	_verifier("GameManager.puzzle3_resolu", str(GameManager.puzzle3_resolu), "true")
	_verifier("Les trois puzzles sont resolus (zone1_terminee)", str(GameManager.zone1_terminee()), "true")

	# Après la résolution, rallumer la lanterne ne doit plus rien raconter
	await _attendre(0.3)
	var vues_avant: int = _lignes_vues.size()
	await _skill("joueur2_skill2")   # éteint
	await _skill("joueur2_skill2")   # rallume
	await _attendre(0.3)
	_verifier("Apres resolution, la lanterne ne fait plus reapparaitre l'echo",
		str(echo.visible or _lignes_vues.slice(vues_avant).any(func(l): return l.contains("fantôme"))), "false")
	await _skill("joueur2_skill2")   # éteint
	await _eloigner(_mira)

# ══════════════════════════════════════════════════════════════════════════════
# 6. GRIMOIRE ET CHOIX DE FIN DE ZONE
# ══════════════════════════════════════════════════════════════════════════════

func _etape_grimoire() -> void:
	print("--- 6. Grimoire, choix et ecran de fin ---")
	var zone_grimoire: Area3D = _zone.get_node("ZoneGrimoire")
	if not GameManager.zone1_terminee():
		_verifier("Prerequis grimoire : zone terminee", "false", "true")
		return

	# main.tscn est ici un ENFANT du test. À la fin, main.gd appelle
	# change_scene_to_file(menu), qui détruit la « scène courante ». On en
	# fait un leurre : c'est lui qui sera détruit, pas ce test.
	var leurre := Node.new()
	leurre.name = "Leurre"
	get_tree().root.add_child(leurre)
	get_tree().current_scene = leurre

	var annonce := await _attendre_que(func(): return zone_grimoire.monitoring, 6.0)
	_verifier("Le grimoire s'active ~3 s apres le dernier puzzle", str(annonce), "true")
	var indice_vu := await _attendre_que(func(): return _lignes_vues.has(_zone.INDICE_GRIMOIRE[0]), 15.0, true)
	_verifier("Une annonce indique ou chercher (zone1.INDICE_GRIMOIRE)", str(indice_vu), "true")
	await _fermer_dialogues()

	# Kael entre dans la vieille maison
	var accessible := await _placer_dans(_kael, zone_grimoire)
	_verifier("Le grimoire est accessible a pied", str(accessible), "true")
	var ouvert := await _attendre_que(func(): return DialogueManager._label_nom.text == "Grimoire d'Aelindra" and DialogueManager.est_actif(), 2.0)
	_verifier("Le grimoire s'ouvre en entrant dans la zone", str(ouvert), "true")
	if not ouvert:
		return
	var premiere_ligne: String = DialogueManager._label_texte.text
	var nb_lignes: int = DialogueManager._lignes.size()
	# On s'arrête dès que le choix apparaît (sinon on appuierait dedans).
	var appuis := await _lire_jusquau_bout("joueur1_interagir", true)
	_verifier("Grimoire lu jusqu'au bout (%d lignes)" % nb_lignes, str(appuis), str(nb_lignes))

	# Le choix s'affiche aussitôt, les DEUX options ensemble
	var choix_affiche := await _attendre_que(func(): return _zone._attente_choix and _choix_en_cours(), 2.0)
	_verifier("La question du choix s'affiche", str(choix_affiche), "true")
	var texte_choix: String = DialogueManager._label_texte.text
	_verifier("Les deux options sont affichees ensemble",
		str(texte_choix.contains("Garder") and texte_choix.contains("confier")), "true")
	_verifier("Le texte du choix nomme la bonne touche pour chaque joueur",
		str(texte_choix.contains("Kael (%s)" % TouchesJoueur.interagir(1))
			and texte_choix.contains("Mira (%s)" % TouchesJoueur.interagir(2))), "true")

	# Choix fait presque aussitôt (0.1 s) : un joueur qui « tapote A » pour lire
	await _attendre(0.1)
	var id_choix: int = 1 if _choix_voulu == "secret" else 2
	await _appuyer("joueur%d_interagir" % id_choix)
	_verifier("Un appui 0.1 s apres l'affichage de la question n'est PAS pris pour un choix",
		GameManager.choix_grimoire, "")

	# Ré-entrer dans la zone ne relance pas le grimoire
	await _eloigner(_kael)
	await _placer_dans(_kael, zone_grimoire)
	_verifier("Re-entrer dans la vieille maison ne relance pas le grimoire",
		str(_choix_en_cours() and DialogueManager._label_texte.text != premiere_ligne), "true")

	# Le vrai choix, après le délai de protection
	await _attendre(0.8)
	await _appuyer("joueur%d_interagir" % id_choix)
	_verifier("Choix enregistre", GameManager.choix_grimoire, _choix_voulu)
	var attendu_moralite: int = -10 if _choix_voulu == "secret" else 10
	_verifier("Moralite de Kael", str(GameManager.moralite_kael), str(attendu_moralite))
	_verifier("Moralite de Mira", str(GameManager.moralite_mira), str(attendu_moralite))
	_verifier("Le choix n'est plus attendu", str(_zone._attente_choix), "false")
	var mot_cle: String = "refermez" if _choix_voulu == "secret" else "emportez"
	_verifier("Le dialogue de consequence s'affiche ('%s')" % mot_cle,
		str(DialogueManager._label_texte.text.contains(mot_cle)), "true")
	_verifier("La barre de moralite de Kael apparait", str(_hud_kael._bloc_moralite.modulate.a > 0.0 or _hud_kael._temps_restant > 0.0), "true")

	# Un second appui (l'autre joueur) ne change plus rien
	await _attendre(0.7)
	await _appuyer("joueur%d_interagir" % (3 - id_choix))
	_verifier("Le second joueur ne peut plus changer le choix", GameManager.choix_grimoire, _choix_voulu)
	await _fermer_dialogues()
	await _attendre(0.5)
	_verifier("Le choix n'est pas repropose apres la conclusion", str(DialogueManager.est_actif()), "false")
	_verifier("Puzzles + choix dans GameManager",
		str([GameManager.puzzle1_resolu, GameManager.puzzle2_resolu, GameManager.puzzle3_resolu, GameManager.choix_grimoire]),
		str([true, true, true, _choix_voulu]))

	# ── Écran de fin → crédits → retour au menu ──────────────────────────────
	var fin_lancee := await _attendre_que(func(): return _scene.ecran_narration != null, 5.0)
	_verifier("L'ecran de fin apparait apres le dialogue de consequence", str(fin_lancee), "true")
	if not fin_lancee:
		return
	_verifier("InteractionManager suspendu pendant la fin", str(InteractionManager.est_suspendu()), "true")
	# On passe les lignes (interagir) et on note tout ce qui s'affiche.
	var textes_fin: Array[String] = []
	var debut := Time.get_ticks_msec()
	var dernier_appui := debut
	while Time.get_ticks_msec() - debut < 180000:
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path == SCENE_MENU:
			break
		if is_instance_valid(_scene) and _scene.ecran_narration != null:
			var t: String = _scene.ecran_narration.texte_affiche()
			if t != "" and not textes_fin.has(t):
				textes_fin.append(t)
		if Time.get_ticks_msec() - dernier_appui > 500:
			dernier_appui = Time.get_ticks_msec()
			await _appuyer("joueur1_interagir")
		else:
			await get_tree().process_frame
	var fin_choix: Array[String] = TextesNarration.FIN_SECRET if _choix_voulu == "secret" else TextesNarration.FIN_PARTAGE
	_verifier("Texte de fin du choix '%s'" % _choix_voulu, str(textes_fin.has(fin_choix[0])), "true")
	_verifier("Puis le texte commun", str(textes_fin.has(TextesNarration.FIN_COMMUNE[0])), "true")
	var menu = get_tree().current_scene
	_verifier("La fin ramene au menu principal",
		menu.scene_file_path if menu != null else "(aucune scene)", SCENE_MENU)
	_verifier("Aucun dialogue ouvert au menu", str(DialogueManager.est_actif()), "false")
	# L'ancienne partie (enfant du test) disparaît, comme en vrai jeu.
	_scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_verifier("InteractionManager actif au menu", str(InteractionManager.est_suspendu()), "false")

# ══════════════════════════════════════════════════════════════════════════════
# 7. NOUVELLE PARTIE
# ══════════════════════════════════════════════════════════════════════════════

# Au menu, « Commencer » : exactement le chemin du vrai jeu (GameManager.
# reinitialiser() puis change_scene_to_file(main)).
func _etape_nouvelle_partie() -> void:
	print("--- 7. Nouvelle partie (menu -> Commencer) ---")
	var menu = get_tree().current_scene
	if menu == null or menu.scene_file_path != SCENE_MENU:
		_verifier("Le menu est affiche pour relancer une partie", "non", "oui")
		return
	# Une cible fantôme laissée par l'ancienne partie doit être oubliée.
	var fantome := Node3D.new()
	InteractionManager.enregistrer(1, fantome)
	menu._sur_commencer()
	var relancee := await _attendre_que(_main_est_la_scene, 5.0)
	_verifier("Commencer relance main.tscn", str(relancee), "true")
	_verifier("Une nouvelle partie repart avec un GameManager vierge",
		str([GameManager.puzzle1_resolu, GameManager.puzzle2_resolu, GameManager.puzzle3_resolu,
			GameManager.choix_grimoire, GameManager.moralite_kael, GameManager.moralite_mira]),
		str([false, false, false, "", 0, 0]))
	_verifier("Aucun dialogue ne survit au changement de scene", str(DialogueManager.est_actif()), "false")
	_verifier("InteractionManager a oublie les cibles de l'ancienne partie",
		str(InteractionManager._cibles[1].has(fantome)), "false")
	fantome.free()

func _main_est_la_scene() -> bool:
	var sc := get_tree().current_scene
	return sc != null and sc.scene_file_path == SCENE_MAIN

# ══════════════════════════════════════════════════════════════════════════════
# OUTILS — DÉPLACEMENTS
# ══════════════════════════════════════════════════════════════════════════════

# Hauteur des pieds au-dessus du sol du village (le sol de la zone est à y=0 local)
func _hauteur_sol(perso: Node3D) -> float:
	return perso.global_position.y - _sol_y()

func _sol_y() -> float:
	return _zone.global_position.y

# Vrai si la capsule d'un personnage tient debout à cet endroit sans toucher
# aucune collision (mur, maison, tronc…).
func _libre(pied: Vector3, seul_ignore: Node3D = null) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	q.shape = capsule
	q.transform = Transform3D(Basis(), pied + Vector3(0, 0.95, 0))
	# Par défaut on ignore les deux héros. Pour placer UN héros, on n'ignore que
	# lui : il ne doit pas atterrir dans l'autre (deux capsules superposées
	# s'éjectent mutuellement).
	if seul_ignore != null:
		q.exclude = [(seul_ignore as CollisionObject3D).get_rid()]
	else:
		q.exclude = [_kael.get_rid(), _mira.get_rid()]
	return _zone.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()

# Vrai si un personnage debout à `pied` est détecté par la sphère de l'aire.
func _chevauche(aire: Area3D, pied: Vector3) -> bool:
	var cs: CollisionShape3D = aire.get_child(0)
	var centre := cs.global_position
	var rayon: float = (cs.shape as SphereShape3D).radius
	var bas := pied + Vector3(0, 0.3, 0)
	var t: float = clampf(centre.y - bas.y, 0.0, 1.2)
	return (bas + Vector3(0, t, 0)).distance_to(centre) < rayon + 0.3 - 0.05

# Cherche le point libre le plus proche du centre de l'aire, y téléporte le
# personnage et laisse la physique détecter l'entrée. Faux si inaccessible.
func _placer_dans(perso: CharacterBody3D, aire: Area3D) -> bool:
	var c := aire.global_position
	var rayon: float = ((aire.get_child(0) as CollisionShape3D).shape as SphereShape3D).radius + 0.3
	var meilleur := Vector3.INF
	var meilleure_d := INF
	var x := -rayon
	while x <= rayon:
		var z := -rayon
		while z <= rayon:
			var pied := Vector3(c.x + x, _sol_y(), c.z + z)
			var d := Vector2(x, z).length()
			if d < meilleure_d and _chevauche(aire, pied) and _libre(pied, perso):
				meilleure_d = d
				meilleur = pied
			z += 0.25
		x += 0.25
	if meilleur == Vector3.INF:
		return false
	await _teleporter(perso, meilleur)
	return true

# Kael se poste au point de sol libre le plus proche de l'oiseau.
func _placer_pres_oiseau(perso: CharacterBody3D) -> void:
	var o: Vector3 = _p2.get_node("Oiseau").global_position
	var meilleur := Vector3.INF
	var x := -8.0
	while x <= 8.0:
		var z := -8.0
		while z <= 8.0:
			var pied := Vector3(o.x + x, _sol_y(), o.z + z)
			if pied.distance_to(o) < meilleur.distance_to(o) and _libre(pied, perso):
				meilleur = pied
			z += 0.1
		x += 0.1
	await _teleporter(perso, meilleur)

# Ramène un personnage sur la place du village, loin de toute zone interactive.
func _eloigner(perso: CharacterBody3D) -> void:
	var local := Vector3(-3.0, 0.0, -14.0) if perso == _kael else Vector3(3.0, 0.0, -18.0)
	await _teleporter(perso, _zone.to_global(local))

func _teleporter(perso: CharacterBody3D, pied: Vector3) -> void:
	perso.velocity = Vector3.ZERO
	perso.global_position = pied + Vector3(0, 0.05, 0)
	for i in 12:
		await get_tree().physics_frame
	await get_tree().process_frame

func _rayon_libre(local_a: Vector3, local_b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(_zone.to_global(local_a), _zone.to_global(local_b))
	q.exclude = [_kael.get_rid(), _mira.get_rid()]
	return _zone.get_world_3d().direct_space_state.intersect_ray(q).is_empty()

# ══════════════════════════════════════════════════════════════════════════════
# OUTILS — APPUIS ET ATTENTES
# ══════════════════════════════════════════════════════════════════════════════

# Bouton lu dans un _process (interagir) — même méthode que les autres tests.
func _appuyer(action: String) -> void:
	await get_tree().process_frame
	Input.action_press(action)
	await get_tree().process_frame
	Input.action_release(action)
	await get_tree().process_frame

func _appuyer_les_deux() -> void:
	await get_tree().process_frame
	Input.action_press("joueur1_interagir")
	Input.action_press("joueur2_interagir")
	await get_tree().process_frame
	Input.action_release("joueur1_interagir")
	Input.action_release("joueur2_interagir")
	await get_tree().process_frame

# Bouton lu dans un _physics_process (skills de Kael et Mira). On appuie juste
# après le signal physics_frame : le pas physique qui suit voit l'appui comme
# « just pressed ».
func _skill(action: String) -> void:
	await get_tree().physics_frame
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)
	await get_tree().process_frame

# Lit un dialogue jusqu'à sa fermeture, en respectant le délai minimum de 0.6 s.
# Retourne le nombre d'appuis qu'il a fallu. Avec `stop_au_choix`, on s'arrête
# dès qu'un choix (proposer_choix) s'affiche, sans appuyer dedans.
func _lire_jusquau_bout(action: String, stop_au_choix: bool = false) -> int:
	var appuis := 0
	while DialogueManager.est_actif() and appuis < 40:
		if stop_au_choix and _choix_en_cours():
			break
		await _attendre(0.7)
		await _appuyer(action)
		appuis += 1
	return appuis

func _fermer_dialogues(action: String = "joueur1_interagir") -> void:
	await _lire_jusquau_bout(action, true)

# Vrai si le DialogueManager affiche un choix (et pas un simple dialogue).
func _choix_en_cours() -> bool:
	return DialogueManager.est_actif() and DialogueManager._courant.get("choix", false)

# Vrai si une ligne contenant `mot` s'est affichée depuis le début du test.
func _vu(mot: String) -> bool:
	return _lignes_vues.any(func(l): return l.contains(mot))

func _attendre(secondes: float) -> void:
	await get_tree().create_timer(secondes).timeout

# Avec `lire_dialogues`, on fait défiler les dialogues ouverts pendant l'attente
# (pour atteindre un message qui attend son tour dans la file).
func _attendre_que(condition: Callable, delai_max: float, lire_dialogues: bool = false) -> bool:
	var fin := Time.get_ticks_msec() + int(delai_max * 1000.0)
	var prochain_appui := Time.get_ticks_msec() + 700
	while Time.get_ticks_msec() < fin:
		if condition.call():
			return true
		if lire_dialogues and DialogueManager.est_actif() and not _choix_en_cours() \
				and Time.get_ticks_msec() > prochain_appui:
			prochain_appui = Time.get_ticks_msec() + 700
			await _appuyer("joueur1_interagir")
		else:
			await get_tree().process_frame
	return condition.call()

func _prompt(hud) -> String:
	return hud._label_prompt.text if hud._label_prompt.visible else "(aucun prompt)"

# ══════════════════════════════════════════════════════════════════════════════
# OUTILS — RAPPORT
# ══════════════════════════════════════════════════════════════════════════════

func _verifier(quoi: String, obtenu, attendu) -> void:
	if str(obtenu) == str(attendu):
		print("  OK   : %s" % quoi)
	else:
		_echecs += 1
		print("  ECHEC: %s  (attendu '%s', obtenu '%s')" % [quoi, attendu, obtenu])

# Imprime l'état des systèmes d'interaction quand un appui n'a rien produit.
func _diagnostic() -> void:
	var c1 = InteractionManager.cible_pour(1)
	var c2 = InteractionManager.cible_pour(2)
	print("         diag : dialogue actif=%s bloque=%s | cible Kael=%s cible Mira=%s | Kael local=%s Mira local=%s" % [
		DialogueManager.est_actif(), DialogueManager.bloque_interaction(),
		c1.name if c1 else "aucune", c2.name if c2 else "aucune",
		_zone.to_local(_kael.global_position).snapped(Vector3.ONE * 0.1),
		_zone.to_local(_mira.global_position).snapped(Vector3.ONE * 0.1)])
	print("         diag : cibles enregistrees J1=%s J2=%s" % [
		InteractionManager._cibles[1].map(func(n): return n.name if is_instance_valid(n) else "<libere>"),
		InteractionManager._cibles[2].map(func(n): return n.name if is_instance_valid(n) else "<libere>")])

# Défaut connu : n'arrête pas le parcours. Compte comme ECHEC avec --strict.
func _constater(quoi: String, condition: bool, detail: String) -> void:
	if condition:
		print("  OK   : %s" % quoi)
		return
	_bugs += 1
	if _strict:
		_echecs += 1
		print("  ECHEC: %s — %s" % [quoi, detail])
	else:
		print("  BUG  : %s — %s" % [quoi, detail])

func _conclure() -> void:
	print("=== %d BUG(S) connu(s) signale(s)%s ===" % [_bugs, " (comptes en ECHEC : --strict)" if _strict else ""])
	if _echecs == 0:
		print("--- RESULTAT : tout est OK ---")
	else:
		print("--- RESULTAT : %d ECHEC(S) ---" % _echecs)
	get_tree().quit()
