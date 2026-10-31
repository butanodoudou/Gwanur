// shaders/paves.gdshader
// Les chemins pavés du village (posés par DecorVillage._paver_entre).
//
// Un chemin est UN ruban plat (une boîte de 2 cm d'épaisseur) : ce shader y
// dessine des pavés « à la Breath of the Wild » :
//   - des pierres IRRÉGULIÈRES : un pavage de Voronoi (chaque pixel appartient
//     au point aléatoire le plus proche ; la frontière entre deux points fait
//     la jointure), déformé par un bruit pour casser les lignes droites ;
//   - des BORDS ARRONDIS : la distance à la jointure est un « minimum doux »
//     (les coins s'émoussent), et la normale se courbe près du bord : chaque
//     pierre s'éclaire comme un petit galet bombé ;
//   - une TEINTE PAR PIERRE (pierre dorée d'ART_DIRECTION), jamais deux
//     voisines pareilles, et un peu de mousse au ras des jointures ;
//   - des JOINTURES ÉVIDÉES : là, le pixel est découpé (alpha scissor) et l'on
//     voit ce qu'il y a dessous — la terre battue sur la place, la prairie
//     ailleurs. Les jointures ont donc toujours la couleur du sol voisin ;
//   - un BORD DE CHEMIN DÉCOUSU : les pierres dont le centre est trop près du
//     bord du ruban disparaissent (au hasard), le chemin s'effrite dans l'herbe.
//
// Coût : deux passes de 3×3 cellules par pixel (18 tours de boucle), sur 4
// rubans au ras du sol — négligeable, et 4 objets à dessiner au lieu de 76
// dalles.
//
// Les dimensions de CHAQUE ruban sont données par une « instance uniform »
// (demi_taille), comme pour la terre battue : un seul matériau pour tous.

shader_type spatial;
render_mode cull_back;

#include "res://shaders/bruit.gdshaderinc"
#include "res://shaders/toon_eclairage.gdshaderinc"

group_uniforms paves;
// Les trois teintes de pierre entre lesquelles chaque pavé tire la sienne.
uniform vec4 pierre_doree : source_color = vec4(0.79, 0.64, 0.42, 1.0);
uniform vec4 pierre_claire : source_color = vec4(0.84, 0.74, 0.55, 1.0);
uniform vec4 pierre_grege : source_color = vec4(0.70, 0.62, 0.50, 1.0);
uniform vec4 mousse : source_color = vec4(0.42, 0.50, 0.27, 1.0);
// Taille moyenne d'un pavé (m) et largeur de la jointure (m).
uniform float taille_pave = 0.62;
uniform float largeur_joint = 0.035;
// Largeur (m) de la zone bombée au bord de chaque pierre, et force du bombé.
uniform float largeur_bombe = 0.16;
uniform float force_bombe : hint_range(0.0, 2.0) = 1.3;
// Proportion de pavés absents au milieu du chemin (l'herbe a gagné).
uniform float pierres_manquantes : hint_range(0.0, 0.5) = 0.04;
group_uniforms;

instance uniform vec3 demi_taille = vec3(1.0);
// Décale le motif d'un chemin à l'autre (sinon les quatre seraient identiques).
instance uniform float graine = 0.0;

varying vec3 position_locale;

void vertex() {
	position_locale = VERTEX;
}

vec2 hash22(vec2 p) {
	return vec2(hash21(p), hash21(p + vec2(17.3, 41.9)));
}

// Minimum « doux » : comme min(a, b), mais arrondi quand a ≈ b. C'est lui qui
// émousse les coins des pavés.
float min_doux(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

void fragment() {
	vec2 local = position_locale.xz;
	// Coordonnées en « pavés », déformées par un bruit : des pierres aux côtés
	// un peu courbes, plutôt que des polygones parfaits.
	vec2 p = (local + vec2(graine * 37.0, graine * 11.0)) / taille_pave;
	p += (vec2(bruit2(p * 0.9), bruit2(p * 0.9 + 19.7)) - 0.5) * 0.35;

	vec2 cellule = floor(p);
	vec2 dans = fract(p);

	// 1re passe : le point le plus proche (= la pierre de ce pixel).
	vec2 vers_centre = vec2(0.0);   // du pixel vers le centre de sa pierre
	vec2 id = vec2(0.0);
	float d_min = 8.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 r = g + 0.15 + hash22(cellule + g) * 0.7 - dans;
			float d = dot(r, r);
			if (d < d_min) {
				d_min = d;
				vers_centre = r;
				id = cellule + g;
			}
		}
	}

	// 2e passe : la distance (douce) aux frontières avec les voisines.
	float bord = 8.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = id - cellule + vec2(float(i), float(j));
			vec2 r = g + 0.15 + hash22(cellule + g) * 0.7 - dans;
			vec2 ecart = r - vers_centre;
			if (dot(ecart, ecart) > 0.0001) {
				float d = dot(0.5 * (vers_centre + r), normalize(ecart));
				bord = min_doux(bord, d, 0.12);
			}
		}
	}
	bord *= taille_pave;   // en mètres

	// ── Quelles pierres existent ? ────────────────────────────────────────────
	float h = hash21(id + 3.7);
	float h2 = hash21(id + 91.1);
	// Le centre de la pierre, dans le repère du ruban (approximatif : sans la
	// déformation, inutile ici).
	vec2 centre = local + vers_centre * taille_pave;
	// Près du bord (en largeur ET aux deux bouts), la pierre manque d'autant
	// plus souvent qu'elle est proche du bord.
	vec2 marge = demi_taille.xz - abs(centre);
	float limite = taille_pave * (0.35 + h2 * 0.6);
	bool presente = marge.x > limite && marge.y > limite * 0.8;
	presente = presente && h2 > pierres_manquantes;

	// La jointure, un peu plus large par endroits (terre tassée).
	float joint = largeur_joint * (0.6 + bruit2(local * 1.7) * 0.9);
	ALPHA = (presente && bord > joint) ? 1.0 : 0.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;

	// ── La couleur de la pierre ───────────────────────────────────────────────
	vec3 c = mix(pierre_doree.rgb, pierre_claire.rgb, smoothstep(0.35, 0.95, h));
	c = mix(c, pierre_grege.rgb, smoothstep(0.55, 0.0, h) * 0.8);
	// un léger grain, accroché à la pierre
	c *= 0.93 + bruit2(local * 4.3) * 0.1 + bruit2(local * 11.0) * 0.04;
	// un peu de mousse au ras des jointures, sur certaines pierres seulement
	float frange = 1.0 - smoothstep(joint, joint + 0.09, bord);
	float moussue = smoothstep(0.45, 0.8, bruit2(local * 0.7 + 5.0));
	c = mix(c, mousse.rgb, frange * moussue * 0.55);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	translucidite = 0.0;

	// ── Le bombé : la normale penche vers l'extérieur près du bord ────────────
	// (repère local du ruban → vue). Chaque pierre a aussi son petit
	// déversement propre, pour que les voisines ne s'éclairent pas pareil.
	float pente = (1.0 - smoothstep(joint, joint + largeur_bombe, bord)) * force_bombe;
	vec2 dehors = -normalize(vers_centre + vec2(0.0001));
	vec2 devers = (hash22(id + 7.0) - 0.5) * 0.18;
	vec3 n_local = normalize(vec3(dehors.x * pente + devers.x, 1.0, dehors.y * pente + devers.y));
	NORMAL = normalize((VIEW_MATRIX * (MODEL_MATRIX * vec4(n_local, 0.0))).xyz);
}
