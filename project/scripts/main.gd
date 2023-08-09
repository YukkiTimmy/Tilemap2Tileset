extends Control

signal InFocus
signal loaded

var tileWidth : int = 16
var tileHeight : int = 16

var imgPath : String = ""
var currentImage = null

var imgLoaded : bool = false 
var urlLoaded : bool = false
var outputDir : String = ""

var running : bool = false

var sort_by : String = "red"

var filter : bool = false

var shader : String = ""

var hflip : bool = false
var vflip : bool = false

var tiler = null

var thread : Thread

var onPic : bool = false
var _dragging : bool = false
var _Modaldragging : bool = false

var onModalPic : bool = false

var loaded_image : Image

var fileName : String = "unknown"

var generatedImages : Array = []
var currentModalImage : int = 0

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

# end offset
onready var endOffsetX : SpinBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/EndOffset/width
onready var endOffsetY : SpinBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/EndOffset/height

# Setting Switches
onready var printingModeLever : CheckButton = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/PrintingMode
onready var mirroredModeLever : CheckButton = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/MirroredMode
onready var sortingModeLever : CheckButton = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingMode

# sorting color
onready var redCheck : CheckBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingColors/Red
onready var blueCheck : CheckBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingColors/Blue
onready var greenCheck : CheckBox = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingColors/Green
onready var sortingColors = $Sidebar/TabContainer/Options/ScrollContainer/OptionList/SortingColors


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

# Modal
onready var modal : Control = $Modal
onready var modalImage : TextureRect = $Modal/ViewportContainer/Viewport/Image
onready var modalLabel: Label = $Modal/Label
onready var richModalLabel: RichTextLabel = $Modal/Info
onready var zoomSlider : HSlider = $Modal/Slider

# Presets
onready var presets : Control = $Sidebar/TabContainer/Presets/ScrollContainer/OptionList/SavedSettings/ScrollContainer/VBoxContainer
onready var presetLineEdit : LineEdit = $Sidebar/TabContainer/Options/Save/LineEdit
onready var tabcontainer : TabContainer = $Sidebar/TabContainer



func _ready() -> void:
	get_tree().connect("files_dropped", self, "_on_files_dropped")
	
	if OS.get_name() == "HTML5" and OS.has_feature('JavaScript'):
		_define_js()
	
	_on_Load()
	
func _process(_delta: float) -> void:
	if zoomSlider.value >= 0.25 && zoomSlider.value <=10 && onModalPic:
		if Input.is_action_just_released("zoom_in"):
			zoomSlider.value += 0.075
		
		elif Input.is_action_just_released("zoom_out"):
			zoomSlider.value -= 0.075
	
	if modal.visible:
		if Input.is_action_just_pressed("ui_right"):
			_on_rightButton_pressed()
		elif Input.is_action_just_pressed("ui_left"):
			_on_leftButton_pressed()
	
		
	elif zoomSlider.value < 0.25:
		zoomSlider.value = 0.25
	
	elif zoomSlider.value > 10:
		zoomSlider.value = 10
	
	
	modalImage.rect_scale = Vector2(zoomSlider.value,zoomSlider.value)



func _notification(notification:int) -> void:
	if notification == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		emit_signal("InFocus")



func _define_js() -> void:
	# Define JS script
	JavaScript.eval("""
	var fileData;
	var fileType;
	var fileName;
	var canceled;
	function upload_image() {
		canceled = true;
		var input = document.createElement('INPUT');
		input.setAttribute("type", "file");
		input.setAttribute("accept", "image/png, image/jpeg, image/webp");
		input.click();
		input.addEventListener('change', event => {
			if (event.target.files.length > 0){
				canceled = false;}
			var file = event.target.files[0];
			var reader = new FileReader();
			fileType = file.type;
			fileName = file.name;
			reader.readAsArrayBuffer(file);
			reader.onloadend = function (evt) {
				if (evt.target.readyState == FileReader.DONE) {
					fileData = evt.target.result;
				}
			}
		  });
	}
	function download(fileName, byte, type) {
		var buffer = Uint8Array.from(byte);
		var blob = new Blob([buffer], { type: type});
		var link = document.createElement('a');
		link.href = window.URL.createObjectURL(blob);
		link.download = fileName;
		link.click();
		link.remove()
	};
	
	""", true)


