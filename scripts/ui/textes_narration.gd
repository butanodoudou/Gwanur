# scripts/ui/textes_narration.gd
# Tous les textes de narration hors dialogues de PNJ : intro, fin de zone, crédits.
# Un seul fichier pour que le scénariste puisse tout relire et retoucher sans
# toucher au code qui les affiche.
#
# Chaque entrée est une liste de lignes, affichées l'une après l'autre.
# (Contenu provisoire — sera réécrit par le scénariste.)

class_name TextesNarration
extends RefCounted

# Acte 0 — affiché en fondu au lancement de la partie, avant de donner la main.
const INTRO: Array[String] = [
	"Sylvara, au creux de l'Aelith.",
	"Deux ans depuis la mort de leur père.",
	"Trois jours depuis le départ de leur mère.",
]

# Fin de zone — après le choix du grimoire.
const FIN_SECRET: Array[String] = [
	"Le grimoire dort au fond du sac de Mira.",
	"Un secret de plus. Mais celui-ci, ils le portent à deux.",
]

const FIN_PARTAGE: Array[String] = [
	"Le soir même, tout Sylvara connaît le nom de la Tisserande.",
	"Les regards ont changé. Pas tous dans le bon sens.",
]

# Dernière ligne, commune aux deux fins, avant les crédits.
const FIN_COMMUNE: Array[String] = [
	"Au nord, la forêt attend.",
]

# Crédits — une entrée par ligne, "" = ligne vide.
const CREDITS: Array[String] = [
	"GWANUR",
	"Le Village des Lisières",
	"",
	"Merci d'avoir joué.",
]
