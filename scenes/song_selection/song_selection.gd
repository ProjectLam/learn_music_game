extends Control
class_name SongSelection

signal song_selected(song)
signal go_back
signal items_reloaded()
#signal item_played

var cSongSelectionItem = preload("res://scenes/song_selection/song_selection_item.tscn")

@onready var song_items_container = find_child("Items")

@export var items_number = 7
@export var middle_i = 3
@export var animation_duration = 0.15

@export var instrument_data: InstrumentData:
	set = set_instrument_data

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
@export_range(0.0,20000.0) var radius: float = 1500

var h_ratio: int = 1

var selected_item: Node

func _ready():
	visibility_changed.connect(_on_visibility_changed)
	
	if not SongsConfigPreloader.is_song_preload_completed:
		set_process(false)
		print("Waiting for song configurations...")
		await SongsConfigPreloader.song_preload_completed
		print("Song configurations loaded")
		set_process(true)
	
	reload_items()
	
	if FocusManager.is_in_focus_tree():
		grab_focus()


func _gui_input(event):
	if event.is_action_pressed("ui_down"):
		accept_event()
		go_down()
	elif event.is_action_pressed("ui_up"):
		accept_event()
		go_up()
	elif event.is_action_pressed("ui_accept"):
		accept_event()
		if song_items_container.get_child_count() != 0:
			_on_Item_selected(song_items_container.get_child(index))


func _unhandled_input(event):
	if not get_viewport().gui_get_focus_owner() \
			or (not has_focus() and not is_ancestor_of(get_viewport().gui_get_focus_owner())):
		
		return
	if event.is_action_pressed("ui_down"):
		get_viewport().set_input_as_handled()
		go_down()
	elif event.is_action_pressed("ui_up"):
		get_viewport().set_input_as_handled()
		go_up()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_Item_selected(selected_item)


func reload_items():
	items_count = 0
	index = 3
	offset = index - middle_i
	
	if tween_x:
		tween_x.kill()
		tween_x = null
	
	if tween_y:
		tween_y.kill()
		tween_y = null
	
#	for child in song_items_container.get_chil
	
	load_items()
#
	_process_items_vertically()
	_process_items()
	if song_items_container.get_child_count() != 0:
		selected_item = song_items_container.get_child(index)

	items_reloaded.emit()
	


func load_items():
	items_count = 0
	
	for n in song_items_container.get_children():
		song_items_container.remove_child(n)
		n.free()
#		n.queue_free()
	
	if PlayerVariables.songs.size():
		while items_count < items_number:
			for songid in PlayerVariables.songs:
				var song : Song = PlayerVariables.songs[songid]
				if not song.can_play_instrument(instrument_data):
					print("Ignoring song(%s,%s) for instrument tags %s" % [song.get_identifier(), song.tags, instrument_data.get_family_tags() if instrument_data else []])
					continue
				
				print("Added song: ", song.get_identifier())
				var nItem: SongSelectionItem = cSongSelectionItem.instantiate()
				nItem.radius = radius
				song_items_container.add_child(nItem)
				nItem.connect("selected", _on_Item_selected)
				nItem.find_child("NameLabel").text = song.title
				nItem.song = song
				items_count += 1
			
			assert(items_count != 0)


func select_item(p_index: int, p_is_internal: bool = false) -> void:
	if song_items_container.get_child_count() == 0:
		return
	selected_item = song_items_container.get_child(p_index)
	# FIXME : this function shouldn't be called when nodes are null. But in some testings it was.
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
			var nMovingUp = song_items_container.get_child(-1)
			song_items_container.move_child(nMovingUp, 0)
			nMovingUp.position.y = -1 * (item_height * (i+1))
			mov_i -= 1
			i += 1
		
		for j in range(items_number - middle_i, song_items_container.get_child_count()):
			var nMovingDown = song_items_container.get_child(j)
			var y = nMovingDown.position.y + (item_height * di)
			tween_y.tween_property(nMovingDown, "position:y", y, animation_duration)
		
		index = p_index + di
		offset = 0
	else:
		var did = (middle_i - (items_count - index)) + 1
		
		if did > 0:
			var move_lim = did
			
			for i in range(did):
				var nMovingUp = song_items_container.get_child(0)
				song_items_container.move_child(nMovingUp, -1)
				
				var y = (((items_count - 1) + i) * item_height) + item_height
				
				nMovingUp.position.y = y
			
			var j = offset - 1
			while j >= 0:
				var nMovingUp = song_items_container.get_child(j)
				nMovingUp.position.y -= item_height * ((offset - 1) - j)
				j -= 1
			
			offset -= did
			index -= did
	
	var items_y = offset * item_height
	items_y *= -1
	
	tween_y.tween_property(song_items_container, "position:y", items_y, animation_duration)
	_process_items()


