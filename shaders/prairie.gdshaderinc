// shaders/prairie.gdshaderinc
// La couleur de la prairie en un point du sol, partagée par le SOL et par
// l'HERBE. Les deux doivent tirer leurs couleurs du même endroit : au loin,
// l'herbe disparaît et c'est le sol qui prend le relais — si les teintes
// diffèrent, on voit une frontière nette autour du joueur.
//
// Les couleurs sont écrites en sRGB (comme dans un logiciel de dessin) et
// converties en linéaire par srgb(), ce qu'attend le moteur.

vec3 srgb(vec3 c) {
	return pow(c, vec3(2.2));
}

// Palette : vert de prairie chaud (soleil de fin d'après-midi), taches plus
// sombres et touches d'herbe sèche dorée (beige doré d'ART_DIRECTION.md).
const vec3 PRAIRIE_SOMBRE = vec3(0.23, 0.38, 0.19);
const vec3 PRAIRIE        = vec3(0.37, 0.55, 0.23);
const vec3 PRAIRIE_CLAIRE = vec3(0.58, 0.68, 0.29);
const vec3 PRAIRIE_SECHE  = vec3(0.74, 0.67, 0.38);

// Couleur « milieu de brin » de la prairie au point xz (en linéaire).
vec3 couleur_prairie(vec2 xz) {
	float grand = fbm2(xz * 0.035 + vec2(3.1, 7.7), 3);
	float moyen = bruit2(xz * 0.21 + vec2(11.0, 2.0));
	vec3 c = mix(PRAIRIE_SOMBRE, PRAIRIE, smoothstep(0.28, 0.55, grand));
	c = mix(c, PRAIRIE_CLAIRE, smoothstep(0.55, 0.78, grand) * 0.8);
	// des taches d'herbe sèche, petites et rares
	float sec = bruit2(xz * 0.06 + vec2(-5.0, 13.0));
	c = mix(c, PRAIRIE_SECHE, smoothstep(0.68, 0.86, sec) * 0.55);
	c *= 0.92 + moyen * 0.16;
	return srgb(c);
}
