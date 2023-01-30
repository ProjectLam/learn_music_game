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


@export_range(0, 100) var h_space: int = 100

var h_ratio: int = 1

var selected_index: int

func _ready():
	if not SongsConfigPreloader.is_song_repload_completed:
		set_process(false)
		await SongsConfigPreloader.song_preload_completed
		set_process(true)
	
	load_items()
	
	index = 3
	offset = index - middle_i
	selected_index = index
	
	_process_items_vertically()
	_process_items()





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
