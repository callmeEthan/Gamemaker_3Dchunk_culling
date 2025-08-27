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

#region BUFFER GRID FUNC
function buffer_grid(type, w, h) constructor {
	self.type=type;
	width = w;
	height = h;
	sizeof=buffer_sizeof(type);
	if type=buffer_u8 {var b_type = buffer_fast} else {var b_type = buffer_fixed}
	data=buffer_create(w*h*sizeof, b_type, sizeof);
	if data=-1 {log("buffer grid create failed!", "error")}
	buffer_seek(data, buffer_seek_start, 0)
	return self;
	
	static set = function(x,y,value)
	{
		if x>=width || y>=height return false
		var i=width*y + x;
		buffer_poke(data, i*sizeof, type, value)
	}
	static get = function(x,y)
	{
		if x>=width || y>=height return undefined
		var i=width*y + x;
		return buffer_peek(data, i*sizeof, type)
	}
	static seek = function(x,y)
	{
		if x>=width || y>=height return false
		var i=width*y + x;
		buffer_seek(data, buffer_seek_start, i*sizeof)
		return true
	}
	static read = function()
	{
		return buffer_read(data, type);
	}
}

function buffer_grid_destroy(buff) {
	buffer_delete(buff.data)
	delete buff
}
function buffer_grid_get(buff, x, y) {return buff.get(x,y)}
function buffer_grid_set(buff, x, y, value) {return buff.set(x,y,value)}
function buffer_grid_width(buff) {return buff.width}
function buffer_grid_height(buff) {return buff.height}
function buffer_grid_clear(buff, value)
{
	buffer_seek(buff.data, buffer_seek_start, 0);
	var s = buff.width*buff.height;
	buffer_fill(buff.data, 0, buff.type, value, buffer_get_size(buff.data));
	/*	for(var i=0; i<s; i++)
	{
		buffer_write(buff.data, buff.type, value)
	}*/
}
function buffer_grid_get_mean(buff, x1, y1, x2, y2)
{
	var sum = 0;
	var val = 0;
	for(var i=x1; i<x2; i++)
	for(var j=y1; j<y2; j++)
	{
		var v = buff.get(i, j);
		if is_undefined(v) continue;
		val += v;
		sum++;
	}
	return val/sum;
}

function grid_to_buffer_grid(buff,grid) {
	var w=ds_grid_width(grid);
	var h=ds_grid_height(grid);
	buffer_grid_resize(buff, w, h);
	for(var xx=0;xx<w;xx++) {
	for(var yy=0;yy<h;yy++) {
		var v=grid[# xx,yy];
		if !is_real(v) {v=0;log("Warning, found string converting from grid to buffer","warning")}
		buffer_grid_set(buff, xx, yy, v);
	}}
	return true
}

function buffer_grid_to_grid(buff) {
	var w=buffer_grid_width(buff);
	var h=buffer_grid_height(buff);
	var temp=ds_grid_create(w,h);
	for(var xx=0;xx<w;xx++) {
	for(var yy=0;yy<h;yy++) {
		temp[# xx,yy]=buffer_grid_get(buff, xx, yy);
	}}
	return temp;
}

function buffer_grid_resize(buff, w, h) {
	if buff.type=buffer_u8 {var b_type = buffer_fast} else {var b_type = buffer_fixed}
	var temp=buffer_create(w*h*buff.sizeof, b_type, buff.sizeof);
	for(var yy=0;yy<h;yy++) {
	for(var xx=0;xx<w;xx++) {
		var v=0;
		if xx<buff.width && yy<buff.height
		{
			v=buff.get(xx,yy);
		}
		var i=w*yy + xx;
		buffer_poke(temp, i*buff.sizeof, buff.type, v);
	}}
	buffer_delete(buff.data);
	buff.data = temp;
	buff.width = w;
	buff.height = h;
}

function buffer_grid_set_grid_region(buff, source, x1, y1, x2, y2, xpos, ypos) {
	var data=source.data;
	if source==buff {
		if source.type=buffer_u8 {var b_type = buffer_fast} else {var b_type = buffer_fixed}
		var s=buffer_get_size(source.data);
		data=buffer_create(s, b_type, source.sizeof);
		buffer_copy(source.data, 0, s, data, 0);
		}
	
	var w=min(xpos+(x2-x1),buffer_grid_width(buff))
	var h=min(ypos+(y2-y1),buffer_grid_height(buff))
	var yi=y1,val;
	for(var yy=ypos;yy<h;yy++) {
	var xi=x1;
	for(var xx=xpos;xx<w;xx++) {
		
		if xi<source.width || yi<source.height
		{
			var i=source.width*yi + xi;
			val = buffer_peek(data, i*source.sizeof, source.type)
		} else {
			val=0
		}
		if is_undefined(val) val=0;
		//log("buffer_grid_set("+string(buff)+","+string(xx)+","+string(yy)+","+string(val))
		buffer_grid_set(buff, xx, yy, val);
		xi+=1;
	}
	yi+=1;
	}
	
	if source==buff buffer_delete(data);
}

function buffer_grid_copy(buff,source) {
	if source.type=buffer_u8 {var b_type = buffer_fast} else {var b_type = buffer_fixed}
	var s=buffer_get_size(source.data);
	var data=buffer_create(s, b_type, source.sizeof);
	buffer_copy(source.data, 0, s, data, 0);
	buffer_delete(buff.data)
	buff.data	= data
	buff.width	= source.width
	buff.height	= source.height
	buff.sizeof	= source.sizeof
	buff.type	= source.type
}
#endregion	