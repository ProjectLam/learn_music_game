extends PanelContainer
#class_name LeaderboardItem

@onready var nNumberLabel: Label = find_child("NumberLabel")
@onready var nNameLabel: Label = find_child("NameLabel")
@onready var nPercentLabel: Label = find_child("PercentLabel")
@onready var nScoreLabel: Label = find_child("ScoreLabel")
@onready var nDateLabel: Label = find_child("DateLabel")
@onready var nAvatarImage: TextureRect = find_child("AvatarImage")

var nLeaderboard

var item: TLeaderboardItem: set = set_item
var is_me: bool = false: set = set_is_me

func _ready():
	pass

func _process(delta):
	pass

func set_item(p_item: TLeaderboardItem) -> void:
	item = p_item
#
#	if item.rank >= 0:
#		nNumberLabel.text = "#" + str(item.rank)
#		nNumberLabel.show()
#	else:
#		nNumberLabel.hide()
#
#	if item.user:
#		nNameLabel.text = item.user.username
#
#		if item.percent >= 0:
#			nPercentLabel.text = "%" + str(item.percent)
#			nPercentLabel.show()
#		else:
#			nPercentLabel.hide()
#
#		if item.score >= 0:
#			nScoreLabel.text = str(item.score)
#		else:
#			nScoreLabel.hide()
#
#	if item.date == "":
#		nDateLabel.hide()
#	else:
#		nDateLabel.text = item.date
#		nDateLabel.show()

func set_is_me(p_is_me: bool) -> void:
	is_me = p_is_me
	
	if is_me:
		add_theme_stylebox_override("panel", nLeaderboard.style_me)
