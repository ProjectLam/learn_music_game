extends PanelContainer
class_name MatchesItem

@onready var nNumberLabel: Label = find_child("NumberLabel")
@onready var nNameLabel: Label = find_child("NameLabel")
@onready var nPlayersCountLabel: Label = find_child("PlayersCountLabel")
@onready var nAvatarImage: TextureRect = find_child("AvatarImage")

var nMatches

var item: TMatchesItem: set = set_item
var is_mine: bool = false: set = set_is_mine

func _ready():
	pass

func _process(delta):
	pass

func set_item(p_item: TMatchesItem) -> void:
	item = p_item
	
	if item.user:
		nNameLabel.text = item.user.username
		
		if item.percent >= 0:
			nPlayersCountLabel.text = "%" + str(item.percent)
			nPlayersCountLabel.show()
		else:
			nPlayersCountLabel.hide()

func set_is_mine(p_is_mine: bool) -> void:
	is_mine = p_is_mine
	
	if is_mine:
		add_theme_stylebox_override("panel", nMatches.style_mine)
