extends Node
class_name Song


@export var artistName = ""
@export var title = ""
@export var artistNameSort = ""
@export var artistYear = ""
@export var artistXXXXYear = ""
@export var bobXXXX = ""
@export var ebeats:Ebeats = Ebeats.new()
@export var songMusicFile = ""
@export var levels_count = 0
@export var levels:Array[Level] = [] #TODO potentially change this to a map


#  <albumName>The name</albumName>
#  <albumNameSort>name, the</albumNameSort>
#  <albumYear>1981</albumYear>


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
