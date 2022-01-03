extends Control

var following : bool = false
var dragging_start_position : Vector2 = Vector2.ZERO

func _on_Titlebar_gui_input(event):
	if event is InputEventMouseButton:
		if event.get_button_index() == 1:
			following = !following
			dragging_start_position = get_local_mouse_position()


# warning-ignore:unused_argument
func _process(delta):
	if following:
		OS.set_window_position(OS.window_position + get_global_mouse_position() - dragging_start_position)


func _on_Minimize_pressed() -> void:
	OS.set_window_minimized(true)


func _on_Close_pressed() -> void:
	get_tree().quit()
