surface = -1;
width = main.width;
height = main.height;
appSurfW = width;
appSurfH = height;
surface_resize(application_surface, appSurfW, appSurfH);

#region Initialize camera
near = 6;
far = 10000;
aspect_ratio = appSurfW / appSurfH
world_render=true
xyAngle = 50;
zAngle = 45;
camDist = 10
camTimer = 0;
viewMat = array_create(16);
projMat = array_create(16);
fov = 50;	zoom = 1;	camUp = [0,0,1];
xFrom = camDist * dcos(xyAngle) * dcos(zAngle);
yFrom = camDist * dsin(xyAngle) * dcos(zAngle);
zFrom = camDist * dsin(zAngle);
xTo = 256
yTo = 256
zTo = 0
camera=cam_create(1, 60, appSurfW / appSurfH, near, far);
camera_3d_enable(true);
cam_set_projmat(camera, 60, appSurfW / appSurfH, near, far);
cam_set_viewmat(camera, xFrom, yFrom, zFrom, 0, 0, 0, 0, 0, 1);
application_surface_draw_enable(false);
#endregion

//vertex_format_init()
globalvar primitiveFormat;
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_texcoord();
primitiveFormat = vertex_format_end();

var mbuff = load_obj_to_buffer("Sphere.obj")
skySphere = vertex_create_buffer_from_buffer(mbuff, global.stdFormat);
buffer_delete(mbuff);


surfVbuff = vertex_create_buffer();
vertex_begin(surfVbuff, global.stdFormat);
vertex_standard(surfVbuff, -1,1,0, 0,0,0, 0,0);
vertex_standard(surfVbuff, 3,1,0, 0,0,0, 2,0);
vertex_standard(surfVbuff, -1,-3,0, 0,0,0, 0,2);
vertex_end(surfVbuff);
vertex_freeze(surfVbuff);

light_angle = 128;
light_direction = [lengthdir_x(1, light_angle), lengthdir_y(1, light_angle), -1]
circle_precision = 24;
alarm[0] = 1

render_surface = function(surface, viewmat = viewMat, projmat = projMat)
{
	surface_set_target(surface)
	matrix_set(matrix_view, viewmat)
	matrix_set(matrix_projection, projmat)
	draw_clear_alpha(c_black, 1);
	event_user(0);
	surface_reset_target()
}
window_resize = function()
{
	surface_resize(application_surface, main.width, main.height);
	if surface_exists(surface) surface_resize(surface, appSurfW, appSurfH)
	aspect_ratio = appSurfW/appSurfH;
}
pos_debug = []

instance_create_depth(0,0,0, frustum_culling)
