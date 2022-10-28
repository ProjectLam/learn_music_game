extends Control
@onready var songsFolderPath = "res://TestSongs/"
@onready var songSArray = []
@onready var buttonObject ="res://Buttons/SongButton.tscn"
@onready var buttonsArray = []
@onready var searchMatches = []
@onready var vbcBttHolder =$CanvasLayer/HBoxContainer/ScrollContainer/VBC_Buttons
func _ready():
	CreateSongsArray(songsFolderPath)
	SpawnButtons()
	FeedEachButton()

func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
func CreateSongsArray(path):
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	while true:
		var songFile = dir.get_next()
		if songFile == "": 
			break
		elif !songFile.begins_with(".") and !songFile.ends_with(".import"):
			songSArray.append(songFile)
	dir.list_dir_end()
#	return songSArray
func SpawnButtons():
	var object = load(buttonObject)
	for i in songSArray:
		var bObj = object.instantiate()
		buttonsArray.append(bObj)
		vbcBttHolder.add_child(bObj)
		if i not in songSArray:
			return
func FeedEachButton():
	for i in buttonsArray.size():
		buttonsArray[i].buttonIndex = i
		buttonsArray[i].songArray = songSArray
		buttonsArray[i].aSPlayer = $AudioStreamPlayer
		var upperCase:String = str(songSArray[i])
		var lowerCase:String = str(songSArray[i])
		upperCase = upperCase.left(1).to_upper()
		lowerCase = lowerCase.right(-1).replace(".ogg","")
		buttonsArray[i].text = upperCase+lowerCase

func _on_search_bar_text_changed(new_text):
	new_text = new_text.to_lower()
	if new_text == "":
		for i in buttonsArray:
			i.show()
		return
	for i in buttonsArray:
		if(new_text in i.text.to_lower() 
		|| new_text in i.album.text.to_lower() 
		|| new_text in i.artist.text.to_lower() 
		|| new_text in i.group.text.to_lower()):
			searchMatches.append(i)
		if i in searchMatches:i.show()
		else:i.hide()
	searchMatches.clear()
