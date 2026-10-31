// shaders/toon_feuillage_scissor.gdshader — cartes de feuilles : la texture
// découpe la forme (alpha scissor, pas de tri ni de transparence coûteuse).
shader_type spatial;
render_mode cull_disabled;

#define FEUILLAGE
#define ALPHA_SCISSOR
#include "res://shaders/toon_materiau.gdshaderinc"
