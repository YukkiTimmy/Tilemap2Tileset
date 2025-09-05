extends Control

@onready var display_image := %OutputImageTextureRect

@onready var output_filename := %Filename_Line
@onready var output_path :=  %OutputPath_Line

@onready var save_dialog := $SaveDialog

var current_output_image : Image = null

var TILE_WIDTH := 16
var TILE_HEIGHT := 16
var TILE_AMOUNT := 1


func show_modal(info_resource : ImageInfoResource) -> void:
	self.visible = true
	display_image.texture = info_resource.get_output_image_texture()
	output_filename.placeholder_text = info_resource.input_image_name

	current_output_image = info_resource.output_image

	TILE_WIDTH = info_resource.tile_size_used.x
	TILE_HEIGHT = info_resource.tile_size_used.y
	TILE_AMOUNT = info_resource.unique_tiles


func _on_close_button_pressed() -> void:
	self.visible = false
	
	
func _on_path_chosen(save_path: String) -> void:
	print(save_path)
	var err := current_output_image.save_png(save_path)
	if err != OK:
		push_error("Couldnt save image: " + save_path)
	else:
		print("Imaged save under: ", save_path)


func _on_save_dialog_dir_selected(dir: String) -> void:
	output_path.text = dir


func _on_output_path_button_pressed() -> void:
	save_dialog.popup_centered()



func _save_image_to_path(path : String, image : Image) -> void:
	var err := image.save_png(path)
	if err != OK:
		push_error("Couldnt save image: " + path)
	else:
		print("Imaged save under: ", path)

func _create_dir_at_path(path : String, dir_name : String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Konnte Basisverzeichnis nicht öffnen: " + path)
		return

	var save_path = path + dir_name
	
	if not dir.dir_exists(save_path):
		var err := dir.make_dir(save_path)
		if err != OK:
			push_error("Konnte Verzeichnis nicht erstellen: " + save_path)
			return
	else:
		print("Verzeichnis existiert bereits:", save_path)


func _on_save_single_image_pressed() -> void:
	var save_path = str(output_path.text, '/', output_filename.placeholder_text, '.png')
	_save_image_to_path(save_path, current_output_image)


func _on_save_multiple_images_pressed() -> void:
	var base_path := str(output_path.text, '/')
	var folder_name := str(output_filename.placeholder_text, "_output")
	
	_create_dir_at_path(base_path, folder_name)

	var rows := int(current_output_image.get_height() / TILE_HEIGHT)
	var cols := int(current_output_image.get_width() / TILE_WIDTH)

	var count := 0

	for row in range(rows):
		for col in range(cols):
			if count >= TILE_AMOUNT:
				return
			
			var pos := Vector2i(col * TILE_WIDTH, row * TILE_HEIGHT)
			var tile_size := Vector2i(TILE_WIDTH, TILE_HEIGHT)
			var tile_data := Image.create(tile_size.x, tile_size.y, false, current_output_image.get_format())

			tile_data.blit_rect(current_output_image, Rect2i(pos, tile_size), Vector2i(0, 0))

			var tile_save_path := str(base_path, folder_name, "/", count, "_", output_filename.placeholder_text, ".png")
			_save_image_to_path(tile_save_path, tile_data)
			
			count += 1


func _on_save_tile_set_pressed() -> void:
	var base_path := str(output_path.text, '/')
	var folder_name := str(output_filename.placeholder_text, "_output")

	_create_dir_at_path(base_path, folder_name)


	var save_path = base_path + folder_name
	var atlas_path := save_path.path_join(output_filename.placeholder_text + "_atlas.png")
	var tileset_path := save_path.path_join(output_filename.placeholder_text + "_tileset.tres")

	_create_tileset_from_atlas(
		current_output_image,
		Vector2i(TILE_WIDTH, TILE_HEIGHT),
		TILE_AMOUNT,
		tileset_path,
		atlas_path
	)


func _create_tileset_from_atlas(image: Image, tile_size: Vector2i, tile_count: int, tileset_save_path: String, atlas_texture_path: String) -> void:
	_save_image_to_path(atlas_texture_path, image)

	var loaded_image := Image.load_from_file(atlas_texture_path)
	if loaded_image == null:
		push_error("Fehler beim Laden des gespeicherten Atlas-Bildes.")
		return

	var texture := ImageTexture.new()
	texture.set_image(loaded_image) 

	var tileset := TileSet.new()
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = tile_size

	var cols := image.get_width() / tile_size.x
	var rows := image.get_height() / tile_size.y

	var count := 0
	for row in range(rows):
		for col in range(cols):
			if count >= tile_count:
				break
			var atlas_coords := Vector2i(col, row)
			atlas.create_tile(atlas_coords, Vector2i(1, 1))
			count += 1
		if count >= tile_count:
			break

	tileset.add_source(atlas)

	var ts_err := ResourceSaver.save(tileset, ProjectSettings.localize_path(tileset_save_path))
	if ts_err != OK:
		push_error("Fehler beim Speichern des Tilesets: " + str(ts_err))
	else:
		print("✅ Tileset erfolgreich gespeichert unter:", tileset_save_path)
