# scripts/zones/fleur_bief.gd
# La fleur sans nom, de l'autre côté du pont du Puzzle 3.
#
# C'est la même fleur que celle trouvée sur l'oreiller d'Aelindra, au début
# du jeu (TextesNarration.INTRO). Elle pousse dans le bief : la preuve que leur
# mère est passée par là, la nuit de son départ. Le jeu ne dit jamais son nom.
#
# RÈGLES
#   - Elle est OPTIONNELLE : rien ne dépend d'elle pour finir la zone. Si les
#     jumeaux l'ont vue, la fin gagne deux lignes (TextesNarration.FIN_FLEUR,
#     lue par main.gd quand GameManager.fleur_trouvee est vrai).
#   - On n'y arrive qu'en traversant le pont : le bief est fermé par la
#     palissade nord, deux bouts de palissade et le ruisseau (zone1.gd).
#   - Ce script ne lit JAMAIS le bouton « interagir » : c'est le
#     PointInteraction (ZoneFleur) qui le reçoit de l'InteractionManager et
#     nous prévient par son signal `active`, avec l'id du joueur.
#
# Kael et Mira ne réagissent pas pareil : le premier qui la regarde a SA
# réaction ; quand le second la regarde à son tour, une ligne commune s'ajoute.
#
# Nœuds attendus (zone1.tscn) :
#   ZoneFleur  (Area3D + PointInteraction) — où l'on peut la regarder
#   Touffe     (Node3D) — repère : une touffe de la même fleur, près du pont
#   TouffePres (Node3D) — repère : une seconde touffe, au pied de la fleur
#                         (de loin, la fleur se lit comme une tache claire)
#   Petales    (Node3D) — repère : des pétales tombés, en file vers la fleur

extends Node3D

# ── Textes ───────────────────────────────────────────────────────────────────
# Le scénariste peut les réécrire librement : les tests ne comparent qu'à ces
# constantes. Une ligne ≤ 90 signes (boîte de dialogue partagée en split-screen).

# Kael, le rêveur : il sent.
const LIGNES_KAEL: Array[String] = [
	"Au bord du bief, la même fleur que sur l'oreiller. Pâle, comme un reste de lune.",
	"Kael s'agenouille. Sous ses Brassards, la sève de la tige bat lentement, tiède.",
	"Kael : « Elle s'est assise ici, cette nuit. La terre s'en souvient encore. »",
]

# Mira, la pragmatique : elle constate.
const LIGNES_MIRA: Array[String] = [
	"Au bord du bief, la même fleur que sur l'oreiller. Mira la reconnaît tout de suite.",
	"Autour, l'herbe est encore couchée. Quelqu'un s'est assis là, il n'y a pas longtemps.",
	"Mira : « Le pont tenait encore quand elle est venue. Elle a choisi cet endroit. »",
]

# Ajoutée quand le second jumeau la regarde à son tour.
const LIGNES_COMMUNES: Array[String] = [
	"Ni l'un ni l'autre ne la cueille. On ne cueille pas ce qu'on vous a laissé.",
]

# Quand on la regarde une seconde fois.
const LIGNES_REVUE: Array[String] = [
	"La fleur pâle n'a pas bougé. Tournée vers l'eau, comme quelqu'un qui attend.",
]

# ── Habillage ────────────────────────────────────────────────────────────────
const DOSSIER_PROPS := "res://assets/models/props/"
# Une lueur très douce : la corolle émet déjà sa lumière (matériau émissif),
# cette lampe ne fait qu'en poser un reflet sur l'herbe autour.
const COULEUR_LUEUR := Color(0.78, 0.82, 1.0)

@onready var zone: PointInteraction = $ZoneFleur

# Le modèle de LA fleur (balancé doucement par le vent dans _process).
var _modele: Node3D = null
var _temps: float = 0.0

func _ready() -> void:
	_modele = _poser_modele("fleur", self)
	_poser_modele("fleur_touffe", $Touffe)
	_poser_modele("fleur_touffe", $TouffePres)
	_poser_modele("petales", $Petales)
	_ajouter_lueur()
	zone.active.connect(_sur_regardee)

# ──────────────────────────────────────────────────────────────────────────────
# L'INTERACTION
# ──────────────────────────────────────────────────────────────────────────────

