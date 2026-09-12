# scripts/npcs/pnj.gd
# PNJ générique — crée son propre visuel (capsule + "!") et gère le dialogue.
#
# Propriétés à configurer depuis l'éditeur :
#   nom_pnj    : nom affiché dans la boîte de dialogue
#   lignes     : tableau de textes
#   couleur    : couleur du placeholder (remplacé par le vrai modèle plus tard)
#   flag_apres : flag GameManager à activer après la conversation

extends Node3D

@export var nom_pnj: String = "PNJ"
@export var lignes: Array[String] = ["..."]
@export var couleur: Color = Color(0.7, 0.5, 0.3)
@export var flag_apres: String = ""

var _joueur_proche: bool = false
var _deja_parle: bool = false
var _label_indicateur: Label3D = null

@onready var zone_proximite: Area3D = $ZoneProximite

func _ready() -> void:
	zone_proximite.body_entered.connect(_sur_entree)
	zone_proximite.body_exited.connect(_sur_sortie)
	_creer_visuel()

func _creer_visuel() -> void:
	# Corps — capsule colorée (placeholder en attendant le vrai modèle)
	var mi := MeshInstance3D.new()
	mi.position = Vector3(0, 0.9, 0)
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.3
	mesh.height = 1.8
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mi.set_surface_override_material(0, mat)
	add_child(mi)

	# Indicateur "!" — billboard jaune au-dessus de la tête, disparaît après dialogue
	var label := Label3D.new()
	label.text = "!"
	label.position = Vector3(0, 2.3, 0)
	label.font_size = 72
	label.modulate = Color(1.0, 0.9, 0.1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	_label_indicateur = label

func _sur_entree(body: Node3D) -> void:
	if body.is_in_group("joueurs"):
		_joueur_proche = true

func _sur_sortie(body: Node3D) -> void:
	if body.is_in_group("joueurs"):
		_joueur_proche = false

func _process(_delta: float) -> void:
	if not _joueur_proche:
		return
	if Input.is_action_just_pressed("joueur1_interagir") or Input.is_action_just_pressed("joueur2_interagir"):
		_parler()

func _parler() -> void:
	DialogueManager.afficher(nom_pnj, lignes)
	if not _deja_parle:
		if flag_apres != "":
			_activer_flag()
		if _label_indicateur:
			_label_indicateur.visible = false
	_deja_parle = true

func _activer_flag() -> void:
	if GameManager.get(flag_apres) != null:
		GameManager.set(flag_apres, true)
