extends Control

@export var idata: InstrumentData


@export var map_from: Vector2i

func _ready():
	if idata:
		var to = idata.map_string_note(map_from.x , map_from.y)
		print("Guitar (%d, %d) : IDATA (%d, %d)" % [map_from.x, map_from.y, to.x, to.y])
