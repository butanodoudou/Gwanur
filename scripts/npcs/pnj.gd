# scripts/npcs/pnj.gd
# PNJ générique — crée son propre visuel (modèle villageois + "!") et gère le dialogue.
#
# Propriétés à configurer depuis l'éditeur :
#   nom_pnj    : nom affiché dans la boîte de dialogue
#   lignes     : tableau de textes
#   couleur    : couleur de la tunique / de la robe du villageois
#   flag_apres : flag GameManager à activer après la conversation
#   verbe      : texte du prompt du HUD (vide → "Parler à <nom_pnj>")
#   silhouette : "ancien", "villageois", "villageoise" ou "enfant"
#                ("auto" → choisie d'après le nom du noeud, voir SILHOUETTES)
#
# LE VISUEL
# Les modèles sont générés par `tools/gen_pnj.py` (Blender). Quatre
# silhouettes pour neuf villageois : c'est la couleur de la tunique qui fait la
# différence entre deux villageois de même silhouette. Le modèle contient un
# matériau nommé `tunique_pnj` ; on le remplace ici par `couleur`.
# Les PNJ ne marchent pas. Le modèle a un squelette et une animation `idle`
# (respiration, poids qui bascule, regard qui erre — tools/animer_personnages.py),
# jouée en boucle ; et le villageois se tourne doucement vers le joueur le
# plus proche quand il passe à portée (voir _process).
#
# Le PNJ ne lit PAS le bouton lui-même : il se signale à l'InteractionManager
# quand un joueur approche, et celui-ci appelle declencher() au bon moment.
# (Voir le commentaire en tête de scripts/globals/interaction_manager.gd.)

extends Node3D

@export var nom_pnj: String = "PNJ"
@export var lignes: Array[String] = ["..."]
@export var couleur: Color = Color(0.7, 0.5, 0.3)
@export var flag_apres: String = ""
@export var verbe: String = ""
# "auto" = d'après le nom du noeud (tableau SILHOUETTES ci-dessous).
@export_enum("auto", "ancien", "villageois", "villageoise", "enfant") var silhouette: String = "auto"

# Silhouette par défaut de chaque villageois de la Zone 1, d'après le NOM DU
# NOEUD (pas nom_pnj, qui peut porter un accent ou changer avec les textes).
# Mettre `silhouette` dans l'inspecteur passe outre ce tableau.
const SILHOUETTES := {
	"Vaenmor": "ancien",   "Caeryn": "ancien",
	"Brennan": "villageois", "Eldwen": "villageois", "Tovan": "villageois",
	"Lira": "villageoise", "Marnen": "villageoise", "Nyssil": "villageoise",
	"Sorai": "enfant",
}
const DOSSIER_MODELES := "res://assets/models/personnages/pnj_"
# Le nom du matériau à recolorer — contrat avec tools/gen_pnj.py.
const MATERIAU_TUNIQUE := "tunique_pnj"

# Le regard : à moins de PORTEE_REGARD mètres, le villageois se tourne vers
# le joueur le plus proche, au plus de ANGLE_REGARD_MAX (il ne fait pas
# volte-face), lentement. Sinon il revient à sa pose d'origine.
const PORTEE_REGARD := 6.0
const ANGLE_REGARD_MAX := 1.22   # radians, ≈ 70°
const VITESSE_REGARD := 2.0

var _deja_parle: bool = false
var _label_indicateur: Label3D = null
var _visuel: Node3D = null

@onready var zone_proximite: Area3D = $ZoneProximite

func _ready() -> void:
	zone_proximite.body_entered.connect(_sur_entree)
	zone_proximite.body_exited.connect(_sur_sortie)
	_creer_visuel()

# Le villageois tourne doucement le corps vers le joueur le plus proche.
func _process(delta: float) -> void:
	if _visuel == null:
		return
	var cible := 0.0
	var joueur := _joueur_le_plus_proche()
	if joueur != null:
		# to_local : la position du joueur vue depuis le PNJ (qui peut être
		# tourné dans la scène). atan2(x, z) = l'angle pour la regarder, car
		# le modèle regarde +Z.
		var local := to_local(joueur.global_position)
		cible = clampf(atan2(local.x, local.z), -ANGLE_REGARD_MAX, ANGLE_REGARD_MAX)
	_visuel.rotation.y = lerp_angle(_visuel.rotation.y, cible, 1.0 - exp(-VITESSE_REGARD * delta))

func _joueur_le_plus_proche() -> Node3D:
	var meilleur: Node3D = null
	var meilleure_distance := PORTEE_REGARD
	for joueur in get_tree().get_nodes_in_group("joueurs"):
		var d := global_position.distance_to((joueur as Node3D).global_position)
		if d < meilleure_distance:
			meilleure_distance = d
			meilleur = joueur
	return meilleur

