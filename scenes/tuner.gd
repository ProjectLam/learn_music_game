extends Control


enum TuningMode {
	CHROMATIC,
	INSTRUMENT_SPECIFIC,
}


@export var instrument_data: InstrumentData

var tuning_mode: TuningMode = TuningMode.CHROMATIC
@export var max_needle_angle = 60.0

@onready var needle = $%"Needle"
@onready var perfect_arrows = $TextureRect/PerfectArrows
@onready var too_high_arrow = $TextureRect/TooHighArrow
@onready var too_low_arrow = $TextureRect/TooLowArrow

var max_error = 0.05
var tuning_pegs: Array


func _ready():
	if instrument_data:
		if instrument_data.family == InstrumentData.Family.GUITARS or instrument_data.family == InstrumentData.Family.STRINGS:
			$HeadStock.show()
			for i in ceil(instrument_data.tuning_pitches.size() / 2.0):
				var peg = preload("res://scenes/tuning/tuning_peg_left.tscn").instantiate()
				$HeadStock/LeftPegs.add_child(peg)
				tuning_pegs.append(peg)
			for i in instrument_data.tuning_pitches.size() / 2:
				var peg = preload("res://scenes/tuning/tuning_peg_right.tscn").instantiate()
				$HeadStock/RightPegs.add_child(peg)
				tuning_pegs.append(peg)
		
		# Adding the same if-statement twice because I don't expect them to stay identical
		if instrument_data.family == InstrumentData.Family.GUITARS or instrument_data.family == InstrumentData.Family.STRINGS:
			tuning_mode = TuningMode.INSTRUMENT_SPECIFIC
	else:
		$HeadStock.hide()


func _process(delta):
	var sin_value = 8 * (sin(0.0001 * Time.get_ticks_msec()) + 1) * 0.5
	var frequency = 27.5 * pow(2, sin_value)
	set_input_frequency(frequency)


func set_input_frequency(new_frequency: float):
	var nearest_frequency_data = _get_nearest_target_frequency(new_frequency)
	$TextureRect/NoteLabels/Label0.text = NoteFrequency.CHROMATIC_NAMES_NO_OCTAVES[(nearest_frequency_data.chromatic_index - 3) % 12]
	$TextureRect/NoteLabels/Label1.text = NoteFrequency.CHROMATIC_NAMES_NO_OCTAVES[(nearest_frequency_data.chromatic_index - 2) % 12]
	$TextureRect/NoteLabels/Label2.text = NoteFrequency.CHROMATIC_NAMES_NO_OCTAVES[(nearest_frequency_data.chromatic_index - 1) % 12]
	$TextureRect/NoteLabels/Label3.text = NoteFrequency.CHROMATIC_NAMES_NO_OCTAVES[nearest_frequency_data.chromatic_index % 12]
	$TextureRect/NoteLabels/Label4.text = NoteFrequency.CHROMATIC_NAMES_NO_OCTAVES[(nearest_frequency_data.chromatic_index + 1) % 12]
	$TextureRect/NoteLabels/Label5.text = NoteFrequency.CHROMATIC_NAMES_NO_OCTAVES[(nearest_frequency_data.chromatic_index + 2) % 12]
	$TextureRect/NoteLabels/Label6.text = NoteFrequency.CHROMATIC_NAMES_NO_OCTAVES[(nearest_frequency_data.chromatic_index + 3) % 12]
	
	var target: float = nearest_frequency_data.frequency
	var chromatic_target: float = NoteFrequency.CHROMATIC[nearest_frequency_data.chromatic_index]
	
	if instrument_data and (instrument_data.family == InstrumentData.Family.GUITARS or instrument_data.family == InstrumentData.Family.STRINGS):
		var target_index = NoteFrequency.CHROMATIC.find(target)
		var peg_index = instrument_data.tuning_pitches.find(target_index)
		for peg in tuning_pegs:
			peg.deselect()
		tuning_pegs[peg_index].select()
	
	var min_frequency: float = 0.5 * chromatic_target * pow(2.0, 11.5/12.0)
	var max_frequency: float = chromatic_target * pow(2, 0.5/12.0)
	
	var deviation = inverse_lerp(min_frequency, max_frequency, new_frequency)
	deviation = clamp(deviation, 0.0, 1.0)
	
	needle.rotation = deg_to_rad(lerp(-max_needle_angle, max_needle_angle, deviation))
	
	if abs(2 * deviation - 1) <= max_error:
		perfect_arrows.show()
		too_low_arrow.hide()
		too_high_arrow.hide()
	elif deviation < 0.5:
		perfect_arrows.hide()
		too_low_arrow.show()
		too_high_arrow.hide()
	else:
		perfect_arrows.hide()
		too_low_arrow.hide()
		too_high_arrow.show()


func _get_nearest_target_frequency(frequency: float):
	var frequencies: Array
	var note_names: Array
	
	match tuning_mode:
		TuningMode.CHROMATIC:
			frequencies = NoteFrequency.CHROMATIC.duplicate()
			note_names = NoteFrequency.CHROMATIC_NAMES.duplicate()
		TuningMode.INSTRUMENT_SPECIFIC:
			frequencies = []
			note_names = []
			
			for frequency_index in instrument_data.tuning_pitches:
				frequencies.append(NoteFrequency.CHROMATIC[frequency_index])
				note_names.append(NoteFrequency.CHROMATIC_NAMES[frequency_index])
	
	var target_index: int = 0
	for i in frequencies.size():
		if abs(frequencies[i] - frequency) < abs(frequencies[target_index] - frequency):
			target_index = i
	
	var chromatic_index: int = target_index
	if tuning_mode != TuningMode.CHROMATIC:
		for i in NoteFrequency.CHROMATIC.size():
			if abs(NoteFrequency.CHROMATIC[i] - frequency) < abs(NoteFrequency.CHROMATIC[chromatic_index] - frequency):
				chromatic_index = i
	
	return {
		frequency = frequencies[target_index],
		note_name = note_names[target_index],
		chromatic_index = chromatic_index
	}


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")
