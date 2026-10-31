# tools/animer_personnages.py — squelette et animations de Kael, Mira et des PNJ
#
# POURQUOI CE FICHIER
# Les modèles de `gen_personnages.py` sont faits de pièces rigides (cuisse,
# mollet, botte, bras…). Ici on leur ajoute :
#   1. un SQUELETTE (une « Armature » Blender) : 18 os, du bassin aux pieds ;
#   2. un RATTACHEMENT de chaque pièce à son os, avec un poids de 1.0. Le
#      modèle étant fait de pièces séparées, chaque pièce suit UN os, sans se
#      déformer — c'est propre et ça évite les coudes « en caoutchouc ».
#      Exceptions douces : le torse (moitié bassin, moitié colonne) et la
#      tunique de Kael (le bas suit un peu les cuisses, comme un tissu) ;
#   3. des ANIMATIONS clé par clé, calculées en Python à chaque image :
#        idle      — boucle, 3,0 s (Kael) / 2,5 s (Mira) : respiration, regard
#        marche    — boucle, 1,0 s : un cycle = deux pas
#        course    — boucle, 1,0 s : idem, plus ample, buste penché
#        interagir — geste court (0,6 s), bras tendu
#        skill1    — Kael lève les brassards / Mira lance le grappin
#        skill2    — Kael porte la corne / Mira touche sa lanterne
#
# DES PIEDS QUI NE PATINENT PAS
# Pour la marche et la course, on ne devine pas les angles des jambes : on
# décide où est le PIED à chaque instant (posé au sol et reculant à vitesse
# constante pendant l'appui, puis levé et ramené vers l'avant), et on calcule
# les angles de la cuisse et du genou qui l'y amènent (« cinématique
# inverse » à deux os : la loi des cosinus). Le bassin descend juste ce qu'il
# faut pour que la jambe atteigne le sol — c'est de là que vient le rebond.
#
# CONTRAT AVEC GODOT (scripts/characters/character_base.gd)
# Un cycle de marche fait avancer le personnage de FOULEE_MARCHE mètres, un
# cycle de course de FOULEE_COURSE mètres. Les deux cycles durent DUREE_CYCLE
# seconde dans le fichier : Godot accélère la lecture selon la vitesse réelle
# (vitesse / foulée), et les pieds restent collés au sol. Les deux cycles ont
# la MÊME durée pour pouvoir être mélangés sans que les jambes se contredisent.
# ⚠ Changer une de ces valeurs = changer aussi character_base.gd.
#
# ORIENTATION ET ÉCHELLE : inchangées. Le modèle regarde -Y dans Blender
# (= +Z dans Godot), ses pieds sont sur z = 0. L'armature est à l'origine.
#
# Usage :
#   blender --background --python tools/animer_personnages.py
#   (gen_personnages.py lancé seul fait la même chose)
# Sortie :
#   assets/models/personnages/kael.glb, mira.glb (avec squelette + animations)
# Les PNJ passent aussi par ici : voir gen_pnj.py (fonction `animer_pnj`).

import bpy
import math
import os
import random
import sys
from mathutils import Matrix, Vector, Quaternion

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from blender_commun import vider_la_scene, DOSSIER_ASSETS
import gen_personnages as gp

SOUS_DOSSIER = "personnages"
IPS = 30                 # images par seconde des animations

# ── Contrat avec character_base.gd ───────────────────────────────────────────
FOULEE_MARCHE = 1.2      # mètres parcourus pendant un cycle de marche
FOULEE_COURSE = 3.0      # mètres parcourus pendant un cycle de course
DUREE_CYCLE = 1.0        # durée d'un cycle de marche ET de course, en secondes

# ── Le squelette ─────────────────────────────────────────────────────────────
# Suffixe _g = gauche du personnage = +X dans Blender (il regarde -Y).
# L'ordre compte : un parent est toujours listé avant ses enfants.
ORDRE = [
	"racine", "bassin", "colonne", "cou", "tete",
	"bras_g", "avantbras_g", "bras_d", "avantbras_d",
	"cuisse_g", "tibia_g", "pied_g", "cuisse_d", "tibia_d", "pied_d",
]
PARENTS = {
	"bassin": "racine", "colonne": "bassin", "cou": "colonne", "tete": "cou",
	"bras_g": "colonne", "avantbras_g": "bras_g",
	"bras_d": "colonne", "avantbras_d": "bras_d",
	"cuisse_g": "bassin", "tibia_g": "cuisse_g", "pied_g": "tibia_g",
	"cuisse_d": "bassin", "tibia_d": "cuisse_d", "pied_d": "tibia_d",
}
# Os du haut du corps : ceux que les gestes (interagir, skills) animent.
# Godot s'en sert comme filtre pour que les jambes continuent de marcher.
HAUT_DU_CORPS = ["colonne", "cou", "tete", "bras_g", "avantbras_g", "bras_d", "avantbras_d"]

