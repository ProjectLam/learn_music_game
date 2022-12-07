extends Control

var cSongSelectionItem = preload("res://scenes/song_selection/song_selection_item.tscn")

@onready var nItems = find_child("Items")

@export var items_number = 7
@export var middle_i = 3
@export var animation_duration = 0.15

var item_height: float
var middle_y: float
var items_count: int

var offset: int = 0
var index: int

var tween_y: Tween
var tween_x: Tween

@export var songs_path = "user://songs"
@export_range(0, 100) var h_space: int = 100

var h_ratio: int = 1

func _ready():
#	for i in 5:
#		var nItem: SongSelectionItem = cSongSelectionItem.instantiate()
#		nItems.add_child(nItem)
#		nItem.connect("selected", _on_Item_selected)
#		nItem.find_child("NameLabel").text += " " + str(i)
	
	load_songs()
	items_count = nItems.get_child_count()
	if items_count:
		while items_count < items_number:
			load_songs()
			items_count = nItems.get_child_count()
	
	index = 3
	offset = index - middle_i
	
	_process_items_vertically()
	_process_items()

func load_songs():
	var dir =  DirAccess.open(songs_path)
	dir.list_dir_begin()
	while true:
		var songFile = dir.get_next()

		#Assume each directory is 1 song
		#TODO in future allow a JSON file that has direct links to song zip or directories
		if songFile == "": 
			break
		elif !songFile.begins_with(".") && dir.current_is_dir():
			print("Found directory - " + songFile)
			_handle_song_dir(songFile,dir.get_current_dir() + "/"+ songFile) # ugly, why isn't there any easier way to do this
		elif songFile.ends_with(".zip"):
			#TODO in future allow songs to be .zip files
			print("Found zip (Not implemented yet) - " + songFile)
	dir.list_dir_end()

func _handle_song_dir(songFile:String, curPath:String):
	var dir =  DirAccess.open(curPath)
	
	print("handle_song_dir-" + songFile)
	var song:Song = Song.new()
	PlayerVariables.songs.append(song)

	dir.list_dir_begin()
	while true:
		var iFile = dir.get_next()
		if iFile == "": 
			break
		elif iFile.ends_with(".xml"):
			var full_xml =  dir.get_current_dir() + "/" + iFile
			print("got xml - " + full_xml)
			var sp:SongParser = SongParser.new()
			#sp.parse_xml(full_xml, song)
			#NOTE this is the core Xml File, there are up to 4 other ones

	dir.list_dir_end()
	
	#Find the instrument specific ones, for now we are only going to look for lead guitair
	var err = dir.change_dir("songs/arr")
	if err != OK:
		print("error2 - " + err)
		return
	
	dir.list_dir_begin()
	while true:
		var iFile = dir.get_next()
		if iFile == "": 
			break
		elif iFile.ends_with("_lead.xml"):
			var full_xml =  dir.get_current_dir() + "/" + iFile
			print("got xml - " + full_xml)
			var sp:SongParser = SongParser.new()
			sp.parse_xml(full_xml, song)
			#NOTE  TODO this is the lead guitar Xml File, there are up to 4 other ones, including vocals

	var nItem: SongSelectionItem = cSongSelectionItem.instantiate()
	nItems.add_child(nItem)
	nItem.connect("selected", _on_Item_selected)
	nItem.find_child("NameLabel").text = songFile
	nItem.song = TSong.new()
	nItem.song.file_name = songFile
	
	dir.list_dir_end()
	dir.change_dir("..")
	dir.change_dir("..")

	# Find the first .mp3 file that doesn't include _preview in audio/windows for now
	# TODO in future do full directory traversal
	err = dir.change_dir("audio/windows/")
	if err != OK:
		print("error2 - " + err)
		return
		
	dir.list_dir_begin()
	while true: 
		var iFile = dir.get_next()
		if iFile == "": 
			break
		elif iFile.ends_with(".mp3") && !("preview" in iFile):
			song.songMusicFile = dir.get_current_dir() + "/" + iFile
			print(song.songMusicFile)

	dir.list_dir_end()
	
	dir.change_dir("..")
	dir.change_dir("..")

func _process(delta):
	pass

