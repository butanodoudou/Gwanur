# scripts/ui/menu_pause.gd
# Menu pause — Reprendre / Menu principal / Quitter.
# Échap, ou le bouton Start de n'importe quelle manette (action "pause" dans
# project.godot), ouvre et ferme le menu.
# Construit en code et ajouté par main.gd (pas besoin de le placer dans main.tscn).
#
# COMMENT MARCHE LA PAUSE DANS GODOT
# get_tree().paused = true arrête tous les nœuds dont le process_mode vaut
# « PAUSABLE » ou « INHERIT » (le défaut) : personnages, PNJ, dialogues,
# InteractionManager… Ce menu, lui, est en PROCESS_MODE_ALWAYS : il continue
# de tourner pendant la pause, sinon personne ne pourrait la lever.

extends CanvasLayer

const SCENE_MENU := "res://scenes/menu_principal.tscn"

var _racine: Control
var _btn_reprendre: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Au-dessus de tout : jeu (1), dialogues (10), écran de narration (15).
	layer = 20
	_construire_ui()
	_racine.visible = false

func _construire_ui() -> void:
	_racine = Control.new()
	_racine.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_racine)

	# Voile sombre sur le jeu figé.
	var voile := ColorRect.new()
	voile.color = Color(0.06, 0.05, 0.04, 0.75)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	_racine.add_child(voile)

	var vbox := VBoxContainer.new()
	vbox.anchor_left   = 0.35
	vbox.anchor_right  = 0.65
	vbox.anchor_top    = 0.32
	vbox.anchor_bottom = 0.8
	vbox.add_theme_constant_override("separation", 20)
	_racine.add_child(vbox)

	var titre := Label.new()
	titre.text = "Pause"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 48)
	titre.add_theme_color_override("font_color", Color(0.95, 0.85, 0.60))
	vbox.add_child(titre)

	var espace := Control.new()
	espace.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(espace)

	_btn_reprendre = _ajouter_bouton(vbox, "Reprendre", _sur_reprendre)
	_ajouter_bouton(vbox, "Menu principal", _sur_menu_principal)
	_ajouter_bouton(vbox, "Quitter", _sur_quitter)

func _ajouter_bouton(parent: Control, texte: String, action: Callable) -> Button:
	var bouton := Button.new()
	bouton.text = texte
	bouton.custom_minimum_size = Vector2(0, 52)
	bouton.add_theme_font_size_override("font_size", 22)
	bouton.pressed.connect(action)
	parent.add_child(bouton)
	return bouton

# On lit l'action dans _process (et pas dans _input) pour une raison simple :
# Input.is_action_just_pressed() marche aussi avec les appuis simulés des tests.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if est_ouvert():
			_sur_reprendre()
		else:
			ouvrir()

func est_ouvert() -> bool:
	return _racine.visible

func ouvrir() -> void:
	get_tree().paused = true
	_racine.visible = true
	# Le focus permet de naviguer à la croix / au stick et de valider avec A.
	_btn_reprendre.grab_focus()

func _sur_reprendre() -> void:
	_racine.visible = false
	# Le focus quitte le bouton : sinon Entrée (= interagir de J2) le
	# re-déclencherait pendant le jeu.
	_btn_reprendre.release_focus()
	# On attend UNE frame avant de relancer le jeu. Le bouton A sert à la fois
	# à valider « Reprendre » et à interagir (joueur1_interagir) : si le jeu
	# repartait dans la même frame, l'InteractionManager verrait cet appui et
	# lancerait une conversation avec le PNJ le plus proche.
	await get_tree().process_frame
	# Si quelqu'un a ré-ouvert le menu pendant cette frame, on reste en pause.
	if not est_ouvert():
		get_tree().paused = false

func _sur_menu_principal() -> void:
	# Toujours lever la pause avant de changer de scène : `paused` appartient à
	# l'arbre entier, il resterait actif dans le menu principal.
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_MENU)

func _sur_quitter() -> void:
	get_tree().quit()