# Quelle pièce du modèle suit quel os. Le nom est celui donné dans
# gen_personnages.py / gen_pnj.py (Blender ajoute .001, .002… aux doublons :
# on les enlève avant de chercher). « membre » = l'os existe à gauche et à
# droite, on choisit le côté d'après la position de la pièce.
OS_PAR_PIECE = {
	# jambes
	"Cuisse": "cuisse", "Mollet": "tibia", "Botte": "pied",
	# bras
	"Epaule": "bras", "Bras": "bras",
	"Avantbras": "avantbras", "Main": "avantbras",
	"Brassard": "avantbras", "BrassardBord": "avantbras",
	"Grappin": "avantbras", "Griffe": "avantbras", "Bobine": "avantbras",
	# tête
	"Cou": "cou",
	"Tete": "tete", "Oeil": "tete", "Cheveux": "tete", "Frange": "tete",
	"Nuque": "tete", "Queue": "tete", "Oreille": "tete", "Barbe": "tete",
	"Moustache": "tete", "ChapeauBord": "tete", "ChapeauCalotte": "tete",
	"ChapeauRuban": "tete", "Chignon": "tete", "Couette": "tete",
	# bassin : ce qui est accroché à la ceinture
	"Ceinture": "bassin", "Carnet": "bassin", "Sangle": "bassin",
	"LanterneCage": "bassin", "LanterneVerre": "bassin", "LanterneAnse": "bassin",
	"Besace": "bassin", "Sacoche": "bassin", "Robe": "bassin", "Ourlet": "bassin",
	# colonne : ce qui est sur le buste ou dans le dos
	"Corne": "colonne", "EmboutCorne": "colonne", "Bandouliere": "colonne",
	"Plastron": "colonne", "Bretelle": "colonne", "Sac": "colonne",
	"Fiole": "colonne", "Etole": "colonne", "Foulard": "colonne",
	"Col": "colonne", "TablierSangle": "colonne",
	# le bâton de l'ancien est planté dans le sol : il ne bouge pas
	"Baton": "racine", "BatonPommeau": "racine",
	# pièces réparties sur deux os (voir _poids_de_la_piece)
	"Torse": "degrade", "Tablier": "degrade", "Tunique": "jupe",
}
MEMBRES = {"cuisse", "tibia", "pied", "bras", "avantbras"}


def h(fraction):
	return gp.TAILLE * fraction


def _lisse(x):
	"""0 → 1 en douceur (smoothstep) : départ et arrivée sans à-coup."""
	x = min(max(x, 0.0), 1.0)
	return x * x * (3.0 - 2.0 * x)


def _rx(angle):
	return Matrix.Rotation(angle, 3, "X")


def _ry(angle):
	return Matrix.Rotation(angle, 3, "Y")


def _rz(angle):
	return Matrix.Rotation(angle, 3, "Z")


R = math.radians   # les réglages sont en degrés, plus lisibles


# ──────────────────────────────────────────────────────────────────────────────
# 1. LE SQUELETTE
# ──────────────────────────────────────────────────────────────────────────────


def reperes(carrure):
	"""Tête et queue de chaque os, aux articulations du corps de gp.corps().

	Les valeurs recopient celles de `gen_personnages.corps()` : épaule, coude,
	main, hanche, genou, cheville. Si on change le corps, on change ici.
	"""
	l_epaules = 0.40 * carrure
	l_bassin = 0.27 * carrure
	rep = {
		"racine":  ((0, 0, 0), (0, 0, 0.12)),
		"bassin":  ((0, 0, h(gp.Y_BASSIN)), (0, 0, h(gp.Y_TAILLE))),
		"colonne": ((0, 0, h(gp.Y_TAILLE)), (0, 0, h(gp.Y_EPAULE))),
		"cou":     ((0, 0, h(gp.Y_EPAULE)), (0, 0, h(gp.Y_TETE) - 0.035)),
		"tete":    ((0, 0, h(gp.Y_TETE) - 0.035), (0, 0, h(gp.Y_TETE) + 0.16)),
	}
	for suffixe, cote in (("g", 1), ("d", -1)):
		x = cote * l_bassin * 0.33
		rep["cuisse_" + suffixe] = ((x, 0, h(gp.Y_BASSIN)), (x, 0.01, h(gp.Y_GENOU)))
		rep["tibia_" + suffixe] = ((x, 0.01, h(gp.Y_GENOU)), (x, 0, h(0.045)))
		rep["pied_" + suffixe] = ((x, 0, h(0.045)), (x, -0.15, h(0.02)))
		xe = cote * l_epaules * 0.5
		coude = (xe + cote * 0.035, 0.015, h(0.63))
		main = (xe + cote * 0.055, -0.02, h(0.47))
		rep["bras_" + suffixe] = ((xe, 0, h(gp.Y_EPAULE)), coude)
		rep["avantbras_" + suffixe] = (coude, main)
	return {nom: (Vector(t), Vector(q)) for nom, (t, q) in rep.items()}


