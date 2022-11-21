extends Object
class_name TInstrumentSelectionItems

var cInstrumentSelectionItem = preload("res://scenes/InstrumentSelection/InstrumentSelectionItem.tscn")

var items: Dictionary = {}

func set_item(
	p_name: String,
	p_label: String,
	p_image: Texture,
	p_songs_count: int,
	p_courses_count: int
) -> TInstrumentSelectionItem:
	var item: TInstrumentSelectionItem = TInstrumentSelectionItem.new()
	item.nItem = cInstrumentSelectionItem.instantiate()
	item.nItem.name = p_name
	item.nItem.item = item
	item.name = p_name
	item.label = p_label
	item.image = p_image
	item.songs_count = p_songs_count
	item.courses_count = p_courses_count
	
	items[p_name] = item
	
	return item

func get_item(p_name) -> TInstrumentSelectionItem:
	return items[p_name]

func get_item_by_index(p_index: int) -> TInstrumentSelectionItem:
	return items[items.keys()[p_index]]

func get_item_circular(p_index: int) -> TInstrumentSelectionItem:
	return get_item_by_index(p_index % items.size())
