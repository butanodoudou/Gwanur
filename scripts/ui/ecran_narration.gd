# scripts/ui/ecran_narration.gd
# Écran de narration plein écran : fond noir, texte en fondu, crédits qui défilent.
# Sert à l'intro (Acte 0) ET à la fin de zone — c'est main.gd qui enchaîne les étapes.
# Construit entièrement en code, comme menu_principal.gd.
#
# UTILISATION (depuis main.gd, qui le charge avec preload())
#   var ecran := EcranNarration.new()
#   add_child(ecran)
#   ecran.noir_immediat()                          # ou : await ecran.fondu_vers_noir(2.0)
#   await ecran.afficher_lignes(TextesNarration.INTRO)
#   await ecran.fondu_depuis_noir(1.5)
#
# `await` attend que la fonction ait fini (le fondu, la lecture des lignes…)
# avant de passer à la suite, sans bloquer le reste du jeu.
#
# PASSER UNE LIGNE
# Le bouton « interagir » de n'importe quel joueur passe à la ligne suivante.
# Cet écran lit donc le bouton lui-même : c'est sans danger UNIQUEMENT parce que
# main.gd suspend l'InteractionManager pendant toute la narration
# (InteractionManager.suspendre(), voir main.gd → _figer_jeu). Sinon, un appui
# pour passer une ligne pourrait aussi lancer une conversation avec un PNJ
# proche — le bug historique du projet. C'est l'UNIQUE exception à la règle
# d'or « seuls InteractionManager et DialogueManager lisent interagir » : elle
# est acceptable car les deux autres lecteurs sont alors muets (Interaction-
# Manager suspendu, et aucun dialogue n'est ouvert pendant la narration).
#
# PAUSE
# Cet écran s'arrête quand le jeu est en pause (comportement par défaut d'un
# nœud) : les fondus et les minuteries attendent la fin de la pause.

extends CanvasLayer

# ── Réglages ─────────────────────────────────────────────────────────────────
const DUREE_APPARITION: float = 1.0    # fondu d'entrée d'une ligne
const DUREE_DISPARITION: float = 0.8   # fondu de sortie d'une ligne
const DUREE_LECTURE_MIN: float = 2.5   # temps de lecture d'une ligne courte
const DUREE_PAR_CARACTERE: float = 0.05  # + un peu de temps par lettre
# On ne peut pas passer une ligne pendant ce délai : évite qu'un appui
# accidentel (ou le même appui que celui qui a fermé un dialogue) saute tout.
const DELAI_AVANT_PASSER: float = 0.4
const VITESSE_CREDITS: float = 60.0    # défilement, en pixels par seconde

const COULEUR_TEXTE = Color(0.95, 0.88, 0.70)   # même or doux que le titre du menu

var _fond: ColorRect
var _texte: Label
var _credits: VBoxContainer

func _ready() -> void:
	# Au-dessus du split-screen (layer 1) et des dialogues (layer 10) ;
	# en dessous du menu pause (layer 20).
	layer = 15
	_construire_ui()

func _construire_ui() -> void:
	# Fond noir plein écran, transparent au départ.
	_fond = ColorRect.new()
	_fond.color = Color.BLACK
	_fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fond.modulate.a = 0.0
	# Le fond ne doit pas avaler les clics de souris destinés au jeu.
	_fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fond)

	# Une ligne de texte centrée.
	_texte = Label.new()
	_texte.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texte.offset_left  = 200.0
	_texte.offset_right = -200.0
	_texte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texte.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texte.add_theme_font_size_override("font_size", 32)
	_texte.add_theme_color_override("font_color", COULEUR_TEXTE)
	_texte.modulate.a = 0.0
	add_child(_texte)

	# Colonne des crédits, remplie par defiler_credits().
	_credits = VBoxContainer.new()
	_credits.anchor_left  = 0.0
	_credits.anchor_right = 1.0
	_credits.add_theme_constant_override("separation", 14)
	_credits.visible = false
	add_child(_credits)

# ──────────────────────────────────────────────────────────────────────────────
# FOND NOIR
# ──────────────────────────────────────────────────────────────────────────────

# Noir tout de suite, sans fondu (début de l'intro : on ne voit jamais le monde
# avant le premier texte).
func noir_immediat() -> void:
	_fond.modulate.a = 1.0