func load_image():
	if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
		return

	# Execute JS function
	JavaScript.eval("upload_image();", true) # Opens prompt for choosing file

	yield(self, "InFocus") # Wait until JS prompt is closed

	yield(get_tree().create_timer(0.5), "timeout") # Give some time for async JS data load

	if JavaScript.eval("canceled;", true): # If File Dialog closed w/o file
		return

	# Use data from png data
	var image_data
	while true:
		image_data = JavaScript.eval("fileData;", true)
		if image_data != null:
			break
		yield(get_tree().create_timer(1.0), "timeout") # Need more time to load data

	var image_type = JavaScript.eval("fileType;", true)
	var image_name = JavaScript.eval("fileName;", true)
	
	fileName = image_name
	
	var image = Image.new()
	var image_error
	match image_type:
		"image/png":
			image_error = image.load_png_from_buffer(image_data)
		"image/jpeg":
			image_error = image.load_jpg_from_buffer(image_data)
		"image/webp":
			image_error = image.load_webp_from_buffer(image_data)
		var invalid_type:
			print("Invalid type: " + invalid_type)
			return
	if image_error:
		print("An error occurred while trying to display the image.")
		return
	
	var imgtex = ImageTexture.new()
	imgtex.create_from_image(image)
	
	currentImage = imgtex
	
	imgLoaded = true
	
	endOffsetX.value = currentImage.get_width()
	endOffsetY.value = currentImage.get_height()
	inputImage.material.set_shader_param("imgW", endOffsetX.value)
	inputImage.material.set_shader_param("imgH", endOffsetY.value)
	
	inputImage.texture = currentImage
	inputImage.visible = true
	fileDialogButton.visible = false
	$Body/VBoxContainer/Panel/urlSubmit.visible = false
	$Body/VBoxContainer/Panel/LineEdit.visible = false
	$Body/VBoxContainer/Panel/CenterContainer.visible = false
	
	emit_signal("loaded")


func save_image(image : Image, file_name : String = "ScaleNXExports") -> void:
	if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
		return
		
		
	var png_data = image.save_png_to_buffer()
	JavaScript.eval("download('%s', %s, 'image/png');" % [file_name, str(png_data)], true)


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
		
		
		var modalPos = modalImage.rect_position
		
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT && onModalPic:
			_Modaldragging = event.pressed
			
			
		elif event is InputEventMouseMotion and _Modaldragging and !running:
			var motion = Vector2(event.relative.x, event.relative.y)
			modalPos.x += motion.x
			modalPos.y += motion.y
			
			
			if modalPos.x > -295 and modalPos.x < 295:
				modalImage.rect_position.x = modalPos.x

			if modalPos.y > -295 and modalPos.y < 295:
				modalImage.rect_position.y = modalPos.y
			
		else:
			_Modaldragging = false
		

func _on_files_dropped(files, _screen):
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
		
		endOffsetX.value = currentImage.get_width()
		endOffsetY.value = currentImage.get_height()
		inputImage.material.set_shader_param("imgW", endOffsetX.value)
		inputImage.material.set_shader_param("imgH", endOffsetY.value)
		
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
		
		endOffsetX.value = currentImage.get_width()
		endOffsetY.value = currentImage.get_height()
		inputImage.material.set_shader_param("imgW", endOffsetX.value)
		inputImage.material.set_shader_param("imgH", endOffsetY.value)
		
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
		var width = int(endOffsetX.value - offsetX.value)
		var height = int(endOffsetY.value - offsetY.value)
		
		# getting the tileWidth and tileHeight from the ui
		tileWidth = int(widthBox.value)
		tileHeight = int(heightBox.value)
		
		
		# checking if the image is divisible by the tile sizes given
		# if width % tileWidth != 0 || height % tileHeight != 0:
			# print(width , " : " , tileWidth, " | ", height, " : ", tileHeight)
			# $InfoText.visible = true
		
			# var tween = Tween.new()
			# add_child(tween)
			# tween.interpolate_property($InfoText, "modulate:a", modulate.a, 0.0, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			# tween.playback_speed = 0.5
			# tween.start()
			
			# return
		
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
		
		instance.endOffsetX = endOffsetX.value
		instance.endOffsetY = endOffsetY.value
		
		instance.outputDir = outputDir
		instance.imgPath = imgPath
		
		instance.seperate = printingModeLever.pressed
		instance.mirrored = !mirroredModeLever.pressed
		instance.sorting = sortingModeLever.pressed
		
		instance.sort_by = sort_by
		
		instance.filter = filter
		instance.shader = shader
		
		add_child(instance)
		
		
		thread = Thread.new()
		# warning-ignore:return_value_discarded
		thread.start(instance, "tilesetToTile", img)
		
		
		if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
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


func _http_request_completed(_result, _response_code, _headers, body):
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

	endOffsetX.value = currentImage.get_width()
	endOffsetY.value = currentImage.get_height()
	inputImage.material.set_shader_param("imgW", endOffsetX.value)
	inputImage.material.set_shader_param("imgH", endOffsetY.value)

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
	if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
		fileDialog.visible = true
	else:
		load_image()
		
			


