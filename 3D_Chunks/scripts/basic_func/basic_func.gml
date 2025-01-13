// DEMO
// These function are for demo to work.
function cmd_init() {	
	global.temp_list=ds_list_create();
	global.temp_map=ds_map_create();
	global.temp_grid=ds_grid_create(1,1);
	global.temp_buffer=buffer_create(128, buffer_grow, 1)
	
	global.script_ids=ds_map_create();
	global.object_ids=ds_map_create();
	global.memory_ids=ds_map_create();
	global.variables=ds_map_create();
	var s=global.script_ids
	var o=global.object_ids
}
function mouse_get_button_pressed() {
	if mouse_check_button_pressed(mb_right) {return(mb_right)}
	else if mouse_check_button_pressed(mb_left) {return(mb_left)}
	else if mouse_check_button_pressed(mb_middle) {return(mb_middle)}
	else if mouse_check_button_pressed(mb_side1) {return(mb_side1)}
	else if mouse_check_button_pressed(mb_side2) {return(mb_side2)}
	return(mb_none)
	}
function mouse_get_button_released() {
	if mouse_check_button_released(mb_right) {return(mb_right)}
	else if mouse_check_button_released(mb_left) {return(mb_left)}
	else if mouse_check_button_released(mb_middle) {return(mb_middle)}
	else if mouse_check_button_released(mb_side1) {return(mb_side1)}
	else if mouse_check_button_released(mb_side2) {return(mb_side2)}
	return(mb_none)
	}
function frametime()
{
	return main.frameend - ((get_timer()/1000)-main.framestart);
}
function debug_overlay(text, index=-1) {
	var out = false;
	if index<0 {
		ds_list_add(main.debug_txt, string(text));
		return true;
	} else {
		var s = ds_list_size(main.debug_txt);
		ds_list_set(main.debug_txt, index, string(text));
		if s<=index return true else return false
	}
}
function debug_overlay_clear(text, index=-1) {ds_list_clear(main.debug_txt)}
function log(text,type=""){
	text=string(text)
	show_debug_message(string(text))
}

function buffer_writes(buffer, type, value) {for (var i = 2; i < argument_count; i ++) buffer_write(buffer, type, argument[i])}
