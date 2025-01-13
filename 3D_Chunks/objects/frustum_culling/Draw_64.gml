if !surface_exists(surface) surface = surface_create(renderer.appSurfW*.3,renderer.appSurfH*.3);

surface_set_target(surface)
draw_clear_alpha(c_black, 1);

var xx = renderer.xTo+700;
var yy = renderer.yTo+700
var zz = renderer.zTo+1400
var view = matrix_build_lookat(xx, yy, zz, renderer.xTo, renderer.yTo, renderer.zTo, 0,0,1)
var proj = matrix_build_projection_perspective_fov(60, renderer.appSurfW/renderer.appSurfH, 6, 10000)
matrix_set(matrix_view, view)
matrix_set(matrix_projection, proj)

gpu_set_ztestenable(true)
gpu_set_zwriteenable(true)
matrix_set(matrix_world, matrix_build(xx, yy, zz, 0,0,0, 100, 100, 100))
gpu_set_cullmode(cull_noculling)
vertex_submit(renderer.skySphere, pr_trianglelist, sprite_get_texture(texSky, 0))
gpu_set_cullmode(cull_counterclockwise)
gpu_set_ztestenable(false)
gpu_set_zwriteenable(false)

var sh = sh_lighting;
shader_set(sh);
shader_set_uniform_f_array(shader_get_uniform(sh, "u_LightForward"), renderer.light_direction);
matrix_set(matrix_world, matrix_build(0,0,0, 0,0,0, 1,1,1))
event_user(0)
shader_reset()

surface_reset_target()

draw_surface(surface, renderer.appSurfW*.7,renderer.appSurfH*.7)