def pencher_reperes(rep, angle, pivot_z):
	"""Même voûte que gen_pnj._pencher_le_haut_du_corps : le haut du corps
	pivote vers l'avant autour du bassin. Les jambes restent droites."""
	pivot = Vector((0, 0, pivot_z))
	rot = _rx(angle)
	for nom in ("bassin", "colonne", "cou", "tete", "bras_g", "avantbras_g",
				"bras_d", "avantbras_d"):
		tete, queue = rep[nom]
		if nom != "bassin":
			tete = pivot + rot @ (tete - pivot)
		queue = pivot + rot @ (queue - pivot)
		rep[nom] = (tete, queue)


def creer_armature(rep):
	donnees = bpy.data.armatures.new("Armature")
	arm = bpy.data.objects.new("Armature", donnees)
	bpy.context.collection.objects.link(arm)
	bpy.context.view_layer.objects.active = arm
	arm.select_set(True)
	bpy.ops.object.mode_set(mode="EDIT")
	for nom in ORDRE:
		eb = donnees.edit_bones.new(nom)
		eb.head, eb.tail = rep[nom]
		eb.roll = 0.0
	for nom, parent in PARENTS.items():
		donnees.edit_bones[nom].parent = donnees.edit_bones[parent]
	bpy.ops.object.mode_set(mode="OBJECT")
	return arm


# ──────────────────────────────────────────────────────────────────────────────
# 2. LE RATTACHEMENT DES PIÈCES
# ──────────────────────────────────────────────────────────────────────────────


def _nom_de_base(nom):
	return nom.split(".")[0]


def _poids_de_la_piece(regle, cote, co, centre_x):
	"""Renvoie {os: poids} pour UN sommet (coordonnées monde `co`)."""
	if regle == "degrade":
		# Du bassin à la colonne, selon la hauteur : un buste qui se tord sans
		# se détacher de la ceinture.
		z0, z1 = h(gp.Y_TAILLE) - 0.05, h(gp.Y_TAILLE) + 0.07
		w = _lisse((co.z - z0) / (z1 - z0))
		return {"bassin": 1.0 - w, "colonne": w}
	if regle == "jupe":
		# Le haut de la tunique suit le bassin ; le bas suit un peu la cuisse
		# du même côté, comme un tissu qu'un genou pousse.
		z_haut, z_bas = h(gp.Y_BASSIN), h(gp.Y_GENOU)
		bas = _lisse((z_haut - co.z) / (z_haut - z_bas)) * 0.45
		g = bas * min(max(0.5 + co.x / 0.18, 0.0), 1.0)
		d = bas - g
		return {"bassin": 1.0 - g - d, "cuisse_g": g, "cuisse_d": d}
	if regle in MEMBRES:
		return {regle + "_" + cote: 1.0}
	return {regle: 1.0}


def rattacher(arm):
	"""Fusionne les pièces en un seul maillage et le lie au squelette."""
	bpy.context.view_layer.update()
	pieces = [o for o in bpy.data.objects if o.type == "MESH"]
	for objet in pieces:
		base = _nom_de_base(objet.name)
		regle = OS_PAR_PIECE.get(base)
		if regle is None:
			print(f"  ⚠ pièce sans os connu : {objet.name} → colonne")
			regle = "colonne"
		monde = [objet.matrix_world @ v.co for v in objet.data.vertices]
		centre_x = sum(c.x for c in monde) / max(len(monde), 1)
		cote = "g" if centre_x >= 0.0 else "d"
		groupes = {}
		for i, co in enumerate(monde):
			for nom_os, poids in _poids_de_la_piece(regle, cote, co, centre_x).items():
				if poids <= 0.0001:
					continue
				if nom_os not in groupes:
					groupes[nom_os] = objet.vertex_groups.get(nom_os) or objet.vertex_groups.new(name=nom_os)
				groupes[nom_os].add([i], poids, "REPLACE")

	# Fusion, comme blender_commun.exporter() : un seul noeud côté Godot.
	bpy.ops.object.select_all(action="DESELECT")
	for objet in pieces:
		objet.select_set(True)
	bpy.context.view_layer.objects.active = pieces[0]
	bpy.ops.object.join()
	maillage = bpy.context.active_object
	# La fusion garde la position de la première pièce comme origine : on
	# « applique » cette position pour que le maillage parte de (0, 0, 0),
	# exactement comme l'armature. Sinon le skin serait décalé dans Godot.
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	bpy.ops.object.shade_flat()

	maillage.parent = arm
	mod = maillage.modifiers.new("Armature", "ARMATURE")
	mod.object = arm
	return maillage


# ──────────────────────────────────────────────────────────────────────────────
# 3. LES POSES
# ──────────────────────────────────────────────────────────────────────────────
# Une pose est décrite en « rotations monde » : pour chaque os, la rotation
# (autour de sa tête) qui l'amène de sa position de repos à la pose voulue,
# exprimée dans les axes de l'armature. Un os absent suit son parent.
# `_cles` traduit ça dans le repère local de chaque os, ce qu'attend Blender.


class Pose:
	def __init__(self):
		self.monde = {}                   # nom → Matrix 3x3
		self.decalage_bassin = Vector()   # translation du bassin (monde)


