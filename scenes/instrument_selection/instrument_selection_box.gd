extends PanelContainer

const ISELECT_ITEM = preload("res://scenes/instrument_selection/instrument_selection_item.tscn")

@onready var items_container := %ItemsContainer

@export_range(0.1, 1) var unselected_scale: float = 0.5: set = set_unselected_scale

@export var auto_select := false

var default_animation_duration = 0.18

var nLeft
var nMiddle
var nRight

var nIncoming: InstrumentSelectionItem
var nDisappearing: InstrumentSelectionItem

var current_index = 1

# -1 is left, 1 is right.
var playing_dir: int = 0
@onready var playing_tween: Tween = get_tree().create_tween()

var is_ready := false


func _ready():
	for key in InstrumentList.instruments:
		var ins_data: InstrumentData = InstrumentList.instruments[key]
		var new_child := ISELECT_ITEM.instantiate()
		new_child.instrument_data = ins_data
		items_container.add_child(new_child)
	
	# Fill empty spots. This is in case instrument count is less than 3
	while(items_container.get_children().size() < 4):
		var a = items_container.get_children().size()
		for key in InstrumentList.instruments:
			var ins_data: InstrumentData = InstrumentList.instruments[key]
			var new_child := ISELECT_ITEM.instantiate()
			new_child.instrument_data = ins_data
			items_container.add_child(new_child)
			if items_container.get_children().size() == 4:
				break
	
	var item_nodes = items_container.get_children()
	
	var current_instrument := PlayerVariables.gameplay_instrument_data
	
	for index in item_nodes.size():
		var node := item_nodes[index]
		if node.instrument_data == current_instrument:
			current_index = index
	
	var lindex := posmod(current_index - 1, item_nodes.size())
	var rindex := posmod(current_index + 1, item_nodes.size())
	nLeft = item_nodes[lindex]
	nMiddle = item_nodes[current_index]
	nRight = item_nodes[rindex]
	
	for index in item_nodes.size():
		if(index == lindex or index == current_index or index == rindex):
			continue
		var child = item_nodes[index]
		child.visible = false
	
	is_ready = true
	
	_process_items()
	


func _process(delta):
	for item_node in items_container.get_children():
		item_node.pivot_offset.x = item_node.size.x / 2
		item_node.pivot_offset.y = item_node.size.y / 2


func _process_items():
	if not is_ready:
		return
	
	var item_margin = 0
	
	var square_size = (items_container.size.x / 3) - (item_margin * 2)
	
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
	
	var y = items_container.size.y / 2 - nLeft.size.y / 2
	
	nLeft.position.y = y
	nMiddle.position.y = y
	nRight.position.y = y
	
	nLeft.scale = Vector2(unselected_scale, unselected_scale)
	nRight.scale = Vector2(unselected_scale, unselected_scale)


func get_slot_x(slot_index : int) -> int:
	var item_margin := 0
	var square_size: int = (items_container.size.x / 3) - (item_margin * 2)
	return (square_size + item_margin)*slot_index


func go_left():
	var anim_duration := default_animation_duration
	if playing_tween.is_running():
		match(playing_dir):
			-1:
				while(true):
					await get_tree().process_frame
					if not playing_tween.is_running():
						break
				if playing_dir != -1:
					return
			1:
				anim_duration = playing_tween.get_total_elapsed_time()
				playing_tween.kill()
			0:
				playing_tween.kill()
			_:
				push_error("invalid playing_dir %d" % playing_dir)
				return
	playing_dir = -1
	
	var items := items_container.get_children()
	
	current_index = posmod(current_index + 1, items.size())
	var incoming_index :int = posmod(current_index + 1, items.size())
	
	nIncoming = items[incoming_index]
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
	tween.tween_property(nLeft, "position:x", get_slot_x(-1), anim_duration)
	tween.tween_property(nMiddle, "position:x", get_slot_x(0), anim_duration)
	tween.tween_property(nMiddle, "scale", nLeft_scale, anim_duration)
	tween.tween_property(nRight, "position:x", get_slot_x(1), anim_duration)
	tween.tween_property(nRight, "scale", nMiddle_scale, anim_duration)
	tween.tween_property(nIncoming, "position:x", get_slot_x(2), anim_duration)
	
	playing_tween = tween
	
	nLeft = nMiddle
	nMiddle = nRight
	nRight = nIncoming
	
	var nDisappearing_curr = nDisappearing
	
	tween.connect("finished", func ():
		nDisappearing_curr.visible = false
	)
	
	if(auto_select):
		select_current()


func go_right():
	var anim_duration := default_animation_duration
	if playing_tween.is_running():
		match(playing_dir):
			1:
				while(true):
					await get_tree().process_frame
					if not playing_tween.is_running():
						break
				if playing_dir != 1:
					return
			-1:
				anim_duration = playing_tween.get_total_elapsed_time()
				playing_tween.kill()
			0:
				playing_tween.kill()
			_:
				push_error("invalid playing_dir %d" % playing_dir)
				return
	playing_dir = 1
	
	var items := items_container.get_children()
	
	current_index = posmod(current_index - 1 + items.size(), items.size())
	var disappearing_index: int = posmod(current_index - 1 + items.size(), items.size())
	
	nDisappearing = nRight
	nIncoming = items[disappearing_index]
	
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
	tween.tween_property(nRight, "position:x", get_slot_x(3), anim_duration)
	tween.tween_property(nMiddle, "position:x", get_slot_x(2), anim_duration)
	tween.tween_property(nMiddle, "scale", nRight_scale, anim_duration)
	tween.tween_property(nLeft, "position:x", get_slot_x(1), anim_duration)
	tween.tween_property(nLeft, "scale", nMiddle_scale, anim_duration)
	tween.tween_property(nIncoming, "position:x", get_slot_x(0), anim_duration)
	
	playing_tween = tween
	
	nRight = nMiddle
	nMiddle = nLeft
	nLeft = nIncoming
	
	var nDisappearing_curr = nDisappearing
	
	tween.connect("finished", func ():
		nDisappearing_curr.visible = false
	)
	
	if(auto_select):
		select_current()


func set_unselected_scale(p_scale: float) -> void:
	unselected_scale = p_scale
	_process_items()


func _on_items_container_item_rect_changed() -> void:
	_process_items()


func select_current() -> void:
	var curr_item := items_container.get_child(current_index)
	var instrument_data: InstrumentData = curr_item.instrument_data
	PlayerVariables.gameplay_instrument_data = instrument_data
	PlayerVariables.save()
