# tools/gen_audio.py
# Génère TOUT l'audio de Gwanur par synthèse : musiques, ambiances, bruitages.
# Aucun son n'est téléchargé : tout sort de ce fichier, versionné et regénérable,
# exactement comme les modèles 3D sortent de gen_maison.py ou gen_arbres.py.
#
# Lancer (le Python de Blender embarque numpy ; bpy n'est PAS utilisé) :
#   "/c/Program Files/Blender Foundation/Blender 5.1/blender.exe" --background --python tools/gen_audio.py
# Puis réimporter dans Godot :
#   godot --headless --path . --import
#
# Sortie : WAV 16 bits mono
#   assets/audio/musique/   theme_zone1, theme_menu, fin          (32 kHz)
#   assets/audio/ambiance/  ambiance_village, ruisseau            (32 kHz)
#   assets/audio/sfx/       tous les bruitages                    (44,1 kHz)
#
# PRINCIPES
#   - Pas de sinus nus : chaque instrument a des partiels, une enveloppe, un
#     léger désaccord (chorus) et passe dans une réverbération par convolution.
#   - Boucles sans couture : la fin d'un morceau bouclé (queues de notes et de
#     réverbe comprises) est repliée sur son début. La boucle est donc circulaire
#     à l'échantillon près. Les bruits d'ambiance sont fabriqués directement dans
#     le domaine fréquentiel, ce qui les rend périodiques par construction.
#   - Crête normalisée à -1 dBFS (jamais d'écrêtage), fondus de 5 ms aux bords
#     des sons non bouclés (jamais de clic).
#   - Le hasard est figé (graine fixe) : relancer le script donne les mêmes fichiers.

import os
import sys
import wave

import numpy as np

# ──────────────────────────────────────────────────────────────────────────────
# CHEMINS
# ──────────────────────────────────────────────────────────────────────────────

try:
	RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
except NameError:
	RACINE = os.getcwd()

DOSSIER_MUSIQUE  = os.path.join(RACINE, "assets", "audio", "musique")
DOSSIER_AMBIANCE = os.path.join(RACINE, "assets", "audio", "ambiance")
DOSSIER_SFX      = os.path.join(RACINE, "assets", "audio", "sfx")

SR_MUSIQUE = 32000   # musique et ambiances : mono 32 kHz (taille raisonnable)
SR_SFX     = 44100   # bruitages : mono 44,1 kHz

rng = np.random.default_rng(20261030)

# ──────────────────────────────────────────────────────────────────────────────
# OUTILS DE BASE
# ──────────────────────────────────────────────────────────────────────────────

def mtof(m):
	"""Numéro MIDI → fréquence en Hz (69 = La 440)."""
	return 440.0 * 2.0 ** ((m - 69) / 12.0)


def ecrire_wav(chemin, x, sr):
	os.makedirs(os.path.dirname(chemin), exist_ok=True)
	donnees = np.clip(np.round(x * 32767.0), -32768, 32767).astype("<i2")
	with wave.open(chemin, "wb") as f:
		f.setnchannels(1)
		f.setsampwidth(2)
		f.setframerate(sr)
		f.writeframes(donnees.tobytes())


def normaliser(x, crete_db=-1.0):
	crete = np.max(np.abs(x))
	if crete < 1e-9:
		return x
	return x * (10.0 ** (crete_db / 20.0) / crete)


def fondus(x, sr, ms_entree=5.0, ms_sortie=5.0):
	"""Fondus en cosinus aux deux bords : supprime les clics."""
	x = x.copy()
	n1 = max(1, int(sr * ms_entree / 1000.0))
	n2 = max(1, int(sr * ms_sortie / 1000.0))
	x[:n1] *= 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, n1))
	x[-n2:] *= 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, n2))
	return x


def lissage(x, n):
	"""Moyenne glissante (n échantillons)."""
	if n <= 1:
		return x
	k = np.ones(n) / n
	return np.convolve(x, k, mode="same")


def gain_bande(freqs, f_bas=None, f_haut=None, douceur=0.35):
	"""Gain d'un passe-bande à flancs doux (en échelle log de fréquence)."""
	g = np.ones_like(freqs)
	lf = np.log2(np.maximum(freqs, 1e-3))
	if f_bas is not None:
		u = np.clip((lf - (np.log2(f_bas) - douceur)) / (2 * douceur), 0, 1)
		g *= np.sin(u * np.pi / 2) ** 2
	if f_haut is not None:
		u = np.clip(((np.log2(f_haut) + douceur) - lf) / (2 * douceur), 0, 1)
		g *= np.sin(u * np.pi / 2) ** 2
	return g


def filtre(x, sr, f_bas=None, f_haut=None, douceur=0.35, circulaire=False):
	"""Filtre passe-bande dans le domaine fréquentiel.
	circulaire=True : le signal est traité comme périodique (boucles)."""
	if circulaire:
		X = np.fft.rfft(x)
		f = np.fft.rfftfreq(len(x), 1.0 / sr)
		return np.fft.irfft(X * gain_bande(f, f_bas, f_haut, douceur), len(x))
	pad = 4096
	xp = np.concatenate([np.zeros(pad), x, np.zeros(pad)])
	X = np.fft.rfft(xp)
	f = np.fft.rfftfreq(len(xp), 1.0 / sr)
	y = np.fft.irfft(X * gain_bande(f, f_bas, f_haut, douceur), len(xp))
	return y[pad:pad + len(x)]


def bruit_periodique(n, sr, f_bas=None, f_haut=None, pente=0.0, douceur=0.35):
	"""Bruit coloré PARFAITEMENT périodique sur n échantillons.
	pente = exposant du spectre en amplitude (0 blanc, -0.5 rose, -1 brun)."""
	f = np.fft.rfftfreq(n, 1.0 / sr)
	mag = np.where(f > 0, np.maximum(f, 1.0) ** pente, 0.0)
	mag *= gain_bande(f, f_bas, f_haut, douceur)
	phase = rng.uniform(0, 2 * np.pi, len(f))
	y = np.fft.irfft(mag * np.exp(1j * phase), n)
	return y / (np.std(y) + 1e-12)


def enveloppe_lente_periodique(n, sr, f_max, f_min=None):
	"""Courbe lente et douce entre 0 et 1, périodique sur n échantillons
	(sert aux rafales de vent, au murmure du ruisseau…)."""
	b = bruit_periodique(n, sr, f_min, f_max, pente=-1.0, douceur=0.2)
	b = (b - b.min()) / (b.max() - b.min() + 1e-12)
	return b


def convoluer(x, h):
	n = len(x) + len(h) - 1
	N = 1 << (n - 1).bit_length()
	y = np.fft.irfft(np.fft.rfft(x, N) * np.fft.rfft(h, N), N)
	return y[:n]


_cache_ri = {}

def reponse_impulsionnelle(sr, rt60, predelai=0.018):
	"""Salle synthétique : bruit à décroissance exponentielle, les aigus
	meurent plus vite que les graves (comme dans une vraie pièce boisée),
	plus quelques premières réflexions."""
	cle = (sr, rt60, predelai)
	if cle in _cache_ri:
		return _cache_ri[cle]
	n = int(rt60 * 1.15 * sr)
	t = np.arange(n) / sr
	b = rng.standard_normal(n)
	grave = filtre(b, sr, None, 700)
	medium = filtre(b, sr, 700, 3500)
	aigu = filtre(b, sr, 3500, None)
	ri = (grave * np.exp(-6.9 * t / (rt60 * 1.15))
		  + medium * np.exp(-6.9 * t / rt60)
		  + 0.7 * aigu * np.exp(-6.9 * t / (rt60 * 0.45)))
	# Montée diffuse (pas de pic sec au début de la queue)
	nm = int(0.012 * sr)
	ri[:nm] *= np.linspace(0, 1, nm) ** 2
	# Premières réflexions
	for d, a in [(0.011, 0.5), (0.017, -0.4), (0.023, 0.35), (0.031, -0.3), (0.043, 0.25)]:
		ri[int(d * sr)] += a * 3.0
	ri = np.concatenate([np.zeros(int(predelai * sr)), ri])
	ri /= np.sqrt(np.sum(ri ** 2))
	_cache_ri[cle] = ri
	return ri


