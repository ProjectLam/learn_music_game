extends Control
class_name TSongSelectionItem

var nItem: SongSelectionItem
var nNameLabel: Label
var nArtistLabel: Label

func remove() -> void:
	nItem.queue_free()
