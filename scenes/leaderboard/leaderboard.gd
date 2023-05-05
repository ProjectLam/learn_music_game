extends Control
class_name Leaderboard

@onready var cLeaderboardItem = preload("res://scenes/leaderboard/leaderboard_item.tscn")

@export var style_odd: StyleBox
@export var style_even: StyleBox
@export var style_me: StyleBox

@onready var nItems = find_child("Items")

func _ready():
	await GBackend.await_finit()
	_update_style()
	load_items()
#	add_test_record()

func add_test_record():
	var leaderboard_id = "TestBoard"
	var score = 160
	var record: NakamaAPI.ApiLeaderboardRecord = await GBackend.client.write_leaderboard_record_async(GBackend.session, leaderboard_id, score)
	if record.is_exception():
		print("An error occurred while loading leaderboard: ", record)
		return
	print("New record username %s and score %s" % [record.username, record.score])
	

func _update_style() -> void:
	for i in nItems.get_child_count():
		var nItem: PanelContainer = nItems.get_child(i)
		if i % 2 == 0:
			nItem.add_theme_stylebox_override("panel", style_odd)
		else:
			nItem.add_theme_stylebox_override("panel", style_even)


func add_item(item: TLeaderboardItem):
	var nItem: LeaderboardItem = cLeaderboardItem.instantiate()
	nItems.add_child(nItem)
	nItem.nLeaderboard = self
	nItem.item = item
	_update_style()


func get_item(p_index: int) -> LeaderboardItem:
	return nItems.get_child(p_index)


func load_items() -> void:
	if not GBackend.connection_status != GBackend.CONNECTION_STATUS.CONNECTED:
		return
	
#	var leaderboard_id = "TestBoard"
#	var result: NakamaAPI.ApiLeaderboardRecordList = await GBackend.client.list_leaderboard_records_async(GBackend.session, leaderboard_id)
#	if result.is_exception():
#		print("An error occurred while loading leaderboard: %s" % result)
#		return
#
#	for r in result.records:
#		var record: NakamaAPI.ApiLeaderboardRecord = r
#		var item: TLeaderboardItem = await TLeaderboardItem.new()
#		await item.set_nakama_object(record)
#		add_item(item)
