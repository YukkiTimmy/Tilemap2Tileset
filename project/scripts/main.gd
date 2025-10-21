extends Control
class_name main_scene

enum POPUP_TYPES {
	warning,
	info
}

var LOADED_IMAGE : Image = null
var LOADED_TEXTURE : ImageTexture = null
var CURRENT_FILE_NAME : String

var SELECTED_TILE_WIDTH := 16
var SELECTED_TILE_HEIGHT := 16

var SELECTED_OFFSET : Rect2i = Rect2i(0,0,0,0)
var use_offset := false

var CHECK_ORIENTATION := false
var SORT_TILES_BY := "None"
var SHADER_TO_APPLY : ShaderMaterial = null

var CURRENT_TILER : Tiler = null

var tiler_thread: Thread = null
var thread_running := false

# UI: Image Preview
@onready var zoom_container := %ZoomContainer
@onready var image_preview := %InputImageTextureRect

# UI: Tile Settings
@onready var manual_tile_size_spinbox_x := %ManualTileSizeX_Spin
@onready var manual_tile_size_spinbox_y := %ManualTileSizeY_Spin
@onready var sorting_options := %SortOptionButton_Opt
@onready var shader_options := %ApplyShader_Opt

@onready var offset_x1 := %OffsetX1_Spin
@onready var offset_y1 := %OffsetY1_Spin
@onready var offset_x2 := %OffsetX2_Spin
@onready var offset_y2 := %OffsetY2_Spin

# UI: Information
@onready var tiling_progess_bar := %ProgressBar

# UI: Modals
@onready var tile_detail_modal := $TileDetailModal
@onready var save_tile_modal := $SaveModal

# UI: Output
@onready var tiled_image_list := $%TiledImagesList_VBox

# UI: Shader/Viewport
@onready var shader_applier := $ShaderApplier
@onready var custom_shader := %CustomShaderDropZone

# UI: Input
@onready var loaded_images_list := %LoadedImages_GridCont

# UI: Info
@onready var popup_container := $PopUpContainer_VBox

# UI: MenuBar
@onready var menu_button_file := $MainHboxContainer/SidebarBackground_Cont/HBoxContainer/Options_VBox/File
@onready var menu_button_tiler_settings := $MainHboxContainer/SidebarBackground_Cont/HBoxContainer/Options_VBox/TilerSettings
@onready var menu_button_settings:= $MainHboxContainer/SidebarBackground_Cont/HBoxContainer/Options_VBox/Settings
@onready var menu_button_help := $MainHboxContainer/SidebarBackground_Cont/HBoxContainer/Options_VBox/Help

@onready var image_file_dialog := $ImageFileDialog

func _ready() -> void:
	get_tree().get_root().files_dropped.connect(_on_files_dropped)
	
	menu_button_file.get_popup().id_pressed.connect(_on_menu_button_file_pressed)
	menu_button_tiler_settings.get_popup().id_pressed.connect(_on_menu_button_tiler_settings_pressed)
	menu_button_settings.get_popup().id_pressed.connect(_on_menu_button_settings_pressed)
	menu_button_help.get_popup().id_pressed.connect(_on_menu_button_help_pressed)



func _process(_delta: float) -> void:
	if CURRENT_TILER:
		tiling_progess_bar.value = CURRENT_TILER.current_tiles_checked
	
	#var texture_rect_shader = image_preview.material
	#texture_rect_shader.set_shader_parameter("mouse_pos", image_preview.get_local_mouse_position())

func _on_files_dropped(files: PackedStringArray) -> void:
	if files.is_empty():
		push_error("No files fiven")
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	for node in get_tree().get_nodes_in_group("image_drop_target"):
		if node is Control and node.get_global_rect().has_point(mouse_pos):
			_handle_uploaded_images(files)
			return
	
	for node in get_tree().get_nodes_in_group("shader_drop_target"):
		if node is Control and node.get_global_rect().has_point(mouse_pos):
			_handle_dropped_shader(files)
			return

func _on_file_dialog_files_selected(files: PackedStringArray) -> void:
	_handle_uploaded_images(files)

