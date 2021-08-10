extends Node

var running = true

var tileWidth = 16
var tileHeight = 16

var imgPath = ""
var outputDir = ""

var seperate = false

func tilesetToTile(img) -> void:
	# getting width and height of the img 
	var width = img.get_width()
	var height = img.get_height()
	
	# getting the amount of rows and colums 
	var rows = width / tileWidth
	var cols = height / tileHeight
	
	# getting the total amount of tiles
	var maxTiles = rows * cols
	
	# turning the StreamTexture into an Image
	var data = img.get_data()
	
	# changing text on the gui
	# information about the tilesize and the amount of tiles
	get_parent().get_node("Info").text = str("tilesize = " , str(tileWidth) ,  " : "  , str(tileHeight), " | amount of tiles = ", maxTiles)
	# turning the start into a stop button
	get_parent().get_node("StartButton").text = "Stop Tiling"
	
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
			temp.blit_rect(data, Rect2(tileWidth * x, tileHeight * y, tileWidth * x + tileWidth, tileHeight * y + tileHeight), Vector2.ZERO)

			# adding the temporary tile to the array
			splittedImgs.append(temp)


	# preparing a new Array for unique tiles only
	var uniqTiles := []
	
	# the first tile must be uniq, because there is no other tile to compare
	uniqTiles.append(splittedImgs[0])
	
	# initialising isUniq value to prevent unnecessary comparisons 
	var isUniq : bool = true

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
		
		# reset the value for the next tile
		isUniq = true
	
	
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
			i.save_png(str(outputDir, "/", fileName, "_tiled_", tileWidth, "x", tileHeight, "_", imgCount, ".png"))
			
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
		imgOut.save_png(str(outputDir, "/tiled_", tileWidth, "x", tileHeight, "_", imgPath.get_file()))
		
		# changing the output image in the gui to the new tileset
		var texture = ImageTexture.new()
		texture.create_from_image(imgOut, 1)
		get_parent().get_node("OutputPic").texture = texture
	
	
	# changing some text so the users knows that the process is done
	get_parent().get_node("OutputPic/OutputName").text = str("tiled_", tileWidth, "x", tileHeight, "_", imgPath.get_file())
	get_parent().get_node("Display").text = "Finished Tiling"
	get_parent().get_node("Info").text = str("Total tiles printed = ", uniqTiles.size())
	get_parent().get_node("StartButton").text = "Start Tiling"
	
	# making sure that the main process can start a new process
	get_parent().running = false
	
	queue_free()


func compareImage(imgUniq : Image, imgNew : Image) -> bool:
	# getting the data of both tiles
	var dataA = imgUniq.get_data()
	var dataB = imgNew.get_data()
	
	# this is the part that was the most troublefull part of the entire programm
	# it looks really simple but it took me over half a year to come up with this method :D
	# my inital plan was to add up all the RGB values of the tile, but than I couldnt detect if 
	# a single pixel was swapped with another, i tried the same with adding up all the PoolByteArray
	# values, but same result
	# In the end just comparing every bit with the other did the job, if you have any better comparing
	# function pls let me know!

	# looping trough all the data in the imgUniq and comparing it to the data in imgNew
	for i in dataA.size():
		if dataA[i] != dataB[i]:
			return false

	return true
