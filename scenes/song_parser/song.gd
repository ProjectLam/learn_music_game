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

#  <albumName>The Wall</albumName>
#  <albumNameSort>Wall, The</albumNameSort>
#  <albumYear>1979</albumYear>


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func parser_ebeats():
	print("weeee ebeats")
