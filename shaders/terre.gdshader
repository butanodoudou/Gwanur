// shaders/terre.gdshader
// La terre battue du village (les plaques posées par DecorVillage._plaque_de_terre).
//
// Une plaque est une boîte plate : sans ce shader, on voit un rectangle brun
// aux bords nets posé sur l'herbe, ce qui trahit la géométrie. Ici :
//   - le BORD est rongé par un bruit : la terre s'effiloche dans l'herbe ;
//   - près du bord, la terre verdit (de l'herbe rase qui reprend) ;
//   - au milieu, des taches plus claires et plus sombres (passages, flaques
//     séchées), à grande échelle, pour casser l'aplat.
//
// La taille de CHAQUE plaque est donnée par une « instance uniform »
// (demi_taille) : un seul matériau pour toutes les plaques, mais chacune
// connaît ses propres bords. stylisation.gd la remplit.

shader_type spatial;
render_mode cull_back;

#include "res://shaders/bruit.gdshaderinc"
#include "res://shaders/toon_eclairage.gdshaderinc"
#include "res://shaders/prairie.gdshaderinc"

uniform vec4 albedo : source_color = vec4(0.52, 0.43, 0.29, 1.0);
// Largeur (m) de la bande rongée le long des bords.
uniform float bord = 1.6;
instance uniform vec3 demi_taille = vec3(1.0);

varying vec3 position_locale;
varying vec3 position_monde;

void vertex() {
	position_locale = VERTEX;
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 xz = position_monde.xz;
	// Distance au bord le plus proche de la plaque (repère local).
	vec2 d2 = demi_taille.xz - abs(position_locale.xz);
	float d = min(d2.x, d2.y);
	// Le bord rongé : un bruit à deux échelles décide où s'arrête la terre.
	float n = bruit2(xz * 0.55) * 0.65 + bruit2(xz * 2.1) * 0.35;
	float seuil = bord * (0.15 + n);
	ALPHA = step(seuil, d);
	ALPHA_SCISSOR_THRESHOLD = 0.5;

	vec3 c = albedo.rgb;
	float taches = fbm2(xz * 0.18 + vec2(4.0, 1.0), 3);
	c *= 0.86 + taches * 0.3;
	c *= 0.94 + bruit2(xz * 3.7) * 0.12;
	// près du bord, l'herbe rase reprend : on tire vers la couleur du sol
	float vert = 1.0 - smoothstep(seuil, seuil + 0.9, d);
	c = mix(c, couleur_prairie(xz) * 0.8, vert * 0.55);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	translucidite = 0.0;
}
