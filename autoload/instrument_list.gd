extends Node

var instruments: Dictionary = {}

const default_instrument_list: Array[String] = [
	"res://models/instruments/piano.tres",
	"res://instruments/guitar.tres",
]


func _ready() -> void:
	for res_path in default_instrument_list:
		if not (res_path is String):
			push_error("Invalid instrument resource path.")
			continue
		var inst = load(res_path)
		if !(inst is InstrumentData):
			push_error("Invalid instrument resource.")
			continue
		var iname = inst.instrument_name
		if instruments.has(iname):
			push_warning("Duplicate instrument [%s] found. Overriding instrument data" % iname)
		instruments[iname] = inst
	print("Instruments configured :", instruments.keys())


func get_instrument_by_name(inst_name : String) -> InstrumentData:
	assert(!instruments.is_empty())
	inst_name = inst_name.to_lower()
	if instruments.has(inst_name):
		return instruments[inst_name]
	var inst : InstrumentData = instruments.values()[0]
	push_error("Instrument not found, defaulting to %s" % inst.instrument_name)
	return inst


func add_instrument(inst : InstrumentData) -> void:
	var iname = inst.instrument_name
	if instruments.has(iname):
		push_warning("Duplicate instrument [%s] found. Overriding instrument data" % iname)
	instruments[iname] = inst