func _creer_visuel() -> void:
	_visuel = _charger_modele()
	if _visuel == null:
		_visuel = _creer_capsule()
	_visuel.name = "Visuel"
	add_child(_visuel)
	_jouer_idle(_visuel)

	# Indicateur "!" — billboard jaune au-dessus de la tête, disparaît après dialogue
	var label := Label3D.new()
	label.text = "!"
	# Au-dessus de la tête, quelle que soit la taille du villageois.
	label.position = Vector3(0, 1.45 if _silhouette() == "enfant" else 2.3, 0)
	label.font_size = 72
	label.modulate = Color(1.0, 0.9, 0.1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	_label_indicateur = label

func _silhouette() -> String:
	if silhouette != "auto" and silhouette != "":
		return silhouette
	return SILHOUETTES.get(String(name), "villageois")

# Instancie le modèle .glb et recolore sa tunique. Renvoie null si le fichier
# manque (on retombe alors sur la capsule, pour ne jamais avoir un PNJ invisible).
func _charger_modele() -> Node3D:
	var chemin := DOSSIER_MODELES + _silhouette() + ".glb"
	if not ResourceLoader.exists(chemin):
		push_warning("Modèle de PNJ introuvable : " + chemin + " — lance tools/gen_pnj.py")
		return null
	var modele: Node3D = (load(chemin) as PackedScene).instantiate()
	_recolorer_tunique(modele)
	return modele

# Parcourt tous les maillages du modèle et remplace, surface par surface, le
# matériau `tunique_pnj` par une copie à la couleur de CE villageois.
# `set_surface_override_material` ne touche que cette instance : les autres PNJ
# qui partagent le même .glb gardent leur propre couleur.
func _recolorer_tunique(racine: Node) -> void:
	var a_voir: Array[Node] = [racine]
	while not a_voir.is_empty():
		var noeud: Node = a_voir.pop_back()
		a_voir.append_array(noeud.get_children())
		if not (noeud is MeshInstance3D):
			continue
		var mi := noeud as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat == null or not mat.resource_name.begins_with(MATERIAU_TUNIQUE):
				continue
			var copie := mat.duplicate() as BaseMaterial3D
			if copie == null:
				continue
			copie.albedo_color = couleur
			mi.set_surface_override_material(i, copie)

# Lance l'animation `idle` du modèle, en boucle.
func _jouer_idle(modele: Node3D) -> void:
	var lecteur := modele.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if lecteur == null or not lecteur.has_animation("idle"):
		return  # la capsule de secours, ou un vieux .glb sans squelette
	# Les .import ne sont pas versionnés : la boucle se règle en code.
	lecteur.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
	# Chaque villageois part d'un moment différent de son souffle, et respire
	# à un rythme un peu différent : sinon les neuf respireraient en chœur,
	# ce qui se remarque tout de suite. hash(name) donne un nombre fixe par
	# PNJ — pas de hasard, c'est testable.
	var graine := absi(hash(String(name)))
	lecteur.speed_scale = 0.9 + float(graine % 200) / 1000.0   # de 0,9 à 1,1
	lecteur.play("idle")
	lecteur.seek(float(graine % 1000) / 1000.0 * lecteur.current_animation_length, true)

# L'ancien placeholder, gardé en secours si le .glb est absent.
func _creer_capsule() -> Node3D:
	var mi := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.3
	mesh.height = 1.8
	mi.mesh = mesh
	mi.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = couleur
	mi.set_surface_override_material(0, mat)
	var racine := Node3D.new()
	racine.add_child(mi)
	return racine

# ──────────────────────────────────────────────────────────────────────────────
# PROXIMITÉ — on signale sa présence au gestionnaire d'interactions
# ──────────────────────────────────────────────────────────────────────────────

func _sur_entree(body: Node3D) -> void:
	if body.is_in_group("joueurs"):
		InteractionManager.enregistrer(body.id_joueur, self)

func _sur_sortie(body: Node3D) -> void:
	if body.is_in_group("joueurs"):
		InteractionManager.retirer(body.id_joueur, self)

# ──────────────────────────────────────────────────────────────────────────────
# INTERFACE ATTENDUE PAR L'INTERACTIONMANAGER
# ──────────────────────────────────────────────────────────────────────────────

# Texte affiché dans le HUD du joueur quand il est à portée
func obtenir_verbe() -> String:
	if verbe != "":
		return verbe
	return "Parler à " + nom_pnj

# Appelé quand le joueur appuie sur le bouton d'interaction
func declencher(_id_joueur: int) -> void:
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
