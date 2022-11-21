extends Control

var cInstrumentSelectionItem = preload("res://scenes/InstrumentSelection/InstrumentSelectionItem.tscn")

@onready var nItems = find_child("Items")

@export_range(0.1, 1) var unselected_scale: float = 0.5: set = set_unselected_scale

var items: TInstrumentSelectionItems: set = set_items
var animation_duration = 0.5

var nLeft
var nMiddle
var nRight

var nIncoming: InstrumentSelectionItem
var nDisappearing: InstrumentSelectionItem

var index = 1

var is_playing = false

func _ready():
	set_items(TInstrumentSelectionItems.new())
	
	var item
	
	item = items.set_item(
		"xylophone",
		"XYLOPHONE",
		load("res://assets/gui/main/xylopone.png"),
		0,
		0
	)
	nItems.add_child(item.nItem)
	
	item = items.set_item(
		"mandoline",
		"Mandoline",
		load("res://assets/gui/main/mandoline.png"),
		0,
		0
	)
	nItems.add_child(item.nItem)
	
	item = items.set_item(
		"fiddle",
		"Fiddle",
		load("res://assets/gui/main/fiddle.png"),
		0,
		0
	)
	nItems.add_child(item.nItem)
	
	item = items.set_item(
		"flute",
		"FLUTE",
		load("res://assets/gui/main/flute.png"),
		0,
		0
	)
	nItems.add_child(item.nItem)
	
	nLeft = nItems.get_child(0)
	nMiddle = nItems.get_child(1)
	nRight = nItems.get_child(2)
	
	for i in range(3, items.items.size()):
		var nItem: InstrumentSelectionItem = items.items.values()[i].nItem
		nItem.visible = false
	
	_process_items()

func _process(delta):
	for nItem in nItems.get_children():
		nItem.pivot_offset.x = nItem.size.x / 2
		nItem.pivot_offset.y = nItem.size.y / 2
	
	var x = get_viewport().get_mouse_position().x / get_viewport_rect().size.x
	var y = get_viewport().get_mouse_position().y / get_viewport_rect().size.y
	var pos = Vector2(x, y)
	
	$Background/Layer.material.set_shader_parameter("lighting_point", pos)

func set_items(p_items: TInstrumentSelectionItems):
	items = p_items

func _process_items():
	if not nItems:
		return
	
	var item_margin = 0
	
	var square_size = (nItems.size.x / 3) - (item_margin * 2)
	
	nLeft.size.x = square_size
	nMiddle.size.x = square_size
	nRight.size.x = square_size
	
	nLeft.size.y = square_size
	nMiddle.size.y = square_size
	nRight.size.y = square_size
	
	var pos0 = 0
	var pos1 = pos0 + nLeft.size.x + item_margin
	var pos2 = pos1 + nMiddle.size.x + item_margin
	
	nLeft.position.x = pos0
	nMiddle.position.x = pos1
	nRight.position.x = pos2
	
	var y = nItems.size.y / 2 - nLeft.size.y / 2
	
	nLeft.position.y = y
	nMiddle.position.y = y
	nRight.position.y = y
	
	nLeft.scale = Vector2(unselected_scale, unselected_scale)
	nRight.scale = Vector2(unselected_scale, unselected_scale)

func go_left():
	if is_playing:
		return
	
	is_playing = true
	
	index = (index+1) % items.items.size()
	
	nIncoming = items.get_item_circular(index+1).nItem
	nDisappearing = nLeft
	
	nIncoming.size = nRight.size
	nIncoming.position.y = nRight.position.y
	nIncoming.position.x = nRight.position.x + nRight.size.x
	nIncoming.scale = nRight.scale
	nIncoming.visible = true
	
	var nLeft_pos = nLeft.position
	var nLeft_scale = nLeft.scale
	
	var nMiddle_pos = nMiddle.position
	var nMiddle_scale = nMiddle.scale
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(nLeft, "position:x", nLeft.position.x - nLeft.size.x, animation_duration)
	tween.tween_property(nMiddle, "position:x", nLeft_pos.x, animation_duration)
	tween.tween_property(nMiddle, "scale", nLeft_scale, animation_duration)
	tween.tween_property(nRight, "position:x", nMiddle_pos.x, animation_duration)
	tween.tween_property(nRight, "scale", nMiddle_scale, animation_duration)
	tween.tween_property(nIncoming, "position:x", nRight.position.x, animation_duration)
	
	nLeft = nMiddle
	nMiddle = nRight
	nRight = nIncoming
	
	var nDisappearing_curr = nDisappearing
	
	tween.connect("finished", func ():
		nDisappearing_curr.visible = false
		is_playing = false
	)

func go_right():
	if is_playing:
		return
	
	is_playing = true
	
	index = (index-1) % items.items.size()
	
	nIncoming = items.get_item_circular(index-1).nItem
	nDisappearing = nRight
	
	nIncoming.size = nLeft.size
	nIncoming.position.y = nLeft.position.y
	nIncoming.position.x = nLeft.position.x - nRight.size.x
	nIncoming.scale = nLeft.scale
	nIncoming.visible = true
	
	var nRight_pos = nRight.position
	var nRight_scale = nRight.scale
	
	var nMiddle_pos = nMiddle.position
	var nMiddle_scale = nMiddle.scale
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(nRight, "position:x", nRight.position.x + nRight.size.x, animation_duration)
	tween.tween_property(nMiddle, "position:x", nRight_pos.x, animation_duration)
	tween.tween_property(nMiddle, "scale", nRight_scale, animation_duration)
	tween.tween_property(nLeft, "position:x", nMiddle_pos.x, animation_duration)
	tween.tween_property(nLeft, "scale", nMiddle_scale, animation_duration)
	tween.tween_property(nIncoming, "position:x", nLeft.position.x, animation_duration)
	
	nRight = nMiddle
	nMiddle = nLeft
	nLeft = nIncoming
	
	var nDisappearing_curr = nDisappearing
	
	tween.connect("finished", func ():
		nDisappearing_curr.visible = false
		is_playing = false
	)

func set_unselected_scale(p_scale: float):
	unselected_scale = p_scale
	_process_items()

func _on_left_btn_pressed():
	go_left()

func _on_right_btn_pressed():
	go_right()

func _on_Items_item_rect_changed():
	_process_items()

func _on_script_changed():
	_process_items()