func _handle_uploaded_images(files: PackedStringArray) -> void:
	if files.is_empty():
		push_error("Keine Datei übergeben.")
		return
	
	var uploaded_images : Array = []
	
	for path in files:
		var ext := path.get_extension().to_lower()
		var valid_extensions := ["png", "jpg", "jpeg", "bmp", "gif", "tga", "webp"]
		if valid_extensions.has(ext):
			uploaded_images.append(path)
			
	
	if uploaded_images.is_empty():
		push_error("No file has a valid image extension: ")
		return
	
	var loaded_images =  loaded_images_list.get_children()
	var loaded_images_paths = []
	for item in loaded_images:
		loaded_images_paths.append(item.saved_path)
	
	var current_uploaded_image
	
	while not uploaded_images.is_empty():
		current_uploaded_image = uploaded_images.pop_front()
		
		if loaded_images_paths.find(current_uploaded_image) != -1:
			continue

		var tmp_image = Image.new()
		var err = tmp_image.load(current_uploaded_image)
		
		if err != OK:
			push_error("Error while loading the image: " + current_uploaded_image)
			return
		
		if tmp_image.get_format() != Image.FORMAT_RGBA8:
			tmp_image.convert(Image.FORMAT_RGBA8)

		if tmp_image.get_data().size() == 0:
			push_error("converted image has no data. Check the original image.")
			return
		
		var texture = ImageTexture.new()
		texture.set_image(tmp_image)

		create_loaded_image_item(texture, tmp_image, current_uploaded_image)
			
	
	if not current_uploaded_image:
		push_error("No current_uploaded_image found")
		return
	
	CURRENT_FILE_NAME = current_uploaded_image.get_file().get_basename()
	
	var image = Image.new()
	image.load(current_uploaded_image)
	set_loaded_image(image, CURRENT_FILE_NAME)
	
	create_popup("Image uploaded successfully!", str("Image with the name: \n" + current_uploaded_image.get_file() + "\nhas been uploaded!"), POPUP_TYPES.info)



func _handle_dropped_shader(files: PackedStringArray) -> void:
	var path = files[0]
	custom_shader.text = path.get_file()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Error with opening the shader-file: " + path)
		return

	var shader_code := file.get_as_text()
	file.close()

	if shader_code.strip_edges() == "":
		push_error("Shader-file is empty or unvalid: " + path)
		return

	var shader := Shader.new()
	shader.code = shader_code

	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader

	SHADER_TO_APPLY = shader_material
	print(SHADER_TO_APPLY)
	print("Shader loaded successfully:", path)

func set_loaded_image(image, filename = null) -> Texture2D:
	var texture = ImageTexture.new()
	texture.set_image(image)

	image_preview.texture = texture

	LOADED_IMAGE = image
	LOADED_TEXTURE = texture
	if filename: 
		CURRENT_FILE_NAME = filename
	
	return texture

