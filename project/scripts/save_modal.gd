extends Control

@onready var display_image := %OutputImageTextureRect

@onready var output_filename := %Filename_Line
@onready var output_path :=  %OutputPath_Line

@onready var output_path_btn := $MainContainer/MainContainerBackground_Cont/MainContainer_MargCont/MainContainer_VBox/MainContent_HBox/SaveOptions_VBox/OutputPath_HBox/OutputPathBtn

@onready var save_dialog := $SaveDialog

var current_output_image : Image = null

var TILE_WIDTH := 16
var TILE_HEIGHT := 16
var TILE_AMOUNT := 1

var MAIN_SCENE : main_scene = null


func show_modal(info_resource : ImageInfoResource) -> void:
	if OS.get_name() == "Web":
		output_path.editable = false
		output_path.text = "Doesn't work on the web version"
		output_path_btn.disabled = true
	
	self.visible = true
	MAIN_SCENE = get_tree().get_root().get_node("Main")  
	
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
	if OS.get_name() != "Web":
		var err := image.save_png(path)
		if err != OK:
			push_error("Couldnt save image: " + path)
			MAIN_SCENE.create_popup("Error while saving Image!", "Image couldn't be saved:\n" + path, main_scene.POPUP_TYPES.warning)
		else:
			print("Imaged save under: ", path)
	else:
		var buffer := image.save_png_to_buffer()
		JavaScriptBridge.download_buffer(buffer, "%s.png" % "my_filename", "image/png")
			
		

