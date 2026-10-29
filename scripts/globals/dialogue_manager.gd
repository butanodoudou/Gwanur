# scripts/globals/dialogue_manager.gd
# AutoLoad (CanvasLayer) — affiche les dialogues PNJ, les messages système, et
# les choix à deux joueurs (le grimoire).
#
# Utilisation depuis n'importe où :
#   DialogueManager.afficher("Brennan", ["La roue s'est arrêtée...", "Comme si elle retenait quelque chose."])
#   DialogueManager.masquer()
#
# Navigation :
#   - Bouton interagir (joueur 1 ou 2) → ligne suivante
#   - Le timer auto-avance si personne n'appuie (fallback)
#
# FILE D'ATTENTE
# Si un dialogue est déjà ouvert, afficher() ne l'écrase PAS : le nouveau
# message attend son tour et s'ouvre dès que le précédent est fini. Ainsi la
# stèle, l'écho de la liane… ne peuvent plus effacer le grimoire ou un indice.
# Un message identique à celui en cours (ou déjà en attente) n'est pas ajouté
# une deuxième fois : sonner trois fois la corne ne fait pas trois messages.
#
# Pour attendre la fin D'UN dialogue précis (et pas celle du dialogue en cours,
# qui peut être un autre), on garde le numéro que renvoie afficher() :
#   var numero := DialogueManager.afficher("", ["..."])
#   await DialogueManager.attendre_fin(numero)
#
# CHOIX À DEUX JOUEURS
#   DialogueManager.proposer_choix("Grimoire", "Kael (E) : garder · Mira (Entrée) : partager")
#   var id_joueur: int = await DialogueManager.choix_fait   # 1 = Kael, 2 = Mira
# Le panneau reste ouvert (pas d'auto-avance) jusqu'à ce qu'un joueur appuie
# sur interagir, et les appuis sont ignorés pendant DELAI_CHOIX secondes après
# l'apparition : un joueur qui « tapote A » pour lire ne choisit pas par erreur.
#
# Ce fichier et l'InteractionManager sont les SEULS à lire le bouton
# « interagir » pendant le jeu (règle d'or, voir CLAUDE.md).

extends CanvasLayer

# Émis à la fin de CHAQUE dialogue (même si un autre, en attente, s'ouvre juste après).
signal dialogue_fini
# Émis juste après l'affichage d'une nouvelle ligne (l'AudioManager y joue son « blip »).
signal ligne_affichee
# Émis quand un joueur a répondu à proposer_choix() : 1 = Kael, 2 = Mira.
signal choix_fait(id_joueur: int)

# Délai minimum avant de pouvoir avancer (évite le skip accidentel)
const DELAI_MIN: float = 0.6
# Délai auto-avance si personne n'appuie
const DELAI_AUTO: float = 5.0
# Délai pendant lequel un choix ignore les appuis (≥ DELAI_MIN, voir plus haut)
const DELAI_CHOIX: float = 0.8

var _panneau: Panel
var _label_nom: Label
var _label_texte: Label   # NE PAS RENOMMER : lu en repli par audio_manager.gd et par les tests
var _label_suite: Label
var _lignes: Array[String] = []
var _index_ligne: int = 0
var _minuterie: float = 0.0
var _actif: bool = false
var _pret_a_avancer: bool = false
# Numéro de la frame où le dialogue a consommé le bouton "interagir".
# Sert à empêcher un autre système de réagir au même appui (voir bloque_interaction).
var _frame_input_consomme: int = -1

# ── File d'attente ────────────────────────────────────────────────────────────
# Chaque entrée est un dictionnaire :
#   { "numero": 3, "nom": "Lira", "lignes": [...], "choix": false }
var _file: Array[Dictionary] = []
# L'entrée affichée en ce moment (vide si rien n'est affiché)
var _courant: Dictionary = {}
# Numéro donné au prochain dialogue, et numéro du dernier dialogue terminé.
# Les dialogues finissent dans l'ordre où on les a demandés, donc « le n°5 est
# fini » équivaut à « _dernier_fini >= 5 ».
var _prochain_numero: int = 1
var _dernier_fini: int = 0

