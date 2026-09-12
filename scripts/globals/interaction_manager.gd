# scripts/globals/interaction_manager.gd
# AutoLoad — sait, pour chaque joueur, avec quoi il peut interagir.
#
# POURQUOI CE FICHIER EXISTE
# Avant, chaque PNJ lisait le bouton "interagir" lui-même, dans son propre
# _process(). Le DialogueManager lisait le MÊME bouton pour avancer d'une ligne.
# Les deux s'exécutaient dans la même frame : appuyer sur A faisait avancer le
# dialogue, puis le PNJ le relançait aussitôt depuis la première ligne.
# Ici, un seul nœud lit le bouton et décide qui doit répondre.
#
# COMMENT ÇA MARCHE
# Un objet interactif (PNJ, mécanisme, objet à examiner) doit :
#   1. s'enregistrer quand un joueur entre dans sa zone  → enregistrer()
#   2. se retirer quand le joueur sort                    → retirer()
#   3. fournir deux méthodes :
#        declencher(id_joueur)  → ce qui se passe quand on appuie
#        obtenir_verbe()        → le texte affiché par le HUD ("Parler à Lira")
#
# Le HUD de chaque joueur appelle cible_pour() pour savoir quoi afficher.

extends Node

# id_joueur (1 ou 2) → liste des objets interactifs à portée de CE joueur
var _cibles: Dictionary = {1: [], 2: []}

# ──────────────────────────────────────────────────────────────────────────────
# ENREGISTREMENT — appelé par les objets interactifs eux-mêmes
# ──────────────────────────────────────────────────────────────────────────────

func enregistrer(id_joueur: int, cible: Node) -> void:
	if not _cibles.has(id_joueur):
		return
	if not _cibles[id_joueur].has(cible):
		_cibles[id_joueur].append(cible)

func retirer(id_joueur: int, cible: Node) -> void:
	if not _cibles.has(id_joueur):
		return
	_cibles[id_joueur].erase(cible)

# ──────────────────────────────────────────────────────────────────────────────
# LECTURE — utilisée par le HUD
# ──────────────────────────────────────────────────────────────────────────────

# Retourne l'objet interactif le plus proche de ce joueur, ou null s'il n'y en a
# aucun à portée. Le HUD s'en sert pour afficher "(A) Parler à Lira".
func cible_pour(id_joueur: int) -> Node:
	var joueur := _trouver_joueur(id_joueur)
	if joueur == null:
		return null

	var meilleure: Node = null
	var meilleure_distance: float = INF

	for cible in _cibles.get(id_joueur, []):
		# Un objet peut avoir été supprimé de la scène entre-temps
		if not is_instance_valid(cible):
			continue
		var distance: float = joueur.global_position.distance_to(cible.global_position)
		if distance < meilleure_distance:
			meilleure_distance = distance
			meilleure = cible

	return meilleure

# ──────────────────────────────────────────────────────────────────────────────
# LECTURE DE L'INPUT — le seul endroit du jeu qui déclenche une interaction
# ──────────────────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	# Si un dialogue est ouvert, le bouton lui appartient : il sert à avancer
	# dans le texte, pas à relancer une conversation.
	if DialogueManager.bloque_interaction():
		return

	for id_joueur in [1, 2]:
		if not Input.is_action_just_pressed("joueur%d_interagir" % id_joueur):
			continue
		var cible := cible_pour(id_joueur)
		if cible != null:
			cible.declencher(id_joueur)
			# Une seule interaction par frame, même si les deux joueurs appuient
			# en même temps sur le même PNJ.
			return

# Kael et Mira s'ajoutent aux groupes "kael" / "mira" dans leur _ready().
func _trouver_joueur(id_joueur: int) -> Node3D:
	var groupe: String = "kael" if id_joueur == 1 else "mira"
	var trouves := get_tree().get_nodes_in_group(groupe)
	if trouves.is_empty():
		return null
	return trouves[0] as Node3D