def reverb(x, sr, rt60=2.2, mix=0.3, predelai=0.018):
	"""Réverbe par convolution. Retourne un signal PLUS LONG (avec la queue)."""
	ri = reponse_impulsionnelle(sr, rt60, predelai)
	mouille = convoluer(x, ri)
	sec = np.concatenate([x, np.zeros(len(mouille) - len(x))])
	return sec * (1.0 - mix * 0.5) + mouille * mix


def replier_boucle(x, n):
	"""Replie tout ce qui dépasse n sur le début : boucle circulaire."""
	y = x[:n].copy()
	reste = x[n:]
	while len(reste) > 0:
		k = min(n, len(reste))
		y[:k] += reste[:k]
		reste = reste[k:]
	return y


def svf_passe_bande(x, sr, fc, q):
	"""Filtre d'état variable (Chamberlin) à fréquence variable dans le temps.
	Boucle Python : réservé aux bruitages courts."""
	n = len(x)
	fc = np.broadcast_to(np.asarray(fc, dtype=float), (n,))
	coef = 2.0 * np.sin(np.pi * np.minimum(fc, sr / 7.0) / sr)
	amort = 1.0 / q
	bas = 0.0
	bande = 0.0
	y = np.empty(n)
	for i in range(n):
		haut = x[i] - bas - amort * bande
		bande += coef[i] * haut
		bas += coef[i] * bande
		y[i] = bande
	return y


class Piste:
	"""Un tampon dans lequel on dépose des notes à un instant donné."""

	def __init__(self, duree, sr):
		self.sr = sr
		self.buf = np.zeros(int(duree * sr))

	def ajouter(self, t, sig, gain=1.0):
		i = int(round(max(t, 0.0) * self.sr))
		if i >= len(self.buf):
			return
		j = min(len(self.buf), i + len(sig))
		self.buf[i:j] += sig[:j - i] * gain


def humain(ms=8.0):
	"""Petit décalage temporel aléatoire : le jeu n'est pas mécanique."""
	return rng.normal(0.0, ms / 1000.0)

# ──────────────────────────────────────────────────────────────────────────────
# INSTRUMENTS
# ──────────────────────────────────────────────────────────────────────────────

def piano(f, dur, vel, sr, rel=0.45):
	"""Piano doux : partiels légèrement inharmoniques (cordes raides), deux
	cordes un peu désaccordées par note, aigus qui s'éteignent plus vite,
	double décroissance (attaque puis « son rémanent »), étouffoir au relâché."""
	n = int((dur + rel) * sr)
	t = np.arange(n) / sr
	out = np.zeros(n)
	B = 0.00035
	tau0 = float(np.clip(3.4 * (220.0 / f) ** 0.6, 0.5, 7.0))
	brillance = 0.45 + 0.35 * vel
	for k in range(1, 13):
		fk = k * f * np.sqrt(1.0 + B * k * k)
		if fk > sr * 0.42:
			break
		a = (1.0 / k ** 1.3) * brillance ** (k - 1)
		tau = tau0 / (1.0 + 0.55 * (k - 1))
		decr = 0.62 * np.exp(-t / tau) + 0.38 * np.exp(-t / (tau * 3.2))
		for cents in (-0.7, 0.8):
			r = 2.0 ** (cents / 1200.0)
			out += 0.5 * a * np.sin(2 * np.pi * fk * r * t + rng.uniform(0, 6.283)) * decr
	# Marteau feutré : un souffle très court
	nm = min(n, int(0.02 * sr))
	marteau = filtre(rng.standard_normal(nm), sr, 200, 2500) * np.exp(-np.arange(nm) / (0.004 * sr))
	out[:nm] += 0.025 * marteau
	# Attaque (4 ms) et étouffoir
	na = int(0.004 * sr)
	out[:na] *= np.linspace(0, 1, na)
	apres = t > dur
	out[apres] *= np.exp(-(t[apres] - dur) / (rel / 4.0))
	return fondus(out, sr, 0.5, 8.0) * vel


def harpe(f, dur, vel, sr, rel=0.6):
	"""Harpe : corde pincée, harmoniques qui retombent vite, résonance longue."""
	n = int((dur + rel) * sr)
	t = np.arange(n) / sr
	out = np.zeros(n)
	tau0 = float(np.clip(2.6 * (220.0 / f) ** 0.5, 0.5, 4.5))
	for k in range(1, 11):
		fk = k * f * np.sqrt(1.0 + 0.0001 * k * k)
		if fk > sr * 0.42:
			break
		a = 1.0 / k ** 1.8
		tau = tau0 / (1.0 + 0.9 * (k - 1))
		for cents in (-1.0, 1.1):
			r = 2.0 ** (cents / 1200.0)
			out += 0.5 * a * np.sin(2 * np.pi * fk * r * t + rng.uniform(0, 6.283)) * np.exp(-t / tau)
	nm = min(n, int(0.01 * sr))
	out[:nm] += 0.03 * filtre(rng.standard_normal(nm), sr, 1500, 6000) * np.exp(-np.arange(nm) / (0.002 * sr))
	na = int(0.002 * sr)
	out[:na] *= np.linspace(0, 1, na)
	apres = t > dur
	out[apres] *= np.exp(-(t[apres] - dur) / (rel / 4.0))
	return fondus(out, sr, 0.3, 8.0) * vel


def flute(f, dur, vel, sr, rel=0.2):
	"""Flûte : fondamentale chaude + quelques harmoniques, souffle, petit
	« chiff » d'attaque, vibrato qui n'arrive qu'après la tenue de la note."""
	n = int((dur + rel) * sr)
	t = np.arange(n) / sr
	prof_vib = 0.0045 * np.clip((t - 0.28) / 0.45, 0, 1)
	f_inst = f * (1.0 + prof_vib * np.sin(2 * np.pi * 5.1 * t + rng.uniform(0, 6.283)))
	ph = 2 * np.pi * np.cumsum(f_inst) / sr
	sig = (np.sin(ph) + 0.22 * np.sin(2 * ph + 0.3) + 0.07 * np.sin(3 * ph + 1.1)
		   + 0.025 * np.sin(4 * ph + 2.0))
	souffle = filtre(rng.standard_normal(n), sr, f * 0.9, min(f * 5.0, sr * 0.4)) * 0.05
	chiff = filtre(rng.standard_normal(n), sr, 1800, 6000) * np.exp(-t / 0.025) * 0.08
	# Enveloppe : attaque douce, très légère baisse en tenue, relâché
	env = 1.0 - np.exp(-t / 0.035)
	env *= 1.0 - 0.12 * np.clip(t / max(dur, 0.1), 0, 1)
	apres = t > dur
	env[apres] *= np.clip(1.0 - (t[apres] - dur) / rel, 0, 1) ** 1.5
	# Respiration : l'amplitude vit un peu
	env *= 1.0 + 0.03 * np.sin(2 * np.pi * 0.7 * t + rng.uniform(0, 6.283))
	return fondus((sig + souffle) * env + chiff, sr, 1.0, 5.0) * vel


