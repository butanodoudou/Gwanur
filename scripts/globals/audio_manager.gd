# scripts/globals/audio_manager.gd
# AutoLoad — tout le son du jeu : musique, ambiances, bruitages.
#
# POURQUOI CE FICHIER EXISTE
# Plutôt que de semer des « play() » dans chaque script, un seul nœud écoute
# ce qui se passe dans le jeu et choisit le son qui va avec. Les autres scripts
# n'ont presque rien à savoir de l'audio : l'AudioManager se branche lui-même
# sur leurs signaux EXISTANTS (corne_sonnee, puzzle_resolu, …).
#
# COMMENT IL TROUVE LES AUTRES NŒUDS
# Le SceneTree émet `node_added` chaque fois qu'un nœud entre dans l'arbre.
# On regarde chaque nouveau nœud : s'il possède un signal qu'on connaît
# (ex. "corne_sonnee"), on s'y connecte. Ça marche quelle que soit la scène
# (main.tscn, test_mecanique.tscn, un test headless…) et sans chemin en dur.
#
# CE QUE LES AUTRES SCRIPTS PEUVENT APPELER
#   AudioManager.jouer_sfx("resolu")          → un bruitage (nom inconnu = ignoré)
#   AudioManager.jouer_musique("theme_menu")  → fondu enchaîné vers ce morceau
#   AudioManager.arreter_musique()            → fondu vers le silence
#   AudioManager.jouer_fin()                  → musique de fin, ambiances coupées
#
# POURQUOI LES BRUITAGES SONT EN 2D (AudioStreamPlayer) ET PAS EN 3D
# En split-screen il y a DEUX caméras, une par SubViewport. Un son 3D n'est
# entendu que depuis le « listener » d'un viewport : on entendrait le jeu
# depuis la tête d'un seul des deux joueurs (ou de personne, selon les
# réglages des SubViewports). Un AudioStreamPlayer 2D a un volume constant :
# Kael et Mira entendent leurs actions pareil, où qu'ils soient. Pour garder
# un repère, les sons de Kael penchent un peu à gauche (sa moitié d'écran) et
# ceux de Mira à droite, grâce aux bus SFX_Gauche / SFX_Droite.
# Le ruisseau, lui, doit s'entendre plus fort quand on s'en approche : son
# volume est calculé à la main à partir du joueur le plus proche.
#
# ┌──────────────────────────────────────────────────────────────────────────┐
# │ SI TU RENOMMES UN DE CES FICHIERS OU SIGNAUX, METS À JOUR CE FICHIER     │
# │ (sinon le son se tait sans erreur : on ne se branche que sur ce qu'on    │
# │ reconnaît — un avertissement s'affiche quand main.tscn est chargée)      │
# │                                                                          │
# │ Fichiers reconnus par leur NOM (voir _type_script) :                     │
# │   scripts/puzzles/puzzle_porte_double.gd   signal puzzle_resolu          │
# │   scripts/puzzles/puzzle_oiseau.gd         signaux puzzle_resolu,        │
# │                                            oiseau_appele, grille_changee │
# │   scripts/puzzles/puzzle_roue_eau.gd       signaux puzzle_resolu,        │
# │                                            pont_s_avance, pont_deploye   │
# │   scripts/zones/zone1.gd                   constantes RUISSEAU_* (eau)   │
# │ Signaux reconnus sur n'importe quel nœud :                               │
# │   corne_sonnee, lianes_invoquees (kael.gd)                               │
# │   grappin_active, lanterne_activee (mira.gd)                             │
# │   active (PointInteraction), pressed / focus_entered (boutons)           │
# │ AutoLoads lus :                                                          │
# │   DialogueManager : signal ligne_affichee, est_actif()                   │
# │   GameManager : choix_grimoire                                           │
# │   InteractionManager : cible_pour(id_joueur)                             │
# │ Scènes : MUSIQUE_PAR_SCENE et SCENES_AVEC_AMBIANCE ci-dessous.           │
# └──────────────────────────────────────────────────────────────────────────┘

extends Node

# Le script de la zone : on y lit où coule le ruisseau (constantes RUISSEAU_*).
const Zone1 = preload("res://scripts/zones/zone1.gd")

# ──────────────────────────────────────────────────────────────────────────────
# CATALOGUE DES SONS
# ──────────────────────────────────────────────────────────────────────────────

const DOSSIER_MUSIQUE  := "res://assets/audio/musique/"
const DOSSIER_AMBIANCE := "res://assets/audio/ambiance/"
const DOSSIER_SFX      := "res://assets/audio/sfx/"

