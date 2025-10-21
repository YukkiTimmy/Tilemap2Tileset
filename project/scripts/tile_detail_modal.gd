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

	var texture = info_resource.get_output_image_texture()
	image_display.texture = texture
	
	if texture.get_size() > image_display.size:
		image_display.pivot_offset = texture.get_size()/2
	else:
		image_display.pivot_offset = image_display.size / 2
	
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
	var image = image_display.texture.get_image()
	image.flip_y()  

	var flipped_texture = ImageTexture.create_from_image(image)
	image_display.texture = flipped_texture
	
	_update_tiled_image_item_image(image)

func _on_flip_h_button_pressed() -> void:
	var image = image_display.texture.get_image()
	image.flip_x()  

	var flipped_texture = ImageTexture.create_from_image(image)
	image_display.texture = flipped_texture

	
	_update_tiled_image_item_image(image)


func _on_rotate_right_button_pressed() -> void:
	var image : Image = image_display.texture.get_image()
	image.rotate_90(CLOCKWISE)

	var rotated_texture = ImageTexture.create_from_image(image)
	image_display.texture = rotated_texture

	_update_tiled_image_item_image(image)


func _on_rotate_left_button_pressed() -> void:
	var image = image_display.texture.get_image()
	image.rotate_90(COUNTERCLOCKWISE)

	var rotated_texture = ImageTexture.create_from_image(image)
	image_display.texture = rotated_texture

	_update_tiled_image_item_image(image)


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


func _update_tiled_image_item_image(image : Image):
	if current_tile_shown and current_tile_shown.output_image_texture_rect:
		current_tile_shown.output_image_texture_rect.texture = image_display.texture

	info_resource.output_image = image


func _on_download_button_pressed() -> void:
	if MAIN_SCENE:
		MAIN_SCENE.save_tile_modal.show_modal(info_resource)
