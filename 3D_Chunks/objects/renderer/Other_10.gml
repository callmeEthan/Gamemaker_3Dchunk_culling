gpu_set_tex_filter(false);
gpu_set_tex_repeat(true);
gpu_set_ztestenable(true);
gpu_set_zwriteenable(true);

matrix_set(matrix_world, matrix_build(xFrom,yFrom,zFrom, 0,0,0, 100, 100, 100))
gpu_set_cullmode(cull_noculling)
gpu_set_ztestenable(false)
gpu_set_zwriteenable(false)
vertex_submit(skySphere, pr_trianglelist, sprite_get_texture(texSky, 0))
gpu_set_cullmode(cull_counterclockwise)
gpu_set_ztestenable(true)
gpu_set_zwriteenable(true)

matrix_set(matrix_world, matrix_build(0,0,0, 0,0,0, 1,1,1))
with(frustum_culling) event_user(0)
shader_reset()

var s = array_length(pos_debug)
for(var i=0; i<s; i++)
{
	matrix_set(matrix_world, pos_debug[i])
	vertex_submit(skySphere, pr_trianglelist, -1)
}
matrix_set(matrix_world, matrix_build_identity())
gpu_set_ztestenable(true);
gpu_set_zwriteenable(true);