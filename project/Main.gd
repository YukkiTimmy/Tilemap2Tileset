extends Control

var tileWidth = 16
var tileHeight = 16

var imgPath : String = ""
var imgLoaded : bool = false 
var outputDir : String = "choose a folder"

var running : bool = false

var tiler = null


onready var fileDialog : FileDialog = $FileDialog
onready var outFileDialog : FileDialog = $OutPutDialog

onready var display : Label = $CentralText/Display
onready var info : Label = $CentralText/Info

onready var inPic : TextureRect = $InputOutput/InputPic
onready var outPic : TextureRect = $InputOutput/OutputPic
onready var outPicPath : Label = $InputOutput/OutputPic/OutputName

onready var widthBox : SpinBox = $SettingsMenu/Width
onready var heightBox : SpinBox = $SettingsMenu/Height
onready var printingModeLever : CheckButton = $SettingsMenu/PrintingMode/PrintingModeSwitch
onready var mirroredModeLever : CheckButton = $SettingsMenu/MirroredMode/MirroredModeSwitch

onready var outputhPath : Label = $Buttons/OutputPath/OutputPathLabel
onready var startButton : Button = $Buttons/StartButton

onready var anim : AnimationPlayer = $AnimationPlayer

func _on_OpenFileButton_pressed() -> void:
	# opening the FileDialog
	fileDialog.popup()
	
	
func _on_FileDialog_file_selected(path) -> void:
	# you must have chosen a file and the tiling process can't be running
	if path != null && running == false:
		# loading the input picture++
		var InputPicImg = load_external_tex(path)
		
		# Backup Check
		if InputPicImg == null:
			display.text = "File Extensions not supported! :("
			outPic.texture = null
			return
			
		# setting the input picture to the file
		inPic.texture = InputPicImg
		outPic.texture = null
		
		
		# setting the global var to the local one
		imgPath = path

		# changing some in the ui for 
		display.text = "Image loaded successfully"
		info.text = str("Width: ", inPic.texture.get_width(), "px Height: ", inPic.texture.get_height(), "px")
		inPic.get_node("InputName").text = path.get_file()
		imgLoaded = true
		yield(get_tree().create_timer(2),"timeout") 
		display.text = "You can now start tiling"
		

func _on_OutputPath_pressed() -> void:
	# opening the OutPutDialog
	outFileDialog.popup()


func _on_OutPutDialog_dir_selected(dir)  -> void:
	# you must have chosen a directory and the tiling process can't be running
	if dir != null && running == false:
		# setting the global var to the local one
		outputDir = dir
		
		# changing some text in the ui
		outputhPath.text = outputDir
		display.text = "Output Folder choosen"
		yield(get_tree().create_timer(2), "timeout")
		display.text = "Waiting for Input"
	
		
func _on_StartButton_pressed() -> void:
	# checking that a image is loaded, that the process isn't running and that you choose a directory
	if imgLoaded == true && running == false && outputDir != "choose a folder":
		# loading the image
		var img = load_external_tex(imgPath)
		
		# getting width und height of the image
		var width = int(img.get_width())
		var height = int(img.get_height())
		
		# getting the tileWidth and tileHeight from the ui
		tileWidth = int(widthBox.value)
		tileHeight = int(heightBox.value)
		
		# checking if the image is divisible by the tile sizes given
		if width % tileWidth != 0 || height % tileHeight != 0:
			print(width , " : " , tileWidth, " | ", height, " : ", tileHeight)
			display.text = "Image- and Tilesizes don't match!"
			info.text = "Youre Imagessizes must be divisible by your Tilesizes"
			return
		
		# setting running to true to stop new processes from happening
		running = true
		
		# reseting the output image
		outPic.texture = null
		
		# loading and instantiating the Tiler
		var scene = load("res://Tiler.tscn")
		var instance =  scene.instance()
		
		tiler = instance
		
		# giving the tiler needed information
		instance.tileWidth = tileWidth
		instance.tileHeight = tileHeight
		
		instance.outputDir = outputDir
		instance.imgPath = imgPath
		
		instance.seperate = printingModeLever.pressed
		instance.mirrored = !mirroredModeLever.pressed
		
		add_child(instance)
		instance.tilesetToTile(img)
		
		# changing text
		display.text = "Started tiling"
	
	# check if there is a image loaded
	elif imgLoaded == false && running == false:
		display.text = "You need to load an image first!"
	
	# check if there is a directory choosen
	elif imgLoaded == true && outputDir == "choose a folder":
		display.text = "You need choose a output folder!"
	
	# stop the tiler
	elif running == true:
		if tiler != null:
			tiler.queue_free()
		running = false
		startButton.text = "Start Tiling"
		display.text = "Tiling has been stopped!"
	
	
func load_external_tex(path) -> Texture:
	# credits and thanks to u/golddotasksquestions over on Reddit
	var tex_file = File.new()
	tex_file.open(path, File.READ)
	var bytes = tex_file.get_buffer(tex_file.get_len())
	var img = Image.new()
	
	if path.ends_with(".png") || path.ends_with(".PNG"):
		var data = img.load_png_from_buffer(bytes)
	elif path.ends_with(".jpg") || path.ends_with(".jpeg") || path.ends_with(".JPG") || path.ends_with(".JPEG"):
		var data = img.load_jpg_from_buffer(bytes)
	else:
		return null
	
	var imgtex = ImageTexture.new()
	imgtex.create_from_image(img)
	tex_file.close()
	return imgtex


func _on_SettingsButton_pressed():
	anim.play("pop_in")


func _on_CloseSettingsButton_pressed():
	anim.play("pop_out")


func _on_4x4_pressed():
	widthBox.value = 4
	heightBox.value = 4


func _on_8x8_pressed():
	widthBox.value = 8
	heightBox.value = 8


func _on_16x16_pressed():
	widthBox.value = 16
	heightBox.value = 16


func _on_32x32_pressed():
	widthBox.value = 32
	heightBox.value = 32


func _on_64x64_pressed():
	widthBox.value = 64
	heightBox.value = 64


func _on_128x128_pressed():
	widthBox.value = 128
	heightBox.value = 128

func _on_PrintingMode_mouse_entered():
	pass # Replace with function body.
