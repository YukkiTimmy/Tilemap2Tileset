extends Control

@onready var viewport := $SubViewport
@onready var texture_rect  := $SubViewport/TextureRect

func get_image_with_shader(image : Image, shader_resource : ShaderMaterial) -> Image:
	_setup(image)
	_apply_shader(shader_resource)
	var output_image = await _get_image()
	return output_image

func _setup(image : Image) -> void:
	viewport.size = image.get_size()
	
	var texture := ImageTexture.new()
	texture.set_image(image)

	
func _apply_shader(shader_resource : ShaderMaterial) -> void:
	texture_rect.material = shader_resource


func _get_image() -> Image:
	var texture = viewport.get_texture()
	await RenderingServer.frame_post_draw
	
	var image = texture.get_image()
	
	return image