const MUSIQUES := ["theme_zone1", "theme_menu", "fin"]
const AMBIANCES := ["ambiance_village", "ruisseau"]
# Ces fichiers tournent en boucle. Les .import n'étant pas versionnés, la boucle
# est réglée ICI, au chargement, pour survivre à n'importe quel réimport.
const EN_BOUCLE := ["theme_zone1", "theme_menu", "ambiance_village", "ruisseau"]

# nom → { fichiers (variantes tirées au hasard), volume en dB, variation de hauteur }
# Tous les WAV sont normalisés à -1 dBFS : c'est ici qu'on règle qui est fort.
const SFX := {
	"corne":          {"fichiers": ["corne"],          "db": -3.0,  "var": 0.0},
	"lianes":         {"fichiers": ["lianes"],         "db": -4.0,  "var": 0.03},
	"grappin":        {"fichiers": ["grappin"],        "db": -5.0,  "var": 0.04},
	"grappin_retour": {"fichiers": ["grappin_retour"], "db": -7.0,  "var": 0.04},
	"lanterne_on":    {"fichiers": ["lanterne_on"],    "db": -5.0,  "var": 0.0},
	"lanterne_off":   {"fichiers": ["lanterne_off"],   "db": -8.0,  "var": 0.0},
	"poignee":        {"fichiers": ["poignee"],        "db": -6.0,  "var": 0.05},
	"porte":          {"fichiers": ["porte"],          "db": -3.0,  "var": 0.0},
	"grille":         {"fichiers": ["grille"],         "db": -5.0,  "var": 0.03},
	"oiseau_chant":   {"fichiers": ["oiseau_chant"],   "db": -6.0,  "var": 0.04},
	"oiseau_envol":   {"fichiers": ["oiseau_envol"],   "db": -6.0,  "var": 0.05},
	"roue":           {"fichiers": ["roue"],           "db": -4.0,  "var": 0.0},
	"pont":           {"fichiers": ["pont"],           "db": -4.0,  "var": 0.0},
	"resolu":         {"fichiers": ["resolu"],         "db": -4.0,  "var": 0.0},
	"dialogue":       {"fichiers": ["dialogue"],       "db": -16.0, "var": 0.0},
	"interaction":    {"fichiers": ["interaction"],    "db": -18.0, "var": 0.02},
	"ui_navigation":  {"fichiers": ["ui_navigation"],  "db": -12.0, "var": 0.02},
	"ui_validation":  {"fichiers": ["ui_validation"],  "db": -8.0,  "var": 0.0},
	"choix_final":    {"fichiers": ["choix_final"],    "db": -3.0,  "var": 0.0},
	"pas_herbe":      {"fichiers": ["pas_herbe_1", "pas_herbe_2", "pas_herbe_3"], "db": -20.0, "var": 0.08},
}

# Quelle musique pour quelle scène. Une scène absente de la liste (écran de
# fin, crédits, test…) ne change PAS la musique en cours.
const MUSIQUE_PAR_SCENE := {
	"res://scenes/menu_principal.tscn": "theme_menu",
	"res://scenes/main.tscn":           "theme_zone1",
	"res://scenes/test_mecanique.tscn": "theme_zone1",
}
# Les scènes jouées dans le village ont l'ambiance (vent, oiseaux, ruisseau).
const SCENES_AVEC_AMBIANCE := ["res://scenes/main.tscn"]

# Le ruisseau du Puzzle 3. Sa position et sa taille ne sont PAS recopiées
# ici : on les lit dans zone1.gd (RUISSEAU_Z, RUISSEAU_LARGEUR, RUISSEAU_X_MIN,
# RUISSEAU_X_MAX), en coordonnées LOCALES de la zone.
const RUISSEAU_PORTEE      := 22.0   # au-delà, on ne l'entend plus
const RUISSEAU_DB          := -3.0
# Vitesse du lissage du volume du ruisseau (plus grand = plus rapide).
const LISSAGE_RUISSEAU     := 6.0

# Les puzzles qu'on s'attend à trouver dans main.tscn, et les signaux dont le
# son a besoin chez chacun. S'il en manque un, on le dit (push_warning).
const DEPENDANCES_PUZZLES := {
	"puzzle_porte_double": ["puzzle_resolu"],
	"puzzle_oiseau":       ["puzzle_resolu", "oiseau_appele", "grille_changee"],
	"puzzle_roue_eau":     ["puzzle_resolu", "pont_s_avance", "pont_deploye"],
}
const SCENE_PRINCIPALE := "res://scenes/main.tscn"

