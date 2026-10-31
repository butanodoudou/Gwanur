# tools/gen_personnages.py — Kael et Mira
#
# Remplace les capsules bleues de kael.tscn / mira.tscn.
#
# CE QU'ON VISE
# Des personnages lisibles à 9 mètres — c'est la distance de la caméra du jeu.
# À cette distance, ce qui identifie un personnage n'est pas son visage mais :
#   1. sa SILHOUETTE (Kael élancé, Mira plus solide et plus ramassée) ;
#   2. sa COULEUR dominante (vert nature / auburn) ;
#   3. son ÉQUIPEMENT, qui déborde de la silhouette (la corne de Kael, la
#      lanterne de Mira) et qu'on reconnaît de dos comme de face.
# Inutile de sculpter des doigts : on ne les verra jamais.
#
# ORIENTATION
# `character_base.gd` fait `rotation.y = atan2(direction.x, direction.z)` :
# à la rotation 0, le personnage doit donc regarder vers +Z de Godot, soit
# -Y dans Blender. Tout ce qui est au visage va en -Y.
#
# ANIMATION
# Ce fichier construit les maillages ; le squelette et les animations sont
# ajoutés par tools/animer_personnages.py (appelé par le main ci-dessous).
#
# Usage :
#   blender --background --python tools/gen_personnages.py
# Sortie :
#   assets/models/personnages/kael.glb
#   assets/models/personnages/mira.glb

import bpy
import math
import os
import random
import sys
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from blender_commun import boite, boule, cylindre, branche, vider_la_scene, exporter

SOUS_DOSSIER = "personnages"

TAILLE = 1.80   # hauteur totale visée, en mètres

# Repères verticaux, en fraction de la taille. Les proportions sont un peu
# stylisées : tête plus grosse et jambes plus courtes que la réalité, comme
# dans un film d'animation — un humain « exact » paraît raide et fluet.
Y_PIED     = 0.00
Y_GENOU    = 0.25
Y_BASSIN   = 0.46
Y_TAILLE   = 0.56
Y_EPAULE   = 0.80
Y_COU      = 0.845
Y_TETE     = 0.90


def h(fraction):
	return TAILLE * fraction


# ──────────────────────────────────────────────────────────────────────────────
# CORPS
# ──────────────────────────────────────────────────────────────────────────────


def corps(carrure, couleur_tunique, couleur_pantalon="cuir", jupe=False):
	"""Le tronc, les jambes, les bras. `carrure` : 1.0 = élancé, 1.2 = solide."""
	l_epaules = 0.40 * carrure
	l_bassin  = 0.27 * carrure

	# ── Jambes ───────────────────────────────────────────────────────────────
	for cote in (-1, 1):
		x = cote * l_bassin * 0.33
		# Cuisse puis mollet : deux segments légèrement décalés valent mieux
		# qu'un cylindre unique, la jambe a une articulation.
		branche("Cuisse", (x, 0, h(Y_BASSIN)), (x, 0.01, h(Y_GENOU)),
				0.085 * carrure, 0.070 * carrure, couleur_pantalon, segments=6)
		branche("Mollet", (x, 0.01, h(Y_GENOU)), (x, 0, h(0.045)),
				0.070 * carrure, 0.050 * carrure, couleur_pantalon, segments=6)
		# Botte : elle dépasse vers l'avant (-Y), sinon le personnage a l'air
		# de finir en pointe.
		boite("Botte", (0.115 * carrure, 0.26, 0.09),
			  (x, -0.035, h(0.030)), "cuir", biseau=0.025)

	# ── Torse ────────────────────────────────────────────────────────────────
	# Un tronc de cône du bassin aux épaules : la carrure se lit tout de suite.
	branche("Torse", (0, 0, h(Y_BASSIN) - 0.02), (0, 0, h(Y_EPAULE)),
			l_bassin * 0.52, l_epaules * 0.48, couleur_tunique, segments=8)

	if jupe:
		# Une tunique longue, fendue : silhouette plus douce, plus elfique.
		branche("Tunique", (0, 0, h(Y_BASSIN) + 0.06), (0, 0, h(Y_GENOU) + 0.05),
				l_bassin * 0.56, l_bassin * 0.72, couleur_tunique, segments=8)

	# Ceinture
	cylindre("Ceinture", l_bassin * 0.56, l_bassin * 0.56, 0.055,
			 (0, 0, h(Y_TAILLE)), "cuir", segments=10)

	# ── Épaules et bras ──────────────────────────────────────────────────────
	for cote in (-1, 1):
		x = cote * l_epaules * 0.5
		boule("Epaule", 0.075 * carrure, (x, 0, h(Y_EPAULE)), couleur_tunique,
			  subdivisions=2)
		coude = Vector((x + cote * 0.035, 0.015, h(0.63)))
		main  = Vector((x + cote * 0.055, -0.02, h(0.47)))
		branche("Bras", (x, 0, h(Y_EPAULE)), coude,
				0.062 * carrure, 0.050 * carrure, couleur_tunique, segments=6)
		branche("Avantbras", coude, main,
				0.050 * carrure, 0.042 * carrure, "peau", segments=6)
		boule("Main", 0.055 * carrure, main, "peau", subdivisions=2)

	# ── Cou et tête ──────────────────────────────────────────────────────────
	cylindre("Cou", 0.055, 0.055, 0.05, (0, 0, h(Y_COU) - 0.02), "peau", segments=8)
	# La tête est une boule légèrement étirée en hauteur, pas une sphère.
	boule("Tete", 0.115, (0, -0.005, h(Y_TETE) + 0.035), "peau",
		  aplatissement=1.15, subdivisions=2)

	# Les yeux : deux taches sombres. À 9 m c'est tout ce qu'on perçoit, et
	# sans elles on ne sait pas de quel côté regarde le personnage.
	for cote in (-1, 1):
		boite("Oeil", (0.028, 0.02, 0.030),
			  (cote * 0.042, -0.105, h(Y_TETE) + 0.045), "ecorce", biseau=0.008)


