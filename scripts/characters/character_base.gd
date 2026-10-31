# scripts/characters/character_base.gd
# Classe de base commune à Kael et Mira.
# Gère le mouvement 3D, la gravité, et pilote les animations du modèle.
# Le mouvement est relatif à la caméra si camera_ref est assigné.
#
# LES ANIMATIONS
# Les modèles kael.glb / mira.glb ont un squelette et six animations, créées
# dans Blender par tools/animer_personnages.py :
#   idle, marche, course   — en boucle
#   interagir, skill1, skill2 — gestes courts, joués une fois
# À l'import, Godot range ces animations dans un AnimationPlayer (un enfant du
# noeud « Modele »). L'AnimationPlayer sait jouer UNE animation à la fois ;
# pour MÉLANGER idle, marche et course selon la vitesse, on lui adjoint un
# AnimationTree, construit en code dans _construire_arbre() :
#
#     idle ───────────────────────────┐
#                                     ├─ Blend2 « mouvement » ─ OneShot « geste » ─ sortie
#     marche ┐                        │   (0 = idle, 1 = pas)    (haut du corps)
#            ├─ BlendSpace1D « allure » ─ TimeScale « cadence »
#     course ┘   (0 = marche, 1 = course)  (vitesse de lecture)
#
# DES PIEDS QUI NE PATINENT PAS
# Un cycle de marche fait avancer de FOULEE_MARCHE mètres, un cycle de course
# de FOULEE_COURSE mètres, et chaque cycle dure 1 s dans le fichier. Si le
# personnage avance à v m/s, il doit donc faire v / foulée cycles par seconde :
# c'est la « cadence », la vitesse de lecture qu'on donne au TimeScale.
# ⚠ Ces constantes sont un contrat avec tools/animer_personnages.py.
#
# On n'anime jamais le CharacterBody3D lui-même : sa capsule de collision
# bougerait avec. Seul le modèle (le noeud « Modele ») s'anime et s'incline.
#
# Les interactions ne passent PAS par ici : c'est l'InteractionManager qui lit
# le bouton et appelle l'objet visé. Voir scripts/globals/interaction_manager.gd.

class_name CharacterBase
extends CharacterBody3D

# Vitesse MAXIMALE, en m/s. Les puzzles en dépendent (ex. les 12 s de Mira) :
# l'accélération ci-dessous ne la change pas, elle ne fait qu'y mener.
@export var vitesse: float = 5.0
@export var id_joueur: int = 1

const GRAVITE: float = 9.8

# Vitesse à laquelle le personnage se tourne vers sa direction, « par seconde ».
# 10 ≈ l'ancien lerp_angle(..., 0.15) à 60 fps, mais identique à 30 ou 144 fps.
const VITESSE_ROTATION: float = 10.0

# ── Accélération ─────────────────────────────────────────────────────────────
# En m/s². 30 : la pleine vitesse est atteinte en 0,17 s, l'arrêt en 0,14 s.
# Assez court pour rester précis, assez long pour que le corps ait du poids.
const ACCELERATION: float = 30.0
const DECELERATION: float = 36.0

# ── Contrat avec tools/animer_personnages.py ────────────────────────────────
const FOULEE_MARCHE: float = 1.2   # mètres parcourus par cycle de marche
const FOULEE_COURSE: float = 3.0   # mètres parcourus par cycle de course
# En dessous de VITESSE_MARCHE : marche pure. Au-dessus de VITESSE_COURSE :
# course pure. Entre les deux, on mélange. Avec ces valeurs, la cadence reste
# la même (≈ 1,67 cycle/s) sur tout le mélange : les jambes ne changent pas de
# rythme quand on pousse le stick, elles allongent seulement le pas.
const VITESSE_MARCHE: float = 2.0
const VITESSE_COURSE: float = 5.0
# Sous cette vitesse, on passe progressivement de « pas » à « idle ».
const VITESSE_ARRET: float = 0.8

# Les os que les gestes (interagir, skills) ont le droit de bouger : les
# jambes continuent ainsi de marcher pendant qu'on lève les bras.
const OS_HAUT_DU_CORPS := ["colonne", "cou", "tete", "bras_g", "avantbras_g", "bras_d", "avantbras_d"]
const ANIMATIONS_EN_BOUCLE := ["idle", "marche", "course"]

# ── Inclinaison dans les virages ─────────────────────────────────────────────
# Le personnage penche vers l'intérieur du virage, comme un coureur.
const INCLINAISON_VIRAGE: float = 0.035  # radians de roulis par rad/s de virage
const INCLINAISON_MAX: float = 0.14      # ≈ 8°
const VITESSE_INCLINAISON: float = 8.0

var camera_ref = null

# Mis à false pendant l'intro et la fin (voir main.gd) : le personnage ne lit
# plus ses touches, mais la gravité continue de s'appliquer.
var controles_actifs: bool = true

