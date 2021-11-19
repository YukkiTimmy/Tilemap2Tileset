extends Control

var tileWidth : int = 16
var tileHeight : int = 16

var imgPath : String = ""
var imgLoaded : bool = false 
var urlLoaded : bool = false
var outputDir : String = "choose a folder"

var running : bool = false

var sort_by : String = "red"

var tiler = null

var thread : Thread

var onPic : bool = false
var _dragging : bool = false

onready var fileDialog : FileDialog = $FileDialog
onready var urlDialog : Popup = $DownloadPopup
onready var urlDialogLineEdit : LineEdit = $DownloadPopup/LineEdit
onready var outFileDialog : FileDialog = $OutPutDialog

onready var display : Label = $CentralText/Display
onready var info : Label = $CentralText/Info

#onready var inPic : TextureRect = $InputOutput/InputPicTexture
onready var inPic : Sprite = $InputOutput/InputPic
onready var outPic : TextureRect = $InputOutput/OutputPic
onready var outPicPath : Label = $InputOutput/OutputPic/OutputName

onready var widthBox : SpinBox = $SettingsMenu/Sizes/Width
onready var heightBox : SpinBox = $SettingsMenu/Sizes/Height

onready var offsetX : SpinBox = $SettingsMenu/Offset/OffsetX
onready var offsetY : SpinBox = $SettingsMenu/Offset/OffsetY

onready var printingModeLever : CheckButton = $SettingsMenu/PrintingMode/PrintingModeSwitch
onready var mirroredModeLever : CheckButton = $SettingsMenu/MirroredMode/MirroredModeSwitch
onready var sortingModeLever : CheckButton = $SettingsMenu/SortingMode/SortingModeSwitch

onready var redCheck : CheckBox = $SettingsMenu/SortingMode/Red
onready var greenCheck : CheckBox = $SettingsMenu/SortingMode/Green
onready var blueCheck : CheckBox = $SettingsMenu/SortingMode/Blue

onready var outputhPath : Label = $Buttons/OutputPath/OutputPathLabel
onready var startButton : Button = $Buttons/StartButton

onready var bar : TextureProgress = $ProgressBar

onready var anim : AnimationPlayer = $AnimationPlayer

var dragStart = Vector2.ZERO

func _ready() -> void:
	$SettingsMenu.visible = false
	anim.play("pop_out")
	
	get_tree().connect("files_dropped", self, "_on_files_dropped")


func _on_files_dropped(files, screen):
	if files[0] != null && running == false:
		# loading the input picture++
		var InputPicImg = load_external_tex(files[0])
		
		# Backup Check
		if InputPicImg == null:
			display.text = "File Extensions not supported! :("
			outPic.texture = null
			return
			
		# setting the input picture to the file
		inPic.texture = InputPicImg
		outPic.texture = null
		
		
		# setting the global var to the local one
		imgPath = files[0]

		# changing some in the ui for 
		display.text = "Image loaded successfully"
		info.text = str("Width: ", inPic.texture.get_width(), "px Height: ", inPic.texture.get_height(), "px")
		inPic.get_node("InputName").text = files[0].get_file()
		imgLoaded = true
		yield(get_tree().create_timer(2),"timeout") 
		display.text = "You can now start tiling"
	

func _input(event):
	var size := Vector2(304,304)
	var offset := Vector2(inPic.region_rect.position.x, inPic.region_rect.position.y)

	if event is InputEventMouseButton and get_global_mouse_position() < Vector2(416,448) and get_global_mouse_position() > Vector2(96, 128):
		_dragging = event.pressed
		
	elif event is InputEventMouseMotion and _dragging:
		var motion = Vector2(event.relative.x, event.relative.y)
		offset.x += -motion.x
		offset.y += -motion.y
		inPic.region_rect = Rect2(offset, size)
	
	else:
		_dragging = false

	
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


func _on_LoadURLImage_pressed() -> void:
	urlDialog.popup()


func _on_submit_pressed() -> void:
	urlDialog.visible = false
	
	if urlDialogLineEdit.text != "":
		var http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.connect("request_completed", self, "_http_request_completed")
		
		var error = http_request.request(urlDialogLineEdit.text)
		if error != OK:
			push_error("An error occurred in the HTTP request.")


func _on_CloseSettingsButton2_pressed() -> void:
	urlDialog.visible = false	

