# scripts/globals/game_manager.gd
# AutoLoad — état global du jeu, accessible depuis n'importe quel script avec GameManager.xxx
# Ne contient que des données — aucune logique de jeu ici.

extends Node

# Émis quand un curseur de moralité bouge.
# Le HUD de chaque joueur écoute ce signal pour afficher brièvement sa barre.
#   id_joueur : 1 = Kael, 2 = Mira
#   valeur    : la nouvelle valeur, entre -100 et +100
signal moralite_changee(id_joueur: int, valeur: int)

# Émis quand le message d'état coopératif change.
# Ce message reste affiché dans le HUD des DEUX joueurs, contrairement à un
# dialogue qui défile et disparaît. Il sert à dire "l'autre t'attend".
signal etat_coop_change(texte: String)

# Émis quand la Zone 1 est finie : le grimoire est choisi ET le dialogue qui
# suit est terminé. main.gd l'écoute pour lancer l'écran de fin et les crédits.
# (zone1.gd ne connaît pas l'écran de fin : il annonce, main.gd orchestre.)
signal zone1_finie

# ── Progression Zone 1 ─────────────────────────────────────────────────────
var vaenmor_parle: bool = false     # Joueurs ont parlé à Vaenmor (donne la lettre d'Aldric)
var lira_parlee: bool = false       # Joueurs ont parlé à Lira
var brennan_parle: bool = false     # Joueurs ont parlé à Brennan

var puzzle1_resolu: bool = false
var puzzle2_resolu: bool = false
var puzzle3_resolu: bool = false

# ── Choix narratifs ────────────────────────────────────────────────────────
# Zone 1 : "secret" = on garde le grimoire / "partager" = on le montre aux villageois
var choix_grimoire: String = ""

# ── Moralité ───────────────────────────────────────────────────────────────
# Kael : -100 (Instinct pur) ↔ +100 (Raison pure)
var moralite_kael: int = 0
# Mira : -100 (Méfiance pure) ↔ +100 (Confiance pure)
var moralite_mira: int = 0

func modifier_moralite_kael(valeur: int) -> void:
	moralite_kael = clamp(moralite_kael + valeur, -100, 100)
	moralite_changee.emit(1, moralite_kael)

func modifier_moralite_mira(valeur: int) -> void:
	moralite_mira = clamp(moralite_mira + valeur, -100, 100)
	moralite_changee.emit(2, moralite_mira)

# ── État coopératif ────────────────────────────────────────────────────────
# Message court affiché en permanence dans les deux vues. Chaîne vide = rien.
var etat_coop: String = ""

func definir_etat_coop(texte: String) -> void:
	if etat_coop == texte:
		return
	etat_coop = texte
	etat_coop_change.emit(texte)

func zone1_terminee() -> bool:
	return puzzle1_resolu and puzzle2_resolu and puzzle3_resolu

func annoncer_fin_zone1() -> void:
	zone1_finie.emit()

# ── Nouvelle partie ────────────────────────────────────────────────────────
# GameManager est un AutoLoad : il survit aux changements de scène. Sans cette
# remise à zéro, revenir au menu puis relancer une partie démarrerait avec
# les puzzles déjà résolus et le grimoire déjà choisi.
# Appelée par le menu principal quand on clique sur « Commencer ».
func reinitialiser() -> void:
	vaenmor_parle = false
	lira_parlee = false
	brennan_parle = false
	puzzle1_resolu = false
	puzzle2_resolu = false
	puzzle3_resolu = false
	choix_grimoire = ""
	moralite_kael = 0
	moralite_mira = 0
	# Passe par la fonction pour que les HUD effacent leur message.
	definir_etat_coop("")
