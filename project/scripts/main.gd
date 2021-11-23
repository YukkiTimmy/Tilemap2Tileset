extends Control

var tileWidth : int = 16
var tileHeight : int = 16

var imgPath : String = ""
var currentImage = null

var imgLoaded : bool = false 
var urlLoaded : bool = false
var outputDir : String = ""

var running : bool = false

var sort_by : String = "red"

var tiler = null

var thread : Thread

var onPic : bool = false
var _dragging : bool = false


# ---onready---

# Dialogs
onready var fileDialog : FileDialog = $Dialogs/FileDialog
onready var outputDialog : FileDialog = $Dialogs/OutputDialog
onready var saveDialog : FileDialog = $Dialogs/SaveDialog

onready var fileDialogButton : Control = $FileDialogButton

# tile- height/width
onready var widthBox : SpinBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/Sizes/width
onready var heightBox : SpinBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/Sizes/height

# offset
onready var offsetX : SpinBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/Offset/width
onready var offsetY : SpinBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/Offset/height

# Setting Switches
onready var printingModeLever : CheckButton = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/PrintingMode
onready var mirroredModeLever : CheckButton = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/MirroredMode
onready var sortingModeLever : CheckButton = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingMode

# sorting color
onready var redCheck : CheckBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingColors/Red
onready var blueCheck : CheckBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingColors/Blue
onready var greenCheck : CheckBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingColors/Green

# start button
onready var startButton : Button = $Lowerbar/VBoxContainer/HBoxContainer/StartButton

# generated image
onready var tiledImages : GridContainer = $Body/VBoxContainer/ScrollContainer/TiledImages

# progressbar
onready var progress : ProgressBar = $Lowerbar/VBoxContainer/ProgressBar

# input image
onready var inputImage : Polygon2D = $Body/VBoxContainer/Panel/inputImage

# url
onready var urlLine : LineEdit = $Body/VBoxContainer/Panel/LineEdit



func _input(event: InputEvent) -> void:
	if inputImage.texture != null:
		var offset := inputImage.texture_offset
		
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT && onPic:
			_dragging = event.pressed
			
			
		elif event is InputEventMouseMotion and _dragging and !running:
			var motion = Vector2(event.relative.x, event.relative.y)
			offset.x += -motion.x
			offset.y += -motion.y
			
			if offset.x > 0 and offset.x < inputImage.texture.get_width() - 1035:
				inputImage.texture_offset.x = offset.x
			
			if offset.y < inputImage.texture.get_height() - 250 and offset.y > 0:
				inputImage.texture_offset.y = offset.y
			
		else:
			_dragging = false
		
		

func _ready() -> void:	
	get_tree().connect("files_dropped", self, "_on_files_dropped")


func _on_files_dropped(files, screen):
	if files[0] != null && running == false:
		# loading the input picture
		var InputPicImg = load_external_tex(files[0])
		
		
		# Backup Check
		if InputPicImg == null:
			print("error")
			return
			
		currentImage = InputPicImg

		
		# setting the global var to the local one
		imgPath = files[0]
		imgLoaded = true
		
		
		inputImage.texture = currentImage
		inputImage.visible = true
		fileDialogButton.visible = false
		$Body/VBoxContainer/Panel/urlSubmit.visible = false
		$Body/VBoxContainer/Panel/LineEdit.visible = false
		$Body/VBoxContainer/Panel/CenterContainer.visible = false


func _on_FileDialog_file_selected(path: String) -> void:
	if path != null && running == false:
		# loading the input picture
		var InputPicImg = load_external_tex(path)
		
		
		# Backup Check
		if InputPicImg == null:
			print("error")
			return
			
		currentImage = InputPicImg
		
		imgPath = path
		imgLoaded = true
		
		inputImage.texture = currentImage
		inputImage.visible = true
		fileDialogButton.visible = false
		$Body/VBoxContainer/Panel/urlSubmit.visible = false
		$Body/VBoxContainer/Panel/LineEdit.visible = false
		$Body/VBoxContainer/Panel/CenterContainer.visible = false
		
		
