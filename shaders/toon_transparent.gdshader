// shaders/toon_transparent.gdshader — vraie transparence (verre, voiles).
// Plus coûteux (tri, pas de prépasse de profondeur) : réservé aux matériaux
// qui étaient déjà transparents à l origine.
shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;

#define ALPHA_BLEND
#include "res://shaders/toon_materiau.gdshaderinc"
