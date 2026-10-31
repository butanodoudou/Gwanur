// shaders/toon_eclairage.gdshaderinc
// L'éclairage « cel-shading doux » façon Breath of the Wild, partagé par tous
// les matériaux du jeu (objets, sol, herbe).
//
// CE QUI FAIT LE RENDU BotW, et comment on le reproduit ici :
//   1. Une RAMPE à paliers doux : au lieu d'une lumière qui décroît
//      régulièrement (Lambert, l'aspect « pâte à modeler »), la surface est
//      soit éclairée, soit à mi-teinte, soit à l'ombre — avec des transitions
//      adoucies. On ne voit plus chaque facette, on voit des masses.
//   2. Des OMBRES TEINTÉES : le côté ombre n'est pas noir ni gris, il reçoit
//      une lumière froide, bleutée/violette (le ciel qui éclaire ce que le
//      soleil ne touche pas). Chaud au soleil, froid à l'ombre : c'est le
//      contraste qui donne l'air « peint ».
//   3. Un LISERÉ (rim light) sur les bords tournés vers le soleil : la
//      silhouette se détache du fond.
//   4. Un spéculaire très discret, en tache nette et petite.
//
// La fonction `light()` est appelée par Godot une fois par lumière et par
// pixel. On n'y écrit QUE l'éclairage direct ; la lumière ambiante est
// ajoutée par Godot ensuite (réglée dans l'Environment de main.tscn).
//
// Pour l'utiliser : `#include "res://shaders/toon_eclairage.gdshaderinc"`
// APRÈS `shader_type spatial;`. Le shader qui l'inclut doit écrire la varying
// `translucidite` dans fragment() (0 pour un objet opaque ordinaire).

group_uniforms toon;
// Seuils de la rampe, en dot(normale, lumière) : sous seuil_ombre on est à
// l'ombre, au-dessus de seuil_lumiere on est en pleine lumière.
uniform float seuil_ombre : hint_range(-1.0, 1.0) = -0.05;
uniform float seuil_lumiere : hint_range(-1.0, 1.0) = 0.42;
// Valeur du palier intermédiaire (0 = ombre, 1 = lumière).
uniform float mi_teinte : hint_range(0.0, 1.0) = 0.62;
// Largeur des transitions : 0 = aplats durs (Wind Waker), 0.2 = très doux.
uniform float douceur : hint_range(0.0, 0.5) = 0.11;
// La lumière froide qui remplit les ombres.
uniform vec3 teinte_ombre : source_color = vec3(0.58, 0.62, 0.88);
uniform float force_ombre_teintee : hint_range(0.0, 1.0) = 0.28;
uniform float force_rim : hint_range(0.0, 2.0) = 0.35;
uniform float largeur_rim : hint_range(0.0, 1.0) = 0.45;
uniform float force_speculaire : hint_range(0.0, 1.0) = 0.06;
group_uniforms;

// Écrite dans fragment() : combien la surface laisse passer la lumière par
// derrière (feuilles, herbe). 0 = opaque.
varying float translucidite;

float rampe_toon(float nl) {
	float p1 = smoothstep(seuil_ombre - douceur, seuil_ombre + douceur, nl);
	float p2 = smoothstep(seuil_lumiere - douceur, seuil_lumiere + douceur, nl);
	return p1 * mi_teinte + p2 * (1.0 - mi_teinte);
}

void light() {
	float nl = dot(NORMAL, LIGHT);
	vec3 lumiere = LIGHT_COLOR / PI;

	// L'ombre portée (ATTENUATION) est elle aussi « durcie » un peu : le flou
	// des ombres de Godot donne sinon une pénombre grise très large.
	float ombre = ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		ombre = smoothstep(0.12, 0.88, ATTENUATION);
	}

	float eclaire = rampe_toon(nl) * ombre;
	DIFFUSE_LIGHT += lumiere * eclaire;

	if (LIGHT_IS_DIRECTIONAL) {
		float energie = dot(lumiere, vec3(0.3333));

		// 2. Ombre teintée : une lumière froide là où le soleil ne va pas.
		DIFFUSE_LIGHT += teinte_ombre * energie * force_ombre_teintee * (1.0 - eclaire);

		// 3. Liseré : les bords (normale perpendiculaire au regard), côté soleil.
		float bord = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float rim = smoothstep(1.0 - largeur_rim, 1.0 - largeur_rim * 0.35, bord);
		rim *= smoothstep(-0.2, 0.35, nl) * ombre;
		// Pas de liseré sur ce qui regarde le ciel (sol, herbe, toits plats) :
		// vu en rasant, tout le sol blanchirait au loin.
		float vers_ciel = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).y;
		rim *= 1.0 - smoothstep(0.45, 0.85, vers_ciel);
		DIFFUSE_LIGHT += lumiere * rim * force_rim;

		// Translucidité : feuilles et brins vus à contre-jour s'illuminent.
		if (translucidite > 0.0) {
			float contre_jour = pow(clamp(dot(-VIEW, LIGHT), 0.0, 1.0), 3.0);
			float dos = clamp(-nl * 0.5 + 0.5, 0.0, 1.0);
			DIFFUSE_LIGHT += lumiere * translucidite * (contre_jour * 0.8 + dos * 0.25) * ombre;
		}

		// 4. Spéculaire : petite tache nette, très discrète.
		vec3 h = normalize(LIGHT + VIEW);
		float s = smoothstep(0.92, 0.97, dot(NORMAL, h));
		SPECULAR_LIGHT += lumiere * s * force_speculaire * ombre;
	}
}
