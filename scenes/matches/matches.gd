extends Control
class_name Matches

@onready var cLeaderboardItem = preload("res://scenes/leaderboard/leaderboard_item.tscn")

@export var style_odd: StyleBox
@export var style_even: StyleBox
@export var style_mine: StyleBox

@export var min_players = 0
@export var max_players = 10
@export var limit = 10
@export var authoritative = false
@export var label = ""
@export var query = ""

@onready var nItems = find_child("Items")

func _ready():
	_update_style()
	await add_test_record()
	await load_items()

func add_test_record():
	var game_match: NakamaRTAPI.Match = await GBackend.socket.create_match_async("Meowing Cats Room")
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

func add_item(p_item: TLeaderboardItem):
	var nItem: LeaderboardItem = cLeaderboardItem.instantiate()
	nItems.add_child(nItem)
	nItem.nLeaderboard = self
	nItem.item = p_item
	_update_style()

func get_item(p_index: int) -> LeaderboardItem:
	return nItems.get_child(p_index)

func load_items() -> void:
	var result = await GBackend.client.list_matches_async(GBackend.session, min_players, max_players, limit, authoritative, label, query)
	
	for m in result.matches:
		var game_match: NakamaAPI.ApiMatch = m
		var item = await TMatchesItem.new()
		await item.set_nakama_object(game_match)
		print("%s: %s/10 players", game_match)
