# tools/tests/test_demarche.gd
# Vérifie la démarche de Kael (character_base.gd + le squelette de kael.glb) :
#   - le modèle a un AnimationPlayer avec idle, marche, course, en boucle ;
#   - à l'arrêt, l'arbre joue idle ; en mouvement, il joue les pas avec la
#     bonne cadence (vitesse / foulée) ;
#   - les pieds ne patinent pas : un pied posé reste (presque) immobile ;
#   - le CharacterBody3D et sa capsule de collision ne sont pas animés ;
#   - la vitesse max n'a pas changé, l'accélération ne dépend pas du framerate ;
#   - un skill joue son geste sans arrêter le déplacement ;
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
	var collision: Node3D = kael.get_node("CollisionShape3D")
	var lecteur := kael.get_node("Modele").find_child("AnimationPlayer", true, false) as AnimationPlayer
	var arbre := kael.get_node("Modele").find_child("AnimationTree", true, false) as AnimationTree
	var squelette := kael.get_node("Modele").find_child("Skeleton3D", true, false) as Skeleton3D

	# ── Le modèle et ses animations ──────────────────────────────────────────
	_verifier("Le modele a un AnimationPlayer", str(lecteur != null), "true")
	_verifier("Le modele a un squelette", str(squelette != null), "true")
	_verifier("Un AnimationTree est construit", str(arbre != null and arbre.active), "true")
	if lecteur == null or arbre == null or squelette == null:
		_conclure()
		return
	for nom in ["idle", "marche", "course", "interagir", "skill1", "skill2"]:
		_verifier("Animation « %s » presente" % nom, str(lecteur.has_animation(nom)), "true")
	for nom in ["idle", "marche", "course"]:
		_verifier("« %s » boucle" % nom,
			str(lecteur.get_animation(nom).loop_mode == Animation.LOOP_LINEAR), "true")
	# Contrat avec animer_personnages.py : un cycle de pas dure 1 s.
	_verifier("Cycle de marche de 1 s", "%.2f" % lecteur.get_animation("marche").length, "1.00")
	_verifier("Cycle de course de 1 s", "%.2f" % lecteur.get_animation("course").length, "1.00")
	# Une boucle sans couture : la première et la dernière clé sont la même pose.
	_verifier("La marche boucle sans couture", str(_boucle_sans_couture(lecteur.get_animation("marche"))), "true")
	_verifier("L'idle boucle sans couture", str(_boucle_sans_couture(lecteur.get_animation("idle"))), "true")

	await _attendre(0.3)
	_verifier("A l'arret : idle (melange = 0)",
		"%.2f" % float(arbre.get("parameters/mouvement/blend_amount")), "0.00")

	# ── Mouvement ────────────────────────────────────────────────────────────
	Input.action_press("joueur1_droite")
	var pied := squelette.find_bone("pied_g")
	var pieds_poses: Array[float] = []   # vitesse du pied quand il touche le sol
	var avant := _pied_monde(squelette, pied)
	for i in 90:
		await get_tree().physics_frame
		var maintenant := _pied_monde(squelette, pied)
		# On regarde le pied seulement après 0,5 s (pleine vitesse atteinte).
		if i > 30 and maintenant.y < 0.13:
			var d := Vector2(maintenant.x - avant.x, maintenant.z - avant.z).length()
			pieds_poses.append(d * Engine.physics_ticks_per_second)
		avant = maintenant
	var vitesse_sol := Vector2(kael.velocity.x, kael.velocity.z).length()
	_verifier("Vitesse max inchangee (5 m/s)", "%.2f" % vitesse_sol, "5.00")
	_verifier("En mouvement : les pas (melange = 1)",
		"%.2f" % float(arbre.get("parameters/mouvement/blend_amount")), "1.00")
	_verifier("A pleine vitesse : course (allure = 1)",
		"%.2f" % float(arbre.get("parameters/allure/blend_position")), "1.00")
	_verifier("Cadence = vitesse / foulee de course",
		"%.3f" % float(arbre.get("parameters/cadence/scale")),
		"%.3f" % (5.0 / CharacterBase.FOULEE_COURSE))
	pieds_poses.sort()
	var mediane: float = pieds_poses[pieds_poses.size() / 2] if not pieds_poses.is_empty() else 99.0
	print("    (pied pose : %d mesures, vitesse mediane %.2f m/s, corps a 5 m/s)" % [pieds_poses.size(), mediane])
	_verifier("Le pied pose ne patine pas (< 1 m/s)", str(mediane < 1.0), "true")
	_verifier("La capsule de collision ne bouge pas",
		str(collision.position.is_equal_approx(Vector3(0, 0.9, 0))), "true")
	_verifier("Kael avance", str(kael.global_position.x > 1.0), "true")
	_verifier("Kael reste au sol (le corps n'est pas anime)",
		"%.2f" % absf(kael.global_position.y), "0.00")

	# ── Un skill pendant la course : geste joué, déplacement intact ─────────
	var x_avant := kael.global_position.x
	kael.utiliser_brassards()
	await _attendre(0.2)
	_verifier("Le geste se joue", str(arbre.get("parameters/geste/active")), "true")
	_verifier("Kael continue d'avancer pendant le geste",
		str(kael.global_position.x - x_avant > 0.8), "true")
	await _attendre(1.2)
	_verifier("Le geste s'efface tout seul", str(arbre.get("parameters/geste/active")), "false")

	# ── Arrêt : retour à idle, en douceur ────────────────────────────────────
	Input.action_release("joueur1_droite")
	await get_tree().physics_frame
	var juste_apres := Vector2(kael.velocity.x, kael.velocity.z).length()
	_verifier("Le personnage freine (pas d'arret sec)", str(juste_apres > 0.5), "true")
	await _attendre(0.5)
	_verifier("Arret : vitesse nulle", "%.2f" % Vector2(kael.velocity.x, kael.velocity.z).length(), "0.00")
	_verifier("Arret : idle (melange = 0)",
		"%.2f" % float(arbre.get("parameters/mouvement/blend_amount")), "0.00")

	# ── Cadence et allure selon la vitesse (stick à moitié poussé) ──────────
	_verifier("A 1,2 m/s : marche pure", "%.2f" % kael._allure_pour(1.2), "0.00")
	_verifier("A 1,2 m/s : un cycle par seconde", "%.2f" % kael.cadence_pour(1.2), "1.00")
	_verifier("Cadence constante pendant le melange",
		"%.3f" % kael.cadence_pour(3.5), "%.3f" % kael.cadence_pour(5.0))

	# ── Accélération indépendante du framerate ───────────────────────────────
	_verifier("Acceleration identique a 30 et 144 fps",
		"%.3f" % _accelerer_un_dixieme_de_seconde(kael, 30),
		"%.3f" % _accelerer_un_dixieme_de_seconde(kael, 144))

	# ── Orientation indépendante du framerate ────────────────────────────────
	var direction := Vector3(1, 0, 0)
	var a_60 := _orienter_un_dixieme_de_seconde(kael, direction, 60)
	var a_120 := _orienter_un_dixieme_de_seconde(kael, direction, 120)
	_verifier("Orientation identique a 60 et 120 fps",
		"%.3f" % a_60, "%.3f" % a_120)

	_conclure()

