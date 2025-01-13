
	zAngle = clamp(zAngle, -89.9, 89.9); 
	xFrom = xTo + camDist * dcos(xyAngle) * dcos(zAngle);
	yFrom = yTo + camDist * dsin(xyAngle) * dcos(zAngle);
	zFrom = zTo + camDist * dsin(zAngle);
	cam_set_projmat(camera, fov*zoom, aspect_ratio, near, far);
	cam_set_viewmat(camera, xFrom, yFrom, zFrom, xTo, yTo, zTo, 0, 0, 1);
	main.current_near = near;
	main.current_far = far;