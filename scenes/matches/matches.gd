extends PanelContainer
class_name Matches

signal match_selected(match_id: String)

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
@onready var refresh_timer = %RefreshTimer

# (match_id, control) pairs.
var match_items := {}

# having a focused match will allow external nodes to view more details about 
# the focused match if needed.
var focused_match: NakamaAPI.ApiMatch

signal full_initialization
var _is_fully_initialized = false

# use 'await await_finit()' to wait for full initialization.
func await_finit():
	if _is_fully_initialized:
		return
	await full_initialization


func _ready():
	focus_entered.connect(_on_focus_entered)
	await GBackend.await_finit()
	_is_fully_initialized = true
	emit_signal("full_initialization")
	
	_on_refresh_timer_timeout()


func _process(delta):
	pass


func reload_items():
	var match_list: NakamaAPI.ApiMatchList = await GBackend.list_matches_async(min_players, max_players, limit, label, query)
	var included_matches: Array[NakamaAPI.ApiMatch]
	for apimatch in match_list.matches:
		var mtch: NakamaAPI.ApiMatch = apimatch
		if mtch.authoritative and mtch.size > 0:
			included_matches.append(mtch)
	_reload_items(included_matches)


# override reload items to pass fake items for testing.
func _reload_items(included_matches: Array[NakamaAPI.ApiMatch]):
	match_items.clear()
	refresh_item_count(included_matches.size())
	
	var items_children = items.get_children()
	
	for i in included_matches.size():
		var apimatch := included_matches[i]
		var control = items_children[i]
		control.set_apimatch(apimatch)
		match_items[apimatch.match_id] = control

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
			match_node.focus_entered.connect(
					func() : _on_match_item_focus_entered(match_node))
			items.add_child(match_node)


func _on_refresh_timer_timeout() -> void:
	await reload_items()
	refresh_timer.start()


#var joining_match := false
func _on_match_item_selected(match_id: String) -> void:
	match_selected.emit(match_id)
#	if joining_matcmh:
#		return
#	joining_match = true
#
#	print("Match selected: ", match_id)
#	SessionVariables.single_player = false
#	var err = await GBackend.join_match_async(match_id)
#	if err:
#		joining_match = false
#		return
#	get_tree().change_scene_to_file("res://scenes/performance.tscn")


func _on_focus_entered():
	if focused_match:
		var match_item = match_items.get(focused_match.match_id)
		if is_instance_valid(match_item):
			match_item.grab_focus()
		elif items.get_child_count() > 0:
			items.get_child(0).grab_focus()
		else:
			# TODO : check if release_focus is the right function to call.
			release_focus()
	else:
		# TODO : check if release_focus is the right function to call.
		release_focus()


func _on_match_item_focus_entered(match_item: MatchesItem):
	focused_match = match_item.apimatch
