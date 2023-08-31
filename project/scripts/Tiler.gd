extends Node

var running : bool = true

var tileWidth : int = 16
var tileHeight : int = 16

var imgPath : String = ""
var outputDir : String = ""

var seperate : bool = false
var mirrored : bool = false
var sorting : bool = true
var filter : bool = false


var sort_by : String = "red"

var shader : String = ""

var start_time : float = 0
var time_now : float = 0

var offsetX := 0
var offsetY := 0

var endOffsetX := 0
var endOffsetY := 0

var grid_size := 0


func _ready() -> void:
	if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
		return
		
	tilesetToTile(get_parent().currentImage)


# warning-ignore:unused_argument
func _process(delta):
	time_now = OS.get_system_time_msecs()


func tilesetToTile(img) -> void:
	start_time = OS.get_system_time_msecs()
	
	# getting width and height of the img
	var width = endOffsetX - offsetX
	var height = endOffsetY - offsetY

	# getting the amount of rows and colums
	# using int + ceil because image "width" does not have to be divisible by "tileWidth"
  # Same goes for height. So we get half-filled tiles too
  var rows = int(ceil(width / tileWidth))
	var cols = int(ceil(height / tileHeight))

	# getting the total amount of tiles
	var maxTiles = rows * cols

	# turning the StreamTexture into an Image
	var data = img.get_data()

	# preparing a new Array for unique tiles only
	var uniqTiles := []

	# dictionary of hashes to tile index in uniqTiles
	var tileHashes : Dictionary = {}

	var counter : int = 0
	get_parent().get("progress").max_value = maxTiles
	
	# >>>>> Thanks to Asher Glick & gokiburi skin over on Github, <<<<<
	# >>>>> for helping me improve the algorithm drastically! <3  <<<<<

	# saving every single tile into the "splittedImgs" Array
	for y in cols:
		for x in rows:
			var tempImage = Image.new()

			# creating a temporary image (width, height, midmap stuff just put it on false,
			# 							  the RGB Format - I just take the same as the origin image has)
			tempImage.create(tileWidth, tileHeight, false, data.get_format())
			# initialising a temporary Image

			# copying part of the main image to the temporary img
			tempImage.blit_rect(
				data,
				Rect2(
					tileWidth * x + offsetX,
					tileHeight * y + offsetY,
					tileWidth * x + tileWidth + offsetX,
					tileHeight * y + tileHeight + offsetY),
				Vector2.ZERO
			)

			
			counter += 1
			get_parent().get("progress").value = counter
			
		
			# Check if the tile is unique.
			var imagehash = _imageHash(tempImage)
			if imagehash in tileHashes:
				continue

			# Add all hashes of tile permutations to the list. This is done so
			# that a hash of any permutation of this tile will be detected in
			# the code above.
			var newTileIndex = len(uniqTiles)
			tileHashes[imagehash] = newTileIndex
			
			if !mirrored:
				tempImage.flip_x()
				tileHashes[_imageHash(tempImage)] = newTileIndex

				tempImage.flip_y()
				tileHashes[_imageHash(tempImage)] = newTileIndex

				tempImage.flip_x()
				tileHashes[_imageHash(tempImage)] = newTileIndex

				# Rotated 90deg Tile Permutations.
				var tempRotatedTile = _rotatedTile(tempImage)
				tileHashes[_imageHash(tempRotatedTile)] = newTileIndex

				tempRotatedTile.flip_x()
				tileHashes[_imageHash(tempRotatedTile)] = newTileIndex

				tempRotatedTile.flip_y()
				tileHashes[_imageHash(tempRotatedTile)] = newTileIndex

				tempRotatedTile.flip_x()
				tileHashes[_imageHash(tempRotatedTile)] = newTileIndex

				# Reset original tile to normal
				tempImage.flip_y()

			# adding the new unique tile to the Array
			uniqTiles.append(tempImage)
			
			
	
	# sorting
	if sorting:
		uniqTiles = _sorting_tiles(uniqTiles)


	# checks if the programm should print out a single or a multiple smaller images

	# ---single tiles---
	if seperate == true:
		# variable to count all the different tiles
		var imgCount = 1

		for i in uniqTiles:
			# getting the filename of the image
			var fileName = imgPath.get_file()

			# I tried to cut of the extensions, so I could add the numbers after the name
			# this step is completly optional

			# removing the 3 long extensions
			if fileName.ends_with(".png") || fileName.ends_with(".jpg") || fileName.ends_with(".gif"):
				fileName.erase(fileName.length() - 4, 4)

			# removing the 4 long extensions
			elif fileName.ends_with(".jpeg"):
				fileName.erase(fileName.length() - 5, 5)

			# just in case you ended up here with a unvalid extension (shouldn't happen
			else:
				print("File Extension can't be accepted")
				return

			# saving all the tiles to a .png file
			var newFileName : String = "_tiled_"

			if !mirrored:
				newFileName += "mirrored_"

			if sorting:
				newFileName += str("sorted_", sort_by, "_")

			i.save_png(str(outputDir, "/", fileName, newFileName, tileWidth, "x", tileHeight, "_", imgCount, ".png"))

			# increasing the number of printed tiles by one
			imgCount += 1


	# ---one big image---
	else:
		# initiallise a new image file
		var imgOut = Image.new()

		# creating a new image file by taking the squareroot of the height and width
		# and rounding them up, you always get a big enough image
		var newWidth = ceil(sqrt(uniqTiles.size())) * tileWidth
		var newHeight = ceil(sqrt(uniqTiles.size())) * tileHeight
		
		imgOut.create(newWidth, newHeight, false , data.get_format())

		# simple count variable
		var count := 0

		# looping through the new image
		for y in ceil(sqrt(uniqTiles.size())):
			for x in ceil(sqrt(uniqTiles.size())):
				# you could end up with less unique tiles then there is space in the image
				if count < uniqTiles.size():
					# putting all unique tiles into the new image
					imgOut.blit_rect(uniqTiles[count], Rect2(0, 0, tileWidth, tileHeight), Vector2(x * tileWidth, y * tileHeight))
					count += 1

		# saving the image to the output path
		var newFileName : String = "/tiled_"

		if !mirrored:
			newFileName += "mirrored_"

		if sorting:
			newFileName += str("sorted_", sort_by, "_")
		
		# changing the output image in the gui to the new tileset
		var texture = ImageTexture.new()
		texture.create_from_image(imgOut, 1)
		
		
		# Adding tiled image to the list
		var scene = load("res://scenes/GeneratedImage.tscn")
		var generatedImage = scene.instance()
		
		get_parent().generatedImages.push_back(generatedImage)
		
		if !sorting:
			sort_by = "None"
		
		
		# Filter stuff
		
		if filter:
			var viewportScene = load("res://scenes/ViewportImage.tscn")
			var viewport = viewportScene.instance()
			
			get_parent().add_child(viewport)
			
			viewport.shader = shader
			
			viewport.getViewportImage(texture)
			
			yield(viewport, "_done")
			
			var newTexture = ImageTexture.new()
			newTexture.create_from_image(viewport.outputImage, 1)
			
			generatedImage.txt = viewport.outputImage
			
			generatedImage.img = newTexture
		
		else:
			shader = "None"
			
			generatedImage.txt = imgOut
			
			generatedImage.img = texture
		
			
		if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
			generatedImage.title = imgPath.get_file()
		else:
			generatedImage.title = get_parent().fileName
			time_now = 0
			start_time = 0
		
		
		generatedImage.info = str("Tiles printed: ", uniqTiles.size(), "\n"
								,"Tile Size: ", tileWidth, "x", tileHeight, "\n"
								,"Original Size: ", width, "x", height, "\n"
								,"New Size: ", newWidth, "x", newHeight, "\n"
								,"Total Tiles: ", maxTiles, "\n"
								,"Time: ", time_now - start_time, "ms\n"
								,"Mirror: ", !mirrored, "\n"
								,"Sorted: ", sorting, "\n"
								,"Sorted By: ",sort_by, "\n"
								,"Sperated: ", seperate, "\n"
								,"Filterd: ", filter, "\n"
								,"Shader: ", shader)
		
		
		get_parent().get("tiledImages").add_child(generatedImage)
		get_parent().get("tiledImages").move_child(generatedImage, 0)
		

	# making sure that the main process can start a new process
	get_parent().running = false
	get_parent().startButton.text = "Start Tiling"
	
	queue_free()


