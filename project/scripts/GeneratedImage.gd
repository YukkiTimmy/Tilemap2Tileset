extends Control

var txt = null
var img : ImageTexture = null
var title : String = ""
var info : String = ""

var rotated : int = 0

var save : FileDialog = null
var saving : bool = false

var main : Control = null

func _ready() -> void:
	$Image.texture_normal = img
	$Title.text = title
	$Info.text = info
	yield(get_tree().create_timer(0.1), "timeout")
	main = get_tree().get_root().get_node("Main")


func _save() -> void:
	if saving:
		if main.hflip:
			txt.flip_x()
		
		if main.vflip:
			txt.flip_y()
		
		txt.save_png(save.current_path)
		save.disconnect("confirmed", self, "_save")
		saving = false


func _on_quit_pressed() -> void:
	for n in main.generatedImages:
		if n == self:
			main.generatedImages.erase(n)
			
	
	queue_free()


func _on_download_pressed() -> void:	
	if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
		saving = true
		save = main.saveDialog
		save.current_file = "tiled.png"
		save.visible = true
		save.connect("confirmed", self, "_save")
	
	else:
		var image : Image = img.get_data()
		
		if main.hflip:
			image.flip_x()
		
		if main.vflip:
			image.flip_y()
		
		main.save_image(image, $Title.text)


func _on_scollUp_pressed() -> void:
	$Info.scroll_to_line(0)


func _on_scollDown_pressed() -> void:
	$Info.scroll_to_line($Info.get_line_count() - 4)


func _on_Image_pressed() -> void:
	main._open_Modal(img, self)
