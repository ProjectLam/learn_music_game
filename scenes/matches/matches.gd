extends PanelContainer
class_name Matches

# Later this class and LAMMatch might need to be moved to c++ when match count becomes high.
# TODO : add maximum loaded match count per second.
# TODO : add loading icon for when matches are loading.

signal match_selected(match_id: String)
signal join_not_allowed(message: String)
signal protected_match_selected(match_id: String)
signal create_match_pressed

const MATCH_ITEM_SCENE = preload("res://scenes/matches/matches_item.tscn")

@export var style_odd: StyleBox
@export var style_even: StyleBox
@export var style_mine: StyleBox
@export var min_players = 1
@export var max_players = -1
@export var limit = 10
@export var authoritative = true
@export var label = ""
@export var query = ""
@onready var items = %Items
@onready var allowed_filter = %AllowedFilter
@onready var refreshing_panel = %RefreshingPanel
@onready var create_match_button = %CreateMatchButton

var refresh_counter: int = 0
# (match_id, control) pairs.
var match_items := {}
# (match_id, LAMMatch) pairs
var match_objects := {}

# having a focused match will allow external nodes to view more details about 
# the focused match if needed.
var focused_match_item: Control


var filter_allowed := true


signal full_initialization
var _is_fully_initialized = false


# use 'await await_finit()' to wait for full initialization.
func await_finit():
	if _is_fully_initialized:
		return
	await full_initialization


func _ready():
	refreshing_panel.visible = false
	allowed_filter.set_pressed_no_signal(filter_allowed)
	
	focus_entered.connect(_on_focus_entered)
	await GBackend.await_finit()
	_is_fully_initialized = true
	emit_signal("full_initialization")
	refresh_matches()


func _process(delta):
	pass


var last_match_list := NakamaAPI.ApiMatchList.new()
func reload_items():
	var rc = refresh_counter
	var last_match_list: NakamaAPI.ApiMatchList = await MatchManager.list_matches_async()
	if rc != refresh_counter:
		return
	_reload_items(last_match_list)


# override reload items to pass fake items for testing.
func _reload_items(all_matches_list: NakamaAPI.ApiMatchList):
	var focused_alapha = -1.0
	var focused_match_id := ""
	if is_instance_valid(focused_match_item) and focused_match_item.has_focus():
		focused_alapha = focused_match_item.focus_overlay.modulate.a
		focused_match_id = focused_match_item.matchobj.match_id
	
	var included_matches: Array[LAMMatch]
	
	var new_match_objects := {}
	for apimatch in all_matches_list.matches:
		if apimatch.authoritative and apimatch.size > 0:
			var mid: String = apimatch.match_id
			var old_match_obj = match_objects.get(mid)
			if old_match_obj:
				old_match_obj.set_apimatch(apimatch)
				new_match_objects[apimatch.match_id] = old_match_obj
			else:
				new_match_objects[apimatch.match_id] = LAMMatch.new(apimatch)
	
	# old objects are erased automatically because they aren't on new_match_objects.
	match_objects = new_match_objects
	
	for match_id in _get_sorted_match_id_array():
		# filering happens here.
		var matchobj = match_objects[match_id]
		if filter_allowed and not matchobj.join_allowed_filter():
			continue
		included_matches.append(matchobj)
	
	match_items.clear()
	
	refresh_item_count(included_matches.size())
	
	var items_children = items.get_children()
	
	var fallback_focus := true
	for index in included_matches.size():
		var matchobj := included_matches[index]
		var control = items_children[index]
		control.matchobj = matchobj
		match_items[matchobj.match_id] = control
		if matchobj.match_id == focused_match_id:
			control.focus_overlay.modulate.a = focused_alapha
			control.grab_focus()
			fallback_focus = false
	
	if fallback_focus:
		grab_focus()


func refresh_item_count(target_count: int):
	var current_count = items.get_child_count()
	if current_count > target_count:
		var items_children = items.get_children()
		for i in range(current_count - 1, target_count - 1, -1):
			items_children[i].queue_free()
	elif current_count < target_count:
		for i in target_count - current_count:
			var match_node = MATCH_ITEM_SCENE.instantiate()
			match_node.selected.connect(_on_match_item_selected)
			match_node.join_not_allowed.connect(_on_match_item_join_not_allowed)
			match_node.protected_match_selected.connect(_on_match_item_protected_match_selected)
			match_node.focus_entered.connect(
					func() : _on_match_item_focus_entered(match_node))
			items.add_child(match_node)


#func _on_refresh_timer_timeout() -> void:
#	await reload_items()
#	refresh_timer.start()

func refresh_matches() -> void:
	refresh_counter += 1
	var rc = refresh_counter
	refreshing_panel.visible = true
	await reload_items()
	if rc != refresh_counter:
		return
	
	refreshing_panel.visible = false

func _on_match_item_selected(match_id: String) -> void:
	match_selected.emit(match_id)


func _on_match_item_focus_entered(match_item: Control) -> void:
	focused_match_item = match_item


# Later this should also use sorting parameters.
func _get_sorted_match_id_array() -> Array:
	var ret := match_objects.keys()
	ret.sort()
	
	return ret


func _on_allowed_filter_toggled(button_pressed):
	filter_allowed = button_pressed
	
	_reload_items(last_match_list)


func clear_reload_matches():
	# This is a placeholder function. later on when this function is called a loading icon should appear.
	call_deferred("reload_items")


func _on_focus_entered():
	if items.get_child_count() > 0:
		items.get_child(0).grab_focus()


func _on_create_match_button_pressed():
	create_match_pressed.emit()


func has_match(match_id: String) -> bool:
	if match_objects.has(match_id):
		return true
	
	return false


func _on_match_item_join_not_allowed(message: String) -> void:
	join_not_allowed.emit(message)


func _on_match_item_protected_match_selected(match_id: String) -> void:
	protected_match_selected.emit(match_id)
	
