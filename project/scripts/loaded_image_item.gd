extends Control
class_name loadedImageItem

@onready var image_preview := $VBoxContainer/ImagePreview
@onready var file_name := $VBoxContainer/FileName

var MAIN_SCENE : main_scene = null

var saved_texture : Texture = null
var saved_image : Image = null
var saved_filename : String = ""
var saved_path : String = ""

func init(texture : Texture2D, image : Image, path : String) -> void:
		MAIN_SCENE = get_tree().get_root().get_node("Main")  
		
		saved_texture = texture
		saved_image = image
		saved_filename = path.get_file().get_basename()
		saved_path = path

		image_preview.texture = saved_texture
		file_name.text = saved_filename

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		MAIN_SCENE.set_loaded_image(saved_image, saved_filename)