def cordes(f, dur, vel, sr, att=1.0, rel=1.8, voix=(-8.0, -3.0, 3.0, 8.0)):
	"""Nappe de cordes : plusieurs « violons » désaccordés (chorus), timbre
	en dent de scie adoucie, vibrato lent propre à chaque voix."""
	n = int((dur + rel) * sr)
	t = np.arange(n) / sr
	out = np.zeros(n)
	K = int(min(10, (sr * 0.4) // f))
	for cents in voix:
		vib = 1.0 + 0.0012 * np.sin(2 * np.pi * rng.uniform(4.6, 5.6) * t + rng.uniform(0, 6.283))
		ph = 2 * np.pi * np.cumsum(f * 2.0 ** (cents / 1200.0) * vib) / sr
		for k in range(1, K + 1):
			out += (1.0 / k) * np.exp(-(k - 1) / 4.0) * np.sin(k * ph + rng.uniform(0, 6.283))
	out /= len(voix)
	env = np.ones(n)
	na = int(att * sr)
	if na > 0:
		env[:na] = np.sin(np.linspace(0, np.pi / 2, na)) ** 2
	apres = t > dur
	env[apres] *= np.cos(np.clip((t[apres] - dur) / rel, 0, 1) * np.pi / 2) ** 2
	return fondus(out * env, sr, 1.0, 5.0) * vel


def cloche(f, dur, vel, sr, brillance=1.0):
	"""Petite cloche / carillon : partiels inharmoniques, chacun avec son
	battement léger (deux composantes très proches)."""
	n = int(dur * sr)
	t = np.arange(n) / sr
	out = np.zeros(n)
	for ratio, a, d in [(0.5, 0.15, 1.0), (1.0, 1.0, 1.0), (2.0, 0.3, 0.6),
						(2.76, 0.35 * brillance, 0.4), (5.40, 0.12 * brillance, 0.2),
						(8.93, 0.05 * brillance, 0.1)]:
		fk = f * ratio
		if fk > sr * 0.42:
			continue
		for dc in (-0.6, 0.6):
			out += 0.5 * a * np.sin(2 * np.pi * (fk + dc) * t + rng.uniform(0, 6.283)) * np.exp(-t / (dur * 0.3 * d))
	na = int(0.002 * sr)
	out[:na] *= np.linspace(0, 1, na)
	return fondus(out, sr, 0.3, 5.0) * vel


def marimba(f, dur, vel, sr):
	"""Lame de bois frappée (rapports 1 : 4 : 10 typiques du marimba)."""
	n = int(dur * sr)
	t = np.arange(n) / sr
	out = (np.sin(2 * np.pi * f * t) * np.exp(-t / (dur * 0.35))
		   + 0.25 * np.sin(2 * np.pi * f * 3.93 * t) * np.exp(-t / (dur * 0.08))
		   + 0.06 * np.sin(2 * np.pi * f * 9.8 * t) * np.exp(-t / (dur * 0.03)))
	na = int(0.0015 * sr)
	out[:na] *= np.linspace(0, 1, na)
	return fondus(out, sr, 0.2, 5.0) * vel

# ──────────────────────────────────────────────────────────────────────────────
# HARMONIE — Ré majeur teinté de lydien (le Sol# de « Mi/Ré » est la couleur)
# ──────────────────────────────────────────────────────────────────────────────
#   basse  : note grave jouée au début de l'accord
#   arp    : 6 notes pour l'arpège (index 0 = la plus grave)
#   nappe  : 4 notes tenues par les cordes

ACCORDS = {
	"Dmaj7": {"basse": 38, "arp": [50, 57, 61, 64, 66, 69], "nappe": [57, 61, 64, 66]},
	"E/D":   {"basse": 38, "arp": [50, 56, 59, 64, 66, 71], "nappe": [56, 59, 64, 66]},
	"Bm7":   {"basse": 47, "arp": [47, 54, 57, 62, 66, 69], "nappe": [54, 57, 62, 66]},
	"Gmaj7": {"basse": 43, "arp": [43, 50, 54, 59, 62, 66], "nappe": [54, 59, 62, 66]},
	"Em7":   {"basse": 40, "arp": [40, 47, 50, 55, 59, 66], "nappe": [55, 59, 62, 66]},
	"Asus4": {"basse": 45, "arp": [45, 52, 57, 62, 64, 69], "nappe": [57, 62, 64, 69]},
	"A":     {"basse": 45, "arp": [45, 52, 57, 61, 64, 69], "nappe": [57, 61, 64, 69]},
	"A/G":   {"basse": 43, "arp": [43, 52, 57, 61, 64, 69], "nappe": [57, 61, 64, 69]},
	"F#m7":  {"basse": 42, "arp": [42, 49, 52, 57, 61, 64], "nappe": [57, 61, 64, 68]},
}

# Section A : la tonique et sa couleur lydienne (Ré — Mi/Ré), puis la descente.
SECTION_A = [["Dmaj7"], ["E/D"], ["Dmaj7"], ["E/D"], ["Bm7"], ["Gmaj7"], ["Em7"], ["Asus4", "A"]]
# Section B : la progression IV-V-iii-vi chère au cinéma d'animation japonais.
SECTION_B = [["Gmaj7"], ["A/G"], ["F#m7"], ["Bm7"], ["Em7"], ["F#m7"], ["Gmaj7"], ["Asus4", "A"]]

# Mélodies : (mesure, temps, durée en temps, note MIDI)
MELODIE_A = [
	(0, 0, 1.5, 69), (0, 1.5, 0.5, 71), (0, 2, 2, 73),
	(1, 0, 1.5, 71), (1, 1.5, 0.5, 68), (1, 2, 2, 66),
	(2, 0, 1, 64), (2, 1, 1, 66), (2, 2, 1, 69), (2, 3, 1, 73),
	(3, 0, 3, 71), (3, 3, 1, 68),
	(4, 0, 1.5, 69), (4, 1.5, 0.5, 66), (4, 2, 2, 62),
	(5, 0, 1, 66), (5, 1, 1, 67), (5, 2, 2, 71),
	(6, 0, 1.5, 69), (6, 1.5, 0.5, 67), (6, 2, 2, 66),
	(7, 0, 3.5, 64),
]
MELODIE_B = [
	(0, 0, 1, 74), (0, 1, 1, 73), (0, 2, 2, 71),
	(1, 0, 1, 73), (1, 1, 1, 71), (1, 2, 2, 69),
	(2, 0, 2, 69), (2, 2, 1, 73), (2, 3, 1, 76),
	(3, 0, 3, 74), (3, 3, 1, 73),
	(4, 0, 1.5, 71), (4, 1.5, 0.5, 74), (4, 2, 2, 79),
	(5, 0, 1.5, 76), (5, 1.5, 0.5, 74), (5, 2, 2, 73),
	(6, 0, 1, 71), (6, 1, 1, 73), (6, 2, 1, 74), (6, 3, 1, 78),
	(7, 0, 2, 76), (7, 2, 2, 73),
]

MOTIF_PIANO = [1, 2, 3, 4, 5, 4, 3, 2]
MOTIF_HARPE = [1, 3, 2, 4, 3, 5, 4, 2]
MOTIF_MENU  = [2, 4, 3, 5]   # en noires : plus nu


def jouer_accompagnement(p_arp, p_basse, p_nappe, mesures, t0, bpm, sr,
						 instrument=None, motif=MOTIF_PIANO, croches=True,
						 vel_arp=0.25, vel_basse=0.35, vel_nappe=0.15, profil=None):
	"""Dépose arpèges, basse et nappe pour une suite de mesures.
	profil(mesure) → multiplicateur de nuance (crescendo, extinction…)."""
	b = 60.0 / bpm
	pas = b / 2 if croches else b
	notes_nappe = []  # (début, fin, midi) — fusionnées si la note continue
	for m, accords in enumerate(mesures):
		nuance = profil(m) if profil else 1.0
		temps_par_accord = 4.0 / len(accords)
		for j, nom in enumerate(accords):
			acc = ACCORDS[nom]
			ts = t0 + (m * 4 + j * temps_par_accord) * b
			te = ts + temps_par_accord * b
			if p_basse is not None and vel_basse > 0:
				p_basse.ajouter(ts + humain(4), piano(mtof(acc["basse"]), te - ts + 0.2, vel_basse * nuance, sr, rel=0.8))
			if p_arp is not None and vel_arp > 0:
				k = int(round(temps_par_accord * b / pas))
				for s in range(k):
					idx = motif[(j * k + s) % len(motif)]
					tn = ts + s * pas
					accent = 1.0 if s % (4 if croches else 2) == 0 else 0.82
					v = vel_arp * nuance * accent * rng.uniform(0.9, 1.08)
					duree = min(2.5 * b, te - tn) + 0.05
					p_arp.ajouter(tn + humain(), instrument(mtof(acc["arp"][idx]), duree, v, sr), 1.0)
			if p_nappe is not None and vel_nappe > 0:
				for mm in acc["nappe"]:
					# Une note commune avec l'accord précédent est simplement
					# prolongée : les cordes ne réattaquent pas, elles tiennent.
					suite = None
					for nn in notes_nappe:
						if nn[2] == mm and abs(nn[1] - ts) < 1e-6:
							suite = nn
					if suite is not None:
						suite[1] = te
					else:
						notes_nappe.append([ts, te, mm, nuance])
	if p_nappe is not None:
		for debut, fin, mm, nuance in notes_nappe:
			p_nappe.ajouter(debut, cordes(mtof(mm), fin - debut, vel_nappe * nuance, sr, att=0.9, rel=1.6))


def jouer_melodie(piste, notes, t0, bpm, sr, instrument, vel, transpo=0, legato=1.0, profil=None):
	b = 60.0 / bpm
	for (m, tps, dur, mm) in notes:
		nuance = profil(m) if profil else 1.0
		t = t0 + (m * 4 + tps) * b
		# Les notes longues sont un peu plus appuyées : la phrase respire
		v = vel * nuance * (0.92 + 0.05 * min(dur, 3)) * rng.uniform(0.94, 1.04)
		piste.ajouter(t + humain(6), instrument(mtof(mm + transpo), dur * b * legato, v, sr))


def mixer(*pistes_gains):
	n = max(len(p.buf) for p, _ in pistes_gains)
	out = np.zeros(n)
	for p, g in pistes_gains:
		out[:len(p.buf)] += p.buf * g
	return out

# ──────────────────────────────────────────────────────────────────────────────
# MUSIQUES
# ──────────────────────────────────────────────────────────────────────────────

def theme_zone1():
	"""32 mesures à 70 BPM ≈ 110 s. A (piano) → B (flûte) → A' (flûte, harpe) → B' (piano, cordes)."""
	sr = SR_MUSIQUE
	bpm = 70.0
	b = 60.0 / bpm
	mesure = 4 * b
	longueur = 32 * mesure
	queue = 9.0
	pistes = {k: Piste(longueur + queue, sr) for k in ("arp", "basse", "nappe", "melo", "contre")}

	def t_section(i):
		return i * 8 * mesure

	# A — piano seul qui pose le thème, nappe à peine audible
	jouer_accompagnement(pistes["arp"], pistes["basse"], pistes["nappe"], SECTION_A, t_section(0), bpm, sr,
						 instrument=piano, motif=MOTIF_PIANO, vel_arp=0.20, vel_basse=0.30, vel_nappe=0.09)
	jouer_melodie(pistes["melo"], MELODIE_A, t_section(0), bpm, sr, piano, 0.50, transpo=12)
	# B — la flûte prend le relais, la harpe arpège
	jouer_accompagnement(pistes["arp"], pistes["basse"], pistes["nappe"], SECTION_B, t_section(1), bpm, sr,
						 instrument=harpe, motif=MOTIF_HARPE, vel_arp=0.24, vel_basse=0.30, vel_nappe=0.14)
	jouer_melodie(pistes["melo"], MELODIE_B, t_section(1), bpm, sr, flute, 0.36, legato=1.02)
	# A' — la flûte rejoue A, le piano répond en tintements aigus
	jouer_accompagnement(pistes["arp"], pistes["basse"], pistes["nappe"], SECTION_A, t_section(2), bpm, sr,
						 instrument=harpe, motif=MOTIF_HARPE, vel_arp=0.22, vel_basse=0.28, vel_nappe=0.13)
	jouer_melodie(pistes["melo"], MELODIE_A, t_section(2), bpm, sr, flute, 0.36, transpo=12, legato=1.02)
	for m, accords in enumerate(SECTION_A):
		acc = ACCORDS[accords[0]]
		t = t_section(2) + (m * 4 + 2.5) * b
		pistes["contre"].ajouter(t + humain(), piano(mtof(acc["arp"][5] + 12), 1.5 * b, 0.20, sr, rel=0.8))
	# B' — retour du piano, les cordes doublent la mélodie une octave dessous ;
	# la dernière mesure s'efface pour retomber doucement sur le début.
	def profil_fin(m):
		return 0.75 if m == 7 else 1.0
	jouer_accompagnement(pistes["arp"], pistes["basse"], pistes["nappe"], SECTION_B, t_section(3), bpm, sr,
						 instrument=piano, motif=MOTIF_PIANO, vel_arp=0.21, vel_basse=0.30, vel_nappe=0.17,
						 profil=profil_fin)
	jouer_melodie(pistes["melo"], MELODIE_B, t_section(3), bpm, sr, piano, 0.46, profil=profil_fin)
	jouer_melodie(pistes["contre"], MELODIE_B, t_section(3), bpm, sr,
				  lambda f, d, v, s: cordes(f, d, v, s, att=0.25, rel=0.7), 0.10, transpo=-12, profil=profil_fin)

	sec = mixer((pistes["arp"], 1.0), (pistes["basse"], 0.8), (pistes["nappe"], 1.0),
				(pistes["melo"], 1.0), (pistes["contre"], 1.0))
	mouille = reverb(sec, sr, rt60=2.6, mix=0.34)
	n = int(round(longueur * sr))
	boucle = replier_boucle(mouille, n)
	return normaliser(boucle - np.mean(boucle)), sr, True


def theme_menu():
	"""16 mesures à 62 BPM ≈ 62 s. Piano seul, en noires : le motif à nu."""
	sr = SR_MUSIQUE
	bpm = 62.0
	b = 60.0 / bpm
	mesure = 4 * b
	longueur = 16 * mesure
	p_acc = Piste(longueur + 9.0, sr)
	p_melo = Piste(longueur + 9.0, sr)
	jouer_accompagnement(p_acc, p_acc, None, SECTION_A, 0.0, bpm, sr, instrument=piano,
						 motif=MOTIF_MENU, croches=False, vel_arp=0.17, vel_basse=0.26, vel_nappe=0)
	jouer_melodie(p_melo, MELODIE_A, 0.0, bpm, sr, piano, 0.48, transpo=12)
	jouer_accompagnement(p_acc, p_acc, None, SECTION_B, 8 * mesure, bpm, sr, instrument=piano,
						 motif=MOTIF_MENU, croches=False, vel_arp=0.17, vel_basse=0.26, vel_nappe=0,
						 profil=lambda m: 0.8 if m == 7 else 1.0)
	jouer_melodie(p_melo, MELODIE_B, 8 * mesure, bpm, sr, piano, 0.46,
				  profil=lambda m: 0.8 if m == 7 else 1.0)
	sec = mixer((p_acc, 1.0), (p_melo, 1.0))
	mouille = reverb(sec, sr, rt60=2.8, mix=0.36)
	boucle = replier_boucle(mouille, int(round(longueur * sr)))
	return normaliser(boucle - np.mean(boucle)), sr, True


def fin():
	"""Écran de fin et crédits ≈ 48 s, sans boucle. La progression B s'ouvre
	cette fois sur la tonique lydienne et s'y repose longuement."""
	sr = SR_MUSIQUE
	bpm = 66.0
	b = 60.0 / bpm
	mesure = 4 * b
	mesures = SECTION_B + [["Dmaj7"], ["E/D"], ["Dmaj7"], ["Dmaj7"]]
	longueur = len(mesures) * mesure
	queue = 6.0
	p = {k: Piste(longueur + queue + 3, sr) for k in ("arp", "basse", "nappe", "melo", "contre")}

	# Crescendo doux jusqu'à la mesure 8, puis tout se pose
	def profil(m):
		return [0.8, 0.85, 0.9, 0.95, 1.0, 1.05, 1.1, 1.1, 1.0, 0.95, 0.9, 0.85][min(m, 11)]

	jouer_accompagnement(p["arp"], p["basse"], p["nappe"], mesures[:11], 0.0, bpm, sr, instrument=harpe,
						 motif=MOTIF_HARPE, vel_arp=0.24, vel_basse=0.32, vel_nappe=0.22, profil=profil)
	jouer_melodie(p["melo"], MELODIE_B, 0.0, bpm, sr, flute, 0.40, legato=1.02, profil=profil)
	jouer_melodie(p["contre"], MELODIE_B, 0.0, bpm, sr,
				  lambda f, d, v, s: cordes(f, d, v, s, att=0.3, rel=0.8), 0.12, transpo=-12, profil=profil)
	# Phrase de conclusion
	conclusion = [(8, 0, 2, 69), (8, 2, 2, 73), (9, 0, 4, 71), (10, 0, 7, 66)]
	jouer_melodie(p["melo"], conclusion, 0.0, bpm, sr, flute, 0.38)
	jouer_melodie(p["contre"], [(10, 0, 7, 78)], 0.0, bpm, sr, piano, 0.20)
	# Accord final : basse, nappe tenue et harpe égrenée vers l'aigu
	t_fin = 11 * mesure
	acc = ACCORDS["Dmaj7"]
	p["basse"].ajouter(t_fin, piano(mtof(acc["basse"]), 4.5, 0.32, sr, rel=1.5))
	for mm in acc["nappe"] + [50]:
		p["nappe"].ajouter(t_fin, cordes(mtof(mm), 3.5, 0.2, sr, att=0.4, rel=3.0))
	notes_roulees = acc["arp"] + [n + 12 for n in acc["arp"][2:]]
	for i, mm in enumerate(notes_roulees):
		p["arp"].ajouter(t_fin + i * 0.09, harpe(mtof(mm), 4.0, 0.22, sr, rel=1.2))

	sec = mixer((p["arp"], 1.0), (p["basse"], 0.8), (p["nappe"], 1.0), (p["melo"], 1.0), (p["contre"], 1.0))
	mouille = reverb(sec, sr, rt60=3.0, mix=0.38)
	n = int((longueur + queue) * sr)
	sortie = mouille[:n]
	# Extinction finale en douceur
	nf = int(3.0 * sr)
	sortie[-nf:] *= np.cos(np.linspace(0, np.pi / 2, nf)) ** 2
	return fondus(normaliser(sortie - np.mean(sortie)), sr), sr, False

# ──────────────────────────────────────────────────────────────────────────────
# AMBIANCES (bouclées)
# ──────────────────────────────────────────────────────────────────────────────

def chant_oiseau(sr, espece, intensite=1.0):
	"""Une phrase d'oiseau : sifflets modulés en fréquence."""
	morceaux = []
	if espece == 0:
		# « tui-tui-tui » descendant
		f0 = rng.uniform(2600, 3300)
		for i in range(int(rng.integers(2, 5))):
			d = rng.uniform(0.07, 0.11)
			t = np.arange(int(d * sr)) / sr
			f = f0 * (1.0 - 0.08 * i) * (1.15 - 0.3 * t / d)
			ph = 2 * np.pi * np.cumsum(f) / sr
			env = np.sin(np.pi * t / d) ** 2
			morceaux.append((np.sin(ph) + 0.12 * np.sin(2 * ph)) * env)
			morceaux.append(np.zeros(int(rng.uniform(0.05, 0.09) * sr)))
	elif espece == 1:
		# Trille rapide
		f0 = rng.uniform(3500, 4500)
		d = rng.uniform(0.35, 0.6)
		t = np.arange(int(d * sr)) / sr
		f = f0 * (1.0 + 0.06 * np.sin(2 * np.pi * rng.uniform(22, 30) * t))
		ph = 2 * np.pi * np.cumsum(f) / sr
		env = np.sin(np.pi * t / d) ** 1.5 * (0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 13 * t)))
		morceaux.append(np.sin(ph) * env)
	else:
		# Sifflet lent qui monte puis retombe
		d = rng.uniform(0.35, 0.55)
		t = np.arange(int(d * sr)) / sr
		f0 = rng.uniform(1700, 2300)
		f = f0 * (1.0 + 0.35 * np.sin(np.pi * t / d))
		ph = 2 * np.pi * np.cumsum(f) / sr
		env = np.sin(np.pi * t / d) ** 2
		morceaux.append((np.sin(ph) + 0.08 * np.sin(2 * ph)) * env)
	return np.concatenate(morceaux) * intensite


