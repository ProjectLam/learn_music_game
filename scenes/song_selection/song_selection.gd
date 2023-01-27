extends Control
class_name SongSelection

signal item_selected
signal item_played

var cSongSelectionItem = preload("res://scenes/song_selection/song_selection_item.tscn")

@onready var nItems = find_child("Items")

@export var items_number = 7
@export var middle_i = 3
@export var animation_duration = 0.15

enum SELECTION_MODE {
	PLAY,
	SELECT
}

@export var selection_mode: SELECTION_MODE = SELECTION_MODE.PLAY

var item_height: float
var middle_y: float
var items_count: int = 0

var offset: int = 0
var index: int

var tween_y: Tween
var tween_x: Tween

@export var songs_path = "user://songs"
@export var songs_json_file = "songs.json"
@export_range(0, 100) var h_space: int = 100

var h_ratio: int = 1

var selected_index: int

func _ready():
	load_songs()
	load_items()
	
	index = 3
	offset = index - middle_i
	selected_index = index
	
	_process_items_vertically()
	_process_items()


func load_songs():
	var json_path := songs_path.path_join(songs_path)
	# check for songs.json
	if FileAccess.file_exists(json_path):
		var json_string = FileAccess.get_file_as_string(json_path)
		var json_data = JSON.parse_string(json_string)
		if json_data == null or not json_data.has("songs"):
			push_error("Failed to parse the json file at ", json_path)
			return
		for song in json_data.songs as String:
			_handle_song_zip(songs_path.path_join(song))
	
	else:
		# else check for files
		
		# processing directories
		#Assume each directory is 1 song
		#TODO in future allow a JSON file that has direct links to song zip or directories
		var song_dirs := DirAccess.get_directories_at(songs_path)
		for song_dir in song_dirs:
			if song_dir.begins_with("."):
				continue
			var song_dpath = songs_path.path_join(song_dir)
			print("Found directory - " + song_dpath)
			_handle_song_dir(song_dpath)
		
		# Assume each zip file is 1 song.
		var song_files := DirAccess.get_files_at(songs_path)
		for sfile in song_files:
			if sfile.begins_with(".") or sfile.get_extension() != "zip":
				continue
			var sfile_path := songs_path.path_join(sfile)
			#TODO in future allow songs to be .zip files
			print("Found zip - " + sfile_path)
			_handle_song_zip(sfile_path)


func load_items():
	items_count = 0
	
	for n in nItems.get_children():
		n.queue_free()
	
	if PlayerVariables.songs.size():
		while items_count < items_number:
			for songid in PlayerVariables.songs:
				var song : Song = PlayerVariables.songs[songid]
				print("Added song: ", song.title)
				var nItem: SongSelectionItem = cSongSelectionItem.instantiate()
				nItems.add_child(nItem)
				nItem.connect("selected", _on_Item_selected)
				nItem.find_child("NameLabel").text = song.title
				nItem.song = song
				items_count += 1


func _handle_song_dir(song_dpath: String):
	print("handle_song_dir-" + song_dpath)
	
	var song: Song
	
	var files := DirAccess.get_files_at(song_dpath)
	
	for file in files:
		if file.begins_with(".") or file.get_extension() != "xml":
			continue
		var fpath := song_dpath.path_join(file)
		print("got song data xml - " + fpath)
		var sp:SongParser = SongParser.new()
		#sp.parse_xml_from_file(full_xml, song)
		#NOTE this is the core Xml File, there are up to 4 other ones
	
	var sarr_path := song_dpath.path_join("songs/arr")
	var arrfiles := DirAccess.get_files_at(sarr_path)
	#Find the instrument specific ones, for now we are only going to look for lead guitair
	for file in arrfiles:
		if file.begins_with(".") or file.get_extension() != "xml":
			continue
		var fpath := sarr_path.path_join(file)
		if file.ends_with("_lead.xml"):
			print("got lead xml - " + fpath)
			var sp:SongParser = SongParser.new()
			song = sp.parse_xml_from_file(fpath)
			#NOTE  TODO this is the lead guitar Xml File, there are up to 4 other ones, including vocals
	
	# Find the first .mp3 file that doesn't include _preview in audio/windows for now
	# TODO in future do full directory traversal
	var windows_path := song_dpath.path_join("audio/windows")
	var wfiles := DirAccess.get_files_at(windows_path)
	for file in wfiles:
		if file.begins_with("."):
			continue
		var fpath := windows_path.path_join(file)
		if file.get_extension() == "mp3" and not file.contains("preview"):
			if song:
				song.song_music_file = fpath
				print("song file found : ", song.song_music_file)
	print_debug(arrfiles, wfiles)
	if song:
		PlayerVariables.songs[song.get_identifier()] = song


func _handle_song_zip(path: String):
	var reader := ZIPReader.new()
	var err := reader.open(path)
	if err != OK:
		push_error("This ZIP file at path ", path, " couldn't be opened")
		return
	
	var song: Song
	var song_music_buffer: PackedByteArray
	
	# Returns a PoolStringArray of all files in all directories
	var files := reader.get_files()
	
	for file in files:
		if file.ends_with("_lead.xml"):
			var song_parser := SongParser.new()
			song = song_parser.parse_xml_from_buffer(reader.read_file(file))
		if file.ends_with(".mp3") and not "preview" in file:
			song_music_buffer = reader.read_file(file)
	
	if song:
		song.song_music_buffer = song_music_buffer
		PlayerVariables.songs[song.get_identifier()] = song


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
	selected_index = (selected_index+1) % items_count
	select_item((index+1) % items_count)

func go_up():
	selected_index -= 1
	if selected_index < 0:
		selected_index = items_count-1
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
	var item_index = p_nItem.get_index()
	
	if item_index != selected_index:
		selected_index = item_index
		select_item(item_index)
		item_selected.emit(p_nItem)
	else:
		item_played.emit(p_nItem)
		if selection_mode == SELECTION_MODE.PLAY:
			SessionVariables.current_song = PlayerVariables.songs[p_nItem.song.get_identifier()]
			SessionVariables.instrument = PlayerVariables.gameplay_instrument_name
			SessionVariables.single_player = true
			get_tree().change_scene_to_file("res://scenes/performance.tscn")

func _on_DownBtn_pressed():
	go_down()

func _on_UpBtn_pressed():
	go_up()

func _on_item_rect_changed() -> void:
	h_ratio = get_rect().size.x / ProjectSettings.get("display/window/size/viewport_width")