def _completer(pose):
	plein = {}
	for nom in ORDRE:
		if nom in pose.monde:
			plein[nom] = pose.monde[nom]
		elif nom in PARENTS:
			plein[nom] = plein[PARENTS[nom]]
		else:
			plein[nom] = Matrix.Identity(3)
	return plein


def _cles(arm, pose, image, precedent):
	plein = _completer(pose)
	for nom in ORDRE:
		pb = arm.pose.bones[nom]
		B = pb.bone.matrix_local.to_3x3()
		parent = plein[PARENTS[nom]] if nom in PARENTS else Matrix.Identity(3)
		relatif = parent.inverted() @ plein[nom]
		q = (B.inverted() @ relatif @ B).to_quaternion()
		# Un quaternion et son opposé sont la même rotation : on garde celui
		# qui est du même côté que l'image précédente, sinon l'interpolation
		# ferait un tour complet entre deux images.
		if nom in precedent and q.dot(precedent[nom]) < 0.0:
			q.negate()
		precedent[nom] = q
		pb.rotation_mode = "QUATERNION"
		pb.rotation_quaternion = q
		pb.keyframe_insert("rotation_quaternion", frame=image, group=nom)
	pb = arm.pose.bones["bassin"]
	pb.location = pb.bone.matrix_local.to_3x3().inverted() @ pose.decalage_bassin
	pb.keyframe_insert("location", frame=image, group="bassin")


def _jambe(pose, rep, cote, cheville, tangage):
	"""Cinématique inverse : place la cheville à `cheville` (monde).

	Le genou plie toujours vers l'avant. `tangage` > 0 = pointe du pied levée.
	"""
	hanche_r, genou_r = rep["cuisse_" + cote]
	_, cheville_r = rep["tibia_" + cote]
	tete_bassin = rep["bassin"][0]
	W_bassin = pose.monde.get("bassin", Matrix.Identity(3))
	hanche = tete_bassin + pose.decalage_bassin + W_bassin @ (hanche_r - tete_bassin)

	L1 = (genou_r - hanche_r).length
	L2 = (cheville_r - genou_r).length
	D = cheville - hanche
	avant = -D.y                           # l'avant est -Y
	cote_bas = Vector((D.x, 0.0, D.z))     # la direction « vers le bas » du plan de la jambe
	r = cote_bas.length
	cote_bas.normalize()
	d = math.hypot(avant, r)
	d_max = (L1 + L2) * 0.999
	if d > d_max:                          # trop loin : jambe tendue, pied raccourci
		D = D * (d_max / d)
		avant, r = avant * d_max / d, r * d_max / d
		d = d_max
	phi = math.atan2(avant, r)             # angle de la ligne hanche-cheville
	cos_b = (L1 * L1 + d * d - L2 * L2) / (2.0 * L1 * d)
	t1 = phi + math.acos(min(max(cos_b, -1.0), 1.0))
	genou = hanche + Vector((0, -1, 0)) * (L1 * math.sin(t1)) + cote_bas * (L1 * math.cos(t1))
	cheville = hanche + D

	pose.monde["cuisse_" + cote] = (genou_r - hanche_r).rotation_difference(genou - hanche).to_matrix()
	pose.monde["tibia_" + cote] = (cheville_r - genou_r).rotation_difference(cheville - genou).to_matrix()
	pose.monde["pied_" + cote] = _rx(-tangage)


def _bras(pose, cote, balance, coude, ecart=0.0, torsion=0.0):
	"""`balance` > 0 = bras vers l'avant ; `coude` > 0 = avant-bras qui se plie
	vers l'avant ; `ecart` > 0 = bras qui s'écarte du corps."""
	signe = 1.0 if cote == "g" else -1.0
	W_col = pose.monde.get("colonne", pose.monde.get("bassin", Matrix.Identity(3)))
	W = W_col @ _rz(torsion * signe) @ _ry(-signe * ecart) @ _rx(-balance)
	pose.monde["bras_" + cote] = W
	pose.monde["avantbras_" + cote] = W @ _rx(-coude)


def _tete(pose, lacet, tangage, roulis=0.0):
	"""Le regard, en rotation MONDE : la tête reste stable quand le buste
	tourne. `tangage` > 0 = regarde vers le bas."""
	W_tete = _rz(lacet) @ _rx(tangage) @ _ry(roulis)
	W_col = pose.monde.get("colonne", Matrix.Identity(3))
	pose.monde["cou"] = W_col.to_quaternion().slerp(W_tete.to_quaternion(), 0.5).to_matrix()
	pose.monde["tete"] = W_tete


# ── Le pied pendant un cycle ─────────────────────────────────────────────────
TALON = 0.09    # du talon à la cheville (botte de gen_personnages : -0.035 ± 0.13)
POINTE = 0.165  # de la cheville à la pointe


