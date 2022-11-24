extends Control

var cSongSelectionItem = preload("res://scenes/song_selection/song_selection_item.tscn")

@onready var nItems = find_child("Items")

@export var items_number = 7

var item_height: float
var middle_y: float
var items_count: int

var offset: int = 0
var index: int

func _ready():
	for i in 15:
		var nItem: SongSelectionItem = cSongSelectionItem.instantiate()
		nItems.add_child(nItem)
		nItem.connect("selected", _on_Item_selected)
	
	items_count = nItems.get_child_count()
	index = floor(items_count / floor(items_number / 2)) - 1
	
	_process_items()

func _process(delta):
	pass

func _process_items():
	var viewport_height = get_viewport_rect().size.y
	
	item_height = viewport_height / items_number
	
	items_count = nItems.get_child_count()
	
	var middle_i = floor(items_count / floor(items_number / 2)) - 2
	print("middle_i: ", middle_i)
	
	for i in items_count:
		var nItem: SongSelectionItem = nItems.get_child(i)
		var nBox: PanelContainer = nItem.find_child("Box")
		
		nItem.custom_minimum_size.y = item_height
		nBox.custom_minimum_size.y = item_height * 0.75
		
		nItem.position.y = i * item_height
	
	for i in range(offset, offset + middle_i + 1):
		var nItem: SongSelectionItem = nItems.get_child(i)
		var nBox: PanelContainer = nItem.find_child("Box")
		
		var si = i % (middle_i+1)
		var vi = middle_i - si
		nItem.position.x = vi * 100
	
	for i in range(offset + middle_i + 1, offset + middle_i + 4):
		var nItem: SongSelectionItem = nItems.get_child(i)
		var nBox: PanelContainer = nItem.find_child("Box")
		
		var vi = (i % (middle_i+1)) + 1
		nItem.position.x = vi * 100

func _on_Songs_item_rect_changed():
	if not nItems:
		return
	
	middle_y = get_viewport_rect().size.y / 2
	
	_process_items()

func _on_Item_selected(p_nItem: SongSelectionItem):
	print("Selected: ", p_nItem.get_index())
