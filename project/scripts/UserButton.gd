extends Button

var title := "User Button 1"

var widthBox : int = 16
var heightBox : int = 16

var sortingModeLever := false

var redCheck := false
var greenCheck := false
var blueCheck := false

var printingModeLever := false

var outputDir := ""

var mirroredModeLever := false

var offsetX : int = 0
var offsetY : int = 0

var main = null

func save():
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"pos_x" : rect_position.x,
		"pos_y" : rect_position.y,
		"title" : title,
		"widthBox" : widthBox,
		"heightBox" : heightBox,
		"sortingModeLever" : sortingModeLever,
		"redCheck" : redCheck,
		"greenCheck" : greenCheck,
		"blueCheck" : blueCheck,
		"printingModeLever" : printingModeLever,
		"outputDir" : outputDir,
		"mirroredModeLever" : mirroredModeLever,
		"offsetX" : offsetX,
		"offsetY" : offsetY
	}
	
	return save_dict


func _ready() -> void:
	yield(get_tree().create_timer(0.4), "timeout")
	text = title
	main = get_tree().get_root().get_node("Main")


func _on_UserButton_pressed() -> void:
	main.widthBox.value = widthBox
	main.heightBox.value = heightBox
	
	main.sortingModeLever.pressed = sortingModeLever
	
	main.redCheck.toggle_mode = redCheck
	main.greenCheck.toggle_mode = greenCheck
	main.blueCheck.toggle_mode = blueCheck
	
	main.printingModeLever.pressed = printingModeLever
	
	main.outputDir = outputDir
	
	main.mirroredModeLever.pressed = mirroredModeLever
	
	main.offsetX.value = offsetX
	main.offsetY.value = offsetY
	
	main.tabcontainer.current_tab = 0


func _on_close_pressed() -> void:
	self.queue_free()
	main._save_buttons()
