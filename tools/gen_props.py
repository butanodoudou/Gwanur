# tools/gen_props.py — les objets des puzzles et de la place de Sylvara
#
# Remplace les boîtes grises qui tenaient lieu de porte, de grille, de roue…
#
# RÈGLE D'OR : LE MODÈLE HABILLE, IL NE DÉCIDE RIEN
# Chaque modèle est posé PAR-DESSUS un noeud existant de zone1.tscn / zone1.gd
# (voir `_coloriser_puzzles()` et `_habiller_bloc()` dans zone1.gd). Les noms
# de noeuds, les positions, les collisions et les Area3D ne changent pas. Pour
# que le modèle tombe pile, son ORIGINE est choisie selon le noeud qu'il habille :
#
#   modèle          habille                         origine du modèle
#   ─────────────── ─────────────────────────────── ─────────────────────────
#   porte_double    Puzzle1PorteDouble/Porte        centre de la boîte 8×4×0.4
#   palissade       les murs de palissade (zone1)   au SOL ; MODULE de 4 m le long
#                                                   de Z Godot, répété par zone1.gd
#   grille          Puzzle2Oiseau/Grille            centre de la boîte 8×4×0.3
#   perchoir        la boîte 1.3×0.45×1.3 (zone1)   centre de la boîte
#   oiseau          Puzzle2Oiseau/Oiseau            centre de l'ancienne sphère
#   plateforme      Puzzle2Oiseau/PlateformePoids   au SOL
#   verrou          Puzzle2Oiseau/ZoneVerrou        au SOL
#   roue_eau        Puzzle3RoueEau/RoueEau          le MOYEU (elle tourne sur Z Godot)
#   roue_support    (posé à côté, immobile)         au sol, sous le moyeu
#   pont            Puzzle3RoueEau/Pont             centre de la boîte 5×0.3×4
#   berge           les rives du ruisseau (zone1)   au SOL ; MODULE de 6 m le long de X
#   cercle_lanterne Puzzle3RoueEau/ZoneLanterne     au SOL
#   liane           Lianes et EchoLiane             centre (la liane pousse depuis
#                                                   son centre : scale Y animé)
#   stele           la stèle 0.5×3.5×0.4 (zone1)    au SOL
#   puits           le puits (zone1 + decor)        au SOL
#
# Rappel d'axes (blender_commun.py) : Blender +Z = Godot +Y (haut) et
# Blender -Y = Godot +Z (le SUD, côté village). Les faces « avant » (poignées,
# inscription) sont donc en -Y ici.
#
# Usage :
#   blender --background --python tools/gen_props.py
# Sortie :
#   assets/models/props/*.glb

import bpy
import math
import os
import random
import sys
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from blender_commun import boite, boule, cylindre, branche, vider_la_scene, exporter

SOUS_DOSSIER = "props"


def anneau(nom, centre, rayon, epaisseur, couleur, plan="XZ", segments=16):
	"""Un anneau fait de petits cylindres bout à bout (jante, poignée, nid).

	`plan` = le plan de l'anneau : "XZ" (debout, face à -Y) ou "XY" (couché).
	"""
	centre = Vector(centre)
	points = []
	for i in range(segments + 1):
		a = i * math.tau / segments
		if plan == "XZ":
			points.append(centre + Vector((math.cos(a) * rayon, 0, math.sin(a) * rayon)))
		else:
			points.append(centre + Vector((math.cos(a) * rayon, math.sin(a) * rayon, 0)))
	for i in range(segments):
		branche(f"{nom}_{i}", points[i], points[i + 1], epaisseur, epaisseur,
				couleur, segments=5)


# ──────────────────────────────────────────────────────────────────────────────
# PUZZLE 1 — LA PORTE À DEUX POIGNÉES
# ──────────────────────────────────────────────────────────────────────────────


