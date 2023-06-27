extends PerformanceInstrument


const MIDDLE_C_OFFSET = 3 + 3 * 12
const MOVEMENT_DISTANCE_THRESHOLD: float = 1.0
const HIGHLIGHT_BRIGHTNESS := 0.5
const HIGHLIGHT_OFF_BRIGHTNESS := 0.1

@onready var target_position = position

@export var move_speed = 0.1

var note_lanes := {}



func _ready():
	super._ready()
	var keyboard_instrument = InstrumentInput.get_instrument(InstrumentInput.get_instrument_index("ComputerKeyboardInput"))
	keyboard_instrument.octave_changed.connect(on_keyboard_octave_changed)
	keyboard_instrument.activated.connect(on_keyboard_activated)
	keyboard_instrument.deactivated.connect(on_keyboard_deactivated)
	
	if keyboard_instrument.is_active:
		on_keyboard_activated()
	else:
		on_keyboard_deactivated()
	
	$Notes.note_spawned.connect(on_note_spawned)
	$Notes.note_destroyed.connect(on_note_destroyed)
	
	for index in NoteFrequency.CHROMATIC.size():
		var pitch = NoteFrequency.CHROMATIC[index]
		var cname = NoteFrequency.CHROMATIC_NAMES[index]
		var lane_node = find_child(cname+"Lane")
		if lane_node:
			note_lanes[pitch] = lane_node
			lane_node.material_override = lane_node.material_override.duplicate()


func on_keyboard_octave_changed(new_offset):
	$ComputerKeyboardLabels.position.x = 7 * (new_offset - MIDDLE_C_OFFSET) / 12


func on_keyboard_activated():
	$ComputerKeyboardLabels.show()


func on_keyboard_deactivated():
	$ComputerKeyboardLabels.hide()


func on_note_spawned():
	update_position()


func on_note_destroyed():
	return
#	update_position()


func update_position():
	var notes_center = $Notes.get_notes_center_x()
	target_position.x = -notes_center


func _process(delta):
	super._process(delta)
	if target_position.distance_to(position) >= MOVEMENT_DISTANCE_THRESHOLD:
		var direction = (target_position - position).normalized()
		translate(direction * move_speed * delta)


func highlight_lanes(pitches: PackedFloat64Array) -> void:
	for pitch in note_lanes:
		var lane_node = note_lanes[pitch]
		if pitch in pitches:
			lane_node.material_override["shader_parameter/brightness"] = HIGHLIGHT_BRIGHTNESS
		else:
			lane_node.material_override["shader_parameter/brightness"] = HIGHLIGHT_OFF_BRIGHTNESS


func _on_notes_song_changed():
	highlight_lanes(notes.used_pitches)