# warning-ignore:unused_argument
# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	
	imgPath = urlDialogLineEdit.text
	var error = null
		
	if imgPath.ends_with(".png") || imgPath.ends_with(".PNG"):
		error = image.load_png_from_buffer(body)
	elif imgPath.ends_with(".jpg") || imgPath.ends_with(".jpeg") || imgPath.ends_with(".JPG") || imgPath.ends_with(".JPEG"):
		error = image.load_jpg_from_buffer(body)
	else:
		return null
	
	if error != OK:
		push_error("Couldn't load the image.")

	var texture = ImageTexture.new()
	texture.create_from_image(image)

	inPic.texture = texture
	outPic.texture = null
	

	# changing some in the ui for 
	display.text = "Image loaded successfully"
	info.text = str("Width: ", inPic.texture.get_width(), "px Height: ", inPic.texture.get_height(), "px")
	inPic.get_node("InputName").text = urlDialogLineEdit.text
	urlLoaded = true
	yield(get_tree().create_timer(2),"timeout") 
	display.text = "You can now start tiling"


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
	if imgLoaded == true && running == false && outputDir != "choose a folder" || urlLoaded == true && running == false && outputDir != "choose a folder":
		# loading the image
		var img = inPic.texture
		
		# getting width und height of the image
		var width = int(img.get_width() - offsetX.value)
		var height = int(img.get_height() - offsetY.value)
		
		# getting the tileWidth and tileHeight from the ui
		tileWidth = int(widthBox.value)
		tileHeight = int(heightBox.value)
		
		# checking if the image is divisible by the tile sizes given
		if width % tileWidth != 0 || height % tileHeight != 0:
			print(width , " : " , tileWidth, " | ", height, " : ", tileHeight)
			display.text = "Image- and Tilesizes don't match!"
			info.text = "Youre Imagessizes must be divisible by your Tilesizes (check the offsets)"
			return
		
		# setting running to true to stop new processes from happening
		running = true
		
		# reseting the output image
		outPic.texture = null
		
		var scene = null
		
		# loading and instantiating the Tiler
		scene = load("res://Tiler.tscn")
			
		var instance =  scene.instance()
		
		tiler = instance
		
		# giving the tiler needed information
		instance.tileWidth = tileWidth
		instance.tileHeight = tileHeight
		
		instance.offsetX = offsetX.value
		instance.offsetY = offsetY.value
		
		instance.outputDir = outputDir
		instance.imgPath = imgPath
		
		instance.seperate = printingModeLever.pressed
		instance.mirrored = !mirroredModeLever.pressed
		instance.sorting = sortingModeLever.pressed
		
		instance.sort_by = sort_by
		
		add_child(instance)
		
		thread = Thread.new()
# warning-ignore:return_value_discarded
		thread.start(instance, "tilesetToTile", img)
		
		# changing text
		display.text = "Started tiling"
	
	# check if there is a image loaded
	elif imgLoaded == false && urlLoaded == false && running == false:
		display.text = "You need to load an image first!"
	
	# check if there is a directory choosen
	elif imgLoaded == true && outputDir == "choose a folder":
		display.text = "You need choose a output folder!"
	
	# stop the tiler
	elif running == true:
		if tiler != null:
			tiler.queue_free()
		running = false
		
		bar.value = 0
		startButton.text = "Start Tiling"
		display.text = "Tiling has been stopped!"
		info.text = "---"
	
	
func load_external_tex(path) -> ImageTexture:
	# credits and thanks to u/golddotasksquestions over on Reddit
	var tex_file = File.new()
	tex_file.open(path, File.READ)
	var bytes = tex_file.get_buffer(tex_file.get_len())
	var img = Image.new()
	
	if path.ends_with(".png") || path.ends_with(".PNG"):
# warning-ignore:unused_variable
		var data = img.load_png_from_buffer(bytes)
	elif path.ends_with(".jpg") || path.ends_with(".jpeg") || path.ends_with(".JPG") || path.ends_with(".JPEG"):
# warning-ignore:unused_variable
		var data = img.load_jpg_from_buffer(bytes)
	else:
		return null
	
	var imgtex = ImageTexture.new()
	imgtex.create_from_image(img)
	tex_file.close()
	return imgtex


func _on_SettingsButton_pressed():
	anim.queue("pop_in")


func _on_CloseSettingsButton_pressed():
	anim.queue("pop_out")


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


func _on_Red_pressed():
	redCheck.pressed = true
	greenCheck.pressed = false
	blueCheck.pressed = false
	sort_by = "red"

func _on_Green_pressed():
	redCheck.pressed = false
	greenCheck.pressed = true
	blueCheck.pressed = false
	sort_by = "green"

func _on_Blue_pressed():
	redCheck.pressed = false
	greenCheck.pressed = false
	blueCheck.pressed = true
	sort_by = "blue"


func _on_SaveSettingsButton_pressed() -> void:
	anim.queue("Saved")
	var f = File.new()
	f.open("user://settings.sav", File.WRITE)
	f.store_var(widthBox.value)
	f.store_var(heightBox.value)
	
	f.store_var(offsetX.value)
	f.store_var(offsetY.value)
	
	f.store_var(sortingModeLever.pressed)
	f.store_var(redCheck.pressed)
	f.store_var(greenCheck.pressed)
	f.store_var(blueCheck.pressed)
	
	f.store_var(mirroredModeLever.pressed)
	
	f.store_var(printingModeLever.pressed)
	
	f.close()
	print("SAVED")


func _on_LoadSettingsButton_pressed() -> void:
	anim.queue("Loaded")
	var f = File.new()
	f.open("user://settings.sav", File.READ)
	widthBox.value = f.get_var()
	heightBox.value = f.get_var()
	
	offsetX.value = f.get_var()
	offsetY.value = f.get_var()
	
	sortingModeLever.pressed = f.get_var()
	redCheck.pressed = f.get_var()
	greenCheck.pressed = f.get_var()
	blueCheck.pressed = f.get_var()
	
	mirroredModeLever.pressed = f.get_var()
	
	printingModeLever.pressed = f.get_var()
	
	f.close()
	print("LOADED")