def ambiance_village():
	"""48 s : vent doux dans les feuilles, rafales lentes, oiseaux lointains épars."""
	sr = SR_MUSIQUE
	L = 48.0
	n = int(L * sr)
	rafales = 0.35 + 0.65 * enveloppe_lente_periodique(n, sr, 0.18, 0.02)
	vent = bruit_periodique(n, sr, 70, 900, pente=-0.8) * rafales
	frisson = enveloppe_lente_periodique(n, sr, 9.0, 1.5)
	feuilles = bruit_periodique(n, sr, 1800, 9000, pente=-0.3) * (rafales ** 2) * (0.45 + 0.55 * frisson)
	lit = 0.55 * vent + 0.28 * feuilles

	# Oiseaux lointains, posés tous les 3 à 8 s
	p = Piste(L + 4.0, sr)
	t = rng.uniform(0.5, 2.0)
	while t < L:
		p.ajouter(t, chant_oiseau(sr, int(rng.integers(0, 3)), rng.uniform(0.10, 0.22)))
		t += rng.uniform(3.0, 8.0)
	oiseaux = filtre(p.buf, sr, 1200, 6000)
	oiseaux = reverb(oiseaux, sr, rt60=1.4, mix=0.5, predelai=0.03)
	oiseaux = replier_boucle(oiseaux, n)

	sortie = lit + oiseaux
	return normaliser(sortie - np.mean(sortie)), sr, True


