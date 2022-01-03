extends Control

signal _done

onready var viewport = $ViewportContainer/Viewport
onready var viewportImage = $ViewportContainer/Viewport/Image
onready var viewportShader = $ViewportContainer/Viewport/Shader

var shader : String = ""

var inputImage : Texture = null

var outputImage = null

	
func getViewportImage(inputImage : Texture):
	viewportShader.material.set_shader_param("blackAndWhite", false)
	viewportShader.material.set_shader_param("gameboy", false)
	viewportShader.material.set_shader_param("virtualBoy", false)
	viewportShader.material.set_shader_param("negative", false)
	
	match shader:
		"GB gray":
			viewportShader.material.set_shader_param("blackAndWhite", true)

		"GB green":
			viewportShader.material.set_shader_param("gameboy", true)
		
		"VB":
			viewportShader.material.set_shader_param("virtualBoy", true)
			
		"Negative":
			viewportShader.material.set_shader_param("negative", true)
	
	viewportImage.texture = inputImage
	
	var inputImageSize = inputImage.get_size()
	viewport.size = inputImageSize
	
	viewportImage.position.x = inputImageSize.x / 2
	viewportImage.position.y = inputImageSize.y / 2
	
	viewportShader.rect_size = inputImageSize
	
	yield(get_tree().create_timer(0.15), "timeout")
	
	var img = viewport.get_texture().get_data()
	img.flip_y()
	
	# Debug output
#	img.save_png("image.png")
	
	outputImage = img

	
	emit_signal("_done")