func _imageHash(image: Image) -> int:
	var data = image.get_data()
	return hash(data)


func _rotatedTile(tile : Image) -> Image:
	var rotatedTile = Image.new()
	rotatedTile.create(tileWidth, tileHeight, false, tile.get_format())

	tile.lock()
	rotatedTile.lock()
	for y in tileHeight:
		for x in tileWidth:
			rotatedTile.set_pixel(y, x, tile.get_pixel(x,y))
	tile.unlock()
	rotatedTile.unlock()

	return rotatedTile


func _sorting_tiles(tiles : Array) -> Array:
	var rgb_values := []
	var sorted_tiles := []

	var tileR : int = 0
	var tileG : int = 0
	var tileB : int = 0

	var count : int = 0

	for i in tiles:
		i.lock()
		for y in tileHeight:
			for x in tileWidth:
				tileR += i.get_pixel(x,y).r8
				tileG += i.get_pixel(x,y).g8
				tileB += i.get_pixel(x,y).b8

		match sort_by:
			"red":
				rgb_values.append(Vector2(tileR,count))
			"green":
				rgb_values.append(Vector2(tileG,count))
			"blue":
				rgb_values.append(Vector2(tileB,count))

		tileR = 0
		tileG = 0
		tileB = 0

		count += 1

	rgb_values.sort()

	for n in tiles.size():
		sorted_tiles.append(0)

	for i in rgb_values.size():
		sorted_tiles[i] = tiles[rgb_values[i].y]

	return sorted_tiles