def porte_double():
	"""Deux vantaux de planches ferrées, 8 × 4 m, centrés sur l'origine."""
	for cote in (-1, 1):
		# Cinq planches par vantail, légèrement de travers : c'est du bois
		# assemblé à la main, pas un panneau.
		for i in range(5):
			x = cote * (0.42 + i * 0.79)
			boite(f"Planche_{cote}_{i}", (0.76, 0.30, 3.92 + random.uniform(-0.05, 0.05)),
				  (x, 0, random.uniform(-0.02, 0.02)),
				  "bois" if i % 2 == 0 else "bois_sombre",
				  biseau=0.04, tordu=0.008)
		# L'écharpe en diagonale (la pièce qui empêche le vantail de s'affaisser)
		branche(f"Echarpe_{cote}", (cote * 0.45, -0.17, -1.25), (cote * 3.55, -0.17, 1.25),
				0.09, 0.09, "bois_clair", segments=6)
		# Les gonds, côté extérieur
		for z in (-1.3, 1.3):
			boite(f"Gond_{cote}_{z}", (0.55, 0.36, 0.16), (cote * 3.75, 0, z), "fer",
				  biseau=0.03)

	# Deux bandes de fer sur toute la largeur
	for z in (-1.2, 1.2):
		boite(f"Bande_{z}", (7.92, 0.36, 0.18), (0, 0, z), "fer", biseau=0.03)
		for i in range(9):
			boule(f"Clou_{z}_{i}", 0.045, (-3.6 + i * 0.9, -0.19, z), "metal", subdivisions=1)

	# Les deux poignées, aux deux bords : celle de GAUCHE est pour Kael (sa
	# zone est à x = -5), celle de DROITE pour Mira (x = +5). Chacune porte la
	# couleur de son héros — un indice discret qu'il faut être deux.
	for cote, teinte, emission in ((-1, "seve", 1.2), (1, "cuivre", 0.0)):
		x = cote * 3.35
		boite(f"Platine_{cote}", (0.32, 0.06, 0.42), (x, -0.18, 0.1), "fer", biseau=0.02)
		anneau(f"Poignee_{cote}", (x, -0.26, -0.12), 0.20, 0.035, "fer", segments=10)
		boule(f"Pierre_{cote}", 0.075, (x, -0.24, 0.1), teinte, subdivisions=2,
			  emission=emission)


LONGUEUR_PALISSADE = 4.0   # un MODULE : zone1.gd le répète le long du mur


def palissade():
	"""Un module de 4 m de rondins appointés, le long de Z Godot (= Y Blender),
	au sol. zone1.gd en aligne autant qu'il faut pour couvrir chaque mur."""
	n = 10
	for i in range(n):
		y = -LONGUEUR_PALISSADE * 0.5 + (i + 0.5) * LONGUEUR_PALISSADE / n
		hauteur = random.uniform(2.55, 3.05)
		x = random.uniform(-0.04, 0.04)
		teinte = random.choice(["bois", "bois", "bois_sombre", "bois_clair"])
		cylindre(f"Rondin_{i}", 0.21, 0.19, hauteur, (x, y, 0), teinte, segments=6)
		cylindre(f"Pointe_{i}", 0.19, 0.03, 0.45, (x, y, hauteur), teinte, segments=6)
	# Deux traverses, des deux côtés
	for cote in (-1, 1):
		for z in (0.8, 2.1):
			boite(f"Traverse_{cote}_{z}", (0.12, LONGUEUR_PALISSADE, 0.16), (cote * 0.24, 0, z),
				  "bois_sombre", biseau=0.03)


# ──────────────────────────────────────────────────────────────────────────────
# PUZZLE 2 — L'OISEAU ET LE PASSAGE
# ──────────────────────────────────────────────────────────────────────────────


