extends Control
class_name Leaderboard

@onready var cLeaderboardItem = preload("res://scenes/leaderboard/leaderboard_item.tscn")

@export var style_odd: StyleBox
@export var style_even: StyleBox
@export var style_me: StyleBox

@onready var nItems = find_child("Items")

func _ready():
	_update_style()

func _process(delta):
	pass

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
