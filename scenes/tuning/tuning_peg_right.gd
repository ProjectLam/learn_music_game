extends TextureRect


const DESELECTED_TEXTURE = preload("res://assets/gui/tuner/tuning_peg_right.png")
const SELECTED_TEXTURE = preload("res://assets/gui/tuner/tuning_peg_right_selected.png")


func select():
	texture = SELECTED_TEXTURE


func deselect():
	texture = DESELECTED_TEXTURE
