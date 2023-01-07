extends Node

var record_bus : int
var record_peaks_effect : int = 0
var bus_layout : AudioBusLayout = preload("res://default_bus_layout.tres")

var reset_audio_bus := true

# for repeatitive not ciritical tasks, locking MIGHT ruin things.
# disabling locking might result in no change.
# locking is still done by default for safety.
var lock_audio_server := true

func _ready():
	AudioServer.lock()
	record_bus = AudioServer.get_bus_index("NoteDetection")
#	bus_layout.set("bus/%d/effect/%d/effect" % 
#		[record_bus, record_peaks_effect], naf)
	AudioServer.unlock()

# lock AudioServer before calling this
func get_pitch_analyzer():
	return AudioServer.get_bus_effect_instance(record_bus,record_peaks_effect)

func get_record_peaks() -> PackedVector2Array:
	if(lock_audio_server):
		AudioServer.lock()
	var arr : PackedVector2Array = []
	var spectrum = get_pitch_analyzer()
	if(spectrum):
		arr = spectrum.get_peaks()
	if(lock_audio_server):
		AudioServer.unlock()
	return arr

func set_record_peaks_clarity(clarity : float = 0.05):
	# Note : there is a cpoule of ways to do this
	var peffect = bus_layout.get("bus/%d/effect/%d/effect" % 
		[record_bus, record_peaks_effect])
	peffect.set("clarity_threshold", clarity)
	
	# forces to recreate the instances with the new settings.
	# not the most efficient way but the most generic way.
	reset_audio_bus = true
	
func _reload_audio_bus():
	AudioServer.set_bus_layout(bus_layout)
	
func _process(delta):
	if reset_audio_bus:
		call_deferred("_reload_audio_bus")
		reset_audio_bus = false