def _pied_dans_le_cycle(p, st, foulee, hauteur_cheville):
	"""Position (avant, hauteur) de la cheville par rapport à l'aplomb du
	bassin, et tangage du pied, à la phase p ∈ [0, 1) de SA jambe.

	p = 0 : le talon touche le sol, pied devant.
	[0, beta) : appui. Le pied est au sol et recule à la vitesse du corps. Il
	            attaque par le talon puis déroule jusqu'à la pointe.
	[beta, 1) : le pied est en l'air et revient vers l'avant.
	"""
	beta = st["appui"]
	trajet = foulee * beta    # ce que recule le pied posé pendant l'appui

	def appui(k):              # k ∈ [0, 1] : avancement de l'appui
		g = trajet * (0.5 - k)
		if k < 0.15:           # attaque du talon : pointe levée qui s'abaisse
			a = R(st["attaque"]) * (1.0 - _lisse(k / 0.15))
			f = g - TALON + TALON * math.cos(a) - hauteur_cheville * math.sin(a)
			z = TALON * math.sin(a) + hauteur_cheville * math.cos(a)
			return f, z, a
		if k > 0.6:            # déroulé : le talon se lève, la pointe reste au sol
			a = R(st["deroule"]) * _lisse((k - 0.6) / 0.4)
			f = g + POINTE - POINTE * math.cos(a) + hauteur_cheville * math.sin(a)
			z = POINTE * math.sin(a) + hauteur_cheville * math.cos(a)
			return f, z, -a
		return g, hauteur_cheville, 0.0

	if p < beta:
		return appui(p / beta)
	q = (p - beta) / (1.0 - beta)
	f0, z0, t0 = appui(1.0)
	f1, z1, t1 = appui(0.0)
	s = _lisse(q) ** st["retard_pied"]   # > 1 : le pied traîne derrière (course)
	f = f0 + (f1 - f0) * s
	z = z0 + (z1 - z0) * s + st["hauteur_pas"] * math.sin(math.pi * q ** st["pic_pas"])
	t = t0 + (t1 - t0) * _lisse(q)
	return f, z, t


def _min_doux(a, b, k=0.015):
	"""min(a, b) sans angle vif : le bassin ne « cogne » pas sa limite."""
	hh = max(k - abs(a - b), 0.0) / k
	return min(a, b) - hh * hh * k * 0.25


def pose_locomotion(rep, st, foulee, u):
	"""La pose de marche ou de course à la phase u ∈ [0, 1) du cycle."""
	pose = Pose()
	beta = st["appui"]
	tour = 2.0 * math.pi
	# Instant de référence : milieu de l'appui de la jambe gauche.
	milieu = u - beta * 0.5

	# ── Bassin : il tourne, se balance et se dandine ────────────────────────
	lacet = -R(st["lacet_bassin"]) * math.cos(tour * u)          # hanche avant = jambe avant
	roulis = -R(st["roulis_bassin"]) * math.cos(tour * milieu)   # la hanche libre descend
	W_bassin = _rz(lacet) @ _ry(roulis) @ _rx(R(st["penche_bassin"]))
	pose.monde["bassin"] = W_bassin
	balance_x = st["balance_x"] * math.cos(tour * milieu)         # au-dessus du pied d'appui

	hanche_z = rep["bassin"][0].z
	cible_z = -st["accroupi"] + st["rebond"] * math.cos(2.0 * tour * milieu)

	# Les pieds
	pieds = {}
	for cote, decalage in (("g", 0.0), ("d", 0.5)):
		p = (u + decalage) % 1.0
		f, z, t = _pied_dans_le_cycle(p, st, foulee, rep["pied_" + cote][0].z)
		x = rep["cuisse_" + cote][0].x * st["ecart_pieds"]
		pieds[cote] = (Vector((x, -f, z)), t, p < beta)

	# Le bassin descend juste assez pour que chaque pied posé soit atteint.
	dz = cible_z
	for cote, (pied, _, au_sol) in pieds.items():
		if not au_sol:
			continue
		hanche_r, genou_r = rep["cuisse_" + cote]
		_, cheville_r = rep["tibia_" + cote]
		portee = ((genou_r - hanche_r).length + (cheville_r - genou_r).length) * 0.985
		h_rel = W_bassin @ (hanche_r - rep["bassin"][0])
		dx = (balance_x + h_rel.x) - pied.x
		dy = h_rel.y - pied.y
		atteignable = pied.z + math.sqrt(max(portee ** 2 - dx * dx - dy * dy, 0.0))
		dz = _min_doux(dz, atteignable - (hanche_z + h_rel.z))
	pose.decalage_bassin = Vector((balance_x, 0.0, dz))

	# ── Buste : il tourne à l'opposé du bassin, et se penche ────────────────
	pose.monde["colonne"] = W_bassin @ _rz(-lacet * st["contre_buste"]) \
		@ _ry(-roulis * 0.6) @ _rx(R(st["penche"]) - R(st["penche_bassin"]))

	# ── Jambes ───────────────────────────────────────────────────────────────
	for cote, (pied, tangage, _) in pieds.items():
		_jambe(pose, rep, cote, pied, tangage)

	# ── Bras : à l'opposé de la jambe du même côté, avec un léger retard ────
	for cote, decalage in (("g", 0.0), ("d", 0.5)):
		phase = math.cos(tour * (u + decalage - st["retard_bras"]))
		balance = R(st["bras_milieu"]) - R(st["bras"]) * phase
		coude = R(st["coude"]) + R(st["coude_plus"]) * max(-phase, 0.0)
		_bras(pose, cote, balance, coude, ecart=R(st["ecart_bras"]))

	# ── Tête : stable, avec un petit hochement à chaque pas ─────────────────
	_tete(pose, lacet * 0.15, R(st["regard"]) + R(st["hochement"]) * math.cos(2.0 * tour * milieu))
	return pose


