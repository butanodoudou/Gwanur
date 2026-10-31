// shaders/toon_feuillage.gdshader — feuillage opaque : normales sphériques,
// vent, translucidité (voir toon_materiau.gdshaderinc).
shader_type spatial;
render_mode cull_disabled;

#define FEUILLAGE
#include "res://shaders/toon_materiau.gdshaderinc"
