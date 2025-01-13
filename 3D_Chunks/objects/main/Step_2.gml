
 /// @description Input check
global.input[input_up]= keyboard_check_pressed(vk_up)
global.input[input_down]= keyboard_check_pressed(vk_down)
global.input[input_left]= keyboard_check_pressed(vk_left)
global.input[input_right]= keyboard_check_pressed(vk_right)
global.input[input_enter]= keyboard_check_pressed(vk_enter)
global.input[input_escape]= keyboard_check_pressed(vk_escape)
global.input[input_shift]= keyboard_check_pressed(vk_shift)

if keyboard_check_pressed(vk_f12) {global.debug=!global.debug; show_debug_overlay(global.debug)}
//if keyboard_check_pressed(vk_f5) {game_restart()}

if mouse_check_button_pressed(mb_any) { //check double click
var mb=mouse_get_button_pressed()
var mb_x=mousex
var mb_y=mousey
alarm[1]=hold_time
alarm[2]=room_speed/3
mb_xpressed=window_mouse_get_x();
mb_ypressed=window_mouse_get_y();

if point_distance(mb_x,mb_y,mb_xprevious,mb_yprevious)<touch_min*0.5 and mb=mb_previous and alarm[0]>0 {
	mb_isdouble=true;
	mb_xprevious=-4;
	mb_yprevious=-4;
	alarm[0]=2;
	exit;
	} else {alarm[0]=room_speed/3}

mb_xprevious=mb_x;
mb_yprevious=mb_y;
mb_previous=mb;
}

if mouse_check_button_released(mb_any) and point_distance(mousex,mousey,mb_xprevious,mb_yprevious)<touch_min*0.5 {
	var mb=mouse_get_button_released()
	if mb_previous=mb and alarm[2]>0 {mb_istap=true;alarm[2]=2;}
}

if mouse_check_button_released(mb_any) or point_distance(mousex,mousey,mb_xprevious,mb_yprevious)>touch_min*0.5 {alarm[1]=-1;mb_ishold=false}
