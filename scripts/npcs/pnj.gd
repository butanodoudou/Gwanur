# scripts/npcs/pnj.gd
# PNJ générique — affiche un dialogue quand un joueur s'approche et interagit.
#
# Pour configurer un PNJ depuis l'éditeur :
#   - nom_pnj : le nom affiché dans la boîte de dialogue
#   - lignes   : les lignes de dialogue (tableau de textes)
#   - flag_apres : nom du flag à activer dans GameManager après la conversation
#                  (ex: "brennan_parle" → GameManager.brennan_parle = true)

extends Node3D

@export var nom_pnj: String = "PNJ"
@export var lignes: Array[String] = ["..."]
@export var flag_apres: String = ""  # Optionnel : flag à activer dans GameManager

var _joueur_proche: bool = false
var _deja_parle: bool = false

# La zone d'interaction (Area3D) doit être un enfant de ce node nommé "ZoneProximite"
@onready var zone_proximite: Area3D = $ZoneProximite

func _ready() -> void:
	zone_proximite.body_entered.connect(_sur_entree)
	zone_proximite.body_exited.connect(_sur_sortie)

func _sur_entree(body: Node3D) -> void:
	if body.is_in_group("joueurs"):
		_joueur_proche = true

func _sur_sortie(body: Node3D) -> void:
	if body.is_in_group("joueurs"):
		_joueur_proche = false

func _process(_delta: float) -> void:
	if not _joueur_proche:
		return
	# N'importe quel joueur peut déclencher le dialogue
	var j1_interagit = Input.is_action_just_pressed("joueur1_interagir")
	var j2_interagit = Input.is_action_just_pressed("joueur2_interagir")
	if j1_interagit or j2_interagit:
		_parler()

func _parler() -> void:
	DialogueManager.afficher(nom_pnj, lignes)
	if not _deja_parle and flag_apres != "":
		_activer_flag()
	_deja_parle = true

# Active un flag booléen dans GameManager par son nom
func _activer_flag() -> void:
	if GameManager.get(flag_apres) != null:
		GameManager.set(flag_apres, true)
