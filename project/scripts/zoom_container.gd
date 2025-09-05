extends Control

var zoom := 1.0
var target_zoom := 1.0
var zoom_step := 0.1
var min_zoom := 0.2
var max_zoom := 5.0

var dragging := false
var drag_start := Vector2()

var texture_rect : TextureRect
var last_texture: Texture2D

var current_tween : Tween

@export var allow_scaling_beyond_container : bool = false

func _ready() -> void:
	texture_rect = get_child(0)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta):
	if texture_rect.texture != last_texture:
		last_texture = texture_rect.texture
		_on_texture_changed()
	

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			drag_start = get_global_mouse_position()

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_target_zoom(target_zoom + zoom_step)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_target_zoom(target_zoom - zoom_step)

	elif event is InputEventMouseMotion and dragging:
		var delta = get_global_mouse_position() - drag_start
		drag_start = get_global_mouse_position()
		move_texture(delta)
	else:
		dragging = false


func move_texture(delta: Vector2):
	if not texture_rect:
		return
	texture_rect.position += delta
	clamp_texture_position()


func get_min_zoom() -> float:
	if not texture_rect:
		return 0.1

	if not allow_scaling_beyond_container:
		var container_size = size
		var image_size = texture_rect.size
		var zoom_x = container_size.x / image_size.x
		var zoom_y = container_size.y / image_size.y
		return max(zoom_x, zoom_y)

	return min_zoom


func set_target_zoom(new_zoom: float):
	target_zoom = clamp(new_zoom, get_min_zoom(), max_zoom)

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	current_tween = get_tree().create_tween()
	current_tween.tween_method(
		apply_zoom, zoom, target_zoom, 0.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)




func apply_zoom(value: float, event_position: Vector2 = size / 2):
	zoom = value

	var prev_scale = texture_rect.scale
	texture_rect.scale = Vector2(zoom, zoom)

	var offset_in_image = (size / 2 - texture_rect.position) / prev_scale
	texture_rect.position = size / 2 - offset_in_image * texture_rect.scale

	clamp_texture_position()



func clamp_texture_position():
	if not texture_rect:
		return

	var scaled_size = texture_rect.size * texture_rect.scale
	var container_size = size

	var min_x = container_size.x - scaled_size.x
	var max_x = 0.0
	var min_y = container_size.y - scaled_size.y
	var max_y = 0.0

	if scaled_size.x <= container_size.x:
		texture_rect.position.x = (container_size.x - scaled_size.x) / 2
	else:
		texture_rect.position.x = clamp(texture_rect.position.x, min_x, max_x)

	if scaled_size.y <= container_size.y:
		texture_rect.position.y = (container_size.y - scaled_size.y) / 2
	else:
		texture_rect.position.y = clamp(texture_rect.position.y, min_y, max_y)


func center_image():
	#texture_rect.size = texture_rect.texture.get_size()

	zoom = 1.0
	target_zoom = 1.0
	texture_rect.scale = Vector2.ONE
	
	var scaled_size := texture_rect.size * texture_rect.scale
	var container_size := size
	var new_position := Vector2(
		(container_size.x - scaled_size.x) / 2,
		(container_size.y - scaled_size.y) / 2
	)
	texture_rect.position = new_position

func _on_texture_changed():
	if not texture_rect or not texture_rect.texture:
		return

	center_image()
