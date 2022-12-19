extends TextureRect


const DESELECTED_TEXTURE = preload("res://assets/gui/tuner/tuning_peg_left.png")
const SELECTED_TEXTURE = preload("res://assets/gui/tuner/tuning_peg_left_selected.png")


func select():
	texture = SELECTED_TEXTURE


func deselect():
	texture = DESELECTED_TEXTURE