def grille():
	"""Une herse de fer dans un cadre de bois, 8 × 4 m, centrée."""
	for z in (-1.82, 1.82):
		boite(f"Traverse_{z}", (8.0, 0.30, 0.34), (0, 0, z), "bois_sombre", biseau=0.04)
	for cote in (-1, 1):
		boite(f"Montant_{cote}", (0.32, 0.30, 3.6), (cote * 3.84, 0, 0), "bois_sombre",
			  biseau=0.04)
	# Les barreaux verticaux, terminés en pointe vers le bas (c'est une herse)
	for i in range(14):
		x = -3.25 + i * 0.5
		cylindre(f"Barreau_{i}", 0.05, 0.05, 3.5, (x, 0, -1.65), "fer", segments=6)
		cylindre(f"Pointe_{i}", 0.0, 0.06, 0.22, (x, 0, -1.95), "fer", segments=6)
	for z in (-0.8, 0.35, 1.3):
		boite(f"Lisse_{z}", (7.5, 0.10, 0.10), (0, 0, z), "fer", biseau=0.02)


def perchoir():
	"""Le perchoir de l'oiseau, sur le faîtage de la maison voisine.

	Centré sur la boîte 1.3 × 0.45 × 1.3 de zone1.gd. L'oiseau se pose à
	z = +0.225 (le dessus de la boîte) : c'est là qu'est le nid.
	"""
	boite("Plateau", (1.2, 1.2, 0.14), (0, 0, -0.15), "bois_clair", biseau=0.03, tordu=0.03)
	for cx in (-0.5, 0.5):
		for cy in (-0.5, 0.5):
			boite(f"Cale_{cx}_{cy}", (0.16, 0.16, 0.16), (cx, cy, -0.2), "bois_sombre")
	# Le nid : deux anneaux de brindilles
	anneau("Nid", (0, 0, 0.05), 0.30, 0.07, "corde", plan="XY", segments=10)
	anneau("NidHaut", (0, 0, 0.14), 0.26, 0.05, "bois_clair", plan="XY", segments=9)
	cylindre("NidFond", 0.30, 0.30, 0.06, (0, 0, -0.08), "corde", segments=10)
	# Un mât avec un fanion : on repère le perchoir de loin, et donc l'oiseau.
	branche("Mat", (0.48, 0.48, -0.1), (0.48, 0.48, 1.4), 0.04, 0.03, "bois_sombre", segments=5)
	boite("Fanion", (0.04, 0.42, 0.22), (0.48, 0.70, 1.25), "tunique_mira",
		  rotation=(0, 0, 0.1), biseau=0.01)


def oiseau():
	"""L'oiseau blanc d'Aelindra. Origine au centre, pattes à z = -0.3.

	Un très léger éclat (émission) : c'est un oiseau un peu plus qu'ordinaire,
	et il doit se lire sur un toit à 15 m.
	"""
	boule("Corps", 0.17, (0, 0.03, -0.06), "plume", aplatissement=0.85, subdivisions=2,
		  emission=0.35)
	boule("Tete", 0.105, (0, -0.13, 0.09), "plume", subdivisions=2, emission=0.35)
	branche("Bec", (0, -0.215, 0.085), (0, -0.31, 0.06), 0.028, 0.004, "bec", segments=5)
	for cote in (-1, 1):
		boite(f"Oeil_{cote}", (0.02, 0.02, 0.025), (cote * 0.06, -0.19, 0.115), "ecorce",
			  biseau=0.005)
		boite(f"Aile_{cote}", (0.05, 0.26, 0.13), (cote * 0.15, 0.05, -0.04), "plume",
			  rotation=(0.25, cote * 0.15, 0), biseau=0.02, emission=0.35)
		branche(f"Patte_{cote}", (cote * 0.05, 0.0, -0.19), (cote * 0.05, -0.02, -0.3),
				0.013, 0.010, "bec", segments=4)
	boite("Queue", (0.10, 0.20, 0.03), (0, 0.22, -0.02), "plume",
		  rotation=(-0.45, 0, 0), biseau=0.01, emission=0.35)


# ──────────────────────────────────────────────────────────────────────────────
# PUZZLE 3 — LA ROUE D'EAU
# ──────────────────────────────────────────────────────────────────────────────

RAYON_ROUE = 1.85   # le moyeu est à 2 m du sol : la roue effleure l'eau