def cheveux(couleur, longueur=0.10, queue=False):
	"""Une calotte qui coiffe le crâne, plus une natte optionnelle."""
	boule("Cheveux", 0.122, (0, 0.006, h(Y_TETE) + 0.055), couleur,
		  aplatissement=1.0, subdivisions=2)
	# La frange, côté visage (-Y)
	boite("Frange", (0.19, 0.05, 0.07), (0, -0.085, h(Y_TETE) + 0.085),
		  couleur, biseau=0.02)
	# La nuque
	boite("Nuque", (0.18, 0.08, longueur),
		  (0, 0.065, h(Y_TETE) + 0.045 - longueur * 0.4), couleur, biseau=0.03)
	if queue:
		# Queue de cheval : elle donne du mouvement et se voit de dos.
		branche("Queue", (0, 0.10, h(Y_TETE) + 0.03), (0, 0.145, h(0.70)),
				0.045, 0.022, couleur, segments=6)


def oreilles_pointues(couleur="peau"):
	"""L'héritage elfique de Kael — un détail de silhouette, pas de visage."""
	for cote in (-1, 1):
		branche("Oreille", (cote * 0.105, 0.0, h(Y_TETE) + 0.045),
				(cote * 0.155, 0.045, h(Y_TETE) + 0.115),
				0.028, 0.006, couleur, segments=5)


# ──────────────────────────────────────────────────────────────────────────────
# KAEL — magie elfique, brassards de Sève, corne d'Appel, carnet
# ──────────────────────────────────────────────────────────────────────────────