func _on_fileDialog_pressed() -> void:
	outputDialog.visible = true


func _on_DeleteTiledImages_pressed() -> void:
	generatedImages.clear()
	for n in $Body/VBoxContainer/ScrollContainer/TiledImages.get_children():
		n.queue_free()


func _on_RemovePreviewImage_pressed() -> void:
	imgLoaded = false
	inputImage.texture = null
	inputImage.visible = false
	fileDialogButton.visible = true
	modalImage.texture = null
	$Body/VBoxContainer/Panel/urlSubmit.visible = true
	$Body/VBoxContainer/Panel/LineEdit.visible = true
	$Body/VBoxContainer/Panel/CenterContainer.visible = true
	
	endOffsetX.value = 0
	endOffsetY.value = 0
	inputImage.material.set_shader_param("imgW", endOffsetX.value)
	inputImage.material.set_shader_param("imgH", endOffsetY.value)


func _on_Panel_mouse_entered() -> void:
	onPic = true


func _on_Panel_mouse_exited() -> void:
	onPic = false


func _on_OutputDialog_dir_selected(dir: String) -> void:
	$Sidebar/TabContainer/Options/ScrollContainer/OptionList/location.text = dir
	outputDir = dir


func _on_ColorPalette_pressed() -> void:
	_reset_settings()
	
	widthBox.value = 1
	heightBox.value = 1


func _on_Save_pressed() -> void:
	print("SAVING")
	var scene = load("res://scenes/UserButton.tscn")
	var instance = scene.instance()
	
	instance.widthBox = widthBox.value
	instance.heightBox = heightBox.value

	instance.sortingModeLever = sortingModeLever.pressed
	
	redCheck.toggle_mode
	greenCheck.toggle_mode
	blueCheck.toggle_mode
	
	instance.printingModeLever = printingModeLever.pressed
	instance.mirroredModeLever = mirroredModeLever.pressed

	instance.offsetX = offsetX.value
	instance.offsetY = offsetY.value
	
	if !presetLineEdit.text:
		instance.title = str("User Button ", presets.get_child_count() + 1)
	
	else:
		instance.title = presetLineEdit.text
	
	presets.add_child(instance)
	
	_save_buttons()
	
	print("SAVED")


func _save_buttons() -> void:
	yield(get_tree().create_timer(0.5), "timeout")
	
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.filename.empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("save")

		# Store the save dictionary as a new line in the save file.
		save_game.store_line(to_json(node_data))
	save_game.close()
	

func _on_Load() -> void:
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		i.queue_free()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open("user://savegame.save", File.READ)
	while save_game.get_position() < save_game.get_len():
		 # Get the saved dictionary from the next line in the save file
		var node_data = parse_json(save_game.get_line())
		
		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instance()
		get_node(node_data["parent"]).add_child(new_object)
		new_object.rect_position = Vector2(node_data["pos_x"], node_data["pos_y"])
		
		
		# Now we set the remaining variables.
		for i in node_data.keys():
			if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
				continue
			new_object.set(i, node_data[i])
		
	save_game.close()


func _reset_settings() -> void:
	widthBox.value = 16
	heightBox.value = 16

	sortingModeLever.pressed = false
	printingModeLever.pressed = false
	mirroredModeLever.pressed = false
	
	offsetX.value = 0
	offsetY.value = 0
	
	if imgLoaded:
		endOffsetX.value = currentImage.get_width()
		endOffsetY.value = currentImage.get_height()
	
	else:
		endOffsetX.value = 0
		endOffsetY.value = 0

	inputImage.material.set_shader_param("imgW", endOffsetX.value)
	inputImage.material.set_shader_param("imgH", endOffsetY.value)

func _on_Clear_pressed() -> void:
	_reset_settings()



func _open_Modal(inI, generatedImage) -> void:
	currentModalImage = generatedImages.find(generatedImage)
	modal.visible = true
	modalImage.texture = inI
	modalImage.rect_rotation = generatedImages[currentModalImage].rotated * 90
	modalLabel.text = generatedImage.title
	richModalLabel.text = generatedImage.info

func _on_closeButton_pressed() -> void:
	modal.visible = false


func _on_rightButton_pressed() -> void:	
	if currentModalImage - 1 >= 0:
		currentModalImage -= 1
	else:
		currentModalImage = generatedImages.size() - 1
	
	modalImage.rect_rotation = generatedImages[currentModalImage].rotated * 90
	modalImage.texture = generatedImages[currentModalImage].img
	modalLabel.text = generatedImages[currentModalImage].title
	richModalLabel.text = generatedImages[currentModalImage].info


