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

extends Node

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

# Le ruisseau du Puzzle 3, en coordonnées LOCALES de zone1 (voir zone1.gd,
# _construire_village : « Fond du ruisseau (eau) » 16 × 7,5 m centré en -22, -34).
const RUISSEAU_CENTRE      := Vector2(-22.0, -34.0)
const RUISSEAU_DEMI_TAILLE := Vector2(8.0, 3.75)
const RUISSEAU_PORTEE      := 22.0   # au-delà, on ne l'entend plus
const RUISSEAU_DB          := -3.0

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
# Un pas tous les ~1,7 m parcourus
const FOULEE: float = 1.7

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
var _foulee: Dictionary = {}           # instance_id → distance parcourue
var _puzzles_oiseau: Array = []
var _etat_oiseau: Dictionary = {}      # instance_id → [oiseau_attire, grille_ouverte]
var _zone: Node3D = null               # zone1, pour situer le ruisseau

var _dialogue_actif_avant: bool = false
var _dernier_texte_dialogue: String = ""
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
	# Le son continue même si le jeu est mis en pause (menu pause à venir)
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

	# Si une ligne de dialogue est un jour annoncée par un signal, on le préfère
	# à la surveillance image par image (voir _surveiller_dialogue).
	if DialogueManager.has_signal("ligne_affichee"):
		DialogueManager.connect("ligne_affichee", _sur_ligne_affichee)

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
		if _type_script(noeud) == "puzzle_oiseau":
			_puzzles_oiseau.append(noeud)
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
			# Dans le puzzle : la roue tourne tout de suite, le pont part à 1,5 s.
			jouer_sfx("roue")
			_plus_tard(1.5, "pont")
			_plus_tard(3.2, "resolu")
		_:
			# Puzzle de l'oiseau (le verrou a déjà fait « clac ») et tout futur puzzle
			_plus_tard(0.3, "resolu")

func _plus_tard(delai: float, nom: String) -> void:
	get_tree().create_timer(delai, true).timeout.connect(func(): jouer_sfx(nom))

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

func _sur_ligne_affichee(_a = null, _b = null) -> void:
	_jouer_blip_dialogue()

func _jouer_blip_dialogue() -> void:
	# Hauteur variée d'une ligne à l'autre : on « entend » quelqu'un parler
	jouer_sfx("dialogue", 0, 0.0, randf_range(0.88, 1.15))

# ──────────────────────────────────────────────────────────────────────────────
# SURVEILLANCE IMAGE PAR IMAGE
# ──────────────────────────────────────────────────────────────────────────────
# Certains événements n'ont pas de signal (la grille qui s'ouvre, l'oiseau qui
# s'envole, une nouvelle ligne de dialogue). On compare l'état d'une image à
# l'autre : quand une variable bascule, on joue le son. Lecture seule — on ne
# modifie jamais les autres scripts.

func _process(delta: float) -> void:
	_instant_scene += delta
	_surveiller_scene()
	_surveiller_oiseaux()
	if not DialogueManager.has_signal("ligne_affichee"):
		_surveiller_dialogue()
	_surveiller_choix()
	_surveiller_cibles()
	_surveiller_pas(delta)
	_mettre_a_jour_ruisseau()
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
	if MUSIQUE_PAR_SCENE.has(chemin):
		_fin_en_cours = false
		jouer_musique(MUSIQUE_PAR_SCENE[chemin])
	if _fin_en_cours:
		return
	if SCENES_AVEC_AMBIANCE.has(chemin):
		_demarrer_ambiances()
	elif MUSIQUE_PAR_SCENE.has(chemin):
		_arreter_ambiances(1.5)

func _surveiller_oiseaux() -> void:
	for puzzle in _puzzles_oiseau:
		if not is_instance_valid(puzzle):
			continue
		var id: int = puzzle.get_instance_id()
		var attire: bool = puzzle.get("oiseau_attire")
		var ouverte: bool = puzzle.get("grille_ouverte")
		var avant: Array = _etat_oiseau.get(id, [false, false])
		if attire and not avant[0]:
			# L'oiseau répond à la Corne, puis s'envole vers la plateforme
			jouer_sfx("oiseau_chant")
			_plus_tard(0.45, "oiseau_envol")
		if ouverte != avant[1]:
			jouer_sfx("grille")
			if not ouverte:
				# Le temps est écoulé : l'oiseau repart sur son perchoir
				jouer_sfx("oiseau_envol", 0, -4.0)
		_etat_oiseau[id] = [attire, ouverte]
	_puzzles_oiseau = _puzzles_oiseau.filter(func(p): return is_instance_valid(p))

