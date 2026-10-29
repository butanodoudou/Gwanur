# tools/tests/test_audio.gd
# Vérifie l'AudioManager :
#   - l'AutoLoad est chargé et les bus Musique / Ambiance / SFX existent
#   - chaque fichier référencé existe et se charge comme un AudioStream
#   - les musiques et ambiances bouclées le sont bien (réglage fait en code)
#   - un nom inconnu ne fait rien planter
#   - les signaux EXISTANTS de Kael et Mira déclenchent leurs bruitages
#
# Prérequis : les WAV générés ET importés
#   blender --background --python tools/gen_audio.py
#   godot --headless --path . --import
# Lancer :
#   godot --headless --path . res://tools/tests/test_audio.tscn --quit-after 600

extends Node

var _echecs: int = 0

func _ready() -> void:
	print("--- Test Audio ---")
	var am := get_node_or_null("/root/AudioManager")
	_verifier("AudioManager charge en AutoLoad", str(am != null), "true")
	if am == null:
		_conclure()
		return

	for bus in ["Musique", "Ambiance", "SFX", "SFX_Gauche", "SFX_Droite"]:
		_verifier("Bus %s present" % bus, str(AudioServer.get_bus_index(bus) != -1), "true")

	# Chaque fichier du catalogue
	for chemin in am.tous_les_chemins():
		var existe := ResourceLoader.exists(chemin)
		var flux: AudioStream = load(chemin) as AudioStream if existe else null
		_verifier("Charge %s" % chemin.get_file(), str(flux != null), "true")

	# Boucles
	for nom in ["theme_zone1", "theme_menu"]:
		var f = am._charger("res://assets/audio/musique/%s.wav" % nom, true)
		if f is AudioStreamWAV:
			_verifier("%s en boucle" % nom, str(f.loop_mode), str(AudioStreamWAV.LOOP_FORWARD))
	var fin = am._charger("res://assets/audio/musique/fin.wav", false)
	if fin is AudioStreamWAV:
		_verifier("fin sans boucle", str(fin.loop_mode), str(AudioStreamWAV.LOOP_DISABLED))

	# Noms inconnus : rien ne doit planter
	am.jouer_sfx("son_qui_n_existe_pas")
	am.jouer_musique("musique_qui_n_existe_pas")
	_verifier("Nom inconnu ignore sans crash", "true", "true")

	# API directe
	am.jouer_sfx("resolu")
	_verifier("jouer_sfx('resolu')", am.dernier_sfx, "resolu")
	am.jouer_musique("theme_menu", 0.1)
	_verifier("jouer_musique('theme_menu')", am.musique_courante, "theme_menu")
	am.jouer_fin()
	_verifier("jouer_fin()", am.musique_courante, "fin")

	# Branchement automatique sur les signaux des personnages
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var kael = get_tree().get_first_node_in_group("kael")
	var mira = get_tree().get_first_node_in_group("mira")
	kael.corne_sonnee.emit()
	_verifier("Corne de Kael -> 'corne'", am.dernier_sfx, "corne")
	kael.lianes_invoquees.emit(Vector3.ZERO)
	_verifier("Lianes de Kael -> 'lianes'", am.dernier_sfx, "lianes")
	mira.grappin_active.emit(true)
	_verifier("Grappin de Mira -> 'grappin'", am.dernier_sfx, "grappin")
	mira.lanterne_activee.emit(true)
	_verifier("Lanterne de Mira -> 'lanterne_on'", am.dernier_sfx, "lanterne_on")
	_verifier("Zone 1 reperee (ruisseau)", str(am._zone != null), "true")

	_conclure()

func _conclure() -> void:
	if _echecs == 0:
		print("--- RESULTAT : tout est OK ---")
	else:
		print("--- RESULTAT : %d ECHEC(S) ---" % _echecs)
	get_tree().quit()

func _verifier(quoi: String, obtenu: String, attendu: String) -> void:
	if obtenu == attendu:
		print("  OK   : %s" % quoi)
	else:
		_echecs += 1
		print("  ECHEC: %s  (attendu '%s', obtenu '%s')" % [quoi, attendu, obtenu])