def ruisseau():
	"""20 s : eau qui court sur les pierres — souffle filtré + milliers de bulles."""
	sr = SR_MUSIQUE
	L = 20.0
	n = int(L * sr)
	remous = enveloppe_lente_periodique(n, sr, 18.0, 2.0)
	courant = bruit_periodique(n, sr, 300, 4500, pente=-0.4) * (0.6 + 0.4 * remous)
	glouglou = bruit_periodique(n, sr, 80, 420, pente=-0.6) * (0.5 + 0.5 * enveloppe_lente_periodique(n, sr, 3.0, 0.3))

	# Bulles : de petits sifflets qui montent très vite et s'éteignent
	bulles = np.zeros(n + sr)
	nb = int(26 * L)
	for _ in range(nb):
		f0 = np.exp(rng.uniform(np.log(450), np.log(2300)))
		d = rng.uniform(0.015, 0.06)
		t = np.arange(int(d * sr)) / sr
		f = f0 * (1.0 + rng.uniform(0.3, 1.1) * t / d)
		ph = 2 * np.pi * np.cumsum(f) / sr
		b = np.sin(ph) * np.exp(-t / (d / 3.0)) * rng.uniform(0.05, 0.3)
		b[:8] *= np.linspace(0, 1, 8)
		i = int(rng.integers(0, n))
		bulles[i:i + len(b)] += b
	bulles = replier_boucle(bulles, n)

	sortie = 0.5 * courant + 0.35 * glouglou + 0.9 * bulles
	sortie = filtre(sortie, sr, 60, 7500, circulaire=True)
	return normaliser(sortie - np.mean(sortie)), sr, True

# ──────────────────────────────────────────────────────────────────────────────
# BRUITAGES
# ──────────────────────────────────────────────────────────────────────────────
# Chaque fonction rend un signal brut ; la finition (réverbe, normalisation,
# fondus) est faite par `finir()`.

def finir(x, sr, rt60=0.9, mix=0.2, duree=None):
	if mix > 0:
		x = reverb(x, sr, rt60=rt60, mix=mix, predelai=0.01)
	if duree is not None:
		x = x[:int(duree * sr)]
	# Coupe le silence de fin (au-delà de -70 dB) pour garder des fichiers petits
	seuil = np.max(np.abs(x)) * 10 ** (-70 / 20)
	idx = np.nonzero(np.abs(x) > seuil)[0]
	if len(idx):
		x = x[:idx[-1] + 1]
	x = normaliser(x - np.mean(x))
	return fondus(x, sr)


def bruit(n):
	return rng.standard_normal(n)


def toc_bois(sr, f=500, d=0.06, amp=1.0):
	"""Choc de bois : bruit court filtré + résonance amortie."""
	n = int(d * sr)
	t = np.arange(n) / sr
	choc = filtre(bruit(n), sr, f * 0.6, f * 3.5) * np.exp(-t / (d * 0.18))
	reso = np.sin(2 * np.pi * f * t) * np.exp(-t / (d * 0.3))
	return (0.6 * choc + 0.5 * reso) * amp


def sourd(sr, f0=90, f1=55, d=0.15, amp=1.0):
	"""Coup sourd grave (une masse qui se pose)."""
	n = int(d * sr)
	t = np.arange(n) / sr
	f = f1 + (f0 - f1) * np.exp(-t / (d * 0.25))
	return np.sin(2 * np.pi * np.cumsum(f) / sr) * np.exp(-t / (d * 0.3)) * amp


