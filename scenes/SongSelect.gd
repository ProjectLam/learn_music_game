extends Node2D
@onready var item_list = get_node(^"ItemList")
var path = "user://songs/"

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir =  DirAccess.open(path)
	dir.list_dir_begin()
	while true:
		var songFile = dir.get_next()

		#Assume each directory is 1 song
		#TODO in future allow a JSON file that has direct links to song zip or directories
		if songFile == "": 
			break
		elif !songFile.begins_with(".") && dir.current_is_dir():
			print("Found directory - " + songFile)
			handle_song_dir(songFile,dir.get_current_dir() + songFile) # ugly, why isn't there any easier way to do this
		elif songFile.ends_with(".zip"):
			#TODO in future allow songs to be .zip files
			print("Found zip (Not implemented yet) - " + songFile)
	dir.list_dir_end()

	pass # Replace with function body.

func handle_song_dir(songFile:String, curPath:String):
	var dir =  DirAccess.open(curPath)
	
	print("handle_song_dir-" + songFile)
	var song:Song = Song.new()
	PlayerVariables.songs.append(song)
	#	elif and !songFile.ends_with(".import"):
	# Find the first .mp3 file that doesn't include _preview in audio/windows for now
	# TODO in future do full directory traversal
	var err = dir.change_dir("audio/windows/")
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
			
	item_list.add_item(songFile)
	dir.change_dir("..")
	dir.change_dir("..")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_back_btn_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_select_btn_pressed():
	var selected = item_list.get_selected_items()
	if len(selected) < 1:
		return

	var selected_song = item_list.get_item_text(selected[0])
	var selected_song_id = item_list.get_index(selected[0])

	print(selected_song)
	print(selected_song_id)
	PlayerVariables.current_song = PlayerVariables.songs[selected[0]]
#	PlayerVariables.current_song = "user://song_knbeegelovey_fixed.mp3"

	get_tree().change_scene_to_file("res://scenes/performance.tscn")
