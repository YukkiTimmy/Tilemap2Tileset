extends Node
class_name Tiler

signal image_ready(output_package: Dictionary)
@warning_ignore("unused_signal")
signal get_total_tiles_to_check(total_tiles_to_check: int)

# Tile settings
var TILE_WIDTH : int = 16
var TILE_HEIGHT : int = 16

var OFFSET_RECT : Rect2i = Rect2i(0,0,0,0)


var CHECK_ORIENTATION := true
var SORT_TILES_BY := "None"

#Information variables
var unique_tile_counter := 0

var start_time : float = 0
var end_time : float = 0

var total_tiles_to_check : int = 0
var current_tiles_checked : int = 0

var should_stop := false

func _run_threaded(tiler_settings : Dictionary) -> void:
	should_stop = false
	
	start_time = Time.get_ticks_msec()
	
	# Set Settings
	TILE_WIDTH = tiler_settings.tile_width
	TILE_HEIGHT = tiler_settings.tile_height
	
	OFFSET_RECT = tiler_settings.offset_rect
	
	var input_image = tiler_settings.input_image
	var input_image_name = tiler_settings.file_name

	CHECK_ORIENTATION = tiler_settings.check_orientation

	SORT_TILES_BY = tiler_settings.sort_by

	total_tiles_to_check = int(input_image.get_width() / TILE_WIDTH * input_image.get_height() / TILE_HEIGHT)
	
	if CHECK_ORIENTATION:
		total_tiles_to_check *= 8

	call_deferred("emit_signal", "get_total_tiles_to_check", total_tiles_to_check)

	if should_stop:
		return

	# Start tiling the image
	var output_image := _generate_unique_tile_image(input_image)
	
	if should_stop:
		return
	
	# Create ImageInfoResource to hold important data
	var info_resource := ImageInfoResource.new()
	info_resource.output_image = output_image
	info_resource.input_image_name = input_image_name
	info_resource.input_image_size = input_image.get_size()
	info_resource.tile_size_used = Vector2i(TILE_WIDTH, TILE_HEIGHT)
	info_resource.unique_tiles = unique_tile_counter
	info_resource.total_tiles_checked = total_tiles_to_check
	info_resource.total_time_needed = end_time - start_time
	info_resource.input_image_file_size = input_image.get_data_size()
	info_resource.checked_orienation = CHECK_ORIENTATION
	info_resource.sorted_by = SORT_TILES_BY
	
	
	call_deferred("_on_finished", info_resource)

func _on_finished(info_resource: ImageInfoResource) -> void:
	emit_signal("image_ready", info_resource)
	

func _generate_unique_tile_image(input_image: Image) -> Image:
	var unique_tiles := _extract_unique_tiles(input_image)
	
	unique_tile_counter = unique_tiles.size()
	
	if should_stop:
		return Image.new()
	
	end_time = Time.get_ticks_msec()
	
	unique_tiles = _sort_unique_tiles(unique_tiles)
	
	return _compose_output_image(unique_tiles, input_image.get_format())

func _extract_unique_tiles(image: Image) -> Array:
	@warning_ignore("integer_division")
	var rows : int = floor((image.get_height() - OFFSET_RECT.position.y - OFFSET_RECT.size.y) / TILE_HEIGHT)
	@warning_ignore("integer_division")
	var cols : int = floor((image.get_width() - OFFSET_RECT.position.x - OFFSET_RECT.size.x) / TILE_WIDTH)

	var seen := {}  
	var unique_tiles := [] 
	var tile_map := {} 

	var tile_id = 0

	for row in range(rows):
		for col in range(cols):
			if should_stop:
				return []
			
			var tile_data := _extract_tile(image, col, row)
			
			#var base_hash = _image_hash(tile_data)
						
			var hashes := _generate_all_orientation_hashes(tile_data)

			var found_tile_id = null
			for h in hashes:
				if seen.has(h):
					found_tile_id = seen[h]
					break

			if found_tile_id != null:
				tile_map[found_tile_id]["amount"] += 1
			else:
				for h in hashes:
					seen[h] = tile_id

				var tile = {
					"tile_id": tile_id,
					"tile_data": tile_data,
					"amount": 1,
				}
				unique_tiles.append(tile)
				tile_map[tile_id] = tile
				tile_id += 1

	return unique_tiles

func _extract_tile(image: Image, col: int, row: int) -> Image:
	var pos := Vector2i(col * TILE_WIDTH + OFFSET_RECT.position.x, row * TILE_HEIGHT + OFFSET_RECT.position.y)
	var size := Vector2i(TILE_WIDTH, TILE_HEIGHT)
	var tile_data := Image.create(size.x, size.y, false, image.get_format())

	tile_data.blit_rect(image, Rect2i(pos, size), Vector2i(0, 0))

	return tile_data