# Bus : nom → [volume par défaut, bus parent, panoramique (0 = aucun)]
# Les mêmes valeurs sont dans default_bus_layout.tres ; on les recrée ici
# seulement si ce fichier est absent (ex. ouvert depuis une autre branche).
const BUS := {
	"Musique":    [-10.0, "Master", 0.0],
	"Ambiance":   [-12.0, "Master", 0.0],
	"SFX":        [-2.0,  "Master", 0.0],
	"SFX_Gauche": [0.0,   "SFX",   -0.3],
	"SFX_Droite": [0.0,   "SFX",    0.3],
}

const FONDU_MUSIQUE: float = 2.0
const NB_LECTEURS_SFX: int = 12
# La musique s'efface un peu sous les dialogues
const ATTENUATION_DIALOGUE_DB: float = -4.0
# Les pas (voir _surveiller_pas) : un bruit à chaque appui des animations.
# Sous SEUIL_PAS (m/s), on ne joue plus de pas (personnage quasi arrêté).
const SEUIL_PAS: float = 0.8
# Ajustement de volume, ajouté à celui du catalogue : plus doux en marche,
# plus appuyé en course.
const PAS_MARCHE_DB: float = -3.0
const PAS_COURSE_DB: float = 2.5

# ──────────────────────────────────────────────────────────────────────────────
# ÉTAT
# ──────────────────────────────────────────────────────────────────────────────

var musique_courante: String = ""
# Le dernier bruitage joué — sert aux tests headless.
var dernier_sfx: String = ""

var _musique_a: AudioStreamPlayer
var _musique_b: AudioStreamPlayer
var _musique_active: AudioStreamPlayer
var _tween_musique: Tween
var _ambiance: AudioStreamPlayer
var _ruisseau: AudioStreamPlayer
var _tween_ambiance: Tween
var _lecteurs: Array[AudioStreamPlayer] = []
var _prochain_lecteur: int = 0

var _cache: Dictionary = {}            # chemin → AudioStream (ou null si absent)
var _absents_signales: Dictionary = {} # nom/chemin déjà signalé (un seul avertissement)

var _scene_courante: Node = null
var _fin_en_cours: bool = false
var _instant_scene: float = 0.0        # secondes depuis le dernier changement de scène

# Nœuds surveillés (on vérifie is_instance_valid : ils peuvent être libérés)
var _personnages: Array = []           # CharacterBase, pour les pas
var _foulee: Dictionary = {}           # instance_id → phase du cycle de pas (ou distance)
var _puzzles_vus: Dictionary = {}      # "puzzle_oiseau" → le nœud (voir _verifier_branchements)
var _zone: Node3D = null               # zone1, pour situer le ruisseau

var _choix_grimoire_avant: String = ""
var _cibles_avant: Dictionary = {1: null, 2: null}
var _attenuation_db: float = 0.0
# Volume « normal » du bus Musique (même valeur que BUS) ; l'atténuation s'y ajoute
var _volume_musique_db: float = -10.0
var _derniere_nav_ui: int = 0

# ──────────────────────────────────────────────────────────────────────────────
# DÉMARRAGE
# ──────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# L'AudioManager tourne même quand le jeu est en pause (menu pause) : la
	# musique et les fondus continuent. Les surveillances qui n'ont pas de sens
	# en pause (pas, cibles) s'arrêtent d'elles-mêmes (voir get_tree().paused).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_assurer_bus()

	_musique_a = _creer_lecteur("Musique")
	_musique_b = _creer_lecteur("Musique")
	_musique_active = _musique_a
	_ambiance = _creer_lecteur("Ambiance")
	_ruisseau = _creer_lecteur("Ambiance")
	for i in NB_LECTEURS_SFX:
		_lecteurs.append(_creer_lecteur("SFX"))

	if GameManager:
		_choix_grimoire_avant = GameManager.choix_grimoire

	# Dorénavant, chaque nœud qui entre dans l'arbre passe par _examiner()
	get_tree().node_added.connect(_sur_noeud_ajoute)
	# … et ceux qui y sont déjà (si l'AudioManager arrive après eux)
	_examiner_arbre(get_tree().root)

	# Un petit « blip » à chaque nouvelle ligne de dialogue.
	DialogueManager.ligne_affichee.connect(_sur_ligne_affichee)

func _creer_lecteur(bus: String) -> AudioStreamPlayer:
	var lecteur := AudioStreamPlayer.new()
	lecteur.bus = bus
	add_child(lecteur)
	return lecteur

func _assurer_bus() -> void:
	for nom in BUS:
		if AudioServer.get_bus_index(nom) != -1:
			continue
		var reglage: Array = BUS[nom]
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, nom)
		AudioServer.set_bus_volume_db(idx, reglage[0])
		AudioServer.set_bus_send(idx, reglage[1])
		if reglage[2] != 0.0:
			var panner := AudioEffectPanner.new()
			panner.pan = reglage[2]
			AudioServer.add_bus_effect(idx, panner)

