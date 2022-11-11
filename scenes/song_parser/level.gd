extends Node
class_name Level

@export var difficulty:int = 0
#@export var notes:Array[SNote] = [] #TODO maybe we can make some kind of packedarray in future
@export var notes = PackedByteArray()
@export var notes_count:int = 0
#<note time="73.12" linkNext="0" accent="1" bend="0" fret="0" hammerOn="0" harmonic="0" hopo="0" ignore="0" leftHand="-1" mute="0" palmMute="0" pluck="-1" pullOff="0" slap="-1" slideTo="-1" string="0" sustain="0" tremolo="0" harmonicPinch="0" pickDirection="0" rightHand="-1" slideUnpitchTo="-1" tap="0" vibrato="0" />



# Called when the node enters the scene tree for the first time.
func _ready():
	notes.resize(65536)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
