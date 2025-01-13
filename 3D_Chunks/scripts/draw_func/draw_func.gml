vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_normal();
vertex_format_add_texcoord();
vertex_format_add_colour();
global.stdFormat = vertex_format_end();
#macro mBuffStdBytesPerVert 36

function cam_create(argument0, argument1, argument2, argument3, argument4) {
	/*
		Creates a camera for the given view
		If view is -1, the camera is not assigned to any views. This is useful for for example shadow maps.

		Script created by TheSnidr
		www.thesnidr.com
	*/
	var viewInd = argument0;
	var FOV = argument1;
	var aspect = argument2;
	var near = argument3;
	var far = argument4;

	var camera = camera_create();
	camera_set_proj_mat(camera, matrix_build_projection_perspective_fov(-FOV, -aspect, near, far));
	camera_set_view_mat(camera, matrix_build_identity());

	if viewInd >= 0
	{
		view_enabled = true;
		view_set_visible(viewInd, true);
		view_set_camera(viewInd, camera);
	}

	return camera;
}
/// @description cam_set_projmat(camera, FOV, aspect, near, far)
/// @param camera
/// @param FOV
/// @param aspect
/// @param near
/// @param far
function cam_set_projmat(camera, FOV, aspect, near, far) {
	/*
	Creates a camera for the given view

	Script created by TheSnidr
	www.thesnidr.com
	*/
	camera_set_proj_mat(camera, matrix_build_projection_perspective_fov(-FOV, -aspect, near, far));
}

/// @description cam_set_viewmat(camera, xFrom, yFrom, zFrom, xTarget, yTarget, zTarget, xUp, yUp, zUp)
/// @param camera
/// @param xFrom
/// @param yFrom
/// @param zFrom
/// @param xTarget
/// @param yTarget
/// @param zTarget
/// @param xUp
/// @param yUp
/// @param zUp
function cam_set_viewmat(argument0, argument1, argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9) {
	camera = argument0
	camera_set_view_mat(camera, matrix_build_lookat(argument1, argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9));
}

function camera_3d_enable(enable=true) {
	if enable {
		//Turns on the z-buffer
		gpu_set_zwriteenable(true);
		gpu_set_ztestenable(true);
		gpu_set_cullmode(cull_counterclockwise);
		gpu_set_texrepeat(true);
	} else {
		gpu_set_zwriteenable(false);
		gpu_set_ztestenable(false);
		gpu_set_cullmode(cull_noculling);
		gpu_set_texrepeat(false);
		}
}
	
function vertex_standard(vertex, x, y, z, nx=0, ny=0, nz=1, u=0, v=0, color=c_white, alpha=1)
{
	vertex_position_3d(vertex,x, y, z);
	vertex_normal(vertex, nx, ny, nz);
	vertex_texcoord(vertex, u, v);
	vertex_color(vertex, color, alpha);
}

function mbuff_add_vertex(mBuff, vx, vy, vz, nx=0, ny=0, nz=1, u, v, col, alpha) {
	//Vertex position
	buffer_writes(mBuff, buffer_f32, vx, vy, vz);

	//Vertex normal
	buffer_writes(mBuff, buffer_f32, nx, ny, nz);

	//Vertex UVs
	buffer_writes(mBuff, buffer_f32, u, v);

	//Colors
	buffer_write(mBuff, buffer_u8, color_get_red(col));
	buffer_write(mBuff, buffer_u8, color_get_green(col));
	buffer_write(mBuff, buffer_u8, color_get_blue(col));
	if alpha<=1 alpha *= 255;
	buffer_write(mBuff, buffer_u8, alpha);
}

function matrix_view_pos(view_mat) {
var _x = -view_mat[0] * view_mat[12] - view_mat[1] * view_mat[13] - view_mat[2] * view_mat[14]; 
var _y = -view_mat[4] * view_mat[12] - view_mat[5] * view_mat[13] - view_mat[6] * view_mat[14];
var _z = -view_mat[8] * view_mat[12] - view_mat[9] * view_mat[13] - view_mat[10] * view_mat[14];
return [_x,_y,_z]
}