# Le modèle visuel (null si la scène n'en a pas), et ce qui l'anime.
var _modele: Node3D = null
var _rotation_repos: Vector3 = Vector3.ZERO
var _lecteur: AnimationPlayer = null
var _arbre: AnimationTree = null
# L'animation jouée par le OneShot « geste » : on change son nom avant chaque geste.
var _noeud_geste: AnimationNodeAnimation = null
var _roulis: float = 0.0
var _rotation_y_avant: float = 0.0

func _ready() -> void:
	add_to_group("joueurs")
	# Le nom « Modele » vient de kael.tscn / mira.tscn.
	_modele = get_node_or_null("Modele") as Node3D
	if _modele:
		_rotation_repos = _modele.rotation
		_lecteur = _modele.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _lecteur:
		_construire_arbre()
	_rotation_y_avant = rotation.y

func _physics_process(delta: float) -> void:
	_appliquer_gravite(delta)
	_deplacer(delta)
	move_and_slide()
	_animer(delta)

func _appliquer_gravite(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITE * delta

func _deplacer(delta: float) -> void:
	var direction = _obtenir_direction()
	# La vitesse visée : `direction` est déjà raccourcie si le stick n'est
	# qu'à moitié poussé (voir _obtenir_direction), jamais allongée.
	var cible := Vector2(direction.x, direction.z) * vitesse
	var actuelle := _accelerer(Vector2(velocity.x, velocity.z), cible, delta)
	velocity.x = actuelle.x
	velocity.z = actuelle.y
	if direction.length() > 0.0:
		_orienter_personnage(direction, delta)

# Rapproche la vitesse actuelle de la vitesse visée, d'au plus
# ACCELERATION × delta. Ce pas est proportionnel à delta : à 30 ou à 144 images
# par seconde, on atteint la pleine vitesse au même instant.
func _accelerer(actuelle: Vector2, cible: Vector2, delta: float) -> Vector2:
	# On freine quand on veut aller moins vite (ou dans l'autre sens).
	var taux := ACCELERATION if cible.length() >= actuelle.length() else DECELERATION
	return actuelle.move_toward(cible, taux * delta)

func _obtenir_direction() -> Vector3:
	if not controles_actifs:
		return Vector3.ZERO
	var prefixe = "joueur" + str(id_joueur) + "_"
	var dir_2d = Input.get_vector(
		prefixe + "gauche",
		prefixe + "droite",
		prefixe + "haut",
		prefixe + "bas"
	)
	if dir_2d.length() < 0.1:
		return Vector3.ZERO
	# Stick à moitié poussé → on marche ; à fond (ou clavier) → on court.
	# La longueur ne dépasse jamais 1 : la vitesse max reste `vitesse`.
	var force := minf(dir_2d.length(), 1.0)

	if camera_ref:
		var h = camera_ref.get_angle_h()
		var avant = Vector3(-sin(h), 0.0, -cos(h))
		var droite = Vector3(cos(h), 0.0, -sin(h))
		return (droite * dir_2d.x + avant * -dir_2d.y).normalized() * force

	return Vector3(dir_2d.x, 0.0, dir_2d.y).normalized() * force

func _orienter_personnage(direction: Vector3, delta: float) -> void:
	var angle_cible = atan2(direction.x, direction.z)
	# 1 - exp(-k * delta) : la même formule que la caméra (camera_follow.gd).
	# Un lerp_angle(..., 0.15) par frame tournerait deux fois plus vite à 120 fps.
	rotation.y = lerp_angle(rotation.y, angle_cible, 1.0 - exp(-VITESSE_ROTATION * delta))

# ──────────────────────────────────────────────────────────────────────────────
# ANIMATIONS
# ──────────────────────────────────────────────────────────────────────────────

# Joue un geste court (« interagir », « skill1 », « skill2 ») sur le haut du
# corps. Il ne bloque rien : les jambes continuent de marcher, et le geste
# s'efface tout seul à la fin.
func jouer_geste(nom: String) -> void:
	if _arbre == null or not _lecteur.has_animation(nom):
		return
	_noeud_geste.animation = nom
	# FIRE relance le geste même s'il était déjà en cours (deux appuis rapides).
	_arbre.set("parameters/geste/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

# Vitesse de lecture des pas (cycles par seconde) pour une vitesse au sol donnée.
func cadence_pour(vitesse_sol: float) -> float:
	var foulee := lerpf(FOULEE_MARCHE, FOULEE_COURSE, _allure_pour(vitesse_sol))
	# Un plancher : à 0,1 m/s on ne fige pas les jambes, on les ralentit.
	return maxf(vitesse_sol, 0.3) / foulee

# 0 = marche, 1 = course.
func _allure_pour(vitesse_sol: float) -> float:
	return clampf((vitesse_sol - VITESSE_MARCHE) / (VITESSE_COURSE - VITESSE_MARCHE), 0.0, 1.0)

func _construire_arbre() -> void:
	# Les .import ne sont pas versionnés : on ne peut pas compter sur une case
	# « boucle » cochée dans l'éditeur. On règle donc la boucle ici.
	for nom in ANIMATIONS_EN_BOUCLE:
		if _lecteur.has_animation(nom):
			_lecteur.get_animation(nom).loop_mode = Animation.LOOP_LINEAR

	# Chaque « noeud » de l'arbre est une ressource ; on les relie par leur nom.
	var racine := AnimationNodeBlendTree.new()

	var idle := AnimationNodeAnimation.new()
	idle.animation = "idle"
	racine.add_node("idle", idle)

	# BlendSpace1D : un curseur de 0 à 1, une animation à chaque bout.
	var allure := AnimationNodeBlendSpace1D.new()
	var marche := AnimationNodeAnimation.new()
	marche.animation = "marche"
	var course := AnimationNodeAnimation.new()
	course.animation = "course"
	allure.add_blend_point(marche, 0.0)
	allure.add_blend_point(course, 1.0)
	allure.min_space = 0.0
	allure.max_space = 1.0
	# sync : marche et course avancent ENSEMBLE même quand l'une pèse 0. Elles
	# restent ainsi en phase (pied gauche avec pied gauche) pendant le mélange.
	allure.sync = true
	racine.add_node("allure", allure)

	var cadence := AnimationNodeTimeScale.new()
	racine.add_node("cadence", cadence)
	racine.connect_node("cadence", 0, "allure")

	var mouvement := AnimationNodeBlend2.new()
	racine.add_node("mouvement", mouvement)
	racine.connect_node("mouvement", 0, "idle")
	racine.connect_node("mouvement", 1, "cadence")

	# Le geste : un OneShot, dont le filtre ne laisse passer que le haut du corps.
	_noeud_geste = AnimationNodeAnimation.new()
	_noeud_geste.animation = "interagir"
	racine.add_node("anim_geste", _noeud_geste)
	var geste := AnimationNodeOneShot.new()
	geste.fadein_time = 0.12
	geste.fadeout_time = 0.25
	geste.filter_enabled = true
	_filtrer_haut_du_corps(geste)
	racine.add_node("geste", geste)
	racine.connect_node("geste", 0, "mouvement")
	racine.connect_node("geste", 1, "anim_geste")

	racine.connect_node("output", 0, "geste")

	_arbre = AnimationTree.new()
	_arbre.name = "AnimationTree"
	_arbre.tree_root = racine
	# L'arbre est posé à côté de l'AnimationPlayer et utilise ses animations.
	# Les pistes des animations sont relatives au parent de l'AnimationPlayer
	# (« Armature/Skeleton3D:cuisse_g ») : on donne la même racine à l'arbre.
	_lecteur.get_parent().add_child(_arbre)
	_arbre.anim_player = _arbre.get_path_to(_lecteur)
	_arbre.root_node = _arbre.get_path_to(_lecteur.get_node(_lecteur.root_node))
	_arbre.active = true

# Chaque piste d'animation vise un os par un chemin du genre
# « Armature/Skeleton3D:colonne ». On coche dans le filtre celles du haut du corps.
func _filtrer_haut_du_corps(geste: AnimationNodeOneShot) -> void:
	var exemple := _lecteur.get_animation("idle")
	if exemple == null:
		return
	for i in exemple.get_track_count():
		var chemin := exemple.track_get_path(i)
		if chemin.get_concatenated_subnames() in OS_HAUT_DU_CORPS:
			geste.set_filter_path(chemin, true)

# À chaque image physique : on règle les curseurs de l'arbre selon la vitesse,
# et on penche le modèle dans les virages.
func _animer(delta: float) -> void:
	if _modele == null:
		return

	# Vitesse horizontale seulement : tomber ne doit pas faire « marcher ».
	var vitesse_sol := Vector2(velocity.x, velocity.z).length()

	if _arbre:
		_arbre.set("parameters/mouvement/blend_amount", clampf(vitesse_sol / VITESSE_ARRET, 0.0, 1.0))
		_arbre.set("parameters/allure/blend_position", _allure_pour(vitesse_sol))
		_arbre.set("parameters/cadence/scale", cadence_pour(vitesse_sol))

	# Inclinaison : on mesure à quelle vitesse le personnage tourne (rad/s).
	# Tourner à gauche (rotation.y qui augmente) → pencher à gauche (roulis < 0).
	var vitesse_virage := 0.0
	if delta > 0.0:
		vitesse_virage = angle_difference(_rotation_y_avant, rotation.y) / delta
	_rotation_y_avant = rotation.y
	var cible := 0.0
	if vitesse > 0.0:
		cible = clampf(-vitesse_virage * INCLINAISON_VIRAGE, -INCLINAISON_MAX, INCLINAISON_MAX) \
			* clampf(vitesse_sol / vitesse, 0.0, 1.0)
	_roulis = lerpf(_roulis, cible, 1.0 - exp(-VITESSE_INCLINAISON * delta))
	_modele.rotation = _rotation_repos + Vector3(0.0, 0.0, _roulis)