func _ready() -> void:
	layer = 10
	_construire_ui()

func _construire_ui() -> void:
	_panneau = Panel.new()
	_panneau.anchor_left   = 0.05
	_panneau.anchor_right  = 0.95
	_panneau.anchor_top    = 0.78
	_panneau.anchor_bottom = 0.96
	_panneau.visible = false
	add_child(_panneau)

	_label_nom = Label.new()
	_label_nom.anchor_right = 1.0
	_label_nom.offset_top   = 8.0
	_label_nom.offset_left  = 14.0
	_label_nom.add_theme_font_size_override("font_size", 17)
	_label_nom.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	_panneau.add_child(_label_nom)

	_label_texte = Label.new()
	_label_texte.anchor_right  = 1.0
	_label_texte.anchor_bottom = 1.0
	_label_texte.offset_top    = 32.0
	_label_texte.offset_left   = 14.0
	_label_texte.offset_right  = -14.0
	_label_texte.offset_bottom = -10.0
	_label_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_texte.add_theme_font_size_override("font_size", 15)
	_panneau.add_child(_label_texte)

	# Indicateur "▶" en bas à droite — clignote quand on peut avancer
	_label_suite = Label.new()
	_label_suite.anchor_left   = 1.0
	_label_suite.anchor_right  = 1.0
	_label_suite.anchor_top    = 1.0
	_label_suite.anchor_bottom = 1.0
	_label_suite.offset_left   = -30.0
	_label_suite.offset_top    = -24.0
	_label_suite.text = "▶"
	_label_suite.add_theme_font_size_override("font_size", 14)
	_label_suite.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	_label_suite.visible = false
	_panneau.add_child(_label_suite)

func _process(delta: float) -> void:
	if not _actif:
		return

	if _courant.get("choix", false):
		_process_choix(delta)
		return

	_minuterie -= delta

	if _minuterie <= DELAI_AUTO - DELAI_MIN:
		_pret_a_avancer = true
		_label_suite.visible = true
		# Clignotement du "▶"
		_label_suite.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)

	# Bouton → avancer (dès que le délai min est passé)
	if _pret_a_avancer:
		if Input.is_action_just_pressed("joueur1_interagir") or Input.is_action_just_pressed("joueur2_interagir"):
			_frame_input_consomme = Engine.get_process_frames()
			_afficher_prochaine_ligne()
			return

	# Auto-avance si le délai complet est écoulé
	if _minuterie <= 0.0:
		_afficher_prochaine_ligne()

# Un choix n'avance jamais tout seul : on attend qu'un des deux joueurs appuie.
func _process_choix(delta: float) -> void:
	_minuterie += delta   # ici la minuterie compte le temps écoulé depuis l'apparition
	if _minuterie < DELAI_CHOIX:
		return
	var id_joueur := 0
	if Input.is_action_just_pressed("joueur1_interagir"):
		id_joueur = 1
	elif Input.is_action_just_pressed("joueur2_interagir"):
		id_joueur = 2
	if id_joueur == 0:
		return
	_frame_input_consomme = Engine.get_process_frames()
	# On ferme d'abord le panneau, PUIS on annonce le choix : celui qui écoute
	# choix_fait peut ainsi ouvrir aussitôt un nouveau dialogue.
	_terminer_courant()
	choix_fait.emit(id_joueur)

# Vrai si un dialogue (ou un choix) est ouvert à l'écran.
func est_actif() -> bool:
	return _actif