# ──────────────────────────────────────────────────────────────────────────────
# API PUBLIQUE
# ──────────────────────────────────────────────────────────────────────────────

# Joue un bruitage.
#   cote    : -1 = Kael (penche à gauche), 1 = Mira (à droite), 0 = centre
#   volume_db / hauteur : ajustements ponctuels (s'ajoutent au catalogue)
func jouer_sfx(nom: String, cote: int = 0, volume_db: float = 0.0, hauteur: float = 1.0) -> void:
	if not SFX.has(nom):
		_signaler_absent(nom, "AudioManager : bruitage inconnu '%s' (ignoré)" % nom)
		return
	var def: Dictionary = SFX[nom]
	var fichiers: Array = def["fichiers"]
	var fichier: String = fichiers[randi() % fichiers.size()]
	var flux := _charger(DOSSIER_SFX + fichier + ".wav", false)
	if flux == null:
		return

	var lecteur := _lecteurs[_prochain_lecteur]
	_prochain_lecteur = (_prochain_lecteur + 1) % _lecteurs.size()
	lecteur.stream = flux
	lecteur.bus = "SFX_Gauche" if cote < 0 else ("SFX_Droite" if cote > 0 else "SFX")
	lecteur.volume_db = float(def["db"]) + volume_db
	var variation: float = def["var"]
	lecteur.pitch_scale = hauteur * randf_range(1.0 - variation, 1.0 + variation)
	lecteur.play()
	dernier_sfx = nom

# Fondu enchaîné vers un morceau (theme_zone1, theme_menu, fin).
func jouer_musique(nom: String, fondu: float = FONDU_MUSIQUE) -> void:
	if nom == musique_courante:
		return
	if not MUSIQUES.has(nom):
		_signaler_absent(nom, "AudioManager : musique inconnue '%s' (ignorée)" % nom)
		return
	var flux := _charger(DOSSIER_MUSIQUE + nom + ".wav", EN_BOUCLE.has(nom))
	if flux == null:
		return
	musique_courante = nom

	var ancienne := _musique_active
	var nouvelle := _musique_b if _musique_active == _musique_a else _musique_a
	_musique_active = nouvelle

	nouvelle.stream = flux
	nouvelle.volume_db = -60.0
	nouvelle.play()

	if _tween_musique:
		_tween_musique.kill()
	_tween_musique = create_tween().set_parallel(true)
	_tween_musique.tween_property(nouvelle, "volume_db", 0.0, fondu) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if ancienne.playing:
		_tween_musique.tween_property(ancienne, "volume_db", -60.0, fondu) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tween_musique.chain().tween_callback(ancienne.stop)

func arreter_musique(fondu: float = FONDU_MUSIQUE) -> void:
	musique_courante = ""
	if _tween_musique:
		_tween_musique.kill()
	_tween_musique = create_tween().set_parallel(true)
	for lecteur in [_musique_a, _musique_b]:
		if lecteur.playing:
			_tween_musique.tween_property(lecteur, "volume_db", -60.0, fondu)
	_tween_musique.chain().tween_callback(func():
		_musique_a.stop()
		_musique_b.stop())

# À appeler par l'écran de fin : musique de fin (sans boucle), ambiances coupées.
# Un changement de scène vers une scène inconnue (crédits…) ne la coupera pas.
func jouer_fin() -> void:
	_fin_en_cours = true
	jouer_musique("fin", 2.5)
	_arreter_ambiances(3.0)

