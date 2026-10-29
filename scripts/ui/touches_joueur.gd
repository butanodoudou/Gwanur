# scripts/ui/touches_joueur.gd
# Quel nom de touche afficher pour « interagir » : (E), (Entrée) ou (A) ?
#
# Chaque joueur peut jouer au clavier OU à la manette (voir project.godot :
# Kael = E ou manette n°0, Mira = Entrée ou manette n°1). On affiche la touche
# du DERNIER périphérique que CE joueur a touché.
#
# COMMENT ON SAIT QUEL PÉRIPHÉRIQUE IL A TOUCHÉ
# On ne passe pas par _input() : le HUD vit dans un SubViewport, et c'est plus
# simple (et plus sûr) d'INTERROGER l'état des touches à chaque image. Pour
# chaque action du joueur ("joueur1_avancer", "joueur1_interagir"…), on regarde
# les touches clavier et les boutons/sticks de manette qui lui sont associés
# dans l'InputMap : si l'un d'eux est enfoncé, on retient ce périphérique.
#
# UTILISATION
# Ce fichier n'est pas un nœud : on le charge avec preload() et on appelle ses
# fonctions « static » (des fonctions qui n'ont pas besoin d'objet) :
#   const TouchesJoueur = preload("res://scripts/ui/touches_joueur.gd")
#   TouchesJoueur.mettre_a_jour(1)        # le HUD de Kael, à chaque image
#   TouchesJoueur.interagir(1)            # → "E", "A"…
#
# Les « static var » sont partagées par tout le jeu : quand le HUD de Kael note
# « clavier », zone1.gd le voit aussi en écrivant le texte du choix.

extends RefCounted

const CLAVIER := "clavier"
const MANETTE := "manette"

# Nom affiché de la touche « interagir », par joueur et par périphérique.
# (Écrits à la main : lire le nom dans l'InputMap donnerait "Enter", en anglais.)
const NOMS := {
	1: { CLAVIER: "E",      MANETTE: "A" },
	2: { CLAVIER: "Entrée", MANETTE: "A" },
}

# Un stick doit être poussé au moins de ça pour compter (évite la dérive des sticks usés).
const SEUIL_STICK: float = 0.5

# id_joueur → CLAVIER / MANETTE (absent tant que le joueur n'a rien touché)
static var _dernier: Dictionary = {}

# Nom de la touche « interagir » à afficher pour ce joueur.
static func interagir(id_joueur: int) -> String:
	return NOMS[id_joueur][peripherique(id_joueur)]

# Le périphérique retenu pour ce joueur. Tant qu'il n'a rien touché : manette
# si la sienne est branchée, sinon clavier.
static func peripherique(id_joueur: int) -> String:
	if _dernier.has(id_joueur):
		return _dernier[id_joueur]
	var num_manette: int = id_joueur - 1
	if Input.get_connected_joypads().has(num_manette):
		return MANETTE
	return CLAVIER

# À appeler à chaque image (le HUD le fait). Regarde si ce joueur appuie en ce
# moment sur une touche clavier ou un bouton de manette.
static func mettre_a_jour(id_joueur: int) -> void:
	var prefixe := "joueur%d_" % id_joueur
	for action in InputMap.get_actions():
		if not String(action).begins_with(prefixe):
			continue
		for evenement in InputMap.action_get_events(action):
			var trouve := _detecter(evenement)
			if trouve != "":
				_dernier[id_joueur] = trouve
				return

# Renvoie CLAVIER ou MANETTE si cet événement de l'InputMap est enfoncé en ce moment.
static func _detecter(evenement: InputEvent) -> String:
	if evenement is InputEventKey:
		var touche := evenement as InputEventKey
		if touche.keycode != KEY_NONE and Input.is_key_pressed(touche.keycode):
			return CLAVIER
		if touche.physical_keycode != KEY_NONE and Input.is_physical_key_pressed(touche.physical_keycode):
			return CLAVIER
	elif evenement is InputEventJoypadButton:
		var bouton := evenement as InputEventJoypadButton
		if Input.is_joy_button_pressed(bouton.device, bouton.button_index):
			return MANETTE
	elif evenement is InputEventJoypadMotion:
		var stick := evenement as InputEventJoypadMotion
		if absf(Input.get_joy_axis(stick.device, stick.axis)) > SEUIL_STICK:
			return MANETTE
	return ""

# Pour les tests : oublie ce que les joueurs ont touché.
static func oublier() -> void:
	_dernier.clear()
