# scripts/ui/textes_narration.gd
# Tous les textes de narration hors dialogues de PNJ : intro, fin de zone, crédits.
# Un seul fichier pour que le scénariste puisse tout relire et retoucher sans
# toucher au code qui les affiche.
#
# Chaque entrée est une liste de lignes, affichées l'une après l'autre en fondu,
# sur écran noir. Une ligne = une respiration : courte, jamais plus de ~90 signes.
# Les guillemets français « » évitent d'avoir à échapper des " dans le code.

class_name TextesNarration
extends RefCounted

# Acte 0 — la « cinématique muette » du lore, affichée au lancement de la partie,
# avant de donner la main. On pose le malaise. On n'explique rien.
const INTRO: Array[String] = [
	"Sylvara dort au creux de l'Aelith, comme une graine dans sa coque.",
	"Deux hivers ont passé depuis que leur père s'est éteint.",
	"Ce matin, le lit de leur mère est vide. Les draps sont froids.",
	"Sur l'oreiller, une seule fleur. Ni Kael ni Mira n'en connaissent le nom.",
	"Kael la trouve le premier. Mira arrive. Aucun des deux ne parle.",
	"Tout là-haut, dans l'écorce, l'Aelith craque doucement — comme s'il savait.",
]

# Fin de zone — après le choix du grimoire. Aucune des deux n'est la « bonne » :
# le secret rapproche les jumeaux mais les isole ; le partage les délivre
# mais les expose.
const FIN_SECRET: Array[String] = [
	"Le grimoire dort au fond du sac de Mira, roulé dans la vieille cape de Kael.",
	"Ils n'en parlent à personne. Ce premier soir, pas même entre eux.",
	"Un secret de plus dans la famille. Celui-là, au moins, ils le portent à deux.",
	"Et quand le village les salue, ils sourient de la même façon. Un peu trop bien.",
]

const FIN_PARTAGE: Array[String] = [
	"Ce soir-là, sur la place, Kael lit le grimoire à voix haute. Mira tient la lanterne.",
	"Personne ne parle. Puis une voix : « On savait. On attendait que vous sachiez. »",
	"Pour la première fois, ils ne sont plus seuls à porter le nom de leur mère.",
	"Mais un nom qui passe de bouche en bouche finit toujours par franchir l'écorce.",
]

# Seulement si les jumeaux ont trouvé la fleur du bief (GameManager.fleur_trouvee),
# entre la fin du choix et la fin commune. La fleur qui ne fane pas : Kael y lit
# un signe que leur mère est vivante ; Mira ne le dit pas, mais elle y croit.
const FIN_FLEUR: Array[String] = [
	"Au bord du bief, la fleur sans nom ne s'est pas fanée.",
	"Kael dit que c'est un signe. Mira hausse les épaules — mais c'est elle qui y retourne.",
]

# Dernières lignes, communes aux deux fins, avant les crédits.
const FIN_COMMUNE: Array[String] = [
	"Au matin, ils passent la porte du nord, côte à côte.",
	"Derrière eux, l'Aelith referme son ombre sur Sylvara.",
	"Devant eux, la lisière s'efface dans la brume. Et quelque part, au bout, leur mère.",
]

# Crédits — une entrée par ligne, "" = ligne vide.
const CREDITS: Array[String] = [
	"GWANUR",
	"Le Village des Lisières",
	"",
	"Conception, développement",
	"[NOM DU DÉVELOPPEUR]",
	"",
	"Développé avec l'aide de Claude (Anthropic)",
	"",
	"Réalisé avec",
	"Godot Engine",
	"Blender",
	"",
	"À tous ceux qui jouent à deux,",
	"et à ceux qui tiennent la porte pour l'autre.",
	"",
	"Merci d'avoir joué.",
]
