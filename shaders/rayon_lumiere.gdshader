// shaders/rayon_lumiere.gdshader
// Un rayon de soleil qui tombe par le Trou de Ciel (l'oculus de l'Aelith).
//
// C'est un simple cylindre allongé, dessiné en mode ADDITIF (il ne fait
// qu'éclaircir ce qu'il y a derrière) et sans éclairage. Bien moins cher que
// le brouillard volumétrique de Godot, qui calculerait la lumière dans tout
// le volume de la cavité, deux fois par image en écran splitté.
//
// Pour qu'on ne voie pas le cylindre :
//   - ses BORDS s'effacent (là où on le voit de biais, il est transparent) ;
//   - ses deux BOUTS s'effacent (on ne voit ni où il commence ni où il finit) ;
//   - il s'efface quand la caméra s'en approche (sinon, une fois dedans, tout
//     l'écran deviendrait doré) ;
//   - il palpite très lentement, comme si des feuilles passaient devant.

shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, fog_disabled, shadows_disabled;

#include "res://shaders/bruit.gdshaderinc"

uniform vec3 couleur : source_color = vec3(1.0, 0.85, 0.58);
uniform float intensite = 0.3;
uniform float phase = 0.0;
// En dessous de cette distance (m), le rayon disparaît.
uniform float distance_fondu = 12.0;

varying float le_long;
varying vec3 position_monde;

void vertex() {
	// CylinderMesh : y va de -hauteur/2 à +hauteur/2. On le ramène à 0..1.
	le_long = clamp(VERTEX.y / 120.0 + 0.5, 0.0, 1.0);
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float face = abs(dot(NORMAL, VIEW));
	float coeur = pow(face, 2.5);
	float bouts = smoothstep(0.0, 0.25, le_long) * smoothstep(1.0, 0.55, le_long);
	float pres = smoothstep(distance_fondu * 0.4, distance_fondu, length(VERTEX));
	float vie = 0.7 + 0.3 * bruit2(vec2(TIME * 0.15 + phase, phase * 3.1));
	// des stries le long du rayon (de la poussière dans la lumière)
	float stries = 0.75 + 0.25 * bruit2(vec2(position_monde.x + position_monde.z, le_long * 6.0 - TIME * 0.05));
	ALBEDO = couleur * intensite * coeur * bouts * pres * vie * stries;
}