func _on_StartButton_pressed() -> void:
	if printingModeLever.pressed:
		if outputDir == "":
			$InfoText2.visible = true
			
			var tween = Tween.new()
			add_child(tween)
			tween.interpolate_property($InfoText2, "modulate:a", modulate.a, 0.0, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.playback_speed = 0.5
			tween.start()
			
			return
		
	
	# checking that a image is loaded, that the process isn't running and that you choose a directory
	if imgLoaded == true && running == false:
		# loading the image
		var img = currentImage
		
		# getting width und height of the image
		var width = int(img.get_width() - offsetX.value)
		var height = int(img.get_height() - offsetY.value)
		
		# getting the tileWidth and tileHeight from the ui
		tileWidth = int(widthBox.value)
		tileHeight = int(heightBox.value)
		
		
		# checking if the image is divisible by the tile sizes given
		if width % tileWidth != 0 || height % tileHeight != 0:
			print(width , " : " , tileWidth, " | ", height, " : ", tileHeight)
			$InfoText.visible = true
		
			var tween = Tween.new()
			add_child(tween)
			tween.interpolate_property($InfoText, "modulate:a", modulate.a, 0.0, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween.playback_speed = 0.5
			tween.start()
			
			return
		
		# setting running to true to stop new processes from happening
		running = true
		
		
		
		var scene = null
		
		# loading and instantiating the Tiler
		scene = load("res://scenes/Tiler.tscn")
			
		var instance = scene.instance()
		
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
		
		startButton.text = "Stop Tiling"
	
	elif running:
		if tiler != null:
			tiler.queue_free()
		
		running = false
		
		startButton.text = "Start Tiling"
		
		yield(get_tree().create_timer(0.001), "timeout")
		progress.value = 0
	
	
	
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


func _on_urlSubmit_pressed() -> void:
	if urlLine.text != "":
		var http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.connect("request_completed", self, "_http_request_completed")
		
		var error = http_request.request(urlLine.text)
		if error != OK:
			push_error("An error occurred in the HTTP request.")


func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	
	imgPath = urlLine.text
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
	
	imgLoaded = true
	
	currentImage = texture	

	inputImage.texture = texture
	inputImage.visible = true
	fileDialogButton.visible = false
	$Body/VBoxContainer/Panel/urlSubmit.visible = false
	$Body/VBoxContainer/Panel/LineEdit.visible = false
	$Body/VBoxContainer/Panel/CenterContainer.visible = false



# SETTINGS BUTTONS

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
	sort_by = "red"


func _on_Green_pressed():
	sort_by = "green"


func _on_Blue_pressed():
	print("blue")
	sort_by = "blue"


func _on_SortingMode_toggled(button_pressed : bool) -> void:
	if button_pressed:
		$Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingColors.visible = true
	else:
		$Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingColors.visible = false
		

func _on_PrintingMode_toggled(button_pressed: bool) -> void:
	if button_pressed:
		$Sidebar/TabContainer/Options/ScrollContainer/OptionList/location.visible = true
		$Sidebar/TabContainer/Options/ScrollContainer/OptionList/fileDialog.visible = true
	else:
		$Sidebar/TabContainer/Options/ScrollContainer/OptionList/location.visible = false
		$Sidebar/TabContainer/Options/ScrollContainer/OptionList/fileDialog.visible = false


func _on_Opendialog_pressed() -> void:
	fileDialog.visible = true


func _on_fileDialog_pressed() -> void:
	outputDialog.visible = true


func _on_DeleteTiledImages_pressed() -> void:
	for n in $Body/VBoxContainer/ScrollContainer/TiledImages.get_children():
		n.queue_free()


func _on_RemovePreviewImage_pressed() -> void:
	inputImage.texture = null
	inputImage.visible = false
	fileDialogButton.visible = true
	$Body/VBoxContainer/Panel/urlSubmit.visible = true
	$Body/VBoxContainer/Panel/LineEdit.visible = true
	$Body/VBoxContainer/Panel/CenterContainer.visible = true


func _on_Panel_mouse_entered() -> void:
	onPic = true


func _on_Panel_mouse_exited() -> void:
	onPic = false


func _on_OutputDialog_dir_selected(dir: String) -> void:
	$Sidebar/TabContainer/Options/ScrollContainer/OptionList/location.text = dir
	outputDir = dir


func _on_ColorPalette_pressed() -> void:
	widthBox.value = 1
	heightBox.value = 1

	sortingModeLever.pressed = false
	printingModeLever.pressed = false
	mirroredModeLever.pressed = false
	
	offsetX.value = 0
	offsetY.value = 0

func _on_Save_pressed() -> void:
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
	
	f.store_var(outputDir)
	
	f.close()


func _on_Load_pressed() -> void:
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
	outputDir = f.get_var()
	$Sidebar/TabContainer/Options/ScrollContainer/OptionList/location.text = outputDir
	
	f.close()