# Règle le volume d'un bus ("Musique", "Ambiance", "SFX") — pour un futur menu d'options.
func definir_volume(bus: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return
	if bus == "Musique":
		_volume_musique_db = db
	else:
		AudioServer.set_bus_volume_db(idx, db)

# Tous les fichiers que l'AudioManager peut demander (utilisé par le test).
func tous_les_chemins() -> Array[String]:
	var liste: Array[String] = []
	for nom in MUSIQUES:
		liste.append(DOSSIER_MUSIQUE + nom + ".wav")
	for nom in AMBIANCES:
		liste.append(DOSSIER_AMBIANCE + nom + ".wav")
	for nom in SFX:
		for fichier in SFX[nom]["fichiers"]:
			liste.append(DOSSIER_SFX + fichier + ".wav")
	return liste

# ──────────────────────────────────────────────────────────────────────────────
# CHARGEMENT
# ──────────────────────────────────────────────────────────────────────────────

func _charger(chemin: String, boucle: bool) -> AudioStream:
	if _cache.has(chemin):
		return _cache[chemin]
	var flux: AudioStream = null
	if ResourceLoader.exists(chemin):
		flux = load(chemin) as AudioStream
	if flux == null:
		_signaler_absent(chemin, "AudioManager : fichier absent ou non importé : %s" % chemin)
	elif flux is AudioStreamWAV:
		var wav := flux as AudioStreamWAV
		if boucle:
			# Boucle sur le fichier entier : le générateur a replié la fin
			# sur le début, la couture est donc invisible.
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
		else:
			wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif "loop" in flux:
		# Si un jour un morceau passe en .ogg
		flux.set("loop", boucle)
	_cache[chemin] = flux
	return flux

func _signaler_absent(cle: String, message: String) -> void:
	if _absents_signales.has(cle):
		return
	_absents_signales[cle] = true
	push_warning(message)

# ──────────────────────────────────────────────────────────────────────────────
# BRANCHEMENTS AUTOMATIQUES
# ──────────────────────────────────────────────────────────────────────────────

func _examiner_arbre(noeud: Node) -> void:
	_examiner(noeud)
	for enfant in noeud.get_children():
		_examiner_arbre(enfant)

func _sur_noeud_ajoute(noeud: Node) -> void:
	_examiner(noeud)

# Regarde un nœud et se branche sur ce qu'il sait faire. Une métadonnée évite
# de se connecter deux fois au même nœud.
func _examiner(noeud: Node) -> void:
	if noeud == self or noeud.has_meta("_audio_branche"):
		return

	var branche := false

	# ── Kael ──
	if noeud.has_signal("corne_sonnee"):
		noeud.connect("corne_sonnee", _sur_corne)
		branche = true
	if noeud.has_signal("lianes_invoquees"):
		noeud.connect("lianes_invoquees", _sur_lianes)
		branche = true
	# ── Mira ──
	if noeud.has_signal("grappin_active"):
		noeud.connect("grappin_active", _sur_grappin)
		branche = true
	if noeud.has_signal("lanterne_activee"):
		noeud.connect("lanterne_activee", _sur_lanterne)
		branche = true
	# ── Les deux héros : les pas ──
	if noeud is CharacterBase:
		_personnages.append(noeud)
		branche = true
	# ── Puzzles ──
	if noeud.has_signal("puzzle_resolu"):
		noeud.connect("puzzle_resolu", _sur_puzzle_resolu.bind(noeud))
		branche = true
	if DEPENDANCES_PUZZLES.has(_type_script(noeud)):
		_puzzles_vus[_type_script(noeud)] = noeud
	# Puzzle 2 : l'oiseau et la grille
	if noeud.has_signal("oiseau_appele"):
		noeud.connect("oiseau_appele", _sur_oiseau_appele)
		branche = true
	if noeud.has_signal("grille_changee"):
		noeud.connect("grille_changee", _sur_grille_changee)
		branche = true
	# Puzzle 3 : le pont
	if noeud.has_signal("pont_s_avance"):
		noeud.connect("pont_s_avance", _sur_pont_s_avance)
		branche = true
	if noeud.has_signal("pont_deploye"):
		noeud.connect("pont_deploye", _sur_pont_deploye)
		branche = true
	# ── Poignées, verrous ──
	if noeud is PointInteraction:
		noeud.connect("active", _sur_point_active.bind(noeud))
		branche = true
	# ── La zone (pour situer le ruisseau) ──
	if _type_script(noeud) == "zone1":
		_zone = noeud as Node3D
		branche = true
	# ── Boutons d'interface (menu, écran de fin…) ──
	if noeud is BaseButton:
		noeud.connect("focus_entered", _sur_ui_survol)
		noeud.connect("mouse_entered", _sur_ui_survol)
		noeud.connect("pressed", _sur_ui_presse)
		branche = true

	if branche:
		noeud.set_meta("_audio_branche", true)

# "res://scripts/puzzles/puzzle_oiseau.gd" → "puzzle_oiseau"
func _type_script(noeud: Node) -> String:
	var scr = noeud.get_script()
	if scr == null or not (scr is Script):
		return ""
	return (scr as Script).resource_path.get_file().get_basename()

# ── Réactions aux signaux ─────────────────────────────────────────────────────

func _sur_corne() -> void:
	jouer_sfx("corne", -1)

func _sur_lianes(_position: Vector3) -> void:
	jouer_sfx("lianes", -1)

func _sur_grappin(actif: bool) -> void:
	jouer_sfx("grappin" if actif else "grappin_retour", 1)

func _sur_lanterne(allumee: bool) -> void:
	jouer_sfx("lanterne_on" if allumee else "lanterne_off", 1)

func _sur_point_active(id_joueur: int, point: Node) -> void:
	# Seules les poignées et verrous des puzzles font « clac » : un futur point
	# d'interaction du décor choisira son propre son.
	if point.get_parent() != null and _type_script(point.get_parent()).begins_with("puzzle_"):
		jouer_sfx("poignee", -1 if id_joueur == 1 else 1)

func _sur_puzzle_resolu(puzzle: Node) -> void:
	match _type_script(puzzle):
		"puzzle_porte_double":
			# La porte monte en 1,5 s (tween du puzzle) ; le carillon après.
			jouer_sfx("porte")
			_plus_tard(1.6, "resolu")
		"puzzle_roue_eau":
			# La roue tourne tout de suite. Le pont et le carillon suivent sur
			# les signaux du puzzle (_sur_pont_s_avance, _sur_pont_deploye).
			jouer_sfx("roue")
		_:
			# Puzzle de l'oiseau (le verrou a déjà fait « clac ») et tout futur puzzle
			_plus_tard(0.3, "resolu")

# Puzzle 2 : l'oiseau répond à la Corne, puis s'envole vers la plateforme.
func _sur_oiseau_appele() -> void:
	jouer_sfx("oiseau_chant")
	_plus_tard(0.45, "oiseau_envol")

# Puzzle 2 : la grille se lève ou retombe.
func _sur_grille_changee(ouverte: bool) -> void:
	jouer_sfx("grille")
	if not ouverte:
		# Le temps est écoulé : l'oiseau repart sur son perchoir
		jouer_sfx("oiseau_envol", 0, -4.0)

# Puzzle 3 : le pont glisse sur le ruisseau…
func _sur_pont_s_avance() -> void:
	jouer_sfx("pont")

# … et se pose : le puzzle est vraiment fini, carillon.
func _sur_pont_deploye() -> void:
	jouer_sfx("resolu")

# Joue un bruitage dans `delai` secondes. Le 2e argument de create_timer,
# false, ARRÊTE la minuterie pendant la pause : pas de son qui part sous le menu.
func _plus_tard(delai: float, nom: String) -> void:
	get_tree().create_timer(delai, false).timeout.connect(func(): jouer_sfx(nom))

func _sur_ui_survol() -> void:
	# Pas de « tic » au tout début d'une scène (focus automatique) ni en rafale
	if _instant_scene < 0.25:
		return
	var maintenant := Time.get_ticks_msec()
	if maintenant - _derniere_nav_ui < 60:
		return
	_derniere_nav_ui = maintenant
	jouer_sfx("ui_navigation")

func _sur_ui_presse() -> void:
	jouer_sfx("ui_validation")

# Branchée sur DialogueManager.ligne_affichee : ce signal n'a pas d'argument,
# donc la fonction n'a pas de paramètre (sinon Godot refuse de l'appeler).
func _sur_ligne_affichee() -> void:
	# Hauteur variée d'une ligne à l'autre : on « entend » quelqu'un parler
	jouer_sfx("dialogue", 0, 0.0, randf_range(0.88, 1.15))

# ──────────────────────────────────────────────────────────────────────────────
# SURVEILLANCE IMAGE PAR IMAGE
# ──────────────────────────────────────────────────────────────────────────────
# Certains états n'ont pas de signal (le changement de scène, le choix du
# grimoire, la cible visée par un joueur, la marche). On compare l'état d'une
# image à l'autre : quand il bascule, on joue le son. Lecture seule — on ne
# modifie jamais les autres scripts.

func _process(delta: float) -> void:
	_instant_scene += delta
	_surveiller_scene()
	_surveiller_choix()
	_surveiller_cibles()
	_surveiller_pas(delta)
	_mettre_a_jour_ruisseau(delta)
	_mettre_a_jour_attenuation(delta)

func _surveiller_scene() -> void:
	var scene := get_tree().current_scene
	if scene == _scene_courante:
		return
	_scene_courante = scene
	_instant_scene = 0.0
	if scene == null:
		return
	var chemin := scene.scene_file_path
	if chemin == SCENE_PRINCIPALE:
		_verifier_branchements(scene)
	if MUSIQUE_PAR_SCENE.has(chemin):
		_fin_en_cours = false
		jouer_musique(MUSIQUE_PAR_SCENE[chemin])
	if _fin_en_cours:
		return
	if SCENES_AVEC_AMBIANCE.has(chemin):
		_demarrer_ambiances()
	elif MUSIQUE_PAR_SCENE.has(chemin):
		_arreter_ambiances(1.5)

# La scène principale vient d'être chargée : chaque puzzle attendu a-t-il été
# trouvé, avec les signaux dont le son a besoin ? Sinon, un avertissement dans
# la console (le jeu marche, mais sans ces sons) — voir l'encadré en tête.
func _verifier_branchements(scene: Node) -> void:
	for nom_script in DEPENDANCES_PUZZLES:
		var puzzle = _puzzles_vus.get(nom_script)
		if puzzle == null or not is_instance_valid(puzzle) or not scene.is_ancestor_of(puzzle):
			push_warning("AudioManager : aucun nœud avec le script %s.gd dans %s — ses sons ne joueront pas" % [nom_script, scene.scene_file_path])
			continue
		for nom_signal in DEPENDANCES_PUZZLES[nom_script]:
			if not puzzle.has_signal(nom_signal):
				push_warning("AudioManager : %s.gd n'a plus de signal '%s' — son muet" % [nom_script, nom_signal])
	if _zone == null or not is_instance_valid(_zone) or not scene.is_ancestor_of(_zone):
		push_warning("AudioManager : zone1.gd introuvable dans %s — le ruisseau restera muet" % scene.scene_file_path)

func _surveiller_choix() -> void:
	var choix: String = GameManager.choix_grimoire
	if choix != _choix_grimoire_avant and choix != "":
		jouer_sfx("choix_final")
	_choix_grimoire_avant = choix

# Un petit tintement quand un objet devient interactif pour un joueur.
func _surveiller_cibles() -> void:
	# En pause, rien ne bouge : pas de tintement sous le menu.
	if get_tree().paused:
		return
	var im := get_node_or_null("/root/InteractionManager")
	if im == null:
		return
	for id_joueur in [1, 2]:
		var cible = im.cible_pour(id_joueur)
		if cible != null and cible != _cibles_avant[id_joueur]:
			jouer_sfx("interaction", -1 if id_joueur == 1 else 1)
		_cibles_avant[id_joueur] = cible

# LES PAS SUIVENT LES PIEDS
# Les héros sont animés (character_base.gd) : un cycle de marche ou de course
# dure 1 s dans le fichier, et le pied gauche se pose à la phase 0, le droit à
# la phase 0,5 (tools/animer_personnages.py). On lit donc la position de
# lecture du mélange marche/course dans l'AnimationTree (le paramètre
# « parameters/allure/current_position », entre 0 et 1) et l'on joue un pas
# chaque fois qu'elle franchit 0 ou 0,5 : le son tombe pile sur l'appui,
# quelle que soit la vitesse (l'arbre accélère la cadence avec elle).
# Sans arbre d'animation (modèle absent), on retombe sur une distance :
# un appui tous les FOULEE_* / 2 mètres.
func _surveiller_pas(delta: float) -> void:
	# En pause, les personnages sont figés mais gardent leur vitesse : sans ce
	# test, on entendrait des pas sous le menu pause.
	if get_tree().paused:
		return
	for perso in _personnages:
		if not is_instance_valid(perso) or not perso.is_inside_tree():
			continue
		var corps := perso as CharacterBody3D
		var vitesse := Vector2(corps.velocity.x, corps.velocity.z).length()
		var id: int = perso.get_instance_id()
		# 0 = marche, 1 = course (même calcul que character_base.gd).
		var allure := clampf((vitesse - CharacterBase.VITESSE_MARCHE)
			/ (CharacterBase.VITESSE_COURSE - CharacterBase.VITESSE_MARCHE), 0.0, 1.0)
		var appui := false

		var arbre := _arbre_de(perso)
		if arbre != null:
			var phase := fmod(float(arbre.get("parameters/allure/current_position")), 1.0)
			var avant: float = _foulee.get(id, phase)
			_foulee[id] = phase
			# Franchissement de 0 (la phase repart de zéro) ou de 0,5.
			appui = phase < avant or (avant < 0.5 and phase >= 0.5)
		else:
			var demi_foulee := lerpf(CharacterBase.FOULEE_MARCHE, CharacterBase.FOULEE_COURSE, allure) * 0.5
			if vitesse < SEUIL_PAS:
				_foulee[id] = demi_foulee * 0.7  # le prochain pas tombe dès qu'on repart
			else:
				_foulee[id] = _foulee.get(id, 0.0) + vitesse * delta
				if _foulee[id] >= demi_foulee:
					_foulee[id] = 0.0
					appui = true

		# Pas de pas en l'air, ni quand on piétine sur place (les jambes
		# bougent encore un peu en ralentissant, mais le pied ne frappe plus).
		if appui and corps.is_on_floor() and vitesse >= SEUIL_PAS:
			jouer_sfx("pas_herbe", -1 if perso.get("id_joueur") == 1 else 1,
				lerpf(PAS_MARCHE_DB, PAS_COURSE_DB, allure),
				lerpf(1.0, 0.94, allure))
	_personnages = _personnages.filter(func(p): return is_instance_valid(p))

# L'AnimationTree construit par character_base.gd (null si le modèle n'est
# pas animé). Gardé en cache dans les métadonnées du personnage.
func _arbre_de(perso: Node) -> AnimationTree:
	if not perso.has_meta("_audio_arbre"):
		var trouve := perso.find_child("AnimationTree", true, false)
		if trouve == null:
			return null  # pas encore construit : on réessaiera
		perso.set_meta("_audio_arbre", trouve)
	var arbre = perso.get_meta("_audio_arbre")
	if not is_instance_valid(arbre):
		perso.remove_meta("_audio_arbre")
		return null
	return arbre as AnimationTree

# ──────────────────────────────────────────────────────────────────────────────
# AMBIANCES
# ──────────────────────────────────────────────────────────────────────────────

func _demarrer_ambiances() -> void:
	if _tween_ambiance:
		_tween_ambiance.kill()
	var village := _charger(DOSSIER_AMBIANCE + "ambiance_village.wav", true)
	if village and not _ambiance.playing:
		_ambiance.stream = village
		_ambiance.volume_db = -60.0
		_ambiance.play()
	var eau := _charger(DOSSIER_AMBIANCE + "ruisseau.wav", true)
	if eau and not _ruisseau.playing:
		_ruisseau.stream = eau
		_ruisseau.volume_db = -80.0
		_ruisseau.play()
	_tween_ambiance = create_tween()
	_tween_ambiance.tween_property(_ambiance, "volume_db", 0.0, 3.0)

func _arreter_ambiances(fondu: float) -> void:
	if _tween_ambiance:
		_tween_ambiance.kill()
	_tween_ambiance = create_tween().set_parallel(true)
	_tween_ambiance.tween_property(_ambiance, "volume_db", -60.0, fondu)
	_tween_ambiance.tween_property(_ruisseau, "volume_db", -80.0, fondu)
	_tween_ambiance.chain().tween_callback(func():
		_ambiance.stop()
		_ruisseau.stop())

# Volume du ruisseau selon le joueur le plus proche de l'eau.
func _mettre_a_jour_ruisseau(delta: float) -> void:
	if not _ruisseau.playing or _fin_en_cours:
		return
	if _zone == null or not is_instance_valid(_zone) or not _zone.is_inside_tree():
		_ruisseau.volume_db = -80.0
		return
	# Le lit du ruisseau, vu de dessus : un rectangle (centre + demi-taille).
	var centre := Vector2((Zone1.RUISSEAU_X_MIN + Zone1.RUISSEAU_X_MAX) * 0.5, Zone1.RUISSEAU_Z)
	var demi_taille := Vector2((Zone1.RUISSEAU_X_MAX - Zone1.RUISSEAU_X_MIN) * 0.5,
		Zone1.RUISSEAU_LARGEUR * 0.5)
	var distance_min := INF
	for perso in _personnages:
		if not is_instance_valid(perso) or not perso.is_inside_tree():
			continue
		var local: Vector3 = _zone.to_local((perso as Node3D).global_position)
		# Distance au bord du rectangle (0 si on est au-dessus de l'eau)
		var dx: float = maxf(absf(local.x - centre.x) - demi_taille.x, 0.0)
		var dz: float = maxf(absf(local.z - centre.y) - demi_taille.y, 0.0)
		distance_min = minf(distance_min, sqrt(dx * dx + dz * dz))
	var gain: float = clampf(1.0 - distance_min / RUISSEAU_PORTEE, 0.0, 1.0)
	gain *= gain
	var cible_db: float = linear_to_db(maxf(gain, 0.0001)) + RUISSEAU_DB
	# Lissage : pas de saut de volume brutal. On parcourt à chaque image une
	# fraction du chemin qui dépend de delta : le même fondu à 30 ou 144 i/s.
	var fraction: float = 1.0 - exp(-LISSAGE_RUISSEAU * delta)
	_ruisseau.volume_db = lerpf(_ruisseau.volume_db, cible_db, fraction)

# La musique baisse de quelques dB pendant les dialogues, puis remonte.
# Jamais pendant la musique de fin : elle doit sonner pleinement.
func _mettre_a_jour_attenuation(delta: float) -> void:
	var cible: float = 0.0
	if DialogueManager.est_actif() and not _fin_en_cours:
		cible = ATTENUATION_DIALOGUE_DB
	_attenuation_db = move_toward(_attenuation_db, cible, 6.0 * delta)
	var idx := AudioServer.get_bus_index("Musique")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, _volume_musique_db + _attenuation_db)
