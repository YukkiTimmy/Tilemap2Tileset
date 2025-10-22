class_name UploadImageExample
extends Control

@onready var upload_button: Button = %"Upload Button" as Button
@onready var canvas: TextureRect = %Canvas as TextureRect
@onready var progress: ProgressBar = %"Progress Bar" as ProgressBar

var file_access_web: FileAccessWeb = FileAccessWeb.new()
var image_type: String = ".jpg"

func _ready() -> void:
	upload_button.pressed.connect(_on_upload_pressed)
	file_access_web.loaded.connect(_on_file_loaded)
	file_access_web.progress.connect(_on_progress)
	file_access_web.upload_cancelled.connect(_on_upload_cancelled)

func _on_upload_pressed() -> void:
	file_access_web.open(image_type)

func _on_upload_cancelled() -> void:
	print("user cancelled the file upload")

func _on_progress(current_bytes: int, total_bytes: int) -> void:
	var percentage: float = float(current_bytes) / float(total_bytes) * 100
	progress.value = percentage

func _on_file_loaded(file_name: String, type: String, base64_data: String) -> void:
	var raw_data: PackedByteArray = Marshalls.base64_to_raw(base64_data)
	raw_draw(type, raw_data)

func raw_draw(type: String, data: PackedByteArray) -> void:
	var image := Image.new()
	var error: int = _load_image(image, type, data)
	
	if not error:
		canvas.texture = _create_texture_from(image)
	else:
		push_error("Error %s id" % error)

func _load_image(image: Image, type: String, data: PackedByteArray) -> int:
	match type:
		"image/png":
			return image.load_png_from_buffer(data)
		"image/jpeg":
			return image.load_jpg_from_buffer(data)
		"image/webp":
			return image.load_webp_from_buffer(data)
		_:
			return Error.FAILED

func _create_texture_from(image: Image) -> ImageTexture:
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture
