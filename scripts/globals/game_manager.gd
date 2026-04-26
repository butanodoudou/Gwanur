# scripts/globals/game_manager.gd
# AutoLoad — état global du jeu, accessible depuis n'importe quel script avec GameManager.xxx
# Ne contient que des données — aucune logique de jeu ici.

extends Node

# ── Progression Zone 1 ─────────────────────────────────────────────────────
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

func modifier_moralite_mira(valeur: int) -> void:
	moralite_mira = clamp(moralite_mira + valeur, -100, 100)

func zone1_terminee() -> bool:
	return puzzle1_resolu and puzzle2_resolu and puzzle3_resolu