func _on_tile_button_pressed() -> void:
	if not LOADED_IMAGE:
		push_error("no image found.")
		create_popup("No Image Found", "You didn't provide an Image! \n or the image is corrupted!", POPUP_TYPES.warning)
		return
	

	if CURRENT_TILER or thread_running:
		create_popup("Another Process is running!", "You can't start a new tiler process while another is running \n Wait for the other process to finish!", POPUP_TYPES.warning)
		return

	
	SELECTED_TILE_WIDTH = manual_tile_size_spinbox_x.value
	SELECTED_TILE_HEIGHT = manual_tile_size_spinbox_y.value

	if LOADED_IMAGE.get_size().x % SELECTED_TILE_WIDTH != 0 or LOADED_IMAGE.get_size().y % SELECTED_TILE_HEIGHT != 0:
		create_popup("Tile dimensions don't match!", "The given image isn't dividable by the Tilesize given! \n Change the Tilesize or the Offset!", POPUP_TYPES.warning)
		return
	
	if not use_offset:
		SELECTED_OFFSET = Rect2i(0,0,0,0)
	
	else:
		if (LOADED_IMAGE.get_size().x - SELECTED_OFFSET.position.x - SELECTED_OFFSET.size.x) % SELECTED_TILE_WIDTH != 0 or (LOADED_IMAGE.get_size().y - SELECTED_OFFSET.position.y - SELECTED_OFFSET.size.y) % SELECTED_TILE_HEIGHT != 0:
			create_popup("Offset dimensions don't match!", "The given image isn't dividable by the Offset given! \n Change the Tilesize or the Offset!", POPUP_TYPES.warning)
			return
	
	var tiler_settings = {
		"input_image": LOADED_IMAGE,
		"file_name": CURRENT_FILE_NAME,
		"tile_width": SELECTED_TILE_WIDTH,
		"tile_height": SELECTED_TILE_HEIGHT,
		"offset_rect": SELECTED_OFFSET,
		"check_orientation": CHECK_ORIENTATION,
		"sort_by": SORT_TILES_BY,
	}

	var tiler_scene = preload("res://scenes/tiler.tscn")
	var tiler_instance = tiler_scene.instantiate()
	tiler_instance.connect("image_ready", Callable(self, "_on_tiling_finished"))
	tiler_instance.connect("get_total_tiles_to_check", Callable(self, "_on_set_progress_max"))
	add_child(tiler_instance)

	CURRENT_TILER = tiler_instance


	tiler_thread = Thread.new()
	thread_running = true
	var callable = Callable(tiler_instance, "_run_threaded").bind(tiler_settings)
	tiler_thread.start(callable)
	
func _on_tiling_finished(info_resource: ImageInfoResource) -> void:
	var tiled_image_item_scene = preload("res://scenes/tiled_image_item.tscn")
	var tiled_image_item_instance = tiled_image_item_scene.instantiate()
	
	if SHADER_TO_APPLY:
		var image_with_shader = await shader_applier.get_image_with_shader(info_resource.output_image, SHADER_TO_APPLY)
		info_resource.output_image = image_with_shader
		
	tiled_image_item_instance.call_deferred("setup", info_resource)
	
	tiled_image_list.add_child(tiled_image_item_instance)
	
	CURRENT_TILER.queue_free()
	CURRENT_TILER = null
	
	tiling_progess_bar.value = tiling_progess_bar.max_value

	if tiler_thread:
		tiler_thread.wait_to_finish()
		tiler_thread = null
		thread_running = false
	
	create_popup("Generated TileSet", str("The Image: \n" + info_resource.input_image_name + "\nis done tiling!"), POPUP_TYPES.info)


func _on_stop_tiling_btn_pressed() -> void:
	if CURRENT_TILER:
		CURRENT_TILER.stop()
	else:
		return

	if tiler_thread and thread_running:
		if tiler_thread.is_alive():
			tiler_thread.wait_to_finish()

		tiler_thread = null
		thread_running = false

	if CURRENT_TILER:
		CURRENT_TILER.queue_free()
		CURRENT_TILER = null

	tiling_progess_bar.value = tiling_progess_bar.max_value

	create_popup("Tiling Stopped", str("The current tiling process has been stopped\nby the user!"), POPUP_TYPES.info)
	

	
func _on_set_progress_max(total_tiles_to_check : int):
	tiling_progess_bar.value = 0
	tiling_progess_bar.max_value = total_tiles_to_check


func _on_tile_size_btn_pressed(extra_arg_0: Vector2i) -> void:
	manual_tile_size_spinbox_x.value = extra_arg_0.x
	manual_tile_size_spinbox_y.value = extra_arg_0.y


func _on_check_orienation_button_check_toggled(toggled_on: bool) -> void:
	CHECK_ORIENTATION = toggled_on

func _on_sort_button_toggled(toggled_on: bool) -> void:
	sorting_options.visible = toggled_on
	if toggled_on:
		SORT_TILES_BY = sorting_options.get_item_text(sorting_options.selected)
	else:
		SORT_TILES_BY = "None"

func _on_sort_option_button_item_selected(_index: int) -> void:
	SORT_TILES_BY = sorting_options.get_item_text(sorting_options.selected)


func _on_apply_shader_check_toggled(toggled_on: bool) -> void:
	shader_options.visible = toggled_on
	if toggled_on:
		var shader_name = shader_options.get_item_text(shader_options.selected)
		SHADER_TO_APPLY = _get_shader(shader_name)
	else:
		SHADER_TO_APPLY = null
		


