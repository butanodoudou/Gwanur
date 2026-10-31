// shaders/toon.gdshader — matériau toon opaque, faces arrière cachées.
// Le corps est dans toon_materiau.gdshaderinc ; les variantes ne changent
// que le render_mode et les #define.
shader_type spatial;
render_mode cull_back;

#include "res://shaders/toon_materiau.gdshaderinc"
