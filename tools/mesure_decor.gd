# tools/mesure_decor.gd
# Outil de dev : construit le décor de la Zone 1 (sans lancer le jeu) et compte
# ce qu'il coûte à dessiner. Pratique pour garder la végétation dans le budget
# de l'écran splitté (la scène est rendue DEUX fois par image).
#
# Lancer :
#   godot --headless --path . res://tools/mesure_decor.tscn
# (une scène, pas `--script` : zone1.gd dépend des AutoLoads, qui ne sont pas
# chargés en mode `--script` — le script ne compilait pas et Godot restait
# bloqué sans jamais quitter.)
#
# Affiche, par famille de noeuds :
#   - le nombre de MultiMeshInstance3D, d'instances et de surfaces
#     (une surface d'un MultiMesh = un ordre de dessin, quel que soit le
#     nombre d'instances) ;
#   - le nombre de MeshInstance3D (un ordre de dessin chacun, par surface) ;
#   - le total de triangles affichés.
# C'est un ordre de grandeur « tout visible » : le frustum culling et les
# `visibility_range_end` en retirent une bonne partie en jeu.
extends Node

const Zone1 = preload("res://scripts/zones/zone1.gd")
const DecorVillage = preload("res://scripts/zones/decor_village.gd")

func _ready() -> void:
	var liste: Array = []
	for maison in Zone1.MAISONS:
		var entree: Dictionary = maison.duplicate()
		entree["taille"] = Zone1.emprise(maison)
		liste.append(entree)
	var decor := DecorVillage.new()
	add_child(decor)
	decor.construire(liste)

	var nb_mm := 0
	var nb_instances := 0
	var surfaces_mm := 0
	var tris_mm := 0
	var nb_mi := 0
	var surfaces_mi := 0
	var tris_mi := 0
	var avec_portee := 0
	var collisions := 0
	var par_modele: Dictionary = {}   # nom du maillage → [noeuds, instances, triangles]
	for n in _tous(decor):
		if n is MultiMeshInstance3D and n.multimesh and n.multimesh.mesh:
			var mesh: Mesh = n.multimesh.mesh
			nb_mm += 1
			nb_instances += n.multimesh.instance_count
			surfaces_mm += mesh.get_surface_count()
			tris_mm += _triangles(mesh) * n.multimesh.instance_count
			if n.visibility_range_end > 0.0:
				avec_portee += 1
			var cle := str(mesh.resource_path.get_file()) if mesh.resource_path != "" else str(n.name).split("_")[1]
			if not par_modele.has(cle):
				par_modele[cle] = [0, 0, 0]
			par_modele[cle][0] += 1
			par_modele[cle][1] += n.multimesh.instance_count
			par_modele[cle][2] += _triangles(mesh) * n.multimesh.instance_count
		elif n is MeshInstance3D and n.mesh:
			nb_mi += 1
			surfaces_mi += n.mesh.get_surface_count()
			tris_mi += _triangles(n.mesh)
		elif n is StaticBody3D:
			collisions += 1
	print("MultiMesh : %d noeuds (%d avec portée), %d instances, %d surfaces, %d triangles" % [
		nb_mm, avec_portee, nb_instances, surfaces_mm, tris_mm])
	for cle in par_modele:
		print("  %-18s %3d noeud(s) %4d instances %7d triangles" % [
			cle, par_modele[cle][0], par_modele[cle][1], par_modele[cle][2]])
	print("MeshInstance : %d noeuds, %d surfaces, %d triangles" % [nb_mi, surfaces_mi, tris_mi])
	print("Collisions (StaticBody3D) : %d" % collisions)
	get_tree().quit()

func _triangles(mesh: Mesh) -> int:
	var total := 0
	for s in mesh.get_surface_count():
		var tableaux := mesh.surface_get_arrays(s)
		var index = tableaux[Mesh.ARRAY_INDEX]
		if index != null and index.size() > 0:
			total += index.size() / 3
		else:
			total += tableaux[Mesh.ARRAY_VERTEX].size() / 3
	return total

func _tous(racine: Node) -> Array:
	var liste: Array = [racine]
	for enfant in racine.get_children():
		liste.append_array(_tous(enfant))
	return liste
