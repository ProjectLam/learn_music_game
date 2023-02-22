extends Control
class_name InstrumentSelectionItem

signal pressed

var instrument_data: InstrumentData: set = set_instrument_data

@onready var icon := %Icon
@onready var name_label := %NameLabel
@onready var songs_number = %SongsNumber
@onready var courses_number = %CoursesNumber
@onready var info = %Info

var is_ready:= false

var _info_visible := true
var info_visible: bool :
	set = set_info_visible,
	get = get_info_visible

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	is_ready = true
	reload()


func _process(delta):
	var x = get_viewport().get_mouse_position().x / get_viewport_rect().size.x
	var y = get_viewport().get_mouse_position().y / get_viewport_rect().size.y
	var pos = Vector2(x, y)
	
	$Circle.material = $Circle.material.duplicate()
	
	$Circle.material.set_shader_parameter("lighting_point", pos)


func set_instrument_data(ndata: InstrumentData):
	if instrument_data != ndata:
		instrument_data = ndata
		reload()


func reload():
	if not is_ready or not instrument_data:
		return
	icon.texture = instrument_data.icon
	name_label.text = instrument_data.instrument_label
	info.visible = _info_visible
	if not SongsConfigPreloader.is_song_preload_completed:
		await SongsConfigPreloader.song_preload_completed
	courses_number.text = str(InstrumentDetails.get_courses_number(instrument_data))
	songs_number.text = str(InstrumentDetails.get_songs_number(instrument_data))


func set_info_visible(vis: bool) -> void:
	_info_visible = vis
	reload()


func get_info_visible() -> bool:
	return _info_visible


func _on_mouse_entered():
	$Circle.material.set_shader_parameter("indicate", true)


func _on_mouse_exited():
	$Circle.material.set_shader_parameter("indicate", false)


func _on_overlay_button_pressed():
	pressed.emit()
