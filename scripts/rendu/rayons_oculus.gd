# scripts/rendu/rayons_oculus.gd
# Les rayons de soleil qui tombent du Trou de Ciel (l'oculus de la canopée de
# l'Aelith) — de grands cylindres lumineux, voir shaders/rayon_lumiere.gdshader.
#
# UTILISATION (fonction STATIQUE) :
#     preload("res://scripts/rendu/rayons_oculus.gd").poser(zone, soleil)
# `soleil` est la DirectionalLight3D : les rayons suivent sa direction. Si on
# tourne le soleil dans main.tscn, les rayons tournent avec.
#
# Pourquoi pas le brouillard volumétrique de Godot ? Il donnerait de « vrais »
# rayons, mais il calcule la lumière dans une grille 3D sur toute la vue :
# c'est l'un des effets les plus chers du moteur, et l'écran splitté le paie
# deux fois. Six cylindres additifs ne coûtent presque rien.

extends RefCounted

const SHADER := preload("res://shaders/rayon_lumiere.gdshader")
const Stylisation := preload("res://scripts/rendu/stylisation.gd")

const ACTIVE := true
# Le centre de l'oculus (au-dessus de la place) et son rayon, d'après
# tools/gen_aelith_v2.py (RAYON_OCULUS) et AELITH_CENTRE de zone1.gd.
const CENTRE_OCULUS := Vector3(0, 95, -10)
const RAYON_OCULUS := 14.0
const LONGUEUR := 120.0   # doit suivre le 120.0 de rayon_lumiere.gdshader
const NOMBRE := 6
const GRAINE := 1914

static func poser(zone: Node3D, soleil: DirectionalLight3D) -> Node3D:
	if not ACTIVE or not Stylisation.est_active() or zone == null or soleil == null:
		return null
	var racine := Node3D.new()
	racine.name = "RayonsOculus"
	zone.add_child(racine)

	# Le sens dans lequel la lumière voyage (vers le bas) : -Z de la lumière.
	var vers_le_bas := -soleil.global_transform.basis.z.normalized()
	var rng := RandomNumberGenerator.new()
	rng.seed = GRAINE
	for i in NOMBRE:
		var angle := rng.randf_range(0.0, TAU)
		var r := sqrt(rng.randf()) * RAYON_OCULUS
		var depart := CENTRE_OCULUS + Vector3(cos(angle) * r, 0.0, sin(angle) * r)

		var cylindre := CylinderMesh.new()
		var epaisseur := rng.randf_range(1.6, 4.2)
		cylindre.top_radius = epaisseur
		cylindre.bottom_radius = epaisseur * 1.35   # le rayon s'évase en tombant
		cylindre.height = LONGUEUR
		cylindre.radial_segments = 12
		cylindre.rings = 1
		cylindre.cap_top = false
		cylindre.cap_bottom = false

		var mat := ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter("phase", rng.randf() * 10.0)
		mat.set_shader_parameter("intensite", rng.randf_range(0.16, 0.30))

		var mi := MeshInstance3D.new()
		mi.mesh = cylindre
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		racine.add_child(mi)
		# Le cylindre est construit le long de Y : on aligne Y sur la direction
		# de la lumière (vers le HAUT, donc -vers_le_bas), centre à mi-longueur.
		var axe_y := -vers_le_bas
		var axe_x := axe_y.cross(Vector3.FORWARD).normalized()
		var axe_z := axe_x.cross(axe_y).normalized()
		mi.global_transform = Transform3D(Basis(axe_x, axe_y, axe_z),
			depart + vers_le_bas * LONGUEUR * 0.5)
	return racine
