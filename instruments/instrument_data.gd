@tool
class_name InstrumentData
extends Resource


enum Family {
	GUITARS,
	STRINGS,
	WOODWINDS,
	BRASS,
	PERCUSSION,
	HARPS,
}

enum Chromatic {
	A0,
	A_SHARP0,
	B0,
	C1,
	C_SHARP1,
	D1,
	D_SHARP1,
	E1,
	F1,
	F_SHARP1,
	G1,
	G_SHARP1,
	A1,
	A_SHARP1,
	B1,
	C2,
	C_SHARP2,
	D2,
	D_SHARP2,
	E2,
	F2,
	F_SHARP2,
	G2,
	G_SHARP2,
	A2,
	A_SHARP2,
	B2,
	C3,
	C_SHARP3,
	D3,
	D_SHARP3,
	E3,
	F3,
	F_SHARP3,
	G3,
	G_SHARP3,
	A3,
	A_SHARP3,
	B3,
	C4,
	C_SHARP4,
	D4,
	D_SHARP4,
	E4,
	F4,
	F_SHARP4,
	G4,
	G_SHARP4,
	A4,
	A_SHARP4,
	B4,
	C5,
	C_SHARP5,
	D5,
	D_SHARP5,
	E5,
	F5,
	F_SHARP5,
	G5,
	G_SHARP5,
	A5,
	A_SHARP5,
	B5,
	C6,
	C_SHARP6,
	D6,
	D_SHARP6,
	E6,
	F6,
	F_SHARP6,
	G6,
	G_SHARP6,
	A6,
	A_SHARP6,
	B6,
	C7,
	C_SHARP7,
	D7,
	D_SHARP7,
	E7,
	F7,
	F_SHARP7,
	G7,
	G_SHARP7,
	A7,
	A_SHARP7,
	B7,
	C8,
	C_SHARP8,
	D8,
	D_SHARP8,
	E8,
	F8,
	F_SHARP8,
	G8,
	G_SHARP8,
}

# used as identifier for the instrument.
# instrument_name is case insensitive. when being used it will be converted to lowercase.
var instrument_name: String :
	get:
		return resource_path.get_file()

# used to display the name of the instrument.
@export var instrument_label: String
@export var family: Family = Family.GUITARS
@export var tuning_pitches: Array[Chromatic]
@export var transposition: int = 0

# big Icon for instrument.
@export var icon: Texture2D
@export var performance_scene: PackedScene

@export var marker_positions: Array[Vector2i] = []

const default_string_pitches: Array[Chromatic] = [
	Chromatic.E2,
	Chromatic.A2,
	Chromatic.D3,
	Chromatic.G3,
	Chromatic.B3,
	Chromatic.E4,
]

const default_fret_count := 12

func get_default_tune(string: int, fret: int) -> Chromatic:
	assert(string >= 0 and string < default_string_pitches.size())
	var base = default_string_pitches[string]
	return base + fret


# TODO: add string mapping that correspond to guitar strings for other instruments.
func map_note(string,fret) -> Vector2:
	if (
			tuning_pitches.size() > string and default_string_pitches[string] == tuning_pitches[string]
			and get_real_fret_count() == default_fret_count):
		# no conversion needed
		return Vector2(string,fret)
	var tune = get_default_tune(string, fret)
	# Add more fingering logic here if neede.
	
	# Current algortihm will just find the lowest fret possible.
	var mstring = 0
	while(tuning_pitches.size() - 1 > mstring and tuning_pitches[mstring + 1] < tune):
		mstring += 1
	var mfret = tune - tuning_pitches[mstring]
	
	return Vector2(mstring, mfret)

func get_string_count() -> int:
	return tuning_pitches.size()


func get_real_fret_count() -> int:
	return abs(transposition)


func get_default_string_colors() -> Array[Color]:
	return [
		Color.PURPLE,
		Color.GREEN,
		Color.PINK,
		Color.BLUE,
		Color.YELLOW,
		Color.RED
	]


func create_performance_node() -> Node:
	if not performance_scene:
		push_error("No performance scene set.")
		return null
	var ret = performance_scene.instantiate()
	ret.set("instrument_data", self)
	return ret