func select_item(p_index: int, p_is_internal: bool = false) -> void:
	if tween_y:
		tween_y.stop()
	tween_y = get_tree().create_tween().set_parallel(true)
	
	var viewport_height = get_viewport_rect().size.y
	item_height = viewport_height / items_number
	
	index = p_index
	offset = index - middle_i
	
	var di = middle_i - index
	
	if di >= 0:
		var mov_lim = items_count - di
		var mov_i = items_count - 1
		
		var i = 0
		while mov_i >= mov_lim:
			var nMovingUp = nItems.get_child(-1)
			nItems.move_child(nMovingUp, 0)
			nMovingUp.position.y = -1 * (item_height * (i+1))
			mov_i -= 1
			i += 1
		
		for j in range(items_number - middle_i, nItems.get_child_count()):
			var nMovingDown = nItems.get_child(j)
			var y = nMovingDown.position.y + (item_height * di)
			tween_y.tween_property(nMovingDown, "position:y", y, animation_duration)
		
		index = p_index + di
		offset = 0
	else:
		var did = (middle_i - (items_count - index)) + 1
		
		if did > 0:
			var move_lim = did
			
			for i in range(did):
				var nMovingUp = nItems.get_child(0)
				nItems.move_child(nMovingUp, -1)
				
				var y = (((items_count - 1) + i) * item_height) + item_height
				
				nMovingUp.position.y = y
			
			var j = offset - 1
			while j >= 0:
				var nMovingUp = nItems.get_child(j)
				nMovingUp.position.y -= item_height * ((offset - 1) - j)
				j -= 1
			
			offset -= did
			index -= did
	
	var items_y = offset * item_height
	items_y *= -1
	
	tween_y.tween_property(nItems, "position:y", items_y, 0.5)
	_process_items()

func _process_items_vertically():
	if tween_y:
		tween_y.stop()
	tween_y = get_tree().create_tween().set_parallel(true)
	
	var viewport_height = get_viewport_rect().size.y
	
	item_height = viewport_height / items_number
	items_count = nItems.get_child_count()
	
	for i in nItems.get_child_count():
		
		var nItem: SongSelectionItem = nItems.get_child(i)
		if not nItem:
			break
		var nBox: PanelContainer = nItem.find_child("Box")
		
		nItem.custom_minimum_size.y = item_height
		nBox.custom_minimum_size.y = item_height * 0.75
		
		var y = i * item_height
		nItem.position.y = y

func _process_items() -> void:
	if tween_x:
		tween_x.stop()
	tween_x = get_tree().create_tween().set_parallel(true)
	
	var viewport_height = get_viewport_rect().size.y
	item_height = viewport_height / items_number
	items_count = nItems.get_child_count()
	
	tween_x.set_ease(Tween.EASE_OUT_IN)
	
	for i in range(offset, offset + items_number):
		
		var nItem: SongSelectionItem = nItems.get_child(i)
		if not nItem:
			break
		var nBox: PanelContainer = nItem.find_child("Box")
		
		nItem.custom_minimum_size.y = item_height
		nBox.custom_minimum_size.y = item_height * 0.75
		
		var y = i * item_height
		tween_x.tween_property(nItem, "position:y", y, animation_duration)
	
	var j = 3
	
	for i in range(offset, offset + middle_i):
		var nItem: SongSelectionItem = nItems.get_child(i)
		if not nItem:
			break
		var nBox: PanelContainer = nItem.find_child("Box")
		
		var vr = get_viewport_rect().size.x / ProjectSettings.get("display/window/size/viewport_width")
		
		tween_x.tween_property(nItem, "position:x", j * h_space * h_ratio, animation_duration * 0.5 * i)
		
		j -= 1
	
	var mi = offset + middle_i
	var nMiddle = nItems.get_child(mi)
	tween_x.tween_property(nMiddle, "position:x", 0, animation_duration)
	
	j = 1
	
	for i in range(offset + middle_i + 1, (offset + middle_i*2) + 1):
		var nItem: SongSelectionItem = nItems.get_child(i)
		if not nItem:
			break
		var nBox: PanelContainer = nItem.find_child("Box")

		tween_x.tween_property(nItem, "position:x", j * h_space * h_ratio, animation_duration * 0.5 * i)
		
		j += 1

func go_down():
	select_item((index+1) % items_count)

func go_up():
	select_item((index-1) % items_count)

func get_song(p_index: int) -> SongSelectionItem:
	return nItems.get_child(p_index)

func _on_Songs_item_rect_changed():
	if not nItems:
		return
	
	middle_y = get_viewport_rect().size.y / 2
	
	_process_items_vertically()
	_process_items()
	
	select_item(index, true)

func _on_Item_selected(p_nItem: SongSelectionItem):
	var song_index = p_nItem.get_index()
	
	select_item(song_index)
	PlayerVariables.current_song = PlayerVariables.songs[song_index]
	get_tree().change_scene_to_file("res://scenes/performance.tscn")

func _on_DownBtn_pressed():
	go_down()

func _on_UpBtn_pressed():
	go_up()

func _on_item_rect_changed() -> void:
	h_ratio = get_rect().size.x / ProjectSettings.get("display/window/size/viewport_width")
