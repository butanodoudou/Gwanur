// shaders/ciel.gdshader
// Le ciel « peint » de fin d'après-midi, façon Breath of the Wild.
//
//   - un DÉGRADÉ chaud : bleu doux au zénith, pêche doré à l'horizon, et une
//     bande de brume claire tout en bas qui se fond dans le brouillard ;
//   - un SOLEIL doux : un disque pâle et un grand halo chaud, sans éblouir ;
//   - des NUAGES stylisés : des masses arrondies aux bords nets mais doux,
//     claires et dorées sur le dessus, lavande dessous (pas de gris), qui
//     DÉRIVENT lentement dans le sens du vent ;
//   - le sol (sous l'horizon) reprend la couleur de la brume : on ne le voit
//     jamais vraiment (le rempart de l'Aelith le cache), mais il éclaire les
//     objets par en dessous via la lumière ambiante.
//
// Les nuages ne sont dessinés QUE dans le ciel visible, pas dans le calcul de
// la lumière ambiante (AT_CUBEMAP_PASS) : celle-ci reste ainsi stable, et le
// ciel animé ne fait pas « clignoter » l'éclairage du village.

shader_type sky;

#include "res://shaders/bruit.gdshaderinc"

group_uniforms degrade;
uniform vec3 couleur_zenith : source_color = vec3(0.33, 0.55, 0.82);
uniform vec3 couleur_milieu : source_color = vec3(0.60, 0.75, 0.90);
uniform vec3 couleur_horizon : source_color = vec3(0.98, 0.84, 0.66);
uniform vec3 couleur_brume : source_color = vec3(0.98, 0.88, 0.74);
uniform vec3 couleur_sol : source_color = vec3(0.62, 0.55, 0.45);
uniform float energie : hint_range(0.0, 4.0) = 1.0;

group_uniforms soleil;
uniform vec3 couleur_soleil : source_color = vec3(1.0, 0.93, 0.78);
uniform float taille_soleil : hint_range(0.0, 0.2) = 0.035;
uniform float force_halo : hint_range(0.0, 2.0) = 0.55;

group_uniforms nuages;
uniform vec3 nuage_clair : source_color = vec3(1.0, 0.97, 0.90);
uniform vec3 nuage_dore : source_color = vec3(1.0, 0.82, 0.60);
uniform vec3 nuage_ombre : source_color = vec3(0.72, 0.70, 0.86);
uniform float couverture : hint_range(0.0, 1.0) = 0.48;
uniform float vitesse_nuages = 0.006;
uniform float echelle_nuages = 1.3;
group_uniforms;

// (Les couleurs `source_color` sont saisies en sRGB et converties en linéaire
// par Godot lui-même : pas de conversion à faire ici.)

// La « densité » des nuages au point p du plan des nuages. Des formes
// arrondies (bruit fractal), tassées vers le bas pour avoir des bords nets.
float densite_nuage(vec2 p) {
	float n = fbm2(p, 5);
	// des trouées plus larges : le ciel BotW est fait de bancs, pas d'un voile
	float trous = bruit2(p * 0.35 + vec2(7.0, 3.0));
	return n * 0.8 + trous * 0.35 - (1.0 - couverture) * 0.75;
}

void sky() {
	vec3 dir = EYEDIR;
	float h = dir.y;

	// ── Le dégradé ─────────────────────────────────────────────────────────
	vec3 c;
	if (h >= 0.0) {
		float t = pow(h, 0.55);
		c = mix(couleur_horizon, couleur_milieu, smoothstep(0.0, 0.45, t));
		c = mix(c, couleur_zenith, smoothstep(0.35, 1.0, t));
		// la brume collée à l'horizon
		c = mix(c, couleur_brume, (1.0 - smoothstep(0.0, 0.10, h)) * 0.85);
	} else {
		c = mix(couleur_brume, couleur_sol, smoothstep(0.0, 0.25, -h));
	}

	// ── Le soleil ──────────────────────────────────────────────────────────
	vec3 vers_soleil = LIGHT0_DIRECTION;
	float cos_soleil = dot(dir, vers_soleil);
	float angle = acos(clamp(cos_soleil, -1.0, 1.0));
	// le halo : chaud et très large, il réchauffe tout ce côté du ciel
	float halo = pow(max(cos_soleil, 0.0), 6.0) * 0.35 + pow(max(cos_soleil, 0.0), 60.0) * 0.6;
	c += couleur_soleil * halo * force_halo * (LIGHT0_ENABLED ? 1.0 : 0.0);

	// ── Les nuages ─────────────────────────────────────────────────────────
	if (!AT_CUBEMAP_PASS && h > 0.0) {
		// On projette la direction sur un plafond plat : les nuages
		// rétrécissent vers l'horizon, comme un vrai plafond nuageux.
		vec2 p = dir.xz / (h + 0.12) * echelle_nuages;
		p += VENT_DIRECTION * TIME * vitesse_nuages * 10.0;
		float d = densite_nuage(p);
		// bord doux mais lisible (pas de dégradé gazeux)
		float masque = smoothstep(0.0, 0.07, d);
		// éclairage du nuage : on compare la densité un peu plus loin vers le
		// soleil. Plus dense là-bas = ce côté-ci est dans l'ombre du nuage.
		vec2 vers_soleil_plan = normalize(vers_soleil.xz + vec2(0.0001));
		float d2 = densite_nuage(p + vers_soleil_plan * 0.12);
		float ombre = smoothstep(-0.02, 0.18, d2 - d + 0.06);
		vec3 coeur = mix(nuage_clair, nuage_ombre, ombre * 0.75);
		// liseré doré sur les bords tournés vers le soleil
		float bord = 1.0 - smoothstep(0.0, 0.14, d);
		coeur = mix(coeur, nuage_dore, bord * 0.6 * (1.0 - ombre));
		// les nuages s'effacent dans la brume de l'horizon
		float fondu = smoothstep(0.02, 0.22, h);
		c = mix(c, coeur, masque * fondu * 0.95);
	}

	// ── Le disque du soleil, devant les nuages fins ────────────────────────
	float disque = 1.0 - smoothstep(taille_soleil * 0.7, taille_soleil, angle);
	c = mix(c, couleur_soleil * 3.0, disque * (LIGHT0_ENABLED ? 1.0 : 0.0));

	COLOR = c * energie;
}