def roue_eau():
	"""La roue à aubes. Origine au MOYEU, axe le long de Y Blender (= Z Godot).

	puzzle_roue_eau.gd la fait tourner autour de Z Godot : l'axe du modèle doit
	être exactement celui-là, sinon elle « valse » au lieu de tourner.
	"""
	branche("Axe", (0, -0.55, 0), (0, 0.55, 0), 0.11, 0.11, "bois_sombre", segments=8)
	branche("Moyeu", (0, -0.24, 0), (0, 0.24, 0), 0.26, 0.26, "bois", segments=8)
	for y in (-0.22, 0.22):
		anneau(f"Jante_{y}", (0, y, 0), RAYON_ROUE, 0.07, "bois_mouille", segments=16)
		for i in range(8):
			a = i * math.tau / 8 + (0.2 if y > 0 else 0.0)
			branche(f"Rayon_{y}_{i}", (0, y, 0),
					(math.cos(a) * RAYON_ROUE, y, math.sin(a) * RAYON_ROUE),
					0.05, 0.04, "bois", segments=5)
	# Les aubes : des planches radiales. rotation Y = -a aligne la planche sur
	# le rayon (une rotation de θ autour de Y envoie X sur (cos θ, 0, -sin θ)).
	for i in range(12):
		a = i * math.tau / 12
		r = RAYON_ROUE - 0.12
		boite(f"Aube_{i}", (0.50, 0.58, 0.06),
			  (math.cos(a) * r, 0, math.sin(a) * r),
			  "bois_mouille" if i % 2 else "bois_sombre",
			  rotation=(0, -a, 0), biseau=0.015)
	# De la mousse sur la jante : elle est restée arrêtée longtemps.
	for i in range(5):
		a = random.uniform(0, math.tau)
		boule(f"Mousse_{i}", random.uniform(0.07, 0.12),
			  (math.cos(a) * RAYON_ROUE, random.choice((-0.22, 0.22)), math.sin(a) * RAYON_ROUE),
			  "mousse", subdivisions=1)


def roue_support():
	"""Les deux chevalets qui portent l'axe. Au sol, sous le moyeu (à 2 m)."""
	for y in (-0.62, 0.62):
		for cote in (-1, 1):
			branche(f"Jambe_{y}_{cote}", (cote * 0.95, y, 0.0), (0, y, 2.05),
					0.10, 0.08, "bois_sombre", segments=6)
		boite(f"Entretoise_{y}", (1.3, 0.12, 0.12), (0, y, 0.75), "bois", biseau=0.02)
		boite(f"Palier_{y}", (0.34, 0.22, 0.30), (0, y, 2.0), "bois", biseau=0.03)
		boite(f"Ferrure_{y}", (0.36, 0.24, 0.06), (0, y, 2.12), "fer", biseau=0.01)


def pont():
	"""Le pont de planches, 5 × 4 m, centré (Y Blender = la direction de marche)."""
	for i in range(9):
		y = -1.8 + i * 0.45
		boite(f"Planche_{i}", (5.0 + random.uniform(-0.15, 0.1), 0.42, 0.10),
			  (random.uniform(-0.06, 0.06), y, 0.10),
			  "bois_clair" if i % 3 else "bois", biseau=0.02, tordu=0.015)
	for x in (-2.0, 2.0):
		boite(f"Longeron_{x}", (0.24, 4.0, 0.20), (x, 0, -0.05), "bois_sombre", biseau=0.03)
	# Garde-corps de corde, bas : on ne les confond pas avec un mur.
	for x in (-2.35, 2.35):
		for y in (-1.8, 1.8):
			cylindre(f"Poteau_{x}_{y}", 0.06, 0.05, 0.8, (x, y, 0.1), "bois_sombre", segments=6)
		branche(f"Corde_{x}", (x, -1.8, 0.82), (x, 1.8, 0.82), 0.025, 0.025, "corde", segments=4)


LONGUEUR_BERGE = 6.0   # un MODULE : zone1.gd le répète le long du ruisseau


