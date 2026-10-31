// shaders/toon_materiau.gdshaderinc
// Le corps commun des matériaux toon : il reprend ce que portait le
// StandardMaterial3D d'origine (couleur, texture, couleurs de sommets,
// émission) et l'éclaire avec toon_eclairage.gdshaderinc.
//
// Les VARIANTES sont des petits fichiers .gdshader qui fixent le render_mode
// (faces arrière, transparence…) et activent des options par #define avant
// d'inclure ce fichier :
//   FEUILLAGE      normales « sphériques », ondulation au vent, translucidité
//   ALPHA_SCISSOR  découpe nette selon l'alpha de la texture (cartes de feuilles)
//   ALPHA_BLEND    vraie transparence (verre, voiles)
//
// Les valeurs sont posées par scripts/rendu/stylisation.gd, qui convertit
// chaque StandardMaterial3D du décor en un ShaderMaterial de ce type.

#include "res://shaders/bruit.gdshaderinc"
#include "res://shaders/toon_eclairage.gdshaderinc"

group_uniforms materiau;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool utiliser_texture = false;
uniform bool utiliser_couleur_sommet = false;
uniform vec3 uv1_echelle = vec3(1.0);
uniform vec3 uv1_decalage = vec3(0.0);
uniform vec3 emission : source_color = vec3(0.0);
uniform float energie_emission = 0.0;
uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap;
uniform bool utiliser_texture_emission = false;
// Texture « aquarelle » : de légères variations de valeur, en taches larges,
// qui cassent les aplats parfaitement unis (le rendu BotW n'en a jamais).
uniform float aquarelle : hint_range(0.0, 0.3) = 0.07;
uniform float echelle_aquarelle = 0.9;
// Saturation de la texture : certains modèles importés sont trop « fluo ».
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float seuil_alpha : hint_range(0.0, 1.0) = 0.5;
group_uniforms;

#ifdef FEUILLAGE
group_uniforms feuillage;
// Normales sphériques : la normale de chaque sommet est tirée vers celle d'un
// ellipsoïde qui englobe le feuillage (centre et demi-axes en coordonnées du
// maillage, calculés par stylisation.gd). Une boule à facettes s'éclaire
// alors comme UN volume doux : on ne voit plus chaque triangle.
uniform vec3 centre_feuillage = vec3(0.0);
uniform vec3 etendue_feuillage = vec3(1.0);
uniform float force_normales_spheriques : hint_range(0.0, 1.0) = 0.0;
// Ondulation au vent, en mètres pour la cime d'un arbre de `hauteur_vent` m.
uniform float amplitude_vent = 0.12;
uniform float hauteur_vent = 8.0;
uniform float force_translucidite : hint_range(0.0, 1.0) = 0.35;
group_uniforms;
#endif

varying vec3 position_locale;

void vertex() {
	UV = UV * uv1_echelle.xy + uv1_decalage.xy;
	position_locale = VERTEX;

#ifdef FEUILLAGE
	if (force_normales_spheriques > 0.0) {
		vec3 sph = normalize((VERTEX - centre_feuillage) / max(etendue_feuillage, vec3(0.01)));
		NORMAL = normalize(mix(NORMAL, sph, force_normales_spheriques));
	}
	// Le vent : déplacement calculé dans le monde (pour que tous les arbres
	// soient pris dans la même rafale), puis ramené dans le repère du maillage.
	vec3 monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float hauteur = max(monde.y - MODEL_MATRIX[3].y, 0.0);
	float poids = clamp(hauteur / hauteur_vent, 0.0, 1.0);
	vec2 v = vent(monde.xz, TIME) * 0.6;
	// petit frisson propre à chaque grappe, qui ne dépend que de la position
	v += vec2(sin(TIME * 2.7 + monde.x * 0.9 + monde.y), cos(TIME * 2.3 + monde.z * 0.8)) * 0.12;
	vec3 deplacement = vec3(v.x, 0.0, v.y) * amplitude_vent * poids * poids;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * deplacement;
#endif
}

void fragment() {
	vec4 c = albedo;
	if (utiliser_texture) {
		vec4 t = texture(texture_albedo, UV);
		float gris = dot(t.rgb, vec3(0.299, 0.587, 0.114));
		t.rgb = mix(vec3(gris), t.rgb, saturation);
		c *= t;
	}
	if (utiliser_couleur_sommet) {
		c *= COLOR;
	}
	// Taches d'aquarelle, accrochées à l'objet (repère local) : elles ne
	// « glissent » pas quand l'objet bouge.
	if (aquarelle > 0.0) {
		float n = bruit3(position_locale * echelle_aquarelle) * 0.65
				+ bruit3(position_locale * echelle_aquarelle * 3.1) * 0.35;
		c.rgb *= 1.0 + (n - 0.5) * 2.0 * aquarelle;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;

	vec3 em = emission * energie_emission;
	if (utiliser_texture_emission) {
		em *= texture(texture_emission, UV).rgb;
	}
	EMISSION = em;

#ifdef FEUILLAGE
	translucidite = force_translucidite;
#else
	translucidite = 0.0;
#endif

#ifdef ALPHA_SCISSOR
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = seuil_alpha;
#endif
#ifdef ALPHA_BLEND
	ALPHA = c.a;
#endif
}
