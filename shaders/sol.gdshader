// shaders/sol.gdshader
// Le sol de la prairie : au lieu d'un aplat vert, la même couleur que l'herbe
// (prairie.gdshaderinc), avec ses taches sombres et dorées, et les rafales de
// vent qui l'éclaircissent au passage. Là où l'herbe s'arrête (au loin, ou
// sous les pieds), le sol prend le relais sans couture.

shader_type spatial;
render_mode cull_back;

#include "res://shaders/bruit.gdshaderinc"
#include "res://shaders/toon_eclairage.gdshaderinc"
#include "res://shaders/prairie.gdshaderinc"

// Le sol est un peu plus sombre que le milieu des brins : c'est le pied de
// l'herbe, à l'ombre des brins voisins.
uniform float assombrissement : hint_range(0.0, 1.0) = 0.86;

varying vec3 position_monde;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 xz = position_monde.xz;
	vec3 c = couleur_prairie(xz) * assombrissement;
	// des petits brins « peints » au sol, pour la texture de près
	float fin = bruit2(xz * 2.3) * 0.6 + bruit2(xz * 6.1) * 0.4;
	c *= 0.9 + fin * 0.2;
	// un peu moins saturé que les brins : le sol nu entre les touffes tire
	// vers le jaune-brun, sinon il fait une bande vert vif au bord des chemins
	float l = dot(c, vec3(0.3, 0.59, 0.11));
	c = mix(c, vec3(l * 1.25, l * 1.1, l * 0.6), 0.3);
	// la rafale éclaircit aussi le sol, très légèrement
	c *= 1.0 + rafale(xz, TIME) * 0.06;
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	translucidite = 0.0;
}
