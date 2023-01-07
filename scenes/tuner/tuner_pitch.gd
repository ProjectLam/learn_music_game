extends Control

var cNotesItem = preload("res://scenes/tuner/notes_item.tscn")

@export var pitch_freq: float = 440
@export var freq_start_div: float = 1
@export var freq_end_div: float = 1

@onready var nItems = find_child("Notes").find_child("Items")
@onready var nFreqLabel = find_child("FreqLabel")
@onready var nStick = find_child("Stick")

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

func _ready():
	for note in mnemonics:
		var nItem = cNotesItem.instantiate()
		nItems.add_child(nItem)
		nItem.find_child("MnemonicLabel").text = note
	
	GAudioServerManager.set_record_peaks_clarity(0.04)
	
	$AudioStreamPlayer.play()

func _process(delta):
	var arr = GAudioServerManager.get_record_peaks()
	if arr.size():
		var freq = arr[0][0]
		var b88_note_i = round((log(freq/27.5) / log(2)) * 12)
		var note_i = (69 + int(round(12 * log(freq / pitch_freq) / log(2)))) % 12
		var nfreq = note_freq(b88_note_i)
		
		var sub_range = note_freq_range(b88_note_i)
		var sub_freq_range: float = sub_range.y - sub_range.x
		var sub_freq: float = freq - sub_range.x
		var sub_freq_ratio: float = sub_freq / sub_freq_range
		
		var note = mnemonics[note_i]
		nFreqLabel.text = note
		
		var iw = nItems.get_child(note_i).get_rect().size.x
		var isw = nItems.get_rect().size.x / 12
		var pos = (iw * note_i) * -1
		pos += nItems.get_rect().size.x / 2
		pos -= iw + iw/4.0
		
		var tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(nItems, "position:x", pos, 0.25)
		
		for i in nItems.get_child_count():
			if i == note_i:
				continue
			var nItem = nItems.get_child(i)
			var label_settings = nItem.find_child("MnemonicLabel").label_settings
			tween.tween_property(nItems.get_child(note_i).find_child("MnemonicLabel").label_settings, "font_color", Color.GRAY, 0.25)
		
		tween.tween_property(nItems.get_child(note_i).find_child("MnemonicLabel").label_settings, "font_color", Color.WHITE, 0.25)
		
		var stick_angle = stick_start + (stick_range * sub_freq_ratio)
		var stick_radians = deg_to_rad(stick_angle)
		tween.tween_property(nStick, "rotation", stick_radians, 0.25)