def kael():
	corps(carrure=1.0, couleur_tunique="tunique_kael", jupe=True)
	cheveux("cheveux_kael", longueur=0.13)
	oreilles_pointues()

	# ── Les Brassards de Sève ────────────────────────────────────────────────
	# Deux anneaux lumineux aux avant-bras. L'émission les rend visibles même
	# à l'ombre : c'est la signature de Kael, elle doit se lire de loin.
	for cote in (-1, 1):
		x = cote * 0.40 * 0.5 + cote * 0.045
		cylindre("Brassard", 0.062, 0.062, 0.075, (x, 0.0, h(0.53)),
				 "seve", segments=10, emission=2.5)
		cylindre("BrassardBord", 0.066, 0.066, 0.018, (x, 0.0, h(0.575)),
				 "cuir", segments=10)

	# ── La Corne d'Appel ─────────────────────────────────────────────────────
	# Portée en bandoulière dans le dos (+Y), pointe vers le haut.
	branche("Corne", (0.11, 0.12, h(0.52)), (0.19, 0.17, h(0.68)),
			0.052, 0.018, "torchis", segments=7)
	cylindre("EmboutCorne", 0.030, 0.030, 0.03, (0.19, 0.17, h(0.68)),
			 "cuivre", segments=8)
	# La bandoulière qui la tient
	boite("Bandouliere", (0.30, 0.055, 0.045), (0, 0.02, h(0.70)),
		  "cuir", rotation=(0, 0.55, 0), biseau=0.015)

	# ── Le Carnet des Anciens ────────────────────────────────────────────────
	# À la ceinture, côté gauche.
	boite("Carnet", (0.10, 0.03, 0.135), (-0.145, -0.01, h(0.50)),
		  "tuile_2", biseau=0.012)
	boite("Sangle", (0.035, 0.05, 0.10), (-0.145, -0.01, h(0.545)),
		  "cuir", biseau=0.01)


# ──────────────────────────────────────────────────────────────────────────────
# MIRA — robustesse humaine, grappin de cuivre, lanterne, sac d'alchimiste
# ──────────────────────────────────────────────────────────────────────────────


def mira():
	corps(carrure=1.2, couleur_tunique="tunique_mira", jupe=False)
	cheveux("cheveux_mira", longueur=0.09, queue=True)

	# ── Plastron de cuir ─────────────────────────────────────────────────────
	# Mira est la pragmatique : elle porte du cuir renforcé, pas une tunique.
	branche("Plastron", (0, 0, h(0.58)), (0, 0, h(0.79)), 0.175, 0.205,
			"cuir", segments=8)
	for cote in (-1, 1):
		boite("Bretelle", (0.05, 0.19, 0.055),
			  (cote * 0.085, 0.0, h(0.795)), "cuir", rotation=(0.15, 0, 0), biseau=0.015)

	# ── Le Grappin de Cuivre ─────────────────────────────────────────────────
	# Sur l'avant-bras droit : un manchon de cuivre et trois griffes.
	x = 0.40 * 1.2 * 0.5 + 0.055
	cylindre("Grappin", 0.075, 0.070, 0.13, (x, -0.01, h(0.50)),
			 "cuivre", segments=10)
	for i in range(3):
		a = -0.5 + i * 0.5
		branche("Griffe", (x, -0.01, h(0.475)),
				(x + math.sin(a) * 0.05, -0.10, h(0.44)),
				0.017, 0.007, "metal", segments=4)
	# La bobine de corde
	cylindre("Bobine", 0.055, 0.055, 0.055, (x, 0.055, h(0.545)),
			 "torchis", segments=10)

	# ── La Lanterne à Mémoire ────────────────────────────────────────────────
	# Accrochée à la hanche gauche. Le verre émet : c'est le repère visuel de
	# Mira dans la pénombre de la cavité de l'Aelith.
	lx = -0.185
	boite("LanterneCage", (0.085, 0.085, 0.115), (lx, -0.02, h(0.475)),
		  "cuivre", biseau=0.012)
	boite("LanterneVerre", (0.065, 0.065, 0.075), (lx, -0.02, h(0.478)),
		  "lueur", biseau=0.01, emission=3.0)
	branche("LanterneAnse", (lx - 0.03, -0.02, h(0.515)), (lx + 0.03, -0.02, h(0.515)),
			0.008, 0.008, "cuivre", segments=4)

	# ── Le Sac d'Alchimiste ──────────────────────────────────────────────────
	# Dans le dos (+Y), avec deux fioles accrochées dessus.
	boite("Sac", (0.24, 0.12, 0.20), (0, 0.145, h(0.62)), "cuir", biseau=0.03)
	for i, teinte in enumerate(["seve", "lueur"]):
		boite("Fiole", (0.035, 0.035, 0.07),
			  (-0.06 + i * 0.12, 0.215, h(0.63)), teinte, biseau=0.01, emission=1.2)


# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
	# Le squelette et les animations sont ajoutés par animer_personnages.py,
	# qui reconstruit les modèles avec les fonctions de ce fichier. Lancer ce
	# script-ci ou l'autre revient donc au même.
	import animer_personnages
	animer_personnages.generer_heros()
