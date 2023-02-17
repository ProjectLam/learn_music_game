extends PanelContainer

const ISELECT_ITEM = preload("res://scenes/instrument_selection/instrument_selection_item.tscn")

@onready var items_container := %ItemsContainer

@export_range(0.1, 1) var unselected_scale: float = 0.5: set = set_unselected_scale

@export var auto_select := false

var default_animation_duration := 0.18

var left_node
var middle_node
var right_node

var incoming_node: InstrumentSelectionItem
var disappearing_node: InstrumentSelectionItem

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
		var node = item_nodes[index]
		if node.instrument_data == current_instrument:
			current_index = index
	
	var lindex := posmod(current_index - 1, item_nodes.size())
	var rindex := posmod(current_index + 1, item_nodes.size())
	left_node = item_nodes[lindex]
	middle_node = item_nodes[current_index]
	right_node = item_nodes[rindex]
	
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
	
	left_node.size.x = square_size
	middle_node.size.x = square_size
	right_node.size.x = square_size
	
	left_node.size.y = square_size
	middle_node.size.y = square_size
	right_node.size.y = square_size
	
	var pos0 = 0
	var pos1 = pos0 + left_node.size.x + item_margin
	var pos2 = pos1 + middle_node.size.x + item_margin
	
	left_node.position.x = pos0
	middle_node.position.x = pos1
	right_node.position.x = pos2
	
	var y = items_container.size.y / 2 - left_node.size.y / 2
	
	left_node.position.y = y
	middle_node.position.y = y
	right_node.position.y = y
	
	left_node.scale = get_slot_scale(0)
	right_node.scale = get_slot_scale(2)


func get_slot_x(slot_index: int) -> int:
	var item_margin := 0
	var square_size: int = (items_container.size.x / 3) - (item_margin * 2)
	return (square_size + item_margin)*slot_index


func get_slot_scale(slot_index: int) -> Vector2:
	match slot_index:
		1:
			return Vector2(1.0, 1.0)
		_:
			return Vector2(unselected_scale, unselected_scale)


func go_left() -> void:
	var anim_duration := default_animation_duration
	if playing_tween.is_running():
		match(playing_dir):
			-1:
				while(true):
					await get_tree().process_frame
					if not is_inside_tree():
						return
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
	
	incoming_node = items[incoming_index]
	disappearing_node = left_node
	
	incoming_node.size = right_node.size
	incoming_node.position.y = right_node.position.y
	incoming_node.position.x = right_node.position.x + right_node.size.x
	incoming_node.scale = right_node.scale
	incoming_node.visible = true
	
	var left_node_pos = left_node.position
	var left_node_scale = left_node.scale
	
	var middle_node_pos = middle_node.position
	var middle_node_scale = middle_node.scale
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(left_node, "position:x", get_slot_x(-1), anim_duration)
	tween.tween_property(left_node, "scale", get_slot_scale(-1), anim_duration)
	tween.tween_property(middle_node, "position:x", get_slot_x(0), anim_duration)
	tween.tween_property(middle_node, "scale", get_slot_scale(0), anim_duration)
	tween.tween_property(right_node, "position:x", get_slot_x(1), anim_duration)
	tween.tween_property(right_node, "scale", get_slot_scale(1), anim_duration)
	tween.tween_property(incoming_node, "position:x", get_slot_x(2), anim_duration)
	tween.tween_property(incoming_node, "scale", get_slot_scale(2), anim_duration)
	
	playing_tween = tween
	
	left_node = middle_node
	middle_node = right_node
	right_node = incoming_node
	
	var disappearing_node_curr = disappearing_node
	
	tween.connect("finished", func ():
		disappearing_node_curr.visible = false
	)
	
	if(auto_select):
		select_current()


func go_right() -> void:
	var anim_duration := default_animation_duration
	if playing_tween.is_running():
		match(playing_dir):
			1:
				while(true):
					await get_tree().process_frame
					if not is_inside_tree():
						return
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
	
	disappearing_node = right_node
	incoming_node = items[disappearing_index]
	
	incoming_node.size = left_node.size
	incoming_node.position.y = left_node.position.y
	incoming_node.position.x = left_node.position.x - right_node.size.x
	incoming_node.scale = left_node.scale
	incoming_node.visible = true
	
	var right_node_pos = right_node.position
	var right_node_scale = right_node.scale
	
	var middle_node_pos = middle_node.position
	var middle_node_scale = middle_node.scale
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(right_node, "position:x", get_slot_x(3), anim_duration)
	tween.tween_property(right_node, "scale", get_slot_scale(3), anim_duration)
	tween.tween_property(middle_node, "position:x", get_slot_x(2), anim_duration)
	tween.tween_property(middle_node, "scale", get_slot_scale(2), anim_duration)
	tween.tween_property(left_node, "position:x", get_slot_x(1), anim_duration)
	tween.tween_property(left_node, "scale", get_slot_scale(1), anim_duration)
	tween.tween_property(incoming_node, "position:x", get_slot_x(0), anim_duration)
	tween.tween_property(incoming_node, "scale", get_slot_scale(0), anim_duration)
	
	playing_tween = tween
	
	right_node = middle_node
	middle_node = left_node
	left_node = incoming_node
	
	var disappearing_node_curr = disappearing_node
	
	tween.connect("finished", func ():
		disappearing_node_curr.visible = false
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