def tintement_metal(sr, f, d=0.3, amp=1.0):
	"""Métal fin (cuivre) : partiels inharmoniques qui s'éteignent vite."""
	n = int(d * sr)
	t = np.arange(n) / sr
	out = np.zeros(n)
	for r, a, dd in [(1.0, 1.0, 1.0), (2.32, 0.6, 0.6), (4.25, 0.35, 0.35), (6.63, 0.2, 0.2)]:
		if f * r < sr * 0.42:
			out += a * np.sin(2 * np.pi * f * r * t + rng.uniform(0, 6.283)) * np.exp(-t / (d * 0.25 * dd))
	return out * amp


def grincement(sr, d, f_min, f_max, rugosite=0.5, formants=(420, 950, 1700)):
	"""Grincement de bois par « collé-glissé » : un train d'impulsions dont la
	cadence erre lentement, filtré par les résonances d'une planche."""
	n = int(d * sr)
	lent = lissage(rng.standard_normal(n), int(0.12 * sr))
	lent = (lent - lent.min()) / (lent.max() - lent.min() + 1e-9)
	f = f_min + (f_max - f_min) * lent
	ph = np.cumsum(f / sr)
	impulsions = np.zeros(n)
	sauts = np.nonzero(np.diff(np.floor(ph)) > 0)[0]
	impulsions[sauts] = 1.0 + rugosite * rng.standard_normal(len(sauts))
	corps = np.zeros(n)
	for fo in formants:
		corps += svf_passe_bande(impulsions, sr, fo, 9.0)
	# Le bois « accroche » par à-coups
	accroche = lissage((rng.uniform(0, 1, n) < 0.0009).astype(float), int(0.09 * sr))
	accroche = np.clip(lissage(accroche, int(0.03 * sr)) * 60, 0.25, 1.0)
	return corps * accroche


def sfx_corne(sr):
	"""Corne d'Appel : deux notes liées (La → Ré), cuivrée mais boisée,
	qui s'ouvre en brillance quand le souffle monte."""
	d = 2.1
	n = int(d * sr)
	t = np.arange(n) / sr
	# Courbe de hauteur : petite approche par en dessous, puis glissé vers la quarte
	f = np.where(t < 0.62, 220.0, 293.66)
	f = lissage(f, int(0.06 * sr))
	f *= 1.0 - 0.02 * np.exp(-t / 0.05)
	f *= 1.0 + 0.004 * np.clip((t - 0.9) / 0.4, 0, 1) * np.sin(2 * np.pi * 4.8 * t)
	ph = 2 * np.pi * np.cumsum(f) / sr
	env = np.clip(t / 0.08, 0, 1) ** 1.5
	env *= np.where(t < 0.62, 0.75, 1.0)
	env = lissage(env, int(0.05 * sr))
	env *= np.clip((d - t) / 0.55, 0, 1) ** 1.2
	out = np.zeros(n)
	for k in range(1, 15):
		a = np.exp(-(k - 1) / 2.4) * (1.0 + 0.7 * np.exp(-((k * 260 - 900) / 450.0) ** 2))
		# Plus on souffle fort, plus les harmoniques s'ouvrent
		out += a * np.sin(k * ph + rng.uniform(0, 6.283)) * env ** (1.0 + 0.18 * k)
	souffle = filtre(bruit(n), sr, 400, 3000) * env * 0.04
	return finir(out + souffle, sr, rt60=2.6, mix=0.38)


def sfx_lianes(sr):
	"""Brassards de Sève : fibres qui s'étirent, feuilles qui s'ouvrent et une
	petite gamme lydienne scintillante — la magie de la nature."""
	d = 1.8
	n = int(d * sr)
	t = np.arange(n) / sr
	# Étirement : bruit filtré dont la résonance monte
	fc = 280 + 1100 * (t / d) ** 1.3
	etire = svf_passe_bande(bruit(n), sr, fc, 6.0) * np.sin(np.pi * np.clip(t / 1.5, 0, 1)) ** 2
	# Petits craquements de fibres
	fibres = grincement(sr, d, 60, 160, rugosite=0.8, formants=(650, 1300)) * np.clip((t - 0.15) / 0.3, 0, 1) * np.clip((1.4 - t) / 0.3, 0, 1)
	# Feuilles qui se déplient
	feuilles = filtre(bruit(n), sr, 2500, 8000) * (lissage((rng.uniform(0, 1, n) < 0.002).astype(float), int(0.02 * sr)) * 40)
	feuilles *= np.clip((t - 0.5) / 0.4, 0, 1) * np.clip((d - t) / 0.4, 0, 1)
	# Scintillement : Ré Mi Fa# Sol# La
	magie = np.zeros(n)
	for i, mm in enumerate([74, 76, 78, 80, 81]):
		c = cloche(mtof(mm), 1.0, 0.22 * (1.0 - 0.08 * i), sr, brillance=0.6)
		i0 = int((0.25 + 0.17 * i) * sr)
		j = min(n, i0 + len(c))
		magie[i0:j] += c[:j - i0]
	out = 0.5 * etire / (np.max(np.abs(etire)) + 1e-9) + 0.25 * fibres / (np.max(np.abs(fibres)) + 1e-9) \
		  + 0.15 * feuilles + 0.55 * magie
	return finir(out, sr, rt60=1.6, mix=0.3)


def sfx_grappin(sr):
	"""Grappin lancé : sifflement de corde, puis le crochet de cuivre qui accroche."""
	d = 1.0
	n = int(d * sr)
	t = np.arange(n) / sr
	fc = 400 + 2200 * np.clip(t / 0.35, 0, 1) ** 0.7
	env = np.sin(np.pi * np.clip(t / 0.38, 0, 1)) ** 2
	whoosh = svf_passe_bande(bruit(n), sr, fc, 2.5) * env
	whoosh /= np.max(np.abs(whoosh)) + 1e-9
	out = 0.55 * whoosh
	i0 = int(0.37 * sr)
	clink = tintement_metal(sr, 1850, 0.35, 0.6)
	out[i0:i0 + len(clink)] += clink[:n - i0]
	thrum = sourd(sr, 140, 105, 0.35, 0.35)
	out[i0:i0 + len(thrum)] += thrum[:n - i0]
	return finir(out, sr, rt60=0.9, mix=0.22)


def sfx_grappin_retour(sr):
	"""Grappin ramené : corde qui file, petit clic du crochet rangé."""
	d = 0.6
	n = int(d * sr)
	t = np.arange(n) / sr
	fc = 2000 - 1500 * np.clip(t / 0.4, 0, 1)
	env = np.sin(np.pi * np.clip(t / 0.42, 0, 1)) ** 2
	w = svf_passe_bande(bruit(n), sr, fc, 2.5) * env
	w /= np.max(np.abs(w)) + 1e-9
	out = 0.45 * w
	c = tintement_metal(sr, 1250, 0.15, 0.35)
	i0 = int(0.42 * sr)
	out[i0:i0 + len(c)] += c[:n - i0]
	return finir(out, sr, rt60=0.7, mix=0.15)


def sfx_lanterne_on(sr):
	"""Lanterne à Mémoire allumée : souffle chaud, puis une lueur de verre."""
	d = 1.4
	n = int(d * sr)
	t = np.arange(n) / sr
	fwoomp = filtre(bruit(n), sr, 80, 700) * np.clip(t / 0.02, 0, 1) * np.exp(-t / 0.18)
	out = 0.5 * fwoomp / (np.max(np.abs(fwoomp)) + 1e-9)
	lueur = np.zeros(n)
	for mm, dt, v in [(69, 0.05, 0.12), (73, 0.05, 0.1), (76, 0.05, 0.1)]:
		s = cordes(mtof(mm + 12), 0.5, v, sr, att=0.15, rel=0.6, voix=(-5.0, 5.0))
		i0 = int(dt * sr)
		lueur[i0:i0 + len(s)] += s[:n - i0]
	for mm, dt, v in [(81, 0.12, 0.3), (88, 0.24, 0.22)]:
		c = cloche(mtof(mm), 1.1, v, sr)
		i0 = int(dt * sr)
		lueur[i0:i0 + len(c)] += c[:n - i0]
	return finir(out + lueur, sr, rt60=1.5, mix=0.3)