func _on_leftButton_pressed() -> void:
	if currentModalImage + 1 <= generatedImages.size() - 1:
		currentModalImage += 1
	else:
		currentModalImage = 0
	
	modalImage.texture = generatedImages[currentModalImage].img
	modalLabel.text = generatedImages[currentModalImage].title
	richModalLabel.text = generatedImages[currentModalImage].info
	modalImage.rect_rotation = generatedImages[currentModalImage].rotated * 90


func _on_GameboyGrayscale_toggled(button_pressed: bool) -> void:
	if button_pressed:
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/GameboyGreen.pressed = false
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/VirtualBoy.pressed = false
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/Negative.pressed = false
		filter = button_pressed
		shader = "GB gray"
		
	else:
		filter = button_pressed
	


func _on_GameboyGreen_toggled(button_pressed: bool) -> void:
	if button_pressed:
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/GameboyGrayscale.pressed = false
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/VirtualBoy.pressed = false
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/Negative.pressed = false
		filter = button_pressed
		shader = "GB green"
		
	else:
		filter = button_pressed



func _on_VirtualBoy_toggled(button_pressed: bool) -> void:
	if button_pressed:
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/GameboyGrayscale.pressed = false
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/GameboyGreen.pressed = false
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/Negative.pressed = false
		filter = button_pressed
		shader = "VB"
		
	else:
		filter = button_pressed



func _on_Negative_toggled(button_pressed: bool) -> void:
	if button_pressed:
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/GameboyGrayscale.pressed = false
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/GameboyGreen.pressed = false
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/VirtualBoy.pressed = false
		filter = button_pressed
		shader = "Negative"
		
	else:
		filter = button_pressed

	


func _on_Filter_Clear_pressed() -> void:
	for n in $Sidebar/TabContainer/Filter/ScrollContainer/OptionList.get_children():
		if n is CheckButton:
			n.pressed = false


func _on_download_pressed() -> void:
	generatedImages[currentModalImage]._on_download_pressed()


func _on_Hflip_pressed() -> void:
	hflip = !hflip
	modalImage.flip_h = hflip
	generatedImages[currentModalImage].get_node("Image").flip_h = hflip


func _on_Vflip_pressed() -> void:
	vflip = !vflip
	modalImage.flip_v = vflip
	generatedImages[currentModalImage].get_node("Image").flip_v = vflip


func _on_roatetLeft_pressed() -> void:
	generatedImages[currentModalImage].rotated -= 1
	if generatedImages[currentModalImage].rotated < 0:
		generatedImages[currentModalImage].rotated = 3
	
	modalImage.rect_rotation = 90 * generatedImages[currentModalImage].rotated
	generatedImages[currentModalImage].get_node("Image").rect_rotation = 90 * generatedImages[currentModalImage].rotated
	
	
func _on_rotateRight_pressed() -> void:
	generatedImages[currentModalImage].rotated += 1
	if generatedImages[currentModalImage].rotated > 3:
		generatedImages[currentModalImage].rotated = 0
		
	modalImage.rect_rotation = 90 * generatedImages[currentModalImage].rotated
	generatedImages[currentModalImage].get_node("Image").rect_rotation = 90 * generatedImages[currentModalImage].rotated


func _on_CenterImage_pressed() -> void:
	modalImage.rect_position = Vector2.ZERO
	zoomSlider.value = 1
	modalImage.rect_scale = Vector2.ONE



func _on_ImageBackground_mouse_entered() -> void:
	onModalPic = true


func _on_ImageBackground_mouse_exited() -> void:
	onModalPic = false


func _on_Control_mouse_entered() -> void:
	onModalPic = true


func _on_Control_mouse_exited() -> void:
	onModalPic = false



func _on_Filter_pressed() -> void:
	if imgLoaded:
		widthBox.value = endOffsetX.value
		heightBox.value = endOffsetY.value
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/GameboyGreen.pressed = true
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/GameboyGrayscale.pressed = false
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/VirtualBoy.pressed = false
		$Sidebar/TabContainer/Filter/ScrollContainer/OptionList/Negative.pressed = false
		filter = true
		shader = "GB green"

func _on_offsetX_value_changed(value):
	inputImage.material.set_shader_param("offsetX", value)
func _on_offsetY_value_changed(value):
	inputImage.material.set_shader_param("offsetY", value)
func _on_widthBox_value_changed(value):
	inputImage.material.set_shader_param("checkerW", value)
func _on_heightBox_value_changed(value):
	inputImage.material.set_shader_param("checkerH", value)
