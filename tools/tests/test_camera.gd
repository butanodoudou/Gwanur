# tools/tests/test_camera.gd
# Vérifie la caméra orbitale : les deux axes de rotation, et surtout le
# RESSENTI, qui tient à trois propriétés faciles à casser sans s'en apercevoir.
#
#   1. Le signe. La caméra vise toujours le personnage, donc la DESCENDRE fait
#      regarder vers le HAUT. Inverser ce signe est très facile.
#   2. La rotation est rigide. Si on amortit la position de la caméra, on
#      amortit aussi sa rotation : le stick pousse, l'image suit un dixième de
#      seconde plus tard, et la caméra devient « molle ».
#   3. L'amortissement ne dépend pas du nombre d'images par seconde. Un
#      `lerp(x, 0.08)` par frame rend la caméra deux fois plus vive à 120 fps
#      qu'à 60 — le réglage ne veut alors plus rien dire.
#
# Lancer :
#   godot --headless --path . res://tools/tests/test_camera.tscn --quit-after 900

extends Node

const CameraFollow = preload("res://scripts/camera/camera_follow.gd")

var _echecs: int = 0

func _ready() -> void:
	print("--- Test camera ---")

	# Un faux personnage, debout à l'origine.
	var perso := Node3D.new()
	perso.add_to_group("kael")
	perso.position = Vector3(0, 1, 0)
	add_child(perso)

	var cam: Camera3D = CameraFollow.new()
	cam.id_joueur = 1
	add_child(cam)
	await get_tree().process_frame
	await get_tree().process_frame

	# Le pivot vise la tête, pas les pieds.
	var pivot := perso.global_position + Vector3.UP * CameraFollow.HAUTEUR_REGARD

	# ── Cadrage de départ : 9 m en arrière, 6 m au-dessus du pivot ───────────
	_placer(cam, cam._angle_v)
	_verifier("Distance horizontale de depart", "%.1f" % Vector2(
		cam.global_position.x - pivot.x,
		cam.global_position.z - pivot.z).length(), "9.0")
	_verifier("Hauteur de depart au-dessus du pivot",
		"%.1f" % (cam.global_position.y - pivot.y), "6.0")

	# ── Vers le haut : la caméra descend, le regard monte ────────────────────
	_placer(cam, CameraFollow.ANGLE_V_MIN)
	# Au moins 15° au-dessus de l'horizontale : assez pour voir le ciel et la
	# canopée de l'Aelith, pas seulement la ligne d'horizon.
	_verifier("En bas : le regard monte d'au moins 15 degres",
		str(rad_to_deg(asin(_direction_regard(cam).y)) > 15.0), "true")
	_verifier("En bas : la camera reste au-dessus du sol",
		str(cam.global_position.y >= CameraFollow.HAUTEUR_MIN - 0.001), "true")

	# ── Vers le bas : la caméra monte, le regard plonge ──────────────────────
	_placer(cam, CameraFollow.ANGLE_V_MAX)
	_verifier("En haut : le regard plonge vers le sol",
		str(_direction_regard(cam).y < 0.0), "true")
	_verifier("En haut : la camera est au-dessus du personnage",
		str(cam.global_position.y > perso.global_position.y), "true")

	# ── Le rayon de l'orbite ne change pas quand on pivote ───────────────────
	var rayons: Array = []
	for angle in [0.0, 0.6, CameraFollow.ANGLE_V_MAX]:
		_placer(cam, angle)
		rayons.append(cam.global_position.distance_to(pivot))
	_verifier("Rayon constant sur l'orbite",
		"%.1f %.1f %.1f" % [rayons[0], rayons[1], rayons[2]],
		"10.8 10.8 10.8")

	# ── L'axe horizontal marche toujours ─────────────────────────────────────
	cam._angle_h = PI * 0.5
	_placer(cam, 0.6)
	_verifier("Un quart de tour place la camera a l'est",
		str(cam.global_position.x > pivot.x + 5.0), "true")

	# ── La rotation est RIGIDE : une seule frame suffit ──────────────────────
	# Le personnage ne bouge pas, donc le pivot est déjà en place : après un
	# quart de tour, la caméra doit être pile sur son orbite dès la première
	# frame. Si elle traîne, c'est qu'on a réintroduit un amortissement sur la
	# position de la caméra — et la rotation devient molle.
	cam._angle_h = 0.0
	cam._process(0.016)
	# Le rayon horizontal dépend de l'angle vertical courant — on le recalcule
	# au lieu de supposer celui du départ.
	var attendu_x: float = pivot.x
	var attendu_z: float = pivot.z + cos(cam._angle_v) * cam._rayon
	_verifier("Rotation instantanee (pas d'elastique)",
		"%.2f %.2f" % [cam.global_position.x - attendu_x, cam.global_position.z - attendu_z],
		"0.00 0.00")

	# ── Le suivi ne dépend pas du nombre d'images par seconde ────────────────
	# On simule une seconde de marche à 60 fps puis à 120 fps : le pivot doit
	# avoir rattrapé le personnage à la même distance dans les deux cas.
	perso.position = Vector3(30, 1, 0)
	var restant_60 := _simuler_une_seconde(cam, perso, 60)
	var restant_120 := _simuler_une_seconde(cam, perso, 120)
	_verifier("Suivi identique a 60 et 120 fps",
		"%.2f %.2f" % [restant_60, restant_120],
		"%.2f %.2f" % [restant_60, restant_60])

	# ── Zone morte et courbe de réponse du stick ─────────────────────────────
	_verifier("Stick au repos ignore", "%.2f" % cam._axe(0.10), "0.00")
	_verifier("Stick a fond = vitesse max", "%.2f" % cam._axe(1.0), "1.00")
	_verifier("Demi-course plus lente que la moitie",
		str(cam._axe(0.5) < 0.5), "true")
	_verifier("Le signe est conserve", str(cam._axe(-1.0) < 0.0), "true")

	_conclure()

# Force l'angle vertical puis laisse la caméra se replacer.
func _placer(cam: Camera3D, angle_v: float) -> void:
	cam._angle_v = angle_v
	cam._process(0.016)
	cam._process(0.016)

# Remet le pivot au point de départ, puis simule une seconde de poursuite.
# Renvoie la distance qu'il reste entre le pivot et le personnage.
func _simuler_une_seconde(cam: Camera3D, perso: Node3D, images: int) -> float:
	cam._pivot = Vector3.ZERO
	cam._pivot_initialise = true
	var delta := 1.0 / float(images)
	for i in images:
		cam._process(delta)
	var vise := perso.global_position + Vector3.UP * CameraFollow.HAUTEUR_REGARD
	return cam._pivot.distance_to(vise)

# La caméra regarde le long de son axe Z local, vers l'arrière (-Z).
func _direction_regard(cam: Camera3D) -> Vector3:
	return -cam.global_transform.basis.z

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
