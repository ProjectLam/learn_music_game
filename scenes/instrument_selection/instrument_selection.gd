extends Control

const ISELECT_ITEM = preload("res://scenes/instrument_selection/instrument_selection_item.tscn")

@onready var instrument_selection_panel = %InstrumentSelectionPanel

func _ready():
	focus_entered.connect(_on_focus_entered)
	
	if get_viewport().gui_get_focus_owner() == null:
		grab_focus()


func select_instrument(idata: InstrumentData):
	PlayerVariables.gameplay_instrument_data = idata
	PlayerVariables.save()
	get_tree().change_scene_to_file("res://scenes/instrument_menu/instrument_menu.tscn")


func _on_focus_entered():
	instrument_selection_panel.grab_focus()


func _on_instrument_selection_panel_instrument_selected(idata):
	select_instrument(idata)
