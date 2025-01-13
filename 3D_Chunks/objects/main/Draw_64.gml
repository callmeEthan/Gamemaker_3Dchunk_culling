matrix_set(matrix_world, matrix_build_identity());
var s=ds_list_size(debug_txt),v;
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
var fs = 0.4
var ls = fontscale[Font_default] * fs
for(var i=0; i<s; i++)
{
	v=debug_txt[| i]
	if (v=0) continue;
	draw_text_transformed(10, i*ls, v, fs, fs, 0)
}