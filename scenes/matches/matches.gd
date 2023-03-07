extends Control
class_name Matches

@onready var cMatchesItem = preload("res://scenes/matches/matches_item.tscn")

@export var style_odd: StyleBox
@export var style_even: StyleBox
@export var style_mine: StyleBox

@export var min_players = 0
@export var max_players = 1
@export var limit = 10
@export var authoritative = false
@export var label = ""
@export var query = ""

@onready var nItems = find_child("Items")

signal full_initialization

# use 'await await_finit()' to wait for full initialization.
func await_finit():
	if _is_fully_initialized:
		return
	await full_initialization

var _is_fully_initialized = false

func _ready():
	_update_style()
	await GBackend.await_finit()
	await load_items()
	_is_fully_initialized = true
	emit_signal("full_initialization")

func add_test_record():
	var game_match: NakamaRTAPI.Match = await GBackend.create_match_async("Meowing Cats Room")
	print("Match created: #%s - %s" % [game_match.match_id, game_match.label])
	return game_match

func _process(delta):
	pass

func _update_style() -> void:
	for i in nItems.get_child_count():
		var nItem: PanelContainer = nItems.get_child(i)
		if i % 2 == 0:
			if style_odd:
				nItem.add_theme_stylebox_override("panel", style_odd)
		else:
			if style_even:
				nItem.add_theme_stylebox_override("panel", style_even)

func add_item(p_item: TMatchesItem) -> void:
	var node_name = p_item.nakama_object.match_id.replace(".", "")
	
	var nExisting = nItems.get_node_or_null(node_name)
	
	if nExisting:
		return
	
	var nItem: MatchesItem = cMatchesItem.instantiate()
	nItem.name = node_name
	nItem.connect("selected", _on_Item_selected)
	nItems.add_child(nItem, true)
	nItem.nMatches = self
	nItem.item = p_item
	_update_style()

func get_item(p_index: int) -> MatchesItem:
	return nItems.get_child(p_index)

func load_items() -> void:
	if(!GBackend.is_fully_initialized()):
		return
	print("Loading matches...")
	
	var result = await GBackend.client.list_matches_async(GBackend.session, min_players, max_players, limit, authoritative, label, query)
	
	print("Total Matches: ", result.matches.size())
	
	var match_ids = []
	
	for m in result.matches:
		var game_match: NakamaAPI.ApiMatch = m
		if game_match.size > max_players:
			var node_name = game_match.match_id.replace(".", "")
			var nExisting = nItems.get_node_or_null(node_name)
			if nExisting:
				nExisting.queue_free()
		
		var item: TMatchesItem = await TMatchesItem.new()
		await item.set_nakama_object(game_match)
		add_item(item)
		
		match_ids.push_back(game_match.match_id)
	
	for i in nItems.get_children():
		var nExisting: MatchesItem = i
		if not match_ids.has(nExisting.item.nakama_object.match_id):
			nExisting.queue_free()

func _on_RefreshTimer_timeout() -> void:
	await load_items()
	$RefreshTimer.start()

func _on_Item_selected(p_nItem: MatchesItem) -> void:
	print("Match selected: ", p_nItem.item.nakama_object.match_id)
	SessionVariables.single_player = false
	await GBackend.join_match_async(p_nItem.item.nakama_object.match_id)
	get_tree().change_scene_to_file("res://scenes/performance.tscn")
