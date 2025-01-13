#macro memory_object_UI 20
#macro Font_default font1
#macro input_up 0
#macro input_down 1
#macro input_left 2
#macro input_right 3
#macro input_enter 4
#macro input_escape 5
#macro input_shift 6
#macro input_device_keyboard 0
#macro input_device_mouse 1
#macro completed 4

globalvar keyboard_context;
keyboard_context = ds_map_create();
keyboard_context[? vk_control] = "Ctrl"
keyboard_context[? vk_shift] = "Shift"
keyboard_context[? vk_alt] = "Alt"
width = max(window_get_width(),128);
height = max(window_get_height(),128);

surface=-1;
virtual_cursor = true;	window_mouse_set_locked(true)
virtual_cursor_unbound = false
mousex = 0;
mousey = 0;
mb_previous=noone;
mb_xprevious=0;
mb_yprevious=0;
mb_istap=false
mb_isdouble=false;
mb_ishold=false;	hold_time=1*room_speed
mouse_xprevious=0;
mouse_yprevious=0;
mouse_xspeed=0;
mouse_yspeed=0;
mb_xpressed=0;
mb_ypressed=0;

enum main_color
{
	blank,
	dark,
	background,
	highlight,
	accent,
	error,
	warning,
	confirm,
	lock,
	light,
}

global.color[main_color.blank]=make_color_rgb(254,254,254);
global.color[main_color.dark]=make_color_rgb(40,40,40);
global.color[main_color.background]=make_color_rgb(190,190,190);
global.color[main_color.highlight]=make_color_rgb(10,180,255);
global.color[main_color.accent]=make_color_rgb(92,193,221);
global.color[main_color.error]= make_color_rgb(255, 34, 0);
global.color[main_color.warning]= make_color_rgb(255, 207, 33);
global.color[main_color.confirm]=make_color_rgb(24, 217, 114);
global.color[main_color.lock]=make_color_rgb(128, 122, 117);

touch_min=26;
cursor_flash=0.5;
date_format_str="d/m/Y";
draw_set_font(Font_default);
fontscale[Font_default]=string_height("D");
debug_txt=ds_list_create();

cmd_init()
title = "Ethan's Animation Tool (Demo)"
window_set_caption(title)
render = instance_create_depth(0,0,0,renderer)

window_x = width;
window_y = height;
window_w = 0;
window_h = 0;
is_fullscreen = window_get_fullscreen()