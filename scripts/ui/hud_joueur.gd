# scripts/ui/hud_joueur.gd
# HUD d'UN seul joueur.
#
# Ce nœud vit À L'INTÉRIEUR du SubViewport de son joueur (voir main.tscn), donc
# tout ce qu'il affiche ne s'affiche que dans sa moitié d'écran. C'est ce qui
# permet à Kael et Mira d'avoir chacun leur propre indicateur sans se marcher
# dessus.
#
# Il affiche deux choses :
#   1. Le prompt d'interaction  — "(A) Parler à Lira", en bas, quand on est à portée
#   2. Le curseur de moralité   — en haut à gauche, seulement quand il vient de bouger
#
# Tout est construit en code, comme le menu principal et la boîte de dialogue.
# Il n'y a donc rien à configurer dans l'éditeur à part id_joueur.

extends Control

@export var id_joueur: int = 1

# Combien de temps la barre de moralité reste pleinement visible après un changement
const DUREE_VISIBLE: float = 3.0
# Durée du fondu de disparition qui suit
const DUREE_FONDU: float = 1.0

const LARGEUR_RAIL: float = 190.0
const COULEUR_ACCENT := Color(1.0, 0.85, 0.5)
const COULEUR_DISCRETE := Color(0.65, 0.58, 0.45)

var _label_prompt: Label
var _bloc_moralite: Control
var _rail: ColorRect
var _curseur: ColorRect
var _label_pole_gauche: Label
var _label_pole_droit: Label

# Temps restant avant que la barre de moralité soit complètement effacée
var _temps_restant: float = 0.0

func _ready() -> void:
	# Le HUD est purement décoratif — il ne doit jamais intercepter la souris
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_construire_prompt()
	_construire_moralite()

	GameManager.moralite_changee.connect(_sur_moralite_changee)

# ──────────────────────────────────────────────────────────────────────────────
# CONSTRUCTION DE L'INTERFACE
# ──────────────────────────────────────────────────────────────────────────────

func _construire_prompt() -> void:
	_label_prompt = Label.new()
	_label_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ancré en bas, sur toute la largeur de la vue, au-dessus de la boîte de dialogue
	_label_prompt.anchor_left   = 0.0
	_label_prompt.anchor_right  = 1.0
	_label_prompt.anchor_top    = 1.0
	_label_prompt.anchor_bottom = 1.0
	_label_prompt.offset_top    = -300.0
	_label_prompt.offset_bottom = -258.0
	_label_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_prompt.add_theme_font_size_override("font_size", 18)
	_label_prompt.add_theme_color_override("font_color", COULEUR_ACCENT)
	# Contour sombre pour rester lisible sur un décor clair
	_label_prompt.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.05))
	_label_prompt.add_theme_constant_override("outline_size", 6)
	_label_prompt.visible = false
	add_child(_label_prompt)

func _construire_moralite() -> void:
	# Conteneur transparent en haut à gauche — on fait varier SON alpha pour le fondu
	_bloc_moralite = Control.new()
	_bloc_moralite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bloc_moralite.offset_left   = 28.0
	_bloc_moralite.offset_top    = 26.0
	_bloc_moralite.offset_right  = 28.0 + LARGEUR_RAIL
	_bloc_moralite.offset_bottom = 26.0 + 42.0
	_bloc_moralite.modulate.a = 0.0
	add_child(_bloc_moralite)

	var poles := _poles_du_joueur()

	_label_pole_gauche = _creer_label_pole(poles[0], HORIZONTAL_ALIGNMENT_LEFT)
	_bloc_moralite.add_child(_label_pole_gauche)

	_label_pole_droit = _creer_label_pole(poles[1], HORIZONTAL_ALIGNMENT_RIGHT)
	_bloc_moralite.add_child(_label_pole_droit)

	# Le rail : une fine ligne horizontale
	_rail = ColorRect.new()
	_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rail.color = Color(COULEUR_DISCRETE.r, COULEUR_DISCRETE.g, COULEUR_DISCRETE.b, 0.55)
	_rail.position = Vector2(0.0, 26.0)
	_rail.size = Vector2(LARGEUR_RAIL, 2.0)
	_bloc_moralite.add_child(_rail)

	# Le curseur : un petit trait vertical qui glisse le long du rail
	_curseur = ColorRect.new()
	_curseur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curseur.color = COULEUR_ACCENT
	_curseur.size = Vector2(3.0, 12.0)
	_bloc_moralite.add_child(_curseur)

	_placer_curseur(_valeur_actuelle())

func _creer_label_pole(texte: String, alignement: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = texte
	label.size = Vector2(LARGEUR_RAIL, 18.0)
	label.horizontal_alignment = alignement
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", COULEUR_DISCRETE)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.05))
	label.add_theme_constant_override("outline_size", 5)
	return label

# Kael : Instinct ↔ Raison    /    Mira : Méfiance ↔ Confiance
func _poles_du_joueur() -> Array:
	if id_joueur == 1:
		return ["Instinct", "Raison"]
	return ["Méfiance", "Confiance"]

func _valeur_actuelle() -> int:
	if id_joueur == 1:
		return GameManager.moralite_kael
	return GameManager.moralite_mira

# ──────────────────────────────────────────────────────────────────────────────
# MISE À JOUR
# ──────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_maj_prompt()
	_maj_moralite(delta)

func _maj_prompt() -> void:
	# Pendant un dialogue, le bouton sert à lire la suite — pas à interagir.
	if DialogueManager.est_actif():
		_label_prompt.visible = false
		return

	var cible := InteractionManager.cible_pour(id_joueur)
	if cible == null:
		_label_prompt.visible = false
		return

	_label_prompt.text = "(A)  " + cible.obtenir_verbe()
	_label_prompt.visible = true

func _maj_moralite(delta: float) -> void:
	if _temps_restant <= 0.0:
		return

	_temps_restant -= delta

	# Pleine opacité pendant DUREE_VISIBLE, puis fondu progressif vers 0
	if _temps_restant > DUREE_FONDU:
		_bloc_moralite.modulate.a = 1.0
	else:
		_bloc_moralite.modulate.a = max(_temps_restant / DUREE_FONDU, 0.0)

func _sur_moralite_changee(id: int, valeur: int) -> void:
	# On ignore le curseur de l'autre joueur — chacun ne voit que le sien
	if id != id_joueur:
		return
	_placer_curseur(valeur)
	_temps_restant = DUREE_VISIBLE + DUREE_FONDU

# Convertit une valeur de -100..+100 en position horizontale sur le rail
func _placer_curseur(valeur: int) -> void:
	var ratio: float = (float(valeur) + 100.0) / 200.0
	var x: float = ratio * (LARGEUR_RAIL - _curseur.size.x)
	_curseur.position = Vector2(x, 21.0)
