extends VBoxContainer

@onready var audio_offset_label = %AudioOffsetLabel
@onready var audio_offset_slider = %AudioOffsetSlider

var prev_value: float = -99999
# Called when the node enters the scene tree for the first time.
func _ready():
	call_deferred("initialize")


func initialize() -> void:
	audio_offset_slider.value = owner.performance_instrument.notes.custom_audio_offset
	refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	refresh()


func refresh():
	if not is_inside_tree():
		return
	
	var offvalue = audio_offset_slider.value
	if prev_value != offvalue:
		audio_offset_label.text = "Audio Offset: %.2f s" % offvalue
		owner.performance_instrument.notes.custom_audio_offset = offvalue
		owner._refresh_audio_stream()
	
	prev_value = offvalue
	
