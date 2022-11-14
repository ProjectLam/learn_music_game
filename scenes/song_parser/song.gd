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
