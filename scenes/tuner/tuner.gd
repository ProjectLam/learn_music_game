extends Control

var cNotesItem = preload("res://scenes/tuner/notes_item.tscn")

@export var pitch_freq: float = 440
@export var sub_steps: int = 9
@export var energy_threshold: float = -60
@export var freq_start_div: float = 2.0
@export var freq_end_div: float = 2.0

@export var sensitivity_interpolation_delay = 60
var sensitivity_interpolation_time = 0

@onready var nItems = find_child("Notes").find_child("Items")
@onready var nFreqLabel = find_child("FreqLabel")
@onready var nStick = find_child("Stick")

var spectrum

# Reference Guitar Note Frequencies:
# 	E	329.63
# 	B	246.94
# 	G	196.00
# 	D	146.83
# 	A	110.00
# 	E	82.41

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

var max_energy
var res_freq

var nonsensitive_sub_freq_ratio = 0.5
var nonsensitive_sub_freq_total = 0
var nonsensitive_sub_freq_count = 0
var nonsensitive_sub_freqs = {}

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

func note_sub_freq_range(i: int) -> Vector2:
	if i == 0:
		return Vector2(26.5, 28.5)
	
	return Vector2(
		note_freq(i-1),
		note_freq(i+1)
	)

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(1, 1)
	$AudioStreamPlayer.play()
	
	for note in mnemonics:
		var nItem = cNotesItem.instantiate()
		nItems.add_child(nItem)
		nItem.find_child("MnemonicLabel").text = note

func _process(delta):
	var time = Time.get_ticks_msec()
	var diff = time - sensitivity_interpolation_time
	var curr = float(diff) / sensitivity_interpolation_delay
	
	var freq_start
	var freq_end
	
	var sub_max_energy
	var sub_res_freq
	
	var sub_range
	var sub_range_start
	var sub_range_end
	var sub_step_freq
	var sub_freq_ratio
	
	var steps_ratio = 0
	
	var b88_note_i: int
	
	max_energy = -INF
	res_freq = -1
	
	for i in 88:
		var freq = note_freq(i)
		var freq_range = note_freq_range(i)
		freq_start = freq_range.x
		freq_end = freq_range.y
		
		var magnitude = spectrum.get_magnitude_for_frequency_range(freq_start, freq_end, spectrum.MAGNITUDE_AVERAGE)
		var energy = linear_to_db(magnitude.x)
		
		if energy > max_energy:
			b88_note_i = i
			steps_ratio = float(i) / 88
			res_freq = freq
			max_energy = energy
	
	if max_energy > energy_threshold:
		sub_max_energy = -INF
		sub_res_freq = -INF
		
		sub_range = note_sub_freq_range(b88_note_i).y - note_sub_freq_range(b88_note_i).x
		sub_step_freq = sub_range / sub_steps
		sub_range_start = note_sub_freq_range(b88_note_i).x - sub_step_freq
		sub_freq_ratio = 0
		
		for j in sub_steps:
			sub_range_start += sub_step_freq
			sub_range_end = sub_range_start + sub_step_freq
			
			var sfreq = (sub_range_start + sub_range_end) / 2.0
			var smagnitude = spectrum.get_magnitude_for_frequency_range(sub_range_start, sub_range_end, spectrum.MAGNITUDE_AVERAGE)
			var senergy = linear_to_db(smagnitude.x)
			
			if senergy > sub_max_energy:
				sub_freq_ratio = float(j) / sub_steps
				sub_res_freq = sfreq
				sub_max_energy = senergy
				
				if diff < sensitivity_interpolation_delay:
					nonsensitive_sub_freq_total += sub_freq_ratio
					nonsensitive_sub_freq_count += 1
					if not nonsensitive_sub_freqs.has(str(sub_freq_ratio)):
						nonsensitive_sub_freqs[str(sub_freq_ratio)] = 0
					nonsensitive_sub_freqs[str(sub_freq_ratio)] += senergy
		
		b88_note_i = b88_note_i
		var note_i = (69 + int(round(12 * log(res_freq / pitch_freq) / log(2)))) % 12
		
		if diff >= sensitivity_interpolation_delay:
#			nonsensitive_sub_freq_ratio = 0
			var t = 0
			for k in nonsensitive_sub_freqs.keys():
				var c = nonsensitive_sub_freqs[k]
				if c > t:
					nonsensitive_sub_freq_ratio = k
				t = c
			nonsensitive_sub_freqs = {}
#			nonsensitive_sub_freq_ratio = float(nonsensitive_sub_freq_total) / nonsensitive_sub_freq_count
		
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
		
		var stick_angle = stick_start + (stick_range * float(nonsensitive_sub_freq_ratio))
		var stick_radians = deg_to_rad(stick_angle)
		tween.tween_property(nStick, "rotation", stick_radians, 0.25)
		
		print("nonsensitive_sub_freq_ratio: ", nonsensitive_sub_freq_ratio , " - ratio: ", sub_freq_ratio)
	
	if diff >= sensitivity_interpolation_delay:
		sensitivity_interpolation_time = Time.get_ticks_msec()
