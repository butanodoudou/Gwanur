# scripts/globals/dialogue_manager.gd
# AutoLoad (CanvasLayer) — affiche les dialogues PNJ et les messages système.
#
# Utilisation depuis n'importe où :
#   DialogueManager.afficher("Brennan", ["La roue s'est arrêtée...", "Comme si elle retenait quelque chose."])
#   DialogueManager.masquer()
#
# Navigation :
#   - Bouton interagir (joueur 1 ou 2) → ligne suivante
#   - Le timer auto-avance si personne n'appuie (fallback)

extends CanvasLayer

signal dialogue_fini

# Délai minimum avant de pouvoir avancer (évite le skip accidentel)
const DELAI_MIN: float = 0.6
# Délai auto-avance si personne n'appuie
const DELAI_AUTO: float = 5.0

var _panneau: Panel
var _label_nom: Label
var _label_texte: Label
var _label_suite: Label
var _lignes: Array[String] = []
var _index_ligne: int = 0
var _minuterie: float = 0.0
var _actif: bool = false
var _pret_a_avancer: bool = false

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

	_minuterie -= delta

	if _minuterie <= DELAI_AUTO - DELAI_MIN:
		_pret_a_avancer = true
		_label_suite.visible = true
		# Clignotement du "▶"
		_label_suite.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)

	# Bouton → avancer (dès que le délai min est passé)
	if _pret_a_avancer:
		if Input.is_action_just_pressed("joueur1_interagir") or Input.is_action_just_pressed("joueur2_interagir"):
			_afficher_prochaine_ligne()
			return

	# Auto-avance si le délai complet est écoulé
	if _minuterie <= 0.0:
		_afficher_prochaine_ligne()

func afficher(nom: String, lignes: Array[String]) -> void:
	_lignes = lignes
	_index_ligne = 0
	_label_nom.text = nom
	_panneau.visible = true
	_actif = true
	_afficher_prochaine_ligne()

func _afficher_prochaine_ligne() -> void:
	if _index_ligne >= _lignes.size():
		masquer()
		return
	_label_texte.text = _lignes[_index_ligne]
	_index_ligne += 1
	_minuterie = DELAI_AUTO
	_pret_a_avancer = false
	_label_suite.visible = false

func masquer() -> void:
	_actif = false
	_panneau.visible = false
	_lignes = []
	_index_ligne = 0
	_pret_a_avancer = false
	dialogue_fini.emit()