function load_obj_to_buffer(filename, ds_list=-1) {
	/*
	Loads an .obj model into a buffer
	add ds_list to write model info to
	*/
	var vBuff, n_index, t_index, v_index, file, i, j, str, type, vertString, triNum, temp_faces, modelArray;
	file = file_text_open_read(filename);
	if file == -1{log("Failed to load model " + string(filename)); return -1;}
	log("Script <c_orange>spart_load_obj</>: Loading obj file " + string(filename));
	
	//Model info output
	if !(ds_list<0) {
		var xmin=0, xmax=0, ymin=0, ymax=0, zmin=0, zmax=0;
		}

	//Create the necessary lists
	var vx, vy, vz, nx, ny, nz, tx, ty, fl, v, n, t, f;
	vx = ds_list_create(); vx[| 0] = 0;
	vy = ds_list_create(); vy[| 0] = 0;
	vz = ds_list_create(); vz[| 0] = 0;
	nx = ds_list_create(); nx[| 0] = 0;
	ny = ds_list_create(); ny[| 0] = 0;
	nz = ds_list_create(); nz[| 0] = 0;
	tx = ds_list_create(); tx[| 0] = 0;
	ty = ds_list_create(); ty[| 0] = 0;
	fl = ds_list_create();

	//Read .obj as textfile
	while !file_text_eof(file)
	{
		str = string_replace_all(file_text_read_string(file),"  "," ");
		type = string_copy(str, 1, 2);
		str = string_delete(str, 1, string_pos(" ", str));
		//Different types of information in the .obj starts with different headers
		switch type
		{
			//Load vertex positions
			case "v ":
				ds_list_add(vx, real(string_copy(str, 1, string_pos(" ", str))));
		        str = string_delete(str, 1, string_pos(" ", str));     
				ds_list_add(vy, real(string_copy(str, 1, string_pos(" ", str))));  
				ds_list_add(vz, real(string_delete(str, 1, string_pos(" ", str))));
				break;
			//Load vertex normals
			case "vn":
				ds_list_add(nx, real(string_copy(str, 1, string_pos(" ", str))));
		        str = string_delete(str, 1, string_pos(" ", str)); 
				ds_list_add(ny, real(string_copy(str, 1, string_pos(" ", str))));
				ds_list_add(nz, real(string_delete(str, 1, string_pos(" ", str))));
				break;
			//Load vertex texture coordinates
			case "vt":
				var u = real(string_copy(str, 1, string_pos(" ", str)));
				var v = real(string_delete(str, 1, string_pos(" ", str)))
				ds_list_add(tx, clamp(u,0,1));
				ds_list_add(ty, clamp(v,0,1));
				break;
			//Load faces
			case "f ":
		        if (string_char_at(str, string_length(str)) == " "){str = string_copy(str, 0, string_length(str) - 1);}
		        triNum = string_count(" ", str);
		        for (i = 0; i < triNum; i ++){
		            vertString[i] = string_copy(str, 1, string_pos(" ", str));
		            str = string_delete(str, 1, string_pos(" ", str));}
				vertString[i--] = str;
		        while i--{for (j = 2; j >= 0; j --){
					ds_list_add(fl, vertString[(i + j) * (j > 0)]);}}
				break;
			}
	    file_text_readln(file);
	}
	file_text_close(file);

	//Loop through the loaded information and generate a model
	var vertCol = c_white;
	var bytesPerVert = 3 * 4 + 3 * 4 + 2 * 4 + 4 * 1;
	var size = ds_list_size(fl);
	var mbuff = buffer_create(size * bytesPerVert, buffer_fixed, 1);
	for (var f = 0; f < size; f ++)
	{
		vertString = ds_list_find_value(fl, f);
		v = 0; n = 0; t = 0;
		//If the vertex contains a position, texture coordinate and normal
		if string_count("/", vertString) == 2 and string_count("//", vertString) == 0{
			v = real(string_copy(vertString, 1, string_pos("/", vertString) - 1));
			vertString = string_delete(vertString, 1, string_pos("/", vertString));
			t = real(string_copy(vertString, 1, string_pos("/", vertString) - 1));
			n = real(string_delete(vertString, 1, string_pos("/", vertString)));}
		//If the vertex contains a position and a texture coordinate
		else if string_count("/", vertString) == 1{
			v = real(string_copy(vertString, 1, string_pos("/", vertString) - 1));
			t = real(string_delete(vertString, 1, string_pos("/", vertString)));}
		//If the vertex only contains a position
		else if (string_count("/", vertString) == 0){
			v = real(vertString);}
		//If the vertex contains a position and normal
		else if string_count("//", vertString) == 1{
			vertString = string_replace(vertString, "//", "/");
			v = real(string_copy(vertString, 1, string_pos("/", vertString) - 1));
			n = real(string_delete(vertString, 1, string_pos("/", vertString)));}
		if v < 0{v = -v;}
		if t < 0{t = -t;}
		if n < 0{n = -n;}
			
		//Add the vertex to the model buffer
		var v_x = vx[| v]
		var v_y = vy[| v]
		var v_z = vz[| v]
		buffer_write(mbuff, buffer_f32, v_x);
		buffer_write(mbuff, buffer_f32, vz[| v]);
		buffer_write(mbuff, buffer_f32, vy[| v]);
	
		buffer_write(mbuff, buffer_f32, nx[| n]);
		buffer_write(mbuff, buffer_f32, nz[| n]);
		buffer_write(mbuff, buffer_f32, ny[| n]);
	
		buffer_write(mbuff, buffer_f32, tx[| t]);
		buffer_write(mbuff, buffer_f32, 1-ty[| t]);
	
		buffer_write(mbuff, buffer_u8, 255);
		buffer_write(mbuff, buffer_u8, 255);
		buffer_write(mbuff, buffer_u8, 255);
		buffer_write(mbuff, buffer_u8, 255);
		
		if !(ds_list<0) {
			if v_x > xmax xmax = v_x;
			if v_x < xmin xmin = v_x;
			if v_y > ymax ymax = v_y;
			if v_y < ymin ymin = v_y;
			if v_z > zmax zmax = v_z;
			if v_z < zmin zmin = v_z;
		}
	}
	ds_list_destroy(fl);
	ds_list_destroy(vx);
	ds_list_destroy(vy);
	ds_list_destroy(vz);
	ds_list_destroy(nx);
	ds_list_destroy(ny);
	ds_list_destroy(nz);
	ds_list_destroy(tx);
	ds_list_destroy(ty);
	if !(ds_list<0) {
		ds_list_add(ds_list, xmin)
		ds_list_add(ds_list, xmax)
		ds_list_add(ds_list, ymin)
		ds_list_add(ds_list, ymax)
		ds_list_add(ds_list, zmin)
		ds_list_add(ds_list, zmax)
	}
	log("Script <c_lime>spart_load_obj</>: Successfully loaded obj " + string(filename));
	return mbuff;
}
	
