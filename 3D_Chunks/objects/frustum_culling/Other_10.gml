/*
for(var i=0; i<size; i++)
{
	var sh = shape[i]
	visibility[@i] = frustum_intersectsBox(sh[0], sh[1], sh[2], sh[3], sh[4], sh[5])
}

for(var i=0; i<size; i++)
{
	if !visibility[i] continue
	vertex_submit(vbuff[i], pr_trianglelist, -1)
}
*/

//chunk_render(chunk, 1000, renderer.viewMat, renderer.projMat)

var sh = sh_debugging;
shader_set(sh);
shader_set_uniform_f_array(shader_get_uniform(sh, "u_LightForward"), renderer.light_direction);

var lod = -1
if keyboard_check(vk_numpad0) lod=0
if keyboard_check(vk_numpad1) lod=1
if keyboard_check(vk_numpad2) lod=2
global.count = 0;

if lod==-1
{
	chunk_render(chunk, 10000, renderer.viewMat, renderer.projMat)
	/*
	var scale = chunk.scale*4;
	var xx = (floor(renderer.xFrom/scale)*scale)/scale;
	var yy = (floor(renderer.yFrom/scale)*scale)/scale;
	for(var i=yy-1; i<=yy+1; i++)
	{
		chunk.render(xx-1, xx+2, i, 2, -1)
	}
	*/
} else {
	var data = chunk.vdata[lod];
	var s = array_length(data)
	for(var i=0; i<s; i++)
	{
		var vbuff = data[i];
		if vbuff==0 continue;
		vertex_submit(vbuff, pr_trianglelist, -1)
		global.count++;
	}
}

debug_overlay("vBuffer count: "+string(global.count), 1)