# Position monde de la cheville (la tête de l'os du pied).
func _pied_monde(squelette: Skeleton3D, os: int) -> Vector3:
	return squelette.global_transform * squelette.get_bone_global_pose(os).origin

# Vrai si chaque piste de rotation a la même valeur au début et à la fin.
func _boucle_sans_couture(anim: Animation) -> bool:
	for i in anim.get_track_count():
		if anim.track_get_type(i) != Animation.TYPE_ROTATION_3D or anim.track_get_key_count(i) < 2:
			continue
		var debut: Quaternion = anim.rotation_track_interpolate(i, 0.0)
		var fin: Quaternion = anim.rotation_track_interpolate(i, anim.length)
		if debut.angle_to(fin) > 0.01:
			return false
	return true

# Part de l'arrêt et accélère vers +X pendant 0,1 s simulée.
func _accelerer_un_dixieme_de_seconde(kael: CharacterBody3D, images: int) -> float:
	var v := Vector2.ZERO
	var delta := 1.0 / float(images)
	var pas := roundi(images * 0.1)
	for i in pas:
		v = kael._accelerer(v, Vector2(5.0, 0.0), delta)
	# On ramène au même instant exact (0,1 s) : pas × delta peut différer d'un poil.
	return v.x / (pas * delta) * 0.1

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