def sfx_lanterne_off(sr):
	"""Lanterne éteinte : la lueur redescend, petite bouffée."""
	d = 1.0
	n = int(d * sr)
	t = np.arange(n) / sr
	bouffee = filtre(bruit(n), sr, 250, 1500) * np.clip(t / 0.015, 0, 1) * np.exp(-t / 0.07)
	out = 0.35 * bouffee / (np.max(np.abs(bouffee)) + 1e-9)
	for mm, dt, v in [(88, 0.0, 0.2), (81, 0.12, 0.22)]:
		c = cloche(mtof(mm), 0.8, v, sr, brillance=0.7)
		i0 = int(dt * sr)
		out[i0:i0 + len(c)] += c[:n - i0]
	return finir(out, sr, rt60=1.2, mix=0.25)


def sfx_poignee(sr):
	"""Poignée tirée : le bois cogne, le loquet claque."""
	n = int(0.5 * sr)
	out = np.zeros(n)
	s = sourd(sr, 95, 60, 0.18, 0.6)
	out[:len(s)] += s
	b = toc_bois(sr, 520, 0.08, 0.7)
	out[:len(b)] += b
	c = tintement_metal(sr, 2400, 0.06, 0.25)
	i0 = int(0.045 * sr)
	out[i0:i0 + len(c)] += c
	return finir(out, sr, rt60=0.8, mix=0.2)


def sfx_porte(sr):
	"""La grande porte grince et monte (1,5 s), puis se cale en haut."""
	d = 2.2
	n = int(d * sr)
	t = np.arange(n) / sr
	g = grincement(sr, 1.6, 150, 320, rugosite=0.5)
	g /= np.max(np.abs(g)) + 1e-9
	out = np.zeros(n)
	out[:len(g)] += 0.55 * g * np.clip(t[:len(g)] / 0.15, 0, 1) * np.clip((1.6 - t[:len(g)]) / 0.2, 0, 1)
	grondement = filtre(bruit(n), sr, 40, 180) * np.clip(t / 0.2, 0, 1) * np.clip((1.55 - t) / 0.2, 0, 1)
	out += 0.35 * grondement / (np.max(np.abs(grondement)) + 1e-9)
	i0 = int(1.5 * sr)
	s = sourd(sr, 85, 50, 0.3, 0.7)
	out[i0:i0 + len(s)] += s[:n - i0]
	b = toc_bois(sr, 300, 0.12, 0.5)
	out[i0:i0 + len(b)] += b[:n - i0]
	return finir(out, sr, rt60=1.8, mix=0.3)


def sfx_grille(sr):
	"""Grille de fer qui monte : cliquetis de chaîne, frottement, clac final."""
	d = 1.4
	n = int(d * sr)
	t = np.arange(n) / sr
	out = np.zeros(n)
	tc = 0.02
	while tc < 0.95:
		c = tintement_metal(sr, rng.uniform(1100, 2900), rng.uniform(0.04, 0.09), rng.uniform(0.12, 0.3))
		i0 = int(tc * sr)
		out[i0:i0 + len(c)] += c[:n - i0]
		tc += rng.uniform(0.025, 0.06)
	frottement = filtre(bruit(n), sr, 120, 500) * np.clip(t / 0.1, 0, 1) * np.clip((1.0 - t) / 0.1, 0, 1)
	out += 0.25 * frottement / (np.max(np.abs(frottement)) + 1e-9)
	i0 = int(1.0 * sr)
	c = tintement_metal(sr, 720, 0.35, 0.6)
	out[i0:i0 + len(c)] += c[:n - i0]
	s = sourd(sr, 110, 70, 0.2, 0.4)
	out[i0:i0 + len(s)] += s[:n - i0]
	return finir(out, sr, rt60=1.4, mix=0.25)


def sfx_oiseau_chant(sr):
	"""L'oiseau blanc répond à la Corne : une phrase claire de 4 notes."""
	morceaux = [np.zeros(int(0.02 * sr))]
	for f0, f1, d in [(3000, 3600, 0.09), (3600, 3100, 0.08), (2800, 2500, 0.12), (3300, 4200, 0.16)]:
		tt = np.arange(int(d * sr)) / sr
		f = np.linspace(f0, f1, len(tt)) * (1.0 + 0.03 * np.sin(2 * np.pi * 28 * tt))
		ph = 2 * np.pi * np.cumsum(f) / sr
		env = np.sin(np.pi * tt / d) ** 2
		morceaux.append((np.sin(ph) + 0.1 * np.sin(2 * ph)) * env)
		morceaux.append(np.zeros(int(0.05 * sr)))
	out = np.concatenate(morceaux) * 0.6
	return finir(out, sr, rt60=1.3, mix=0.3)


def sfx_oiseau_envol(sr):
	"""Battements d'ailes qui s'éloignent, et un petit cri."""
	d = 1.3
	n = int(d * sr)
	out = np.zeros(n)
	tc = 0.0
	ecart = 0.075
	amp = 1.0
	while tc < 1.1:
		db = 0.06
		nb = int(db * sr)
		tt = np.arange(nb) / sr
		bat = filtre(bruit(nb), sr, 250, 2500 * amp + 500) * np.sin(np.pi * tt / db) ** 3 * amp
		i0 = int(tc * sr)
		out[i0:i0 + nb] += bat[:n - i0]
		tc += ecart
		ecart *= 1.12
		amp *= 0.82
	cri = chant_oiseau(sr, 0, 0.25)
	i0 = int(0.15 * sr)
	out[i0:i0 + len(cri)] += cri[:n - i0]
	return finir(out, sr, rt60=1.2, mix=0.25)


def sfx_roue(sr):
	"""La roue à eau se met à tourner : bois qui grince à chaque rayon,
	godets qui se remplissent, l'eau qui retombe."""
	d = 2.6
	n = int(d * sr)
	t = np.arange(n) / sr
	out = np.zeros(n)
	for i, tc in enumerate([0.0, 0.5, 1.0, 1.5]):
		g = grincement(sr, 0.35, 110, 190, rugosite=0.6, formants=(320, 760, 1400))
		g = g / (np.max(np.abs(g)) + 1e-9) * np.sin(np.pi * np.linspace(0, 1, len(g)))
		i0 = int(tc * sr)
		out[i0:i0 + len(g)] += 0.4 * g[:n - i0]
		b = toc_bois(sr, 260, 0.08, 0.35)
		out[i0:i0 + len(b)] += b[:n - i0]
	eau = filtre(bruit(n), sr, 400, 3500)
	vagues = 0.5 + 0.5 * np.sin(2 * np.pi * 2.0 * t) ** 2
	eau *= vagues * np.clip(t / 0.3, 0, 1) * np.clip((d - t) / 0.6, 0, 1)
	out += 0.3 * eau / (np.max(np.abs(eau)) + 1e-9)
	# Gouttes
	for _ in range(60):
		f0 = rng.uniform(500, 1800)
		dd = rng.uniform(0.02, 0.05)
		tt = np.arange(int(dd * sr)) / sr
		g = np.sin(2 * np.pi * np.cumsum(f0 * (1 + 0.8 * tt / dd)) / sr) * np.exp(-tt / (dd / 3)) * rng.uniform(0.05, 0.2)
		i0 = int(rng.uniform(0.2, d - 0.3) * sr)
		out[i0:i0 + len(g)] += g
	grave = filtre(bruit(n), sr, 40, 160) * np.clip(t / 0.3, 0, 1) * np.clip((d - t) / 0.5, 0, 1)
	out += 0.25 * grave / (np.max(np.abs(grave)) + 1e-9)
	return finir(out, sr, rt60=1.5, mix=0.25)


def sfx_pont(sr):
	"""Le pont glisse et se déploie (1,5 s), puis se pose : deux coups de bois."""
	d = 2.0
	n = int(d * sr)
	t = np.arange(n) / sr
	glisse = svf_passe_bande(bruit(n), sr, 500 + 300 * np.sin(2 * np.pi * 0.7 * t), 3.0)
	acc = 0.6 + 0.4 * lissage(rng.uniform(0, 1, n), int(0.03 * sr))
	glisse *= acc * np.clip(t / 0.15, 0, 1) * np.clip((1.5 - t) / 0.15, 0, 1)
	out = 0.4 * glisse / (np.max(np.abs(glisse)) + 1e-9)
	g = grincement(sr, d, 90, 150, formants=(380, 900))
	out += 0.2 * g / (np.max(np.abs(g)) + 1e-9) * np.clip((1.5 - t) / 0.2, 0, 1)
	for tc, a in [(1.5, 0.8), (1.62, 0.45)]:
		i0 = int(tc * sr)
		s = sourd(sr, 90, 55, 0.25, a)
		out[i0:i0 + len(s)] += s[:n - i0]
		b = toc_bois(sr, 340, 0.1, a * 0.7)
		out[i0:i0 + len(b)] += b[:n - i0]
	return finir(out, sr, rt60=1.6, mix=0.28)


