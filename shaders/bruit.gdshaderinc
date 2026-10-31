// shaders/bruit.gdshaderinc
// Bruits procéduraux partagés par tous les shaders du rendu « BotW ».
//
// Pourquoi du bruit calculé plutôt qu'une texture de bruit ?
// Une NoiseTexture2D se génère dans un thread au démarrage : pendant les
// premières images, elle est vide (les captures et les tests la verraient
// noire). Un bruit « valeur » coûte quelques multiplications par pixel, ce
// qui est négligeable, et il est disponible dès la première image.
//
// Le VENT est défini ici aussi : herbe, feuillage et sol doivent onduler
// ENSEMBLE, sinon l'oeil voit tout de suite que ce sont trois effets séparés.

// Un nombre pseudo-aléatoire entre 0 et 1 pour chaque point du plan.
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float hash31(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

// Bruit « valeur » 2D : des valeurs au hasard aux coins d'une grille,
// interpolées en douceur entre les coins. Résultat entre 0 et 1.
float bruit2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// La même chose en 3D (pour la texture « aquarelle » des objets).
float bruit3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i);
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	return mix(
		mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
		mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}

// Bruit fractal : plusieurs bruits superposés, de plus en plus fins.
// Donne des formes « naturelles » (nuages, taches d'herbe sèche).
float fbm2(vec2 p, int octaves) {
	float somme = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < octaves; i++) {
		somme += bruit2(p) * amplitude;
		p = p * 2.03 + vec2(17.1, 9.2);
		amplitude *= 0.5;
	}
	return somme;
}

// ── LE VENT ──────────────────────────────────────────────────────────────────
// Direction dominante : il souffle du sud-ouest vers le nord-est, en gros.
const vec2 VENT_DIRECTION = vec2(0.82, -0.57);
const float VENT_VITESSE = 1.6;   // vitesse des rafales qui traversent le champ (m/s)

// Intensité d'une rafale en un point du sol, entre 0 et 1.
// Ce sont ces grandes taches qui « traversent » le champ comme dans BotW :
// un bruit étiré, que l'on fait glisser dans la direction du vent.
float rafale(vec2 xz, float temps) {
	vec2 p = xz - VENT_DIRECTION * temps * VENT_VITESSE;
	// étiré perpendiculairement au vent : des fronts de vague, pas des taches
	vec2 q = vec2(dot(p, VENT_DIRECTION), dot(p, vec2(-VENT_DIRECTION.y, VENT_DIRECTION.x)) * 0.45);
	float r = bruit2(q * 0.09) * 0.7 + bruit2(q * 0.23 + 3.7) * 0.3;
	return smoothstep(0.35, 0.85, r);
}

// Le déplacement horizontal (x, z) dû au vent, pour un point à `xz`.
// Une ondulation permanente (petite) + la rafale (grande).
vec2 vent(vec2 xz, float temps) {
	float r = rafale(xz, temps);
	float ondule = sin(temps * 2.1 + dot(xz, vec2(0.7, 0.4))) * 0.5
				 + sin(temps * 3.3 + dot(xz, vec2(-0.3, 1.1))) * 0.25;
	return VENT_DIRECTION * (0.12 + r * 0.55) + VENT_DIRECTION.yx * vec2(-1.0, 1.0) * ondule * 0.08;
}
