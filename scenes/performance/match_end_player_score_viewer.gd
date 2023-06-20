extends PanelContainer

@onready var even_panel = %EvenPanel
@onready var odd_panel = %OddPanel

@onready var score_label = %ScoreLabel
@onready var name_label = %NameLabel

var score: String = "Syncing":
	set = set_score

var username: String = "":
	set = set_username

# Called when the node enters the scene tree for the first time.
func _ready():
	score_label.text = str(score)
	name_label.text = username


func set_score(value):
	if score != value:
		score = value
		if is_instance_valid(score_label):
			score_label.text = str(value)


func set_username(value):
	if username != value:
		username = value
		if is_instance_valid(name_label):
			name_label.text = username
