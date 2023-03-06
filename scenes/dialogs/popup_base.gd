extends PanelContainer
class_name PopupBase

signal option_selected(params)
signal closed
signal opened

# add new options here.
const OPTION_LOGIN := "login"
const OPTION_REGISTER := "register"
const OPTION_CLOSE := "close"

@onready var animation_player = %AnimationPlayer
@onready var click_blocker = %ClickBlocker#get_node_or_null("%ClickBlocker")
@export var free_on_select := false
@export var open_on_ready := false
@export var disabled := false :
	set = set_disabled

var opening := false

var done := true:
	set(value):
		if done != value:
			done = value
			visible = not done


var is_ready := false
func _ready():
	if disabled:
			visible = false
	
	focus_mode = Control.FOCUS_ALL
	await get_tree().process_frame
	if open_on_ready:
		open()
	else:
		visible = false
		animation_player.play("Close")
		animation_player.advance(10.0)
	is_ready = true


func await_ready() -> void:
	while not is_ready:
		await get_tree().process_frame


func _input(event):
	if not visible:
		return
	var focus_owner = get_viewport().gui_get_focus_owner()
	if has_focus() or (focus_owner and is_ancestor_of(focus_owner)):
		if event.is_action_pressed("ui_focus_next", true):
			var next = focus_owner.find_next_valid_focus()
			if not is_ancestor_of(next):
				next = find_next_valid_focus()
			if is_ancestor_of(next):
				next.grab_focus()
			accept_event()
		elif event.is_action_pressed("ui_focus_prev", true):
			var prev = focus_owner.find_prev_valid_focus()
			if not is_ancestor_of(prev):
				# ignore request
				accept_event()


func open():
	if disabled:
		return
	await await_ready()
	opening = true
	if not done:
		push_error("open was called more than once")
		if animation_player.current_animation == "Close":
			animation_player.play("Open")
	else:
		if not animation_player.is_playing() or animation_player.current_animation != "Open":
			animation_player.play("Open")
	done = false
	if(is_instance_valid(click_blocker)):
		click_blocker.visible = true
	try_grab_focus()
	if animation_player.is_playing():
		await animation_player.animation_finished
	if(is_instance_valid(click_blocker)):
		click_blocker.visible = false
	opened.emit()
	opening = false


func try_grab_focus():
	var p = get_parent()
	var cidx = get_index()
	var siblings = p.get_children()
	for index in range(cidx + 1, siblings.size()):
		var sb = p.get_child(index)
		if not (sb is PopupBase):
			continue
		if sb.done == false:
			# there is another dialog that's on top
			return
	grab_focus()


func close():
	await await_ready()
	print("Closing dialog :", get_path())
	if done:
		push_error("close was called more than once")
		return
	if not animation_player.is_playing():
		if(is_instance_valid(click_blocker)):
			click_blocker.visible = true
		animation_player.play("Close")
	await animation_player.animation_finished
	if not opening:
		done = true
		if(is_instance_valid(click_blocker)):
			click_blocker.visible = false
		if free_on_select:
			queue_free()
	closed.emit()


func _on_option_selected(params: Dictionary) -> bool:
	if not can_receive_input():
		return false
	option_selected.emit(params)
	return true


func can_receive_input():
	return is_ready and not animation_player.is_playing()


func set_disabled(value: bool) -> void:
	if disabled != value:
		disabled = value
		if disabled:
			visible = false
			# TODO : check if setting done to true is enough
			#  the 'disabled' property is mostly used for testing only.
			done = true
