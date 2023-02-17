extends PerformanceInstrument


const MIDDLE_C_OFFSET = 3 + 3 * 12
const MOVEMENT_DISTANCE_THRESHOLD: float = 1.0

@onready var target_position = position

@export var move_speed = 0.1


func _ready():
	super._ready()
	GBackend.ui_node.visible = false
#	if not SongsConfigPreloader.is_song_preload_completed:
#		set_process(false)
#		print("Waiting for song configurations...")
#		await SongsConfigPreloader.song_preload_completed
#		print("Song configurations loaded")
#		set_process(true)
	
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
	
	var debug_note := Note.new()
	debug_note.string = 0
	debug_note.time = 6.0
	
	$Notes.spawn_note(debug_note,0)


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
	if target_position.distance_to(position) >= MOVEMENT_DISTANCE_THRESHOLD:
		var direction = (target_position - position).normalized()
		translate(direction * move_speed * delta)
