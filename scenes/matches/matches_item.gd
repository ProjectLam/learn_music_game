extends PanelContainer
class_name MatchesItem

signal selected(match_id: String)
signal join_not_allowed(message: String)
signal protected_match_selected(match_id: String)

const ANIMATION_DURATION := 0.15

const status_indicator_texts := {
	LAMMatch.GameStatus.UNDEFINED: "[right] [/right]",
	LAMMatch.GameStatus.DEFAULT: "[right] [/right]",
	LAMMatch.GameStatus.STARTED: "[right]Started[/right]"
}

@onready var name_label = %NameLabel
@onready var song_label = %SongLabel
@onready var players_count_label = %PlayersCountLabel
@onready var instrument_label = %InstrumentLabel
@onready var focus_overlay = %FocusOverlay
@onready var tween: Tween
@onready var even_panel = %EvenPanel
@onready var odd_panel = %OddPanel
@onready var locked_icon = %LockedIcon
@onready var game_status_label = %GameStatusLabel


var style_odd: StyleBox
var style_even: StyleBox
var style_mine: StyleBox

var matchobj: LAMMatch:
	set = set_match

var target_fov_alpha := 0.0


func _init():
	matchobj = LAMMatch.new()


func _ready():
	
	focus_overlay.set("modulate", Color(1.0,1.0,1.0,0.0))
	
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	
	
	refresh()


func _process(delta):
	pass


var skip_click = false
# TODO : add touch events after porting to mobile.
func _gui_input(event):
	if event is InputEventMouseButton:
		if has_focus():
			accept_event()
			if not event.pressed and not skip_click:
				skip_click = false
			elif event.double_click:
				try_select_match()
					
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		try_select_match()
		accept_event()

@onready var prev_has_focus := has_focus()
func refresh() -> void:
	if not is_inside_tree():
		return
	if not matchobj or not matchobj.is_valid():
		return
	
	name_label.text = matchobj.match_name
	instrument_label.text = matchobj.instrument_name
	song_label.text = matchobj.song_identifier
	players_count_label.player_count = matchobj.player_count
	players_count_label.player_limit = matchobj.player_limit
	locked_icon.modulate = Color.WHITE if matchobj.password_proceted else Color.TRANSPARENT
	
	if prev_has_focus != has_focus():
		if has_focus():
			skip_click = true
			target_fov_alpha = 1.0
			var anim_duration = ANIMATION_DURATION*abs(focus_overlay.modulate.a - target_fov_alpha)
			new_tween()
			tween.tween_property(focus_overlay, "modulate:a", 1.0, anim_duration)
		else:
			skip_click = false
			target_fov_alpha = 0.0
			var anim_duration = ANIMATION_DURATION*abs(focus_overlay.modulate.a - target_fov_alpha)
			new_tween()
			tween.tween_property(focus_overlay, "modulate:a", 0.0, anim_duration)
	
	prev_has_focus = has_focus()
	if get_index() % 2 == 0:
		even_panel.show()
		odd_panel.hide()
	else:
		even_panel.hide()
		odd_panel.show()
	
	if matchobj.join_allowed_filter():
		game_status_label.text = "[color=yellow]" + status_indicator_texts[matchobj.game_status] + "[/color]"
	else:
		game_status_label.text = "[color=red]" + status_indicator_texts[matchobj.game_status] + "[/color]"


func try_select_match():
	if matchobj:
		if matchobj.player_count >= matchobj.player_limit:
			join_not_allowed.emit("Match is full")
			return
		
		if matchobj.join_allowed_filter():
			if matchobj.password_proceted:
				print("Trying to join password protected match with match_id = ", matchobj.match_id)
				protected_match_selected.emit(matchobj.match_id)
			else:
				print("Trying to join match with match_id = ", matchobj.match_id)
				selected.emit(matchobj.match_id)
		else:
			push_warning("Join not allowed")
			join_not_allowed.emit("Join not allowed!")

#func set_apimatch(value: NakamaAPI.ApiMatch) -> void:
#	matchobj.set_apimatch(value)


func set_match(value: LAMMatch) -> void:
	if matchobj != value:
		if matchobj and matchobj.changed.is_connected(_on_match_changed):
			matchobj.changed.disconnect(_on_match_changed)
		
		matchobj = value
		
		if matchobj:
			matchobj.changed.connect(_on_match_changed)
		if has_focus():
			release_focus()
		_on_match_changed()


func _on_match_changed() -> void:
	refresh()


func _on_focus_entered():
	refresh()


func _on_focus_exited():
	refresh()


func new_tween() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel()
