# scripts/interaction/point_interaction.gd
# Un endroit du décor avec lequel un joueur peut interagir : une poignée de
# porte, un verrou, un mécanisme...
#
# À ATTACHER à une Area3D dans la scène. Le script fait tout le reste :
# il prévient l'InteractionManager quand un joueur entre et sort, il fournit
# le texte affiché par le HUD, et il émet `active` quand le joueur appuie.
#
# À RETENIR : ce script ne lit JAMAIS l'input lui-même. C'est l'InteractionManager
# qui décide, pour éviter que deux systèmes répondent au même appui.
#
# Utilisation depuis un puzzle :
#   @onready var poignee: PointInteraction = $ZoneInteractionKael
#   func _ready():
#       poignee.active.connect(_sur_poignee_prise)

class_name PointInteraction
extends Area3D

# Texte affiché dans le HUD, ex. "Tirer la poignée"
@export var verbe: String = "Interagir"
# Qui a le droit d'interagir : 0 = les deux, 1 = Kael seulement, 2 = Mira seulement
@export var joueur_autorise: int = 0

signal active(id_joueur: int)

var _disponible: bool = true
# Les joueurs actuellement dans la zone (on les retient pour pouvoir
# réenregistrer ou retirer le point quand sa disponibilité change)
var _joueurs_presents: Array[int] = []

func _ready() -> void:
	body_entered.connect(_sur_entree)
	body_exited.connect(_sur_sortie)

func _sur_entree(body: Node3D) -> void:
	if not body.is_in_group("joueurs"):
		return
	var id: int = body.id_joueur
	if joueur_autorise != 0 and id != joueur_autorise:
		return
	if not _joueurs_presents.has(id):
		_joueurs_presents.append(id)
	if _disponible:
		InteractionManager.enregistrer(id, self)

func _sur_sortie(body: Node3D) -> void:
	if not body.is_in_group("joueurs"):
		return
	var id: int = body.id_joueur
	_joueurs_presents.erase(id)
	InteractionManager.retirer(id, self)

# ── Interface attendue par l'InteractionManager ───────────────────────────────

func obtenir_verbe() -> String:
	return verbe

func declencher(id_joueur: int) -> void:
	active.emit(id_joueur)

# ── Contrôle depuis le puzzle ─────────────────────────────────────────────────

# Rend le point utilisable ou non (ex. une fois la porte ouverte, on n'affiche
# plus "Tirer la poignée"). Les joueurs déjà sur place voient le prompt
# apparaître ou disparaître immédiatement.
func definir_disponible(valeur: bool) -> void:
	if _disponible == valeur:
		return
	_disponible = valeur
	for id in _joueurs_presents:
		if valeur:
			InteractionManager.enregistrer(id, self)
		else:
			InteractionManager.retirer(id, self)

# Change le texte du HUD à la volée (ex. "En attente de Mira...")
func definir_verbe(nouveau: String) -> void:
	verbe = nouveau
