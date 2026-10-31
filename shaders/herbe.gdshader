// shaders/herbe.gdshader
// L'herbe de la prairie, façon Breath of the Wild. Appliquée aux touffes du
// MultiMesh posé par scripts/zones/herbe.gd.
//
// Ce que fait ce shader :
//   - un DÉGRADÉ du pied (sombre) à la pointe (claire et dorée) ;
//   - la couleur de fond vient de prairie.gdshaderinc : la MÊME que le sol,
//     qui varie lentement d'un endroit à l'autre ;
//   - le VENT : chaque touffe se couche selon la rafale qui passe sur elle
//     (bruit.gdshaderinc). Les rafales traversent le champ en grandes vagues
//     plus claires, comme dans BotW ;
//   - les brins s'écartent sous les pieds de Kael et Mira ;
//   - au loin, les touffes RAPETISSENT jusqu'à disparaître dans le sol, au
//     lieu de disparaître d'un coup (pas de « pop »).
//
// Les normales : toutes tournées vers le ciel. Un brin éclairé comme une
// petite lame verticale scintille et s'assombrit au hasard ; éclairé comme
// le sol, le champ se lit comme une seule masse, et se fond dans le sol.

shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

#include "res://shaders/bruit.gdshaderinc"
#include "res://shaders/toon_eclairage.gdshaderinc"
#include "res://shaders/prairie.gdshaderinc"

// Positions des deux héros (mises à jour à chaque image par herbe.gd).
uniform vec3 joueur_1 = vec3(0.0, -100.0, 0.0);
uniform vec3 joueur_2 = vec3(0.0, -100.0, 0.0);
uniform float rayon_ecart = 0.9;

// Distance (m) où l'herbe commence à rapetisser, et où elle a disparu.
uniform float fondu_debut = 26.0;
uniform float fondu_fin = 38.0;

uniform float force_vent = 1.0;

varying float hauteur_relative;
varying float hasard_brin;
varying vec3 position_racine;

void vertex() {
	// Avec world_vertex_coords, VERTEX est déjà dans le monde, touffe placée.
	vec3 racine = MODEL_MATRIX[3].xyz;
	position_racine = racine;
	hauteur_relative = UV.y;       // 0 au pied, 1 à la pointe (cf. herbe.gd)
	hasard_brin = COLOR.r;         // un hasard propre à chaque brin

	float h = max(VERTEX.y - racine.y, 0.0);

	// Disparition au loin : on écrase la touffe vers sa racine.
	float d = distance(CAMERA_POSITION_WORLD, racine);
	float taille = 1.0 - smoothstep(fondu_debut, fondu_fin, d);
	VERTEX = racine + (VERTEX - racine) * vec3(1.0, taille, 1.0);
	h *= taille;

	// Le vent : la touffe entière se couche ensemble, chaque brin avec un
	// petit décalage de phase pour ne pas bouger comme un bloc.
	vec2 v = vent(racine.xz, TIME + hasard_brin * 0.35) * force_vent;
	v += vec2(sin(TIME * 4.0 + hasard_brin * 6.28), cos(TIME * 3.4 + hasard_brin * 6.28)) * 0.05;

	// Les héros écartent les brins (dans le plan du sol).
	for (int i = 0; i < 2; i++) {
		vec3 j = i == 0 ? joueur_1 : joueur_2;
		vec2 ecart = racine.xz - j.xz;
		float dist = length(ecart);
		float poids = (1.0 - smoothstep(rayon_ecart * 0.4, rayon_ecart, dist))
					* (1.0 - smoothstep(0.5, 1.6, abs(racine.y - j.y + 0.9)));
		v += ecart / max(dist, 0.05) * poids * 1.3;
	}

	float courbure = UV.y * UV.y;  // la pointe bouge, le pied reste planté
	VERTEX.xz += v * h * courbure;
	// on rabaisse un peu la pointe pour que le brin ne s'allonge pas en se couchant
	VERTEX.y -= dot(v, v) * h * courbure * 0.45;

	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec3 fond = couleur_prairie(position_racine.xz);
	vec3 pied = fond * 0.42;
	vec3 pointe = mix(fond, srgb(PRAIRIE_CLAIRE) * 1.05, 0.55);
	float t = smoothstep(0.0, 1.0, hauteur_relative);
	vec3 c = mix(pied, pointe, t);
	// chaque brin a sa nuance, un peu plus doré ou un peu plus vert
	c *= 0.88 + hasard_brin * 0.24;
	c = mix(c, srgb(PRAIRIE_SECHE) * 0.9, step(0.93, hasard_brin) * t * 0.6);
	// la rafale qui passe éclaircit les pointes (le reflet des brins couchés)
	c += srgb(vec3(0.42, 0.42, 0.25)) * rafale(position_racine.xz, TIME) * t * t * 0.55;
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	// Normale vers le ciel, de quelque côté qu'on regarde le brin (sinon la
	// face arrière, retournée par Godot, serait dans le noir).
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	translucidite = 0.35 * t;
}