def sfx_resolu(sr):
	"""Puzzle résolu : petit carillon montant La-Ré-Mi-La, sur un souffle de nappe."""
	d = 3.0
	n = int(d * sr)
	out = np.zeros(n)
	for i, mm in enumerate([81, 86, 88, 93]):
		c = cloche(mtof(mm), 2.2, 0.5 - 0.06 * i, sr)
		i0 = int((0.02 + 0.14 * i) * sr)
		out[i0:i0 + len(c)] += c[:n - i0]
	for mm in [62, 69, 73, 76]:
		s = cordes(mtof(mm), 0.9, 0.06, sr, att=0.3, rel=1.2, voix=(-6.0, 6.0))
		out[:len(s)] += s[:n]
	return finir(out, sr, rt60=2.2, mix=0.32)


def sfx_dialogue(sr):
	"""Petit « blip » de dialogue, rond et feutré. La hauteur est variée en jeu."""
	d = 0.1
	n = int(d * sr)
	t = np.arange(n) / sr
	f = 640.0 * (1.0 - 0.1 * t / d)
	ph = 2 * np.pi * np.cumsum(f) / sr
	out = (np.sin(ph) + 0.15 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph)) * np.clip(t / 0.003, 0, 1) * np.exp(-t / 0.025)
	return finir(out, sr, mix=0.0)


def sfx_interaction(sr):
	"""Un objet est à portée : un tintement de verre presque murmuré."""
	n = int(0.5 * sr)
	out = np.zeros(n)
	c = cloche(mtof(88), 0.45, 0.4, sr, brillance=0.5)
	out[:len(c)] += c
	c = cloche(mtof(95), 0.35, 0.18, sr, brillance=0.4)
	i0 = int(0.06 * sr)
	out[i0:i0 + len(c)] += c[:n - i0]
	return finir(out, sr, rt60=0.9, mix=0.2)


def sfx_ui_navigation(sr):
	"""Déplacement dans un menu : petite lame de bois."""
	return finir(marimba(mtof(81), 0.18, 0.6, sr), sr, rt60=0.6, mix=0.12)


def sfx_ui_validation(sr):
	"""Validation : deux notes qui montent (La → Mi)."""
	n = int(0.7 * sr)
	out = np.zeros(n)
	a = marimba(mtof(81), 0.45, 0.55, sr)
	out[:len(a)] += a
	b = marimba(mtof(88), 0.55, 0.6, sr)
	i0 = int(0.075 * sr)
	out[i0:i0 + len(b)] += b[:n - i0]
	return finir(out, sr, rt60=1.0, mix=0.2)


def sfx_choix_final(sr):
	"""Le choix du grimoire : accord de Ré lydien égrené à la harpe, cordes qui gonflent."""
	d = 4.5
	n = int(d * sr)
	out = np.zeros(n)
	for i, mm in enumerate([50, 57, 64, 66, 68, 69, 73, 76]):
		h = harpe(mtof(mm), 3.2, 0.28, sr, rel=1.0)
		i0 = int((0.03 + 0.075 * i) * sr)
		out[i0:i0 + len(h)] += h[:n - i0]
	for mm in [62, 66, 69, 73]:
		s = cordes(mtof(mm), 2.4, 0.16, sr, att=1.0, rel=1.6)
		out[:len(s)] += s[:n]
	c = cloche(mtof(93), 2.5, 0.25, sr)
	i0 = int(0.65 * sr)
	out[i0:i0 + len(c)] += c[:n - i0]
	return finir(out, sr, rt60=2.8, mix=0.38)


def sfx_pas_herbe(sr):
	"""Un pas dans l'herbe : petit poids sourd et froissement de brins."""
	d = 0.22
	n = int(d * sr)
	t = np.arange(n) / sr
	poids = sourd(sr, rng.uniform(75, 95), 55, 0.08, 0.5)
	grains = (rng.uniform(0, 1, n) < 0.08) * rng.standard_normal(n)
	froisse = filtre(grains + 0.3 * bruit(n), sr, rng.uniform(1100, 1500), 6500)
	froisse *= np.clip(t / 0.008, 0, 1) * np.exp(-t / rng.uniform(0.04, 0.07))
	medium = filtre(bruit(n), sr, 300, 1100) * np.clip(t / 0.005, 0, 1) * np.exp(-t / 0.025)
	out = 0.6 * froisse / (np.max(np.abs(froisse)) + 1e-9) + 0.25 * medium / (np.max(np.abs(medium)) + 1e-9)
	out[:len(poids)] += poids
	return finir(out, sr, mix=0.0)

# ──────────────────────────────────────────────────────────────────────────────
# CONTRÔLES (« écoute mentale »)
# ──────────────────────────────────────────────────────────────────────────────

def rapport(nom, x, sr, boucle):
	crete = 20 * np.log10(np.max(np.abs(x)) + 1e-12)
	rms = 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-12)
	ligne = "  %-18s %6.2f s  crête %5.1f dBFS  RMS %5.1f dBFS" % (nom, len(x) / sr, crete, rms)
	if boucle:
		# La couture : l'écart entre le dernier et le premier échantillon doit
		# ressembler à un écart ordinaire entre deux échantillons voisins.
		saut = abs(x[0] - x[-1])
		typique = np.percentile(np.abs(np.diff(x)), 99.9)
		ligne += "  couture %.4f (p99.9 voisins %.4f) %s" % (saut, typique, "OK" if saut <= typique else "A VERIFIER")
	else:
		ligne += "  bords %.4f / %.4f" % (abs(x[0]), abs(x[-1]))
	print(ligne)

# ──────────────────────────────────────────────────────────────────────────────
# PROGRAMME PRINCIPAL
# ──────────────────────────────────────────────────────────────────────────────

def main():
	total = 0
	print("=== Gwanur — génération audio ===")
	print("Musiques :")
	for nom, fn in [("theme_zone1", theme_zone1), ("theme_menu", theme_menu), ("fin", fin)]:
		x, sr, boucle = fn()
		chemin = os.path.join(DOSSIER_MUSIQUE, nom + ".wav")
		ecrire_wav(chemin, x, sr)
		rapport(nom, x, sr, boucle)
		total += os.path.getsize(chemin)
	print("Ambiances :")
	for nom, fn in [("ambiance_village", ambiance_village), ("ruisseau", ruisseau)]:
		x, sr, boucle = fn()
		chemin = os.path.join(DOSSIER_AMBIANCE, nom + ".wav")
		ecrire_wav(chemin, x, sr)
		rapport(nom, x, sr, boucle)
		total += os.path.getsize(chemin)
	print("Bruitages :")
	sfx = [
		("corne", sfx_corne), ("lianes", sfx_lianes),
		("grappin", sfx_grappin), ("grappin_retour", sfx_grappin_retour),
		("lanterne_on", sfx_lanterne_on), ("lanterne_off", sfx_lanterne_off),
		("poignee", sfx_poignee), ("porte", sfx_porte), ("grille", sfx_grille),
		("oiseau_chant", sfx_oiseau_chant), ("oiseau_envol", sfx_oiseau_envol),
		("roue", sfx_roue), ("pont", sfx_pont), ("resolu", sfx_resolu),
		("dialogue", sfx_dialogue), ("interaction", sfx_interaction),
		("ui_navigation", sfx_ui_navigation), ("ui_validation", sfx_ui_validation),
		("choix_final", sfx_choix_final),
		("pas_herbe_1", sfx_pas_herbe), ("pas_herbe_2", sfx_pas_herbe), ("pas_herbe_3", sfx_pas_herbe),
	]
	for nom, fn in sfx:
		x = fn(SR_SFX)
		chemin = os.path.join(DOSSIER_SFX, nom + ".wav")
		ecrire_wav(chemin, x, SR_SFX)
		rapport(nom, x, SR_SFX, False)
		total += os.path.getsize(chemin)
	print("Total : %.2f Mo" % (total / 1024 / 1024))


main()
