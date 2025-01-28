function chunk_vbuffer(subdivide=3, size=128) constructor
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
			chunk.render(x1, x2, y, lod, texture)
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
