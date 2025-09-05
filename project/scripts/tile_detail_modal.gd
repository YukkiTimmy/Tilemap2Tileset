extends Control

@onready var image_display := %OutputImageTextureRect
@onready var zoom_container := %ZoomContainer

@onready var image_information_label := %ImageInformation
@onready var tiled_images_list = %TiledImagesList_VBox

var current_tile_shown = null

var info_resource : ImageInfoResource

var MAIN_SCENE = null

func show_modal(_info_resource : ImageInfoResource):
	self.visible = true
	
	zoom_container.center_image()
	
	info_resource = _info_resource
	MAIN_SCENE = get_tree().get_root().get_node("Main")  

	image_display.texture = info_resource.get_output_image_texture()
	
	image_information_label.text = info_resource.get_formatted_info_string()
	
	current_tile_shown = info_resource.stored_in_tiled_image_item

func clear_modal():
	image_information_label.text = ""
	image_display.texture = null
	current_tile_shown = null
	self.visible = false
	

func _on_close_button_pressed() -> void:
	self.visible = false


func _on_previous_image_pressed() -> void:
	var neighbours := tiled_images_list.get_children()
	var own_position_in_list := neighbours.find(current_tile_shown)
	var previous_list_item := own_position_in_list - 1 if own_position_in_list - 1 >= 0 else neighbours.size() - 1
	
	show_modal(neighbours[previous_list_item].info_resource)

func _on_next_image_pressed() -> void:
	var neighbours := tiled_images_list.get_children()
	var own_position_in_list := neighbours.find(current_tile_shown)
	var next_list_item := own_position_in_list + 1 if own_position_in_list + 1 < neighbours.size() else 0
	
	show_modal(neighbours[next_list_item].info_resource)


func _on_flip_v_button_pressed() -> void:
	image_display.flip_v = not image_display.flip_v
	_update_tiled_image_item_image()

func _on_flip_h_button_pressed() -> void:
	image_display.flip_h = not image_display.flip_h
	_update_tiled_image_item_image()


func _on_rotate_right_button_pressed() -> void:
	image_display.rotation += deg_to_rad(90)
	_update_tiled_image_item_image()


func _on_rotate_left_button_pressed() -> void:
	image_display.rotation -= deg_to_rad(90)
	_update_tiled_image_item_image()


func _on_delete_button_pressed() -> void:
	var old_item_shown = current_tile_shown
	
	var neighbours := tiled_images_list.get_children()
	var own_position_in_list := neighbours.find(current_tile_shown)
	var next_list_item := own_position_in_list + 1 if own_position_in_list + 1 < neighbours.size() else 0
	
	if neighbours[next_list_item] != old_item_shown:
		show_modal(neighbours[next_list_item].info_resource)
	else:
		clear_modal()
	old_item_shown.queue_free()


func _update_tiled_image_item_image():
	if current_tile_shown and current_tile_shown.output_image_texture_rect:
		current_tile_shown.output_image_texture_rect.flip_h = image_display.flip_h
		current_tile_shown.output_image_texture_rect.flip_v = image_display.flip_v


func _on_download_button_pressed() -> void:
	if MAIN_SCENE:
		MAIN_SCENE.save_tile_modal.show_modal(info_resource)
