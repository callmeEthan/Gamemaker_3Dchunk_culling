if !surface_exists(surface) surface = surface_create(appSurfW,appSurfH)
viewMat = camera_get_view_mat(camera);
projMat = camera_get_proj_mat(camera);