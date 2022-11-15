extends Control

var sSongSelectionItem = preload("res://scenes/SongSelection/SongSelectionItem.tscn")

@onready var nSongSelectionWindow = find_child("SongSelectionWindow")
@onready var nList = find_child("List")
@onready var nList_Items = nList.find_child("Items")

@onready var nItemMenu = $CanvasLayer/SongSelectionItemMenu

@onready var nUpdateTimer = find_child("UpdateTimer")

var pixeled_otf = preload("res://fonts/Pixeled.otf")

enum AVATAR_MODE {CROSS, ORDER}
@export var avatar_mode: AVATAR_MODE = AVATAR_MODE.ORDER

@export var avatar_size = Vector2(100, 100)
@export var avatar_square_size = 20
var avatar_colors = [
	Color.RED, Color.CYAN, Color.ALICE_BLUE, Color.YELLOW,
	Color.HOT_PINK, Color.TOMATO, Color.CHARTREUSE,
	Color.BLANCHED_ALMOND, Color.DARK_ORCHID, Color.CORNFLOWER_BLUE
]

var selected_song: TSong
var removing_song: TSong
var renaming_song: TSong

var songs = TSongs.new()

var do_save_state = true

var prelistening_song: TSong = null

func _ready():
	nSongSelectionWindow.visible = false
	nItemMenu.visible = false
	load_state()
	open()

func open():
	$AnimationPlayer.play("Open")
	nUpdateTimer.stop()
	nUpdateTimer.start()

func close():
	$AnimationPlayer.play("Close")
	
	if prelistening_song:
		prelistening_song = null
		$AudioStreamPlayer2D.stop()
	
	if selected_song:
		deselect_song()

func toggle():
	if nSongSelectionWindow.visible:
		close()
	else:
		open()

func select_song(p_song: TSong, force: bool = false):
	if not force and selected_song and selected_song.item.nItem == p_song.item.nItem:
		deselect_song()
		return

	deselect_song()

	p_song.item.nItem.select()
	selected_song = p_song

func deselect_song():
	if not selected_song:
		return
	
	if selected_song.item and selected_song.item.nItem:
		selected_song.item.nItem.deselect()
	
	selected_song = null

func _on_item_gui_input(p_event, p_song):
	if not (p_event is InputEventMouseButton and p_event.pressed and p_event.button_index == MOUSE_BUTTON_LEFT):
		return

	select_song(p_song)

func save_state() -> void:
	if not do_save_state:
		return
	
	var file = FileAccess.open("user://songs.json", FileAccess.WRITE)
	file.store_string(songs.json)

func load_state() -> void:
	do_save_state = false
	
	if not FileAccess.file_exists("user://songs.json"):
		do_save_state = true
		return
		
	var file = FileAccess.open("user://songs.json", FileAccess.READ)
	var json = file.get_as_text()
	if file.get_length() > 0:
		songs.json = json
	else:
		songs = TSongs.new()
	
	add_songs(songs)
	
	do_save_state = true

func add_songs(songs: TSongs) -> void:
	for song in songs.songs:
		add_song(song)

func add_song(song: TSong) -> void:
	var old_item = song.item
	song.item = TSongSelectionItem.new()

	var digits = song.name.substr(2)
	if digits == "":
		digits = "No Name Song"
	var digit_colors = []
	for i in digits:
		digit_colors.append(avatar_colors[(i.unicode_at(0) - 48) % avatar_colors.size()])
	
	var image = Image.create(avatar_size.x, avatar_size.y, false, Image.FORMAT_RGB8)
	for x in range(avatar_size.x):
		for y in range(avatar_size.y):
			var si
			if avatar_mode == AVATAR_MODE.CROSS:
				si = x / avatar_square_size + y / avatar_square_size
			else:
				si = x / avatar_square_size + ((y / avatar_square_size) * (image.get_width() / avatar_square_size))
			image.set_pixel(x, y, digit_colors[si % (avatar_colors.size() - 1)])
	
	var texture = ImageTexture.create_from_image(image)
	
	var nItem: SongSelectionItem = sSongSelectionItem.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	nItem.song = song
	nItem.connect("gui_input", _on_item_gui_input.bind(song))
	nItem.get_node("VBoxContainer/Song/Avatar").texture = texture
	nItem.get_node("VBoxContainer/Song/Details/Name").text = song.name
	nItem.get_node("VBoxContainer/Song/Details/Artist").text = song.artist
	
	nItem.connect("hold", _on_item_hold)
	nItem.connect("prelisten", _on_item_prelisten)
	
	song.item.nItem = nItem
	song.item.nNameLabel = nItem.get_node("VBoxContainer/Song/Details/Name")
	song.item.nArtistLabel = nItem.get_node("VBoxContainer/Song/Details/Artist")
	
	songs.set_song(song.name, song)
	
	if old_item and old_item.nItem:
		for i in old_item.nItem.get_child_count():
			old_item.nItem.remove_child(old_item.nItem.get_child(i))
		old_item.nItem.replace_by(song.item.nItem, false)
		old_item.nItem = null
		if selected_song and selected_song.song == song.song:
			select_song(song, true)
	else:
		nList_Items.add_child(nItem)
	
	save_state()

func refresh() -> void:
	pass

func _on_CloseButton_pressed():
	close()

func _on_item_hold(p_song: TSong):
	select_song(p_song)
	nItemMenu.open(p_song)

func _on_item_prelisten(p_song: TSong):
	if prelistening_song:
		prelistening_song = null
		$AudioStreamPlayer2D.stop()
		return
	
	prelistening_song = p_song
	$AudioStreamPlayer2D.stream = AudioStreamOggVorbis.from_filesystem("user://" + p_song.filename)
	$AudioStreamPlayer2D.play()

func _on_SongSelectionWindow_rect_changed():
	$CanvasLayer/SongSelectionWindow.pivot_offset.x = $CanvasLayer/SongSelectionWindow.size.x / 2
	$CanvasLayer/SongSelectionWindow.pivot_offset.y = $CanvasLayer/SongSelectionWindow.size.y / 2