# ── Les réglages de chaque personnage ────────────────────────────────────────
# Kael : souple et aérien — pieds qui montent haut, grands bras relâchés,
#        regard un peu levé.
# Mira : décidée — buste en avant, bras serrés et coudes pliés, genoux plus
#        fléchis, pieds qui rasent le sol.
STYLES = {
	"kael": {
		"marche": dict(appui=0.58, attaque=16, deroule=24, hauteur_pas=0.10, pic_pas=1.0,
					   retard_pied=1.0, accroupi=0.035, rebond=0.020, ecart_pieds=0.85,
					   lacet_bassin=6, roulis_bassin=4, penche_bassin=2, balance_x=0.020,
					   contre_buste=1.6, penche=2, bras=24, bras_milieu=2, coude=12,
					   coude_plus=16, ecart_bras=6, retard_bras=0.04, regard=-5, hochement=1.5),
		"course": dict(appui=0.30, attaque=6, deroule=30, hauteur_pas=0.30, pic_pas=0.65,
					   retard_pied=1.25, accroupi=0.085, rebond=0.040, ecart_pieds=0.75,
					   lacet_bassin=9, roulis_bassin=3, penche_bassin=6, balance_x=0.010,
					   contre_buste=1.6, penche=11, bras=42, bras_milieu=6, coude=72,
					   coude_plus=18, ecart_bras=10, retard_bras=0.03, regard=-2, hochement=2.5),
	},
	"mira": {
		"marche": dict(appui=0.60, attaque=12, deroule=20, hauteur_pas=0.075, pic_pas=1.0,
					   retard_pied=1.0, accroupi=0.050, rebond=0.010, ecart_pieds=1.0,
					   lacet_bassin=7, roulis_bassin=3, penche_bassin=4, balance_x=0.016,
					   contre_buste=1.4, penche=6, bras=20, bras_milieu=6, coude=26,
					   coude_plus=18, ecart_bras=9, retard_bras=0.02, regard=4, hochement=1.0),
		"course": dict(appui=0.32, attaque=4, deroule=26, hauteur_pas=0.24, pic_pas=0.7,
					   retard_pied=1.2, accroupi=0.10, rebond=0.030, ecart_pieds=0.9,
					   lacet_bassin=10, roulis_bassin=3, penche_bassin=8, balance_x=0.008,
					   contre_buste=1.5, penche=15, bras=36, bras_milieu=8, coude=88,
					   coude_plus=14, ecart_bras=12, retard_bras=0.02, regard=6, hochement=2.0),
	},
}


# ── Idle : respiration, poids qui se déplace, regard ─────────────────────────
IDLES = {
	# Kael rêveur : il se balance doucement d'un pied sur l'autre et lève les
	# yeux, comme s'il écoutait les feuilles.
	"kael": dict(duree=3.0, balance_x=0.016, souffle=1.3, regard_lacet=10, regard=-7,
				 regard_roulis=4, ecart_pieds=1.0, bras_ecart=5, coude=10, penche=0,
				 accroupi=0.012),
	# Mira campée : pieds écartés, peu de balancement, regard qui balaie
	# l'horizon devant elle.
	"mira": dict(duree=2.5, balance_x=0.006, souffle=1.0, regard_lacet=14, regard=2,
				 regard_roulis=0, ecart_pieds=1.45, bras_ecart=9, coude=20, penche=2,
				 accroupi=0.022),
	# PNJ : respiration lente, regard qui tourne doucement.
	"pnj": dict(duree=4.0, balance_x=0.008, souffle=1.2, regard_lacet=16, regard=1,
				regard_roulis=2, ecart_pieds=1.0, bras_ecart=4, coude=10, penche=0,
				accroupi=0.010),
}


def pose_idle(rep, st, t):
	"""Toutes les courbes sont des sinus dont la période divise la durée :
	la boucle retombe exactement sur sa première image."""
	pose = Pose()
	tour = 2.0 * math.pi * t / st["duree"]
	souffle = math.sin(tour * 2.0)                   # deux respirations par boucle
	balance = math.sin(tour)                         # une bascule de poids
	pose.monde["bassin"] = _ry(R(1.5) * balance * st["balance_x"] / 0.016)
	pose.decalage_bassin = Vector((st["balance_x"] * balance, 0.0,
								   -st["accroupi"] + 0.004 * souffle))
	pose.monde["colonne"] = pose.monde["bassin"] @ _ry(-R(2.0) * balance * st["balance_x"] / 0.016) \
		@ _rx(R(st["penche"]) - R(st["souffle"]) * souffle)
	for cote in ("g", "d"):
		hanche, _ = rep["cuisse_" + cote]
		_, cheville = rep["tibia_" + cote]
		pied = Vector((hanche.x * st["ecart_pieds"], cheville.y, cheville.z))
		_jambe(pose, rep, cote, pied, 0.0)
		_bras(pose, cote, R(1.5) * math.sin(tour + (0.0 if cote == "g" else 1.0)),
			  R(st["coude"]) + R(3.0) * souffle,
			  ecart=R(st["bras_ecart"]) + R(1.2) * souffle)
	# Regard : un lent aller-retour (une période), plus une petite hésitation.
	lacet = R(st["regard_lacet"]) * (0.8 * math.sin(tour) + 0.2 * math.sin(tour * 3.0))
	_tete(pose, lacet, R(st["regard"]) + R(2.0) * math.sin(tour * 2.0 + 0.7),
		  R(st["regard_roulis"]) * math.sin(tour + 1.2))
	return pose


