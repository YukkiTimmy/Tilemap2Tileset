extends Control

var LOADED_IMAGE : Image = null
var LOADED_TEXTURE : ImageTexture = null
var CURRENT_FILE_NAME : String

var SELECTED_TILE_WIDTH := 16
var SELECTED_TILE_HEIGHT := 16

var SELECTED_OFFSET : Rect2i = Rect2i(0,0,0,0)

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

func _ready() -> void:
	get_tree().get_root().files_dropped.connect(_on_files_dropped)


func _process(_delta: float) -> void:
	if CURRENT_TILER:
		tiling_progess_bar.value = CURRENT_TILER.current_tiles_checked


func _on_files_dropped(files: PackedStringArray) -> void:
	var path = files[0]
	CURRENT_FILE_NAME = path.get_file().get_basename()
	
	var image = Image.new()
	var err = image.load(path)
	if err != OK:
		push_error("Fehler beim Laden des Bildes: " + path)
		return

	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)

	if image.get_data().size() == 0:
		push_error("Konvertiertes Bild hat keine Daten. Überprüfen Sie das Originalbild.")
		return


	var texture = ImageTexture.new()
	texture.set_image(image)

	image_preview.texture = texture

	LOADED_IMAGE = image
	LOADED_TEXTURE = texture


func _on_tile_button_pressed() -> void:
	if not LOADED_IMAGE:
		push_error("Kein Bild geladen.")
		return

	if CURRENT_TILER or thread_running:
		return

	var tiler_scene = preload("res://scenes/tiler.tscn")
	var tiler_instance = tiler_scene.instantiate()
	tiler_instance.connect("image_ready", Callable(self, "_on_tiling_finished"))
	tiler_instance.connect("get_total_tiles_to_check", Callable(self, "_on_set_progress_max"))
	add_child(tiler_instance)

	CURRENT_TILER = tiler_instance

	SELECTED_TILE_WIDTH = manual_tile_size_spinbox_x.value
	SELECTED_TILE_HEIGHT = manual_tile_size_spinbox_y.value
	
	
	var tiler_settings = {
		"input_image": LOADED_IMAGE,
		"file_name": CURRENT_FILE_NAME,
		"tile_width": SELECTED_TILE_WIDTH,
		"tile_height": SELECTED_TILE_HEIGHT,
		"offset_rect": SELECTED_OFFSET,
		"check_orientation": CHECK_ORIENTATION,
		"sort_by": SORT_TILES_BY,
	}

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

func _on_apply_shader_opt_item_selected(index: int) -> void:
	var shader_name = shader_options.get_item_text(shader_options.selected)
	SHADER_TO_APPLY = _get_shader(shader_name)


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
	var loaded_image_size = LOADED_IMAGE.get_size()
	
	var offset_rect := Rect2i(
		offset_x1.value,
		offset_y1.value,
		loaded_image_size.x - offset_x2.value - offset_x1.value,
		loaded_image_size.y - offset_y2.value - offset_y1.value
	)
	
	SELECTED_OFFSET = offset_rect
	
	var texture_rect_shader = image_preview.material
	
	texture_rect_shader.set_shader_parameter("rect_pos", offset_rect.position)
	texture_rect_shader.set_shader_parameter("rect_size", offset_rect.size)


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


func _on_toggle_image_scaling_btn_pressed() -> void:
	zoom_container.allow_scaling_beyond_container = !zoom_container.allow_scaling_beyond_container
