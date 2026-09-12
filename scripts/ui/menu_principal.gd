# scripts/ui/menu_principal.gd
# Menu principal — Commencer / Quitter.
# Construit entièrement en code pour rester cohérent avec le reste du projet.

extends Control

func _ready() -> void:
	_construire_ui()

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
	var btn_commencer := Button.new()
	btn_commencer.text = "Commencer"
	btn_commencer.custom_minimum_size = Vector2(0, 52)
	btn_commencer.add_theme_font_size_override("font_size", 22)
	btn_commencer.pressed.connect(_sur_commencer)
	vbox.add_child(btn_commencer)

	# Bouton Quitter
	var btn_quitter := Button.new()
	btn_quitter.text = "Quitter"
	btn_quitter.custom_minimum_size = Vector2(0, 52)
	btn_quitter.add_theme_font_size_override("font_size", 22)
	btn_quitter.pressed.connect(_sur_quitter)
	vbox.add_child(btn_quitter)

	# Note bas de page (deux joueurs requis)
	var note := Label.new()
	note.text = "Jeu coopératif local — deux manettes requises"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color(0.50, 0.45, 0.35))
	note.anchor_top    = 0.92
	note.anchor_bottom = 1.0
	note.anchor_right  = 1.0
	add_child(note)

func _sur_commencer() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _sur_quitter() -> void:
	get_tree().quit()
