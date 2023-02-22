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


var done := true:
	set(value):
		if done != value:
			done = value
			visible = not done


func _ready():
	focus_mode = Control.FOCUS_ALL
	await get_tree().process_frame
	if open_on_ready:
		open()
	else:
		visible = false


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
	if not done:
		push_error("open was called more than once")
	done = false
	if(is_instance_valid(click_blocker)):
		click_blocker.visible = true
	try_grab_focus()
	animation_player.play("Open")
	await animation_player.animation_finished
	if(is_instance_valid(click_blocker)):
		click_blocker.visible = false
	opened.emit()


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
	print("Closing dialog :", get_path())
	if done:
		push_error("close was called more than once")
		return
	if not animation_player.is_playing():
		if(is_instance_valid(click_blocker)):
			click_blocker.visible = true
		animation_player.play("Close")
	await animation_player.animation_finished
	if(is_instance_valid(click_blocker)):
		click_blocker.visible = false
	if free_on_select:
		queue_free()
	done = true
	# when a control becomes hidden, it will automatically lose focus.
	closed.emit()


func _on_option_selected(params: Dictionary) -> bool:
	if not can_receive_input():
		return false
	option_selected.emit(params)
	return true


func can_receive_input():
	return not animation_player.is_playing()