func _process_items_vertically():
	if song_items_container.get_child_count() == 0:
		return
	if tween_y:
		tween_y.stop()
	tween_y = get_tree().create_tween().set_parallel(true)
	
	var viewport_height = get_viewport_rect().size.y
	
	item_height = viewport_height / items_number
	items_count = song_items_container.get_child_count()
	
	for i in song_items_container.get_child_count():
		
		var nItem: SongSelectionItem = song_items_container.get_child(i)
		if not nItem:
			break
		var nBox: PanelContainer = nItem.find_child("Box")
		
#		nItem.custom_minimum_size.y = item_height
#		nBox.custom_minimum_size.y = item_height * 0.75
		
		var y = i * item_height
		nItem.position.y = y


func _process_items() -> void:
	if song_items_container.get_child_count() == 0:
		return
	if tween_x:
		tween_x.stop()
	tween_x = get_tree().create_tween().set_parallel(true)
	
	var viewport_height = get_viewport_rect().size.y
	item_height = viewport_height / items_number
	items_count = song_items_container.get_child_count()
	
	tween_x.set_ease(Tween.EASE_OUT_IN)
	
	for i in range(offset, offset + items_number):
		var nItem: SongSelectionItem = song_items_container.get_child(i)
		if not nItem:
			break
		var nBox: PanelContainer = nItem.find_child("Box")
		
#		nItem.custom_minimum_size.y = item_height
#		nBox.custom_minimum_size.y = item_height * 0.75
		
		var y = i * item_height
		tween_x.tween_property(nItem, "position:y", y, animation_duration)
	
	var j = 3
	
	for i in range(offset, offset + middle_i):
		var nItem: SongSelectionItem = song_items_container.get_child(i)
		if not nItem:
			break
		var nBox: PanelContainer = nItem.find_child("Box")
		
		var vr = get_viewport_rect().size.x / ProjectSettings.get("display/window/size/viewport_width")
		
#		tween_x.tween_property(nItem, "position:x", get_final_x(j, item_height), animation_duration)
		
		j -= 1
	
	var mi = offset + middle_i
	var nMiddle = song_items_container.get_child(mi)
#	tween_x.tween_property(nMiddle, "position:x", 0, animation_duration)
	
	j = 1

	for i in range(offset + middle_i + 1, (offset + middle_i*2) + 1):
		var nItem: SongSelectionItem = song_items_container.get_child(i)
		if not nItem:
			break
		var nBox: PanelContainer = nItem.find_child("Box")

#		tween_x.tween_property(nItem, "position:x", get_final_x(j, item_height), animation_duration)

		j += 1


func go_down():
	if song_items_container.get_child_count() == 0:
		return
	if items_count == 0:
		return
#	selected_index = (selected_index+1) % items_count
	select_item((index+1) % items_count)
	selected_item = song_items_container.get_child(index)


func go_up():
	if song_items_container.get_child_count() == 0:
		return
	if items_count == 0:
		return
#	selected_index -= 1
#	if selected_index < 0:
#		selected_index = items_count-1
	select_item((index-1) % items_count)
	selected_item = song_items_container.get_child(index)


func get_song(p_index: int) -> SongSelectionItem:
	if song_items_container.get_child_count() == 0:
		return null
	return song_items_container.get_child(p_index)


func _on_Songs_item_rect_changed():
	if not song_items_container:
		return
	
	middle_y = get_viewport_rect().size.y / 2
	
	_process_items_vertically()
	_process_items()
	
	select_item(index, true)


func _on_Item_selected(p_selected: SongSelectionItem):
	var item_index = p_selected.get_index()
	
	if p_selected != selected_item:
		select_item(p_selected.get_index())
	else:
		song_selected.emit(p_selected.song)
#		item_selected.emit(p_selected)
#	else:
#		item_played.emit(p_selected)
#		if selection_mode == SELECTION_MODE.PLAY:
#			SessionVariables.current_song = PlayerVariables.songs[p_selected.song.get_identifier()]
#			SessionVariables.instrument = PlayerVariables.gameplay_instrument_name
#			SessionVariables.single_player = true
#			get_tree().change_scene_to_file("res://scenes/performance.tscn")
		

func _on_DownBtn_pressed():
	go_down()


func _on_UpBtn_pressed():
	go_up()


func _on_item_rect_changed() -> void:
	h_ratio = get_rect().size.x / ProjectSettings.get("display/window/size/viewport_width")


func _on_go_back():
	go_back.emit()
#	get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")


func _on_visibility_changed():
	if visible:
		if FocusManager.is_in_focus_tree():
			grab_focus()


func set_instrument_data(value: InstrumentData) -> void:
	if instrument_data != value:
		instrument_data = value
		reload_items()
