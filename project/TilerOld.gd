extends Node

var running : bool = true

var tileWidth : int = 16
var tileHeight : int = 16

var imgPath : String = ""
var outputDir : String = ""

var seperate : bool = false
var mirrored : bool = false
var sorting : bool = true

var sort_by : String = "red"

var start_time := 0
var time_now := 0

var offsetX := 0
var offsetY := 0

var grid_size := 0

func _process(delta):
	time_now = OS.get_unix_time()
	
func tilesetToTile(img) -> void:
	print("OLD")
	start_time = OS.get_unix_time()

	# getting width and height of the img
	var width = img.get_width() - offsetX
	var height = img.get_height() - offsetY

	# getting the amount of rows and colums
	var rows = width / tileWidth
	var cols = height / tileHeight

	# getting the total amount of tiles
	var maxTiles = rows * cols

	# turning the StreamTexture into an Image
	var data = img.get_data()

	# changing text on the gui
	# information about the tilesize and the amount of tiles
	get_parent().get("info").text = str("tilesize = " , str(tileWidth) ,  " : "  , str(tileHeight), " | amount of tiles = ", maxTiles)
	
	# turning the start into a stop button
	get_parent().get("startButton").text = "Stop Tiling"

	# setting up an empty Array for all tiles in the tilemap
	var splittedImgs := []

	# saving every single tile into the "splittedImgs" Array
	for y in cols:
		for x in rows:
			# initialising a temporary Image
			var temp = Image.new()

			# creating a temporary image (width, height, midmap stuff just put it on false,
			# 							  the RGB Format - I just take the same as the origin image has)
			temp.create(tileWidth, tileHeight, false, data.get_format())

			# copying part of the main image to the temporary img
			temp.blit_rect(data, Rect2(tileWidth * x + offsetX, tileHeight * y + offsetY, tileWidth * x + tileWidth + offsetX, tileHeight * y + tileHeight + offsetY), Vector2.ZERO)

			# adding the temporary tile to the array
			splittedImgs.append(temp)


	# preparing a new Array for unique tiles only
	var uniqTiles := []

	# the first tile must be uniq, because there is no other tile to compare
	uniqTiles.append(splittedImgs[0])

	# initialising isUniq value to prevent unnecessary comparisons
	var isUniq : bool = true
	
	var counter : int = 0
	get_parent().get("bar").max_value = maxTiles
	
	# loop through all the tiles (skipping the first)
	for i in range(1,splittedImgs.size()):
		for j in uniqTiles.size():
			if isUniq:
				# comparing the new tile to all the unique tiles,
				# if it isn't in the unique tiles it must be unique it self
				if compareImage(uniqTiles[j], splittedImgs[i]):
					isUniq = false

		if isUniq:
			# adding the new unique tile to the Array
			uniqTiles.append(splittedImgs[i])
		
		counter += 1
		get_parent().get("bar").value = counter
		
		# reset the value for the next tile
		isUniq = true
	
	
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
		imgOut.create(ceil(sqrt(uniqTiles.size())) * tileWidth, ceil(sqrt(uniqTiles.size())) * tileHeight, false , data.get_format())

		# simple count variable
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
		
		imgOut.save_png(str(outputDir, newFileName, tileWidth, "x", tileHeight, "_", imgPath.get_file()))
		
		# changing the output image in the gui to the new tileset
		var texture = ImageTexture.new()
		texture.create_from_image(imgOut, 1)
		get_parent().get("outPic").texture = texture


	# changing some text so the users knows that the process is done
	get_parent().get("outPicPath").text = str("tiled_", tileWidth, "x", tileHeight, "_", imgPath.get_file())
	get_parent().get("display").text = "Finished Tiling"
	get_parent().get("info").text = str(uniqTiles.size(), " tiles printed in: ", time_now - start_time, " secs")
	get_parent().get("startButton").text = "Start Tiling"

	# making sure that the main process can start a new process
	get_parent().running = false

	queue_free()


func compareImage(imgUniq : Image, imgNew : Image) -> bool:
	imgUniq.lock()
	imgNew.lock()
	var is_matching = (
		_tile_match_exact(imgUniq, imgNew) or
		_tile_match_rotated_clockwise_90(imgUniq, imgNew) or
		_tile_match_rotated_clockwise_180(imgUniq, imgNew) or
		_tile_match_rotated_clockwise_270(imgUniq, imgNew) or
		_tile_match_transposed(imgUniq, imgNew) or
		_tile_match_transposed_rotated_clockwise_90(imgUniq, imgNew) or
		_tile_match_transposed_rotated_clockwise_180(imgUniq, imgNew) or
		_tile_match_transposed_rotated_clockwise_270(imgUniq, imgNew)
	)
	imgUniq.unlock()
	imgNew.unlock()
	return is_matching


func _tile_match_exact(tileA : Image, tileB : Image) -> bool:
	for y in tileHeight:
		for x in tileWidth:
			if tileA.get_pixel(x, y) != tileB.get_pixel(x, y):
				return false
	return true

func _tile_match_rotated_clockwise_90(tileA : Image, tileB : Image) -> bool:
	if mirrored:
		return false
		
	if tileWidth != tileHeight:
		return false
	for y in tileHeight:
		for x in tileWidth:
			if tileA.get_pixel(x, y) != tileB.get_pixel(tileHeight - 1 - y, x):
				return false
	return true

func _tile_match_rotated_clockwise_180(tileA : Image, tileB : Image) -> bool:
	if mirrored:
		return false
		
	for y in tileHeight:
		for x in tileWidth:
			if tileA.get_pixel(x, y) != tileB.get_pixel(tileWidth - 1 - x, tileHeight - 1 - y):
				return false
	return true

func _tile_match_rotated_clockwise_270(tileA : Image, tileB : Image) -> bool:
	if mirrored:
		return false
		
	if tileWidth != tileHeight:
		return false
	for y in tileHeight:
		for x in tileWidth:
			if tileA.get_pixel(x, y) != tileB.get_pixel(y, tileWidth - 1 - x):
				return false
	return true

func _tile_match_transposed(tileA : Image, tileB : Image) -> bool:
	if tileWidth != tileHeight:
		return false
	for y in tileHeight:
		for x in tileWidth:
			if tileA.get_pixel(x, y) != tileB.get_pixel(y, x):
				return false
	return true

func _tile_match_transposed_rotated_clockwise_90(tileA : Image, tileB : Image) -> bool:
	if mirrored:
		return false
		
	for y in tileHeight:
		for x in tileWidth:
			if tileA.get_pixel(x, y) != tileB.get_pixel(tileWidth - 1 - x, y):
				return false
	return true

func _tile_match_transposed_rotated_clockwise_180(tileA : Image, tileB : Image) -> bool:
	if mirrored:
		return false
		
	if tileWidth != tileHeight:
		return false
	for y in tileHeight:
		for x in tileWidth:
			if tileA.get_pixel(x, y) != tileB.get_pixel(tileHeight - 1 - y, tileWidth - 1 - x):
				return false
	return true

func _tile_match_transposed_rotated_clockwise_270(tileA : Image, tileB : Image) -> bool:
	if !mirrored:
		return false
		
	for y in tileHeight:
		for x in tileWidth:
			if tileA.get_pixel(x, y) != tileB.get_pixel(x, tileHeight - 1 - y):
				return false
	return true

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