def berge():
	"""Un module de 6 m de galets le long de X, au sol. zone1.gd en aligne le
	long des deux rives — et saute ceux où le pont se pose."""
	demi = LONGUEUR_BERGE * 0.5
	x = -demi
	i = 0
	while x < demi - 0.3:
		r = random.uniform(0.30, 0.48)
		boule(f"Galet_{i}", r, (x + r * 0.6, random.uniform(-0.1, 0.1), r * 0.35),
			  random.choice(["galet", "pierre_sombre", "pierre_claire", "galet"]),
			  aplatissement=random.uniform(0.55, 0.75), subdivisions=1,
			  rotation=(0, 0, random.uniform(0, math.tau)))
		x += r * 1.3
		i += 1
	# Des touffes de mousse et d'herbe entre les pierres
	for j in range(5):
		boule(f"Touffe_{j}", random.uniform(0.15, 0.28),
			  (random.uniform(-demi + 0.2, demi - 0.2), random.uniform(-0.25, 0.25), 0.35),
			  random.choice(["mousse", "feuille", "feuille_clair"]),
			  aplatissement=0.6, subdivisions=1)


def liane():
	"""La liane qui s'enroule (Puzzle 3). 2 m de haut, centrée sur l'origine.

	Le puzzle l'agrandit de scale Y = 0 → 1 : elle pousse depuis son centre.
	Les bourgeons de sève brillent — c'est la magie de Kael.
	"""
	tours = 3.0
	pas = 24
	points = []
	for i in range(pas + 1):
		t = i / pas
		a = t * tours * math.tau
		r = 0.13 + 0.03 * math.sin(t * 9.0)
		points.append(Vector((math.cos(a) * r, math.sin(a) * r, -1.0 + t * 2.0)))
	for i in range(pas):
		epais = 0.055 - 0.03 * (i / pas)
		branche(f"Tige_{i}", points[i], points[i + 1], epais, epais * 0.9,
				"feuille_sombre", segments=5)
		if i % 3 == 1:
			p = points[i]
			dehors = Vector((p.x, p.y, 0)).normalized() * 0.14
			boule(f"Feuille_{i}", 0.09, p + dehors, "feuille_clair",
				  aplatissement=0.35, subdivisions=1,
				  rotation=(random.uniform(-0.6, 0.6), 0, random.uniform(0, math.tau)))
		if i % 5 == 3:
			boule(f"Bourgeon_{i}", 0.04, points[i], "seve", subdivisions=1, emission=1.8)


# ──────────────────────────────────────────────────────────────────────────────
# LES REPÈRES AU SOL — pour qu'on voie OÙ se joue chaque puzzle
# ──────────────────────────────────────────────────────────────────────────────


def verrou():
	"""Le verrou du Puzzle 2 : un poteau de bois et un levier de fer, au sol.

	Posé sur ZoneVerrou (Area3D, au sol). La poignée en cuivre rappelle le
	grappin de Mira : c'est SON verrou.
	"""
	boite("Socle", (0.7, 0.7, 0.25), (0, 0, 0.125), "pierre_sombre", biseau=0.05)
	boite("Poteau", (0.32, 0.32, 1.45), (0, 0, 0.95), "bois_sombre", biseau=0.04)
	boite("Boitier", (0.42, 0.22, 0.42), (0, -0.2, 1.15), "fer", biseau=0.03)
	branche("Levier", (0, -0.32, 1.15), (0.0, -0.55, 1.62), 0.035, 0.03, "fer", segments=5)
	boule("Pommeau", 0.07, (0.0, -0.56, 1.64), "cuivre", subdivisions=2)
	# La chaîne qui court vers la grille : trois maillons, juste pour l'idée.
	for i in range(3):
		anneau(f"Maillon_{i}", (0.08, 0.05 + i * 0.12, 1.75 + i * 0.05), 0.05, 0.012,
			   "fer", plan="XY", segments=6)