function draw_floor(x1, y1, x2, y2)
{
	static texture = sprite_get_texture(spr_color_2, 4)

	var col = c_gray
	var vBuff = vertex_create_buffer();
	vertex_begin(vBuff, global.stdFormat);
	vertex_standard(vBuff, x1,	y1,	0,		0,0,1,		0,0,		col,1) 
	vertex_standard(vBuff, x2,	y1,	0,		0,0,1,		1,0,		col,1) 
	vertex_standard(vBuff, x1,	y2,	0,		0,0,1,		0,1,		col,1) 

	vertex_standard(vBuff, x2,	y1,	0,		0,0,1,		1,0,		col,1) 
	vertex_standard(vBuff, x2,	y2,	0,		0,0,1,		1,1,		col,1) 
	vertex_standard(vBuff, x1,	y2, 0,		0,0,1,		0,1,		col,1) 
	
	vertex_end(vBuff);	vertex_freeze(vBuff)
	vertex_submit(vBuff,  pr_trianglelist, texture);
	vertex_delete_buffer(vBuff)
}
	
function build_box_vbuffer(p1, p2)
{
var vBuff = vertex_create_buffer(); vBoneshape_box = vBuff;
var r0 = p1, r1=p2
vertex_begin(vBuff, global.stdFormat);
vertex_standard(vBuff, r0[0],	r0[1],	r0[2],		-1,0,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r0[0],	r0[1],	r1[2],		-1,0,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r0[0],	r1[1],	r0[2],		-1,0,0,		0,1,		c_white,1) 

vertex_standard(vBuff, r0[0],	r0[1],	r1[2],		-1,0,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r0[0],	r1[1],	r1[2],		-1,0,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r0[0],	r1[1],	r0[2],		-1,0,0,		0,1,		c_white,1) 

//+x
vertex_standard(vBuff, r1[0],	r0[1],	r0[2],		1,0,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r1[1],	r0[2],		1,0,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r0[1],	r1[2],		1,0,0,		0,1,		c_white,1) 

vertex_standard(vBuff, r1[0],	r0[1],	r1[2],		1,0,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r1[1],	r0[2],		1,0,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r1[1],	r1[2],		1,0,0,		0,1,		c_white,1) 

//-y
vertex_standard(vBuff, r0[0],	r0[1],	r0[2],		0,-1,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r0[1],	r0[2],		0,-1,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r0[0],	r0[1],	r1[2],		0,-1,0,		0,1,		c_white,1) 

vertex_standard(vBuff, r0[0],	r0[1],	r1[2],		0,-1,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r0[1],	r0[2],		0,-1,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r0[1],	r1[2],		0,-1,0,		0,1,		c_white,1) 

//+y
vertex_standard(vBuff, r0[0],	r1[1],	r0[2],		0,1,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r0[0],	r1[1],	r1[2],		0,1,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r1[1],	r0[2],		0,1,0,		0,1,		c_white,1) 

vertex_standard(vBuff, r0[0],	r1[1],	r1[2],		0,1,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r1[1],	r1[2],		0,1,0,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r1[1],	r0[2],		0,1,0,		0,1,		c_white,1) 

//-z
vertex_standard(vBuff, r0[0],	r0[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 
vertex_standard(vBuff, r0[0],	r1[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r0[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 

vertex_standard(vBuff, r0[0],	r1[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r1[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r0[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 

//+z
vertex_standard(vBuff, r0[0],	r0[1],	r1[2],		0,0,1,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r0[1],	r1[2],		0,0,1,		0,1,		c_white,1) 
vertex_standard(vBuff, r0[0],	r1[1],	r1[2],		0,0,1,		0,1,		c_white,1) 

vertex_standard(vBuff, r0[0],	r1[1],	r1[2],		0,0,1,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r0[1],	r1[2],		0,0,1,		0,1,		c_white,1) 
vertex_standard(vBuff, r1[0],	r1[1],	r1[2],		0,0,1,		0,1,		c_white,1) 
vertex_end(vBuff);	vertex_freeze(vBuff)
return vBuff
}

function build_box_mbuffer(p1, p2)
{
	var mbuff = buffer_create(mBuffStdBytesPerVert, buffer_grow, 1);
	var r0 = p1, r1=p2
	mbuff_add_vertex(mbuff, r0[0],	r0[1],	r0[2],		-1,0,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r0[0],	r0[1],	r1[2],		-1,0,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r0[0],	r1[1],	r0[2],		-1,0,0,		0,1,		c_white,1) 

	mbuff_add_vertex(mbuff, r0[0],	r0[1],	r1[2],		-1,0,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r0[0],	r1[1],	r1[2],		-1,0,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r0[0],	r1[1],	r0[2],		-1,0,0,		0,1,		c_white,1) 

	//+x
	mbuff_add_vertex(mbuff, r1[0],	r0[1],	r0[2],		1,0,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r1[1],	r0[2],		1,0,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r0[1],	r1[2],		1,0,0,		0,1,		c_white,1) 

	mbuff_add_vertex(mbuff, r1[0],	r0[1],	r1[2],		1,0,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r1[1],	r0[2],		1,0,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r1[1],	r1[2],		1,0,0,		0,1,		c_white,1) 

	//-y
	mbuff_add_vertex(mbuff, r0[0],	r0[1],	r0[2],		0,-1,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r0[1],	r0[2],		0,-1,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r0[0],	r0[1],	r1[2],		0,-1,0,		0,1,		c_white,1) 

	mbuff_add_vertex(mbuff, r0[0],	r0[1],	r1[2],		0,-1,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r0[1],	r0[2],		0,-1,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r0[1],	r1[2],		0,-1,0,		0,1,		c_white,1) 

	//+y
	mbuff_add_vertex(mbuff, r0[0],	r1[1],	r0[2],		0,1,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r0[0],	r1[1],	r1[2],		0,1,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r1[1],	r0[2],		0,1,0,		0,1,		c_white,1) 

	mbuff_add_vertex(mbuff, r0[0],	r1[1],	r1[2],		0,1,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r1[1],	r1[2],		0,1,0,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r1[1],	r0[2],		0,1,0,		0,1,		c_white,1) 

	//-z
	mbuff_add_vertex(mbuff, r0[0],	r0[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r0[0],	r1[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r0[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 

	mbuff_add_vertex(mbuff, r0[0],	r1[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r1[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r0[1],	r0[2],		0,0,-1,		0,1,		c_white,1) 

	//+z
	mbuff_add_vertex(mbuff, r0[0],	r0[1],	r1[2],		0,0,1,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r0[1],	r1[2],		0,0,1,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r0[0],	r1[1],	r1[2],		0,0,1,		0,1,		c_white,1) 

	mbuff_add_vertex(mbuff, r0[0],	r1[1],	r1[2],		0,0,1,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r0[1],	r1[2],		0,0,1,		0,1,		c_white,1) 
	mbuff_add_vertex(mbuff, r1[0],	r1[1],	r1[2],		0,0,1,		0,1,		c_white,1) 
	buffer_resize(mbuff, buffer_tell(mbuff));
	return mbuff
}
