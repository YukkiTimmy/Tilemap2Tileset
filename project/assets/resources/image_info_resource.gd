extends Resource
class_name ImageInfoResource

@export var output_image: Image

@export var input_image_name: String
@export var input_image_size: Vector2i
@export var input_image_file_size: int

@export var tile_size_used: Vector2i

@export var unique_tiles: int
@export var total_tiles_checked: int

@export var total_time_needed: float

@export var checked_orienation: bool

@export var sorted_by: String

var stored_in_tiled_image_item: TiledImageItem

func get_output_image_texture() -> ImageTexture:
	var texture := ImageTexture.new()
	texture.set_image(output_image)
	return texture

func get_formatted_info_string() -> String:
	return str(
		"Unique Tiles: ", unique_tiles, "\n",
		"Tile Size: ", tile_size_used, "\n",
		"Input Image Size: ", input_image_size, "\n",
		"Output Image Size: ", output_image.get_size(), "\n",
		"Total tiles checked: ", total_tiles_checked, "\n",
		"Time: ", total_time_needed, "ms", "\n",
		"Output Image Size: ", output_image.get_data_size() / 1000.0, "KB", "\n",
		"Input Image Size: ", input_image_file_size / 1000.0, "KB", "\n",
		"Checked Orientations: ", checked_orienation, "\n",
		"Sorted by: ", sorted_by, "\n",
	)
