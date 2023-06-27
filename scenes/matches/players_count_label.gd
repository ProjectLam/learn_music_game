extends Label

var player_limit := 0:
	set = set_player_limit


var player_count := 0:
	set = set_player_count


var full_stylebox: StyleBox


func _ready():
	refresh_theme()
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	text = "%d/%d" % [player_count, player_limit]
	
	self["theme_override_styles/normal"] = null if player_count < player_limit else full_stylebox


func refresh_theme():
	if has_theme_stylebox("full"):
		full_stylebox = get_theme_stylebox("full")


func set_player_limit(value: int) -> void:
	if player_limit != value:
		player_limit = value
		refresh()


func set_player_count(value: int) -> void:
	if player_count != value:
		player_count = value
		refresh()