func _on_apply_shader_opt_item_selected(_index: int) -> void:
	var shader_name = shader_options.get_item_text(shader_options.selected)
	
	if shader_name == "Custom":
		custom_shader.visible = true
	else:
		SHADER_TO_APPLY = _get_shader(shader_name)
		custom_shader.visible = false


func _get_shader(shader_name : String) -> ShaderMaterial:
	match shader_name:
		"Gameboy (Green)":
			return preload("res://assets/shaders/gameboy_green_shader_material.tres")
		"Gameboy (Gray)":
			return preload("res://assets/shaders/gameboy_gray_shader_material.tres")
		"Virtualboy":
			return preload("res://assets/shaders/virtualboy_shader_material.tres")
		_:
			return  null


func _on_offset_spin_value_changed(value: float) -> void:
	if LOADED_IMAGE == null: return
		
	var offset_rect := Rect2i(
		offset_x1.value,
		offset_y1.value,
		offset_x2.value,
		offset_y2.value 
	)
	
	SELECTED_OFFSET = offset_rect
	
	var texture_rect_shader = image_preview.material
	
	texture_rect_shader.set_shader_parameter("rect_pos", offset_rect.position)
	texture_rect_shader.set_shader_parameter("rect_size", offset_rect.size)

func _on_use_offset_check_toggled(toggled_on: bool) -> void:
	if LOADED_IMAGE == null: return

	use_offset = toggled_on
	
	var offset_rect := Rect2i(
		offset_x1.value,
		offset_y1.value,
		offset_x2.value,
		offset_y2.value 
	)
	
	if toggled_on:
		SELECTED_OFFSET = offset_rect
	else:
		SELECTED_OFFSET = Rect2i(0,0,0,0)

func _on_reset_offset_btn_pressed() -> void:
	offset_x1.value = 0
	offset_y1.value = 0
	offset_x2.value = 0
	offset_y2.value = 0


func _on_delete_image_btn_pressed() -> void:
	image_preview.texture = null

	LOADED_IMAGE = null
	LOADED_TEXTURE = null


func _on_center_image_btn_pressed() -> void:
	zoom_container.center_image()

var draw_grid := false
func _on_toggle_grid_btn_pressed() -> void:
	var texture_rect_shader = image_preview.material
	draw_grid = !draw_grid
	texture_rect_shader.set_shader_parameter("draw_grid", draw_grid)

var draw_box := true
func _on_show_offset_btn_pressed() -> void:
	var texture_rect_shader = image_preview.material
	draw_box = !draw_box
	texture_rect_shader.set_shader_parameter("draw_box", draw_box)

func _on_toggle_image_scaling_btn_pressed() -> void:
	zoom_container.allow_scaling_beyond_container = !zoom_container.allow_scaling_beyond_container


func create_loaded_image_item(texture : Texture2D, image : Image, path : String):	
	var scene = preload("res://scenes/loaded_images.tscn")
	var instance = scene.instantiate()
		
	loaded_images_list.add_child(instance)
	instance.init(texture, image, path)
	

func create_popup(header : String,text : String, type : POPUP_TYPES) -> Control:
	var scene = load("res://scenes/pop_up_message.tscn")
	var instance : popup_message = scene.instantiate()
	
	popup_container.add_child(instance)
	
	match type:
		POPUP_TYPES.warning:
			instance.show_warning(header, text)
		POPUP_TYPES.info:
			instance.show_info(header, text)
			
	return instance


func _on_menu_button_file_pressed(id : int) -> void:
	match id:
		# Open File Dialog
		0: 
			image_file_dialog.popup()
		# Exit Programm	
		1: 
			get_tree().quit()


func _on_menu_button_tiler_settings_pressed(id : int) -> void:
	match id:
		0: print("other")
		1: print("other")
		
func _on_menu_button_settings_pressed(id : int) -> void:
	match id:
		# Darkmode
		0: 
			pass

		
func _on_menu_button_help_pressed(id : int) -> void:
	match id:
		0: print("other")
		1: print("other")
