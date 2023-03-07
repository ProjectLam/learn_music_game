extends Control
class_name Score

@onready var nLeaderboard: Leaderboard = find_child("Leaderboard")
@onready var nScoreLabel: Label = find_child("ScoreLabel")
@onready var nScoreIcons = find_child("ScoreIcons")

var score: int = 0: set = set_score
var icons_score: int = 0: set = set_icons_score

func _ready():
	for i in range(1, 10):
		nLeaderboard.add_item(await TLeaderboardItem.new({
			"number": i,
			"user": {
				"id": i,
				"name": "Meowing Cat",
				"avatar_url": ""
			},
			"score": i * 10
		}))
		
		score = 1200
		icons_score = 2
	
	nLeaderboard.get_item(2).is_me = true

func _process(delta):
	pass

func set_score(p_score: int) -> void:
	score = p_score
	nScoreLabel.text = str(score)

func set_icons_score(p_score: int) -> void:
	icons_score = p_score
	
	var to = icons_score
	if to > nScoreIcons.get_child_count():
		to = nScoreIcons.get_child_count()
	
	for i in to:
		var nIcon: TextureRect = nScoreIcons.get_child(i)
		nIcon.modulate = nScoreLabel.get_theme_stylebox("normal").bg_color
		nIcon.modulate.a = 1
