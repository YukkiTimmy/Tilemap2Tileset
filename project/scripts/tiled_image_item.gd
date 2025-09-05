extends Control
class_name TiledImageItem

@onready var output_image_texture_rect := %OutputImagetextureRect
@onready var title_label := %Title_Line
@onready var info_label := %Info

var MAIN_SCENE : Control = null

var output_image : Image 

var info_resource : ImageInfoResource


func setup(_info_resource : ImageInfoResource) -> void:
	info_resource = _info_resource
	
	MAIN_SCENE = get_tree().get_root().get_node("Main")  
	output_image = info_resource.output_image
	
	output_image_texture_rect.texture = info_resource.get_output_image_texture()
	
	title_label.text = info_resource.input_image_name
	info_label.text = info_resource.get_formatted_info_string()
	
	info_resource.stored_in_tiled_image_item = self
	


func _on_delete_pressed() -> void:
	queue_free()


func _on_download_pressed() -> void:
	if not MAIN_SCENE:
		push_error("couldnt find main scene")
	
	MAIN_SCENE.save_tile_modal.show_modal(info_resource)

	
func _on_path_chosen(save_path: String) -> void:
	print(save_path)
	var err := output_image.save_png(save_path)
	if err != OK:
		push_error("Couldnt save image: " + save_path)
	else:
		print("Imaged save under: ", save_path)



		
func _on_input_imagetexture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		if not MAIN_SCENE:
			push_error("couldnt find main scene")
		
		MAIN_SCENE.tile_detail_modal.show_modal(info_resource)
		
