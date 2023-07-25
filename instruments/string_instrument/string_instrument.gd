@tool
extends PerformanceInstrument
class_name StringInstrument

@export var instrument_data: InstrumentData:
	set = set_instrument_data
@onready var strings = %Strings
@onready var frets = %Frets
@onready var lanes = %Lanes
@onready var markers = %Markers
@onready var string_container = %StringContainer

func _ready():
	InstrumentInput.current_instrument_changed.connect(refresh)
	super._ready()
	if not instrument_data:
		push_error("Invalid Instrument Data")
		if not Engine.is_editor_hint():
			queue_free()
		return
	refresh()
	
	

func _process(delta):
	super._process(delta)


func refresh():
	if not is_inside_tree():
		return
	
	strings.string_count = instrument_data.get_string_count()
	strings.string_colors = instrument_data.get_default_string_colors()
	frets.fret_count = instrument_data.get_real_fret_count()
	markers.marker_positions = instrument_data.marker_positions
	
	for c in get_children():
		if c.has_method("refresh"):
			c.refresh()
	
	for c in string_container.get_children():
		if c.has_method("refresh"):
			c.refresh()
		
	
	InstrumentInput.computer_keyboard_input.string_count = strings.string_count


func set_instrument_data(value: InstrumentData) -> void:
	if instrument_data != value:
		instrument_data = value
		refresh()
