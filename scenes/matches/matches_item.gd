extends PanelContainer
class_name MatchesItem

signal selected(match_id: String)

const ANIMATION_DURATION := 0.15

@onready var name_label = %NameLabel
@onready var song_label = %SongLabel
@onready var players_count_label = %PlayersCountLabel
@onready var instrument_label = %InstrumentLabel
@onready var focus_overlay = %FocusOverlay
@onready var playing_tween: Tween
@onready var even_panel = %EvenPanel
@onready var odd_panel = %OddPanel


var style_odd: StyleBox
var style_even: StyleBox
var style_mine: StyleBox

var apimatch: NakamaAPI.ApiMatch :
	set = set_apimatch
var match_id: String = ""
var paresd_label :
	set = set_parsed_label
var instrument_name := "" :
	set = set_instrument_name
var song_identifier := "" :
	set = set_song_identifier
var player_count := 0 :
	set = set_player_count
var match_name := "" :
	set = set_match_name

func _ready():
	focus_overlay.set("modulate", Color(1.0,1.0,1.0,0.0))
	
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	name_label.text = match_name
	instrument_label.text = instrument_name
	song_label.text = song_identifier
	players_count_label.text = str(player_count)
	refresh()


func _process(delta):
	pass


var skip_click = false
# TODO : add touch events after porting to mobile.
func _gui_input(event):
	if event is InputEventMouseButton:
		if has_focus():
			if not event.pressed and not skip_click:
				skip_click = false
			elif event.double_click:
				selected.emit(match_id)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		selected.emit(match_id)
		accept_event()


@onready var prev_has_focus := has_focus()
func refresh() -> void:
	if not is_inside_tree():
		return
	
	match_name = "invalid name"
	song_identifier = ""
	instrument_name = ""
	if not (paresd_label is Dictionary):
		push_error("Invalid match label detected")
	else:
		var lname = paresd_label.get("name")
		if not (lname is String):
			push_error("Ivalid match name")
		else:
			match_name = lname
		var lsongid = paresd_label.get("song")
		if not (lsongid is String):
			push_error("Invalid song identifier")
		else:
			song_identifier = lsongid
		var linsname = paresd_label.get("instrument")
		if not (linsname is String):
			push_error("Invalid instrument name")
		else:
			instrument_name = linsname.get_basename()
	
	if prev_has_focus != has_focus():
		if has_focus():
			skip_click = true
			var anim_duration = ANIMATION_DURATION
			if playing_tween:
				playing_tween.pause()
				var spent_time := playing_tween.get_total_elapsed_time()
				var remaining_time = max(ANIMATION_DURATION - spent_time,0)
				anim_duration = max(ANIMATION_DURATION - remaining_time, 0)
				playing_tween.kill()
			var tween := get_tree().create_tween()
			
			tween.tween_property(focus_overlay, "modulate:a", 1.0, anim_duration)
			playing_tween = tween
		else:
			skip_click = false
			var anim_duration = ANIMATION_DURATION
			if playing_tween:
				playing_tween.pause()
				var spent_time := playing_tween.get_total_elapsed_time()
				var remaining_time = max(ANIMATION_DURATION - spent_time,0)
				anim_duration = max(ANIMATION_DURATION - remaining_time, 0)
				playing_tween.kill()
			var tween := get_tree().create_tween()
			
			tween.tween_property(focus_overlay, "modulate:a", 0.0, anim_duration)
			
			playing_tween = tween
	
	prev_has_focus = has_focus()
	if get_index() % 2 == 0:
		even_panel.show()
		odd_panel.hide()
	else:
		even_panel.hide()
		odd_panel.show()


func set_apimatch(value: NakamaAPI.ApiMatch) -> void:
	if apimatch != value:
		apimatch = value
		match_id = apimatch.match_id
		player_count = apimatch.size
		paresd_label = JSON.parse_string(apimatch.label)
#		refresh()


func set_parsed_label(value):
	if paresd_label != value:
		paresd_label = value
		refresh()


func set_instrument_name(value: String) -> void:
	if instrument_name != value:
		instrument_name = value
		if is_inside_tree():
			instrument_label.text = instrument_name


func set_song_identifier(value: String) -> void:
	if song_identifier != value:
		song_identifier = value
		if is_inside_tree():
			song_label.text = song_identifier


func set_player_count(value: int) -> void:
	if player_count != value:
		if value < 0:
			push_warning("invalid player count")
			player_count = 0
		else:
			player_count = value
		if is_inside_tree():
			players_count_label.text = str(player_count)


func set_match_name(value: String) -> void:
	if match_name != value:
		match_name = value
		if is_inside_tree():
			name_label.text = match_name


func _on_focus_entered():
	refresh()


func _on_focus_exited():
	refresh()
