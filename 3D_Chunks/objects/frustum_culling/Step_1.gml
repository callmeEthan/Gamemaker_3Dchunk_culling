var xx = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var yy = keyboard_check(ord("S")) - keyboard_check(ord("W"));
var zz = keyboard_check(vk_space) - keyboard_check(vk_control);
var dist = max(abs(xx), abs(yy))*2;
if keyboard_check(vk_shift) dist*=4
var dir = point_direction(0,0,xx,yy);
xx = lengthdir_x(dist, dir);
yy = lengthdir_y(dist, dir);

renderer.xyAngle += main.mouse_xspeed * mouse_sensitivity;
renderer.zAngle += main.mouse_yspeed * mouse_sensitivity;
renderer.xTo = renderer.xTo+lengthdir_x(dist, dir-renderer.xyAngle+90);
renderer.yTo = renderer.yTo+lengthdir_y(dist, dir-renderer.xyAngle+90);
renderer.zTo = renderer.zTo+zz*4