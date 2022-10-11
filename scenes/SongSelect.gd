extends Node2D
@onready var item_list = get_node(^"ItemList")

# Called when the node enters the scene tree for the first time.
func _ready():
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
	PlayerVariables.current_song = selected_song

	get_tree().change_scene_to_file("res://scenes/song.tscn")