def plateforme():
	"""La plateforme de poids du Puzzle 2 : une dalle ronde où l'oiseau se pose.

	Origine au SOL (zone1.gd compense le y = 0.2 de PlateformePoids). Une
	plume gravée et dorée : on comprend que l'oiseau doit venir ici.
	"""
	cylindre("Dalle", 1.25, 1.2, 0.16, (0, 0, 0), "pierre_claire", segments=16)
	anneau("Bord", (0, 0, 0.16), 1.15, 0.05, "pierre_sombre", plan="XY", segments=16)
	# La plume : une tige et des barbes, en or gravé
	branche("Rachis", (0, 0.55, 0.17), (0, -0.55, 0.17), 0.025, 0.012, "or_grave", segments=4)
	for i in range(6):
		y = 0.4 - i * 0.16
		for cote in (-1, 1):
			branche(f"Barbe_{i}_{cote}", (0, y, 0.17), (cote * (0.28 - i * 0.03), y - 0.12, 0.17),
					0.014, 0.008, "or_grave", segments=4)
	boule("Lueur", 0.08, (0, 0.62, 0.18), "or_grave", aplatissement=0.4,
		  subdivisions=1, emission=0.8)


def cercle_lanterne():
	"""Le cercle de pierres de la ZoneLanterne (Puzzle 3), au sol.

	C'est l'endroit où Mira doit se tenir, lanterne allumée. Huit pierres
	levées en rond, de la mousse, et une dalle centrale qui luit doucement.
	"""
	for i in range(8):
		a = i * math.tau / 8 + random.uniform(-0.1, 0.1)
		r = 2.2
		hauteur = random.uniform(0.35, 0.7)
		boite(f"Pierre_{i}", (0.34, 0.30, hauteur),
			  (math.cos(a) * r, math.sin(a) * r, hauteur * 0.5),
			  random.choice(["galet", "pierre_sombre", "pierre_claire"]),
			  rotation=(0, 0, a), biseau=0.06, tordu=0.12)
		if i % 2 == 0:
			boule(f"Mousse_{i}", 0.16, (math.cos(a) * r, math.sin(a) * r, hauteur),
				  "mousse", aplatissement=0.5, subdivisions=1)
	cylindre("Dalle", 0.7, 0.68, 0.06, (0, 0, 0), "pierre_claire", segments=12)
	# Une lanterne gravée sur la dalle, qui luit : c'est l'indice pour Mira.
	boite("Gravure", (0.18, 0.18, 0.02), (0, 0, 0.065), "lueur", biseau=0.004, emission=1.2)
	anneau("Halo", (0, 0, 0.065), 0.32, 0.018, "lueur", plan="XY", segments=12)


# ──────────────────────────────────────────────────────────────────────────────
# LA STÈLE DU PACTE ET LE PUITS
# ──────────────────────────────────────────────────────────────────────────────


def stele():
	"""La stèle du Pacte d'Aelric, au sol. L'inscription regarde le sud (-Y)."""
	boite("Socle", (1.6, 0.95, 0.35), (0, 0, 0.175), "pierre_sombre", biseau=0.05, tordu=0.01)
	boite("Marche", (1.25, 0.72, 0.25), (0, 0, 0.47), "pierre_sombre", biseau=0.04)
	boite("Dalle", (1.0, 0.42, 2.6), (0, 0, 1.88), "pierre_claire", biseau=0.05, tordu=0.012)
	# Le sommet arrondi : un demi-disque (cylindre couché le long de Y)
	branche("Sommet", (0, -0.21, 3.12), (0, 0.21, 3.12), 0.5, 0.5, "pierre_claire", segments=12)

	# Deux anneaux entrelacés : Aelindra et Aldric, les deux peuples.
	for cx in (-0.14, 0.14):
		anneau(f"Sceau_{cx}", (cx, -0.225, 2.75), 0.2, 0.022, "or_grave", segments=14)

	# Les lignes de l'inscription : des petits signes gravés et dorés.
	for ligne in range(6):
		z = 2.25 - ligne * 0.22
		n = random.randint(4, 6)
		for k in range(n):
			x = -0.34 + k * (0.68 / (n - 1))
			boite(f"Rune_{ligne}_{k}", (random.uniform(0.05, 0.1), 0.02, 0.1),
				  (x, -0.218, z), "or_grave", biseau=0.004, emission=0.6)

	# La mousse au pied : elle est là depuis longtemps.
	for i in range(7):
		boule(f"Mousse_{i}", random.uniform(0.12, 0.25),
			  (random.uniform(-0.8, 0.8), random.choice((-0.5, 0.5)), 0.32),
			  random.choice(["mousse", "feuille_sombre"]), aplatissement=0.5, subdivisions=1)


