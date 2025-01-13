// Source: https://github.com/fuzhenn/frustum-intersects/tree/master

function frustum_intersectsBox(xmin, ymin, zmin, xmax, ymax, zmax) {
	var planes = frustum_setPlanes.planes
    for (var i = 0; i < 6; i++) {
        var plane = planes[i];
        // corner at max distance
        var xx = (plane[0] > 0 ? xmax : xmin);
        var yy = (plane[1] > 0 ? ymax : ymin);
        var zz = (plane[2] > 0 ? zmax : zmin);

        if (frustum_distanceToPoint(plane, xx, yy, zz) < 0) {
            return false;
        }
    }
    return true;
}

function frustum_intersectsSphere(x, y, z, radius) {
	var planes = frustum_setPlanes.planes
    var negRadius = -radius;
    for (var i = 0; i < 6; i++) {
        var distance = frustum_distanceToPoint(planes[i], x, y, z);
        if (distance < negRadius) {
            return false;
        }
    }
    return true;
}

function frustum_distanceToPoint(plane, xx, yy, zz) {
    return plane[0] * xx + plane[1] * yy + plane[2] * zz + plane[3];
}


function frustum_setPlanes(matrix){
	static planes = [[],[],[],[],[],[]];
	
    //explanation: https://gamedev.stackexchange.com/questions/156743/finding-the-normals-of-the-planes-of-a-view-frustum
    var me = matrix;
    var me0 = me[0], me1 = me[1], me2 = me[2], me3 = me[3];
    var me4 = me[4], me5 = me[5], me6 = me[6], me7 = me[7];
    var me8 = me[8], me9 = me[9], me10 = me[10], me11 = me[11];
    var me12 = me[12], me13 = me[13], me14 = me[14], me15 = me[15];

    //right
    frustum_setComponents(planes[0], me3 - me0, me7 - me4, me11 - me8, me15 - me12);
    //left
    frustum_setComponents(planes[1], me3 + me0, me7 + me4, me11 + me8, me15 + me12);
    //bottom
    frustum_setComponents(planes[2], me3 + me1, me7 + me5, me11 + me9, me15 + me13);
    //top
    frustum_setComponents(planes[3], me3 - me1, me7 - me5, me11 - me9, me15 - me13);
    //z-far
    frustum_setComponents(planes[4], me3 - me2, me7 - me6, me11 - me10, me15 - me14);
    //z-near
    frustum_setComponents(planes[5], me3 + me2, me7 + me6, me11 + me10, me15 + me14);
}

function frustum_setComponents(out, x, y, z, w) {
    var inverseNormalLength = 1 / sqrt(x * x + y * y + z * z);
    out[@0] = x * inverseNormalLength;
    out[@1] = y * inverseNormalLength;
    out[@2] = z * inverseNormalLength;
    out[@3] = w * inverseNormalLength;
    return out;
}