func _create_dir_at_path(path : String, dir_name : String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		MAIN_SCENE.create_popup("Error with directory", "Couldn't open the Directorty:\n" + path, main_scene.POPUP_TYPES.warning)

		return

	var save_path = path + dir_name
	
	if not dir.dir_exists(save_path):
		var err := dir.make_dir(save_path)
		if err != OK:
			MAIN_SCENE.create_popup("Error with directory", "Couldn't open the Directorty:\n" + path, main_scene.POPUP_TYPES.warning)
			return
	else:
		print("Verzeichnis existiert bereits:", save_path)


func _on_save_single_image_pressed() -> void:
	var save_path = str(output_path.text, '/', output_filename.placeholder_text, '.png')
	_save_image_to_path(save_path, current_output_image)
	
	MAIN_SCENE.create_popup("Image Saved!", "Image saved in:\n " + save_path, main_scene.POPUP_TYPES.info)


func _on_save_multiple_images_pressed() -> void:
	var base_path := str(output_path.text, '/')
	var folder_name := str(output_filename.placeholder_text, "_output")
	
	@warning_ignore("integer_division")
	var rows := int(current_output_image.get_height() / TILE_HEIGHT)
	@warning_ignore("integer_division")
	var cols := int(current_output_image.get_width() / TILE_WIDTH)

	var count := 0

	# Desktop-Version
	if OS.get_name() != "Web":
		_create_dir_at_path(base_path, folder_name)

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

		MAIN_SCENE.create_popup("Image Saved!", "Image saved in:\n" + base_path, main_scene.POPUP_TYPES.info)
		return
	
	else:
		# --- Web-Version ---
		var file_map := {}
		for row in range(rows):
			for col in range(cols):
				if count >= TILE_AMOUNT:
					break
					
				var pos := Vector2i(col * TILE_WIDTH, row * TILE_HEIGHT)
				var tile_size := Vector2i(TILE_WIDTH, TILE_HEIGHT)
				var tile_data := Image.create(tile_size.x, tile_size.y, false, current_output_image.get_format())
				tile_data.blit_rect(current_output_image, Rect2i(pos, tile_size), Vector2i(0, 0))

				tile_data.flip_y()
				var png_data = tile_data.save_png_to_buffer()
				var base64_str = Marshalls.raw_to_base64(png_data)

				var filename = str(count, "_", output_filename.placeholder_text, ".png")
				file_map[filename] = base64_str

				count += 1

		# Web-Download über JavaScriptBridge
		var json = JSON.stringify(file_map)
		JavaScriptBridge.eval("window.downloadZip(" + json + ")")

	MAIN_SCENE.create_popup("Download Ready!", "Your images have been prepared for download.", main_scene.POPUP_TYPES.info)

func _on_save_tile_set_pressed() -> void:
	var base_path := str(output_path.text, '/')
	var folder_name := str(output_filename.placeholder_text, "_output")
	var save_path = base_path + folder_name
	var atlas_path := save_path.path_join(output_filename.placeholder_text + "_atlas.png")
	var tileset_path := save_path.path_join(output_filename.placeholder_text + "_tileset.tres")

	# --- Desktop-Version (unverändert) ---
	if OS.get_name() != "Web":
		_create_dir_at_path(base_path, folder_name)

		_create_tileset_from_atlas(
			current_output_image,
			Vector2i(TILE_WIDTH, TILE_HEIGHT),
			TILE_AMOUNT,
			tileset_path,
			atlas_path
		)
		return

	# --- Web-Version ---
	# Wir erzeugen alles im Speicher und übergeben es an JSZip.
	var atlas_img := current_output_image.duplicate()
	atlas_img.flip_y()
	var atlas_png = atlas_img.save_png_to_buffer()
	var atlas_base64 := Marshalls.raw_to_base64(atlas_png)
	var atlas_filename := str(output_filename.placeholder_text, "_atlas.png")

	# Tileset-Datei als Text exportieren (im Speicher)
	var tileset_text := _generate_tileset_tres_text(
		atlas_filename,
		Vector2i(TILE_WIDTH, TILE_HEIGHT),
		TILE_AMOUNT,
		atlas_img.get_width(),
		atlas_img.get_height()
	)
	var tileset_base64 := Marshalls.raw_to_base64(tileset_text.to_utf8_buffer())
	var tileset_filename := str(output_filename.placeholder_text, "_tileset.tres")

	# Dateien zusammenpacken und Download auslösen
	var file_map = {
		atlas_filename: atlas_base64,
		tileset_filename: tileset_base64
	}
	var json := JSON.stringify(file_map)
	JavaScriptBridge.eval("window.downloadZip(" + json + ")")

	MAIN_SCENE.create_popup(
		"Download Ready!",
		"Your Tileset and Atlas are ready for download.",
		main_scene.POPUP_TYPES.info
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

	@warning_ignore("integer_division")
	var cols := image.get_width() / tile_size.x
	@warning_ignore("integer_division")
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
		MAIN_SCENE.create_popup("Error while saving Tileset!", "Tielset couldn't be saved:\n" + str(ts_err), main_scene.POPUP_TYPES.warning)
	else:
		print("Tileset saved in:", tileset_save_path)
		MAIN_SCENE.create_popup("Tilset Saved!", "Tileset saved in:\n " + tileset_save_path, main_scene.POPUP_TYPES.info)


func _generate_tileset_tres_text(atlas_filename: String, tile_size: Vector2i, tile_count: int, atlas_w: int, atlas_h: int) -> String:
	var cols := int(atlas_w / tile_size.x)
	if cols <= 0:
		cols = 1

	var text := "[gd_resource type=\"TileSet\" format=3]\n\n"
	text += "[ext_resource path=\"" + atlas_filename + "\" type=\"Texture2D\" id=1]\n\n"
	text += "[resource]\n"

	for i in range(tile_count):
		var tx := (i % cols) * tile_size.x
		var ty := int(i / cols) * tile_size.y
		text += "tile/%d/name = \"tile_%d\"\n" % [i, i]
		text += "tile/%d/texture = ExtResource( 1 )\n" % i
		text += "tile/%d/region = Rect2( %d, %d, %d, %d )\n\n" % [i, tx, ty, tile_size.x, tile_size.y]

	text += "# Auto-generated tileset for Web export\n"
	return text
