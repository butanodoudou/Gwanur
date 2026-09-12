# tools/tests/test_hud.gd
# Vérifie le HUD par joueur dans main.tscn : présence dans chaque SubViewport,
# pôles de moralité propres à chaque jumeau, prompt d'interaction contextuel,
# et isolation entre les deux moitiés d'écran.
#
# Lancer :
#   godot --headless --path . res://tools/tests/test_hud.tscn --quit-after 900

extends Node

class FausseCible extends Node3D:
	func obtenir_verbe() -> String:
		return "Parler a Lira"
	func declencher(_id_joueur: int) -> void:
		pass

var _echecs: int = 0

func _ready() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	print("--- Test HUD ---")

	var hud_kael = scene.get_node_or_null(
		"SplitScreen/Conteneur/VueKael/SubViewport/HudKael")
	var hud_mira = scene.get_node_or_null(
		"SplitScreen/Conteneur/VueMira/SubViewport/HudMira")

	_verifier("HUD de Kael present", str(hud_kael != null), "true")
	_verifier("HUD de Mira present", str(hud_mira != null), "true")
	if hud_kael == null or hud_mira == null:
		_conclure()
		return

	_verifier("Kael lit le bon pole gauche", hud_kael._label_pole_gauche.text, "Instinct")
	_verifier("Mira lit le bon pole gauche", hud_mira._label_pole_gauche.text, "Méfiance")

	# ── Prompt d'interaction ────────────────────────────────────────────────
	_verifier("Prompt cache au depart", str(hud_kael._label_prompt.visible), "false")

	var cible := FausseCible.new()
	add_child(cible)
	InteractionManager.enregistrer(1, cible)
	await get_tree().process_frame
	await get_tree().process_frame

	_verifier("Prompt de Kael visible a portee", str(hud_kael._label_prompt.visible), "true")
	_verifier("Prompt de Kael a le bon texte", hud_kael._label_prompt.text, "(A)  Parler a Lira")
	_verifier("Prompt de Mira reste cache", str(hud_mira._label_prompt.visible), "false")

	InteractionManager.retirer(1, cible)
	await get_tree().process_frame
	await get_tree().process_frame
	_verifier("Prompt cache quand on s'eloigne", str(hud_kael._label_prompt.visible), "false")

	# ── Moralite ────────────────────────────────────────────────────────────
	_verifier("Barre invisible au repos", "%.1f" % hud_kael._bloc_moralite.modulate.a, "0.0")

	var x_avant: float = hud_kael._curseur.position.x
	GameManager.modifier_moralite_kael(-40)
	await get_tree().process_frame

	_verifier("Barre de Kael apparait", "%.1f" % hud_kael._bloc_moralite.modulate.a, "1.0")
	_verifier("Curseur de Kael glisse vers Instinct",
		str(hud_kael._curseur.position.x < x_avant), "true")
	_verifier("Barre de Mira reste invisible",
		"%.1f" % hud_mira._bloc_moralite.modulate.a, "0.0")

	# La barre doit s'effacer toute seule
	await get_tree().create_timer(4.4).timeout
	_verifier("Barre de Kael effacee apres le fondu",
		"%.1f" % hud_kael._bloc_moralite.modulate.a, "0.0")

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
