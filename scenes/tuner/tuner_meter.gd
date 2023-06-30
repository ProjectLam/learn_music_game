extends PanelContainer

var cNotesItem = preload("res://scenes/tuner/notes_item.tscn")


@export var pitch_freq: float = 440
@export var freq_start_div: float = 1
@export var freq_end_div: float = 1
@export var volume_sensitivity := 0.005
@export_range(0.01,1.0) var note_font_size_ratio := 0.05

@onready var note_items = %Notes.find_child("Items")
#@onready var note_label = %NoteLabel
#@onready var volume_label = %VolumeLabel
@onready var stick = %Stick

var mnemonics = [
	"C",
	"Db",
	"D",
	"Eb",
	"E",
	"F",
	"Gb",
	"G",
	"Ab",
	"A",
	"Bb",
	"B"
]

var stick_start = -60
var stick_end = 60
@onready var stick_range = stick_end - stick_start


func _ready():
	for note in mnemonics:
		var item_node = cNotesItem.instantiate()
		item_node.find_child("MnemonicLabel").text = note
		note_items.add_child(item_node)
	
	GAudioServerManager.set_record_peaks_clarity(0.4)
	refresh()
	
	resized.connect(refresh)


func refresh():
	if not is_inside_tree():
		return
	
	for item_node in note_items.get_children():
		item_node.find_child("MnemonicLabel")["theme_override_font_sizes/font_size"] = size.y*note_font_size_ratio
		item_node.custom_minimum_size.x = size.y*note_font_size_ratio*2.0


func note_freq(i: int) -> float:
	if i == 0:
		return 27.5
	
	return pow(2.0, float(i) / 12) * 27.5

func note_freq_range(i: int) -> Vector2:
	if i == 0:
		return Vector2(26.5, 28.5)
	
	return Vector2(
		note_freq(i) - ((note_freq(i) - note_freq(i-1)) / freq_start_div),
		note_freq(i) + ((note_freq(i+1) - note_freq(i)) / freq_end_div)
	)


var tween
var prev_i = -1
func _process(delta):
	print_debug(InstrumentInput.microphone_input.current_peaks)
	if InstrumentInput.microphone_input.current_peaks.size() != 0:
		var freq = 0.0
		var freq_volume = 0.0
		var chromatic: int = 0
		
		for peak_chr in InstrumentInput.microphone_input.current_peaks:
			var peak_dict: Dictionary = InstrumentInput.microphone_input.current_peaks[peak_chr]
			var peak_v = peak_dict["volume"]
			var peak_fr = peak_dict["frequency"]
			if peak_v > freq_volume:
				freq = peak_fr
				freq_volume = peak_v
				chromatic = peak_chr
		if freq_volume < volume_sensitivity:
			return
		
#		var b88_note_i = round((log(freq/27.5) / log(2)) * 12)
		var note_i := 0
		var inputs = InstrumentInput.microphone_input.inputs
#		if not inputs.is_empty():
#			note_i = (NoteFrequency.CHROMATIC.find(inputs[0]) + 9) % 12
#		else:
		note_i = (69 + int(round(12 * log(freq / pitch_freq) / log(2)))) % 12
		var chr_rem := chromatic%12
		var chr_add := - chr_rem + 3
		if chr_rem < 3:
			chr_add = -chr_rem - 12 + 3
		var chromatic_start := chromatic + chr_add
		var chromatic_end := chromatic_start + 11
		var start_freq := NoteFrequency.CHROMATIC[chromatic_start]
		var sub_freq = freq - start_freq
		var sub_freq_range: float = NoteFrequency.CHROMATIC[chromatic_end] - start_freq
		var sub_freq_ratio: float = sub_freq / sub_freq_range
		
		var note = mnemonics[note_i]
#		note_label.text = "Note: " + note
		var isw = note_items.get_rect().size.x / mnemonics.size()
		var pos = note_items.get_parent().size.x / 2 - isw * note_i - isw/2
		
		if tween and tween.is_running():
			tween.kill()
		tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(note_items, "position:x", pos, 0.25)
		if prev_i != note_i:
			prev_i = note_i
		
		for i in note_items.get_child_count():
			if i == note_i:
				continue
			var nItem = note_items.get_child(i)
			var label_settings = nItem.find_child("MnemonicLabel").label_settings
			tween.tween_property(note_items.get_child(note_i).find_child("MnemonicLabel").label_settings, "font_color", Color.GRAY, 0.25)

		tween.tween_property(note_items.get_child(note_i).find_child("MnemonicLabel").label_settings, "font_color", Color.WHITE, 0.25)
#		sub_freq_ratio = 1.0
		var stick_angle = stick_start + (stick_range * sub_freq_ratio)
		var stick_radians = deg_to_rad(stick_angle)
		print_debug(stick_radians)
#		tween.tween_property(stick, "rotation", stick_radians, 0.25)
		stick.rotation = stick_radians
		tween.play()
