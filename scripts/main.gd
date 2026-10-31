# scripts/main.gd
# Scène de jeu : câble les caméras aux personnages, ajoute le menu pause, et
# enchaîne les grandes étapes d'une partie :
#   intro (écran noir + textes) → jeu → fin de zone (textes + crédits) → menu.
# Les caméras trouvent leur cible elles-mêmes (voir camera_follow.gd).
#
# Le menu pause et l'écran de narration sont créés EN CODE ici, pour ne pas
# toucher à main.tscn (où se règlent la lumière et l'environnement).

extends Node3D

const MenuPause = preload("res://scripts/ui/menu_pause.gd")
const EcranNarration = preload("res://scripts/ui/ecran_narration.gd")

const SCENE_MENU := "res://scenes/menu_principal.tscn"

# Durées des fondus au noir, en secondes.
const FONDU_DEBUT_JEU: float = 2.0   # le noir de l'intro se lève sur le village
const FONDU_FIN_ZONE: float = 2.5    # le village s'efface après le grimoire

# Le menu pause (accessible aux tests).
var menu_pause: MenuPause
# L'écran de narration en cours (null quand on joue).
var ecran_narration: EcranNarration = null

func _ready() -> void:
	var kael     = $Monde/Kael
	var mira     = $Monde/Mira
	var cam_kael = $SplitScreen/Conteneur/VueKael/SubViewport/CameraKael
	var cam_mira = $SplitScreen/Conteneur/VueMira/SubViewport/CameraMira

	# camera_ref permet aux personnages de se déplacer relatif à leur caméra
	if cam_kael:
		kael.camera_ref = cam_kael
	if cam_mira:
		mira.camera_ref = cam_mira

	# Rendu « Breath of the Wild » : Kael, Mira (la zone s'est déjà stylisée
	# elle-même), tout ce qui apparaîtra en cours de partie, et les rayons de
	# soleil qui tombent du Trou de Ciel (voir scripts/rendu/).
	preload("res://scripts/rendu/stylisation.gd").styliser($Monde)
	preload("res://scripts/rendu/stylisation.gd").suivre(get_tree())
	preload("res://scripts/rendu/rayons_oculus.gd").poser($Monde/Zone1, $Monde/LumiereDirectionnelle)

	menu_pause = MenuPause.new()
	add_child(menu_pause)

	# Nouvelle partie : aucun dialogue de la partie précédente ne doit rester
	# affiché (le DialogueManager est un AutoLoad, il survit au changement de scène).
	DialogueManager.masquer()

	# zone1.gd annonce la fin de zone via GameManager (voir _appliquer_choix).
	GameManager.zone1_finie.connect(_jouer_fin)

	# L'intro ne se joue que si main est LA scène du jeu, posée directement sous
	# la racine (c'est ce que fait change_scene_to_file depuis le menu, ou F6
	# dans l'éditeur). Les bancs de test qui glissent main.tscn À L'INTÉRIEUR de
	# leur propre scène (test_hud, test_puzzle_porte…) démarrent ainsi
	# directement en jeu, sans 15 secondes d'écran noir à passer.
	if get_parent() == get_tree().root:
		_jouer_intro()

# Quand on quitte la scène (retour au menu, quitter), on rend la main à
# l'InteractionManager : c'est un AutoLoad, il survit à cette scène, et il
# resterait coupé si on partait pendant une narration.
func _exit_tree() -> void:
	InteractionManager.reprendre()

# ──────────────────────────────────────────────────────────────────────────────
# INTRO — Acte 0
# ──────────────────────────────────────────────────────────────────────────────

func _jouer_intro() -> void:
	_figer_jeu(true)
	ecran_narration = EcranNarration.new()
	add_child(ecran_narration)
	ecran_narration.noir_immediat()

	await ecran_narration.afficher_lignes(TextesNarration.INTRO)
	await ecran_narration.fondu_depuis_noir(FONDU_DEBUT_JEU)

	ecran_narration.queue_free()
	ecran_narration = null
	_figer_jeu(false)

# ──────────────────────────────────────────────────────────────────────────────
# FIN DE ZONE — après le choix du grimoire
# ──────────────────────────────────────────────────────────────────────────────

func _jouer_fin() -> void:
	# Plus aucun dialogue (ni en attente) : il resterait affiché SOUS l'écran
	# de fin, et la musique resterait baissée comme pendant un dialogue.
	DialogueManager.masquer()
	_figer_jeu(true)
	# Musique de fin dès le fondu au noir (l'AudioManager coupe les ambiances).
	AudioManager.jouer_fin()
	ecran_narration = EcranNarration.new()
	add_child(ecran_narration)
	await ecran_narration.fondu_vers_noir(FONDU_FIN_ZONE)

	# Le texte dépend du choix fait devant le grimoire.
	var fin: Array[String] = TextesNarration.FIN_SECRET
	if GameManager.choix_grimoire == "partager":
		fin = TextesNarration.FIN_PARTAGE
	await ecran_narration.afficher_lignes(fin)
	# La fleur du bief est optionnelle : ses lignes n'apparaissent que si les
	# jumeaux l'ont trouvée (voir scripts/zones/fleur_bief.gd).
	if GameManager.fleur_trouvee:
		await ecran_narration.afficher_lignes(TextesNarration.FIN_FLEUR)
	await ecran_narration.afficher_lignes(TextesNarration.FIN_COMMUNE)
	await ecran_narration.defiler_credits(TextesNarration.CREDITS)

	# GameManager sera remis à zéro quand on cliquera sur « Commencer ».
	get_tree().change_scene_to_file(SCENE_MENU)

# ──────────────────────────────────────────────────────────────────────────────
# FIGER LE JEU PENDANT LA NARRATION
# ──────────────────────────────────────────────────────────────────────────────
#
# Pendant l'intro et la fin :
#   - Kael et Mira ne lisent plus leurs touches (la gravité continue) ;
#   - l'InteractionManager est coupé. L'écran de narration lit le bouton
#     « interagir » pour passer une ligne : sans cette coupure, le même appui
#     pourrait aussi lancer un dialogue avec un PNJ proche.
# On n'utilise PAS get_tree().paused : c'est réservé au menu pause, et la
# narration doit continuer de tourner.
func _figer_jeu(fige: bool) -> void:
	for joueur in get_tree().get_nodes_in_group("joueurs"):
		joueur.controles_actifs = not fige
	if fige:
		InteractionManager.suspendre()
	else:
		InteractionManager.reprendre()