# ── Gestes courts : quelques poses clés, enchaînées en douceur ───────────────
# Chaque clé : (instant en s, {réglage: valeur en degrés}). Les réglages absents
# valent 0. bg/bd = balance du bras gauche/droit, cg/cd = coude, eg/ed = écart,
# pc = buste penché, lc = buste tourné, rt = tête baissée, lt = tête tournée.
GESTES = {
	"kael": {
		# Il tend la main vers ce qu'il touche, et le regarde.
		"interagir": [(0.0, {}), (0.22, dict(bd=58, cd=14, ed=2, pc=7, rt=10)),
					  (0.38, dict(bd=60, cd=10, ed=2, pc=7, rt=10)), (0.6, {})],
		# Brassards de Sève : les deux bras se lèvent, paumes vers la terre.
		"skill1": [(0.0, {}), (0.28, dict(bg=78, bd=78, cg=8, cd=8, eg=12, ed=12, pc=-4, rt=-6)),
				   (0.62, dict(bg=84, bd=84, cg=6, cd=6, eg=14, ed=14, pc=-5, rt=-8)), (0.9, {})],
		# Corne d'Appel : la main gauche monte à la bouche, la tête se lève.
		"skill2": [(0.0, {}), (0.3, dict(bg=55, cg=120, eg=-28, bd=6, pc=-6, rt=-14, lt=6)),
				   (0.75, dict(bg=58, cg=124, eg=-30, bd=8, pc=-7, rt=-16, lt=6)), (1.0, {})],
	},
	"mira": {
		"interagir": [(0.0, {}), (0.2, dict(bd=55, cd=18, ed=4, pc=9, rt=12)),
					  (0.36, dict(bd=58, cd=12, ed=4, pc=9, rt=12)), (0.6, {})],
		# Grappin : armer le bras, puis le lancer droit devant.
		"skill1": [(0.0, {}), (0.12, dict(bg=-18, cg=70, eg=8, lc=-12, pc=4)),
				   (0.26, dict(bg=88, cg=0, eg=4, lc=14, pc=8, rt=-4)),
				   (0.45, dict(bg=86, cg=2, eg=4, lc=12, pc=8, rt=-4)), (0.7, {})],
		# Lanterne : la main droite vient la toucher, à la hanche, et elle la regarde.
		"skill2": [(0.0, {}), (0.25, dict(bd=16, cd=30, ed=-5, pc=6, rt=20, lt=-14)),
				   (0.55, dict(bd=16, cd=32, ed=-6, pc=6, rt=22, lt=-14)), (0.8, {})],
	},
}


def pose_geste(rep, cles, t, idle_st):
	# Trouve les deux clés qui encadrent t et interpole en douceur.
	for (t0, v0), (t1, v1) in zip(cles, cles[1:]):
		if t <= t1:
			break
	k = _lisse((t - t0) / max(t1 - t0, 1e-6))
	val = lambda nom: v0.get(nom, 0.0) + (v1.get(nom, 0.0) - v0.get(nom, 0.0)) * k
	pose = Pose()
	pose.decalage_bassin = Vector((0, 0, -idle_st["accroupi"]))
	pose.monde["colonne"] = _rz(R(val("lc"))) @ _rx(R(val("pc")))
	for cote in ("g", "d"):
		hanche, _ = rep["cuisse_" + cote]
		_, cheville = rep["tibia_" + cote]
		_jambe(pose, rep, cote, Vector((hanche.x * idle_st["ecart_pieds"], cheville.y, cheville.z)), 0.0)
	_bras(pose, "g", R(val("bg")), R(idle_st["coude"] + val("cg")), ecart=R(idle_st["bras_ecart"] + val("eg")))
	_bras(pose, "d", R(val("bd")), R(idle_st["coude"] + val("cd")), ecart=R(idle_st["bras_ecart"] + val("ed")))
	_tete(pose, R(val("lt")), R(idle_st["regard"] + val("rt")))
	return pose


# ──────────────────────────────────────────────────────────────────────────────
# 4. ENREGISTRER UNE ACTION
# ──────────────────────────────────────────────────────────────────────────────


