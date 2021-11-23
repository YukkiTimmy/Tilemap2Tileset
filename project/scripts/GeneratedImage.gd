extends Control

var txt = null
var img : ImageTexture = null
var title : String = ""
var info : String = ""

var save : FileDialog = null
var saving : bool = false


func _ready() -> void:
	$Image.texture = img
	$Title.text = title
	$Info.text = info


func _save() -> void:
	if saving:
		txt.save_png(save.current_path)
		save.disconnect("confirmed", self, "_save")
		saving = false


func _on_quit_pressed() -> void:
	queue_free()


func _on_download_pressed() -> void:
	saving = true
	save = get_tree().get_root().get_node("Main").saveDialog
	save.current_file = "tiled.png"
	save.visible = true
	save.connect("confirmed", self, "_save")



func _on_scollUp_pressed() -> void:
	print($Info.get_line_count() - 1)
	$Info.scroll_to_line(0)


func _on_scollDown_pressed() -> void:
	$Info.scroll_to_line($Info.get_line_count() - 1)
