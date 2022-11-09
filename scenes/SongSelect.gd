extends Node2D
@onready var item_list = get_node(^"ItemList")
var path = "user://songs/"

# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	while true:
		var songFile = dir.get_next()
		if songFile == "": 
			break
		elif !songFile.begins_with(".") and !songFile.ends_with(".import"):
			item_list.add_item(songFile)
	dir.list_dir_end()

	pass # Replace with function body.


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
	PlayerVariables.current_song = path + selected_song
#	PlayerVariables.current_song = "user://song_knbeegelovey_fixed.mp3"

	get_tree().change_scene_to_file("res://scenes/performance.tscn")