def enregistrer(arm, nom, duree, fabrique_pose):
	"""Crée l'action `nom` : une clé par image, de 0 à duree * IPS inclus.

	Pour une boucle, la dernière image est identique à la première (toutes les
	courbes sont périodiques) : Godot relie les deux sans couture.
	"""
	# Blender compte en images, Godot en secondes : la conversion se fait avec
	# la cadence de la scène (24 i/s par défaut). On la fixe à IPS, sinon un
	# cycle de 31 images durerait 1,25 s au lieu de 1 s dans Godot.
	bpy.context.scene.render.fps = IPS
	bpy.context.scene.render.fps_base = 1.0
	arm.animation_data_create()
	action = bpy.data.actions.new(nom)
	action.use_fake_user = True
	arm.animation_data.action = action
	images = round(duree * IPS)
	precedent = {}
	for image in range(images + 1):
		_cles(arm, fabrique_pose(image / IPS), image, precedent)
	# Chaque action est rangée dans sa propre piste NLA : c'est ce qui permet
	# à l'export glTF de les sortir TOUTES comme animations séparées.
	piste = arm.animation_data.nla_tracks.new()
	piste.name = nom
	piste.strips.new(nom, 0, action)
	piste.mute = True
	arm.animation_data.action = None
	print(f"    animation {nom} : {duree:.2f} s, {images + 1} images")


def remettre_au_repos(arm):
	for pb in arm.pose.bones:
		pb.rotation_quaternion = Quaternion()
		pb.location = Vector()


def exporter_anime(nom_fichier, arm, maillage):
	dossier = os.path.join(DOSSIER_ASSETS, SOUS_DOSSIER)
	os.makedirs(dossier, exist_ok=True)
	chemin = os.path.join(dossier, nom_fichier)
	maillage.name = os.path.splitext(nom_fichier)[0]
	remettre_au_repos(arm)
	bpy.ops.object.select_all(action="DESELECT")
	arm.select_set(True)
	maillage.select_set(True)
	bpy.context.view_layer.objects.active = arm
	bpy.ops.export_scene.gltf(
		filepath=chemin,
		use_selection=True,
		export_format="GLB",
		export_apply=False,              # ne surtout pas « appliquer » le squelette
		export_skins=True,
		export_animations=True,
		export_animation_mode="ACTIONS",  # une animation glTF par action
		export_force_sampling=True,
		export_optimize_animation_size=True,
		export_anim_slide_to_zero=True,
	)
	print(f"OK  {SOUS_DOSSIER}/{nom_fichier}  ({len(maillage.data.polygons)} faces, "
		  f"{len(arm.data.bones)} os)")


# ──────────────────────────────────────────────────────────────────────────────
# 5. LES PERSONNAGES
# ──────────────────────────────────────────────────────────────────────────────


def animer_heros(nom, carrure):
	"""À appeler juste après gp.kael() / gp.mira() : la scène contient les pièces."""
	rep = reperes(carrure)
	arm = creer_armature(rep)
	maillage = rattacher(arm)
	idle_st = IDLES[nom]
	enregistrer(arm, "idle", idle_st["duree"], lambda t: pose_idle(rep, idle_st, t))
	for allure, foulee in (("marche", FOULEE_MARCHE), ("course", FOULEE_COURSE)):
		st = STYLES[nom][allure]
		enregistrer(arm, allure, DUREE_CYCLE,
					lambda t, st=st, foulee=foulee: pose_locomotion(rep, st, foulee, t / DUREE_CYCLE))
	for geste, cles in GESTES[nom].items():
		enregistrer(arm, geste, cles[-1][0], lambda t, cles=cles: pose_geste(rep, cles, t, idle_st))
	return arm, maillage


def animer_pnj(carrure, inclinaison=None):
	"""Squelette + idle pour un PNJ. `inclinaison` = (angle, pivot_z) de la voûte
	de l'ancien, pour que les os suivent le dos courbé du modèle."""
	rep = reperes(carrure)
	if inclinaison is not None:
		pencher_reperes(rep, *inclinaison)
	arm = creer_armature(rep)
	maillage = rattacher(arm)
	idle_st = IDLES["pnj"]
	enregistrer(arm, "idle", idle_st["duree"], lambda t: pose_idle(rep, idle_st, t))
	return arm, maillage


def preparer_la_scene():
	"""Scène vide : objets, maillages, mais aussi squelettes et actions du
	modèle précédent (sinon l'export glTF les embarquerait aussi)."""
	vider_la_scene()
	for bloc in list(bpy.data.armatures):
		bpy.data.armatures.remove(bloc)
	for bloc in list(bpy.data.actions):
		bpy.data.actions.remove(bloc)


def generer_heros():
	for nom_fichier, graine, fabrique, nom, carrure in [
		("kael.glb", 11, gp.kael, "kael", 1.0),
		("mira.glb", 22, gp.mira, "mira", 1.2),
	]:
		preparer_la_scene()
		random.seed(graine)
		gp.TAILLE = 1.80
		fabrique()
		arm, maillage = animer_heros(nom, carrure)
		exporter_anime(nom_fichier, arm, maillage)


if __name__ == "__main__":
	generer_heros()