# Vrai si le bouton "interagir" appartient au dialogue en ce moment.
# Les autres systèmes (InteractionManager) doivent alors l'ignorer.
#
# Le test sur la frame couvre un cas précis : à la toute dernière ligne, l'appui
# ferme le dialogue et _actif repasse à false DANS LA MÊME FRAME. Sans ce test,
# l'InteractionManager verrait un bouton "libre" et relancerait la conversation.
func bloque_interaction() -> bool:
	return _actif or Engine.get_process_frames() == _frame_input_consomme

# Ouvre un dialogue, ou le met en file d'attente si un autre est déjà affiché.
# Renvoie son numéro (à passer à attendre_fin), ou 0 s'il était déjà prévu.
func afficher(nom: String, lignes: Array[String]) -> int:
	return _ajouter({ "nom": nom, "lignes": lignes, "choix": false })

# Ouvre un choix : `texte` doit présenter les DEUX options à la fois.
# La réponse arrive par le signal choix_fait(id_joueur).
func proposer_choix(nom: String, texte: String) -> int:
	var lignes: Array[String] = [texte]
	return _ajouter({ "nom": nom, "lignes": lignes, "choix": true })

# Attend la fin du dialogue n° `numero` (rend la main tout de suite s'il est déjà fini).
func attendre_fin(numero: int) -> void:
	while _dernier_fini < numero:
		await dialogue_fini

func _ajouter(entree: Dictionary) -> int:
	if _deja_prevu(entree):
		return 0
	entree["numero"] = _prochain_numero
	_prochain_numero += 1
	if _actif:
		_file.append(entree)
	else:
		_ouvrir(entree)
	return entree["numero"]

# Même nom et mêmes lignes qu'un message en cours ou en attente ?
func _deja_prevu(entree: Dictionary) -> bool:
	var candidats: Array = _file.duplicate()
	if _actif:
		candidats.append(_courant)
	for autre in candidats:
		if autre["nom"] == entree["nom"] and autre["lignes"] == entree["lignes"] \
				and autre["choix"] == entree["choix"]:
			return true
	return false

func _ouvrir(entree: Dictionary) -> void:
	_courant = entree
	_lignes = entree["lignes"]
	_index_ligne = 0
	_label_nom.text = entree["nom"]
	_panneau.visible = true
	_actif = true
	# L'appui qui a ouvert ce dialogue ne doit rien déclencher d'autre.
	_frame_input_consomme = Engine.get_process_frames()
	_afficher_prochaine_ligne()
	if entree["choix"]:
		_minuterie = 0.0   # compte le temps écoulé (voir _process_choix)
		_label_suite.visible = false

func _afficher_prochaine_ligne() -> void:
	if _index_ligne >= _lignes.size():
		_terminer_courant()
		return
	_label_texte.text = _lignes[_index_ligne]
	ligne_affichee.emit()
	_index_ligne += 1
	_minuterie = DELAI_AUTO
	_pret_a_avancer = false
	_label_suite.visible = false

# Le dialogue affiché est fini : on ouvre le suivant de la file, ou on ferme.
func _terminer_courant() -> void:
	_dernier_fini = _courant.get("numero", _dernier_fini)
	_courant = {}
	if _file.is_empty():
		_fermer_panneau()
	else:
		# On ouvre le suivant AVANT d'émettre dialogue_fini : celui qui attend
		# « plus aucun dialogue » (while est_actif()) voit qu'il en reste un.
		_ouvrir(_file.pop_front())
	dialogue_fini.emit()

func _fermer_panneau() -> void:
	_actif = false
	_panneau.visible = false
	_label_texte.text = ""
	_label_nom.text = ""
	_lignes = []
	_index_ligne = 0
	_pret_a_avancer = false
	_label_suite.visible = false

# Ferme TOUT : le dialogue en cours et ceux en attente (changement de scène,
# retour au menu…). Les dialogues en attente comptent comme finis, pour que
# personne ne reste bloqué dans un attendre_fin().
func masquer() -> void:
	_file.clear()
	_courant = {}
	_dernier_fini = _prochain_numero - 1
	_fermer_panneau()
	dialogue_fini.emit()
