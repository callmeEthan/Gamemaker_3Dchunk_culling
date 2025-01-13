if virtual_cursor
{
	//if !window_mouse_get_locked() window_mouse_set_locked(true)
	mouse_xspeed = window_mouse_get_delta_x()
	mouse_yspeed = window_mouse_get_delta_y()
	mousex += mouse_xspeed;
	mousey += mouse_yspeed;
	mouse_xprevious = mousex;
	mouse_yprevious = mousey;
	/*
	if (!mouse_check_button(mb_any) && !is_fullscreen) switch (virtual_cursor_unbound)
	{
		case -1:
			virtual_cursor_unbound = false
			exit
		case false:
			if !point_in_rectangle(mousex, mousey, 0,0,width,height)
			{
				alarm[5]=room_speed*.1
				virtual_cursor_unbound = true
				window_mouse_set_locked(false);
				display_mouse_set(window_x+mousex, window_y+mousey);
			} else {
			}
			exit;
		case true:
			if point_in_rectangle(display_mouse_get_x(), display_mouse_get_y(), window_x, window_y, window_x+window_w, window_y+window_h)
			{
				mousex = display_mouse_get_x()-window_x;
				mousey = display_mouse_get_y()-window_y;
				virtual_cursor_unbound = -1
				window_mouse_set_locked(true);
			}
			exit;
	}*/
	mousex = clamp(mousex, 0, width)
	mousey = clamp(mousey, 0, height)
} else {
	mousex = display_mouse_get_x()-window_x;
	mousey = display_mouse_get_y()-window_y
	mouse_xspeed = mousex-mouse_xprevious;
	mouse_yspeed = mousey-mouse_yprevious;
	mouse_xprevious = mousex;
	mouse_yprevious = mousey;
}