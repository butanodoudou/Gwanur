# tools/compare_maison.gd
# Outil de dev : met côte à côte la maison procédurale (boîte + prisme) et la
# maison modélisée dans Blender, sous la même lumière.
#
# Lancer :
#   godot --path . res://tools/compare_maison.tscn --resolution 1400x720
# Sortie : tools/captures/comparaison_maison.png
extends Node3D

const SORTIE := "res://tools/captures/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SORTIE)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var ciel := Sky.new()
	ciel.sky_material = ProceduralSkyMaterial.new()
	e.sky = ciel
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.5
	env.environment = e
	add_child(env)

	var soleil := DirectionalLight3D.new()
	soleil.transform = Transform3D(
		Basis(Vector3(0.3, 1.0, 0.4).normalized(), deg_to_rad(35.0)) *
		Basis(Vector3(1, 0, 0), deg_to_rad(-48.0)),
		Vector3(0, 10, 0)
	)
	soleil.light_color = Color(1, 0.952941, 0.8)
	soleil.light_energy = 1.2
	soleil.shadow_enabled = true
	add_child(soleil)

	_sol()
	_maison_procedurale(Vector3(-7, 0, 0))
	_maison_blender("maison_a", Vector3(7, 0, 0))
	_reglet(Vector3(0, 0, 6))   # une silhouette de 1,8 m pour juger l'échelle

	var cam := Camera3D.new()
	cam.current = true
	add_child(cam)
	cam.position = Vector3(0, 7.5, 20)
	cam.look_at(Vector3(0, 2.5, 0), Vector3.UP)

	for i in 8:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SORTIE + "comparaison_maison.png")
	print("capture: comparaison_maison")

	# Deuxième prise : les trois bâtiments en vue trois quarts, comme la
	# caméra du jeu les verra.
	_maison_blender("maison_b", Vector3(-14, 0, -6), 0.3)
	_maison_blender("moulin", Vector3(-2, 0, -4), 1.9)
	cam.position = Vector3(11, 6.5, 13)
	cam.look_at(Vector3(-4, 3.0, -4), Vector3.UP)
	for i in 8:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SORTIE + "trio_blender.png")
	print("capture: trio_blender")
	get_tree().quit()

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m

func _bloc(mesh: Mesh, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c)
	mi.position = pos
	add_child(mi)
	return mi

func _sol() -> void:
	var p := BoxMesh.new()
	p.size = Vector3(60, 0.2, 60)
	_bloc(p, Vector3(0, -0.1, 0), Color(0.36, 0.48, 0.28))

# La maison telle qu'elle est aujourd'hui dans le jeu : une boîte, un prisme,
# et des plaques plates collées sur la façade.
func _maison_procedurale(pos: Vector3) -> void:
	var taille := Vector3(7.0, 4.0, 6.5)
	var murs := BoxMesh.new()
	murs.size = taille
	_bloc(murs, pos + Vector3(0, taille.y * 0.5, 0), Color(0.42, 0.28, 0.18))

	var h_toit := taille.y * 0.55
	var toit := PrismMesh.new()
	toit.size = Vector3(taille.x + 1.4, h_toit, taille.z + 1.4)
	_bloc(toit, pos + Vector3(0, taille.y + h_toit * 0.5, 0), Color(0.55, 0.25, 0.16))

	var faite := BoxMesh.new()
	faite.size = Vector3(0.25, 0.25, taille.z + 1.6)
	_bloc(faite, pos + Vector3(0, taille.y + h_toit, 0), Color(0.42, 0.28, 0.18))

	var z := pos.z + taille.z * 0.5 + 0.03
	var porte := BoxMesh.new()
	porte.size = Vector3(1.2, 2.0, 0.06)
	_bloc(porte, Vector3(pos.x, 1.0, z), Color(0.28, 0.18, 0.11))

	var fen := BoxMesh.new()
	fen.size = Vector3(0.9, 0.9, 0.06)
	_bloc(fen, Vector3(pos.x - taille.x * 0.28, 2.3, z), Color(1.0, 0.8, 0.45))
	_bloc(fen, Vector3(pos.x + taille.x * 0.28, 2.3, z), Color(1.0, 0.8, 0.45))

	var poutre := BoxMesh.new()
	poutre.size = Vector3(0.22, taille.y, 0.06)
	_bloc(poutre, Vector3(pos.x - taille.x * 0.45, taille.y * 0.5, z), Color(0.58, 0.42, 0.26))
	_bloc(poutre, Vector3(pos.x + taille.x * 0.45, taille.y * 0.5, z), Color(0.58, 0.42, 0.26))

func _maison_blender(nom: String, pos: Vector3, rot_y: float = 0.0) -> void:
	var glb := load("res://assets/models/environnement/" + nom + ".glb")
	if glb == null:
		push_error(nom + ".glb introuvable — lance d'abord tools/gen_maison.py")
		return
	var n: Node3D = glb.instantiate()
	n.position = pos
	n.rotation.y = rot_y
	add_child(n)

# Un bonhomme de 1,80 m : sans repère d'échelle, impossible de juger une maison.
func _reglet(pos: Vector3) -> void:
	var corps := CapsuleMesh.new()
	corps.radius = 0.3
	corps.height = 1.8
	_bloc(corps, pos + Vector3(0, 0.9, 0), Color(0.2, 0.25, 0.35))
