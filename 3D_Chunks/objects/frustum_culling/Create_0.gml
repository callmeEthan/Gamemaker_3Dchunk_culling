mouse_sensitivity = 0.1

surface = -1;

chunk = new chunk_vbuffer();
var mbuff = build_box_mbuffer([0,0,0], [1,1,1])
for(var j = 50; j<=4000; j+=50)
{
	for(var i = 50; i<=4000; i+=50)
	{
		var xx = i + random(10)*choose(1,-1);
		var yy = j + random(10)*choose(1,-1);
		var zz = 0;
		var w = random(15)+10;
		var h = random(15)+10;
		var z = random(30)+10;
	
		chunk.add_model(xx,yy,0, mbuff, matrix_build(xx, yy, zz, 0,0,0, w, h, z));
		chunk.add_model(xx,yy,1, mbuff, matrix_build(xx, yy, zz, 0,0,0, w, h, z));
		chunk.add_model(xx,yy,2, mbuff, matrix_build(xx, yy, zz, 0,0,0, w, h, z));
	}
}
chunk.update_queue()
global.debug=false
show_debug_overlay(true, false)