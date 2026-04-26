# scripts/globals/dialogue_manager.gd
# AutoLoad (CanvasLayer) — affiche les dialogues PNJ et les messages système.
#
# Utilisation depuis n'importe où :
#   DialogueManager.afficher("Brennan", ["La roue s'est arrêtée...", "Comme si elle retenait quelque chose."])
#   DialogueManager.masquer()

extends CanvasLayer

# Délai entre chaque ligne de dialogue (secondes)
const DELAI_LIGNE: float = 3.5

var _panneau: Panel
var _label_nom: Label
var _label_texte: Label
var _lignes: Array[String] = []
var _index_ligne: int = 0
var _minuterie: float = 0.0
var _actif: bool = false

func _ready() -> void:
	layer = 10  # Au-dessus de tout
	_construire_ui()

# Construit le panneau de dialogue en code (pas de .tscn séparé nécessaire)
func _construire_ui() -> void:
	_panneau = Panel.new()
	_panneau.anchor_left = 0.1
	_panneau.anchor_right = 0.9
	_panneau.anchor_top = 0.8
	_panneau.anchor_bottom = 0.95
	_panneau.visible = false
	add_child(_panneau)

	_label_nom = Label.new()
	_label_nom.anchor_right = 1.0
	_label_nom.offset_top = 5.0
	_label_nom.offset_left = 10.0
	_label_nom.add_theme_font_size_override("font_size", 18)
	_panneau.add_child(_label_nom)

	_label_texte = Label.new()
	_label_texte.anchor_right = 1.0
	_label_texte.anchor_bottom = 1.0
	_label_texte.offset_top = 30.0
	_label_texte.offset_left = 10.0
	_label_texte.offset_right = -10.0
	_label_texte.offset_bottom = -5.0
	_label_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_texte.add_theme_font_size_override("font_size", 16)
	_panneau.add_child(_label_texte)

func _process(delta: float) -> void:
	if not _actif:
		return
	_minuterie -= delta
	if _minuterie <= 0.0:
		_afficher_prochaine_ligne()

# Affiche une séquence de lignes avec le nom du personnage
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
	_minuterie = DELAI_LIGNE

func masquer() -> void:
	_actif = false
	_panneau.visible = false
	_lignes = []
	_index_ligne = 0