func _compose_output_image(tiles: Array, format: int) -> Image:
	var count := tiles.size()
	var grid := int(ceil(sqrt(count)))

	var output := Image.create(grid * TILE_WIDTH, grid * TILE_HEIGHT, false, format)

	var i := 0
	for y in range(grid):
		for x in range(grid):
			if i >= count: break
			output.blit_rect(
				tiles[i].tile_data,
				Rect2i(Vector2i.ZERO, Vector2i(TILE_WIDTH, TILE_HEIGHT)),
				Vector2i(x * TILE_WIDTH, y * TILE_HEIGHT)
			)
			i += 1

	return output

func _image_hash(image: Image) -> int:
	current_tiles_checked += 1
	return hash(image.get_data())


# manipulating an dupliacted image over the base image (via tile.duplicate()) saved in average 16% time
func _generate_all_orientation_hashes(tile: Image) -> Array:
	var hashes: Array = []
	hashes.append(_image_hash(tile))

	if not CHECK_ORIENTATION:
		return hashes

	var tmp := tile.duplicate()
	tmp.flip_x()
	hashes.append(_image_hash(tmp))

	tmp.flip_y()
	hashes.append(_image_hash(tmp))

	tmp = tile.duplicate()
	tmp.flip_y()
	hashes.append(_image_hash(tmp))

	var rotated := _rotate_image(tile)
	hashes.append(_image_hash(rotated))

	tmp = rotated.duplicate()
	tmp.flip_x()
	hashes.append(_image_hash(tmp))

	tmp.flip_y()
	hashes.append(_image_hash(tmp))

	tmp = rotated.duplicate()
	tmp.flip_y()
	hashes.append(_image_hash(tmp))

	return hashes


func _rotate_image(tile: Image) -> Image:
	var rotated := Image.create(TILE_WIDTH, TILE_HEIGHT, false, tile.get_format())

	for y in TILE_HEIGHT:
		for x in TILE_WIDTH:
			rotated.set_pixel(y, x, tile.get_pixel(x, y))

	return rotated



func _compare_tile_amount(a, b) -> bool:
	return a["amount"] > b["amount"]


func _compare_by_brightness(a, b) -> bool:
	var brightness_a := get_average_brightness(a["tile_data"])
	var brightness_b := get_average_brightness(b["tile_data"])
	return brightness_a < brightness_b


func get_average_brightness(image: Image) -> float:
	var total_brightness := 0.0
	var width := image.get_width()
	var height := image.get_height()

	for y in range(height):
		for x in range(width):
			var color: Color = image.get_pixel(x, y)
			var brightness := (color.r + color.g + color.b) / 3.0
			total_brightness += brightness

	return total_brightness / float(width * height)


func _sort_unique_tiles(unique_tiles: Array) -> Array:
	match SORT_TILES_BY:
		"Amount":
			unique_tiles.sort_custom(_compare_tile_amount)
		"Brightness":
			unique_tiles.sort_custom(_compare_by_brightness)
		"Dominant Color":
			unique_tiles.sort_custom(_compare_by_dominant_color)
		"Cluster by Color":
			return cluster_tiles_by_dominant_color(unique_tiles)
	return unique_tiles


func _compare_by_dominant_color(a, b) -> bool:
	var dom_a := get_dominant_color_channel(a["tile_data"])
	var dom_b := get_dominant_color_channel(b["tile_data"])
	return dom_a < dom_b 


func get_dominant_color_channel(image: Image) -> int:
	var total_r := 0.0
	var total_g := 0.0
	var total_b := 0.0
	var width := image.get_width()
	var height := image.get_height()

	for y in range(height):
		for x in range(width):
			var color: Color = image.get_pixel(x, y)
			total_r += color.r
			total_g += color.g
			total_b += color.b

	if total_r >= total_g and total_r >= total_b:
		return 0  
	elif total_g >= total_r and total_g >= total_b:
		return 1  
	else:
		return 2  

func cluster_tiles_by_dominant_color(unique_tiles: Array) -> Array:
	var red_tiles: Array = []
	var green_tiles: Array = []
	var blue_tiles: Array = []

	for tile in unique_tiles:
		var dominant := get_dominant_color_channel(tile["tile_data"])
		match dominant:
			0:  # red
				red_tiles.append(tile)
			1:  # green
				green_tiles.append(tile)
			2:  # blue
				blue_tiles.append(tile)

	# Du kannst die Reihenfolge hier beliebig ändern
	return red_tiles + green_tiles + blue_tiles

func stop():
	should_stop = true
