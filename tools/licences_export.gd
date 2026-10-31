# tools/licences_export.gd
# Écrit build/windows/LICENCES.txt, à livrer à côté de Gwanur.exe.
#
# Pourquoi : Godot est sous licence MIT, qui exige que son texte de licence
# accompagne le jeu publié. Godot embarque aussi des bibliothèques tierces
# (FreeType, etc.) qui ont leurs propres licences. Le moteur sait lister tout
# ça lui-même (Engine.get_license_text / get_copyright_info / get_license_info) :
# on n'a qu'à l'écrire dans un fichier.
# On y ajoute les assets tiers du jeu (assets/models/vegetation/LICENCES.md).
#
# Lancer (après chaque export) :
#   godot --headless --path . --script res://tools/licences_export.gd

extends SceneTree

const SORTIE := "res://build/windows/LICENCES.txt"
const LICENCES_ASSETS := "res://assets/models/vegetation/LICENCES.md"

func _init() -> void:
	var texte := "GWANUR — Licences\n"
	texte += "==================\n\n"

	# ── Assets tiers du jeu ───────────────────────────────────────────────────
	texte += "ASSETS TIERS\n------------\n\n"
	if FileAccess.file_exists(LICENCES_ASSETS):
		texte += FileAccess.get_file_as_string(LICENCES_ASSETS) + "\n\n"

	# ── Le moteur Godot (MIT) ─────────────────────────────────────────────────
	texte += "MOTEUR — GODOT ENGINE\n---------------------\n\n"
	texte += "Ce jeu utilise Godot Engine, disponible sous la licence MIT suivante.\n\n"
	texte += Engine.get_license_text() + "\n\n"

	# ── Les composants tiers embarqués dans Godot ─────────────────────────────
	texte += "COMPOSANTS TIERS DE GODOT\n-------------------------\n\n"
	for composant in Engine.get_copyright_info():
		texte += "- %s\n" % composant["name"]
		for partie in composant["parts"]:
			for c in partie["copyright"]:
				texte += "    © %s\n" % c
			texte += "    Licence : %s\n" % partie["license"]
	texte += "\n"

	# ── Le texte complet de chaque licence citée ──────────────────────────────
	texte += "TEXTES DES LICENCES\n-------------------\n\n"
	var licences: Dictionary = Engine.get_license_info()
	for nom in licences:
		texte += "=== %s ===\n\n%s\n\n" % [nom, licences[nom]]

	var f := FileAccess.open(SORTIE, FileAccess.WRITE)
	if f == null:
		push_error("Impossible d'écrire %s (le dossier build/windows existe-t-il ?)" % SORTIE)
		quit(1)
		return
	f.store_string(texte)
	f.close()
	print("Licences écrites dans ", ProjectSettings.globalize_path(SORTIE))
	quit()