# Un joueur a appuyé sur « interagir » près de la fleur.
#   id_joueur : 1 = Kael, 2 = Mira
func _sur_regardee(id_joueur: int) -> void:
	var deja_vue: bool = GameManager.fleur_vue_kael if id_joueur == 1 else GameManager.fleur_vue_mira
	if deja_vue:
		DialogueManager.afficher("", LIGNES_REVUE)
		return

	# Première fois pour CE jumeau.
	GameManager.fleur_trouvee = true
	if id_joueur == 1:
		GameManager.fleur_vue_kael = true
	else:
		GameManager.fleur_vue_mira = true

	# `duplicate()` : on ne modifie jamais la constante elle-même.
	var lignes: Array[String] = (LIGNES_KAEL if id_joueur == 1 else LIGNES_MIRA).duplicate()
	# Les deux l'ont vue : la ligne commune s'ajoute à la fin.
	if GameManager.fleur_vue_kael and GameManager.fleur_vue_mira:
		lignes.append_array(LIGNES_COMMUNES)
	DialogueManager.afficher("", lignes)

# ──────────────────────────────────────────────────────────────────────────────
# L'HABILLAGE
# ──────────────────────────────────────────────────────────────────────────────

# Pose le modèle `nom` (tools/gen_fleur.py) sous `parent`. Sans modèle (pas
# encore généré ou importé), une petite boîte pâle tient lieu de fleur.
func _poser_modele(nom: String, parent: Node3D) -> Node3D:
	var chemin := DOSSIER_PROPS + nom + ".glb"
	if ResourceLoader.exists(chemin):
		var scene := load(chemin) as PackedScene
		if scene != null:
			var modele := scene.instantiate() as Node3D
			parent.add_child(modele)
			return modele
	var boite := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.25, 0.5, 0.25)
	boite.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.90, 0.88, 0.98)
	mat.emission_enabled = true
	mat.emission = COULEUR_LUEUR
	mat.emission_energy_multiplier = 0.5
	boite.material_override = mat
	boite.position = Vector3(0, 0.25, 0)
	parent.add_child(boite)
	return boite

# Une petite lampe sans ombre au-dessus de la corolle, et quelques grains de
# lumière qui montent lentement. Deux nœuds bon marché, même en split-screen
# (pas d'ombre, 3 m de portée, 8 particules).
func _ajouter_lueur() -> void:
	var lampe := OmniLight3D.new()
	lampe.name = "Lueur"
	lampe.position = Vector3(0, 1.1, 0)
	lampe.light_color = COULEUR_LUEUR
	lampe.light_energy = 1.0
	lampe.omni_range = 3.0
	lampe.shadow_enabled = false
	add_child(lampe)

	var grains := GPUParticles3D.new()
	grains.name = "Grains"
	grains.amount = 8
	grains.lifetime = 4.0
	grains.position = Vector3(0, 0.9, 0)
	grains.visibility_aabb = AABB(Vector3(-1.5, -1, -1.5), Vector3(3, 4, 3))

	var processus := ParticleProcessMaterial.new()
	processus.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	processus.emission_sphere_radius = 0.5
	processus.direction = Vector3(0, 1, 0)
	processus.spread = 25.0
	processus.initial_velocity_min = 0.08
	processus.initial_velocity_max = 0.18
	processus.gravity = Vector3.ZERO
	# Les grains naissent, brillent, puis s'éteignent (courbe d'opacité).
	var degrade := Gradient.new()
	degrade.set_color(0, Color(1, 1, 1, 0))
	degrade.set_color(1, Color(1, 1, 1, 0))
	degrade.add_point(0.3, Color(1, 1, 1, 1))
	var texture_degrade := GradientTexture1D.new()
	texture_degrade.gradient = degrade
	processus.color_ramp = texture_degrade
	grains.process_material = processus

	var grain := SphereMesh.new()
	grain.radius = 0.02
	grain.height = 0.04
	grain.radial_segments = 6
	grain.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = COULEUR_LUEUR
	mat.vertex_color_use_as_albedo = true   # pour que la courbe d'opacité s'applique
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grain.material = mat
	grains.draw_pass_1 = grain
	add_child(grains)

# Le vent : la fleur oscille à peine. Lent et irrégulier (deux sinus), pour
# qu'elle paraisse vivante sans attirer l'attention comme un métronome.
func _process(delta: float) -> void:
	if _modele == null:
		return
	_temps += delta
	_modele.rotation.x = 0.035 * sin(_temps * 1.3) + 0.015 * sin(_temps * 3.1)
	_modele.rotation.z = 0.03 * sin(_temps * 0.9 + 1.0)