# DialogueManager n'émet pas de signal par ligne : on regarde le texte affiché.
# (Si un signal `ligne_affichee` est ajouté un jour, il est utilisé à la place.)
func _surveiller_dialogue() -> void:
	var actif: bool = DialogueManager.est_actif()
	var texte := ""
	var label = DialogueManager.get("_label_texte")
	if label is Label:
		texte = label.text
	if actif and (not _dialogue_actif_avant or texte != _dernier_texte_dialogue):
		_jouer_blip_dialogue()
	_dialogue_actif_avant = actif
	_dernier_texte_dialogue = texte

func _surveiller_choix() -> void:
	var choix: String = GameManager.choix_grimoire
	if choix != _choix_grimoire_avant and choix != "":
		jouer_sfx("choix_final")
	_choix_grimoire_avant = choix

# Un petit tintement quand un objet devient interactif pour un joueur.
func _surveiller_cibles() -> void:
	var im := get_node_or_null("/root/InteractionManager")
	if im == null:
		return
	for id_joueur in [1, 2]:
		var cible = im.cible_pour(id_joueur)
		if cible != null and cible != _cibles_avant[id_joueur]:
			jouer_sfx("interaction", -1 if id_joueur == 1 else 1)
		_cibles_avant[id_joueur] = cible

func _surveiller_pas(delta: float) -> void:
	for perso in _personnages:
		if not is_instance_valid(perso) or not perso.is_inside_tree():
			continue
		var corps := perso as CharacterBody3D
		var vitesse := Vector2(corps.velocity.x, corps.velocity.z).length()
		var id: int = perso.get_instance_id()
		if not corps.is_on_floor() or vitesse < 1.0:
			# À l'arrêt : le prochain pas tombera dès qu'on repart
			_foulee[id] = FOULEE * 0.7
			continue
		_foulee[id] = _foulee.get(id, 0.0) + vitesse * delta
		if _foulee[id] >= FOULEE:
			_foulee[id] = 0.0
			jouer_sfx("pas_herbe", -1 if perso.get("id_joueur") == 1 else 1)
	_personnages = _personnages.filter(func(p): return is_instance_valid(p))

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
func _mettre_a_jour_ruisseau() -> void:
	if not _ruisseau.playing or _fin_en_cours:
		return
	if _zone == null or not is_instance_valid(_zone) or not _zone.is_inside_tree():
		_ruisseau.volume_db = -80.0
		return
	var distance_min := INF
	for perso in _personnages:
		if not is_instance_valid(perso) or not perso.is_inside_tree():
			continue
		var local: Vector3 = _zone.to_local((perso as Node3D).global_position)
		var dx: float = maxf(absf(local.x - RUISSEAU_CENTRE.x) - RUISSEAU_DEMI_TAILLE.x, 0.0)
		var dz: float = maxf(absf(local.z - RUISSEAU_CENTRE.y) - RUISSEAU_DEMI_TAILLE.y, 0.0)
		distance_min = minf(distance_min, sqrt(dx * dx + dz * dz))
	var gain: float = clampf(1.0 - distance_min / RUISSEAU_PORTEE, 0.0, 1.0)
	gain *= gain
	var cible_db: float = linear_to_db(maxf(gain, 0.0001)) + RUISSEAU_DB
	# Lissage : pas de saut de volume brutal
	_ruisseau.volume_db = lerpf(_ruisseau.volume_db, cible_db, 0.1)

# La musique baisse de quelques dB pendant les dialogues, puis remonte.
func _mettre_a_jour_attenuation(delta: float) -> void:
	var cible: float = ATTENUATION_DIALOGUE_DB if DialogueManager.est_actif() else 0.0
	_attenuation_db = move_toward(_attenuation_db, cible, 6.0 * delta)
	var idx := AudioServer.get_bus_index("Musique")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, _volume_musique_db + _attenuation_db)
