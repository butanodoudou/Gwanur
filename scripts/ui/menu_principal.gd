# scripts/ui/menu_principal.gd
# Menu principal — Commencer / Quitter.
# Construit entièrement en code pour rester cohérent avec le reste du projet.
#
# MANETTE
# Un bouton Godot ne réagit à la manette que s'il a le FOCUS (le contour
# lumineux). On le donne à « Commencer » dès l'ouverture : la croix ou le stick
# déplacent ensuite le focus (actions ui_up / ui_down), et A valide
# (action ui_accept, à laquelle project.godot ajoute le bouton A).

extends Control

var _btn_commencer: Button

func _ready() -> void:
	_construire_ui()
	_btn_commencer.grab_focus()
	# On peut revenir ici en pleine conversation (menu pause → Menu principal).
	# Le DialogueManager est un AutoLoad : sans ça, sa boîte de dialogue
	# resterait affichée par-dessus le menu.
	if DialogueManager.est_actif():
		DialogueManager.masquer()

func _construire_ui() -> void:
	# Fond plein écran (couleur chaude, style Ghibli)
	var fond := ColorRect.new()
	fond.color = Color(0.12, 0.10, 0.08)
	fond.anchor_right  = 1.0
	fond.anchor_bottom = 1.0
	add_child(fond)

	# Conteneur vertical centré
	var vbox := VBoxContainer.new()
	vbox.anchor_left   = 0.3
	vbox.anchor_right  = 0.7
	vbox.anchor_top    = 0.3
	vbox.anchor_bottom = 0.8
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)

	# Titre
	var titre := Label.new()
	titre.text = "GWANUR"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 64)
	titre.add_theme_color_override("font_color", Color(0.95, 0.85, 0.60))
	vbox.add_child(titre)

	# Sous-titre
	var sous_titre := Label.new()
	sous_titre.text = "Le Village des Lisières"
	sous_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sous_titre.add_theme_font_size_override("font_size", 20)
	sous_titre.add_theme_color_override("font_color", Color(0.70, 0.60, 0.45))
	vbox.add_child(sous_titre)

	# Espaceur
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)

	# Bouton Commencer
	_btn_commencer = Button.new()
	_btn_commencer.text = "Commencer"
	_btn_commencer.custom_minimum_size = Vector2(0, 52)
	_btn_commencer.add_theme_font_size_override("font_size", 22)
	_btn_commencer.pressed.connect(_sur_commencer)
	vbox.add_child(_btn_commencer)

	# Bouton Quitter
	var btn_quitter := Button.new()
	btn_quitter.text = "Quitter"
	btn_quitter.custom_minimum_size = Vector2(0, 52)
	btn_quitter.add_theme_font_size_override("font_size", 22)
	btn_quitter.pressed.connect(_sur_quitter)
	vbox.add_child(btn_quitter)

	# Note bas de page (deux joueurs requis)
	var note := Label.new()
	# Deuxième ligne : les touches de secours, pour tester sans manette.
	note.text = "Jeu coopératif local — deux manettes · Start ou Échap : pause\n" \
		+ "Sans manette : Kael = ZQSD, E, A, R (souris + clic droit pour la caméra) · " \
		+ "Mira = flèches, Entrée, Maj droit, Ctrl droit (pavé num. 8/4/6/2 pour la caméra)"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color(0.50, 0.45, 0.35))
	note.anchor_top    = 0.90
	note.anchor_bottom = 1.0
	note.anchor_right  = 1.0
	add_child(note)

func _sur_commencer() -> void:
	# GameManager survit aux changements de scène : on efface la partie précédente.
	GameManager.reinitialiser()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _sur_quitter() -> void:
	get_tree().quit()