# L'écran s'assombrit jusqu'au noir complet.
func fondu_vers_noir(duree: float) -> void:
	await _fondu(_fond, 1.0, duree)

# Le noir se lève et laisse voir le jeu.
func fondu_depuis_noir(duree: float) -> void:
	await _fondu(_fond, 0.0, duree)

# ──────────────────────────────────────────────────────────────────────────────
# LIGNES DE TEXTE
# ──────────────────────────────────────────────────────────────────────────────

# Affiche les lignes l'une après l'autre : fondu d'entrée, lecture, fondu de sortie.
# Chaque ligne avance toute seule, ou plus tôt si un joueur appuie sur interagir.
func afficher_lignes(lignes: Array[String]) -> void:
	for ligne in lignes:
		_texte.text = ligne
		await _fondu(_texte, 1.0, DUREE_APPARITION)
		var duree_lecture := DUREE_LECTURE_MIN + ligne.length() * DUREE_PAR_CARACTERE
		await _attendre_ou_passer(duree_lecture)
		await _fondu(_texte, 0.0, DUREE_DISPARITION)
	_texte.text = ""

# Texte actuellement affiché (utile aux tests).
func texte_affiche() -> String:
	return _texte.text

# ──────────────────────────────────────────────────────────────────────────────
# CRÉDITS
# ──────────────────────────────────────────────────────────────────────────────

# Les crédits montent doucement du bas de l'écran jusqu'à disparaître en haut.
# Une chaîne vide "" fait une ligne vide. Interagir les termine plus tôt.
func defiler_credits(lignes: Array[String]) -> void:
	for ligne in lignes:
		var label := Label.new()
		# Un espace plutôt que "" : un Label vide n'a pas de hauteur.
		label.text = ligne if ligne != "" else " "
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", COULEUR_TEXTE)
		_credits.add_child(label)

	# Laisse une frame au conteneur pour calculer sa hauteur.
	_credits.visible = true
	await get_tree().process_frame
	var hauteur_ecran: float = get_viewport().get_visible_rect().size.y
	var hauteur_credits: float = _credits.get_combined_minimum_size().y

	# Départ : juste sous le bas de l'écran. Arrivée : juste au-dessus du haut.
	_credits.position.y = hauteur_ecran
	var arrivee := -hauteur_credits
	var duree := (hauteur_ecran + hauteur_credits) / VITESSE_CREDITS

	var tween := create_tween()
	tween.tween_property(_credits, "position:y", arrivee, duree)
	var ecoule := 0.0
	while tween.is_valid() and tween.is_running():
		await get_tree().process_frame
		if get_tree().paused:
			continue
		ecoule += get_process_delta_time()
		if ecoule > DELAI_AVANT_PASSER and _interagir_presse():
			tween.kill()
			break
	_credits.visible = false

# ──────────────────────────────────────────────────────────────────────────────
# OUTILS
# ──────────────────────────────────────────────────────────────────────────────

# Fait varier l'opacité d'un nœud jusqu'à `alpha`, en `duree` secondes.
# create_tween() lie le fondu à CE nœud : il se met en pause avec le jeu.
func _fondu(noeud: CanvasItem, alpha: float, duree: float) -> void:
	var tween := create_tween()
	tween.tween_property(noeud, "modulate:a", alpha, duree)
	await tween.finished

# Attend `duree` secondes, ou moins si un joueur appuie sur interagir.
# On compte le temps nous-mêmes, frame par frame, pour pouvoir écouter le
# bouton pendant l'attente. Le temps ne s'écoule pas pendant la pause.
func _attendre_ou_passer(duree: float) -> void:
	var ecoule := 0.0
	while ecoule < duree:
		# process_frame est émis au DÉBUT de chaque frame, avant les _process() :
		# Input.is_action_just_pressed() est donc fiable juste après.
		await get_tree().process_frame
		if get_tree().paused:
			continue
		ecoule += get_process_delta_time()
		if ecoule > DELAI_AVANT_PASSER and _interagir_presse():
			return

func _interagir_presse() -> bool:
	return Input.is_action_just_pressed("joueur1_interagir") \
		or Input.is_action_just_pressed("joueur2_interagir")
