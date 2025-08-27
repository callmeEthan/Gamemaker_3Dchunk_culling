function chunk_vbuffer(subdivide=2, size=128) constructor
{
	self.scale = size;
	self.subdivide = subdivide;
	data = []; lod_dist = [];
	vdata = [];
	pdata = [];
	buffer_func = chunk_read_buffer_std;
	width = 0;
	height = 0;
	zmin = 0; zmax = 512
	queue = ds_map_create();
	
	for(var i=0; i<subdivide; i++)
	{
		array_push(data, ds_grid_create(1,1));
		array_push(vdata, []);
		array_push(pdata, []);
		var dist = self.scale;
		repeat(i) dist=dist*2;
		array_insert(lod_dist, 0, dist*2);
	}
	log("Chunk vbuffer initialized, LOD distance: "+string(lod_dist))
	
	static add_model = function(x,y,lod,mbuffer, matrix=matrix_build_identity(), UV=[0,0,1,1])
	{
		var chunk = get_chunk(x,y,lod,true);
		if is_undefined(chunk) return false
		var dat =
		{
			mbuff: mbuffer,
			matrix: matrix,
			UV: UV,
		}
		array_push(chunk, dat);
		
		var scale = self.scale;
		for(var i=0; i<subdivide; i++)
		{
			var yy = (floor(y/scale)*scale)/scale;
			var hash = string(i)+","+string(yy)
			ds_map_set(queue, hash, [i, yy])
			scale=scale*2;
		}
	}
	static update_queue = function()
	{
		var s = ds_map_size(queue);
		var k = ds_map_find_first(queue);
		for(var i=0; i<s; i++)
		{
			log("updating "+string(k))
			var upd = queue[? k];
			update_vbuffer(0, upd[1], upd[0])
			k = ds_map_find_next(queue, k);
		}
		ds_map_clear(queue)
		log("Updated "+string(s)+" vertex buffer in queue")
	}
	static chunk_pos = function(x,y,lod)
	{
		var scale = self.scale;
		repeat(lod) scale=scale*2;
		var xx = floor(x/scale)*scale;
		var yy = floor(y/scale)*scale;
		return [xx/scale,yy/scale]
	}
	static get_chunk = function(x,y,lod,write=false)
	{
		if lod>=subdivide return undefined;
		var data = self.data[lod];
		var w=ds_grid_width(data), h=ds_grid_height(data);
		
		var pos=chunk_pos(x,y,lod)	// GET PROPER CHUNK POSITION (snap to grid)
		var temp=undefined;
		if (pos[0]<w && pos[1]<h) {var temp=data[# pos[0], pos[1]]}
		if !is_undefined(temp) && temp!=0 return temp;
		
		if !write return undefined;
		if w<(pos[0]+1) || h<(pos[1]+1) {ds_grid_resize(data, max(pos[0]+1,w), max(pos[1]+1,h))}
		var temp = [];
		data[# pos[0], pos[1]] = temp;
		
		var scale = self.scale;
		repeat(lod) scale=scale*2;
		width = max(width, (pos[0]+1)*scale);
		height = max(height, (pos[1]+1)*scale);
		return temp;
	}
	static update_vbuffer = function(x,y, lod)
	{
		var vbuff = vdata[lod];
		var positions = pdata[lod];
		
		var yy = y;
		
		if yy+1>array_length(vbuff)
		{
			array_resize(vbuff, yy+1)
			array_resize(positions, yy+1);
		};
		if positions[yy]==0 positions[@yy]=[];
		if vbuff[@yy]!=0 vertex_delete_buffer(vbuff[yy]);
		vbuff[@yy] = vertex_create_buffer();
		
		var pos = positions[yy]
		var buff = vbuff[yy]
		vertex_begin(buff, global.stdFormat);
		
		var data = self.data[lod];
		var w = ds_grid_width(data);
		var seek = 0;
		for(var i=0; i<w; i++)
		{
			var model = data[# i, yy]
			if model==0 {pos[@i] = seek;continue;}
			seek = buffer_func(model, buff, seek);
			pos[@i] = seek;
		}
		
		 if seek==0 {vertex_delete_buffer(vbuff[yy]); vbuff[yy]=0; return false}
		
		vertex_end(buff);	vertex_freeze(buff)
		log("vertex updated y="+string(yy)+" LOD="+string(lod)+" size: "+string(seek))
		lod++
	}
	static render = function(xfrom=-1, xto, y, lod, texture)
	{
		
		if keyboard_check(vk_numpad7) && lod=0 exit;
		if keyboard_check(vk_numpad8) && lod=1 exit;
		if keyboard_check(vk_numpad9) && lod=2 exit;
		static u_Colour = shader_get_uniform(sh_debugging, "u_Colour")
		var col;
		switch(lod)
		{
			case 0: col=c_lime; break
			case 1: col=c_green; break
			case 2: col=c_yellow; break
			case 3: col=c_orange; break
			case 4: col=c_red; break
		}
		shader_set_uniform_f(u_Colour, color_get_red(col)/255, color_get_green(col)/255, color_get_blue(col)/255)
		
		var scale = self.scale;
		repeat(lod) scale=scale*2;
		draw_floor(xfrom*scale, y*scale, (xto)*scale, (y+1)*scale);
				
		var vbuff = vdata[lod];
		var positions = pdata[lod];
		
		var x0=0, x1=0, seek0=0, seek1=0;
		if y<0 return;
		if y>=array_length(vbuff) return;
		var buff = vbuff[@y]
		if buff==0 return;
		
		
		var pos = positions[y]
		var w = array_length(pos);
		
		var seek0, seek1;
		xto = clamp(xto, 0, w);
		xfrom = clamp(xfrom, 0, w);
		if xto=xfrom return;
		seek1 = pos[xto-1]
		if xfrom=0 seek0=0 else seek0=pos[xfrom-1]
		if seek0>=seek1 exit;
		vertex_submit_ext(buff, pr_trianglelist, texture, seek0, seek1-seek0);
		global.count++
	}
}

function chunk_read_buffer_std(data, vbuff, pos)
{
	var s = array_length(data)
	for(var i=0; i<s; i++)
	{
		var model = data[i]
		var mbuff = model.mbuff;
		var size = buffer_get_size(mbuff) / mBuffStdBytesPerVert;
		buffer_seek(mbuff, buffer_seek_start, 0)
		for(var vi=0; vi<size; vi++)
		{
			//Vertex position
			var vx = buffer_read(mbuff, buffer_f32)
			var vy = buffer_read(mbuff, buffer_f32)
			var vz = buffer_read(mbuff, buffer_f32)
	
			//Vertex normal
			var nx = buffer_read(mbuff, buffer_f32)
			var ny = buffer_read(mbuff, buffer_f32)
			var nz = buffer_read(mbuff, buffer_f32)
	
			//Vertex UVs
			var u = buffer_read(mbuff, buffer_f32)
			var v = buffer_read(mbuff, buffer_f32)
			
			//Vertex color
			var cr = buffer_read(mbuff, buffer_u8);
			var cg = buffer_read(mbuff, buffer_u8);
			var cb = buffer_read(mbuff, buffer_u8);
			var ca = buffer_read(mbuff, buffer_u8);
			
			u = lerp(model.UV[0], model.UV[2], u);
			v = lerp(model.UV[1], model.UV[3], v);
			var vert = matrix_transform_vertex(model.matrix, vx, vy, vz, 1);
			var norm = matrix_transform_vertex(model.matrix, nx, ny, nz, 0);
			
			vertex_position_3d(vbuff, vert[0], vert[1], vert[2]);
			vertex_normal(vbuff, norm[0], norm[1], norm[2]);
			vertex_texcoord(vbuff, u, v);
			vertex_color(vbuff, make_color_rgb(cr, cg, cb), ca/255);
			pos++;
		}
	}
	return pos;
}

function chunk_render(chunk, radius, texture=-1)
{
	// Get camera position
	var _x = renderer.xFrom;
	var _y = renderer.yFrom;
	var _z = renderer.zFrom;
	
	// get radius area
	var scale = chunk.scale;
	repeat(chunk.subdivide-1) scale=scale*2;
	var lod_dist = chunk.lod_dist;
	
	var xfrom = clamp(_x-radius, 0, chunk.width-scale);
	var yfrom = clamp(_y-radius, 0, chunk.height-scale);
	var xto = clamp(_x+radius, scale, chunk.width);
	var yto = clamp(_y+radius, scale, chunk.height);
	
	// snap to grid position
	xfrom = (floor(xfrom/scale)*scale)/scale;
	yfrom = (floor(yfrom/scale)*scale)/scale;
	xto = (ceil(xto/scale)*scale)/scale;
	yto = (ceil(yto/scale)*scale)/scale;
		
	static render = function(chunk, x1, x2, y, scale, lod, subdivide, cx, cy, cz, lod_dist, func, texture)
	{
		static draw = function(chunk, x1, x2, y, scale, lod, texture)
		{
			lod=(chunk.subdivide-lod)-1
			chunk.render(x1, x2, y, lod, -1)
		}
		
		var radius = lod_dist[lod];
		if lod>0 
		{
			for(var i=x1; i<x2; i++) if !frustum_intersectsBox(i*scale, y*scale, chunk.zmin, (i+1)*scale, (y+1)*scale, chunk.zmax) x1++ else break;
			for(var i=x2-1; i>x1; i--) if !frustum_intersectsBox(i*scale, y*scale, chunk.zmin, (i+1)*scale, (y+1)*scale, chunk.zmax) x2-- else break;
		}
		if x1>=x2 return;
		
		// Already reached max subdivide, render and exit
		if lod+1=subdivide {draw(chunk, x1, x2, y, scale, lod, texture); return}
		
		// Check distance for subdivide
		if point_distance_3d(cx, cy, cz, cx, (y+0.5)*scale, 0)>=radius {draw(chunk, x1, x2, y, scale, lod, texture); return}
		
		// Further subdivide
		var _x1=-1, _x2=-1
		for(var i=x1; i<x2; i++)
		{
			var dist = point_distance_3d((i+0.5)*scale, (y+0.5)*scale, 0, cx, cy, cz);
			if dist<radius {_x1=i; break}
		}
		for(var i=x2; i>x1; i--)
		{
			var dist = point_distance_3d((i+0.5)*scale, (y+0.5)*scale, 0, cx, cy, cz);
			if dist<radius {_x2=i+1; break}
		}
		if _x1<0 || _x1>=_x2{draw(chunk, x1, x2, y, scale, lod, texture); return}
		if _x2<0 _x2=x2
		
		func(chunk, _x1*2, _x2*2, y*2, scale/2, lod+1, subdivide, cx, cy, cz, lod_dist, func, texture);
		func(chunk, _x1*2, _x2*2, y*2+1, scale/2, lod+1, subdivide, cx, cy, cz, lod_dist, func, texture);
		if _x1>x1 draw(chunk, x1, _x1, y, scale, lod, texture)
		if x2>_x2 draw(chunk, _x2, x2, y, scale, lod, texture)
		return;
	}

	// Frustum check on lowest lod
	for(var j=yfrom; j<yto; j++)
	{
		debug_overlay(0,j)
		if !frustum_intersectsBox(xfrom, j*scale, chunk.zmin, xto*scale, (j+1)*scale, chunk.zmax) continue;
		var x1 = xfrom, x2 = xto;
		for(var i=x1; i<x2; i++) if !frustum_intersectsBox(i*scale, j*scale, chunk.zmin, (i+1)*scale, (j+1)*scale, chunk.zmax) x1++ else break;
		for(var i=x2-1; i>x1; i--) if !frustum_intersectsBox(i*scale, j*scale, chunk.zmin, (i+1)*scale, (j+1)*scale, chunk.zmax) x2-- else break;
		if x1>=x2 continue;
		render(chunk, x1, x2, j, scale, 0, chunk.subdivide, _x, _y, _z, lod_dist, render)
	}
}
function chunk_render_area(chunk, radius=-1, texture=-1)
{
	// Perform frustum check and render visible chunk only, with lod models;
	// if there's multiple chunk structure with similar scale, you can set radius=-1 to skip the frustum check and render directly using previous data;
	
	// Get camera position
	var _x = renderer.xFrom;
	var _y = renderer.yFrom;
	var _z = renderer.zFrom;
	
	// get radius area
	var scale = chunk.scale;
	repeat(chunk.subdivide-1) scale=scale*2;
	var lod_dist = chunk.lod_dist;
	
	var xfrom = clamp(_x-radius, 0, chunk.width-scale);
	var yfrom = clamp(_y-radius, 0, chunk.height-scale);
	var xto = clamp(_x+radius, scale, chunk.width);
	var yto = clamp(_y+radius, scale, chunk.height);
	
	// snap to grid position
	xfrom = (floor(xfrom/scale)*scale)/scale;
	yfrom = (floor(yfrom/scale)*scale)/scale;
	xto = (ceil(xto/scale)*scale)/scale;
	yto = (ceil(yto/scale)*scale)/scale;
			
	static render = function(chunk, x1, x2, y, scale, lod, subdivide, cx, cy, cz, lod_dist, func, buffer)
	{
		static draw = function(chunk, x1, x2, y, scale, lod, buffer)
		{
			lod=(chunk.subdivide-lod)-1
			//buffer_write(buffer, buffer_u8, lod);
			//buffer_writes(buffer, buffer_u16, x1, x2, y);
			chunk.render(x1, x2, y, lod, -1)
		}
		
		var radius = lod_dist[lod];
		// Already reached max subdivide, render and exit
		if lod+1=subdivide {draw(chunk, x1, x2, y, scale, lod, buffer); return}
		
		// Check distance for subdivide
		if point_distance_3d(cx, cy, cz, cx, (y+0.5)*scale, 0)>=radius {draw(chunk, x1, x2, y, scale, lod, buffer); return}
		
		// Further subdivide
		var _x1=-1, _x2=-1
		for(var i=x1; i<x2; i++)
		{
			var dist = point_distance_3d((i+0.5)*scale, (y+0.5)*scale, 0, cx, cy, cz);
			if dist<radius {_x1=i; break}
		}
		for(var i=x2; i>x1; i--)
		{
			var dist = point_distance_3d((i+0.5)*scale, (y+0.5)*scale, 0, cx, cy, cz);
			if dist<radius {_x2=i+1; break}
		}
		if _x1<0 || _x1>=_x2{draw(chunk, x1, x2, y, scale, lod, buffer); return}
		if _x2<0 _x2=x2
		
		func(chunk, _x1*2, _x2*2, y*2, scale/2, lod+1, subdivide, cx, cy, cz, lod_dist, func, buffer);
		func(chunk, _x1*2, _x2*2, y*2+1, scale/2, lod+1, subdivide, cx, cy, cz, lod_dist, func, buffer);
		if _x1>x1 draw(chunk, x1, _x1, y, scale, lod, buffer)
		if x2>_x2 draw(chunk, _x2, x2, y, scale, lod, buffer)
		
		return;
	}

	// Frustum check on lowest lod
	for(var j=yfrom; j<yto; j++)
	{
		render(chunk, xfrom, xto, j, scale, 0, chunk.subdivide, _x, _y, _z, lod_dist, render, -1)
	}
	
}

function chunk_render_impostor(chunk, radius=-1, texture=-1)
{	
	// Perform frustum check and render visible chunk only, with lod models;
	// if there's multiple chunk structure with similar scale, you can set radius=-1 to skip the frustum check and render directly using previous data;
	
	// Get camera position
	var _x = renderer.xFrom;
	var _y = renderer.yFrom;
	var _z = renderer.zFrom;
	
	// get radius area
	var scale = chunk.scale;
	repeat(chunk.subdivide-1) scale=scale*2;
	var lod_dist = chunk.lod_dist;
	
	var xfrom = clamp(_x-radius, 0, chunk.width-scale);
	var yfrom = clamp(_y-radius, 0, chunk.height-scale);
	var xto = clamp(_x+radius, scale, chunk.width);
	var yto = clamp(_y+radius, scale, chunk.height);
	
	// snap to grid position
	xfrom = (floor(xfrom/scale)*scale)/scale;
	yfrom = (floor(yfrom/scale)*scale)/scale;
	xto = (ceil(xto/scale)*scale)/scale;
	yto = (ceil(yto/scale)*scale)/scale;
			
	static render = function(chunk, x1, x2, y, scale, lod, subdivide, cx, cy, cz, lod_dist, func, buffer)
	{
		static draw = function(chunk, x1, x2, y, scale, lod, buffer)
		{
			lod=(chunk.subdivide-lod)-1
			//buffer_write(buffer, buffer_u8, lod);
			//buffer_writes(buffer, buffer_u16, x1, x2, y);
			chunk.render(x1, x2, y, lod, -1)
		}
		
		var radius = lod_dist[lod];
		// Already reached max subdivide, render and exit
		if lod+1=subdivide {draw(chunk, x1, x2, y, scale, lod, buffer); return}
		
		// Check distance for subdivide
		if point_distance_3d(cx, cy, cz, cx, (y+0.5)*scale, 0)>=radius {draw(chunk, x1, x2, y, scale, lod, buffer); return}
		
		// Further subdivide
		var _x1=-1, _x2=-1
		for(var i=x1; i<x2; i++)
		{
			var dist = point_distance_3d((i+0.5)*scale, (y+0.5)*scale, 0, cx, cy, cz);
			if dist<radius {_x1=i; break}
		}
		for(var i=x2; i>x1; i--)
		{
			var dist = point_distance_3d((i+0.5)*scale, (y+0.5)*scale, 0, cx, cy, cz);
			if dist<radius {_x2=i+1; break}
		}
		if _x1<0 || _x1>=_x2{draw(chunk, x1, x2, y, scale, lod, buffer); return}
		if _x2<0 _x2=x2
		
		if _x1>x1 draw(chunk, x1, _x1, y, scale, lod, buffer)
		if x2>_x2 draw(chunk, _x2, x2, y, scale, lod, buffer)
		
		return;
	}

	// Frustum check on lowest lod
	for(var j=yfrom; j<yto; j++)
	{
		render(chunk, xfrom, xto, j, scale, 0, chunk.subdivide, _x, _y, _z, lod_dist, render, -1)
	}
}

function vertex_buffer_grid(width=16, height=16) constructor
{
	self.width = width;
	self.height = height;
	vbuffer = new dynamic_vertex_buffer(global.stdFormat);
	grid = new buffer_grid(buffer_u32, width, height);
	flag = new buffer_grid(buffer_u8, width, height);
	chunks = ds_grid_create(width,height);
	checking = -1;
	
	curr_index = 0;
	model_map = ds_map_create();
	model_grid = ds_grid_create(width, height);
		
	static destroy = function()	// destroy all data
	{
		vbuffer.destroy(); vbuffer=0
		buffer_delete(grid.data); grid=false
		buffer_delete(flag.data); flag=false
	}
	static mbuffer_add = function(mbuffer, x, y, byte=-1)	// add model buffer to grid position
	{		
		// Get vertex buffer offset
		var p=width*y + x, o;
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		p=grid.read();
		
		// Add data into vbuffer
		var _delta = vbuffer.insert_mbuffer(mbuffer, p, 0, byte);
				
		// rewrite vertex offset;
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		var len = width*height;
		for(var i=p; i<len; i++)
		{
			var v = buffer_peek(grid.data, i*grid.sizeof, grid.type);
			buffer_write(grid.data, grid.type, v+_delta)
		}
		var _chunk = model_grid[# x,y];
		if _chunk==0
		{
			model_grid[# x,y]=[_delta]
		} else {
			var i = array_length(_chunk);
			if (i==0) {array_push(_chunk, _delta)} else {array_push(_chunk, _chunk[i-1]+_delta)}
		}
		model_map[? curr_index] = [width*y+x, i];
		
		// swap vertex buffer;
		var temp = vbuffer;
		vbuffer = vswap; vswap = temp;
		temp = curr_index; curr_index++
		return temp;
	}
	static model_remove = function(index)
	{
		// Get chunk pos
		var _entry = model_map[? index];
		var _x = _entry[0] mod width;
		var _y = floor(_entry[0]/width);
		var _chunk = model_grid[# _x, _y];
		var _i = _entry[1]
		
		// Get data length
		var _o = 0;
		if _i>0 _o=_chunk[_i-1];
		var _size = _chunk[_i] - _o;
				
		// Remove from vbuffer
		var p=width*_y + _x;
		if p>0 {buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof); _o+=grid.read();}
		vbuffer.remove(_o, _size);
		
		// Shift data position
		var s = array_length(_chunk)
		for(var i=_i; i<s; i++)
		{
			_chunk[@i]-=_size;
		}
		array_delete(_chunk, _i, 1);
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		var len = width*height;
		for(var i=p; i<len; i++)
		{
			var v = buffer_peek(grid.data, i*grid.sizeof, grid.type);
			buffer_write(grid.data, grid.type, v-_size);
		}
		
	}
	static clear_chunk = function(x,y)
	{
		var p=width*_y + _x, o;
		if p>0 {buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof); o=grid.read();}
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof)
		var _size = grid.read() - o;
		vbuffer.remove(o, _size);
		
		// Shift data position
		model_grid[# x, y] = 0;
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		var len = width*height;
		for(var i=p; i<len; i++)
		{
			var v = buffer_peek(grid.data, i*grid.sizeof, grid.type);
			buffer_write(grid.data, grid.type, v-_size);
		}
		
	}
	static submit = function(xfrom, xto, y, texture)	// submit range of vertex buffer in grid (must be on the same row)
	{
		var _from, _to;
		xto = clamp(xto, 0, width-1);
		xfrom = clamp(xfrom, 0, min(width-1, xto));
		
		var p=width*y + xfrom, o;
		if p==0 {o=0} else {buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof); o=grid.read()}
		_from = o;
		
		p=width*y + xto;
		_to = buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		
		//vertex_submit_ext(vbuff, pr_trianglelist, texture, _from, _to-_from);
		vbuffer.submit(texture, _from, _to-_from);
	}
		
	static vbuffer_get_pos = function(x, y)
	{
		var p=width*y + x;
		if p==0 return 0;
		buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof);
		return grid.read();
	}
	static vbuffer_get_size = function(x,y)
	{
		var p=width*y + x, o;
		if p==0 {o=0} else {buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof); o=grid.read()}
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		return grid.read()-o;
	}
	static vbuffer_get_range = function(xfrom, xto, y)
	{
		static range = array_create(2);
		xto = clamp(xto, 0, width-1);
		xfrom = clamp(xfrom, 0, min(width-1, xto));
		
		var p=width*y + xfrom, o;
		if p==0 {o=0} else {buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof); o=grid.read()}
		range[@0] = o;
		
		p=width*y + xto;
		range[@1] = buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		
		return range;
	}
}
enum vbuffer_job
{
	reserve,
	add_mbuffer,
	add_vbuffer
}
function dynamic_vertex_buffer(format=global.stdFormat, BytesPerVert=36) constructor
{
	// A flexible vertex buffer allow you to insert, remove data directly on the gpu (without editting buffer and push to gpu every time)
	// Queue action to minimize copy bandwidth as much as possible
	vbuffer = vertex_create_buffer();
	vswap = vertex_create_buffer();
	size = 0; size_real = 0;
	jobs = ds_list_create(); upd=false
	vertex_begin(vbuffer, format); vertex_end(vbuffer);
	vertex_begin(vswap, format); vertex_end(vswap);
	self.BytesPerVert = BytesPerVert;
	
	static destroy = function()
	{
		// clean up memory
		vertex_delete_buffer(vbuffer);
		vertex_delete_buffer(vswap);
		ds_list_destroy(jobs);
	}
	static insert_mbuffer = function(mbuffer, pos, offset=0, byte=-1)
	{
		// Insert a model buffer data into the vertex buffer, all proceeding data will be shifted forward
		// Return number of vertice added
		if ds_list_size(jobs)=0 and size_real>0 ds_list_add(jobs, [vbuffer_job.reserve, 0, 0, size_real]);
		
		if byte<0 byte = buffer_get_size(mbuffer);
		if frac(byte/BytesPerVert)>0 {byte=floor(byte/BytesPerVert)*BytesPerVert}
		if frac(offset/BytesPerVert)>0 {offset=floor(offset/BytesPerVert)*BytesPerVert}
		if byte==0 return 0;
		
		var s = ds_list_size(jobs)
		for(var i=0; i<s; i++)
		{
			var _job = jobs[| i];
			var _size = _job[3] - _job[2];
			if (_job[1]<pos and _job[1]+_size>pos)
			{
				var _offset = pos - _job[1];
				var _copy = variable_clone(_job);
				_copy[@3] = _job[2]+_offset;
				ds_list_add(jobs, _copy);
				
				_copy = variable_clone(_job);
				_copy[@1] = pos;
				_copy[@2] = _job[2]+_offset;
				ds_list_add(jobs, _copy);
				ds_list_delete(jobs, i);
				break;
			}
		}
		
		var s = ds_list_size(jobs)
		for(var i=0; i<s; i++)
		{
			var _job = jobs[| i];
			if _job[1]>=pos {_job[1]+=byte/BytesPerVert}
		}
		ds_list_add(jobs, [vbuffer_job.add_mbuffer, pos, offset/BytesPerVert, byte/BytesPerVert, mbuffer]);
		upd=true; size+=byte/BytesPerVert;
		return byte/BytesPerVert;
	}
	static remove = function(pos, size)
	{
		// Remove data partially from vertex buffer, all proceeding data will be shifted backward
		var _len = (pos+size)-self.size; size-=_len
		if size<=0 return true;
		if ds_list_size(jobs)=0 && size_real>0 ds_list_add(jobs, [vbuffer_job.reserve, 0, 0, size_real]);
		var s = ds_list_size(jobs)
		for(var i=0; i<s; i++)
		{
			var _job = jobs[| i];
			var _size = _job[3] - _job[2];
			if (_job[1]>=pos and _job[1]+_size<=pos+size)
			{
				ds_list_delete(jobs, i); i--
			}
			else if (_job[1]<pos and _job[1]+_size>pos)
			{
				var _len = (_job[1]+size)-pos;
				_job[3]-=_len;
			}
			else if (_job[1]<pos+size and _job[1]+_size>pos+size)
			{
				var _len = (pos+size)-_job[1]
				_job[1]+=_len;
				_job[2]+=_len;
			}
			else if (_job[1]<pos and _job[1]+size>pos+size)
			{
				var _copy = variable_clone(_job);
				var _len = (_job[1]+size)-pos;
				_copy[@3]-=_len;
				ds_list_add(jobs, _copy);
				
				_copy = variable_clone(_job);
				var _len = (pos+size)-_job[1]
				_copy[@1] += _len;
				_copy[@2] += _len;
				ds_list_add(jobs, _copy);
				ds_list_delete(jobs, i); i--;
				break;
			}
		}
		var s = ds_list_size(jobs)
		for(var i=0; i<s; i++)
		{
			var _job = jobs[| i];
			if _job[1]>=pos {_job[1]-=size}
		}
		upd=true; self.size-=size;
		return size;
	}
	static update = function()
	{
		// Perform vertex data modification (automatically executed in submit() function)
		var s = ds_list_size(jobs);
		for(var i=0; i<s; i++)
		{
			var _job = jobs[| i];
			var _len = (_job[3]-_job[2]);
			switch(_job[0])
			{
					case vbuffer_job.reserve:
						vertex_update_buffer_from_vertex(vswap, _job[1], vbuffer, _job[2], _len);
						break
					case vbuffer_job.add_mbuffer:
						vertex_update_buffer_from_buffer(vswap, _job[1], _job[4], _job[2]*BytesPerVert, _len*BytesPerVert);
						break
					case vbuffer_job.add_vbuffer:
						vertex_update_buffer_from_vertex(vswap, _job[1], _job[4], _job[2], _len);
						break
			}
		}
		ds_list_clear(jobs);
		size_real = size;	upd=false;
		var temp = vbuffer;
		vbuffer = vswap; vswap = temp;
		return true;
	}
	static submit = function(texture=-1, offset=0, num=0, prim=pr_trianglelist)
	{
		// Update vertex buffer if there's any change, and submit to GPU for rendering
		if upd update();
		if num<=0 num=size_real;
		vertex_submit_ext(vbuffer, prim, texture, offset, num);
	}
}
globalvar mbuffer_handler;
mbuffer_handler = new model_buffer_handler();
function model_buffer_handler() constructor
{
	// Handle importing 3d model from external file (expect standard format)
	// And process it for game (transformation)
	static cache = ds_map_create();
	target = -1;
	mbuffer = buffer_create(1024, buffer_grow, 1);
	mbuffer_import = import_format_standard;
	mbuffer_export = export_format_standard;
	size = 0;
	limit = 100; // memory limit (in Mb), tries to delete older model to free memory
	BytesPerVert = 36;	// standard format
	_x=0; _y=0; _z=0; _nx=0; _ny=0; _nz=0; _u=0; _v=0; _r=0; _g=0; _b=0; _a=0;

	// Load model for processing (will keep already loaded model)
	static load_standard = function(file)
	{
		// Load external model (standard format)
		var n = filename_name(file);
		target = cache[? n];
		if is_undefined(target)
		{
			if file_exists(file) {log("<c_red>ERROR</>: model file not found ("+string(file)+")")}
			target = buffer_load(file);
			cache[? n] = target;
		}
		mbuffer_import = import_format_standard;
		BytesPerVert = 36;
		return target;
	}
	static add_standard = function(mbuffer)
	{
		// Point to a model buffer for processing
		target = mbuffer;
		mbuffer_import = import_format_standard;
		BytesPerVert = 36;
	}
	
	// Transform model loaded with import_* function
	static transform_matrix = function(matrix)
	{
		var pos, size=0;
		if target=-1 log("<c_red>Error</>: Model not loaded")
		var s = buffer_get_size(target)/BytesPerVert;
		buffer_seek(target, buffer_seek_start, 0);
		buffer_seek(mbuffer, buffer_seek_start, 0);
		for(var i=0; i<s; i++)
		{
			mbuffer_import();
			
			pos = matrix_transform_vertex(matrix, _x, _y, _z, 1);
			_x = pos[0]; _y = pos[1]; _z = pos[2];
			pos = matrix_transform_vertex(matrix, _x, _y, _z, 0);
			_nx = pos[0]; _ny = pos[1]; _nz = pos[2];
			
			mbuffer_export(_x, _y, _z, _nx, _ny, _nz, _u, _v, _r, _g, _b, _a);
		}
	}
	static transform = function(x, y, z, quaternion, xscale, yscale, zscale)
	{
		var pos = array_create(3), size=0;
		if target=-1 log("<c_red>Error</>: Model not loaded")
		var s = buffer_get_size(target)/BytesPerVert;
		buffer_seek(target, buffer_seek_start, 0);
		buffer_seek(mbuffer, buffer_seek_start, 0);
		for(var i=0; i<s; i++)
		{
			mbuffer_import();
			
			quaternion_transform_vector(quaternion, _x*xscale, _y*yscale, _z*zscale, pos);
			_x = pos[0]+x;
			_y = pos[1]+y;
			_z = pos[2]+z;
			quaternion_transform_vector(quaternion, _nx, _ny, _nz, pos);
			_nx = pos[0];
			_ny = pos[1];
			_nz = pos[2];
			
			mbuffer_export(_x, _y, _z, _nx, _ny, _nz, _u, _v, _r, _g, _b, _a);
		}
	}
	
	// Ignore these
	static import_format_standard = function()
	{
		_x = buffer_read(target, buffer_f32);
		_y = buffer_read(target, buffer_f32);
		_z = buffer_read(target, buffer_f32);
		_nx = buffer_read(target, buffer_f32);
		_ny = buffer_read(target, buffer_f32);
		_nz = buffer_read(target, buffer_f32);
		_u = buffer_read(target, buffer_f32);
		_v = buffer_read(target, buffer_f32);
		_r = buffer_read(target, buffer_u8);
		_g = buffer_read(target, buffer_u8);
		_b = buffer_read(target, buffer_u8);
		_a = buffer_read(target, buffer_u8);
	}
	static export_format_standard = function(_x,_y,_z, _nx=0,_ny=0,_nz=1, _u=0,_v=0, _r=1,_g=1,_b=1,_a=1)
	{
		buffer_write(mbuffer, buffer_f32, _x);
		buffer_write(mbuffer, buffer_f32, _y);
		buffer_write(mbuffer, buffer_f32, _z);
		
		buffer_write(mbuffer, buffer_f32, _nx);
		buffer_write(mbuffer, buffer_f32, _ny);
		buffer_write(mbuffer, buffer_f32, _nz);
		
		buffer_write(mbuffer, buffer_f32, _u);
		buffer_write(mbuffer, buffer_f32, _v);
		
		buffer_write(mbuffer, buffer_f32, _r);
		buffer_write(mbuffer, buffer_f32, _g);
		buffer_write(mbuffer, buffer_f32, _b);
		buffer_write(mbuffer, buffer_f32, _z);
		size+=36;
	}
}
/*
function vertex_buffer_grid(width=16, height=16) constructor
{
	self.width = width;
	self.height = height;
	vbuffer = new dynamic_vertex_buffer(global.stdFormat);
	grid = new buffer_grid(buffer_u32, width, height);
	flag = new buffer_grid(buffer_u8, width, height);
	chunks = ds_grid_create(width,height);
	checking = -1;
	
	curr_index = 0;
	model_map = ds_map_create();
	model_grid = ds_grid_create(width, height);
	
	
	static destroy = function()	// destroy all data
	{
		vbuffer.destroy(); vbuffer=0
		buffer_delete(grid.data); grid=false
		buffer_delete(flag.data); flag=false
	}
	static mbuffer_set = function(mbuffer, x, y, byte=-1)	// override model buffer at grid position
	{
		if byte<0 byte = buffer_get_size(mbuffer);
		if frac(byte)>0 {byte=floor(byte/BytesPerVert)*BytesPerVert}
		// Get vertex buffer offset
		var p=width*y + x, o;
		if p==0 o=0 else {buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof); o=grid.read()/BytesPerVert}
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		p=grid.read()/BytesPerVert;
		var _size = p-o;
		
		// reserve space for new buffer
		vertex_update_buffer_from_vertex(vswap, 0, vbuffer, 0, o);
		vertex_update_buffer_from_vertex(vswap, o+byte/BytesPerVert, vbuffer, p, size-p);
		
		// insert new vertex buffer from buffer
		vertex_update_buffer_from_buffer(vswap, o, mbuffer, 0, byte);
		var _delta = (byte/BytesPerVert) - _size;
		size += _delta;
		
		// rewrite vertex offset;
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		var len = width*height;
		for(var i=(width*y+x); i<len; i++)
		{
			var v = buffer_peek(grid.data, i*grid.sizeof, grid.type);
			buffer_write(grid.data, grid.type, v+_delta)
		}
		
		// swap vertex buffer;
		var temp = vbuffer;
		vbuffer = vswap; vswap = temp;
		return true;
	}
	static mbuffer_add = function(mbuffer, x, y, byte=-1)	// add model buffer to grid position
	{
		if byte<0 byte = buffer_get_size(mbuffer);
		if frac(byte/BytesPerVert)>0 {byte=floor(byte/BytesPerVert)*BytesPerVert}
		
		// Get vertex buffer offset
		var p=width*y + x, o;
		if p==0 o=0 else {buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof); o=grid.read()/BytesPerVert}
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		p=grid.read()/BytesPerVert;
		
		// reserve space for new buffer
		vertex_update_buffer_from_vertex(vswap, 0, vbuffer, 0, o);
		vertex_update_buffer_from_vertex(vswap, p+byte/BytesPerVert, vbuffer, p, size-p);
		size += _delta;
		
		// insert new vertex buffer from buffer
		vertex_update_buffer_from_buffer(vswap, p, mbuffer, 0, byte);
		var _delta = (byte/BytesPerVert);
		
		// rewrite vertex offset;
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		var len = width*height;
		for(var i=(width*y+x); i<len; i++)
		{
			var v = buffer_peek(grid.data, i*grid.sizeof, grid.type);
			buffer_write(grid.data, grid.type, v+_delta)
		}
		var _chunk = model_grid[# x,y];
		var i = array_length(_chunk);
		if (i==0) {chunk[i]=byte/BytesPerVert} else {chunk[i]=chunk[i-1]+byte/BytesPerVert}
		model_map[? curr_index] = [width*y+x,1]
//var _x = i mod width;
//var _y = floor(i/width);
		
		// swap vertex buffer;
		var temp = vbuffer;
		vbuffer = vswap; vswap = temp;
		temp = curr_index; curr_index++
		return temp;
	}
	static submit = function(xfrom, xto, y, texture)	// submit range of vertex buffer in grid (must be on the same row)
	{
		var _from, _to;
		xto = clamp(xto, 0, width-1);
		xfrom = clamp(xfrom, 0, min(width-1, xto));
		
		var p=width*y + xfrom, o;
		if p==0 {o=0} else {buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof); o=grid.read()}
		_from = o;
		
		p=width*y + xto;
		_to = buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		
		vertex_submit_ext(vbuff, pr_trianglelist, texture, _from, _to-_from);
	}
		
	static vbuffer_get_pos = function(x, y)
	{
		var p=width*y + x;
		if p==0 return 0;
		buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof);
		return grid.read();
	}
	static vbuffer_get_size = function(x,y)
	{
		var p=width*y + x, o;
		if p==0 {o=0} else {buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof); o=grid.read()}
		buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		return grid.read()-o;
	}
	static vbuffer_get_range = function(xfrom, xto, y)
	{
		static range = array_create(2);
		xto = clamp(xto, 0, width-1);
		xfrom = clamp(xfrom, 0, min(width-1, xto));
		
		var p=width*y + xfrom, o;
		if p==0 {o=0} else {buffer_seek(grid.data, buffer_seek_start, (p-1)*grid.sizeof); o=grid.read()}
		range[@0] = o;
		
		p=width*y + xto;
		range[@1] = buffer_seek(grid.data, buffer_seek_start, p*grid.sizeof);
		
		return range;
	}
}