def puits():
	"""Le puits de la place, au sol. Remplace la boîte de pierre de zone1.gd ET
	l'habillage en primitives de decor_village.gd."""
	cylindre("Mur", 0.98, 0.95, 1.15, (0, 0, 0), "pierre", segments=14)
	# Des pierres en saillie, pour casser le cylindre parfait.
	for i in range(16):
		a = i * math.tau / 16 + random.uniform(-0.1, 0.1)
		boite(f"Moellon_{i}", (0.36, 0.14, 0.22),
			  (math.cos(a) * 0.97, math.sin(a) * 0.97, random.uniform(0.2, 0.95)),
			  random.choice(["pierre_sombre", "pierre_claire", "galet"]),
			  rotation=(0, 0, a + math.pi * 0.5), biseau=0.04)
	anneau("Margelle", (0, 0, 1.2), 0.93, 0.13, "pierre_claire", plan="XY", segments=14)
	cylindre("Eau", 0.82, 0.82, 0.02, (0, 0, 0.95), "bois_mouille", segments=14)

	# Les montants, la toiture, le treuil
	for cote in (-1, 1):
		boite(f"Montant_{cote}", (0.16, 0.16, 3.3), (cote * 0.92, 0, 1.65), "bois", biseau=0.03)
	for cote in (-1, 1):
		boite(f"Toit_{cote}", (2.5, 1.15, 0.08), (0, cote * 0.46, 3.52), "tuile_puits",
			  rotation=(cote * 0.62, 0, 0), biseau=0.02)
	boite("Faitage", (2.6, 0.14, 0.14), (0, 0, 3.86), "bois_sombre", biseau=0.02)
	branche("Treuil", (-0.92, 0, 2.6), (0.92, 0, 2.6), 0.09, 0.09, "bois_clair", segments=8)
	branche("Manivelle", (1.0, 0, 2.6), (1.0, -0.28, 2.38), 0.03, 0.03, "fer", segments=4)
	branche("Corde", (0.1, 0, 2.55), (0.1, 0, 1.85), 0.015, 0.015, "corde", segments=4)
	cylindre("Seau", 0.17, 0.21, 0.30, (0.1, 0, 1.55), "bois", segments=10)
	cylindre("SeauCercle", 0.215, 0.215, 0.04, (0.1, 0, 1.75), "fer", segments=10)


# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
	total = 0
	for nom_fichier, graine, fabrique in [
		("porte_double.glb", 41, porte_double),
		("palissade.glb", 42, palissade),
		("grille.glb", 43, grille),
		("perchoir.glb", 44, perchoir),
		("oiseau.glb", 45, oiseau),
		("roue_eau.glb", 46, roue_eau),
		("roue_support.glb", 47, roue_support),
		("pont.glb", 48, pont),
		("berge.glb", 49, berge),
		("liane.glb", 50, liane),
		("stele.glb", 51, stele),
		("puits.glb", 52, puits),
		("verrou.glb", 53, verrou),
		("plateforme.glb", 54, plateforme),
		("cercle_lanterne.glb", 55, cercle_lanterne),
	]:
		vider_la_scene()
		random.seed(graine)
		fabrique()
		total += exporter(SOUS_DOSSIER, nom_fichier, lisse=False)
	print(f"Total props : {total} faces")
