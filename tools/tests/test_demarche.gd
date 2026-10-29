# tools/tests/test_demarche.gd
# Vérifie la démarche procédurale de Kael (character_base.gd) :
#   - quand il marche, le MODÈLE rebondit ;
#   - le CharacterBody3D et sa capsule de collision, eux, ne sont pas animés ;
#   - à l'arrêt, le modèle revient doucement à sa position de repos ;
#   - l'orientation ne dépend pas du nombre d'images par seconde.
#
# Lancer :
#   godot --headless --path . res://tools/tests/test_demarche.tscn --quit-after 3000

extends Node

var _echecs: int = 0

func _ready() -> void:
	print("--- Test demarche ---")

	# Un sol plat pour que Kael marche au lieu de tomber.
	var sol := StaticBody3D.new()
	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = Vector3(200, 1, 200)
	forme.shape = boite
	sol.add_child(forme)
	sol.position = Vector3(0, -0.5, 0)
	add_child(sol)

	var kael: CharacterBody3D = load("res://scenes/characters/kael.tscn").instantiate()
	add_child(kael)
	var modele: Node3D = kael.get_node("Modele")
	var collision: Node3D = kael.get_node("CollisionShape3D")
	var repos := modele.position
	await _attendre(0.3)

	# ── Marche ───────────────────────────────────────────────────────────────
	Input.action_press("joueur1_droite")
	var rebond_max := 0.0
	var roulis_max := 0.0
	for i in 60:
		await get_tree().physics_frame
		rebond_max = maxf(rebond_max, modele.position.y - repos.y)
		roulis_max = maxf(roulis_max, absf(modele.rotation.z))
	_verifier("Le modele rebondit en marchant", str(rebond_max > 0.02), "true")
	_verifier("Le modele se balance en marchant", str(roulis_max > 0.02), "true")
	_verifier("Rebond leger (moins de 10 cm)", str(rebond_max < 0.1), "true")
	_verifier("La capsule de collision ne bouge pas",
		str(collision.position.is_equal_approx(Vector3(0, 0.9, 0))), "true")
	_verifier("Kael avance", str(kael.global_position.x > 1.0), "true")
	_verifier("Kael reste au sol (le corps n'est pas anime)",
		"%.2f" % absf(kael.global_position.y), "0.00")

	# ── Arrêt : retour doux au repos ─────────────────────────────────────────
	Input.action_release("joueur1_droite")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var juste_apres := modele.position.distance_to(repos) + absf(modele.rotation.x)
	await _attendre(1.0)
	var une_seconde_apres := modele.position.distance_to(repos) + absf(modele.rotation.x)
	_verifier("Le modele revient au repos apres l'arret", str(une_seconde_apres < 0.002), "true")
	_verifier("Le retour est doux (pas instantane)", str(juste_apres > une_seconde_apres), "true")

	# ── Orientation indépendante du framerate ────────────────────────────────
	var direction := Vector3(1, 0, 0)
	var a_60 := _orienter_un_dixieme_de_seconde(kael, direction, 60)
	var a_120 := _orienter_un_dixieme_de_seconde(kael, direction, 120)
	_verifier("Orientation identique a 60 et 120 fps",
		"%.3f" % a_60, "%.3f" % a_120)

	_conclure()

# Part de rotation.y = PI (dos à la cible), tourne vers `direction` pendant 0,1 s simulée.
func _orienter_un_dixieme_de_seconde(kael: CharacterBody3D, direction: Vector3, images: int) -> float:
	kael.rotation.y = PI  # dos à la direction visée
	var delta := 1.0 / float(images)
	# roundi() plutôt que images / 10 : Godot avertit sur les divisions entières.
	for i in roundi(images * 0.1):
		kael._orienter_personnage(direction, delta)
	return kael.rotation.y

func _attendre(secondes: float) -> void:
	await get_tree().create_timer(secondes).timeout

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
