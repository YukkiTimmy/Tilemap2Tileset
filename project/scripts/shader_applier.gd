extends Control

@onready var viewport := $SubViewport
@onready var texture_rect  := $SubViewport/ShaderTextureRect

func get_image_with_shader(image : Image, shader_resource : ShaderMaterial) -> Image:
	_setup(image)
	_apply_shader(shader_resource)
	var output_image = await _get_image()
	return output_image

func _setup(image : Image) -> void:
	viewport.size = image.get_size()
	
	var texture := ImageTexture.new()
	texture.set_image(image)
	
	texture_rect.texture = texture
	
func _apply_shader(shader_resource : ShaderMaterial) -> void:
	texture_rect.material = shader_resource

func _get_image() -> Image:
	var _texture = viewport.get_texture()
	await RenderingServer.frame_post_draw
	
	await get_tree().create_timer(0.1).timeout
	var image = viewport.get_texture().get_image()

	
	return image
